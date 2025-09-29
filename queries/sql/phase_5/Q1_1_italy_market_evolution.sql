-- Q1_1: Italian EV Market Evolution vs European Average
-- Analyzes Italy's EV adoption trajectory compared to Europe overall

WITH italy_europe_data AS (
    SELECT 
        region as state,
        year,
        parameter,
        powertrain,
        SUM(value) as total_value
    FROM ev_sales 
    WHERE region IN ('Italy', 'Europe')
        AND parameter IN ('EV sales', 'EV stock', 'EV sales share')
        AND mode = 'Cars'
        AND year >= 2015
        AND year <= 2023  -- Use available data
    GROUP BY region, year, parameter, powertrain
),

aggregated_data AS (
    SELECT 
        state,
        year,
        parameter,
        SUM(total_value) as ev_total,
        SUM(CASE WHEN powertrain = 'BEV' THEN total_value ELSE 0 END) as bev_value,
        SUM(CASE WHEN powertrain = 'PHEV' THEN total_value ELSE 0 END) as phev_value
    FROM italy_europe_data
    GROUP BY state, year, parameter
)

-- Italian vs European Performance Summary  
SELECT 
    state,
    year,
    
    -- EV Sales Performance
    ROUND(MAX(CASE WHEN parameter = 'EV sales' THEN ev_total ELSE 0 END), 0) as ev_sales_units,
    ROUND(MAX(CASE WHEN parameter = 'EV sales' THEN bev_value ELSE 0 END), 0) as bev_sales_units,
    ROUND(MAX(CASE WHEN parameter = 'EV sales' THEN phev_value ELSE 0 END), 0) as phev_sales_units,
    
    -- Market Share Performance
    ROUND(MAX(CASE WHEN parameter = 'EV sales share' THEN ev_total ELSE 0 END), 2) as ev_market_share_percent,
    
    -- EV Stock (Fleet Size)
    ROUND(MAX(CASE WHEN parameter = 'EV stock' THEN ev_total ELSE 0 END), 0) as ev_stock_units,
    
    -- Technology Mix Analysis
    CASE 
        WHEN MAX(CASE WHEN parameter = 'EV sales' THEN ev_total ELSE 0 END) > 0 THEN
            ROUND((MAX(CASE WHEN parameter = 'EV sales' THEN bev_value ELSE 0 END) / 
                   MAX(CASE WHEN parameter = 'EV sales' THEN ev_total ELSE 0 END) * 100), 1)
        ELSE 0
    END as bev_share_percent,
    
    -- Strategic Context
    CASE 
        WHEN state = 'Italy' AND year >= 2020 THEN 'Italy Recent Performance'
        WHEN state = 'Europe' AND year >= 2020 THEN 'European Benchmark'
        WHEN state = 'Italy' THEN 'Italy Historical'
        ELSE 'European Historical'
    END as period_context,
    
    -- Growth Classification
    CASE 
        WHEN MAX(CASE WHEN parameter = 'EV sales share' THEN ev_total ELSE 0 END) > 10 THEN 'Mass Market'
        WHEN MAX(CASE WHEN parameter = 'EV sales share' THEN ev_total ELSE 0 END) > 5 THEN 'Growth Stage'
        WHEN MAX(CASE WHEN parameter = 'EV sales share' THEN ev_total ELSE 0 END) > 1 THEN 'Early Adoption'
        ELSE 'Emerging Market'
    END as market_stage

FROM aggregated_data
WHERE year IN (2020, 2021, 2022, 2023)  -- Focus on recent years
GROUP BY state, year
ORDER BY state, year;

/*
SIMPLIFIED ITALY MARKET EVOLUTION ANALYSIS:
==========================================

PURPOSE: Italy vs Europe EV adoption comparison
SCOPE: 2020-2023 performance with technology breakdown
STRATEGIC VALUE: Italy's position relative to European average

KEY INSIGHTS PROVIDED:
• Italy vs Europe sales volume comparison
• BEV vs PHEV technology preferences
• Market share evolution over time
• Fleet size (stock) comparison
• Growth stage classification

SIMPLIFICATIONS MADE:
• Focus on recent years (2020-2023)
• Standard parameters only (sales, stock, share)
• Removed complex growth calculations
• Direct Italy vs Europe comparison
*/