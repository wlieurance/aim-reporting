-- Text encoding used: System
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table: CodeDescriptions
CREATE TABLE CodeDescriptions (Code TEXT, Description TEXT, SubDescription TEXT);

-- Table: CodeTags
CREATE TABLE CodeTags (Code TEXT, Tag TEXT, Category CHAR, Use BOOLEAN DEFAULT (1), UNIQUE (Code, Tag));

-- Table: Data_DateRange
CREATE TABLE Data_DateRange (StartDate DATETIME, EndDate DATETIME, SeasonLength_Months INTEGER);

-- Table: Data_DBconfig
CREATE TABLE Data_DBconfig (VariableName TEXT, Value TEXT, PossibleValues TEXT);

-- Table: Duration_GrowthHabit_Combinations
CREATE TABLE Duration_GrowthHabit_Combinations (GrowthHabit CHAR, DurationTag CHAR, Use INTEGER DEFAULT (1), Category CHAR);

-- Table: EcositeGroups
CREATE TABLE EcositeGroups (EcolSiteIDStd TEXT PRIMARY KEY, EcolSiteID TEXT, EcolSiteVeg TEXT, EcolSiteName TEXT, EcolsiteType TEXT, MLRA TEXT, EcoGroup TEXT, Subgroup TEXT, GroupType TEXT, Acreage REAL, Model BOOLEAN, DraftStatus TEXT);

-- Table: Exports
CREATE TABLE Exports (Category TEXT, DataType TEXT, Scale TEXT, ObjectName TEXT, ExportName TEXT);

-- Table: HitCategories
CREATE TABLE HitCategories (HitCategory CHAR PRIMARY KEY, Type CHAR);

-- Table: LI_SizeClasses
CREATE TABLE LI_SizeClasses (StartOperator TEXT CHECK (StartOperator IN ('>', '>=')) NOT NULL, StartLimit INTEGER NOT NULL, EndOperator TEXT CHECK (EndOperator IN ('<', '<=')), EndLimit INTEGER);

-- Table: Methods
CREATE TABLE Methods (MethodName TEXT PRIMARY KEY, Use BOOLEAN DEFAULT (1), FormNumber INTEGER);

-- Table: NonSpeciesCodes
CREATE TABLE NonSpeciesCodes (Code TEXT PRIMARY KEY, Name TEXT, Description TEXT, Cateogry TEXT);

-- Table: PlotTags
CREATE TABLE PlotTags (PlotKey TEXT, Tag TEXT, Weight REAL DEFAULT (1), PRIMARY KEY (PlotKey, Tag));

-- Table: QAQC_Queries
CREATE TABLE QAQC_Queries (QueryOrder REAL, QueryName TEXT, Method TEXT, Function TEXT, Description TEXT, DescriptionSub TEXT, ExportID TEXT, Field TEXT, CorrectValue TEXT, use_check BOOLEAN NOT NULL DEFAULT (1));

-- Table: SeasonDefinition
CREATE TABLE SeasonDefinition (SeasonStart DATETIME, SeasonEnd DATETIME, SeasonLabel TEXT);

-- Table: SoilSeries
CREATE TABLE SoilSeries (SeriesName TEXT PRIMARY KEY);

-- Table: SoilStab_Codes
CREATE TABLE SoilStab_Codes (Code TEXT PRIMARY KEY, Duration TEXT, Description TEXT, Category TEXT);

-- Table: SpeciesTags
CREATE TABLE SpeciesTags (SpeciesCode CHAR, Tag CHAR, PRIMARY KEY (SpeciesCode, Tag));

-- Table: SR_Raw
CREATE TABLE SR_Raw (RecKey TEXT, subPlotID INTEGER, SpeciesCode TEXT, PRIMARY KEY (RecKey ASC, subPlotID ASC, SpeciesCode ASC));

-- Table: TablesToImport
CREATE TABLE TablesToImport (TableName TEXT PRIMARY KEY NOT NULL UNIQUE, AppendDoNotUse BOOL, ImportTable TEXT, FieldString TEXT, DeleteTable BOOLEAN DEFAULT (1));

-- Table: UnitConversion
CREATE TABLE UnitConversion (MeasureChoice TEXT, Units TEXT, ConvertFactor REAL, FinalUnits TEXT);

-- Table: tblCanopyGapDetail
CREATE TABLE tblCanopyGapDetail (RecKey TEXT NOT NULL, Species TEXT NOT NULL, StartPos REAL NOT NULL, Length REAL, Chkbox BOOLEAN, PRIMARY KEY (RecKey, Species, StartPos));

