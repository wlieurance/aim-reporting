PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- View: CodeTags_CodeCount
/* Counts the number of Tags for each Category and Tag. Used for the Duration_GrowthHabit_Combinations type Views. */
CREATE VIEW IF NOT EXISTS CodeTags_CodeCount AS
    SELECT Category,
           Tag,
           Count(Code) AS CodeCount
      FROM CodeTags
     GROUP BY Category,
              Tag
     ORDER BY Category,
              Tag;
			  
-- View: CodeTags_Grouped
/* Similar to CodeTags_CodeCount but restricts results to only Use = 1 tags. Used for the LPI_Line_IndicatorsCartesian view. */
CREATE VIEW IF NOT EXISTS CodeTags_Grouped AS
    SELECT Category,
           Tag
      FROM CodeTags
     WHERE Use = 1
     GROUP BY Tag,
              Category
     ORDER BY Category,
              Tag;
			  			  
-- View: Cover_Plot
/* The final Plot level product for Cover. Gets cover information from LPI and LI penultimate products. Uses Seasons to delineate multiple 
 samples of the same plots. */
CREATE VIEW IF NOT EXISTS Cover_Plot AS
SELECT SiteKey, PlotKey, SiteID, PlotID,
      (SELECT SeasonLabel FROM SeasonDefinition WHERE FormDate BETWEEN SeasonStart AND SeasonEnd) AS Season,
       Method, Duration, IndicatorCategory, Indicator, HitCategory,
       Count(LineKey) AS Line_n, Avg(CoverPct) AS CoverPctMean,
       stdev(CoverPct) AS CoverPctSD, Avg(ChkPct) AS ChkPctMean,
       stdev(ChkPct) AS ChkPctSD
  FROM Cover_Line
 GROUP BY SiteKey, PlotKey, Season, Method, Duration,
          IndicatorCategory, Indicator, HitCategory
 ORDER BY SiteID, PlotID, Season, Method, IndicatorCategory,
          Indicator, HitCategory, Duration;
			  
-- View: Cover_Tag
/* Final product for Cover on the above-plot level. Uses weighted mean and standard deviation functions given in the classes.py file. 
Missing cover values are replaced by a zero. Missing Chkbox values remain NULL. */
CREATE VIEW IF NOT EXISTS Cover_Tag AS
SELECT Tag, Method, Duration, IndicatorCategory, Indicator, HitCategory,
       count(CoverPctMean) AS cover_n, meanw(CoverPctMean, Weight) AS CoverPctMean, stdevw(CoverPctMean, Weight) AS CoverPctSD,
       count(ChkPctMean) AS chk_n, meanw(ChkPctMean, Weight) AS ChkPctMean, stdevw(ChkPctMean, Weight) AS ChkPctSD
  FROM 
       (SELECT a.*,
               CASE WHEN b.CoverPctMean IS NULL THEN 0 ELSE b.CoverPctMean END AS CoverPctMean, 
               b.ChkPctMean
          FROM Cover_Tag_Indicators_Plot AS a
          LEFT JOIN Cover_Plot AS b 
            ON a.PlotKey = b.PlotKey AND
               a.Season = b.Season AND
               a.Method = b.Method AND
               a.Duration = b.Duration AND
               a.IndicatorCategory = b.IndicatorCategory AND
               a.Indicator = b.Indicator AND
               a.HitCategory = b.Hitcategory) AS x
 GROUP BY Tag, Method, Duration, IndicatorCategory, Indicator, HitCategory
 ORDER BY Tag, Method, Duration, IndicatorCategory, Indicator, HitCategory;
			  
-- View: Dimensions_Line
/* The final Line level product for Dimension. Gets dimension information from LPI and LI penultimate products. */
CREATE VIEW IF NOT EXISTS Dimensions_Line AS
SELECT a.SiteKey, a.PlotKey, a.LineKey, b.RecKey, a.SiteID, a.PlotID, a.LineID, b.FormDate, b.Method, 
       b.HitCategory AS MethodCategory, 
       b.LineSize, LineSizeUnits, Duration, IndicatorCategory, Indicator, 
       'Height' AS Dimension, 
       b.HeightMean AS DimMean,
       b.HeightUnits AS DimUnits
  FROM joinSitePlotLine AS a
 INNER JOIN LPI_Line_IndicatorsCalc AS b ON a.LineKey = b.LineKey
 WHERE HeightMean IS NOT NULL

 UNION ALL
SELECT SiteKey, PlotKey, LineKey, RecKey, SiteID, PlotID, LineID, FormDate, Method,
       HitCategory AS MethodCategory,
       LineSize, LineSizeUnits, Duration, IndicatorCategory, Indicator, Dimension, DimMean, DimUnits
  FROM LI_Line_Height

 UNION ALL
SELECT SiteKey, PlotKey, LineKey, RecKey, SiteID, PlotID, LineID, FormDate, Method,
       HitCategory AS MethodCategory,
       LineSize, LineSizeUnits, Duration, IndicatorCategory, Indicator, Dimension, DimMean, DimUnits
  FROM LI_Line_Length
 ORDER BY SiteID, PlotID, LineID, FormDate, Method, MethodCategory, IndicatorCategory, HitCategory,
       Dimension, Indicator, Duration;
			  
-- View: Dimensions_Plot
/* The final Plot level product for Dimension. Gets dimension information from LPI and LI penultimate products. Uses Seasons to delineate multiple 
 samples of the same plots. */
CREATE VIEW IF NOT EXISTS Dimensions_Plot AS
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
/* Final product for Dimension on the above-plot level. Uses weighted mean and standard deviation functions given in the classes.py file. */
CREATE VIEW IF NOT EXISTS Dimensions_Tag AS
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
/* Used as an intial way to construct viable combinations of Durations and GrowthHabits, converting Durations via CodeTags. 
Assumes that the Duration_GrowthHabit_Combinations table is populated. This methodlology is not as robust as the GrowthHabitSub 
versions of this methodology because it assumes that there are no combinationCodeTags for the GrowthHabit codes woody and non-woody 
(e.g. Woody_Non-woody). If this were to change in the future, then this methodology would have to be altered to reflect the 
GrowthHabitSub version. It was left this way for simplicity, and because future Tags of this sort seem unlikely to be needed.*/
CREATE VIEW IF NOT EXISTS Duration_GrowthHabit_Combinations_ghTags AS
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
/* Filters out any combinations of Duration and GrowthHabit that are not valid. In practice this is likely to be none.  For a better example 
of how this methodology is supposed to work, see the Duration_GrowthHabitSub_Combinations_Final view description. */
CREATE VIEW IF NOT EXISTS Duration_GrowthHabit_Combinations_Use AS
    SELECT a.*,
           b.CodeCount,
           (TagCount / CodeCount) AS TagUse
      FROM Duration_GrowthHabit_Combinations_ghTags AS a
           JOIN
           CodeTags_CodeCount AS b ON a.DurationTag = b.Tag
     WHERE TagUse = 1;
	 
-- View: Duration_GrowthHabit_Combinations_Use_Count
/* Provides a simple and easy to utilize list of valid GrowthHabits where Duration is not being considered. Also provides a way to parse out 
which GrowthHabits need to be in queries that construct an 'All' duration.  If a GrowthHabit has a duration count of 1, it is left out of 
constructors of the 'All' duration because identical data exists for it in the duration specific version of that query.*/
CREATE VIEW IF NOT EXISTS Duration_GrowthHabit_Combinations_Use_Count AS
    SELECT GHTag,
           Count(DurationTag) AS DurationCount
      FROM Duration_GrowthHabit_Combinations_Use
     GROUP BY GHTag
     ORDER BY GHTag;
	 
-- View: Duration_GrowthHabitSub_Combinations_AllTags
/* Passes the results from Duration_GrowthHabitSub_Combinations_ghTags through CodeTags, providing duration code tags. This results in 
all combinations of GrowthHabitSub (and all of its Tags) and Duration (and all of its Tags). */
CREATE VIEW IF NOT EXISTS Duration_GrowthHabitSub_Combinations_AllTags AS
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
/* Serves as a filter to remove non-valid combinations of duration and growth habit. For instance, the 'shrub' growth habit may have the duration 
of 'perennial' in the list of valid durations given in Duration_GrowthHabit_Combinations.  The duration of 'perennial' may be mapped to the tag 
'Biennial_Perennial in CodeTags, thus we could end up with a combination of 'Shrub' and 'Biennial_Perennial' if we were using that particular code tag. 
Biennial is not listed in the Duration_GrowthHabit_Combinations table as an available duration for Shrub, thus we would not want to use that particular 
Code Tag for this Growth Habit. Biennial_Perennial may be a vaild tag for the a forb, because forbs can be either of those things.  Using the dividing of 
the Count of that duration in CodeTags and that duration's Count in Duration_GrowthHabitSub_Combinations_ghTags provides a method of filtration. 
If the 'DurationTagCount' is < the 'CodeCount' then one of the amalgamated durations from CodeTags is not proper for this growth habit and we can remove 
it (UseDurationTag must equal 1). This convoluted methodology is only necessary due to the use of the CodeTag table to amalgumate durations together. 
Without the CodeTags table introducing complexity (and also useful functionality) we could just use the Duration_GrowthHabit_Combinations table directly. */
CREATE VIEW IF NOT EXISTS Duration_GrowthHabitSub_Combinations_Final AS
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
/* Used as an intial way to construct viable combinations of Durations and GrowthHabitSubs (after those growth habits have passed through the 
CodeTags table for conversion, i.e includes both 'Shrub' and 'Shrub_SubShrub' as growth habits if 'Shrub_SubShrub' is a 
Code Tag of 'Shrub'). Assumes that the Duration_GrowthHabit_Combinations table is populated. */
CREATE VIEW IF NOT EXISTS Duration_GrowthHabitSub_Combinations_ghTags AS
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
/* While all 'valid' GrowthHabitSub and Durations have been combined in Duration_GrowthHabitSub_Combinations_Final, they still need to be 
filtered out by the 'Use' field in CodeTags, which tells the query whether or not the database wants to use that particular Tag. This view accomplishes 
that. */
CREATE VIEW IF NOT EXISTS Duration_GrowthHabitSub_Combinations_Use AS
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
/* Provides a simple and easy to utilize list of valid GrowthHabitSubs where Duration is not being considered. Also provides a way to parse out 
which GrowthHabitSubs need to be in queries that construct an 'All' duration.  If a GrowthHabitSub has a duration count of 1, it is left out of 
constructors of the 'All' duration because identical data exists for it in the duration specific version of that query.*/
CREATE VIEW IF NOT EXISTS Duration_GrowthHabitSub_Combinations_Use_Count AS
    SELECT GHTag,
           Count(GHTag) AS GHCount
      FROM Duration_GrowthHabitSub_Combinations_Use
     GROUP BY GHTag
     ORDER BY GHTag;
	 
-- View: Duration_SpeciesTags
/* Provides a list of combination of species tags and durations.  Only returns existing combinations. This assumes an error free Species List. */
CREATE VIEW IF NOT EXISTS Duration_SpeciesTags AS
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
/* Passes the results of Duration_SpeciesTags through CodeTags to get Duration Code Tags marked as Use. */
CREATE VIEW IF NOT EXISTS Duration_SpeciesTags_Combinations_Use AS
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
/* Provides a simple and easy to utilize list of valid SpeciesTags where Duration is not being considered. Also provides a way to parse out 
which SpeciesTags need to be in queries that construct an 'All' duration.  If a SpeciesTag has a duration count of 1, it is left out of 
constructors of the 'All' duration because identical data exists for it in the duration specific version of that query.*/
CREATE VIEW IF NOT EXISTS Duration_SpeciesTags_Combinations_Use_Count AS
    SELECT SpeciesTag,
           Count(DurationTag) AS DurationCount
      FROM Duration_SpeciesTags_Combinations_Use
     GROUP BY SpeciesTag
     ORDER BY SpeciesTag;
	 
