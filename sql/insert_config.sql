-- Text encoding used: System
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table: CodeDescriptions
INSERT INTO CodeDescriptions (Code, Description, SubDescription) VALUES 
('N', 'None', 'Nothing in the Top Canopy (outdated)'), 
('R', 'Rock Fragment', 'Rock fragments 5 mm + (alternative to classes)'), 
('GR', 'Gravel', 'Rock fragments 5 - 76 mm'), 
('CB', 'Cobble', 'Rock fragments > 76 - 250 mm'), 
('ST', 'Stone', 'Rock fragments> 250 - 600 mm'), 
('BY', 'Boulder', 'Rock fragments > 600 mm'), 
('BR', 'Bedrock', NULL), 
('D', 'Duff', 'Partially decomposed plant litter with no recognizable plant parts'), 
('M', 'Moss', NULL), 
('LC', 'Lichen', 'Lichen on soil (not on Rock)'), 
('W', 'Water', 'IF Soil Surface -> permanent water, IF lower code -> ephemeral water.'), 
('S', 'Soil', 'Indicates bare soil, mineral soil, or soil with no detectable biological crust'), 
('VL', 'Vagrant Lichen', 'Mobile lichen'), 
('EL', 'Embeded Litter', 'Embedded woody litter > 5 mm diamter'), 
('HL', 'Herbaceous Litter', 'Same as ''L'''), 
('DS', 'Deposited Soil', 'Soil deposition overlying a plant base.'), 
('NL', 'Other Litter', 'Litter such as plastic, metal, and decomposing animal matter'), 
('L', 'Litter', 'Herbaceous litter including dung and haybales'), 
('WL', 'Woody Litter', 'Woody or succulent litter > 5 mm diameter');

