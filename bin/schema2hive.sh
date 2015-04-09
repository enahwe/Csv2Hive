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
  -q QUOTECHAR  The quote character surrounding the fields.
  --create	Creates the table in Hive.
                Overrides the previous Hive table, as well as its file in HDFS.
  --db-name DB_NAME
		Optional name of Hive database where to create the table.
  --table-name TABLE_NAME
		Specify a name for the table to be created.
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
		if [ "${CSV_DELIMITER}" = "" ]; then
                        echo "- Error: The delimiter is missing !"
                        exit 1
                fi
		continue
	fi
	if [ "$param" = "-t" ] || [ "$param" = "--tab" ]; then
		CSV_DELIMITER="\t"
		continue
	fi

	# QUOTE_CHAR
        if [ "$param" = "-q" ]; then
                option="OPTION_QUOTE_CHAR"
                continue
        fi
        if [ "$option" = "OPTION_QUOTE_CHAR" ]; then
                option=""
                QUOTE_CHAR=$param
		if [ "${QUOTE_CHAR}" = "" ]; then
                        echo "- Error: The quote character is missing !"
                        exit 1
                fi
                continue
        fi

        # HIVE_CREATE
        if [ "$param" = "--create" ]; then
                HIVE_CREATE="1"
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
		if [ "${HIVE_DB_NAME}" = "" ]; then
                        echo "- Error: The Hive DB name is missing !"
                        exit 1
                fi
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
		if [ "${HIVE_TABLE_NAME}" = "" ]; then
                        echo "- Error: The Hive table name is missing !"
                        exit 1
                fi
                continue
        fi

	# HIVE_TABLE_PREFIX
        if [ "$param" = "--table-prefix" ]; then
                option="OPTION_HIVE_TABLE_PREFIX"
                continue
        fi
        if [ "$option" = "OPTION_HIVE_TABLE_PREFIX" ]; then
                option=""
                HIVE_TABLE_PREFIX=$param
		if [ "${HIVE_TABLE_PREFIX}" = "" ]; then
                        echo "- Error: The Hive table prefix is missing !"
                        exit 1
                fi
                continue
        fi

	# HIVE_TABLE_SUFFIX
        if [ "$param" = "--table-suffix" ]; then
                option="OPTION_HIVE_TABLE_SUFFIX"
                continue
        fi
        if [ "$option" = "OPTION_HIVE_TABLE_SUFFIX" ]; then
                option=""
                HIVE_TABLE_SUFFIX=$param
		if [ "${HIVE_TABLE_SUFFIX}" = "" ]; then
                        echo "- Error: The Hive table suffix is missing !"
                        exit 1
                fi
                continue
        fi

	# PARQUET_CREATE
        if [ "$param" = "--parquet-create" ]; then
                PARQUET_CREATE="1"
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
		if [ "${PARQUET_DB_NAME}" = "" ]; then
                        echo "- Error: The Parquet DB name is missing !"
                        exit 1
                fi
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
		if [ "${PARQUET_TABLE_NAME}" = "" ]; then
                        echo "- Error: The Parquet table name is missing !"
                        exit 1
                fi
                continue
        fi

	# PARQUET_TABLE_PREFIX
        if [ "$param" = "--parquet-table-prefix" ]; then
                option="OPTION_PARQUET_TABLE_PREFIX"
                continue
        fi
        if [ "$option" = "OPTION_PARQUET_TABLE_PREFIX" ]; then
                option=""
                PARQUET_TABLE_PREFIX=$param
		if [ "${PARQUET_TABLE_PREFIX}" = "" ]; then
                        echo "- Error: The Parquet table prefix is missing !"
                        exit 1
                fi
                continue
        fi

	# PARQUET_TABLE_SUFFIX
        if [ "$param" = "--parquet-table-suffix" ]; then
                option="OPTION_PARQUET_TABLE_SUFFIX"
                continue
        fi
        if [ "$option" = "OPTION_PARQUET_TABLE_SUFFIX" ]; then
                option=""
                PARQUET_TABLE_SUFFIX=$param
		if [ "${PARQUET_TABLE_SUFFIX}" = "" ]; then
                        echo "- Error: The Parquet table suffix is missing !"
                        exit 1
                fi
                continue
        fi

        # HDFS_FILENAME
        if [ "$param" = "--hdfs-file-name" ]; then
                option="OPTION_HDFS_FILENAME"
                continue
        fi
        if [ "$option" = "OPTION_HDFS_FILENAME" ]; then
                option=""
                HDFS_FILENAME=$param
		if [ "${HDFS_FILENAME}" = "" ]; then
                        echo "- Error: The HDFS file name is missing !"
                        exit 1
                fi
                continue
        fi

	# HDFS_FILE_PREFIX
        if [ "$param" = "--hdfs-file-prefix" ]; then
                option="OPTION_HDFS_FILE_PREFIX"
                continue
        fi
        if [ "$option" = "OPTION_HDFS_FILE_PREFIX" ]; then
                option=""
                HDFS_FILE_PREFIX=$param
		if [ "${HDFS_FILE_PREFIX}" = "" ]; then
                        echo "- Error: The HDFS file prefix is missing !"
                        exit 1
                fi
                continue
        fi

	# HDFS_FILE_SUFFIX
        if [ "$param" = "--hdfs-file-suffix" ]; then
                option="OPTION_HDFS_FILE_SUFFIX"
                continue
        fi
        if [ "$option" = "OPTION_HDFS_FILE_SUFFIX" ]; then
                option=""
                HDFS_FILE_SUFFIX=$param
		if [ "${HDFS_FILE_SUFFIX}" = "" ]; then
                        echo "- Error: The HDFS file suffix is missing !"
                        exit 1
                fi
                continue
        fi

	# PARENT_CALL
        if [ "$param" = "--parent-call" ]; then
                PARENT_CALL="1"
                continue
        fi

	# OPTIONS TO SKIP
	if [ "$param" = "-s" ] || [ "$param" = "--separated-header" ]; then
                option="OPTION_SEPARATED_HEADER"
                continue
        fi
        if [ "$option" = "OPTION_SEPARATED_HEADER" ]; then
                option=""
                continue
        fi
        if [ "$param" = "--no-header" ]; then
                continue
        fi

	# CSV_FILE
	if [ "${CSV_FILE}" = "" ]; then
		CSV_FILE=$param
		CSV_DIR=`(cd \`dirname ${CSV_FILE}\`; pwd)`
                CSV_BASENAME=$(basename ${CSV_FILE})
                CSV_FILENAME=${CSV_BASENAME%.*}
		if [ -z "${CSV_BASENAME##*.*}" ] ;then
			CSV_EXTENSION="${CSV_BASENAME##*.}"
		fi
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