-- View: IIRH_Raw
/* Provides a raw IIRH output for reports. */
CREATE VIEW IF NOT EXISTS IIRH_Raw AS
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
/* A simple constructor joining Sites and Plots. Used as a base for other views. */
CREATE VIEW IF NOT EXISTS joinSitePlot AS
    SELECT a.SiteKey,
           a.SiteID,
           a.SiteName,
           b.PlotKey,
           b.PlotID
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999')
	 ORDER BY SiteID, PlotID;
	 
-- View: joinSitePlotLine
/* A simple constructor joining Sites, Plots and Lines. Used as a base for other views. */
CREATE VIEW IF NOT EXISTS joinSitePlotLine AS
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
     WHERE a.SiteKey NOT IN ('888888888', '999999999')
	 ORDER BY SiteID, PlotID, LineID;
	 
-- View: LI_Detail_View
/* This view serves as a way to combine Detail table information for Gap Intercept, Continuous Line Intercept, and Canopy Gap w/ Species.
As they are all very similar line intercept methods, it makes sense to process them together. */
CREATE VIEW IF NOT EXISTS LI_Detail_View AS
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
/* This view serves as a way to combine Header table information for Gap Intercept, Continuous Line Intercept, and Canopy Gap w/ Species.
As they are all very similar line intercept methods, it makes sense to process them together. */
CREATE VIEW IF NOT EXISTS LI_Header_View AS
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
/* Splits off LI Pct Cover information and formats it so it can be a precursor to the final products. */
CREATE VIEW IF NOT EXISTS LI_Line_Cover AS
SELECT a.SiteKey, a.PlotKey, a.LineKey, b.RecKey, a.SiteID, a.PlotID, a.LineID, b.FormDate,
       c.Method, c.LineLengthAmount AS LineSize, c.LengthUnits AS LineSizeUnits, c.Duration,
       c.IndicatorCategory, c.Indicator, c.InterceptType AS HitCategory, c.LengthSum AS IndicatorSum,
       c.PctCover AS CoverPct, c.ChkBoxMean AS ChkPct
  FROM joinSitePlotLine AS a
 INNER JOIN LI_Header_View AS b ON a.LineKey = b.LineKey
 INNER JOIN LI_LineCalc AS c ON b.RecKey = c.RecKey AND b.Method = c.Method
 ORDER BY a.SiteID, a.PlotID, a.LineID, b.FormDate, c.Method, c.IndicatorCategory, c.Indicator, c.Duration;
			  
-- View: LI_Line_Height
/* Splits off LI Height information and formats it so it can be a precursor to the final products. */
CREATE VIEW IF NOT EXISTS LI_Line_Height AS
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
      FROM joinSitePlotLine AS a
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
			  
-- View: LI_Line_Length
/* Splits off LI Length information and formats it so it can be a precursor to the final products. */
CREATE VIEW IF NOT EXISTS LI_Line_Length AS
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
      FROM joinSitePlotLine AS a
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
/* Takes the calculated LI indicators and converts to the correct units (if necessary) and also calculates percent cover. */
CREATE VIEW IF NOT EXISTS LI_LineCalc AS
SELECT a.LineKey, b.RecKey, b.Method,
           b.SegType AS InterceptType,
           (a.LineLengthAmount * c.ConvertFactor) AS LineLengthAmount,
           d.FinalUnits AS LengthUnits,
           b.IndicatorCategory, b.Duration, b.Indicator,
           (b.LengthMean * d.ConvertFactor) AS LengthMean,
           (b.LengthSum * d.ConvertFactor) AS LengthSum,
           (CAST ( (b.LengthSum * d.ConvertFactor) AS REAL) / 
                 (a.LineLengthAmount * c.ConvertFactor) ) AS PctCover,
           (b.HeightMean * e.ConvertFactor) AS HeightMean,
           e.FinalUnits AS HeightUnit, b.ChkBoxMean
  FROM LI_Header_View AS a
 INNER JOIN LI_LineSum_Indicators AS b ON a.RecKey = b.RecKey AND a.Method = b.Method
  LEFT JOIN UnitConversion_Use AS c ON a.LineLengthUnit = c.Units
  LEFT JOIN UnitConversion_Use AS d ON a.SegUnit = d.Units
  LEFT JOIN UnitConversion_Use AS e ON a.HeightUnit = e.Units;
  
 --View: LI_Line_IndicatorsCartesian
/* Creates a full list of Iindicators for the LI methods. DEPRECATED */
SELECT a.RecKey, a.Method, a.SegType, b.IndicatorCategory, b.Duration, b.Indicator
  FROM LI_PlotsLinesForms AS a,
       NonSpeciesIndicators AS b
 WHERE a.Method = 'Continuous Line Intercept' AND b.IndicatorCategory <> 'Gap'

 UNION
SELECT a.RecKey, a.Method, a.SegType, b.IndicatorCategory, b.Duration, b.Indicator
  FROM LI_PlotsLinesForms AS a,
       NonSpeciesIndicators AS b
 WHERE a.Method = 'Canopy Gap with Species'

 UNION
SELECT a.RecKey, a.Method, a.SegType, b.IndicatorCategory, b.Duration, b.Indicator
  FROM LI_PlotsLinesForms AS a,
       NonSpeciesIndicators AS b
 WHERE a.Method = 'Gap Intercept' AND b.IndicatorCategory = 'Gap'

 UNION
SELECT y.RecKey, x.Method, x.SegType, x.IndicatorCategory, x.Duration, x.Indicator
  FROM
       (SELECT b.LineKey, a.Method, a.SegType, 'Species' AS IndicatorCategory, a.Duration, a.Indicator
          FROM LI_Plot_Species AS a
         INNER JOIN tblLines AS b ON a.PlotKey = b.PlotKey) AS x
 INNER JOIN LI_Header_View AS y ON x.LineKey = y.LineKey AND x.Method = y.Method
 GROUP BY y.RecKey, x.Method, x.SegType, x.IndicatorCategory, x.Duration, x.Indicator;
 
--View: LI_Line_Indicators_Plot
/* Creates a Plot/Method level set of indicators for later processing. Used to convert missind data to zeros later.*/
CREATE VIEW IF NOT EXISTS LI_Line_Indicators_Plot AS
SELECT z.RecKey, x.Method, x.SegType, x.IndicatorCategory, x.Duration, x.Indicator
FROM  (SELECT * 
         FROM (SELECT d.PlotKey, 
                       (SELECT SeasonLabel FROM SeasonDefinition WHERE FormDate BETWEEN SeasonStart AND SeasonEnd) AS Season,
                       a.Method, a.SegType, a.IndicatorCategory, a.Duration, a.Indicator
                 FROM LI_LineSum AS a
                INNER JOIN LI_Header_View AS b ON a.RecKey = b.RecKey
                INNER JOIN tblLines AS c ON b.LineKey = c.LineKey
                INNER JOIN tblPlots AS d ON c.PlotKey = d.PlotKey
               ) AS a
        GROUP BY PlotKey, Season, Method, SegType, IndicatorCategory, Duration, Indicator
      ) AS x
 INNER JOIN tblLines AS y ON x.PlotKey = y.PlotKey
 INNER JOIN LI_Header_View AS z ON y.LineKey = z.LineKey
 GROUP BY z.RecKey, x.Method, x.SegType, x.IndicatorCategory, x.Duration, x.Indicator;
		  
-- View: LI_LineSum_Indicators
/* Joins full indicator list for LI with existing Line data. Replaces NULL Lengths with zeros. */
CREATE VIEW IF NOT EXISTS LI_LineSum_Indicators AS
SELECT a.RecKey, a.Method, a.IndicatorCategory, a.Duration, a.Indicator, a.SegType,
       CASE WHEN b.LengthMean IS NULL THEN 0 
            ELSE b.LengthMean END AS LengthMean,
       CASE WHEN b.LengthSum IS NULL THEN 0 
            ELSE b.LengthSum END AS LengthSum,
       b.HeightMean,
       b.ChkBoxMean
  FROM LI_Line_Indicators_Plot AS a
  LEFT JOIN LI_LineSum AS b ON a.RecKey = b.RecKey AND 
                              a.Method = b.Method AND
                              a.IndicatorCategory = b.IndicatorCategory AND 
                              a.Duration = b.Duration AND 
                              a.Indicator = b.Indicator AND 
                              a.SegType = b.SegType;
			  
-- View: LI_Plot_Species
-- UNUSED
/* Creates a list of species used by each plot where LI is used. */
CREATE VIEW IF NOT EXISTS LI_Plot_Species AS
SELECT a.PlotKey, b.Method, c.SegType,
       CASE WHEN d.Duration IS NULL THEN 'NA' ELSE d.Duration END AS Duration,
       CASE WHEN d.CodeType = 'generic' THEN 'Unidentified ' || d.ScientificName || ' (' || d.SpeciesCode || ')' 
            WHEN (d.ScientificName IS NULL OR d.ScientificName = '') AND (d.CommonName IS NULL OR d.CommonName = '') THEN d.SpeciesCode 
            WHEN (d.ScientificName IS NULL OR d.ScientificName = '') THEN d.CommonName 
            WHEN d.CodeType = 'family' THEN d.Family || ' genus sp.' 
            WHEN d.CodeType = 'genus' THEN d.ScientificName || ' sp.' 
            ELSE d.ScientificName END AS Indicator
  FROM tblLines AS a
 INNER JOIN LI_Header_View AS b ON a.LineKey = b.LineKey
 INNER JOIN LI_Detail_View AS c ON b.RecKey = c.RecKey AND b.Method = c.Method
 INNER JOIN tblSpecies AS d ON c.Species = d.SpeciesCode
 WHERE d.SpeciesCode IS NOT NULL
 GROUP BY a.PlotKey, b.Method, Indicator;
			  
-- View: LI_PlotsLinesForms
/* Used as a precursor to construct an full indicator list for each line for Line Intercept methods. */
CREATE VIEW IF NOT EXISTS LI_PlotsLinesForms AS
SELECT a.SiteKey, a.PlotKey, a.LineKey, b.RecKey, a.SiteID, a.PlotID,  a.LineID,
       b.Method, b.FormDate, c.SegType
  FROM joinSitePlotLine AS a
 INNER JOIN LI_Header_View AS b ON a.LineKey = b.LineKey
 INNER JOIN LI_Detail_View AS c ON b.RecKey = c.RecKey
 GROUP BY a.SiteKey, a.PlotKey, a.LineKey, b.RecKey, b.Method, c.SegType;
			  