-- Table: CodeTags
INSERT INTO CodeTags (Code, Tag, Category, Use) VALUES 
('B', 'Ground Cover', 'Ground Cover', 1), 
('L', 'Ground Cover', 'Ground Cover', 1), 
('WL', 'Ground Cover', 'Ground Cover', 1), 
('BY', 'Ground Cover', 'Ground Cover', 1), 
('CB', 'Ground Cover', 'Ground Cover', 1), 
('D', 'Ground Cover', 'Ground Cover', 1), 
('EL', 'Ground Cover', 'Ground Cover', 1), 
('GR', 'Ground Cover', 'Ground Cover', 1), 
('LC', 'Ground Cover', 'Ground Cover', 1), 
('M', 'Ground Cover', 'Ground Cover', 1), 
('R', 'Ground Cover', 'Ground Cover', 1), 
('ST', 'Ground Cover', 'Ground Cover', 1), 
('BR', 'Ground Cover', 'Ground Cover', 1), 
('GR', 'Rock', 'Soil Surface', 1), 
('CB', 'Rock', 'Soil Surface', 1), 
('ST', 'Rock', 'Soil Surface', 1), 
('BY', 'Rock', 'Soil Surface', 1), 
('BR', 'Rock', 'Soil Surface', 1), 
('R', 'Rock', 'Soil Surface', 1), 
('EL', 'All Litter', 'Litter', 1), 
('D', 'All Litter', 'Litter', 1), 
('WL', 'All Litter', 'Litter', 1), 
('L', 'All Litter', 'Litter', 1), 
('HL', 'All Litter', 'Litter', 1), 
('VL', 'All Litter', 'Litter', 1), 
('BR', 'Bedrock', 'Soil Surface', 1), 
('GR', 'Gravel', 'Soil Surface', 1), 
('CB', 'Cobble', 'Soil Surface', 1), 
('ST', 'Stone', 'Soil Surface', 1), 
('BY', 'Boulder', 'Soil Surface', 1), 
('R', 'Rock Fragment', 'Soil Surface', 0), 
('CY', 'Cyanobacteria', 'Soil Surface', 1), 
('D', 'Duff', 'Soil Surface', 1), 
('EL', 'Embedded Litter', 'Soil Surface', 1), 
('LC', 'Lichen Crust', 'Soil Surface', 1), 
('M', 'Moss', 'Soil Surface', 1), 
('W', 'Water', 'Soil Surface', 0), 
('S', 'Soil', 'Soil Surface', 1), 
('B', 'Basal', 'Soil Surface', 1), 
('M', 'Soil Crust', 'Soil Surface', 1), 
('LC', 'Soil Crust', 'Soil Surface', 1), 
('CY', 'Soil Crust', 'Soil Surface', 1), 
('NL', 'All Litter', 'Litter', 1), 
('NL', 'Other Litter', 'Litter', 1), 
('WL', 'Woody Litter', 'Litter', 1), 
('L', 'Herbaceous Litter', 'Litter', 1), 
('HL', 'Herbaceous Litter', 'Litter', 1), 
('L', 'Herbaceous_Woody Litter', 'Litter', 1), 
('HL', 'Herbaceous_Woody Litter', 'Litter', 1), 
('WL', 'Herbaceous_Woody Litter', 'Litter', 1), 
('VL', 'Vagrant Lichen', 'Litter', 1), 
('HL', 'Ground Cover', 'Ground Cover', 1), 
('VL', 'Ground Cover', 'Ground Cover', 1), 
('NL', 'Ground Cover', 'Ground Cover', 1), 
('CY', 'Ground Cover', 'Ground Cover', 1), 
('S', 'Soil_Cyanobacteria', 'Soil Surface', 1), 
('CY', 'Soil_Cyanobacteria', 'Soil Surface', 1), 
('Annual', 'Annual_Biennial', 'Duration', 1), 
('Biennial', 'Annual_Biennial', 'Duration', 1), 
('Annual', 'Annual', 'Duration', 0), 
('Biennial', 'Biennial', 'Duration', 0), 
('Perennial', 'Perennial', 'Duration', 1), 
('Biennial', 'Biennial_Perennial', 'Duration', 0), 
('Perennial', 'Biennial_Perennial', 'Duration', 0), 
('Tree', 'Tree', 'GrowthHabitSub', 1), 
('Shrub', 'Shrub', 'GrowthHabitSub', 0), 
('Sub-Shrub', 'Subshrub', 'GrowthHabitSub', 0), 
('Succulent', 'Succulent', 'GrowthHabitSub', 1), 
('Forb/herb', 'Forb', 'GrowthHabitSub', 1), 
('Graminoid', 'Graminoid', 'GrowthHabitSub', 1), 
('Sedge', 'Graminoid', 'GrowthHabitSub', 1), 
('Sedge', 'Sedge', 'GrowthHabitSub', 0), 
('Shrub', 'Shrub_Subshrub', 'GrowthHabitSub', 1), 
('Sub-Shrub', 'Shrub_Subshrub', 'GrowthHabitSub', 1), 
('Forb/herb', 'Forb_Subshrub', 'GrowthHabitSub', 0), 
('Sub-Shrub', 'Forb_Subshrub', 'GrowthHabitSub', 0), 
('Woody', 'Woody', 'GrowthHabit', 1), 
('Non-woody', 'Non-woody', 'GrowthHabit', 1), 
('Foliar', 'Foliar', 'Foliar', 1), 
('Gap', 'Gap', 'Gap', 1);


-- Table: Data_DBconfig
INSERT INTO Data_DBconfig (VariableName, Value, PossibleValues) 
VALUES ('units', 'metric', 'metric, US customary');

-- Table: Duration_GrowthHabit_Combinations
INSERT INTO Duration_GrowthHabit_Combinations (GrowthHabit, DurationTag, Use, Category) VALUES 
('Tree', 'Perennial', 1, 'GrowthHabitSub'), 
('Shrub', 'Perennial', 1, 'GrowthHabitSub'), 
('Sub-Shrub', 'Perennial', 1, 'GrowthHabitSub'), 
('Succulent', 'Perennial', 1, 'GrowthHabitSub'), 
('Forb/herb', 'Perennial', 1, 'GrowthHabitSub'), 
('Graminoid', 'Perennial', 1, 'GrowthHabitSub'), 
('Sedge', 'Perennial', 1, 'GrowthHabitSub'), 
('Succulent', 'Biennial', 0, 'GrowthHabitSub'), 
('Succulent', 'Annual', 0, 'GrowthHabitSub'), 
('Forb/herb', 'Biennial', 0, 'GrowthHabitSub'), 
('Forb/herb', 'Annual', 0, 'GrowthHabitSub'), 
('Graminoid', 'Annual', 1, 'GrowthHabitSub'), 
('Sedge', 'Annual', 1, 'GrowthHabitSub'), 
('Sagebrush', 'Perennial', 1, 'SpeciesTags'), 
('ShrubNotSagebrush', 'Perennial', 1, 'SpeciesTags'), 
('Sensitive', 'Annual', 1, 'SpeciesTags'), 
('Sensitive', 'Biennial', 1, 'SpeciesTags'), 
('Sensitive', 'Perennial', 1, 'SpeciesTags'), 
('Invasive (graminoid)', 'Annual', 1, 'SpeciesTags'), 
('Invasive (graminoid)', 'Perennial', 1, 'SpeciesTags'), 
('Invasive (non-graminoid)', 'Annual', 1, 'SpeciesTags'), 
('Invasive (non-graminoid)', 'Biennial', 1, 'SpeciesTags'), 
('Invasive (non-graminoid)', 'Perennial', 1, 'SpeciesTags'), 
('Woody', 'Perennial', 1, 'GrowthHabit'), 
('Non-woody', 'Annual', 1, 'GrowthHabit'), 
('Non-woody', 'Biennial', 1, 'GrowthHabit'), 
('Non-woody', 'Perennial', 1, 'GrowthHabit'), 
('Graminoid', 'Biennial', 0, 'GrowthHabitSub'), 
('Sedge', 'Biennial', 0, 'GrowthHabitSub');

