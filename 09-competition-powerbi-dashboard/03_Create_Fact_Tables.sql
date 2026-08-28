/* ============================================================
   03 - Create the fact tables
   Project: Property Analysis - Data Warehouse (PropertyDW)
   Author:  Srikanth

   Two fact tables:

   1) FactPropertyValue - the "normal" fact. It holds the actual
      number I care about (the median property value) plus keys
      pointing at the dimensions.
      GRAIN (the level of detail of one row): one row per suburb
      per month. I wrote the grain down first before building
      anything, because everything else depends on it.

   2) FactSchoolLocation - a FACTLESS fact table. It has no
      numbers at all! Each row just says "this school exists in
      this location". It sounds useless but it lets me answer
      questions like "how many selective schools are in $2.5M+
      suburbs" by joining through the shared DimLocation.
      I had to research what a factless fact table is for this
      task - it is basically a bridge that records an event or
      relationship instead of a measurement.
   ============================================================ */

USE PropertyDW;
GO

/* ------------------------------------------------------------
   1. FactPropertyValue
   Grain: one row per suburb per month.
   PropertyValueKey is just a row id (IDENTITY).
   The three other keys point to my dimensions.
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.FactPropertyValue') IS NOT NULL DROP TABLE dbo.FactPropertyValue;
CREATE TABLE dbo.FactPropertyValue (
    PropertyValueKey    INT IDENTITY(1,1) NOT NULL,
    LocationKey         INT   NOT NULL,   -- which suburb/postcode (DimLocation)
    DateKey             INT   NOT NULL,   -- which year+month (DimDate)
    CategoryKey         INT   NOT NULL,   -- which price bucket (DimCategory)
    PropertyMedianValue MONEY NOT NULL,   -- the actual measure
    CONSTRAINT PK_FactPropertyValue PRIMARY KEY (PropertyValueKey),
    CONSTRAINT FK_FactPV_Location FOREIGN KEY (LocationKey) REFERENCES dbo.DimLocation (LocationKey),
    CONSTRAINT FK_FactPV_Date     FOREIGN KEY (DateKey)     REFERENCES dbo.DimDate     (DateKey),
    CONSTRAINT FK_FactPV_Category FOREIGN KEY (CategoryKey) REFERENCES dbo.DimCategory (CategoryKey)
);
GO

/* ------------------------------------------------------------
   2. FactSchoolLocation (factless fact table)
   Grain: one row per school per location.
   No measure columns on purpose - the row existing IS the fact.
   The primary key is both columns together, so the same school
   can't be linked to the same location twice.
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.FactSchoolLocation') IS NOT NULL DROP TABLE dbo.FactSchoolLocation;
CREATE TABLE dbo.FactSchoolLocation (
    SchoolKey   INT NOT NULL,   -- which school (DimSchool)
    LocationKey INT NOT NULL,   -- which suburb/postcode (DimLocation)
    CONSTRAINT PK_FactSchoolLocation PRIMARY KEY (SchoolKey, LocationKey),
    CONSTRAINT FK_FactSL_School   FOREIGN KEY (SchoolKey)   REFERENCES dbo.DimSchool   (SchoolKey),
    CONSTRAINT FK_FactSL_Location FOREIGN KEY (LocationKey) REFERENCES dbo.DimLocation (LocationKey)
);
GO

/* ------------------------------------------------------------
   Reset block - used by Package 2 before each full reload,
   so I don't get duplicate rows when I re-run the ETL.
   Delete facts first, then dims (children before parents),
   then reset the IDENTITY counters back to the start.
   ------------------------------------------------------------ */
/*
DELETE FROM dbo.FactSchoolLocation;
DELETE FROM dbo.FactPropertyValue;
DELETE FROM dbo.DimSchool;
DELETE FROM dbo.DimDate;
DELETE FROM dbo.DimLocation;
DBCC CHECKIDENT ('dbo.FactPropertyValue', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimSchool',  RESEED, 0);
DBCC CHECKIDENT ('dbo.DimLocation', RESEED, 0);
*/

PRINT 'Fact tables created (FactPropertyValue + factless FactSchoolLocation).';
