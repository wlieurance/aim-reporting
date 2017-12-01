-- Text encoding used: System
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;
/* This script serves as an intermediary processor. Database was running out of memory on large datasets. 
This script converts some view results to indexed tables in order to solve the problem at the cost of disk space. */

--Delete/Insert: LPI_CanopyLayers_Point_DB_UNION was old view name.
DELETE FROM lpi_detail;

INSERT OR IGNORE INTO lpi_detail
SELECT b.RecKey, PointNbr,
	   CASE WHEN TopCanopy IN ('None', '') THEN NULL 
            ELSE TopCanopy END AS Species,
       ChkBoxTop AS ChkBox,
       CASE WHEN (HeightTop GLOB '*[A-z]*' OR HeightTop = '') THEN NULL 
            ELSE (HeightTop * ConvertFactor) END AS Height, 
       'Top' AS Category, 0 AS Layer
  FROM tblLPIHeader AS b
 INNER JOIN tblLPIDetail AS c ON b.RecKey = c.RecKey
 INNER JOIN UnitConversion_Use AS d ON b.HeightUOM = d.Units
 WHERE Coalesce(Species, Height) IS NOT NULL

 UNION ALL
SELECT b.RecKey, PointNbr,
       CASE WHEN Lower1 IN ('None', '') THEN NULL 
            ELSE Lower1 END AS Species,
       ChkBoxLower1 AS ChkBox,
       CASE WHEN (HeightLower1 GLOB '*[A-z]*' OR HeightLower1 = '') THEN NULL 
            ELSE (HeightLower1 * ConvertFactor) END AS Height,
       'Lower' AS Category, 1 AS Layer
  FROM tblLPIHeader AS b
 INNER JOIN tblLPIDetail AS c ON b.RecKey = c.RecKey
 INNER JOIN UnitConversion_Use AS d ON b.HeightUOM = d.Units
 WHERE Coalesce(Species, Height) IS NOT NULL

 UNION ALL
SELECT b.RecKey, PointNbr,
       CASE WHEN Lower2 IN ('None', '') THEN NULL 
            ELSE Lower2 END AS Species,
       ChkBoxLower2 AS ChkBox,
       CASE WHEN (HeightLower2 GLOB '*[A-z]*' OR HeightLower2 = '') THEN NULL 
            ELSE (HeightLower2 * ConvertFactor) END AS Height,
       'Lower' AS Category, 2 AS Layer
  FROM tblLPIHeader AS b
 INNER JOIN tblLPIDetail AS c ON b.RecKey = c.RecKey
 INNER JOIN UnitConversion_Use AS d ON b.HeightUOM = d.Units
 WHERE Coalesce(Species, Height) IS NOT NULL

 UNION ALL
SELECT b.RecKey, PointNbr,
       CASE WHEN Lower3 IN ('None', '') THEN NULL 
            ELSE Lower3 END AS Species,
       ChkBoxLower3 AS ChkBox,
	   CASE WHEN (HeightLower3 GLOB '*[A-z]*' OR HeightLower3 = '') THEN NULL 
            ELSE (HeightLower3 * ConvertFactor) END AS Height,
       'Lower' AS Category, 3 AS Layer
  FROM tblLPIHeader AS b
 INNER JOIN tblLPIDetail AS c ON b.RecKey = c.RecKey
 INNER JOIN UnitConversion_Use AS d ON b.HeightUOM = d.Units
 WHERE Coalesce(Species, Height) IS NOT NULL

 UNION ALL
SELECT b.RecKey, PointNbr,
       CASE WHEN Lower4 IN ('None', '') THEN NULL 
            ELSE Lower4 END AS Species,
       ChkBoxLower4 AS ChkBox,
       CASE WHEN (HeightLower4 GLOB '*[A-z]*' OR HeightLower4 = '') THEN NULL 
            ELSE (HeightLower4 * ConvertFactor) END AS Height,
       'Lower' AS Category, 4 AS Layer
  FROM tblLPIHeader AS b
 INNER JOIN tblLPIDetail AS c ON b.RecKey = c.RecKey
 INNER JOIN UnitConversion_Use AS d ON b.HeightUOM = d.Units
 WHERE Coalesce(Species, Height) IS NOT NULL

 UNION ALL
