-- Italian Charging Infrastructure Analysis by Region
-- Analyzes charging station distribution and power capacity across Italian regions

WITH italian_stations AS (
    SELECT 
        *,
        CASE 
            WHEN UPPER(city) LIKE '%MILANO%' OR UPPER(city) LIKE '%TORINO%' 
                OR UPPER(city) LIKE '%GENOVA%' OR UPPER(city) LIKE '%BOLOGNA%'
                OR UPPER(city) LIKE '%VENEZIA%' OR UPPER(city) LIKE '%TRENTO%'
                OR UPPER(city) LIKE '%TRIESTE%' THEN 'Northern Italy'
            WHEN UPPER(city) LIKE '%ROMA%' OR UPPER(city) LIKE '%FIRENZE%'
                OR UPPER(city) LIKE '%PERUGIA%' OR UPPER(city) LIKE '%ANCONA%'
                OR UPPER(city) LIKE '%L''AQUILA%' THEN 'Central Italy'
            WHEN UPPER(city) LIKE '%NAPOLI%' OR UPPER(city) LIKE '%BARI%'
                OR UPPER(city) LIKE '%PALERMO%' OR UPPER(city) LIKE '%CATANZARO%'
                OR UPPER(city) LIKE '%POTENZA%' OR UPPER(city) LIKE '%CAMPOBASSO%' THEN 'Southern Italy'
            ELSE 'Other/Unknown'
        END as region_type,
        CASE 
            WHEN power_kw >= 150 THEN 'Ultra-Fast (≥150kW)'
            WHEN power_kw >= 50 THEN 'Fast (50-149kW)'
            WHEN power_kw >= 22 THEN 'Medium (22-49kW)'
            ELSE 'Slow (<22kW)'
        END as connector_power
    FROM charging_stations 
    WHERE UPPER(country_code) = 'IT' OR UPPER(country_code) = 'ITALY'
),
regional_summary AS (
    SELECT 
        region_type,
        connector_power,
        COUNT(*) as station_count,
        SUM(power_kw) as total_power,
        AVG(power_kw) as avg_power
    FROM italian_stations
    GROUP BY region_type, connector_power
),
region_totals AS (
    SELECT 
        region_type,
        SUM(station_count) as total_stations,
        SUM(total_power) as region_total_power
    FROM regional_summary
    GROUP BY region_type
)
SELECT 
    rt.region_type as country_code,
    rt.total_stations,
    ROUND(rt.region_total_power, 0) as region_total_power,
    ROUND(rt.region_total_power / rt.total_stations, 1) as avg_power_per_station,
    ROUND((rt.total_stations / 1000.0) * (rt.region_total_power / 10000.0), 2) as infrastructure_density_score,
    rs.connector_power as power_category,
    rs.station_count,
    ROUND(rs.total_power, 0) as category_total_power,
    ROUND(rs.avg_power, 1) as category_avg_power
FROM region_totals rt
JOIN regional_summary rs ON rt.region_type = rs.region_type
ORDER BY rt.total_stations DESC, rs.connector_power;