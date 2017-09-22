PRAGMA foreign_keys = off;

BEGIN TRANSACTION;

-- View: CodeTags_CodeCount
CREATE VIEW CodeTags_CodeCount AS
    SELECT Category,
           Tag,
           Count(Code) AS CodeCount
      FROM CodeTags
     GROUP BY Category,
              Tag
     ORDER BY Category,
              Tag;
			  
-- View: CodeTags_Grouped
CREATE VIEW CodeTags_Grouped AS
    SELECT Category,
           Tag
      FROM CodeTags
     WHERE Use = 1
     GROUP BY Tag,
              Category
     ORDER BY Category,
              Tag;
			  
-- View: Cover_Line
CREATE VIEW Cover_Line AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           Method,
           LineSize,
           LineSizeUnits,
           Duration,
           IndicatorCategory,
           Indicator,
           HitCategory,
           IndicatorSum,
           CoverPct,
           ChkPct
      FROM LPI_Line_IndicatorsCalc
     WHERE HitCategory <> 'Height'
    UNION
    SELECT *
      FROM LI_Line_Cover
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              Method,
              IndicatorCategory,
              Indicator,
              Duration;
			  
-- View: Cover_Plot
CREATE VIEW Cover_Plot AS
    SELECT SiteKey,
           PlotKey,
           SiteID,
           PlotID,
           (
               SELECT SeasonLabel
                 FROM SeasonDefinition
                WHERE FormDate BETWEEN SeasonStart AND SeasonEnd
           )
           AS Season,
           Method,
           Duration,
           IndicatorCategory,
           Indicator,
           HitCategory,
           Count(LineKey) AS Line_n,
           Avg(CoverPct) AS CoverPctMean,
           stdev(CoverPct) AS CoverPctSD,
           Avg(ChkPct) AS ChkPctMean,
           stdev(ChkPct) AS ChkPctSD
      FROM Cover_Line
     GROUP BY SiteKey,
              PlotKey,
              Season,
              Method,
              Duration,
              IndicatorCategory,
              Indicator,
              HitCategory
     ORDER BY SiteID,
              PlotID,
              Season,
              Method,
              IndicatorCategory,
              Indicator,
              HitCategory,
              Duration;
			  
-- View: Cover_Tag
CREATE VIEW Cover_Tag AS
    SELECT a.Tag,
           b.Method,
           b.Duration,
           b.IndicatorCategory,
           b.Indicator,
           b.HitCategory,
           Count(b.PlotKey) AS Plot_n,
           meanw(b.CoverPctMean, a.Weight) AS CoverPctMean,
           stdevw(b.CoverPctMean, a.Weight) AS CoverPctSD,
           meanw(b.ChkPctMean, a.Weight) AS ChkPctMean,
           stdevw(b.ChkPctMean, a.Weight) AS ChkPctSD
      FROM PlotTags AS a
           JOIN
           Cover_Plot AS b ON a.PlotKey = b.PlotKey
     GROUP BY a.Tag,
              b.Method,
              b.Duration,
              b.IndicatorCategory,
              b.Indicator,
              b.HitCategory
     ORDER BY a.Tag,
              b.Method,
              b.Duration,
              b.IndicatorCategory,
              b.Indicator,
              b.HitCategory;
			  
-- View: Dimensions_Line
CREATE VIEW Dimensions_Line AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           Method,
           HitCategory AS MethodCategory,
           LineSize,
           LineSizeUnits,
           Duration,
           IndicatorCategory,
           Indicator,
           'Height' AS Dimension,
           HeightMean AS DimMean,
           HeightUnits AS DimUnits
      FROM LPI_Line_IndicatorsCalc
     WHERE HeightMean IS NOT NULL
    UNION
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           Method,
           HitCategory AS MethodCategory,
           LineSize,
           LineSizeUnits,
           Duration,
           IndicatorCategory,
           Indicator,
           Dimension,
           DimMean,
           DimUnits
      FROM LI_Line_Height
    UNION
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           Method,
           HitCategory AS MethodCategory,
           LineSize,
           LineSizeUnits,
           Duration,
           IndicatorCategory,
           Indicator,
           Dimension,
           DimMean,
           DimUnits
      FROM LI_Line_Length
     ORDER BY SiteID,
              PLotID,
              LineID,
              FormDate,
              Method,
              MethodCategory,
              IndicatorCategory,
              HitCategory,
              Dimension,
              Indicator,
              Duration;
			  
-- View: Dimensions_Plot
CREATE VIEW Dimensions_Plot AS
    SELECT a.SiteKey,
           a.PlotKey,
           a.SiteID,
           a.PlotID,
           (
               SELECT SeasonLabel
                 FROM SeasonDefinition
                WHERE FormDate BETWEEN SeasonStart AND SeasonEnd
           )
           AS Season,
           a.Method,
           a.MethodCategory,
           a.Duration,
           a.IndicatorCategory,
           a.Indicator,
           a.Dimension,
           Count(LineKey) AS Line_n,
           avg(a.DimMean) AS DimMean,
           stdev(DimMean) AS DimSD,
           a.DimUnits
      FROM Dimensions_Line AS a
     GROUP BY SiteKey,
              PlotKey,
              Season,
              Method,
              MethodCategory,
              Duration,
              IndicatorCategory,
              Indicator,
              Dimension,
              DimUnits
     ORDER BY SiteID,
              PlotID,
              Season,
              Method,
              MethodCategory,
              IndicatorCategory,
              Indicator,
              Dimension,
              Duration;
			  
-- View: Dimensions_Tag
CREATE VIEW Dimensions_Tag AS
    SELECT a.Tag,
           b.Method,
           b.MethodCategory,
           b.Duration,
           b.IndicatorCategory,
           b.Indicator,
           b.Dimension,
           Count(b.PlotKey) AS Plot_n,
           meanw(b.DimMean, a.Weight) AS DimMean,
           stdevw(b.DimMean, a.Weight) AS DimSD,
           DimUnits
      FROM PlotTags AS a
           JOIN
           Dimensions_Plot AS b ON a.PlotKey = b.PlotKey
     GROUP BY a.Tag,
              b.Method,
              b.MethodCategory,
              b.Duration,
              b.IndicatorCategory,
              b.Indicator,
              b.Dimension
     ORDER BY a.Tag,
              b.Method,
              b.MethodCategory,
              b.Duration,
              b.IndicatorCategory,
              b.Indicator,
              b.Dimension;
			  
-- View: Duration_GrowthHabit_Combinations_ghTags
CREATE VIEW Duration_GrowthHabit_Combinations_ghTags AS
    SELECT a.GrowthHabit AS GHTag,
           b.Tag AS DurationTag,
           b.Use,
           Count(b.Tag) AS TagCount
      FROM Duration_GrowthHabit_Combinations AS a
           JOIN
           CodeTags AS b ON a.DurationTag = b.Code
     WHERE a.Category = 'GrowthHabit' AND 
           b.Category = 'Duration' AND 
           b.Use = 1
     GROUP BY a.GrowthHabit,
              b.Tag,
              b.Use;
			  
-- View: Duration_GrowthHabit_Combinations_Use
CREATE VIEW Duration_GrowthHabit_Combinations_Use AS
    SELECT a.*,
           b.CodeCount,
           (TagCount / CodeCount) AS TagUse
      FROM Duration_GrowthHabit_Combinations_ghTags AS a
           JOIN
           CodeTags_CodeCount AS b ON a.DurationTag = b.Tag
     WHERE TagUse = 1;
	 
-- View: Duration_GrowthHabit_Combinations_Use_Count
CREATE VIEW Duration_GrowthHabit_Combinations_Use_Count AS
    SELECT GHTag,
           Count(DurationTag) AS DurationCount
      FROM Duration_GrowthHabit_Combinations_Use
     GROUP BY GHTag
     ORDER BY GHTag;
	 
-- View: Duration_GrowthHabitSub_Combinations_AllTags
CREATE VIEW Duration_GrowthHabitSub_Combinations_AllTags AS
    SELECT a.GHTag,
           b.Tag AS DurationTag,
           Count(b.Tag) AS DurationTagCount
      FROM Duration_GrowthHabitSub_Combinations_ghTags AS a
           JOIN
           CodeTags AS b ON a.Duration = b.Code
     GROUP BY GHTag,
              DurationTag
     ORDER BY a.GHTag,
              b.Tag;
			  
-- View: Duration_GrowthHabitSub_Combinations_Final
CREATE VIEW Duration_GrowthHabitSub_Combinations_Final AS
    SELECT a.*,
           b.CodeCount,
           (a.DurationTagCount / b.CodeCount) AS UseDurationTag
      FROM Duration_GrowthHabitSub_Combinations_AllTags AS a
           JOIN
           CodeTags_CodeCount AS b ON a.DurationTag = b.Tag
     WHERE UseDurationTag = 1
     ORDER BY a.GHTag,
              a.DurationTag;
			  
-- View: Duration_GrowthHabitSub_Combinations_ghTags
CREATE VIEW Duration_GrowthHabitSub_Combinations_ghTags AS
    SELECT a.Tag AS GHTag,
           b.DurationTag AS Duration
      FROM CodeTags AS a
           JOIN
           Duration_GrowthHabit_Combinations AS b ON a.Code = b.GrowthHabit
     WHERE b.Category = 'GrowthHabitSub'
     GROUP BY a.Tag,
              b.DurationTag
     ORDER BY a.Tag,
              b.DurationTag;
			  
-- View: Duration_GrowthHabitSub_Combinations_Use
CREATE VIEW Duration_GrowthHabitSub_Combinations_Use AS
    SELECT a.GHTag,
           a.DurationTag,
           b.Use AS GHUse,
           c.Use AS DurationUse
      FROM Duration_GrowthHabitSub_Combinations_Final AS a
           JOIN
           CodeTags AS b ON a.GHTag = b.Tag
           JOIN
           CodeTags AS c ON a.DurationTag = c.Tag
     GROUP BY GHTag,
              DurationTag,
              GHUse,
              DurationUse
    HAVING GHUse = 1 AND 
           DurationUse = 1
     ORDER BY GHTag,
              DurationTag;
			  
-- View: Duration_GrowthHabitSub_Combinations_Use_Count
CREATE VIEW Duration_GrowthHabitSub_Combinations_Use_Count AS
    SELECT GHTag,
           Count(GHTag) AS GHCount
      FROM Duration_GrowthHabitSub_Combinations_Use
     GROUP BY GHTag
     ORDER BY GHTag;
	 
-- View: Duration_SpeciesTags
CREATE VIEW Duration_SpeciesTags AS
    SELECT a.Tag,
           b.Duration
      FROM SpeciesTags AS a
           JOIN
           tblSpecies AS b ON a.SpeciesCode = b.SpeciesCode
     WHERE Duration IS NOT NULL
     GROUP BY Tag,
              Duration
     ORDER BY Tag,
              Duration;
			  
-- View: Duration_SpeciesTags_Combinations_Use
CREATE VIEW Duration_SpeciesTags_Combinations_Use AS
    SELECT a.Tag AS SpeciesTag,
           b.Tag AS DurationTag
      FROM Duration_SpeciesTags AS a
           JOIN
           CodeTags AS b ON a.Duration = b.Code
     WHERE b.Category = 'Duration' AND 
           b.Use = 1
     GROUP BY SpeciesTag,
              DurationTag;
			  
-- View: Duration_SpeciesTags_Combinations_Use_Count
CREATE VIEW Duration_SpeciesTags_Combinations_Use_Count AS
    SELECT SpeciesTag,
           Count(DurationTag) AS DurationCount
      FROM Duration_SpeciesTags_Combinations_Use
     GROUP BY SpeciesTag
     ORDER BY SpeciesTag;
	 
-- View: IIRH_Raw
CREATE VIEW IIRH_Raw AS
    SELECT d.SiteKey,
           c.PlotKey,
           a.RecKey,
           d.SiteID,
           d.SiteName,
           c.PlotID,
           c.EcolSite,
           'Indicator' AS Category,
           a.Seq,
           f.Description AS Description,
           e.Code AS RatingCode,
           e.Description AS RatingDescription,
           a.Comment
      FROM tblQualDetail AS a
           JOIN
           tblQualHeader AS b ON a.RecKey = b.RecKey
           JOIN
           tblPlots AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSites AS d ON c.SiteKey = d.SiteKey
           LEFT JOIN
           tblMaintQualRatings AS e ON a.Rating = e.Rating
           LEFT JOIN
           tblMaintQualIndicators AS f ON a.Seq = f.Seq
    UNION
    SELECT c.SiteKey,
           b.PlotKey,
           a.RecKey,
           c.SiteID,
           c.SiteName,
           b.PlotID,
           b.EcolSite,
           'Attribute' AS Category,
           0 AS Seq,
           'Soil & Site Stability' AS Description,
           a.SSSVxWRatingFinal AS RatingCode,
           e.Description AS RatingDescription,
           a.CommentSSS AS Comment
      FROM tblQualHeader AS a
           JOIN
           tblPlots AS b ON a.PlotKey = b.PlotKey
           JOIN
           tblSites AS c ON b.SiteKey = c.SiteKey
           LEFT JOIN
           tblMaintQualRatings AS e ON a.SSSVxWRatingFinal = e.Code
    UNION
    SELECT c.SiteKey,
           b.PlotKey,
           a.RecKey,
           c.SiteID,
           c.SiteName,
           b.PlotID,
           b.EcolSite,
           'Attribute' AS Category,
           0 AS Seq,
           'Hydrologic Function' AS Description,
           a.HFVxWRatingFinal AS RatingCode,
           e.Description AS RatingDescription,
           a.CommentHF AS Comment
      FROM tblQualHeader AS a
           JOIN
           tblPlots AS b ON a.PlotKey = b.PlotKey
           JOIN
           tblSites AS c ON b.SiteKey = c.SiteKey
           LEFT JOIN
           tblMaintQualRatings AS e ON a.HFVxWRatingFinal = e.Code
    UNION
    SELECT c.SiteKey,
           b.PlotKey,
           a.RecKey,
           c.SiteID,
           c.SiteName,
           b.PlotID,
           b.EcolSite,
           'Attribute' AS Category,
           0 AS Seq,
           'Biotic Integrity' AS Description,
           a.BIVxWRatingFinal AS RatingCode,
           e.Description AS RatingDescription,
           a.CommentBI AS Comment
      FROM tblQualHeader AS a
           JOIN
           tblPlots AS b ON a.PlotKey = b.PlotKey
           JOIN
           tblSites AS c ON b.SiteKey = c.SiteKey
           LEFT JOIN
           tblMaintQualRatings AS e ON a.BIVxWRatingFinal = e.Code
     ORDER BY SIteID,
              PlotID,
              a.Seq,
              Description;
			  
-- View: joinSitePlot
CREATE VIEW joinSitePlot AS
    SELECT a.SiteKey,
           a.SiteID,
           a.SiteName,
           b.PlotKey,
           b.PlotID
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999');
	 
-- View: joinSitePlotLine
CREATE VIEW joinSitePlotLine AS
    SELECT a.SiteKey,
           a.SiteID,
           a.SiteName,
           b.PlotKey,
           b.PlotID,
           c.LineKey,
           c.LineID
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999');
	 
-- View: LI_Detail_View
CREATE VIEW LI_Detail_View AS
    SELECT RecKey,
           'Gap Intercept' AS Method,
           CASE WHEN RecType = 'C' THEN 'Canopy' WHEN RecType = 'B' THEN 'Basal' ELSE 'Unknown' END AS SegType,
           'GAP' AS Species,
           CAST (GapStart AS NUMERIC) AS SegStart,
           CAST (GapEnd AS NUMERIC) AS SegEnd,
           NULL AS Height,
           NULL AS ChkBox
      FROM tblGapDetail
    UNION ALL
    SELECT RecKey,
           'Continuous Line Intercept' AS Method,
           'Canopy' AS SegType,
           Species,
           StartPos AS SegStart,
           EndPos AS SegEnd,
           Height,
           ChkBox
      FROM tblLICDetail
    UNION ALL
    SELECT a.RecKey,
           'Canopy Gap with Species' AS Method,
           'Canopy' AS SegType,
           a.Species,
           a.StartPos AS SegStart,
           CASE WHEN DataEntryDirection = 1 THEN StartPos + Length ELSE StartPos - Length END AS SegEnd,
           NULL AS Height,
           a.ChkBox
      FROM tblCanopyGapDetail AS a
           JOIN
           tblCanopyGapHeader AS b ON a.RecKey = b.RecKey
     ORDER BY RecKey,
              Method,
              SegStart;
			  
-- View: LI_Header_View
CREATE VIEW LI_Header_View AS
    SELECT LineKey,
           RecKey,
           DateModified,
           'Gap Intercept' AS Method,
           FormDate,
           Observer,
           Recorder,
           DataEntry,
           DataErrorChecking,
           LineLengthAmount,
           CASE WHEN Measure = 1 THEN 'm' ELSE 'ft' END AS LineLengthUnit,
           CASE WHEN Measure = 1 THEN 'cm' ELSE 'ft' END AS SegUnit,
           GapMin AS SegMin,
           CASE WHEN Perennials = 1 THEN 'Perennials;' ELSE '' END || CASE WHEN AnnualGrasses = 1 THEN 'AnnualGrasses;' ELSE '' END || CASE WHEN AnnualForbs = 1 THEN 'AnnualForbs;' ELSE '' END || CASE WHEN Other = 1 THEN 'Other;' ELSE '' END AS SegEndCriteria,
           NULL AS HeightUnit,
           NULL AS ChkBoxLabel,
           Notes,
           CASE WHEN GapData = '1' THEN NoCanopyGaps * NoBasalGaps WHEN GapData = '2' THEN NoCanopyGaps ELSE NoBasalGaps END AS EmptyForm
      FROM tblGapHeader
     WHERE FormDate BETWEEN (
                                SELECT StartDate
                                  FROM Data_DateRange
                                 WHERE rowid = 1
                            )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
    UNION ALL
    SELECT LineKey,
           RecKey,
           DateModified,
           'Canopy Gap with Species' AS Method,
           FormDate,
           Observer,
           Recorder,
           DataEntry,
           DataErrorChecking,
           LineLengthAmount,
           CASE WHEN Measure = 1 THEN 'm' ELSE 'ft' END AS LineLengthUnit,
           PositionUOM AS SegUnit,
           MinLength AS SegMin,
           'Unknown' AS SegEndCriteria,
           NULL AS HeightUnit,
           CheckboxLabel AS ChkBoxLabel,
           Notes,
           NULL AS EmptyForm
      FROM tblCanopyGapHeader
     WHERE FormDate BETWEEN (
                                SELECT StartDate
                                  FROM Data_DateRange
                                 WHERE rowid = 1
                            )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
    UNION ALL
    SELECT LineKey,
           RecKey,
           DateModified,
           'Continuous Line Intercept' AS Method,
           FormDate,
           Observer,
           Recorder,
           DataEntry,
           DataErrorChecking,
           LineLengthAmount,
           CASE WHEN Measure = 1 THEN 'm' ELSE 'ft' END AS LineLengthUnit,
           PositionUOM AS SegUnit,
           MinLengthCanopySeg AS SegMin,
           'Unknown' AS SegEndCriteria,
           HeightUOM AS HeightUnit,
           CheckboxLabel AS ChkBoxLabel,
           Notes,
           NULL AS EmptyForm
      FROM tblLICHeader
     WHERE FormDate BETWEEN (
                                SELECT StartDate
                                  FROM Data_DateRange
                                 WHERE rowid = 1
                            )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     ORDER BY LineKey,
              RecKey,
              Method;
			  
-- View: LI_Line_Cover
CREATE VIEW LI_Line_Cover AS
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           c.Method,
           c.LineLengthAmount AS LineSize,
           c.LengthUnits AS LineSizeUnits,
           c.Duration,
           c.IndicatorCategory,
           c.Indicator,
           c.InterceptType AS HitCategory,
           c.LengthSum AS IndicatorSum,
           c.PctCover AS CoverPct,
           c.ChkBoxMean AS ChkPct
      FROM SitePlotLine_Join AS a
           JOIN
           LI_Header_View AS b ON a.LineKey = b.LineKey
           JOIN
           LI_LineCalc AS c ON b.RecKey = c.RecKey AND 
                               b.Method = c.Method
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID,
              b.FormDate,
              c.Method,
              c.IndicatorCategory,
              c.Indicator,
              c.Duration;
			  
