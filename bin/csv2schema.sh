#!/bin/bash

# -- VERSION -------------------------------------------------------------------

VERSION="csv2schema v1.0"

# -- HELP ----------------------------------------------------------------------

HELP_CONTENT="
usage: csv2schema [CSV_FILE] {WORK_DIR}

Generates from a CSV file a schema containing the columns names and their types.

positional arguments:
  CSV_FILE	The CSV file to operate on.
  WORK_DIR	The work directory where to create the schema file (optional).
		If missing, then the work directory will the same as the CSV
		file. The schema file name will be the same as the CSV file
		name but with the extension '.schema'.

optional arguments:
  --version	Show the version of this program.
  -h, --help	Show this help message and exit.
  -d DELIMITER, --delimiter DELIMITER
		Specify the delimiter used in the CSV file.
		If not present without -t nor --tab, then the delimiter will
		be discovered automatically between :
		{\",\" \"\\\t\" \";\" \"|\" \"\\\b\"}.
  -t, --tab	Indicates that the tab delimiter is used in the CSV file.
		Overrides -d and --delimiter.
		If not present without -d nor --delimiter, then the delimiter
		will be discovered automatically between :
		{\",\" \"\\\t\" \";\" \"|\" \"\\\b\"}.
  --no-header	If present, indicates that the CSV file hasn't header.
		Then the columns will be named 'column1', 'column2', and so on.
  -s SEPARATED_HEADER, --separated-header SEPARATED_HEADER
		Specify a separated header file that contains the header,
		its delimiter must be the same as the delimiter in the CSV file.
		Overrides --no-header.
  -q QUOTE_CHARACTER, --quote-character QUOTE_CHARACTER 
		The quote character surrounding the fields.
"

# -- ARGS ----------------------------------------------------------------------

ALL_ARGS="$0 $@"
option=""
counter=-1
CURRENT_DIR=`pwd`
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
        if [ "$param" = "--version" ]; then
                SHOW_VERSION="1"
                break
        fi

	# SHOW_HELP
	if [ "$param" = "-h" ] || [ "$param" = "--help" ]; then
		SHOW_HELP="1"
		break
	fi

	# CSV_DELIMITER
	if [ "$param" = "-d" ] || [ "$param" = "--delimiter" ]; then
		option="OPTION_CSV_DELIMITER"
		continue
	fi
	if [ "$option" = "OPTION_CSV_DELIMITER" ]; then
		option=""
		CSV_DELIMITER=$param
		continue
	fi
	if [ "$param" = "-t" ] || [ "$param" = "--tab" ]; then
		CSV_DELIMITER="\t"
		continue
	fi

	# CSV_NO_HEADER
	if [ "$param" = "--no-header" ]; then
		CSV_NO_HEADER="1"
		continue
	fi

	# SEPARATED_HEADER
	if [ "$param" = "-s" ] || [ "$param" = "--separated-header" ]; then
                option="OPTION_SEPARATED_HEADER"
                continue
        fi
        if [ "$option" = "OPTION_SEPARATED_HEADER" ]; then
                option=""
                SEPARATED_HEADER_FILE=$param
                continue
        fi

	# CSV_NO_HEADER
        if [ "$param" = "--no-header" ]; then
                CSV_NO_HEADER="1"
                continue
        fi

	# QUOTE_CHARACTER
        if [ "$param" = "-q" ] || [ "$param" = "--quote-character" ]; then
                option="OPTION_QUOTE_CHARACTER"
                continue
        fi
        if [ "$option" = "OPTION_QUOTE_CHARACTER" ]; then
                option=""
                QUOTE_CHARACTER=$param
                continue
        fi

	# PARENT_CALL
        if [ "$param" = "--parent-call" ]; then
                PARENT_CALL="1"
                continue
        fi

	# OPTIONS TO SKIP
        if [ "$param" = "--create" ]; then
                continue
        fi
	if [ "$param" = "--db-name" ]; then
                option="OPTION_HIVE_DB_NAME"
                continue
        fi
        if [ "$option" = "OPTION_HIVE_DB_NAME" ]; then
                option=""
                continue
        fi
	if [ "$param" = "--table-name" ]; then
                option="OPTION_HIVE_TABLE_NAME"
                continue
        fi
        if [ "$option" = "OPTION_HIVE_TABLE_NAME" ]; then
                option=""
                continue
        fi
	if [ "$param" = "--table-prefix" ]; then
                option="OPTION_HIVE_TABLE_PREFIX"
                continue
        fi
        if [ "$option" = "OPTION_HIVE_TABLE_PREFIX" ]; then
                option=""
                continue
        fi
	if [ "$param" = "--table-suffix" ]; then
                option="OPTION_HIVE_TABLE_SUFFIX"
                continue
        fi
        if [ "$option" = "OPTION_HIVE_TABLE_SUFFIX" ]; then
                option=""
                continue
        fi
	if [ "$param" = "--parquet-create" ]; then
                continue
        fi
	if [ "$param" = "--parquet-db-name" ]; then
                option="OPTION_PARQUET_DB_NAME"
                continue
        fi
        if [ "$option" = "OPTION_PARQUET_DB_NAME" ]; then
                option=""
                continue
        fi
        if [ "$param" = "--parquet-table-name" ]; then
                option="OPTION_PARQUET_TABLE_NAME"
                continue
        fi
        if [ "$option" = "OPTION_PARQUET_TABLE_NAME" ]; then
                option=""
                continue
        fi
	if [ "$param" = "--parquet-table-prefix" ]; then
                option="OPTION_PARQUET_TABLE_PREFIX"
                continue
        fi
        if [ "$option" = "OPTION_PARQUET_TABLE_PREFIX" ]; then
                option=""
                continue
        fi
	if [ "$param" = "--parquet-table-suffix" ]; then
                option="OPTION_PARQUET_TABLE_SUFFIX"
                continue
        fi
        if [ "$option" = "OPTION_PARQUET_TABLE_SUFFIX" ]; then
                option=""
                continue
        fi
        if [ "$param" = "--hdfs-file-name" ]; then
                option="OPTION_HDFS_FILE_NAME"
                continue
        fi
        if [ "$option" = "OPTION_HDFS_FILE_NAME" ]; then
                option=""
                continue
        fi
	if [ "$param" = "--hdfs-file-prefix" ]; then
                option="OPTION_HDFS_FILE_PREFIX"
                continue
        fi
        if [ "$option" = "OPTION_HDFS_FILE_PREFIX" ]; then
                option=""
                continue
        fi
	if [ "$param" = "--hdfs-file-suffix" ]; then
                option="OPTION_HDFS_FILE_SUFFIX"
                continue
        fi
        if [ "$option" = "OPTION_HDFS_FILE_SUFFIX" ]; then
                option=""
                continue
        fi

	# CSV_FILE
	if [ "${CSV_FILE}" = "" ]; then
		CSV_FILE=$param
		CSV_DIR=`(cd \`dirname ${CSV_FILE}\`; pwd)`
                CSV_BASENAME=$(basename ${CSV_FILE})
                CSV_FILENAME=${CSV_BASENAME%.*}
		#CSV_EXTENSION="${CSV_BASENAME##*.}"
		continue
	fi

	# WORK_DIR
        if [ "${WORK_DIR}" = "" ]; then
                WORK_DIR=$param
                WORK_DIR=`(cd ${WORK_DIR}; pwd)`
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

# Watchdogs
if [ "${option}" = "OPTION_CSV_DELIMITER" ] && [ "${CSV_DELIMITER}" = "" ]; then
        echo "- Error: The delimiter is missing (note: for a space delimiter, use \"\\b\" rather than \" \") !"
        exit 1
fi
if [ "${option}" = "OPTION_SEPARATED_HEADER" ] && [ "${SEPARATED_HEADER_FILE}" = "" ]; then
        echo "- Error: The header file is missing !"
        exit 1
fi
if [ "${option}" = "OPTION_QUOTE_CHARACTER" ] && [ "${QUOTE_CHARACTER}" = "" ]; then
        echo "- Error: The quote character is missing !"
        exit 1
fi

# Check if the CSV file argument is missing or if the file doesn't exists
if [ "${CSV_FILE}" = "" ]; then
        echo "- Error: The CSV file is missing ! Please use \"-h\" or \"--help\" for usage."
        exit 1
fi
if [ ! -f ${CSV_FILE} ]; then
        echo "- Error: The CSV file \"${CSV_FILE}\" doesn't exist !"
        exit 1
fi

# If the work directory argument is missing, then takes the current directory
if [ "${WORK_DIR}" = "" ]; then
	WORK_DIR=${CURRENT_DIR}
fi
# If the work directory is the same as the CSV directory, then creates a sub-directory
# that will become the new work directory
if [ "${WORK_DIR}" = "${CSV_DIR}" ]; then
	if [ ! -d "${WORK_DIR}/${CSV_FILENAME}" ]; then
		mkdir "${WORK_DIR}/${CSV_FILENAME}"
	fi
        WORK_DIR=${WORK_DIR}/${CSV_FILENAME}
fi

# The CSV short file
CSV_SHORT_FILE=${WORK_DIR}/${CSV_FILENAME}.short

# The schema file
SCHEMA_FILE=${WORK_DIR}/${CSV_FILENAME}.schema

# The vi commands file
VI_COMMANDS_FILE=${WORK_DIR}/${CSV_FILENAME}.vi

# The vi commands to transform the SQL-DDL file generated by csvsql into a simpler schema file
VI_COMMANDS="dd
G
dd
G\$a,\e
:%s/\t//g
:%s/\"//g
:%s/, /,/g
:g/^CHECK (/d
:%s/ NOT NULL,/,/g
:%s/([0-9]*)//g
:%s/ VARCHAR,/-string,/g
:%s/ STRING,/-string,/g
:%s/ DATETIME,/-string,/g
:%s/ DATE,/-string,/g
:%s/ TIMESTAMP,/-string,/g
:%s/ INTEGER,/-int,/g
:%s/ INT,/-int,/g
:%s/ TINYINT,/-int,/g
:%s/ SMALLINT,/-int,/g
:%s/ BIGINT,/-bigint,/g
:%s/ DECIMAL,/-decimal,/g
:%s/ DOUBLE,/-double,/g
:%s/ FLOAT,/-float,/g
:%s/ BOOLEAN,/-boolean,/g
:%s/ BINARY,/-binary,/g
:%s/ /_/g
:%s/-string,/ string,/g
:%s/-int,/ int,/g
:%s/-bigint,/ bigint,/g
:%s/-decimal,/ decimal,/g
:%s/-double,/ double,/g
:%s/-float,/ float,/g
:%s/-boolean,/ boolean,/g
:%s/-binary,/ binary,/g
:%s/^_/x_/g
G\$x
:wq
"

# -- PROG ----------------------------------------------------------------------

# Create the csv short file used for the csvsql command
head -10000 "${CSV_FILE}" > "${CSV_SHORT_FILE}"

# If it exists a separated header file then concat it with the csv short file
if [ ! "${SEPARATED_HEADER_FILE}" = "" ]; then
	cp "${SEPARATED_HEADER_FILE}" "${CSV_SHORT_FILE}~"
	cat "${CSV_SHORT_FILE}" >> "${CSV_SHORT_FILE}~"
	mv "${CSV_SHORT_FILE}~" "${CSV_SHORT_FILE}"
	CSV_NO_HEADER="0"
fi

# Search the delimiter if not defined
if [ "${CSV_DELIMITER}" = "" ]; then
        TWO_FIRST_LINES_FILE=${WORK_DIR}/${CSV_FILENAME}.2FirstLines
	if [ ! "${SEPARATED_HEADER_FILE}" = "" ]; then
		cp "${SEPARATED_HEADER_FILE}" "${TWO_FIRST_LINES_FILE}"
		head -1 "${CSV_FILE}" | cat >> "${TWO_FIRST_LINES_FILE}"
	else
		head -2 "${CSV_FILE}" > "${TWO_FIRST_LINES_FILE}"
	fi
        STRING_1=`head -1 "${TWO_FIRST_LINES_FILE}"`
        STRING_2=`tail -n +2 "${TWO_FIRST_LINES_FILE}"`
        rm -rf "${TWO_FIRST_LINES_FILE}"
        CSV_DELIMITER=`python "${SCRIPT_DIR}/searchDelimiter.py" "${STRING_1}" "${STRING_2}" "${QUOTE_CHARACTER}"`
        if [ "${CSV_DELIMITER}" = "NO_DELIMITER" ]; then
                echo "- Error: Delimiter not found !"
		echo "         Maybe the number of delimiters are differents in the two first lines !"
		echo "         Or maybe you should check the quote character (-q option) !"
                exit 1
        fi
fi

# Specify the delimiter option for the csvsql command
CSVSQL_OPTS=
if [ "${CSV_DELIMITER}" = "\t" ]; then
	CSVSQL_OPTS="${CSVSQL_OPTS}-t"
elif [ "${CSV_DELIMITER}" = "\b" ]; then
	CSVSQL_OPTS="${CSVSQL_OPTS}"
else
	CSVSQL_OPTS="${CSVSQL_OPTS}-d ${CSV_DELIMITER}"
fi

# Specify the ISO8859 and no-constraints options
CSVSQL_OPTS="${CSVSQL_OPTS} -b -e ISO8859 --no-constraints"

# Set the csvsql header option if the csv input file has no header
if [ "${CSV_NO_HEADER}" = "1" ]; then
	CSVSQL_OPTS="${CSVSQL_OPTS} --no-header-row"
fi

# Create with csvsql a DDL SQL file from the CSV file
csvsql ${CSVSQL_OPTS} "${CSV_SHORT_FILE}" > "${SCHEMA_FILE}"

# Create the vi file containing the vi commands
rm -rf "${VI_COMMANDS_FILE}"
touch "${VI_COMMANDS_FILE}"
echo -e "${VI_COMMANDS}" > "${VI_COMMANDS_FILE}"

# Clean the DDL SQL file with the vi commands to obtain a simple schema file
# that will be used to build the Hive CREATE TABLE statement
vi "${SCHEMA_FILE}" < "${VI_COMMANDS_FILE}" 2> /dev/null
rm -rf "${VI_COMMANDS_FILE}"

# Action to do if that script has been called by a parent script
if [ "${PARENT_CALL}" = "1" ]; then
	rm -rf "${CSV_SHORT_FILE}"
fi

