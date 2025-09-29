#!/usr/bin/env python3
"""
Loads CSV/JSON data into PostgreSQL and MongoDB.
"""

import os
import time
import csv
import json
import psycopg2
import pymongo
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


def wait_for_database(db_type="postgres", max_attempts=30):
    """Wait for database to be ready"""
    for attempt in range(max_attempts):
        try:
            if db_type == "postgres":
                conn = psycopg2.connect(
                    host=os.getenv('POSTGRES_HOST', 'localhost'),
                    port=5432,
                    database=os.getenv('POSTGRES_DB', 'ev_global_analysis'),
                    user=os.getenv('POSTGRES_USER', 'ev_admin'),
                    password=os.getenv('POSTGRES_PASSWORD', 'ev_password123')
                )
                conn.close()
                return True
            else:  # mongodb
                user = os.getenv('MONGO_USER', 'ev_admin')
                password = os.getenv('MONGO_PASSWORD', 'ev_password123')
                host = os.getenv('MONGO_HOST', 'localhost')
                client = pymongo.MongoClient(f"mongodb://{user}:{password}@{host}:27017")
                client.admin.command('ping')
                client.close()
                return True
        except:
            time.sleep(1)
    return False


def create_typed_table_from_csv(cursor, csv_file, table_name):
    """Create PostgreSQL table with proper data types AND load data"""
    
    # Analyze CSV to determine types
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        headers = next(reader)
        
        # Read first few rows to guess types
        sample_rows = []
        for i, row in enumerate(reader):
            if i >= 100:  # Sample first 100 rows
                break
            sample_rows.append(row)
        
        # Analyze column types
        columns = []
        for i, header in enumerate(headers):
            col_values = [row[i] if i < len(row) else '' for row in sample_rows]
            col_type = guess_column_type(col_values)
            columns.append(f'"{header}" {col_type}')
        
        column_def = ', '.join(columns)
    
    # Drop table if exists and create new one
    cursor.execute(f'DROP TABLE IF EXISTS "{table_name}"')
    cursor.execute(f'CREATE TABLE "{table_name}" ({column_def})')
    print(f"   Created table {table_name} with typed columns")
    
    # Now load data into the table
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        headers = next(reader)  # Skip header
        
        # Prepare INSERT statement
        placeholders = ','.join(['%s'] * len(headers))
        insert_sql = f'INSERT INTO "{table_name}" VALUES ({placeholders})'
        
        # Load in batches
        batch_size = 1000
        batch_data = []
        count = 0
        
        for row in reader:
            # Ensure correct number of columns
            while len(row) < len(headers):
                row.append(None)
            
            # Convert empty strings to None
            row = [val if val and val.strip() else None for val in row[:len(headers)]]
            batch_data.append(row)
            count += 1
            
            if len(batch_data) >= batch_size:
                cursor.executemany(insert_sql, batch_data)
                batch_data = []
                
                if count % 10000 == 0:
                    print(f"      Imported {count:,} records...")
        
        # Insert remaining
        if batch_data:
            cursor.executemany(insert_sql, batch_data)
    
    print(f"   Completed: {count:,} records imported to {table_name}")


def guess_column_type(values):
    """Guess PostgreSQL column type from sample values"""
    non_empty_values = [v.strip() for v in values if v and v.strip()]
    
    if not non_empty_values:
        return 'TEXT'
    
    # Check if all values are numeric (decimal or integer)
    all_numeric = True
    has_decimal = False
    
    try:
        for v in non_empty_values[:20]:
            float_val = float(v)
            # Check if it has decimal part
            if '.' in v or float_val != int(float_val):
                has_decimal = True
    except (ValueError, TypeError):
        all_numeric = False
    
    if all_numeric:
        if has_decimal:
            return 'DECIMAL(15,4)'
        else:
            return 'INTEGER'
    
    # Default to VARCHAR with appropriate length
    max_length = max(len(str(v)) for v in non_empty_values[:50])
    if max_length <= 50:
        return 'VARCHAR(100)'  # Be generous with varchar
    elif max_length <= 150:
        return 'VARCHAR(200)'
    else:
        return 'TEXT'


def create_table_from_csv(cursor, csv_file, table_name):
    """Legacy function - now uses typed table creation"""
    return create_typed_table_from_csv(cursor, csv_file, table_name)


