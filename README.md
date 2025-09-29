# EV Data Management - Global Analytics Platform

Comparative SQL/NoSQL analytics system for Electric Vehicle market intelligence with 37 validated queries across PostgreSQL and MongoDB.

**Status**: Production-ready | 37/37 queries validated | 242K+ records

---

## Database Architecture

### PostgreSQL 15 (Relational)
```sql
-- Three normalized tables for structured analytics
charging_stations (id, latitude, longitude, country_code, city, power_kw, ports, connector_type, network)
ev_population (id, vin, county, city, state, postal_code, model_year, make, model, electric_vehicle_type, 
               cafv_eligibility, electric_range, base_msrp, legislative_district, vehicle_location)
ev_sales (id, region_name, year, parameter, value, unit, mode, powertrain, category)
```

### MongoDB 7.0 (Document-based)
```javascript
// Three collections for flexible aggregation
charging_stations     // Same schema as SQL, optimized for geospatial queries
ev_population_data    // Document-based vehicle records with nested structures
ev_sales_data         // Time-series data with embedded metadata
```

---

## Setup Instructions

### 1. Environment Setup
```bash
# Install dependencies
pip install -r requirements.txt

# Start databases (PostgreSQL, MongoDB, pgAdmin, Mongo Express)
docker-compose up -d

# Verify services are running
docker-compose ps
```

### 2. Data Pipeline
```bash
# Download datasets from Kaggle and Hugging Face
python global_ev_data_downloader.py

# Clean and validate data
python data_preprocessor.py

# Load into both databases
python setup_databases.py
```

### 3. Query Execution
```bash
# Interactive query selection
python quick_test.py

# Run specific query on both databases
python quick_test.py --query Q1_1_market_growth_trajectory --phase phase_1 --database both

# Test all 37 queries for consistency
python test_all_queries.py

# Demo mode with formatted output
python demo.py
```

### 4. Performance Analysis
```bash
# Index performance analysis (6 representative queries)
python index_performance_analyzer.py

# Custom query selection
python index_performance_analyzer.py --queries phase_1:Q1_1_market_growth_trajectory phase_2:Q3_1_price_range_correlation
```

---

## Query Organization (37 Queries / 7 Phases)

### Phase 1: Market Fundamentals (4 queries)
Core market metrics and infrastructure baseline
- `Q1_1_market_growth_trajectory` - Market growth trajectory analysis
- `Q1_4_top_performing_models` - Top performing EV models identification
- `Q2_1_infrastructure_density` - Charging station density assessment
- `Q2_2_fast_charging_availability` - Fast charging availability mapping

### Phase 2: Business Intelligence (4 queries)
Competitive dynamics and market evolution
- `Q1_2_market_share_evolution` - BEV/PHEV market share trends
- `Q3_1_price_range_correlation` - Price-performance correlation analysis
- `Q4_1_manufacturer_positioning` - Manufacturer strategic positioning
- `Q5_1_urban_rural_distribution` - Urban vs rural EV distribution patterns

### Phase 3: Advanced Analytics (6 queries)
Optimization and predictive modeling
- `Q3_3_seasonal_charging_patterns` - Seasonal charging pattern analysis
- `Q5_2_highway_charging_corridors` - Highway charging corridor optimization
- `Q6_1_optimal_station_placement` - Optimal station placement algorithms
- `Q6_3_grid_impact_analysis` - Grid impact analysis and load prediction
- `Q3_2_range_anxiety_analysis` - Range anxiety and charging behavior
- `Q4_3_incentive_effectiveness` - Government incentive effectiveness analysis

### Phase 4: Regional Intelligence (6 queries)
Geographic market penetration analysis
- `Q1_3_regional_adoption_rate` - Regional adoption rate tracking
- `Q2_3_network_coverage_analysis` - Comprehensive network coverage analysis
- `Q4_2_regional_technology_preferences` - Regional technology preferences
- `Q5_3_geographic_market_penetration` - Geographic market penetration mapping
- `Q2_4_charging_station_growth` - Infrastructure growth trajectory analysis
- `Q3_4_ev_population_demographics` - EV population demographics and characteristics

### Phase 5: Italian Market Focus (4 queries)
Italy-specific opportunities and competitive landscape
- `Q5_1_italian_regional_analysis` - Italian regional EV analysis
- `Q5_2_italian_infrastructure_assessment` - Italian charging infrastructure assessment
- `Q6_1_italian_market_potential` - Italian market potential evaluation
- `Q5_4_italian_charging_accessibility` - Italian charging network accessibility

### Phase 6: Global Market Dynamics (8 queries)
Worldwide competition and strategic positioning
- `Q5_1_global_market_leaders` - Global market leaders (China, USA, Europe)
- `Q5_2_italy_vs_global_comparison` - Italy vs global giants comparison
- `Q5_3_global_brand_warfare` - Global brand competition (Tesla vs BYD vs European)
- `Q6_1_technology_adoption_patterns` - Technology adoption patterns globally
- `Q6_2_policy_effectiveness_comparison` - Policy effectiveness global comparison
- `Q4_4_brand_performance_regions` - Brand performance by geographic region
- `Q5_5_european_market_dynamics` - European market dynamics and trends
- `Q6_4_charging_network_comparison` - Global charging network comparison

