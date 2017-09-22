PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

--QAQC_Plot_Methods_FormNumberCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_Plot_Methods_FormNumberCheck','All Methods','Missing Data','This check will display counts of forms for all methods at the plot level and compare it against a predetermined number of forms that should be present within a season.','Missing Forms for certain methods.','Plot_Methods_FormNumberCheck',NULL,NULL);

CREATE VIEW QAQC_Plot_Methods_FormNumberCheck AS
    SELECT x.SiteID,
           x.SiteName,
           x.PlotID,
           x.MethodName,
           x.FormNumber AS FormsNeeded,
           y.Season,
           CASE WHEN y.n IS NULL THEN 0 ELSE y.n END AS FormsPresent
      FROM (
               SELECT a.SiteID,
                      a.Sitename,
                      b.PlotID,
                      b.PlotKey,
                      c.MethodName,
                      c.FormNumber
                 FROM tblSites AS a
                      JOIN
                      tblPlots AS b ON a.SiteKey = b.SiteKey
                      CROSS JOIN
                      Methods AS c
                WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
                      c.Use = 1
           )
           AS x
           LEFT JOIN
           (
               SELECT PlotKey,
                      'Line Establishment' AS Method,
                      NULL AS Season,
                      Count(LineKey) AS n
                 FROM tblLines
                WHERE PlotKey NOT IN ('888888888', '999999999') 
                GROUP BY PlotKey
               UNION
               SELECT b.PlotKey,
                      'Line-point Intercept' AS Method,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE FormDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      Count(a.RecKey) AS n
                 FROM tblLPIHeader AS a
                      JOIN
                      tblLines AS b ON a.LineKey = b.LineKey
                GROUP BY b.PlotKey,
                         Season
               UNION
               SELECT b.PlotKey,
                      'Continuous Line Intercept' AS Method,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE FormDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      Count(a.RecKey) AS n
                 FROM tblLICHeader AS a
                      JOIN
                      tblLines AS b ON a.LineKey = b.LineKey
                GROUP BY b.PlotKey,
                         Season
               UNION
               SELECT b.PlotKey,
                      'Gap Intercept' AS Method,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE FormDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      Count(a.RecKey) AS n
                 FROM tblGapHeader AS a
                      JOIN
                      tblLines AS b ON a.LineKey = b.LineKey
                GROUP BY b.PlotKey,
                         Season
               UNION
               SELECT b.PlotKey,
                      'Plant Density' AS Method,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE FormDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      Count(a.RecKey) AS n
                 FROM tblPlantDenHeader AS a
                      JOIN
                      tblLines AS b ON a.LineKey = b.LineKey
                GROUP BY b.PlotKey,
                         Season
               UNION
               SELECT b.PlotKey,
                      'Species Richness' AS Method,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE FormDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      Count(a.RecKey) AS n
                 FROM tblSpecRichHeader AS a
                      JOIN
                      tblLines AS b ON a.LineKey = b.LineKey
                GROUP BY b.PlotKey,
                         Season
               UNION
               SELECT b.PlotKey,
                      'IIRH' AS Method,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE FormDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      Count(a.RecKey) AS n
                 FROM tblQualHeader AS a
                      JOIN
                      tblPlots AS b ON a.PlotKey = b.PlotKey
                GROUP BY b.PlotKey,
                         Season
               UNION
               SELECT b.PlotKey,
                      'Soil Stability' AS Method,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE FormDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      Count(a.RecKey) AS n
                 FROM tblSoilStabHeader AS a
                      JOIN
                      tblPlots AS b ON a.PlotKey = b.PlotKey
                GROUP BY b.PlotKey,
                         Season
               UNION
               SELECT b.PlotKey,
                      'Soil Pit' AS Method,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE a.DateRecorded BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      Count(a.SoilKey) AS n
                 FROM tblSoilPits AS a
                      JOIN
                      tblPlots AS b ON a.PlotKey = b.PlotKey
                GROUP BY b.PlotKey,
                         Season
           )
           AS y ON x.PlotKey = y.PlotKey AND 
                   x.MethodName = y.Method
     WHERE FormsNeeded != FormsPresent;

	 
--QAQC_Plot_Methods_FormDateCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_Plot_Methods_FormDateCheck','All Methods','Data Criterion Failure','Method data within the same plot have different form dates.  Minimum Criteria is for Soil Pit form date for projects with legacy soil pit information.','If methods are done on different days or if there is multiple years data in the database, this check will return valid dates.  All form dates are given for plots such that possible incorrect dates can be identified from the list.','Plot_Methods_FormDateCheck',NULL,NULL);

CREATE VIEW QAQC_Plot_Methods_FormDateCheck AS
    SELECT q.*,
           r.DateCountMost,
           r.FormDateMost,
           Abs(julianday(q.FormDate) - julianday(r.FormDateMost) ) AS DayDif
      FROM (
               SELECT x.SiteID,
                      x.SiteName,
                      y.PlotID,
                      y.PlotKey,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE fDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      z.RecType,
                      z.LineID,
                      z.fDate AS FormDate
                 FROM tblSites AS x
                      JOIN
                      tblPLots AS y ON x.SiteKey = y.SiteKey
                      JOIN
                      (
                          SELECT a.PlotKey,
                                 a.LineID,
                                 b.RecType,
                                 b.fDate
                            FROM tblLines AS a
                                 JOIN
                                 (
                                     SELECT LineKey,
                                            RecKey,
                                            'LPI' AS RecType,
                                            Date(FormDate) AS fDate
                                       FROM tblLPIHeader
                                     UNION ALL
                                     SELECT LineKey,
                                            RecKey,
                                            'CLI' AS RecType,
                                            Date(FormDate) AS fDate
                                       FROM tblLICHeader
                                     UNION ALL
                                     SELECT LineKey,
                                            RecKey,
                                            'CGS' AS RecType,
                                            Date(FormDate) AS fDate
                                       FROM tblCanopyGapHeader
                                     UNION ALL
                                     SELECT LineKey,
                                            RecKey,
                                            'GAP' AS RecType,
                                            Date(FormDate) AS fDate
                                       FROM tblGapHeader
                                     UNION ALL
                                     SELECT LineKey,
                                            RecKey,
                                            'PD' AS RecType,
                                            Date(FormDate) AS fDate
                                       FROM tblPlantDenHeader
                                     UNION ALL
                                     SELECT LineKey,
                                            RecKey,
                                            'SR' AS RecType,
                                            Date(FormDate) AS fDate
                                       FROM tblSpecRichHeader
                                 )
                                 AS b ON a.LineKey = b.LineKey
                          UNION ALL
                          SELECT PlotKey,
                                 'NA' AS LineID,
                                 RecType,
                                 fDate
                            FROM (
                                     SELECT PlotKey,
                                            'Plot' AS RecType,
                                            Date(EstablishDate) AS fDate
                                       FROM tblPlots
                                     UNION ALL
                                     SELECT PlotKey,
                                            'IIRH' AS RecType,
                                            Date(FormDate) AS fDate
                                       FROM tblQualHeader
                                     UNION ALL
                                     SELECT PlotKey,
                                            'Soil Pit' AS RecType,
                                            Date(DateRecorded) AS fDate
                                       FROM tblSoilPits
                                     UNION ALL
                                     SELECT PlotKey,
                                            'Soil Stability' AS ReType,
                                            Date(FormDate) AS fDate
                                       FROM tblSoilStabHeader
                                     UNION ALL
                                     SELECT PlotKey,
                                            'Production' AS RecType,
                                            Date(FormDate) AS fDate
                                       FROM tblPlantProdHeader
                                 )
                      )
                      AS z ON y.PlotKey = z.PlotKey
                WHERE x.SiteKey NOT IN ('888888888', '999999999') 
           )
           AS q
           JOIN
           (
               SELECT PlotKey,
                      Season,
                      Max(DateCount) AS DateCountMost,
                      FormDate AS FormDateMost
                 FROM (
                          SELECT PlotKey,
                                 fDate AS FormDate,
                                 (
                                     SELECT SeasonLabel
                                       FROM SeasonDefinition
                                      WHERE fDate BETWEEN SeasonStart AND SeasonEnd
                                 )
                                 AS Season,
                                 Count(fDate) AS DateCount
                            FROM (
                                     SELECT a.PlotKey,
                                            b.RecType,
                                            b.fDate
                                       FROM tblLines AS a
                                            JOIN
                                            (
                                                SELECT LineKey,
                                                       RecKey,
                                                       'LPI' AS RecType,
                                                       Date(FormDate) AS fDate
                                                  FROM tblLPIHeader
                                                UNION ALL
                                                SELECT LineKey,
                                                       RecKey,
                                                       'CLI' AS RecType,
                                                       Date(FormDate) AS fDate
                                                  FROM tblLICHeader
                                                UNION ALL
                                                SELECT LineKey,
                                                       RecKey,
                                                       'CGS' AS RecType,
                                                       Date(FormDate) AS fDate
                                                  FROM tblCanopyGapHeader
                                                UNION ALL
                                                SELECT LineKey,
                                                       RecKey,
                                                       'GAP' AS RecType,
                                                       Date(FormDate) AS fDate
                                                  FROM tblGapHeader
                                                UNION ALL
                                                SELECT LineKey,
                                                       RecKey,
                                                       'PD' AS RecType,
                                                       Date(FormDate) AS fDate
                                                  FROM tblPlantDenHeader
                                                UNION ALL
                                                SELECT LineKey,
                                                       RecKey,
                                                       'SR' AS RecType,
                                                       Date(FormDate) AS fDate
                                                  FROM tblSpecRichHeader
                                            )
                                            AS b ON a.LineKey = b.LineKey
                                     UNION ALL
                                     SELECT PlotKey,
                                            'Plot' AS RecType,
                                            Date(EstablishDate) AS fDate
                                       FROM tblPlots
                                     UNION ALL
                                     SELECT PlotKey,
                                            'IIRH' AS RecType,
                                            Date(FormDate) AS fDate
                                       FROM tblQualHeader
                                     UNION ALL
                                     SELECT PlotKey,
                                            'Soil Pit' AS RecType,
                                            Date(DateRecorded) AS fDate
                                       FROM tblSoilPits
                                     UNION ALL
                                     SELECT PlotKey,
                                            'Soil Stability' AS ReType,
                                            Date(FormDate) AS fDate
                                       FROM tblSoilStabHeader
                                     UNION ALL
                                     SELECT PlotKey,
                                            'Production' AS RecType,
                                            Date(FormDate) AS fDate
                                       FROM tblPlantProdHeader
                                 )
                           WHERE PlotKey NOT IN ('888888888', '999999999') 
                           GROUP BY PlotKey,
                                    Season,
                                    FormDate
                      )
                GROUP BY PlotKey,
                         Season
           )
           AS r ON q.PlotKey = r.PlotKey AND 
                   q.Season = r.Season
     WHERE DayDif > 0
     ORDER BY SiteID,
              PlotID,
              Season,
              RecType,
              LineID;


--QAQC_Descriptions_Criteria	  
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_Descriptions_Criteria','All Methods','Descriptions','This is the description list for QAQC Queries',NULL,'Quality Check Descriptions',NULL,NULL);

CREATE VIEW QAQC_Descriptions_Criteria AS
    SELECT QueryName,
           Method,
           Function,
           Description,
           DescriptionSub,
           ExportID,
           Field,
           CorrectValue
      FROM QAQC_Queries
     ORDER BY Method,
              Function,
              QueryOrder;

			  
--QAQC_SpeciesMethods			  
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_SpeciesMethods','All Methods','Species Tracking','Use this query to identify the lines/plots where a species code occurs in all methods with species codes.',NULL,'SpeciesMethods',NULL,NULL);			  

CREATE VIEW QAQC_SpeciesMethods AS
    SELECT x.SiteID,
           x.SiteName,
           y.PlotID,
           z.Season,
           z.Species,
           group_concat(z.Method, ';') AS Methods
      FROM tblSites AS x
           JOIN
           tblPlots AS y ON x.SiteKey = y.Sitekey
           JOIN
           (
               SELECT PlotKey,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE FormDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      'LPI' AS Method,
                      Species
                 FROM (
                          SELECT a.*
                            FROM LPI_CanopyLayers_Point_DB_UNION AS a
                                 JOIN
                                 tblSpecies AS b ON a.Species = b.SpeciesCode
                      )
                GROUP BY PlotKey,
                         Season,
                         Method,
                         Species
               UNION
               SELECT d.PlotKey,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE FormDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      a.Method,
                      a.Species
                 FROM LI_Detail_View AS a
                      JOIN
                      LI_Header_View AS b ON a.RecKey = b.RecKey
                      JOIN
                      tblLines AS c ON b.LineKey = c.LineKey
                      JOIN
                      tblPlots AS d ON c.PlotKey = d.PlotKey
                      JOIN
                      tblSpecies AS e ON a.Species = e.SpeciesCode
                GROUP BY d.PlotKey,
                         Season,
                         a.Method,
                         a.Species
               UNION
               SELECT a.PlotKey,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE FormDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      'Plant Density' AS Method,
                      a.SpeciesCode AS Species
                 FROM PD_Raw_Final AS a
                      JOIN
                      tblSpecies AS b ON a.SpeciesCode = b.SpeciesCode
                GROUP BY Plotkey,
                         Season,
                         Method,
                         Species
               UNION
               SELECT a.PlotKey,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE b.FormDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      'Production' AS Method,
                      c.SpeciesCode AS Species
                 FROM tblPlots AS a
                      JOIN
                      tblPlantProdHeader AS b ON a.PlotKey = b.PlotKey
                      JOIN
                      tblPlantProdDetail AS c ON b.RecKey = c.RecKey
                      JOIN
                      tblSpecies AS d ON c.SpeciesCode = d.SpeciesCode
                GROUP BY a.PlotKey,
                         Season,
                         Method,
                         Species
               UNION
               SELECT a.PlotKey,
                      (
                          SELECT SeasonLabel
                            FROM SeasonDefinition
                           WHERE c.FormDate BETWEEN SeasonStart AND SeasonEnd
                      )
                      AS Season,
                      'Species Richness' AS Method,
                      d.SpeciesCode AS Species
                 FROM tblPlots AS a
                      JOIN
                      tblLines AS b ON a.PlotKey = b.PlotKey
                      JOIN
                      tblSpecRichHeader AS c ON b.LineKey = c.LineKey
                      JOIN
                      SR_Raw AS d ON c.RecKey = d.RecKey
                      JOIN
                      tblSpecies AS e ON d.SpeciesCode = e.SpeciesCode
                GROUP BY a.PlotKey,
                         Season,
                         Method,
                         Species
                ORDER BY PLotKey,
                         Season,
                         Species,
                         Method
           )
           AS z ON y.PlotKey = z.PlotKey
     GROUP BY SiteID,
              PlotID,
              Season,
              Species
     ORDER BY SiteID,
              PlotID,
              Season,
              Species,
              Methods; 
			  
--QAQC_CLI_LengthLessMin
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_CLI_LengthLessMin','Continuous Line Intercept','Data Criterion Failure','A length was less than minimum.',NULL,'CLI_LengthLessMin','Length','>=2cm');			

CREATE VIEW QAQC_CLI_LengthLessMin AS
    SELECT c.RecKey || ';' || c.Species || ';' || c.StartPos AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           c.RecKey,
           c.Species,
           c.StartPos,
           c.EndPos,
           Abs(c.EndPos - c.StartPos) AS Length
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLICDetail AS c ON b.RecKey = c.RecKey
     WHERE Length < 2
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID,
              c.StartPos;


--QAQC_CLI_FormDateCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_CLI_FormDateCheck','Continuous Line Intercept','Data Criterion Failure','Lines have different dates. Use to check for incorrect date.','If methods are done on different days or if there is multiple years data in the database, this check will return valid dates.','CLI_FormDateCheck',NULL,NULL);

CREATE VIEW QAQC_CLI_FormDateCheck AS
    SELECT c.RecKey AS ErrorKey,
           a.SiteKey,
           a.SiteID,
           a.SiteName,
           a.PlotKey,
           a.PlotID,
           a.LineKey,
           a.LineID,
           c.FormType,
           date(c.FormDate) AS FormDate,
           date(b.MinFormDate) AS MinFormDate,
           date(b.MaxFormDate) AS MaxFormDate,
           julianday(b.MaxFormDate) - julianday(b.MinFormDate) AS FormDateDayDif
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS c ON a.LineKey = c.LineKey
           JOIN
           (
               SELECT x.PlotKey,
                      Max(y.FormDate) AS MaxFormDate,
                      Min(y.FormDate) AS MinFormDate
                 FROM joinSitePlotLine AS x
                      JOIN
                      tblLICHeader AS y ON x.LineKey = y.LineKey
                GROUP BY x.PlotKey
           )
           AS b ON a.PlotKey = b.PlotKey
     WHERE FormDateDayDif >= 1
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;

			  
--QAQC_CLI_DurationNotPerennial			  
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_CLI_DurationNotPerennial','Continuous Line Intercept','Data Criterion Failure','The duration for this species is not Perennial.',NULL,'CLI_DurationNotPerennial','Duration',NULL);			  

CREATE VIEW QAQC_CLI_DurationNotPerennial AS
    SELECT c.RecKey || ';' || c.Species || ';' & c.StartPos AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           c.Species,
           d.Duration
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLICDetail AS c ON b.RecKey = c.RecKey
           LEFT JOIN
           tblSpecies AS d ON c.Species = d.SpeciesCode
     WHERE d.Duration <> 'Perennial';


--QAQC_CLI_OverlapTest
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(6.0,'QAQC_CLI_OverlapTest','Continuous Line Intercept','Data Criterion Failure','These canopy cover sections overlap.','If multiple levels of canopy occur, the "dominant" one, or one that supersedes the other in height, should be used.','CLI_OverlapTest','OverlapTest',NULL);	 

CREATE VIEW QAQC_CLI_OverlapTest AS
    SELECT c.RecKey || ';' || c.Species || ';' || c.StartPos AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.FormDate,
           c.Species AS SpeciesTest,
           c.StartPos AS StartPosTest,
           c.EndPos AS EndPosTest,
           d.Species,
           d.StartPos,
           d.EndPos,
           CASE WHEN c.Species = d.Species AND 
                     c.StartPos = d.StartPos AND 
                     c.EndPos = d.EndPos THEN NULL WHEN d.StartPos >= c.StartPos AND 
                                                        d.StartPos < c.EndPos THEN 'Overlap' ELSE NULL END AS OverlapTest
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLICDetail AS c ON b.RecKey = c.RecKey
           JOIN
           tblLICDetail AS d ON b.RecKey = d.RecKey
     WHERE OverlapTest IS NOT NULL
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID,
              b.FormDate,
              c.StartPos,
              d.StartPos;

	
--QAQC_CLI_MeasureIncorrect	
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_CLI_MeasureIncorrect','Continuous Line Intercept','Form Default','Data collection units incorrect.','1=metric; 2=english','CLI_MeasureIncorrect','Measure','=1');
			  
CREATE VIEW QAQC_CLI_MeasureIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.Measure
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
     WHERE b.Measure IS NULL OR 
           b.Measure <> 1
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;

--QAQC_CLI_LineLengthIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_CLI_LineLengthIncorrect','Continuous Line Intercept','Form Default','Line Length is outside criterion.','Lines may have different lengths for appropriate reason, use only to double check.','CLI_LineLengthIncorrect','LineLengthAmount','=25m');
			  
CREATE VIEW QAQC_CLI_LineLengthIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.Observer,
           b.Recorder,
           b.DataEntry,
           b.DataErrorChecking,
           b.LineLengthAmount
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
     WHERE b.LineLengthAmount IS NULL OR 
           b.LineLengthAmount <> 25
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;

			  
--QAQC_CLI_PositionIncorrect			  
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_CLI_PositionIncorrect','Continuous Line Intercept','Form Default','Position Units incorrect.',NULL,'CLI_PositionIncorrect','PositionUOM','=cm');
			  
CREATE VIEW QAQC_CLI_PositionIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.PositionUOM
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
     WHERE b.PositionUOM IS NULL OR 
           b.PositionUOM <> 'cm'
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;

			  
--QAQC_CLI_MinNonInterceptGapIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_CLI_MinNonInterceptGapIncorrect','Continuous Line Intercept','Form Option','Minimum Non-Intercept Gap is incorrect.',NULL,'CLI_MinNonInterceptGapIncorrect','MinNonInterceptGap','=2cm');			  

CREATE VIEW QAQC_CLI_MinNonInterceptGapIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.MinNonInterceptGap
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
     WHERE b.MinNonInterceptGap IS NULL OR 
           b.MinNonInterceptGap <> 2
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;

			  
--QAQC_CLI_MinLengthCanopySegIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_CLI_MinLengthCanopySegIncorrect','Continuous Line Intercept','Form Option','Minimum Length of Canpoy Segment is incorrect.',NULL,'CLI_MinLengthCanopySegIncorrect','MinLengthCanopySeg','=2cm');
			  
