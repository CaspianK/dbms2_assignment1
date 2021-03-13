CREATE DATABASE KazData
GO

USE KazData
GO

--import from .csv
CREATE TABLE temp (
	Country VARCHAR(10),
	Country_ID VARCHAR(3),
	Year_ID SMALLINT,
	Indicator varchar(100),
	Indicator_ID VARCHAR(25),
	Value_Data FLOAT)

BULK INSERT temp
    FROM 'C:\Users\shalk\OneDrive\Desktop\edu\Databases\ASMT1\data.csv'
    WITH ( FIRSTROW = 3, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n' )

SELECT Year_ID, Indicator, Indicator_ID, Value_Data
INTO EmploymentStats
FROM temp
WHERE
Indicator = 'Vulnerable employment female (% of female employment) (modeled ILO estimate)'
OR
Indicator = 'Vulnerable employment male (% of male employment) (modeled ILO estimate)'
OR
Indicator = 'Unemployment female (% of female labor force) (modeled ILO estimate)'
OR
Indicator = 'Unemployment male (% of male labor force) (modeled ILO estimate)'
OR
Indicator = 'Children in employment female (% of female children ages 7-14)'
OR
Indicator = 'Children in employment male (% of male children ages 7-14)'

DROP TABLE temp

--import from .json
Declare @JSON varchar(max)
SELECT @JSON=BulkColumn
FROM OPENROWSET (BULK 'C:\Users\shalk\OneDrive\Desktop\edu\Databases\ASMT1\data.json', SINGLE_CLOB) import
SELECT * INTO temp
FROM OPENJSON (@JSON)
WITH ([Year] varchar(10),
      [Indicator Name] varchar(100),
      [Indicator Code] varchar(100),
      [Value] varchar(20))

CREATE TABLE EmploymentStats_JSON (
	Year_ID SMALLINT,
	Indicator varchar(100),
	Indicator_ID VARCHAR(25),
	Value_Data FLOAT)

INSERT INTO EmploymentStats_JSON
SELECT * FROM temp
WHERE
[Indicator Name] = 'Vulnerable employment female (% of female employment) (modeled ILO estimate)'
OR
[Indicator Name] = 'Vulnerable employment male (% of male employment) (modeled ILO estimate)'
OR
[Indicator Name] = 'Unemployment female (% of female labor force) (modeled ILO estimate)'
OR
[Indicator Name] = 'Unemployment male (% of male labor force) (modeled ILO estimate)'
OR
[Indicator Name] = 'Children in employment female (% of female children ages 7-14)'
OR
[Indicator Name] = 'Children in employment male (% of male children ages 7-14)'

DROP TABLE temp

--check for nulls
SELECT
	SUM(CASE WHEN Year_ID IS NULL OR Year_ID = '' THEN 1 ELSE 0 END) as Year_NULLS,
	SUM(CASE WHEN Indicator IS NULL OR Indicator = '' THEN 1 ELSE 0 END) as Indicator_NULLS,
	SUM(CASE WHEN Indicator_ID IS NULL OR Indicator_ID = '' THEN 1 ELSE 0 END) as IndicatorID_NULLS,
	SUM(CASE WHEN Value_Data IS NULL OR Value_Data = '' THEN 1 ELSE 0 END) as Value_NULLS
	FROM EmploymentStats

--FACTS
--#1 Unemployment rate has increased by a factor of 5.96388
--since Kazakhstan gained its independence, having the peak value of 15.027% in 1999
--and the minimum value of 0.555% in 1991. As we can see, after the fall of the USSR
--Kazakhstan's economy experienced decline.
DECLARE @Unemp_1991 FLOAT, @Unemp_2019 FLOAT, @Peak_Year SMALLINT,
		@Peak_Val FLOAT, @Min_Year SMALLINT, @Min_Val FLOAT;
SET @Unemp_1991 = (
SELECT (SUM(Value_Data) / 2) FROM EmploymentStats
WHERE Indicator LIKE 'Unemployment%'
AND Year_ID = 1991
)
SET @Unemp_2019 = (
SELECT (SUM(Value_Data) / 2) FROM EmploymentStats
WHERE Indicator LIKE 'Unemployment%'
AND Year_ID = 2019
)
SET @Peak_Val = (
SELECT MAX(Value_Data) FROM EmploymentStats WHERE Indicator LIKE 'Unemployment%'
)
SET @Peak_Year = (
SELECT Year_ID FROM EmploymentStats
WHERE Indicator LIKE 'Unemployment%'
AND Value_Data = @Peak_Val
)
SET @Min_Val = (
SELECT MIN(Value_Data) FROM EmploymentStats WHERE Indicator LIKE 'Unemployment%'
)
SET @Min_Year = (
SELECT Year_ID FROM EmploymentStats
WHERE Indicator LIKE 'Unemployment%'
AND Value_Data = @Min_Val
)
PRINT CONCAT('Unemployment rate has increased by a factor of ', @Unemp_2019 / @Unemp_1991,
' since Kazakhstan gained its independence, having the peak value of ', @Peak_Val,
'% in ', @Peak_Year, ' and the minimum value of ', @Min_Val, '% in ', @Min_Year, '.')

--#2
--In average there are more women vulnerably employed than men. Though the reasons
--might not be clear, it signalizes about existing gender gap in the country, since
--more women are not socially secured at their jobs and/or not having a stable salary.
DECLARE @Vuln_Wom FLOAT, @Vuln_Men FLOAT;
SET @Vuln_Wom = (
SELECT AVG(Value_Data) FROM EmploymentStats
WHERE Indicator LIKE 'Vulnerable%female%'
)
SET @Vuln_Men = (
SELECT AVG(Value_Data) FROM EmploymentStats
WHERE Indicator LIKE 'Vulnerable employment male%'
)
PRINT CONCAT('In average there are more women vulnerably employed than men (',
@Vuln_Wom, '% vs ', @Vuln_Men, '% respectively)')

--#3
--Since 1996 percentage of children in labor has decreased by 8 times,
--which shows socioeconomic growth of the country in the decade.
DECLARE @Children_1996 FLOAT, @Children_2006 FLOAT;
SET @Children_1996 = (
SELECT AVG(Value_Data) FROM EmploymentStats
WHERE Indicator LIKE 'Children%'
AND Year_ID = 1996
)
SET @Children_2006 = (
SELECT AVG(Value_Data) FROM EmploymentStats
WHERE Indicator LIKE 'Children%'
AND Year_ID = 2006
)
PRINT CONCAT('During the period of 1996-2006, percentage of child laber has
been decreased by a factor of ', @Children_1996 / @Children_2006, ', from ', 
@Children_1996, '% to ', @Children_2006, '%.')