### Phase 7: USA vs China Geopolitical Analysis (5 queries)
Superpower market intelligence and strategic comparison
- `Q7_1_usa_china_market_dominance` - Market size and dominance comparison
- `Q7_2_usa_china_technology_race` - Technology race (BEV vs PHEV preferences)
- `Q7_3_usa_china_infrastructure_race` - Infrastructure development comparison
- `Q7_4_usa_china_oil_displacement` - Oil displacement impact analysis
- `Q7_5_usa_china_future_projections` - Future market growth projections (2024-2030)

---

## Key Scripts

| Script | Purpose |
|--------|---------|
| `global_ev_data_downloader.py` | Download datasets from Kaggle and Hugging Face |
| `data_preprocessor.py` | Clean, validate, and prepare data for import |
| `setup_databases.py` | Initialize PostgreSQL and MongoDB with data |
| `quick_test.py` | Interactive query testing tool |
| `demo.py` | Formatted query demonstration with performance metrics |
| `test_all_queries.py` | Comprehensive validation of all 37 queries |
| `index_performance_analyzer.py` | Index impact analysis (6 representative queries) |

---

## Using demo.py

The `demo.py` script provides formatted query results with performance metrics. It supports both console output and saving results to files.

### Basic Usage

```bash
# Run a single query on SQL database
python3 demo.py --query Q1_1_market_growth_trajectory --phase phase_1 --database sql

# Run on MongoDB
python3 demo.py --query Q1_1_market_growth_trajectory --phase phase_1 --database mongodb

# Run on both databases and compare performance
python3 demo.py --query Q1_1_market_growth_trajectory --phase phase_1 --database both
```

### Save Results to File

Use the `--output` (or `-o`) flag to save complete results to a text file:

```bash
# Save SQL results
python3 demo.py --query Q1_1_market_growth_trajectory --phase phase_1 --database sql --output results.txt

# Save MongoDB results
python3 demo.py --query Q2_1_infrastructure_density --phase phase_1 --database mongodb -o mongo_results.txt

# Save comparison results
python3 demo.py --query Q1_1_market_growth_trajectory --phase phase_1 --database both -o comparison.txt
```

**File Output Includes**:
- Query metadata (name, phase, database)
- Complete query text (SQL or MongoDB aggregation pipeline)
- **Full results** without truncation:
  - SQL: Formatted table with all rows and aligned columns
  - MongoDB: Pretty-printed JSON with all documents
- Execution time
- Performance comparison (in "both" mode)

### Arguments

| Argument | Short | Description | Required |
|----------|-------|-------------|----------|
| `--query` | `-q` | Query name (e.g., Q1_1_market_growth_trajectory) | ✓ |
| `--phase` | `-p` | Phase folder (e.g., phase_1, phase_2, ..., phase_7) | ✓ |
| `--database` | `-d` | Database to use: `sql`, `mongodb`, or `both` | ✓ |
| `--output` | `-o` | Output file path to save results (optional) | ✗ |

### Interactive Mode

Run without arguments for an interactive menu:

```bash
python3 demo.py
```

**Interactive Features**:
1. **Browse queries** - Select from all 37 queries organized by phase
2. **Demo suite** - Automated presentation of 6 showcase queries
3. **Manual entry** - Enter query name and phase directly

**Interactive File Saving**: After selecting a query and database, you'll be prompted:
```
Save results to file? (y/n, default: n): y
Enter filename (e.g., results.txt): my_analysis.txt
```

This allows you to save results even when using the interactive menu!

### Command-Line Examples

```bash
# Phase 1: Market fundamentals
python3 demo.py -q Q1_1_market_growth_trajectory -p phase_1 -d both -o growth_analysis.txt
python3 demo.py -q Q2_1_infrastructure_density -p phase_1 -d sql

# Phase 5: Italian market analysis
python3 demo.py -q Q5_1_italian_regional_analysis -p phase_5 -d mongodb -o italy_report.txt

# Phase 7: USA vs China comparison
python3 demo.py -q Q7_1_usa_china_market_dominance -p phase_7 -d both -o geopolitical.txt
```

### Typical Workflow

**Quick Exploration** (Interactive Mode):
```bash
# Launch interactive menu
python3 demo.py

# Select option 1 (Browse queries)
# Choose query from list
# Select database (SQL/MongoDB/Both)
# Choose whether to save results to file
```

**Production Analysis** (Command-Line Mode):
```bash
# Direct execution with file output
python3 demo.py -q Q1_1_market_growth_trajectory -p phase_1 -d both -o market_report.txt

# Review results
cat market_report.txt
```

**Presentation Mode**:
```bash
# Run demo suite (automatically runs 6 showcase queries)
python3 demo.py --suite

# Or with file output
python3 demo.py --suite -o presentation_results.txt
```

---

## Service Endpoints