-- Table: tblCanopyGapHeader
CREATE TABLE tblCanopyGapHeader (LineKey TEXT, RecKey TEXT PRIMARY KEY NOT NULL, DateModified DATETIME, FormType TEXT, FormDate DATETIME, Observer TEXT, Recorder TEXT, DataEntry TEXT, DataErrorChecking TEXT, Measure INTEGER, LineLengthAmount INTEGER, CheckboxLabel TEXT, Notes TEXT, DataEntryDirection INTEGER, PositionUOM TEXT, MinLength REAL);

-- Table: tblEcolSites
CREATE TABLE tblEcolSites (EcolSite TEXT, SiteName TEXT, DateModified DATETIME DEFAULT NULL, DateComplete DATETIME DEFAULT NULL, PRIMARY KEY (EcolSite));

-- Table: tblGapDetail
CREATE TABLE tblGapDetail (RecKey TEXT NOT NULL, SeqNo INTEGER NOT NULL, RecType TEXT, GapStart TEXT, GapEnd TEXT, PRIMARY KEY (RecKey, SeqNo));

-- Table: tblGapHeader
CREATE TABLE tblGapHeader (LineKey TEXT, RecKey TEXT PRIMARY KEY NOT NULL, DateModified DATETIME, FormType TEXT, FormDate DATETIME, Observer TEXT, Recorder TEXT, DataEntry TEXT, DataErrorChecking TEXT, Measure INTEGER, LineLengthAmount INTEGER, GapMin REAL, GapData TEXT, Perennials BOOLEAN, AnnualGrasses BOOLEAN, AnnualForbs BOOLEAN, Other BOOLEAN, Notes TEXT, NoCanopyGaps BOOLEAN, NoBasalGaps BOOLEAN);

-- Table: tblLICDetail
CREATE TABLE tblLICDetail (RecKey TEXT NOT NULL, Species TEXT NOT NULL, StartPos REAL NOT NULL, EndPos REAL, Height REAL, Chkbox BOOLEAN, PRIMARY KEY (RecKey, Species, StartPos));

-- Table: tblLICHeader
CREATE TABLE tblLICHeader (LineKey TEXT, RecKey TEXT PRIMARY KEY NOT NULL, DateModified DATETIME, FormType TEXT, FormDate DATETIME, Observer TEXT, Recorder TEXT, DataEntry TEXT, DataErrorChecking TEXT, Measure INTEGER, LineLengthAmount INTEGER, HeightUOM TEXT, CheckboxLabel TEXT, Notes TEXT, MinNonInterceptGap TEXT, MinLengthCanopySeg TEXT, MaxPctNonCanopy TEXT, PositionUOM TEXT);

-- Table: tblLines
CREATE TABLE tblLines (PlotKey TEXT, LineKey TEXT PRIMARY KEY NOT NULL, DateModified DATETIME, LineID TEXT, Azimuth INTEGER, ElevationType INTEGER, NorthType INTEGER, NorthingStart REAL, EastingStart REAL, ElevationStart REAL, NorthingEnd REAL, EastingEnd REAL, ElevationEnd REAL, LatitudeStart REAL, LongitudeStart REAL, LatitudeEnd REAL, LongitudeEnd REAL);

-- Table: tblLPIDetail
CREATE TABLE tblLPIDetail (RecKey TEXT NOT NULL, PointLoc REAL NOT NULL, PointNbr INTEGER, TopCanopy TEXT, Lower1 TEXT, Lower2 TEXT, Lower3 TEXT, Lower4 TEXT, Lower5 TEXT, Lower6 TEXT, Lower7 TEXT, SoilSurface TEXT, HeightTop TEXT, ChkboxTop BOOLEAN, ChkboxLower1 BOOLEAN, ChkboxLower2 BOOLEAN, ChkboxLower3 BOOLEAN, ChkboxLower4 BOOLEAN, ChkboxLower5 BOOLEAN, ChkboxLower6 BOOLEAN, ChkboxLower7 BOOLEAN, ChkboxSoil BOOLEAN, ChkboxWoody BOOLEAN, ChkboxHerbaceous BOOLEAN, HeightLower1 TEXT, HeightLower2 TEXT, HeightLower3 TEXT, HeightLower4 TEXT, HeightLower5 TEXT, HeightLower6 TEXT, HeightLower7 TEXT, HeightSurface TEXT, HeightWoody TEXT, HeightHerbaceous TEXT, ShrubShape TEXT, SpeciesWoody TEXT, SpeciesHerbaceous TEXT, PRIMARY KEY (RecKey, PointLoc));

