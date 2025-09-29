-- Italian Price Preferences Analysis
-- Analyzes price sensitivity and preferences in the Italian EV market

WITH italian_market_analysis AS (
    SELECT 
        *,
        CASE 
            WHEN base_msrp < 20000 THEN 'Ultra Budget (<€20k)'
            WHEN base_msrp < 30000 THEN 'Budget (€20k-€30k)'
            WHEN base_msrp < 45000 THEN 'Mass Market (€30k-€45k)'
            WHEN base_msrp < 65000 THEN 'Premium (€45k-€65k)'
            ELSE 'Luxury (€65k+)'
        END as price_segment_eur,
        CASE 
            WHEN base_msrp < 35000 AND electric_range >= 250 THEN 'Italian Sweet Spot'
            WHEN base_msrp < 25000 AND electric_range >= 200 THEN 'Budget Conscious'
            WHEN base_msrp >= 50000 AND electric_range >= 400 THEN 'Premium Performance'
            ELSE 'Standard Market'
        END as italian_preference_category,
        electric_range / base_msrp as value_ratio
    FROM ev_population 
    WHERE base_msrp > 0
),
segment_analysis AS (
    SELECT 
        price_segment_eur,
        italian_preference_category,
        COUNT(*) as model_count,
        COUNT(*) as total_sales,
        AVG(base_msrp) as avg_price,
        AVG(electric_range) as avg_range,
        AVG(value_ratio) as avg_value_ratio,
        MIN(base_msrp) as min_price,
        MAX(base_msrp) as max_price
    FROM italian_market_analysis
    GROUP BY price_segment_eur, italian_preference_category
),
market_totals AS (
    SELECT SUM(total_sales) as total_market_sales
    FROM segment_analysis
)
SELECT 
    sa.price_segment_eur as price_segment,
    sa.italian_preference_category as preference_category,
    sa.model_count,
    sa.total_sales,
    ROUND((sa.total_sales * 100.0 / mt.total_market_sales), 2) as market_penetration_percent,
    ROUND(sa.avg_price, 0) as avg_price_eur,
    ROUND(sa.avg_range * 1.609, 0) as avg_range_km,
    ROUND(sa.avg_value_ratio * 1.609, 4) as value_ratio_km_per_eur,
    CASE 
        WHEN sa.italian_preference_category = 'Italian Sweet Spot' THEN 10
        WHEN sa.italian_preference_category = 'Budget Conscious' THEN 8
        WHEN sa.avg_value_ratio >= 0.008 AND sa.avg_price < 40000 THEN 7
        ELSE 5
    END as italian_appeal_score,
    ROUND(sa.min_price, 0) as min_price_eur,
    ROUND(sa.max_price, 0) as max_price_eur
FROM segment_analysis sa
CROSS JOIN market_totals mt
ORDER BY sa.total_sales DESC;