-- Q6.1 - Optimal Station Placement
-- Business Question: "Where should new charging stations be placed for optimal coverage?"

WITH geographic_analysis AS (
    SELECT 
        country_code,
        ROUND(latitude, 1) as lat_grid,
        ROUND(longitude, 1) as lon_grid,
        COUNT(*) as existing_stations,
        AVG(power_kw) as avg_power,
        SUM(ports) as total_ports,
        COUNT(DISTINCT city) as operators_present
    FROM charging_stations
    WHERE latitude IS NOT NULL 
        AND longitude IS NOT NULL
        AND power_kw > 0
    GROUP BY country_code, ROUND(latitude, 1), ROUND(longitude, 1)
    HAVING COUNT(*) >= 1
),

coverage_gaps AS (
    SELECT 
        country_code,
        lat_grid,
        lon_grid,
        existing_stations,
        total_ports,
        ROUND(avg_power, 1) as avg_power_kw,
        operators_present,
        CASE 
            WHEN existing_stations >= 10 THEN 'Saturated'
            WHEN existing_stations >= 5 THEN 'Well Covered'
            WHEN existing_stations >= 2 THEN 'Moderate Coverage'
            ELSE 'Gap Area'
        END as coverage_level,
        CASE 
            WHEN existing_stations < 3 AND avg_power < 100 THEN 'High Priority'
            WHEN existing_stations < 5 AND avg_power < 150 THEN 'Medium Priority'
            ELSE 'Low Priority'
        END as placement_priority
    FROM geographic_analysis
),

optimal_locations AS (
    SELECT 
        *,
        -- Simple scoring based on coverage gaps and infrastructure needs
        CASE 
            WHEN placement_priority = 'High Priority' THEN 100
            WHEN placement_priority = 'Medium Priority' THEN 50
            ELSE 10
        END as placement_score,
        RANK() OVER (PARTITION BY country_code ORDER BY 
            CASE 
                WHEN placement_priority = 'High Priority' THEN 100
                WHEN placement_priority = 'Medium Priority' THEN 50
                ELSE 10
            END DESC, existing_stations ASC
        ) as priority_rank
    FROM coverage_gaps
)

SELECT 
    country_code,
    lat_grid as latitude,
    lon_grid as longitude,
    existing_stations,
    total_ports,
    avg_power_kw,
    operators_present,
    coverage_level,
    placement_priority,
    placement_score,
    priority_rank
FROM optimal_locations
WHERE placement_priority IN ('High Priority', 'Medium Priority')
ORDER BY country_code, placement_score DESC, priority_rank
LIMIT 25;