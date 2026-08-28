/* ============================================================================
   AU PROPERTY DATA WAREHOUSE — PART 2
   Star Schema DDL + Dimension/Fact Load Scripts
   Database: AUPropertyDW   |  Source layer: dw.* 
   New presentation layer:  star.*  (Kimball dimensional model)
   ============================================================================

USE AUPropertyDW;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'star')
    EXEC('CREATE SCHEMA star');
GO

/* ============================================================================
   SECTION 1 — DROP (safe re-run) — facts first, then dimensions (FK order)
   ============================================================================ */
IF OBJECT_ID('star.FactHouseValue','U')       IS NOT NULL DROP TABLE star.FactHouseValue;
IF OBJECT_ID('star.FactRentalValue','U')      IS NOT NULL DROP TABLE star.FactRentalValue;
IF OBJECT_ID('star.FactCrime','U')            IS NOT NULL DROP TABLE star.FactCrime;
IF OBJECT_ID('star.FactSchoolPresence','U')   IS NOT NULL DROP TABLE star.FactSchoolPresence;
IF OBJECT_ID('star.FactTransportAccess','U')  IS NOT NULL DROP TABLE star.FactTransportAccess;
IF OBJECT_ID('star.DimSuburb','U')            IS NOT NULL DROP TABLE star.DimSuburb;
IF OBJECT_ID('star.DimOffenceType','U')       IS NOT NULL DROP TABLE star.DimOffenceType;
IF OBJECT_ID('star.DimRentalHouseType','U')   IS NOT NULL DROP TABLE star.DimRentalHouseType;
IF OBJECT_ID('star.DimSchool','U')            IS NOT NULL DROP TABLE star.DimSchool;
IF OBJECT_ID('star.DimTransportStop','U')     IS NOT NULL DROP TABLE star.DimTransportStop;
GO

/* ============================================================================
   SECTION 2 — DIMENSION TABLES
   ============================================================================ */

-- 2.1  DimSuburb — the conformed hub dimension. Every fact table joins to this.
CREATE TABLE star.DimSuburb (
    SuburbKey     INT IDENTITY(1,1) NOT NULL,
    Suburb        NVARCHAR(100)     NOT NULL,
    City          NVARCHAR(100)     NULL,
    State         NVARCHAR(100)     NULL,
    StateCode     NVARCHAR(10)      NOT NULL,
    Latitude      DECIMAL(9,6)      NULL,
    Longitude     DECIMAL(9,6)      NULL,
    CONSTRAINT PK_DimSuburb PRIMARY KEY (SuburbKey),
    CONSTRAINT UQ_DimSuburb_NaturalKey UNIQUE (Suburb, StateCode)
);
GO

-- 2.2  DimOffenceType — used by FactCrime

CREATE TABLE star.DimOffenceType (
    OffenceTypeKey      INT IDENTITY(1,1) NOT NULL,
    OffenceCategory     NVARCHAR(200)     NOT NULL,
    OffenceSubcategory  NVARCHAR(200)     NOT NULL,
    CONSTRAINT PK_DimOffenceType PRIMARY KEY (OffenceTypeKey),
    CONSTRAINT UQ_DimOffenceType_NaturalKey UNIQUE (OffenceCategory, OffenceSubcategory)
);
GO

-- 2.3  DimRentalHouseType — used by FactRentalValue

CREATE TABLE star.DimRentalHouseType (
    RentalHouseTypeKey  INT IDENTITY(1,1) NOT NULL,
    RentalHouseType     NVARCHAR(100)     NOT NULL,
    CONSTRAINT PK_DimRentalHouseType PRIMARY KEY (RentalHouseTypeKey),
    CONSTRAINT UQ_DimRentalHouseType_NaturalKey UNIQUE (RentalHouseType)
);
GO

-- 2.4  DimSchool — used by FactSchoolPresence (factless)

CREATE TABLE star.DimSchool (
    SchoolKey     INT IDENTITY(1,1) NOT NULL,
    SchoolCode    NVARCHAR(50)      NOT NULL,
    StateCode     NVARCHAR(10)      NOT NULL,
    SchoolName    NVARCHAR(200)     NULL,
    SchoolType    NVARCHAR(100)     NULL,
    Address       NVARCHAR(300)     NULL,
    Postcode      NVARCHAR(10)      NULL,
    CONSTRAINT PK_DimSchool PRIMARY KEY (SchoolKey),
    CONSTRAINT UQ_DimSchool_NaturalKey UNIQUE (SchoolCode, StateCode)
);
GO

-- 2.5  DimTransportStop — used by FactTransportAccess (factless)

