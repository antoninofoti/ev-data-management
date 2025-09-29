-- Q7.4: USA vs China Oil Displacement
-- Compare oil saved by EVs in 2023

SELECT 
    region,
    parameter,
    ROUND(SUM(value), 2) as oil_saved_2023,
    CASE 
        WHEN parameter = 'Oil displacement Mbd' THEN 'million barrels/day'
        ELSE 'million liters gasoline equivalent'
    END as unit
FROM ev_sales 
WHERE region IN ('USA', 'China')
    AND parameter IN ('Oil displacement Mbd', 'Oil displacement, million lge')
    AND powertrain = 'EV'
    AND year = 2023
GROUP BY region, parameter
ORDER BY region, parameter;