CREATE VIEW QAQC_CLI_MinLengthCanopySegIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.MinLengthCanopySeg
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
     WHERE b.MinLengthCanopySeg IS NULL OR 
           b.MinLengthCanopySeg <> 2
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;


--QAQC_CLI_MaxPctNonCanopyIncorrect			  
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_CLI_MaxPctNonCanopyIncorrect','Continuous Line Intercept','Form Option','Max % of Non-Caopy in a Canopy Segment outside of criterion.','This field determines the maximum percentage of canopy that can be gap before a section can no longer be considered canopy.','CLI_MaxPctNonCanopyIncorrect','MaxPctNonCanopy','=50%');
			  
CREATE VIEW QAQC_CLI_MaxPctNonCanopyIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.Observer,
           b.Recorder,
           b.DataEntry,
           b.DataErrorChecking,
           b.MinNonInterceptGap,
           b.MinLengthCanopySeg,
           b.MaxPctNonCanopy
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
     WHERE b.MaxPctNonCanopy IS NULL OR 
           b.MaxPctNonCanopy <> 50
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;

--QAQC_CLI_MissingData
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(0.0,'QAQC_CLI_MissingData','Continuous Line Intercept','Missing Data','Continuous Line Intercept not done on this line.',NULL,'CLI_MissingData',NULL,'=FALSE');

CREATE VIEW QAQC_CLI_MissingData AS
    SELECT a.LineKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.RecKey
      FROM joinSitePlotLine AS a
           LEFT JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
     WHERE b.RecKey IS NULL
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;

			  
--QAQC_CLI_BlankForm
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_CLI_BlankForm','Continuous Line Intercept','Missing Data','The form is empty.',NULL,'CLI_BlankForm',NULL,NULL);
			  
CREATE VIEW QAQC_CLI_BlankForm AS
    SELECT c.RecKey || ';' || c.Species || ';' || c.StartPos AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.Notes,
           c.RecKey
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
           LEFT JOIN
           tblLICDetail AS c ON b.RecKey = c.RecKey
     WHERE c.RecKey IS NULL
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
			  
--QAQC_CLI_MissingObserver
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_CLI_MissingObserver','Continuous Line Intercept','Missing Data','Missing Observer.',NULL,'CLI_MissingObserver','Observer',NULL);

CREATE VIEW QAQC_CLI_MissingObserver AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.Observer,
           b.Recorder,
           b.DataEntry,
           b.DataErrorChecking
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
     WHERE b.Observer IS NULL OR 
           b.Observer = ''
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;

			  
--QAQC_CLI_MissingRecorder
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_CLI_MissingRecorder','Continuous Line Intercept','Missing Data','Missing Recorder.',NULL,'CLI_MissingRecorder','Recorder',NULL);

CREATE VIEW QAQC_CLI_MissingRecorder AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.Observer,
           b.Recorder,
           b.DataEntry,
           b.DataErrorChecking
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
     WHERE b.Recorder IS NULL OR 
           b.Recorder = ''
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  

--QAQC_CLI_DataEntryNoErrorCheck			  
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_CLI_DataEntryNoErrorCheck','Continuous Line Intercept','Missing Data','There was data entry from other source (because DataEntry not NULL) and there is no Error Checker listed.',NULL,'CLI_DataEntryNoErrorCheck','DataErrorChecking',NULL);

CREATE VIEW QAQC_CLI_DataEntryNoErrorCheck AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.Observer,
           b.Recorder,
           b.DataEntry,
           b.DataErrorChecking
      FROM joinSitePlotLine AS a
           JOIN
           tblLICHeader AS b ON a.LineKey = b.LineKey
     WHERE (b.DataEntry IS NOT NULL AND 
            b.DataEntry <> '') AND 
           (b.DataErrorChecking IS NULL OR 
            b.DataErrorChecking = '') 
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;


--QAQC_CLI_SpeciesNoGrowthHabitDuration
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(5.0,'QAQC_CLI_SpeciesNoGrowthHabitDuration','Continuous Line Intercept','Missing Data','A species was used in this line''s data that does not have a growth habit or does not have a duration assigned to it in the state species list.',NULL,'CLI_SpeciesNoGrowthHabitDur','GrowthHabit OR Duration',NULL);
			  
CREATE VIEW QAQC_CLI_SpeciesNoGrowthHabitDuration AS
    SELECT x.RecKey || ';' || x.Species AS ErrorKey,
           x.SiteID,
           x.SiteName,
           x.PlotID,
           x.LineID,
           x.FormDate,
           x.Species,
           y.ScientificName,
           y.CommonName,
           y.Duration,
           z.Code,
           z.GrowthHabit,
           z.GrowthHabitSub
      FROM (
               SELECT a.SiteKey,
                      a.LineKey,
                      a.PlotKey,
                      b.RecKey,
                      a.SiteID,
                      a.SiteName,
                      a.PlotID,
                      a.LineID,
                      b.FormDate,
                      c.Species
                 FROM joinSitePlotLine AS a
                      JOIN
                      tblLICHeader AS b ON a.LineKey = b.LineKey
                      JOIN
                      tblLICDetail AS c ON b.RecKey = c.RecKey
                GROUP BY b.RecKey,
                         c.Species
               HAVING c.Species NOT LIKE '%XX' AND 
                      c.Species NOT LIKE 'PP%' AND 
                      c.Species NOT LIKE 'AA%'
           )
           AS x
           JOIN
           tblSpecies AS y ON x.Species = y.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS z ON y.GrowthHabitCode = z.Code
     WHERE (y.Duration IS NULL OR 
            y.Duration = '') OR 
           (z.GrowthHabit IS NULL OR 
            z.GrowthHabit = '') 
     ORDER BY x.SiteID,
              x.PlotID,
              x.LineID,
              x.FormDate,
              x.Species;

			  
--QAQC_CLI_Header_OrphanRecordCheck			  
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_CLI_Header_OrphanRecordCheck','Continuous Line Intercept','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'CLI_Header_OrphanRecordCheck',NULL,NULL);
			  
CREATE VIEW QAQC_CLI_Header_OrphanRecordCheck AS
    SELECT a.RecKey AS ErrorKey,
           b.LineKey AS tblLines_LineKey,
           a.LineKey AS tblLICHeader_LineKey,
           a.RecKey,
           a.FormDate,
           a.Observer,
           a.Recorder
      FROM tblLICHeader AS a
           LEFT JOIN
           tblLines AS b ON a.LineKey = b.LineKey
     WHERE b.LineKey IS NULL;

	 
--QAQC_CLI_Detail_OrphanRecordCheck	 
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_CLI_Detail_OrphanRecordCheck','Continuous Line Intercept','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'CLI_Detail_OrphanRecordCheck',NULL,NULL);
	 
CREATE VIEW QAQC_CLI_Detail_OrphanRecordCheck AS
    SELECT a.RecKey || ';' || a.Species || ';' || a.StartPos AS ErrorKey,
           b.RecKey AS tblLICHeader_RecKey,
           a.RecKey AS tblLICDetail_RecKey,
           a.Species,
           a.StartPos,
           a.EndPos,
           a.Height,
           a.Chkbox
      FROM tblLICDetail AS a
           LEFT JOIN
           tblLICHeader AS b ON a.RecKey = b.RecKey
     WHERE b.RecKey IS NULL;


--QAQC_GAP_GapTypeIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_GAP_GapTypeIncorrect','Gap Intercept','Data Criterion Failure','An incorrect type assignment has been made to a gap.','"C"=Canopy; "B" = Basal','GAP_GapTypeIncorrect','RecType','=C');
	 
CREATE VIEW QAQC_GAP_GapTypeIncorrect AS
    SELECT c.RecKey || ';' || c.SeqNo AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           c.SeqNo,
           c.RecType,
           c.GapStart,
           c.GapEnd
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblGapDetail AS c ON b.RecKey = c.RecKey
     WHERE c.RecType NOT IN ('C') 
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID,
              c.SeqNo;


--QAQC_GAP_GapNullOrLessThanMin
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_GAP_GapNullOrLessThanMin','Gap Intercept','Data Criterion Failure','A gap size is either blank or less than the minimum.',NULL,'GAP_GapNullOrLessThanMin','Gap','>=20cm');
			  
CREATE VIEW QAQC_GAP_GapNullOrLessThanMin AS
    SELECT c.RecKey || ';' || c.SeqNo AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           c.SeqNo,
           c.RecKey,
           c.RecType,
           c.GapStart,
           c.GapEnd,
           Abs(c.GapStart - c.GapEnd) AS Gap
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblGapDetail AS c ON b.RecKey = c.RecKey
     WHERE Gap < 20
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID,
              c.SeqNo;


--QAQC_GAP_FormDateCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_GAP_FormDateCheck','Gap Intercept','Data Criterion Failure','Lines have different dates. Use to check for incorrect date.','If methods are done on different days or if there is multiple years data in the database, this check will return valid dates.','GAP_FormDateCheck',NULL,NULL);
			  
CREATE VIEW QAQC_GAP_FormDateCheck AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteKey,
           a.SiteID,
           a.SiteName,
           a.PlotKey,
           a.PlotID,
           a.LineKey,
           a.LineID,
           date(b.FormDate) AS FormDate,
           date(c.MinFormDate) AS MinFormDate,
           date(c.MaxFormDate) AS MaxFormDate,
           julianday(c.MaxFormDate) - julianday(c.MinFormDate) AS FormDateDayDif
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
           JOIN
           (
               SELECT x.PlotKey,
                      Min(y.FormDate) AS MinFormDate,
                      Max(y.FormDate) AS MaxFormDate
                 FROM joinSitePlotLine AS x
                      JOIN
                      tblGapHeader AS y ON x.LineKey = y.LineKey
                GROUP BY x.PlotKey
           )
           AS c ON a.PlotKey = c.PlotKey
     WHERE FormDateDayDif >= 1
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;

			  
--QAQC_GAP_OverlapTest
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_GAP_OverlapTest','Gap Intercept','Data Criterion Failure','These gaps have sections that overlap each other.',NULL,'GAP_OverlapTest','OverlapTest',NULL);
			  
CREATE VIEW QAQC_GAP_OverlapTest AS
    SELECT c.RecKey || ';' || c.SeqNo AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.FormDate,
           c.RecType AS RecTypeTest,
           c.GapStart AS GapStartTest,
           c.GapEnd AS GapEndTest,
           d.RecType,
           d.GapStart,
           d.GapEnd,
           CASE WHEN c.RecType = d.Rectype AND 
                     c.GapStart = d.GapStart AND 
                     c.GapEnd = d.GapEnd THEN NULL WHEN CAST (d.GapStart AS INTEGER) >= CAST (c.GapStart AS INTEGER) AND 
                                                        CAST (d.GapStart AS INTEGER) < CAST (c.GapEnd AS INTEGER) AND 
                                                        d.Rectype = c.RecType THEN 'Overlap' ELSE NULL END AS OverlapTest
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
           JOIN
           (
               tblGapDetail
           ) AS c
           ON b.RecKey = c.RecKey
           JOIN
           (
               tblGapDetail
           ) AS d
           ON c.RecKey = d.RecKey
     WHERE OverlapTest IS NOT NULL AND 
           c.GapStart <> '' AND 
           d.GapStart <> '' AND 
           c.GapEnd <> '' AND 
           d.GapEnd <> ''
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID,
              b.FormDate,
              c.GapStart,
              d.GapStart;


--QAQC_GAP_MeasureIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_GAP_MeasureIncorrect','Gap Intercept','Form Default','Data collection units incorrect.','1=metric; 2=english','GAP_MeasureIncorrect','Measure','=1');
			  
CREATE VIEW QAQC_GAP_MeasureIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.Measure
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
     WHERE b.Measure <> 1
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;


--QAQC_GAP_LineLengthIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_GAP_LineLengthIncorrect','Gap Intercept','Form Default','Line Length was outside criterion.','Lines may have different lengths for appropriate reason, use only to double check.','GAP_LineLengthIncorrect','LineLengthAmount','=25m');
			  
CREATE VIEW QAQC_GAP_LineLengthIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.LineLengthAmount
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
     WHERE b.LineLengthAmount IS NULL OR 
           b.LineLengthAmount <> 25
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;

			  
--QAQC_GAP_MinIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_GAP_MinIncorrect','Gap Intercept','Form Default','Minimum Gap is incorrect.',NULL,'GAP_MinIncorrect','GapMin','=20cm');
			  
CREATE VIEW QAQC_GAP_MinIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.GapMin
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
     WHERE b.GapMin <> 20
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;


--QAQC_GAP_GapDataIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(5.0,'QAQC_GAP_GapDataIncorrect','Gap Intercept','Form Default','Data to be collected incorrect.','1=Basal and Canopy; 2= Canopy Gap Only; 3=Basal Gap Only','GAP_GapDataIncorrect','GapData','=2');
			  
CREATE VIEW QAQC_GAP_GapDataIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.GapData
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
     WHERE b.GapData <> 2
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;


--QAQC_GAP_StopsGapIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_GAP_StopsGapIncorrect','Gap Intercept','Form Option','Plants that stop a gap is incorrect.',NULL,'GAP_StopsGapIncorrect','StopsGap','=1');
			  
CREATE VIEW QAQC_GAP_StopsGapIncorrect AS
    SELECT x.*
      FROM (
               SELECT b.RecKey AS ErrorKey,
                      a.SiteID,
                      a.SiteName,
                      a.PlotID,
                      a.LineID,
                      b.DateModified,
                      b.FormType,
                      b.FormDate,
                      'Perennials' AS GapStopType,
                      b.Perennials AS StopsGap
                 FROM joinSitePlotLine AS a
                      JOIN
                      tblGapHeader AS b ON a.LineKey = b.LineKey
               UNION
               SELECT b.RecKey AS ErrorKey,
                      a.SiteID,
                      a.SiteName,
                      a.PlotID,
                      a.LineID,
                      b.DateModified,
                      b.FormType,
                      b.FormDate,
                      'Annual Grasses' AS GapStopType,
                      b.AnnualGrasses AS StopsGap
                 FROM joinSitePlotLine AS a
                      JOIN
                      tblGapHeader AS b ON a.LineKey = b.LineKey
               UNION
               SELECT b.RecKey AS ErrorKey,
                      a.SiteID,
                      a.SiteName,
                      a.PlotID,
                      a.LineID,
                      b.DateModified,
                      b.FormType,
                      b.FormDate,
                      'Annual Forbs' AS GapStopType,
                      b.AnnualForbs AS StopsGap
                 FROM joinSitePlotLine AS a
                      JOIN
                      tblGapHeader AS b ON a.LineKey = b.LineKey
               UNION
               SELECT b.RecKey AS ErrorKey,
                      a.SiteID,
                      a.SiteName,
                      a.PlotID,
                      a.LineID,
                      b.DateModified,
                      b.FormType,
                      b.FormDate,
                      'Other' AS GapStopType,
                      b.Other AS StopsGap
                 FROM joinSitePlotLine AS a
                      JOIN
                      tblGapHeader AS b ON a.LineKey = b.LineKey
           )
           AS x
     WHERE (x.GapStopType IN ('Perennials', 'Annual Grasses', 'AnnualForbs') AND 
            x.StopsGap = 0) OR 
           (x.GapStopType = 'Other' AND 
            x.StopsGap = 1) 
     ORDER BY x.SiteID,
              x.PlotID,
              x.LineID,
              x.GapStopType;


--QAQC_GAP_NoBasalGapChecked
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(5.0,'QAQC_GAP_NoBasalGapChecked','Gap Intercept','Form Option','No Basal Gaps checked and there is basal cover data.',NULL,'GAP_NoBasalGapChecked','NoBasalGaps','=FALSE');
			  
CREATE VIEW QAQC_GAP_NoBasalGapChecked AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.NoBasalGaps,
           c.Records
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
           JOIN
           (
               SELECT RecKey,
                      Count(SeqNo) AS Records
                 FROM tblGapDetail
                WHERE RecType = 'B'
                GROUP BY RecKey
           )
           AS c ON b.RecKey = c.RecKey
     WHERE b.NoBasalGaps = 1 AND 
           c.Records > 0
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;


--QAQC_GAP_NoCanopyGapChecked
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(6.0,'QAQC_GAP_NoCanopyGapChecked','Gap Intercept','Form Option','No Canopy Gaps checked and there is canopy cover data.','Double check, should almost always be =False, unless there really no gaps on a site.','GAP_NoCanopyGapChecked','NoCanopyGaps','=FALSE');
			  
CREATE VIEW QAQC_GAP_NoCanopyGapChecked AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.NoCanopyGaps,
           c.Records
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
           JOIN
           (
               SELECT RecKey,
                      Count(SeqNo) AS Records
                 FROM tblGapDetail
                WHERE RecType = 'C'
                GROUP BY RecKey
           )
           AS c ON b.RecKey = c.RecKey
     WHERE b.NoCanopyGaps = 1 AND 
           c.Records > 0
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;

			  
--QAQC_GAP_BlankForm
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_GAP_BlankForm','Gap Intercept','Missing Data','There is a blank form with no data and "No canopy gaps" hasn’t been checked.',NULL,'GAP_BlankForm',NULL,NULL);
			  
CREATE VIEW QAQC_GAP_BlankForm AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.GapData,
           b.NoCanopyGaps,
           b.NoBasalGaps,
           c.RecKey
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
           LEFT JOIN
           tblGapDetail AS c ON b.RecKey = c.RecKey
     WHERE (b.GapData = 1 AND 
            b.NoCanopyGaps = 0 AND 
            b.NoBasalGaps = 0 AND 
            c.RecKey IS NULL) OR 
           (b.GapData = 2 AND 
            b.NoCanopyGaps = 0 AND 
            c.RecKey IS NULL) OR 
           (b.GapData = 3 AND 
            b.NoBasalGaps = 0 AND 
            c.RecKey IS NULL) 
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;

			  
--QAQC_GAP_MissingObserver
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_GAP_MissingObserver','Gap Intercept','Missing Data','Missing Observer.',NULL,'GAP_MissingObserver','Observer',NULL);
			  
CREATE VIEW QAQC_GAP_MissingObserver AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.Observer,
           b.Recorder
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
     WHERE b.Observer IS NULL OR 
           b.Observer = ''
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;


--QAQC_GAP_MissingRecorder
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_GAP_MissingRecorder','Gap Intercept','Missing Data','Missing Recorder.',NULL,'GAP_MissingRecorder','Recorder',NULL);
			  
CREATE VIEW QAQC_GAP_MissingRecorder AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.Observer,
           b.Recorder
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
     WHERE b.Recorder IS NULL OR 
           b.Recorder = ''
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;


--QAQC_GAP_DataEntryNoErrorCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_GAP_DataEntryNoErrorCheck','Gap Intercept','Missing Data','There was data entry from other source (because DataEntry not NULL) and there is no Error Checker listed.',NULL,'GAP_DataEntryNoErrorCheck','DataErrorChecking',NULL);
		  
CREATE VIEW QAQC_GAP_DataEntryNoErrorCheck AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.Observer,
           b.Recorder,
           b.DataEntry,
           b.DataErrorChecking
      FROM joinSitePlotLine AS a
           JOIN
           tblGapHeader AS b ON a.LineKey = b.LineKey
     WHERE (b.DataEntry IS NOT NULL AND 
            b.DataEntry <> '') AND 
           (b.DataErrorChecking IS NULL OR 
            b.DataErrorChecking = '') 
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;


--QAQC_Gap_Detail_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_Gap_Detail_OrphanRecordCheck','Gap Intercept','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'Gap_Detail_OrphanRecordCheck',NULL,NULL);
			  
CREATE VIEW QAQC_Gap_Detail_OrphanRecordCheck AS
    SELECT a.RecKey || ';' || a.SeqNo AS ErrorKey,
           b.RecKey AS tblGapHeader_RecKey,
           a.RecKey AS tblGapDetail_RecKey,
           a.SeqNo,
           a.RecType,
           a.GapStart,
           a.GapEnd
      FROM tblGapDetail AS a
           LEFT JOIN
           tblGapHeader AS b ON a.RecKey = b.RecKey
     WHERE b.RecKey IS NULL;


--QAQC_Gap_Header_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_Gap_Header_OrphanRecordCheck','Gap Intercept','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'Gap_Header_OrphanRecordCheck',NULL,NULL);
	 
