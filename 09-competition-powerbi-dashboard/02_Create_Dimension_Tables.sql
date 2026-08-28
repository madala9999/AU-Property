/* ============================================================
   02 - Create the dimension tables
   Project: Property Analysis - Data Warehouse (PropertyDW)
   Author:  Srikanth

   My design in simple terms:
   I went with a STAR SCHEMA - one middle (fact) table with the
   numbers, and small "dimension" tables around it that describe
   things (where, when, what price group, which school).
   I picked star over snowflake because it is easier to write
   queries against and it is what Power BI likes best.

   Each dimension gets its own IDENTITY key (a number SQL Server
   makes up automatically). This is called a surrogate key. I use
   it instead of the natural values (like suburb name) because
   names are messy - they had trailing spaces and duplicates.
   ============================================================ */

USE PropertyDW;
GO

/* ------------------------------------------------------------
   1. DimLocation - WHERE the property/school is.
   One row per suburb + postcode combo, loaded from the AUS
   location file. This is my "conformed dimension" - both fact
   tables share it, so I can join schools and property values
   through the same location.
   Important lesson I learnt: suburb name alone is NOT unique -
   Abbotsford exists in NSW, VIC and QLD. So the real business
   key is suburb + postcode together.
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.DimLocation') IS NOT NULL DROP TABLE dbo.DimLocation;
CREATE TABLE dbo.DimLocation (
    LocationKey INT IDENTITY(1,1) NOT NULL,
    Suburb      NVARCHAR(100) NOT NULL,
    Postcode    INT           NOT NULL,
    City        NVARCHAR(100) NULL,
    District    NVARCHAR(100) NULL,
    [State]     NVARCHAR(100) NULL,
    StateCode   NVARCHAR(10)  NULL,
    Latitude    DECIMAL(9,6)  NULL,
    Longitude   DECIMAL(9,6)  NULL,
    CONSTRAINT PK_DimLocation PRIMARY KEY (LocationKey)
);
GO

/* ------------------------------------------------------------
   2. DimDate - WHEN the property value was recorded.
   I only have year + month in the data (no exact days), so my
   date key is simply YYYYMM as a number, e.g. June 2017 = 201706.
   I build the key myself instead of IDENTITY so the same
   year+month always gives the same key.
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.DimDate') IS NOT NULL DROP TABLE dbo.DimDate;
CREATE TABLE dbo.DimDate (
    DateKey   INT          NOT NULL,   -- YYYYMM, e.g. 201706
    [Year]    INT          NOT NULL,
    [Month]   INT          NOT NULL,
    MonthName NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_DimDate PRIMARY KEY (DateKey)
);
GO

/* ------------------------------------------------------------
   3. DimCategory - the price buckets.
   The task asked for a transformation that categorises median
   property values. I created 4 buckets and this little table
   holds them. The actual bucketing happens in SSIS with a
   Derived Column, then a Lookup finds the right key here.
   I seed (pre-fill) the 4 rows right away because they never
   change.
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.DimCategory') IS NOT NULL DROP TABLE dbo.DimCategory;
CREATE TABLE dbo.DimCategory (
    CategoryKey  INT IDENTITY(1,1) NOT NULL,
    CategoryName NVARCHAR(50)      NOT NULL,
    CONSTRAINT PK_DimCategory PRIMARY KEY (CategoryKey)
);
GO

INSERT INTO dbo.DimCategory (CategoryName)
VALUES ('$0-$750K'), ('$750K-$1.5M'), ('$1.5M-$2.5M'), ('$2.5M+');
GO

/* ------------------------------------------------------------
   4. DimSchool - WHICH school.
   One row per school from the NSW schools CSV.
   The source had 'np' (not published) inside number columns
   like student_number and ICSEA_Value, so those columns allow
   NULL and the SSIS load turns 'np' into NULL with
   NULLIF(col,'np').
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.DimSchool') IS NOT NULL DROP TABLE dbo.DimSchool;
CREATE TABLE dbo.DimSchool (
    SchoolKey           INT IDENTITY(1,1) NOT NULL,
    SchoolCode          INT           NULL,
    SchoolName          NVARCHAR(255) NOT NULL,
    Suburb              NVARCHAR(100) NULL,
    Postcode            INT           NULL,
    LevelOfSchooling    NVARCHAR(50)  NULL,
    SelectiveSchool     NVARCHAR(50)  NULL,
    OpportunityClass    NVARCHAR(50)  NULL,
    SchoolSpecialtyType NVARCHAR(50)  NULL,
    SchoolGender        NVARCHAR(50)  NULL,
    StudentNumber       INT           NULL,   -- 'np' in source becomes NULL
    ICSEA_Value         INT           NULL,   -- 'np' in source becomes NULL
    Latitude            DECIMAL(9,6)  NULL,
    Longitude           DECIMAL(9,6)  NULL,
    CONSTRAINT PK_DimSchool PRIMARY KEY (SchoolKey)
);
GO

PRINT 'Dimension tables created and DimCategory seeded with the 4 price buckets.';
