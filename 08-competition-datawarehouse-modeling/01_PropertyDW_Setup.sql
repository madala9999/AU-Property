/* =============================================================
   PROPERTY ANALYSIS DATA WAREHOUSE - COMPLETE SETUP SCRIPT
   Run this ONCE in SSMS before building your SSIS packages.
   Execute the whole file with F5, or run section by section.
   ============================================================= */

/* ---------- SECTION 1: CREATE THE DATABASE ---------- */
IF DB_ID('PropertyDW') IS NULL
    CREATE DATABASE PropertyDW;
GO

USE PropertyDW;
GO

/* ---------- SECTION 2: STAGING TABLES (load_ prefix) ----------
   Staging columns are deliberately forgiving (NVARCHAR) so that
   Package 1 never fails on dirty data. Cleansing happens in Package 2.
*/

IF OBJECT_ID('dbo.load_Schools') IS NOT NULL DROP TABLE dbo.load_Schools;
CREATE TABLE dbo.load_Schools (
    school_code              NVARCHAR(50),
    AgeID                    NVARCHAR(50),
    school_name              NVARCHAR(255),
    street                   NVARCHAR(255),
    town_suburb              NVARCHAR(100),
    postcode                 NVARCHAR(20),
    student_number           NVARCHAR(50),
    indigenous_pct           NVARCHAR(50),   -- contains 'np' placeholders
    lbote_pct                NVARCHAR(50),   -- contains 'np' placeholders
    ICSEA_Value              NVARCHAR(50),
    level_of_schooling       NVARCHAR(100),
    selective_school         NVARCHAR(100),
    opportunity_class        NVARCHAR(10),
    school_specialty_type    NVARCHAR(100),
    school_subtype           NVARCHAR(100),
    support_classes          NVARCHAR(100),
    preschool_ind            NVARCHAR(10),
    distance_education       NVARCHAR(50),
    intensive_english_centre NVARCHAR(10),
    school_gender            NVARCHAR(50),
    phone                    NVARCHAR(50),
    school_email             NVARCHAR(255),
    fax                      NVARCHAR(50),
    late_opening_school      NVARCHAR(10),
    date_1st_teacher         NVARCHAR(50),
    lga                      NVARCHAR(100),
    electorate               NVARCHAR(100),
    fed_electorate           NVARCHAR(100),
    operational_directorate  NVARCHAR(100),
    principal_network        NVARCHAR(100),
    facs_district            NVARCHAR(255),
    local_health_district    NVARCHAR(100),
    aecg_region              NVARCHAR(100),
    ASGS_remoteness          NVARCHAR(100),
    latitude                 NVARCHAR(50),
    longitude                NVARCHAR(50),
    date_extracted           NVARCHAR(50)
);
GO

IF OBJECT_ID('dbo.load_PropertyMedianValue') IS NOT NULL DROP TABLE dbo.load_PropertyMedianValue;
CREATE TABLE dbo.load_PropertyMedianValue (
    [State]                  NVARCHAR(100),  -- dirty: 'New South Wales' AND 'NEW SOUTH WALES_NSW'
    City_Town                NVARCHAR(100),
    Suburb                   NVARCHAR(100),
    Postcode                 NVARCHAR(20),
    District                 NVARCHAR(100),
    [Location]               NVARCHAR(100),
    Property_Median_Value    NVARCHAR(50),
    Updated_Year             NVARCHAR(10),
    Updated_Month            NVARCHAR(10)
);
GO

IF OBJECT_ID('dbo.load_AusLocation') IS NOT NULL DROP TABLE dbo.load_AusLocation;
CREATE TABLE dbo.load_AusLocation (
    postcode                 NVARCHAR(20),
    suburb                   NVARCHAR(100),
    city                     NVARCHAR(100),
    [state]                  NVARCHAR(100),  -- dirty: leading spaces e.g. ' Northern Territory'
    state_code               NVARCHAR(10),
    lat                      NVARCHAR(50),
    lon                      NVARCHAR(50),
    district                 NVARCHAR(100)   -- source column is misspelled 'Distric'
);
GO

/* ---------- SECTION 3: DIMENSION TABLES ---------- */

IF OBJECT_ID('dbo.FactPropertyValue')   IS NOT NULL DROP TABLE dbo.FactPropertyValue;
IF OBJECT_ID('dbo.FactSchoolLocation')  IS NOT NULL DROP TABLE dbo.FactSchoolLocation;
IF OBJECT_ID('dbo.DimLocation')         IS NOT NULL DROP TABLE dbo.DimLocation;
IF OBJECT_ID('dbo.DimDate')             IS NOT NULL DROP TABLE dbo.DimDate;
IF OBJECT_ID('dbo.DimCategory')         IS NOT NULL DROP TABLE dbo.DimCategory;
IF OBJECT_ID('dbo.DimSchool')           IS NOT NULL DROP TABLE dbo.DimSchool;
GO

