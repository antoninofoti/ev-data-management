-- Q3.3 - Seasonal Charging Patterns
-- Business Question: "What are the seasonal patterns in charging station usage?"

WITH seasonal_analysis AS (
    SELECT 
        country_code,
        CASE 
            WHEN EXTRACT(MONTH FROM CURRENT_DATE) IN (12, 1, 2) THEN 'Winter'
            WHEN EXTRACT(MONTH FROM CURRENT_DATE) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM CURRENT_DATE) IN (6, 7, 8) THEN 'Summer'
            ELSE 'Fall'
        END as current_season,
        COUNT(*) as total_stations,
        AVG(power_kw) as avg_power,
        COUNT(CASE WHEN power_kw >= 150 THEN 1 END) as high_power_stations,
        COUNT(DISTINCT city) as operators
    FROM charging_stations
    WHERE country_code IS NOT NULL
        AND power_kw > 0
    GROUP BY country_code
    HAVING COUNT(*) >= 20
),

pattern_analysis AS (
    SELECT 
        *,
        ROUND(high_power_stations * 100.0 / total_stations, 1) as high_power_percentage,
        CASE 
            WHEN total_stations >= 1000 THEN 'High Usage Expected'
            WHEN total_stations >= 100 THEN 'Moderate Usage Expected'
            ELSE 'Low Usage Expected'
        END as expected_seasonal_demand
    FROM seasonal_analysis
)

SELECT 
    country_code,
    current_season,
    total_stations,
    ROUND(avg_power, 1) as avg_power_kw,
    high_power_stations,
    high_power_percentage,
    operators,
    expected_seasonal_demand
FROM pattern_analysis
ORDER BY total_stations DESC;