CREATE VIEW QAQC_Gap_Header_OrphanRecordCheck AS
    SELECT a.RecKey AS ErrorKey,
           b.LineKey AS tblLines_LineKey,
           a.LineKey AS tblGapHeader_LineKey,
           a.RecKey,
           a.DateModified,
           a.FormType,
           a.FormDate,
           a.Observer,
           a.Recorder
      FROM tblGapHeader AS a
           LEFT JOIN
           tblLines AS b ON a.LineKey = b.LineKey
     WHERE b.LineKey IS NULL;


--QAQC_IIRH_CompositionBaseIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_IIRH_CompositionBaseIncorrect','Interpreting Indicators of Rangeland Health','Form Option','Composition incorrect.','1=Annual Production; 2=Cover Produced During Current Year; 3=Biomass','IIRH_CompositionBaseIncorrect','CompositionBase','=2');
	 
CREATE VIEW QAQC_IIRH_CompositionBaseIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           b.DateModified,
           b.FormDate,
           b.EcolSite,
           b.CompositionBase
      FROM joinSitePlot AS a
           JOIN
           tblQualHeader AS b ON a.PlotKey = b.PlotKey
     WHERE trim(b.EcolSite) <> 'UNKNOWN' AND 
           b.CompositionBase <> 2
     ORDER BY a.SiteID,
              a.PlotID;


--QAQC_IIRH_SitePhotoTakenIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_IIRH_SitePhotoTakenIncorrect','Interpreting Indicators of Rangeland Health','Form Option','Site Photo Taken? Incorrect.',NULL,'IIRH_SitePhotoTakenIncorrect','SitePhotoTaken','=TRUE');
			  
CREATE VIEW QAQC_IIRH_SitePhotoTakenIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           b.FormDate,
           b.EcolSite,
           b.SitePhotoTaken
      FROM joinSitePlot AS a
           JOIN
           tblQualHeader AS b ON a.PlotKey = b.PlotKey
     WHERE trim(b.EcolSite) <> 'UNKNOWN' AND 
           b.SitePhotoTaken <> 1
     ORDER BY a.SiteID,
              a.PlotID;


--QAQC_IIRH_AttrEvalMethodIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_IIRH_AttrEvalMethodIncorrect','Interpreting Indicators of Rangeland Health','Form Option','Attribute Evaluation Method in the Attribute Ratings tab incorrect.','0=Manual (preponderance of evidnce); 1= Automatic #1 (all indicators weighted equally); 2=Automatic #2 (indicator weights downloaded); 3=Automatic #3 (user-defined weights)','IIRH_AttrEvalMethodIncorrect','AttrEvalMethod','=0');
			  
CREATE VIEW QAQC_IIRH_AttrEvalMethodIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           b.DateModified,
           b.FormDate,
           b.EcolSite,
           b.AttrEvalMethod
      FROM joinSitePlot AS a
           JOIN
           tblQualHeader AS b ON a.PlotKey = b.PlotKey
     WHERE trim(b.EcolSite) <> 'UNKNOWN' AND 
           b.AttrEvalMethod <> 0
     ORDER BY a.SiteID,
              a.PlotID;

			  
--QAQC_IIRH_RefSheetTypeIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_IIRH_RefSheetTypeIncorrect','Interpreting Indicators of Rangeland Health','Form Option','Missing or incorrect Type under the Reference Sheet heading (listbox).','1=New; 2=Existing - downloaded from NRCS; 3=Existing - obtained from other source','IIRH_RefSheetTypeIncorrect','RefSheetType','=2');
			  
CREATE VIEW QAQC_IIRH_RefSheetTypeIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           b.DateModified,
           b.FormDate,
           b.EcolSite,
           b.RefSheetType,
           b.RepCriteria
      FROM joinSitePlot AS a
           LEFT JOIN
           tblQualHeader AS b ON a.PlotKey = b.PlotKey
     WHERE trim(b.EcolSite) <> 'UNKNOWN' AND 
           b.RefSheetType <> 2 AND 
           b.RepCriteria NOT LIKE '*no ref*'
     ORDER BY a.SiteID,
              a.PlotID;

			  
--QAQC_IIRH_MissingData	
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_IIRH_MissingData','Interpreting Indicators of Rangeland Health','Missing Data','No IIRH done at this plot.',NULL,'IIRH_MissingData',NULL,'=TRUE');
		  
CREATE VIEW QAQC_IIRH_MissingData AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EcolSite,
           c.RecKey
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           LEFT JOIN
           tblQualHeader AS c ON b.PlotKey = c.PlotKey
     WHERE trim(b.EcolSite) <> 'UNKNOWN' AND 
           c.RecKey IS NULL
     ORDER BY a.SiteID,
              b.PlotID;

			  
--QAQC_IIRH_EvalAreaSizeIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_IIRH_EvalAreaSizeIncorrect','Interpreting Indicators of Rangeland Health','Missing Data','Missing Evaluation Area Size.',NULL,'IIRH_EvalAreaSizeIncorrect','EvalAreaSize','=0.28 ha');		  

CREATE VIEW QAQC_IIRH_EvalAreaSizeIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           b.DateModified,
           b.FormDate,
           b.EcolSite,
           b.EvalAreaSize
      FROM joinSitePlot AS a
           JOIN
           tblQualHeader AS b ON a.PlotKey = b.PlotKey
     WHERE trim(b.EcolSite) <> 'UNKNOWN' AND 
           (b.EvalAreaSize IS NULL OR 
            b.EvalAreaSize <> '0.28 ha') 
     ORDER BY a.SiteID,
              a.PlotID;

			  
--QAQC_IIRH_MissingObserver	
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_IIRH_MissingObserver','Interpreting Indicators of Rangeland Health','Missing Data','Missing Observer.',NULL,'IIRH_MissingObserver','Observer',NULL);
	  
CREATE VIEW QAQC_IIRH_MissingObserver AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           b.DateModified,
           b.FormDate,
           b.Observer,
           b.Recorder,
           b.EcolSite
      FROM joinSitePlot AS a
           JOIN
           tblQualHeader AS b ON a.PlotKey = b.PlotKey
     WHERE b.Observer IS NULL OR 
           b.Observer = ''
     ORDER BY a.SiteID,
              a.PlotID;


--QAQC_IIRH_MissingRecorder
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_IIRH_MissingRecorder','Interpreting Indicators of Rangeland Health','Missing Data','Missing Recorder.',NULL,'IIRH_MissingRecorder','Recorder',NULL);
			  
CREATE VIEW QAQC_IIRH_MissingRecorder AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           b.DateModified,
           b.FormDate,
           b.Observer,
           b.Recorder,
           b.EcolSite
      FROM joinSitePlot AS a
           JOIN
           tblQualHeader AS b ON a.PlotKey = b.PlotKey
     WHERE b.Recorder IS NULL OR 
           b.Recorder = ''
     ORDER BY a.SiteID,
              a.PlotID;
			  
			  
--QAQC_IIRH_MissingRefSheetAuthor
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(5.0,'QAQC_IIRH_MissingRefSheetAuthor','Interpreting Indicators of Rangeland Health','Missing Data','Missing Author Initials under the Reference Sheet heading.',NULL,'IIRH_MissingRefSheetAuthor','RefSheetAuthor',NULL);

CREATE VIEW QAQC_IIRH_MissingRefSheetAuthor AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           b.DateModified,
           b.FormDate,
           b.EcolSite,
           b.RefSheetAuthor,
           b.RepCriteria
      FROM joinSitePlot AS a
           JOIN
           tblQualHeader AS b ON a.PlotKey = b.PlotKey
     WHERE trim(b.EcolSite) <> 'UNKNOWN' AND 
           (b.RefSheetAuthor IS NULL OR 
            b.RefSheetAuthor = '') AND 
           b.RepCriteria NOT LIKE '%no ref%'
     ORDER BY a.SiteID,
              a.PlotID;
			  
			  
--QAQC_IIRH_MissingRefSheetDate
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(6.0,'QAQC_IIRH_MissingRefSheetDate','Interpreting Indicators of Rangeland Health','Missing Data','Missing Date Created under the Reference Sheet heading.',NULL,'IIRH_MissingRefSheetDate','RefSheetDate',NULL);

CREATE VIEW QAQC_IIRH_MissingRefSheetDate AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           b.DateModified,
           b.FormDate,
           b.EcolSite,
           b.RefSheetDate,
           b.RepCriteria
      FROM joinSitePlot AS a
           JOIN
           tblQualHeader AS b ON a.PlotKey = b.PlotKey
     WHERE trim(b.EcolSite) <> 'UNKNOWN' AND 
           (b.RefSheetDate IS NULL OR 
            b.RefSheetDate = '') AND 
           b.RepCriteria NOT LIKE '%no ref%'
     ORDER BY a.SiteID,
              a.PlotID;
			  
			  
--QAQC_IIRH_MissingIndicatorRating
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(7.0,'QAQC_IIRH_MissingIndicatorRating','Interpreting Indicators of Rangeland Health','Missing Data','Missng Indicator Rating and rating is not Annual Production.',NULL,'IIRH_MissingIndicatorRating','Rating',NULL);

CREATE VIEW QAQC_IIRH_MissingIndicatorRating AS
    SELECT c.RecKey || ';' || c.Seq AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           b.EcolSite,
           c.Seq,
           c.Rating,
           c.Comment,
           b.RepCriteria
      FROM joinSitePlot AS a
           JOIN
           tblQualHeader AS b ON a.PlotKey = b.PlotKey
           JOIN
           tblQualDetail AS c ON b.RecKey = c.RecKey
     WHERE trim(b.EcolSite) <> 'UNKNOWN' AND 
           c.Seq <> 15 AND 
           c.Rating = 0 AND 
           b.RepCriteria NOT LIKE '%no ref%'
     ORDER BY a.SiteID,
              a.PlotID,
              c.Seq;
			  
			  
--QAQC_IIRH_MissingIndicatorComment_RatingNotNS
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(8.0,'QAQC_IIRH_MissingIndicatorComment_RatingNotNS','Interpreting Indicators of Rangeland Health','Missing Data','If an Indicator is anything other than None to Slight,there should be a comment.',NULL,'IIRH_MissingIndComment_NotNS','Comment',NULL);

CREATE VIEW QAQC_IIRH_MissingIndicatorComment_RatingNotNS AS
    SELECT c.RecKey || ';' || c.Seq AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           b.EcolSite,
           c.Seq,
           c.Rating,
           c.Comment,
           b.RepCriteria
      FROM joinSitePlot AS a
           JOIN
           tblQualHeader AS b ON a.PlotKey = b.PlotKey
           JOIN
           tblQualDetail AS c ON b.RecKey = c.RecKey
     WHERE trim(b.EcolSite) <> 'UNKNOWN' AND 
           c.Seq <> 15 AND 
           c.Rating <> 1 AND 
           b.RepCriteria NOT LIKE '%no ref%' AND 
           c.Comment IS NOT NULL AND 
           c.Comment <> ''
     ORDER BY a.SiteID,
              a.PlotID,
              c.Seq;

			  
--QAQC_IIRH_MissingAttrRating
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(9.0,'QAQC_IIRH_MissingAttrRating','Interpreting Indicators of Rangeland Health','Missing Data','Missing Rating.',NULL,'IIRH_MissingAttrRating','RatingCode',NULL);
			  
CREATE VIEW QAQC_IIRH_MissingAttrRating AS
    SELECT x.RecKey || ';' || x.Description AS ErrorKey,
           x.*
      FROM (
               SELECT c.SiteKey,
                      b.PlotKey,
                      a.RecKey,
                      c.SiteID,
                      c.SiteName,
                      b.PlotID,
                      b.EcolSite,
                      a.RepCriteria,
                      'Attribute' AS Category,
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
                      a.RepCriteria,
                      'Attribute' AS Category,
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
                      a.RepCriteria,
                      'Attribute' AS Category,
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
                         Description
           )
           AS x
     WHERE trim(x.EcolSite) <> 'UNKNOWN' AND 
           x.RepCriteria NOT LIKE '%no ref%' AND 
           (x.RatingCode = '' OR 
            x.RatingCode IS NULL);
			
			
--QAQC_IIRH_MissingAttrComment_NotNS
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(10.0,'QAQC_IIRH_MissingAttrComment_NotNS','Interpreting Indicators of Rangeland Health','Missing Data','If a Final Rating is anything other than None to Slight,there should be a comment.',NULL,'IIRH_MissingAttrComment_NotNS','Comment',NULL);

CREATE VIEW QAQC_IIRH_MissingAttrComment_NotNS AS
	SELECT x.RecKey || ';' || x.Description AS ErrorKey,
           x.*
      FROM (
               SELECT c.SiteKey,
                      b.PlotKey,
                      a.RecKey,
                      c.SiteID,
                      c.SiteName,
                      b.PlotID,
                      b.EcolSite,
                      a.RepCriteria,
                      'Attribute' AS Category,
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
                      a.RepCriteria,
                      'Attribute' AS Category,
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
                      a.RepCriteria,
                      'Attribute' AS Category,
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
                         Description
           )
           AS x
     WHERE trim(x.EcolSite) <> 'UNKNOWN' AND 
           (x.RatingCode IS NOT NULL AND 
           x.RatingCode <> 'NS') AND 
           (x.Comment IS NULL OR 
           x.Comment = '');
		   
		   
--QAQC_IIRH_Detail_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_IIRH_Detail_OrphanRecordCheck','Interpreting Indicators of Rangeland Health','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'IIRH_Detail_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_IIRH_Detail_OrphanRecordCheck AS
    SELECT a.RecKey || ';' || a.Seq AS ErrorKey,
           b.RecKey AS tblQualHeader_RecKey,
           a.RecKey AS tblQualDetail_RecKey,
           a.Seq,
           a.Rating,
           a.SSSWt,
           a.SSSVxW,
           a.HFWt,
           a.HFVxW,
           a.BIWt,
           a.BIVxW,
           a.Comment
      FROM tblQualDetail AS a
           LEFT JOIN
           tblQualHeader AS b ON a.RecKey = b.RecKey
     WHERE b.RecKey IS NULL;
	 
	 
--QAQC_IIRH_Header_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_IIRH_Header_OrphanRecordCheck','Interpreting Indicators of Rangeland Health','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'IIRH_Header_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_IIRH_Header_OrphanRecordCheck AS
    SELECT a.RecKey AS ErrorKey,
           b.PlotKey AS tblPlots_PlotKey,
           a.PlotKey AS tblQualHeader_PlotKey,
           a.RecKey,
           a.DateModified,
           a.FormDate,
           a.Observer,
           a.Recorder,
           a.EcolSite
      FROM tblQualHeader AS a
           LEFT JOIN
           tblPlots AS b ON a.PlotKey = b.PlotKey
     WHERE b.PlotKey IS NULL;
	 
	 
--QAQC_Lines_ElevationTypeIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_Lines_ElevationTypeIncorrect','Line Definition','Form Option','The Elevation units of measure chosen for the line is incorrect.','1="m" or meters 2="ft" or feet','Lines_ElevationTypeIncorrect','ElevationType','=1');

CREATE VIEW QAQC_Lines_ElevationTypeIncorrect AS
    SELECT c.LineKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           b.GPSCoordSys,
           b.Datum,
           b.Zone,
           c.ElevationType,
           c.ElevationStart,
           c.ElevationEnd
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           c.ElevationType <> 1
     ORDER BY a.SiteID,
              b.PlotID,
              c.LineID;
			  
			  
--QAQC_Lines_NorthTypeIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_Lines_NorthTypeIncorrect','Line Definition','Form Option','The wrong type of North was used. Should not be changed without checking whether or not to convert the associated azimuth between geodetic and magnetic (or vice versa).','(Magnetic = 1, True = 2)','Lines_NorthTypeIncorrect','NorthType','=2');

CREATE VIEW QAQC_Lines_NorthTypeIncorrect AS
    SELECT c.LineKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           b.GPSCoordSys,
           b.Datum,
           b.Zone,
           c.NorthType
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           c.NorthType <> 2
     ORDER BY a.SiteID,
              b.PlotID,
              c.LineID;
			  
			  
--QAQC_Lines_AzimuthIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_Lines_AzimuthIncorrect','Line Definition','Data Criterion Failure','Azimuth incorrect.',NULL,'Lines_AzimuthIncorrect','Azimuth','(0,120,240)');

CREATE VIEW QAQC_Lines_AzimuthIncorrect AS
    SELECT c.LineKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           c.Azimuth
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           c.Azimuth NOT IN (0, 120, 240) 
     ORDER BY a.SiteID,
              b.PlotID,
              c.LineID;
			  
			  
--QAQC_Lines_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_Lines_OrphanRecordCheck','Line Definition','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'Lines_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_Lines_OrphanRecordCheck AS
    SELECT a.LineKey AS ErrorKey,
           b.PlotKey AS tblPlots_PlotKey,
           a.PlotKey AS tblLines_PlotKey,
           a.LineKey,
           a.DateModified,
           a.LineID
      FROM tblLines AS a
           LEFT JOIN
           tblPlots AS b ON a.PlotKey = b.PlotKey
     WHERE b.PlotKey IS NULL;
	 
	 
--QAQC_LPI_HeightsMissingOrIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_LPI_HeightsMissingOrIncorrect','Line-point Intercept','Data Criterion Failure','There is a height at a non-standard point location (not divisiable by Criteria)',NULL,'LPI_HeightsMissingOrIncorrect','PointNbr','');

CREATE VIEW QAQC_LPI_HeightsMissingOrIncorrect AS
    SELECT RecKey || ';' || PointNbr || ';' || Category AS ErrorKey,
           SiteID,
           PlotID,
           LineID,
           FormDate,
           PointNbr,
           Species,
           ChkBox,
           Height,
           Category,
           Rank
      FROM LPI_CanopyLayers_Point_DB_UNION
     WHERE (Height IS NOT NULL AND 
            Height <> '' AND 
            PointNbr % 5 <> 0) OR 
           ( (Height IS NULL OR 
              Height = '') AND 
             PointNbr % 5 = 0 AND 
             Category IN ('Woody', 'Herbaceous') ) 
     ORDER BY SiteID,
              PlotID,
              LineID,
              PointNbr,
              Category;
			  
			  
--QAQC_LPI_Species_NoGrowthHabitDuration
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_LPI_Species_NoGrowthHabitDuration','Line-point Intercept','Data Criterion Failure','A species was used in this line''s data that does not have a growth habit or does not have a duration assigned to it in the state species list.',NULL,'LPI_SpeciesNoGrowthHabitDur','GrowthHabit OR Duration','Not Null');

CREATE VIEW QAQC_LPI_Species_NoGrowthHabitDuration AS
    SELECT a.PlotKey || ';' || a.Species AS ErrorKey,
           a.SiteID,
           a.PlotID,
           a.Species,
           b.Duration,
           c.GrowthHabitSub
      FROM LPI_CanopyLayers_Point_DB_UNION AS a
           JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS c ON b.GrowthHabitCode = c.Code
     WHERE b.Duration IS NULL OR 
           c.GrowthHabitSub IS NULL
     GROUP BY a.PlotKey,
              a.Species
     ORDER BY SiteID,
              PlotID;
			  
			  
--QAQC_LPI_FormDateCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_LPI_FormDateCheck','Line-point Intercept','Data Criterion Failure','Lines have different dates. Use to check for incorrect date.','If methods are done on different days or if there is multiple years data in the database, this check will return valid dates.','LPI_FormDateCheck',NULL,NULL);

CREATE VIEW QAQC_LPI_FormDateCheck AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteKey,
           a.SiteID,
           a.SiteName,
           a.PlotKey,
           a.PlotID,
           a.LineKey,
           a.LineID,
           date(b.FormDate) AS FormDate,
           date(c.MinFormDate) AS MinFormDate,
           date(c.MaxFormDate) AS MaxFormDate,
           julianday(c.MaxFormDate) - julianday(c.MinFormDate) AS FormDateDayDif
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           (
               SELECT x.PlotKey,
                      Min(y.FormDate) AS MinFormDate,
                      Max(y.FormDate) AS MaxFormDate
                 FROM joinSitePlotLine AS x
                      JOIN
                      tblLPIHeader AS y ON x.LineKey = y.LineKey
                GROUP BY x.PlotKey
           )
           AS c ON a.PlotKey = c.PlotKey
     WHERE FormDateDayDif >= 1
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_MeasureIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_LPI_MeasureIncorrect','Line-point Intercept','Form Default','Data collections units are incorrect.','1=metric; 2=english','LPI_MeasureIncorrect','Measure','=1');

CREATE VIEW QAQC_LPI_MeasureIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.Measure
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.Measure IS NULL OR 
           b.Measure <> 1
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;


--QAQC_LPI_LineLengthIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_LPI_LineLengthIncorrect','Line-point Intercept','Form Default','Line Length is outside criterion.',NULL,'LPI_LineLengthIncorrect','LineLengthAmount','=25m');
			  