-- View: LI_Raw_Final
/* Constructs a recordset for the Line Intercept raw data report. */
CREATE VIEW IF NOT EXISTS LI_Raw_Final AS
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
/* Constructs a recordset for the Line Definition raw data report. */
CREATE VIEW IF NOT EXISTS Line_Definition AS
    SELECT c.SiteKey,
           b.PlotKey,
           a.LineKey,
           c.SiteID,
           c.SiteName,
           b.PlotID,
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
/* Serves to define what consitutes Cover, Bare, and Bare Litter cover types. Used to delineate surface categories in 
LPI_CanopyLayers_Point_SoilSurface_CvrCat */
CREATE VIEW IF NOT EXISTS LPI_CanopyDefinitions AS
SELECT *,
       CASE WHEN instr(CategoryConcat, 'Top') != 0 THEN 'Cover' 
            WHEN (instr(CategoryConcat, 'Top') = 0 AND instr(CategoryConcat, 'Lower') != 0) THEN 'Bare Litter' 
            ELSE 'Bare' END AS CvrCat
  FROM LPI_CanopyDefinitions_CategoryConcat;
			  
-- View: LPI_CanopyDefinitions_CategoryConcat
/* Essentially concats the existing LPI canopy layers from the raw LPI.  Provides a quick way of determining what data was found 
at each point and serves as a precursor to LPI_CanopyDefinitions */
CREATE VIEW IF NOT EXISTS LPI_CanopyDefinitions_CategoryConcat AS
SELECT RecKey, PointNbr,
       group_concat(Category, ';') AS CategoryConcat
  FROM LPI_CanopyLayers_Point_DB_RestrictDates
 GROUP BY RecKey, PointNbr;
			  
-- View: LPI_CanopyLayers_Point_DB_RestrictDates
/* Restricts LPI data by the allowed date range */
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_DB_RestrictDates AS
SELECT a.*
  FROM lpi_detail AS a
 INNER JOIN tblLPIHeader AS b ON a.RecKey = b. RecKey
 WHERE b.FormDate BETWEEN 
         (SELECT StartDate FROM Data_DateRange WHERE rowid = 1) AND
         (SELECT EndDate FROM Data_DateRange WHERE rowid = 1);
			  			  
-- View: LPI_CanopyLayers_Point_Duration_Foliar
/* Creates record set that shows whether each LPI point has or doesn't have foliar cover at it for each specific Duration. 
Uses the CodeTags table to define and convert durations (i.e. annual duration may become annual_biennial if set up that way 
in CodeTags). Each UNION provides a different Hit Category (First, Any, Basal, Height). See additional comments inside 
statement. */
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_Duration_Foliar AS
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
/* This statement is used to add instances of NULL species where there is a Woody Height, thus an implied perennial for the height. A similar statement for an Herbaceous Height field is not given due to the unknown duration of herbaceous hits (and this is a duration specific constructor). */
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
 GROUP BY RecKey, PointNbr, Duration, Indicator;
			  
-- View: LPI_CanopyLayers_Point_Duration_GrowthHabit
/* Serves to define whether each LPI point has GrowthHabit hit on it for a particular duration (i.e. woody vs non-woody). 
Uses the CodeTags table to define and convert durations (i.e. annual duration may become annual_biennial and similar combinations 
/ conversions could be done with GrowthHabit if set up that way in CodeTags). 
Also uses the Duration_GrowthHabit_Combinations_Use view to define desired GrowthHabit and duration combinations. 
(See Duration_GrowthHabit_Combinations_Use for more information). Results are given the 'Lignification' IndicatorCategory 
to more clearly differentiate the results from the GrowthHabitSub category (GrowthHabit -> Lignification and GrowthHabitSub -> 
Growth Habit).  Each UNIONED statement provides a separate Hit Category (Any, First, Basal, Height). See inside statement 
for further comment. */
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_Duration_GrowthHabit AS
SELECT RecKey, PointNbr,
       e.Tag AS Duration,
       'Lignification' AS IndicatorCategory,
       d.Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Any' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabit = d.Code
  LEFT JOIN CodeTags AS e ON b.Duration = e.Code
 INNER JOIN Duration_GrowthHabit_Combinations_Use AS f ON d.Tag = f.GHTag AND e.Tag = f.DurationTag
 WHERE d.Category = 'GrowthHabit' AND 
       e.Category = 'Duration' AND 
       a.Category IN ('Top', 'Lower', 'Surface') 
 GROUP BY a.RecKey, a.PointNbr, e.Tag, d.Tag

 UNION ALL
SELECT RecKey, PointNbr,
       e.Tag AS Duration,
       'Lignification' AS IndicatorCategory,
       d.Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'First' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabit = d.Code
  LEFT JOIN CodeTags AS e ON b.Duration = e.Code
 INNER JOIN Duration_GrowthHabit_Combinations_Use AS f ON d.Tag = f.GHTag AND e.Tag = f.DurationTag
 WHERE d.Category = 'GrowthHabit' AND 
       e.Category = 'Duration' AND 
       a.Category = 'Top'
 GROUP BY a.RecKey, a.PointNbr, e.Tag, d.Tag

 UNION ALL
SELECT RecKey, PointNbr,
       e.Tag AS Duration,
       'Lignification' AS IndicatorCategory,
       d.Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Basal' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabit = d.Code
  LEFT JOIN CodeTags AS e ON b.Duration = e.Code
 INNER JOIN Duration_GrowthHabit_Combinations_Use AS f ON d.Tag = f.GHTag AND e.Tag = f.DurationTag
 WHERE d.Category = 'GrowthHabit' AND 
       e.Category = 'Duration' AND 
       a.Category = 'Surface'
 GROUP BY a.RecKey, a.PointNbr, e.Tag, d.Tag

 UNION ALL
SELECT RecKey, PointNbr,
       e.Tag AS Duration,
       'Lignification' AS IndicatorCategory,
       d.Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Height' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabit = d.Code
  LEFT JOIN CodeTags AS e ON b.Duration = e.Code
 INNER JOIN Duration_GrowthHabit_Combinations_Use AS f ON d.Tag = f.GHTag AND e.Tag = f.DurationTag
 WHERE d.Category = 'GrowthHabit' AND 
       e.Category = 'Duration' AND 
       a.Category IN ('HeightWoody', 'HeightHerbaceous') 
 GROUP BY a.RecKey, a.PointNbr, e.Tag, d.Tag

 UNION ALL
/* Serves as a way to include null species records with a valid woody height entry. Herbaceous not included due to lack of implied duration information for herbaceous (this is a duration specific query). */
SELECT RecKey, PointNbr,
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
 GROUP BY RecKey, PointNbr, Indicator;
			  
-- View: LPI_CanopyLayers_Point_Duration_GrowthHabitSub
/* Serves to define whether each LPI point has GrowthHabitSub hit on it for a particular duration (i.e. forb, graminoid, etc.). 
Uses the CodeTags table to define and convert Duration and GrowthHabitSub(i.e. annual duration may become annual_biennial and 
Shrub and Sub-Shrub may be combined into Shrub_SubShrub if set up that way in CodeTags). 
Also uses the Duration_GrowthHabitSub_Combinations_Use view to define desired GrowthHabitSub and duration combinations. 
(See Duration_GrowthHabitSub_Combinations_Use for more information). Results are given the 'Growth Habit' IndicatorCategory 
to more clearly differentiate the results from the GrowthHabit category (GrowthHabit -> Lignification and GrowthHabitSub -> 
Growth Habit). Each UNIONED statement provides a separate Hit Category (Any, First, Basal, Height). */
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_Duration_GrowthHabitSub AS
SELECT RecKey, PointNbr,
       e.Tag AS Duration,
       'Growth Habit' AS IndicatorCategory,
       d.Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Any' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabitSub = d.Code
  LEFT JOIN CodeTags AS e ON b.Duration = e.Code
 INNER JOIN Duration_GrowthHabitSub_Combinations_Use AS f ON d.Tag = f.GHTag AND e.Tag = f.DurationTag
 WHERE d.Category = 'GrowthHabitSub' AND 
       e.Category = 'Duration' AND 
       a.Category IN ('Top', 'Lower', 'Surface') 
 GROUP BY a.RecKey, a.PointNbr, e.Tag, d.Tag

 UNION ALL

SELECT RecKey, PointNbr,
       e.Tag AS Duration,
       'Growth Habit' AS IndicatorCategory,
       d.Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'First' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabitSub = d.Code
  LEFT JOIN CodeTags AS e ON b.Duration = e.Code
 INNER JOIN Duration_GrowthHabitSub_Combinations_Use AS f ON d.Tag = f.GHTag AND e.Tag = f.DurationTag
 WHERE d.Category = 'GrowthHabitSub' AND 
       e.Category = 'Duration' AND 
       a.Category = 'Top'
 GROUP BY a.RecKey, a.PointNbr, e.Tag, d.Tag

 UNION ALL

SELECT RecKey, PointNbr,
       e.Tag AS Duration,
       'Growth Habit' AS IndicatorCategory,
       d.Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Basal' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabitSub = d.Code
  LEFT JOIN CodeTags AS e ON b.Duration = e.Code
 INNER JOIN Duration_GrowthHabitSub_Combinations_Use AS f ON d.Tag = f.GHTag AND e.Tag = f.DurationTag
 WHERE d.Category = 'GrowthHabitSub' AND 
       e.Category = 'Duration' AND 
       a.Category = 'Surface'
 GROUP BY a.RecKey, a.PointNbr, e.Tag, d.Tag

 UNION ALL

SELECT RecKey, PointNbr,
       e.Tag AS Duration,
       'Growth Habit' AS IndicatorCategory,
       d.Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Height' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabitSub = d.Code
  LEFT JOIN CodeTags AS e ON b.Duration = e.Code
 INNER JOIN Duration_GrowthHabitSub_Combinations_Use AS f ON d.Tag = f.GHTag AND e.Tag = f.DurationTag
 WHERE d.Category = 'GrowthHabitSub' AND 
       e.Category = 'Duration' AND 
       a.Category IN ('HeightWoody', 'HeightHerbaceous') 
 GROUP BY a.RecKey, a.PointNbr, e.Tag, d.Tag;
			  
-- View: LPI_CanopyLayers_Point_Duration_SpeciesTags
/* Serves to define whether each LPI point has Species Tag hit on it for a particular duration (defined in the SpeciesTags table). 
Uses the CodeTags table to define and convert durations (i.e. annual duration may become annual_biennial if set up that way 
in CodeTags). Also uses the Duration_SpeciesTags_Combinations_Use view to define desired species tags and duration combinations. 
(See Duration_SpeciesTags_Combinations_Use for more information). Each UNIONED statement provides a separate Hit Category 
(Any, First, Basal, Height). */
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_Duration_SpeciesTags AS
SELECT RecKey, PointNbr,
       d.Tag AS Duration,
       'Species Tag' AS IndicatorCategory,
       c.Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Any' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 INNER JOIN SpeciesTags AS c ON a.Species = c.SpeciesCode
 INNER JOIN CodeTags AS d ON b.Duration = d.Code
 INNER JOIN Duration_SpeciesTags_Combinations_Use AS e ON d.Tag = e.DurationTag AND c.Tag = e.SpeciesTag
 WHERE a.Category IN ('Top', 'Lower', 'Surface') 
 GROUP BY RecKey, PointNbr, d.Tag, c.Tag

 UNION ALL

SELECT RecKey, PointNbr,
       d.Tag AS Duration,
       'Species Tag' AS IndicatorCategory,
       c.Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'First' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 INNER JOIN SpeciesTags AS c ON a.Species = c.SpeciesCode
 INNER JOIN CodeTags AS d ON b.Duration = d.Code
 INNER JOIN Duration_SpeciesTags_Combinations_Use AS e ON d.Tag = e.DurationTag AND c.Tag = e.SpeciesTag
 WHERE a.Category = 'Top'
 GROUP BY RecKey, PointNbr, d.Tag, c.Tag

 UNION ALL

