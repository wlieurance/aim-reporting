PRAGMA foreign_keys = off;

BEGIN TRANSACTION;

--Tag Type: Plot --Tag: SiteName
INSERT OR IGNORE INTO PlotTags SELECT a.PlotKey,
                            b.SiteName AS Tag,
                            1 AS Weight
                       FROM tblPlots AS a
                            JOIN
                            tblSites AS b ON a.SiteKey = b.SiteKey
                      WHERE b.SiteKey NOT IN ('888888888', '999999999');

					  
--Tag Type: Plot --Tag: SiteName_Ecological Site
INSERT OR IGNORE INTO PlotTags SELECT a.PlotKey,
                            b.SiteName || '_' || Trim(a.Ecolsite) AS Tag,
                            1 AS Weight
                       FROM tblPlots AS a
                            JOIN
                            tblSites AS b ON a.SiteKey = b.SiteKey
                      WHERE b.SiteKey NOT IN ('888888888', '999999999');


--Tag Type: Plot --Tag: SiteName_Ecological Group					  
INSERT OR IGNORE INTO PlotTags SELECT a.PlotKey,
                            b.SiteName || '_' || CASE WHEN c.EcoGroup IS NULL THEN Trim(a.EcolSite) ELSE c.EcoGroup END AS Tag,
                            1 AS Weight
                       FROM tblPlots AS a
                            JOIN
                            tblSites AS b ON a.SiteKey = b.SiteKey
                            LEFT JOIN
                            EcositeGroups AS c ON a.Ecolsite = c.EcolSiteID
                      WHERE b.SiteKey NOT IN ('888888888', '999999999');

				
--Tag Type: Plot --Tag: SiteID				
INSERT OR IGNORE INTO PlotTags SELECT a.PlotKey,
                            b.SiteID AS Tag,
                            1 AS Weight
                       FROM tblPlots AS a
                            JOIN
                            tblSites AS b ON a.SiteKey = b.SiteKey
                      WHERE b.SiteKey NOT IN ('888888888', '999999999');

					  
--Tag Type: Plot --Tag: SiteID_Ecological Site					  
INSERT OR IGNORE INTO PlotTags SELECT a.PlotKey,
                            b.SiteID || '_' || Trim(a.Ecolsite) AS Tag,
                            1 AS Weight
                       FROM tblPlots AS a
                            JOIN
                            tblSites AS b ON a.SiteKey = b.SiteKey
                      WHERE b.SiteKey NOT IN ('888888888', '999999999');

					  
--Tag Type: Plot --Tag: SiteID_Ecological Group					  
INSERT OR IGNORE INTO PlotTags SELECT a.PlotKey,
                            b.SiteID || '_' || CASE WHEN c.EcoGroup IS NULL THEN Trim(a.EcolSite) ELSE c.EcoGroup END AS Tag,
                            1 AS Weight
                       FROM tblPlots AS a
                            JOIN
                            tblSites AS b ON a.SiteKey = b.SiteKey
                            LEFT JOIN
                            EcositeGroups AS c ON a.Ecolsite = c.EcolSiteID
                      WHERE b.SiteKey NOT IN ('888888888', '999999999');

					  
--Tag Type: Plot --Tag: Ecological Site
INSERT OR IGNORE INTO PlotTags SELECT a.PlotKey,
                            Trim(a.Ecolsite) AS Tag,
                            1 AS Weight
                       FROM tblPlots AS a
                            JOIN
                            tblSites AS b ON a.SiteKey = b.SiteKey
                      WHERE b.SiteKey NOT IN ('888888888', '999999999');

					  
--Tag Type: Plot --Tag: Ecological Group					  
INSERT OR IGNORE INTO PlotTags SELECT a.PlotKey,
                            CASE WHEN c.EcoGroup IS NULL THEN Trim(a.EcolSite) ELSE c.EcoGroup END AS Tag,
                            1 AS Weight
                       FROM tblPlots AS a
                            JOIN
                            tblSites AS b ON a.SiteKey = b.SiteKey
                            LEFT JOIN
                            EcositeGroups AS c ON a.Ecolsite = c.EcolSiteID
                      WHERE b.SiteKey NOT IN ('888888888', '999999999');


--Tag Type: Plot --Tag: DIMA Plot Tag					  
INSERT OR IGNORE INTO PlotTags SELECT PlotKey,
                                      Tag,
                                      1 AS Weight
                                 FROM tblPlotTags;
					  
--Tag Type: Species --Tag: Sagebrush				  
INSERT OR IGNORE INTO SpeciesTags SELECT a.SpeciesCode,
                                         'Sagebrush' AS Tag
                                    FROM tblSpecies AS a
                                         LEFT JOIN
                                         tblSpeciesGrowthHabit AS b ON a.GrowthHabitCode = b.Code
                                   WHERE a.ScientificName LIKE 'Artemisia%' AND 
                                         b.GrowthHabit = 'Woody';

										 
--Tag Type: Species --Tag: ShrubNotSagebrush										 
INSERT OR IGNORE INTO SpeciesTags SELECT a.SpeciesCode,
                                         'ShrubNotSagebrush' AS Tag
                                    FROM tblSpecies AS a
                                         LEFT JOIN
                                         tblSpeciesGrowthHabit AS b ON a.GrowthHabitCode = b.Code
                                   WHERE a.ScientificName NOT LIKE 'Artemisia%' AND 
                                         b.GrowthHabitSub IN ('Shrub', 'Sub-Shrub');
										 

--Tag Type: Species --Tag: Invasive											 
INSERT OR IGNORE INTO SpeciesTags SELECT a.SpeciesCode,
                                         'Invasive' AS Tag
                                    FROM tblSpecies AS a
                                         LEFT JOIN
                                         tblSpeciesGrowthHabit AS b ON a.GrowthHabitCode = b.Code
                                   WHERE a.Invasive = 1;

								   
--Tag Type: Species --Tag: Invasive_GrowthHabit								   
INSERT OR IGNORE INTO SpeciesTags SELECT a.SpeciesCode,
                                         'Invasive' || "_" || CASE WHEN b.GrowthHabitSub IS NULL THEN 'NA' ELSE b.GrowthHabitSub END AS Tag
                                    FROM tblSpecies AS a
                                         LEFT JOIN
                                         tblSpeciesGrowthHabit AS b ON a.GrowthHabitCode = b.Code
                                   WHERE a.Invasive = 1;

								   
--Tag Type: Species --Tag: DIMA Group							   
INSERT OR IGNORE INTO SpeciesTags SELECT a.SpeciesCode,
                                         a.[Group]
                                    FROM tblSpecies AS a
                                   WHERE a.[Group] IS NOT NULL AND
									     a.[Group] != "";

COMMIT TRANSACTION ; 

PRAGMA foreign_keys = on;
