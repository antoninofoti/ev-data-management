-- Italy vs Global Giants Per-Capita Analysis
-- Deep dive into how Italy performs against superpowers on per-capita basis

WITH country_stats AS (
    SELECT 
        region as state,
        year,
        parameter,
        SUM(value) as total_value
    FROM ev_sales 
    WHERE region IN ('China', 'USA', 'Europe', 'Italy')
        AND parameter IN ('EV sales', 'EV stock', 'EV sales share')
        AND mode = 'Cars'
        AND year IN (2020, 2021, 2022, 2023, 2024)
    GROUP BY region, year, parameter
),
population_context AS (
    SELECT 
        state,
        CASE state
            WHEN 'China' THEN 1400.0
            WHEN 'USA' THEN 330.0
            WHEN 'Europe' THEN 750.0
            WHEN 'Italy' THEN 59.1
        END as population_millions,
        CASE state
            WHEN 'China' THEN 9596961  -- km2
            WHEN 'USA' THEN 9833517
            WHEN 'Europe' THEN 10180000
            WHEN 'Italy' THEN 301339
        END as area_km2,
        CASE state
            WHEN 'China' THEN 17734062  -- GDP in millions USD (2024 est)
            WHEN 'USA' THEN 25035164
            WHEN 'Europe' THEN 18000000  -- EU GDP estimate
            WHEN 'Italy' THEN 2107700
        END as gdp_millions_usd
    FROM (SELECT DISTINCT state FROM country_stats) t
),
latest_performance AS (
    SELECT 
        cs.state,
        pc.population_millions,
        pc.area_km2,
        pc.gdp_millions_usd,
        MAX(CASE WHEN cs.parameter = 'EV sales' AND cs.year = 2024 THEN cs.total_value END) as ev_sales_2024,
        MAX(CASE WHEN cs.parameter = 'EV stock' AND cs.year = 2024 THEN cs.total_value END) as ev_stock_2024,
        MAX(CASE WHEN cs.parameter = 'EV sales share' AND cs.year = 2024 THEN cs.total_value END) as sales_share_2024,
        -- Historical comparison
        MAX(CASE WHEN cs.parameter = 'EV sales' AND cs.year = 2020 THEN cs.total_value END) as ev_sales_2020,
        MAX(CASE WHEN cs.parameter = 'EV sales share' AND cs.year = 2020 THEN cs.total_value END) as sales_share_2020
    FROM country_stats cs
    JOIN population_context pc ON cs.state = pc.state
    GROUP BY cs.state, pc.population_millions, pc.area_km2, pc.gdp_millions_usd
),
italy_benchmarks AS (
    SELECT 
        ev_stock_2024 / population_millions as italy_ev_per_capita,
        ev_sales_2024 / population_millions as italy_sales_per_capita,
        sales_share_2024 as italy_sales_share,
        ev_stock_2024 / area_km2 * 1000 as italy_ev_per_1000_km2,
        ev_sales_2024 / gdp_millions_usd * 1000000 as italy_ev_per_billion_gdp
    FROM latest_performance 
    WHERE state = 'Italy'
)
SELECT 
    lp.state,
    ROUND(lp.population_millions, 1) as population_millions,
    ROUND(lp.area_km2 / 1000, 0) as area_1000_km2,
    ROUND(lp.gdp_millions_usd / 1000, 0) as gdp_billions_usd,
    
    -- Absolute numbers
    ROUND(COALESCE(lp.ev_sales_2024, 0), 0) as ev_sales_2024,
    ROUND(COALESCE(lp.ev_stock_2024, 0), 0) as ev_stock_2024,
    ROUND(COALESCE(lp.sales_share_2024, 0), 2) as sales_share_2024_percent,
    
    -- Per capita metrics
    ROUND(COALESCE(lp.ev_stock_2024, 0) / lp.population_millions, 1) as ev_per_1000_people,
    ROUND(COALESCE(lp.ev_sales_2024, 0) / lp.population_millions, 1) as annual_ev_sales_per_1000_people,
    
    -- Per area metrics  
    ROUND(COALESCE(lp.ev_stock_2024, 0) / lp.area_km2 * 1000, 2) as ev_per_1000_km2,
    
    -- Economic efficiency
    ROUND(COALESCE(lp.ev_sales_2024, 0) / lp.gdp_millions_usd * 1000000, 2) as ev_sales_per_billion_gdp,
    
    -- Growth metrics
    ROUND(
        CASE 
            WHEN lp.ev_sales_2020 > 0 AND lp.ev_sales_2024 > 0 
            THEN ((lp.ev_sales_2024 - lp.ev_sales_2020) / lp.ev_sales_2020) * 100
            ELSE 0 
        END, 1
    ) as sales_growth_2020_2024_percent,
    
    ROUND(
        CASE 
            WHEN lp.sales_share_2020 > 0 AND lp.sales_share_2024 > 0 
            THEN (lp.sales_share_2024 - lp.sales_share_2020)
            ELSE 0 
        END, 2
    ) as share_improvement_2020_2024,
    
    -- Italy comparison ratios
    ROUND(
        (COALESCE(lp.ev_stock_2024, 0) / lp.population_millions) / ib.italy_ev_per_capita, 2
    ) as vs_italy_per_capita_ratio,
    
    ROUND(
        COALESCE(lp.sales_share_2024, 0) / ib.italy_sales_share, 2
    ) as vs_italy_adoption_ratio,
    
    -- Performance classification
    CASE 
        WHEN lp.state = 'Italy' THEN 'Base Country - Italy'
        WHEN (COALESCE(lp.ev_stock_2024, 0) / lp.population_millions) > (ib.italy_ev_per_capita * 2) 
        THEN 'Much Higher Per-Capita (>2x Italy)'
        WHEN (COALESCE(lp.ev_stock_2024, 0) / lp.population_millions) > ib.italy_ev_per_capita 
        THEN 'Higher Per-Capita than Italy'
        WHEN (COALESCE(lp.ev_stock_2024, 0) / lp.population_millions) > (ib.italy_ev_per_capita * 0.5) 
        THEN 'Similar Per-Capita to Italy'
        ELSE 'Lower Per-Capita than Italy'
    END as per_capita_comparison,
    
    -- Strategic insights
    CASE 
        WHEN lp.state = 'China' THEN 'Scale Leader - Learn from mass adoption strategies'
        WHEN lp.state = 'USA' THEN 'Innovation Hub - Tesla influence and technology leadership'
        WHEN lp.state = 'Europe' THEN 'Regional Peer - Policy and infrastructure comparison'
        WHEN lp.state = 'Italy' THEN 'Home Market - Reference point'
        ELSE 'Other Market'
    END as strategic_insight,
    
    -- Market maturity
    CASE 
        WHEN COALESCE(lp.sales_share_2024, 0) > 30 THEN 'Mature EV Market'
        WHEN COALESCE(lp.sales_share_2024, 0) > 15 THEN 'Advanced EV Market'
        WHEN COALESCE(lp.sales_share_2024, 0) > 5 THEN 'Developing EV Market'
        ELSE 'Early EV Market'
    END as market_maturity

FROM latest_performance lp
CROSS JOIN italy_benchmarks ib
ORDER BY 
    CASE lp.state 
        WHEN 'Italy' THEN 1 
        WHEN 'Europe' THEN 2 
        WHEN 'USA' THEN 3 
        WHEN 'China' THEN 4 
        ELSE 5 
    END;