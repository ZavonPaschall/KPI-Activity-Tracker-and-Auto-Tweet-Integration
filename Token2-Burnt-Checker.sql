-- This query will track how much of the $BONK asset was burnt by the specific 7my... burn_authority in question. 
-- It will also calculate a running total and current total burnt of the token. 
-- Dashboard Link: https://flipsidecrypto.xyz/HitmonleeCrypto/burnt-bern-by-bernzy-t7S6n2

WITH RunningTotals AS (
    SELECT 
        LEFT(BLOCK_TIMESTAMP, 16) AS burn_date, 
        Burn_amount / 100000 AS Bonk_Burned, 
        mint,
        succeeded,
        burn_authority,
        event_type, 
        SUM(Burn_amount / 100000) OVER (ORDER BY LEFT(BLOCK_TIMESTAMP, 16) ASC) AS Running_Total,
        (Bonk_burned / 100000000000000) * 100 AS bonk_Burned_percent
    FROM 
        solana.defi.fact_token_burn_actions
    WHERE 
        mint = 'DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263'
     --   AND Token_Account = '5y1Nb9XybDBDg1cZSUZ2YMTyUHAusaNnmv3cDsMMWCjt'
        AND block_timestamp > '2023-05-30'
        AND burn_authority = '7MyTjmRygJoCuDBUtAuSugiYZFULD2SWaoUTmtjtRDzD'
)
SELECT 
    burn_date, 
    Bonk_Burned, 
   --  bonk_Burned_percent,
    Running_Total,
    event_type, 
    mint,
    succeeded, 
    (SELECT MAX(Running_Total) FROM RunningTotals) AS Total_Bonk_Burned_by_Bernzy
   -- (SELECT SUM(bonk_Burned_percent) FROM RunningTotals) AS Total_BERN_percent_burned
FROM 
    RunningTotals
ORDER BY 
    burn_date DESC;
