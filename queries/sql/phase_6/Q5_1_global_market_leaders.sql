-- Global EV Market Leaders Analysis
-- Compares China, USA, Europe, and Italy market size, growth, and leadership

WITH global_markets AS (
    SELECT 
        region as state,
        year,
        parameter,
        powertrain,
        SUM(value) as total_value
    FROM ev_sales 
    WHERE region IN ('China', 'USA', 'Europe', 'Italy', 'World')
        AND parameter IN ('EV sales', 'EV stock', 'EV sales share')
        AND mode = 'Cars'
        AND year >= 2020
    GROUP BY region, year, parameter, powertrain
),
latest_metrics AS (
    SELECT 
        state,
        MAX(CASE WHEN parameter = 'EV sales' AND year = 2024 THEN total_value END) as ev_sales_2024,
        MAX(CASE WHEN parameter = 'EV stock' AND year = 2024 THEN total_value END) as ev_stock_2024,
        MAX(CASE WHEN parameter = 'EV sales share' AND year = 2024 THEN total_value END) as sales_share_2024,
        -- Growth calculation
        MAX(CASE WHEN parameter = 'EV sales' AND year = 2020 THEN total_value END) as ev_sales_2020,
        MAX(CASE WHEN parameter = 'EV stock' AND year = 2020 THEN total_value END) as ev_stock_2020
    FROM global_markets
    GROUP BY state
),
market_analysis AS (
    SELECT 
        state,
        COALESCE(ev_sales_2024, 0) as ev_sales_2024,
        COALESCE(ev_stock_2024, 0) as ev_stock_2024,
        COALESCE(sales_share_2024, 0) as sales_share_2024,
        -- Growth rates
        CASE 
            WHEN ev_sales_2020 > 0 AND ev_sales_2024 > 0 
            THEN ((ev_sales_2024 - ev_sales_2020) / ev_sales_2020) * 100
            ELSE 0 
        END as sales_growth_2020_2024,
        CASE 
            WHEN ev_stock_2020 > 0 AND ev_stock_2024 > 0 
            THEN ((ev_stock_2024 - ev_stock_2020) / ev_stock_2020) * 100
            ELSE 0 
        END as stock_growth_2020_2024,
        -- Population context (approximate)
        CASE state
            WHEN 'China' THEN 1400.0  -- Million people
            WHEN 'USA' THEN 330.0
            WHEN 'Europe' THEN 750.0
            WHEN 'Italy' THEN 59.1
            WHEN 'World' THEN 8000.0
            ELSE 100.0
        END as population_millions
    FROM latest_metrics
),
global_totals AS (
    SELECT 
        SUM(CASE WHEN state != 'World' THEN ev_sales_2024 ELSE 0 END) as total_global_sales,
        SUM(CASE WHEN state != 'World' THEN ev_stock_2024 ELSE 0 END) as total_global_stock
    FROM market_analysis
    WHERE state != 'World'
)
SELECT 
    ma.state,
    ROUND(ma.ev_sales_2024, 0) as ev_sales_2024,
    ROUND(ma.ev_stock_2024, 0) as ev_stock_2024,
    ROUND(ma.sales_share_2024, 2) as sales_share_2024_percent,
    
    -- Per capita metrics
    ROUND(ma.ev_stock_2024 / ma.population_millions, 0) as ev_per_1000_people,
    ROUND(ma.ev_sales_2024 / ma.population_millions, 0) as annual_sales_per_1000_people,
    
    -- Global market share
    ROUND(CASE WHEN gt.total_global_sales > 0 THEN (ma.ev_sales_2024 * 100.0 / gt.total_global_sales) ELSE 0 END, 2) as global_market_share_percent,
    ROUND(CASE WHEN gt.total_global_stock > 0 THEN (ma.ev_stock_2024 * 100.0 / gt.total_global_stock) ELSE 0 END, 2) as global_stock_share_percent,
    
    -- Growth metrics
    ROUND(ma.sales_growth_2020_2024, 1) as sales_growth_2020_2024_percent,
    ROUND(ma.stock_growth_2020_2024, 1) as stock_growth_2020_2024_percent,
    
    -- Market classification
    CASE 
        WHEN ma.state = 'China' THEN 'Global Leader'
        WHEN ma.state = 'USA' THEN 'Major Market'
        WHEN ma.state = 'Europe' THEN 'Major Regional Market'
        WHEN ma.state = 'Italy' THEN 'Developing Market'
        WHEN ma.state = 'World' THEN 'Global Total'
        ELSE 'Other'
    END as market_classification,
    
    -- Italy comparison
    CASE 
        WHEN ma.state = 'Italy' THEN 'Base Country'
        WHEN ma.ev_stock_2024 / ma.population_millions > 
             (SELECT ev_stock_2024 / population_millions FROM market_analysis WHERE state = 'Italy') 
        THEN 'Higher Per-Capita than Italy'
        ELSE 'Lower Per-Capita than Italy'
    END as italy_comparison,
    
    -- Leadership indicators
    CASE 
        WHEN ma.sales_share_2024 > 25 THEN 'EV Leader (>25% share)'
        WHEN ma.sales_share_2024 > 15 THEN 'EV Advanced (>15% share)'
        WHEN ma.sales_share_2024 > 5 THEN 'EV Developing (>5% share)'
        ELSE 'EV Emerging (<5% share)'
    END as adoption_stage

FROM market_analysis ma
CROSS JOIN global_totals gt
ORDER BY ma.ev_sales_2024 DESC;