-- Table: tblLPIHeader
CREATE TABLE tblLPIHeader (LineKey TEXT, RecKey TEXT PRIMARY KEY NOT NULL, DateModified DATETIME, FormType TEXT, FormDate DATETIME, Observer TEXT, Recorder TEXT, DataEntry TEXT, DataErrorChecking TEXT, Measure INTEGER, LineLengthAmount INTEGER, SpacingIntervalAmount REAL, SpacingType TEXT, Notes TEXT, HeightOption TEXT, HeightUOM TEXT, CheckboxLabel TEXT, ShowCheckbox BOOLEAN, HeightNoneOption BOOLEAN, WoodyHerbHeights BOOLEAN, LayerHeights BOOLEAN, RapidMode BOOLEAN, ShowShrubShape BOOLEAN);

-- Table: tblMaintQualIndicators
CREATE TABLE tblMaintQualIndicators (Seq INTEGER PRIMARY KEY  DEFAULT NULL, Description TEXT (255) DEFAULT NULL, SSS NUMERIC DEFAULT NULL, HF NUMERIC DEFAULT NULL, BI NUMERIC DEFAULT NULL);

-- Table: tblMaintQualRatings
CREATE TABLE tblMaintQualRatings (Code TEXT (50) PRIMARY KEY  DEFAULT NULL, Description TEXT (255) DEFAULT NULL, Rating INTEGER);

-- Table: tblMaintSoilStability
CREATE TABLE tblMaintSoilStability (Code TEXT (50) PRIMARY KEY  DEFAULT NULL, Description TEXT (50) DEFAULT NULL, CommonName TEXT (255) DEFAULT NULL, SortSeq INTEGER);

-- Table: tblMaintSoilTexture
CREATE TABLE tblMaintSoilTexture (Code TEXT (50) PRIMARY KEY  DEFAULT NULL, Description TEXT (50) DEFAULT NULL, SortSeq INTEGER);

-- Table: tblMaintStructureShapes
CREATE TABLE tblMaintStructureShapes (Abbrev TEXT (50) PRIMARY KEY, Description TEXT (50), SortSeq INTEGER);

-- Table: tblMaintSurfaceSoilProperties
CREATE TABLE tblMaintSurfaceSoilProperties (Abbrev TEXT (50) PRIMARY KEY, Description TEXT (255), Sort INTEGER);

-- Table: tblPeople
CREATE TABLE tblPeople (FullName TEXT PRIMARY KEY NOT NULL, Organization TEXT, Address TEXT, PhoneNbr TEXT, Email TEXT, Recorder BOOLEAN, Observer BOOLEAN, LandManager BOOLEAN, Designer BOOLEAN, FieldCrewLeader BOOLEAN, DataEntry BOOLEAN, DataErrorChecking BOOLEAN);

-- Table: tblPlantDenDetail
CREATE TABLE tblPlantDenDetail (RecKey TEXT NOT NULL, Quadrat INTEGER NOT NULL, SpeciesCode TEXT NOT NULL, SubQuadSize REAL NOT NULL, SubQuadSizeUOM TEXT, Class1total INTEGER, Class2total INTEGER, Class3total INTEGER, Class4total INTEGER, Class5total INTEGER, Class6total INTEGER, Class7total INTEGER, Class8total INTEGER, Class9total INTEGER, PRIMARY KEY (RecKey, Quadrat, SpeciesCode, SubQuadSize));

-- Table: tblPlantDenHeader
CREATE TABLE tblPlantDenHeader (LineKey TEXT, RecKey TEXT PRIMARY KEY NOT NULL, DateModified DATETIME, FormType TEXT, FormDate DATETIME, Observer TEXT, Recorder TEXT, DataEntry TEXT, DataErrorChecking TEXT, Measure INTEGER, LineLengthAmount INTEGER, numQuadrats INTEGER, Notes TEXT, SpeciesSearchedFor TEXT);

