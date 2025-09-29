-- Q6.3 - Grid Impact Analysis
-- Business Question: "What is the potential grid impact of charging infrastructure?"

WITH grid_load_analysis AS (
    SELECT 
        country_code,
        COUNT(*) as total_stations,
        SUM(power_kw) as total_power_capacity,
        SUM(ports) as total_charging_ports,
        AVG(power_kw) as avg_station_power,
        MAX(power_kw) as max_station_power,
        COUNT(CASE WHEN power_kw >= 150 THEN 1 END) as ultra_fast_stations
    FROM charging_stations
    WHERE country_code IS NOT NULL
        AND power_kw > 0
    GROUP BY country_code
    HAVING COUNT(*) >= 10
),

impact_assessment AS (
    SELECT 
        *,
        ROUND(total_power_capacity / 1000.0, 1) as total_mw_capacity,
        ROUND(total_power_capacity / total_stations, 1) as avg_kw_per_station,
        ROUND(ultra_fast_stations * 100.0 / total_stations, 1) as ultra_fast_percentage,
        CASE 
            WHEN total_power_capacity >= 100000 THEN 'High Grid Impact'
            WHEN total_power_capacity >= 10000 THEN 'Moderate Grid Impact'
            ELSE 'Low Grid Impact'
        END as grid_impact_level
    FROM grid_load_analysis
)

SELECT 
    country_code,
    total_stations,
    total_charging_ports,
    total_mw_capacity,
    avg_kw_per_station,
    max_station_power,
    ultra_fast_stations,
    ultra_fast_percentage,
    grid_impact_level,
    RANK() OVER (ORDER BY total_power_capacity DESC) as impact_rank
FROM impact_assessment
ORDER BY total_power_capacity DESC;