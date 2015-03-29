#!/bin/bash

../../bin/csv2hive.sh --create --parquet-create --parquet-db-name "myParquetDb" --parquet-table-name "myAirportTable" ../data/airports.csv

