-- Q7.2: USA vs China Technology Race
-- Compare BEV vs PHEV sales in 2023

SELECT 
    region,
    powertrain,
    ROUND(SUM(value)/1000000, 1) as sales_2023_millions,
    'M vehicles' as unit
FROM ev_sales 
WHERE region IN ('USA', 'China')
    AND year = 2023
    AND parameter = 'EV sales'
    AND powertrain IN ('BEV', 'PHEV')
GROUP BY region, powertrain
ORDER BY region, sales_2023_millions DESC;