-- Table: ExecutionOrder
INSERT INTO ExecutionOrder (RunOrder, Name) VALUES 
(2, 'Cover_Line'), 
(3, 'Dimensions_Line'), 
(1, 'LPI_CanopyLayers_Point_DB_RestrictDates'), 
(4, 'SoilStability_Line');

-- Table: Exports
INSERT INTO Exports (Category, DataType, Scale, ObjectName, ExportName) VALUES 
('Calculation', 'Cover', 'Line', 'Cover_Line', 'Cover_Line'), 
('Calculation', 'Dimension', 'Line', 'Dimensions_Line', 'Dimensions_Line'), 
('Calculation', 'Plant Density', 'Line', 'PD_Line', 'PD_Line'), 
('Calculation', 'Soil Stability', 'Line', 'SoilStab_Line', 'SoilStability_Line'), 
('Calculation', 'Species Richness', 'Line', 'SR_Line', 'SR_Line'), 
('Method', 'Line Intercept', 'Raw', 'LI_Raw_Final', 'LI_Raw'), 
('Method', 'Line-point Intercept', 'Raw', 'LPI_CanopyLayers_Point_DB_RestrictDates', 'LPI_Raw'), 
('Method', 'Plant Density', 'Raw', 'PD_Raw_Final', 'PD_Raw'), 
('Method', 'Soil Stability', 'Raw', 'SoilStab_Raw_Final', 'SAS_Raw'), 
('Method', 'Species Richness', 'Raw', 'SR_Raw_Final', 'SR_Raw'), 
('Method', 'Plot Definition', 'Raw', 'Plot_Definition', 'Plot_Definition'), 
('Method', 'Line Definition', 'Raw', 'Line_Definition', 'Line_Definition'), 
('Method', 'Plot Notes', 'Raw', 'Plot_Notes', 'Plot_Notes'), 
('Method', 'Interpreting Indicators of Rangeland Health', 'Raw', 'IIRH_Raw', 'IIRH_Raw'), 
('Method', 'Soil Pit', 'Raw', 'SoilPit_Raw', 'SoilPit_Raw'), 
('Calculation', 'Dimension', 'Plot', 'Dimensions_Plot', 'Dimensions_Plot'), 
('Calculation', 'Cover', 'Plot', 'Cover_Plot', 'Cover_Plot'), 
('Calculation', 'Plant Density', 'Plot', 'PD_Plot', 'PD_Plot'), 
('Calculation', 'Soil Stability', 'Plot', 'SoilStab_Plot', 'SoilStab_Plot'), 
('Calculation', 'Cover', 'Tag', 'Cover_Tag', 'Cover_Tag'), 
('Calculation', 'Dimension', 'Tag', 'Dimensions_Tag', 'Dimensions_Tag'), 
('Calculation', 'Plant Density', 'Tag', 'PD_Tag', 'PD_Tag'), 
('Calculation', 'Soil Stability', 'Tag', 'SoilStab_Tag', 'SAS_Tag'), 
('Calculation', 'Species Richness', 'Tag', 'SR_Tag', 'SR_Tag'), 
('Calculation', 'Species Richness', 'Plot', 'SR_Plot', 'SR_Plot');

