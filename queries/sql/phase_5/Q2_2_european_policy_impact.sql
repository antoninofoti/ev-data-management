-- European Policy Impact Analysis
-- Analyzes the effectiveness of EU policies on EV adoption across different periods

WITH policy_periods AS (
    SELECT 
        region as country_code,
        parameter,
        year,
        value,
        CASE 
            WHEN year <= 2020 THEN 'Pre-EU Green Deal (2019-2020)'
            WHEN year <= 2022 THEN 'EU Green Deal Era (2021-2022)'
            WHEN year >= 2023 THEN 'Fit for 55 Package (2023+)'
            ELSE 'Other'
        END as policy_period
    FROM ev_sales 
    WHERE region IN ('EU27', 'World')
        AND year >= 2019
        AND parameter IN ('EV sales', 'EV sales share', 'EV stock')
        AND value > 0
),
period_aggregation AS (
    SELECT 
        country_code,
        policy_period,
        parameter,
        AVG(value) as avg_value,
        SUM(value) as total_value
    FROM policy_periods
    GROUP BY country_code, policy_period, parameter
),
country_period_summary AS (
    SELECT 
        country_code,
        policy_period,
        AVG(CASE WHEN parameter = 'EV sales share' THEN avg_value END) as sales_share_avg,
        SUM(CASE WHEN parameter = 'EV sales' THEN total_value ELSE 0 END) as sales_total
    FROM period_aggregation
    GROUP BY country_code, policy_period
)
SELECT 
    country_code,
    policy_period,
    ROUND(COALESCE(sales_share_avg, 0), 2) as avg_sales_share_percent,
    ROUND(sales_total, 0) as total_sales,
    CASE 
        WHEN sales_share_avg >= 10 AND policy_period = 'Fit for 55 Package (2023+)' THEN 'High Impact'
        WHEN sales_share_avg >= 5 AND policy_period != 'Pre-EU Green Deal (2019-2020)' THEN 'Moderate Impact'
        WHEN sales_share_avg < 3 THEN 'Low Impact'
        ELSE 'Developing'
    END as policy_effectiveness,
    CASE 
        WHEN country_code = 'Italy' THEN 'Base Country'
        WHEN sales_share_avg > 15 THEN 'Outperforming Italy'
        WHEN sales_share_avg > 8 THEN 'Above Italy'
        ELSE 'Similar to Italy'
    END as italy_comparison
FROM country_period_summary
WHERE sales_share_avg IS NOT NULL
ORDER BY policy_period, sales_share_avg DESC;