-- View: LI_Line_Height
CREATE VIEW LI_Line_Height AS
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           c.Method,
           c.LineLengthAmount AS LineSize,
           c.LengthUnits AS LineSizeUnits,
           c.Duration,
           c.IndicatorCategory,
           c.Indicator,
           c.InterceptType AS HitCategory,
           'Height' AS Dimension,
           c.HeightMean AS DimMean,
           c.HeightUnit AS DimUnits
      FROM SitePlotLine_Join AS a
           JOIN
           LI_Header_View AS b ON a.LineKey = b.LineKey
           JOIN
           LI_LineCalc AS c ON b.RecKey = c.RecKey AND 
                               b.Method = c.Method
     WHERE HeightMean IS NOT NULL
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID,
              b.FormDate,
              c.Method,
              c.IndicatorCategory,
              c.Indicator,
              c.Duration;
			  
-- View: LI_Line_IndicatorsCartesian
CREATE VIEW LI_Line_IndicatorsCartesian AS
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           a.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           a.Method,
           a.FormDate,
           a.SegType,
           b.IndicatorCategory,
           b.Duration,
           b.Indicator
      FROM LI_PlotsLinesForms AS a,
           NonSpeciesIndicators AS b
     WHERE a.Method = 'Continuous Line Intercept' AND 
           b.IndicatorCategory <> 'Gap'
    UNION ALL
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           a.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           a.Method,
           a.FormDate,
           a.SegType,
           b.IndicatorCategory,
           b.Duration,
           b.Indicator
      FROM LI_PlotsLinesForms AS a,
           NonSpeciesIndicators AS b
     WHERE a.Method = 'Canopy Gap with Species'
    UNION ALL
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           a.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           a.Method,
           a.FormDate,
           a.SegType,
           b.IndicatorCategory,
           b.Duration,
           b.Indicator
      FROM LI_PlotsLinesForms AS a,
           NonSpeciesIndicators AS b
     WHERE a.Method = 'Gap Intercept' AND 
           b.IndicatorCategory = 'Gap'
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              Method,
              IndicatorCategory,
              Indicator,
              Duration;
			  
-- View: LI_Line_Length
CREATE VIEW LI_Line_Length AS
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           c.Method,
           c.LineLengthAmount AS LineSize,
           c.LengthUnits AS LineSizeUnits,
           c.Duration,
           c.IndicatorCategory,
           c.Indicator,
           c.InterceptType AS HitCategory,
           'Length' AS Dimension,
           c.LengthMean AS DimMean,
           c.LengthUnits AS DimUnits
      FROM SitePlotLine_Join AS a
           JOIN
           LI_Header_View AS b ON a.LineKey = b.LineKey
           JOIN
           LI_LineCalc AS c ON b.RecKey = c.RecKey AND 
                               b.Method = c.Method
     WHERE LengthMean IS NOT NULL
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID,
              b.FormDate,
              c.Method,
              c.IndicatorCategory,
              c.Indicator,
              c.Duration;
			  
-- View: LI_LineCalc
CREATE VIEW LI_LineCalc AS
    SELECT a.LineKey,
           b.RecKey,
           b.Method,
           b.SegType AS InterceptType,
           (a.LineLengthAmount * c.ConvertFactor) AS LineLengthAmount,
           d.FinalUnits AS LengthUnits,
           b.IndicatorCategory,
           b.Duration,
           b.Indicator,
           (b.LengthMean * d.ConvertFactor) AS LengthMean,
           (b.LengthSum * d.ConvertFactor) AS LengthSum,
           (CAST ( (b.LengthSum * d.ConvertFactor) AS REAL) / (a.LineLengthAmount * c.ConvertFactor) ) AS PctCover,
           (b.HeightMean * e.ConvertFactor) AS HeightMean,
           e.FinalUnits AS HeightUnit,
           b.ChkBoxMean
      FROM LI_Header_View AS a
           JOIN
           LI_LineSum_Indicators AS b ON a.RecKey = b.RecKey AND 
                                         a.Method = b.Method
           LEFT JOIN
           UnitConversion_Use AS c ON a.LineLengthUnit = c.Units
           LEFT JOIN
           UnitConversion_Use AS d ON a.SegUnit = d.Units
           LEFT JOIN
           UnitConversion_Use AS e ON a.HeightUnit = e.Units
     ORDER BY a.Linekey,
              b.RecKey,
              b.Method,
              b.SegType,
              b.IndicatorCategory,
              b.Indicator,
              b.Duration;
			  
-- View: LI_LineSum
CREATE VIEW LI_LineSum AS
    SELECT RecKey,
           Method,
           SegType,
           'Gap' AS IndicatorCategory,
           'NA' AS Duration,
           'Gap' AS Indicator,
           Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
           Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
           Avg(Height) AS HeightMean,
           Avg(ChkBox) AS ChkBoxMean
      FROM LI_Detail_View AS a
     WHERE Species = 'GAP'
     GROUP BY RecKey,
              Method,
              SegType,
              IndicatorCategory,
              Duration,
              Indicator
    UNION ALL
    SELECT RecKey,
           Method,
           SegType,
           'Gap' AS IndicatorCategory,
           'NA' AS Duration,
           ('Gap (' || b.StartLimit || CASE WHEN b.StartOperator = '>' THEN '<' ELSE '=' END || 'x' || CASE WHEN b.EndOperator IS NULL THEN '' WHEN b.EndOperator = '<' THEN '<' ELSE '=' END || CASE WHEN b.EndLimit IS NULL THEN '' ELSE b.EndLimit END || ')') AS Indicator,
           Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
           Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
           Avg(Height) AS HeightMean,
           Avg(ChkBox) AS ChkBoxMean
      FROM LI_Detail_View AS a,
           LI_SizeClasses AS b
     WHERE Species = 'GAP' AND 
           (CASE WHEN b.StartOperator = '>' THEN Abs(SegStart - SegEnd) > b.StartLimit WHEN b.StartOperator = '>=' THEN Abs(SegStart - SegEnd) >= b.StartLimit ELSE 1 END) AND 
           (CASE WHEN b.EndOperator = '<' THEN Abs(SegStart - SegEnd) < b.EndLimit WHEN b.EndOperator = '<=' THEN Abs(SegStart - SegEnd) <= b.EndLimit ELSE 1 END) 
     GROUP BY RecKey,
              Method,
              SegType,
              IndicatorCategory,
              Duration,
              Indicator
    UNION ALL
    SELECT RecKey,
           Method,
           SegType,
           'Species' AS IndicatorCategory,
           c.Tag AS Duration,
           b.ScientificName AS Indicator,
           Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
           Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
           Avg(Height) AS HeightMean,
           Avg(ChkBox) AS ChkBoxMean
      FROM LI_Detail_View AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           JOIN
           CodeTags AS c ON b.Duration = c.Code
     WHERE b.ScientificName IS NOT NULL AND 
           c.Category = 'Duration' AND 
           c.Use = 1
     GROUP BY RecKey,
              Method,
              SegType,
              IndicatorCategory,
              Duration,
              Indicator
    UNION ALL
    SELECT RecKey,
           Method,
           SegType,
           'Foliar' AS IndicatorCategory,
           'All' AS Duration,
           'Foliar' AS Indicator,
           Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
           Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
           Avg(Height) AS HeightMean,
           Avg(ChkBox) AS ChkBoxMean
      FROM LI_Detail_View AS a
     WHERE Species <> 'GAP'
     GROUP BY RecKey,
              Method,
              SegType,
              IndicatorCategory,
              Duration,
              Indicator
    UNION ALL
    SELECT RecKey,
           Method,
           SegType,
           'Foliar' AS IndicatorCategory,
           c.Tag AS Duration,
           'Foliar' AS Indicator,
           Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
           Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
           Avg(Height) AS HeightMean,
           Avg(ChkBox) AS ChkBoxMean
      FROM LI_Detail_View AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           JOIN
           CodeTags AS c ON b.Duration = c.Code
     WHERE Species <> 'GAP' AND 
           c.Category = 'Duration' AND 
           C.Use = 1
     GROUP BY RecKey,
              Method,
              SegType,
              IndicatorCategory,
              Duration,
              Indicator
    UNION ALL
    SELECT RecKey,
           Method,
           SegType,
           'GrowthHabit' AS IndicatorCategory,
           e.Tag AS Duration,
           d.Tag AS Indicator,
           Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
           Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
           Avg(Height) AS HeightMean,
           Avg(ChkBox) AS ChkBoxMean
      FROM LI_Detail_View AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           JOIN
           CodeTags AS d ON c.GrowthHabitSub = d.Code
           JOIN
           CodeTags AS e ON b.Duration = e.Code
     WHERE Species <> 'GAP' AND 
           d.Category = 'GrowthHabitSub' AND 
           d.Use = 1 AND 
           e.Category = 'Duration' AND 
           e.Use = 1
     GROUP BY RecKey,
              Method,
              SegType,
              IndicatorCategory,
              Duration,
              Indicator
    UNION ALL
    SELECT RecKey,
           Method,
           SegType,
           'GrowthHabit' AS IndicatorCategory,
           'All' AS Duration,
           d.Tag AS Indicator,
           Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
           Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
           Avg(Height) AS HeightMean,
           Avg(ChkBox) AS ChkBoxMean
      FROM LI_Detail_View AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           JOIN
           CodeTags AS d ON c.GrowthHabitSub = d.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use_Count AS e ON d.Tag = e.GHTag
     WHERE Species <> 'GAP' AND 
           d.Category = 'GrowthHabitSub' AND 
           d.Use = 1 AND 
           e.GHCount > 1
     GROUP BY RecKey,
              Method,
              SegType,
              IndicatorCategory,
              Duration,
              Indicator
    UNION ALL
    SELECT RecKey,
           Method,
           SegType,
           'GrowthHabit' AS IndicatorCategory,
           e.Tag AS Duration,
           d.Tag AS Indicator,
           Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
           Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
           Avg(Height) AS HeightMean,
           Avg(ChkBox) AS ChkBoxMean
      FROM LI_Detail_View AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           JOIN
           CodeTags AS d ON c.GrowthHabit = d.Code
           JOIN
           CodeTags AS e ON b.Duration = e.Code
     WHERE Species <> 'GAP' AND 
           d.Category = 'GrowthHabit' AND 
           d.Use = 1 AND 
           e.Category = 'Duration' AND 
           e.Use = 1
     GROUP BY RecKey,
              Method,
              SegType,
              IndicatorCategory,
              Duration,
              Indicator
    UNION ALL
    SELECT RecKey,
           Method,
           SegType,
           'GrowthHabit' AS IndicatorCategory,
           'All' AS Duration,
           d.Tag AS Indicator,
           Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
           Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
           Avg(Height) AS HeightMean,
           Avg(ChkBox) AS ChkBoxMean
      FROM LI_Detail_View AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           JOIN
           CodeTags AS d ON c.GrowthHabit = d.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use_Count AS e ON d.Tag = e.GHTag
     WHERE Species <> 'GAP' AND 
           d.Category = 'GrowthHabit' AND 
           d.Use = 1 AND 
           e.DurationCount > 1
     GROUP BY RecKey,
              Method,
              SegType,
              IndicatorCategory,
              Duration,
              Indicator
    UNION ALL
    SELECT RecKey,
           Method,
           SegType,
           'Species Tag' AS IndicatorCategory,
           'All' AS Duration,
           c.Tag AS Indicator,
           Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
           Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
           Avg(Height) AS HeightMean,
           Avg(ChkBox) AS ChkBoxMean
      FROM LI_Detail_View AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           JOIN
           SpeciesTags AS c ON b.SpeciesCode = c.SpeciesCode
           JOIN
           Duration_SpeciesTags_Combinations_Use_Count AS d ON c.Tag = d.SpeciesTag
     WHERE Species <> 'GAP' AND 
           d.DurationCount > 1
     GROUP BY RecKey,
              Method,
              SegType,
              IndicatorCategory,
              Duration,
              Indicator
    UNION ALL
    SELECT RecKey,
           Method,
           SegType,
           'Species Tag' AS IndicatorCategory,
           d.Tag AS Duration,
           c.Tag AS Indicator,
           Avg(Abs(SegStart - SegEnd) ) AS LengthMean,
           Sum(Abs(SegStart - SegEnd) ) AS LengthSum,
           Avg(Height) AS HeightMean,
           Avg(ChkBox) AS ChkBoxMean
      FROM LI_Detail_View AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           JOIN
           SpeciesTags AS c ON a.Species = c.SpeciesCode
           JOIN
           CodeTags AS d ON b.Duration = d.Code
     WHERE Species <> 'GAP' AND 
           d.Category = 'Duration' AND 
           d.Use = 1
     GROUP BY RecKey,
              Method,
              SegType,
              IndicatorCategory,
              d.Tag,
              c.Tag
     ORDER BY RecKey,
              Method,
              SegType,
              IndicatorCategory,
              Indicator,
              Duration;
			  
-- View: LI_LineSum_Indicators
CREATE VIEW LI_LineSum_Indicators AS
    SELECT a.RecKey,
           a.Method,
           a.IndicatorCategory,
           a.Duration,
           a.Indicator,
           a.SegType,
           CASE WHEN b.LengthMean IS NULL THEN 0 ELSE b.LengthMean END AS LengthMean,
           CASE WHEN b.LengthSum IS NULL THEN 0 ELSE b.LengthSum END AS LengthSum,
           b.HeightMean,
           b.ChkBoxMean
      FROM LI_Line_IndicatorsCartesian AS a
           LEFT JOIN
           LI_LineSum AS b ON a.RecKey = b.RecKey AND 
                              a.IndicatorCategory = b.IndicatorCategory AND 
                              a.Duration = b.Duration AND 
                              a.Indicator = b.Indicator AND 
                              a.SegType = b.SegType
     ORDER BY a.RecKey,
              a.Method,
              a.SegType,
              a.IndicatorCategory,
              a.Indicator,
              a.Duration;
			  
-- View: LI_Plot_Species
CREATE VIEW LI_Plot_Species AS
    SELECT a.SiteKey,
           a.PlotKey,
           a.SiteID,
           a.PlotID,
           d.ScientificName
      FROM SitePlotLine_Join AS a
           JOIN
           LI_Header_View AS b ON a.LineKey = b.LineKey
           JOIN
           LI_Detail_View AS c ON b.RecKey = c.RecKey
           JOIN
           tblSpecies AS d ON c.Species = d.SpeciesCode
     WHERE d.ScientificName IS NOT NULL
     GROUP BY a.SiteKey,
              a.PlotKey,
              d.ScientificName
     ORDER BY a.SiteID,
              a.PlotID,
              d.ScientificName;
			  
-- View: LI_PlotsLinesForms
CREATE VIEW LI_PlotsLinesForms AS
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.Method,
           b.FormDate,
           c.SegType
      FROM SitePlotLine_Join AS a
           JOIN
           LI_Header_View AS b ON a.LineKey = b.LineKey
           JOIN
           LI_Detail_View AS c ON b.RecKey = c.RecKey
     GROUP BY a.SiteKey,
              a.PlotKey,
              a.LineKey,
              b.RecKey,
              c.SegType
     ORDER BY SiteID,
              PlotID,
              LineID,
              b.Method,
              FormDate,
              SegType;
			  
-- View: LI_Raw_Final
CREATE VIEW LI_Raw_Final AS
    SELECT e.SiteID,
           e.SiteName,
           d.PlotID,
           c.LineID,
           b.FormDate,
           a.*
      FROM LI_Detail_View AS a
           JOIN
           LI_Header_View AS b ON a.RecKey = b.RecKey
           JOIN
           tblLines AS c ON b.LineKey = c.LineKey
           JOIN
           tblPlots AS d ON c.PlotKey = d.PlotKey
           JOIN
           tblSites AS e ON d.SiteKey = e.SiteKey
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              SegStart;
			  
-- View: Line_Definition
CREATE VIEW Line_Definition AS
    SELECT c.SiteKey,
           b.PlotKey,
           a.LineKey,
           c.SiteID,
           c.SiteName,
           b.PLotID,
           b.EstablishDate AS Plot_EstablishDate,
           b.GPSCoordSys,
           b.Datum,
           b.Zone,
           a.DateModified,
           a.LineID,
           a.Azimuth,
           CASE a.ElevationType WHEN 1 THEN 'm' WHEN 2 THEN 'ft' ELSE a.ElevationType END AS ElevationType,
           CASE a.NorthType WHEN 1 THEN 'Magnetic' WHEN 2 THEN 'Geodetic' ELSE a.NorthType END AS NorthType,
           a.NorthingStart,
           a.EastingStart,
           a.ElevationStart,
           a.NorthingEnd,
           a.EastingEnd,
           a.ElevationEnd,
           a.LatitudeStart,
           a.LongitudeStart,
           a.LatitudeEnd,
           a.LongitudeEnd
      FROM tblLines AS a
           JOIN
           tblPlots AS b ON a.PlotKey = b.PlotKey
           JOIN
           tblSites AS c ON b.SiteKey = c.SiteKey
     ORDER BY SiteID,
              PlotID,
              LineID;
			  
-- View: LPI_CanopyDefinitions
CREATE VIEW LPI_CanopyDefinitions AS
    SELECT *,
           CASE WHEN instr(CategoryConcat, 'Top') != 0 THEN 'Cover' WHEN (instr(CategoryConcat, 'Top') = 0 AND 
                                                                          instr(CategoryConcat, 'Lower') != 0) THEN 'Bare Litter' ELSE 'Bare' END AS CvrCat
      FROM LPI_CanopyDefinitions_CategoryConcat
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr;
			  
-- View: LPI_CanopyDefinitions_CategoryConcat
CREATE VIEW LPI_CanopyDefinitions_CategoryConcat AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           group_concat(Category, ';') AS CategoryConcat
      FROM LPI_CanopyLayers_Point_DB_RestrictDates
     GROUP BY RecKey,
              PointNbr
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr;
			  
-- View: LPI_CanopyLayers_Point_DB_RestrictDates
CREATE VIEW LPI_CanopyLayers_Point_DB_RestrictDates AS
    SELECT *
      FROM LPI_CanopyLayers_Point_DB_UNION
     WHERE FormDate BETWEEN (
                                SELECT StartDate
                                  FROM Data_DateRange
                                 WHERE rowid = 1
                            )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Rank;
			  
