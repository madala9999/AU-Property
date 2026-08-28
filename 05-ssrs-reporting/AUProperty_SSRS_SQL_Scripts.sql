/* =====================================================================
   AU PROPERTY DATA WAREHOUSE - SSRS REPORTING SCRIPTS
   Task 7 - BI Advanced - SSRS Report (Part 3 of the sprint)
   ===================================================================== */


USE AUPropertyDW;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'rpt')
    EXEC('CREATE SCHEMA rpt');
GO


/* =====================================================================
   PART 1: THE THREE CASCADING PARAMETER LOOKUPS
   ===================================================================== */

CREATE OR ALTER PROCEDURE rpt.usp_Lookup_States
AS
BEGIN
    SET NOCOUNT ON;
    SELECT State FROM (
        SELECT '(All)' AS State
        UNION ALL
        SELECT DISTINCT State
        FROM star.DimSuburb
        WHERE SuburbKey <> -1        -- skip the "Unknown" member row
    ) x
    ORDER BY State;
END
GO

CREATE OR ALTER PROCEDURE rpt.usp_Lookup_Cities
    @State NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT City FROM (
        SELECT '(All)' AS City
        UNION ALL
        SELECT DISTINCT City
        FROM star.DimSuburb
        WHERE SuburbKey <> -1
          AND (@State IS NULL OR @State = '(All)' OR State = @State)
    ) x
    ORDER BY City;
END
GO

CREATE OR ALTER PROCEDURE rpt.usp_Lookup_Suburbs
    @State NVARCHAR(100) = NULL,
    @City  NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Suburb FROM (
        SELECT '(All)' AS Suburb
        UNION ALL
        SELECT DISTINCT Suburb
        FROM star.DimSuburb
        WHERE SuburbKey <> -1
          AND (@State IS NULL OR @State = '(All)' OR State = @State)
          AND (@City  IS NULL OR @City  = '(All)' OR City  = @City)
    ) x
    ORDER BY Suburb;
END
GO


/* =====================================================================
   PART 2: THE FIVE REPORT PROCEDURES
   ===================================================================== */

-- 2.1  House Value - one row per suburb

CREATE OR ALTER PROCEDURE rpt.usp_Rpt_HouseValue
    @State  NVARCHAR(100) = NULL,
    @City   NVARCHAR(100) = NULL,
    @Suburb NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        s.State, s.City, s.Suburb,
        f.Postcode, f.HouseValue
    FROM star.FactHouseValue f
    INNER JOIN star.DimSuburb s ON s.SuburbKey = f.SuburbKey
    WHERE s.SuburbKey <> -1
      AND (@State  IS NULL OR @State  = '(All)' OR s.State  = @State)
      AND (@City   IS NULL OR @City   = '(All)' OR s.City   = @City)
      AND (@Suburb IS NULL OR @Suburb = '(All)' OR s.Suburb = @Suburb)
    ORDER BY s.State, s.City, s.Suburb;
END
GO

-- 2.2  Rental Value - one row per suburb + rental house type

CREATE OR ALTER PROCEDURE rpt.usp_Rpt_RentalValue
    @State  NVARCHAR(100) = NULL,
    @City   NVARCHAR(100) = NULL,
    @Suburb NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        s.State, s.City, s.Suburb,
        rht.RentalHouseType, f.RentalAmount
    FROM star.FactRentalValue f
    INNER JOIN star.DimSuburb s ON s.SuburbKey = f.SuburbKey
    INNER JOIN star.DimRentalHouseType rht ON rht.RentalHouseTypeKey = f.RentalHouseTypeKey
    WHERE s.SuburbKey <> -1
      AND (@State  IS NULL OR @State  = '(All)' OR s.State  = @State)
      AND (@City   IS NULL OR @City   = '(All)' OR s.City   = @City)
      AND (@Suburb IS NULL OR @Suburb = '(All)' OR s.Suburb = @Suburb)
    ORDER BY s.State, s.City, s.Suburb, rht.RentalHouseType;
END
GO

-- 2.3  Local Transport Stations - one row per stop-in-a-suburb

CREATE OR ALTER PROCEDURE rpt.usp_Rpt_TransportStations
    @State  NVARCHAR(100) = NULL,
    @City   NVARCHAR(100) = NULL,
    @Suburb NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        s.State, s.City, s.Suburb,
        ts.StopName, ts.Mode, ts.StopLat, ts.StopLong
    FROM star.FactTransportAccess f
    INNER JOIN star.DimSuburb s ON s.SuburbKey = f.SuburbKey
    INNER JOIN star.DimTransportStop ts ON ts.StopKey = f.StopKey
    WHERE s.SuburbKey <> -1
      AND (@State  IS NULL OR @State  = '(All)' OR s.State  = @State)
      AND (@City   IS NULL OR @City   = '(All)' OR s.City   = @City)
      AND (@Suburb IS NULL OR @Suburb = '(All)' OR s.Suburb = @Suburb)
    ORDER BY s.State, s.City, s.Suburb, ts.Mode, ts.StopName;
END
GO

-- 2.4  Local Schools - one row per school-in-a-suburb

CREATE OR ALTER PROCEDURE rpt.usp_Rpt_LocalSchools
    @State  NVARCHAR(100) = NULL,
    @City   NVARCHAR(100) = NULL,
    @Suburb NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        s.State, s.City, s.Suburb,
        sch.SchoolName, sch.SchoolType, sch.Address, sch.Postcode
    FROM star.FactSchoolPresence f
    INNER JOIN star.DimSuburb s ON s.SuburbKey = f.SuburbKey
    INNER JOIN star.DimSchool sch ON sch.SchoolKey = f.SchoolKey
    WHERE s.SuburbKey <> -1
      AND (@State  IS NULL OR @State  = '(All)' OR s.State  = @State)
      AND (@City   IS NULL OR @City   = '(All)' OR s.City   = @City)
      AND (@Suburb IS NULL OR @Suburb = '(All)' OR s.Suburb = @Suburb)
    ORDER BY s.State, s.City, s.Suburb, sch.SchoolName;
END
GO

-- 2.5  Summarised Crime Recorded Incidents - grouped by offence category

CREATE OR ALTER PROCEDURE rpt.usp_Rpt_CrimeSummary
    @State  NVARCHAR(100) = NULL,
    @City   NVARCHAR(100) = NULL,
    @Suburb NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        s.State, s.City, s.Suburb,
        ot.OffenceCategory,
        SUM(f.RecordedIncidents) AS TotalRecordedIncidents
    FROM star.FactCrime f
    INNER JOIN star.DimSuburb s ON s.SuburbKey = f.SuburbKey
    INNER JOIN star.DimOffenceType ot ON ot.OffenceTypeKey = f.OffenceTypeKey
    WHERE s.SuburbKey <> -1
      AND (@State  IS NULL OR @State  = '(All)' OR s.State  = @State)
      AND (@City   IS NULL OR @City   = '(All)' OR s.City   = @City)
      AND (@Suburb IS NULL OR @Suburb = '(All)' OR s.Suburb = @Suburb)
    GROUP BY s.State, s.City, s.Suburb, ot.OffenceCategory
    ORDER BY s.State, s.City, s.Suburb, TotalRecordedIncidents DESC;
END
GO
