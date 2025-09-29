-- Q5.2 - Highway Charging Corridors
-- Business Question: "Which highways have the best charging infrastructure coverage?"

WITH highway_analysis AS (
    SELECT 
        country_code,
        city,
        COUNT(*) as stations_in_area,
        COUNT(CASE WHEN power_kw >= 150 THEN 1 END) as fast_stations,
        AVG(power_kw) as avg_power,
        SUM(ports) as total_ports,
        COUNT(DISTINCT city) as operators
    FROM charging_stations
    WHERE country_code IS NOT NULL
        AND city IS NOT NULL
        AND power_kw >= 50  -- Highway-appropriate charging
    GROUP BY country_code, city
    HAVING COUNT(*) >= 3  -- Minimum corridor presence
),

corridor_ranking AS (
    SELECT 
        *,
        ROUND(fast_stations * 100.0 / stations_in_area, 1) as fast_charging_percentage,
        ROUND(CASE WHEN total_ports IS NULL OR total_ports = 0 THEN NULL ELSE total_ports END / stations_in_area, 1) as avg_ports_per_station,
        (stations_in_area * fast_stations) as corridor_score
    FROM highway_analysis
)

SELECT 
    country_code,
    city as corridor_area,
    stations_in_area,
    fast_stations,
    fast_charging_percentage,
    total_ports,
    avg_ports_per_station,
    operators,
    corridor_score,
    RANK() OVER (ORDER BY corridor_score DESC) as corridor_rank
FROM corridor_ranking
ORDER BY corridor_score DESC
LIMIT 20;