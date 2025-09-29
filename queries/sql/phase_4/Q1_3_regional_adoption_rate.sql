-- Q1.3 - Regional Adoption Rate
-- Business Question: "What are the EV adoption rates across different regions?"

WITH regional_adoption AS (
    SELECT 
        state,
        COUNT(DISTINCT make) as unique_manufacturers,
        COUNT(DISTINCT model) as unique_models,
        COUNT(*) as total_ev_registrations,
        AVG(base_msrp) as avg_price,
        AVG(electric_range) as avg_range
    FROM ev_population
    WHERE model_year >= 2020
        AND state IS NOT NULL
    GROUP BY state
    HAVING COUNT(*) >= 50
),

adoption_metrics AS (
    SELECT 
        *,
        ROUND(total_ev_registrations::NUMERIC / NULLIF(unique_models, 0), 1) as avg_registrations_per_model,
        CASE 
            WHEN total_ev_registrations >= 10000 THEN 'High Adoption'
            WHEN total_ev_registrations >= 1000 THEN 'Moderate Adoption'
            WHEN total_ev_registrations >= 100 THEN 'Low Adoption'
            ELSE 'Minimal Adoption'
        END as adoption_level,
        ROUND(unique_models::NUMERIC / NULLIF(unique_manufacturers, 0), 1) as models_per_manufacturer
    FROM regional_adoption
)

SELECT 
    state,
    unique_manufacturers,
    unique_models,
    total_ev_registrations,
    ROUND(avg_price, 0) as avg_price,
    ROUND(avg_range, 0) as avg_range,
    avg_registrations_per_model,
    models_per_manufacturer,
    adoption_level,
    RANK() OVER (ORDER BY total_ev_registrations DESC) as adoption_rank
FROM adoption_metrics
ORDER BY total_ev_registrations DESC;