# Search the delimiter if not specified
if [ "${CSV_DELIMITER}" = "" ]; then
	TWO_FIRST_LINES_FILE=${WORK_DIR}/${CSV_FILENAME}.2FirstLines
        head -2 "${CSV_FILE}" > "${TWO_FIRST_LINES_FILE}"
        STRING_1=`head -1 "${TWO_FIRST_LINES_FILE}"`
        STRING_2=`tail -n +2 "${TWO_FIRST_LINES_FILE}"`
        rm -rf "${TWO_FIRST_LINES_FILE}"
        CSV_DELIMITER=`python "${SCRIPT_DIR}/searchDelimiter.py" "${STRING_1}" "${STRING_2}" "${QUOTE_CHAR}"`
        if [ "${CSV_DELIMITER}" = "NO_DELIMITER" ]; then
                echo "- Error: Delimiter not found !"
		echo "         Maybe the number of delimiters are differents in the two first lines !"
                echo "         Or maybe you should check the quote character (-q option) !"
                exit 1
        fi
fi

# If the Hive table name is missing, then we use the CSV file name minus extension
if [ "${HIVE_TABLE_NAME}" = "" ]; then
        HIVE_TABLE_NAME="${CSV_FILENAME}"
fi
# If the Hive table prefix or suffix exist, then we surround the Hive table name with them
if [ ! "${HIVE_TABLE_PREFIX}" = "" ]; then
        HIVE_TABLE_NAME="${HIVE_TABLE_PREFIX}${HIVE_TABLE_NAME}"
fi
if [ ! "${HIVE_TABLE_SUFFIX}" = "" ]; then
        HIVE_TABLE_NAME="${HIVE_TABLE_NAME}${HIVE_TABLE_SUFFIX}"
fi

# If the Parquet table name is missing but the Parquet database or the prefix or
# the suffix are specified, then we use the CSV file name minus extension
if [ "${PARQUET_TABLE_NAME}" = "" ]; then
	if [ ! "${PARQUET_DB_NAME}" = "" ] || [ ! "${PARQUET_TABLE_PREFIX}" = "" ] || [ ! "${PARQUET_TABLE_SUFFIX}" = "" ]; then
        	PARQUET_TABLE_NAME="${CSV_FILENAME}"
	fi
fi
# If the Parquet table name exists and also the prefix or suffix, then we surround the Parquet table name with them
if [ ! "${PARQUET_TABLE_NAME}" = "" ]; then
	if [ ! "${PARQUET_TABLE_PREFIX}" = "" ]; then
        	PARQUET_TABLE_NAME="${PARQUET_TABLE_PREFIX}${PARQUET_TABLE_NAME}"
	fi
	if [ ! "${PARQUET_TABLE_SUFFIX}" = "" ]; then
        	PARQUET_TABLE_NAME="${PARQUET_TABLE_NAME}${PARQUET_TABLE_SUFFIX}"
	fi
fi

# If the HDFS file name is missing, then we use the CSV file name
if [ "${HDFS_FILENAME}" = "" ]; then
        HDFS_FILENAME="${CSV_BASENAME}"
