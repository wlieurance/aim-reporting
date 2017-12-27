-- Text encoding used: System
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;
/* This script serves as an intermediary processor. Database was running out of memory on large datasets. 
This script converts some view results to indexed tables in order to solve the problem at the cost of disk space. */

--Delete/Insert: LPI_CanopyLayers_Point_DB_UNION was old view name.
--
--
--
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
 
 --Delete/Insert: LI_LineSum was old view name.
 --
 --
 --
DELETE FROM LI_LineSum;
 
INSERT OR IGNORE INTO LI_LineSum
SELECT RecKey, Method, SegType,
       'Gap' AS IndicatorCategory,
       'NA' AS Duration,
       'Gap' AS Indicator,
       Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
       Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
       Avg(Height) AS HeightMean,
       Avg(ChkBox) AS ChkBoxMean
  FROM LI_Detail_View AS a
 WHERE Species = 'GAP'
 GROUP BY RecKey, Method, SegType, IndicatorCategory, Duration, Indicator;

INSERT OR IGNORE INTO LI_LineSum
/* Creates the size class version of the Gap indicator. The CASE operator serves to contruct the indicator name from the size classes.*/
SELECT RecKey, Method, SegType,
       'Gap' AS IndicatorCategory,
       'NA' AS Duration,
       ('Gap (' || b.StartOperator || b.StartLimit ||  
             CASE WHEN EndOperator IS NULL THEN ')' 
                  ELSE ' to ' || EndOperator || EndLimit || ')' END) AS Indicator,
       Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
       Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
       Avg(Height) AS HeightMean,
       Avg(ChkBox) AS ChkBoxMean
  FROM LI_Detail_View AS a, LI_SizeClasses AS b
 WHERE Species = 'GAP' AND 
       (CASE WHEN b.StartOperator = '>' THEN Abs(SegStart - SegEnd) > b.StartLimit 
             WHEN b.StartOperator = '>=' THEN Abs(SegStart - SegEnd) >= b.StartLimit 
             ELSE 1 END) AND 
       (CASE WHEN b.EndOperator = '<' THEN Abs(SegStart - SegEnd) < b.EndLimit 
             WHEN b.EndOperator = '<=' THEN Abs(SegStart - SegEnd) <= b.EndLimit ELSE 1 END) 
 GROUP BY RecKey, Method, SegType, IndicatorCategory, Duration, Indicator;

INSERT OR IGNORE INTO LI_LineSum
/* Provides the species indicator. CodeTags serves as a duration converter.*/
SELECT RecKey, Method, SegType,
       'Species' AS IndicatorCategory,
       CASE WHEN b.Duration IS NULL THEN 'NA' ELSE b.Duration END AS Duration,
       CASE WHEN b.CodeType = 'generic' THEN 'Unidentified ' || b.ScientificName || ' (' || b.SpeciesCode || ')' 
            WHEN (b.ScientificName IS NULL OR b.ScientificName = '') AND 
                 (b.CommonName IS NULL OR b.CommonName = '') THEN b.SpeciesCode 
            WHEN (b.ScientificName IS NULL OR b.ScientificName = '') THEN b.CommonName 
            WHEN b.CodeType = 'family' THEN b.Family || ' genus sp.' 
            WHEN b.CodeType = 'genus' THEN b.ScientificName || ' sp.' 
            ELSE b.ScientificName END AS Indicator,
       Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
       Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
       Avg(Height) AS HeightMean,
       Avg(ChkBox) AS ChkBoxMean
  FROM LI_Detail_View AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 WHERE b.SpeciesCode IS NOT NULL
 GROUP BY RecKey, Method, SegType, IndicatorCategory, Duration, Indicator;

INSERT OR IGNORE INTO LI_LineSum
/* Provides the non-duration foliar indicator. */
SELECT RecKey, Method, SegType,
       'Foliar' AS IndicatorCategory,
       'All' AS Duration,
       'Foliar' AS Indicator,
       Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
       Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
       Avg(Height) AS HeightMean,
       Avg(ChkBox) AS ChkBoxMean
  FROM LI_Detail_View AS a
 WHERE Species <> 'GAP'
 GROUP BY RecKey, Method, SegType, IndicatorCategory, Duration, Indicator;