SELECT RecKey, PointNbr,
       d.Tag AS Duration,
       'Species Tag' AS IndicatorCategory,
       c.Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Basal' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 INNER JOIN SpeciesTags AS c ON a.Species = c.SpeciesCode
 INNER JOIN CodeTags AS d ON b.Duration = d.Code
 INNER JOIN Duration_SpeciesTags_Combinations_Use AS e ON d.Tag = e.DurationTag AND c.Tag = e.SpeciesTag
 WHERE a.Category = 'Surface'
 GROUP BY RecKey, PointNbr, d.Tag, c.Tag

 UNION ALL

SELECT RecKey, PointNbr,
       d.Tag AS Duration,
       'Species Tag' AS IndicatorCategory,
       c.Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Height' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 INNER JOIN SpeciesTags AS c ON a.Species = c.SpeciesCode
 INNER JOIN CodeTags AS d ON b.Duration = d.Code
 INNER JOIN Duration_SpeciesTags_Combinations_Use AS e ON d.Tag = e.DurationTag AND c.Tag = e.SpeciesTag
 WHERE a.Category IN ('HeightWoody', 'HeightHerbaceous') 
 GROUP BY RecKey, PointNbr, d.Tag, c.Tag;
			  
-- View: LPI_CanopyLayers_Point_Foliar
/* Serves to define whether each LPI point has foliar cover at it (non-duration specific). Each UNION provides a different 
Hit Category (First, Any, Basal, Height). See additional comments inside statement. */
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_Foliar AS
SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Cover' AS IndicatorCategory,
       'Foliar' AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Any' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
  LEFT JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 WHERE Category IN ('Top', 'Lower', 'Surface') AND 
       b.SpeciesCode IS NOT NULL
 GROUP BY RecKey, PointNbr, Indicator, HitCategory

 UNION ALL

SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Cover' AS IndicatorCategory,
       'Foliar' AS Indicator,
       ChkBox,
       Height,
       'First' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
  LEFT JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 WHERE Category = 'Top' AND b.SpeciesCode IS NOT NULL

 UNION ALL

SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Cover' AS IndicatorCategory,
       'Foliar' AS Indicator,
       ChkBox, Height,
       'Basal' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
  LEFT JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 WHERE Category = 'Surface' AND b.SpeciesCode IS NOT NULL
 
 UNION ALL

SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Cover' AS IndicatorCategory,
       'Foliar' AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Height' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
  LEFT JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 WHERE Category IN ('HeightWoody', 'HeightHerbaceous') 
 GROUP BY RecKey, PointNbr, Indicator, HitCategory
HAVING Height <> 0;
			  
-- View: LPI_CanopyLayers_Point_GroundCover
/* Serves to define whether each LPI point has ground cover at it. Uses the CodeTags table to define what non-species codes
constitute ground cover and includes any point with a valid species hit (in tblSpecies) also as ground cover. */
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_GroundCover AS
SELECT RecKey, PointNbr,
       'NA' AS Duration,
       'Cover' AS IndicatorCategory,
       'Ground Cover' AS Indicator,
       NULL AS ChkBox,
       NULL AS Height,
       'Any' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
  LEFT JOIN CodeTags AS b ON a.Species = b.Code
  LEFT JOIN tblSpecies AS c ON a.Species = c.SpeciesCode
 WHERE a.Category IN ('Lower', 'Surface') AND 
       (b.Category = 'Ground Cover' OR 
       (c.SpeciesCode IS NOT NULL AND 
       a.Category = 'Surface') ) AND 
       b.Use = 1
 GROUP BY RecKey, PointNbr, Indicator;
			  
-- View: LPI_CanopyLayers_Point_GrowthHabit
/* Serves to define whether each LPI point has GrowthHabit hit (i.e. woody vs non-woody). Not duration specific.  
Uses the CodeTags table to define and convert GrowthHabit (i.e. combinations/conversions could be done with GrowthHabit 
if set up that way in CodeTags). Also uses the Duration_GrowthHabit_Combinations_Use_Count view to define desired species tags, 
i.e. Tags with only a single duration are not used because their data already exists in the duration specific version of this query 
(e.g. All Sagebrush = Perennial Sagebrush)(See Duration_GrowthHabit_Combinations_Use_Count for more information). Results are given 
the 'Lignification' IndicatorCategory to more clearly differentiate the results from the GrowthHabitSub category 
(GrowthHabit -> Lignification and GrowthHabitSub -> Growth Habit).  Each UNIONED statement provides a separate Hit Category 
(Any, First, Basal, Height). See inside statement for further comment. */
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_GrowthHabit AS
SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Lignification' AS IndicatorCategory,
       Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Any' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabit = d.Code
  LEFT JOIN Duration_GrowthHabit_Combinations_Use_Count AS e ON e.GHTag = d.Tag
 WHERE d.Category = 'GrowthHabit' AND 
       d.Use = 1 AND 
       e.DurationCount > 1 AND 
       a.Category IN ('Top', 'Lower', 'Surface') 
 GROUP BY a.RecKey, a.PointNbr, d.Tag

UNION ALL
SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Lignification' AS IndicatorCategory,
       Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'First' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabit = d.Code
  LEFT JOIN Duration_GrowthHabit_Combinations_Use_Count AS e ON e.GHTag = d.Tag
 WHERE d.Category = 'GrowthHabit' AND 
       d.Use = 1 AND 
       e.DurationCount > 1 AND 
       a.Category = 'Top'
 GROUP BY a.RecKey, a.PointNbr, d.Tag

UNION ALL
SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Lignification' AS IndicatorCategory,
       Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Basal' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabit = d.Code
  LEFT JOIN Duration_GrowthHabit_Combinations_Use_Count AS e ON e.GHTag = d.Tag
 WHERE d.Category = 'GrowthHabit' AND 
       d.Use = 1 AND 
       e.DurationCount > 1 AND 
       a.Category = 'Surface'
 GROUP BY a.RecKey, a.PointNbr, d.Tag
 
 UNION ALL
SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Lignification' AS IndicatorCategory,
       Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Height' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabit = d.Code
  LEFT JOIN Duration_GrowthHabit_Combinations_Use_Count AS e ON e.GHTag = d.Tag
 WHERE d.Category = 'GrowthHabit' AND 
       d.Use = 1 AND 
       e.DurationCount > 1 AND 
       a.Category IN ('HeightWoody', 'HeightHerbaceous') 
 GROUP BY a.RecKey, a.PointNbr, d.Tag

 UNION ALL
/* This statement adds points that have a null species and a non-null, non-zero herbaceous heights to the non-woody indicator. This is similar to how the duration specific version of this view does so for woody (non-woody is not duration specific while woody is implied as perennial). */
SELECT RecKey, PointNbr,
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
 GROUP BY RecKey, PointNbr, Indicator;
			  
-- View: LPI_CanopyLayers_Point_GrowthHabitSub
/* Serves to define whether each LPI point has GrowthHabitSub hit (i.e. forb, shrub, etc.) Not duration specific.  
Uses the CodeTags table to define and convert GrowthHabitSub (i.e. Shrub and Sub-Shrub combined into Shrub_SubShrub if set 
up that way in CodeTags). Also uses the Duration_GrowthHabitSub_Combinations_Use_Count view to define desired species tags, 
i.e. Tags with only a single duration are not used because their data already exists in the duration specific version of 
this query (e.g. All Sagebrush = Perennial Sagebrush) (See Duration_GrowthHabitSub_Combinations_Use_Count 
for more information). Results are given the 'Growth Habit' IndicatorCategory to more clearly differentiate the results from the 
GrowthHabit category (GrowthHabit -> Lignification and GrowthHabitSub -> Growth Habit).  Each UNIONED statement provides a separate 
Hit Category (Any, First, Basal, Height). See inside statement 
for further comment. */
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_GrowthHabitSub AS
SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Growth Habit' AS IndicatorCategory,
       Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Any' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabitSub = d.Code
  LEFT JOIN Duration_GrowthHabitSub_Combinations_Use_Count AS e ON e.GHTag = d.Tag
 WHERE d.Category = 'GrowthHabitSub' AND 
       d.Use = 1 AND 
       e.GHCount > 1 AND 
       a.Category IN ('Top', 'Lower', 'Surface') 
 GROUP BY a.RecKey, a.PointNbr, d.Tag

 UNION ALL
SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Growth Habit' AS IndicatorCategory,
       Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'First' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabitSub = d.Code
  LEFT JOIN Duration_GrowthHabitSub_Combinations_Use_Count AS e ON e.GHTag = d.Tag
 WHERE a.Category = 'Top' AND 
       d.Category = 'GrowthHabitSub' AND 
       d.Use = 1 AND 
       e.GHCount > 1
 GROUP BY a.RecKey, a.PointNbr, d.Tag

 UNION ALL
SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Growth Habit' AS IndicatorCategory,
       Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Basal' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabitSub = d.Code
  LEFT JOIN Duration_GrowthHabitSub_Combinations_Use_Count AS e ON e.GHTag = d.Tag
 WHERE a.Category = 'Surface' AND 
       d.Category = 'GrowthHabitSub' AND 
       d.Use = 1 AND 
       e.GHCount > 1
 GROUP BY a.RecKey, a.PointNbr, d.Tag
 
 UNION ALL
SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Growth Habit' AS IndicatorCategory,
       Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Height' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
  LEFT JOIN CodeTags AS d ON c.GrowthHabitSub = d.Code
  LEFT JOIN Duration_GrowthHabitSub_Combinations_Use_Count AS e ON e.GHTag = d.Tag
 WHERE d.Category = 'GrowthHabitSub' AND 
       d.Use = 1 AND 
       e.GHCount > 1 AND 
       a.Category IN ('HeightWoody', 'HeightHerbaceous') 
 GROUP BY a.RecKey, a.PointNbr, d.Tag;
			  
-- View: LPI_CanopyLayers_Point_Litter
/* Gives information on whether Litter occurs at each LPI point.  Uses the CodeTags table to define what 'Litter' is.*/
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_Litter AS
SELECT RecKey, PointNbr,
       'NA' AS Duration,
       'Litter' AS IndicatorCategory,
       Tag AS Indicator,
       NULL AS ChkBox,
       NULL AS Height,
       'Any' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
  LEFT JOIN CodeTags AS b ON a.Species = b.Code
 WHERE a.Category = 'Lower' AND 
       b.Category = 'Litter' AND 
       b.Use = 1
 GROUP BY a.RecKey, a.PointNbr, b.Tag;
			  
-- View: LPI_CanopyLayers_Point_SoilSurface
/* Gives information on whether each LPI point has soil surface cover. Soil surface is either a basal species hit (in tblSpecies) 
or listed in the CodeTags table as a Soil Surface code.*/
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_SoilSurface AS
SELECT RecKey, PointNbr,
       'NA' AS Duration,
       'Soil Surface' AS IndicatorCategory,
       CASE WHEN b.Tag IS NULL THEN 'Basal' 
            ELSE b.Tag END AS Indicator,
       NULL AS ChkBox,
       NULL AS Height,
       'Any' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
  LEFT JOIN CodeTags AS b ON a.Species = b.Code
  LEFT JOIN tblSpecies AS c ON a.Species = c.SpeciesCode
 WHERE a.Category = 'Surface' AND 
       (b.Category = 'Soil Surface' OR 
       c.SpeciesCode IS NOT NULL) AND 
       b.Use = 1;
			  