-- Table: tblPlantProdDetail
CREATE TABLE tblPlantProdDetail (RecKey TEXT, DetailKey TEXT, SpeciesCode TEXT, SubPlotSize REAL, SubPlotUOM TEXT, SizeCF REAL, WtMeas TEXT, WtMethod TEXT, Sub1Wt REAL, Sub2Wt REAL, Sub3Wt REAL, Sub4Wt REAL, Sub5Wt REAL, Sub6Wt REAL, Sub7Wt REAL, Sub8Wt REAL, Sub9Wt REAL, Sub10Wt REAL, Sub11Wt REAL, Sub12Wt REAL, Sub13Wt REAL, Sub14Wt REAL, Sub15Wt REAL, Sub16Wt REAL, Sub17Wt REAL, Sub18Wt REAL, Sub19Wt REAL, Sub20Wt REAL, Sub1Clip BOOLEAN, Sub2Clip BOOLEAN, Sub3Clip BOOLEAN, Sub4Clip BOOLEAN, Sub5Clip BOOLEAN, Sub6Clip BOOLEAN, Sub7Clip BOOLEAN, Sub8Clip BOOLEAN, Sub9Clip BOOLEAN, Sub10Clip BOOLEAN, Sub11Clip BOOLEAN, Sub12Clip BOOLEAN, Sub13Clip BOOLEAN, Sub14Clip BOOLEAN, Sub15Clip BOOLEAN, Sub16Clip BOOLEAN, Sub17Clip BOOLEAN, Sub18Clip BOOLEAN, Sub19Clip BOOLEAN, Sub20Clip BOOLEAN, TotalWtUnits REAL, WtUnitWt REAL, ClipWt1 REAL, ClipWt2 REAL, ClipWt3 REAL, ClipWt4 REAL, ClipWt5 REAL, ClipWt6 REAL, ClipWt7 REAL, ClipWt8 REAL, ClipWt9 REAL, ClipWt10 REAL, ClipWt11 REAL, ClipWt12 REAL, ClipWt13 REAL, ClipWt14 REAL, ClipWt15 REAL, ClipWt16 REAL, ClipWt17 REAL, ClipWt18 REAL, ClipWt19 REAL, ClipWt20 REAL, ADWAdj TEXT, UtilAdj TEXT, GwthAdj TEXT, WthrAdj TEXT, ClippedEstWt REAL, ClippedClipWt REAL, ClipEstCF REAL, TotalWt REAL, TotalWtHectare REAL, PRIMARY KEY (DetailKey, SpeciesCode));

-- Table: tblPlantProdHeader
CREATE TABLE tblPlantProdHeader (PlotKey TEXT, RecKey TEXT, DateModified DATETIME, FormType TEXT, FormDate DATETIME, LineKey TEXT, Measure INTEGER, LineLengthAmount INTEGER, Observer TEXT, Recorder TEXT, DataEntry TEXT, DataErrorChecking TEXT, numSubPlots INTEGER, SubPlotLocs TEXT, Notes TEXT, TotalProd REAL, SubPlot1Exp BOOLEAN, SubPlot2Exp BOOLEAN, SubPlot3Exp BOOLEAN, SubPlot4Exp BOOLEAN, SubPlot5Exp BOOLEAN, SubPlot6Exp BOOLEAN, SubPlot7Exp BOOLEAN, SubPlot8Exp BOOLEAN, SubPlot9Exp BOOLEAN, SubPlot10Exp BOOLEAN, SubPlot11Exp BOOLEAN, SubPlot12Exp BOOLEAN, SubPlot13Exp BOOLEAN, SubPlot14Exp BOOLEAN, SubPlot15Exp BOOLEAN, SubPlot16Exp BOOLEAN, SubPlot17Exp BOOLEAN, SubPlot18Exp BOOLEAN, SubPlot19Exp BOOLEAN, SubPlot20Exp BOOLEAN, TotalProdHectare REAL, SubPlot1NotSamp BOOLEAN, SubPlot2NotSamp BOOLEAN, SubPlot3NotSamp BOOLEAN, SubPlot4NotSamp BOOLEAN, SubPlot5NotSamp BOOLEAN, SubPlot6NotSamp BOOLEAN, SubPlot7NotSamp BOOLEAN, SubPlot8NotSamp BOOLEAN, SubPlot9NotSamp BOOLEAN, SubPlot10NotSamp BOOLEAN, SubPlot11NotSamp BOOLEAN, SubPlot12NotSamp BOOLEAN, SubPlot13NotSamp BOOLEAN, SubPlot14NotSamp BOOLEAN, SubPlot15NotSamp BOOLEAN, SubPlot16NotSamp BOOLEAN, SubPlot17NotSamp BOOLEAN, SubPlot18NotSamp BOOLEAN, SubPlot19NotSamp BOOLEAN, SubPlot20NotSamp BOOLEAN, TotNotSamp INTEGER, PRIMARY KEY (RecKey));

-- Table: tblPlotFormDefaults
CREATE TABLE tblPlotFormDefaults (PlotKey TEXT PRIMARY KEY, PlantDenNumQuadrats INTEGER, PlantDenClass1 TEXT, PlantDenClass2 TEXT, PlantDenClass3 TEXT, PlantDenClass4 TEXT, PlantDenClass5 TEXT, PlantDenClass6 TEXT, PlantDenClass7 TEXT, PlantDenClass8 TEXT, PlantDenClass9 TEXT);