-- View: LPI_CanopyLayers_Point_DB_UNION
CREATE VIEW LPI_CanopyLayers_Point_DB_UNION AS
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           PointNbr,
           CASE WHEN TopCanopy IN ('None', '') THEN NULL ELSE TopCanopy END AS Species,
           ChkBoxTop AS ChkBox,
           CASE WHEN (HeightTop GLOB '*[A-z]*' OR 
                      HeightTop = '') THEN NULL ELSE (HeightTop * ConvertFactor) END AS Height,
           'Top' AS Category,
           0 AS Rank
      FROM SitePlotLine_Join AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
           JOIN
           UnitConversion_Use AS d ON b.HeightUOM = d.Units
     WHERE Coalesce(Species, Height) IS NOT NULL
    UNION ALL
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           PointNbr,
           CASE WHEN Lower1 IN ('None', '') THEN NULL ELSE Lower1 END AS Species,
           ChkBoxLower1 AS ChkBox,
           CASE WHEN (HeightLower1 GLOB '*[A-z]*' OR 
                      HeightLower1 = '') THEN NULL ELSE (HeightLower1 * ConvertFactor) END AS Height,
           'Lower' AS Category,
           1 AS Rank
      FROM SitePlotLine_Join AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
           JOIN
           UnitConversion_Use AS d ON b.HeightUOM = d.Units
     WHERE Coalesce(Species, Height) IS NOT NULL
    UNION ALL
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           PointNbr,
           CASE WHEN Lower2 IN ('None', '') THEN NULL ELSE Lower2 END AS Species,
           ChkBoxLower2 AS ChkBox,
           CASE WHEN (HeightLower2 GLOB '*[A-z]*' OR 
                      HeightLower2 = '') THEN NULL ELSE (HeightLower2 * ConvertFactor) END AS Height,
           'Lower' AS Category,
           2 AS Rank
      FROM SitePlotLine_Join AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
           JOIN
           UnitConversion_Use AS d ON b.HeightUOM = d.Units
     WHERE Coalesce(Species, Height) IS NOT NULL
    UNION ALL
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           PointNbr,
           CASE WHEN Lower3 IN ('None', '') THEN NULL ELSE Lower3 END AS Species,
           ChkBoxLower3 AS ChkBox,
           CASE WHEN (HeightLower3 GLOB '*[A-z]*' OR 
                      HeightLower3 = '') THEN NULL ELSE (HeightLower3 * ConvertFactor) END AS Height,
           'Lower' AS Category,
           3 AS Rank
      FROM SitePlotLine_Join AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
           JOIN
           UnitConversion_Use AS d ON b.HeightUOM = d.Units
     WHERE Coalesce(Species, Height) IS NOT NULL
    UNION ALL
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           PointNbr,
           CASE WHEN Lower4 IN ('None', '') THEN NULL ELSE Lower4 END AS Species,
           ChkBoxLower4 AS ChkBox,
           CASE WHEN (HeightLower4 GLOB '*[A-z]*' OR 
                      HeightLower4 = '') THEN NULL ELSE (HeightLower4 * ConvertFactor) END AS Height,
           'Lower' AS Category,
           4 AS Rank
      FROM SitePlotLine_Join AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
           JOIN
           UnitConversion_Use AS d ON b.HeightUOM = d.Units
     WHERE Coalesce(Species, Height) IS NOT NULL
    UNION ALL
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           PointNbr,
           CASE WHEN Lower5 IN ('None', '') THEN NULL ELSE Lower5 END AS Species,
           ChkBoxLower5 AS ChkBox,
           CASE WHEN (HeightLower5 GLOB '*[A-z]*' OR 
                      HeightLower5 = '') THEN NULL ELSE (HeightLower5 * ConvertFactor) END AS Height,
           'Lower' AS Category,
           5 AS Rank
      FROM SitePlotLine_Join AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
           JOIN
           UnitConversion_Use AS d ON b.HeightUOM = d.Units
     WHERE Coalesce(Species, Height) IS NOT NULL
    UNION ALL
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           PointNbr,
           CASE WHEN Lower6 IN ('None', '') THEN NULL ELSE Lower6 END AS Species,
           ChkBoxLower6 AS ChkBox,
           CASE WHEN (HeightLower6 GLOB '*[A-z]*' OR 
                      HeightLower6 = '') THEN NULL ELSE (HeightLower6 * ConvertFactor) END AS Height,
           'Lower' AS Category,
           6 AS Rank
      FROM SitePlotLine_Join AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
           JOIN
           UnitConversion_Use AS d ON b.HeightUOM = d.Units
     WHERE Coalesce(Species, Height) IS NOT NULL
    UNION ALL
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           PointNbr,
           CASE WHEN Lower7 IN ('None', '') THEN NULL ELSE Lower7 END AS Species,
           ChkBoxLower7 AS ChkBox,
           CASE WHEN (HeightLower7 GLOB '*[A-z]*' OR 
                      HeightLower7 = '') THEN NULL ELSE (HeightLower7 * ConvertFactor) END AS Height,
           'Lower' AS Category,
           7 AS Rank
      FROM SitePlotLine_Join AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
           JOIN
           UnitConversion_Use AS d ON b.HeightUOM = d.Units
     WHERE Coalesce(Species, Height) IS NOT NULL
    UNION ALL
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           PointNbr,
           CASE WHEN SoilSurface IN ('None', '') THEN NULL ELSE SoilSurface END AS Species,
           ChkBoxSoil AS ChkBox,
           CASE WHEN (HeightSurface GLOB '*[A-z]*' OR 
                      HeightSurface = '') THEN NULL ELSE (HeightSurface * ConvertFactor) END AS Height,
           'Surface' AS Category,
           8 AS Rank
      FROM SitePlotLine_Join AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
           JOIN
           UnitConversion_Use AS d ON b.HeightUOM = d.Units
     WHERE Coalesce(Species, Height) IS NOT NULL
    UNION ALL
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           PointNbr,
           CASE WHEN SpeciesWoody IN ('None', '') THEN NULL ELSE SpeciesWoody END AS Species,
           NULL AS ChkBox,
           CASE WHEN (HeightWoody GLOB '*[A-z]*' OR 
                      HeightWoody = '') THEN NULL ELSE (HeightWoody * ConvertFactor) END AS Height,
           'HeightWoody' AS Category,
           9 AS Rank
      FROM SitePlotLine_Join AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
           JOIN
           UnitConversion_Use AS d ON b.HeightUOM = d.Units
     WHERE Coalesce(Species, Height) IS NOT NULL
    UNION ALL
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           PointNbr,
           CASE WHEN SpeciesHerbaceous IN ('None', '') THEN NULL ELSE SpeciesHerbaceous END AS Species,
           NULL AS ChkBox,
           CASE WHEN (HeightHerbaceous GLOB '*[A-z]*' OR 
                      HeightHerbaceous = '') THEN NULL ELSE (HeightHerbaceous * ConvertFactor) END AS Height,
           'HeightHerbaceous' AS Category,
           10 AS Rank
      FROM SitePlotLine_Join AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
           JOIN
           UnitConversion_Use AS d ON b.HeightUOM = d.Units
     WHERE Coalesce(Species, Height) IS NOT NULL
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Rank;
			  
-- View: LPI_CanopyLayers_Point_Duration_Foliar
CREATE VIEW LPI_CanopyLayers_Point_Duration_Foliar AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           c.Tag AS Duration,
           'Cover' AS IndicatorCategory,
           'Foliar' AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Any' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           LEFT JOIN
           tblSpecies AS b ON b.SpeciesCode = a.Species
           LEFT JOIN
           CodeTags AS c ON b.Duration = c.Code
     WHERE b.SpeciesCode IS NOT NULL AND 
           c.Category = 'Duration' AND 
           c.Use = 1 AND 
           a.Category IN ('Top', 'Lower', 'Surface') 
     GROUP BY RecKey,
              PointNbr,
              c.Tag,
              Indicator
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           c.Tag AS Duration,
           'Cover' AS IndicatorCategory,
           'Foliar' AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'First' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           LEFT JOIN
           tblSpecies AS b ON b.SpeciesCode = a.Species
           LEFT JOIN
           CodeTags AS c ON b.Duration = c.Code
     WHERE b.SpeciesCode IS NOT NULL AND 
           c.Category = 'Duration' AND 
           c.Use = 1 AND 
           a.Category = 'Top'
     GROUP BY RecKey,
              PointNbr,
              c.Tag,
              Indicator
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           c.Tag AS Duration,
           'Cover' AS IndicatorCategory,
           'Foliar' AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Basal' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           LEFT JOIN
           tblSpecies AS b ON b.SpeciesCode = a.Species
           LEFT JOIN
           CodeTags AS c ON b.Duration = c.Code
     WHERE b.SpeciesCode IS NOT NULL AND 
           c.Category = 'Duration' AND 
           c.Use = 1 AND 
           a.Category = 'Surface'
     GROUP BY RecKey,
              PointNbr,
              c.Tag,
              Indicator
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           c.Tag AS Duration,
           'Cover' AS IndicatorCategory,
           'Foliar' AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Height' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           LEFT JOIN
           tblSpecies AS b ON b.SpeciesCode = a.Species
           LEFT JOIN
           CodeTags AS c ON b.Duration = c.Code
     WHERE b.SpeciesCode IS NOT NULL AND 
           c.Category = 'Duration' AND 
           c.Use = 1 AND 
           a.Category IN ('HeightWoody', 'HeightHerbaceous') 
     GROUP BY RecKey,
              PointNbr,
              c.Tag,
              Indicator
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
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
     GROUP BY RecKey,
              PointNbr,
              Duration,
              Indicator
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Duration,
              Indicator,
              HitCategory;
			  
-- View: LPI_CanopyLayers_Point_Duration_GrowthHabit
CREATE VIEW LPI_CanopyLayers_Point_Duration_GrowthHabit AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           e.Tag AS Duration,
           'Lignification' AS IndicatorCategory,
           d.Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Any' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabit = d.Code
           LEFT JOIN
           CodeTags AS e ON b.Duration = e.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use AS f ON d.Tag = f.GHTag AND 
                                                         e.Tag = f.DurationTag
     WHERE d.Category = 'GrowthHabit' AND 
           e.Category = 'Duration' AND 
           a.Category IN ('Top', 'Lower', 'Surface') 
     GROUP BY a.RecKey,
              a.PointNbr,
              e.Tag,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           e.Tag AS Duration,
           'Lignification' AS IndicatorCategory,
           d.Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'First' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabit = d.Code
           LEFT JOIN
           CodeTags AS e ON b.Duration = e.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use AS f ON d.Tag = f.GHTag AND 
                                                         e.Tag = f.DurationTag
     WHERE d.Category = 'GrowthHabit' AND 
           e.Category = 'Duration' AND 
           a.Category = 'Top'
     GROUP BY a.RecKey,
              a.PointNbr,
              e.Tag,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           e.Tag AS Duration,
           'Lignification' AS IndicatorCategory,
           d.Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Basal' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabit = d.Code
           LEFT JOIN
           CodeTags AS e ON b.Duration = e.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use AS f ON d.Tag = f.GHTag AND 
                                                         e.Tag = f.DurationTag
     WHERE d.Category = 'GrowthHabit' AND 
           e.Category = 'Duration' AND 
           a.Category = 'Surface'
     GROUP BY a.RecKey,
              a.PointNbr,
              e.Tag,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           e.Tag AS Duration,
           'Lignification' AS IndicatorCategory,
           d.Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Height' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabit = d.Code
           LEFT JOIN
           CodeTags AS e ON b.Duration = e.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use AS f ON d.Tag = f.GHTag AND 
                                                         e.Tag = f.DurationTag
     WHERE d.Category = 'GrowthHabit' AND 
           e.Category = 'Duration' AND 
           a.Category IN ('HeightWoody', 'HeightHerbaceous') 
     GROUP BY a.RecKey,
              a.PointNbr,
              e.Tag,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'Perennial' AS Duration,
           'Lignification' AS IndicatorCategory,
           'Woody' AS Indicator,
           NULL AS ChkBox,
           Max(Height) AS Height,
           'Height' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates
     WHERE Category IN ('HeightWoody') AND 
           Species IS NULL AND 
           Height > 0
     GROUP BY RecKey,
              PointNbr,
              Indicator
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Indicator,
              Duration,
              HitCategory;
			  
-- View: LPI_CanopyLayers_Point_Duration_GrowthHabitSub
CREATE VIEW LPI_CanopyLayers_Point_Duration_GrowthHabitSub AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           e.Tag AS Duration,
           'Growth Habit' AS IndicatorCategory,
           d.Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Any' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabitSub = d.Code
           LEFT JOIN
           CodeTags AS e ON b.Duration = e.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use AS f ON d.Tag = f.GHTag AND 
                                                            e.Tag = f.DurationTag
     WHERE d.Category = 'GrowthHabitSub' AND 
           e.Category = 'Duration' AND 
           a.Category IN ('Top', 'Lower', 'Surface') 
     GROUP BY a.RecKey,
              a.PointNbr,
              e.Tag,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           e.Tag AS Duration,
           'Growth Habit' AS IndicatorCategory,
           d.Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'First' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabitSub = d.Code
           LEFT JOIN
           CodeTags AS e ON b.Duration = e.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use AS f ON d.Tag = f.GHTag AND 
                                                            e.Tag = f.DurationTag
     WHERE d.Category = 'GrowthHabitSub' AND 
           e.Category = 'Duration' AND 
           a.Category = 'Top'
     GROUP BY a.RecKey,
              a.PointNbr,
              e.Tag,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           e.Tag AS Duration,
           'Growth Habit' AS IndicatorCategory,
           d.Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Basal' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabitSub = d.Code
           LEFT JOIN
           CodeTags AS e ON b.Duration = e.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use AS f ON d.Tag = f.GHTag AND 
                                                            e.Tag = f.DurationTag
     WHERE d.Category = 'GrowthHabitSub' AND 
           e.Category = 'Duration' AND 
           a.Category = 'Surface'
     GROUP BY a.RecKey,
              a.PointNbr,
              e.Tag,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           e.Tag AS Duration,
           'Growth Habit' AS IndicatorCategory,
           d.Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Height' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabitSub = d.Code
           LEFT JOIN
           CodeTags AS e ON b.Duration = e.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use AS f ON d.Tag = f.GHTag AND 
                                                            e.Tag = f.DurationTag
     WHERE d.Category = 'GrowthHabitSub' AND 
           e.Category = 'Duration' AND 
           a.Category IN ('HeightWoody', 'HeightHerbaceous') 
     GROUP BY a.RecKey,
              a.PointNbr,
              e.Tag,
              d.Tag
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Indicator,
              Duration,
              HitCategory;
			  
-- View: LPI_CanopyLayers_Point_Duration_SpeciesTags
CREATE VIEW LPI_CanopyLayers_Point_Duration_SpeciesTags AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           d.Tag AS Duration,
           'Species Tag' AS IndicatorCategory,
           c.Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Any' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           JOIN
           SpeciesTags AS c ON a.Species = c.SpeciesCode
           JOIN
           CodeTags AS d ON b.Duration = d.Code
           JOIN
           Duration_SpeciesTags_Combinations_Use AS e ON d.Tag = e.DurationTag AND 
                                                         c.Tag = e.SpeciesTag
     WHERE a.Category IN ('Top', 'Lower', 'Surface') 
     GROUP BY RecKey,
              PointNbr,
              d.Tag,
              c.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           d.Tag AS Duration,
           'Species Tag' AS IndicatorCategory,
           c.Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'First' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           JOIN
           SpeciesTags AS c ON a.Species = c.SpeciesCode
           JOIN
           CodeTags AS d ON b.Duration = d.Code
           JOIN
           Duration_SpeciesTags_Combinations_Use AS e ON d.Tag = e.DurationTag AND 
                                                         c.Tag = e.SpeciesTag
     WHERE a.Category = 'Top'
     GROUP BY RecKey,
              PointNbr,
              d.Tag,
              c.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           d.Tag AS Duration,
           'Species Tag' AS IndicatorCategory,
           c.Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Basal' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           JOIN
           SpeciesTags AS c ON a.Species = c.SpeciesCode
           JOIN
           CodeTags AS d ON b.Duration = d.Code
           JOIN
           Duration_SpeciesTags_Combinations_Use AS e ON d.Tag = e.DurationTag AND 
                                                         c.Tag = e.SpeciesTag
     WHERE a.Category = 'Surface'
     GROUP BY RecKey,
              PointNbr,
              d.Tag,
              c.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           d.Tag AS Duration,
           'Species Tag' AS IndicatorCategory,
           c.Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Height' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           JOIN
           SpeciesTags AS c ON a.Species = c.SpeciesCode
           JOIN
           CodeTags AS d ON b.Duration = d.Code
           JOIN
           Duration_SpeciesTags_Combinations_Use AS e ON d.Tag = e.DurationTag AND 
                                                         c.Tag = e.SpeciesTag
     WHERE a.Category IN ('HeightWoody', 'HeightHerbaceous') 
     GROUP BY RecKey,
              PointNbr,
              d.Tag,
              c.Tag
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Indicator,
              Duration,
              HitCategory;
			  
-- View: LPI_CanopyLayers_Point_Foliar
CREATE VIEW LPI_CanopyLayers_Point_Foliar AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Cover' AS IndicatorCategory,
           'Foliar' AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Any' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           LEFT JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
     WHERE Category IN ('Top', 'Lower', 'Surface') AND 
           b.SpeciesCode IS NOT NULL
     GROUP BY RecKey,
              PointNbr,
              Indicator,
              HitCategory
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Cover' AS IndicatorCategory,
           'Foliar' AS Indicator,
           ChkBox,
           Height,
           'First' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           LEFT JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
     WHERE Category = 'Top' AND 
           b.SpeciesCode IS NOT NULL
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Cover' AS IndicatorCategory,
           'Foliar' AS Indicator,
           ChkBox,
           Height,
           'Basal' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           LEFT JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
     WHERE Category = 'Surface' AND 
           b.SpeciesCode IS NOT NULL
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Cover' AS IndicatorCategory,
           'Foliar' AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Height' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           LEFT JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
     WHERE Category IN ('HeightWoody', 'HeightHerbaceous') 
     GROUP BY RecKey,
              PointNbr,
              Indicator,
              HitCategory
    HAVING Height <> 0
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Indicator,
              HitCategory;
			  
-- View: LPI_CanopyLayers_Point_GroundCover
CREATE VIEW LPI_CanopyLayers_Point_GroundCover AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'NA' AS Duration,
           'Cover' AS IndicatorCategory,
           'Ground Cover' AS Indicator,
           NULL AS ChkBox,
           NULL AS Height,
           'Any' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           LEFT JOIN
           CodeTags AS b ON a.Species = b.Code
           LEFT JOIN
           tblSpecies AS c ON a.Species = c.SpeciesCode
     WHERE a.Category IN ('Lower', 'Surface') AND 
           (b.Category = 'Ground Cover' OR 
            (c.SpeciesCode IS NOT NULL AND 
             a.Category = 'Surface') ) AND 
           b.Use = 1
     GROUP BY RecKey,
              PointNbr,
              Indicator
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr;
			  
-- View: LPI_CanopyLayers_Point_GrowthHabit
CREATE VIEW LPI_CanopyLayers_Point_GrowthHabit AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Lignification' AS IndicatorCategory,
           Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Any' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabit = d.Code
           LEFT JOIN
           Duration_GrowthHabit_Combinations_Use_Count AS e ON e.GHTag = d.Tag
     WHERE d.Category = 'GrowthHabit' AND 
           d.Use = 1 AND 
           e.DurationCount > 1 AND 
           a.Category IN ('Top', 'Lower', 'Surface') 
     GROUP BY a.RecKey,
              a.PointNbr,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Lignification' AS IndicatorCategory,
           Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'First' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabit = d.Code
           LEFT JOIN
           Duration_GrowthHabit_Combinations_Use_Count AS e ON e.GHTag = d.Tag
     WHERE d.Category = 'GrowthHabit' AND 
           d.Use = 1 AND 
           e.DurationCount > 1 AND 
           a.Category = 'Top'
     GROUP BY a.RecKey,
              a.PointNbr,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Lignification' AS IndicatorCategory,
           Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Basal' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabit = d.Code
           LEFT JOIN
           Duration_GrowthHabit_Combinations_Use_Count AS e ON e.GHTag = d.Tag
     WHERE d.Category = 'GrowthHabit' AND 
           d.Use = 1 AND 
           e.DurationCount > 1 AND 
           a.Category = 'Surface'
     GROUP BY a.RecKey,
              a.PointNbr,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Lignification' AS IndicatorCategory,
           Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Height' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabit = d.Code
           LEFT JOIN
           Duration_GrowthHabit_Combinations_Use_Count AS e ON e.GHTag = d.Tag
     WHERE d.Category = 'GrowthHabit' AND 
           d.Use = 1 AND 
           e.DurationCount > 1 AND 
           a.Category IN ('HeightWoody', 'HeightHerbaceous') 
     GROUP BY a.RecKey,
              a.PointNbr,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Lignification' AS IndicatorCategory,
           'Non-woody' AS Indicator,
           NULL AS ChkBox,
           Max(Height) AS Height,
           'Height' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates
     WHERE Category IN ('HeightHerbaceous') AND 
           Species IS NULL AND 
           Height > 0
     GROUP BY RecKey,
              PointNbr,
              Indicator
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Indicator,
              HitCategory;
			  
-- View: LPI_CanopyLayers_Point_GrowthHabitSub
CREATE VIEW LPI_CanopyLayers_Point_GrowthHabitSub AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Growth Habit' AS IndicatorCategory,
           Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Any' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabitSub = d.Code
           LEFT JOIN
           Duration_GrowthHabitSub_Combinations_Use_Count AS e ON e.GHTag = d.Tag
     WHERE d.Category = 'GrowthHabitSub' AND 
           d.Use = 1 AND 
           e.GHCount > 1 AND 
           a.Category IN ('Top', 'Lower', 'Surface') 
     GROUP BY a.RecKey,
              a.PointNbr,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Growth Habit' AS IndicatorCategory,
           Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'First' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabitSub = d.Code
           LEFT JOIN
           Duration_GrowthHabitSub_Combinations_Use_Count AS e ON e.GHTag = d.Tag
     WHERE a.Category = 'Top' AND 
           d.Category = 'GrowthHabitSub' AND 
           d.Use = 1 AND 
           e.GHCount > 1
     GROUP BY a.RecKey,
              a.PointNbr,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Growth Habit' AS IndicatorCategory,
           Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Basal' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabitSub = d.Code
           LEFT JOIN
           Duration_GrowthHabitSub_Combinations_Use_Count AS e ON e.GHTag = d.Tag
     WHERE a.Category = 'Surface' AND 
           d.Category = 'GrowthHabitSub' AND 
           d.Use = 1 AND 
           e.GHCount > 1
     GROUP BY a.RecKey,
              a.PointNbr,
              d.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Growth Habit' AS IndicatorCategory,
           Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Height' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           LEFT JOIN
           CodeTags AS d ON c.GrowthHabitSub = d.Code
           LEFT JOIN
           Duration_GrowthHabitSub_Combinations_Use_Count AS e ON e.GHTag = d.Tag
     WHERE d.Category = 'GrowthHabitSub' AND 
           d.Use = 1 AND 
           e.GHCount > 1 AND 
           a.Category IN ('HeightWoody', 'HeightHerbaceous') 
     GROUP BY a.RecKey,
              a.PointNbr,
              d.Tag
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Indicator,
              HitCategory;
			  
