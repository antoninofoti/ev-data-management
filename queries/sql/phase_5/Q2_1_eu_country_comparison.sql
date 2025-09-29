-- Q2_1: EU Country Comparison
-- Compare Italy against major European countries

WITH eu_countries AS (
    SELECT 
        region as state,
        year,
        parameter,
        powertrain,
        SUM(value) as total_value
    FROM ev_sales 
    WHERE region IN ('Italy', 'Germany', 'France', 'Spain', 'Netherlands', 'Norway', 'Europe')
        AND parameter IN ('EV sales', 'EV stock', 'EV sales share')
        AND mode = 'Cars'
        AND year BETWEEN 2020 AND 2023
    GROUP BY region, year, parameter, powertrain
),

country_summary AS (
    SELECT 
        state,
        year,
        -- EV Sales
        ROUND(MAX(CASE WHEN parameter = 'EV sales' THEN total_value ELSE 0 END), 0) as ev_sales,
        -- Market Share
        ROUND(MAX(CASE WHEN parameter = 'EV sales share' THEN total_value ELSE 0 END), 2) as market_share_percent,
        -- EV Stock
        ROUND(MAX(CASE WHEN parameter = 'EV stock' THEN total_value ELSE 0 END), 0) as ev_stock,
        -- BEV vs PHEV Split
        ROUND(SUM(CASE WHEN parameter = 'EV sales' AND powertrain = 'BEV' THEN total_value ELSE 0 END), 0) as bev_sales,
        ROUND(SUM(CASE WHEN parameter = 'EV sales' AND powertrain = 'PHEV' THEN total_value ELSE 0 END), 0) as phev_sales
    FROM eu_countries
    GROUP BY state, year
)

-- Final EU Country Comparison
SELECT 
    state,
    year,
    ev_sales,
    market_share_percent,
    ev_stock,
    bev_sales,
    phev_sales,
    
    -- Technology Preference
    CASE 
        WHEN (bev_sales + phev_sales) > 0 THEN
            ROUND((bev_sales / (bev_sales + phev_sales) * 100), 1)
        ELSE 0
    END as bev_preference_percent,
    
    -- Country Classification
    CASE 
        WHEN state = 'Italy' THEN 'Target Country'
        WHEN state = 'Norway' THEN 'EV Leader'
        WHEN state IN ('Germany', 'France') THEN 'Major Market'
        WHEN state = 'Europe' THEN 'Regional Average'
        ELSE 'Comparison Country'
    END as country_type,
    
    -- Market Maturity
    CASE 
        WHEN market_share_percent > 20 THEN 'Advanced Market'
        WHEN market_share_percent > 10 THEN 'Growth Market'
        WHEN market_share_percent > 5 THEN 'Developing Market'
        ELSE 'Emerging Market'
    END as market_maturity,
    
    -- Strategic Position vs Italy
    CASE 
        WHEN state = 'Italy' THEN 'Italy Performance'
        WHEN state = 'Europe' THEN 'European Benchmark'
        ELSE 'Competitive Reference'
    END as strategic_context

FROM country_summary
WHERE year = 2023  -- Latest available data
    AND (ev_sales > 0 OR market_share_percent > 0)
ORDER BY market_share_percent DESC, ev_sales DESC;

/*
SIMPLIFIED EU COUNTRY COMPARISON:
=================================

PURPOSE: Italy vs major EU countries EV performance
SCOPE: 2023 latest data across key European markets
STRATEGIC VALUE: Italy's competitive position in Europe

KEY INSIGHTS PROVIDED:
• Italy vs Germany, France, Spain, Netherlands, Norway
• Market share and sales volume comparison
• BEV vs PHEV technology preferences
• Market maturity classification
• Strategic positioning analysis

SIMPLIFICATIONS MADE:
• Focus on latest year (2023)
• Major European countries only
• Standard metrics (sales, share, stock)
• Clear state classification system
*/