CREATE VIEW QAQC_LPI_LineLengthIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.LineLengthAmount
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.LineLengthAmount <> 25
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_SpacingTypeIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_LPI_SpacingTypeIncorrect','Line-point Intercept','Form Default','Spacing Interval Type is incorrect.','Metric(cm or m), English(ft)','LPI_SpacingTypeIncorrect','SpacingType','=cm');

CREATE VIEW QAQC_LPI_SpacingTypeIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.SpacingType
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.SpacingType <> 'cm'
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_SpacingIntervalIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(5.0,'QAQC_LPI_SpacingIntervalIncorrect','Line-point Intercept','Form Default','Spacing Interval is incorrect.',NULL,'LPI_SpacingIntervalIncorrect','SpacingIntervalAmount','=50');

CREATE VIEW QAQC_LPI_SpacingIntervalIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.SpacingIntervalAmount
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.SpacingIntervalAmount <> 50
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_HeightOptionIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(8.0,'QAQC_LPI_HeightOptionIncorrect','Line-point Intercept','Form Default','Height Option is incorrect.',NULL,'LPI_HeightOptionIncorrect','HeightOption','every 5th');

CREATE VIEW QAQC_LPI_HeightOptionIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.HeightOption
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.HeightOption IS NULL OR 
           b.HeightOption <> 'every 5th'
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_HeightUOMIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(9.0,'QAQC_LPI_HeightUOMIncorrect','Line-point Intercept','Form Default','Height Units incorrect.',NULL,'LPI_HeightUOMIncorrect','HeightUOM','=cm');

CREATE VIEW QAQC_LPI_HeightUOMIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.HeightUOM
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.HeightUOM IS NULL OR 
           b.HeightUOM <> 'cm'
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_HeightNoneOptionIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(10.0,'QAQC_LPI_HeightNoneOptionIncorrect','Line-point Intercept','Form Default','"Permit non-zero Height in Top Canopy, when ''None''" is incorrect.',NULL,'LPI_HeightNoneOptionIncorrect','HeightNoneOption','=FALSE');

CREATE VIEW QAQC_LPI_HeightNoneOptionIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.HeightNoneOption
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.HeightNoneOption = 1
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_LayerHeightsIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(11.0,'QAQC_LPI_LayerHeightsIncorrect','Line-point Intercept','Form Default','Heights for each layer (Top, Lower and Soil) is incorrect.',NULL,'LPI_LayerHeightsIncorrect','LayerHeights','=FALSE');

CREATE VIEW QAQC_LPI_LayerHeightsIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.LayerHeights
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.LayerHeights = 1
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_WoodyHerbHeightsIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(12.0,'QAQC_LPI_WoodyHerbHeightsIncorrect','Line-point Intercept','Form Default','"BLM AIM Herbaceous and Woody heights" is incorrect.',NULL,'LPI_WoodyHerbHeightsIncorrect','WoodyHerbHeights','=TRUE');

CREATE VIEW QAQC_LPI_WoodyHerbHeightsIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.WoodyHerbHeights
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.WoodyHerbHeights = 0
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  

--QAQC_LPI_ShowCheckboxIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(13.0,'QAQC_LPI_ShowCheckboxIncorrect','Line-point Intercept','Form Default','Show Checkbox is incorrect.',NULL,'LPI_ShowCheckboxIncorrect','ShowCheckbox','=TRUE');
			  
CREATE VIEW QAQC_LPI_ShowCheckboxIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.ShowCheckbox
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.ShowCheckbox = 0
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_CheckboxLabelIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(14.0,'QAQC_LPI_CheckboxLabelIncorrect','Line-point Intercept','Form Default','Checkbox Label is incorrect.',NULL,'LPI_CheckboxLabelIncorrect','CheckboxLabel','=Dead');

CREATE VIEW QAQC_LPI_CheckboxLabelIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.CheckboxLabel
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.CheckboxLabel NOT LIKE '%Dead%'
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_ShowShrubShapeIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(15.0,'QAQC_LPI_ShowShrubShapeIncorrect','Line-point Intercept','Form Default','"Show ShrubShape" in incorrect.',NULL,'LPI_ShowShrubShapeIncorrect','ShowShrubShape','=TRUE');

CREATE VIEW QAQC_LPI_ShowShrubShapeIncorrect AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.ShowShrubShape
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.ShowShrubShape = 0
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  

--QAQC_LPI_MissingData
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_LPI_MissingData','Line-point Intercept','Missing Data','These are lines without LPI data.','This query will give lines with no LPI data, which includes empty plots and lines not planned for revisit or not yet revisited.','LPI_MissingData',NULL,NULL);
			  
CREATE VIEW QAQC_LPI_MissingData AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.RecKey
      FROM joinSitePlotLine AS a
           LEFT JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.RecKey IS NULL
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_MissingObserver
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_LPI_MissingObserver','Line-point Intercept','Missing Data','Missing Observer.',NULL,'LPI_MissingObserver','Observer',NULL);

CREATE VIEW QAQC_LPI_MissingObserver AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.Observer
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.Observer IS NULL OR 
           b.Observer = ''
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_MissingRecorder
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_LPI_MissingRecorder','Line-point Intercept','Missing Data','Missing Recorder.',NULL,'LPI_MissingRecoder','Recorder',NULL);

CREATE VIEW QAQC_LPI_MissingRecorder AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.Recorder
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE b.Recorder IS NULL OR 
           b.Recorder = ''
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_DataEntryNoErrorCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_LPI_DataEntryNoErrorCheck','Line-point Intercept','Missing Data','There was data entry from other source (because DataEntry not NULL) and there is no Error Checker listed.',NULL,'LPI_DataEntryNoErrorCheck','DataErrorChecking',NULL);

CREATE VIEW QAQC_LPI_DataEntryNoErrorCheck AS
    SELECT b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           b.DataEntry,
           b.DataErrorChecking
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
     WHERE (b.DataEntry IS NOT NULL AND 
            b.DataEntry <> '') AND 
           (b.DataErrorChecking IS NULL OR 
            b.DataErrorChecking = '') 
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID;
			  
			  
--QAQC_LPI_TopCanopyMissing
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(5.0,'QAQC_LPI_TopCanopyMissing','Line-point Intercept','Missing Data','These points are missing a Top Canopy, a required element.',NULL,'LPI_TopCanopyMissing','TopCanopy',NULL);

CREATE VIEW QAQC_LPI_TopCanopyMissing AS
    SELECT c.RecKey || ';' || c.PointNbr AS ErrorKey,
           b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           c.PointNbr,
           c.PointLoc,
           c.TopCanopy
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
     WHERE c.TopCanopy IS NULL OR 
           c.TopCanopy = ''
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID,
              PointNbr;
			  
			  
--QAQC_LPI_SoilSurfaceMissing
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(6.0,'QAQC_LPI_SoilSurfaceMissing','Line-point Intercept','Missing Data','These points are missing a Soil Surface, a required element.',NULL,'LPI_SoilSurfaceMissing','SoilSurface',NULL);

CREATE VIEW QAQC_LPI_SoilSurfaceMissing AS
    SELECT c.RecKey || ';' || c.PointNbr AS ErrorKey,
           b.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           a.PlotID,
           a.LineID,
           b.DateModified,
           b.FormType,
           b.FormDate,
           c.PointNbr,
           c.PointLoc,
           c.SoilSurface
      FROM joinSitePlotLine AS a
           JOIN
           tblLPIHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblLPIDetail AS c ON b.RecKey = c.RecKey
     WHERE c.SoilSurface IS NULL OR 
           c.SoilSurface = ''
     ORDER BY a.SiteID,
              a.PlotID,
              a.LineID,
              PointNbr;
			  
			  
--QAQC_LPI_Species_NotInSpeciesList
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(9.0,'QAQC_LPI_Species_NotInSpeciesList','Line-point Intercept','Missing Data','There was a Species code used in LPI that is not present in the Master Species List',NULL,'LPI_Species_NotInSpeciesList','Species',NULL);

CREATE VIEW QAQC_LPI_Species_NotInSpeciesList AS
    SELECT a.RecKey || ';' || a.PointNbr || ';' || a.Category AS ErrorKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           a.FormDate,
           a.PointNbr,
           a.Species,
           a.Category,
           a.Rank
      FROM LPI_CanopyLayers_Point_DB_UNION AS a
           LEFT JOIN
           tblSpecies AS b ON a.Species = b.SpeciesCode
           LEFT JOIN
           NonSpeciesCodes AS c ON a.Species = c.Code
     WHERE a.Species IS NOT NULL AND 
           c.Code IS NULL AND 
           b.SpeciesCode IS NULL
     ORDER BY SiteID,
              PlotID,
              LineID,
              PointNbr,
              Category;
			  
			  
--QAQC_LPI_Header_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_LPI_Header_OrphanRecordCheck','Line-point Intercept','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'LPI_Header_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_LPI_Header_OrphanRecordCheck AS
    SELECT a.RecKey AS ErrorKey,
           b.LineKey AS tblLines_LineKey,
           a.LineKey AS tblLPIHeader_LineKey,
           a.RecKey,
           a.DateModified,
           a.FormType,
           a.FormDate,
           a.Observer,
           a.Recorder
      FROM tblLPIHeader AS a
           LEFT JOIN
           tblLines AS b ON a.LineKey = b.LineKey
     WHERE b.LineKey IS NULL;
	 
	 
--QAQC_LPI_Detail_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_LPI_Detail_OrphanRecordCheck','Line-point Intercept','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'LPI_Detail_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_LPI_Detail_OrphanRecordCheck AS
    SELECT a.RecKey || ';' || a.PointLoc AS ErrorKey,
           b.RecKey AS tblLPIHeader_RecKey,
           a.RecKey AS tblLPIDetail_RecKey,
           a.PointLoc,
           a.PointNbr
      FROM tblLPIDetail AS a
           LEFT JOIN
           tblLPIHeader AS b ON a.RecKey = b.RecKey
     WHERE b.RecKey IS NULL;
	 
	 
--QAQC_PD_DifferentSubQuadSizeDifSpecies
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_PD_DifferentSubQuadSizeDifSpecies','Plant Density','Data Criterion Failure','plant species in the same quadrat have a different subquadrat size associated with them.',NULL,'PD_DifSubQuadSizeDifSpecies','SubQuadSize','Max(SubQuadSize) - Min(SubQuadSize) = 0');

CREATE VIEW QAQC_PD_DifferentSubQuadSizeDifSpecies AS
    SELECT x.RecKey || ';' || x.Quadrat || ';' || y.Quadrat AS ErrorKey,
           x.*,
           y.MaxOfSubQuadSize,
           (y.MaxOfSubQuadSize - x.MinOfSubQuadSize) AS SubQuadSizeDif
      FROM (
               SELECT a.SiteID,
                      a.SiteName,
                      a.PlotID,
                      a.LineID,
                      c.RecKey,
                      c.Quadrat,
                      Min(c.SubQuadSize) AS MinOfSubQuadSize
                 FROM joinSitePlotLine AS a
                      JOIN
                      tblPlantDenHeader AS b ON a.LineKey = b.LineKey
                      JOIN
                      tblPlantDenDetail AS c ON b.RecKey = c.RecKey
                GROUP BY a.SiteID,
                         a.SiteName,
                         a.PlotID,
                         a.LineID,
                         c.RecKey,
                         c.Quadrat,
                         a.SiteKey,
                         b.RecKey
           )
           AS x
           JOIN
           (
               SELECT a.SiteID,
                      a.SiteName,
                      a.PlotID,
                      a.LineID,
                      c.RecKey,
                      c.Quadrat,
                      Max(c.SubQuadSize) AS MaxOfSubQuadSize
                 FROM joinSitePlotLine AS a
                      JOIN
                      tblPlantDenHeader AS b ON a.LineKey = b.LineKey
                      JOIN
                      tblPlantDenDetail AS c ON b.RecKey = c.RecKey
                GROUP BY a.SiteID,
                         a.SiteName,
                         a.PlotID,
                         a.LineID,
                         c.RecKey,
                         c.Quadrat,
                         a.SiteKey,
                         b.RecKey
           )
           AS y ON x.RecKey = y.RecKey
     WHERE SubQuadSizeDif > 0
     ORDER BY x.SiteID,
              x.PlotID,
              x.LineID,
              x.Quadrat;
			  
			  
--QAQC_PD_FormDateCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_PD_FormDateCheck','Plant Density','Data Criterion Failure','Lines have different dates. Use to check for incorrect date.','If methods are done on different days or if there is multiple years data in the database, this check will return valid dates.','PD_FormDateCheck',NULL,NULL);

CREATE VIEW QAQC_PD_FormDateCheck AS
    SELECT z.RecKey AS ErrorKey,
           x.SiteKey,
           x.SiteID,
           x.SiteName,
           x.PlotKey,
           x.PlotID,
           x.LineKey,
           x.LineID,
           'PlantDensity' AS FormType,
           z.FormDate,
           y.MinOfFormDate,
           y.MaxOfFormDate,
           julianday(y.MaxOfFormDate) - julianday(y.MinOfFormDate) AS FormDateDayDif
      FROM joinSitePlotLine AS x
           JOIN
           (
               SELECT a.SiteKey,
                      a.SiteID,
                      a.SiteName,
                      a.PlotKey,
                      a.PlotID,
                      'PlantDensity' AS FormType,
                      Min(b.FormDate) AS MinOfFormDate,
                      Max(b.FormDate) AS MaxOfFormDate
                 FROM joinSitePlotLine AS a
                      JOIN
                      tblPlantDenHeader AS b ON a.LineKey = b.LineKey
                GROUP BY a.PlotKey
           )
           AS y ON x.PlotKey = y.PlotKey
           JOIN
           tblPlantDenHeader AS z ON x.LineKey = z.LineKey
     WHERE FormDateDayDif >= 1
     ORDER BY x.SiteID,
              x.PlotID,
              x.LineID;
			  
			  
--QAQC_PD_SubQuadSizeIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_PD_SubQuadSizeIncorrect','Plant Density','Data Criterion Failure','The sub quardrat size is incorrect for these species',NULL,'PD_SubQuadSizeIncorrect','SubQuadSize','1_or_150');

CREATE VIEW QAQC_PD_SubQuadSizeIncorrect AS
    SELECT c.RecKey || ';' || c.Quadrat || ';' || c.SpeciesCode AS ErrorKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           c.SpeciesCode,
           c.SubQuadSize
      FROM joinSitePlotLine AS a
           JOIN
           tblPlantDenHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblPlantDenDetail AS c ON b.RecKey = c.RecKey
     WHERE c.SubQuadSize NOT IN (1, 150);
	 
	 
--QAQC_PD_MeasureIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_PD_MeasureIncorrect','Plant Density','Form Default','Data collections units are incorrect.','1=metric; 2=english','PD_MeasureIncorrect','Measure','=1');

CREATE VIEW QAQC_PD_MeasureIncorrect AS
    SELECT b.Reckey AS ErrorKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           b.Measure
      FROM joinSitePlotLine AS a
           JOIN
           tblPlantDenHeader AS b ON a.LineKey = b.LineKey
     WHERE b.Measure <> 1;
	 
	 
--QAQC_PD_NumQuadratsIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_PD_NumQuadratsIncorrect','Plant Density','Form Default','The number of subquadrats for this form is incorrect.',NULL,'PD_NumQuadratsIncorrect','numQuadrats','1_or_10');

CREATE VIEW QAQC_PD_NumQuadratsIncorrect AS
    SELECT b.Reckey AS ErrorKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           b.NumQuadrats
      FROM joinSitePlotLine AS a
           JOIN
           tblPlantDenHeader AS b ON a.LineKey = b.LineKey
     WHERE b.NumQuadrats NOT IN (1, 10);
	 
	 
--QAQC_PD_LineLengthIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_PD_LineLengthIncorrect','Plant Density','Form Default','Line Length is outside criterion.','Lines may have different lengths for appropriate reason, use only to double check.','PD_LineLengthIncorrect','LineLengthAmount','=25m');

CREATE VIEW QAQC_PD_LineLengthIncorrect AS
    SELECT b.Reckey AS ErrorKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           b.LineLengthAmount
      FROM joinSitePlotLine AS a
           JOIN
           tblPlantDenHeader AS b ON a.LineKey = b.LineKey
     WHERE b.LineLengthAmount <> 25;
	 
	 
--QAQC_PD_SubQuadSizeUOMIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_PD_SubQuadSizeUOMIncorrect','Plant Density','Form Option','SubQuad Size Units is incorrect for this Species.','1=sq. m; 2=sq.ft','PD_SubQuadSizeUOMIncorrect','SubQuadSizeUOM','=1');

CREATE VIEW QAQC_PD_SubQuadSizeUOMIncorrect AS
    SELECT c.RecKey || ';' || c.Quadrat || ';' || c.SpeciesCode AS ErrorKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           c.SpeciesCode,
           c.SubQuadSize,
           c.SubQuadSizeUOM
      FROM joinSitePlotLine AS a
           JOIN
           tblPlantDenHeader AS b ON a.LineKey = b.LineKey
           JOIN
           tblPlantDenDetail AS c ON b.RecKey = c.RecKey
     WHERE c.SubQuadSizeUOM <> 1;
	 
	 
--QAQC_PD_MissingData
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_PD_MissingData','Plant Density','Missing Data','Plant density not done at this location.',NULL,'PD_MissingData',NULL,'=FALSE');

CREATE VIEW QAQC_PD_MissingData AS
    SELECT a.LineKey AS ErrorKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.RecKey
      FROM joinSitePlotLine AS a
           LEFT JOIN
           tblPlantDenHeader AS b ON a.LineKey = b.LineKey
     WHERE b.RecKey IS NULL;
	 
	 
--QAQC_PD_MissingObserver
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_PD_MissingObserver','Plant Density','Missing Data','Missing Observer.',NULL,'PD_MissingObserver','Observer',NULL);

CREATE VIEW QAQC_PD_MissingObserver AS
    SELECT b.Reckey AS ErrorKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           b.Observer
      FROM joinSitePlotLine AS a
           JOIN
           tblPlantDenHeader AS b ON a.LineKey = b.LineKey
     WHERE b.Observer IS NULL OR 
           b.Observer = '';
		   
		   
--QAQC_PD_MissingRecorder
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_PD_MissingRecorder','Plant Density','Missing Data','Missing Recorder.',NULL,'PD_MissingRecorder','Recorder',NULL);

CREATE VIEW QAQC_PD_MissingRecorder AS
    SELECT b.Reckey AS ErrorKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           b.Recorder
      FROM joinSitePlotLine AS a
           JOIN
           tblPlantDenHeader AS b ON a.LineKey = b.LineKey
     WHERE b.Recorder IS NULL OR 
           b.Recorder = '';
		   
		   
--QAQC_PD_DataEntryNoErrorCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_PD_DataEntryNoErrorCheck','Plant Density','Missing Data','There was data entry from other source (because DataEntry not NULL) and there is no Error Checker listed.',NULL,'PD_DataEntryNoErrorCheck','DataErrorChecking',NULL);

CREATE VIEW QAQC_PD_DataEntryNoErrorCheck AS
    SELECT b.Reckey AS ErrorKey,
           a.SiteID,
           a.PlotID,
           a.LineID,
           b.FormDate,
           b.DataEntry,
           b.DataErrorChecking
      FROM joinSitePlotLine AS a
           JOIN
           tblPlantDenHeader AS b ON a.LineKey = b.LineKey
     WHERE (b.DataEntry IS NOT NULL AND 
            b.DataEntry <> '') AND 
           (b.DataErrorChecking IS NULL OR 
            b.DataErrorChecking = '');
			
			
--QAQC_PD_SpeciesNoGrowthHabitDuration
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(5.0,'QAQC_PD_SpeciesNoGrowthHabitDuration','Plant Density','Missing Data','A species was used in this line''s data that does not have a growth habit or does not have a duration assigned to it in the state species list.',NULL,'PD_SpeciesNoGrowthHabitDuration','SpeciesCode',NULL);