CREATE TABLE star.DimTransportStop (
    StopKey       INT IDENTITY(1,1) NOT NULL,
    StopName      NVARCHAR(200)     NOT NULL,
    Mode          NVARCHAR(50)      NOT NULL,
    StateCode     NVARCHAR(10)      NOT NULL,
    StopLat       DECIMAL(9,6)      NULL,
    StopLong      DECIMAL(9,6)      NULL,
    CONSTRAINT PK_DimTransportStop PRIMARY KEY (StopKey),
    CONSTRAINT UQ_DimTransportStop_NaturalKey UNIQUE (StopName, Mode, StateCode, StopLat, StopLong)
);
GO

/* ============================================================================
   SECTION 3 — FACT TABLES
   ============================================================================ */

-- 3.1  FactHouseValue  — grain: one row per Suburb (median house value snapshot)

CREATE TABLE star.FactHouseValue (
    HouseValueKey BIGINT IDENTITY(1,1) NOT NULL,
    SuburbKey     INT            NOT NULL,
    Postcode      NVARCHAR(10)   NULL,
    HouseValue    DECIMAL(12,2)  NOT NULL,
    LoadDateTime  DATETIME2(7)   NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_FactHouseValue PRIMARY KEY (HouseValueKey),
    CONSTRAINT FK_FactHouseValue_Suburb FOREIGN KEY (SuburbKey) REFERENCES star.DimSuburb(SuburbKey)
);
GO

-- 3.2  FactRentalValue — grain: one row per Suburb + RentalHouseType

CREATE TABLE star.FactRentalValue (
    RentalValueKey      BIGINT IDENTITY(1,1) NOT NULL,
    SuburbKey            INT           NOT NULL,
    RentalHouseTypeKey   INT           NOT NULL,
    RentalAmount         DECIMAL(10,2) NOT NULL,
    LoadDateTime          DATETIME2(7)  NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_FactRentalValue PRIMARY KEY (RentalValueKey),
    CONSTRAINT FK_FactRentalValue_Suburb FOREIGN KEY (SuburbKey) REFERENCES star.DimSuburb(SuburbKey),
    CONSTRAINT FK_FactRentalValue_RentalHouseType FOREIGN KEY (RentalHouseTypeKey) REFERENCES star.DimRentalHouseType(RentalHouseTypeKey)
);
GO

-- 3.3  FactCrime — grain: one row per Suburb + Postcode + OffenceCategory + OffenceSubcategory

CREATE TABLE star.FactCrime (
    CrimeKey            BIGINT IDENTITY(1,1) NOT NULL,
    SuburbKey           INT           NOT NULL,
    OffenceTypeKey      INT           NOT NULL,
    Postcode            NVARCHAR(10)  NULL,
    RecordedIncidents   INT           NOT NULL,
    LoadDateTime         DATETIME2(7)  NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_FactCrime PRIMARY KEY (CrimeKey),
    CONSTRAINT FK_FactCrime_Suburb FOREIGN KEY (SuburbKey) REFERENCES star.DimSuburb(SuburbKey),
    CONSTRAINT FK_FactCrime_OffenceType FOREIGN KEY (OffenceTypeKey) REFERENCES star.DimOffenceType(OffenceTypeKey)
);
GO

-- 3.4  FactSchoolPresence — FACTLESS fact table.

--      Grain: one row per (school exists in suburb) event. No numeric measure —
--      the fact of the relationship existing IS the fact. Query with COUNT(*).
CREATE TABLE star.FactSchoolPresence (
    SchoolPresenceKey  BIGINT IDENTITY(1,1) NOT NULL,
    SuburbKey          INT          NOT NULL,
    SchoolKey          INT          NOT NULL,
    LoadDateTime        DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_FactSchoolPresence PRIMARY KEY (SchoolPresenceKey),
    CONSTRAINT FK_FactSchoolPresence_Suburb FOREIGN KEY (SuburbKey) REFERENCES star.DimSuburb(SuburbKey),
    CONSTRAINT FK_FactSchoolPresence_School FOREIGN KEY (SchoolKey) REFERENCES star.DimSchool(SchoolKey)
);
GO

-- 3.5  FactTransportAccess — FACTLESS fact table.
--      Grain: one row per (transport stop exists in suburb) event.
CREATE TABLE star.FactTransportAccess (
    TransportAccessKey BIGINT IDENTITY(1,1) NOT NULL,
    SuburbKey           INT          NOT NULL,
    StopKey              INT          NOT NULL,
    LoadDateTime          DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_FactTransportAccess PRIMARY KEY (TransportAccessKey),
    CONSTRAINT FK_FactTransportAccess_Suburb FOREIGN KEY (SuburbKey) REFERENCES star.DimSuburb(SuburbKey),
    CONSTRAINT FK_FactTransportAccess_Stop FOREIGN KEY (StopKey) REFERENCES star.DimTransportStop(StopKey)
);
GO

