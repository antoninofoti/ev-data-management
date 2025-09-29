-- Q6_2: Policy Effectiveness Global Comparison - EU vs China vs USA Policy Impact
-- Focus: How different policy approaches (incentives, mandates, infrastructure) drive EV adoption
-- Context: Learning from global policy successes for Italy's strategic positioning

WITH policy_effectiveness_metrics AS (
    -- Extract policy-relevant metrics across regions
    SELECT 
        region as state,
        year,
        parameter,
        SUM(value) as metric_value
    FROM ev_sales 
    WHERE region IN ('China', 'USA', 'Europe', 'Italy', 'World')
        AND year BETWEEN 2018 AND 2024
        AND mode = 'Cars'
        AND parameter IN ('EV sales share', 'EV sales', 'EV stock', 'EV sales share', 'Public charging points')
    GROUP BY region, year, parameter
),

regional_policy_context AS (
    -- Add known policy context for each state
    SELECT 
        state,
        -- Policy approach classification
        CASE 
            WHEN state = 'China' THEN 'State-Led Comprehensive'
            WHEN state = 'USA' THEN 'Market-Driven with Federal Support'
            WHEN state = 'Europe' THEN 'Regulatory Framework with National Variations'
            WHEN state = 'Italy' THEN 'EU Framework with National Incentives'
            ELSE 'Mixed Approach'
        END as policy_approach,
        
        -- Key policy tools
        CASE 
            WHEN state = 'China' THEN 'NEV mandates, subsidies, battery supply chain'
            WHEN state = 'USA' THEN 'Federal tax credits, state ZEV programs, infrastructure'
            WHEN state = 'Europe' THEN 'CO2 standards, national incentives, Green Deal'
            WHEN state = 'Italy' THEN 'Ecobonus, charging infrastructure, city restrictions'
            ELSE 'Various tools'
        END as key_policy_tools,
        
        -- Policy timeline intensity
        CASE 
            WHEN state = 'China' THEN 'Early aggressive (2015+), sustained support'
            WHEN state = 'USA' THEN 'Moderate start (2010+), recent acceleration'
            WHEN state = 'Europe' THEN 'Building momentum (2020+), accelerating'
            WHEN state = 'Italy' THEN 'Following EU trend, local adaptations'
            ELSE 'Variable timing'
        END as policy_timeline,
        
        -- Infrastructure focus
        CASE 
            WHEN state = 'China' THEN 'Massive public charging network'
            WHEN state = 'USA' THEN 'Private sector led, federal support'
            WHEN state = 'Europe' THEN 'Coordinated network expansion'
            WHEN state = 'Italy' THEN 'National plan with EU funding'
            ELSE 'Mixed infrastructure'
        END as infrastructure_strategy
    FROM (SELECT DISTINCT state FROM policy_effectiveness_metrics) r
),

policy_impact_analysis AS (
    -- Calculate policy effectiveness metrics
    SELECT 
        pem.state,
        rpc.policy_approach,
        rpc.key_policy_tools,
        rpc.policy_timeline,
        rpc.infrastructure_strategy,
        
        -- EV adoption progression metrics
        MAX(CASE WHEN pem.year = 2024 AND pem.parameter = 'EV sales share' THEN pem.metric_value END) as ev_share_2024,
        MAX(CASE WHEN pem.year = 2020 AND pem.parameter = 'EV sales share' THEN pem.metric_value END) as ev_share_2020,
        MAX(CASE WHEN pem.year = 2018 AND pem.parameter = 'EV sales share' THEN pem.metric_value END) as ev_share_2018,
        
        -- Absolute growth metrics
        MAX(CASE WHEN pem.year = 2024 AND pem.parameter = 'EV sales' THEN pem.metric_value END) as ev_sales_2024,
        MAX(CASE WHEN pem.year = 2020 AND pem.parameter = 'EV sales' THEN pem.metric_value END) as ev_sales_2020,
        MAX(CASE WHEN pem.year = 2018 AND pem.parameter = 'EV sales' THEN pem.metric_value END) as ev_sales_2018,
        
        -- Stock accumulation
        MAX(CASE WHEN pem.year = 2024 AND pem.parameter = 'EV stock' THEN pem.metric_value END) as ev_stock_2024,
        MAX(CASE WHEN pem.year = 2020 AND pem.parameter = 'EV stock' THEN pem.metric_value END) as ev_stock_2020,
        
        -- Infrastructure development (if available)
        MAX(CASE WHEN pem.year = 2024 AND pem.parameter = 'Public charging points' THEN pem.metric_value END) as charging_points_2024,
        MAX(CASE WHEN pem.year = 2020 AND pem.parameter = 'Public charging points' THEN pem.metric_value END) as charging_points_2020
        
    FROM policy_effectiveness_metrics pem
    JOIN regional_policy_context rpc ON pem.state = rpc.state
    GROUP BY pem.state, rpc.policy_approach, rpc.key_policy_tools, rpc.policy_timeline, rpc.infrastructure_strategy
),