CREATE TABLE dbo.DimLocation (
    LocationKey   INT IDENTITY(1,1) PRIMARY KEY,
    Suburb        NVARCHAR(100)  NOT NULL,
    Postcode      INT            NOT NULL,
    City          NVARCHAR(100),
    District      NVARCHAR(100),
    [State]       NVARCHAR(100),
    StateCode     NVARCHAR(10),
    Latitude      DECIMAL(9,6),
    Longitude     DECIMAL(9,6)
);
GO

CREATE TABLE dbo.DimDate (
    DateKey       INT PRIMARY KEY,        -- format YYYYMM e.g. 201706
    [Year]        INT NOT NULL,
    [Month]       INT NOT NULL,
    MonthName     NVARCHAR(20)
);
GO

CREATE TABLE dbo.DimCategory (
    CategoryKey   INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName  NVARCHAR(50) NOT NULL,
    MinValue      MONEY NOT NULL,
    MaxValue      MONEY NULL              -- NULL = no upper bound
);
GO

CREATE TABLE dbo.DimSchool (
    SchoolKey            INT IDENTITY(1,1) PRIMARY KEY,
    SchoolCode           INT NOT NULL,
    SchoolName           NVARCHAR(255),
    Suburb               NVARCHAR(100),
    Postcode             INT,
    LevelOfSchooling     NVARCHAR(100),
    SelectiveSchool      NVARCHAR(100),
    OpportunityClass     NVARCHAR(10),
    SchoolSpecialtyType  NVARCHAR(100),
    SchoolGender         NVARCHAR(50),
    StudentNumber        INT,
    ICSEA_Value          INT,
    Latitude             DECIMAL(9,6),
    Longitude            DECIMAL(9,6)
);
GO

/* ---------- SECTION 4: FACT TABLES ---------- */

CREATE TABLE dbo.FactPropertyValue (
    PropertyValueKey     INT IDENTITY(1,1) PRIMARY KEY,
    LocationKey          INT NOT NULL FOREIGN KEY REFERENCES dbo.DimLocation(LocationKey),
    DateKey              INT NOT NULL FOREIGN KEY REFERENCES dbo.DimDate(DateKey),
    CategoryKey          INT NOT NULL FOREIGN KEY REFERENCES dbo.DimCategory(CategoryKey),
    PropertyMedianValue  MONEY NOT NULL
);
GO

/* Factless fact table: records the EXISTENCE of a school at a location.
   No numeric measures - used for counting / coverage analysis, per Kimball. */
CREATE TABLE dbo.FactSchoolLocation (
    SchoolLocationKey    INT IDENTITY(1,1) PRIMARY KEY,
    SchoolKey            INT NOT NULL FOREIGN KEY REFERENCES dbo.DimSchool(SchoolKey),
    LocationKey          INT NOT NULL FOREIGN KEY REFERENCES dbo.DimLocation(LocationKey)
);
GO

/* ---------- SECTION 5: SEED DimCategory (the 4 buckets) ---------- */
INSERT INTO dbo.DimCategory (CategoryName, MinValue, MaxValue) VALUES
 ('$0-$750K',      0,        750000),
 ('$750K-$1.5M',   750000,   1500000),
 ('$1.5M-$2.5M',   1500000,  2500000),
 ('$2.5M+',        2500000,  NULL);
GO

/* ---------- SECTION 6: RESET SCRIPT (used by Package 2, Execute SQL Task) ----------
   Copy the block below into the Execute SQL Task in Package 2.
   Facts are deleted before dims because of foreign keys. */
/*
DELETE FROM dbo.FactPropertyValue;
DELETE FROM dbo.FactSchoolLocation;
DELETE FROM dbo.DimSchool;
DELETE FROM dbo.DimLocation;
DELETE FROM dbo.DimDate;
DBCC CHECKIDENT ('dbo.FactPropertyValue',  RESEED, 0);
DBCC CHECKIDENT ('dbo.FactSchoolLocation', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimSchool',          RESEED, 0);
DBCC CHECKIDENT ('dbo.DimLocation',        RESEED, 0);
*/

/* ---------- SECTION 7: STAGING TRUNCATE (used by Package 1, Execute SQL Task) ---------- */
/*
TRUNCATE TABLE dbo.load_Schools;
TRUNCATE TABLE dbo.load_PropertyMedianValue;
TRUNCATE TABLE dbo.load_AusLocation;
*/

PRINT 'PropertyDW setup complete.';