INSERT OR IGNORE INTO LI_LineSum
/* Provides the duration specific foliar indicator. CodeTags serves as a duration converter. */
SELECT RecKey, Method, SegType,
       'Foliar' AS IndicatorCategory,
       c.Tag AS Duration,
       'Foliar' AS Indicator,
       Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
       Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
       Avg(Height) AS HeightMean,
       Avg(ChkBox) AS ChkBoxMean
  FROM LI_Detail_View AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 INNER JOIN CodeTags AS c ON b.Duration = c.Code
 WHERE Species <> 'GAP' AND 
       c.Category = 'Duration' AND 
       c.Use = 1
 GROUP BY RecKey, Method, SegType, IndicatorCategory, Duration, Indicator;

INSERT OR IGNORE INTO LI_LineSum
/* Provides the duration specific GrowthHabitSub Indicator (Growth Habit). CodeTags used to filter and convert durations and growth habits.*/
SELECT RecKey, Method, SegType,
       'GrowthHabit' AS IndicatorCategory,
       e.Tag AS Duration, d.Tag AS Indicator,
       Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
       Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
       Avg(Height) AS HeightMean,
       Avg(ChkBox) AS ChkBoxMean
  FROM LI_Detail_View AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
 INNER JOIN CodeTags AS d ON c.GrowthHabitSub = d.Code
 INNER JOIN CodeTags AS e ON b.Duration = e.Code
 WHERE Species <> 'GAP' AND 
       d.Category = 'GrowthHabitSub' AND 
       d.Use = 1 AND 
       e.Category = 'Duration' AND 
       e.Use = 1
 GROUP BY RecKey, Method, SegType, IndicatorCategory, Duration, Indicator;

INSERT OR IGNORE INTO LI_LineSum
/* Provides the non-duration specific GrowthHabitSub Indicator (Growth Habit). CodeTags used to filter and convert growth habits.*/
SELECT RecKey, Method, SegType,
       'GrowthHabit' AS IndicatorCategory,
       'All' AS Duration,
       d.Tag AS Indicator,
       Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
       Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
       Avg(Height) AS HeightMean,
       Avg(ChkBox) AS ChkBoxMean
  FROM LI_Detail_View AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
 INNER JOIN CodeTags AS d ON c.GrowthHabitSub = d.Code
 INNER JOIN Duration_GrowthHabitSub_Combinations_Use_Count AS e ON d.Tag = e.GHTag
 WHERE Species <> 'GAP' AND 
       d.Category = 'GrowthHabitSub' AND 
       d.Use = 1 AND 
       e.GHCount > 1
 GROUP BY RecKey, Method, SegType, IndicatorCategory, Duration, Indicator;

INSERT OR IGNORE INTO LI_LineSum
/* Provides the duration specific GrowthHabit Indicator (Lignification). CodeTags used to filter and convert durations and growth habits.*/
SELECT RecKey, Method, SegType, IndicatorCategory, Duration, Indicator,
       Avg(length) AS LengthMean,
       Sum(length) AS LengthSum,
       Avg(Height) AS HeightMean,
       Avg(ChkBox) AS ChkBoxMean
  FROM 
       (SELECT a.RecKey, a.Method, a.SegType,
               'Lignification' AS IndicatorCategory,
               e.Tag AS Duration, d.Tag AS Indicator,
               Abs(a.SegStart - a.SegEnd) AS length,
               a.Height, a.ChkBox
          FROM LI_Detail_View AS a
         INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
          LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
         INNER JOIN CodeTags AS d ON c.GrowthHabit = d.Code
         INNER JOIN CodeTags AS e ON b.Duration = e.Code
         WHERE a.Species <> 'GAP' AND 
               d.Category = 'GrowthHabit' AND 
               d.Use = 1 AND 
               e.Category = 'Duration' AND 
               e.Use = 1)
 GROUP BY RecKey, Method, SegType, IndicatorCategory, Duration, Indicator;

