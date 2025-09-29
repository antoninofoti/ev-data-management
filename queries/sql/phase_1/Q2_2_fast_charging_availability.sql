-- Q2.2 - Fast Charging Availability
-- Business Question: "What is the availability of fast charging stations?"

WITH charging_categories AS (
    SELECT 
        country_code,
        city, -- using city instead of city
        CASE 
            WHEN power_kw >= 350 THEN 'Ultra Fast (350kW+)'
            WHEN power_kw >= 150 THEN 'Super Fast (150-349kW)'
            WHEN power_kw >= 50 THEN 'Fast (50-149kW)'
            WHEN power_kw >= 22 THEN 'Semi-Fast (22-49kW)'
            ELSE 'Standard (<22kW)'
        END as charging_category,
        COUNT(*) as station_count,
        SUM(ports) as total_ports
    FROM charging_stations
    WHERE country_code IS NOT NULL
        AND power_kw IS NOT NULL
        AND power_kw > 0
    GROUP BY country_code, city, 
        CASE 
            WHEN power_kw >= 350 THEN 'Ultra Fast (350kW+)'
            WHEN power_kw >= 150 THEN 'Super Fast (150-349kW)'
            WHEN power_kw >= 50 THEN 'Fast (50-149kW)'
            WHEN power_kw >= 22 THEN 'Semi-Fast (22-49kW)'
            ELSE 'Standard (<22kW)'
        END
),

fast_charging_summary AS (
    SELECT 
        country_code,
        charging_category,
        SUM(station_count) as total_stations,
        SUM(total_ports) as total_ports,
        COUNT(DISTINCT city) as locations_count
    FROM charging_categories
    WHERE charging_category IN ('Ultra Fast (350kW+)', 'Super Fast (150-349kW)', 'Fast (50-149kW)')
    GROUP BY country_code, charging_category
)

SELECT 
    country_code,
    charging_category,
    total_stations,
    total_ports,
    locations_count,
    ROUND(total_ports / NULLIF(total_stations, 0), 1) as avg_ports_per_station,
    RANK() OVER (PARTITION BY charging_category ORDER BY total_stations DESC) as country_rank
FROM fast_charging_summary
ORDER BY charging_category, total_stations DESC;