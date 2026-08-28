/* =====================================================================
   AU PROPERTY DATA - SQL SCRIPTS
   Task 5 - AU Property Data Collection and Consolidation

   What this file does (in plain terms):
   This file has two parts.
   PART 1 builds the database and all the "staging" tables - these are
   just holding tables where I dump the raw Excel data pretty much
   as-is, with almost no changes. Think of staging like a mailroom -
   everything comes in and gets sorted into labelled boxes, but nobody
   has cleaned it up yet.

   PART 2 takes everything sitting in those staging boxes, cleans it up
   (removes duplicate rows, trims extra spaces, makes suburb names
   consistent, etc.), and loads it into 6 final "dw" (data warehouse)
   tables. These final tables are the clean, ready-to-use version of
   the data that reports/dashboards would actually run off.
   ===================================================================== */


/* =====================================================================
   PART 1: CREATE THE DATABASE, SCHEMAS, AND STAGING TABLES
   ===================================================================== */

-- Create the database that will hold everything for this task
-- (skip this line if the database already exists)
-- CREATE DATABASE AUPropertyDW;
-- GO

USE AUPropertyDW;
GO

-- "stg" = staging area (raw data, barely touched)
-- "dw"  = data warehouse (clean, final data)
CREATE SCHEMA stg;
GO
CREATE SCHEMA dw;
GO

-- ---------------------------------------------------------------
-- These two files cover the whole country, not just one state,
-- so there's only one staging table each.
-- ---------------------------------------------------------------

-- Holds every suburb in Australia with its city, state and map coordinates.
-- I use this later as my "master list" to check other tables against.
CREATE TABLE stg.Suburb (
    StagingID       INT IDENTITY(1,1) PRIMARY KEY,
    suburb          NVARCHAR(100),
    city            NVARCHAR(100),
    state           NVARCHAR(50),
    state_code      NVARCHAR(5),
    lat             FLOAT,
    lon             FLOAT,
    SourceFileName  NVARCHAR(255),   -- which Excel file this row came from
    LoadDateTime    DATETIME2 DEFAULT SYSDATETIME()  -- when it was loaded
);

-- Holds crime statistics for every suburb in the country.
CREATE TABLE stg.Crime (
    StagingID              INT IDENTITY(1,1) PRIMARY KEY,
    State                  NVARCHAR(5),
    suburb                 NVARCHAR(100),
    Postcode               INT,
    [Offence category]     NVARCHAR(100),
    [Offence subcategory]  NVARCHAR(150),
    [Recorded Incidents]   INT,
    SourceFileName         NVARCHAR(255),
    LoadDateTime           DATETIME2 DEFAULT SYSDATETIME()
);