-- View: LPI_CanopyLayers_Point_Litter
CREATE VIEW LPI_CanopyLayers_Point_Litter AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'NA' AS Duration,
           'Litter' AS IndicatorCategory,
           Tag AS Indicator,
           NULL AS ChkBox,
           NULL AS Height,
           'Any' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           LEFT JOIN
           CodeTags AS b ON a.Species = b.Code
     WHERE a.Category = 'Lower' AND 
           b.Category = 'Litter' AND 
           b.Use = 1
     GROUP BY a.RecKey,
              a.PointNbr,
              b.Tag
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Tag;
			  
-- View: LPI_CanopyLayers_Point_SoilSurface
CREATE VIEW LPI_CanopyLayers_Point_SoilSurface AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'NA' AS Duration,
           'Soil Surface' AS IndicatorCategory,
           CASE WHEN b.Tag IS NULL THEN 'Basal' ELSE b.Tag END AS Indicator,
           NULL AS ChkBox,
           NULL AS Height,
           'Any' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           LEFT JOIN
           CodeTags AS b ON a.Species = b.Code
           LEFT JOIN
           tblSpecies AS c ON a.Species = c.SpeciesCode
     WHERE a.Category = 'Surface' AND 
           (b.Category = 'Soil Surface' OR 
            c.SpeciesCode IS NOT NULL) AND 
           b.Use = 1
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Indicator;
			  
-- View: LPI_CanopyLayers_Point_SoilSurface_CvrCat
CREATE VIEW LPI_CanopyLayers_Point_SoilSurface_CvrCat AS
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           a.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           a.FormDate,
           a.PointNbr,
           a.Duration,
           'Soil Surface' AS IndicatorCategory,
           a.Indicator,
           a.ChkBox,
           a.Height,
           CvrCat AS HitCategory
      FROM LPI_CanopyLayers_Point_SoilSurface AS a
           LEFT JOIN
           LPI_CanopyDefinitions AS b ON a.RecKey = b.RecKey AND 
                                         a.PointNbr = b.PointNbr
     WHERE a.Indicator <> 'Basal'
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID,
              a.FormDate,
              a.PointNbr;
			  
-- View: LPI_CanopyLayers_Point_Species
CREATE VIEW LPI_CanopyLayers_Point_Species AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           CASE WHEN Duration IS NULL THEN 'NA' ELSE Duration END AS Duration,
           'Species' AS IndicatorCategory,
           CASE WHEN b.CodeType = 'generic' THEN 'Unidentified ' || b.ScientificName || ' (' || b.SpeciesCode || ')' WHEN (b.ScientificName IS NULL OR 
                                                                                                                           b.ScientificName = '') AND 
                                                                                                                          (b.CommonName IS NULL OR 
                                                                                                                           b.CommonName = '') THEN b.SpeciesCode WHEN (b.ScientificName IS NULL OR 
                                                                                                                                                                       b.ScientificName = '') THEN b.CommonName WHEN b.CodeType = 'family' THEN b.Family || ' genus sp.' WHEN b.CodeType = 'genus' THEN b.ScientificName || ' sp.' ELSE b.ScientificName END AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Any' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
     WHERE a.Category IN ('Top', 'Lower', 'Surface') AND 
           a.Species <> 'None' AND 
           a.Species IS NOT NULL
     GROUP BY RecKey,
              PointNbr,
              Species
    HAVING Indicator IS NOT NULL
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           CASE WHEN Duration IS NULL THEN 'NA' ELSE Duration END AS Duration,
           'Species' AS IndicatorCategory,
           CASE WHEN b.CodeType = 'generic' THEN 'Unidentified ' || b.ScientificName || ' (' || b.SpeciesCode || ')' WHEN (b.ScientificName IS NULL OR 
                                                                                                                           b.ScientificName = '') AND 
                                                                                                                          (b.CommonName IS NULL OR 
                                                                                                                           b.CommonName = '') THEN b.SpeciesCode WHEN (b.ScientificName IS NULL OR 
                                                                                                                                                                       b.ScientificName = '') THEN b.CommonName WHEN b.CodeType = 'family' THEN b.Family || ' genus sp.' WHEN b.CodeType = 'genus' THEN b.ScientificName || ' sp.' ELSE b.ScientificName END AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'First' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
     WHERE Category = 'Top' AND 
           a.Species <> 'None' AND 
           a.Species IS NOT NULL
     GROUP BY RecKey,
              PointNbr,
              Species
    HAVING Indicator IS NOT NULL
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           CASE WHEN Duration IS NULL THEN 'NA' ELSE Duration END AS Duration,
           'Species' AS IndicatorCategory,
           CASE WHEN b.CodeType = 'generic' THEN 'Unidentified ' || b.ScientificName || ' (' || b.SpeciesCode || ')' WHEN (b.ScientificName IS NULL OR 
                                                                                                                           b.ScientificName = '') AND 
                                                                                                                          (b.CommonName IS NULL OR 
                                                                                                                           b.CommonName = '') THEN b.SpeciesCode WHEN (b.ScientificName IS NULL OR 
                                                                                                                                                                       b.ScientificName = '') THEN b.CommonName WHEN b.CodeType = 'family' THEN b.Family || ' genus sp.' WHEN b.CodeType = 'genus' THEN b.ScientificName || ' sp.' ELSE b.ScientificName END AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Basal' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
     WHERE Category = 'Surface' AND 
           a.Species <> 'None' AND 
           a.Species IS NOT NULL
     GROUP BY RecKey,
              PointNbr,
              Species
    HAVING Indicator IS NOT NULL
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           CASE WHEN Duration IS NULL THEN 'NA' ELSE Duration END AS Duration,
           'Species' AS IndicatorCategory,
           CASE WHEN b.CodeType = 'generic' THEN 'Unidentified ' || b.ScientificName || ' (' || b.SpeciesCode || ')' WHEN (b.ScientificName IS NULL OR 
                                                                                                                           b.ScientificName = '') AND 
                                                                                                                          (b.CommonName IS NULL OR 
                                                                                                                           b.CommonName = '') THEN b.SpeciesCode WHEN (b.ScientificName IS NULL OR 
                                                                                                                                                                       b.ScientificName = '') THEN b.CommonName WHEN b.CodeType = 'family' THEN b.Family || ' genus sp.' WHEN b.CodeType = 'genus' THEN b.ScientificName || ' sp.' ELSE b.ScientificName END AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Height' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
     WHERE a.Category IN ('HeightHerbaceous', 'HeightWoody') AND 
           a.Species <> 'None' AND 
           a.Species IS NOT NULL
     GROUP BY RecKey,
              PointNbr,
              Species
    HAVING Indicator IS NOT NULL
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Indicator,
              HitCategory;
			  
-- View: LPI_CanopyLayers_Point_SpeciesTags
CREATE VIEW LPI_CanopyLayers_Point_SpeciesTags AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Species Tag' AS IndicatorCategory,
           Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Any' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           SpeciesTags AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           Duration_SpeciesTags_Combinations_Use_Count AS c ON b.Tag = c.SpeciesTag
     WHERE a.Category IN ('Top', 'Lower', 'Surface') AND 
           c.DurationCount > 1
     GROUP BY a.RecKey,
              a.PointNbr,
              b.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Species Tag' AS IndicatorCategory,
           Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'First' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           SpeciesTags AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           Duration_SpeciesTags_Combinations_Use_Count AS c ON b.Tag = c.SpeciesTag
     WHERE a.Category = 'Top' AND 
           c.DurationCount > 1
     GROUP BY a.RecKey,
              a.PointNbr,
              b.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Species Tag' AS IndicatorCategory,
           Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Basal' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           SpeciesTags AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           Duration_SpeciesTags_Combinations_Use_Count AS c ON b.Tag = c.SpeciesTag
     WHERE a.Category = 'Surface' AND 
           c.DurationCount > 1
     GROUP BY a.RecKey,
              a.PointNbr,
              b.Tag
    UNION ALL
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           'All' AS Duration,
           'Species Tag' AS IndicatorCategory,
           Tag AS Indicator,
           Min(ChkBox) AS ChkBox,
           Max(Height) AS Height,
           'Height' AS HitCategory
      FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
           JOIN
           SpeciesTags AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           Duration_SpeciesTags_Combinations_Use_Count AS c ON b.Tag = c.SpeciesTag
     WHERE a.Category IN ('HeightWoody', 'HeightHerbaceous') AND 
           c.DurationCount > 1
     GROUP BY a.RecKey,
              a.PointNbr,
              b.Tag
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Indicator,
              HitCategory;
			  
-- View: LPI_Line_Count
CREATE VIEW LPI_Line_Count AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           IndicatorCategory,
           Duration,
           Indicator,
           HitCategory,
           Count(PointNbr) AS PointCount,
           (Sum(CAST (ChkBox AS FLOAT) ) / Count(PointNbr) ) AS ChkPct,
           Avg(Height) AS HeightMean
      FROM LPI_Point_Indicators
     GROUP BY SiteKey,
              PlotKey,
              LineKey,
              RecKey,
              IndicatorCategory,
              Indicator,
              Duration,
              HitCategory
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              IndicatorCategory,
              Indicator,
              Duration,
              HitCategory;
			  
-- View: LPI_Line_IndicatorsCalc
CREATE VIEW LPI_Line_IndicatorsCalc AS
    SELECT a.SiteKey AS SiteKey,
           a.PlotKey AS PlotKey,
           a.LineKey AS LineKey,
           a.RecKey AS RecKey,
           a.SiteID AS SiteID,
           a.PlotID AS PlotID,
           a.LineID AS LineID,
           a.FormDate AS FormDate,
           'Line-point Intercept' AS Method,
           a.PointCount AS LineSize,
           'points' AS LineSizeUnits,
           a.Duration AS Duration,
           a.IndicatorCategory AS IndicatorCategory,
           a.Indicator AS Indicator,
           a.HitCategory AS HitCategory,
           CASE WHEN b.PointCount IS NULL THEN 0 ELSE b.PointCount END AS IndicatorSum,
           CASE WHEN b.PointCount IS NULL THEN 0 ELSE (CAST (b.PointCount AS FLOAT) / a.PointCount) END AS CoverPct,
           b.ChkPct AS ChkPct,
           b.HeightMean AS HeightMean,
           CASE WHEN (
                         SELECT Value
                           FROM Data_DBconfig
                          WHERE VariableName = 'units'
                     )
=              'metric' THEN 'cm' ELSE 'in' END AS HeightUnits
      FROM LPI_Line_IndicatorsCartesian AS a
           LEFT JOIN
           LPI_Line_Count AS b ON a.RecKey = b.RecKey AND 
                                  a.Duration = b.Duration AND 
                                  a.IndicatorCategory = b.IndicatorCategory AND 
                                  a.Indicator = b.Indicator AND 
                                  a.HitCategory = b.HitCategory
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              IndicatorCategory,
              Indicator,
              Duration,
              HitCategory;
			  
-- View: LPI_Line_IndicatorsCartesian
CREATE VIEW LPI_Line_IndicatorsCartesian AS
    SELECT a.*,
           b.Tag AS Duration,
           'Cover' AS IndicatorCategory,
           'Foliar' AS Indicator,
           c.HitCategory AS HitCategory
      FROM LPI_Line_PointCount AS a,
           CodeTags_Grouped AS b,
           HitCategories AS c
     WHERE b.Category = 'Duration' AND 
           c.Type = 'Foliar'
    UNION ALL
    SELECT a.*,
           b.DurationTag AS Duration,
           'Lignification' AS IndicatorCategory,
           b.GHTag AS Indicator,
           c.HitCategory AS HitCategory
      FROM LPI_Line_PointCount AS a,
           Duration_GrowthHabit_Combinations_Use AS b,
           HitCategories AS c
     WHERE c.Type = 'Foliar'
    UNION ALL
    SELECT a.*,
           b.DurationTag AS Duration,
           'Growth Habit' AS IndicatorCategory,
           b.GHTag AS Indicator,
           c.HitCategory AS HitCategory
      FROM LPI_Line_PointCount AS a,
           Duration_GrowthHabitSub_Combinations_Use AS b,
           HitCategories AS c
     WHERE c.Type = 'Foliar'
    UNION ALL
    SELECT a.*,
           b.DurationTag AS Duration,
           'Species Tag' AS IndicatorCategory,
           b.SpeciesTag AS Indicator,
           c.HitCategory AS HitCategory
      FROM LPI_Line_PointCount AS a,
           Duration_SpeciesTags_Combinations_Use AS b,
           HitCategories AS c
     WHERE c.Type = 'Foliar'
    UNION ALL
    SELECT a.*,
           'All' AS Duration,
           'Cover' AS IndicatorCategory,
           'Foliar' AS Indicator,
           b.HitCategory AS HitCategory
      FROM LPI_Line_PointCount AS a,
           HitCategories AS b
     WHERE b.Type = 'Foliar'
    UNION ALL
    SELECT a.*,
           'NA' AS Duration,
           'Cover' AS IndicatorCategory,
           'Ground Cover' AS Indicator,
           'Any' AS HitCategory
      FROM LPI_Line_PointCount AS a
    UNION ALL
    SELECT a.*,
           'All' AS Duration,
           'Lignification' AS IndicatorCategory,
           b.Tag AS Indicator,
           c.HitCategory AS HitCategory
      FROM LPI_Line_PointCount AS a,
           CodeTags_Grouped AS b,
           HitCategories AS c
           JOIN
           Duration_GrowthHabit_Combinations_Use_Count AS d ON b.Tag = d.GHTag
     WHERE b.Category = 'GrowthHabit' AND 
           c.Type = 'Foliar' AND 
           d.DurationCount > 1
    UNION ALL
    SELECT a.*,
           'All' AS Duration,
           'Growth Habit' AS IndicatorCategory,
           b.Tag AS Indicator,
           c.HitCategory AS HitCategory
      FROM LPI_Line_PointCount AS a,
           CodeTags_Grouped AS b,
           HitCategories AS c
           JOIN
           Duration_GrowthHabitSub_Combinations_Use_Count AS d ON b.Tag = d.GHTag
     WHERE b.Category = 'GrowthHabitSub' AND 
           c.Type = 'Foliar' AND 
           d.GHCount > 1
    UNION ALL
    SELECT a.*,
           'NA' AS Duration,
           'Litter' AS IndicatorCategory,
           b.Tag AS Indicator,
           'Any' AS HitCategory
      FROM LPI_Line_PointCount AS a,
           CodeTags_Grouped AS b
     WHERE b.Category = 'Litter'
    UNION ALL
    SELECT a.*,
           'NA' AS Duration,
           'Soil Surface' AS IndicatorCategory,
           b.Tag AS Indicator,
           c.HitCategory AS HitCategory
      FROM LPI_Line_PointCount AS a,
           HitCategories AS c,
           CodeTags_Grouped AS b
     WHERE b.Category = 'Soil Surface' AND 
           b.Tag <> 'Basal' AND 
           c.Type = 'Surface'
    UNION ALL
    SELECT a.*,
           'NA' AS Duration,
           'Soil Surface' AS IndicatorCategory,
           b.Tag AS Indicator,
           'Any' AS HitCategory
      FROM LPI_Line_PointCount AS a,
           CodeTags_Grouped AS b
     WHERE b.Category = 'Soil Surface'
    UNION ALL
    SELECT a.*,
           c.Duration,
           'Species' AS IndicatorCategory,
           c.Indicator,
           b.HitCategory AS HitCategory
      FROM LPI_Line_PointCount AS a,
           HitCategories AS b
           LEFT JOIN
           LPI_Plot_Species AS c ON a.PlotKey = c.PlotKey
     WHERE b.Type = 'Foliar'
    UNION ALL
    SELECT a.*,
           'All' AS Duration,
           'Species Tag' AS IndicatorCategory,
           b.SpeciesTag AS Indicator,
           c.HitCategory AS HitCategory
      FROM LPI_Line_PointCount AS a,
           Duration_SpeciesTags_Combinations_Use_Count AS b,
           HitCategories AS c
     WHERE c.Type = 'Foliar' AND 
           b.DurationCount > 1
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              IndicatorCategory,
              Indicator,
              Duration,
              HitCategory;
			  
-- View: LPI_Line_PointCount
CREATE VIEW LPI_Line_PointCount AS
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           b.RecKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           Count(c.PointNbr) AS PointCount
      FROM SitePlotLine_Join AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
     WHERE c.SoilSurface IS NOT NULL
     GROUP BY a.SiteID,
              a.PlotID,
              a.LineID,
              b.RecKey;
			  
-- View: LPI_Plot_Species
CREATE VIEW LPI_Plot_Species AS
    SELECT SiteKey,
           PlotKey,
           SiteID,
           PlotID,
           Duration,
           Indicator
      FROM LPI_CanopyLayers_Point_Species
     WHERE HitCategory = 'Any'
     GROUP BY PlotKey,
              Duration,
              Indicator
     ORDER BY SiteID,
              PlotID,
              Indicator;
			  
-- View: LPI_Point_Indicators
CREATE VIEW LPI_Point_Indicators AS
    SELECT *
      FROM LPI_CanopyLayers_Point_Duration_Foliar
    UNION ALL
    SELECT *
      FROM LPI_CanopyLayers_Point_Duration_GrowthHabit
    UNION ALL
    SELECT *
      FROM LPI_CanopyLayers_Point_Duration_GrowthHabitSub
    UNION ALL
    SELECT *
      FROM LPI_CanopyLayers_Point_Duration_SpeciesTags
    UNION ALL
    SELECT *
      FROM LPI_CanopyLayers_Point_Foliar
    UNION ALL
    SELECT *
      FROM LPI_CanopyLayers_Point_GroundCover
    UNION ALL
    SELECT *
      FROM LPI_CanopyLayers_Point_GrowthHabit
    UNION ALL
    SELECT *
      FROM LPI_CanopyLayers_Point_GrowthHabitSub
    UNION ALL
    SELECT *
      FROM LPI_CanopyLayers_Point_Litter
    UNION ALL
    SELECT *
      FROM LPI_CanopyLayers_Point_SoilSurface
    UNION ALL
    SELECT *
      FROM LPI_CanopyLayers_Point_SoilSurface_CvrCat
    UNION ALL
    SELECT *
      FROM LPI_CanopyLayers_Point_Species
    UNION ALL
    SELECT *
      FROM LPI_CanopyLayers_Point_SpeciesTags
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              PointNbr,
              Indicator,
              HitCategory;
			  
