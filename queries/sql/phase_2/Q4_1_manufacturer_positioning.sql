-- Q4.1 - Manufacturer Positioning
-- Business Question: "How are manufacturers positioned in different market segments?"

WITH manufacturer_portfolio AS (
    SELECT 
        make as manufacturer,
        COUNT(DISTINCT model) as total_models,
        COUNT(*) as total_sales,
        AVG(CASE WHEN base_msrp::NUMERIC > 0 THEN base_msrp::NUMERIC ELSE NULL END) as avg_price,
        AVG(CASE WHEN electric_range::NUMERIC > 0 THEN electric_range::NUMERIC ELSE NULL END) as avg_range,
        MIN(CASE WHEN base_msrp::NUMERIC > 0 THEN base_msrp::NUMERIC ELSE NULL END) as min_price,
        MAX(CASE WHEN base_msrp::NUMERIC > 0 THEN base_msrp::NUMERIC ELSE NULL END) as max_price,
        COUNT(DISTINCT state) as market_presence
    FROM ev_population
    WHERE make IS NOT NULL 
        AND model IS NOT NULL 
    GROUP BY make
    HAVING COUNT(*) >= 100  -- Significant market presence
),

positioning_analysis AS (
    SELECT 
        *,
        CASE 
            WHEN avg_price < 35000 THEN 'Mass Market'
            WHEN avg_price < 60000 THEN 'Premium'
            WHEN avg_price IS NOT NULL THEN 'Luxury'
            ELSE 'Unknown'
        END as market_positioning,
        CASE 
            WHEN avg_range < 250 THEN 'Short Range Focus'
            WHEN avg_range < 350 THEN 'Balanced Range'
            WHEN avg_range IS NOT NULL THEN 'Long Range Focus'
            ELSE 'Unknown'
        END as range_strategy,
        ROUND(COALESCE(max_price - min_price, 0), 0) as price_spread,
        ROUND(COALESCE(total_sales * COALESCE(avg_range, 250) / COALESCE(avg_price, 50000), 0), 0) as value_score
    FROM manufacturer_portfolio
)

SELECT 
    manufacturer,
    total_models,
    total_sales,
    market_presence,
    ROUND(COALESCE(avg_price, 0), 0) as avg_price,
    ROUND(COALESCE(avg_range, 0), 0) as avg_range,
    market_positioning,
    range_strategy,
    price_spread,
    value_score,
    RANK() OVER (ORDER BY total_sales DESC) as sales_rank,
    RANK() OVER (ORDER BY value_score DESC) as value_rank
FROM positioning_analysis
ORDER BY total_sales DESC;