-- View: LPI_CanopyLayers_Point_SoilSurface_CvrCat
/* Gives the same information as LPI_CanopyLayers_Point_SoilSurface but instead of 'Any' as a HitCategory, defines the HitCategory 
 as either Bare, Bare Litter, or cover, as determined by the LPI_CanopyDefinitions view.*/
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_SoilSurface_CvrCat AS
SELECT a.RecKey, a.PointNbr, a.Duration,
       'Soil Surface' AS IndicatorCategory,
       a.Indicator, a.ChkBox, a.Height,
       CvrCat AS HitCategory
  FROM LPI_CanopyLayers_Point_SoilSurface AS a
  LEFT JOIN LPI_CanopyDefinitions AS b ON a.RecKey = b.RecKey AND a.PointNbr = b.PointNbr
 WHERE a.Indicator <> 'Basal';
			  
-- View: LPI_CanopyLayers_Point_Species
/* Gives info on species which occur at each LPI point.  Each UNIONED statement provides a separate HitCatgory (Basal, Any First, Height) 
Most of the complexity of this view arrives from converting plant codes to formmated names. */
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_Species AS
SELECT RecKey, PointNbr,
       CASE WHEN Duration IS NULL THEN 'NA' 
            ELSE Duration END AS Duration,
       'Species' AS IndicatorCategory,
       CASE WHEN b.CodeType = 'generic' THEN 'Unidentified ' || b.ScientificName || ' (' || b.SpeciesCode || ')' 
            WHEN (b.ScientificName IS NULL OR b.ScientificName = '') AND (b.CommonName IS NULL OR b.CommonName = '') THEN b.SpeciesCode 
            WHEN (b.ScientificName IS NULL OR b.ScientificName = '') THEN b.CommonName 
            WHEN b.CodeType = 'family' THEN b.Family || ' genus sp.' 
            WHEN b.CodeType = 'genus' THEN b.ScientificName || ' sp.' 
                ELSE b.ScientificName END AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Any' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 WHERE a.Category IN ('Top', 'Lower', 'Surface') AND 
       a.Species <> 'None' AND 
       a.Species IS NOT NULL
 GROUP BY RecKey, PointNbr, Species
HAVING Indicator IS NOT NULL

 UNION ALL
SELECT RecKey, PointNbr,
       CASE WHEN Duration IS NULL THEN 'NA' 
            ELSE Duration END AS Duration,
       'Species' AS IndicatorCategory,
       CASE WHEN b.CodeType = 'generic' THEN 'Unidentified ' || b.ScientificName || ' (' || b.SpeciesCode || ')' 
            WHEN (b.ScientificName IS NULL OR b.ScientificName = '') AND (b.CommonName IS NULL OR b.CommonName = '') THEN b.SpeciesCode 
            WHEN (b.ScientificName IS NULL OR b.ScientificName = '') THEN b.CommonName 
            WHEN b.CodeType = 'family' THEN b.Family || ' genus sp.' 
            WHEN b.CodeType = 'genus' THEN b.ScientificName || ' sp.' 
            ELSE b.ScientificName END AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'First' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 WHERE Category = 'Top' AND 
       a.Species <> 'None' AND 
       a.Species IS NOT NULL
 GROUP BY RecKey, PointNbr, Species
HAVING Indicator IS NOT NULL

 UNION ALL
SELECT RecKey, PointNbr,
       CASE WHEN Duration IS NULL THEN 'NA' 
            ELSE Duration END AS Duration,
       'Species' AS IndicatorCategory,
       CASE WHEN b.CodeType = 'generic' THEN 'Unidentified ' || b.ScientificName || ' (' || b.SpeciesCode || ')' 
            WHEN (b.ScientificName IS NULL OR b.ScientificName = '') AND (b.CommonName IS NULL OR b.CommonName = '') THEN b.SpeciesCode 
            WHEN (b.ScientificName IS NULL OR b.ScientificName = '') THEN b.CommonName 
            WHEN b.CodeType = 'family' THEN b.Family || ' genus sp.' 
            WHEN b.CodeType = 'genus' THEN b.ScientificName || ' sp.' 
            ELSE b.ScientificName END AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Basal' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 WHERE Category = 'Surface' AND 
       a.Species <> 'None' AND 
       a.Species IS NOT NULL
 GROUP BY RecKey, PointNbr, Species
HAVING Indicator IS NOT NULL

 UNION ALL
SELECT RecKey, PointNbr,
       CASE WHEN Duration IS NULL THEN 'NA' 
            ELSE Duration END AS Duration,
       'Species' AS IndicatorCategory,
       CASE WHEN b.CodeType = 'generic' THEN 'Unidentified ' || b.ScientificName || ' (' || b.SpeciesCode || ')' 
            WHEN (b.ScientificName IS NULL OR b.ScientificName = '') AND (b.CommonName IS NULL OR b.CommonName = '') THEN b.SpeciesCode 
            WHEN (b.ScientificName IS NULL OR b.ScientificName = '') THEN b.CommonName 
            WHEN b.CodeType = 'family' THEN b.Family || ' genus sp.' 
            WHEN b.CodeType = 'genus' THEN b.ScientificName || ' sp.' 
            ELSE b.ScientificName END AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Height' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN tblSpecies AS b ON a.Species = b.SpeciesCode
 WHERE a.Category IN ('HeightHerbaceous', 'HeightWoody') AND 
       a.Species <> 'None' AND 
       a.Species IS NOT NULL
 GROUP BY RecKey, PointNbr, Species
HAVING Indicator IS NOT NULL;
			  
-- View: LPI_CanopyLayers_Point_SpeciesTags
/* Serves to define whether each LPI point has Species Tag hit on it (non-duration specific, defined in the SpeciesTags table). 
Also uses the Duration_SpeciesTags_Combinations_Use_Count view to define desired species tags, i.e. Tags with only a single duration 
are not used because their data already exists in the duration specific version of this query (e.g. All Sagebrush = Perennial Sagebrush). 
(See Duration_SpeciesTags_Combinations_Use_Count for more information). Each UNIONED statement provides a separate Hit Category 
(Any, First, Basal, Height). */
CREATE VIEW IF NOT EXISTS LPI_CanopyLayers_Point_SpeciesTags AS
SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Species Tag' AS IndicatorCategory,
       Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Any' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN SpeciesTags AS b ON a.Species = b.SpeciesCode
  LEFT JOIN Duration_SpeciesTags_Combinations_Use_Count AS c ON b.Tag = c.SpeciesTag
 WHERE a.Category IN ('Top', 'Lower', 'Surface') AND 
       c.DurationCount > 1
 GROUP BY a.RecKey, a.PointNbr, b.Tag

 UNION ALL
SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Species Tag' AS IndicatorCategory,
       Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
        Max(Height) AS Height,
        'First' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN SpeciesTags AS b ON a.Species = b.SpeciesCode
  LEFT JOIN Duration_SpeciesTags_Combinations_Use_Count AS c ON b.Tag = c.SpeciesTag
 WHERE a.Category = 'Top' AND 
       c.DurationCount > 1
 GROUP BY a.RecKey, a.PointNbr, b.Tag

 UNION ALL
SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Species Tag' AS IndicatorCategory,
       Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
        Max(Height) AS Height,
        'Basal' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN SpeciesTags AS b ON a.Species = b.SpeciesCode
  LEFT JOIN Duration_SpeciesTags_Combinations_Use_Count AS c ON b.Tag = c.SpeciesTag
 WHERE a.Category = 'Surface' AND 
        c.DurationCount > 1
 GROUP BY a.RecKey, a.PointNbr, b.Tag

 UNION ALL
SELECT RecKey, PointNbr,
       'All' AS Duration,
       'Species Tag' AS IndicatorCategory,
       Tag AS Indicator,
       Min(ChkBox) AS ChkBox,
       Max(Height) AS Height,
       'Height' AS HitCategory
  FROM LPI_CanopyLayers_Point_DB_RestrictDates AS a
 INNER JOIN SpeciesTags AS b ON a.Species = b.SpeciesCode
  LEFT JOIN Duration_SpeciesTags_Combinations_Use_Count AS c ON b.Tag = c.SpeciesTag
 WHERE a.Category IN ('HeightWoody', 'HeightHerbaceous') AND 
       c.DurationCount > 1
 GROUP BY a.RecKey, a.PointNbr, b.Tag;
			  
-- View: LPI_Line_Count
/* Serves as the primary GROUP BY function for converting LPI point information to line totals/averages. */
CREATE VIEW IF NOT EXISTS LPI_Line_Count AS
SELECT RecKey, Duration, IndicatorCategory, Indicator, HitCategory,
       Count(PointNbr) AS PointCount,
       Sum(CAST(ChkBox AS FLOAT))/Count(PointNbr) AS ChkPct,
       Avg(Height) AS HeightMean
  FROM LPI_Point_Indicators
 GROUP BY RecKey, IndicatorCategory, Indicator, Duration, HitCategory;
			  
-- View: LPI_Line_IndicatorsCalc
/* Serves as a way to combine a full indicator list with actual line data.  Indicators with a NULL point count are converted to a zero and hight 
units are converted at this time. Is the final LPI specific line data product. */
CREATE VIEW IF NOT EXISTS LPI_Line_IndicatorsCalc AS
SELECT a.PlotKey, a.LineKey, a.RecKey, a.FormDate,
       'Line-point Intercept' AS Method,
       a.PointCount AS LineSize,
       'points' AS LineSizeUnits,
       a.Duration, a.IndicatorCategory, a.Indicator, a.HitCategory,
       CASE WHEN b.PointCount IS NULL THEN 0 
            ELSE b.PointCount END AS IndicatorSum,
       CASE WHEN b.PointCount IS NULL THEN 0 
            ELSE (CAST (b.PointCount AS FLOAT) / a.PointCount) END AS CoverPct,
       b.ChkPct, b.HeightMean,
       CASE WHEN (SELECT Value FROM Data_DBconfig WHERE VariableName = 'units') = 'metric' THEN 'cm' 
            ELSE 'in' END AS HeightUnits
  FROM LPI_Line_IndicatorsCartesian AS a
  LEFT JOIN LPI_Line_Count AS b ON a.RecKey = b.RecKey AND 
                                   a.Duration = b.Duration AND 
                                   a.IndicatorCategory = b.IndicatorCategory AND 
                                   a.Indicator = b.Indicator AND 
                                   a.HitCategory = b.HitCategory;
			  
-- View: LPI_Line_IndicatorsCartesian
/* This view creates a recordset of all possible LPI indicators, durations and hit categories (at least those marked for use) and joins it
with site/plot/line info.  Serves as a constructor for the LPI_Line_IndicatorsCalc view. */
CREATE VIEW IF NOT EXISTS LPI_Line_IndicatorsCartesian AS
SELECT a.*,
       b.Tag AS Duration,
       'Cover' AS IndicatorCategory,
       'Foliar' AS Indicator,
       c.HitCategory AS HitCategory
  FROM LPI_Line_PointCount AS a,
       CodeTags_Grouped AS b,
       HitCategories AS c
 WHERE b.Category = 'Duration' AND c.Type = 'Foliar'

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
 INNER JOIN Duration_GrowthHabit_Combinations_Use_Count AS d ON b.Tag = d.GHTag
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
 INNER JOIN Duration_GrowthHabitSub_Combinations_Use_Count AS d ON b.Tag = d.GHTag
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
  LEFT JOIN LPI_Plot_Species AS c ON a.PlotKey = c.PlotKey
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
       b.DurationCount > 1;