-- Table: tblPlotHistory
CREATE TABLE tblPlotHistory (PlotKey TEXT, RecKey TEXT PRIMARY KEY, RecType TEXT, DateRecorded DATETIME, DateModified DATETIME, PlotCustom1Data TEXT, PlotCustom2Data TEXT, PlotCustom3Data TEXT, PlotCustom4Data TEXT, ESD_PctGrassCover NUMERIC, ESD_ResourceRetentionClass NUMERIC, ESD_bareGapPatchSize NUMERIC, ESD_grassPatchSize NUMERIC, ESD_SoilRedistributionClass TEXT, ESD_ResourceRetentionNotes TEXT, ESD_Pedoderm_Class TEXT, ESD_PedodermMod TEXT, ESD_SurfaceNotes TEXT, ESD_Compaction BOOLEAN, ESD_SubsurfaceNotes TEXT, ESD_StateWithinEcologicalSite TEXT, ESD_CommunityWithinState TEXT, ESD_CommunityDescription TEXT, ESD_Root_density TEXT, ESD_Root_Depth NUMERIC, ESD_Root_Notes TEXT, Observers TEXT, Methods TEXT, DataEntry TEXT, DataEntryDate DATE, ErrorCheck TEXT, ErrorCheckDate DATE, RecentWeatherPast12 TEXT, RecentWeatherPrevious12 TEXT, PrecipUOM TEXT, PrecipPast12 TEXT, PrecipPrevious12 TEXT, DataSource TEXT, Photo1Num TEXT, Photo2Num TEXT, Photo3Num TEXT, Photo4Num TEXT, Photo5Num TEXT, Photo6Num TEXT, Photo1Desc TEXT, Photo2Desc TEXT, Photo3Desc TEXT, Photo4Desc TEXT, Photo5Desc TEXT, Photo6Desc TEXT, Rills TEXT, Gullies TEXT, Pedestals TEXT, Deposition TEXT, WaterFlow TEXT, SheetErosion TEXT, Other TEXT, MgtHistory TEXT, Wildlife TEXT, Livestock TEXT, OffSite TEXT, Disturbances TEXT);

-- Table: tblPlotNotes
CREATE TABLE tblPlotNotes (CommentID TEXT PRIMARY KEY NOT NULL, PlotKey TEXT, NoteDate DATETIME, Recorder TEXT, Note TEXT);

-- Table: tblPlots
CREATE TABLE tblPlots (SiteKey TEXT, PlotKey TEXT PRIMARY KEY NOT NULL, DateModified DATETIME, PlotID TEXT, genericPlot BOOLEAN, EstablishDate DATETIME, State TEXT, County TEXT, Directions TEXT, AvgPrecip REAL, AvgPrecipUOM TEXT, EcolSite TEXT, Soil TEXT, ParentMaterial TEXT, Slope REAL, Aspect TEXT, ESD_SlopeShape TEXT, LandscapeType TEXT, LandscapeTypeSecondary TEXT, MgtUnit TEXT, GPSCoordSys TEXT, Datum TEXT, Zone TEXT, Easting REAL, Northing REAL, Elevation REAL, ElevationType INTEGER, RecentWeatherPast12 TEXT, RecentWeatherPrevious12 TEXT, DisturbWildfire BOOLEAN, DisturbRodents BOOLEAN, DisturbMammals BOOLEAN, DisturbWater BOOLEAN, DisturbWind BOOLEAN, DisturbWaterSoilDep BOOLEAN, DisturbWindSoilDep BOOLEAN, DisturbUndgroundUtils BOOLEAN, DisturbOverhdTransLines BOOLEAN, DisturbOther BOOLEAN, DisturbOtherDesc TEXT, WildlifeUse TEXT, MgtHistory TEXT, OffsiteInfluences TEXT, Comments TEXT, SpeciesList TEXT, DensityList TEXT, ESD_Series TEXT, MapUnitComponent TEXT, SoilPhase TEXT, ESD_MLRA TEXT, ESD_CRA TEXT, ESD_Region TEXT, ESD_Investigators TEXT, ESD_Bedrock TEXT, ESD_MajorLandform TEXT, ESD_ComponentLandform TEXT, HillslopeType TEXT, ESD_GeomorphicComp TEXT, ESD_RunIn_RunOff TEXT, ESD_SlopeComplexity TEXT, ESD_LitterClass TEXT, ESD_BiologicalCrustClass TEXT, ESD_ParticleSizeClass TEXT, ESD_Mineralogy TEXT, ESD_SoilTempRegime TEXT, ESD_DepthClass TEXT, ESD_Subgroup TEXT, ESD_Greatgroup TEXT, ESD_Reaction TEXT, ESD_SoilMoistureRegime TEXT, ESD_CationExchangeActivityClass TEXT, ESD_Epipedon TEXT, ESD_Subsurface_features TEXT, ESD_Depth_to_root_horizon REAL, ESD_Type_root_horizon TEXT, ESD_Horizon_notes TEXT, ESD_TrackingID TEXT, EcolSite_Assoc1 TEXT, EcolSite_Assoc2 TEXT, EcolSite_Assoc3 TEXT, EcolSite_Similar1 TEXT, EcolSite_Similar2 TEXT, EcolSite_Similar3 TEXT, EcolSite_Notes TEXT, EcolSite_Lookup1 TEXT, EcolSite_Lookup2 TEXT, EcolSite_Lookup3 TEXT, EcolSite_Text1 TEXT, EcolSite_Text2 TEXT, EcolSite_Text3 TEXT, ESD_RecentWeatherPast12 TEXT, ESD_ErosionPatternClass TEXT, Longitude REAL, Latitude REAL, CoordLabel1 TEXT, CoordDistance1 TEXT, Longitude1 REAL, Latitude1 REAL, Easting1 REAL, Northing1 REAL, CoordLabel2 TEXT, CoordDistance2 TEXT, Longitude2 REAL, Latitude2 REAL, Easting2 REAL, Northing2 REAL, CoordLabel3 TEXT, CoordDistance3 TEXT, Longitude3 REAL, Latitude3 REAL, Easting3 REAL, Northing3 REAL);

