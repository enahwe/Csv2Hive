DROP TABLE airports-noheader;
CREATE TABLE airports-noheader (
	column1 int,
	column2 string,
	column3 string,
	column4 string,
	myModifiedColumn5 string,
	column6 string,
	column7 float,
	column8 float,
	myModifiedColumn9 int,
	column10 float,
	column11 string,
	column12 string
)
COMMENT "The table [airports-noheader]"
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\,';
LOAD DATA LOCAL
INPATH '/home/user/Csv2Hive/test/data/airports-noheader.csv' OVERWRITE INTO TABLE airports-noheader;