-- Table: HitCategories
INSERT INTO HitCategories (HitCategory, Type) VALUES 
('Bare', 'Surface'), 
('Bare Litter', 'Surface'), 
('Cover', 'Surface'), 
('Any', 'Foliar'), 
('First', 'Foliar'), 
('Basal', 'Foliar'), 
('Height', 'Foliar');

-- Table: InsertViews
INSERT INTO InsertViews (RunOrder, ViewName, InsertTable, ColumnString, ValueString, WhereStatement) VALUES 
(0, 'LPI_Line_IndicatorsCalc', 'Cover_Line', NULL, 'SiteKey, PlotKey, LineKey, RecKey, SiteID, PlotID, LineID, FormDate, Method, LineSize, LineSizeUnits, Duration, IndicatorCategory, Indicator, HitCategory, IndicatorSum, CoverPct, ChkPct', 'HitCategory <> ''Height'''), 
(0, 'LPI_Line_IndicatorsCalc', 'Dimensions_Line', NULL, 'SiteKey, PlotKey, LineKey, RecKey, SiteID, PlotID, LineID, FormDate, Method, LineSize, LineSizeUnits, Duration, IndicatorCategory, Indicator, HitCategory, ''Height'', HeightMean, HeightUnits', 'HeightMean IS NOT NULL'), 
(0, 'LPI_CanopyLayers_Point_DB_RestrictDates_View', 'LPI_CanopyLayers_Point_DB_RestrictDates', NULL, NULL, NULL), 
(1, 'LI_Line_Cover', 'Cover_Line', NULL, NULL, NULL), 
(1, 'LI_Line_Height', 'Dimensions_Line', NULL, NULL, NULL), 
(2, 'LI_Line_Length', 'Dimensions_Line', NULL, NULL, NULL), 
(0, 'SoilStab_Line', 'SoilStability_Line', NULL, NULL, NULL), 
(0, 'SR_Line', 'SpeciesRichness_Line', NULL, NULL, NULL);

-- Table: LI_SizeClasses
INSERT INTO LI_SizeClasses (StartOperator, StartLimit, EndOperator, EndLimit) VALUES 
('>', 0, '<', 25), 
('>=', 25, '<=', 50), 
('>', 50, '<=', 100), 
('>', 100, '<=', 250), 
('>', 250, NULL, NULL);

-- Table: Methods
INSERT INTO Methods (MethodName, Use, FormNumber) VALUES 
('Plot Establishment', 0, 1), 
('Line Establishment', 1, 3), 
('Line-point Intercept', 1, 3), 
('Continuous Line Intercept', 1, 0), 
('Gap Intercept', 1, 3), 
('Plant Density', 1, 3), 
('Species Richness', 1, 1), 
('IIRH', 1, 1), 
('Soil Stability', 1, 1), 
('Soil Pit', 1, 1);

-- Table: NonSpeciesCodes
INSERT INTO NonSpeciesCodes (Code, Name, Description, Cateogry) VALUES 
('N', 'None', 'No top canopy', 'Top'), 
('None', 'None', 'No top canopy', 'Top'), 
('HL', 'Herbaceous Litter', 'Herbaceous litter (including dung and haybales) <= 5 mm diameter', 'Lower'), 
('L', 'Herbaceous Litter', 'Herbaceous litter (including dung and haybales) <= 5 mm diameter', 'Lower'), 
('WL', 'Woody Litter', 'Woody or succulent litter > 5 mm diameter', 'Lower'), 
('NL', 'Other Litter', 'Other litter such as plastic, metal, and decomposing animal matter', 'Lower'), 
('DS', 'Deposited Soil', 'Soil deposition overlying a plant base.', 'Soil Surface'), 
('W', 'Water', 'Water or ice present at the time of measurement. May be permanent or ephemeral.', 'Soil Surface'), 
('VL', 'Vagrant Lichen', 'Lichens that are loose, never attached to any substrate.', 'Lower'), 
('R', 'Rock Fragment', 'Rock fragments > 5 mm, but only when overlying a buried plant base.', 'Soil Surface'), 
('GR', 'Gravel', 'Rock fragments 5 - 76 mm', 'Soil Surface'), 
('CB', 'Cobble', 'Rock fragments 76 - 250 mm', 'Soil Surface'), 
('ST', 'Stone', 'Rock fragments 250 - 600 mm', 'Soil Surface'), 
('BY', 'Boulder', 'Rock fragments > 600 mm', 'Soil Surface'), 
('BR', 'Bedrock', 'Bedrock', 'Soil Surface'), 
('S', 'Soil', 'Indicates bare soil, mineral soil, or soil with no detectable biological crust', 'Soil Surface'), 
('LC', 'Lichen', 'Visible lichen crust attached to soil surface. Record if attached to soil, but not if on rock.', 'Soil Surface'), 
('M', 'Moss', 'Moss', 'Soil Surface'), 
('D', 'Duff', 'Partially decomposed plant litter with no recognizable plant parts.', 'Soil Surface'), 
('CY', 'Cyanobacteria', 'Cyanobacteria', 'Soil Surface'), 
('EL', 'Embedded Litter', 'Embedded woody litter > 5 mm in diameter', 'Soil Surface');

