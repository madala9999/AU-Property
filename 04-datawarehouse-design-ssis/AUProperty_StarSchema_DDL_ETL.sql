/* ============================================================================
   AU PROPERTY DATA WAREHOUSE — PART 2
   Star Schema DDL + Dimension/Fact Load Scripts
   Database: AUPropertyDW   |  Source layer: dw.*  (built in Part 1 / Task 5)
   New presentation layer:  star.*  (Kimball dimensional model)
   ============================================================================
   Layer flow reminder:
     stg.*   -> raw 1:1 landing tables per source Excel file (Part 1)
     dw.*    -> cleaned / consolidated, one table per data domain (Part 1)
     star.*  -> Kimball star schema: Dim* and Fact* tables (Part 2, this file)
   ============================================================================ */

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
   ----------------------------------------------------------------------------
   Part 1's validation step found a handful of orphan suburbs in the fact-level
   data (e.g. HMAS Creswell, Jervis Bay) that do not exist in the AUS Suburb
   master file. If a fact row's Suburb+StateCode can't be found in DimSuburb
   during the Lookup step in SSIS, we redirect it here instead of failing the
   package or silently dropping the row. This is the standard Kimball
   "Unknown member" pattern.
   ============================================================================ */
SET IDENTITY_INSERT star.DimSuburb ON;
INSERT INTO star.DimSuburb (SuburbKey, Suburb, City, State, StateCode, Latitude, Longitude)
VALUES (-1, 'UNKNOWN', 'Unknown', 'Unknown', 'N/A', NULL, NULL);
SET IDENTITY_INSERT star.DimSuburb OFF;
GO

/* ============================================================================
   SECTION 5 — DIMENSION LOAD SCRIPTS
   ----------------------------------------------------------------------------
   These are written to be pasted straight into SSIS "Execute SQL Task" boxes
   (see the step-by-step guide, Steps 4-5). They TRUNCATE + reload every run,
   which is safe because dimensions here have no history to preserve
   (Type 0 / Type 1 style — always reflects the latest dw.* snapshot).
   Run order matters: dimensions must be loaded BEFORE facts.
   ============================================================================ */

-- 5.1 Clear all star schema tables (facts first — FK order)
--     Use this as the "0 - Truncate Star Schema Tables" Execute SQL Task.
--     NOTE: the 5 Dim* tables are referenced by FOREIGN KEY constraints from
--     the Fact* tables, and SQL Server refuses TRUNCATE TABLE on ANY table
--     that has an incoming FK constraint -- even if the referencing table is
--     already empty. So: TRUNCATE the facts (nothing references them), then
--     DELETE the dimensions (allowed once the facts are empty), then manually
--     reseed each dimension's IDENTITY counter back to 0 so surrogate keys
--     still restart cleanly at 1 on every run, same as TRUNCATE would have done.
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
--      ROW_NUMBER guards against any repeat Suburb+StateCode combination.
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
--      LTRIM/RTRIM matters here: OffenceCategory/OffenceSubcategory were never
--      trimmed back in Part 1 (only Suburb was). SQL Server's DISTINCT treats
--      trailing-space variants as equal and silently keeps just one physical
--      representation, but the SSIS Lookup transformation does an exact
--      byte-for-byte comparison and does NOT ignore trailing spaces -- so an
--      untrimmed dimension can look "complete" in SQL (e.g. an EXCEPT check
--      against dw.Crime returns 0 rows) while still failing to match at
--      runtime in the Lookup. Trimming both sides (here, and in the
--      SRC - dw_Crime source query in SSIS) avoids this class of bug.
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

/* ============================================================================
   SECTION 6 — FACT LOAD SCRIPTS (SQL reference version)
   ----------------------------------------------------------------------------
   In the SSIS package these are built as Data Flow Tasks: OLE DB Source (dw.*)
   -> Lookup transformation(s) against the Dim tables -> OLE DB Destination
   (star.Fact*). The equivalent pure-SQL version below is given as a reference/
   fallback (e.g. if you want to sanity-check expected row counts and results
   in SSMS before wiring up the SSIS Lookups), and is what the Lookup +
   no-match-redirect logic is functionally equivalent to.
   Unmatched suburbs fall back to SuburbKey = -1 (Unknown) via LEFT JOIN + ISNULL.
   ============================================================================ */

-- 6.1  FactHouseValue
INSERT INTO star.FactHouseValue (SuburbKey, Postcode, HouseValue)
SELECT ISNULL(s.SuburbKey, -1), h.Postcode, h.HouseValue
FROM dw.HouseValue h
LEFT JOIN star.DimSuburb s ON h.Suburb = s.Suburb AND h.StateCode = s.StateCode;
GO

-- 6.2  FactRentalValue
INSERT INTO star.FactRentalValue (SuburbKey, RentalHouseTypeKey, RentalAmount)
SELECT ISNULL(s.SuburbKey, -1), rt.RentalHouseTypeKey, r.RentalAmount
FROM dw.RentalValue r
LEFT JOIN star.DimSuburb s ON r.Suburb = s.Suburb AND r.StateCode = s.StateCode
JOIN star.DimRentalHouseType rt ON r.RentalHouseType = rt.RentalHouseType;
GO