INSERT OR IGNORE INTO LI_LineSum
/* Provides the non-duration specific GrowthHabit Indicator (Lignification). CodeTags used to filter and convert growth habits.*/
SELECT RecKey, Method, SegType, IndicatorCategory, Duration, Indicator,
       Avg(length) AS LengthMean,
       Sum(length) AS LengthSum,
       Avg(Height) AS HeightMean,
       Avg(ChkBox) AS ChkBoxMean
  FROM 
       (SELECT a.RecKey, a.Method, a.SegType,
               'Lignification' AS IndicatorCategory,
               'All' AS Duration,
               d.Tag AS Indicator,
               SegStart, SegEnd, Height, ChkBox,
               Abs(SegStart - SegEnd) AS length
          FROM LI_Detail_View AS a
         INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
          LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
         INNER JOIN CodeTags AS d ON c.GrowthHabit = d.Code
         INNER JOIN Duration_GrowthHabit_Combinations_Use_Count AS e ON d.Tag = e.GHTag
         WHERE a.Species <> 'GAP' AND 
               d.Category = 'GrowthHabit' AND 
               d.Use = 1 AND 
               e.DurationCount > 1)
 GROUP BY RecKey, Method, SegType, IndicatorCategory, Duration, Indicator;

INSERT OR IGNORE INTO LI_LineSum
/* Provides the non-duration specific Species Tag Indicator. */
SELECT RecKey, Method, SegType,
       'Species Tag' AS IndicatorCategory,
       'All' AS Duration,
       c.Tag AS Indicator,
       Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
       Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
       Avg(Height) AS HeightMean,
       Avg(ChkBox) AS ChkBoxMean
  FROM LI_Detail_View AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 INNER JOIN SpeciesTags AS c ON b.SpeciesCode = c.SpeciesCode
 INNER JOIN Duration_SpeciesTags_Combinations_Use_Count AS d ON c.Tag = d.SpeciesTag
 WHERE Species <> 'GAP' AND d.DurationCount > 1
 GROUP BY RecKey, Method, SegType, IndicatorCategory, Duration, Indicator;

 INSERT OR IGNORE INTO LI_LineSum
/* Provides the duration specific Species Tag Indicator. CodeTags used to filter and convert durations.*/
SELECT RecKey, Method, SegType,
       'Species Tag' AS IndicatorCategory,
       d.Tag AS Duration, c.Tag AS Indicator,
       Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
       Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
       Avg(Height) AS HeightMean,
       Avg(ChkBox) AS ChkBoxMean
  FROM LI_Detail_View AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 INNER JOIN SpeciesTags AS c ON a.Species = c.SpeciesCode
 INNER JOIN CodeTags AS d ON b.Duration = d.Code
 WHERE Species <> 'GAP' AND 
       d.Category = 'Duration' AND 
       d.Use = 1
 GROUP BY RecKey, Method, SegType, IndicatorCategory, d.Tag, c.Tag;
 

--Delete/Insert: Cover_Line was name of old view
--
--
--
DELETE FROM Cover_Line;

INSERT INTO Cover_Line 
SELECT a.SiteKey, a.PlotKey, a.LineKey, b.RecKey, a.SiteID, a.PlotID,
       a.LineID, b.FormDate, b.Method, b.LineSize, b.LineSizeUnits,
       b.Duration, b.IndicatorCategory, b.Indicator, b.HitCategory,
       b.IndicatorSum, b.CoverPct, b.ChkPct
  FROM joinSitePlotLine AS a
 INNER JOIN LPI_Line_IndicatorsCalc AS b ON a.LineKey = b.LineKey
 WHERE HitCategory <> 'Height';

INSERT INTO Cover_Line
SELECT *
  FROM LI_Line_Cover;

--Delete/Insert: SR_Line was name of old view
--
--
--  
DELETE FROM SR_Line;
INSERT INTO SR_Line
SELECT a.*,
       CASE WHEN b.subPlot_n IS NULL THEN 0 ELSE b.subPlot_n END AS subPlot_n,
       CASE WHEN b.MeanSpecies_n IS NULL THEN 0 ELSE b.MeanSpecies_n END AS MeanSpecies_n
  FROM SR_Line_Count AS a
 INNER JOIN SR_Line_Mean AS b ON a.RecKey = b.RecKey AND 
                                 a.Duration = b.Duration AND 
                                 a.Indicator = b.Indicator
 ORDER BY a.SiteID, a.PlotID, a.LineID, a.FormDate, a.IndicatorCategory, a.Duration, a.Indicator;
  
  
COMMIT TRANSACTION;
PRAGMA foreign_keys = on;