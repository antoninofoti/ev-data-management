-- Q4.2 - Brand Performance by Region
-- Business Question: "How do different brands perform across regions?"

WITH brand_regional_performance AS (
    SELECT 
        make as brand,
        state,
        COUNT(DISTINCT model) as model_count,
        COUNT(*) as total_sales,
        AVG(base_msrp) as avg_price,
        AVG(electric_range) as avg_range,
        COUNT(*) as market_entries
    FROM ev_population
    WHERE model_year >= 2020
        AND state IS NOT NULL
    GROUP BY make, state
    HAVING COUNT(*) >= 10
),

regional_totals AS (
    SELECT 
        state,
        SUM(total_sales) as region_total_sales
    FROM brand_regional_performance
    GROUP BY state
),

performance_analysis AS (
    SELECT 
        b.brand,
        b.state,
        b.model_count,
        b.total_sales,
        ROUND(b.avg_price, 0) as avg_price,
        ROUND(b.avg_range, 0) as avg_range,
        ROUND(b.total_sales * 100.0 / r.region_total_sales, 2) as regional_market_share,
        RANK() OVER (PARTITION BY b.state ORDER BY b.total_sales DESC) as regional_rank
    FROM brand_regional_performance b
    JOIN regional_totals r ON b.state = r.state
)

SELECT 
    brand,
    state,
    model_count,
    total_sales,
    avg_price,
    avg_range,
    regional_market_share,
    regional_rank
FROM performance_analysis
WHERE regional_rank <= 5  -- Top 5 brands per state
ORDER BY state, regional_rank;