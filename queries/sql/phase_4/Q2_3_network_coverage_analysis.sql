-- Q2.3 - Charging Network Coverage Analysis
-- Business Question: "What is the geographic coverage of major charging networks?"

WITH network_analysis AS (
    SELECT 
        city as network_name,
        COUNT(*) as total_stations,
        COUNT(DISTINCT country_code) as countries_covered,
        AVG(power_kw) as avg_power_kw,
        COUNT(CASE WHEN power_kw >= 150 THEN 1 END) as ultra_fast_stations,
        COUNT(CASE WHEN power_kw >= 50 THEN 1 END) as fast_stations
    FROM charging_stations
    WHERE city IS NOT NULL
        AND power_kw > 0
    GROUP BY city
    HAVING COUNT(*) >= 10  -- Only networks with significant presence
),

coverage_scores AS (
    SELECT 
        *,
        (countries_covered * total_stations / 100.0) as coverage_score,
        ROUND(ultra_fast_stations * 100.0 / total_stations, 1) as ultra_fast_percentage
    FROM network_analysis
)

SELECT 
    network_name,
    total_stations,
    countries_covered,
    ROUND(avg_power_kw, 1) as avg_power_kw,
    ultra_fast_stations,
    ultra_fast_percentage,
    ROUND(coverage_score, 1) as coverage_score,
    RANK() OVER (ORDER BY coverage_score DESC) as coverage_rank
FROM coverage_scores
ORDER BY coverage_score DESC
LIMIT 20;