-- Q4.3 - Technology Adoption Rate Analysis
-- Business Question: "What is the adoption rate of different charging technologies?"

WITH country_charging_tech AS (
    SELECT 
        country_code,
        COUNT(*) as total_stations,
        COUNT(CASE WHEN power_kw >= 150 THEN 1 END) as ultra_fast_stations,
        COUNT(CASE WHEN power_kw >= 50 THEN 1 END) as fast_stations,
        COUNT(CASE WHEN power_kw < 50 THEN 1 END) as standard_stations,
        AVG(power_kw) as avg_power_kw,
        MAX(power_kw) as max_power_kw
    FROM charging_stations
    WHERE country_code IS NOT NULL 
        AND power_kw > 0
    GROUP BY country_code
    HAVING COUNT(*) >= 50  -- Countries with significant infrastructure
),

technology_metrics AS (
    SELECT 
        *,
        ROUND(ultra_fast_stations * 100.0 / total_stations, 1) as ultra_fast_adoption_pct,
        ROUND(fast_stations * 100.0 / total_stations, 1) as fast_adoption_pct,
        ROUND(standard_stations * 100.0 / total_stations, 1) as standard_adoption_pct,
        ROUND((ultra_fast_stations * 0.6 + fast_stations * 0.4) * 100.0 / total_stations, 1) as innovation_score
    FROM country_charging_tech
),

technology_rankings AS (
    SELECT 
        *,
        CASE
            WHEN ultra_fast_adoption_pct >= 30 THEN 'Technology Leader'
            WHEN ultra_fast_adoption_pct >= 15 THEN 'Early Adopter'
            WHEN fast_adoption_pct >= 60 THEN 'Fast Follower'
            ELSE 'Technology Laggard'
        END as technology_tier,
        RANK() OVER (ORDER BY innovation_score DESC) as innovation_rank
    FROM technology_metrics
)

SELECT 
    country_code,
    total_stations,
    ultra_fast_stations,
    ultra_fast_adoption_pct,
    fast_adoption_pct,
    innovation_score,
    technology_tier,
    innovation_rank,
    ROUND(avg_power_kw, 1) as avg_power_kw,
    max_power_kw
FROM technology_rankings
ORDER BY innovation_score DESC;