-- Table: tblPlotTags
CREATE TABLE tblPlotTags (PlotKey TEXT, Tag TEXT, PRIMARY KEY (PlotKey, Tag));

-- Table: tblQualDetail
CREATE TABLE tblQualDetail (RecKey TEXT, Seq INTEGER, Rating REAL, SSSWt REAL, SSSVxW REAL, HFWt REAL, HFVxW REAL, BIWt REAL, BIVxW REAL, Comment TEXT, PRIMARY KEY (RecKey, Seq));

-- Table: tblQualHeader
CREATE TABLE tblQualHeader (PlotKey TEXT, RecKey TEXT PRIMARY KEY NOT NULL, DateModified DATETIME, FormDate DATETIME, Observer TEXT, Recorder TEXT, EcolSite TEXT, RefSheetType INTEGER, RefSheetDate DATETIME, RefSheetAuthor TEXT, DateDownloaded DATETIME, AttrEvalMethod INTEGER, WeightsSource TEXT, AerialPhoto TEXT, SitePhotoTaken BOOLEAN, EvalAreaSize TEXT, RepCriteria TEXT, CompositionBase INTEGER, SSSVxWRatingFinal TEXT, HFVxWRatingFinal TEXT, BIVxWRatingFinal TEXT, CommentSSS TEXT, CommentHF TEXT, CommentBI TEXT);

-- Table: tblSites
CREATE TABLE tblSites (SiteKey TEXT PRIMARY KEY NOT NULL, DateModified DATETIME, SiteID TEXT, SiteName TEXT, Ownership TEXT, ContactName TEXT, MgtObject TEXT, MonObject TEXT, Notes TEXT);

-- Table: tblSoilPitHorizons
CREATE TABLE tblSoilPitHorizons (SoilKey TEXT, HorizonKey TEXT PRIMARY KEY NOT NULL, HorizonDepthUpper TEXT, DepthMeasure TEXT, Texture TEXT, RockFragments REAL, Effer TEXT, HorizonColorDry TEXT, HorizonColorMoist TEXT, StructGrade TEXT, StructShape TEXT, Nomenclature TEXT, HorizonDepthLower TEXT, ESD_Horizon TEXT, ESD_HorizonModifier TEXT, ESD_FragVolPct TEXT, ESD_FragmentType TEXT, ESD_PetrocalcicRubble BOOLEAN, ESD_Gypsic BOOLEAN, ESD_PctClay REAL, ESD_Hue TEXT, ESD_Value TEXT, ESD_Chroma REAL, ESD_Color TEXT, ESD_Grade TEXT, ESD_Size TEXT, ESD_Structure TEXT, ESD_StructQual TEXT, ESD_Grade2 TEXT, ESD_Size2 TEXT, ESD_Structure2 TEXT, ESD_RuptureResistance TEXT, ESD_ClayFilm BOOLEAN, ESD_CarbonateStage INTEGER, ESD_CaCO3EquivPct REAL, ESD_EC REAL, ESD_pH REAL, ESD_GypsumPct REAL, ESD_NAabsorptionRatio REAL, ESD_Notes TEXT, ESD_PSAPctSand REAL, ESD_PSAPctSilt REAL, ESD_PSAPctClay REAL, ESD_GravelClassPctFine REAL, ESD_GravelClassPctMed REAL, ESD_GravelClassPctCoarse REAL, ESD_GravelCarbonateCoatPct REAL, ESD_FragmentRoundness TEXT, ESD_RootSize TEXT, ESD_RootQty TEXT, ESD_PoresSize TEXT, ESD_PoresQty TEXT, ESD_SandFractPctVeryFine REAL, ESD_SandFractPctFine REAL, ESD_SandFractPctMed REAL, ESD_SandFractPctCoarse REAL, ESD_SandFractPctVeryCoarse REAL, ESD_FragVolPct2 TEXT, ESD_FragmentType2 TEXT, ESD_FragVolPct3 TEXT, ESD_FragmentType3 TEXT, ESD_PctSand REAL, ESD_LabGravelPctFine REAL, ESD_LabGravelPctMed REAL, ESD_LabGravelPctCoarse REAL);

