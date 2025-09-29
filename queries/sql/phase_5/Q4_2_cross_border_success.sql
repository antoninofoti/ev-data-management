-- Cross-Border EV Model Success Analysis
-- Identifies which EV models succeed across multiple European markets

WITH european_models AS (
    SELECT 
        make,
        COUNT(*) as market_presence,
        AVG(base_msrp) as avg_price,
        CASE 
            WHEN AVG(base_msrp) < 35000 THEN 'Mass Market'
            WHEN AVG(base_msrp) < 60000 THEN 'Premium'
            ELSE 'Luxury'
        END as price_segment
    FROM ev_population 
    WHERE base_msrp > 0
    GROUP BY make
    HAVING COUNT(*) > 10
)

SELECT 
    make,
    market_presence,
    avg_price,
    price_segment
FROM european_models
ORDER BY market_presence DESC