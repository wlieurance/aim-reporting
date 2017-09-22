INSERT INTO EcositeGroups (EcolSiteIDStd, EcolSiteID, EcolSiteVeg, EcolSiteName, EcolsiteType, MLRA, EcoGroup, Subgroup, GroupType, Acreage, Model, DraftStatus) VALUES 
('023XY008NV', 'R023XY008NV', 'ARAR8/FEID-POSE', 'Mountain Ridge 14+', 'Range', '23', '23 1', '1', 'DRG', '33,029', 0, 'Final'),
('023XY031NV', 'R023XY031NV', 'ARAR8/PSSPS-ACTH7', 'Claypan 10-14"', 'Range', '23', '23 1', '1', 'DRG', '90,782', 1, 'Final'),
('023XY037NV', 'R023XY037NV', 'ARARL3/PSSPS', 'Clay Slope 8-12"', 'Range', '23', '23 1', '1', 'DRG', '64,040', 0, 'Final');

INSERT INTO PlotTags (PlotKey, Tag, Weight) VALUES 
('1603111317266107', 'Barren', 1),
('1603111319528429', 'Barren', 1),
('1603111320571827', 'Riparian', 1);


INSERT INTO SoilSeries (SeriesName) VALUES 
('aabab'),
('aagard'),
('aarup');

INSERT INTO SpeciesTags (SpeciesCode, Tag) VALUES 
('ABPA3', 'Sensitive'),
('ABRE', 'Sensitive'),
('ABTH', 'Invasive (non-graminoid)');

INSERT INTO Data_DateRange (StartDate, EndDate, SeasonLength_Months) VALUES 
('2011-01-01', '2017-12-31', 12);

