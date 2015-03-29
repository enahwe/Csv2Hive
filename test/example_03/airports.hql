DROP TABLE myDatabase.myAirportTable;
CREATE TABLE myDatabase.myAirportTable (
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
COMMENT "The table [myDatabase.myAirportTable]"
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\,';
LOAD DATA LOCAL
INPATH '/home/user/Csv2Hive/test/data/airports.csv' OVERWRITE INTO TABLE myDatabase.myAirportTable;