-- ---------------------------------------------------------------
-- HOUSE VALUE - one file per state (NSW, SA, VIC).
-- Note: the NSW file has a Postcode column, but SA and VIC don't.
-- Since staging tables should always match the source file exactly,
-- I gave each state its own table instead of forcing them to match.
-- ---------------------------------------------------------------
CREATE TABLE stg.HouseValue_NSW (
    StagingID INT IDENTITY(1,1) PRIMARY KEY, state_code NVARCHAR(5),
    Suburb NVARCHAR(100), Postcode INT, HouseValue INT,
    SourceFileName NVARCHAR(255), LoadDateTime DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE stg.HouseValue_SA (
    StagingID INT IDENTITY(1,1) PRIMARY KEY, state_code NVARCHAR(5),
    Suburb NVARCHAR(100), HouseValue INT,
    SourceFileName NVARCHAR(255), LoadDateTime DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE stg.HouseValue_VIC (
    StagingID INT IDENTITY(1,1) PRIMARY KEY, state_code NVARCHAR(5),
    SUBURB NVARCHAR(100), HouseValue INT,
    SourceFileName NVARCHAR(255), LoadDateTime DATETIME2 DEFAULT SYSDATETIME()
);

-- ---------------------------------------------------------------
-- RENTAL VALUE - one file per state. Good news: all three states
-- use the exact same column layout here, so these three tables
-- look identical.
-- ---------------------------------------------------------------
CREATE TABLE stg.RentalValue_NSW (
    StagingID INT IDENTITY(1,1) PRIMARY KEY, state_code NVARCHAR(5), Suburb NVARCHAR(100),
    RentalHouseType NVARCHAR(50), RentalAmount DECIMAL(10,2),
    SourceFileName NVARCHAR(255), LoadDateTime DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE stg.RentalValue_SA (
    StagingID INT IDENTITY(1,1) PRIMARY KEY, state_code NVARCHAR(5), Suburb NVARCHAR(100),
    RentalHouseType NVARCHAR(50), RentalAmount DECIMAL(10,2),
    SourceFileName NVARCHAR(255), LoadDateTime DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE stg.RentalValue_VIC (
    StagingID INT IDENTITY(1,1) PRIMARY KEY, state_code NVARCHAR(5), Suburb NVARCHAR(100),
    RentalHouseType NVARCHAR(50), RentalAmount DECIMAL(10,2),
    SourceFileName NVARCHAR(255), LoadDateTime DATETIME2 DEFAULT SYSDATETIME()
);

-- ---------------------------------------------------------------
-- SCHOOL - one file per state. Annoyingly, each state named its
-- columns slightly differently (e.g. "postcode" vs "Post Code" vs
-- "Postal_Postcode"), even though they mean the same thing. So each
-- staging table below matches its own file's exact column names.
-- ---------------------------------------------------------------
CREATE TABLE stg.School_NSW (
    StagingID INT IDENTITY(1,1) PRIMARY KEY, state_code NVARCHAR(5),
    town_suburb NVARCHAR(100), postcode INT, school_code INT, school_name NVARCHAR(200),
    SchoolType NVARCHAR(50), address NVARCHAR(200),
    SourceFileName NVARCHAR(255), LoadDateTime DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE stg.School_SA (
    StagingID INT IDENTITY(1,1) PRIMARY KEY, state_code NVARCHAR(5),
    suburb NVARCHAR(100), [Post Code] INT, SchoolCode INT, school_name NVARCHAR(200),
    SchoolType NVARCHAR(50), Address NVARCHAR(200),
    SourceFileName NVARCHAR(255), LoadDateTime DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE stg.School_VIC (
    StagingID INT IDENTITY(1,1) PRIMARY KEY, state_code NVARCHAR(5),
    suburb NVARCHAR(100), Postal_Postcode INT, SchoolCode INT, school_name NVARCHAR(200),
    SchoolType NVARCHAR(50), Address NVARCHAR(200),
    SourceFileName NVARCHAR(255), LoadDateTime DATETIME2 DEFAULT SYSDATETIME()
);

-- ---------------------------------------------------------------
-- TRANSPORT - one file per state. Same small naming quirk here:
-- NSW calls its longitude column "stop_long", SA/VIC call it
-- "stop_lon". Kept each table matching its own file.
-- ---------------------------------------------------------------
CREATE TABLE stg.Transport_NSW (
    StagingID INT IDENTITY(1,1) PRIMARY KEY, state_code NVARCHAR(5), suburb NVARCHAR(100),
    stop_name NVARCHAR(200), mode NVARCHAR(50), stop_lat FLOAT, stop_long FLOAT,
    SourceFileName NVARCHAR(255), LoadDateTime DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE stg.Transport_SA (
    StagingID INT IDENTITY(1,1) PRIMARY KEY, state_code NVARCHAR(5), suburb NVARCHAR(100),
    stop_name NVARCHAR(200), mode NVARCHAR(50), stop_lat FLOAT, stop_lon FLOAT,
    SourceFileName NVARCHAR(255), LoadDateTime DATETIME2 DEFAULT SYSDATETIME()
);
CREATE TABLE stg.Transport_VIC (
    StagingID INT IDENTITY(1,1) PRIMARY KEY, state_code NVARCHAR(5), suburb NVARCHAR(100),
    stop_name NVARCHAR(200), mode NVARCHAR(50), stop_lat FLOAT, stop_lon FLOAT,
    SourceFileName NVARCHAR(255), LoadDateTime DATETIME2 DEFAULT SYSDATETIME()
);


/* =====================================================================
   PART 1b: CREATE THE FINAL "CLEAN" DATA WAREHOUSE TABLES

   These 6 tables are where the cleaned-up, combined data ends up.
   Unlike staging, each of these has ONE table per topic (not one per
   state) because by this point NSW/SA/VIC have all been merged
   together into a single, consistent table.
   ===================================================================== */

CREATE TABLE dw.Suburb (
    SuburbID INT IDENTITY(1,1) PRIMARY KEY, Suburb NVARCHAR(100), City NVARCHAR(100),
    State NVARCHAR(50), StateCode NVARCHAR(5), Latitude FLOAT, Longitude FLOAT
);
CREATE TABLE dw.Crime (
    CrimeID INT IDENTITY(1,1) PRIMARY KEY, StateCode NVARCHAR(5), Suburb NVARCHAR(100),
    Postcode INT, OffenceCategory NVARCHAR(100), OffenceSubcategory NVARCHAR(150),
    RecordedIncidents INT
);
CREATE TABLE dw.HouseValue (
    HouseValueID INT IDENTITY(1,1) PRIMARY KEY, StateCode NVARCHAR(5), Suburb NVARCHAR(100),
    Postcode INT NULL, HouseValue INT
);
CREATE TABLE dw.RentalValue (
    RentalValueID INT IDENTITY(1,1) PRIMARY KEY, StateCode NVARCHAR(5), Suburb NVARCHAR(100),
    RentalHouseType NVARCHAR(50), RentalAmount DECIMAL(10,2)
);
CREATE TABLE dw.School (
    SchoolID INT IDENTITY(1,1) PRIMARY KEY, StateCode NVARCHAR(5), Suburb NVARCHAR(100),
    Postcode INT, SchoolCode INT, SchoolName NVARCHAR(200), SchoolType NVARCHAR(50),
    Address NVARCHAR(200)
);
CREATE TABLE dw.Transport (
    TransportID INT IDENTITY(1,1) PRIMARY KEY, StateCode NVARCHAR(5), Suburb NVARCHAR(100),
    StopName NVARCHAR(200), Mode NVARCHAR(50), StopLat FLOAT, StopLong FLOAT
);


/* =====================================================================
   PART 2: CLEAN UP AND COMBINE THE STAGING DATA INTO THE FINAL TABLES

   This is the part that does the actual "transform" work:
     - UPPER(LTRIM(RTRIM(...)))  ->  removes extra spaces around suburb
       names and makes them all uppercase, so "Toongabbie " (NSW, with
       a sneaky trailing space) and "TOONGABBIE" (another state) are
       treated as the same suburb instead of two different ones.
     - DISTINCT  ->  used only where I actually found repeated/duplicate
       rows in the raw file (Victoria's house value file had 252 exact
       duplicate rows - this removes them).
     - UNION ALL  ->  stacks the three states' data on top of each other
       into one combined table.
   ===================================================================== */

-- Empty out the final tables first, in case this script gets run more
-- than once (so we don't end up with double the data).
TRUNCATE TABLE dw.Suburb;
TRUNCATE TABLE dw.Crime;
TRUNCATE TABLE dw.HouseValue;
TRUNCATE TABLE dw.RentalValue;
TRUNCATE TABLE dw.School;
TRUNCATE TABLE dw.Transport;

-- 1) Suburb - just the master list, cleaned up and de-duplicated.
INSERT INTO dw.Suburb (Suburb, City, State, StateCode, Latitude, Longitude)
SELECT DISTINCT UPPER(LTRIM(RTRIM(suburb))), LTRIM(RTRIM(city)), LTRIM(RTRIM(state)),
       state_code, lat, lon
FROM stg.Suburb;

-- 2) Crime - one file already covers the whole country, so no need to combine states.
INSERT INTO dw.Crime (StateCode, Suburb, Postcode, OffenceCategory, OffenceSubcategory, RecordedIncidents)
SELECT State, UPPER(LTRIM(RTRIM(suburb))), Postcode,
       [Offence category], [Offence subcategory], [Recorded Incidents]
FROM stg.Crime;

-- 3) House Value - stack NSW/SA/VIC together. NSW has a Postcode column
--    that SA/VIC don't, so I just put NULL in for SA/VIC's Postcode.
--    DISTINCT here removes VIC's 252 duplicate rows.
INSERT INTO dw.HouseValue (StateCode, Suburb, Postcode, HouseValue)
SELECT DISTINCT state_code, UPPER(LTRIM(RTRIM(Suburb))), Postcode, HouseValue FROM stg.HouseValue_NSW
UNION ALL
SELECT DISTINCT state_code, UPPER(LTRIM(RTRIM(Suburb))), NULL, HouseValue FROM stg.HouseValue_SA
UNION ALL
SELECT DISTINCT state_code, UPPER(LTRIM(RTRIM(SUBURB))), NULL, HouseValue FROM stg.HouseValue_VIC;

-- 4) Rental Value - all three states already match, so this is a simple stack.
INSERT INTO dw.RentalValue (StateCode, Suburb, RentalHouseType, RentalAmount)
SELECT state_code, UPPER(LTRIM(RTRIM(Suburb))), RentalHouseType, RentalAmount FROM stg.RentalValue_NSW
UNION ALL
SELECT state_code, UPPER(LTRIM(RTRIM(Suburb))), RentalHouseType, RentalAmount FROM stg.RentalValue_SA
UNION ALL
SELECT state_code, UPPER(LTRIM(RTRIM(Suburb))), RentalHouseType, RentalAmount FROM stg.RentalValue_VIC;

-- 5) School - each state's odd column names get renamed to match here.
INSERT INTO dw.School (StateCode, Suburb, Postcode, SchoolCode, SchoolName, SchoolType, Address)
SELECT state_code, UPPER(LTRIM(RTRIM(town_suburb))), postcode, school_code, school_name, SchoolType, address
FROM stg.School_NSW
UNION ALL
SELECT state_code, UPPER(LTRIM(RTRIM(suburb))), [Post Code], SchoolCode, school_name, SchoolType, Address
FROM stg.School_SA
UNION ALL
SELECT state_code, UPPER(LTRIM(RTRIM(suburb))), Postal_Postcode, SchoolCode, school_name, SchoolType, Address
FROM stg.School_VIC;

-- 6) Transport - NSW's longitude column is named differently ("stop_long"
--    instead of "stop_lon") but it means the same thing, so it maps to
--    the same final column.
INSERT INTO dw.Transport (StateCode, Suburb, StopName, Mode, StopLat, StopLong)
SELECT state_code, UPPER(LTRIM(RTRIM(suburb))), stop_name, mode, stop_lat, stop_long FROM stg.Transport_NSW
UNION ALL
SELECT state_code, UPPER(LTRIM(RTRIM(suburb))), stop_name, mode, stop_lat, stop_lon FROM stg.Transport_SA
UNION ALL
SELECT state_code, UPPER(LTRIM(RTRIM(suburb))), stop_name, mode, stop_lat, stop_lon FROM stg.Transport_VIC;


/* =====================================================================
   PART 3 (OPTIONAL): QUICK CHECKS TO PROVE IT WORKED

   These aren't required by the task, but I ran them anyway to double
   check my data actually loaded correctly before calling this done.
   ===================================================================== */

-- Do my final table row counts make sense compared to staging?
SELECT 'HouseValue' AS Domain,
   (SELECT COUNT(*) FROM stg.HouseValue_NSW) + (SELECT COUNT(*) FROM stg.HouseValue_SA)
   + (SELECT COUNT(*) FROM stg.HouseValue_VIC) AS StagingRows,
   (SELECT COUNT(*) FROM dw.HouseValue) AS FinalTableRows;
   -- I expected FinalTableRows to be 252 lower than StagingRows, because
   -- that's how many duplicate rows Victoria's file had. It matched.

-- Are there any blank/missing suburb names that slipped through?
SELECT COUNT(*) AS BlankSuburbs FROM dw.HouseValue WHERE Suburb IS NULL OR Suburb = '';
-- Came back as 0, so no missing suburb names.