-- View: NonSpeciesIndicators
CREATE VIEW NonSpeciesIndicators AS
    SELECT 'All' AS Duration,
           'Growth Habit' AS IndicatorCategory,
           GHTag AS Indicator
      FROM Duration_GrowthHabit_Combinations_Use_Count
     WHERE DurationCount > 1
    UNION ALL
    SELECT 'All' AS Duration,
           'Growth Habit' AS IndicatorCategory,
           GHTag AS Indicator
      FROM Duration_GrowthHabitSub_Combinations_Use_Count
     WHERE GHCount > 1
    UNION ALL
    SELECT 'All' AS Duration,
           Code AS IndicatorCategory,
           Tag AS Indicator
      FROM CodeTags
     WHERE Code = 'Foliar'
    UNION ALL
    SELECT 'All' AS Duration,
           'Species Tag' AS IndicatorCategory,
           SpeciesTag AS Indicator
      FROM Duration_SpeciesTags_Combinations_Use_Count
     WHERE DurationCount > 1
    UNION ALL
    SELECT DurationTag AS Duration,
           'Growth Habit' AS IndicatorCategory,
           GHTag AS Indicator
      FROM Duration_GrowthHabit_Combinations_Use
    UNION ALL
    SELECT DurationTag AS Duration,
           'Growth Habit' AS IndicatorCategory,
           GHTag AS Indicator
      FROM Duration_GrowthHabitSub_Combinations_Use
    UNION ALL
    SELECT a.Tag AS Duration,
           'Foliar' AS IndicatorCategory,
           b.Tag AS Indicator
      FROM CodeTags AS a,
           CodeTags AS b
     WHERE a.Category = 'Duration' AND 
           b.Category = 'Foliar' AND 
           a.Use = 1
     GROUP BY Duration,
              IndicatorCategory,
              Indicator
    UNION ALL
    SELECT 'NA' AS Duration,
           Category AS IndicatorCategory,
           Code AS Indicator
      FROM CodeTags
     WHERE IndicatorCategory = 'Gap'
    UNION ALL
    SELECT 'NA' AS Duration,
           a.Category AS IndicatorCategory,
           CASE WHEN b.EndLimit IS NULL THEN (a.Code || ' (' || b.StartLimit || '+)') ELSE (a.Code || ' (' || b.StartLimit || '-' || b.EndLimit || ')') END AS Indicator
      FROM CodeTags AS a,
           LI_SizeClasses AS b
     WHERE IndicatorCategory = 'Gap'
    UNION ALL
    SELECT DurationTag AS Duration,
           'Species Tag' AS IndicatorCategory,
           SpeciesTag AS Indicator
      FROM Duration_SpeciesTags_Combinations_Use
     ORDER BY IndicatorCategory,
              Indicator,
              Duration;
			  
-- View: PD_ClassLabels
CREATE VIEW PD_ClassLabels AS
    SELECT PlotKey,
           1 AS ClassNumber,
           PlantDenClass1 AS Label
      FROM tblPlotFormDefaults
     WHERE PlotKey != '999999999'
    UNION
    SELECT PlotKey,
           2 AS ClassNumber,
           PlantDenClass2 AS Label
      FROM tblPlotFormDefaults
     WHERE PlotKey != '999999999'
    UNION
    SELECT PlotKey,
           3 AS ClassNumber,
           PlantDenClass3 AS Label
      FROM tblPlotFormDefaults
     WHERE PlotKey != '999999999'
    UNION
    SELECT PlotKey,
           4 AS ClassNumber,
           PlantDenClass4 AS Label
      FROM tblPlotFormDefaults
     WHERE PlotKey != '999999999'
    UNION
    SELECT PlotKey,
           5 AS ClassNumber,
           PlantDenClass5 AS Label
      FROM tblPlotFormDefaults
     WHERE PlotKey != '999999999'
    UNION
    SELECT PlotKey,
           6 AS ClassNumber,
           PlantDenClass6 AS Label
      FROM tblPlotFormDefaults
     WHERE PlotKey != '999999999'
    UNION
    SELECT PlotKey,
           7 AS ClassNumber,
           PlantDenClass7 AS Label
      FROM tblPlotFormDefaults
     WHERE PlotKey != '999999999'
    UNION
    SELECT PlotKey,
           8 AS ClassNumber,
           PlantDenClass8 AS Label
      FROM tblPlotFormDefaults
     WHERE PlotKey != '999999999'
    UNION
    SELECT PlotKey,
           9 AS ClassNumber,
           PlantDenClass9 AS Label
      FROM tblPlotFormDefaults
     WHERE PlotKey != '999999999';

	 
-- View: PD_Detail_Long
CREATE VIEW PD_Detail_Long AS
    SELECT RecKey,
           Quadrat,
           CASE WHEN SubQuadSizeUOM = 1 THEN SubQuadSize ELSE SubQuadSize * 0.092903 END AS SubQuadSize_sqm,
           SpeciesCode,
           1 AS ClassNumber,
           Class1total AS Total
      FROM tblPlantDenDetail
    UNION
    SELECT RecKey,
           Quadrat,
           CASE WHEN SubQuadSizeUOM = 1 THEN SubQuadSize ELSE SubQuadSize * 0.092903 END AS SubQuadSize_sqm,
           SpeciesCode,
           2 AS ClassNumber,
           Class2total AS Total
      FROM tblPlantDenDetail
    UNION
    SELECT RecKey,
           Quadrat,
           CASE WHEN SubQuadSizeUOM = 1 THEN SubQuadSize ELSE SubQuadSize * 0.092903 END AS SubQuadSize_sqm,
           SpeciesCode,
           3 AS ClassNumber,
           Class3total AS Total
      FROM tblPlantDenDetail
    UNION
    SELECT RecKey,
           Quadrat,
           CASE WHEN SubQuadSizeUOM = 1 THEN SubQuadSize ELSE SubQuadSize * 0.092903 END AS SubQuadSize_sqm,
           SpeciesCode,
           4 AS ClassNumbe,
           Class4total AS Totalr
      FROM tblPlantDenDetail
    UNION
    SELECT RecKey,
           Quadrat,
           CASE WHEN SubQuadSizeUOM = 1 THEN SubQuadSize ELSE SubQuadSize * 0.092903 END AS SubQuadSize_sqm,
           SpeciesCode,
           5 AS ClassNumber,
           Class5total AS Total
      FROM tblPlantDenDetail
    UNION
    SELECT RecKey,
           Quadrat,
           CASE WHEN SubQuadSizeUOM = 1 THEN SubQuadSize ELSE SubQuadSize * 0.092903 END AS SubQuadSize_sqm,
           SpeciesCode,
           6 AS ClassNumber,
           Class6total AS Total
      FROM tblPlantDenDetail
    UNION
    SELECT RecKey,
           Quadrat,
           CASE WHEN SubQuadSizeUOM = 1 THEN SubQuadSize ELSE SubQuadSize * 0.092903 END AS SubQuadSize_sqm,
           SpeciesCode,
           7 AS ClassNumber,
           Class7total AS Total
      FROM tblPlantDenDetail
    UNION
    SELECT RecKey,
           Quadrat,
           CASE WHEN SubQuadSizeUOM = 1 THEN SubQuadSize ELSE SubQuadSize * 0.092903 END AS SubQuadSize_sqm,
           SpeciesCode,
           8 AS ClassNumber,
           Class8total AS Total
      FROM tblPlantDenDetail
    UNION
    SELECT RecKey,
           Quadrat,
           CASE WHEN SubQuadSizeUOM = 1 THEN SubQuadSize ELSE SubQuadSize * 0.092903 END AS SubQuadSize_sqm,
           SpeciesCode,
           9 AS ClassNumber,
           Class9total AS Total
      FROM tblPlantDenDetail
     ORDER BY RecKey,
              Quadrat,
              SpeciesCode,
              ClassNumber;
			  
-- View: PD_Line
CREATE VIEW PD_Line AS
    SELECT/* Species Class */ SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           SiteName,
           PlotID,
           LineID,
           FormDate,
           numQuadrats,
           Count(Quadrat) AS QuadratCount,
           Sum(SubQuadSize_sqm) AS Area_sqm,
           "Species" AS IndicatorCategory,
           ClassNumber,
           Label AS ClassLabel,
           CASE WHEN Duration IS NULL THEN 'NA' ELSE Duration END AS Duration,
           CASE WHEN b.ScientificName IS NULL THEN (CASE WHEN b.CommonName IS NULL THEN a.SpeciesCode ELSE b.CommonName END) ELSE b.ScientificName END AS Indicator,
           Sum(Total) AS TotalSum,
           (Sum(Total) / Sum(SubQuadSize_sqm) ) / 10000 AS PlantsPerHa
      FROM PD_Raw_Final AS a
           LEFT JOIN
           tblSpecies AS b ON a.SpeciesCode = b.SpeciesCode
     GROUP BY SiteKey,
              PlotKey,
              LineKey,
              RecKey,
              Indicator,
              ClassLabel
    UNION-- Species Total
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           SiteName,
           PlotID,
           LineID,
           FormDate,
           numQuadrats,
           Count(Quadrat) / Count(ClassNumber) AS QuadratCount,
           Sum(SubQuadSize_sqm) / Count(ClassNumber) AS Area_sqm,
           "Species" AS IndicatorCategory,
           0 AS ClassNumber,
           'Total' AS ClassLabel,
           CASE WHEN Duration IS NULL THEN 'NA' ELSE Duration END AS Duration,
           CASE WHEN b.ScientificName IS NULL THEN (CASE WHEN b.CommonName IS NULL THEN a.SpeciesCode ELSE b.CommonName END) ELSE b.ScientificName END AS Indicator,
           Sum(Total) AS TotalSum,
           (Sum(Total) / (Sum(SubQuadSize_sqm) / Count(ClassNumber) ) ) / 10000 AS PlantsPerHa
      FROM PD_Raw_Final AS a
           LEFT JOIN
           tblSpecies AS b ON a.SpeciesCode = b.SpeciesCode
     GROUP BY SiteKey,
              PlotKey,
              LineKey,
              RecKey,
              Indicator,
              ClassLabel
    UNION-- Growth Habit Class
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           SiteName,
           PlotID,
           LineID,
           FormDate,
           numQuadrats,
           Count(Quadrat) / Count(a.SpeciesCode) AS QuadratCount,
           Sum(SubQuadSize_sqm) / Count(a.SpeciesCode) AS Area_sqm,
           "Growth Habit" AS IndicatorCategory,
           ClassNumber,
           Label AS ClassLabel,
           f.DurationTag AS Duration,
           f.GHTag AS Indicator,
           Sum(Total) AS TotalSum,
           (Sum(Total) / (Sum(SubQuadSize_sqm) / Count(a.SpeciesCode) ) ) / 10000 AS PlantsPerHa
      FROM PD_Raw_Final AS a
           JOIN
           tblSpecies AS b ON a.SpeciesCode = b.SpeciesCode
           JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           JOIN
           CodeTags AS d ON b.Duration = d.Code
           JOIN
           CodeTags AS e ON c.GrowthHabitSub = e.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use AS f ON d.Tag = f.DurationTag AND 
                                                            e.Tag = f.GHTag
     WHERE d.Category = 'Duration' AND 
           e.Category = 'GrowthHabitSub'
     GROUP BY SiteKey,
              PlotKey,
              LineKey,
              RecKey,
              Indicator,
              ClassLabel
    UNION-- Growth Habit Total
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           SiteName,
           PlotID,
           LineID,
           FormDate,
           numQuadrats,
           Count(Quadrat) / Count(a.SpeciesCode) AS QuadratCount,
           Sum(SubQuadSize_sqm) / Count(a.SpeciesCode) AS Area_sqm,
           "Growth Habit" AS IndicatorCategory,
           0 AS ClassNumber,
           'Total' AS ClassLabel,
           f.DurationTag AS Duration,
           f.GHTag AS Indicator,
           Sum(Total) AS TotalSum,
           (Sum(Total) / (Sum(SubQuadSize_sqm) / (Count(a.SpeciesCode) ) ) ) / 10000 AS PlantsPerHa
      FROM PD_Raw_Final AS a
           JOIN
           tblSpecies AS b ON a.SpeciesCode = b.SpeciesCode
           JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           JOIN
           CodeTags AS d ON b.Duration = d.Code
           JOIN
           CodeTags AS e ON c.GrowthHabitSub = e.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use AS f ON d.Tag = f.DurationTag AND 
                                                            e.Tag = f.GHTag
     WHERE d.Category = 'Duration' AND 
           e.Category = 'GrowthHabitSub'
     GROUP BY SiteKey,
              PlotKey,
              LineKey,
              RecKey,
              Indicator,
              ClassLabel
    UNION-- Lignification Class
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           SiteName,
           PlotID,
           LineID,
           FormDate,
           numQuadrats,
           Count(Quadrat) / Count(a.SpeciesCode) AS QuadratCount,
           Sum(SubQuadSize_sqm) / Count(a.SpeciesCode) AS Area_sqm,
           "Lignification" AS IndicatorCategory,
           ClassNumber,
           Label AS ClassLabel,
           f.DurationTag AS Duration,
           f.GHTag AS Indicator,
           Sum(Total) AS TotalSum,
           (Sum(Total) / (Sum(SubQuadSize_sqm) / Count(a.SpeciesCode) ) ) / 10000 AS PlantsPerHa
      FROM PD_Raw_Final AS a
           JOIN
           tblSpecies AS b ON a.SpeciesCode = b.SpeciesCode
           JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           JOIN
           CodeTags AS d ON b.Duration = d.Code
           JOIN
           CodeTags AS e ON c.GrowthHabit = e.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use AS f ON d.Tag = f.DurationTag AND 
                                                         e.Tag = f.GHTag
     WHERE d.Category = 'Duration' AND 
           e.Category = 'GrowthHabit'
     GROUP BY SiteKey,
              PlotKey,
              LineKey,
              RecKey,
              Indicator,
              ClassLabel
    UNION-- Lignification Total
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           SiteName,
           PlotID,
           LineID,
           FormDate,
           numQuadrats,
           Count(Quadrat) / Count(a.SpeciesCode) AS QuadratCount,
           Sum(SubQuadSize_sqm) / Count(a.SpeciesCode) AS Area_sqm,
           'Lignification' AS IndicatorCategory,
           0 AS ClassNumber,
           'Total' AS ClassLabel,
           f.DurationTag AS Duration,
           f.GHTag AS Indicator,
           Sum(Total) AS TotalSum,
           (Sum(Total) / (Sum(SubQuadSize_sqm) / Count(a.SpeciesCode) ) ) / 10000 AS PlantsPerHa
      FROM PD_Raw_Final AS a
           JOIN
           tblSpecies AS b ON a.SpeciesCode = b.SpeciesCode
           JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
           JOIN
           CodeTags AS d ON b.Duration = d.Code
           JOIN
           CodeTags AS e ON c.GrowthHabit = e.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use AS f ON d.Tag = f.DurationTag AND 
                                                         e.Tag = f.GHTag
     WHERE d.Category = 'Duration' AND 
           e.Category = 'GrowthHabit'
     GROUP BY SiteKey,
              PlotKey,
              LineKey,
              RecKey,
              Indicator,
              ClassLabel
    UNION-- Species Tag Class
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           SiteName,
           PlotID,
           LineID,
           FormDate,
           numQuadrats,
           Count(Quadrat) / Count(a.SpeciesCode) AS QuadratCount,
           Sum(SubQuadSize_sqm) / Count(a.SpeciesCode) AS Area_sqm,
           'Species Tag' AS IndicatorCategory,
           ClassNumber,
           Label AS ClassLabel,
           e.DurationTag AS Duration,
           c.Tag AS Indicator,
           Sum(Total) AS TotalSum,
           (Sum(Total) / (Sum(SubQuadSize_sqm) / Count(a.SpeciesCode) ) ) / 10000 AS PlantsPerHa
      FROM PD_Raw_Final AS a
           JOIN
           tblSpecies AS b ON a.SpeciesCode = b.SpeciesCode
           JOIN
           SpeciesTags AS c ON b.SpeciesCode = c.SpeciesCode
           JOIN
           CodeTags AS d ON b.Duration = d.Code
           JOIN
           Duration_SpeciesTags_Combinations_Use AS e ON c.Tag = e.SpeciesTag AND 
                                                         d.Tag = e.DurationTag
     WHERE d.Category = 'Duration'
     GROUP BY SiteKey,
              PlotKey,
              LineKey,
              RecKey,
              Indicator,
              ClassLabel
    UNION-- Species Tag Total
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           SiteName,
           PlotID,
           LineID,
           FormDate,
           numQuadrats,
           Count(Quadrat) / Count(a.SpeciesCode) AS QuadratCount,
           Sum(SubQuadSize_sqm) / Count(a.SpeciesCode) AS Area_sqm,
           'Species Tag' AS IndicatorCategory,
           0 AS ClassNumber,
           'Total' AS ClassLabel,
           e.DurationTag AS Duration,
           c.Tag AS Indicator,
           Sum(Total) AS TotalSum,
           (Sum(Total) / (Sum(SubQuadSize_sqm) / Count(a.SpeciesCode) ) ) / 10000 AS PlantsPerHa
      FROM PD_Raw_Final AS a
           JOIN
           tblSpecies AS b ON a.SpeciesCode = b.SpeciesCode
           JOIN
           SpeciesTags AS c ON b.SpeciesCode = c.SpeciesCode
           JOIN
           CodeTags AS d ON b.Duration = d.Code
           JOIN
           Duration_SpeciesTags_Combinations_Use AS e ON c.Tag = e.SpeciesTag AND 
                                                         d.Tag = e.DurationTag
     WHERE d.Category = 'Duration'
     GROUP BY SiteKey,
              PlotKey,
              LineKey,
              RecKey,
              Indicator,
              ClassLabel
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              IndicatorCategory,
              Indicator,
              ClassNumber;
			  
-- View: PD_Plot
CREATE VIEW PD_Plot AS
    SELECT SiteKey,
           PlotKey,
           SiteID,
           SiteName,
           PlotID,
           (
               SELECT SeasonLabel
                 FROM SeasonDefinition
                WHERE FormDate BETWEEN SeasonStart AND SeasonEnd
           )
           AS Season,
           IndicatorCategory,
           ClassNumber,
           ClassLabel,
           Duration,
           Indicator,
           Count(LineKey) AS Line_n,
           avg(PlantsPerHa) AS PlantsPerHaMean,
           stdev(PlantsPerHa) AS PlantsPerHaSD
      FROM PD_Line
     GROUP BY SiteKey,
              PlotKey,
              Season,
              IndicatorCategory,
              ClassNumber,
              ClassLabel,
              Duration,
              Indicator
     ORDER BY SiteID,
              PlotID,
              Season,
              IndicatorCategory,
              Indicator,
              ClassNumber;
			  
-- View: PD_Raw_Final
CREATE VIEW PD_Raw_Final AS
    SELECT e.SiteKey,
           d.PlotKey,
           c.LineKey,
           e.SiteID,
           e.SiteName,
           d.PlotID,
           c.LineID,
           b.FormDate,
           b.numQuadrats,
           a.RecKey,
           a.QUadrat,
           a.SubQuadSize_sqm,
           a.SpeciesCode,
           a.ClassNumber,
           f.Label,
           a.Total
      FROM PD_Detail_Long AS a
           JOIN
           tblPlantDenHeader AS b ON a.RecKey = b.RecKey
           JOIN
           tblLines AS c ON b.LineKey = c.LineKey
           JOIN
           tblPlots AS d ON c.PlotKey = d.PlotKey
           JOIN
           tblSites AS e ON d.SiteKey = e.SiteKey
           JOIN
           PD_ClassLabels AS f ON a.ClassNumber = f.ClassNumber AND 
                                  d.PlotKey = f.PlotKey
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              Quadrat,
              SubQuadSize_sqm,
              SpeciesCode,
              a.ClassNumber;
			  
-- View: PD_Tag
CREATE VIEW PD_Tag AS
    SELECT a.Tag,
           b.IndicatorCategory,
           b.ClassNumber,
           b.ClassLabel,
           b.Duration,
           b.Indicator,
           Count(b.PlotKey) AS Plot_n,
           meanw(b.PlantsPerHaMean, a.Weight) AS PlantsPerHaMean,
           stdevw(b.PlantsPerHaMean, a.Weight) AS PlantsPerHaSD
      FROM PlotTags AS a
           JOIN
           PD_Plot AS b ON a.PlotKey = b.PlotKey
     GROUP BY a.Tag,
              b.IndicatorCategory,
              b.ClassNumber,
              b.ClassLabel,
              b.Duration,
              b.Indicator
     ORDER BY a.Tag,
              b.IndicatorCategory,
              b.ClassNumber,
              b.ClassLabel,
              b.Duration,
              b.Indicator;
			  
