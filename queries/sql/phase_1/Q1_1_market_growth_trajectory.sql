-- Q1.1 - Market Growth Trajectory
-- Business Question: "What is the annual growth rate of EV sales for major regions?"

WITH regional_sales AS (
    SELECT 
        region,
        year,
        SUM(CASE WHEN parameter = 'EV sales' AND unit = 'Vehicles' 
            THEN value ELSE 0 END) as total_ev_sales
    FROM ev_sales
    WHERE region IN ('United States', 'Europe', 'China', 'USA', 'World')
        AND year BETWEEN 2020 AND 2024
        AND parameter = 'EV sales'
        AND unit = 'Vehicles'
    GROUP BY region, year
),

growth_rates AS (
    SELECT 
        region,
        year,
        total_ev_sales,
        LAG(total_ev_sales) OVER (PARTITION BY region ORDER BY year) as prev_year_sales,
        CASE 
            WHEN LAG(total_ev_sales) OVER (PARTITION BY region ORDER BY year) > 0 
            THEN ROUND(
                ((total_ev_sales - LAG(total_ev_sales) OVER (PARTITION BY region ORDER BY year)) 
                / LAG(total_ev_sales) OVER (PARTITION BY region ORDER BY year) * 100)::NUMERIC, 1
            )
            ELSE 0
        END as growth_rate_pct
    FROM regional_sales
)

SELECT 
    region,
    year,
    total_ev_sales,
    COALESCE(growth_rate_pct, 0) as growth_rate_pct,
    CASE 
        WHEN growth_rate_pct > 50 THEN 'High Growth'
        WHEN growth_rate_pct > 20 THEN 'Moderate Growth'
        WHEN growth_rate_pct > 0 THEN 'Slow Growth'
        ELSE 'Decline'
    END as growth_category
FROM growth_rates
ORDER BY region, year;