CREATE VIEW QAQC_PD_SpeciesNoGrowthHabitDuration AS
    SELECT x.RecKey || ';' || x.SpeciesCode AS ErrorKey,
           x.SiteID,
           x.PlotID,
           x.LineID,
           x.FormDate,
           x.SpeciesCode,
           y.Duration,
           z.GrowthHabitSub,
           x.SumOfClass1total + x.SumOfClass2total + x.SumOfClass3total + x.SumOfClass4total + x.SumOfClass5total + x.SumOfClass6total + x.SumOfClass7total + x.SumOfClass8total + x.SumOfClass9total AS AllClassSum
      FROM (
               SELECT a.SiteKey,
                      a.SiteID,
                      a.SiteName,
                      a.PlotKey,
                      a.PlotID,
                      a.LineKey,
                      a.LineID,
                      b.FormDate,
                      c.RecKey,
                      c.SpeciesCode,
                      Sum(c.Class1total) AS SumOfClass1total,
                      Sum(c.Class2total) AS SumOfClass2total,
                      Sum(c.Class3total) AS SumOfClass3total,
                      Sum(c.Class4total) AS SumOfClass4total,
                      Sum(c.Class5total) AS SumOfClass5total,
                      Sum(c.Class6total) AS SumOfClass6total,
                      Sum(c.Class7total) AS SumOfClass7total,
                      Sum(c.Class8total) AS SumOfClass8total,
                      Sum(c.Class9total) AS SumOfClass9total
                 FROM joinSitePlotLine AS a
                      JOIN
                      tblPlantDenHeader AS b ON a.LineKey = b.LineKey
                      JOIN
                      tblPlantDenDetail AS c ON c.RecKey = b.RecKey
                GROUP BY c.RecKey,
                         c.SpeciesCode
           )
           AS x
           JOIN
           tblSpecies AS y ON x.SpeciesCode = y.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS z ON y.GrowthHabitCode = z.Code
     WHERE y.Duration IS NULL OR 
           y.Duration = '' OR 
           z.GrowthHabitSub IS NULL;
		   
		   
--QAQC_PD_SpeciesNotInSpeciesList
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(6.0,'QAQC_PD_SpeciesNotInSpeciesList','Plant Density','Missing Data','A species was used in this line''s data that is not in the state species list.',NULL,'PD_SpeciesNotInSpeciesList','SpeciesCode',NULL);

CREATE VIEW QAQC_PD_SpeciesNotInSpeciesList AS
    SELECT x.RecKey || ';' || x.SpeciesCode AS ErrorKey,
           x.SiteID,
           x.PlotID,
           x.LineID,
           x.FormDate,
           x.SpeciesCode,
           y.Duration,
           x.SumOfClass1total + x.SumOfClass2total + x.SumOfClass3total + x.SumOfClass4total + x.SumOfClass5total + x.SumOfClass6total + x.SumOfClass7total + x.SumOfClass8total + x.SumOfClass9total AS AllClassSum
      FROM (
               SELECT a.SiteKey,
                      a.SiteID,
                      a.SiteName,
                      a.PlotKey,
                      a.PlotID,
                      a.LineKey,
                      a.LineID,
                      b.FormDate,
                      c.RecKey,
                      c.SpeciesCode,
                      Sum(c.Class1total) AS SumOfClass1total,
                      Sum(c.Class2total) AS SumOfClass2total,
                      Sum(c.Class3total) AS SumOfClass3total,
                      Sum(c.Class4total) AS SumOfClass4total,
                      Sum(c.Class5total) AS SumOfClass5total,
                      Sum(c.Class6total) AS SumOfClass6total,
                      Sum(c.Class7total) AS SumOfClass7total,
                      Sum(c.Class8total) AS SumOfClass8total,
                      Sum(c.Class9total) AS SumOfClass9total
                 FROM joinSitePlotLine AS a
                      JOIN
                      tblPlantDenHeader AS b ON a.LineKey = b.LineKey
                      JOIN
                      tblPlantDenDetail AS c ON c.RecKey = b.RecKey
                GROUP BY c.RecKey,
                         c.SpeciesCode
           )
           AS x
           LEFT JOIN
           tblSpecies AS y ON x.SpeciesCode = y.SpeciesCode
     WHERE y.SpeciesCode IS NULL;

--QAQC_PD_Detail_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_PD_Detail_OrphanRecordCheck','Plant Density','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'PD_Detail_OrphanRecordCheck',NULL,NULL);
	 
CREATE VIEW QAQC_PD_Detail_OrphanRecordCheck AS
    SELECT a.RecKey || ';' || a.Quadrat || ';' || a.SpeciesCode AS ErrorKey,
           b.RecKey AS tblPlantDenHeader_RecKey,
           a.RecKey AS tblPlantDenDetail_RecKey
      FROM tblPlantDenDetail AS a
           LEFT JOIN
           tblPlantDenHeader AS b ON a.RecKey = b.RecKey
     WHERE b.RecKey IS NULL;
	 
	 
--QAQC_PD_Header_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_PD_Header_OrphanRecordCheck','Plant Density','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'PD_Header_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_PD_Header_OrphanRecordCheck AS
    SELECT a.RecKey AS ErrorKey,
           b.LineKey AS tblLines_LineKey,
           a.LineKey AS tblPlantDenHeader_LineKey,
           a.RecKey
      FROM tblPlantDenHeader AS a
           LEFT JOIN
           tblLines AS b ON a.LineKey = b.LineKey
     WHERE b.LineKey IS NULL;
	 
	 
--QAQC_PP_Header_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_PP_Header_OrphanRecordCheck','Plant Production','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'PP_Header_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_PP_Header_OrphanRecordCheck AS
    SELECT a.RecKey AS ErrorKey,
           b.LineKey AS tblLines_LineKey,
           a.LineKey AS tblPlantDenHeader_LineKey,
           a.RecKey
      FROM tblPlantDenHeader AS a
           LEFT JOIN
           tblLines AS b ON a.LineKey = b.LineKey
     WHERE b.LineKey IS NULL;
	 
	 
--QAQC_PP_Detail_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_PP_Detail_OrphanRecordCheck','Plant Production','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'PP_Detail_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_PP_Detail_OrphanRecordCheck AS
    SELECT a.DetailKey AS ErrorKey,
           b.RecKey AS tblPlantProdHeader_RecKey,
           a.RecKey AS tblPlantProdDetail_RecKey,
           a.DetailKey,
           a.SpeciesCode
      FROM tblPlantProdDetail AS a
           LEFT JOIN
           tblPlantProdHeader AS b ON a.RecKey = b.RecKey
     WHERE b.RecKey IS NULL;
	 
	 
--QAQC_Plot_AvgPrecipUOMIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_Plot_AvgPrecipUOMIncorrect','Plot Definition','Form Option','Avg. Precip units incorrect.',NULL,'Plot_AvgPrecipUOMIncorrect','AvgPrecipUOM','=mm');

CREATE VIEW QAQC_Plot_AvgPrecipUOMIncorrect AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EstablishDate,
           b.AvgPrecip,
           b.AvgPrecipUOM
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE b.AvgPrecipUOM <> 'mm' AND 
           a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY a.SiteID,
              b.PlotID;
			  
			  
--QAQC_Plot_ElevationTypeIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_Plot_ElevationTypeIncorrect','Plot Definition','Form Option','Elevation units incorrect.','1="m" 2="ft"','Plot_ElevationTypeIncorrect','ElevationType','=1');

CREATE VIEW QAQC_Plot_ElevationTypeIncorrect AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EstablishDate,
           b.Elevation,
           b.ElevationType
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE b.ElevationType <> 1 AND 
           a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY a.SiteID,
              b.PlotID;
			  
			  
--QAQC_Plot_MissingState
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_Plot_MissingState','Plot Definition','Missing Data','State missing.',NULL,'Plot_MissingState','State',NULL);

CREATE VIEW QAQC_Plot_MissingState AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EstablishDate,
           b.State
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE (b.State IS NULL OR 
            b.State = '') AND 
           a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY a.SiteID,
              b.PlotID;
			  
			  
--QAQC_Plot_MissingCounty
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_Plot_MissingCounty','Plot Definition','Missing Data','County missing.',NULL,'Plot_MissingCounty','County',NULL);

CREATE VIEW QAQC_Plot_MissingCounty AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EstablishDate,
           b.County
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE (b.County IS NULL OR 
            b.County = '') AND 
           a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY a.SiteID,
              b.PlotID;
			  
			  
--QAQC_Plot_MissingDirections
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_Plot_MissingDirections','Plot Definition','Missing Data','Directions to Plot missing.',NULL,'Plot_MissingDirections','Directions',NULL);

CREATE VIEW QAQC_Plot_MissingDirections AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EstablishDate,
           b.Directions
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE (b.Directions IS NULL OR 
            b.Directions = '') AND 
           a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY a.SiteID,
              b.PlotID;
			  
			  
--QAQC_Plot_MissingAvgPrecip
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_Plot_MissingAvgPrecip','Plot Definition','Missing Data','Avg. Precip missing.',NULL,'Plot_MissingAvgPrecip','AvgPrecip',NULL);

CREATE VIEW QAQC_Plot_MissingAvgPrecip AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EstablishDate,
           b.AvgPrecip,
           b.AvgPrecipUOM
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE (b.AvgPrecip IS NULL OR 
            b.AvgPrecip = '' OR 
            b.AvgPrecip <= 0 OR 
            b.AvgPrecipUOM = 'in') AND 
           a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY a.SiteID,
              b.PlotID;
			  
			  
--QAQC_Plot_MissingSoil
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(5.0,'QAQC_Plot_MissingSoil','Plot Definition','Missing Data','Map Unit Symbol missing.',NULL,'Plot_MissingSoil','Soil',NULL);

CREATE VIEW QAQC_Plot_MissingSoil AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EstablishDate,
           b.Soil
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE (b.Soil IS NULL OR 
            b.Soil = '') AND 
           a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY a.SiteID,
              b.PlotID;
			  
			  
--QAQC_Plot_MissingSoilSeries
/*In order for this view to work properly, you need to populate the SoilSeries table with a list of valid soils.*/
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(6.0,'QAQC_Plot_MissingSoilSeries','Plot Definition','Missing Data','Soil Series missing.',NULL,'Plot_MissingSoilSeries','ESD_Series',NULL);

CREATE VIEW QAQC_Plot_MissingSoilSeries AS
    SELECT x.ErrorKey,
           x.SiteID,
           x.Sitename,
           x.PlotID,
           x.EstablishDate,
           x.ESD_Series
      FROM (
               SELECT b.PlotKey AS ErrorKey,
                      a.SiteID,
                      a.SiteName,
                      b.PlotID,
                      b.EstablishDate,
                      b.ESD_Series,
                      Lower(b.ESD_Series) AS SeriesNameLower
                 FROM tblSites AS a
                      JOIN
                      tblPlots AS b ON a.SiteKey = b.SiteKey
                WHERE a.SiteKey NOT IN ('888888888', '999999999') 
           )
           AS x
           LEFT JOIN
           (
               SELECT SeriesName,
                      [Replace](SeriesName, '_', ' ') AS NameLower
                 FROM SoilSeries
           )
           AS c ON x.SeriesNameLower = c.NameLower
     WHERE (x.ESD_Series IS NULL OR 
            x.ESD_Series = '' OR 
            c.NameLower IS NULL) 
     ORDER BY x.SiteID,
              x.PlotID;
			  
			  
--QAQC_Plot_MissingParentMaterial
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(7.0,'QAQC_Plot_MissingParentMaterial','Plot Definition','Missing Data','Parent Material missing.',NULL,'Plot_MissingParentMaterial','ParentMaterial',NULL);

CREATE VIEW QAQC_Plot_MissingParentMaterial AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EstablishDate,
           b.ParentMaterial
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE (b.ParentMaterial IS NULL OR 
            b.ParentMaterial = '') AND 
           a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY a.SiteID,
              b.PlotID;
			  
			  
--QAQC_Plot_SlopeExactlyZero
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(8.0,'QAQC_Plot_SlopeExactlyZero','Plot Definition','Missing Data','Slope missing.','There may be rare cases where slope is excatly 0.0%.  Use to double check.','Plot_SlopeMissingOrExactlyZero','Slope',NULL);

CREATE VIEW QAQC_Plot_SlopeExactlyZero AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EstablishDate,
           b.Slope
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE (b.Slope IS NULL OR 
            b.Slope = '' OR 
            b.Slope = 0) AND 
           a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY a.SiteID,
              b.PlotID;
			  
			  
--QAQC_Plot_AspectMissingORNotNumericORInvalid
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(9.0,'QAQC_Plot_AspectMissingORNotNumericORInvalid','Plot Definition','Missing Data','The plot Aspect is either missing or a non-numeric value.',NULL,'Plot_AspectInvalid','Aspect','=0-359 or =-1 (for no aspect)');

CREATE VIEW QAQC_Plot_AspectMissingORNotNumericORInvalid AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EstablishDate,
           b.Aspect
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE (b.Aspect IS NULL OR 
            b.Aspect = '' OR 
            CAST (b.Aspect AS INTEGER) > 360 OR 
            CAST (b.Aspect AS INTEGER) < -1 OR 
            b.Aspect != '0' AND 
            CAST (b.Aspect AS INTEGER) = 0) AND 
           a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY a.SiteID,
              b.PlotID;
			  
			  
--QAQC_Plot_MissingSlopeShape
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(10.0,'QAQC_Plot_MissingSlopeShape','Plot Definition','Missing Data','Slope Shape missing.',NULL,'Plot_MissingSlopeShape','ESD_SlopeShape',NULL);

CREATE VIEW QAQC_Plot_MissingSlopeShape AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EstablishDate,
           b.ESD_SlopeShape
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE (b.ESD_SlopeShape IS NULL OR 
            b.ESD_SlopeShape = '') AND 
           a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY a.SiteID,
              b.PlotID;
			  
			  
--QAQC_Plot_MissingLandscapeType
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(11.0,'QAQC_Plot_MissingLandscapeType','Plot Definition','Missing Data','Landscape Unit missing.',NULL,'Plot_MissingLandscapeType','LandscapeType',NULL);

CREATE VIEW QAQC_Plot_MissingLandscapeType AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EstablishDate,
           b.ESD_SlopeShape
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE (b.ESD_SlopeShape IS NULL OR 
            b.ESD_SlopeShape = '') AND 
           a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY a.SiteID,
              b.PlotID;
			  
			  
--QAQC_Plot_MissingRecentWeather
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(12.0,'QAQC_Plot_MissingRecentWeather','Plot Definition','Missing Data','Recent Weather (past or previoud 12 months) missing in Disturbances/Mgt History tab.',NULL,'Plot_MissingWeather','RecentWeatherPast12 AND RecentWeatherPrevious12',NULL);

CREATE VIEW QAQC_Plot_MissingRecentWeather AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.EstablishDate,
           b.RecentWeatherPast12,
           b.RecentWeatherPrevious12
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
     WHERE (b.RecentWeatherPast12 IS NULL OR 
            b.RecentWeatherPast12 = '' OR 
            b.RecentWeatherPrevious12 IS NULL OR 
            b.RecentWeatherPrevious12 = '') AND 
           a.SiteKey NOT IN ('888888888', '999999999') 
     ORDER BY a.SiteID,
              b.PlotID;
			  
			  
--QAQC_Plot_MissingEcoStateCommnunity
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(14.0,'QAQC_Plot_MissingEcoStateCommnunity','Plot Definition','Missing Data','State, Community, or  Phase (community description) missing from plot.','Use NA for ecoistes with no State or Community information or diagram.','Plot_MissingEcoStateCom',NULL,'TRUE');

CREATE VIEW QAQC_Plot_MissingEcoStateCommnunity AS
    SELECT a.PlotKey AS ErrorKey,
           c.SiteID,
           c.SiteName,
           a.PlotKey,
           a.PlotID,
           b.RecType,
           b.ESD_StateWithinEcologicalSite,
           b.ESD_CommunityWithinState,
           b.ESD_CommunityDescription
      FROM tblPlots AS a
           LEFT JOIN
           tblPlotHistory AS b ON a.PlotKey = b.PlotKey
           LEFT JOIN
           tblSites AS c ON a.SiteKey = c.SiteKey
     WHERE c.SiteKey NOT IN ('888888888', '999999999') AND 
           b.RecType = 'E' AND 
           (b.ESD_StateWithinEcologicalSite IS NULL OR 
            b.ESD_StateWithinEcologicalSite = '' OR 
            b.ESD_CommunityWithinState IS NULL OR 
            b.ESD_CommunityWithinState = '' OR 
            b.ESD_CommunityDescription IS NULL OR 
            b.ESD_CommunityDescription = '');
			
			
--QAQC_PlotHistory_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_PlotHistory_OrphanRecordCheck','Plot Definition','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'PlotHistory_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_PlotHistory_OrphanRecordCheck AS
    SELECT a.RecKey AS ErrorKey,
           b.PlotKey AS tblPlots_PlotKey,
           a.PlotKey AS tblPlotHistory_PlotKey,
           a.RecType
      FROM tblPlotHistory AS a
           LEFT JOIN
           tblPlots AS b ON a.Plotkey = b.PlotKey
     WHERE b.PlotKey IS NULL;
	 
	 
--QAQC_PlotTags_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_PlotTags_OrphanRecordCheck','Plot Definition','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'PlotTags_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_PlotTags_OrphanRecordCheck AS
    SELECT a.PlotKey AS ErrorKey,
           b.PlotKey AS tblPlots_PlotKey,
           a.PlotKey AS tblPlotTags_PlotKey,
           a.Tag
      FROM tblPlotTags AS a
           LEFT JOIN
           tblPlots AS b ON a.Plotkey = b.PlotKey
     WHERE b.PlotKey IS NULL;
	 
	 
--QAQC_Plot_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_Plot_OrphanRecordCheck','Plot Definition','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'Plot_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_Plot_OrphanRecordCheck AS
    SELECT a.PlotKey AS ErrorKey,
           b.SiteKey AS tblSites_SiteKey,
           a.SiteKey AS tblPlots_SiteKey,
           a.PlotID
      FROM tblPlots AS a
           LEFT JOIN
           tblSites AS b ON a.Sitekey = b.SiteKey
     WHERE b.SiteKey IS NULL;
	 
	 
--QAQC_PlotNotes_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_PlotNotes_OrphanRecordCheck','Plot Definition','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'PlotNotes_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_PlotNotes_OrphanRecordCheck AS
    SELECT a.CommentID AS ErrorKey,
           b.PlotKey AS tblPlots_PlotKey,
           a.PlotKey AS tblPlotNotes_PlotKey,
           a.NoteDate,
           a.Note
      FROM tblPlotNotes AS a
           LEFT JOIN
           tblPlots AS b ON a.Plotkey = b.PlotKey
     WHERE b.PlotKey IS NULL;
	 
	 
--QAQC_Plot_ZoneIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_Plot_ZoneIncorrect','Plot Definition','Form Option','Incorrect value for Zone.',NULL,'Plot_DD_ZoneNotBlank','Zone','=NULL (blank)');

CREATE VIEW QAQC_Plot_ZoneIncorrect AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.Zone
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.Sitekey = b.SiteKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (b.Zone IS NOT NULL AND 
            b.Zone != '');
			
			
--QAQC_Plot_GPSCoordSysIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_Plot_GPSCoordSysIncorrect','Plot Definition','Form Option','GPS Coordinate System incorrect.','Project should have standard coordinate system. Use to double check. (UTM or Decimal Degrees)','Plot_GPSCoordSysIncorrect','GPSCoordSys','=Decimal Degrees');

CREATE VIEW QAQC_Plot_GPSCoordSysIncorrect AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.GPSCoordSys
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.Sitekey = b.SiteKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (b.GPSCoordSys != 'Decimal Degrees' OR 
            b.GPSCoordSys IS NULL);
			
			
--QAQC_Plot_DatumIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_Plot_DatumIncorrect','Plot Definition','Form Option','Datum incorrect.',NULL,'Plot_DD_DatumIncorrect','Datum','NAD83');

CREATE VIEW QAQC_Plot_DatumIncorrect AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           b.Datum
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.Sitekey = b.SiteKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (b.Datum != 'NAD83');
		   
		   
--QAQC_SAS_SoilStabSubSurfaceIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_SAS_SoilStabSubSurfaceIncorrect','Soil Aggregate Stability','Form Default','"This Sample Contains:" is incorrect.','1=Surface Only; 2=Surface/SubSurface','SAS_SoilStabSubSurfaceIncorrect','SoilStabSubSurface','=1');

CREATE VIEW QAQC_SAS_SoilStabSubSurfaceIncorrect AS
    SELECT c.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.SoilStabSubSurface
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.Sitekey = b.SiteKey
           JOIN
           tblSoilStabHeader AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           c.SoilStabSubSurface != 1;
		   
		   
--QAQC_SAS_MissingData
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_SAS_MissingData','Soil Aggregate Stability','Missing Data','Soil Aggregate Stability not done at this plot.',NULL,'SAS_MissingData',NULL,'=TRUE');

CREATE VIEW QAQC_SAS_MissingData AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.Sitekey = b.SiteKey
           LEFT JOIN
           tblSoilStabHeader AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           c.PlotKey IS NULL;
		   
		   
--QAQC_SAS_MissingObserver
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_SAS_MissingObserver','Soil Aggregate Stability','Missing Data','Missing Observer.',NULL,'SAS_MissingObserver','Observer',NULL);

