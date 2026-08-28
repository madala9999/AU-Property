/* ============================================================
   01 - Create the database and the staging (load) tables
   Project: Property Analysis - Data Warehouse (PropertyDW)
   Author:  Srikanth

   What this script does (in my own words):
   The staging tables are just "landing zones". SSIS dumps the
   raw files into them exactly as they come, so I made every
   column NVARCHAR (text). I don't try to fix or convert
   anything here - all the cleaning happens later when I move
   data from staging into the dimension and fact tables.
   That way, if a load fails I can look at the raw data in SQL
   and see what the file actually contained.
   ============================================================ */

-- Create the database if it is not there yet
IF DB_ID('PropertyDW') IS NULL
    CREATE DATABASE PropertyDW;
GO

USE PropertyDW;
GO

/* ------------------------------------------------------------
   1. load_Schools
   Raw copy of NSW-Public-Schools-Master-Dataset-07032017.csv
   (one row per school, ~2,211 rows).
   Most columns are NVARCHAR(50). A few are longer because the
   CSV has long values in them (school names, emails, streets).
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.load_Schools') IS NOT NULL DROP TABLE dbo.load_Schools;
CREATE TABLE dbo.load_Schools (
    school_code              NVARCHAR(50),
    AgeID                    NVARCHAR(50),
    school_name              NVARCHAR(255),
    street                   NVARCHAR(255),
    town_suburb              NVARCHAR(50),
    postcode                 NVARCHAR(50),
    student_number           NVARCHAR(50),   -- has 'np' where the number is hidden
    indigenous_pct           NVARCHAR(50),
    lbote_pct                NVARCHAR(50),
    ICSEA_Value              NVARCHAR(50),   -- also has 'np' values
    level_of_schooling       NVARCHAR(50),
    selective_school         NVARCHAR(50),
    opportunity_class        NVARCHAR(50),
    school_specialty_type    NVARCHAR(50),
    school_subtype           NVARCHAR(50),
    support_classes          NVARCHAR(50),
    preschool_ind            NVARCHAR(50),
    distance_education       NVARCHAR(50),
    intensive_english_centre NVARCHAR(50),
    school_gender            NVARCHAR(50),
    phone                    NVARCHAR(50),
    school_email             NVARCHAR(255),
    fax                      NVARCHAR(50),
    late_opening_school      NVARCHAR(50),
    date_1st_teacher         NVARCHAR(50),
    lga                      NVARCHAR(50),
    electorate               NVARCHAR(50),
    fed_electorate           NVARCHAR(50),
    operational_directorate  NVARCHAR(50),
    principal_network        NVARCHAR(50),
    facs_district            NVARCHAR(255),  -- this one has long comma lists
    local_health_district    NVARCHAR(50),
    aecg_region              NVARCHAR(50),
    ASGS_remoteness          NVARCHAR(50),
    latitude                 NVARCHAR(50),
    longitude                NVARCHAR(50),
    date_extracted           NVARCHAR(50)
);
GO

/* ------------------------------------------------------------
   2. load_PropertyMedianValue
   Raw copy of NSW_PropertyMedainValue.xlsx (yes, the file name
   has a typo - "Medain" - I kept the original file name).
   Everything is text because Excel numbers come through in
   odd formats.
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.load_PropertyMedianValue') IS NOT NULL DROP TABLE dbo.load_PropertyMedianValue;
CREATE TABLE dbo.load_PropertyMedianValue (
    [State]               NVARCHAR(100),   -- messy: 'New South Wales' AND 'NEW SOUTH WALES_NSW'
    City_Town             NVARCHAR(100),
    Suburb                NVARCHAR(100),
    Postcode              NVARCHAR(50),
    District              NVARCHAR(100),   -- mostly empty in the file
    [Location]            NVARCHAR(100),   -- mostly empty too
    Property_Median_Value NVARCHAR(100),
    Updated_Year          NVARCHAR(50),
    Updated_Month         NVARCHAR(50)
);
GO

/* ------------------------------------------------------------
   3. load_AusLocation
   Raw copy of AUS_SubCityDistrictState_Data.xlsx
   (~16,000 rows covering all of Australia).
   Note: the source file literally has a column called "Distric"
   (missing the final t). I map it to "district" in SSIS.
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.load_AusLocation') IS NOT NULL DROP TABLE dbo.load_AusLocation;
CREATE TABLE dbo.load_AusLocation (
    postcode   NVARCHAR(100),
    suburb     NVARCHAR(100),
    city       NVARCHAR(100),
    [state]    NVARCHAR(100),   -- some rows have leading spaces
    state_code NVARCHAR(100),
    lat        NVARCHAR(100),
    lon        NVARCHAR(100),
    district   NVARCHAR(100)    -- source column is called 'Distric' (typo in the file)
);
GO

PRINT 'Staging tables created.';
