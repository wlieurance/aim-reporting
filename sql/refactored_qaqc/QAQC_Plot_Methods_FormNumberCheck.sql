CREATE VIEW QAQC_Plot_Methods_FormNumberCheck AS
WITH form_wanted AS (
SELECT a.SiteID, a.Sitename, b.PlotID, b.PlotKey, c.MethodName, c.FormNumber
  FROM tblSites AS a
 INNER JOIN tblPlots AS b ON a.SiteKey = b.SiteKey
 CROSS JOIN Methods AS c
 WHERE a.SiteKey NOT IN ('888888888', '999999999') 
   AND c.Use = 1

), line_est AS (
SELECT PlotKey, 'Line Establishment' AS Method, strftime('%Y', DateModified) AS Season, 
       Count(LineKey) AS n
  FROM tblLines
 WHERE PlotKey NOT IN ('888888888', '999999999') 
 GROUP BY PlotKey, strftime('%Y', DateModified)

), lpi AS (
SELECT b.PlotKey, 'Line-point Intercept' AS Method, strftime('%Y', a.FormDate) AS Season,
	   Count(a.RecKey) AS n
  FROM tblLPIHeader AS a
 INNER JOIN tblLines AS b ON a.LineKey = b.LineKey
 GROUP BY b.PlotKey, strftime('%Y', a.FormDate)

), cli AS (
SELECT b.PlotKey, 'Continuous Line Intercept' AS Method, strftime('%Y', a.FormDate) AS Season,
	   Count(a.RecKey) AS n
  FROM tblLICHeader AS a
 INNER JOIN tblLines AS b ON a.LineKey = b.LineKey
 GROUP BY b.PlotKey, strftime('%Y', a.FormDate)

), gap AS (
SELECT b.PlotKey, 'Gap Intercept' AS Method, strftime('%Y', a.FormDate) AS Season,
       Count(a.RecKey) AS n
  FROM tblGapHeader AS a
 INNER JOIN tblLines AS b ON a.LineKey = b.LineKey
 GROUP BY b.PlotKey, strftime('%Y', a.FormDate)

), plant_dens AS (
SELECT b.PlotKey, 'Plant Density' AS Method, strftime('%Y', a.FormDate) AS Season,
	   Count(a.RecKey) AS n
  FROM tblPlantDenHeader AS a
 INNER JOIN tblLines AS b ON a.LineKey = b.LineKey
 GROUP BY b.PlotKey, strftime('%Y', a.FormDate)

), spec_rich AS (
SELECT b.PlotKey, 'Species Richness' AS Method, strftime('%Y', a.FormDate) AS Season,
       Count(a.RecKey) AS n
  FROM tblSpecRichHeader AS a
 INNER JOIN tblLines AS b ON a.LineKey = b.LineKey
 GROUP BY b.PlotKey, strftime('%Y', a.FormDate)

), iirh AS (
SELECT b.PlotKey, 'IIRH' AS Method, strftime('%Y', a.FormDate) AS Season,
	   Count(a.RecKey) AS n
  FROM tblQualHeader AS a
 INNER JOIN tblPlots AS b ON a.PlotKey = b.PlotKey
 GROUP BY b.PlotKey, strftime('%Y', a.FormDate)

), soil_stab AS (
SELECT b.PlotKey, 'Soil Stability' AS Method, strftime('%Y', a.FormDate) AS Season,
	   Count(a.RecKey) AS n
  FROM tblSoilStabHeader AS a
 INNER JOIN tblPlots AS b ON a.PlotKey = b.PlotKey
 GROUP BY b.PlotKey, strftime('%Y', a.FormDate)

), soil_pit AS (
SELECT b.PlotKey, 'Soil Pit' AS Method, strftime('%Y',  a.DateRecorded) AS Season,
	   Count(a.SoilKey) AS n
  FROM tblSoilPits AS a
 INNER JOIN tblPlots AS b ON a.PlotKey = b.PlotKey
 GROUP BY b.PlotKey, strftime('%Y',  a.DateRecorded)

), form_cnt AS (
SELECT * FROM line_est UNION
SELECT * FROM lpi UNION
SELECT * FROM cli UNION
SELECT * FROM gap UNION
SELECT * FROM plant_dens UNION
SELECT * FROM spec_rich UNION
SELECT * FROM iirh UNION
SELECT * FROM soil_stab UNION
SELECT * FROM soil_pit
)

SELECT x.SiteID, x.SiteName, x.PlotID, x.MethodName,
	   x.FormNumber AS FormsNeeded, y.Season,
	   CASE WHEN y.n IS NULL THEN 0 ELSE y.n END AS FormsPresent
  FROM form_wanted x
  LEFT JOIN form_cnt AS y ON x.PlotKey = y.PlotKey 
        AND x.MethodName = y.Method
 WHERE FormsNeeded != FormsPresent;