CREATE VIEW QAQC_SAS_MissingObserver AS
    SELECT c.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.Observer
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.Sitekey = b.SiteKey
           JOIN
           tblSoilStabHeader AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (c.Observer IS NULL OR 
            c.Observer = '');
			
			
--QAQC_SAS_MissingRecorder
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_SAS_MissingRecorder','Soil Aggregate Stability','Missing Data','Missing Recorder.',NULL,'SAS_MissingRecorder','Recorder',NULL);

CREATE VIEW QAQC_SAS_MissingRecorder AS
    SELECT c.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.Recorder
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.Sitekey = b.SiteKey
           JOIN
           tblSoilStabHeader AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (c.Recorder IS NULL OR 
            c.Recorder = '');
			
			
--QAQC_SAS_DataEntryNoErrorCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_SAS_DataEntryNoErrorCheck','Soil Aggregate Stability','Missing Data','There was data entry from other source (because DataEntry not NULL) and there is no Error Checker listed.',NULL,'SAS_DataEntryNoErrorCheck','DataErrorChecking',NULL);

CREATE VIEW QAQC_SAS_DataEntryNoErrorCheck AS
    SELECT c.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.Recorder,
           c.DataEntry,
           c.DataErrorChecking
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.Sitekey = b.SiteKey
           JOIN
           tblSoilStabHeader AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (c.DataEntry IS NOT NULL AND 
            c.DataEntry != ' ') AND 
           (c.DataErrorChecking IS NULL OR 
            c.DataErrorChecking = '');
			
			
--QAQC_SAS_MissingLineAssignments
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(5.0,'QAQC_SAS_MissingLineAssignments','Soil Aggregate Stability','Missing Data','Line assignments are missing.',NULL,'SAS_MissingLineAssignments','Line[1:6]',NULL);

CREATE VIEW QAQC_SAS_MissingLineAssignments AS
    SELECT d.ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.FormDate,
           d.BoxNum,
           d.LineID,
           d.LineLabel
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.Sitekey = b.SiteKey
           JOIN
           tblSoilStabHeader AS c ON b.PlotKey = c.PlotKey
           JOIN
           (
               SELECT RecKey || ';' || BoxNum || ';Line1' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Line1' AS LineID,
                      Line1 AS LineLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Line2' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Line2' AS LineID,
                      Line2 AS LineLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Line3' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Line3' AS LineID,
                      Line3 AS LineLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Line4' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Line4' AS LineID,
                      Line4 AS LineLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Line5' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Line5' AS LineID,
                      Line5 AS LineLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Line6' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Line6' AS LineID,
                      Line6 AS LineLabel
                 FROM tblSoilStabDetail
           )
           AS d ON c.RecKey = d.RecKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           d.BoxNum = '1' AND 
           (d.LineLabel IS NULL OR 
            d.LineLabel = '');
			
			
--QAQC_SAS_MissingPositionAssignments
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(6.0,'QAQC_SAS_MissingPositionAssignments','Soil Aggregate Stability','Missing Data','Position assignments are missing.',NULL,'SAS_MissingPositionAssignments','Pos[1:18]',NULL);

CREATE VIEW QAQC_SAS_MissingPositionAssignments AS
    SELECT d.ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.FormDate,
           d.BoxNum,
           d.PosID,
           d.PosLabel
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.Sitekey = b.SiteKey
           JOIN
           tblSoilStabHeader AS c ON b.PlotKey = c.PlotKey
           JOIN
           (
               SELECT RecKey || ';' || BoxNum || ';Pos1' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos1' AS PosID,
                      Pos1 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos2' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos2' AS PosID,
                      Pos2 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos3' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos3' AS PosID,
                      Pos3 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos4' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos4' AS PosID,
                      Pos4 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos5' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos5' AS PosID,
                      Pos5 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos6' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos6' AS PosID,
                      Pos6 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos7' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos7' AS PosID,
                      Pos7 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos8' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos8' AS PosID,
                      Pos8 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos9' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos9' AS PosID,
                      Pos9 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos10' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos10' AS PosID,
                      Pos10 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos11' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos11' AS PosID,
                      Pos11 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos12' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos12' AS PosID,
                      Pos12 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos13' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos13' AS PosID,
                      Pos13 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos14' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos14' AS PosID,
                      Pos14 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos15' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos15' AS PosID,
                      Pos15 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos16' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos16' AS PosID,
                      Pos16 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos17' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos17' AS PosID,
                      Pos17 AS PosLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Pos18' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Pos18' AS PosID,
                      Pos18 AS PosLabel
                 FROM tblSoilStabDetail
           )
           AS d ON c.RecKey = d.RecKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           d.BoxNum = '1' AND 
           (d.PosLabel IS NULL OR 
            d.PosLabel = '');
			
			
--QAQC_SAS_MissingVegAssignments
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(7.0,'QAQC_SAS_MissingVegAssignments','Soil Aggregate Stability','Missing Data','Vegetation Assignments are missing.',NULL,'SAS_MissingVegAssignments','Veg[1:18]',NULL);

CREATE VIEW QAQC_SAS_MissingVegAssignments AS
    SELECT d.ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.FormDate,
           d.BoxNum,
           d.VegID,
           d.VegLabel
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.Sitekey = b.SiteKey
           JOIN
           tblSoilStabHeader AS c ON b.PlotKey = c.PlotKey
           JOIN
           (
               SELECT RecKey || ';' || BoxNum || ';Veg1' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg1' AS VegID,
                      Veg1 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg2' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg2' AS VegID,
                      Veg2 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg3' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg3' AS VegID,
                      Veg3 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg4' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg4' AS VegID,
                      Veg4 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg5' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg5' AS VegID,
                      Veg5 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg6' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg6' AS VegID,
                      Veg6 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg7' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg7' AS VegID,
                      Veg7 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg8' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg8' AS VegID,
                      Veg8 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg9' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg9' AS VegID,
                      Veg9 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg10' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg10' AS VegID,
                      Veg10 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg11' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg11' AS VegID,
                      Veg11 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg12' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg12' AS VegID,
                      Veg12 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg13' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg13' AS VegID,
                      Veg13 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg14' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg14' AS VegID,
                      Veg14 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg15' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg15' AS VegID,
                      Veg15 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg16' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg16' AS VegID,
                      Veg16 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg17' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg17' AS VegID,
                      Veg17 AS VegLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Veg18' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Veg18' AS VegID,
                      Veg18 AS VegLabel
                 FROM tblSoilStabDetail
           )
           AS d ON c.RecKey = d.RecKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           d.BoxNum = '1' AND 
           (d.VegLabel IS NULL OR 
            d.VegLabel = '');
			
			
--QAQC_SAS_MissingRatings
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(8.0,'QAQC_SAS_MissingRatings','Soil Aggregate Stability','Missing Data','Ratings are missing.',NULL,'SAS_MissingRatings','Rating[1:18]',NULL);

CREATE VIEW QAQC_SAS_MissingRatings AS
    SELECT d.ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.FormDate,
           d.BoxNum,
           d.RatingID,
           d.RatingLabel
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.Sitekey = b.SiteKey
           JOIN
           tblSoilStabHeader AS c ON b.PlotKey = c.PlotKey
           JOIN
           (
               SELECT RecKey || ';' || BoxNum || ';Rating1' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating1' AS RatingID,
                      Rating1 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating2' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating2' AS RatingID,
                      Rating2 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating3' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating3' AS RatingID,
                      Rating3 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating4' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating4' AS RatingID,
                      Rating4 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating5' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating5' AS RatingID,
                      Rating5 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating6' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating6' AS RatingID,
                      Rating6 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating7' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating7' AS RatingID,
                      Rating7 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating8' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating8' AS RatingID,
                      Rating8 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating9' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating9' AS RatingID,
                      Rating9 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating10' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating10' AS RatingID,
                      Rating10 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating11' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating11' AS RatingID,
                      Rating11 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating12' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating12' AS RatingID,
                      Rating12 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating13' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating13' AS RatingID,
                      Rating13 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating14' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating14' AS RatingID,
                      Rating14 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating15' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating15' AS RatingID,
                      Rating15 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating16' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating16' AS RatingID,
                      Rating16 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating17' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating17' AS RatingID,
                      Rating17 AS RatingLabel
                 FROM tblSoilStabDetail
               UNION
               SELECT RecKey || ';' || BoxNum || ';Rating18' AS ErrorKey,
                      RecKey,
                      BoxNum,
                      'Rating18' AS RatingID,
                      Rating18 AS RatingLabel
                 FROM tblSoilStabDetail
           )
           AS d ON c.RecKey = d.RecKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           d.BoxNum = '1' AND 
           (d.RatingLabel IS NULL OR 
            d.RatingLabel = '');
			
			
--QAQC_SAS_Header_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_SAS_Header_OrphanRecordCheck','Soil Aggregate Stability','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'SAS_Header_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_SAS_Header_OrphanRecordCheck AS
    SELECT a.RecKey AS ErrorKey,
           b.PlotKey AS tblPlots_PlotKey,
           a.PlotKey AS tblSoilStabHeader_PlotKey,
           a.FormDate
      FROM tblSoilStabHeader AS a
           LEFT JOIN
           tblPlots AS b ON a.Plotkey = b.PlotKey
     WHERE b.PlotKey IS NULL;
	 
	 
--QAQC_SAS_Detail_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_SAS_Detail_OrphanRecordCheck','Soil Aggregate Stability','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'SAS_Detail_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_SAS_Detail_OrphanRecordCheck AS
    SELECT a.RecKey || ';' || a.BoxNum AS ErrorKey,
           b.RecKey AS tblSoilStabHeader_RecKey,
           a.RecKey AS tblSoilStabDetail_RecKey,
           a.BoxNum
      FROM tblSoilStabDetail AS a
           LEFT JOIN
           tblSoilStabHeader AS b ON a.RecKey = b.RecKey
     WHERE b.RecKey IS NULL;
	 
	 
--QAQC_SoilPit_MissingData
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_SoilPit_MissingData','Soil Pit','Missing Data','Soil pit information missing from this site.',NULL,'SoilPit_MissingData',NULL,NULL);

CREATE VIEW QAQC_SoilPit_MissingData AS
    SELECT b.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           LEFT JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           c.Plotkey IS NULL;
		   
		   
--QAQC_SoilPit_MissingPitDescription
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_SoilPit_MissingPitDescription','Soil Pit','Missing Data','Missing pit description.','E.g. "Sacrifice Zone" or "Plot Center"','SoilPit_MissingPitDescription','PitDesc',NULL);

CREATE VIEW QAQC_SoilPit_MissingPitDescription AS
    SELECT c.SoilKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.PitDesc
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (c.PitDesc IS NULL OR 
            c.PitDesc = '');
			
			
--QAQC_SoilPit_MissingSoilDepthLower
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_SoilPit_MissingSoilDepthLower','Soil Pit','Missing Data','Total Soil Pedon Depth missing.',NULL,'SoilPit_MissingSoilDepthLower','SoilDepthLower',NULL);

CREATE VIEW QAQC_SoilPit_MissingSoilDepthLower AS
    SELECT c.SoilKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.SoilDepthLower
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (c.SoilDepthLower IS NULL OR 
            c.SoilDepthLower = '');
			
			
--QAQC_SoilPit_MissingObserver
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_SoilPit_MissingObserver','Soil Pit','Missing Data','Missing Observer.',NULL,'SoilPit_MissingObserver','Observer',NULL);

CREATE VIEW QAQC_SoilPit_MissingObserver AS
    SELECT c.SoilKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.Observer
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (c.Observer IS NULL OR 
            c.Observer = '');
			
			
--QAQC_SoilPit_MissingHorizons
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(5.0,'QAQC_SoilPit_MissingHorizons','Soil Pit','Missing Data','There are no horizons for this soil pit.',NULL,'SoilPit_MissingHorizons',NULL,NULL);

CREATE VIEW QAQC_SoilPit_MissingHorizons AS
    SELECT c.SoilKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.DateRecorded,
           d.HorizonKey
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSoilPitHorizons AS d ON c.SoilKey = d.SoilKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.HorizonKey IS NULL);
		   
		   
--QAQC_SoilPit_MissingHorizonDepthUpper
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(6.0,'QAQC_SoilPit_MissingHorizonDepthUpper','Soil Pit','Missing Data','The upper end of horizon measurement is missing.',NULL,'SoilPit_MissingHorizonDepthUpr','HorizonDepthUpper','= number');

CREATE VIEW QAQC_SoilPit_MissingHorizonDepthUpper AS
    SELECT d.HorizonKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.DateRecorded,
           d.HorizonDepthUpper
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSoilPitHorizons AS d ON c.SoilKey = d.SoilKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.HorizonDepthUpper IS NULL OR 
            d.HorizonDepthUpper = '');
			
			
--QAQC_SoilPit_MissingHorizonDepthLower
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(6.0,'QAQC_SoilPit_MissingHorizonDepthLower','Soil Pit','Missing Data','The lower end of horizon measurement is missing.',NULL,'SoilPit_MissingHorizonDepthLwr','HorizonDepthLower','= number or +');

CREATE VIEW QAQC_SoilPit_MissingHorizonDepthLower AS
    SELECT d.HorizonKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.DateRecorded,
           d.HorizonDepthLower
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSoilPitHorizons AS d ON c.SoilKey = d.SoilKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.HorizonDepthLower IS NULL OR 
            d.HorizonDepthLower = '');
			
			
--QAQC_SoilPit_MissingTexture
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(7.0,'QAQC_SoilPit_MissingTexture','Soil Pit','Missing Data','Horizon missing a texture assignment.',NULL,'SoilPit_MissingTexture','Texture',NULL);

CREATE VIEW QAQC_SoilPit_MissingTexture AS
    SELECT d.HorizonKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.DateRecorded,
           d.Texture
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSoilPitHorizons AS d ON c.SoilKey = d.SoilKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.Texture IS NULL OR 
            d.Texture = '');
			
			
--QAQC_SoilPit_RockFragmentsZero
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(8.0,'QAQC_SoilPit_RockFragmentsZero','Soil Pit','Missing Data','Rock fragments missing.','In some rare cases rock fragments can be exactly zero.  Use to double check.','SoilPit_RockFragmentsZero','RockFragments',NULL);

CREATE VIEW QAQC_SoilPit_RockFragmentsZero AS
    SELECT d.HorizonKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.DateRecorded,
		   d.HorizonDepthUpper,
		   d.HorizonDepthLower,
		   d.ESD_Horizon,
           d.RockFragments
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSoilPitHorizons AS d ON c.SoilKey = d.SoilKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.RockFragments IS NULL OR 
            d.RockFragments = '' OR 
            d.RockFragments = 0) AND
           (d.ESD_Horizon IS NULL OR
           d.ESD_Horizon <> 'R');
			
			
--QAQC_SoilPit_Header_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_SoilPit_Header_OrphanRecordCheck','Soil Pit','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'SoilPit_Header_OrphanRecCheck',NULL,NULL);

CREATE VIEW QAQC_SoilPit_Header_OrphanRecordCheck AS
    SELECT a.SoilKey AS ErrorKey,
           b.PlotKey AS tblPlots_PlotKey,
           a.PlotKey AS tblSoilPits_PlotKey,
           a.DateRecorded
      FROM tblSoilPits AS a
           LEFT JOIN
           tblPlots AS b ON a.Plotkey = b.PlotKey
     WHERE b.PlotKey IS NULL;
	 
	 
--QAQC_SoilPit_Detail_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_SoilPit_Detail_OrphanRecordCheck','Soil Pit','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'SoilPit_Detail_OrphanRecCheck',NULL,NULL);

CREATE VIEW QAQC_SoilPit_Detail_OrphanRecordCheck AS
    SELECT a.HorizonKey AS ErrorKey,
           b.SoilKey AS tblSoilPits_SoilKey,
           a.SoilKey AS tblSoilPitHorizons_SoilKey
      FROM tblSoilPitHorizons AS a
           LEFT JOIN
           tblSoilPits AS b ON a.SoilKey = b.SoilKey
     WHERE b.SoilKey IS NULL;
	 
	 
--QAQC_SR_SubPlotIDIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_SR_SubPlotIDIncorrect','Species Richness','Data Criterion Failure','A species was not assigned to the correct Sub-Plot if there is only one subplot.',NULL,'SR_SubPlotIDIncorrect','subPlotID','=1');

CREATE VIEW QAQC_SR_SubPlotIDIncorrect AS
    SELECT e.RecKey || ';' || e.subPlotID AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           d.FormDate,
           e.SubPlotID
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSpecRichHeader AS d ON c.LineKey = d.LineKey
           JOIN
           tblSpecRichDetail AS e ON d.RecKey = e.RecKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (e.SubPlotID IS NULL OR 
            e.SubPlotID != 1);
			
			
--QAQC_SR_SpeciesByPlot_NoGrowthHabitDuration
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_SR_SpeciesByPlot_NoGrowthHabitDuration','Species Richness','Data Criterion Failure','A species is present in this plot''s species richness that has either no growth habit or no duration assigned in the state species list.',NULL,'SR_NoGrowthHabitDuration','GrowthHabitSub OR Duration',NULL);

CREATE VIEW QAQC_SR_SpeciesByPlot_NoGrowthHabitDuration AS
    SELECT e.RecKey || ';' || e.subPlotID || ';' || e.SpeciesCode AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           d.FormDate,
           e.SpeciesCode,
           f.Duration,
           g.GrowthHabitSub
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSpecRichHeader AS d ON c.LineKey = d.LineKey
           JOIN
           SR_Raw AS e ON d.RecKey = e.RecKey
           JOIN
           tblSpecies AS f ON e.SpeciesCode = f.SpeciesCode
           LEFT JOIN
           tblSpeciesGrowthHabit AS g ON f.GrowthHabitCode = g.Code
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           f.Duration = '' OR 
           f.Duration IS NULL OR 
           g.GrowthHabitSub IS NULL;


--QAQC_SR_GeneralCodesUsed
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_SR_GeneralCodesUsed','Species Richness','Data Criterion Failure','There is a generalized code in the Species Richness','Examples include "PPSH" or "AAFF".','SR_GeneralCodesUsed',NULL,'=TRUE');

CREATE VIEW QAQC_SR_GeneralCodesUsed AS
    SELECT e.RecKey || ';' || e.subPlotID || ';' || e.SpeciesCode AS ErrorKey,
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
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           e.SpeciesCode IN ('AF00', 'PF00', 'AG00', 'PG00', 'SH00', 'TR00', 'SU00', 'AF000', 'PF000', 'AG000', 'PG000', 'SH000', 'TR000', 'SU000');

		   
--QAQC_SR_EmptyValue
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_SR_EmptyValue','Species Richness','Data Criterion Failure','There is an empty or null value in the species richness list.',NULL,'SR_EmptyValue','Species',NULL);
		   
CREATE VIEW QAQC_SR_EmptyValue AS
    SELECT e.RecKey || ';' || e.subPlotID AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           d.FormDate,
           e.SpeciesList
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSpecRichHeader AS d ON c.LineKey = d.LineKey
           JOIN
           tblSpecRichDetail AS e ON d.RecKey = e.RecKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (e.SpeciesList IS NULL OR 
            e.SpeciesList = '');

			
--QAQC_SR_MeasureIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_SR_MeasureIncorrect','Species Richness','Form Default','"Sub-Plot Sizes are:" is incorrect.','1=Metric; 2=English','SR_MeasureIncorrect','SpecRichMeasure','=1');
	
CREATE VIEW QAQC_SR_MeasureIncorrect AS
    SELECT d.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           d.FormDate,
           d.SpecRichMeasure
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSpecRichHeader AS d ON c.LineKey = d.LineKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.SpecRichMeasure IS NULL OR 
            d.SpecRichMeasure != 1);
			
			
--QAQC_SR_SpecRichMethodIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_SR_SpecRichMethodIncorrect','Species Richness','Form Default','"Method" choice incorrect.','1=Monitoring Manual; 2=Custom 1; 3=Custom 2','SR_SpecRichMethodIncorrect','SpecRichMethod','=3');

CREATE VIEW QAQC_SR_SpecRichMethodIncorrect AS
    SELECT d.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           d.FormDate,
           d.SpecRichMethod
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSpecRichHeader AS d ON c.LineKey = d.LineKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.SpecRichMethod IS NULL OR 
            d.SpecRichMethod != 4);
			
			
--QAQC_SR_NumberSubPlotsIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_SR_NumberSubPlotsIncorrect','Species Richness','Form Default','"# of Sub-Plots:" incorrect.',NULL,'SR_NumberSubPlotsIncorrect','SpecRichNbrSubPlots','=1');

CREATE VIEW QAQC_SR_NumberSubPlotsIncorrect AS
    SELECT d.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           d.FormDate,
           d.SpecRichNbrSubPlots
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSpecRichHeader AS d ON c.LineKey = d.LineKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.SpecRichNbrSubPlots IS NULL OR 
            d.SpecRichNbrSubPlots != 1);
			
			