| Service | Port | URL | Credentials |
|---------|------|-----|-------------|
| PostgreSQL | 5432 | localhost:5432 | ev_admin / ev_password123 |
| MongoDB | 27017 | localhost:27017 | ev_admin / ev_password123 |
| pgAdmin | 5050 | http://localhost:5050 | admin@evproject.com / ev_admin123 |
| Mongo Express | 8081 | http://localhost:8081 | admin / ev_admin123 |

---

## Database Access via Web Interfaces

### pgAdmin (PostgreSQL Web Interface)

**Access URL**: http://localhost:5050

**Login Credentials**:
- Email: `admin@evproject.com`
- Password: `ev_admin123`

**First-Time Setup** (Add PostgreSQL Server):
1. Open http://localhost:5050 in your browser
2. Login with the credentials above
3. Right-click "Servers" in the left panel → Register → Server
4. **General Tab**:
   - Name: `EV Database` (or any name you prefer)
5. **Connection Tab**:
   - Host name/address: `ev_postgres` (or `localhost`)
   - Port: `5432`
   - Maintenance database: `ev_global_analysis`
   - Username: `ev_admin`
   - Password: `ev_password123`
   - Save password: ✓ (optional)
6. Click "Save"

**Navigate to Tables**:
```
Servers → EV Database → Databases → ev_global_analysis → Schemas → public → Tables
```

**Available Tables**:
- `charging_stations` - 242K+ charging station records worldwide
- `ev_population` - Electric vehicle registration data
- `ev_sales` - IEA global EV sales time-series (2010-2024)

**Quick Query**:
- Right-click any table → View/Edit Data → All Rows
- Use the Query Tool (Tools → Query Tool) to run custom SQL

---

### Mongo Express (MongoDB Web Interface)

**Access URL**: http://localhost:8081

**Login Credentials** (HTTP Basic Auth):
- Username: `admin`
- Password: `ev_admin123`

**MongoDB Database Credentials** (pre-configured):
- Database: `ev_global_analysis`
- Admin User: `ev_admin`
- Admin Password: `ev_password123`

**Navigate to Collections**:
1. Open http://localhost:8081 in your browser
2. Login with basic auth credentials (admin / ev_admin123)
3. Select database: `ev_global_analysis`
4. You'll see 3 collections:
   - `charging_stations` - Charging station documents with geospatial data
   - `ev_population_data` - Vehicle registration documents
   - `ev_sales_data` - Time-series sales/stock data

**View Documents**:
- Click on any collection name to browse documents
- Use "Simple" view for formatted JSON
- Use "Table" view for spreadsheet-like display

**Run Queries**:
- Click collection → "Advanced" tab
- Enter MongoDB query in JSON format
- Example: `{"country_code": "US"}` to filter US stations
- Click "Find" to execute

**Import/Export**:
- Use "Export" button to download collection as JSON
- Use "Import" to upload JSON data

---

## Default Credentials Summary

### PostgreSQL Database
```
Host: localhost
Port: 5432
Database: ev_global_analysis
Username: ev_admin
Password: ev_password123
```

### MongoDB Database
```
Host: localhost
Port: 27017
Database: ev_global_analysis
Username: ev_admin
Password: ev_password123
Connection String: mongodb://ev_admin:ev_password123@localhost:27017/ev_global_analysis?authSource=admin
```

### pgAdmin Web Interface
```
URL: http://localhost:5050
Email: admin@evproject.com
Password: ev_admin123
```

### Mongo Express Web Interface
```
URL: http://localhost:8081
Username: admin
Password: ev_admin123
```

**Security Note**: These are development credentials. For production deployment, 
change all passwords and restrict network access appropriately.

---

## Project Structure

```
ev-data-management/
├── data/
│   ├── raw/                      # Original CSV files
│   ├── processed/                # Cleaned CSV files
│   ├── sql/                      # PostgreSQL import files
│   └── nosql/                    # MongoDB import files
├── queries/
│   ├── sql/phase_[1-7]/          # 37 SQL query files (.sql)
│   ├── mongodb/phase_[1-7]/      # 37 MongoDB query files (.json)
│   └── common/
│       ├── unified_query_executor.py    # Universal query interface
│       ├── database_connectors.py       # Database connections
│       └── query_loader.py              # External file loader
├── global_ev_data_downloader.py  # Dataset download automation
├── data_preprocessor.py          # Data cleaning and validation
├── setup_databases.py            # Database initialization
├── quick_test.py                 # Query testing tool
├── demo.py                       # Demo presentation tool
├── test_all_queries.py           # Full query validation
├── index_performance_analyzer.py # Index performance analysis
├── docker-compose.yml            # Infrastructure configuration
└── requirements.txt              # Python dependencies
```

---

## Technical Details

- **Query Consistency**: 100% validation (37/37 SQL/MongoDB matches)
- **External Query Files**: All queries stored as `.sql` and `.json` files for easy modification
- **Performance**: Sub-second execution for most analytical queries
- **Data Scale**: 242,417+ charging stations, global EV sales 2010-2024
- **Index Analysis**: 2x-6x performance improvements with optimized indexing