-- View: Plot_Definition
CREATE VIEW Plot_Definition AS
    SELECT a.SiteKey,
           a.PlotKey,
           b.SiteID,
           b.SiteName,
           a.PlotID,
           a.DateModified,
           a.EstablishDate,
           a.State,
           a.County,
           a.Directions,
           a.AvgPrecip,
           a.AvgPrecipUOM,
           Trim(a.EcolSite) AS Ecolsite,
           a.Soil,
           a.ParentMaterial,
           a.Slope,
           a.Aspect,
           a.ESD_SlopeShape AS SlopeShape,
           a.LandscapeType,
           a.LandscapeTypeSecondary,
           a.MgtUnit,
           a.GPSCoordSys,
           a.Datum,
           a.Zone,
           a.Easting,
           a.Northing,
           a.Elevation,
           CASE a.ElevationType WHEN 1 THEN 'm' WHEN 2 THEN 'ft' ELSE a.ElevationType END AS ElevationType,
           a.RecentWeatherPast12,
           a.RecentWeatherPrevious12,
           a.DisturbWildfire,
           a.DisturbRodents,
           a.DisturbMammals,
           a.DisturbWater,
           a.DisturbWind,
           a.DisturbWaterSoilDep,
           a.DisturbWindSoilDep,
           a.DisturbUndgroundUtils,
           a.DisturbOverhdTransLines,
           a.DisturbOther,
           a.DisturbOtherDesc,
           a.WildlifeUse,
           a.MgtHistory,
           a.OffsiteInfluences,
           a.Comments,
           a.SpeciesList,
           a.DensityList,
           a.ESD_Series AS SoilSeries,
           a.MapUnitComponent,
           a.Longitude,
           a.Latitude,
           a.CoordLabel1,
           a.CoordDistance1,
           a.Longitude1,
           a.Latitude1,
           a.Easting1,
           a.Northing1,
           a.CoordLabel2,
           a.CoordDistance2,
           a.Longitude2,
           a.Latitude2,
           a.Easting2,
           a.Northing2,
           a.CoordLabel3,
           a.CoordDistance3,
           a.Longitude3,
           a.Latitude3,
           a.Easting3,
           a.Northing3
      FROM tblPlots AS a
           JOIN
           tblSites AS b ON a.SiteKey = b.SiteKey
     WHERE b.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY SiteID,
              PlotID;
			  
-- View: Plot_Notes
CREATE VIEW Plot_Notes AS
    SELECT c.SiteKey,
           b.PlotKey,
           a.CommentID,
           c.SiteID,
           c.SiteName,
           b.PlotID,
           a.NoteDate,
           a.Recorder,
           a.Note
      FROM tblPlotNotes AS a
           JOIN
           tblPlots AS b ON a.PLotKey = b.PlotKey
           JOIN
           tblSites AS c ON b.SiteKey = c.SiteKey
     ORDER BY SiteID,
              PlotID,
              NoteDate;
			  
-- View: SitePlot_Join
CREATE VIEW SitePlot_Join AS
    SELECT a.SiteKey,
           a.SiteID,
           a.SiteName,
           b.PlotKey,
           b.PlotID
      FROM tblSites AS a
           LEFT JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY SiteID,
              PlotID;
			  
-- View: SitePlotLine_Join
CREATE VIEW SitePlotLine_Join AS
    SELECT a.SiteKey,
           a.SiteID,
           a.SiteName,
           b.PlotKey,
           b.PlotID,
           c.LineKey,
           c.LineID
      FROM tblSites AS a
           LEFT JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           LEFT JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY SiteID,
              PlotID,
              LineID;
			  
-- View: SoilPit_Raw
CREATE VIEW SoilPit_Raw AS
    SELECT d.SiteKey,
           c.PlotKey,
           a.SoilKey,
           a.HorizonKey,
           d.SiteID,
           d.SiteName,
           c.PlotID,
           a.HorizonDepthUpper,
           a.HorizonDepthLower,
           a.DepthMeasure,
           a.Texture,
           a.RockFragments,
           a.Effer,
           a.HorizonColorDry,
           a.HorizonColorMoist,
           a.StructGrade,
           a.StructShape,
           a.Nomenclature,
           a.ESD_Horizon,
           a.ESD_HorizonModifier,
           a.ESD_FragVolPct,
           a.ESD_FragmentType,
           a.ESD_PetrocalcicRubble,
           a.ESD_Gypsic,
           a.ESD_PctClay,
           a.ESD_Hue,
           a.ESD_Value,
           a.ESD_Chroma,
           a.ESD_Color,
           a.ESD_Grade,
           a.ESD_Size,
           a.ESD_Structure,
           a.ESD_StructQual,
           a.ESD_Grade2,
           a.ESD_Size2,
           a.ESD_Structure2,
           a.ESD_RuptureResistance,
           a.ESD_ClayFilm,
           a.ESD_CarbonateStage,
           a.ESD_CaCO3EquivPct,
           a.ESD_EC,
           a.ESD_pH,
           a.ESD_GypsumPct,
           a.ESD_NAabsorptionRatio,
           a.ESD_Notes,
           a.ESD_PSAPctSand,
           a.ESD_PSAPctSilt,
           a.ESD_PSAPctClay,
           a.ESD_GravelClassPctFine,
           a.ESD_GravelClassPctMed,
           a.ESD_GravelClassPctCoarse,
           a.ESD_GravelCarbonateCoatPct,
           a.ESD_FragmentRoundness,
           a.ESD_RootSize,
           a.ESD_RootQty,
           a.ESD_PoresSize,
           a.ESD_PoresQty,
           a.ESD_SandFractPctVeryFine,
           a.ESD_SandFractPctFine,
           a.ESD_SandFractPctMed,
           a.ESD_SandFractPctCoarse,
           a.ESD_SandFractPctVeryCoarse,
           a.ESD_FragVolPct2,
           a.ESD_FragmentType2,
           a.ESD_FragVolPct3,
           a.ESD_FragmentType3,
           a.ESD_PctSand,
           a.ESD_LabGravelPctFine,
           a.ESD_LabGravelPctMed,
           a.ESD_LabGravelPctCoarse
      FROM tblSoilPitHorizons AS a
           JOIN
           tblSoilPits AS b ON a.SoilKey = b.SoilKey
           JOIN
           tblPlots AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSites AS d ON c.SiteKey = d.SiteKey
     ORDER BY SiteID,
              PlotID,
              HorizonDepthUpper;
			  
-- View: SoilStab_Line
CREATE VIEW SoilStab_Line AS
    SELECT d.SiteKey,
           c.PlotKey,
           a.RecKey,
           d.SiteName,
           d.SiteID,
           d.PlotID,
           c.FormDate,
           a.Line,
           "Growth Habit" AS IndicatorCategory,
           b.Duration,
           b.Description AS Indicator,
           count(a.Cell) AS n,
           avg(a.Rating) AS RatingMean,
           stdev(a.Rating) AS RatingSD,
           sum(a.Hydro) / count(a.Hydro) AS HydroPct
      FROM SoilStabDetail_Long AS a
           JOIN
           SoilStab_Codes AS b ON a.Veg = b.Code
           JOIN
           tblSoilStabHeader AS c ON c.RecKey = a.RecKey
           JOIN
           SitePlot_Join AS d ON d.PlotKey = c.PlotKey
     WHERE a.Veg NOT IN ('C', 'NC') AND 
           c.FormDate BETWEEN (
                                  SELECT StartDate
                                    FROM Data_DateRange
                                   WHERE rowid = 1
                              )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY d.SiteKey,
              d.SiteName,
              d.SiteID,
              d.PlotID,
              c.PlotKey,
              c.FormDate,
              a.RecKey,
              a.Line,
              Indicator
    UNION ALL
    SELECT d.Sitekey,
           c.PlotKey,
           a.RecKey,
           d.SiteName,
           d.SiteID,
           d.PlotID,
           c.FormDate,
           a.Line,
           "Cover" AS IndicatorCategory,
           'NA' AS Duration,
           b.Category AS Indicator,
           count(a.Cell) AS n,
           avg(a.Rating) AS RatingMean,
           stdev(a.Rating) AS RatingSD,
           sum(a.Hydro) / count(a.Hydro) AS HydroPct
      FROM SoilStabDetail_Long AS a
           JOIN
           SoilStab_Codes AS b ON a.Veg = b.Code
           JOIN
           tblSoilStabHeader AS c ON c.RecKey = a.RecKey
           JOIN
           SitePlot_Join AS d ON d.PlotKey = c.PlotKey
     WHERE c.FormDate BETWEEN (
                                  SELECT StartDate
                                    FROM Data_DateRange
                                   WHERE rowid = 1
                              )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY d.SiteKey,
              d.SiteName,
              d.SiteID,
              d.PlotID,
              c.PlotKey,
              c.FormDate,
              a.RecKey,
              a.Line,
              Indicator
    UNION ALL
    SELECT d.Sitekey,
           c.PlotKey,
           a.RecKey,
           d.SiteName,
           d.SiteID,
           d.PlotID,
           c.FormDate,
           a.Line,
           "Total" AS IndicatorCategory,
           'NA' AS Duration,
           "All" AS Indicator,
           count(a.Cell) AS n,
           avg(a.Rating) AS RatingMean,
           stdev(a.Rating) AS RatingSD,
           sum(a.Hydro) / count(a.Hydro) AS HydroPct
      FROM SoilStabDetail_Long AS a
           JOIN
           SoilStab_Codes AS b ON a.Veg = b.Code
           JOIN
           tblSoilStabHeader AS c ON c.RecKey = a.RecKey
           JOIN
           SitePlot_Join AS d ON d.PlotKey = c.PlotKey
     WHERE FormDate BETWEEN (
                                SELECT StartDate
                                  FROM Data_DateRange
                                 WHERE rowid = 1
                            )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY d.SiteKey,
              d.SiteName,
              d.SiteID,
              d.PlotID,
              c.PlotKey,
              c.FormDate,
              a.RecKey,
              a.Line,
              Indicator
     ORDER BY d.SiteID,
              d.PlotID,
              a.Line,
              c.FormDate,
              Indicator;
			  
-- View: SoilStab_Plot
CREATE VIEW SoilStab_Plot AS
    SELECT d.SiteKey,
           c.PlotKey,
           a.RecKey,
           d.SiteName,
           d.SiteID,
           d.PlotID,
           c.FormDate,
           "Growth Habit" AS IndicatorCategory,
           b.Duration,
           b.Description AS Indicator,
           count(a.Cell) AS n,
           avg(a.Rating) AS RatingMean,
           stdev(a.Rating) AS RatingSD,
           sum(a.Hydro) / count(a.Hydro) AS HydroPct
      FROM SoilStabDetail_Long AS a
           JOIN
           SoilStab_Codes AS b ON a.Veg = b.Code
           JOIN
           tblSoilStabHeader AS c ON c.RecKey = a.RecKey
           JOIN
           SitePlot_Join AS d ON d.PlotKey = c.PlotKey
     WHERE a.Veg NOT IN ('C', 'NC') AND 
           c.FormDate BETWEEN (
                                  SELECT StartDate
                                    FROM Data_DateRange
                                   WHERE rowid = 1
                              )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY d.SiteKey,
              d.SiteName,
              d.SiteID,
              d.PlotID,
              c.PlotKey,
              c.FormDate,
              Indicator
    UNION ALL
    SELECT d.Sitekey,
           c.PlotKey,
           a.RecKey,
           d.SiteName,
           d.SiteID,
           d.PlotID,
           c.FormDate,
           "Cover" AS IndicatorCategory,
           'NA' AS Duration,
           b.Category AS Indicator,
           count(a.Cell) AS n,
           avg(a.Rating) AS RatingMean,
           stdev(a.Rating) AS RatingSD,
           sum(a.Hydro) / count(a.Hydro) AS HydroPct
      FROM SoilStabDetail_Long AS a
           JOIN
           SoilStab_Codes AS b ON a.Veg = b.Code
           JOIN
           tblSoilStabHeader AS c ON c.RecKey = a.RecKey
           JOIN
           SitePlot_Join AS d ON d.PlotKey = c.PlotKey
     WHERE c.FormDate BETWEEN (
                                  SELECT StartDate
                                    FROM Data_DateRange
                                   WHERE rowid = 1
                              )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY d.SiteKey,
              d.SiteName,
              d.SiteID,
              d.PlotID,
              c.PlotKey,
              c.FormDate,
              Indicator
    UNION ALL
    SELECT d.Sitekey,
           c.PlotKey,
           a.RecKey,
           d.SiteName,
           d.SiteID,
           d.PlotID,
           c.FormDate,
           "Total" AS IndicatorCategory,
           'NA' AS Duration,
           "All" AS Indicator,
           count(a.Cell) AS n,
           avg(a.Rating) AS RatingMean,
           stdev(a.Rating) AS RatingSD,
           sum(a.Hydro) / count(a.Hydro) AS HydroPct
      FROM SoilStabDetail_Long AS a
           JOIN
           SoilStab_Codes AS b ON a.Veg = b.Code
           JOIN
           tblSoilStabHeader AS c ON c.RecKey = a.RecKey
           JOIN
           SitePlot_Join AS d ON d.PlotKey = c.PlotKey
     WHERE FormDate BETWEEN (
                                SELECT StartDate
                                  FROM Data_DateRange
                                 WHERE rowid = 1
                            )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY d.SiteKey,
              d.SiteName,
              d.SiteID,
              d.PlotID,
              c.PlotKey,
              c.FormDate,
              Indicator
     ORDER BY d.SiteID,
              d.PlotID,
              c.FormDate,
              Indicator;
			  
-- View: SoilStab_Raw_Final
CREATE VIEW SoilStab_Raw_Final AS
    SELECT d.SiteID,
           d.SiteName,
           c.PlotID,
           b.FormDate,
           a.*
      FROM SoilStabDetail_Long AS a
           JOIN
           tblSoilStabHeader AS b ON a.RecKey = b.RecKey
           JOIN
           tblPlots AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSites AS d ON c.SiteKey = d.SiteKey
     WHERE b.FormDate BETWEEN (
                                  SELECT StartDate
                                    FROM Data_DateRange
                                   WHERE rowid = 1
                              )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     ORDER BY SiteID,
              PlotID,
              FormDate,
              BoxNumber,
              Line,
              Position;
			  
-- View: SoilStab_Tag
CREATE VIEW SoilStab_Tag AS
    SELECT a.Tag,
           b.IndicatorCategory,
           b.Duration,
           b.Indicator,
           Count(b.PlotKey) AS Plot_n,
           meanw(b.RatingMean, a.Weight) AS DimMean,
           stdevw(b.RatingMean, a.Weight) AS DimSD,
           meanw(b.HydroPct, a.Weight) AS HydroPct
      FROM PlotTags AS a
           JOIN
           SoilStab_Plot AS b ON a.PlotKey = b.PlotKey
     GROUP BY a.Tag,
              b.IndicatorCategory,
              b.Duration,
              b.Indicator
     ORDER BY a.Tag,
              b.IndicatorCategory,
              b.Duration,
              b.Indicator;
			  
-- View: SoilStabDetail_Long
CREATE VIEW SoilStabDetail_Long AS
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line1 AS Line,
           CAST (Pos1 AS NUMERIC) AS Position,
           Veg1 AS Veg,
           CAST (Rating1 AS NUMERIC) AS Rating,
           Hydro1 AS Hydro,
           In1 AS InTime,
           Dip1 AS DipTime,
           1 AS Cell
      FROM tblSoilStabDetail
     WHERE Line1 IS NOT NULL AND 
           Pos1 != "" AND 
           Veg1 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line1 AS Line,
           CAST (Pos2 AS NUMERIC) AS Position,
           Veg2 AS Veg,
           CAST (Rating2 AS NUMERIC) AS Rating,
           Hydro2 AS Hydro,
           In2 AS InTime,
           Dip2 AS DipTime,
           2 AS Cell
      FROM tblSoilStabDetail
     WHERE Line1 IS NOT NULL AND 
           Pos2 != "" AND 
           Veg2 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line1 AS Line,
           CAST (Pos3 AS NUMERIC) AS Position,
           Veg3 AS Veg,
           CAST (Rating3 AS NUMERIC) AS Rating,
           Hydro3 AS Hydro,
           In3 AS InTime,
           Dip3 AS DipTime,
           3 AS Cell
      FROM tblSoilStabDetail
     WHERE Line1 IS NOT NULL AND 
           Pos3 != "" AND 
           Veg3 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line2 AS Line,
           CAST (Pos4 AS NUMERIC) AS Position,
           Veg4 AS Veg,
           CAST (Rating4 AS NUMERIC) AS Rating,
           Hydro4 AS Hydro,
           In4 AS InTime,
           Dip4 AS DipTime,
           4 AS Cell
      FROM tblSoilStabDetail
     WHERE Line2 IS NOT NULL AND 
           Pos4 != "" AND 
           Veg4 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line2 AS Line,
           CAST (Pos5 AS NUMERIC) AS Position,
           Veg5 AS Veg,
           CAST (Rating5 AS NUMERIC) AS Rating,
           Hydro5 AS Hydro,
           In5 AS InTime,
           Dip5 AS DipTime,
           5 AS Cell
      FROM tblSoilStabDetail
     WHERE Line2 IS NOT NULL AND 
           Pos5 != "" AND 
           Veg5 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line2 AS Line,
           CAST (Pos6 AS NUMERIC) AS Position,
           Veg6 AS Veg,
           CAST (Rating6 AS NUMERIC) AS Rating,
           Hydro6 AS Hydro,
           In6 AS InTime,
           Dip6 AS DipTime,
           6 AS Cell
      FROM tblSoilStabDetail
     WHERE Line2 IS NOT NULL AND 
           Pos6 != "" AND 
           Veg6 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line3 AS Line,
           CAST (Pos7 AS NUMERIC) AS Position,
           Veg7 AS Veg,
           CAST (Rating7 AS NUMERIC) AS Rating,
           Hydro7 AS Hydro,
           In7 AS InTime,
           Dip7 AS DipTime,
           7 AS Cell
      FROM tblSoilStabDetail
     WHERE Line3 IS NOT NULL AND 
           Pos7 != "" AND 
           Veg7 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line3 AS Line,
           CAST (Pos8 AS NUMERIC) AS Position,
           Veg8 AS Veg,
           CAST (Rating8 AS NUMERIC) AS Rating,
           Hydro8 AS Hydro,
           In8 AS InTime,
           Dip8 AS DipTime,
           8 AS Cell
      FROM tblSoilStabDetail
     WHERE Line3 IS NOT NULL AND 
           Pos8 != "" AND 
           Veg8 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line3 AS Line,
           CAST (Pos9 AS NUMERIC) AS Position,
           Veg9 AS Veg,
           CAST (Rating9 AS NUMERIC) AS Rating,
           Hydro9 AS Hydro,
           In9 AS InTime,
           Dip9 AS DipTime,
           9 AS Cell
      FROM tblSoilStabDetail
     WHERE Line3 IS NOT NULL AND 
           Pos9 != "" AND 
           Veg9 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line4 AS Line,
           CAST (Pos10 AS NUMERIC) AS Position,
           Veg10 AS Veg,
           CAST (Rating10 AS NUMERIC) AS Rating,
           Hydro10 AS Hydro,
           In10 AS InTime,
           Dip10 AS DipTime,
           10 AS Cell
      FROM tblSoilStabDetail
     WHERE Line4 IS NOT NULL AND 
           Pos10 != "" AND 
           Veg10 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line4 AS Line,
           CAST (Pos11 AS NUMERIC) AS Position,
           Veg11 AS Veg,
           CAST (Rating11 AS NUMERIC) AS Rating,
           Hydro11 AS Hydro,
           In11 AS InTime,
           Dip11 AS DipTime,
           11 AS Cell
      FROM tblSoilStabDetail
     WHERE Line4 IS NOT NULL AND 
           Pos11 != "" AND 
           Veg11 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line4 AS Line,
           CAST (Pos12 AS NUMERIC) AS Position,
           Veg12 AS Veg,
           CAST (Rating12 AS NUMERIC) AS Rating,
           Hydro12 AS Hydro,
           In12 AS InTime,
           Dip12 AS DipTime,
           12 AS Cell
      FROM tblSoilStabDetail
     WHERE Line4 IS NOT NULL AND 
           Pos12 != "" AND 
           Veg12 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line5 AS Line,
           CAST (Pos13 AS NUMERIC) AS Position,
           Veg13 AS Veg,
           CAST (Rating13 AS NUMERIC) AS Rating,
           Hydro13 AS Hydro,
           In13 AS InTime,
           Dip13 AS DipTime,
           13 AS Cell
      FROM tblSoilStabDetail
     WHERE Line5 IS NOT NULL AND 
           Pos13 != "" AND 
           Veg13 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line5 AS Line,
           CAST (Pos14 AS NUMERIC) AS Position,
           Veg14 AS Veg,
           CAST (Rating14 AS NUMERIC) AS Rating,
           Hydro14 AS Hydro,
           In14 AS InTime,
           Dip14 AS DipTime,
           14 AS Cell
      FROM tblSoilStabDetail
     WHERE Line5 IS NOT NULL AND 
           Pos14 != "" AND 
           Veg14 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line5 AS Line,
           CAST (Pos15 AS NUMERIC) AS Position,
           Veg15 AS Veg,
           CAST (Rating15 AS NUMERIC) AS Rating,
           Hydro15 AS Hydro,
           In15 AS InTime,
           Dip15 AS DipTime,
           15 AS Cell
      FROM tblSoilStabDetail
     WHERE Line5 IS NOT NULL AND 
           Pos15 != "" AND 
           Veg15 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line6 AS Line,
           CAST (Pos16 AS NUMERIC) AS Position,
           Veg16 AS Veg,
           CAST (Rating16 AS NUMERIC) AS Rating,
           Hydro16 AS Hydro,
           In16 AS InTime,
           Dip16 AS DipTime,
           16 AS Cell
      FROM tblSoilStabDetail
     WHERE Line6 IS NOT NULL AND 
           Pos16 != "" AND 
           Veg16 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line6 AS Line,
           CAST (Pos17 AS NUMERIC) AS Position,
           Veg17 AS Veg,
           CAST (Rating17 AS NUMERIC) AS Rating,
           Hydro17 AS Hydro,
           In17 AS InTime,
           Dip17 AS DipTime,
           17 AS Cell
      FROM tblSoilStabDetail
     WHERE Line6 IS NOT NULL AND 
           Pos17 != "" AND 
           Veg17 IS NOT NULL
    UNION ALL
    SELECT RecKey,
           CAST (BoxNum AS NUMERIC) AS BoxNumber,
           Line6 AS Line,
           CAST (Pos18 AS NUMERIC) AS Position,
           Veg18 AS Veg,
           CAST (Rating18 AS NUMERIC) AS Rating,
           Hydro18 AS Hydro,
           In18 AS InTime,
           Dip18 AS DipTime,
           18 AS Cell
      FROM tblSoilStabDetail
     WHERE Line6 IS NOT NULL AND 
           Pos18 != "" AND 
           Veg18 IS NOT NULL
     ORDER BY RecKey,
              BoxNumber,
              Line,
              Position;
			  
