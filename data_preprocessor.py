#!/usr/bin/env python3
"""
EV Data Preprocessor
Clean and validate raw data before database import.
"""

import csv
import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime


class EVDataPreprocessor:
    def __init__(self, data_dir="data"):
        self.data_dir = Path(data_dir)
        self.raw_dir = self.data_dir / "raw"
        self.processed_dir = self.data_dir / "processed"
        self.sql_dir = self.data_dir / "sql"
        self.nosql_dir = self.data_dir / "nosql"
        
        # Create processed directory
        self.processed_dir.mkdir(exist_ok=True)
    
    def clean_string(self, value: str) -> Optional[str]:
        """Clean strings by removing spaces and invalid characters"""
        if not value or value.strip() in ['', 'NULL', 'null', 'None', 'N/A', 'n/a']:
            return None
        
        cleaned = value.strip()
        # Remove control characters
        cleaned = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', cleaned)
        return cleaned if cleaned else None
    
    def clean_numeric(self, value: str, data_type="float") -> Optional[float]:
        """Clean and convert numeric values"""
        if not value:
            return None
            
        # Remove common non-numeric characters
        cleaned = str(value).replace('$', '').replace(',', '').replace('%', '').strip()
        
        # Handle special cases
        if cleaned.lower() in ['null', 'none', 'n/a', '', 'nan']:
            return None
            
        try:
            if data_type == "int":
                return int(float(cleaned))  # Convert via float to handle decimals
            return float(cleaned)
        except (ValueError, TypeError):
            return None
    
    def clean_year(self, value: str) -> Optional[int]:
        """Clean and validate years"""
        year = self.clean_numeric(value, "int")
        if year and 1990 <= year <= 2030:  # Reasonable range for EV vehicles
            return year
        return None
    
    def standardize_make(self, make: str) -> Optional[str]:
        """Standardize manufacturer names"""
        if not make:
            return None
            
        make = self.clean_string(make)
        if not make:
            return None
            
        # Mapping to standardize common names
        standardization_map = {
            'bmw': 'BMW',
            'tesla': 'Tesla',
            'audi': 'Audi', 
            'mercedes': 'Mercedes-Benz',
            'mercedes-benz': 'Mercedes-Benz',
            'volkswagen': 'Volkswagen',
            'vw': 'Volkswagen',
            'nissan': 'Nissan',
            'hyundai': 'Hyundai',
            'kia': 'Kia',
            'ford': 'Ford',
            'chevrolet': 'Chevrolet',
            'chevy': 'Chevrolet',
            'byd': 'BYD',
            'nio': 'NIO',
            'lucid': 'Lucid Motors',
            'rivian': 'Rivian',
            'polestar': 'Polestar'
        }
        
        make_lower = make.lower()
        return standardization_map.get(make_lower, make.title())
    
    def validate_coordinates(self, lat: str, lng: str) -> tuple:
        """Validate geographic coordinates"""
        try:
            lat_f = float(lat) if lat else None
            lng_f = float(lng) if lng else None
            
            if lat_f is not None and lng_f is not None:
                if -90 <= lat_f <= 90 and -180 <= lng_f <= 180:
                    return lat_f, lng_f
        except (ValueError, TypeError):
            pass
        return None, None
    
    def clean_ev_population_data(self, raw_data: List[Dict]) -> List[Dict]:
        """Clean EV population data"""
        cleaned_data = []
        
        for row in raw_data:
            cleaned_row = {}
            
            # Handle variable column names
            make = (self.standardize_make(row.get('make') or row.get('Make')))
            model = (self.clean_string(row.get('model') or row.get('Model')))
            
            if not make or not model:
                continue  # Skip rows without make/model
            
            cleaned_row['make'] = make
            cleaned_row['model'] = model
            
            # Year (handle different column names)
            year_field = (row.get('model_year') or row.get('Model Year') or 
                         row.get('year') or row.get('Year'))
            year = self.clean_year(year_field)
            if year:
                cleaned_row['model_year'] = year
            
            # Electric vehicle type
            ev_type_field = (row.get('electric_vehicle_type') or 
                           row.get('Electric Vehicle Type') or
                           row.get('EV Type'))
            ev_type = self.clean_string(ev_type_field)
            if ev_type:
                cleaned_row['electric_vehicle_type'] = ev_type
            
            # Electric range
            range_field = (row.get('electric_range') or 
                          row.get('Electric Range') or 
                          row.get('range'))
            electric_range = self.clean_numeric(range_field, "int")
            if electric_range and electric_range > 0:
                cleaned_row['electric_range'] = electric_range
            
            # Price
            price_field = (row.get('base_msrp') or 
                          row.get('Base MSRP') or 
                          row.get('MSRP') or 
                          row.get('price'))
            price = self.clean_numeric(price_field)
            if price and price > 0:
                cleaned_row['base_msrp'] = price
            
            # Location
            state_field = (row.get('state') or row.get('State'))
            city_field = (row.get('city') or row.get('City'))
            county_field = (row.get('county') or row.get('County'))
            
            state = self.clean_string(state_field)
            city = self.clean_string(city_field)
            county = self.clean_string(county_field)
            
            if state:
                cleaned_row['state'] = state
            if city:
                cleaned_row['city'] = city
            if county:
                cleaned_row['county'] = county
            
            # VIN (handle variants)
            vin_field = (row.get('vin_1_10') or 
                        row.get('VIN (1-10)') or 
                        row.get('VIN') or 
                        row.get('vin'))
            vin = self.clean_string(vin_field)
            if vin and len(vin) >= 10:
                cleaned_row['vin_1_10'] = vin
            
            # Keep record if we have at least make, model and location
            if cleaned_row.get('make') and cleaned_row.get('model') and (
                cleaned_row.get('state') or cleaned_row.get('city')
            ):
                cleaned_data.append(cleaned_row)
        
        return cleaned_data
    
    def clean_charging_stations_data(self, raw_data: List[Dict]) -> List[Dict]:
        """Clean charging stations data"""
        cleaned_data = []
        
        for row in raw_data:
            cleaned_row = {}
            
            # Coordinates (mandatory)
            lat, lng = self.validate_coordinates(
                row.get('latitude'), 
                row.get('longitude')
            )
            if lat is None or lng is None:
                continue  # Skip stations without valid coordinates
            
            cleaned_row['latitude'] = lat
            cleaned_row['longitude'] = lng
            
            # Country (mandatory)
            country = self.clean_string(row.get('country_code') or row.get('country'))
            if not country:
                continue
            cleaned_row['country_code'] = country.upper()
            
            # City
            city = self.clean_string(row.get('city'))
            if city:
                cleaned_row['city'] = city
            
            # Power (important for analysis)
            power = self.clean_numeric(row.get('power_kw') or row.get('power'))
            if power and power > 0:
                cleaned_row['power_kw'] = power
            
            # Ports/charging points
            ports = self.clean_numeric(row.get('ports'), 'int')
            if ports and ports > 0:
                cleaned_row['ports'] = ports
            
            # Power class
            power_class = self.clean_string(row.get('power_class'))
            if power_class:
                cleaned_row['power_class'] = power_class
            
            # Fast DC indicator
            is_fast = row.get('is_fast_dc')
            if is_fast is not None:
                # Convert TRUE/FALSE strings to boolean
                if isinstance(is_fast, str):
                    cleaned_row['is_fast_dc'] = is_fast.upper() in ['TRUE', 'YES', '1', 'T']
                else:
                    cleaned_row['is_fast_dc'] = bool(is_fast)
            
            # Connector type
            connector = self.clean_string(row.get('connector_type'))
            if connector:
                cleaned_row['connector_type'] = connector
            
            # Network
            network = self.clean_string(row.get('network') or row.get('operator'))
            if network:
                cleaned_row['network'] = network
            
            # Status
            status = self.clean_string(row.get('status'))
            if status:
                cleaned_row['status'] = status
            
            cleaned_data.append(cleaned_row)
        
        return cleaned_data
    
    def clean_ev_sales_data(self, raw_data: List[Dict]) -> List[Dict]:
        """Clean EV sales data"""
        cleaned_data = []
        
        for row in raw_data:
            cleaned_row = {}
            
            # Region/Country (mandatory)
            region = self.clean_string(row.get('region') or row.get('country'))
            if not region:
                continue
            cleaned_row['region'] = region
            
            # Year (mandatory)
            year = self.clean_year(row.get('year'))
            if not year:
                continue
            cleaned_row['year'] = year
            
            # Parameter/Category
            parameter = self.clean_string(row.get('parameter') or row.get('category'))
            if parameter:
                cleaned_row['parameter'] = parameter
            
            # Value
            value = self.clean_numeric(row.get('value'))
            if value is not None:
                cleaned_row['value'] = value
            
            # Unit
            unit = self.clean_string(row.get('unit'))
            if unit:
                cleaned_row['unit'] = unit
            
            # Mode (if present in IEA data)
            mode = self.clean_string(row.get('mode'))
            if mode:
                cleaned_row['mode'] = mode
            
            # Powertrain (if present)
            powertrain = self.clean_string(row.get('powertrain'))
            if powertrain:
                cleaned_row['powertrain'] = powertrain
            
            cleaned_data.append(cleaned_row)
        
        return cleaned_data
    

    
    def detect_data_type(self, filename: str) -> str:
        """Detect dataset type from filename"""
        filename_lower = filename.lower()
        
        if 'population' in filename_lower or 'vehicle' in filename_lower:
            return 'ev_population'
        elif 'charging_station' in filename_lower or 'station' in filename_lower:
            return 'charging_stations'
        elif 'sales' in filename_lower or 'iea' in filename_lower or 'global' in filename_lower:
            return 'ev_sales'
        else:
            return 'generic'  # Default for unclassified data
    
    def load_csv_data(self, csv_file: Path) -> List[Dict]:
        """Load CSV data"""
        data = []
        try:
            with open(csv_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    data.append(row)
        except Exception as e:
            print(f"Error loading {csv_file}: {e}")
        return data
    
    def save_cleaned_data(self, data: List[Dict], filename: str):
        """Save cleaned data in CSV and JSON format"""
        if not data:
            print(f"No data to save for {filename}")
            return
        
        # Ensure all records have the same fields by collecting all unique keys
        all_fields = set()
        for record in data:
            all_fields.update(record.keys())
        
        # Fill missing fields with None for consistency
        standardized_data = []
        for record in data:
            standardized_record = {}
            for field in all_fields:
                standardized_record[field] = record.get(field, None)
            standardized_data.append(standardized_record)
        
        # Save processed CSV
        csv_file = self.processed_dir / f"{filename}.csv"
        with open(csv_file, 'w', newline='', encoding='utf-8') as f:
            if standardized_data:
                writer = csv.DictWriter(f, fieldnames=sorted(all_fields))
                writer.writeheader()
                writer.writerows(standardized_data)
        
        print(f"Saved cleaned CSV: {csv_file} ({len(data)} records)")
        
        # Copy to SQL directory
        sql_file = self.sql_dir / f"{filename}.csv"
        with open(sql_file, 'w', newline='', encoding='utf-8') as f:
            if standardized_data:
                writer = csv.DictWriter(f, fieldnames=sorted(all_fields))
                writer.writeheader()
                writer.writerows(standardized_data)
        
        # Convert and save JSON for MongoDB
        json_file = self.nosql_dir / f"{filename}.json"
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(standardized_data, f, indent=2, ensure_ascii=False)
        
        print(f"Saved to SQL and NoSQL directories: {len(data)} records")
    
    def process_all_files(self):
        """Process all CSV files in the raw directory"""
        print("=" * 60)
        print("EV DATA PREPROCESSING")
        print("=" * 60)
        
        csv_files = list(self.raw_dir.glob("*.csv"))
        print(f"Found {len(csv_files)} CSV files to process")
        
        total_processed = 0
        total_original = 0
        
        for csv_file in csv_files:
            print(f"\nProcessing: {csv_file.name}")
            
            # Load raw data
            raw_data = self.load_csv_data(csv_file)
            if not raw_data:
                print(f"  No data loaded from {csv_file.name}")
                continue
            
            total_original += len(raw_data)
            print(f"  Raw records: {len(raw_data)}")
            
            # Detect dataset type and apply appropriate cleaning
            data_type = self.detect_data_type(csv_file.stem)
            print(f"  Detected type: {data_type}")
            
            if data_type == 'ev_population':
                cleaned_data = self.clean_ev_population_data(raw_data)
            elif data_type == 'charging_stations':
                cleaned_data = self.clean_charging_stations_data(raw_data)
            elif data_type == 'ev_sales':
                cleaned_data = self.clean_ev_sales_data(raw_data)
            else:
                # For unclassified data, skip processing (not used by queries)
                print(f"  WARNING: Unknown dataset type - skipping (not used by queries)")
                continue
            
            # Save cleaned data
            if cleaned_data:
                total_processed += len(cleaned_data)
                retention_rate = (len(cleaned_data) / len(raw_data)) * 100
                print(f"  Cleaned records: {len(cleaned_data)} ({retention_rate:.1f}% retained)")
                
                self.save_cleaned_data(cleaned_data, csv_file.stem)
            else:
                print(f"  No valid records after cleaning")
        
        # Final summary
        print("\n" + "=" * 60)
        print("PREPROCESSING COMPLETED")
        print("=" * 60)
        print(f"Total original records: {total_original:,}")
        print(f"Total processed records: {total_processed:,}")
        
        if total_original > 0:
            overall_retention = (total_processed / total_original) * 100
            print(f"Overall retention rate: {overall_retention:.1f}%")
        
        print(f"\nResults saved to:")
        print(f"  - Processed: {self.processed_dir}")
        print(f"  - SQL: {self.sql_dir}")
        print(f"  - NoSQL: {self.nosql_dir}")


if __name__ == "__main__":
    preprocessor = EVDataPreprocessor()
    preprocessor.process_all_files()