--QAQC_SR_SpecRichContainerIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_SR_SpecRichContainerIncorrect','Species Richness','Form Default','Container Sub-Plot incorrect marked incorrectly',NULL,'SR_SpecRichContainerIncorrect','SpecRich#Container','1=1, 2=0, 3=0, 4=0, 5=0, 6=0');

CREATE VIEW QAQC_SR_SpecRichContainerIncorrect AS
    SELECT d.RecKey || ';' || d.SubPlot AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PLotID,
           c.LineID,
           d.FormDate,
           d.SubPlot,
           d.SpecRichContainer
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           (
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '1' AS SubPlot,
                      SpecRich1Container AS SpecRichContainer,
                      SpecRich1Shape AS SpecRichShape,
                      SpecRich1Dim1 AS SpecRichDim1,
                      SpecRich1Dim2 AS SpecRichDim2,
                      SpecRich1Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '2' AS SubPlot,
                      SpecRich2Container AS SpecRichContainer,
                      SpecRich2Shape AS SpecRichShape,
                      SpecRich2Dim1 AS SpecRichDim1,
                      SpecRich2Dim2 AS SpecRichDim2,
                      SpecRich2Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '3' AS SubPlot,
                      SpecRich3Container AS SpecRichContainer,
                      SpecRich3Shape AS SpecRichShape,
                      SpecRich3Dim1 AS SpecRichDim1,
                      SpecRich3Dim2 AS SpecRichDim2,
                      SpecRich3Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '4' AS SubPlot,
                      SpecRich4Container AS SpecRichContainer,
                      SpecRich4Shape AS SpecRichShape,
                      SpecRich4Dim1 AS SpecRichDim1,
                      SpecRich4Dim2 AS SpecRichDim2,
                      SpecRich4Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '5' AS SubPlot,
                      SpecRich5Container AS SpecRichContainer,
                      SpecRich5Shape AS SpecRichShape,
                      SpecRich5Dim1 AS SpecRichDim1,
                      SpecRich5Dim2 AS SpecRichDim2,
                      SpecRich5Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '6' AS SubPlot,
                      SpecRich6Container AS SpecRichContainer,
                      SpecRich6Shape AS SpecRichShape,
                      SpecRich6Dim1 AS SpecRichDim1,
                      SpecRich6Dim2 AS SpecRichDim2,
                      SpecRich6Area AS SpecRichArea
                 FROM tblSpecRichHeader
           )
           AS d ON c.LineKey = d.LineKey
     WHERE (d.SubPlot = '1' AND 
            (d.SpecRichContainer IS NULL OR 
             d.SpecRichContainer != 1) ) OR 
           (d.SubPlot = '2' AND 
            (d.SpecRichContainer IS NULL OR 
             d.SpecRichContainer != 0) ) OR 
           (d.SubPlot = '3' AND 
            (d.SpecRichContainer IS NULL OR 
             d.SpecRichContainer != 0) ) OR 
           (d.SubPlot = '4' AND 
            (d.SpecRichContainer IS NULL OR 
             d.SpecRichContainer != 0) ) OR 
           (d.SubPlot = '5' AND 
            (d.SpecRichContainer IS NULL OR 
             d.SpecRichContainer != 0) ) OR 
           (d.SubPlot = '6' AND 
            (d.SpecRichContainer IS NULL OR 
             d.SpecRichContainer != 0) ) 
     ORDER BY a.SiteID,
              b.PlotID,
              c.LineID,
              d.FormDate,
              d.SubPlot;
			  
			  
--QAQC_SR_SpecRichShapeIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(5.0,'QAQC_SR_SpecRichShapeIncorrect','Species Richness','Form Default','Shape of Sub-Plot incorrect.','1=Square; 2=Circle','SR_SpecRich1ShapeIncorrect','SpecRich#Shape','1=2, 2=1, 3=1, 4=1, 5=1, 6=1');

CREATE VIEW QAQC_SR_SpecRichShapeIncorrect AS
    SELECT d.RecKey || ';' || d.SubPlot AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PLotID,
           c.LineID,
           d.FormDate,
           d.SubPlot,
           d.SpecRichShape
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           (
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '1' AS SubPlot,
                      SpecRich1Container AS SpecRichContainer,
                      SpecRich1Shape AS SpecRichShape,
                      SpecRich1Dim1 AS SpecRichDim1,
                      SpecRich1Dim2 AS SpecRichDim2,
                      SpecRich1Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '2' AS SubPlot,
                      SpecRich2Container AS SpecRichContainer,
                      SpecRich2Shape AS SpecRichShape,
                      SpecRich2Dim1 AS SpecRichDim1,
                      SpecRich2Dim2 AS SpecRichDim2,
                      SpecRich2Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '3' AS SubPlot,
                      SpecRich3Container AS SpecRichContainer,
                      SpecRich3Shape AS SpecRichShape,
                      SpecRich3Dim1 AS SpecRichDim1,
                      SpecRich3Dim2 AS SpecRichDim2,
                      SpecRich3Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '4' AS SubPlot,
                      SpecRich4Container AS SpecRichContainer,
                      SpecRich4Shape AS SpecRichShape,
                      SpecRich4Dim1 AS SpecRichDim1,
                      SpecRich4Dim2 AS SpecRichDim2,
                      SpecRich4Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '5' AS SubPlot,
                      SpecRich5Container AS SpecRichContainer,
                      SpecRich5Shape AS SpecRichShape,
                      SpecRich5Dim1 AS SpecRichDim1,
                      SpecRich5Dim2 AS SpecRichDim2,
                      SpecRich5Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '6' AS SubPlot,
                      SpecRich6Container AS SpecRichContainer,
                      SpecRich6Shape AS SpecRichShape,
                      SpecRich6Dim1 AS SpecRichDim1,
                      SpecRich6Dim2 AS SpecRichDim2,
                      SpecRich6Area AS SpecRichArea
                 FROM tblSpecRichHeader
           )
           AS d ON c.LineKey = d.LineKey
     WHERE (d.SubPlot = '1' AND 
            (d.SpecRichShape IS NULL OR 
             d.SpecRichShape != 2) ) OR 
           (d.SubPlot = '2' AND 
            (d.SpecRichShape IS NULL OR 
             d.SpecRichShape != 1) ) OR 
           (d.SubPlot = '3' AND 
            (d.SpecRichShape IS NULL OR 
             d.SpecRichShape != 1) ) OR 
           (d.SubPlot = '4' AND 
            (d.SpecRichShape IS NULL OR 
             d.SpecRichShape != 1) ) OR 
           (d.SubPlot = '5' AND 
            (d.SpecRichShape IS NULL OR 
             d.SpecRichShape != 1) ) OR 
           (d.SubPlot = '6' AND 
            (d.SpecRichShape IS NULL OR 
             d.SpecRichShape != 1) ) 
     ORDER BY a.SiteID,
              b.PlotID,
              c.LineID,
              d.FormDate,
              d.SubPlot;
			  
			  
--QAQC_SR_SpecRichDim1Incorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(6.0,'QAQC_SR_SpecRichDim1Incorrect','Species Richness','Form Default','"Side or Radius" incorrect for Sub-Plot (Dim1).',NULL,'SR_SpecRich1Dim1orDim2Incorrect','SpecRich#Dim1','1=30, 2=0, 3=0, 4=0, 5=0, 6=0');

CREATE VIEW QAQC_SR_SpecRichDim1Incorrect AS
    SELECT d.RecKey || ';' || d.SubPlot AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PLotID,
           c.LineID,
           d.FormDate,
           d.SubPlot,
           d.SpecRichDim1
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           (
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '1' AS SubPlot,
                      SpecRich1Container AS SpecRichContainer,
                      SpecRich1Shape AS SpecRichShape,
                      SpecRich1Dim1 AS SpecRichDim1,
                      SpecRich1Dim2 AS SpecRichDim2,
                      SpecRich1Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '2' AS SubPlot,
                      SpecRich2Container AS SpecRichContainer,
                      SpecRich2Shape AS SpecRichShape,
                      SpecRich2Dim1 AS SpecRichDim1,
                      SpecRich2Dim2 AS SpecRichDim2,
                      SpecRich2Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '3' AS SubPlot,
                      SpecRich3Container AS SpecRichContainer,
                      SpecRich3Shape AS SpecRichShape,
                      SpecRich3Dim1 AS SpecRichDim1,
                      SpecRich3Dim2 AS SpecRichDim2,
                      SpecRich3Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '4' AS SubPlot,
                      SpecRich4Container AS SpecRichContainer,
                      SpecRich4Shape AS SpecRichShape,
                      SpecRich4Dim1 AS SpecRichDim1,
                      SpecRich4Dim2 AS SpecRichDim2,
                      SpecRich4Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '5' AS SubPlot,
                      SpecRich5Container AS SpecRichContainer,
                      SpecRich5Shape AS SpecRichShape,
                      SpecRich5Dim1 AS SpecRichDim1,
                      SpecRich5Dim2 AS SpecRichDim2,
                      SpecRich5Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '6' AS SubPlot,
                      SpecRich6Container AS SpecRichContainer,
                      SpecRich6Shape AS SpecRichShape,
                      SpecRich6Dim1 AS SpecRichDim1,
                      SpecRich6Dim2 AS SpecRichDim2,
                      SpecRich6Area AS SpecRichArea
                 FROM tblSpecRichHeader
           )
           AS d ON c.LineKey = d.LineKey
     WHERE (d.SubPlot = '1' AND 
            (d.SpecRichDim1 IS NULL OR 
             d.SpecRichDim1 != 30) ) OR 
           (d.SubPlot = '2' AND 
            (d.SpecRichDim1 IS NULL OR 
             d.SpecRichDim1 != 0) ) OR 
           (d.SubPlot = '3' AND 
            (d.SpecRichDim1 IS NULL OR 
             d.SpecRichDim1 != 0) ) OR 
           (d.SubPlot = '4' AND 
            (d.SpecRichDim1 IS NULL OR 
             d.SpecRichDim1 != 0) ) OR 
           (d.SubPlot = '5' AND 
            (d.SpecRichDim1 IS NULL OR 
             d.SpecRichDim1 != 0) ) OR 
           (d.SubPlot = '6' AND 
            (d.SpecRichDim1 IS NULL OR 
             d.SpecRichDim1 != 0) ) 
     ORDER BY a.SiteID,
              b.PlotID,
              c.LineID,
              d.FormDate,
              d.SubPlot;


--QAQC_SR_LineIDIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_SR_LineIDIncorrect','Species Richness','Form Option','Line ID incorrect.','A specific line needs to be chosen if Species Richness is not being done on the line level but the plot level.','SR_LineIDIncorrect','LineID','=1');
			  
CREATE VIEW QAQC_SR_LineIDIncorrect AS
    SELECT d.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           d.FormDate
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSpecRichHeader AS d ON c.LineKey = d.LineKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (c.LineID != '1');
		   
		   
--QAQC_SR_MissingData
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_SR_MissingData','Species Richness','Missing Data','Missing Species Richness for this plot.',NULL,'SR_MissingData',NULL,NULL);

CREATE VIEW QAQC_SR_MissingData AS
    SELECT c.PlotKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           Count(RecKey) AS Line_n
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           LEFT JOIN
           tblSpecRichHeader AS d ON c.LineKey = d.LineKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') 
     GROUP BY PlotID
    HAVING Line_n = 0;
	
	
--QAQC_SR_MissingObserver
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_SR_MissingObserver','Species Richness','Missing Data','Missing Observer.',NULL,'SR_MissingObserver','Observer',NULL);

CREATE VIEW QAQC_SR_MissingObserver AS
    SELECT d.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           d.FormDate,
           d.Observer
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSpecRichHeader AS d ON c.LineKey = d.LineKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.Observer IS NULL OR 
            d.Observer = '');
			
			
--QAQC_SR_MissingRecorder
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(3.0,'QAQC_SR_MissingRecorder','Species Richness','Missing Data','Missing Recorder.',NULL,'SR_MissingRecorder','Recorder','TRUE');

CREATE VIEW QAQC_SR_MissingRecorder AS
    SELECT d.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           d.FormDate,
           d.Recorder
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSpecRichHeader AS d ON c.LineKey = d.LineKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.Recorder IS NULL OR 
            d.Recorder = '');
			
			
--QAQC_SR_DataEntryNoErrorCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(4.0,'QAQC_SR_DataEntryNoErrorCheck','Species Richness','Missing Data','There was data entry from other source (because DataEntry not NULL) and there is no Error Checker listed.',NULL,'SR_DataEntryNoErrorCheck','DataErrorChecking',NULL);

CREATE VIEW QAQC_SR_DataEntryNoErrorCheck AS
    SELECT d.RecKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           d.FormDate,
           d.DataEntry,
           d.DataErrorChecking
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSpecRichHeader AS d ON c.LineKey = d.LineKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.DataEntry IS NOT NULL AND 
            d.DataEntry != '' AND 
            (d.DataErrorChecking IS NULL OR 
             d.DataErrorChecking = ''));
			 
			 
--QAQC_SR_SpeciesListBlank
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(5.0,'QAQC_SR_SpeciesListBlank','Species Richness','Missing Data','Species Richness is blank.',NULL,'SR_SpeciesListBlank',NULL,NULL);

CREATE VIEW QAQC_SR_SpeciesListBlank AS
    SELECT e.RecKey || ';' || e.subPlotID AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           d.FormDate,
           e.SpeciesList
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSpecRichHeader AS d ON c.LineKey = d.LineKey
           JOIN
           tblSpecRichDetail AS e ON d.RecKey = e.RecKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (e.SpeciesList IS NULL OR 
            e.SpeciesList = '');

			
--QAQC_SR_LPI_SpeciesNotInSR
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(6.0,'QAQC_SR_LPI_SpeciesNotInSR','Species Richness','Missing Data','There is a species in LPI not in Species Richness.',NULL,'SR_SpeciesInLPI_NotSR',NULL,NULL);
			
CREATE VIEW QAQC_SR_LPI_SpeciesNotInSR AS
    SELECT q.PlotKey || ';' || q.Season || ';' || q.Species AS ErrorKey,
           q.*
      FROM (
               SELECT x.*
                 FROM (
                          SELECT a.SiteID,
                                 a.PlotKey,
                                 a.PlotID,
                                 (
                                     SELECT SeasonLabel
                                       FROM SeasonDefinition
                                      WHERE a.FormDate BETWEEN SeasonStart AND SeasonEnd
                                 )
                                 AS Season,
                                 a.Species
                            FROM LPI_CanopyLayers_Point_DB_UNION AS a
                           GROUP BY PlotKey,
                                    Season,
                                    Species
                      )
                      AS x
                      JOIN
                      tblSpecies AS y ON x.Species = y.SpeciesCode
           )
           AS q
           LEFT JOIN
           (
               SELECT x.SiteID,
                      x.SiteName,
                      x.PlotKey,
                      x.PlotID,
                      x.Season,
                      x.SpeciesCode
                 FROM (
                          SELECT a.SiteID,
                                 a.SiteName,
                                 b.PlotKey,
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
                           WHERE a.SiteKey NOT IN ('888888888', '999999999') 
                           GROUP BY PlotID,
                                    Season,
                                    SpeciesCode
                      )
                      AS x
           )
           AS r ON q.PlotKey = r.PlotKey AND 
                   q.Season = r.Season AND 
                   q.Species = r.SpeciesCode
     WHERE r.SpeciesCode IS NULL AND 
           q.Species NOT IN ('AF00', 'PF00', 'AG00', 'PG00', 'SH00', 'TR00', 'SU00', 'AF000', 'PF000', 'AG000', 'PG000', 'SH000', 'TR000', 'SU000', 'AAFF', 'PPFF', 'AAGG', 'PPGG', 'PPSH', 'PPTR', 'PPSU');

		   
--QAQC_SR_LI_SpeciesNotInSR
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(7.0,'QAQC_SR_LI_SpeciesNotInSR','Species Richness','Missing Data','There is a species in LI not in Species Richness.',NULL,'SR_SpeciesInLI_NotSR',NULL,NULL);
		   
CREATE VIEW QAQC_SR_LI_SpeciesNotInSR AS
    SELECT q.PlotKey || ';' || q.Season || ';' || q.Species AS ErrorKey,
           q.*
      FROM (
               SELECT x.*
                 FROM (
                          SELECT a.SiteID,
                                 a.PlotKey,
                                 a.PlotID,
                                 (
                                     SELECT SeasonLabel
                                       FROM SeasonDefinition
                                      WHERE a.FormDate BETWEEN SeasonStart AND SeasonEnd
                                 )
                                 AS Season,
                                 a.Species
                            FROM (
                                     SELECT e.SiteID,
                                            e.SiteName,
                                            d.PlotKey,
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
                                               SegStart
                                 )
                                 AS a
                           GROUP BY PlotKey,
                                    Season,
                                    Species
                      )
                      AS x
                      JOIN
                      tblSpecies AS y ON x.Species = y.SpeciesCode
           )
           AS q
           LEFT JOIN
           (
               SELECT x.SiteID,
                      x.SiteName,
                      x.PlotKey,
                      x.PlotID,
                      x.Season,
                      x.SpeciesCode
                 FROM (
                          SELECT a.SiteID,
                                 a.SiteName,
                                 b.PlotKey,
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
                           WHERE a.SiteKey NOT IN ('888888888', '999999999') 
                           GROUP BY PlotID,
                                    Season,
                                    SpeciesCode
                      )
                      AS x
           )
           AS r ON q.PlotKey = r.PlotKey AND 
                   q.Season = r.Season AND 
                   q.Species = r.SpeciesCode
     WHERE r.SpeciesCode IS NULL AND 
           q.Species NOT IN ('AF00', 'PF00', 'AG00', 'PG00', 'SH00', 'TR00', 'SU00', 'AF000', 'PF000', 'AG000', 'PG000', 'SH000', 'TR000', 'SU000', 'AAFF', 'PPFF', 'AAGG', 'PPGG', 'PPSH', 'PPTR', 'PPSU');

		   
--QAQC_SR_PD_SpeciesNotInSR
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(8.0,'QAQC_SR_PD_SpeciesNotInSR','Species Richness','Missing Data','There is a species in Plant Density not in Species Richness.',NULL,'SR_SpeciesInPD_NotSR',NULL,NULL);
		   
CREATE VIEW QAQC_SR_PD_SpeciesNotInSR AS
    SELECT q.PlotKey || ';' || q.Season || ';' || q.SpeciesCode AS ErrorKey,
           q.*
      FROM (
               SELECT x.*
                 FROM (
                          SELECT a.SiteID,
                                 a.SiteName,
                                 b.PlotID,
                                 b.PlotKey,
                                 (
                                     SELECT SeasonLabel
                                       FROM SeasonDefinition
                                      WHERE d.FormDate BETWEEN SeasonStart AND SeasonEnd
                                 )
                                 AS Season,
                                 e.SpeciesCode
                            FROM tblSites AS a
                                 JOIN
                                 tblPlots AS b ON a.siteKey = b.SiteKey
                                 JOIN
                                 tblLines AS c ON b.PlotKey = c.PlotKey
                                 JOIN
                                 tblPlantDenHeader AS d ON c.LineKey = d.LineKey
                                 JOIN
                                 PD_Detail_Long AS e ON d.RecKey = e.RecKey
                           GROUP BY b.PlotKey,
                                    Season,
                                    e.SpeciesCode
                      )
                      AS x
                      JOIN
                      tblSpecies AS y ON x.SpeciesCode = y.SpeciesCode
           )
           AS q
           LEFT JOIN
           (
               SELECT x.SiteID,
                      x.SiteName,
                      x.PlotKey,
                      x.PlotID,
                      x.Season,
                      x.SpeciesCode
                 FROM (
                          SELECT a.SiteID,
                                 a.SiteName,
                                 b.PlotKey,
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
                           WHERE a.SiteKey NOT IN ('888888888', '999999999') 
                           GROUP BY PlotID,
                                    Season,
                                    SpeciesCode
                      )
                      AS x
           )
           AS r ON q.PlotKey = r.PlotKey AND 
                   q.Season = r.Season AND 
                   q.SpeciesCode = r.SpeciesCode
     WHERE r.SpeciesCode IS NULL AND 
           q.SpeciesCode NOT IN ('AF00', 'PF00', 'AG00', 'PG00', 'SH00', 'TR00', 'SU00', 'AF000', 'PF000', 'AG000', 'PG000', 'SH000', 'TR000', 'SU000', 'AAFF', 'PPFF', 'AAGG', 'PPGG', 'PPSH', 'PPTR', 'PPSU');