-- View: SpeciesList
CREATE VIEW SpeciesList AS
    SELECT a.SpeciesCode,
           a.ScientificName,
           a.CommonName,
           a.Family,
           a.synonymOf,
           a.Duration,
           a.Stabilizing,
           a.Invasive,
           a.GrowthHabitCode,
           b.GrowthHabit,
           b.GrowthHabitSub
      FROM tblSpecies AS a
           LEFT JOIN
           tblSpeciesGrowthHabit AS b ON a.GrowthHabitCode = b.Code;
		   
-- View: SR_Line
CREATE VIEW SR_Line AS
    SELECT a.*,
           CASE WHEN b.subPlot_n IS NULL THEN 0 ELSE b.subPlot_n END AS subPlot_n,
           CASE WHEN b.MeanSpecies_n IS NULL THEN 0 ELSE b.MeanSpecies_n END AS MeanSpecies_n
      FROM SR_Line_Count AS a
           JOIN
           SR_Line_Mean AS b ON a.RecKey = b.RecKey AND 
                                a.Duration = b.Duration AND 
                                a.Indicator = b.Indicator
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID,
              a.FormDate,
              a.IndicatorCategory,
              a.Duration,
              a.Indicator;
			  
-- View: SR_Line_Count
CREATE VIEW SR_Line_Count AS
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           SiteName,
           PlotID,
           LineID,
           FormDate,
           'Species' AS IndicatorCategory,
           Duration,
           SpeciesName AS Indicator,
           1 AS Species_n
      FROM SR_List_Line
    UNION-- Growth Habit Sub Duration
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           a.RecKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           a.FormDate,
           'Growth Habit' AS IndicatorCategory,
           b.Tag AS Duration,
           c.Tag AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Line AS a
           JOIN
           CodeTags AS b ON a.Duration = b.Code
           JOIN
           CodeTags AS c ON a.GrowthHabitSub = c.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use AS d ON b.Tag = d.DurationTag AND 
                                                            c.Tag = d.GHTag
     WHERE b.Category = 'Duration' AND 
           c.Category = 'GrowthHabitSub'
     GROUP BY a.RecKey,
              Duration,
              Indicator
    UNION-- Growth Habit Sub
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           a.RecKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           a.FormDate,
           'Growth Habit' AS IndicatorCategory,
           'All' AS Duration,
           b.Tag AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Line AS a
           JOIN
           CodeTags AS b ON a.GrowthHabitSub = b.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use_Count AS c ON b.Tag = c.GHTag
     WHERE b.Category = 'GrowthHabitSub' AND 
           c.GHCount > 1
     GROUP BY a.RecKey,
              Indicator
    UNION-- Lignification Duration
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           a.RecKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           a.FormDate,
           'Lignification' AS IndicatorCategory,
           b.Tag AS Duration,
           c.Tag AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Line AS a
           JOIN
           CodeTags AS b ON a.Duration = b.Code
           JOIN
           CodeTags AS c ON a.GrowthHabit = c.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use AS d ON b.Tag = d.DurationTag AND 
                                                         c.Tag = d.GHTag
     WHERE b.Category = 'Duration' AND 
           c.Category = 'GrowthHabit'
     GROUP BY a.RecKey,
              Duration,
              Indicator
    UNION-- Lignification
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           a.RecKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           a.FormDate,
           'Lignification' AS IndicatorCategory,
           'All' AS Duration,
           b.Tag AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Line AS a
           JOIN
           CodeTags AS b ON a.GrowthHabit = b.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use_Count AS c ON b.Tag = c.GHTag
     WHERE b.Category = 'GrowthHabit' AND 
           c.DurationCount > 1
     GROUP BY a.RecKey,
              Indicator
    UNION-- Species Tag Duration
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           a.RecKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           a.FormDate,
           'Species Tag' AS IndicatorCategory,
           b.Tag AS Duration,
           c.Tag AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_List_Line AS a
           JOIN
           CodeTags AS b ON a.Duration = b.Code
           JOIN
           SpeciesTags AS c ON a.SpeciesCode = c.SpeciesCode
           JOIN
           Duration_SpeciesTags_Combinations_Use AS d ON b.Tag = d.DurationTag AND 
                                                         c.Tag = d.SpeciesTag
     WHERE b.Category = 'Duration'
     GROUP BY a.RecKey,
              Duration,
              Indicator
    UNION-- Species Tag
    SELECT a.SiteKey,
           a.PlotKey,
           a.LineKey,
           a.RecKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           a.FormDate,
           'Species Tag' AS IndicatorCategory,
           'All' AS Duration,
           b.Tag AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_List_Line AS a
           JOIN
           SpeciesTags AS b ON a.SpeciesCode = b.SpeciesCode
           JOIN
           Duration_SpeciesTags_Combinations_Use_Count AS c ON b.Tag = c.SpeciesTag
     WHERE c.DurationCount > 1
     GROUP BY a.RecKey,
              Indicator
    UNION
    SELECT SiteKey,
           PlotKey,
           LineKey,
           RecKey,
           SiteID,
           SiteName,
           PlotID,
           LineID,
           FormDate,
           'Total' AS IndicatorCategory,
           'NA' AS Duration,
           'Total' AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Line
     GROUP BY RecKey
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              IndicatorCategory,
              Duration,
              Indicator;
			  
-- View: SR_Line_Mean
CREATE VIEW SR_Line_Mean AS
    SELECT x.*,
           Count(y.subPlotID) AS subPlot_n,
           Avg(CASE WHEN y.Species_n IS NULL THEN 0 ELSE y.Species_n END) AS MeanSpecies_n
      FROM (
               SELECT a.*,
                      b.IndicatorCategory,
                      b.Duration,
                      b.Indicator
                 FROM (
                          SELECT SiteKey,
                                 PlotKey,
                                 LineKey,
                                 RecKey,
                                 SiteID,
                                 SiteName,
                                 PlotID,
                                 LineID,
                                 FormDate,
                                 subPlotID
                            FROM SR_SubPlot
                           GROUP BY RecKey,
                                    subPlotID
                      )
                      AS a
                      JOIN
                      (
                          SELECT RecKey,
                                 IndicatorCategory,
                                 Duration,
                                 Indicator
                            FROM SR_SubPlot
                           GROUP BY RecKey,
                                    IndicatorCategory,
                                    Duration,
                                    Indicator
                      )
                      AS b ON a.RecKey = b.RecKey
           )
           AS x
           LEFT JOIN
           SR_SubPlot AS y ON x.RecKey = y.RecKey AND 
                              x.subPlotID = y.subPlotID AND 
                              x.Duration = y.Duration AND 
                              x.Indicator = y.Indicator
     GROUP BY x.RecKey,
              x.Duration,
              x.Indicator
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              IndicatorCategory,
              Duration,
              Indicator;
			  
-- View: SR_List_Line
CREATE VIEW SR_List_Line AS
    SELECT x.SiteKey,
           x.PlotKey,
           x.LineKey,
           x.RecKey,
           x.SiteID,
           x.SiteName,
           x.PlotID,
           x.LineID,
           x.FormDate,
           x.SpeciesCode,
           CASE WHEN y.Duration IS NULL THEN 'NA' ELSE y.Duration END AS Duration,
           z.GrowthHabit,
           z.GrowthHabitSub,
           CASE WHEN (y.ScientificName) IS NULL THEN x.SpeciesCode ELSE y.ScientificName END AS SpeciesName
      FROM (
               SELECT a.SiteKey,
                      b.PlotKey,
                      c.LineKey,
                      d.RecKey,
                      a.SiteID,
                      a.SiteName,
                      b.PlotID,
                      c.LineID,
                      d.FormDate,
                      e.SpeciesCode
                 FROM tblSites AS a
                      JOIN
                      tblPlots AS b ON a.SiteKey = b.SiteKey
                      JOIN
                      tblLines AS c ON b.PlotKey = c.PlotKey
                      JOIN
                      tblSpecRichHeader AS d ON c.LineKey = d.LineKey
                      JOIN
                      SR_Raw AS e ON d.RecKey = e.RecKey
                WHERE d.FormDate BETWEEN (
                                             SELECT StartDate
                                               FROM Data_DateRange
                                              WHERE rowid = 1
                                         )
                      AND (
                              SELECT EndDate
                                FROM Data_DateRange
                               WHERE rowid = 1
                          )
           )
           AS x
           LEFT JOIN
           tblSpecies AS y ON x.SpeciesCode = y.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS z ON y.GrowthHabitCode = z.Code
     GROUP BY x.RecKey,
              x.SpeciesCode
     ORDER BY x.SiteID,
              x.PlotID,
              x.LineID,
              x.FormDate,
              x.SpeciesCode;
			  
-- View: SR_List_Plot
CREATE VIEW SR_List_Plot AS
    SELECT x.SiteKey,
           x.PlotKey,
           x.SiteID,
           x.SiteName,
           x.PlotID,
           x.Season,
           x.SpeciesCode,
           CASE WHEN y.Duration IS NULL THEN 'NA' ELSE y.Duration END AS Duration,
           z.GrowthHabit,
           z.GrowthHabitSub,
           CASE WHEN (y.ScientificName) IS NULL THEN x.SpeciesCode ELSE y.ScientificName END AS SpeciesName
      FROM (
               SELECT a.SiteKey,
                      b.PlotKey,
                      a.SiteID,
                      a.SiteName,
                      b.PlotID,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE d.FormDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      e.SpeciesCode
                 FROM tblSites AS a
                      JOIN
                      tblPlots AS b ON a.SiteKey = b.SiteKey
                      JOIN
                      tblLines AS c ON b.PlotKey = c.PlotKey
                      JOIN
                      tblSpecRichHeader AS d ON c.LineKey = d.LineKey
                      JOIN
                      SR_Raw AS e ON d.RecKey = e.RecKey
                WHERE d.FormDate BETWEEN (
                                             SELECT StartDate
                                               FROM Data_DateRange
                                              WHERE rowid = 1
                                         )
                      AND (
                              SELECT EndDate
                                FROM Data_DateRange
                               WHERE rowid = 1
                          )
           )
           AS x
           LEFT JOIN
           tblSpecies AS y ON x.SpeciesCode = y.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS z ON y.GrowthHabitCode = z.Code
     GROUP BY x.PlotKey,
              x.Season,
              x.SpeciesCode
     ORDER BY x.SiteID,
              x.PlotID,
              x.Season,
              x.SpeciesCode;
			  
-- View: SR_List_Tag
CREATE VIEW SR_List_Tag AS
    SELECT x.Tag,
           x.SpeciesCode,
           CASE WHEN y.Duration IS NULL THEN 'NA' ELSE y.Duration END AS Duration,
           z.GrowthHabit,
           z.GrowthHabitSub,
           CASE WHEN (y.ScientificName) IS NULL THEN x.SpeciesCode ELSE y.ScientificName END AS SpeciesName
      FROM (
               SELECT a.Tag,
                      d.SpeciesCode
                 FROM PlotTags AS a
                      JOIN
                      tblLines AS b ON a.PlotKey = b.PlotKey
                      JOIN
                      tblSpecRichHeader AS c ON b.LineKey = c.LineKey
                      JOIN
                      SR_Raw AS d ON c.RecKey = d.RecKey
                WHERE c.FormDate BETWEEN (
                                             SELECT StartDate
                                               FROM Data_DateRange
                                              WHERE rowid = 1
                                         )
                      AND (
                              SELECT EndDate
                                FROM Data_DateRange
                               WHERE rowid = 1
                          )
           )
           AS x
           LEFT JOIN
           tblSpecies AS y ON x.SpeciesCode = y.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS z ON y.GrowthHabitCode = z.Code
     GROUP BY x.Tag,
              x.SpeciesCode
     ORDER BY x.Tag,
              x.SpeciesCode;-- View: SR_Plot

CREATE VIEW SR_Plot AS
    SELECT a.*,
           CASE WHEN b.line_n IS NULL THEN 0 ELSE b.line_n END AS line_n,
           CASE WHEN b.MeanSpecies_n IS NULL THEN 0 ELSE b.MeanSpecies_n END AS MeanSpecies_n
      FROM SR_Plot_Count AS a
           JOIN
           SR_Plot_Mean AS b ON a.PlotKey = b.PlotKey AND 
                                a.Season = b.Season AND 
                                a.Duration = b.Duration AND 
                                a.Indicator = b.Indicator
     ORDER BY a.SiteID,
              a.PlotID,
              a.Season,
              a.IndicatorCategory,
              a.Duration,
              a.Indicator;
			  
-- View: SR_Plot_Count
CREATE VIEW SR_Plot_Count AS
    SELECT SiteKey,
           PlotKey,
           SiteID,
           SiteName,
           PlotID,
           Season,
           'Species' AS IndicatorCategory,
           Duration,
           SpeciesName AS Indicator,
           1 AS Species_n
      FROM SR_List_Plot
    UNION-- Growth Habit Sub Duration
    SELECT a.SiteKey,
           a.PlotKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.Season,
           'Growth Habit' AS IndicatorCategory,
           b.Tag AS Duration,
           c.Tag AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Plot AS a
           JOIN
           CodeTags AS b ON a.Duration = b.Code
           JOIN
           CodeTags AS c ON a.GrowthHabitSub = c.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use AS d ON b.Tag = d.DurationTag AND 
                                                            c.Tag = d.GHTag
     WHERE b.Category = 'Duration' AND 
           c.Category = 'GrowthHabitSub'
     GROUP BY a.PlotKey,
              a.Season,
              Duration,
              Indicator
    UNION-- Growth Habit Sub
    SELECT a.SiteKey,
           a.PlotKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.Season,
           'Growth Habit' AS IndicatorCategory,
           'All' AS Duration,
           b.Tag AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Plot AS a
           JOIN
           CodeTags AS b ON a.GrowthHabitSub = b.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use_Count AS c ON b.Tag = c.GHTag
     WHERE b.Category = 'GrowthHabitSub' AND 
           c.GHCount > 1
     GROUP BY a.PlotKey,
              a.Season,
              Indicator
    UNION-- Lignification Duration
    SELECT a.SiteKey,
           a.PlotKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.Season,
           'Lignification' AS IndicatorCategory,
           b.Tag AS Duration,
           c.Tag AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Plot AS a
           JOIN
           CodeTags AS b ON a.Duration = b.Code
           JOIN
           CodeTags AS c ON a.GrowthHabit = c.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use AS d ON b.Tag = d.DurationTag AND 
                                                         c.Tag = d.GHTag
     WHERE b.Category = 'Duration' AND 
           c.Category = 'GrowthHabit'
     GROUP BY a.PlotKey,
              a.Season,
              Duration,
              Indicator
    UNION-- Lignification
    SELECT a.SiteKey,
           a.PlotKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.Season,
           'Lignification' AS IndicatorCategory,
           'All' AS Duration,
           b.Tag AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Plot AS a
           JOIN
           CodeTags AS b ON a.GrowthHabit = b.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use_Count AS c ON b.Tag = c.GHTag
     WHERE b.Category = 'GrowthHabit' AND 
           c.DurationCount > 1
     GROUP BY a.PlotKey,
              a.Season,
              Indicator
    UNION-- Species Tag Duration
    SELECT a.SiteKey,
           a.PlotKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.Season,
           'Species Tag' AS IndicatorCategory,
           b.Tag AS Duration,
           c.Tag AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_List_Plot AS a
           JOIN
           CodeTags AS b ON a.Duration = b.Code
           JOIN
           SpeciesTags AS c ON a.SpeciesCode = c.SpeciesCode
           JOIN
           Duration_SpeciesTags_Combinations_Use AS d ON b.Tag = d.DurationTag AND 
                                                         c.Tag = d.SpeciesTag
     WHERE b.Category = 'Duration'
     GROUP BY a.PlotKey,
              a.Season,
              Duration,
              Indicator
    UNION-- Species Tag
    SELECT a.SiteKey,
           a.PlotKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.Season,
           'Species Tag' AS IndicatorCategory,
           'All' AS Duration,
           b.Tag AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_List_Plot AS a
           JOIN
           SpeciesTags AS b ON a.SpeciesCode = b.SpeciesCode
           JOIN
           Duration_SpeciesTags_Combinations_Use_Count AS c ON b.Tag = c.SpeciesTag
     WHERE c.DurationCount > 1
     GROUP BY a.PlotKey,
              a.Season,
              Indicator
    UNION
    SELECT SiteKey,
           PlotKey,
           SiteID,
           SiteName,
           PlotID,
           Season,
           'Total' AS IndicatorCategory,
           'NA' AS Duration,
           'Total' AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Plot
     GROUP BY PlotKey,
              Season
     ORDER BY SiteID,
              PlotID,
              Season,
              IndicatorCategory,
              Duration,
              Indicator;
			  
-- View: SR_Plot_Mean
CREATE VIEW SR_Plot_Mean AS
    SELECT x.SiteKey AS SiteKey,
           x.PlotKey AS PlotKey,
           x.SiteID AS SiteID,
           x.SiteName AS SiteName,
           x.PlotID AS PlotID,
           (
               SELECT SeasonLabel
                 FROM SeasonDefinition
                WHERE x.FormDate BETWEEN SeasonStart AND SeasonEnd
           )
           AS Season,
           x.IndicatorCategory AS IndicatorCategory,
           x.Duration AS Duration,
           x.Indicator AS Indicator,
           Count(x.LineKey) AS line_n,
           Avg(CASE WHEN y.Species_n IS NULL THEN 0 ELSE y.Species_n END) AS MeanSpecies_n
      FROM (
               SELECT a.*,
                      b.IndicatorCategory,
                      b.Duration,
                      b.Indicator
                 FROM (
                          SELECT SiteKey,
                                 PlotKey,
                                 LineKey,
                                 RecKey,
                                 SiteID,
                                 SiteName,
                                 PlotID,
                                 LineID,
                                 FormDate
                            FROM SR_Line
                           GROUP BY RecKey
                      )
                      AS a
                      JOIN
                      (
                          SELECT PlotKey,
                                 IndicatorCategory,
                                 Duration,
                                 Indicator
                            FROM SR_Line
                           GROUP BY PlotKey,
                                    IndicatorCategory,
                                    Duration,
                                    Indicator
                      )
                      AS b ON a.PlotKey = b.PlotKey
           )
           AS x
           LEFT JOIN
           SR_Line AS y ON x.RecKey = y.RecKey AND 
                           x.Duration = y.Duration AND 
                           x.Indicator = y.Indicator
     GROUP BY x.PlotKey,
              Season,
              x.Duration,
              x.Indicator
     ORDER BY SiteID,
              PlotID,
              Season,
              IndicatorCategory,
              Duration,
              Indicator;
			  
