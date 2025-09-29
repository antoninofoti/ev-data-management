-- Italian Brand Loyalty Analysis - Stellantis vs Foreign Brands
-- Analyzes brand preferences and market positioning in Italian EV market
-- NOTE: Some Italian makes lack base_msrp or electric_range in the dataset. This query
-- implements a fallback that includes brands by registration counts when price/range
-- is not available so that Italian brands (e.g., Fiat) are represented in the summary.

WITH
-- Primary path: compute aggregates for makes where price and range are available
italian_preferences AS (
    SELECT 
        make,
        COUNT(*) as model_count,
        AVG(NULLIF(base_msrp,0)) as avg_price,
        AVG(NULLIF(electric_range,0)) as avg_range,
        CASE 
            WHEN UPPER(make) IN ('FIAT', 'ALFA ROMEO', 'MASERATI', 'LANCIA', 'ABARTH') THEN 'Italian (Stellantis)'
            WHEN UPPER(make) IN ('VOLKSWAGEN', 'BMW', 'MERCEDES-BENZ', 'AUDI', 'PORSCHE', 'SMART', 'OPEL') THEN 'German Premium'
            WHEN UPPER(make) IN ('RENAULT', 'PEUGEOT', 'CITROEN', 'CITROËN', 'DS', 'ALPINE') THEN 'French'
            WHEN UPPER(make) IN ('TESLA', 'FORD', 'CHEVROLET', 'RIVIAN', 'LUCID', 'FISKER') THEN 'American'
            WHEN UPPER(make) IN ('NISSAN', 'TOYOTA', 'HONDA', 'KIA', 'HYUNDAI', 'MAZDA') THEN 'Asian'
            WHEN UPPER(make) IN ('VOLVO', 'POLESTAR', 'JAGUAR', 'MINI') THEN 'Nordic/British'
            WHEN UPPER(make) IN ('BYD', 'NIO', 'MG', 'XPENG') THEN 'Chinese'
            ELSE 'Other'
        END as brand_origin,
        CASE 
            WHEN AVG(NULLIF(base_msrp,0)) < 25000 THEN 'Budget (<€25k)'
            WHEN AVG(NULLIF(base_msrp,0)) < 40000 THEN 'Mass Market (€25k-€40k)'
            WHEN AVG(NULLIF(base_msrp,0)) < 60000 THEN 'Premium (€40k-€60k)'
            ELSE 'Luxury (€60k+)'
        END as price_category
    FROM ev_population 
    WHERE base_msrp IS NOT NULL
        AND base_msrp <> 0
        AND electric_range IS NOT NULL
        AND electric_range <> 0
    GROUP BY make 
    HAVING COUNT(*) >= 3
),
-- Fallback path: include brands by registrations even if price/range are missing
italian_preferences_fallback AS (
    SELECT
        make,
        COUNT(*) as model_count,
        NULL::numeric as avg_price,
        NULL::numeric as avg_range,
        CASE WHEN UPPER(make) IN ('FIAT', 'ALFA ROMEO', 'MASERATI', 'LANCIA', 'ABARTH') THEN 'Italian (Stellantis)'
             WHEN UPPER(make) IN ('VOLKSWAGEN', 'BMW', 'MERCEDES-BENZ', 'AUDI', 'PORSCHE', 'SMART', 'OPEL') THEN 'German Premium'
             WHEN UPPER(make) IN ('RENAULT', 'PEUGEOT', 'CITROEN', 'CITROËN', 'DS', 'ALPINE') THEN 'French'
             WHEN UPPER(make) IN ('TESLA', 'FORD', 'CHEVROLET', 'RIVIAN', 'LUCID', 'FISKER') THEN 'American'
             WHEN UPPER(make) IN ('NISSAN', 'TOYOTA', 'HONDA', 'KIA', 'HYUNDAI', 'MAZDA') THEN 'Asian'
             WHEN UPPER(make) IN ('VOLVO', 'POLESTAR', 'JAGUAR', 'MINI') THEN 'Nordic/British'
             WHEN UPPER(make) IN ('BYD', 'NIO', 'MG', 'XPENG') THEN 'Chinese'
             ELSE 'Other' END as brand_origin,
        'Unknown' as price_category
    FROM ev_population
    GROUP BY make
    HAVING COUNT(*) >= 10
),
-- combine primary and fallback (primary preferred)
italian_preferences_combined AS (
    SELECT * FROM italian_preferences
    UNION ALL
    SELECT * FROM italian_preferences_fallback ipf
    WHERE ipf.make NOT IN (SELECT make FROM italian_preferences)
),
brand_summary AS (
    SELECT 
        brand_origin,
        price_category,
        SUM(model_count) as model_count,
        SUM(model_count) as total_sales,
        AVG(avg_price) as avg_price,
        AVG(avg_range) as avg_range,
        COUNT(DISTINCT make) as unique_brands
    FROM italian_preferences_combined
    GROUP BY brand_origin, price_category
),
origin_totals AS (
    SELECT 
        brand_origin,
        SUM(model_count) as total_models,
        SUM(total_sales) as total_brand_sales,
        SUM(unique_brands) as brand_count
    FROM brand_summary
    GROUP BY brand_origin
),
market_totals AS (
    SELECT SUM(total_brand_sales) as total_market_sales
    FROM origin_totals
)
SELECT 
    ot.brand_origin,
    ot.total_models,
    ot.total_brand_sales,
    ROUND((ot.total_brand_sales * 100.0 / mt.total_market_sales), 2) as market_share_percent,
    ot.brand_count as unique_brands,
    ROUND(ot.total_models::NUMERIC / NULLIF(ot.brand_count, 0), 1) as avg_models_per_brand,
    CASE 
        WHEN ot.brand_origin = 'Italian (Stellantis)' THEN 'Home Market'
        WHEN (ot.total_brand_sales * 100.0 / mt.total_market_sales) > 20 THEN 'Strong Competitor'
        WHEN (ot.total_brand_sales * 100.0 / mt.total_market_sales) > 10 THEN 'Moderate Competitor'
        ELSE 'Niche Player'
    END as italian_competitiveness,
    bs.price_category,
    bs.model_count as segment_models,
    bs.total_sales as segment_sales,
    ROUND(bs.avg_price, 0) as segment_avg_price,
    ROUND(bs.avg_range, 0) as segment_avg_range
FROM origin_totals ot
CROSS JOIN market_totals mt
LEFT JOIN brand_summary bs ON ot.brand_origin = bs.brand_origin
ORDER BY ot.total_brand_sales DESC, bs.price_category;