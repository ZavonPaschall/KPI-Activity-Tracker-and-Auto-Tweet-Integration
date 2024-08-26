-- This query will track how much of the $BERN asset was burnt by the specific burn_authority in question. 
-- It will also calculate a running total and current total burnt of the token. 
-- Dashboard Link: https://flipsidecrypto.xyz/HitmonleeCrypto/burnt-bern-by-bernzy-t7S6n2

WITH RunningTotals AS (
    SELECT 
        LEFT(BLOCK_TIMESTAMP, 16) AS burn_date, 
        succeeded, 
        Burn_amount / 100000 AS BERN_Burned, 
        mint,
        event_type, 
        tx_id,
        burn_authority,
        SUM(Burn_amount / 100000) OVER (ORDER BY LEFT(BLOCK_TIMESTAMP, 16) ASC) AS Running_Total,
        (Burn_amount / 1000000000000)  AS Percent_of_Supply_Burned
    FROM 
        solana.defi.fact_token_burn_actions
    WHERE 
        mint = 'CKfatsPMUf8SkiURsDXs7eK6GWb4Jsd6UDbs7twMCWxo'
        -- AND Token_Account = 'J9toZ7f7mGpVRuXhwsVDPbYTqtQbPArzDmvUiw5MMSao'
        and burn_authority = '7MyTjmRygJoCuDBUtAuSugiYZFULD2SWaoUTmtjtRDzD'
        and block_timestamp > '2023-05-30'

)
SELECT 
    burn_date, 
    BERN_Burned, 
    CAST(ROUND(Percent_of_Supply_Burned, 4) AS VARCHAR) || '%' AS Percent_of_Supply_Burned,
    Running_Total,
    event_type, 
    mint,
    succeeded, 
    (SELECT MAX(Running_Total) FROM RunningTotals) AS Total_BERN_Burned,
    (SELECT SUM(Percent_of_Supply_Burned) FROM RunningTotals) AS Total_Percent_Supply_Bernzy_Burned,
    tx_id
FROM 
    RunningTotals
ORDER BY 
    burn_date DESC;
