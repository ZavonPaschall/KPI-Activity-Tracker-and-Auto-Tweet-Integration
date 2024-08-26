-- This query was used to combine all of the previous queries that that we we're calculating into one so that we could pass all of the results over webhook. 
-- This will calculate the $BERN burnt/rewards and the $BONK burnt, then once every 24 hrs it will be sent to a google sheet for storage.
       -- The google app script will receive the webhook and then populate the data in the sheet as so. 
-- If the values are new and their was an activity within the last 24 hours then it will publish a tweet to the @BernIntern Twitter Account for the community. 
-- Dashboard Link: https://flipsidecrypto.xyz/HitmonleeCrypto/burnt-bern-by-bernzy-t7S6n2


WITH RunningTotals_Bonk AS (
    SELECT 
        SUM(CASE WHEN BLOCK_TIMESTAMP >= CURRENT_TIMESTAMP - INTERVAL '1 day' THEN Burn_amount / 100000 ELSE 0 END) AS daily_bonk_amount,
        SUM(Burn_amount / 100000) AS running_bonk_total
     --   burn_authority
    FROM 
        solana.defi.fact_token_burn_actions
    WHERE 
        mint = 'DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263'
       -- AND Token_Account = '5y1Nb9XybDBDg1cZSUZ2YMTyUHAusaNnmv3cDsMMWCjt'
        AND BLOCK_TIMESTAMP >= '2023-06-01'
        and burn_authority = '7MyTjmRygJoCuDBUtAuSugiYZFULD2SWaoUTmtjtRDzD'
),

RunningTotals_BERN AS (
    SELECT 
        SUM(CASE WHEN BLOCK_TIMESTAMP >= CURRENT_TIMESTAMP - INTERVAL '1 day' THEN Burn_amount / 100000 ELSE 0 END) AS daily_bern_amount,
        SUM(Burn_amount / 100000) AS running_bern_total
       -- burn_authority
    FROM 
        solana.defi.fact_token_burn_actions
    WHERE 
        mint = 'CKfatsPMUf8SkiURsDXs7eK6GWb4Jsd6UDbs7twMCWxo'
    --    AND Token_Account = 'J9toZ7f7mGpVRuXhwsVDPbYTqtQbPArzDmvUiw5MMSao'
        AND BLOCK_TIMESTAMP >= '2023-05-31'
        and burn_authority = '7MyTjmRygJoCuDBUtAuSugiYZFULD2SWaoUTmtjtRDzD'
),
-- BERN rewards Txs only and omitting the others
reward_txs AS (
  SELECT DISTINCT
    block_timestamp,
    tx_id
  FROM solana.core.fact_events
  WHERE succeeded
    AND program_id = 'TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb' -- Token2022
    AND event_type = 'transferChecked'
    AND signers[0] = '7MyTjmRygJoCuDBUtAuSugiYZFULD2SWaoUTmtjtRDzD'
    AND instruction :parsed :info :authority = '7MyTjmRygJoCuDBUtAuSugiYZFULD2SWaoUTmtjtRDzD'
    AND instruction :parsed :info :mint = 'CKfatsPMUf8SkiURsDXs7eK6GWb4Jsd6UDbs7twMCWxo' -- BERN
    AND block_timestamp > current_timestamp() - INTERVAL '24 hours'
),

reward_transfers AS (
  SELECT
    block_timestamp,
    tx_id,
    tx_to,
    amount - (amount * 0.069) AS amount
  FROM solana.core.fact_transfers
  INNER JOIN reward_txs USING(tx_id, block_timestamp)
  WHERE mint = 'CKfatsPMUf8SkiURsDXs7eK6GWb4Jsd6UDbs7twMCWxo'
    AND tx_from = '7MyTjmRygJoCuDBUtAuSugiYZFULD2SWaoUTmtjtRDzD'
    AND block_timestamp > current_timestamp() - INTERVAL '24 hours'
),

aggregated AS (
  SELECT
    date_trunc('hour', block_timestamp) AS date,
    COUNT(DISTINCT tx_to) AS receivers,
    SUM(amount) AS bern,
    SUM(SUM(amount)) OVER (ORDER BY date) AS cumul,
    AVG(amount) AS "Avg. per User",
    MEDIAN(amount) AS "Med. per User"
  FROM reward_transfers
  GROUP BY 1
),

total_rewards AS (
  SELECT
    SUM(amount - (amount * 0.069)) AS running_bern_reward_total
  FROM solana.core.fact_transfers
  WHERE mint = 'CKfatsPMUf8SkiURsDXs7eK6GWb4Jsd6UDbs7twMCWxo'
    AND tx_from = '7MyTjmRygJoCuDBUtAuSugiYZFULD2SWaoUTmtjtRDzD'
    AND block_timestamp >= '2023-06-01'
)

SELECT 
    COALESCE(b.daily_bonk_amount, 0) AS daily_bonk_amount,
    COALESCE(b.running_bonk_total, 0) AS running_bonk_total,
    COALESCE(bn.daily_bern_amount, 0) AS daily_bern_amount,
    COALESCE(bn.running_bern_total, 0) AS running_bern_total,
    COALESCE(a.cumul, 0) AS daily_bern_reward_amount,
    COALESCE(t.running_bern_reward_total, 0) AS running_bern_reward_total
FROM 
    RunningTotals_Bonk b
CROSS JOIN 
    RunningTotals_BERN bn
CROSS JOIN 
    (SELECT cumul FROM aggregated ORDER BY date DESC LIMIT 1) a
CROSS JOIN 
    total_rewards t
LIMIT 1;