def import_ev_population_data(cursor):
    """Import the Electric_Vehicle_Population_Data.csv into PostgreSQL"""
    csv_file = Path(__file__).parent / "data" / "raw" / "Electric_Vehicle_Population_Data.csv"
    
    if not csv_file.exists():
        print(f"   WARNING: {csv_file.name} not found, skipping EV population data")
        return
    
    print(f"   Loading {csv_file.name} -> ev_population (this may take a while...)")
    
    # Create the ev_population table
    cursor.execute("DROP TABLE IF EXISTS ev_population")
    cursor.execute("""
        CREATE TABLE ev_population (
            vin_1_10 TEXT,
            county TEXT,
            city TEXT,
            state TEXT,
            postal_code TEXT,
            model_year TEXT,
            make TEXT,
            model TEXT,
            electric_vehicle_type TEXT,
            cafv_eligibility TEXT,
            electric_range TEXT,
            base_msrp TEXT,
            legislative_district TEXT,
            dol_vehicle_id TEXT,
            vehicle_location TEXT,
            electric_utility TEXT,
            census_tract_2020 TEXT
        )
    """)
    
    # Import data in batches for better performance
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        headers = next(reader)  # Skip header row
        
        count = 0
        batch_size = 1000
        batch_data = []
        
        for row in reader:
            # Handle rows that may have fewer columns than expected
            while len(row) < 17:
                row.append('')
            
            batch_data.append(row[:17])  # Take only first 17 columns
            count += 1
            
            if len(batch_data) >= batch_size:
                # Insert batch
                cursor.executemany(
                    "INSERT INTO ev_population VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)",
                    batch_data
                )
                batch_data = []
                
                if count % 10000 == 0:
                    print(f"      Imported {count:,} records...")
        
        # Insert remaining data
        if batch_data:
            cursor.executemany(
                "INSERT INTO ev_population VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)",
                batch_data
            )
    
    print(f"   Completed: {count:,} records imported to ev_population table")


def setup_postgresql():
    """Setup PostgreSQL with CSV data"""
    if not wait_for_database("postgres"):
        print("ERROR: PostgreSQL not ready")
        return False
    
    print("Setting up PostgreSQL...")
    
    # Use hardcoded values since .env doesn't exist yet - matches docker-compose.yml
    conn = psycopg2.connect(
        host=os.getenv('POSTGRES_HOST', 'localhost'),
        port=5432,
        database=os.getenv('POSTGRES_DB', 'ev_global_analysis'),
        user=os.getenv('POSTGRES_USER', 'ev_admin'),
        password=os.getenv('POSTGRES_PASSWORD', 'ev_password123')
    )
    
    cursor = conn.cursor()
    
    # Mapping of CSV filenames to table names used by queries
    file_to_table_mapping = {
        'IEA Global EV Data 2024': 'ev_sales',
        'charging_stations_2025_world': 'charging_stations',
        'Electric_Vehicle_Population_Data': 'ev_population'
    }
    
    # Load CSV files from data/sql directory
    data_dir = Path(__file__).parent / "data" / "sql"
    if data_dir.exists():
        for csv_file in data_dir.glob("*.csv"):
            file_stem = csv_file.stem
            table_name = file_to_table_mapping.get(file_stem, file_stem)
            
            print(f"   Loading {csv_file.name} -> {table_name}")
            try:
                create_table_from_csv(cursor, csv_file, table_name)
                conn.commit()
            except Exception as e:
                print(f"   ERROR loading {csv_file.name}: {e}")
                conn.rollback()
    
    cursor.close()
    conn.close()
    print("PostgreSQL setup complete")
    return True


def setup_mongodb():
    """Setup MongoDB with JSON data"""
    if not wait_for_database("mongodb"):
        print("ERROR: MongoDB not ready")
        return False
    
    print("Setting up MongoDB...")
    
    # Use hardcoded values since .env doesn't exist yet - matches docker-compose.yml
    user = os.getenv('MONGO_USER', 'ev_admin')
    password = os.getenv('MONGO_PASSWORD', 'ev_password123')
    host = os.getenv('MONGO_HOST', 'localhost')
    db_name = os.getenv('MONGO_DB', 'ev_global_analysis')
    
    client = pymongo.MongoClient(f"mongodb://{user}:{password}@{host}:27017/")
    db = client[db_name]
    
    # Mapping of JSON filenames to MongoDB collection names used by queries
    file_to_collection_mapping = {
        'IEA Global EV Data 2024': 'ev_sales_data',
        'charging_stations_2025_world': 'charging_stations',
        'Electric_Vehicle_Population_Data': 'ev_population_data'
    }
    
    data_dir = Path(__file__).parent / "data" / "nosql"
    
    if data_dir.exists():
        for json_file in data_dir.glob("*.json"):
            file_stem = json_file.stem
            collection_name = file_to_collection_mapping.get(file_stem, file_stem)
            
            print(f"   Loading {json_file.name} -> {collection_name}")
            
            try:
                # Drop existing collection
                db.drop_collection(collection_name)
                
                # Load and insert JSON data
                with open(json_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                if isinstance(data, list):
                    if data:  # Check if list is not empty
                        db[collection_name].insert_many(data)
                        print(f"   Inserted {len(data)} documents")
                else:
                    db[collection_name].insert_one(data)
                    print(f"   Inserted 1 document")
                    
            except Exception as e:
                print(f"   ERROR loading {json_file.name}: {e}")
    
    client.close()
    print("MongoDB setup complete")
    return True


def main():
    """Main setup function"""
    print("Database Setup Starting")
    print("=" * 30)
    
    postgres_ok = setup_postgresql()
    mongodb_ok = setup_mongodb()
    
    if postgres_ok and mongodb_ok:
        print("All databases ready")
        return True
    else:
        print("WARNING: Some databases failed")
        return False


if __name__ == "__main__":
    success = main()
    if not success:
        exit(1)