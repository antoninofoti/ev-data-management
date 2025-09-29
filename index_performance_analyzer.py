#!/usr/bin/env python3
"""
Index Performance Analyzer - Simplified Version

Demonstrates the impact of database indexes by running queries
with and without indexes and comparing performance.
"""

import os
import time
import json
import sys
from datetime import datetime
from pathlib import Path
import psycopg2
from dotenv import load_dotenv

# Add queries path for imports
sys.path.append(str(Path(__file__).parent / "queries" / "common"))
from unified_query_executor import QueryExecutor

load_dotenv()


class IndexAnalyzer:
    """Simple index performance analyzer"""
    
    def __init__(self):
        self.executor = QueryExecutor()
        self.pg_config = {
            "host": os.getenv("POSTGRES_HOST", "localhost"),
            "port": int(os.getenv("POSTGRES_PORT", "5432")),
            "database": os.getenv("POSTGRES_DB", "ev_global_analysis"),
            "user": os.getenv("POSTGRES_USER", "ev_admin"),
            "password": os.getenv("POSTGRES_PASSWORD", "ev_password123")
        }
        self.created_indexes = []
        self.output_dir = Path(__file__).parent / "index_analysis_results"
        self.output_dir.mkdir(exist_ok=True)
    
    def get_connection(self):
        """Get PostgreSQL connection"""
        return psycopg2.connect(**self.pg_config)
    
    def create_indexes(self):
        """Create essential indexes for testing"""
        indexes = [
            # Key indexes that should improve common query patterns
            ("idx_ev_sales_region_year", "ev_sales", "region_name, year"),
            ("idx_ev_sales_parameter", "ev_sales", "parameter, unit"),
            ("idx_charging_country", "charging_stations", "country_code"),
            ("idx_charging_power", "charging_stations", "CAST(power_kw AS NUMERIC)"),
            ("idx_population_state", "ev_population", "state, make"),
            ("idx_population_year", "ev_population", "model_year"),
        ]
        
        conn = self.get_connection()
        cursor = conn.cursor()
        
        print("Creating performance indexes...")
        created = 0
        
        for index_name, table, columns in indexes:
            try:
                # Drop if exists, then create
                cursor.execute(f"DROP INDEX IF EXISTS {index_name}")
                cursor.execute(f"CREATE INDEX {index_name} ON {table} ({columns})")
                conn.commit()
                self.created_indexes.append(index_name)
                created += 1
                print(f"  + {index_name}")
            except Exception as e:
                print(f"  - {index_name}: {e}")
                conn.rollback()
        
        cursor.close()
        conn.close()
        print(f"Created {created} indexes")
        return created
    
    def drop_indexes(self):
        """Remove created indexes"""
        if not self.created_indexes:
            return
        
        conn = self.get_connection()
        cursor = conn.cursor()
        
        print("Dropping indexes...")
        for index_name in self.created_indexes:
            try:
                cursor.execute(f"DROP INDEX IF EXISTS {index_name}")
                conn.commit()
                print(f"  + Dropped {index_name}")
            except Exception as e:
                print(f"  - Error dropping {index_name}: {e}")
        
        cursor.close()
        conn.close()
        self.created_indexes = []
    
    def test_query_performance(self, query_name, phase, iterations=3):
        """Test a query multiple times and return average execution time"""
        times = []
        
        for _ in range(iterations):
            try:
                result = self.executor.execute_query(query_name, phase, "sql")
                sql_time = result.get("times", {}).get("sql", 0)
                if sql_time > 0:
                    times.append(sql_time)
            except Exception as e:
                print(f"    Error: {e}")
        
        return sum(times) / len(times) if times else 0
    
    def run_analysis(self, test_queries=None):
        """Run complete index performance analysis"""
        if test_queries is None:
            # Default set of queries that benefit from indexing
            test_queries = [
                ("Q1_1_market_growth_trajectory", "phase_1"),
                ("Q2_1_infrastructure_density", "phase_1"), 
                ("Q1_2_market_share_evolution", "phase_2"),
                ("Q3_1_price_range_correlation", "phase_2"),
                ("Q1_3_regional_adoption_rate", "phase_4"),
                ("Q2_3_network_coverage_analysis", "phase_4"),
            ]
        
        print("=" * 60)
        print("INDEX PERFORMANCE ANALYSIS")
        print("=" * 60)
        print(f"Testing {len(test_queries)} queries")
        print()
        
        results = {
            "timestamp": datetime.now().isoformat(),
            "queries_tested": len(test_queries),
            "baseline_results": {},
            "indexed_results": {},
            "improvements": {}
        }
        
        # Step 1: Baseline testing (no indexes)
        print("Step 1: Baseline Performance (No Indexes)")
        print("-" * 40)
        
        for query_name, phase in test_queries:
            print(f"Testing {query_name}...", end=" ")
            baseline_time = self.test_query_performance(query_name, phase)
            results["baseline_results"][f"{phase}/{query_name}"] = baseline_time
            print(f"{baseline_time:.3f}s")
        
        # Step 2: Create indexes
        print(f"\nStep 2: Creating Indexes")
        print("-" * 40)
        indexes_created = self.create_indexes()
        results["indexes_created"] = indexes_created
        
        # Step 3: Test with indexes
        print(f"\nStep 3: Performance With Indexes")
        print("-" * 40)
        
        for query_name, phase in test_queries:
            print(f"Testing {query_name}...", end=" ")
            indexed_time = self.test_query_performance(query_name, phase)
            results["indexed_results"][f"{phase}/{query_name}"] = indexed_time
            print(f"{indexed_time:.3f}s")
        
        # Step 4: Calculate improvements
        print(f"\nStep 4: Performance Analysis")
        print("-" * 40)
        
        total_speedup = 0
        improvements_count = 0
        
        for query_key in results["baseline_results"].keys():
            baseline = results["baseline_results"][query_key]
            indexed = results["indexed_results"][query_key]
            
            if baseline > 0 and indexed > 0:
                speedup = baseline / indexed
                improvement_pct = (speedup - 1) * 100
                
                results["improvements"][query_key] = {
                    "baseline_time": baseline,
                    "indexed_time": indexed,
                    "speedup": speedup,
                    "improvement_percent": improvement_pct
                }
                
                query_display = query_key.split("/")[-1].replace("_", " ").title()
                
                if speedup > 1.05:  # At least 5% improvement
                    print(f"+ {query_display}: {improvement_pct:.1f}% faster ({speedup:.2f}x)")
                    improvements_count += 1
                else:
                    print(f"~ {query_display}: {improvement_pct:.1f}% change ({speedup:.2f}x)")
                
                total_speedup += speedup
        
        # Summary
        avg_speedup = total_speedup / len(test_queries) if test_queries else 0
        results["summary"] = {
            "queries_improved": improvements_count,
            "average_speedup": avg_speedup,
            "indexes_created": indexes_created
        }
        
        print(f"\nSUMMARY:")
        print(f"  • Queries tested: {len(test_queries)}")
        print(f"  • Indexes created: {indexes_created}")
        print(f"  • Queries improved: {improvements_count}")
        print(f"  • Average speedup: {avg_speedup:.2f}x")
        
        # Step 5: Cleanup
        print(f"\nStep 5: Cleanup")
        print("-" * 40)
        self.drop_indexes()
        
        # Save results
        self.save_results(results)
        
        return results
    
    def save_results(self, results):
        """Save analysis results"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Save JSON results
        json_file = self.output_dir / f"index_analysis_{timestamp}.json"
        with open(json_file, 'w') as f:
            json.dump(results, f, indent=2, default=str)
        
        # Generate simple report
        report_file = self.output_dir / f"index_report_{timestamp}.md"
        with open(report_file, 'w') as f:
            f.write("# Index Performance Analysis Report\n\n")
            f.write(f"**Generated:** {results['timestamp']}\n")
            f.write(f"**Queries Tested:** {results['queries_tested']}\n")
            f.write(f"**Indexes Created:** {results['summary']['indexes_created']}\n")
            f.write(f"**Queries Improved:** {results['summary']['queries_improved']}\n")
            f.write(f"**Average Speedup:** {results['summary']['average_speedup']:.2f}x\n\n")
            
            f.write("## Detailed Results\n\n")
            f.write("| Query | Baseline | With Index | Improvement |\n")
            f.write("|-------|----------|------------|-------------|\n")
            
            for query_key, data in results["improvements"].items():
                query_name = query_key.split("/")[-1].replace("_", " ").title()
                baseline = f"{data['baseline_time']:.3f}s"
                indexed = f"{data['indexed_time']:.3f}s"
                improvement = f"{data['improvement_percent']:.1f}%"
                f.write(f"| {query_name} | {baseline} | {indexed} | {improvement} |\n")
        
        print(f"\nResults saved:")
        print(f"{json_file}")
        print(f"{report_file}")


def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Database Index Performance Analyzer")
    parser.add_argument("--queries", nargs="+", 
                       help="Specific queries to test (format: phase_1:Q1_1_market_growth_trajectory)")
    
    args = parser.parse_args()
    
    # Parse specific queries if provided
    test_queries = None
    if args.queries:
        test_queries = []
        for query_spec in args.queries:
            if ":" in query_spec:
                phase, query_name = query_spec.split(":", 1)
                test_queries.append((query_name, phase))
            else:
                print(f"Warning: Invalid query format '{query_spec}'. Use 'phase_1:Q1_1_market_growth_trajectory'")
    
    try:
        analyzer = IndexAnalyzer()
        analyzer.run_analysis(test_queries)
        
        print("\n" + "=" * 60)
        print("ANALYSIS COMPLETED")
        print("=" * 60)
        print("Check the 'index_analysis_results' directory for detailed reports")
        
    except KeyboardInterrupt:
        print("\n\nAnalysis interrupted by user")
        try:
            analyzer = IndexAnalyzer()
            analyzer.drop_indexes()
        except:
            pass
    except Exception as e:
        print(f"\nError: {e}")
        print("Make sure Docker containers are running and databases are initialized")


if __name__ == "__main__":
    main()