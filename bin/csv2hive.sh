#!/bin/bash

# -- VERSION -------------------------------------------------------------------

VERSION="csv2hive v1.0"

# -- HELP ----------------------------------------------------------------------

HELP_CONTENT="
usage: csv2hive [CSV_FILE] {WORK_DIR}

Generate a Hive 'CREATE TABLE' statement given a CSV file and execute that
statement directly on Hive by uploading the CSV file to HDFS.
The Parquet format is also supported.

positional argument:
  CSV_FILE	The CSV file to operate on.
  WORK_DIR	The work directory where to create the Hive file (optional).
		If missing, the work directory will be the same as the CSV file.
		In that directory, the name of the output Hive file will be the
		same as the CSV file but with the extension '.hql'.

optional arguments:
  -v, --version	Show the version of this program.
  -h, --help	Show this help message and exit.
  -d DELIMITER, --delimiter DELIMITER
		Specify the delimiter used in the CSV file.
		If not present without -t nor --tab, then the delimiter will
		be discovered automatically between :
		{\",\" \"\\\t\" \";\" \"|\" \"\\\s\"}.
  -t, --tab	Indicates that the tab delimiter is used in the CSV file.
		Overrides -d and --delimiter.
		If not present without -d nor --delimiter, then the delimiter
		will be discovered automatically between :
		{\",\" \"\\\t\" \";\" \"|\" \"\\\s\"}.
  --no-header	If present, indicates that the CSV file hasn't header.
		Then the columns will be named 'column1', 'column2', and so on.
  -s SEPARATED_HEADER, --separated-header SEPARATED_HEADER
		Specify a separated header file that contains the header,
		its delimiter must be the same as the delimiter in the CSV file.
		Overrides --no-header.
  -q QUOTE_CHARACTER, --quote-character QUOTE_CHARACTER
		The quote character surrounding the fields.
  --create	Creates the table in Hive.
		Overrides the previous Hive table, as well as its file in HDFS.
  --db-name DB_NAME
		Optional name for database where to create the Hive table.
  --table-name TABLE_NAME
		Specify a name for the Hive table to be created.
		If omitted, the CSV file name (minus extension) will be used.
  --table-prefix TABLE_PREFIX
		Specify a prefix for the Hive table name.
  --table-suffix TABLE_SUFFIX
		Specify a suffix for the Hive table name.
  --parquet-create
		Ask to create the Parquet table.
  --parquet-db-name PARQUET_DB_NAME
		Optional name for database where to create the Parquet table.
  --parquet-table-name PARQUET_TABLE_NAME
		Specify a name for the Parquet table to be created.
		If omitted, the CSV file name (minus extension) will be used.
  --parquet-table-prefix PARQUET_TABLE_PREFIX
		Specify a prefix for the Parquet table name.
  --parquet-table-suffix PARQUET_TABLE_SUFFIX
		Specify a suffix for the Parquet table name.
  --hdfs-file-name HDFS_FILE_NAME
		Specify a name for the HDFS file to be uploaded.
		If omitted, the CSV file name (minus extension) will be used.
  --hdfs-file-prefix HDFS_FILE_PREFIX
		Specify a prefix for the HDFS file name.
  --hdfs-file-suffix HDFS_FILE_SUFFIX
		Specify a suffix for the HDFS file name.
"

# -- ARGS ----------------------------------------------------------------------

ALL_ARGS="$0 $@"
option=""
counter=-1
for param in ${ALL_ARGS}
do
	counter=$((counter+1))

	# SCRIPT_FILE & SCRIPT_DIR
	if [ "$counter" = "0" ]; then
		SCRIPT_FILE=$param
		SCRIPT_DIR=`(cd \`dirname ${SCRIPT_FILE}\`; pwd)`
		# If the script file is a symbolic link
		if [[ -L "${SCRIPT_FILE}" ]]
		then
			SCRIPT_FILE=`ls -la ${SCRIPT_FILE} | cut -d">" -f2`
			SCRIPT_DIR=`(cd \`dirname ${SCRIPT_FILE}\`; pwd)`
		fi
		SCRIPT_BASENAME=$(basename ${SCRIPT_FILE})
		SCRIPT_FILENAME=${SCRIPT_BASENAME%.*}
		continue
	fi

        # SHOW_VERSION
        if [ "$param" = "-v" ] || [ "$param" = "--version" ]; then
                SHOW_VERSION="1"
                break
        fi

	# SHOW_HELP
	if [ "$param" = "-h" ] || [ "$param" = "--help" ]; then
		SHOW_HELP="1"
		break
	fi
done

# -- VARS ----------------------------------------------------------------------

# Showing the version
if [ "${SHOW_VERSION}" = "1" ]; then
        echo -e "${VERSION}"
        exit 0
fi

# Showing the Help content if asked
if [ "${SHOW_HELP}" = "1" ] || [ "$#" = "0" ]; then
        echo -e "${HELP_CONTENT}"
        exit 0
fi

# -- PROG ----------------------------------------------------------------------

# Create the schema automatically by using the CSVKIT library
"${SCRIPT_DIR}/csv2schema.sh" --parent-call "$@"
if [ "$?" = "1" ]; then
        exit 1
fi

# Generate the CREATE TABLE Hive statement and create the Hive table
"${SCRIPT_DIR}/schema2hive.sh" --parent-call "$@"
