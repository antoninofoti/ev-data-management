"""
Database Connectors
Direct connections to PostgreSQL and MongoDB.
"""

import os
import psycopg2
import pymongo
from typing import Dict, List
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class SimplePostgreSQL:
    """Minimal PostgreSQL connector"""
    
    def __init__(self):
        self.config = {
            "host": os.getenv("POSTGRES_HOST"),
            "port": int(os.getenv("POSTGRES_PORT", "5432")),
            "database": os.getenv("POSTGRES_DB"),
            "user": os.getenv("POSTGRES_USER"),
            "password": os.getenv("POSTGRES_PASSWORD")
        }
    
    def execute_query(self, query: str) -> List[Dict]:
        """Execute SQL query and return results as list of dicts"""
        conn = psycopg2.connect(**self.config)
        try:
            cursor = conn.cursor()
            cursor.execute(query)
            columns = [desc[0] for desc in cursor.description] if cursor.description else []
            rows = cursor.fetchall()
            return [dict(zip(columns, row)) for row in rows]
        finally:
            conn.close()


class SimpleMongoDB:
    """Minimal MongoDB connector"""
    
    def __init__(self):
        host = os.getenv("MONGO_HOST")
        port = int(os.getenv("MONGO_PORT", "27017"))
        db_name = os.getenv("MONGO_DB")
        user = os.getenv("MONGO_USER")
        password = os.getenv("MONGO_PASSWORD")
        
        self.client = pymongo.MongoClient(f"mongodb://{user}:{password}@{host}:{port}")
        self.db = self.client[db_name]
    
    def execute_aggregation(self, collection_name: str, pipeline: List[Dict]) -> List[Dict]:
        """Execute MongoDB aggregation pipeline"""
        collection = self.db[collection_name]
        return list(collection.aggregate(pipeline))


class UnifiedDatabaseManager:
    """Simple unified manager"""
    
    def __init__(self):
        self.postgresql = SimplePostgreSQL()
        self.mongodb = SimpleMongoDB()
