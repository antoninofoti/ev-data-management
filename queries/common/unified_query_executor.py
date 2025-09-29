"""
Simple Query Executor
Execute queries without complexity.
"""

import time
import sys
from pathlib import Path
from typing import Dict

sys.path.append(str(Path(__file__).parent))
from query_loader import QueryLoader
from database_connectors import UnifiedDatabaseManager


class QueryExecutor:
    """Simple query executor"""
    
    def __init__(self):
        self.loader = QueryLoader()
        self.db_manager = UnifiedDatabaseManager()
    
    def execute_query(self, query_name: str, phase: str, database_type: str = "both") -> Dict:
        """Execute a query"""
        print(f"Executing {phase}/{query_name}")
        
        results = {"sql": [], "mongodb": [], "times": {}}
        
        if database_type in ["sql", "both"]:
            start = time.time()
            try:
                query = self.loader.load_sql_query(query_name, phase)
                results["sql"] = self.db_manager.postgresql.execute_query(query)
                results["times"]["sql"] = time.time() - start
                print(f"   SQL: {len(results['sql'])} rows in {results['times']['sql']:.3f}s")
            except Exception as e:
                print(f"   SQL error: {e}")
        
        if database_type in ["mongodb", "both"]:
            start = time.time()
            try:
                pipeline = self.loader.load_mongodb_query(query_name, phase)
                collection = self._get_collection_name(query_name)
                results["mongodb"] = self.db_manager.mongodb.execute_aggregation(collection, pipeline)
                results["times"]["mongodb"] = time.time() - start
                print(f"   MongoDB: {len(results['mongodb'])} rows in {results['times']['mongodb']:.3f}s")
            except Exception as e:
                print(f"   MongoDB error: {e}")
        
        return results
    
    def _get_collection_name(self, query_name: str) -> str:
        """Get collection name from query name - Complete mapping for all 37 queries"""
        
        # Complete mappings based on actual table/collection usage
        collection_mappings = {
            # Phase 1 - Market Fundamentals (4 queries)
            "Q1_1_market_growth_trajectory": "ev_sales_data",        # IEA time-series data
            "Q1_4_top_performing_models": "ev_population_data",      # Vehicle registrations
            "Q2_1_infrastructure_density": "charging_stations",      # Station locations
            "Q2_2_fast_charging_availability": "charging_stations",  # Station specifications
            
            # Phase 2 - Business Intelligence (4 queries)
            "Q1_2_market_share_evolution": "ev_population_data",     # Vehicle types by year
            "Q3_1_price_range_correlation": "ev_population_data",    # Price and range data
            "Q4_1_manufacturer_positioning": "ev_population_data",   # Make/brand analysis
            "Q5_1_urban_rural_distribution": "ev_population_data",   # Geographic distribution
            
            # Phase 3 - Advanced Analytics (4 queries)
            "Q3_3_seasonal_charging_patterns": "charging_stations",  # Station usage patterns
            "Q5_2_highway_charging_corridors": "charging_stations",  # Highway network
            "Q6_1_optimal_station_placement": "charging_stations",   # Location optimization
            "Q6_3_grid_impact_analysis": "charging_stations",        # Power grid analysis
            
            # Phase 4 - Regional Intelligence (6 queries)
            "Q1_3_regional_adoption_rate": "ev_population_data",     # State-level adoption
            "Q2_3_network_coverage_analysis": "charging_stations",   # Network gaps
            "Q2_4_infrastructure_gap_identification": "charging_stations", # Infrastructure gaps
            "Q4_2_brand_performance_by_region": "ev_population_data", # Regional brand data
            "Q4_3_technology_adoption_rate": "ev_population_data",   # Technology types
            "Q4_4_price_evolution_analysis": "ev_population_data",   # Price trends
            
            # Phase 5 - Italian Market Focus (7 queries)
            "Q1_1_italy_market_evolution": "ev_sales_data",          # Italy time-series
            "Q1_3_italy_charging_infrastructure": "charging_stations", # Italy stations
            "Q2_1_eu_country_comparison": "ev_sales_data",           # EU comparison
            "Q2_2_european_policy_impact": "ev_sales_data",          # EU policy data
            "Q3_1_italian_price_preferences": "ev_population_data",  # Italy vehicle prices
            "Q3_3_italian_brand_loyalty": "ev_population_data",      # Italy brand preferences
            "Q3_4_european_brand_dominance": "ev_population_data",   # European brands
            
            # Phase 6 - Global Market Dynamics (5 queries)
            "Q4_1_infrastructure_readiness": "ev_sales_data",        # Global infrastructure
            "Q4_2_cross_border_success": "ev_population_data",       # Brand penetration
            "Q5_1_global_market_leaders": "ev_sales_data",           # Global sales leaders
            "Q5_2_italy_vs_global_giants": "ev_sales_data",          # Italy vs global
            "Q5_3_global_brand_warfare": "ev_sales_data",            # Global competition
            "Q6_1_technology_adoption_patterns": "ev_sales_data",    # Tech adoption globally
            "Q6_2_policy_effectiveness_global": "ev_sales_data",     # Policy comparison
            
            # Phase 7 - USA vs China Geopolitical (5 queries)
            "Q7_1_usa_china_market_dominance": "ev_sales_data",      # USA/China market size
            "Q7_2_usa_china_technology_race": "ev_sales_data",       # USA/China tech
            "Q7_3_usa_china_infrastructure_race": "ev_sales_data",   # USA/China infrastructure
            "Q7_4_usa_china_oil_displacement": "ev_sales_data",      # USA/China oil impact
            "Q7_5_usa_china_future_projections": "ev_sales_data",    # USA/China projections
        }
        
        # Try exact match first
        if query_name in collection_mappings:
            return collection_mappings[query_name]
        
        # Fallback: search for partial match (for query name variations)
        for key, collection in collection_mappings.items():
            if key in query_name or query_name in key:
                return collection_mappings[key]
        
        # Last resort fallback based on keywords
        query_lower = query_name.lower()
        if "charging" in query_lower or "station" in query_lower or "infrastructure" in query_lower or "corridor" in query_lower or "network" in query_lower or "grid" in query_lower:
            return "charging_stations"
        elif "population" in query_lower or "model" in query_lower or "brand" in query_lower or "manufacturer" in query_lower or "price" in query_lower or "vehicle" in query_lower:
            return "ev_population_data"
        else:
            # Default to sales data for market/global/regional queries
            return "ev_sales_data"


if __name__ == "__main__":
    executor = QueryExecutor()
    result = executor.execute_query("Q1_1_market_growth_trajectory", "phase_1", "both")
    print(f"Results: SQL={len(result['sql'])}, MongoDB={len(result['mongodb'])}")