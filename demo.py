#!/usr/bin/env python3
"""
EV Data Management - Simple Demo Script
Shows actual query results and performance for selected queries.
"""

import sys
import time
import json
import argparse
from pathlib import Path
from typing import Dict, List

# Add queries directory to path
sys.path.append(str(Path(__file__).parent / "queries" / "common"))

try:
    from unified_query_executor import QueryExecutor
    from query_loader import QueryLoader
except ImportError:
    print("ERROR: Cannot import required modules. Check database setup.")
    sys.exit(1)


class DemoRunner:
    """Simple demo runner with nice output formatting"""
    
    def __init__(self):
        self.executor = QueryExecutor()
        self.loader = QueryLoader()
    
    def list_queries(self):
        """List available queries by scanning the filesystem"""
        queries = []
        queries_dir = Path(__file__).parent / "queries"
        
        # Scan SQL queries
        sql_dir = queries_dir / "sql"
        if sql_dir.exists():
            for phase_dir in sorted(sql_dir.iterdir()):
                if phase_dir.is_dir():
                    phase_name = phase_dir.name
                    for sql_file in sorted(phase_dir.glob("*.sql")):
                        query_name = sql_file.stem
                        # Generate description from query name
                        desc = query_name.replace("_", " ").title()
                        queries.append((query_name, phase_name, desc, "SQL"))
        
        # Scan MongoDB queries
        mongo_dir = queries_dir / "mongodb"
        if mongo_dir.exists():
            for phase_dir in sorted(mongo_dir.iterdir()):
                if phase_dir.is_dir():
                    phase_name = phase_dir.name
                    for json_file in sorted(phase_dir.glob("*.json")):
                        query_name = json_file.stem
                        # Only add if not already present from SQL
                        if not any(q[0] == query_name and q[1] == phase_name for q in queries):
                            desc = query_name.replace("_", " ").title()
                            queries.append((query_name, phase_name, desc, "MongoDB"))
        
        # Sort by phase and query name
        queries.sort(key=lambda x: (x[1], x[0]))
        
        print("Available queries:")
        for i, (query, phase, desc, db_type) in enumerate(queries, 1):
            print(f"{i:2d}. {query} ({phase}) - {desc}")
        
        return [(q[0], q[1], q[2]) for q in queries]  # Return without db_type for compatibility
    
    def print_header(self, title: str):
        """Print a formatted header"""
        print("\n" + "="*60)
        print(f"EV DATA DEMO: {title}")
        print("="*60)
    
    def print_separator(self):
        """Print a separator line"""
        print("-" * 60)
    
    def show_query_content(self, query_name: str, phase: str, db_type: str):
        """Show the actual query being executed"""
        print(f"\nQuery: {query_name.replace('_', ' ').title()}")
        print(f"Phase: {phase}")
        print(f"Database: {db_type.upper()}")
        
        try:
            if db_type == "sql":
                query = self.loader.load_sql_query(query_name, phase)
                print(f"\nSQL Query:")
                print("   " + query.replace('\n', '\n   '))
            elif db_type == "mongodb":
                pipeline = self.loader.load_mongodb_query(query_name, phase)
                print(f"\nMongoDB Pipeline:")
                formatted_pipeline = json.dumps(pipeline, indent=2)
                print("   " + formatted_pipeline.replace('\n', '\n   '))
        except Exception as e:
            print(f"   WARNING: Could not load query: {e}")
    
    def format_results_as_table(self, results: List[Dict]) -> str:
        """Format SQL results as a complete table"""
        if not results:
            return "   No results found"
        
        output = []
        output.append(f"\n   Total Results: {len(results)} rows\n")
        
        # Get all column names
        if results:
            columns = list(results[0].keys())
            
            # Calculate column widths
            col_widths = {}
            for col in columns:
                # Start with column name length
                max_width = len(col)
                # Check all values
                for row in results:
                    val = row.get(col, "")
                    if isinstance(val, float):
                        str_val = f"{val:.2f}"
                    else:
                        str_val = str(val) if val is not None else "NULL"
                    max_width = max(max_width, len(str_val))
                col_widths[col] = min(max_width, 50)  # Cap at 50 chars
            
            # Print header
            header = " | ".join(col.ljust(col_widths[col]) for col in columns)
            output.append(f"   {header}")
            output.append("   " + "-" * len(header))
            
            # Print all rows
            for row in results:
                row_values = []
                for col in columns:
                    val = row.get(col, "")
                    if isinstance(val, float):
                        str_val = f"{val:.2f}"
                    elif val is None:
                        str_val = "NULL"
                    else:
                        str_val = str(val)
                    # Truncate if too long
                    if len(str_val) > col_widths[col]:
                        str_val = str_val[:col_widths[col]-3] + "..."
                    row_values.append(str_val.ljust(col_widths[col]))
                output.append(f"   {' | '.join(row_values)}")
        
        return "\n".join(output)
    
    def format_results_as_json(self, results: List[Dict]) -> str:
        """Format MongoDB results as complete JSON"""
        if not results:
            return "   No results found"
        
        output = []
        output.append(f"\n   Total Results: {len(results)} documents\n")
        
        # Format as pretty JSON
        json_output = json.dumps(results, indent=2, default=str)
        # Indent each line
        indented_json = "\n".join("   " + line for line in json_output.split("\n"))
        output.append(indented_json)
        
        return "\n".join(output)
    
    def run_demo_query(self, query_name: str, phase: str, database_type: str = "both"):
        """Run a single query with nice demo output"""
        self.print_header(f"{query_name.replace('_', ' ').title()}")
        
        if database_type == "both":
            print("Running comparison between SQL and MongoDB...")
            self.print_separator()
            
            # SQL execution
            print("\nSQL EXECUTION")
            self.show_query_content(query_name, phase, "sql")
            
            start_time = time.time()
            result = self.executor.execute_query(query_name, phase, "sql")
            sql_time = time.time() - start_time
            
            print(f"\nSQL Results (Table Format):")
            print(self.format_results_as_table(result.get("sql", [])))
            print(f"\nSQL Execution Time: {sql_time:.3f} seconds")
            
            self.print_separator()
            
            # MongoDB execution
            print("\nMONGODB EXECUTION")
            self.show_query_content(query_name, phase, "mongodb")
            
            start_time = time.time()
            result = self.executor.execute_query(query_name, phase, "mongodb")
            mongo_time = time.time() - start_time
            
            print(f"\nMongoDB Results (JSON Format):")
            print(self.format_results_as_json(result.get("mongodb", [])))
            print(f"\nMongoDB Execution Time: {mongo_time:.3f} seconds")
            
            # Performance comparison
            self.print_separator()
            print("\nPERFORMANCE COMPARISON")
            if sql_time > 0 and mongo_time > 0:
                if sql_time < mongo_time:
                    speedup = mongo_time / sql_time
                    print(f"Winner: SQL (PostgreSQL)")
                    print(f"SQL is {speedup:.2f}x faster than MongoDB")
                else:
                    speedup = sql_time / mongo_time
                    print(f"Winner: MongoDB")
                    print(f"MongoDB is {speedup:.2f}x faster than SQL")
            
        else:
            # Single database execution
            self.show_query_content(query_name, phase, database_type)
            
            start_time = time.time()
            result = self.executor.execute_query(query_name, phase, database_type)
            execution_time = time.time() - start_time
            
            db_results = result.get(database_type, [])
            
            if database_type == "sql":
                print(f"\nResults (Table Format):")
                print(self.format_results_as_table(db_results))
            else:  # mongodb
                print(f"\nResults (JSON Format):")
                print(self.format_results_as_json(db_results))
            
            print(f"\nExecution Time: {execution_time:.3f} seconds")
    
    def run_demo_suite(self):
        """Run a suite of demo queries"""
        self.print_header("EV DATA MANAGEMENT DEMO SUITE")
        
        demo_queries = [            
            ("Q1_1_market_growth_trajectory", "phase_1"),
            ("Q2_1_infrastructure_density", "phase_1"), 
            ("Q1_2_market_share_evolution", "phase_2"),
            ("Q3_1_price_range_correlation", "phase_2"),
            ("Q1_3_regional_adoption_rate", "phase_4"),
            ("Q2_3_network_coverage_analysis", "phase_4"),
        ]
        
        print("Running demo queries to showcase database performance...")
        
        for query_name, phase in demo_queries:
            self.run_demo_query(query_name, phase, "both")
        
        print("\n" + "="*60)
        print("Demo completed! Thank you for watching.")
        print("="*60)