/* ============================================================================
   SECTION 4 — SEED THE "UNKNOWN" MEMBER ROW (SuburbKey = -1)
   ============================================================================ */
SET IDENTITY_INSERT star.DimSuburb ON;
INSERT INTO star.DimSuburb (SuburbKey, Suburb, City, State, StateCode, Latitude, Longitude)
VALUES (-1, 'UNKNOWN', 'Unknown', 'Unknown', 'N/A', NULL, NULL);
SET IDENTITY_INSERT star.DimSuburb OFF;
GO

/* ============================================================================
   SECTION 5 — DIMENSION LOAD SCRIPTS
   ============================================================================ */

-- 5.1 Clear all star schema tables 

TRUNCATE TABLE star.FactHouseValue;
TRUNCATE TABLE star.FactRentalValue;
TRUNCATE TABLE star.FactCrime;
TRUNCATE TABLE star.FactSchoolPresence;
TRUNCATE TABLE star.FactTransportAccess;

DELETE FROM star.DimSuburb;
DBCC CHECKIDENT ('star.DimSuburb', RESEED, 0);

DELETE FROM star.DimOffenceType;
DBCC CHECKIDENT ('star.DimOffenceType', RESEED, 0);

DELETE FROM star.DimRentalHouseType;
DBCC CHECKIDENT ('star.DimRentalHouseType', RESEED, 0);

DELETE FROM star.DimSchool;
DBCC CHECKIDENT ('star.DimSchool', RESEED, 0);

DELETE FROM star.DimTransportStop;
DBCC CHECKIDENT ('star.DimTransportStop', RESEED, 0);

-- Re-seed the Unknown member immediately after clearing DimSuburb

SET IDENTITY_INSERT star.DimSuburb ON;
INSERT INTO star.DimSuburb (SuburbKey, Suburb, City, State, StateCode, Latitude, Longitude)
VALUES (-1, 'UNKNOWN', 'Unknown', 'Unknown', 'N/A', NULL, NULL);
SET IDENTITY_INSERT star.DimSuburb OFF;
GO

-- 5.2  Load DimSuburb from dw.Suburb (already cleaned/deduped in Part 1)

INSERT INTO star.DimSuburb (Suburb, City, State, StateCode, Latitude, Longitude)
SELECT Suburb, City, State, StateCode, Latitude, Longitude
FROM (
    SELECT Suburb, City, State, StateCode, Latitude, Longitude,
           ROW_NUMBER() OVER (PARTITION BY Suburb, StateCode ORDER BY Suburb) AS rn
    FROM dw.Suburb
) d
WHERE rn = 1;
GO

-- 5.3  Load DimOffenceType from dw.Crime

INSERT INTO star.DimOffenceType (OffenceCategory, OffenceSubcategory)
SELECT DISTINCT LTRIM(RTRIM(OffenceCategory)), LTRIM(RTRIM(OffenceSubcategory))
FROM dw.Crime;
GO

-- 5.4  Load DimRentalHouseType from dw.RentalValue

INSERT INTO star.DimRentalHouseType (RentalHouseType)
SELECT DISTINCT RentalHouseType
FROM dw.RentalValue;
GO

-- 5.5  Load DimSchool from dw.School

INSERT INTO star.DimSchool (SchoolCode, StateCode, SchoolName, SchoolType, Address, Postcode)
SELECT SchoolCode, StateCode, SchoolName, SchoolType, Address, Postcode
FROM (
    SELECT SchoolCode, StateCode, SchoolName, SchoolType, Address, Postcode,
           ROW_NUMBER() OVER (PARTITION BY SchoolCode, StateCode ORDER BY SchoolCode) AS rn
    FROM dw.School
) d
WHERE rn = 1;
GO

-- 5.6  Load DimTransportStop from dw.Transport

INSERT INTO star.DimTransportStop (StopName, Mode, StateCode, StopLat, StopLong)
SELECT StopName, Mode, StateCode, StopLat, StopLong
FROM (
    SELECT StopName, Mode, StateCode, StopLat, StopLong,
           ROW_NUMBER() OVER (PARTITION BY StopName, Mode, StateCode, StopLat, StopLong ORDER BY StopName) AS rn
    FROM dw.Transport
) d
WHERE rn = 1;
GO

/