-- View: SR_Raw_Final
CREATE VIEW SR_Raw_Final AS
    SELECT f.SiteID,
           f.SiteName,
           e.PlotID,
           d.LineID,
           c.FormDate,
           a.*
      FROM SR_Raw AS a
           JOIN
           tblSpecRichDetail AS b ON a.RecKey = b.RecKey AND 
                                     a.subPlotID = b.subPlotID
           JOIN
           tblSpecRichHeader AS c ON b.RecKey = c.RecKey
           JOIN
           tblLines AS d ON c.LineKey = d.LineKey
           JOIN
           tblPlots AS e ON d.PlotKey = e.PlotKey
           JOIN
           tblSites AS f ON e.SiteKey = f.SiteKey
     WHERE FormDate BETWEEN (
                                SELECT StartDate
                                  FROM Data_DateRange
                                 WHERE rowid = 1
                            )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              subPlotID,
              SpeciesCode;
			  
-- View: SR_SubPlot
CREATE VIEW SR_SubPlot AS
    SELECT f.SiteKey AS SiteKey,
           e.PlotKey AS PlotKey,
           d.LineKey AS Linekey,
           a.RecKey AS RecKey,
           f.SiteID AS SiteID,
           f.SiteName AS SiteName,
           e.PlotID AS PlotID,
           d.LineID AS LineID,
           c.FormDate AS FormDate,
           a.subPlotID,
           'Species' AS IndicatorCategory,
           CASE WHEN g.Duration IS NULL THEN 'NA' ELSE g.Duration END AS Duration,
           CASE WHEN (g.ScientificName) IS NULL THEN a.SpeciesCode ELSE g.ScientificName END AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_Raw AS a
           JOIN
           tblSpecRichHeader AS c ON a.RecKey = c.RecKey
           JOIN
           tblLines AS d ON c.LineKey = d.LineKey
           JOIN
           tblPlots AS e ON d.PlotKey = e.PlotKey
           JOIN
           tblSites AS f ON e.SiteKey = f.SiteKey
           JOIN
           tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
     WHERE c.FormDate BETWEEN (
                                  SELECT StartDate
                                    FROM Data_DateRange
                                   WHERE rowid = 1
                              )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY f.SiteKey,
              e.PlotKey,
              d.LineKey,
              a.RecKey,
              a.subPlotID,
              g.ScientificName-- Species
    UNION-- Growth Habit Sub Duration
    SELECT f.SiteKey AS SiteKey,
           e.PlotKey AS PlotKey,
           d.LineKey AS Linekey,
           a.RecKey AS RecKey,
           f.SiteID AS SiteID,
           f.SiteName AS SiteName,
           e.PlotID AS PlotID,
           d.LineID AS LineID,
           c.FormDate AS FormDate,
           a.subPlotID,
           'Growth Habit' AS IndicatorCategory,
           k.DurationTag AS Duration,
           k.GHTag AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_Raw AS a
           JOIN
           tblSpecRichHeader AS c ON a.RecKey = c.RecKey
           JOIN
           tblLines AS d ON c.LineKey = d.LineKey
           JOIN
           tblPlots AS e ON d.PlotKey = e.PlotKey
           JOIN
           tblSites AS f ON e.SiteKey = f.SiteKey
           JOIN
           tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS h ON g.GrowthHabitCode = h.Code
           LEFT JOIN
           CodeTags AS i ON g.Duration = i.Code
           LEFT JOIN
           CodeTags AS j ON h.GrowthHabitSub = j.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use AS k ON j.Tag = k.GHTag AND 
                                                            i.Tag = k.DurationTag
     WHERE i.Category = 'Duration' AND 
           j.Category = 'GrowthHabitSub' AND 
           c.FormDate BETWEEN (
                                  SELECT StartDate
                                    FROM Data_DateRange
                                   WHERE rowid = 1
                              )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY f.SiteKey,
              e.PlotKey,
              d.LineKey,
              a.RecKey,
              a.subPlotID,
              k.GHTag,
              k.DurationTag
    UNION-- Growth Habit Sub
    SELECT f.SiteKey AS SiteKey,
           e.PlotKey AS PlotKey,
           d.LineKey AS Linekey,
           a.RecKey AS RecKey,
           f.SiteID AS SiteID,
           f.SiteName AS SiteName,
           e.PlotID AS PlotID,
           d.LineID AS LineID,
           c.FormDate AS FormDate,
           a.subPlotID,
           'Growth Habit' AS IndicatorCategory,
           'All' AS Duration,
           k.GHTag AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_Raw AS a
           JOIN
           tblSpecRichHeader AS c ON a.RecKey = c.RecKey
           JOIN
           tblLines AS d ON c.LineKey = d.LineKey
           JOIN
           tblPlots AS e ON d.PlotKey = e.PlotKey
           JOIN
           tblSites AS f ON e.SiteKey = f.SiteKey
           JOIN
           tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS h ON g.GrowthHabitCode = h.Code
           LEFT JOIN
           CodeTags AS j ON h.GrowthHabitSub = j.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use_Count AS k ON j.Tag = k.GHTag
     WHERE j.Category = 'GrowthHabitSub' AND 
           k.GHCount > 1 AND 
           c.FormDate BETWEEN (
                                  SELECT StartDate
                                    FROM Data_DateRange
                                   WHERE rowid = 1
                              )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY f.SiteKey,
              e.PlotKey,
              d.LineKey,
              a.RecKey,
              a.subPlotID,
              k.GHTag
    UNION-- Lignification Duration
    SELECT f.SiteKey AS SiteKey,
           e.PlotKey AS PlotKey,
           d.LineKey AS Linekey,
           a.RecKey AS RecKey,
           f.SiteID AS SiteID,
           f.SiteName AS SiteName,
           e.PlotID AS PlotID,
           d.LineID AS LineID,
           c.FormDate AS FormDate,
           a.SubPlotID,
           'Lignification' AS IndicatorCategory,
           k.DurationTag AS Duration,
           k.GHTag AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_Raw AS a
           JOIN
           tblSpecRichHeader AS c ON a.RecKey = c.RecKey
           JOIN
           tblLines AS d ON c.LineKey = d.LineKey
           JOIN
           tblPlots AS e ON d.PlotKey = e.PlotKey
           JOIN
           tblSites AS f ON e.SiteKey = f.SiteKey
           JOIN
           tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS h ON g.GrowthHabitCode = h.Code
           LEFT JOIN
           CodeTags AS i ON g.Duration = i.Code
           LEFT JOIN
           CodeTags AS j ON h.GrowthHabit = j.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use AS k ON j.Tag = k.GHTag AND 
                                                         i.Tag = k.DurationTag
     WHERE i.Category = 'Duration' AND 
           j.Category = 'GrowthHabit' AND 
           c.FormDate BETWEEN (
                                  SELECT StartDate
                                    FROM Data_DateRange
                                   WHERE rowid = 1
                              )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY f.SiteKey,
              e.PlotKey,
              d.LineKey,
              a.RecKey,
              a.SubPlotID,
              k.GHTag,
              k.DurationTag
    UNION-- Lignification
    SELECT f.SiteKey AS SiteKey,
           e.PlotKey AS PlotKey,
           d.LineKey AS Linekey,
           a.RecKey AS RecKey,
           f.SiteID AS SiteID,
           f.SiteName AS SiteName,
           e.PlotID AS PlotID,
           d.LineID AS LineID,
           c.FormDate AS FormDate,
           a.SubPlotID,
           'Lignification' AS IndicatorCategory,
           'All' AS Duration,
           k.GHTag AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_Raw AS a
           JOIN
           tblSpecRichHeader AS c ON a.RecKey = c.RecKey
           JOIN
           tblLines AS d ON c.LineKey = d.LineKey
           JOIN
           tblPlots AS e ON d.PlotKey = e.PlotKey
           JOIN
           tblSites AS f ON e.SiteKey = f.SiteKey
           JOIN
           tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS h ON g.GrowthHabitCode = h.Code
           LEFT JOIN
           CodeTags AS j ON h.GrowthHabit = j.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use_Count AS k ON j.Tag = k.GHTag
     WHERE j.Category = 'GrowthHabit' AND 
           k.DurationCount > 1 AND 
           c.FormDate BETWEEN (
                                  SELECT StartDate
                                    FROM Data_DateRange
                                   WHERE rowid = 1
                              )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY f.SiteKey,
              e.PlotKey,
              d.LineKey,
              a.RecKey,
              a.SubPlotID,
              k.GHTag
    UNION-- Species Tag Duration
    SELECT f.SiteKey AS SiteKey,
           e.PlotKey AS PlotKey,
           d.LineKey AS Linekey,
           a.RecKey AS RecKey,
           f.SiteID AS SiteID,
           f.SiteName AS SiteName,
           e.PlotID AS PlotID,
           d.LineID AS LineID,
           c.FormDate AS FormDate,
           a.SubPlotID,
           'Species Tag' AS IndicatorCategory,
           g.Duration AS Duration,
           h.Tag AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_Raw AS a
           JOIN
           tblSpecRichHeader AS c ON a.RecKey = c.RecKey
           JOIN
           tblLines AS d ON c.LineKey = d.LineKey
           JOIN
           tblPlots AS e ON d.PlotKey = e.PlotKey
           JOIN
           tblSites AS f ON e.SiteKey = f.SiteKey
           JOIN
           tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
           JOIN
           SpeciesTags AS h ON a.SpeciesCode = h.SpeciesCode
           LEFT JOIN
           CodeTags AS i ON g.Duration = i.Code
           JOIN
           Duration_SpeciesTags_Combinations_Use AS k ON h.Tag = k.SpeciesTag AND 
                                                         i.Tag = k.DurationTag
     WHERE i.Category = 'Duration' AND 
           c.FormDate BETWEEN (
                                  SELECT StartDate
                                    FROM Data_DateRange
                                   WHERE rowid = 1
                              )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY f.SiteKey,
              e.PlotKey,
              d.LineKey,
              a.RecKey,
              a.SubPlotID,
              h.Tag,
              g.Duration
    UNION-- Species Tag
    SELECT f.SiteKey AS SiteKey,
           e.PlotKey AS PlotKey,
           d.LineKey AS Linekey,
           a.RecKey AS RecKey,
           f.SiteID AS SiteID,
           f.SiteName AS SiteName,
           e.PlotID AS PlotID,
           d.LineID AS LineID,
           c.FormDate AS FormDate,
           a.SubPlotID,
           'Species Tag' AS IndicatorCategory,
           'All' AS Duration,
           h.Tag AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_Raw AS a
           JOIN
           tblSpecRichHeader AS c ON a.RecKey = c.RecKey
           JOIN
           tblLines AS d ON c.LineKey = d.LineKey
           JOIN
           tblPlots AS e ON d.PlotKey = e.PlotKey
           JOIN
           tblSites AS f ON e.SiteKey = f.SiteKey
           JOIN
           tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
           JOIN
           SpeciesTags AS h ON a.SpeciesCode = h.SpeciesCode
           JOIN
           Duration_SpeciesTags_Combinations_Use_Count AS k ON h.Tag = k.SpeciesTag
     WHERE k.DurationCount > 1 AND 
           c.FormDate BETWEEN (
                                  SELECT StartDate
                                    FROM Data_DateRange
                                   WHERE rowid = 1
                              )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY f.SiteKey,
              e.PlotKey,
              d.LineKey,
              a.RecKey,
              a.SubPlotID,
              h.Tag
    UNION-- Total
    SELECT f.SiteKey AS SiteKey,
           e.PlotKey AS PlotKey,
           d.LineKey AS Linekey,
           a.RecKey AS RecKey,
           f.SiteID AS SiteID,
           f.SiteName AS SiteName,
           e.PlotID AS PlotID,
           d.LineID AS LineID,
           c.FormDate AS FormDate,
           a.subPlotID,
           'Total' AS IndicatorCategory,
           'NA' AS Duration,
           'Total' AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_Raw AS a
           JOIN
           tblSpecRichHeader AS c ON a.RecKey = c.RecKey
           JOIN
           tblLines AS d ON c.LineKey = d.LineKey
           JOIN
           tblPlots AS e ON d.PlotKey = e.PlotKey
           JOIN
           tblSites AS f ON e.SiteKey = f.SiteKey
           JOIN
           tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
     WHERE c.FormDate BETWEEN (
                                  SELECT StartDate
                                    FROM Data_DateRange
                                   WHERE rowid = 1
                              )
           AND (
                   SELECT EndDate
                     FROM Data_DateRange
                    WHERE rowid = 1
               )
     GROUP BY f.SiteKey,
              e.PlotKey,
              d.LineKey,
              a.RecKey,
              a.subPlotID
     ORDER BY SiteID,
              PlotID,
              LineID,
              FormDate,
              a.SubPlotID,
              IndicatorCategory,
              Indicator;
			  
-- View: SR_Tag
CREATE VIEW SR_Tag AS
    SELECT a.*,
           CASE WHEN b.Plot_n IS NULL THEN 0 ELSE b.Plot_n END AS Plot_n,
           CASE WHEN b.MeanSpecies_n IS NULL THEN 0 ELSE b.MeanSpecies_n END AS MeanSpecies_n
      FROM SR_Tag_Count AS a
           JOIN
           SR_Tag_Mean AS b ON a.Tag = b.Tag AND 
                               a.Duration = b.Duration AND 
                               a.Indicator = b.Indicator
     ORDER BY a.Tag,
              a.IndicatorCategory,
              a.Duration,
              a.Indicator;
			  
-- View: SR_Tag_Count
CREATE VIEW SR_Tag_Count AS
    SELECT Tag,
           'Species' AS IndicatorCategory,
           Duration,
           SpeciesName AS Indicator,
           1 AS Species_n
      FROM SR_List_Tag
    UNION-- Growth Habit Sub Duration
    SELECT a.Tag AS Tag,
           'Growth Habit' AS IndicatorCategory,
           b.Tag AS Duration,
           c.Tag AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Tag AS a
           JOIN
           CodeTags AS b ON a.Duration = b.Code
           JOIN
           CodeTags AS c ON a.GrowthHabitSub = c.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use AS d ON b.Tag = d.DurationTag AND 
                                                            c.Tag = d.GHTag
     WHERE b.Category = 'Duration' AND 
           c.Category = 'GrowthHabitSub'
     GROUP BY a.Tag,
              Duration,
              Indicator
    UNION-- Growth Habit Sub
    SELECT a.Tag AS Tag,
           'Growth Habit' AS IndicatorCategory,
           'All' AS Duration,
           b.Tag AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Tag AS a
           JOIN
           CodeTags AS b ON a.GrowthHabitSub = b.Code
           JOIN
           Duration_GrowthHabitSub_Combinations_Use_Count AS c ON b.Tag = c.GHTag
     WHERE b.Category = 'GrowthHabitSub' AND 
           c.GHCount > 1
     GROUP BY a.Tag,
              Indicator
    UNION-- Lignification Duration
    SELECT a.Tag AS Tag,
           'Lignification' AS IndicatorCategory,
           b.Tag AS Duration,
           c.Tag AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Tag AS a
           JOIN
           CodeTags AS b ON a.Duration = b.Code
           JOIN
           CodeTags AS c ON a.GrowthHabit = c.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use AS d ON b.Tag = d.DurationTag AND 
                                                         c.Tag = d.GHTag
     WHERE b.Category = 'Duration' AND 
           c.Category = 'GrowthHabit'
     GROUP BY a.Tag,
              Duration,
              Indicator
    UNION-- Lignification
    SELECT a.Tag AS Tag,
           'Lignification' AS IndicatorCategory,
           'All' AS Duration,
           b.Tag AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Tag AS a
           JOIN
           CodeTags AS b ON a.GrowthHabit = b.Code
           JOIN
           Duration_GrowthHabit_Combinations_Use_Count AS c ON b.Tag = c.GHTag
     WHERE b.Category = 'GrowthHabit' AND 
           c.DurationCount > 1
     GROUP BY a.Tag,
              Indicator
    UNION-- Species Tag Duration
    SELECT a.Tag AS Tag,
           'Species Tag' AS IndicatorCategory,
           b.Tag AS Duration,
           c.Tag AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_List_Tag AS a
           JOIN
           CodeTags AS b ON a.Duration = b.Code
           JOIN
           SpeciesTags AS c ON a.SpeciesCode = c.SpeciesCode
           JOIN
           Duration_SpeciesTags_Combinations_Use AS d ON b.Tag = d.DurationTag AND 
                                                         c.Tag = d.SpeciesTag
     WHERE b.Category = 'Duration'
     GROUP BY a.Tag,
              Duration,
              Indicator
    UNION-- Species Tag
    SELECT a.Tag AS Tag,
           'Species Tag' AS IndicatorCategory,
           'All' AS Duration,
           b.Tag AS Indicator,
           Count(a.SpeciesCode) AS Species_n
      FROM SR_List_Tag AS a
           JOIN
           SpeciesTags AS b ON a.SpeciesCode = b.SpeciesCode
           JOIN
           Duration_SpeciesTags_Combinations_Use_Count AS c ON b.Tag = c.SpeciesTag
     WHERE c.DurationCount > 1
     GROUP BY a.Tag,
              Indicator
    UNION-- Total
    SELECT Tag,
           'Total' AS IndicatorCategory,
           'NA' AS Duration,
           'Total' AS Indicator,
           Count(SpeciesCode) AS Species_n
      FROM SR_List_Tag
     GROUP BY Tag
     ORDER BY Tag,
              IndicatorCategory,
              Duration,
              Indicator;
			  
-- View: SR_Tag_Mean
CREATE VIEW SR_Tag_Mean AS
    SELECT x.Tag AS Tag,
           x.IndicatorCategory AS IndicatorCategory,
           x.Duration AS Duration,
           x.Indicator AS Indicator,
           Count(x.PlotKey) AS Plot_n,
           meanw(CASE WHEN y.Species_n IS NULL THEN 0 ELSE y.Species_n END, x.Weight) AS MeanSpecies_n
      FROM (
               SELECT a.*,
                      b.IndicatorCategory,
                      b.Duration,
                      b.Indicator
                 FROM (
                          SELECT r.Tag,
                                 r.Weight,
                                 q.PlotKey,
                                 q.PlotID,
                                 q.Season
                            FROM SR_Plot AS q
                                 JOIN
                                 PlotTags AS r ON q.PlotKey = r.PlotKey
                           GROUP BY r.Tag,
                                    q.PlotKey,
                                    q.Season
                      )
                      AS a
                      JOIN
                      (
                          SELECT r.Tag,
                                 q.IndicatorCategory,
                                 q.Duration,
                                 q.Indicator
                            FROM SR_Plot AS q
                                 JOIN
                                 PlotTags AS r ON q.PlotKey = r.PlotKey
                           GROUP BY r.Tag,
                                    q.IndicatorCategory,
                                    q.Duration,
                                    q.Indicator
                      )
                      AS b ON a.Tag = b.Tag
           )
           AS x
           LEFT JOIN
           SR_Plot AS y ON x.PlotKey = y.PlotKey AND 
                           x.Season = y.Season AND 
                           x.Duration = y.Duration AND 
                           x.Indicator = y.Indicator
     GROUP BY x.Tag,
              x.Duration,
              x.Indicator
     ORDER BY x.Tag,
              x.IndicatorCategory,
              x.Duration,
              x.Indicator;
			  
-- View: UnitConversion_Use
CREATE VIEW UnitConversion_Use AS
    SELECT *
      FROM UnitConversion
     WHERE MeasureChoice = (
                               SELECT Value
                                 FROM Data_DBconfig
                                WHERE VariableName = 'units'
                           );

--Exports_All
CREATE VIEW Exports_All AS
SELECT Category, DataType, Scale, ObjectName, ExportName, Null AS Function, Null AS QueryOrder
  FROM Exports
 UNION
SELECT 'QAQC' AS Category, Method AS DataType, 'Raw' AS Scale, QueryName AS ObjectName, ExportID As ExportName, Function, QueryOrder
  FROM QAQC_Queries
 WHERE use_check = 1
 ORDER BY Category, DataType, Scale, Function, QueryOrder;	
 
COMMIT TRANSACTION; 

PRAGMA foreign_keys = on;