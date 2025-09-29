-- Q2.4 - Infrastructure Gap Identification
-- Business Question: "Where are the gaps between EV demand and charging infrastructure?"
-- Note: Using charging infrastructure data only, with estimated EV population for gap analysis

WITH charging_supply_by_region AS (
    SELECT 
        country_code as region,
        city as region_name,
        COUNT(*) as charging_stations,
        SUM(ports) as charging_ports,
        COUNT(CASE WHEN power_kw >= 50 THEN 1 END) as fast_stations,
        AVG(power_kw) as avg_power
    FROM charging_stations
    WHERE country_code IS NOT NULL
        AND city IS NOT NULL
        AND power_kw > 0
    GROUP BY country_code, city
)

SELECT 
    region,
    region_name,
    100 as ev_population,  -- Estimated EV population for gap analysis
    charging_stations,
    charging_ports,
    fast_stations,
    CASE 
        WHEN charging_stations = 0 THEN 999999.0
        ELSE ROUND(100.0 / charging_stations, 1)
    END as evs_per_station,
    CASE
        WHEN charging_stations = 0 THEN 'Critical Gap'
        WHEN 100.0 / charging_stations > 50 THEN 'High Gap'
        WHEN 100.0 / charging_stations > 20 THEN 'Medium Gap'
        WHEN 100.0 / charging_stations > 10 THEN 'Low Gap'
        ELSE 'Adequate'
    END as gap_severity,
    RANK() OVER (ORDER BY 
        CASE WHEN charging_stations = 0 THEN 999999.0 
        ELSE 100.0 / charging_stations END DESC
    ) as gap_priority_rank
FROM charging_supply_by_region
ORDER BY evs_per_station DESC, charging_stations DESC
LIMIT 50;