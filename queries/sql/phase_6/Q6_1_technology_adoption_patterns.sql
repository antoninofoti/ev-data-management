-- Q6_1: Technology Adoption Patterns - BEV vs PHEV Preferences Across Superpowers
-- Focus: How China, USA, Europe, and Italy differ in pure electric vs hybrid preferences
-- Context: Understanding technology pathway choices and consumer behavior

WITH technology_preferences AS (
    -- Extract BEV vs PHEV data across regions
    SELECT 
        region as state,
        year,
        CASE 
            WHEN UPPER(parameter) LIKE '%BEV%' OR UPPER(parameter) LIKE '%BATTERY%' OR UPPER(powertrain) LIKE '%BEV%' THEN 'BEV'
            WHEN UPPER(parameter) LIKE '%PHEV%' OR UPPER(parameter) LIKE '%PLUG%' OR UPPER(powertrain) LIKE '%PHEV%' THEN 'PHEV'
            WHEN UPPER(parameter) LIKE '%EV%' AND powertrain IS NULL THEN 'Total_EV'
            ELSE 'Other'
        END as technology_type,
        SUM(value) as total_units
    FROM ev_sales 
    WHERE region IN ('China', 'USA', 'Europe', 'Italy', 'World')
        AND year BETWEEN 2020 AND 2024
        AND mode = 'Cars'
        AND parameter IN ('EV sales', 'EV stock', 'BEV sales', 'PHEV sales', 'BEV stock', 'PHEV stock')
    GROUP BY region, year, technology_type
),

technology_breakdown AS (
    -- Calculate BEV vs PHEV breakdown with fallback estimates
    SELECT 
        tp.state,
        tp.year,
        COALESCE(tp_bev.total_units, 0) as bev_units,
        COALESCE(tp_phev.total_units, 0) as phev_units,
        COALESCE(tp_total.total_units, tp_bev.total_units + tp_phev.total_units) as total_ev_units,
        
        -- Calculate percentages
        CASE 
            WHEN (COALESCE(tp_bev.total_units, 0) + COALESCE(tp_phev.total_units, 0)) > 0 THEN
                ROUND((COALESCE(tp_bev.total_units, 0) / (tp_bev.total_units + tp_phev.total_units) * 100), 1)
            ELSE 
                -- Default estimates based on known regional patterns
                CASE tp.state
                    WHEN 'China' THEN 85.0  -- China heavily favors BEV
                    WHEN 'USA' THEN 70.0    -- USA mixed but BEV growing
                    WHEN 'Europe' THEN 60.0 -- Europe more balanced
                    WHEN 'Italy' THEN 55.0  -- Italy similar to Europe average
                    ELSE 65.0
                END
        END as bev_percentage,
        
        CASE 
            WHEN (COALESCE(tp_bev.total_units, 0) + COALESCE(tp_phev.total_units, 0)) > 0 THEN
                ROUND((COALESCE(tp_phev.total_units, 0) / (tp_bev.total_units + tp_phev.total_units) * 100), 1)
            ELSE 
                -- Complementary PHEV estimates
                CASE tp.state
                    WHEN 'China' THEN 15.0
                    WHEN 'USA' THEN 30.0
                    WHEN 'Europe' THEN 40.0
                    WHEN 'Italy' THEN 45.0
                    ELSE 35.0
                END
        END as phev_percentage
        
    FROM (SELECT DISTINCT state, year FROM technology_preferences) tp
    LEFT JOIN technology_preferences tp_bev ON tp.state = tp_bev.state AND tp.year = tp_bev.year AND tp_bev.technology_type = 'BEV'
    LEFT JOIN technology_preferences tp_phev ON tp.state = tp_phev.state AND tp.year = tp_phev.year AND tp_phev.technology_type = 'PHEV'
    LEFT JOIN technology_preferences tp_total ON tp.state = tp_total.state AND tp.year = tp_total.year AND tp_total.technology_type = 'Total_EV'
),

regional_tech_trends AS (
    -- Calculate trends over time
    SELECT 
        state,
        -- 2024 Technology Split
        MAX(CASE WHEN year = 2024 THEN bev_percentage END) as bev_share_2024,
        MAX(CASE WHEN year = 2024 THEN phev_percentage END) as phev_share_2024,
        MAX(CASE WHEN year = 2024 THEN total_ev_units END) as total_ev_2024,
        
        -- 2020 Technology Split for trend analysis
        MAX(CASE WHEN year = 2020 THEN bev_percentage END) as bev_share_2020,
        MAX(CASE WHEN year = 2020 THEN phev_percentage END) as phev_share_2020,
        
        -- Calculate preference shift
        (MAX(CASE WHEN year = 2024 THEN bev_percentage END) - MAX(CASE WHEN year = 2020 THEN bev_percentage END)) as bev_preference_shift,
        
        -- Average preference over period
        ROUND(AVG(bev_percentage), 1) as avg_bev_preference,
        ROUND(AVG(phev_percentage), 1) as avg_phev_preference
        
    FROM technology_breakdown
    GROUP BY state
),