effectiveness_calculations AS (
    -- Calculate policy effectiveness indicators
    SELECT 
        *,
        -- Market share growth rates
        CASE 
            WHEN COALESCE(ev_share_2020, 0) > 0 THEN 
                ROUND(((COALESCE(ev_share_2024, 0) - ev_share_2020) / ev_share_2020 * 100), 1)
            ELSE 0 
        END as share_growth_2020_2024_percent,
        
        CASE 
            WHEN COALESCE(ev_share_2018, 0) > 0 THEN 
                ROUND(((COALESCE(ev_share_2024, 0) - ev_share_2018) / ev_share_2018 * 100), 1)
            ELSE 0 
        END as share_growth_2018_2024_percent,
        
        -- Sales volume growth
        CASE 
            WHEN COALESCE(ev_sales_2020, 0) > 0 THEN 
                ROUND(((COALESCE(ev_sales_2024, 0) - ev_sales_2020) / ev_sales_2020 * 100), 1)
            ELSE 0 
        END as sales_growth_2020_2024_percent,
        
        -- Stock accumulation rate
        CASE 
            WHEN COALESCE(ev_stock_2020, 0) > 0 THEN 
                ROUND(((COALESCE(ev_stock_2024, 0) - ev_stock_2020) / ev_stock_2020 * 100), 1)
            ELSE 0 
        END as stock_growth_2020_2024_percent,
        
        -- Infrastructure development
        CASE 
            WHEN COALESCE(charging_points_2020, 0) > 0 THEN 
                ROUND(((COALESCE(charging_points_2024, 0) - charging_points_2020) / charging_points_2020 * 100), 1)
            ELSE 0 
        END as charging_growth_2020_2024_percent,
        
        -- Policy effectiveness score (composite metric)
        ROUND((
            COALESCE(ev_share_2024, 0) * 0.4 +  -- Current achievement weight
            CASE WHEN COALESCE(ev_share_2020, 0) > 0 THEN 
                ((COALESCE(ev_share_2024, 0) - ev_share_2020) / ev_share_2020 * 10) 
            ELSE 0 END * 0.3 +  -- Growth momentum weight
            CASE WHEN COALESCE(ev_sales_2024, 0) > 1000000 THEN 10 
                 WHEN COALESCE(ev_sales_2024, 0) > 500000 THEN 7
                 WHEN COALESCE(ev_sales_2024, 0) > 100000 THEN 5
                 ELSE 2 END * 0.3  -- Scale achievement weight
        ), 1) as policy_effectiveness_score
        
    FROM policy_impact_analysis
),

comparative_analysis AS (
    -- Compare policies against Italy and derive insights
    SELECT 
        ec.*,
        -- Italy comparison
        CASE 
            WHEN state = 'Italy' THEN 'Reference Market'
            WHEN ev_share_2024 > (SELECT ev_share_2024 FROM effectiveness_calculations WHERE state = 'Italy') THEN 'Outperforming Italy'
            ELSE 'Underperforming vs Italy'
        END as italy_performance_comparison,
        
        -- Policy maturity assessment
        CASE 
            WHEN ev_share_2024 >= 20 AND sales_growth_2020_2024_percent >= 100 THEN 'Mature High-Growth'
            WHEN ev_share_2024 >= 10 AND sales_growth_2020_2024_percent >= 200 THEN 'Rapid Scaling'
            WHEN ev_share_2024 >= 5 AND sales_growth_2020_2024_percent >= 150 THEN 'Strong Development'
            WHEN ev_share_2024 >= 2 THEN 'Early Growth'
            ELSE 'Initial Stage'
        END as policy_maturity_stage,
        
        -- Success factors
        CASE 
            WHEN state = 'China' THEN 'Scale mandates, supply chain control, infrastructure'
            WHEN state = 'USA' THEN 'Innovation ecosystem, federal incentives, state leadership'
            WHEN state = 'Europe' THEN 'Regulatory consistency, manufacturer pressure, climate targets'
            WHEN state = 'Italy' THEN 'EU alignment, national incentives, urban policies'
            ELSE 'Mixed success factors'
        END as key_success_factors,
        
        -- Transferable lessons for Italy
        CASE 
            WHEN state = 'China' THEN 'Long-term industrial strategy, supply chain development'
            WHEN state = 'USA' THEN 'Innovation support, state-level experimentation'
            WHEN state = 'Europe' THEN 'Regulatory certainty, coordinated approach'
            ELSE 'Market-specific adaptations'
        END as lessons_for_italy,
        
        -- Policy sustainability
        CASE 
            WHEN share_growth_2020_2024_percent >= 100 AND ev_share_2024 >= 10 THEN 'Highly Sustainable'
            WHEN share_growth_2020_2024_percent >= 50 AND ev_share_2024 >= 5 THEN 'Sustainable Growth'
            WHEN share_growth_2020_2024_percent >= 25 THEN 'Moderate Sustainability'
            ELSE 'Sustainability Concerns'
        END as sustainability_outlook
        
    FROM effectiveness_calculations ec
)

SELECT 
    state,
    policy_approach,
    key_policy_tools,
    policy_timeline,
    infrastructure_strategy,
    COALESCE(ev_share_2024, 0) as ev_share_2024_percent,
    COALESCE(ev_sales_2024, 0) as ev_sales_2024_units,
    COALESCE(ev_stock_2024, 0) as ev_stock_2024_units,
    share_growth_2020_2024_percent,
    sales_growth_2020_2024_percent,
    stock_growth_2020_2024_percent,
    charging_growth_2020_2024_percent,
    policy_effectiveness_score,
    italy_performance_comparison,
    policy_maturity_stage,
    key_success_factors,
    lessons_for_italy,
    sustainability_outlook
FROM comparative_analysis
ORDER BY 
    CASE state 
        WHEN 'China' THEN 1
        WHEN 'USA' THEN 2  
        WHEN 'Europe' THEN 3
        WHEN 'Italy' THEN 4
        ELSE 5 
    END;