-- Table: SoilStab_Codes
INSERT INTO SoilStab_Codes (Code, Duration, Description, Category) VALUES 
('C', 'Perennial', 'Cover', 'Cover'), 
('F', 'Perennial', 'Forb', 'Cover'), 
('G', 'Perennial', 'Graminoid or graminoid-shrub mix', 'Cover'), 
('M', 'Perennial', 'Root mat', 'Cover'), 
('NC', 'NA or Annual', 'No or annual cover', 'No Cover'), 
('Sh', 'Perennial', 'Shrub', 'Cover'), 
('T', 'Perennial', 'Tree', 'Cover');

-- Table: TablesToImport
INSERT INTO TablesToImport (TableName, AppendDoNotUse, ImportTable, FieldString, DeleteTable) VALUES 
('tblCanopyGapDetail', 0, NULL, NULL, 1), 
('tblCanopyGapHeader', 0, NULL, NULL, 1), 
('tblGapDetail', 0, NULL, NULL, 1), 
('tblGapHeader', 0, NULL, NULL, 1), 
('tblLICDetail', 0, NULL, NULL, 1), 
('tblLICHeader', 0, NULL, NULL, 1), 
('tblLines', 0, NULL, NULL, 1), 
('tblLPIDetail', 0, NULL, NULL, 1), 
('tblLPIHeader', 0, NULL, NULL, 1), 
('tblPeople', 0, NULL, NULL, 1), 
('tblPlantDenDetail', 0, NULL, NULL, 1), 
('tblPlantDenHeader', 0, NULL, NULL, 1), 
('tblPlotNotes', 0, NULL, NULL, 1), 
('tblPlots', 0, NULL, NULL, 1), 
('tblPlotTags', 0, NULL, NULL, 1), 
('tblQualDetail', 0, NULL, NULL, 1), 
('tblQualHeader', 0, NULL, NULL, 1), 
('tblSites', 0, NULL, NULL, 1), 
('tblSoilPitHorizons', 0, NULL, NULL, 1), 
('tblSoilPits', 0, NULL, NULL, 1), 
('tblSoilStabDetail', 0, NULL, NULL, 1), 
('tblSoilStabHeader', 0, NULL, NULL, 1), 
('tblSpecies', 0, NULL, NULL, 1), 
('tblSpeciesGrowthHabit', 0, NULL, NULL, 1), 
('tblSpecRichDetail', 0, NULL, NULL, 1), 
('tblSpecRichHeader', 0, NULL, NULL, 1), 
('tblPlotFormDefaults', 0, NULL, NULL, 1), 
('tblPlantProdHeader', 0, NULL, NULL, 1), 
('tblPlantProdDetail', 0, NULL, NULL, 1), 
('tblSpeciesGeneric', 0, 'tblSpecies', '''generic'' AS CodeType', 0);

-- Table: UnitConversion
INSERT INTO UnitConversion (MeasureChoice, Units, ConvertFactor, FinalUnits) VALUES 
('metric', 'm', 100, 'cm'), 
('metric', 'ft', 30.48, 'cm'), 
('metric', 'cm', 1, 'cm'), 
('metric', 'in', 2.54, 'cm'), 
('US customary', 'm', 39.3701, 'in'), 
('US customary', 'ft', 12, 'in'), 
('US customary', 'cm', 0.393701, 'in'), 
('US customary', 'in', 1, 'in');

COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
