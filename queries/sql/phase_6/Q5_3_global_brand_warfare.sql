-- Q5_3: Global Technology Warfare - BEV vs PHEV vs FCEV Competition
-- Focus: How different EV technologies compete worldwide
-- Context: Technology dominance analysis across China, USA, Europe with Italy reference

WITH technology_performance AS (
    -- Aggregate technology sales across major regions
    SELECT 
        powertrain as technology,
        region as state,
        year,
        SUM(CASE WHEN parameter = 'EV sales' THEN value ELSE 0 END) as ev_sales,
        SUM(CASE WHEN parameter = 'EV stock' THEN value ELSE 0 END) as ev_stock,
        SUM(CASE WHEN parameter = 'EV sales share' THEN value ELSE 0 END) as market_share
    FROM ev_sales 
    WHERE region IN ('China', 'USA', 'Europe', 'Italy', 'World')
        AND year BETWEEN 2020 AND 2024
        AND mode = 'Cars'
        AND powertrain IN ('BEV', 'PHEV', 'FCEV')
    GROUP BY powertrain, region, year
),

technology_warfare_2023 AS (
    -- 2023 technology performance (latest available data)
    SELECT 
        technology,
        state,
        ev_sales as sales_2023,
        ev_stock as stock_2023,
        market_share as share_2023
    FROM technology_performance
    WHERE year = 2023
),

technology_warfare_2020 AS (
    -- 2020 baseline for growth calculation
    SELECT 
        technology,
        state,
        ev_sales as sales_2020,
        market_share as share_2020
    FROM technology_performance
    WHERE year = 2020
),

technology_warfare_analysis AS (
    -- Technology competition analysis
    SELECT 
        t23.technology,
        t23.state,
        
        -- 2023 Performance (latest available)
        COALESCE(t23.sales_2023, 0) as sales_2023,
        COALESCE(t23.stock_2023, 0) as stock_2023,
        COALESCE(t23.share_2023, 0) as share_2023_percent,
        
        -- Growth since 2020
        CASE 
            WHEN COALESCE(t20.sales_2020, 0) > 0 THEN 
                ROUND(((t23.sales_2023 - t20.sales_2020) / t20.sales_2020 * 100), 1)
            ELSE 999 
        END as sales_growth_2020_2023_percent,
        
        CASE 
            WHEN COALESCE(t20.share_2020, 0) > 0 THEN 
                ROUND((t23.share_2023 - t20.share_2020), 2)
            ELSE t23.share_2023 
        END as share_growth_2020_2023_points,
        
        -- Technology classification
        CASE 
            WHEN t23.technology = 'BEV' THEN 'Battery Electric - Pure EV'
            WHEN t23.technology = 'PHEV' THEN 'Plug-in Hybrid - Transitional'
            WHEN t23.technology = 'FCEV' THEN 'Fuel Cell - Emerging'
            ELSE 'Other Technology'
        END as technology_type,
        
        -- Competitive position
        CASE 
            WHEN t23.share_2023 > 15 THEN 'Dominant Technology'
            WHEN t23.share_2023 > 5 THEN 'Strong Presence'
            WHEN t23.share_2023 > 1 THEN 'Growing Market'
            ELSE 'Niche Technology'
        END as competitive_position
        
    FROM technology_warfare_2023 t23
    LEFT JOIN technology_warfare_2020 t20 
        ON t23.technology = t20.technology 
        AND t23.state = t20.state
)

-- Final technology warfare summary
SELECT 
    technology,
    state,
    
    -- Performance metrics
    ROUND(sales_2023, 0) as sales_2023_units,
    ROUND(stock_2023, 0) as stock_2023_units,
    ROUND(share_2023_percent, 2) as share_2023_percent,
    
    -- Growth metrics
    sales_growth_2020_2023_percent,
    share_growth_2020_2023_points,
    
    -- Strategic context
    technology_type,
    competitive_position,
    
    -- Strategic insights
    CASE 
        WHEN state = 'Italy' AND technology = 'BEV' THEN 'Italy BEV adoption vs global leaders'
        WHEN state = 'Europe' AND technology = 'BEV' THEN 'European BEV leadership position'
        WHEN state = 'China' AND technology = 'BEV' THEN 'Chinese BEV dominance reference'
        WHEN state = 'USA' AND technology = 'BEV' AND share_2023_percent > 10 THEN 'USA BEV catching up to Europe/China'
        WHEN technology = 'PHEV' AND share_2023_percent > 3 THEN 'PHEV still competitive vs BEV'
        WHEN technology = 'FCEV' THEN 'Hydrogen fuel cell niche opportunity'
        ELSE 'Technology adoption tracking'
    END as strategic_insight

FROM technology_warfare_analysis
WHERE sales_2023 > 0 OR stock_2023 > 0
ORDER BY 
    CASE state 
        WHEN 'Italy' THEN 1 
        WHEN 'Europe' THEN 2 
        WHEN 'China' THEN 3 
        WHEN 'USA' THEN 4 
        WHEN 'World' THEN 5 
        ELSE 6 
    END,
    share_2023_percent DESC;

/*
SIMPLIFIED TECHNOLOGY WARFARE ANALYSIS SUMMARY:
==============================================

PURPOSE: Global EV technology competition analysis (BEV vs PHEV vs FCEV)
SCOPE: Major regions (Italy, Europe, China, USA, World) from 2020-2024
STRATEGIC VALUE: Technology adoption patterns and competitive positioning

KEY INSIGHTS PROVIDED:
• BEV vs PHEV dominance by state
• Fuel cell (FCEV) emerging opportunities
• Italy's technology preferences vs global leaders
• Growth trends showing technology shifts
• Market share evolution 2020-2024

REPLACES: Brand warfare (not available in data)
FOCUS: Technology warfare across major EV markets
*/