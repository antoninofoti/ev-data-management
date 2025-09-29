-- Q7.5: USA vs China Future Projections
-- Compare 2030 EV projections

SELECT 
    region,
    parameter,
    ROUND(SUM(value)/1000000, 1) as projected_2030_millions,
    CASE 
        WHEN parameter LIKE '%share%' THEN '%'
        ELSE 'M vehicles'
    END as unit
FROM ev_sales 
WHERE region IN ('USA', 'China')
    AND year = 2030
    AND (
        (parameter IN ('EV sales', 'EV stock') AND powertrain IN ('BEV', 'PHEV', 'FCEV'))
        OR (parameter = 'EV sales share' AND powertrain = 'EV')
    )
GROUP BY region, parameter
ORDER BY parameter, region;