SELECT b.RecKey, PointNbr,
       CASE WHEN Lower5 IN ('None', '') THEN NULL 
            ELSE Lower5 END AS Species,
       ChkBoxLower5 AS ChkBox,
       CASE WHEN (HeightLower5 GLOB '*[A-z]*' OR HeightLower5 = '') THEN NULL 
            ELSE (HeightLower5 * ConvertFactor) END AS Height,
       'Lower' AS Category, 5 AS Layer
  FROM tblLPIHeader AS b
 INNER JOIN tblLPIDetail AS c ON b.RecKey = c.RecKey
 INNER JOIN UnitConversion_Use AS d ON b.HeightUOM = d.Units
 WHERE Coalesce(Species, Height) IS NOT NULL

 UNION ALL
SELECT b.RecKey, PointNbr,
       CASE WHEN Lower6 IN ('None', '') THEN NULL 
            ELSE Lower6 END AS Species,
       ChkBoxLower6 AS ChkBox,
       CASE WHEN (HeightLower6 GLOB '*[A-z]*' OR HeightLower6 = '') THEN NULL 
            ELSE (HeightLower6 * ConvertFactor) END AS Height,
       'Lower' AS Category, 6 AS Layer
  FROM tblLPIHeader AS b
 INNER JOIN tblLPIDetail AS c ON b.RecKey = c.RecKey
 INNER JOIN UnitConversion_Use AS d ON b.HeightUOM = d.Units
 WHERE Coalesce(Species, Height) IS NOT NULL

 UNION ALL
SELECT b.RecKey, PointNbr,
       CASE WHEN Lower7 IN ('None', '') THEN NULL 
            ELSE Lower7 END AS Species,
       ChkBoxLower7 AS ChkBox,
       CASE WHEN (HeightLower7 GLOB '*[A-z]*' OR HeightLower7 = '') THEN NULL 
            ELSE (HeightLower7 * ConvertFactor) END AS Height,
       'Lower' AS Category, 7 AS Layer
  FROM tblLPIHeader AS b
 INNER JOIN tblLPIDetail AS c ON b.RecKey = c.RecKey
 INNER JOIN UnitConversion_Use AS d ON b.HeightUOM = d.Units
 WHERE Coalesce(Species, Height) IS NOT NULL

 UNION ALL
SELECT b.RecKey, PointNbr,
       CASE WHEN SoilSurface IN ('None', '') THEN NULL 
            ELSE SoilSurface END AS Species,
       ChkBoxSoil AS ChkBox,
       CASE WHEN (HeightSurface GLOB '*[A-z]*' OR HeightSurface = '') THEN NULL 
            ELSE (HeightSurface * ConvertFactor) END AS Height,
       'Surface' AS Category, 8 AS Layer
  FROM tblLPIHeader AS b
 INNER JOIN tblLPIDetail AS c ON b.RecKey = c.RecKey
 INNER JOIN UnitConversion_Use AS d ON b.HeightUOM = d.Units
 WHERE Coalesce(Species, Height) IS NOT NULL

 UNION ALL
SELECT b.RecKey, PointNbr,
       CASE WHEN SpeciesWoody IN ('None', '') THEN NULL 
            ELSE SpeciesWoody END AS Species,
       NULL AS ChkBox,
       CASE WHEN (HeightWoody GLOB '*[A-z]*' OR HeightWoody = '') THEN NULL 
            ELSE (HeightWoody * ConvertFactor) END AS Height,
       'HeightWoody' AS Category, 9 AS Layer
  FROM tblLPIHeader AS b
 INNER JOIN tblLPIDetail AS c ON b.RecKey = c.RecKey
 INNER JOIN UnitConversion_Use AS d ON b.HeightUOM = d.Units
 WHERE Coalesce(Species, Height) IS NOT NULL

 UNION ALL
SELECT b.RecKey, PointNbr,
       CASE WHEN SpeciesHerbaceous IN ('None', '') THEN NULL 
            ELSE SpeciesHerbaceous END AS Species,
       NULL AS ChkBox,
       CASE WHEN (HeightHerbaceous GLOB '*[A-z]*' OR HeightHerbaceous = '') THEN NULL 
            ELSE (HeightHerbaceous * ConvertFactor) END AS Height,
       'HeightHerbaceous' AS Category, 10 AS Layer
  FROM tblLPIHeader AS b
 INNER JOIN tblLPIDetail AS c ON b.RecKey = c.RecKey
 INNER JOIN UnitConversion_Use AS d ON b.HeightUOM = d.Units
 WHERE Coalesce(Species, Height) IS NOT NULL
 ORDER BY b.RecKey, PointNbr, Layer;
 
