-- Q7.1: USA vs China Market Dominance
-- Compare 2023 EV sales, stock, and market share

SELECT 
    region,
    parameter,
    ROUND(SUM(value)/1000000, 1) as value_millions,
    CASE 
        WHEN parameter LIKE '%share%' THEN '%'
        ELSE 'M vehicles'
    END as unit
FROM ev_sales 
WHERE region IN ('USA', 'China')
    AND year = 2023
    AND (
        (parameter IN ('EV sales', 'EV stock') AND powertrain IN ('BEV', 'PHEV', 'FCEV'))
        OR (parameter = 'EV sales share' AND powertrain = 'EV')
    )
GROUP BY region, parameter
ORDER BY parameter, region;