-- View: LPI_Line_PointCount
/* Counts up the number of points per line/record for use in calculations. */
CREATE VIEW IF NOT EXISTS LPI_Line_PointCount AS
SELECT a.PlotKey, a.LineKey, b.RecKey, b.FormDate, Count(c.PointNbr) AS PointCount
  FROM tblLines AS a
 INNER JOIN tblLPIHeader AS b ON a.LineKey = b.LineKey
 INNER JOIN tblLPIDetail AS c ON b.RecKey = c.RecKey
 WHERE c.SoilSurface IS NOT NULL
 GROUP BY a.PlotKey, a.LineKey, b.RecKey;

-- View: LPI_Plot_Species
/* Serves as a precursor constructor to LPI_Line_IndicatorsCartesian view, giving a list of all species found on the plot for use in 
generating a total indicator list. */
CREATE VIEW IF NOT EXISTS LPI_Plot_Species AS
SELECT c.PlotKey, a.Duration, a.Indicator
  FROM LPI_CanopyLayers_Point_Species AS a
 INNER JOIN tblLPIHeader AS b ON a.RecKey = b.RecKey
 INNER JOIN tblLines AS c ON b.LineKey = c.LineKey
 WHERE a.HitCategory = 'Any'
 GROUP BY PlotKey, Duration, Indicator;
 
 --View: Cover_Tag_Indicators_Plot
 /* Creates a set of all Tag/Durations/Indicators/HitCategories present for every Plot/Method where if ther is multiple seasons gives 
 only the plot with the most reason season.  This is used as a precursor for Cover_Plot, such that missing cover indicators can be 
 replaced with a zero (i.e. an indicator was not found at a plot thus its cover value is zero). */
 CREATE VIEW IF NOT EXISTS Cover_Tag_Indicators_Plot AS
 SELECT x.Tag, x.Method, x.Duration, x.IndicatorCategory, x.Indicator, x.HitCategory, y.PlotKey, y.Season, y.Weight
  FROM 
       (SELECT b.Tag, a.Method, a.Duration, a.IndicatorCategory, a.Indicator, a.HitCategory
          FROM Cover_Plot AS a
         INNER JOIN PlotTags AS b ON a.PlotKey = b.PlotKey
         GROUP BY b.Tag, a.Method, a.Duration, a.IndicatorCategory, a.Indicator, a.HitCategory) AS x 
 INNER JOIN 
       (SELECT q.Tag, q.PlotKey, q.Weight, r.Method, Max(r.Season) AS Season
          FROM PlotTags AS q 
         INNER JOIN Cover_Plot AS r ON q.PlotKey = r.PlotKey
         GROUP BY q.Tag, q.PlotKey, q.Weight, r.Method) AS y ON x.Tag = y.Tag AND x.Method = y.Method;
 
-- View: LPI_Raw
/* Gives Raw LPI data for report output */
SELECT a.SiteKey, a.PlotKey, a.LineKey, b.RecKey, a.SiteID, a.SiteName, a.PlotID, a.LineID, b.FormDate, c.*
  FROM joinSitePlotLine AS a
 INNER JOIN tblLPIHeader AS b ON a.LineKey = b.LineKey
 INNER JOIN tblLPIDetail AS c ON b.RecKey = c.RecKey
 ORDER BY SiteID, PlotID, LineID, FormDate, PointLoc;

-- View: NonSpeciesIndicators
/* Constructs a list of non-species indicators for use in other queries. */
CREATE VIEW IF NOT EXISTS NonSpeciesIndicators AS
SELECT 'All' AS Duration,
       'Lignification' AS IndicatorCategory,
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
       'Lignification' AS IndicatorCategory,
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
  FROM CodeTags AS a, CodeTags AS b
 WHERE a.Category = 'Duration' AND 
       b.Category = 'Foliar' AND 
       a.Use = 1
 GROUP BY Duration, IndicatorCategory, Indicator

 UNION ALL
SELECT 'NA' AS Duration,
       Category AS IndicatorCategory,
        Code AS Indicator
  FROM CodeTags
 WHERE IndicatorCategory = 'Gap'

 UNION ALL
SELECT 'NA' AS Duration,
       a.Category AS IndicatorCategory,
       (a.Code || ' (' || b.StartOperator || b.StartLimit ||  
           CASE WHEN EndOperator IS NULL THEN ')' 
                ELSE ' to ' || EndOperator || EndLimit || ')' END) AS Indicator
  FROM CodeTags AS a, LI_SizeClasses AS b
 WHERE IndicatorCategory = 'Gap'

 UNION ALL
SELECT DurationTag AS Duration,
           'Species Tag' AS IndicatorCategory,
           SpeciesTag AS Indicator
  FROM Duration_SpeciesTags_Combinations_Use;
			  
-- View: PD_ClassLabels
/* Converts the wide view of Plant Density labels to a long view. */
CREATE VIEW IF NOT EXISTS PD_ClassLabels AS
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
/* Converts the wide view of the Plant Density Detail table to a long view, which is easier for processing. Also converts the subquad size to 
Square Meters if given in Square Feet. */
CREATE VIEW IF NOT EXISTS PD_Detail_Long AS
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
/* The workhorse of the Plant Density views. Calulates plants per hectare for the line for multiple indicators. Each UNIONED statement 
adds a different indicator to the line calulations. See inside statement for more comments.*/
CREATE VIEW IF NOT EXISTS PD_Line AS
    -- Species. Classes (provides class level data).
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
    UNION
    -- Species. Total (Provides a total number, across all classes).
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
    UNION
    -- Growth Habit (GrowthHabitSub). Classes. Uses CodeTags table to convert Durations and GrowthHabitSubs.
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
    UNION-- Growth Habit (GrowthHabitSub). Total.
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
    UNION
	-- Lignification (GrowthHabit). Classes.
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
    UNION
	-- Lignification *GrowthHabit). Total.
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
    UNION
	-- Species Tag. Classes.
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
    UNION
	-- Species Tag. Total.
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
/* Takes plant density line level data and averages by line. Requires stdev function to be loaded as an extension (classes.py). */
CREATE VIEW IF NOT EXISTS PD_Plot AS
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
/* Creates a raw data table for report purposes, and also as a precursor for further data processing. */
CREATE VIEW IF NOT EXISTS PD_Raw_Final AS
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
/* Averages plot level plant density data to the above plot level based on PlotTags.  Requires meanw and stdevw to be loaded as an 
extension (classes.py). */
CREATE VIEW IF NOT EXISTS PD_Tag AS
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
/* Creates a raw data output of plot definition data for report purposes. */
CREATE VIEW IF NOT EXISTS Plot_Definition AS
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
/* Creates a raw data ouput of plot notes for report purposes. */
CREATE VIEW IF NOT EXISTS Plot_Notes AS
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
			  
-- View: SoilPit_Raw
/* Creates a raw output of soil pit data for report purposes. */
CREATE VIEW IF NOT EXISTS SoilPit_Raw AS
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
/* Parses out soil stability data at a line level.  Soil stablity data is a plot level method, but contains line level information. 
Each UNIONED statement provides a separate line level indicator. Requires the stdev function to be loaded as an extention (classes.py). */
CREATE VIEW IF NOT EXISTS SoilStab_Line AS
	-- Growth Habit (from SoilStab_Codes).
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
           joinSitePlot AS d ON d.PlotKey = c.PlotKey
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
	-- Provides the Cover and No Cover indicators.
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
           joinSitePlot AS d ON d.PlotKey = c.PlotKey
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
	-- Provides a Total soil stability indicator (no classes).
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
           joinSitePlot AS d ON d.PlotKey = c.PlotKey
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
/* Provides Soil Stability data at a plot level. EACH UNIONED statement provides a different indicator. */
CREATE VIEW IF NOT EXISTS SoilStab_Plot AS
    -- Growth Habit
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
           joinSitePlot AS d ON d.PlotKey = c.PlotKey
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
	--Cover Indicator (Cover, No Cover).
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
           joinSitePlot AS d ON d.PlotKey = c.PlotKey
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
	--Total (classless).
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
           joinSitePlot AS d ON d.PlotKey = c.PlotKey
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
/* Provides raw soil stability data for report purposes. */
CREATE VIEW IF NOT EXISTS SoilStab_Raw_Final AS
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
/* Creates above plot averages for soil stability data. Requires the meanw and stdevw functions to be loaded as extensions (classes.py). */
CREATE VIEW IF NOT EXISTS SoilStab_Tag AS
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
/* Creates a long version of the soil stability detail table, which allows for easier processing. */
CREATE VIEW IF NOT EXISTS SoilStabDetail_Long AS
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
/* Creates a raw output of the Species table for report purposes. */
CREATE VIEW IF NOT EXISTS SpeciesList AS
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
/* Combines the output of SR_Line_Count and SR_Line_Mean into the final Species Richness line product. */
CREATE VIEW IF NOT EXISTS SR_Line AS
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
/* Provides a count of unique species/species categories per line. Separate UNION statements provide individual indicators. */
CREATE VIEW IF NOT EXISTS SR_Line_Count AS
SELECT SiteKey, PlotKey, LineKey, RecKey, SiteID, SiteName, PlotID, LineID, FormDate,
       'Species' AS IndicatorCategory,
       Duration,
       SpeciesName AS Indicator,
       1 AS Species_n
  FROM SR_List_Line

 UNION
-- Growth Habit (GrowthHabitSub). Duration specific. Uses CodeTags to convert durations and growth habits.
SELECT SiteKey, PlotKey, LineKey, RecKey, SiteID, SiteName, PlotID, LineID, FormDate,
       IndicatorCategory, Duration, Indicator, 
       Count(SpeciesCode) AS Species_n
  FROM (SELECT a.SiteKey, a.PlotKey, a.LineKey, a.RecKey, a.SiteID, a.SiteName, a.PlotID, a.LineID, a.FormDate,
               'Growth Habit' AS IndicatorCategory, b.Tag AS Duration, c.Tag AS Indicator, a.SpeciesCode
          FROM SR_List_Line AS a
         INNER JOIN CodeTags AS b ON a.Duration = b.Code
         INNER JOIN CodeTags AS c ON a.GrowthHabitSub = c.Code
         INNER JOIN Duration_GrowthHabitSub_Combinations_Use AS d ON b.Tag = d.DurationTag AND c.Tag = d.GHTag
         WHERE b.Category = 'Duration' AND c.Category = 'GrowthHabitSub')
 GROUP BY RecKey, Duration, Indicator

 UNION
--Growth Habit (GrowthHabitSub). Duration non-specific. Uses CodeTags to convert growth habits.
SELECT a.SiteKey, a.PlotKey, a.LineKey, a.RecKey, a.SiteID, a.SiteName, a.PlotID, a.LineID, a.FormDate,
       'Growth Habit' AS IndicatorCategory,
       'All' AS Duration,
       b.Tag AS Indicator,
       Count(SpeciesCode) AS Species_n
  FROM SR_List_Line AS a
 INNER JOIN CodeTags AS b ON a.GrowthHabitSub = b.Code
 INNER JOIN Duration_GrowthHabitSub_Combinations_Use_Count AS c ON b.Tag = c.GHTag
 WHERE b.Category = 'GrowthHabitSub' AND c.GHCount > 1
 GROUP BY a.RecKey, Indicator

 UNION
