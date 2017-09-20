-- Text encoding used: System
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

--Update tblSpecies to define CodeType as genus
UPDATE tblSpecies
   SET CodeType = 'genus'
 WHERE CodeType IS NULL AND 
       (ScientificName IS NOT NULL AND 
        ScientificName <> '') AND 
       instr(ScientificName, '×') = 0 AND 
       (instr(ScientificName, ' ') = 0 OR 
        ScientificName LIKE '% sp.%');

		
--Update tblSpecies to define CodeType as hybrid
UPDATE tblSpecies
   SET CodeType = 'hybrid'
 WHERE CodeType IS NULL AND 
       ScientificName LIKE '%×%';


--Update tblSpecies to define CodeType as subspecies	   
UPDATE tblSpecies
   SET CodeType = 'subspecies'
 WHERE CodeType IS NULL AND 
       (ScientificName LIKE '%ssp.%' OR 
        ScientificName LIKE '%subsp.%');

		
--Update tblSpecies to define CodeType as family
UPDATE tblSpecies
   SET CodeType = 'family'
 WHERE CodeType IS NULL AND 
       length(SpeciesCode) >= 6 AND 
       ( (ScientificName LIKE '%eae' AND 
          instr(ScientificName, ' ') = 0) OR 
         (CommonName LIKE '% family%') );


--Update tblSpecies to define CodeType as variety
UPDATE tblSpecies
   SET CodeType = 'variety'
 WHERE CodeType IS NULL AND 
       ScientificName LIKE '%var.%';

	   
--Update tblSpecies to define CodeType as species
UPDATE tblSpecies
   SET CodeType = 'species'
 WHERE CodeType IS NULL;

 
 --Update tblSpecies to define CodeType as generic
UPDATE tblSpecies
   SET CodeType = 'generic'
 WHERE CodeType IS NULL AND 
       substr(SpeciesCode, 1, 2) IN ('AF', 'PF', 'AG', 'PG', 'SH', 'TR', 'SU') AND 
       (CAST (substr(SpeciesCode, 3, length(SpeciesCode) - 2) AS INTEGER) <> 0 OR 
        SpeciesCode LIKE '%00');

		
--Update tblSpecies to define CodeType as dead beyond recognition
UPDATE tblSpecies
   SET CodeType = 'dead beyond recognition'
 WHERE CodeType IS NULL AND 
       SpeciesCode IN ('AAGG', 'AAFF', 'PPGG', 'PPFF', 'PPSH', 'PPTR', 'PPSU');



COMMIT TRANSACTION;
PRAGMA foreign_keys = on;