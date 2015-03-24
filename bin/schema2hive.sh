#!/bin/bash

# -- HELP ----------------------------------------------------------------------

HELP_CONTENT="
usage: schema2hive [CSV_FILE] {WORK_DIR}

Generate a Hive 'CREATE TABLE' statement given a schema file and execute that
statement directly on Hive by uploading the CSV file to HDFS.
The Parquet format is also supported.

positional argument:
  CSV_FILE	The CSV file to operate on.
  WORK_DIR	The work directory where to create the Hive file (optional).
		If missing, the work directory will be the same as the CSV file.
		In that directory, the name of the input schema file must be the
		same as the CSV file but with the extension '.schema'.
		In that directory, the name of the output Hive file will be the
		same as the CSV file but with the extension '.hql'.

optional arguments:
  -h, --help	Show this help message and exit.
  -d DELIMITER, --delimiter DELIMITER
		Specify the delimiter used in the CSV file.
		If not present without -t nor --tab, then the delimiter will
		be discovered automatically between :
		{\",\" \"\\\t\" \";\" \"|\" \" \"}.
  -t, --tab	Indicates that the tab delimiter is used in the CSV file.
		Overrides -d and --delimiter.
		If not present without -d nor --delimiter, then the delimiter
		will be discovered automatically between :
		{\",\" \"\\\t\" \";\" \"|\" \" \"}.
  --db-name DB_NAME
		Optional name of Hive database where to create the table.
  --table-name TABLE_NAME
		Specify a name for the table to be created.
		If omitted, the file name (minus extension) will be used.
  --create	Ask to create the table in Hive.
  --parquet-db-name PARQUET_DB_NAME
		Optional name for database where to create the Parquet table.
  --parquet-table-name PARQUET_TABLE_NAME
		Specify a name for the Parquet table to be created.
		If omitted, the file name (minus extension) will be used.
  --parquet-create
		Ask to create the Parquet table.
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

	# HELP
	if [ "$param" = "-h" ] || [ "$param" = "--help" ]; then
		HELP="1"
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

        # HIVE_DB_NAME
        if [ "$param" = "--db-name" ]; then
                option="OPTION_HIVE_DB_NAME"
                continue
        fi
        if [ "$option" = "OPTION_HIVE_DB_NAME" ]; then
                option=""
                HIVE_DB_NAME="$param"
                continue
        fi

        # HIVE_TABLE_NAME
        if [ "$param" = "--table-name" ]; then
                option="OPTION_HIVE_TABLE_NAME"
                continue
        fi
        if [ "$option" = "OPTION_HIVE_TABLE_NAME" ]; then
                option=""
                HIVE_TABLE_NAME=$param
                continue
        fi

        # HIVE_CREATE
        if [ "$param" = "--create" ]; then
                HIVE_CREATE="1"
                continue
        fi

	# PARQUET_DB_NAME
        if [ "$param" = "--parquet-db-name" ]; then
                option="OPTION_PARQUET_DB_NAME"
                continue
        fi
        if [ "$option" = "OPTION_PARQUET_DB_NAME" ]; then
                option=""
                PARQUET_DB_NAME="$param"
                continue
        fi

        # PARQUET_TABLE_NAME
        if [ "$param" = "--parquet-table-name" ]; then
                option="OPTION_PARQUET_TABLE_NAME"
                continue
        fi
        if [ "$option" = "OPTION_PARQUET_TABLE_NAME" ]; then
                option=""
                PARQUET_TABLE_NAME=$param
                continue
        fi

	# PARENT_CALL
        if [ "$param" = "--parent-call" ]; then
                PARENT_CALL="1"
                continue
        fi

	# PARQUET_CREATE
        if [ "$param" = "--parquet-create" ]; then
                PARQUET_CREATE="1"
                continue
        fi

	# OPTIONS TO SKIP
        if [ "$param" = "--no-header" ]; then
                continue
        fi

	# CSV_FILE
	if [ "${CSV_FILE}" = "" ]; then
		CSV_FILE=$param
		CSV_DIR=`(cd \`dirname ${CSV_FILE}\`; pwd)`
                # If the input csv file is a symbolic link
                if [[ -L "${CSV_FILE}" ]]
                then
                        CSV_FILE=`ls -la ${CSV_FILE} | cut -d">" -f2`
                        CSV_DIR=`(cd \`dirname ${CSV_FILE}\`; pwd)`
                fi
                CSV_BASENAME=$(basename ${CSV_FILE})
                CSV_FILENAME=${CSV_BASENAME%.*}
		CSV_EXTENSION="${CSV_BASENAME##*.}"
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

# Showing the Help content if asked
if [ "${HELP}" = "1" ] || [ "$#" = "0" ]; then
	echo -e "${HELP_CONTENT}"
	exit 0
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

# If the work directory argument is missing, then takes the CSV file directory
if [ "${WORK_DIR}" = "" ]; then
	WORK_DIR=${CSV_DIR}
fi

# The CSV head file
CSV_HEAD_EXTENSION="head"
CSV_HEAD_FILENAME=${CSV_FILENAME}
CSV_HEAD_DIR=${WORK_DIR}
CSV_HEAD_FILE=${CSV_HEAD_DIR}/${CSV_HEAD_FILENAME}.${CSV_HEAD_EXTENSION}

# Search the delimiter if not specified
if [ "${CSV_DELIMITER}" = "" ]; then
        head -2 "${CSV_FILE}" > "${CSV_HEAD_FILE}"
        STRING_1=`head -1 "${CSV_HEAD_FILE}"`
        STRING_2=`tail -1 "${CSV_HEAD_FILE}"`
        rm -rf "${CSV_HEAD_FILE}"
        CSV_DELIMITER=`python "${SCRIPT_DIR}/searchDelimiter.py" "${STRING_1}" "${STRING_2}"`
        if [ "${CSV_DELIMITER}" = "NO_DELIMITER" ]; then
                echo "- Error: Delimiter not found !"
                exit 1
        fi
fi

# The schema file
SCHEMA_EXTENSION="schema"
SCHEMA_FILENAME=${CSV_FILENAME}
SCHEMA_DIR=${WORK_DIR}
SCHEMA_FILE=${SCHEMA_DIR}/${SCHEMA_FILENAME}.${SCHEMA_EXTENSION}

# The Hive table name: If missing we use the CSV file name minus extension
if [ "${HIVE_TABLE_NAME}" = "" ]; then
        HIVE_TABLE_NAME="${CSV_FILENAME}"
fi

# The Parquet table name: If missing we use the CSV file name minus extension
if [ ! "${PARQUET_DB_NAME}" = "" ] && [ "${PARQUET_TABLE_NAME}" = "" ]; then
        PARQUET_TABLE_NAME="${CSV_FILENAME}"
fi

# The Hive table file
HIVE_TABLE_EXTENSION="hql"
HIVE_TABLE_FILENAME=${CSV_FILENAME}
HIVE_TABLE_DIR=${WORK_DIR}
HIVE_TABLE_FILE=${HIVE_TABLE_DIR}/${HIVE_TABLE_FILENAME}.${HIVE_TABLE_EXTENSION}

# The vars to build the Hive template
HIVE_TABLE_MODEL=`sed -e 's/^/\t/' ${SCHEMA_FILE}`
HIVE_TABLE_DELIMITER=${CSV_DELIMITER}
HIVE_TABLE_COMMENT="The table [${HIVE_TABLE_NAME}]"
PARQUET_TABLE_COMMENT="The parquet table [${PARQUET_TABLE_NAME}]"

# The parquet table file
PARQUET_TABLE_EXTENSION="parquet"
PARQUET_TABLE_FILENAME=${CSV_FILENAME}
PARQUET_TABLE_DIR=${WORK_DIR}
PARQUET_TABLE_FILE=${PARQUET_TABLE_DIR}/${PARQUET_TABLE_FILENAME}.${PARQUET_TABLE_EXTENSION}

# The Hive CREATE TABLE templates
HIVE_SEP=""
if [ ! "${HIVE_DB_NAME}" = "" ]; then
        HIVE_SEP="."
fi
HIVE_TEMPLATE="DROP TABLE ${HIVE_DB_NAME}${HIVE_SEP}${HIVE_TABLE_NAME};
CREATE TABLE ${HIVE_DB_NAME}${HIVE_SEP}${HIVE_TABLE_NAME} (
${HIVE_TABLE_MODEL}
)
COMMENT \"The table [${HIVE_DB_NAME}${HIVE_SEP}${HIVE_TABLE_NAME}]\"
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\\${HIVE_TABLE_DELIMITER}';
LOAD DATA LOCAL
INPATH '${CSV_DIR}/${CSV_BASENAME}' OVERWRITE INTO TABLE ${HIVE_DB_NAME}${HIVE_SEP}${HIVE_TABLE_NAME};"

# The Parquet CREATE TABLE template
PARQUET_SEP=""
if [ ! "${PARQUET_DB_NAME}" = "" ]; then
        PARQUET_SEP="."
fi
PARQUET_TEMPLATE="DROP TABLE ${PARQUET_DB_NAME}${PARQUET_SEP}${PARQUET_TABLE_NAME};
CREATE TABLE ${PARQUET_DB_NAME}${PARQUET_SEP}${PARQUET_TABLE_NAME} (
${HIVE_TABLE_MODEL}
)
COMMENT \"The table [${PARQUET_DB_NAME}${PARQUET_SEP}${PARQUET_TABLE_NAME}]\"
ROW FORMAT SERDE 'parquet.hive.serde.ParquetHiveSerDe'
  STORED AS
    INPUTFORMAT \"parquet.hive.DeprecatedParquetInputFormat\"
    OUTPUTFORMAT \"parquet.hive.DeprecatedParquetOutputFormat\";
set parquet.compression=\"snappy\";
INSERT OVERWRITE TABLE ${PARQUET_DB_NAME}${PARQUET_SEP}${PARQUET_TABLE_NAME} SELECT * FROM ${HIVE_DB_NAME}${DB_TABLE_SEP}${HIVE_TABLE_NAME};"

# -- PROG ----------------------------------------------------------------------

# Generate the Hive CREATE TABLE file
rm -rf "${HIVE_TABLE_FILE}"
touch "${HIVE_TABLE_FILE}"
echo -e "${HIVE_TEMPLATE}" > "${HIVE_TABLE_FILE}"

# Generate the Parquet table if asked
if [ ! "${PARQUET_DB_NAME}" = "" ]; then
	rm -rf "${PARQUET_TABLE_FILE}"
	touch "${PARQUET_TABLE_FILE}"
	echo -e "${PARQUET_TEMPLATE}" > "${PARQUET_TABLE_FILE}"
fi

# Create the Hive table if asked
if [ "${HIVE_CREATE}" = "1" ]; then
        if [ ! -f "hive" ]; then
                echo "-> Warning: The executable 'hive' doesn't exists !"
		echo "            Don't use \"--create\" to avoid this warning the next time."
                echo "            Anyway, a Hive 'CREATE TABLE' file named \"${HIVE_TABLE_NAME}.hql\" has been generated."
        else
                hive -f "${HIVE_TABLE_FILE}"
        fi
fi

# Create the Parquet table if asked
if [ "${PARQUET_CREATE}" = "1" ]; then
        if [ ! -f "hive" ]; then
                echo "-> Warning: The executable 'hive' doesn't exists !"
                echo "            Don't use \"--parquet-create\" to avoid this warning the next time."
                echo "            Anyway, a Parquet 'CREATE TABLE' file named \"${PARQUET_TABLE_NAME}.hql\" has been generated."
        else
                hive -f "${PARQUET_TABLE_FILE}"
        fi
fi

# Action to do if that script has been called by a parent script
if [ "${PARENT_CALL}" = "1" ]; then
        rm -rf "${SCHEMA_FILE}"
fi