-- Table: tblSoilPits
CREATE TABLE tblSoilPits (PlotKey TEXT, SoilKey TEXT PRIMARY KEY NOT NULL, Observer TEXT, PitDesc TEXT, SoilDepthUpper TEXT, SoilDepthLower TEXT, SurfTexture TEXT, RockFragments INTEGER, SurfEffer TEXT, ColorDry TEXT, ColorMoist TEXT, DepthMeasure TEXT, Northing REAL, Easting REAL, Elevation REAL, ElevationType INTEGER, Notes TEXT, Latitude REAL, Longitude REAL, DateRecorded DATETIME);

-- Table: tblSoilStabDetail
CREATE TABLE tblSoilStabDetail (RecKey TEXT, BoxNum INTEGER, Line1 TEXT, Line2 TEXT, Line3 TEXT, Line4 TEXT, Line5 TEXT, Line6 TEXT, Pos1 TEXT, Pos2 TEXT, Pos3 TEXT, Pos4 TEXT, Pos5 TEXT, Pos6 TEXT, Pos7 TEXT, Pos8 TEXT, Pos9 TEXT, Pos10 TEXT, Pos11 TEXT, Pos12 TEXT, Pos13 TEXT, Pos14 TEXT, Pos15 TEXT, Pos16 TEXT, Pos17 TEXT, Pos18 TEXT, Veg1 TEXT, Veg2 TEXT, Veg3 TEXT, Veg4 TEXT, Veg5 TEXT, Veg6 TEXT, Veg7 TEXT, Veg8 TEXT, Veg9 TEXT, Veg10 TEXT, Veg11 TEXT, Veg12 TEXT, Veg13 TEXT, Veg14 TEXT, Veg15 TEXT, Veg16 TEXT, Veg17 TEXT, Veg18 TEXT, Rating1 TEXT, Rating2 TEXT, Rating3 TEXT, Rating4 TEXT, Rating5 TEXT, Rating6 TEXT, Rating7 TEXT, Rating8 TEXT, Rating9 TEXT, Rating10 TEXT, Rating11 TEXT, Rating12 TEXT, Rating13 TEXT, Rating14 TEXT, Rating15 TEXT, Rating16 TEXT, Rating17 TEXT, Rating18 TEXT, Hydro1 BOOLEAN, Hydro2 BOOLEAN, Hydro3 BOOLEAN, Hydro4 BOOLEAN, Hydro5 BOOLEAN, Hydro6 BOOLEAN, Hydro7 BOOLEAN, Hydro8 BOOLEAN, Hydro9 BOOLEAN, Hydro10 BOOLEAN, Hydro11 BOOLEAN, Hydro12 BOOLEAN, Hydro13 BOOLEAN, Hydro14 BOOLEAN, Hydro15 BOOLEAN, Hydro16 BOOLEAN, Hydro17 BOOLEAN, Hydro18 BOOLEAN, In1 TEXT, In2 TEXT, In3 TEXT, In4 TEXT, In5 TEXT, In6 TEXT, In7 TEXT, In8 TEXT, In9 TEXT, In10 TEXT, In11 TEXT, In12 TEXT, In13 TEXT, In14 TEXT, In15 TEXT, In16 TEXT, In17 TEXT, In18 TEXT, Dip1 TEXT, Dip2 TEXT, Dip3 TEXT, Dip4 TEXT, Dip5 TEXT, Dip6 TEXT, Dip7 TEXT, Dip8 TEXT, Dip9 TEXT, Dip10 TEXT, Dip11 TEXT, Dip12 TEXT, Dip13 TEXT, Dip14 TEXT, Dip15 TEXT, Dip16 TEXT, Dip17 TEXT, Dip18 TEXT, PRIMARY KEY (RecKey, BoxNum));

