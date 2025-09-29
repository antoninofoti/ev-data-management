"""
Query Loader
Loads SQL and JSON files for queries.
"""

import json
from pathlib import Path
from typing import Dict, List


class QueryLoader:
    """Simple file loader for queries"""
    
    def __init__(self):
        # Auto-detect query directory
        self.queries_dir = Path(__file__).parent.parent
    
    def load_sql_query(self, query_name: str, phase: str) -> str:
        """Load SQL query from file"""
        sql_file = self.queries_dir / "sql" / phase / f"{query_name}.sql"
        if not sql_file.exists():
            raise FileNotFoundError(f"SQL file not found: {sql_file}")
        return sql_file.read_text(encoding='utf-8')
    
    def load_mongodb_query(self, query_name: str, phase: str) -> List[Dict]:
        """Load MongoDB pipeline from JSON file"""
        json_file = self.queries_dir / "mongodb" / phase / f"{query_name}.json"
        if not json_file.exists():
            raise FileNotFoundError(f"MongoDB file not found: {json_file}")
        
        with open(json_file, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def list_queries(self) -> Dict:
        """List available queries"""
        result = {"sql": {}, "mongodb": {}}
        
        # List SQL queries
        sql_dir = self.queries_dir / "sql"
        if sql_dir.exists():
            for phase_dir in sql_dir.iterdir():
                if phase_dir.is_dir():
                    files = [f.stem for f in phase_dir.glob("*.sql")]
                    if files:
                        result["sql"][phase_dir.name] = sorted(files)
        
        # List MongoDB queries
        mongo_dir = self.queries_dir / "mongodb"
        if mongo_dir.exists():
            for phase_dir in mongo_dir.iterdir():
                if phase_dir.is_dir():
                    files = [f.stem for f in phase_dir.glob("*.json")]
                    if files:
                        result["mongodb"][phase_dir.name] = sorted(files)
        
        return result


if __name__ == "__main__":
    loader = QueryLoader()
    queries = loader.list_queries()
    print(f"Available: {len(queries['sql'])} SQL phases, {len(queries['mongodb'])} MongoDB phases")