COMMIT TRANSACTION;

BEGIN TRANSACTION;
--Delete/Insert: LPI_CanopyLayers_Point_Duration_Foliar was old view name
DELETE FROM LPI_Point_Indicators;

INSERT OR IGNORE INTO LPI_Point_Indicators
SELECT RecKey, PointNbr, c.Tag AS Duration,
       'Cover' AS IndicatorCategory,
       'Foliar' AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Any' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
  LEFT JOIN tblSpecies AS b ON b.SpeciesCode = a.Species
  LEFT JOIN CodeTags AS c ON b.Duration = c.Code
 WHERE b.SpeciesCode IS NOT NULL AND 
           c.Category = 'Duration' AND 
           c.Use = 1 AND 
           a.Category IN ('Top', 'Lower', 'Surface') 
 GROUP BY RecKey, PointNbr, c.Tag, Indicator

 UNION ALL
SELECT RecKey, PointNbr, c.Tag AS Duration,
       'Cover' AS IndicatorCategory,
       'Foliar' AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'First' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
  LEFT JOIN tblSpecies AS b ON b.SpeciesCode = a.Species
  LEFT JOIN CodeTags AS c ON b.Duration = c.Code
 WHERE b.SpeciesCode IS NOT NULL AND 
           c.Category = 'Duration' AND 
           c.Use = 1 AND 
           a.Category = 'Top'
 GROUP BY RecKey, PointNbr, c.Tag, Indicator

 UNION ALL
SELECT RecKey, PointNbr, c.Tag AS Duration,
       'Cover' AS IndicatorCategory,
       'Foliar' AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Basal' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
  LEFT JOIN tblSpecies AS b ON b.SpeciesCode = a.Species
  LEFT JOIN CodeTags AS c ON b.Duration = c.Code
 WHERE b.SpeciesCode IS NOT NULL AND 
           c.Category = 'Duration' AND 
           c.Use = 1 AND 
           a.Category = 'Surface'
 GROUP BY RecKey, PointNbr, c.Tag, Indicator

 UNION ALL
SELECT RecKey, PointNbr, c.Tag AS Duration,
       'Cover' AS IndicatorCategory,
       'Foliar' AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Height' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
  LEFT JOIN tblSpecies AS b ON b.SpeciesCode = a.Species
  LEFT JOIN CodeTags AS c ON b.Duration = c.Code
 WHERE b.SpeciesCode IS NOT NULL AND 
           c.Category = 'Duration' AND 
           c.Use = 1 AND 
           a.Category IN ('HeightWoody', 'HeightHerbaceous') 
 GROUP BY RecKey, PointNbr, c.Tag, Indicator

 UNION ALL
/* This statement is used to add instances of NULL species where there is a Woody Height, thus an implied perennial 
for the height. A similar statement for an Herbaceous Height field is not given due to the unknown duration of 
herbaceous hits (and this is a duration specific constructor). */
SELECT RecKey, PointNbr,
       'Perennial' AS Duration,
       'Cover' AS IndicatorCategory,
       'Foliar' AS Indicator,
       NULL AS ChkBox,
       Max(Height) AS Height,
       'Height' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates
 WHERE Category IN ('HeightWoody') AND 
           Species IS NULL AND 
           Height > 0
 GROUP BY RecKey, PointNbr, Duration, Indicator
 ORDER BY RecKey, PointNbr, Duration, Indicator;
 

--Delete/Insert: Cover_Line was name of old view
DELETE FROM Cover_Line;

INSERT INTO Cover_Line 
SELECT a.SiteKey, a.PlotKey, a.LineKey, b.RecKey, a.SiteID, a.PlotID,
       a.LineID, b.FormDate, b.Method, b.LineSize, b.LineSizeUnits,
       b.Duration, b.IndicatorCategory, b.Indicator, b.HitCategory,
       b.IndicatorSum, b.CoverPct, b.ChkPct
  FROM joinSitePlotLine AS a
 INNER JOIN LPI_Line_IndicatorsCalc AS b ON a.LineKey = b.LineKey
 WHERE HitCategory <> 'Height'

 UNION ALL
SELECT *
  FROM LI_Line_Cover
 ORDER BY SiteID, PlotID, LineID, FormDate, Method, 
       IndicatorCategory, Indicator, Duration;

COMMIT TRANSACTION;
PRAGMA foreign_keys = on;