-- Q4.4 - Price Evolution Analysis
-- Business Question: "How have EV prices evolved over time across different segments?"

WITH price_segments AS (
    SELECT 
        state,
        model_year,
        make,
        model,
        base_msrp,
        electric_range,
        CASE 
            WHEN base_msrp < 30000 THEN 'Budget'
            WHEN base_msrp < 50000 THEN 'Mid-Range'
            WHEN base_msrp < 80000 THEN 'Premium'
            ELSE 'Luxury'
        END as price_segment,
        CASE 
            WHEN electric_range < 200 THEN 'Short Range'
            WHEN electric_range < 350 THEN 'Medium Range'
            ELSE 'Long Range'
        END as range_segment
    FROM ev_population
    WHERE model_year >= 2020 
        AND base_msrp > 0
        AND electric_range > 0
),

segment_evolution AS (
    SELECT 
        model_year,
        price_segment,
        COUNT(*) as models_in_segment,
        AVG(base_msrp) as avg_price,
        MIN(base_msrp) as min_price,
        MAX(base_msrp) as max_price,
        AVG(electric_range) as avg_range,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY base_msrp) as median_price
    FROM price_segments
    GROUP BY model_year, price_segment
),

price_trends AS (
    SELECT 
        *,
        LAG(avg_price) OVER (PARTITION BY price_segment ORDER BY model_year) as prev_year_price,
        CASE 
            WHEN LAG(avg_price) OVER (PARTITION BY price_segment ORDER BY model_year) IS NULL THEN 0
            WHEN LAG(avg_price) OVER (PARTITION BY price_segment ORDER BY model_year) = 0 THEN 0
            ELSE ROUND(
                ((avg_price - LAG(avg_price) OVER (PARTITION BY price_segment ORDER BY model_year)) 
                / LAG(avg_price) OVER (PARTITION BY price_segment ORDER BY model_year) * 100)::NUMERIC, 1
            )
        END as price_change_pct
    FROM segment_evolution
)

SELECT 
    model_year,
    price_segment,
    models_in_segment,
    ROUND(avg_price::NUMERIC, 0) as avg_price,
    ROUND(min_price::NUMERIC, 0) as min_price,
    ROUND(max_price::NUMERIC, 0) as max_price,
    ROUND(median_price::NUMERIC, 0) as median_price,
    ROUND(avg_range::NUMERIC, 0) as avg_range,
    COALESCE(price_change_pct, 0) as price_change_pct,
    CASE 
        WHEN price_change_pct > 10 THEN 'Price Increase'
        WHEN price_change_pct < -10 THEN 'Price Decrease'
        ELSE 'Stable'
    END as price_trend
FROM price_trends
ORDER BY model_year, price_segment;