fi
HDFS_BASENAME=${HDFS_FILENAME}
HDFS_FILENAME=${HDFS_BASENAME%.*}
if [ -z "${HDFS_BASENAME##*.*}" ] ;then
	HDFS_EXTENSION="${HDFS_BASENAME##*.}"
fi
if [ "${HDFS_EXTENSION}" = "" ] && [ ! "${CSV_EXTENSION}" = "" ]; then
	HDFS_EXTENSION=${CSV_EXTENSION}
fi
# If the HDFS file prefix or suffix exist, then we surround the HDFS file name with them
if [ ! "${HDFS_FILE_PREFIX}" = "" ]; then
        HDFS_FILENAME="${HDFS_FILE_PREFIX}${HDFS_FILENAME}"
fi
if [ ! "${HDFS_FILE_SUFFIX}" = "" ]; then
        HDFS_FILENAME="${HDFS_FILENAME}${HDFS_FILE_SUFFIX}"
fi
# We update the HDFS file base name (e.g: filename + extension)
HDFS_BASENAME=${HDFS_FILENAME}
if [ ! "${HDFS_EXTENSION}" = "" ]; then
        HDFS_BASENAME="${HDFS_FILENAME}.${HDFS_EXTENSION}"
fi

# The schema file
SCHEMA_FILE=${WORK_DIR}/${CSV_FILENAME}.schema

# The Hive CREATE TABLE file
HIVE_TABLE_FILE=${WORK_DIR}/${CSV_FILENAME}.hql

# The parquet CREATE TABLE file
PARQUET_TABLE_FILE=${WORK_DIR}/${CSV_FILENAME}.parquet

# The vars for building the Hive template
HIVE_TABLE_MODEL=`sed -e 's/^/\t/' ${SCHEMA_FILE}`
HIVE_TABLE_DELIMITER=${CSV_DELIMITER}
HIVE_TABLE_COMMENT="The table [${HIVE_TABLE_NAME}]"
PARQUET_TABLE_COMMENT="The parquet table [${PARQUET_TABLE_NAME}]"

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
INPATH '${WORK_DIR}/${HDFS_BASENAME}' OVERWRITE INTO TABLE ${HIVE_DB_NAME}${HIVE_SEP}${HIVE_TABLE_NAME};"

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
INSERT OVERWRITE TABLE ${PARQUET_DB_NAME}${PARQUET_SEP}${PARQUET_TABLE_NAME} SELECT * FROM ${HIVE_DB_NAME}${HIVE_SEP}${HIVE_TABLE_NAME};"

# -- PROG ----------------------------------------------------------------------

# Creates the link to the CSV file
rm -f "${WORK_DIR}/${HDFS_BASENAME}"
ln -s "${CSV_DIR}/${CSV_BASENAME}" "${WORK_DIR}/${HDFS_BASENAME}"

# Generates the Hive CREATE TABLE file
rm -f "${HIVE_TABLE_FILE}"
touch "${HIVE_TABLE_FILE}"
echo -e "${HIVE_TEMPLATE}" > "${HIVE_TABLE_FILE}"

# Generates the Parquet CREATE TABLE file if the Parquet table name exists
if [ ! "${PARQUET_TABLE_NAME}" = "" ]; then
	rm -f "${PARQUET_TABLE_FILE}"
	touch "${PARQUET_TABLE_FILE}"
	echo -e "${PARQUET_TEMPLATE}" > "${PARQUET_TABLE_FILE}"
fi

# Checks if the hive executable exists
HIVE_EXISTS=0
if which "hive" >/dev/null; then
	HIVE_EXISTS=1
fi

# Create the Hive table if asked
if [ "${HIVE_CREATE}" = "1" ]; then
        if [ "${HIVE_EXISTS}" = "1" ]; then
                hive -f "${HIVE_TABLE_FILE}"
        else
                echo "-> Warning: The executable 'hive' doesn't exists !"
		echo "            Don't use \"--create\" to avoid this warning the next time."
                echo "            Anyway, a Hive 'CREATE TABLE' file named \"${HIVE_TABLE_NAME}.hql\" has been generated."
        fi
fi

# Create the Parquet table if asked
if [ "${PARQUET_CREATE}" = "1" ]; then
        if [ "${HIVE_EXISTS}" = "1" ]; then
                hive -f "${PARQUET_TABLE_FILE}"
        else
                echo "-> Warning: The executable 'hive' doesn't exists !"
                echo "            Don't use \"--parquet-create\" to avoid this warning the next time."
                echo "            Anyway, a Parquet 'CREATE TABLE' file named \"${PARQUET_TABLE_NAME}.hql\" has been generated."
        fi
fi

# Action to do if that script has been called by a parent script
if [ "${PARENT_CALL}" = "1" ]; then
        rm -rf "${SCHEMA_FILE}"
fi