def main():
    """Main demo function"""
    parser = argparse.ArgumentParser(description='EV Data Management Demo Tool')
    parser.add_argument('--query', '-q', help='Query name to execute')
    parser.add_argument('--phase', '-p', help='Phase name (e.g., phase_1)')
    parser.add_argument('--database', '-d', choices=['sql', 'mongodb', 'both'], 
                       default='both', help='Database to use (default: both)')
    parser.add_argument('--list', '-l', action='store_true', 
                       help='List available queries')
    parser.add_argument('--suite', '-s', action='store_true',
                       help='Run demo suite for presentations')
    parser.add_argument('--output', '-o', help='Save output to file (e.g., results.txt)')
    
    args = parser.parse_args()
    
    # Track output file info
    original_stdout = sys.stdout
    output_file = None
    output_filename = None
    
    if args.output:
        try:
            output_file = open(args.output, 'w', encoding='utf-8')
            output_filename = args.output
            sys.stdout = output_file
            # Also print to console that we're saving to file
            print(f"Saving output to: {output_filename}", file=original_stdout)
        except Exception as e:
            print(f"Error opening output file: {e}", file=original_stdout)
            return
    
    try:
        demo = DemoRunner()
        
        if args.list:
            demo.list_queries()
            return
        
        if args.suite:
            demo.run_demo_suite()
            return
        
        if args.query and args.phase:
            # Direct query execution
            demo.run_demo_query(args.query, args.phase, args.database)
            return
        
        # Interactive mode
        print("EV Data Management Demo Tool")
        print("\nAvailable demo modes:")
        print("1. Browse and select from all available queries")
        print("2. Full demo suite (recommended for presentations)")
        print("3. Enter specific query details")
        
        choice = input("\nSelect mode (1-3): ").strip()
        
        if choice == "1":
            # Browse and select queries
            queries = demo.list_queries()
            if not queries:
                print("No queries found!")
                return
            
            print(f"\nSelect a query number (1-{len(queries)}): ", end="")
            try:
                selection = int(input()) - 1
                if 0 <= selection < len(queries):
                    query_name, phase, _ = queries[selection]
                    
                    print("\nDatabase options:")
                    print("1. SQL only")
                    print("2. MongoDB only") 
                    print("3. Both (comparison)")
                    
                    db_choice = input("Select database (1-3, default: 3): ").strip() or "3"
                    db_map = {"1": "sql", "2": "mongodb", "3": "both"}
                    database_type = db_map.get(db_choice, "both")
                    
                    # Ask about output file
                    save_choice = input("\nSave results to file? (y/n, default: n): ").strip().lower()
                    if save_choice in ['y', 'yes']:
                        filename = input("Enter filename (e.g., results.txt): ").strip()
                        if filename:
                            # Redirect output to file
                            try:
                                output_file = open(filename, 'w', encoding='utf-8')
                                output_filename = filename
                                sys.stdout = output_file
                                print(f"Saving output to: {output_filename}", file=original_stdout)
                            except Exception as e:
                                print(f"Error opening output file: {e}")
                                return
                    
                    demo.run_demo_query(query_name, phase, database_type)
                else:
                    print("Invalid selection")
            except (ValueError, KeyboardInterrupt):
                print("Invalid input or cancelled")
        
        elif choice == "2":
            # Ask about output file for suite
            save_choice = input("\nSave suite results to file? (y/n, default: n): ").strip().lower()
            if save_choice in ['y', 'yes']:
                filename = input("Enter filename (e.g., suite_results.txt): ").strip()
                if filename:
                    # Redirect output to file
                    try:
                        output_file = open(filename, 'w', encoding='utf-8')
                        output_filename = filename
                        sys.stdout = output_file
                        print(f"Saving output to: {output_filename}", file=original_stdout)
                    except Exception as e:
                        print(f"Error opening output file: {e}")
                        return
            
            demo.run_demo_suite()
        
        elif choice == "3":
            # Manual entry
            print("\nEnter query details:")
            query = input("Query name: ").strip()
            if not query:
                print("Query name is required")
                return
            
            phase = input("Phase (default: phase_1): ").strip() or "phase_1"
            
            print("\nDatabase options:")
            print("1. SQL only")
            print("2. MongoDB only")
            print("3. Both (comparison)")
            
            db_choice = input("Select database (1-3, default: 3): ").strip() or "3"
            db_map = {"1": "sql", "2": "mongodb", "3": "both"}
            database_type = db_map.get(db_choice, "both")
            
            # Ask about output file
            save_choice = input("\nSave results to file? (y/n, default: n): ").strip().lower()
            if save_choice in ['y', 'yes']:
                filename = input("Enter filename (e.g., results.txt): ").strip()
                if filename:
                    # Redirect output to file
                    try:
                        output_file = open(filename, 'w', encoding='utf-8')
                        output_filename = filename
                        sys.stdout = output_file
                        print(f"Saving output to: {output_filename}", file=original_stdout)
                    except Exception as e:
                        print(f"Error opening output file: {e}")
                        return
            
            demo.run_demo_query(query, phase, database_type)
        
        else:
            print("Invalid selection")
    
    finally:
        # Restore stdout and close file if opened
        sys.stdout = original_stdout
        if output_file:
            output_file.close()
            if output_filename:
                print(f"Output saved to: {output_filename}")



if __name__ == "__main__":
    main()