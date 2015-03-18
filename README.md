[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif "Donate for Csv2Hive")]
(https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=Z2CBDC45UYGKN)

![](/Csv2Hive.png "Csv2Hive")

## "The data together with its schema, is fully self-describing"

The philosophy of Csv2Hive is that the data, together with its schema, is fully self-describing. This approach is purely dynamic, so you don't need to write any schemas at all. To allow this dynamic behaviour, Csv2Hive parses automatically the first thousands lines for each CSV file it operates, in order to evaluate the right type for each column. Further to facilitate the automation, Csv2Hive evaluates dynamically which kind of delimiter each CSV file is using.

## Requirements
* Requires a Unix or a Linux operating system to run
* Requires Python V2.7
  * Examples of commands to install Python on Linux (e.g: Debian, Ubuntu) :
    * $ sudo apt-get install python-dev python-pip python-setuptools build-essential
    * $ pip install setuptools --upgrade
* Requires CsvKit V0.9.0 (https://csvkit.readthedocs.org/)
  * Commands to install CsvKit :
    * $ pip install csvkit
    * $ pip install csvkit --upgrade
  * PIP requirements to install CsvKit-0.9.0 in offline mode (e.g: useful for safe install on a hadoop node) :
    * xlrd-0.9.3, SQLAlchemy-0.9.9, jdcal-1.0, openpyxl-2.2.0, six-1.9.0, python-dateutil-2.2, dbf-0.94.003

## Executing
Example with direct executing :
```
$ unzip Csv2Hive-master.zip -d ~ ; mv ~/Csv2Hive-master ~/Csv2Hive
$ cd ~/Csv2Hive
$ ./bin/csv2hive.sh ~/myCsvFile.csv
```
Example with configuring your PATH :
```
$ export PATH=/home/`whoami`/Csv2Hive/bin:$PATH
$ csv2hive.sh myCsvFile.csv
```
Example with referencing into /usr/bin :
```
$ sudo mv ~/Csv2Hive /usr/lib
$ sudo ln -s /usr/lib/Csv2Hive/bin/csv2hive.sh /usr/bin/csv2hive
$ csv2hive myTsvFile.tsv
```

## Usage
```
usage: csv2hive [CSV_FILE] {WORK_DIR}

Generate a Hive 'CREATE TABLE' statement given a CSV file and execute that
statement directly on Hive by uploading the CSV file to HDFS.
The Parquet format is also supported.

positional argument:
  CSV_FILE      The CSV file to operate on.
  WORK_DIR      The work directory where to create the Hive file (optional).
                If missing, the work directory will be the same as the CSV file.
                In that directory, the name of the output Hive file will be the
                same as the CSV file but with the extension '.hql'.

optional arguments:
  -h, --help    Show this help message and exit.
  -d DELIMITER, --delimiter DELIMITER
                Specify the delimiter used in the CSV file.
                If not present without -t nor --tab, then the delimiter will
                be discovered automatically between {',' '\\\t' ';' ' '}.
  -t, --tab     Indicates that the tab delimiter is used in the CSV file.
                Overrides -d and --delimiter.
                If not present without -d nor --delimiter, then the delimiter
                will be discovered automatically between {',' '\\\t' ';' ' '}.
  --no-header   If present, indicates that the CSV file hasn't header.
                Then the columns will be named 'column1', 'column2', and so on.
  --db-name DB_NAME
                Optional name for database where to create the Hive table.
  --table-name TABLE_NAME
                Specify a name for the Hive table to be created.
                If omitted, the file name (minus extension) will be used.
  --create      Ask to create the table in Hive.
  --parquet-db-name PARQUET_DB_NAME
                Optional name for database where to create the Parquet table.
  --parquet-table-name PARQUET_TABLE_NAME
                Specify a name for the Parquet table to be created.
                If omitted, the file name (minus extension) will be used.
  --parquet-create
                Ask to create the Parquet table.
```

## Examples
### Example 1 (the simplest way to create a Hive table)

This example generates a 'CREATE TABLE' statement file in order to create a Hive table named 'airports' :
```
$ csv2hive --create airports.csv
```
Note that from the new Hive statement file named 'airports.hql', the delimiter, the number of columns and the type for each column have been evaluated dynamically :
```
$ less airports.hql

DROP TABLE airports;
CREATE TABLE airports (
        Airport_ID int,
        Name string,
        City string,
        Country string,
        IATA_FAA string,
        ICAO string,
        Latitude float,
        Longitude float,
        Altitude int,
        Timezone float,
        DST string,
        Tz_db_time_zone string
)
COMMENT "The table [airports]"
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\,'
LOAD DATA LOCAL
INPATH '/home/user/Csv2Hive/test/airports.csv' OVERWRITE INTO TABLE airports;
```

### Example 2 (specifying the names for database and table)
You can specify the name of Hive database, and the Hive table's name as follows :
```
$ csv2hive --create --db-name "myDatabase" --table-name "myAirportTable" airports.csv
```

### Example 3 (no creating the table on Hive)
If you don't want to create the table on Hive or if Hive is not installed on the same machine, don't use the '--create' option (anyway Cs2Hive will generates for you a '.hql' file) :
```
$ csv2hive airports.csv
```

### Example 4 (create a Parquet table just after the Hive table)
You can create a Parquet table just after creating the Hive table as follows :
```
$ csv2hive --create --parquet-create --parquet-db-name "myParquetDb" --parquet-table-name "myAirportTable" airports.csv
```
Cs2Hive will generates the two 'CREATE TABLE' statement files '.hql' and '.parquet'.

### Example 5 (creating a Hive table in two steps)
It's possible first to generate the schema in order to modify the columns names, before to create the Hive table. This could be especially useful when the CSV file hasn't header :
```
$ csv2schema --no-header airports.csv
$ vi airports.schema
```
After modifying the columns names, then you can create the Hive table as follows :
```
$ schema2hive --create airports.csv
```
