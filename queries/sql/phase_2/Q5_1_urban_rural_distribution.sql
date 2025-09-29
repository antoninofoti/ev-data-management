-- Q5.1 - Urban vs Rural EV Distribution Analysis
-- Business Question: "What is the distribution of EVs between urban and rural areas?"

WITH regional_ev_distribution AS (
    SELECT 
        state as area_name,
        'US' as country_code,  -- our data is US-focused
        COUNT(*) as total_ev_count,
        COUNT(DISTINCT make) as distinct_makes,
        CASE
            WHEN COUNT(*) >= 5000 THEN 'Urban'
            WHEN COUNT(*) >= 500 THEN 'Suburban'
            ELSE 'Rural'
        END as area_type
    FROM ev_population
    WHERE state IS NOT NULL 
        AND state != ''
        AND make IS NOT NULL
    GROUP BY state
),

area_type_summary AS (
    SELECT
        area_type,
        COUNT(*) as areas_count,
        SUM(total_ev_count) as total_evs,
        AVG(total_ev_count) as avg_evs_per_area,
        MAX(total_ev_count) as max_evs_per_area,
        MIN(total_ev_count) as min_evs_per_area
    FROM regional_ev_distribution
    GROUP BY area_type
)

SELECT 
    area_type,
    areas_count,
    total_evs,
    ROUND(avg_evs_per_area, 1) as avg_evs_per_area,
    max_evs_per_area,
    min_evs_per_area,
    ROUND(total_evs * 100.0 / SUM(total_evs) OVER(), 1) as percentage_of_total
FROM area_type_summary
ORDER BY total_evs DESC;