-- Lignification (GrowthHabit). Duration specific. Uses CodeTags to convert durations and growth habits.
SELECT SiteKey, PlotKey, LineKey, RecKey, SiteID, SiteName, PlotID, LineID, FormDate,
       IndicatorCategory, Duration, Indicator, Count(SpeciesCode) As Species_n
  FROM (SELECT a.SiteKey, a.PlotKey, a.LineKey, a.RecKey, a.SiteID, a.SiteName, a.PlotID, a.LineID, a.FormDate,
               'Lignification' AS IndicatorCategory, b.Tag AS Duration, c.Tag AS Indicator, a.SpeciesCode
          FROM SR_List_Line AS a
         INNER JOIN CodeTags AS b ON a.Duration = b.Code
         INNER JOIN CodeTags AS c ON a.GrowthHabit = c.Code
         INNER JOIN Duration_GrowthHabit_Combinations_Use AS d ON b.Tag = d.DurationTag AND c.Tag = d.GHTag
         WHERE b.Category = 'Duration' AND c.Category = 'GrowthHabit')
 GROUP BY RecKey, Duration, Indicator

 UNION
-- Lignification (GrowthHabit). Duration non-specific. Uses CodeTags to convert growth habits.
SELECT a.SiteKey, a.PlotKey, a.LineKey, a.RecKey, a.SiteID, a.SiteName, a.PlotID, a.LineID, a.FormDate,
       'Lignification' AS IndicatorCategory,
       'All' AS Duration,
       b.Tag AS Indicator,
       Count(SpeciesCode) AS Species_n
  FROM SR_List_Line AS a
 INNER JOIN CodeTags AS b ON a.GrowthHabit = b.Code
 INNER JOIN Duration_GrowthHabit_Combinations_Use_Count AS c ON b.Tag = c.GHTag
 WHERE b.Category = 'GrowthHabit' AND c.DurationCount > 1
 GROUP BY a.RecKey, Indicator

 UNION
-- Species Tag. Duration specific. Uses CodeTags to convert durations.
SELECT a.SiteKey, a.PlotKey, a.LineKey, a.RecKey, a.SiteID, a.SiteName, a.PlotID, a.LineID, a.FormDate,
       'Species Tag' AS IndicatorCategory,
       b.Tag AS Duration,
       c.Tag AS Indicator,
       Count(a.SpeciesCode) AS Species_n
  FROM SR_List_Line AS a
 INNER JOIN CodeTags AS b ON a.Duration = b.Code
 INNER JOIN SpeciesTags AS c ON a.SpeciesCode = c.SpeciesCode
 INNER JOIN Duration_SpeciesTags_Combinations_Use AS d ON b.Tag = d.DurationTag AND c.Tag = d.SpeciesTag
 WHERE b.Category = 'Duration'
 GROUP BY a.RecKey, Duration, Indicator

 UNION
-- Species Tag. Duration non-specific.
SELECT a.SiteKey, a.PlotKey, a.LineKey, a.RecKey, a.SiteID, a.SiteName, a.PlotID, a.LineID, a.FormDate,
       'Species Tag' AS IndicatorCategory,
       'All' AS Duration,
       b.Tag AS Indicator,
       Count(a.SpeciesCode) AS Species_n
  FROM SR_List_Line AS a
 INNER JOIN SpeciesTags AS b ON a.SpeciesCode = b.SpeciesCode
 INNER JOIN Duration_SpeciesTags_Combinations_Use_Count AS c ON b.Tag = c.SpeciesTag
 WHERE c.DurationCount > 1
 GROUP BY a.RecKey, Indicator

 UNION
-- Total
SELECT SiteKey, PlotKey, LineKey, RecKey, SiteID, SiteName, PlotID, LineID, FormDate,
       'Total' AS IndicatorCategory,
       'NA' AS Duration,
       'Total' AS Indicator,
       Count(SpeciesCode) AS Species_n
  FROM SR_List_Line
 GROUP BY RecKey;
			  
-- View: SR_Line_Mean
/* Provides the mean number of species found per line.  Each UNIONED statement provides a separate indicator. Urilizes SR_SubPlot for the core 
of the workload. */
CREATE VIEW IF NOT EXISTS SR_Line_Mean AS
SELECT x.*,
       Count(y.subPlotID) AS subPlot_n,
       Avg(CASE WHEN y.Species_n IS NULL THEN 0 ELSE y.Species_n END) AS MeanSpecies_n
  FROM (SELECT a.*, b.IndicatorCategory, b.Duration, b.Indicator
          FROM (SELECT SiteKey, PlotKey, LineKey, RecKey, SiteID, SiteName, PlotID, LineID, FormDate, subPlotID
                  FROM SR_SubPlot
                 GROUP BY RecKey, subPlotID)
            AS a
         INNER JOIN 
               (SELECT RecKey, IndicatorCategory, Duration, Indicator
                  FROM SR_SubPlot
                 GROUP BY RecKey, IndicatorCategory, Duration, Indicator)
            AS b ON a.RecKey = b.RecKey)
    AS x
  LEFT JOIN SR_SubPlot AS y ON x.RecKey = y.RecKey AND 
                               x.subPlotID = y.subPlotID AND 
                               x.Duration = y.Duration AND 
                               x.Indicator = y.Indicator
 GROUP BY x.RecKey, x.Duration, x.Indicator;
			  
-- View: SR_List_Line
/* Creates a list of Species Richness species found specifically within each line.*/
CREATE VIEW IF NOT EXISTS SR_List_Line AS
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
/* Creates a Species Richness list of species found specifically within each plot. */
CREATE VIEW IF NOT EXISTS SR_List_Plot AS
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
/* Creates a Species Richness list of species found specifically within each Tag (PlotTags). */
CREATE VIEW IF NOT EXISTS SR_List_Tag AS
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
              x.SpeciesCode;
			  
-- View: SR_Plot
/* Final product for Species Richness at plot level.  Combines data from SR_Plot_Mean and SR_Plot_Count. */
CREATE VIEW IF NOT EXISTS SR_Plot AS
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
/* Provides count for unique species/categories on a per plot basis.  Each separate UNIONED statement provides a separate indicator. */
CREATE VIEW IF NOT EXISTS SR_Plot_Count AS
    -- Species.
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
    UNION
	-- Growth Habit (GrowthHabitSub). Duration specific. Uses CodeTags to convert durations and growth habits.
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
    UNION
	-- Growth Habit (GrowthHabitSub). Duration non-specific. Uses CodeTags to convert growth habits.
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
    UNION
	-- Lignification (GrowthHabit). Duration specific. Uses CodeTags to convert durations and growth habits.
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
    UNION
	-- Lignification (GrowthHabit). Duration non-specific. Uses CodeTags to convert growth habits.
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
    UNION
	-- Species Tag. Duration specific. Uses CodeTags to convert durations.
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
    UNION
	-- Species Tag. Duration non-specific.
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
	-- Total.
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
/* Provides the mean number of species/category at a plot level (e.g. if Line 1 has 12 species, Line 2 has 4 species and Line 3 has 8 species 
then the plot mean would be 8 species. */
CREATE VIEW IF NOT EXISTS SR_Plot_Mean AS
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
/* Serves as a raw Species Richness output for reporting purposes as well as a base for other Species Richness views.*/
CREATE VIEW IF NOT EXISTS SR_Raw_Final AS
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
/* Provides sprecies richness count information for each species/category for each subplot.  Each UNIONED statement provides 
a separate indicator. */
CREATE VIEW IF NOT EXISTS SR_SubPlot AS
SELECT f.SiteKey AS SiteKey, e.PlotKey AS PlotKey, d.LineKey AS Linekey, a.RecKey AS RecKey,
       f.SiteID AS SiteID, f.SiteName AS SiteName, e.PlotID AS PlotID, d.LineID AS LineID,
       c.FormDate AS FormDate, a.subPlotID,
       'Species' AS IndicatorCategory,
       CASE WHEN g.Duration IS NULL THEN 'NA' ELSE g.Duration END AS Duration,
       CASE WHEN (g.ScientificName) IS NULL THEN a.SpeciesCode ELSE g.ScientificName END AS Indicator,
       Count(a.SpeciesCode) AS Species_n
  FROM SR_Raw AS a
 INNER JOIN tblSpecRichHeader AS c ON a.RecKey = c.RecKey
 INNER JOIN tblLines AS d ON c.LineKey = d.LineKey
 INNER JOIN tblPlots AS e ON d.PlotKey = e.PlotKey
 INNER JOIN tblSites AS f ON e.SiteKey = f.SiteKey
 INNER JOIN tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
 WHERE c.FormDate BETWEEN (SELECT StartDate FROM Data_DateRange WHERE rowid = 1) AND
                          (SELECT EndDate FROM Data_DateRange WHERE rowid = 1)
 GROUP BY f.SiteKey, e.PlotKey, d.LineKey, a.RecKey, a.subPlotID, g.ScientificName

 UNION
-- Growth Habit (GrowthHabitSub). Duration specific. Uses CodeTags to convert durations and growth habits.
SELECT f.SiteKey AS SiteKey, e.PlotKey AS PlotKey, d.LineKey AS Linekey, a.RecKey AS RecKey,
       f.SiteID AS SiteID, f.SiteName AS SiteName, e.PlotID AS PlotID, d.LineID AS LineID,
       c.FormDate AS FormDate, a.subPlotID,
       'Growth Habit' AS IndicatorCategory,
       k.DurationTag AS Duration,
       k.GHTag AS Indicator,
       Count(a.SpeciesCode) AS Species_n
  FROM SR_Raw AS a
 INNER JOIN tblSpecRichHeader AS c ON a.RecKey = c.RecKey
 INNER JOIN tblLines AS d ON c.LineKey = d.LineKey
 INNER JOIN tblPlots AS e ON d.PlotKey = e.PlotKey
 INNER JOIN tblSites AS f ON e.SiteKey = f.SiteKey
 INNER JOIN tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS h ON g.GrowthHabitCode = h.Code
  LEFT JOIN CodeTags AS i ON g.Duration = i.Code
  LEFT JOIN CodeTags AS j ON h.GrowthHabitSub = j.Code
 INNER JOIN Duration_GrowthHabitSub_Combinations_Use AS k ON j.Tag = k.GHTag AND i.Tag = k.DurationTag
 WHERE i.Category = 'Duration' AND 
       j.Category = 'GrowthHabitSub' AND 
       c.FormDate BETWEEN (SELECT StartDate FROM Data_DateRange WHERE rowid = 1) AND 
                          (SELECT EndDate FROM Data_DateRange WHERE rowid = 1)
 GROUP BY f.SiteKey, e.PlotKey, d.LineKey, a.RecKey, a.subPlotID, k.GHTag, k.DurationTag

 UNION
-- Growth Habit (GrowthHabitSub). Duration non-specific. Uses CodeTags to convert growth habits.
SELECT f.SiteKey AS SiteKey, e.PlotKey AS PlotKey, d.LineKey AS Linekey, a.RecKey AS RecKey,
       f.SiteID AS SiteID, f.SiteName AS SiteName, e.PlotID AS PlotID, d.LineID AS LineID,
       c.FormDate AS FormDate, a.subPlotID,
       'Growth Habit' AS IndicatorCategory,
       'All' AS Duration,
       k.GHTag AS Indicator,
       Count(a.SpeciesCode) AS Species_n
  FROM SR_Raw AS a
  INNER JOIN tblSpecRichHeader AS c ON a.RecKey = c.RecKey
  INNER JOIN tblLines AS d ON c.LineKey = d.LineKey
  INNER JOIN tblPlots AS e ON d.PlotKey = e.PlotKey
  INNER JOIN tblSites AS f ON e.SiteKey = f.SiteKey
  INNER JOIN tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
   LEFT JOIN tblSpeciesGrowthHabit AS h ON g.GrowthHabitCode = h.Code
   LEFT JOIN CodeTags AS j ON h.GrowthHabitSub = j.Code
  INNER JOIN Duration_GrowthHabitSub_Combinations_Use_Count AS k ON j.Tag = k.GHTag
  WHERE j.Category = 'GrowthHabitSub' AND k.GHCount > 1 AND 
        c.FormDate BETWEEN (SELECT StartDate FROM Data_DateRange WHERE rowid = 1)
                       AND ( SELECT EndDate FROM Data_DateRange WHERE rowid = 1)
 GROUP BY f.SiteKey, e.PlotKey, d.LineKey,a.RecKey,a.subPlotID, k.GHTag

 UNION