-- 6.3  FactCrime
INSERT INTO star.FactCrime (SuburbKey, OffenceTypeKey, Postcode, RecordedIncidents)
SELECT ISNULL(s.SuburbKey, -1), o.OffenceTypeKey, c.Postcode, c.RecordedIncidents
FROM dw.Crime c
LEFT JOIN star.DimSuburb s ON c.Suburb = s.Suburb AND c.StateCode = s.StateCode
JOIN star.DimOffenceType o ON c.OffenceCategory = o.OffenceCategory AND c.OffenceSubcategory = o.OffenceSubcategory;
GO

-- 6.4  FactSchoolPresence (factless)
INSERT INTO star.FactSchoolPresence (SuburbKey, SchoolKey)
SELECT ISNULL(s.SuburbKey, -1), sc.SchoolKey
FROM dw.School d
LEFT JOIN star.DimSuburb s ON d.Suburb = s.Suburb AND d.StateCode = s.StateCode
JOIN star.DimSchool sc ON d.SchoolCode = sc.SchoolCode AND d.StateCode = sc.StateCode;
GO

-- 6.5  FactTransportAccess (factless)
INSERT INTO star.FactTransportAccess (SuburbKey, StopKey)
SELECT ISNULL(s.SuburbKey, -1), t.StopKey
FROM dw.Transport dt
LEFT JOIN star.DimSuburb s ON dt.Suburb = s.Suburb AND dt.StateCode = s.StateCode
JOIN star.DimTransportStop t
     ON dt.StopName = t.StopName AND dt.Mode = t.Mode AND dt.StateCode = t.StateCode
     AND ((dt.StopLat = t.StopLat) OR (dt.StopLat IS NULL AND t.StopLat IS NULL))
     AND ((dt.StopLong = t.StopLong) OR (dt.StopLong IS NULL AND t.StopLong IS NULL));
GO

/* ============================================================================
   SECTION 7 — VALIDATION QUERIES (run after the SSIS package finishes)
   ============================================================================ */

-- 7.1  Row counts — every star.Fact* row count should equal (or be very close
--      to) its dw.* source row count. Small drops are expected only where the
--      transport-stop dedup (Section 5.6) removed exact duplicate rows.
SELECT 'star.DimSuburb'          AS TableName, COUNT(*) AS Rows FROM star.DimSuburb
UNION ALL SELECT 'star.DimOffenceType',        COUNT(*) FROM star.DimOffenceType
UNION ALL SELECT 'star.DimRentalHouseType',    COUNT(*) FROM star.DimRentalHouseType
UNION ALL SELECT 'star.DimSchool',             COUNT(*) FROM star.DimSchool
UNION ALL SELECT 'star.DimTransportStop',      COUNT(*) FROM star.DimTransportStop
UNION ALL SELECT 'star.FactHouseValue',        COUNT(*) FROM star.FactHouseValue
UNION ALL SELECT 'star.FactRentalValue',       COUNT(*) FROM star.FactRentalValue
UNION ALL SELECT 'star.FactCrime',             COUNT(*) FROM star.FactCrime
UNION ALL SELECT 'star.FactSchoolPresence',    COUNT(*) FROM star.FactSchoolPresence
UNION ALL SELECT 'star.FactTransportAccess',   COUNT(*) FROM star.FactTransportAccess;

-- 7.2  How many fact rows fell back to the Unknown suburb member (-1)?
--      This should roughly match the "orphan suburb" counts you already found
--      during Part 1 validation.
SELECT 'FactHouseValue'       AS FactTable, COUNT(*) AS UnknownSuburbRows FROM star.FactHouseValue      WHERE SuburbKey = -1
UNION ALL SELECT 'FactRentalValue',      COUNT(*) FROM star.FactRentalValue     WHERE SuburbKey = -1
UNION ALL SELECT 'FactCrime',            COUNT(*) FROM star.FactCrime           WHERE SuburbKey = -1
UNION ALL SELECT 'FactSchoolPresence',   COUNT(*) FROM star.FactSchoolPresence  WHERE SuburbKey = -1
UNION ALL SELECT 'FactTransportAccess',  COUNT(*) FROM star.FactTransportAccess WHERE SuburbKey = -1;

-- 7.3  Sample BI-style query the star schema now makes trivial:
--      average house value AND crime incident count by state, in one join.
SELECT s.State,
       AVG(hv.HouseValue)                       AS AvgHouseValue,
       SUM(cr.RecordedIncidents)                AS TotalRecordedIncidents,
       COUNT(DISTINCT sp.SchoolKey)             AS SchoolCount,
       COUNT(DISTINCT ta.StopKey)               AS TransportStopCount
FROM star.DimSuburb s
LEFT JOIN star.FactHouseValue hv       ON hv.SuburbKey = s.SuburbKey
LEFT JOIN star.FactCrime cr            ON cr.SuburbKey = s.SuburbKey
LEFT JOIN star.FactSchoolPresence sp   ON sp.SuburbKey = s.SuburbKey
LEFT JOIN star.FactTransportAccess ta  ON ta.SuburbKey = s.SuburbKey
WHERE s.SuburbKey <> -1
GROUP BY s.State
ORDER BY s.State;
GO
