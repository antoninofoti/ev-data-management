-- Q2.1 - Infrastructure Density
-- Business Question: "What is the charging infrastructure density by state?"

WITH country_infrastructure AS (
    SELECT 
        country_code,
        COUNT(*) as total_stations,
        COUNT(CASE WHEN power_kw >= 150 THEN 1 END) as ultra_fast_stations,
        COUNT(CASE WHEN power_kw >= 50 THEN 1 END) as fast_stations,
        AVG(power_kw) as avg_power_kw,
        COUNT(DISTINCT city) as unique_locations
    FROM charging_stations
    WHERE country_code IS NOT NULL
        AND power_kw IS NOT NULL
        AND power_kw > 0
    GROUP BY country_code
    HAVING COUNT(*) >= 10  -- Countries with meaningful infrastructure
),

density_analysis AS (
    SELECT 
        *,
        ROUND(ultra_fast_stations * 100.0 / NULLIF(total_stations, 0), 1) as ultra_fast_pct,
        ROUND(fast_stations * 100.0 / NULLIF(total_stations, 0), 1) as fast_pct,
        CASE
            WHEN total_stations >= 1000 THEN 'High Density'
            WHEN total_stations >= 100 THEN 'Medium Density'
            ELSE 'Low Density'
        END as density_category
    FROM country_infrastructure
)

SELECT 
    country_code,
    total_stations,
    ultra_fast_stations,
    ultra_fast_pct,
    fast_pct,
    unique_locations,
    density_category,
    ROUND(avg_power_kw, 1) as avg_power_kw
FROM density_analysis
ORDER BY total_stations DESC;