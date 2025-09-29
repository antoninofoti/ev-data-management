#!/usr/bin/env python3
"""
EV Data Management - Query Testing Tool
"""

import sys
import argparse
from pathlib import Path

# Add queries directory to path
sys.path.append(str(Path(__file__).parent / "queries" / "common"))

try:
    from unified_query_executor import QueryExecutor
except ImportError:
    print("Error: Cannot import QueryExecutor. Check database setup.")
    sys.exit(1)


def list_queries():
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


def run_query(query_name, phase, database_type):
    """Execute a single query"""
    executor = QueryExecutor()
    
    print(f"Executing: {query_name} from {phase}")
    print(f"Database: {database_type}")
    print("-" * 50)
    
    try:
        result = executor.execute_query(query_name, phase, database_type)
        
        if database_type == "both":
            sql_time = result['times'].get('sql', 0)
            mongo_time = result['times'].get('mongodb', 0)
            sql_count = len(result.get('sql', []))
            mongo_count = len(result.get('mongodb', []))
            
            print(f"SQL Results: {sql_count} rows in {sql_time:.3f}s")
            print(f"MongoDB Results: {mongo_count} rows in {mongo_time:.3f}s")
            
            if sql_time > 0 and mongo_time > 0:
                winner = "SQL" if sql_time < mongo_time else "MongoDB"
                speedup = max(sql_time, mongo_time) / min(sql_time, mongo_time)
                print(f"Performance: {winner} is {speedup:.2f}x faster")
        
        elif database_type == "sql":
            sql_count = len(result.get('sql', []))
            sql_time = result['times'].get('sql', 0)
            print(f"SQL Results: {sql_count} rows in {sql_time:.3f}s")
        
        elif database_type == "mongodb":
            mongo_count = len(result.get('mongodb', []))
            mongo_time = result['times'].get('mongodb', 0)
            print(f"MongoDB Results: {mongo_count} rows in {mongo_time:.3f}s")
        
        return True
        
    except Exception as e:
        print(f"Error executing query: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description='EV Data Query Testing Tool')
    parser.add_argument('--query', '-q', help='Query name to execute')
    parser.add_argument('--phase', '-p', help='Phase name (e.g., phase_1)')
    parser.add_argument('--database', '-d', choices=['sql', 'mongodb', 'both'], 
                       default='both', help='Database to use')
    parser.add_argument('--list', '-l', action='store_true', 
                       help='List available queries')
    
    args = parser.parse_args()
    
    if args.list:
        list_queries()
        return
    
    if not args.query or not args.phase:
        queries = list_queries()
        print("\nSelect a query number (1-{}): ".format(len(queries)), end="")
        
        try:
            choice = int(input()) - 1
            if 0 <= choice < len(queries):
                query_name, phase, _ = queries[choice]
                run_query(query_name, phase, args.database)
            else:
                print("Invalid selection")
        except (ValueError, KeyboardInterrupt):
            print("Invalid input or cancelled")
    else:
        run_query(args.query, args.phase, args.database)


if __name__ == "__main__":
    main()