-- Table: tblSoilStabHeader
CREATE TABLE tblSoilStabHeader (PlotKey TEXT, RecKey TEXT PRIMARY KEY NOT NULL, DateModified DATETIME, FormType TEXT, FormDate DATETIME, LineKey TEXT, Observer TEXT, Recorder TEXT, DataEntry TEXT, DataErrorChecking TEXT, SoilStabSubSurface INTEGER, SoilStabTimeInterval INTEGER, Notes TEXT, SoilStabLimitedVeg BOOLEAN);

-- Table: tblSpecies
CREATE TABLE tblSpecies (SpeciesCode TEXT PRIMARY KEY UNIQUE NOT NULL, ScientificName TEXT, CommonName TEXT, Family TEXT, synonymOf TEXT, GrowthHabitCode TEXT, Duration TEXT, Stabilizing BOOLEAN DEFAULT (0), Invasive BOOLEAN DEFAULT (0), "Group" TEXT, CodeType TEXT) WITHOUT ROWID;

-- Table: tblSpeciesGrowthHabit
CREATE TABLE tblSpeciesGrowthHabit (Code TEXT PRIMARY KEY  NOT NULL , GrowthHabit TEXT, GrowthHabitSub TEXT);

-- Table: tblSpecRichDetail
CREATE TABLE tblSpecRichDetail (RecKey TEXT, subPlotID INTEGER, subPlotDesc TEXT, SpeciesCount INTEGER, SpeciesList TEXT, PRIMARY KEY (RecKey, subPlotID));

-- Table: tblSpecRichHeader
CREATE TABLE tblSpecRichHeader (LineKey TEXT, RecKey TEXT, DateModified DATETIME, FormType TEXT, FormDate DATETIME, Observer TEXT, Recorder TEXT, DataEntry TEXT, DataErrorChecking TEXT, SpecRichMethod INTEGER, SpecRichMeasure INTEGER, SpecRichNbrSubPlots INTEGER, SpecRich1Container BOOLEAN, SpecRich1Shape INTEGER, SpecRich1Dim1 REAL, SpecRich1Dim2 REAL, SpecRich1Area REAL, SpecRich2Container BOOLEAN, SpecRich2Shape INTEGER, SpecRich2Dim1 REAL, SpecRich2Dim2 REAL, SpecRich2Area REAL, SpecRich3Container BOOLEAN, SpecRich3Shape INTEGER, SpecRich3Dim1 REAL, SpecRich3Dim2 REAL, SpecRich3Area REAL, SpecRich4Container BOOLEAN, SpecRich4Shape INTEGER, SpecRich4Dim1 REAL, SpecRich4Dim2 REAL, SpecRich4Area REAL, SpecRich5Container BOOLEAN, SpecRich5Shape INTEGER, SpecRich5Dim1 REAL, SpecRich5Dim2 REAL, SpecRich5Area REAL, SpecRich6Container BOOLEAN, SpecRich6Shape INTEGER, SpecRich6Dim1 REAL, SpecRich6Dim2 REAL, SpecRich6Area REAL, Notes TEXT, PRIMARY KEY (RecKey));



--Create Indexes

-- Index: tblEcolSites_EcolSite
CREATE INDEX tblEcolSites_EcolSite ON tblEcolSites (EcolSite ASC);

-- Index: tblMaintSoilStability_Phenology
CREATE UNIQUE INDEX tblMaintSoilStability_Phenology ON tblMaintSoilStability (Code ASC);

-- Index: tblMaintSoilStability_PhenologyCode
CREATE INDEX tblMaintSoilStability_PhenologyCode ON tblMaintSoilStability (Description ASC);

-- Index: tblMaintSoilTexture_Phenology
CREATE UNIQUE INDEX tblMaintSoilTexture_Phenology ON tblMaintSoilTexture (Code ASC);

-- Index: tblMaintSoilTexture_PhenologyCode
CREATE INDEX tblMaintSoilTexture_PhenologyCode ON tblMaintSoilTexture (Description ASC);

-- Index: tblMaintStructureShapes_Abbrev
CREATE UNIQUE INDEX tblMaintStructureShapes_Abbrev ON tblMaintStructureShapes (Abbrev ASC);

-- Index: tblMaintStructureShapes_Description
CREATE UNIQUE INDEX tblMaintStructureShapes_Description ON tblMaintStructureShapes (Description ASC);

-- Index: tblMaintStructureShapes_SortSeq
CREATE UNIQUE INDEX tblMaintStructureShapes_SortSeq ON tblMaintStructureShapes (SortSeq ASC);


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
