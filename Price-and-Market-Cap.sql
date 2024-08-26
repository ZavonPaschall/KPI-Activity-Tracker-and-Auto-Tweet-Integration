-- this is a simple query that'll present on the dashboard, the current asset price and market capitalization. 

select price, price * 988304111.45 as Bern_Market_Cap
from solana.price.ez_prices_hourly
where token_address = 'CKfatsPMUf8SkiURsDXs7eK6GWb4Jsd6UDbs7twMCWxo'
order by hour DESC 
limit 1
