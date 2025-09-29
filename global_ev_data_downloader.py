#!/usr/bin/env python3
"""
Complete EV Data Downloader
Downloads all required EV datasets from Kaggle and Hugging Face and converts to CSV/JSON format.
"""

import os
import csv
import json
import requests
import subprocess
import zipfile
from pathlib import Path


class CompleteEVDownloader:
    def __init__(self, output_dir="data"):
        self.output_dir = Path(output_dir)
        self.create_directories()
    
    def create_directories(self):
        """Create necessary directories"""
        dirs = ["raw", "sql", "nosql"]
        for d in dirs:
            (self.output_dir / d).mkdir(parents=True, exist_ok=True)
    
    def download_file(self, url, filename):
        """Download a file from URL"""
        try:
            print(f"Downloading {filename}...")
            response = requests.get(url, timeout=60)
            if response.status_code == 200:
                file_path = self.output_dir / "raw" / filename
                file_path.write_bytes(response.content)
                print(f"Downloaded {filename} successfully")
                return file_path
            else:
                print(f"Failed to download {filename}: HTTP {response.status_code}")
                return None
        except Exception as e:
            print(f"Error downloading {filename}: {e}")
            return None
    
    def download_kaggle_dataset(self, dataset_id, expected_files=None):
        """Download dataset from Kaggle"""
        try:
            # Check if Kaggle API is configured
            kaggle_config = Path.home() / ".kaggle" / "kaggle.json"
            if not kaggle_config.exists():
                print(f"WARNING: Kaggle API not configured. Cannot download {dataset_id}")
                print("Please configure Kaggle API with: pip install kaggle")
                print("And place your kaggle.json in ~/.kaggle/kaggle.json")
                return []
            
            print(f"Downloading Kaggle dataset: {dataset_id}")
            
            # Create temp directory for download
            temp_dir = self.output_dir / "temp"
            temp_dir.mkdir(exist_ok=True)
            
            # Download with kaggle CLI
            result = subprocess.run([
                "kaggle", "datasets", "download", "-d", dataset_id, "-p", str(temp_dir), "--unzip"
            ], capture_output=True, text=True)
            
            if result.returncode != 0:
                print(f"Error downloading {dataset_id}: {result.stderr}")
                return []
            
            # Move CSV files to raw directory
            downloaded = []
            for csv_file in temp_dir.glob("*.csv"):
                target_file = self.output_dir / "raw" / csv_file.name
                csv_file.rename(target_file)
                downloaded.append(target_file)
                print(f"Downloaded: {csv_file.name}")
            
            # Clean up temp directory
            import shutil
            shutil.rmtree(temp_dir, ignore_errors=True)
            
            return downloaded
            
        except Exception as e:
            print(f"Error downloading {dataset_id}: {e}")
            return []
    
    def download_all_datasets(self):
        """Download all required datasets"""
        print("=" * 60)
        print("DOWNLOADING ALL EV DATASETS")
        print("=" * 60)
        
        downloaded_files = []
        
        # 1. Global EV Charging Stations Dataset (Hugging Face)
        print("\n1. Downloading Global EV Charging Stations (Hugging Face)...")
        downloaded_files.extend(self.download_charging_stations())
        
        # 2. IEA Global EV Data 2024 (Kaggle)
        print("\n2. Downloading IEA Global EV Data 2024 (Kaggle)...")
        downloaded_files.extend(
            self.download_kaggle_dataset("alphaamadoubalde/iea-global-ev-data-2024")
        )
        
        # 3. Electric Vehicle Population Data 2024 (Kaggle)
        print("\n3. Downloading Electric Vehicle Population Data 2024 (Kaggle)...")
        downloaded_files.extend(
            self.download_kaggle_dataset("utkarshx27/electric-vehicle-population-data")
        )
        
        print(f"\nTotal files downloaded: {len(downloaded_files)}")
        for file in downloaded_files:
            print(f"  - {file.name}")
        
        return downloaded_files

    def download_charging_stations(self):
        """Download only the main charging stations data from Hugging Face (not summary files)"""
        base_url = "https://huggingface.co/datasets/TarekMasryo/Global-EV-Charging-Stations/resolve/main/data/"
        files = [
            "charging_stations_2025_world.csv"  # Only file actually used by queries
        ]
        
        downloaded = []
        for filename in files:
            file_path = self.download_file(base_url + filename, filename)
            if file_path:
                downloaded.append(file_path)
        
        return downloaded
    
    def csv_to_json(self, csv_file, json_file):
        """Convert CSV to JSON format"""
        try:
            data = []
            with open(csv_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    data.append(row)
            
            with open(json_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            
            print(f"Converted {csv_file.name} to {json_file.name} ({len(data)} records)")
            return True
        except Exception as e:
            print(f"Error converting {csv_file} to JSON: {e}")
            return False
    
    def process_files(self):
        """Process downloaded files for SQL and NoSQL with detailed logging"""
        raw_dir = self.output_dir / "raw"
        sql_dir = self.output_dir / "sql"
        nosql_dir = self.output_dir / "nosql"
        
        # Get all CSV files
        csv_files = list(raw_dir.glob("*.csv"))
        
        print("\n" + "=" * 60)
        print("PROCESSING FILES FOR DATABASE SETUP")
        print("=" * 60)
        print(f"Found {len(csv_files)} CSV files to process:")
        for csv_file in csv_files:
            print(f"  - {csv_file.name}")
        
        # Copy CSV files to SQL directory (for PostgreSQL)
        print(f"Copying {len(csv_files)} files to SQL directory...")
        for csv_file in csv_files:
            sql_file = sql_dir / csv_file.name
            sql_file.write_bytes(csv_file.read_bytes())
            print(f"  Copied {csv_file.name}")
        
        # Convert CSV to JSON for MongoDB
        print(f"Converting {len(csv_files)} files to JSON for MongoDB...")
        successful_conversions = 0
        for csv_file in csv_files:
            json_file = nosql_dir / f"{csv_file.stem}.json"
            if self.csv_to_json(csv_file, json_file):
                successful_conversions += 1
        
        print(f"Processing completed:")
        print(f"  - {len(csv_files)} CSV files copied to SQL directory")
        print(f"  - {successful_conversions} JSON files created for MongoDB")
        
        # Validation
        sql_files = list(sql_dir.glob("*.csv"))
        nosql_files = list(nosql_dir.glob("*.json"))
        
        if len(sql_files) == len(nosql_files) == len(csv_files):
            print(f"  Perfect symmetry achieved: {len(csv_files)} files in each directory")
        else:
            print(f"  Asymmetry detected:")
            print(f"     - Raw: {len(csv_files)} CSV files")
            print(f"     - SQL: {len(sql_files)} CSV files") 
            print(f"     - NoSQL: {len(nosql_files)} JSON files")
    
    def run(self):
        """Execute complete download and processing"""
        print("Starting Complete EV Data Download")
        print("=" * 40)
        
        # Download all datasets
        self.download_all_datasets()
        
        # Run preprocessing on downloaded data
        print("\nSTARTING DATA PREPROCESSING")
        print("=" * 60)
        
        try:
            from data_preprocessor import EVDataPreprocessor
            preprocessor = EVDataPreprocessor()
            preprocessor.process_all_files()
        except ImportError:
            print("Data preprocessor not found, falling back to basic processing")
            self.process_files()
        
        print("\nDOWNLOAD AND PROCESSING COMPLETED SUCCESSFULLY")
        print("=" * 60)
        print("\nNext steps:")
        print("1. Run 'python setup_databases.py' to load cleaned data into databases")
        print("2. Run 'python demo.py' to test queries")
        print("3. Run 'python index_performance_analyzer.py' for performance analysis")
        
        return True


if __name__ == "__main__":
    downloader = CompleteEVDownloader()
    downloader.run()