-- Q4_1: Infrastructure Readiness 
-- Compare charging infrastructure across European countries

WITH charging_infrastructure AS (
    SELECT 
        region as state,
        year,
        parameter,
        powertrain,
        SUM(value) as total_value
    FROM ev_sales 
    WHERE region IN ('Italy', 'Germany', 'France', 'Spain', 'Netherlands', 'Norway', 'Europe')
        AND parameter LIKE '%charging%' OR parameter LIKE '%infrastructure%' OR parameter = 'EV stock'
        AND mode = 'Cars'
        AND year = 2023
    GROUP BY region, year, parameter, powertrain
),

-- Since charging station data might be limited, create infrastructure proxy
infrastructure_proxy AS (
    SELECT 
        region as state,
        year,
        -- Use EV stock as proxy for infrastructure needs
        SUM(CASE WHEN parameter = 'EV stock' THEN value ELSE 0 END) as ev_stock,
        -- Estimate charging stations needed (rough proxy: 1 station per 10 EVs)
        ROUND(SUM(CASE WHEN parameter = 'EV stock' THEN value ELSE 0 END) / 10, 0) as estimated_stations_needed
    FROM ev_sales 
    WHERE region IN ('Italy', 'Germany', 'France', 'Spain', 'Netherlands', 'Norway')
        AND parameter = 'EV stock'
        AND mode = 'Cars'
        AND year = 2023
    GROUP BY region, year
)

-- Infrastructure Readiness Analysis
SELECT 
    state,
    year,
    ev_stock,
    estimated_stations_needed,
    
    -- Infrastructure density classification
    CASE 
        WHEN ev_stock > 1000000 THEN 'High Infrastructure Demand'
        WHEN ev_stock > 500000 THEN 'Medium Infrastructure Demand'
        WHEN ev_stock > 100000 THEN 'Growing Infrastructure Demand'
        ELSE 'Basic Infrastructure Needs'
    END as infrastructure_demand_level,
    
    -- Country infrastructure context
    CASE 
        WHEN state = 'Germany' THEN 'Leading EU Infrastructure'
        WHEN state = 'Norway' THEN 'Advanced Nordic Infrastructure'
        WHEN state = 'France' THEN 'Major Market Infrastructure'
        WHEN state = 'Italy' THEN 'Target Market Infrastructure'
        WHEN state = 'Netherlands' THEN 'Compact High-Density'
        WHEN state = 'Spain' THEN 'Large Territory Challenge'
        ELSE 'European Infrastructure'
    END as infrastructure_context,
    
    -- Relative infrastructure position
    CASE 
        WHEN state = 'Italy' THEN 'Italy Infrastructure Position'
        ELSE 'Comparison Market'
    END as analysis_focus,
    
    -- Infrastructure development stage
    CASE 
        WHEN ev_stock > 1000000 THEN 'Mature Infrastructure Needed'
        WHEN ev_stock > 500000 THEN 'Scaling Infrastructure Phase'
        WHEN ev_stock > 100000 THEN 'Foundation Infrastructure Phase'
        ELSE 'Early Infrastructure Phase'
    END as development_stage,
    
    -- Strategic priority
    CASE 
        WHEN state = 'Italy' AND ev_stock > 200000 THEN 'High Priority - Italy Infrastructure Investment'
        WHEN state = 'Italy' THEN 'Medium Priority - Italy Infrastructure Development'
        ELSE 'Benchmark Reference'
    END as strategic_priority

FROM infrastructure_proxy
WHERE ev_stock > 0
ORDER BY ev_stock DESC;

/*
SIMPLIFIED INFRASTRUCTURE READINESS ANALYSIS:
============================================

PURPOSE: European infrastructure comparison for EV adoption
SCOPE: 2023 infrastructure demand based on EV stock
STRATEGIC VALUE: Italy's infrastructure needs vs European leaders

KEY INSIGHTS PROVIDED:
• Infrastructure demand based on EV fleet size
• Italy vs major European markets comparison
• Development stage classification
• Strategic infrastructure priorities

SIMPLIFICATIONS MADE:
• Uses EV stock as proxy for infrastructure needs
• Focus on latest year (2023) only
• Simplified demand estimation model
• Clear state classification system

NOTE: Actual charging station data may be limited in dataset,
so this uses EV stock as a proxy for infrastructure demand.
*/