-- Lignification (GrowthHabit). Duration specific. Uses CodeTags to convert durations and growth habits.
SELECT f.SiteKey AS SiteKey, e.PlotKey AS PlotKey, d.LineKey AS Linekey, a.RecKey AS RecKey,
       f.SiteID AS SiteID, f.SiteName AS SiteName, e.PlotID AS PlotID, d.LineID AS LineID,
       c.FormDate AS FormDate, a.SubPlotID,
       'Lignification' AS IndicatorCategory,
       k.DurationTag AS Duration,
       k.GHTag AS Indicator,
       Count(a.SpeciesCode) AS Species_n
  FROM SR_Raw AS a
 INNER JOIN tblSpecRichHeader AS c ON a.RecKey = c.RecKey
 INNER JOIN tblLines AS d ON c.LineKey = d.LineKey
 INNER JOIN tblPlots AS e ON d.PlotKey = e.PlotKey
 INNER JOIN tblSites AS f ON e.SiteKey = f.SiteKey
 INNER JOIN tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS h ON g.GrowthHabitCode = h.Code
  LEFT JOIN CodeTags AS i ON g.Duration = i.Code
  LEFT JOIN CodeTags AS j ON h.GrowthHabit = j.Code
 INNER  JOIN Duration_GrowthHabit_Combinations_Use AS k ON j.Tag = k.GHTag AND i.Tag = k.DurationTag
 WHERE i.Category = 'Duration' AND j.Category = 'GrowthHabit' AND 
       c.FormDate BETWEEN (SELECT StartDate FROM Data_DateRange WHERE rowid = 1) AND 
                          (SELECT EndDate FROM Data_DateRange WHERE rowid = 1)
 GROUP BY f.SiteKey, e.PlotKey, d.LineKey, a.RecKey, a.SubPlotID, k.GHTag, k.DurationTag

 UNION
-- Lignification (GrowthHabit). Duration non-specific. Uses CodeTags to convert growth habits.
SELECT f.SiteKey AS SiteKey, e.PlotKey AS PlotKey, d.LineKey AS Linekey, a.RecKey AS RecKey,
       f.SiteID AS SiteID, f.SiteName AS SiteName, e.PlotID AS PlotID, d.LineID AS LineID,
       c.FormDate AS FormDate, a.SubPlotID,
       'Lignification' AS IndicatorCategory,
       'All' AS Duration,
       k.GHTag AS Indicator,
       Count(a.SpeciesCode) AS Species_n
  FROM SR_Raw AS a
 INNER JOIN tblSpecRichHeader AS c ON a.RecKey = c.RecKey
 INNER JOIN tblLines AS d ON c.LineKey = d.LineKey
 INNER JOIN tblPlots AS e ON d.PlotKey = e.PlotKey
 INNER JOIN tblSites AS f ON e.SiteKey = f.SiteKey
 INNER JOIN tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
  LEFT JOIN tblSpeciesGrowthHabit AS h ON g.GrowthHabitCode = h.Code
  LEFT JOIN CodeTags AS j ON h.GrowthHabit = j.Code
 INNER JOIN Duration_GrowthHabit_Combinations_Use_Count AS k ON j.Tag = k.GHTag
 WHERE j.Category = 'GrowthHabit' AND  k.DurationCount > 1 AND 
       c.FormDate BETWEEN (SELECT StartDate FROM Data_DateRange WHERE rowid = 1) AND 
                          (SELECT EndDate FROM Data_DateRange WHERE rowid = 1)
 GROUP BY f.SiteKey, e.PlotKey, d.LineKey, a.RecKey, a.SubPlotID, k.GHTag

 UNION
-- Species Tag. Duration specific. Uses CodeTags to convert durations.
SELECT f.SiteKey AS SiteKey, e.PlotKey AS PlotKey, d.LineKey AS Linekey, a.RecKey AS RecKey,
       f.SiteID AS SiteID, f.SiteName AS SiteName, e.PlotID AS PlotID, d.LineID AS LineID,
       c.FormDate AS FormDate, a.SubPlotID,
       'Species Tag' AS IndicatorCategory,
       g.Duration AS Duration,
       h.Tag AS Indicator,
       Count(a.SpeciesCode) AS Species_n
  FROM SR_Raw AS a
 INNER JOIN tblSpecRichHeader AS c ON a.RecKey = c.RecKey
 INNER JOIN tblLines AS d ON c.LineKey = d.LineKey
 INNER JOIN tblPlots AS e ON d.PlotKey = e.PlotKey
 INNER JOIN tblSites AS f ON e.SiteKey = f.SiteKey
 INNER JOIN tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
 INNER JOIN SpeciesTags AS h ON a.SpeciesCode = h.SpeciesCode
  LEFT JOIN CodeTags AS i ON g.Duration = i.Code
 INNER JOIN Duration_SpeciesTags_Combinations_Use AS k ON h.Tag = k.SpeciesTag AND i.Tag = k.DurationTag
 WHERE i.Category = 'Duration' AND 
       c.FormDate BETWEEN (SELECT StartDate FROM Data_DateRange WHERE rowid = 1) AND 
                          (SELECT EndDate FROM Data_DateRange WHERE rowid = 1)
 GROUP BY f.SiteKey, e.PlotKey, d.LineKey, a.RecKey, a.SubPlotID, h.Tag, g.Duration

 UNION
-- Species Tag. Duration non-specific.
SELECT f.SiteKey AS SiteKey, e.PlotKey AS PlotKey, d.LineKey AS Linekey, a.RecKey AS RecKey,
       f.SiteID AS SiteID, f.SiteName AS SiteName, e.PlotID AS PlotID, d.LineID AS LineID,
       c.FormDate AS FormDate, a.SubPlotID,
       'Species Tag' AS IndicatorCategory,
       'All' AS Duration,
        h.Tag AS Indicator,
        Count(a.SpeciesCode) AS Species_n
  FROM SR_Raw AS a
 INNER JOIN tblSpecRichHeader AS c ON a.RecKey = c.RecKey
 INNER JOIN tblLines AS d ON c.LineKey = d.LineKey
 INNER JOIN tblPlots AS e ON d.PlotKey = e.PlotKey
 INNER JOIN tblSites AS f ON e.SiteKey = f.SiteKey
 INNER JOIN tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode
 INNER JOIN SpeciesTags AS h ON a.SpeciesCode = h.SpeciesCode
 INNER JOIN Duration_SpeciesTags_Combinations_Use_Count AS k ON h.Tag = k.SpeciesTag
 WHERE k.DurationCount > 1 AND 
       c.FormDate BETWEEN (SELECT StartDate FROM Data_DateRange WHERE rowid = 1) AND 
                          (SELECT EndDate FROM Data_DateRange WHERE rowid = 1)
 GROUP BY f.SiteKey, e.PlotKey, d.LineKey, a.RecKey, a.SubPlotID, h.Tag

UNION
-- Total.
SELECT f.SiteKey AS SiteKey, e.PlotKey AS PlotKey, d.LineKey AS Linekey, a.RecKey AS RecKey,
       f.SiteID AS SiteID, f.SiteName AS SiteName, e.PlotID AS PlotID, d.LineID AS LineID,
       c.FormDate AS FormDate, a.subPlotID,
       'Total' AS IndicatorCategory,
       'NA' AS Duration,
       'Total' AS Indicator,
       Count(a.SpeciesCode) AS Species_n
  FROM SR_Raw AS a
 INNER JOIN tblSpecRichHeader AS c ON a.RecKey = c.RecKey
 INNER JOIN tblLines AS d ON c.LineKey = d.LineKey
 INNER JOIN tblPlots AS e ON d.PlotKey = e.PlotKey
 INNER JOIN tblSites AS f ON e.SiteKey = f.SiteKey
 INNER JOIN tblSpecies AS g ON a.SpeciesCode = g.SpeciesCode 
 WHERE c.FormDate BETWEEN (SELECT StartDate FROM Data_DateRange WHERE rowid = 1) AND 
                          (SELECT EndDate FROM Data_DateRange WHERE rowid = 1)
 GROUP BY f.SiteKey, e.PlotKey, d.LineKey, a.RecKey, a.subPlotID;
			  
-- View: SR_Tag
/* Serves as the final product for species richness above plot level.  Combines data from SR_Tag_Count and SR_Tag_Mean. */
CREATE VIEW IF NOT EXISTS SR_Tag AS
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
/* Provides counts of unique species within categoies for Tags (PlotTags). Each UNIONED statement provides a separate indicator. */
CREATE VIEW IF NOT EXISTS SR_Tag_Count AS
    -- Species.
	SELECT Tag,
           'Species' AS IndicatorCategory,
           Duration,
           SpeciesName AS Indicator,
           1 AS Species_n
      FROM SR_List_Tag
    UNION
	-- Growth Habit (GrowthHabitSub). Duration specific. Uses CodeTags to convert durations and growth habits.
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
    UNION
	-- Growth Habit (GrowthHabitSub). Duration non-specific. Uses CodeTags to convert growth habits.
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
    UNION
	-- Lignification (GrowthHabit). Duration specific. Uses CodeTags to convert durations and growth habits.
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
    UNION
	-- Lignification (GrowthHabit). Duration non-specific. Uses CodeTags to convert growth habits.
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
    UNION
	-- Species Tag. Duration specific. Uses CodeTags to convert durations.
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
    UNION
	-- Species Tag. Duration non-specific.
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
    UNION
	-- Total.
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
/* Provides a mean number of unique species per category per Tag (PlotTags) e.g. If Plot A has 12 unique species and Plot B has 
6 unique species and both have the same PlotTag, then that Tag will have a unique species mean of 9.*/
CREATE VIEW IF NOT EXISTS SR_Tag_Mean AS
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
/* Gets the units choice from the Data_DBconfig table and restricts the UnitConversion to those choices.  Used to convert from one set of 
units to another within views.*/
CREATE VIEW IF NOT EXISTS UnitConversion_Use AS
    SELECT *
      FROM UnitConversion
     WHERE MeasureChoice = (
                               SELECT Value
                                 FROM Data_DBconfig
                                WHERE VariableName = 'units'
                           );

--Exports_All
/* Provides a combined list of exports for both regular and QAQC reports. */
CREATE VIEW IF NOT EXISTS Exports_All AS
SELECT Category, DataType, Scale, ObjectName, ExportName, Null AS Function, Null AS QueryOrder
  FROM Exports
 UNION
SELECT 'QAQC' AS Category, Method AS DataType, 'Raw' AS Scale, QueryName AS ObjectName, ExportID As ExportName, Function, QueryOrder
  FROM QAQC_Queries
 WHERE use_check = 1
 ORDER BY Category, DataType, Scale, Function, QueryOrder;	
 
COMMIT TRANSACTION; 

PRAGMA foreign_keys = on;