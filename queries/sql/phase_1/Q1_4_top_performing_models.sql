-- Q1.4 - Top Performing Models
-- Business Question: "Which EV models have the highest sales performance?"

WITH model_performance AS (
    SELECT 
        make,
        model,
        COUNT(*) as market_presence,
        AVG(CASE WHEN base_msrp::NUMERIC > 0 THEN base_msrp::NUMERIC ELSE NULL END) as avg_price,
        AVG(CASE WHEN electric_range::NUMERIC > 0 THEN electric_range::NUMERIC ELSE NULL END) as avg_range,
        COUNT(*) as total_registrations,
        COUNT(DISTINCT state) as markets_present
    FROM ev_population
    WHERE model_year >= 2020
        AND make IS NOT NULL 
        AND model IS NOT NULL
        AND make != ''
        AND model != ''
    GROUP BY make, model
    HAVING COUNT(*) >= 100  -- Only models with significant registrations
),

performance_ranking AS (
    SELECT 
        *,
        ROUND((total_registrations * markets_present * 
               COALESCE(avg_range, 250) / 
               GREATEST(COALESCE(avg_price, 50000), 30000) * 100)::NUMERIC, 2) as performance_score,
        RANK() OVER (ORDER BY total_registrations DESC) as sales_rank,
        RANK() OVER (ORDER BY markets_present DESC) as market_reach_rank
    FROM model_performance
)

SELECT 
    make,
    model,
    total_registrations,
    avg_price::INTEGER as avg_price,
    avg_range::INTEGER as avg_range,
    markets_present,
    performance_score,
    sales_rank,
    market_reach_rank
FROM performance_ranking
ORDER BY performance_score DESC, total_registrations DESC
LIMIT 10;