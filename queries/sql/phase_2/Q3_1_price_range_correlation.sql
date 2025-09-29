-- Q3.1 - Price Range Correlation
-- Business Question: "What is the correlation between EV price and electric range?"

WITH price_range_analysis AS (
    SELECT 
        make,
        model,
        base_msrp::NUMERIC as price,
        electric_range::NUMERIC as range_miles,
        CASE 
            WHEN base_msrp::NUMERIC < 30000 THEN 'Budget (<$30k)'
            WHEN base_msrp::NUMERIC < 50000 THEN 'Mid-Range ($30k-$50k)'
            WHEN base_msrp::NUMERIC < 80000 THEN 'Premium ($50k-$80k)'
            ELSE 'Luxury ($80k+)'
        END as price_segment,
        CASE 
            WHEN electric_range::NUMERIC < 200 THEN 'Short (<200mi)'
            WHEN electric_range::NUMERIC < 300 THEN 'Medium (200-300mi)'
            WHEN electric_range::NUMERIC < 400 THEN 'Long (300-400mi)'
            ELSE 'Extended (400mi+)'
        END as range_segment
    FROM ev_population
    WHERE base_msrp::NUMERIC > 0 
        AND electric_range::NUMERIC > 0
        AND make IS NOT NULL
        AND model IS NOT NULL
),

segment_statistics AS (
    SELECT 
        price_segment,
        range_segment,
        COUNT(*) as model_count,
        COUNT(*) as total_sales,
        AVG(price) as avg_price,
        AVG(range_miles) as avg_range,
        MIN(price) as min_price,
        MAX(price) as max_price,
        ROUND(AVG(price) / NULLIF(AVG(range_miles), 0), 2) as price_per_mile
    FROM price_range_analysis
    GROUP BY price_segment, range_segment
)

SELECT 
    price_segment,
    range_segment,
    model_count,
    total_sales,
    ROUND(avg_price::NUMERIC, 0) as avg_price,
    ROUND(avg_range::NUMERIC, 0) as avg_range,
    min_price::INTEGER as min_price,
    max_price::INTEGER as max_price,
    price_per_mile,
    ROUND(total_sales * 100.0 / SUM(total_sales) OVER(), 1) as market_share_pct
FROM segment_statistics
ORDER BY 
    CASE price_segment 
        WHEN 'Budget (<$30k)' THEN 1
        WHEN 'Mid-Range ($30k-$50k)' THEN 2  
        WHEN 'Premium ($50k-$80k)' THEN 3
        ELSE 4 
    END,
    CASE range_segment
        WHEN 'Short (<200mi)' THEN 1
        WHEN 'Medium (200-300mi)' THEN 2
        WHEN 'Long (300-400mi)' THEN 3
        ELSE 4
    END;