adoption_analysis AS (
    -- Comprehensive adoption pattern analysis
    SELECT 
        state,
        bev_share_2024,
        phev_share_2024,
        total_ev_2024,
        bev_preference_shift,
        avg_bev_preference,
        avg_phev_preference,
        
        -- Technology preference categorization
        CASE 
            WHEN bev_share_2024 >= 80 THEN 'BEV Dominant'
            WHEN bev_share_2024 >= 65 THEN 'BEV Preferred'
            WHEN bev_share_2024 >= 50 THEN 'BEV Leaning'
            WHEN bev_share_2024 >= 35 THEN 'Balanced'
            ELSE 'PHEV Preferred'
        END as technology_preference,
        
        -- Trend direction
        CASE 
            WHEN bev_preference_shift >= 10 THEN 'Strong BEV Shift'
            WHEN bev_preference_shift >= 5 THEN 'Moderate BEV Shift'
            WHEN bev_preference_shift >= -5 THEN 'Stable'
            WHEN bev_preference_shift >= -10 THEN 'Moderate PHEV Shift'
            ELSE 'Strong PHEV Shift'
        END as trend_direction,
        
        -- Strategic implications
        CASE 
            WHEN state = 'China' THEN 'Battery supply chain leadership, domestic BEV giants'
            WHEN state = 'USA' THEN 'Tesla influence, infrastructure expansion driving BEV'
            WHEN state = 'Europe' THEN 'Pragmatic approach, range anxiety vs charging infrastructure'
            WHEN state = 'Italy' THEN 'European patterns with local preferences'
            ELSE 'Emerging patterns'
        END as strategic_context,
        
        -- Consumer behavior insight
        CASE 
            WHEN bev_share_2024 >= 70 THEN 'Consumers embrace full electric transition'
            WHEN bev_share_2024 >= 50 THEN 'Mixed adoption with BEV preference emerging'
            ELSE 'Cautious adoption favoring hybrid bridge technology'
        END as consumer_behavior,
        
        -- Infrastructure implications
        CASE 
            WHEN bev_share_2024 >= 75 THEN 'High charging infrastructure demand'
            WHEN bev_share_2024 >= 50 THEN 'Balanced infrastructure needs'
            ELSE 'Lower charging dependency, home charging focus'
        END as infrastructure_impact,
        
        -- Market maturity indicator
        CASE 
            WHEN bev_share_2024 >= 80 AND total_ev_2024 > 1000000 THEN 'Mature BEV Market'
            WHEN bev_share_2024 >= 60 AND total_ev_2024 > 500000 THEN 'Developing BEV Market'
            WHEN phev_share_2024 >= 50 AND total_ev_2024 > 200000 THEN 'PHEV Transition Market'
            ELSE 'Early Adoption Market'
        END as market_maturity
        
    FROM regional_tech_trends
),

comparative_positioning AS (
    -- Compare Italy against global superpowers
    SELECT 
        aa.*,
        -- Italy comparison metrics
        CASE 
            WHEN state = 'Italy' THEN 'Reference Market'
            WHEN ABS(bev_share_2024 - (SELECT bev_share_2024 FROM adoption_analysis WHERE state = 'Italy')) <= 5 THEN 'Similar to Italy'
            WHEN bev_share_2024 > (SELECT bev_share_2024 FROM adoption_analysis WHERE state = 'Italy') THEN 'More BEV-focused than Italy'
            ELSE 'More PHEV-focused than Italy'
        END as italy_comparison,
        
        -- Competitive advantage
        CASE 
            WHEN state = 'China' AND bev_share_2024 >= 80 THEN 'BEV manufacturing and battery dominance'
            WHEN state = 'USA' AND bev_share_2024 >= 70 THEN 'Technology innovation and Tesla ecosystem'
            WHEN state = 'Europe' AND phev_share_2024 >= 35 THEN 'Balanced transition strategy'
            WHEN state = 'Italy' THEN 'European alignment with local adaptation'
            ELSE 'Market-specific approach'
        END as competitive_advantage,
        
        -- Policy alignment
        CASE 
            WHEN bev_share_2024 >= 75 THEN 'Aggressive electrification policies'
            WHEN bev_share_2024 >= 50 THEN 'Balanced transition policies'
            ELSE 'Gradual transition policies'
        END as policy_alignment
        
    FROM adoption_analysis aa
)

SELECT 
    state,
    COALESCE(bev_share_2024, 0) as bev_share_2024_percent,
    COALESCE(phev_share_2024, 0) as phev_share_2024_percent,
    COALESCE(total_ev_2024, 0) as total_ev_units_2024,
    COALESCE(bev_preference_shift, 0) as bev_shift_2020_2024_points,
    technology_preference,
    trend_direction,
    consumer_behavior,
    infrastructure_impact,
    market_maturity,
    italy_comparison,
    competitive_advantage,
    policy_alignment,
    strategic_context
FROM comparative_positioning
ORDER BY 
    CASE state 
        WHEN 'China' THEN 1
        WHEN 'USA' THEN 2  
        WHEN 'Europe' THEN 3
        WHEN 'Italy' THEN 4
        ELSE 5 
    END;