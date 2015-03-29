#!/bin/bash

# We create a symbolic link to upload the file with another name to hdfs ('airports.csv' rather 'airports-noheader.csv')
if [ ! -f "./airports.csv" ];then
	ln -s ../data/airports-noheader.csv ./airports.csv
fi
../../bin/csv2hive.sh -s ../data/airports.header --table-name airports ./airports.csv

