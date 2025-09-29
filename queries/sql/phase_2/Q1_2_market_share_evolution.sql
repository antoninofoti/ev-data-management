-- Q1.2 - BEV/PHEV Market Share Evolution
-- Business Question: "How has BEV vs PHEV market share evolved over time?"

WITH yearly_powertrain_sales AS (
    SELECT 
        model_year as year,
        electric_vehicle_type as powertrain_type,
        COUNT(*) as total_registrations,
        COUNT(DISTINCT make) as manufacturer_count,
        AVG(CASE WHEN base_msrp > 0 THEN base_msrp ELSE NULL END) as avg_price,
        AVG(CASE WHEN electric_range > 0 THEN electric_range ELSE NULL END) as avg_range
    FROM ev_population
    WHERE model_year BETWEEN 2020 AND 2024
        AND electric_vehicle_type IN ('Battery Electric Vehicle (BEV)', 'Plug-in Hybrid Electric Vehicle (PHEV)')
    GROUP BY model_year, electric_vehicle_type
),

market_totals AS (
    SELECT 
        year,
        SUM(total_registrations) as year_total
    FROM yearly_powertrain_sales
    GROUP BY year
),

market_share_evolution AS (
    SELECT 
        y.year,
        CASE 
            WHEN y.powertrain_type = 'Battery Electric Vehicle (BEV)' THEN 'BEV'
            WHEN y.powertrain_type = 'Plug-in Hybrid Electric Vehicle (PHEV)' THEN 'PHEV'
            ELSE y.powertrain_type
        END as powertrain,
        y.total_registrations,
        y.manufacturer_count,
        ROUND(COALESCE(y.avg_price, 0), 0) as avg_price,
        ROUND(COALESCE(y.avg_range, 0), 0) as avg_range,
        ROUND(y.total_registrations * 100.0 / m.year_total, 2) as market_share_pct
    FROM yearly_powertrain_sales y
    JOIN market_totals m ON y.year = m.year
)

SELECT 
    year,
    powertrain,
    total_registrations,
    manufacturer_count,
    avg_price,
    avg_range,
    market_share_pct,
    LAG(market_share_pct) OVER (PARTITION BY powertrain ORDER BY year) as prev_year_share,
    ROUND(
        (market_share_pct - LAG(market_share_pct) OVER (PARTITION BY powertrain ORDER BY year))::NUMERIC, 2
    ) as share_change_pct
FROM market_share_evolution
ORDER BY year DESC, powertrain;