--QAQC_SR_SpeciesNotInSpeciesList
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(9.0,'QAQC_SR_SpeciesNotInSpeciesList','Species Richness','Missing Data','There is a species in the species richness list that is not in the Master Species List',NULL,'SR_SpeciesNotInSpeciesList','Species',NULL);
		   
CREATE VIEW QAQC_SR_SpeciesNotInSpeciesList AS
    SELECT e.RecKey || ';' || e.subPlotID || ';' || e.SpeciesCode AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.LineID,
           d.FormDate,
           e.SpeciesCode AS SpeciesCodeForm,
           f.SpeciesCode AS SpeciesCodeMaster
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSpecRichHeader AS d ON c.LineKey = d.LineKey
           JOIN
           SR_Raw AS e ON d.RecKey = e.RecKey
           LEFT JOIN
           tblSpecies AS f ON e.SpeciesCode = f.SpeciesCode
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           f.SpeciesCode IS NULL;
		   
		   
--QAQC_SR_Header_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(1.0,'QAQC_SR_Header_OrphanRecordCheck','Species Richness','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'SR_Header_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_SR_Header_OrphanRecordCheck AS
    SELECT a.RecKey AS ErrorKey,
           b.LineKey AS tblLines_LineKey,
           a.LineKey AS tblSpecRichHeader_LineKey,
           a.FormDate
      FROM tblSpecRichHeader AS a
           LEFT JOIN
           tblLines AS b ON a.LineKey = b.LineKey
     WHERE b.LineKey IS NULL;
	 
	 
--QAQC_SR_Detail_OrphanRecordCheck
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(2.0,'QAQC_SR_Detail_OrphanRecordCheck','Species Richness','Orphan Record','Records from this table do not have an associated record from related table.',NULL,'SR_Detail_OrphanRecordCheck',NULL,NULL);

CREATE VIEW QAQC_SR_Detail_OrphanRecordCheck AS
    SELECT a.RecKey || ';' || a.subPlotID AS ErrorKey,
           b.RecKey AS tblSpecRichHeader_RecKey,
           a.RecKey AS tblSpecRichDetail_RecKey,
           a.SpeciesList
      FROM tblSpecRichDetail AS a
           LEFT JOIN
           tblSpecRichHeader AS b ON a.RecKey = b.RecKey
     WHERE b.RecKey IS NULL;
	 
	 
--QAQC_Geographic
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(0.0,'QAQC_Geographic','All Methods','Data Criterion Failure','A coordinate falls outside of sample area.',NULL,'Geographic','Coord','-120 < x --114, 35 < y < 42, 146 < z < 4007 ');

CREATE VIEW QAQC_Geographic AS
    SELECT q.SiteID || ':' || q.PlotID || ':' || q.LineID || ';' || q.CoordType || ';' || q.PointType AS ErrorKey,
           q.*
      FROM (
               SELECT a.SiteID,
                      a.SiteName,
                      b.PlotID,
                      'NA' AS LineID,
                      b.GPSCoordSys,
                      b.Datum,
                      b.Zone,
                      b.Easting AS Coord,
                      'X' AS CoordType,
                      'Plot Center' AS PointType
                 FROM tblSites AS a
                      JOIN
                      tblPlots AS b ON a.SiteKey = b.SiteKey
                WHERE a.SiteKey NOT IN ('888888888', '999999999') 
               UNION
               SELECT a.SiteID,
                      a.SiteName,
                      b.PlotID,
                      'NA' AS LineID,
                      b.GPSCoordSys,
                      b.Datum,
                      b.Zone,
                      b.Northing AS Coord,
                      'Y' AS CoordType,
                      'Plot Center' AS PointType
                 FROM tblSites AS a
                      JOIN
                      tblPlots AS b ON a.SiteKey = b.SiteKey
                WHERE a.SiteKey NOT IN ('888888888', '999999999') 
               UNION
               SELECT a.SiteID,
                      a.SiteName,
                      b.PlotID,
                      'NA' AS LineID,
                      b.GPSCoordSys,
                      b.Datum,
                      b.Zone,
                      b.Elevation AS Coord,
                      'Z' AS CoordType,
                      'Plot Center' AS PointType
                 FROM tblSites AS a
                      JOIN
                      tblPlots AS b ON a.SiteKey = b.SiteKey
                WHERE a.SiteKey NOT IN ('888888888', '999999999') 
               UNION
               SELECT a.SiteID,
                      a.SiteName,
                      b.PlotID,
                      c.LineID,
                      b.GPSCoordSys,
                      b.Datum,
                      b.Zone,
                      c.EastingStart AS Coord,
                      'X' AS CoordType,
                      'Line Start' AS PointType
                 FROM tblSites AS a
                      JOIN
                      tblPlots AS b ON a.SiteKey = b.SiteKey
                      JOIN
                      tblLines AS c ON b.PlotKey = c.PlotKey
                WHERE a.SiteKey NOT IN ('888888888', '999999999') 
               UNION
               SELECT a.SiteID,
                      a.SiteName,
                      b.PlotID,
                      c.LineID,
                      b.GPSCoordSys,
                      b.Datum,
                      b.Zone,
                      c.NorthingStart AS Coord,
                      'Y' AS CoordType,
                      'Line Start' AS PointType
                 FROM tblSites AS a
                      JOIN
                      tblPlots AS b ON a.SiteKey = b.SiteKey
                      JOIN
                      tblLines AS c ON b.PlotKey = c.PlotKey
                WHERE a.SiteKey NOT IN ('888888888', '999999999') 
               UNION
               SELECT a.SiteID,
                      a.SiteName,
                      b.PlotID,
                      c.LineID,
                      b.GPSCoordSys,
                      b.Datum,
                      b.Zone,
                      c.ElevationStart AS Coord,
                      'Z' AS CoordType,
                      'Line Start' AS PointType
                 FROM tblSites AS a
                      JOIN
                      tblPlots AS b ON a.SiteKey = b.SiteKey
                      JOIN
                      tblLines AS c ON b.PlotKey = c.PlotKey
                WHERE a.SiteKey NOT IN ('888888888', '999999999') 
               UNION
               SELECT a.SiteID,
                      a.SiteName,
                      b.PlotID,
                      c.LineID,
                      b.GPSCoordSys,
                      b.Datum,
                      b.Zone,
                      c.EastingEnd AS Coord,
                      'X' AS CoordType,
                      'Line End' AS PointType
                 FROM tblSites AS a
                      JOIN
                      tblPlots AS b ON a.SiteKey = b.SiteKey
                      JOIN
                      tblLines AS c ON b.PlotKey = c.PlotKey
                WHERE a.SiteKey NOT IN ('888888888', '999999999') 
               UNION
               SELECT a.SiteID,
                      a.SiteName,
                      b.PlotID,
                      c.LineID,
                      b.GPSCoordSys,
                      b.Datum,
                      b.Zone,
                      c.NorthingEnd AS Coord,
                      'Y' AS CoordType,
                      'Line End' AS PointType
                 FROM tblSites AS a
                      JOIN
                      tblPlots AS b ON a.SiteKey = b.SiteKey
                      JOIN
                      tblLines AS c ON b.PlotKey = c.PlotKey
                WHERE a.SiteKey NOT IN ('888888888', '999999999') 
               UNION
               SELECT a.SiteID,
                      a.SiteName,
                      b.PlotID,
                      c.LineID,
                      b.GPSCoordSys,
                      b.Datum,
                      b.Zone,
                      c.ElevationEnd AS Coord,
                      'Z' AS CoordType,
                      'Line End' AS PointType
                 FROM tblSites AS a
                      JOIN
                      tblPlots AS b ON a.SiteKey = b.SiteKey
                      JOIN
                      tblLines AS c ON b.PlotKey = c.PlotKey
                WHERE a.SiteKey NOT IN ('888888888', '999999999') 
           )
           AS q
     WHERE (CoordType = 'X' AND 
            (Coord < -120 OR 
             Coord > -114) ) OR 
           (CoordType = 'Y' AND 
            (Coord < 35 OR 
             Coord > 42) ) OR 
           (CoordType = 'Z' AND 
            (Coord < 146 OR 
             Coord > 4007) ) 
     ORDER BY SiteID,
              PlotID,
              LineID,
              PointType,
              CoordType;

			  
--QAQC_SoilPit_MissingEffervescence
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(9.0,'QAQC_SoilPit_MissingEffervescence','Soil Pit','Missing Data','Effervescence missing',NULL,'SoilPit_MissingEffervescence','Effer',NULL);
			  
CREATE VIEW QAQC_SoilPit_MissingEffervescence AS
    SELECT d.HorizonKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.DateRecorded,
		   d.HorizonDepthUpper,
		   d.HorizonDepthLower,
		   d.ESD_Horizon,
           d.Effer
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSoilPitHorizons AS d ON c.SoilKey = d.SoilKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.Effer IS NULL OR 
            d.Effer = '') AND
           (d.ESD_Horizon IS NULL OR
           d.ESD_Horizon <> 'R');
			
			
--QAQC_SoilPit_MissingColor
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(10.0,'QAQC_SoilPit_MissingColor','Soil Pit','Missing Data','Color missing',NULL,'SoilPit_MissingColor','ESD_Hue, ESD_Value, ESD_Chroma',NULL);

CREATE VIEW QAQC_SoilPit_MissingColor AS
    SELECT d.HorizonKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.DateRecorded,
           d.HorizonDepthUpper,
		   d.HorizonDepthLower,
		   d.ESD_Horizon,
           d.ESD_Hue,
           d.ESD_Value,
           d.ESD_Chroma
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSoilPitHorizons AS d ON c.SoilKey = d.SoilKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           ( (d.ESD_Hue IS NULL OR 
              d.ESD_Value IS NULL OR 
              d.ESD_Chroma IS NULL) OR 
             (d.ESD_Hue = '' OR 
              d.ESD_Value = '' OR 
              d.ESD_Chroma = '') ) AND
           (d.ESD_Horizon IS NULL OR
           d.ESD_Horizon <> 'R');
			  
			  
--QAQC_SoilPit_ColorTypeIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(11.0,'QAQC_SoilPit_ColorTypeIncorrect','Soil Pit','Data Criterion Failure','Color type incorrect','The project specifies wheather color should be collected Dry or Wet.  Value not consistent with project.','SoilPit_ColorTypeIncorrect','ESD_Color','Dry');

CREATE VIEW QAQC_SoilPit_ColorTypeIncorrect AS
    SELECT d.HorizonKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.DateRecorded,
           d.HorizonDepthUpper,
		   d.HorizonDepthLower,
		   d.ESD_Horizon,
           d.ESD_Color
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSoilPitHorizons AS d ON c.SoilKey = d.SoilKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.ESD_Color IS NULL OR 
            d.ESD_Color != 'Dry') AND
           (d.ESD_Horizon IS NULL OR
            d.ESD_Horizon <> 'R');
			
			
--QAQC_SoilPit_MissingGrade
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(12.0,'QAQC_SoilPit_MissingGrade','Soil Pit','Missing Data','Grade missing',NULL,'SoilPit_MissingGrade','ESD_Grade',NULL);

CREATE VIEW QAQC_SoilPit_MissingGrade AS
    SELECT d.HorizonKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.DateRecorded,
           d.HorizonDepthUpper,
		   d.HorizonDepthLower,
           d.ESD_Horizon,
		   d.ESD_Grade
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSoilPitHorizons AS d ON c.SoilKey = d.SoilKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.ESD_Grade IS NULL OR 
            d.ESD_Color = '') AND
           (d.ESD_Horizon IS NULL OR
           d.ESD_Horizon <> 'R');
			
			
--QAQC_SoilPit_MissingSize
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(13.0,'QAQC_SoilPit_MissingSize','Soil Pit','Missing Data','Size missing',NULL,'SoilPit_MissingSize','ESD_Size',NULL);

CREATE VIEW QAQC_SoilPit_MissingSize AS
    SELECT d.HorizonKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.DateRecorded,
           d.HorizonDepthUpper,
           d.HorizonDepthLower,
           d.ESD_Horizon,
           d.ESD_Size 
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSoilPitHorizons AS d ON c.SoilKey = d.SoilKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.ESD_Size IS NULL OR 
            d.ESD_Size = '') AND
           (d.ESD_Horizon IS NULL OR
           d.ESD_Horizon <> 'R');
			
			
--QAQC_SoilPit_MissingStructure
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(14.0,'QAQC_SoilPit_MissingStructure','Soil Pit','Missing Data','Structure missing',NULL,'SoilPit_MissingStructure','ESD_Structure',NULL);

CREATE VIEW QAQC_SoilPit_MissingStructure AS
    SELECT d.HorizonKey AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PlotID,
           c.DateRecorded,
		   d.HorizonDepthUpper,
		   d.HorizonDepthLower,
		   d.ESD_Horizon,
           d.ESD_Structure
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblSoilPits AS c ON b.PlotKey = c.PlotKey
           JOIN
           tblSoilPitHorizons AS d ON c.SoilKey = d.SoilKey
     WHERE a.SiteKey NOT IN ('888888888', '999999999') AND 
           (d.ESD_Structure IS NULL OR 
            d.ESD_Structure = '') AND
           (d.ESD_Horizon IS NULL OR
           d.ESD_Horizon <> 'R');

			
--QAQC_SR_SpecRichDim2Incorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(7.0,'QAQC_SR_SpecRichDim2Incorrect','Species Richness','Form Default','"Side or Radius" incorrect for Sub-Plot (Dim2).',NULL,'SR_SpecRichDim2Incorrect','SpecRich#Dim2','1=2, 2=0, 3=0, 4=0, 5=0, 6=0');
			
CREATE VIEW QAQC_SR_SpecRichDim2Incorrect AS
    SELECT d.RecKey || ';' || d.SubPlot AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PLotID,
           c.LineID,
           d.FormDate,
           d.SubPlot,
           d.SpecRichDim2
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           (
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '1' AS SubPlot,
                      SpecRich1Container AS SpecRichContainer,
                      SpecRich1Shape AS SpecRichShape,
                      SpecRich1Dim1 AS SpecRichDim1,
                      SpecRich1Dim2 AS SpecRichDim2,
                      SpecRich1Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '2' AS SubPlot,
                      SpecRich2Container AS SpecRichContainer,
                      SpecRich2Shape AS SpecRichShape,
                      SpecRich2Dim1 AS SpecRichDim1,
                      SpecRich2Dim2 AS SpecRichDim2,
                      SpecRich2Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '3' AS SubPlot,
                      SpecRich3Container AS SpecRichContainer,
                      SpecRich3Shape AS SpecRichShape,
                      SpecRich3Dim1 AS SpecRichDim1,
                      SpecRich3Dim2 AS SpecRichDim2,
                      SpecRich3Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '4' AS SubPlot,
                      SpecRich4Container AS SpecRichContainer,
                      SpecRich4Shape AS SpecRichShape,
                      SpecRich4Dim1 AS SpecRichDim1,
                      SpecRich4Dim2 AS SpecRichDim2,
                      SpecRich4Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '5' AS SubPlot,
                      SpecRich5Container AS SpecRichContainer,
                      SpecRich5Shape AS SpecRichShape,
                      SpecRich5Dim1 AS SpecRichDim1,
                      SpecRich5Dim2 AS SpecRichDim2,
                      SpecRich5Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '6' AS SubPlot,
                      SpecRich6Container AS SpecRichContainer,
                      SpecRich6Shape AS SpecRichShape,
                      SpecRich6Dim1 AS SpecRichDim1,
                      SpecRich6Dim2 AS SpecRichDim2,
                      SpecRich6Area AS SpecRichArea
                 FROM tblSpecRichHeader
           )
           AS d ON c.LineKey = d.LineKey
     WHERE (d.SubPlot = '1' AND 
            (d.SpecRichDim2 IS NULL OR 
             d.SpecRichDim2 != 30) ) OR 
           (d.SubPlot = '2' AND 
            (d.SpecRichDim2 IS NULL OR 
             d.SpecRichDim2 != 0) ) OR 
           (d.SubPlot = '3' AND 
            (d.SpecRichDim2 IS NULL OR 
             d.SpecRichDim2 != 0) ) OR 
           (d.SubPlot = '4' AND 
            (d.SpecRichDim2 IS NULL OR 
             d.SpecRichDim2 != 0) ) OR 
           (d.SubPlot = '5' AND 
            (d.SpecRichDim2 IS NULL OR 
             d.SpecRichDim2 != 0) ) OR 
           (d.SubPlot = '6' AND 
            (d.SpecRichDim2 IS NULL OR 
             d.SpecRichDim2 != 0) ) 
     ORDER BY a.SiteID,
              b.PlotID,
              c.LineID,
              d.FormDate,
              d.SubPlot;

			  
--QAQC_SR_SpecRichAreaIncorrect
INSERT INTO QAQC_Queries (QueryOrder, QueryName, Method, Function, Description, DescriptionSub, ExportID, Field, CorrectValue) 
VALUES(8.0,'QAQC_SR_SpecRichAreaIncorrect','Species Richness','Form Default','Area value incorrect for Sub-Plot',NULL,'SR_SpecRichAreaIncorrect','SpecRich#Area','1=2827.431, 2=0. 3=0, 4=0, 5=0, 6=0');			  

CREATE VIEW QAQC_SR_SpecRichAreaIncorrect AS
    SELECT d.RecKey || ';' || d.SubPlot AS ErrorKey,
           a.SiteID,
           a.SiteName,
           b.PLotID,
           c.LineID,
           d.FormDate,
           d.SubPlot,
           d.SpecRichArea
      FROM tblSites AS a
           JOIN
           tblPlots AS b ON a.SiteKey = b.SiteKey
           JOIN
           tblLines AS c ON b.PlotKey = c.PlotKey
           JOIN
           (
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '1' AS SubPlot,
                      SpecRich1Container AS SpecRichContainer,
                      SpecRich1Shape AS SpecRichShape,
                      SpecRich1Dim1 AS SpecRichDim1,
                      SpecRich1Dim2 AS SpecRichDim2,
                      SpecRich1Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '2' AS SubPlot,
                      SpecRich2Container AS SpecRichContainer,
                      SpecRich2Shape AS SpecRichShape,
                      SpecRich2Dim1 AS SpecRichDim1,
                      SpecRich2Dim2 AS SpecRichDim2,
                      SpecRich2Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '3' AS SubPlot,
                      SpecRich3Container AS SpecRichContainer,
                      SpecRich3Shape AS SpecRichShape,
                      SpecRich3Dim1 AS SpecRichDim1,
                      SpecRich3Dim2 AS SpecRichDim2,
                      SpecRich3Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '4' AS SubPlot,
                      SpecRich4Container AS SpecRichContainer,
                      SpecRich4Shape AS SpecRichShape,
                      SpecRich4Dim1 AS SpecRichDim1,
                      SpecRich4Dim2 AS SpecRichDim2,
                      SpecRich4Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '5' AS SubPlot,
                      SpecRich5Container AS SpecRichContainer,
                      SpecRich5Shape AS SpecRichShape,
                      SpecRich5Dim1 AS SpecRichDim1,
                      SpecRich5Dim2 AS SpecRichDim2,
                      SpecRich5Area AS SpecRichArea
                 FROM tblSpecRichHeader
               UNION
               SELECT LineKey,
                      RecKey,
                      FormDate,
                      '6' AS SubPlot,
                      SpecRich6Container AS SpecRichContainer,
                      SpecRich6Shape AS SpecRichShape,
                      SpecRich6Dim1 AS SpecRichDim1,
                      SpecRich6Dim2 AS SpecRichDim2,
                      SpecRich6Area AS SpecRichArea
                 FROM tblSpecRichHeader
           )
           AS d ON c.LineKey = d.LineKey
     WHERE (d.SubPlot = '1' AND 
            (d.SpecRichArea IS NULL OR 
             Round(d.SpecRichArea,3) != 2827.431) ) OR 
           (d.SubPlot = '2' AND 
            (d.SpecRichArea IS NULL OR 
             Round(d.SpecRichArea,3) != 0.000) ) OR 
           (d.SubPlot = '3' AND 
            (d.SpecRichArea IS NULL OR 
             Round(d.SpecRichArea,3) != 0.000) ) OR 
           (d.SubPlot = '4' AND 
            (d.SpecRichArea IS NULL OR 
             Round(d.SpecRichArea,3) != 0.000) ) OR 
           (d.SubPlot = '5' AND 
            (d.SpecRichArea IS NULL OR 
             Round(d.SpecRichArea,3) != 0.000) ) OR 
           (d.SubPlot = '6' AND 
            (d.SpecRichArea IS NULL OR 
             Round(d.SpecRichArea,3) != 0.000) ) 
     ORDER BY a.SiteID,
              b.PlotID,
              c.LineID,
              d.FormDate,
              d.SubPlot;
			  
COMMIT TRANSACTION;
PRAGMA foreign_keys = on;