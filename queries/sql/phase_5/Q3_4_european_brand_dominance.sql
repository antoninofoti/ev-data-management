-- European Brand Dominance Analysis - Cross-Country Market Performance
-- Analyzes how European brands perform in home markets vs foreign markets

WITH european_brand_classification AS (
    SELECT 
        make,
        state,
        COUNT(*) as registrations,
        AVG(base_msrp) as avg_price,
        AVG(electric_range) as avg_range,
        CASE 
            -- German brands
            WHEN UPPER(make) IN ('BMW', 'MERCEDES-BENZ', 'VOLKSWAGEN', 'AUDI', 'PORSCHE', 'SMART', 'OPEL') THEN 'German'
            -- French brands
            WHEN UPPER(make) IN ('RENAULT', 'PEUGEOT', 'CITROËN', 'CITROEN', 'DS', 'DS AUTOMOBILES', 'ALPINE') THEN 'French'
            -- Italian brands
            WHEN UPPER(make) IN ('FIAT', 'ALFA ROMEO', 'MASERATI', 'LANCIA', 'FERRARI') THEN 'Italian'
            -- Swedish brands
            WHEN UPPER(make) IN ('VOLVO', 'POLESTAR') THEN 'Swedish'
            -- British brands
            WHEN UPPER(make) IN ('JAGUAR', 'LAND ROVER', 'MINI', 'ASTON MARTIN', 'BENTLEY', 'ROLLS-ROYCE') THEN 'British'
            ELSE NULL  -- Filter out non-European brands
        END as brand_origin,
        CASE 
            WHEN AVG(base_msrp) < 30000 THEN 'Entry Level (<€30k)'
            WHEN AVG(base_msrp) < 50000 THEN 'Mid-Market (€30k-€50k)'
            WHEN AVG(base_msrp) < 80000 THEN 'Premium (€50k-€80k)'
            ELSE 'Luxury (€80k+)'
        END as price_tier
    FROM ev_population 
    WHERE base_msrp > 0
        AND electric_range > 0
    GROUP BY make, state
    HAVING COUNT(*) >= 5  -- Minimum presence
),
-- Filter to only European brands
european_brands_only AS (
    SELECT *
    FROM european_brand_classification
    WHERE brand_origin IS NOT NULL
),
-- Aggregate by brand origin
brand_performance AS (
    SELECT 
        brand_origin,
        COUNT(DISTINCT make) as unique_brands,
        COUNT(DISTINCT state) as markets_present,
        SUM(registrations) as total_registrations,
        AVG(avg_price) as overall_avg_price,
        AVG(avg_range) as overall_avg_range,
        COUNT(DISTINCT price_tier) as price_tiers_covered
    FROM european_brands_only
    GROUP BY brand_origin
),
-- Get totals for market share calculation
market_totals AS (
    SELECT SUM(total_registrations) as total_european_brand_sales
    FROM brand_performance
),
-- Analyze price tier distribution
price_tier_distribution AS (
    SELECT 
        brand_origin,
        price_tier,
        COUNT(DISTINCT make) as brands_in_tier,
        SUM(registrations) as tier_registrations,
        AVG(avg_price) as tier_avg_price,
        AVG(avg_range) as tier_avg_range
    FROM european_brands_only
    GROUP BY brand_origin, price_tier
)

SELECT 
    bp.brand_origin,
    bp.unique_brands,
    bp.markets_present,
    bp.total_registrations,
    ROUND((bp.total_registrations * 100.0 / mt.total_european_brand_sales), 2) as market_share_percent,
    ROUND(bp.overall_avg_price, 0) as avg_price_eur,
    ROUND(bp.overall_avg_range, 0) as avg_range_km,
    bp.price_tiers_covered,
    CASE bp.brand_origin
        WHEN 'German' THEN 'Premium & Luxury Focus'
        WHEN 'French' THEN 'Mass Market & Affordable'
        WHEN 'Italian' THEN 'Style & Performance'
        WHEN 'Swedish' THEN 'Safety & Premium'
        WHEN 'British' THEN 'Luxury & Heritage'
    END as brand_positioning,
    -- Top performing price tier
    (SELECT ptd.price_tier 
     FROM price_tier_distribution ptd 
     WHERE ptd.brand_origin = bp.brand_origin 
     ORDER BY ptd.tier_registrations DESC 
     LIMIT 1) as dominant_price_tier,
    -- Registrations in dominant tier
    (SELECT ptd.tier_registrations 
     FROM price_tier_distribution ptd 
     WHERE ptd.brand_origin = bp.brand_origin 
     ORDER BY ptd.tier_registrations DESC 
     LIMIT 1) as dominant_tier_sales
FROM brand_performance bp
CROSS JOIN market_totals mt
ORDER BY bp.total_registrations DESC;