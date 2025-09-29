-- Q7.3: USA vs China Infrastructure Race
-- Compare EV charging points in 2023

SELECT 
    region,
    ROUND(SUM(value)/1000, 0) as charging_points_thousands,
    'K points' as unit
FROM ev_sales 
WHERE region IN ('USA', 'China')
    AND parameter = 'EV charging points'
    AND powertrain LIKE 'Publicly available%'
    AND year = 2023
GROUP BY region
ORDER BY charging_points_thousands DESC;