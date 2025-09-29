#!/usr/bin/env python3
"""
Comprehensive Test Runner for EV Data Management Queries
Tests all queries on both SQL and MongoDB to ensure everything works correctly.
"""

import sys
import time
import json
from pathlib import Path
from datetime import datetime

# Add the queries module to path
sys.path.append(str(Path(__file__).parent / "queries"))

from queries.common.unified_query_executor import QueryExecutor


class QueryTestRunner:
    def __init__(self):
        self.executor = QueryExecutor()
        self.results = {
            'start_time': datetime.now(),
            'total_queries': 0,
            'sql_success': 0,
            'sql_failures': 0,
            'mongodb_success': 0,
            'mongodb_failures': 0,
            'failed_queries': [],
            'query_results': []
        }
    
    def test_query(self, phase, query_name, database_type):
        """Test a single query and return results"""
        try:
            # Capture stdout to avoid cluttering test output
            import io
            import contextlib
            
            output_capture = io.StringIO()
            
            with contextlib.redirect_stdout(output_capture):
                # Execute the query using the unified executor
                result = self.executor.execute_query(query_name, phase, database_type.lower())
            
            if database_type.lower() == 'sql':
                data = result.get('sql', [])
                execution_time = result.get('times', {}).get('sql', 0)
            else:  # mongodb
                data = result.get('mongodb', [])
                execution_time = result.get('times', {}).get('mongodb', 0)
            
            # Check if we got valid results
            if isinstance(data, list):
                return {
                    'success': True,
                    'execution_time': execution_time,
                    'row_count': len(data),
                    'error': None
                }
            else:
                return {
                    'success': False,
                    'execution_time': execution_time,
                    'row_count': 0,
                    'error': 'Invalid result format'
                }
                
        except Exception as e:
            return {
                'success': False,
                'execution_time': 0,
                'row_count': 0,
                'error': str(e)
            }
    
    def discover_queries(self):
        """Discover all available queries from the file system"""
        queries = []
        queries_dir = Path(__file__).parent / "queries"
        
        # Check both SQL and MongoDB directories
        for db_type in ['sql', 'mongodb']:
            db_dir = queries_dir / db_type
            if not db_dir.exists():
                continue
                
            for phase_dir in sorted(db_dir.iterdir()):
                if not phase_dir.is_dir() or not phase_dir.name.startswith('phase_'):
                    continue
                    
                phase = phase_dir.name
                
                for query_file in sorted(phase_dir.iterdir()):
                    if db_type == 'sql' and query_file.suffix == '.sql':
                        query_name = query_file.stem
                        queries.append((phase, query_name, 'SQL'))
                    elif db_type == 'mongodb' and query_file.suffix == '.json':
                        query_name = query_file.stem
                        queries.append((phase, query_name, 'MongoDB'))
        
        return queries
    
    def run_all_tests(self, verbose=True):
        """Run tests on all discovered queries"""
        print("EV Data Management - Comprehensive Query Test Runner")
        print("=" * 60)
        
        # Discover all queries
        queries = self.discover_queries()
        self.results['total_queries'] = len(queries)
        
        if not queries:
            print("ERROR: No queries found!")
            return False
        
        # Group queries by name for side-by-side comparison
        query_groups = {}
        for phase, query_name, db_type in queries:
            key = (phase, query_name)
            if key not in query_groups:
                query_groups[key] = {'SQL': None, 'MongoDB': None}
            query_groups[key][db_type] = True
        
        # Count SQL and MongoDB queries separately
        sql_count = len([q for q in queries if q[2] == 'SQL'])
        mongodb_count = len([q for q in queries if q[2] == 'MongoDB'])
        
        print(f"Found {len(queries)} total query files:")
        print(f"    SQL: {sql_count} queries")
        print(f"    MongoDB: {mongodb_count} queries")
        print(f"    Unique query names: {len(query_groups)}")
        print("Starting comprehensive test run...\n")
        
        test_number = 1
        for (phase, query_name), db_types in sorted(query_groups.items()):
            print(f"[{test_number:2d}/{len(query_groups)}] Testing {phase}/{query_name}")
            
            query_result = {
                'phase': phase,
                'query_name': query_name,
                'sql_result': None,
                'mongodb_result': None
            }
            
            # Test SQL version if it exists
            if db_types['SQL']:
                if verbose:
                    print("    SQL...", end=" ")
                
                sql_result = self.test_query(phase, query_name, 'SQL')
                query_result['sql_result'] = sql_result
                
                if sql_result['success']:
                    self.results['sql_success'] += 1
                    if verbose:
                        print(f"PASS ({sql_result['row_count']} rows, {sql_result['execution_time']:.3f}s)")
                else:
                    self.results['sql_failures'] += 1
                    self.results['failed_queries'].append({
                        'phase': phase,
                        'query': query_name,
                        'database': 'SQL',
                        'error': sql_result['error']
                    })
                    if verbose:
                        print(f"FAIL {sql_result['error']}")
            
            # Test MongoDB version if it exists
            if db_types['MongoDB']:
                if verbose:
                    print("    MongoDB...", end=" ")
                
                mongodb_result = self.test_query(phase, query_name, 'MongoDB')
                query_result['mongodb_result'] = mongodb_result
                
                if mongodb_result['success']:
                    self.results['mongodb_success'] += 1
                    if verbose:
                        print(f"PASS ({mongodb_result['row_count']} rows, {mongodb_result['execution_time']:.3f}s)")
                else:
                    self.results['mongodb_failures'] += 1
                    self.results['failed_queries'].append({
                        'phase': phase,
                        'query': query_name,
                        'database': 'MongoDB',
                        'error': mongodb_result['error']
                    })
                    if verbose:
                        print(f"FAIL {mongodb_result['error']}")
            
            self.results['query_results'].append(query_result)
            
            if verbose:
                print()  # Empty line for readability
            
            test_number += 1
        
        # Calculate final results
        self.results['end_time'] = datetime.now()
        self.results['duration'] = (self.results['end_time'] - self.results['start_time']).total_seconds()
        
        return True
    
    def print_summary(self):
        """Print a comprehensive test summary"""
        print("\n" + "=" * 60)
        print("TEST SUMMARY")
        print("=" * 60)
        
        total_sql = self.results['sql_success'] + self.results['sql_failures']
        total_mongodb = self.results['mongodb_success'] + self.results['mongodb_failures']
        
        print(f"Total Duration: {self.results['duration']:.2f} seconds")
        print(f"Total Query Files Tested: {self.results['total_queries']}")
        print(f"Unique Queries: {len(self.results['query_results'])}")
        print()
        
        # SQL Results
        if total_sql > 0:
            sql_success_rate = (self.results['sql_success'] / total_sql) * 100
            print(f"SQL Database:")
            print(f"   Successful: {self.results['sql_success']}/{total_sql} ({sql_success_rate:.1f}%)")
            print(f"   Failed: {self.results['sql_failures']}/{total_sql}")
        
        # MongoDB Results
        if total_mongodb > 0:
            mongodb_success_rate = (self.results['mongodb_success'] / total_mongodb) * 100
            print(f"MongoDB:")
            print(f"   Successful: {self.results['mongodb_success']}/{total_mongodb} ({mongodb_success_rate:.1f}%)")
            print(f"   Failed: {self.results['mongodb_failures']}/{total_mongodb}")
        
        # Overall success rate
        total_tests = total_sql + total_mongodb
        total_successes = self.results['sql_success'] + self.results['mongodb_success']
        overall_success_rate = (total_successes / total_tests) * 100 if total_tests > 0 else 0
        
        print(f"\nOverall Success Rate: {total_successes}/{total_tests} ({overall_success_rate:.1f}%)")
        
        # Failed queries details
        if self.results['failed_queries']:
            print(f"\nFAILED QUERIES ({len(self.results['failed_queries'])}):")
            print("-" * 60)
            for failure in self.results['failed_queries']:
                print(f"   {failure['phase']}/{failure['query']} ({failure['database']})")
                print(f"   Error: {failure['error']}")
                print()
        else:
            print("\nALL QUERIES PASSED!")
        
        # Query coverage analysis
        both_db_queries = len([q for q in self.results['query_results'] 
                              if q['sql_result'] is not None and q['mongodb_result'] is not None])
        sql_only_queries = len([q for q in self.results['query_results'] 
                               if q['sql_result'] is not None and q['mongodb_result'] is None])
        mongodb_only_queries = len([q for q in self.results['query_results'] 
                                   if q['sql_result'] is None and q['mongodb_result'] is not None])
        
        print("QUERY COVERAGE ANALYSIS:")
        print(f"   Available in both databases: {both_db_queries}")
        print(f"   SQL only: {sql_only_queries}")
        print(f"   MongoDB only: {mongodb_only_queries}")
        
        print("\n" + "=" * 60)
    
    def save_detailed_report(self, filename="test_report.json"):
        """Save detailed test results to a JSON file"""
        # Convert datetime objects to strings for JSON serialization
        report_data = self.results.copy()
        report_data['start_time'] = self.results['start_time'].isoformat()
        report_data['end_time'] = self.results['end_time'].isoformat()
        
        with open(filename, 'w') as f:
            json.dump(report_data, f, indent=2, default=str)
        
        print(f"Detailed report saved to: {filename}")


def main():
    """Main test runner function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Test all EV Data Management queries')
    parser.add_argument('--quiet', '-q', action='store_true', 
                       help='Run in quiet mode (less verbose output)')
    parser.add_argument('--save-report', '-s', action='store_true',
                       help='Save detailed JSON report')
    parser.add_argument('--report-file', '-r', default='test_report.json',
                       help='Filename for the detailed report')
    
    args = parser.parse_args()
    
    # Create and run the test runner
    runner = QueryTestRunner()
    
    try:
        success = runner.run_all_tests(verbose=not args.quiet)
        
        if success:
            runner.print_summary()
            
            if args.save_report:
                runner.save_detailed_report(args.report_file)
            
            # Exit with error code if any tests failed
            if runner.results['failed_queries']:
                print(f"\nWARNING: {len(runner.results['failed_queries'])} queries failed. Exiting with error code 1.")
                sys.exit(1)
            else:
                print("\nAll tests passed!")
                sys.exit(0)
        else:
            print("ERROR: Test runner failed to initialize")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\nTest run interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()