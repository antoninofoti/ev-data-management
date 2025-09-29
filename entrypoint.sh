#!/bin/bash
set -e

echo "Starting EV Data Management Lab Environment"
echo "Python $(python --version)"
echo "=========================================="

wait_for_service() {
    local service=$1
    local host=$2
    local port=$3
    local max_attempts=30
    
    echo "Waiting for $service..."
    for i in $(seq 1 $max_attempts); do
        if nc -z $host $port 2>/dev/null; then
            echo "$service is ready"
            return 0
        fi
        echo "Attempt $i/$max_attempts..."
        sleep 2
    done
    echo "$service failed to start"
    return 1
}

wait_for_service "PostgreSQL" "postgres" 5432
wait_for_service "MongoDB" "mongodb" 27017


if [ -f "/root/.kaggle/kaggle.json" ]; then
    echo "Kaggle API token found"
    chmod 600 /root/.kaggle/kaggle.json
else
    echo "WARNING: Kaggle API token not found"
    echo "Some datasets may not be available"
fi

echo "=========================================="
echo "DOWNLOADING EV DATASETS..."
echo "=========================================="
python global_ev_data_downloader.py

echo "=========================================="
echo "SETTING UP DATABASES..."
echo "=========================================="
python setup_databases.py
