@echo off
rem *****UK TIMES standard outputs tool*****
rem version of TIMES model = uktm_model_v1.2.3_d0.1.2_DNP
rem DOS Batch file to construct SQL queries, run the code, amalgamate the results and tidy up (delete) the intermediate stages
rem version as filename. By Fernley Symons 8:02 PM 12 January, 2016
rem works by:
rem
rem 1) constructing SQL code file to create temp files from TIMES runs (creates one script entry for each file)
rem 2) adding analysis SQL to generate summaries which are output to CSVs
rem 3) amalgamates the CSVs
rem 4) deletes the intermediate CSVs leaving a single output file
rem
rem *** _Important note_: this will not work if the folder path has spaces (or other chars like '&' in it ***
rem 
rem By Fernley Symons
rem *****Instructions for updating from "HumanReadableQueries.sql" in Notepad++*****
rem Things to bear in mind:
rem if '%' is part of a sql query (e.g. "like 'x%'), then % needs to be doubled "like 'x%%'"
rem Other characters (|, <, > etc) need to be escaped in a similar way with ^:- ^| etc
rem can't have very long lines - need to break statements
rem filename at end of line, no spaces afterwards
REM Also note that doesn't like labels (col names or values etc) which break across lines. Inserts a break into them so that they don't match any more
rem It will be rare that you'll need to change the first, dynamic bit of the script which creates one SQL statement set
rem for each VD file in the folder. These instructions ignore that and assume that block's unchanged.
rem 1) Copy the appropriate block of SQL from "Human..." to a blank doc
rem 2) Remove indentation from the copied text: select it and press shift-tab repeatedly to do this
rem 3) Comment lines starting "--" should be removed (comments starting "/*" retained). Do this by doing a regex search / replace for 
rem    "^--.+\r\n" (no quotes) replace with blank.
rem 4) Remove embedded comments [appearing on same line as code] with regex replace "--.+" with blank
rem 5) Remove extraneous blank lines with regex replace "(\r\n){2,}" with "\r\n"
rem 6) Make replacements for other reserved DOS words. See below for example (set "texta..." etc). In general there will only be a few of these; define more as needed
rem    NB No need to replace "~" in output file locations since these are DOS commands meaning "put it in the same folder as this BAT file". "~" only needs replacing if part of a query
rem    (i.e. regex in postgres). ****Note that the first 2 queries contain reserved words****
rem 7) Change the single "%" to double "%%" but leave filenames for copy statements unchanged. Regex replace "(%[^~])" with "%\1"
rem 8) Escape other characters: Regex replace "(\||<|>)" with "^\1"
rem 9) Regex replace "(.+)" with "echo \1 >> MainBatchUpload.sql"
rem 10) Regex replace "echo (\/\*.+\/)" with "rem \1\r\necho \1". This duplicates the header in a way which is more obvious to read in the BAT file
rem 11) Copy the edited text back over the body of the BAT below (below the upload statements and before the run SQL statement) and save file
rem 12) comment out the run SQL statement, run the BAT and check the SQL appears sensible.
rem 13) Uncomment the run SQL statement and use the file
rem ***********
rem 9:34 PM 19 January, 2016 Correction of error in new vehicles capacity script
rem 2:04 PM 01 February, 2016; addition of whole vehicle stock capacity
rem 2:58 PM 04 February, 2016; addition of new vehicle emissions intensity
rem 1:39 PM 08 February, 2016; correction of new vehicle emissions intensity
rem 3:30 PM 16 February, 2016; a slew of new queries, refactored code, re-ordered queries. Baseline version for git:-replaces v18
rem 7:50 PM 04 April, 2016: addition of final end use energy demand by main sector; renamed some analysis entities
rem 1:48 PM 12 April, 2016: addition of primary energy demand by main fuel
rem 8:47 PM 11 August, 2016: updated to reflect changes to elec gen techs
rem 11:53 AM 15 August, 2016: updated to reflect corrected and standardised set definitions
rem 8:52 PM 15 November, 2016: correction to FUEL TECHS AGR set in final energy query
rem 2:55 PM 15 December, 2016: BF edited Filter 131, 'heat-res_conserv' and Filter 146, 'new-heat-res_conserv'
rem 2:10 PM 16 December, 2016: 
rem BF added 'RESMSWINO','RESMSWORG' to Filters 287,206,207,208 to match locations of equivalent service sector commodities 'SERMSWINO','SERMSWORG'
rem BF added 'RESMSWINO01','RESMSWORG01' to Filter 304 'Fuel Techs RES' to match equivalent locations of equivalent service sector Fuel Techs 'SERMSWINO01','SERMSWORG01'
rem 3:00 PM 16 December, 2016:
rem BF added residential EFW CHP, 'RCHPEA-EFW01','RCHPNA-EFW01' to Filters 79,114,303,335
rem BF added services EFW CHP, 'SCHP-EFW01' to Filters 79,114,230,368
REM 8:54 PM 12 January, 2017 FS: change to electrical storage query, other small changes to filter definitions (removal of cast to varchar)
REM 1:26 PM 06 February, 2017 FS: various updates to reflect revised human readable
REM 6:19 PM 23 February, 2017 FS: various updates to reflect human readable, change to instructions for how to produce this file (above)
rem 9:01 PM 09 March, 2017 FS: update to human readable
rem ***********
echo processing vd files...
@echo off
rem The following allows us to insert text which is otherwise outlawed in DOS:
setlocal enableDelayedExpansion
rem delete the SQL script if it exists - code below (re-) generates it.
IF EXIST MainBatchUpload.sql del /F MainBatchUpload.sql
rem need to define some variables which contain DOS reserved words. These are replaced by the preprocessor in the script:
set "texta=IF"
set "textb=IF NOT"
set "textc=~"
set "textd=^"
set "texte=&"
rem this block creates the 2 temp table definitions. First stores the unformatted data from the VD file, second parses this into fields and inserts into the "vedastore" table against which the 
rem queries are run.
echo CREATE temp TABLE !textb! EXISTS vedastore( tablename varchar(100), id serial, attribute varchar(50), commodity varchar(50), process varchar(50), period varchar(50), region varchar(50), vintage varchar(50), timeslice varchar(50), userconstraint varchar(50), pv numeric ); drop table !texta! exists veda; create temp table veda( id serial, stuff varchar(1000) ); >> MainBatchUpload.sql
rem the following creates a block of sql for each VD file to upload it, delete the header rows and break the entries into fields
for /f "delims=|" %%i in ('dir /b *.vd') do echo delete from veda; ALTER SEQUENCE veda_id_seq RESTART WITH 1; copy veda (stuff) from '%%~fi'; insert into vedastore (tablename, attribute ,commodity ,process ,period ,region ,vintage ,timeslice ,userconstraint ,pv) select '%%~ni', trim(both '"' from a[1]), trim(both '"' from a[2]), trim(both '"' from a[3]), trim(both '"' from a[4]), trim(both '"' from a[5]), trim(both '"' from a[6]), trim(both '"' from a[7]), trim(both '"' from a[8]), cast(a[9] as numeric) from ( select string_to_array(stuff, ',') from veda order by id offset 13 ) as dt(a); >> MainBatchUpload.sql
rem /* *Dummy imports by table* */echo /* *Dummy imports by table* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo select 'dummies' ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| 'Cost_Act' ^|^| '^|' ^|^| 'various' ^|^| '^|various'::varchar(300) "id", >> MainBatchUpload.sql
echo 'dummies'::varchar(300) "analysis", tablename, 'Cost_Act'::varchar(50) "attribute", >> MainBatchUpload.sql
echo 'various'::varchar(50) "commodity", >> MainBatchUpload.sql
echo 'various'::varchar(50) "process", >> MainBatchUpload.sql
echo sum(pv)::numeric "all", >> MainBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> MainBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> MainBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> MainBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> MainBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> MainBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> MainBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> MainBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> MainBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> MainBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> MainBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> MainBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> MainBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where process in('IMPDEMZ','IMPMATZ','IMPNRGZ') and attribute = 'Cost_Act' >> MainBatchUpload.sql
echo group by tablename >> MainBatchUpload.sql
echo order by tablename, analysis >> MainBatchUpload.sql
echo ) TO '%~dp0dummiesout.csv' delimiter ',' CSV HEADER; >> MainBatchUpload.sql
rem /* *All GHG emissions* */echo /* *All GHG emissions* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo select 'ghg_all^|' ^|^| tablename ^|^| '^|Var_FOut^|' ^|^| commodity ^|^| '^|all'::varchar(300) "id", >> MainBatchUpload.sql
echo 'ghg_all'::varchar(50) "analysis", >> MainBatchUpload.sql
echo tablename, >> MainBatchUpload.sql
echo 'Var_FOut'::varchar(50) "attribute", >> MainBatchUpload.sql
echo commodity, >> MainBatchUpload.sql
echo 'all'::varchar(50) "process", >> MainBatchUpload.sql
echo sum(pv)::numeric "all", >> MainBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> MainBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> MainBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> MainBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> MainBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> MainBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> MainBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> MainBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> MainBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> MainBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> MainBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> MainBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> MainBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FOut' and commodity in('GHG-ETS-NO-IAS-NET','GHG-ETS-NO-IAS-TER','GHG-ETS-YES-IAS-NET','GHG-ETS-YES-IAS-TER', >> MainBatchUpload.sql
echo 'GHG-NO-IAS-YES-LULUCF-NET','GHG-NO-IAS-YES-LULUCF-TER','GHG-NON-ETS-YES-LULUCF-NET','GHG-NON-ETS-YES-LULUCF-TER', >> MainBatchUpload.sql
echo 'GHG-YES-IAS-YES-LULUCF-NET','GHG-YES-IAS-YES-LULUCF-TER','GHG-NO-AS-YES-LULUCF-NET') >> MainBatchUpload.sql
echo group by tablename, commodity >> MainBatchUpload.sql
echo order by tablename, commodity >> MainBatchUpload.sql
echo ) TO '%~dp0GHGOut.csv' delimiter ',' CSV; >> MainBatchUpload.sql
rem /* *GHG emissions by sector* */echo /* *GHG emissions by sector* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| commodity ^|^| '^|' ^|^| process::varchar(300) "id", analysis, tablename,attribute, >> MainBatchUpload.sql
echo commodity, process, >> MainBatchUpload.sql
echo sum(pv)::numeric "all", >> MainBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> MainBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> MainBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> MainBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> MainBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> MainBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> MainBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> MainBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> MainBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> MainBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> MainBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> MainBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> MainBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select 'all'::varchar(50) "process", period, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when attribute='VAR_FIn' and commodity in('Traded-Emission-ETS','PRCCH4P') then -pv >> MainBatchUpload.sql
echo else pv >> MainBatchUpload.sql
echo end as pv, >> MainBatchUpload.sql
echo tablename, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when commodity in('Traded-Emission-ETS','PRCCO2P','PRCCH4P','PRCN2OP') then 'various' >> MainBatchUpload.sql
echo else attribute >> MainBatchUpload.sql
echo end as attribute, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when commodity in('PRCCO2P', 'PRCCH4N', 'PRCCH4P', 'PRCN2ON', 'PRCN2OP') then 'various' >> MainBatchUpload.sql
echo else commodity >> MainBatchUpload.sql
echo end as "commodity", >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when commodity='Traded-Emission-ETS' then 'ghg_sec-traded-emis-ets' >> MainBatchUpload.sql
echo when commodity in('GHG-ELC','GHG-IND-ETS','GHG-RES-ETS','GHG-SER-ETS','GHG-OTHER-ETS','GHG-IAS-ETS', >> MainBatchUpload.sql
echo 'GHG-IAS-NON-ETS','GHG-IND-NON-ETS','GHG-RES-NON-ETS','GHG-SER-NON-ETS','GHG-TRA-NON-ETS-NO-AS', >> MainBatchUpload.sql
echo 'GHG-AGR-NO-LULUCF','GHG-OTHER-NON-ETS','GHG-LULUCF','GHG-HFC-NON-ETS','Traded-Emission-Non-ETS','GHG-ELC-CAPTURED','GHG-IND-ETS-CAPTURED', >> MainBatchUpload.sql
echo 'GHG-IND-NON-ETS-CAPTURED','GHG-OTHER-ETS-CAPTURED','GHG-DAS-ETS','GHG-DAS-NON-ETS') then 'ghg_sec-main-secs' >> MainBatchUpload.sql
echo when commodity in('PRCCH4N','PRCN2ON') then 'ghg_sec-prc-non-waste-non-ets' >> MainBatchUpload.sql
echo when commodity in('PRCCO2P','PRCCH4P','PRCN2OP') then 'ghg_sec-prc-waste-non-ets' >> MainBatchUpload.sql
echo when commodity ='PRCCO2N' then 'ghg_sec-prc-ets' >> MainBatchUpload.sql
echo end as "analysis" >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where (attribute='VAR_FOut' and commodity in('GHG-ELC','GHG-IND-ETS','GHG-RES-ETS','GHG-SER-ETS','GHG-OTHER-ETS', >> MainBatchUpload.sql
echo 'GHG-IAS-ETS','GHG-IAS-NON-ETS','Traded-Emission-ETS','GHG-IND-NON-ETS','GHG-RES-NON-ETS', >> MainBatchUpload.sql
echo 'GHG-SER-NON-ETS','GHG-TRA-NON-ETS-NO-AS','GHG-AGR-NO-LULUCF','GHG-OTHER-NON-ETS','GHG-LULUCF','GHG-HFC-NON-ETS', >> MainBatchUpload.sql
echo 'Traded-Emission-Non-ETS','GHG-ELC-CAPTURED','GHG-IND-ETS-CAPTURED','GHG-IND-NON-ETS-CAPTURED', >> MainBatchUpload.sql
echo 'GHG-OTHER-ETS-CAPTURED','PRCCO2P','PRCCH4N','PRCCH4P','PRCN2ON','PRCN2OP', >> MainBatchUpload.sql
echo 'PRCCO2N','GHG-DAS-ETS','GHG-DAS-NON-ETS')) or (attribute='VAR_FIn' and commodity in('Traded-Emission-ETS','PRCCH4P')) >> MainBatchUpload.sql
echo order by period >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where analysis ^<^>'' >> MainBatchUpload.sql
echo group by id, analysis,tablename, attribute, commodity,process >> MainBatchUpload.sql
echo order by tablename,  analysis, attribute, commodity >> MainBatchUpload.sql
echo ) TO '%~dp0GHGsectorOut.csv' delimiter ',' CSV; >> MainBatchUpload.sql
rem /* *GHG and sequestered emissions by industry sub-sector* */echo /* *GHG and sequestered emissions by industry sub-sector* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo select 'ghg_ind-subsec-'^|^|sector ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| 'VAR_FOut' ^|^| '^|' ^|^| 'various' ^|^| '^|various'::varchar(300) "id", >> MainBatchUpload.sql
echo 'ghg_ind-subsec-'^|^|sector::varchar(300) "analysis", tablename, 'VAR_Fout'::varchar(50) "attribute", >> MainBatchUpload.sql
echo 'various'::varchar(50) "commodity", >> MainBatchUpload.sql
echo 'various'::varchar(50) "process", >> MainBatchUpload.sql
echo sum(pv)::numeric "all", >> MainBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> MainBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> MainBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> MainBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> MainBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> MainBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> MainBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> MainBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> MainBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> MainBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> MainBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> MainBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> MainBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> MainBatchUpload.sql
echo from( >> MainBatchUpload.sql
echo select tablename, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when left(process,3)='ICH' then 'ich' >> MainBatchUpload.sql
echo when left(process,3)='ICM' then 'icm' >> MainBatchUpload.sql
echo when left(process,3)='IFD' then 'ifd' >> MainBatchUpload.sql
echo when left(process,3)='IIS' then 'iis' >> MainBatchUpload.sql
echo when left(process,3)='INF' then 'inf' >> MainBatchUpload.sql
echo when left(process,3)='INM' then 'inm' >> MainBatchUpload.sql
echo when left(process,3)='IOI' or process like 'INDHFCOTH0%%' then 'ioi' >> MainBatchUpload.sql
echo when left(process,3)='IPP' then 'ipp' >> MainBatchUpload.sql
echo when process='-' then 'other' >> MainBatchUpload.sql
echo else null >> MainBatchUpload.sql
echo end "sector", >> MainBatchUpload.sql
echo period, sum(case when commodity in('SKNINDCO2N','SKNINDCO2P') then -pv else pv end) "pv" >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where commodity in ('SKNINDCO2N','SKNINDCO2P','INDCO2N','INDCO2P','INDNEUCO2N','INDCH4N','INDN2ON','INDHFCP') and attribute='VAR_FOut' >> MainBatchUpload.sql
echo group by tablename, sector,period >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where sector is not null >> MainBatchUpload.sql
echo group by tablename, sector >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select 'ghgseq_ind-subsec-'^|^|sector ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| 'VAR_FOut' ^|^| '^|' ^|^| 'various' ^|^| '^|various'::varchar(300) "id", >> MainBatchUpload.sql
echo 'ghgseq_ind-subsec-'^|^|sector::varchar(300) "analysis", tablename, 'VAR_Fout'::varchar(50) "attribute", >> MainBatchUpload.sql
echo 'various'::varchar(50) "commodity", >> MainBatchUpload.sql
echo 'various'::varchar(50) "process", >> MainBatchUpload.sql
echo sum(pv)::numeric "all", >> MainBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> MainBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> MainBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> MainBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> MainBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> MainBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> MainBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> MainBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> MainBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> MainBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> MainBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> MainBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> MainBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> MainBatchUpload.sql
echo from( >> MainBatchUpload.sql
echo select tablename, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when left(process,3)='ICH' then 'ich' >> MainBatchUpload.sql
echo when left(process,3)='ICM' then 'icm' >> MainBatchUpload.sql
echo when left(process,3)='IFD' then 'ifd' >> MainBatchUpload.sql
echo when left(process,3)='IIS' then 'iis' >> MainBatchUpload.sql
echo when left(process,3)='INF' then 'inf' >> MainBatchUpload.sql
echo when left(process,3)='INM' then 'inm' >> MainBatchUpload.sql
echo when left(process,3)='IOI' or process like 'INDHFCOTH0%%' then 'ioi' >> MainBatchUpload.sql
echo when left(process,3)='IPP' then 'ipp' >> MainBatchUpload.sql
echo when process='-' then 'other' >> MainBatchUpload.sql
echo else null >> MainBatchUpload.sql
echo end "sector", >> MainBatchUpload.sql
echo period, sum(case when commodity in('SKNINDCO2N','SKNINDCO2P') then -pv else pv end) "pv" >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where commodity in ('SKNINDCO2N','SKNINDCO2P') and attribute='VAR_FOut' >> MainBatchUpload.sql
echo group by tablename, sector,period >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where sector is not null >> MainBatchUpload.sql
echo group by tablename, sector >> MainBatchUpload.sql
echo ) TO '%~dp0IndSubGHG.csv' CSV; >> MainBatchUpload.sql
rem /* *Electricity generation by source* */echo /* *Electricity generation by source* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo with emissions_chp as ( >> MainBatchUpload.sql
echo select tablename, proc_set, commodity,period,sum(pv) "pv" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select period, pv,commodity,process,tablename, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','ICHCHPCCGT01','ICHCHPCCGTH01','ICHCHPCOA00','ICHCHPCOA01','ICHCHPFCH01','ICHCHPGT01','ICHCHPHFO00','ICHCHPLFO00','ICHCHPLPG00' >> MainBatchUpload.sql
echo ,'ICHCHPLPG01','ICHCHPNGA00','ICHCHPPRO00','ICHCHPPRO01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01','IFDCHPCCGT01','IFDCHPCCGTH01','IFDCHPCOA00','IFDCHPCOA01','IFDCHPFCH01' >> MainBatchUpload.sql
echo ,'IFDCHPGT01','IFDCHPHFO00','IFDCHPLFO00','IFDCHPNGA00','IISCHPBFG00','IISCHPBFG01','IISCHPBIOG01','IISCHPBIOS01','IISCHPCCGT01','IISCHPCCGTH01','IISCHPCOG00','IISCHPCOG01' >> MainBatchUpload.sql
echo ,'IISCHPFCH01','IISCHPGT01','IISCHPHFO00','IISCHPNGA00','INMCHPBIOG01','INMCHPBIOS01','INMCHPCCGT01','INMCHPCCGTH01','INMCHPCOA01','INMCHPCOG00','INMCHPCOG01','INMCHPFCH01' >> MainBatchUpload.sql
echo ,'INMCHPGT01','INMCHPNGA00','IOICHPBIOG01','IOICHPBIOS00','IOICHPBIOS01','IOICHPCCGT01','IOICHPCCGTH01','IOICHPCOA01','IOICHPFCH01','IOICHPGT01','IOICHPHFO00','IOICHPNGA00' >> MainBatchUpload.sql
echo ,'IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPCCGT01','IPPCHPCCGTH01','IPPCHPCOA00','IPPCHPCOA01','IPPCHPFCH01','IPPCHPGT01','IPPCHPNGA00','IPPCHPWST00','IPPCHPWST01') >> MainBatchUpload.sql
echo then 'CHP IND SECTOR' >> MainBatchUpload.sql
echo when process in('PCHP-CCP00','PCHP-CCP01') then 'CHP PRC SECTOR' >> MainBatchUpload.sql
echo when process in('SCHP-ADM01','SCHP-CCG00','SCHP-CCG01', >> MainBatchUpload.sql
echo 'SCHP-CCH01','SCHP-FCH01','SCHP-GES00','SCHP-GES01', >> MainBatchUpload.sql
echo 'SCHP-STM01','SCHP-STW00','SCHP-STW01','SHLCHPRG01', >> MainBatchUpload.sql
echo 'SHLCHPRH01','SHLCHPRW01','SCHP-EFW01') then 'CHP SER SECTOR' >> MainBatchUpload.sql
echo when process in('UCHP-CCG00','UCHP-CCG01') then 'CHP UPS SECTOR' >> MainBatchUpload.sql
echo when process in('RHEACHPRG01','RHEACHPRH01','RHEACHPRW01', >> MainBatchUpload.sql
echo 'RHFCCHPRG01','RHFCCHPRH01','RHFCCHPRW01','RHFSCHPRG01', >> MainBatchUpload.sql
echo 'RHFSCHPRH01','RHFSCHPRW01','RHHCCHPRG01','RHHCCHPRH01', >> MainBatchUpload.sql
echo 'RHHCCHPRW01','RHHSCHPRG01','RHHSCHPRH01','RHHSCHPRW01', >> MainBatchUpload.sql
echo 'RHNACHPRG01','RHNACHPRH01','RHNACHPRW01' >> MainBatchUpload.sql
echo ) then 'CHP RES MICRO' >> MainBatchUpload.sql
echo end proc_set >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FOut' and commodity in('RESCH4N','SERN2ON','INDCO2N','SERCH4N','INDCH4N','INDN2ON','UPSN2ON','UPSCO2N','UPSCH4N','PRCCH4N','PRCCO2N','PRCN2ON' >> MainBatchUpload.sql
echo ,'SERCO2N','RESCO2N','RESN2ON') >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select period, pv,commodity,process,tablename, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01','IISCHPBIOG01','IISCHPBIOS01','INMCHPBIOG01','INMCHPBIOS01','IOICHPBIOG01' >> MainBatchUpload.sql
echo ,'IOICHPBIOS00','IOICHPBIOS01','IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPWST00','IPPCHPWST01') then 'CHP IND BIO' >> MainBatchUpload.sql
echo when process in('SCHP-ADM01','SCHP-GES00','SCHP-GES01','SCHP-STM01','SCHP-STW00','SCHP-STW01','SHLCHPRW01','SCHP-EFW01') then 'CHP SER BIO' >> MainBatchUpload.sql
echo when process in('SHLCHPRG01','SHLCHPRH01','SHLCHPRW01') then 'CHP SER MICRO' >> MainBatchUpload.sql
echo when process in('RCHPEA-CCG00','RCHPEA-CCG01','RCHPEA-CCH01', >> MainBatchUpload.sql
echo 'RCHPEA-FCH01','RCHPEA-STW01','RCHPNA-CCG01','RCHPNA-CCH01', >> MainBatchUpload.sql
echo 'RCHPNA-FCH01','RCHPNA-STW01','RHEACHPRG01','RHEACHPRH01', >> MainBatchUpload.sql
echo 'RHEACHPRW01','RHNACHPRG01','RHNACHPRH01','RHNACHPRW01', >> MainBatchUpload.sql
echo 'RCHPEA-EFW01','RCHPNA-EFW01','RHFCCHPRH01','RHFSCHPRH01', >> MainBatchUpload.sql
echo 'RHHCCHPRH01','RHHSCHPRH01','RHFCCHPRG01','RHFSCHPRG01', >> MainBatchUpload.sql
echo 'RHHCCHPRG01','RHHSCHPRG01','RHFCCHPRW01','RHFSCHPRW01', >> MainBatchUpload.sql
echo 'RHHCCHPRW01','RHHSCHPRW01') then 'CHP RES SECTOR' >> MainBatchUpload.sql
echo else null >> MainBatchUpload.sql
echo end proc_set >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FOut' and commodity in('RESCH4N','SERN2ON','INDCO2N','SERCH4N','INDCH4N','INDN2ON','UPSN2ON','UPSCO2N','UPSCH4N','PRCCH4N','PRCCO2N','PRCN2ON' >> MainBatchUpload.sql
echo ,'SERCO2N','RESCO2N','RESN2ON') >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where proc_set is not null >> MainBatchUpload.sql
echo group by tablename, proc_set, commodity,period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , emis_co2_sector as( >> MainBatchUpload.sql
echo select tablename, comm_set, >> MainBatchUpload.sql
echo commodity,period, pv >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select case >> MainBatchUpload.sql
echo when commodity in('AGRCO2N','AGRCO2P') then 'EMIS CO2 AGR' >> MainBatchUpload.sql
echo when commodity in('ELCCO2N') then 'EMIS CO2 ELC' >> MainBatchUpload.sql
echo when commodity in('HYGCO2N') then 'EMIS CO2 HYG' >> MainBatchUpload.sql
echo when commodity in('INDCO2N','INDCO2P') then 'EMIS CO2 IND' >> MainBatchUpload.sql
echo when commodity in('INDNEUCO2N') then 'EMIS CO2 NEU' >> MainBatchUpload.sql
echo when commodity in('PRCCO2N','PRCCO2P') then 'EMIS CO2 PRC' >> MainBatchUpload.sql
echo when commodity in('RESCO2N') then 'EMIS CO2 RES' >> MainBatchUpload.sql
echo when commodity in('SERCO2N') then 'EMIS CO2 SER' >> MainBatchUpload.sql
echo when commodity in('TRACO2N') then 'EMIS CO2 TRA' >> MainBatchUpload.sql
echo when commodity in('UPSCO2N','UPSCO2P') then 'EMIS CO2 UPS' >> MainBatchUpload.sql
echo end as comm_set,commodity,pv,period,tablename >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FOut' >> MainBatchUpload.sql
echo ) a where comm_set is not null >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , emis_ghg_dif as ( >> MainBatchUpload.sql
echo select tablename, comm_set, >> MainBatchUpload.sql
echo commodity,period,pv >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select case >> MainBatchUpload.sql
echo when commodity in ('AGRCH4N','AGRCH4P','AGRCO2N','AGRCO2P','AGRHFCN','AGRHFCP','AGRN2ON','AGRN2OP','AGRNH3','AGRNOX','AGRPM10','AGRPM25','AGRSO2','AGRVOC') then 'EMIS GHG AGR' >> MainBatchUpload.sql
echo when commodity in ('ELCCH4N','ELCCH4P','ELCCO2N','ELCCO2P','ELCHFCN','ELCHFCP','ELCN2ON','ELCN2OP','ELCNH3','ELCNOX','ELCPM10','ELCPM25','ELCSO2','ELCVOC') then 'EMIS GHG ELC' >> MainBatchUpload.sql
echo when commodity in ('HYGCH4N','HYGCH4P','HYGCO2N','HYGCO2P','HYGHFCN','HYGHFCP','HYGN2ON','HYGN2OP','HYGNH3','HYGNOX','HYGPM10','HYGPM25','HYGSO2','HYGVOC') then 'EMIS GHG HYG' >> MainBatchUpload.sql
echo when commodity in ('INDCH4N','INDCH4P','INDCO2N','INDCO2P','INDHFCN','INDHFCP','INDN2ON','INDN2OP') then 'EMIS GHG IND' >> MainBatchUpload.sql
echo when commodity in ('INDNEUCO2N') then 'EMIS GHG NEU' >> MainBatchUpload.sql
echo when commodity in ('PRCCH4N','PRCCH4P','PRCCO2N','PRCCO2P','PRCHFCN','PRCHFCP','PRCN2ON','PRCN2OP','PRCNH3','PRCNOX','PRCPM10','PRCPM25','PRCSO2','PRCVOC') then 'EMIS GHG PRC' >> MainBatchUpload.sql
echo when commodity in ('RESCH4N','RESCH4P','RESCO2N','RESCO2P','RESHFCN','RESHFCP','RESN2ON','RESN2OP','RESNH3','RESNOX','RESPM10','RESPM25','RESSO2','RESVOC') then 'EMIS GHG RES' >> MainBatchUpload.sql
echo when commodity in ('SERCH4N','SERCH4P','SERCO2N','SERCO2P','SERHFCN','SERHFCP','SERN2ON','SERN2OP','SERNH3','SERNOX','SERPM10','SERPM25','SERSO2','SERVOC') then 'EMIS GHG SER' >> MainBatchUpload.sql
echo when commodity in ('TRACH4N','TRACH4P','TRACO2N','TRACO2P','Traded-Emission-ETS','Traded-Emission-Non-ETS','TRAHFCN','TRAHFCP','TRAN2ON','TRAN2OP','TRANH3','TRANOX','TRAPM10' >> MainBatchUpload.sql
echo ,'TRAPM25','TRASO2','TRAVOC') then 'EMIS GHG TRA' >> MainBatchUpload.sql
echo when commodity in ('UPSCH4N','UPSCH4P','UPSCO2N','UPSCO2P','UPSHFCN','UPSHFCP','UPSN2ON','UPSN2OP') then 'EMIS GHG UPS' >> MainBatchUpload.sql
echo end as comm_set,commodity,pv,period, tablename >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute in('EQ_Combal','VAR_Comnet') >> MainBatchUpload.sql
echo ) a where comm_set is not null >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , "elc-emis" as( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo tablename,period,sum(pv)/1000 "elc-emis" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select tablename,pv,period from "emis_co2_sector" where comm_set='EMIS CO2 ELC' >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select tablename,pv,period from "emis_ghg_dif" >> MainBatchUpload.sql
echo where commodity in('ELCCH4N','ELCN2ON') >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select tablename,sum(pv) "pv", period from "emissions_chp" >> MainBatchUpload.sql
echo where proc_set in('CHP IND SECTOR','CHP PRC SECTOR','CHP RES SECTOR','CHP SER SECTOR','CHP UPS SECTOR') and >> MainBatchUpload.sql
echo commodity in('INDCO2N','INDCH4N','INDN2ON','PRCCO2N','PRCCH4N','PRCN2ON','RESCO2N','RESCH4N','RESN2ON','SERCO2N','SERCH4N','SERN2ON','UPSCO2N','UPSCH4N','UPSN2ON') >> MainBatchUpload.sql
echo group by tablename, period >> MainBatchUpload.sql
echo ) a group by tablename,period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , elc_prd_fuel as ( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo proc_set,tablename,period, sum(pv) "pv" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo tablename,period, pv, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('EBIO01','EBIOCON00','EBIOS00','EBOG-ADE01','EBOG-LFE00','EBOG-LFE01','EBOG-SWE00','EBOG-SWE01','EMSW00','EMSW01','EPOLWST00','ESTWWST00' >> MainBatchUpload.sql
echo ,'ESTWWST01') then 'ELC FROM BIO' >> MainBatchUpload.sql
echo when process in('EBIOQ01') then 'ELC FROM BIO CCS' >> MainBatchUpload.sql
echo when process in('PCHP-CCP00','PCHP-CCP01','UCHP-CCG00','UCHP-CCG01') then 'ELC FROM CHP' >> MainBatchUpload.sql
echo when process='ECOAQR01' then 'ELC FROM COAL CCSRET' >> MainBatchUpload.sql
echo when process in('ECOARR01') then 'ELC FROM COAL RR' >> MainBatchUpload.sql
echo when process in('ECOA00','ECOABIO00') then 'ELC FROM COAL-COF' >> MainBatchUpload.sql
echo when process in('ECOAQ01','ECOAQDEMO01') then 'ELC FROM COALCOF CCS' >> MainBatchUpload.sql
echo when process in('ENGACCT00','ENGAOCT00','ENGAOCT01','ENGARCPE00','ENGARCPE01') then 'ELC FROM GAS' >> MainBatchUpload.sql
echo when process in('ENGACCTQ01','ENGACCTQDEMO01') then 'ELC FROM GAS CCS' >> MainBatchUpload.sql
echo when process='ENGAQR01' then 'ELC FROM GAS CCSRET' >> MainBatchUpload.sql
echo when process in('ENGACCTRR01') then 'ELC FROM GAS RR' >> MainBatchUpload.sql
echo when process in('EGEO01') then 'ELC FROM GEO' >> MainBatchUpload.sql
echo when process in('EHYD00','EHYD01') then 'ELC FROM HYDRO' >> MainBatchUpload.sql
echo when process in('EHYGCCT01','EHYGOCT01') then 'ELC FROM HYDROGEN' >> MainBatchUpload.sql
echo when process in('ELCIE00','ELCIE01','ELCII00','ELCII01') then 'ELC FROM IMPORTS' >> MainBatchUpload.sql
echo when process in('EMANOCT00','EMANOCT01') then 'ELC FROM MANFUELS' >> MainBatchUpload.sql
echo when process in('ENUCPWR00','ENUCPWR101','ENUCPWR102') then 'ELC FROM NUCLEAR' >> MainBatchUpload.sql
echo when process in('EDSTRCPE00','EDSTRCPE01','EHFOIGCC01','EOILL00','EOILL01','EOILS00','EOILS01') then 'ELC FROM OIL' >> MainBatchUpload.sql
echo when process in('EHFOIGCCQ01') then 'ELC FROM OIL CCS' >> MainBatchUpload.sql
echo when process in('ESOL00','ESOL01','ESOLPV00','ESOLPV01') then 'ELC FROM SOL-PV' >> MainBatchUpload.sql
echo when process in('ETIB101','ETIR101','ETIS101') then 'ELC FROM TIDAL' >> MainBatchUpload.sql
echo when process in('EWAV101') then 'ELC FROM WAVE' >> MainBatchUpload.sql
echo when process in('EWNDOFF00','EWNDOFF101','EWNDOFF201') then 'ELC FROM WIND-OFFSH' >> MainBatchUpload.sql
echo when process in('EWNDONS00','EWNDONS101','EWNDONS201') then 'ELC FROM WIND-ONSH' >> MainBatchUpload.sql
echo when process in('ELCEE00','ELCEE01','ELCEI00','ELCEI01') then 'ELC TO EXPORTS' >> MainBatchUpload.sql
echo end as proc_set >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FOut' and commodity in('ELCDUMMY','ELC','ELC-E-IRE','ELC-E-EU','ELCGEN') >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where proc_set is not null >> MainBatchUpload.sql
echo group by tablename, period,proc_set >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select proc_set,tablename,period, sum(pv) "pv" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select tablename,period, pv, >> MainBatchUpload.sql
echo case when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01', >> MainBatchUpload.sql
echo 'ICHCHPCCGT01','ICHCHPCCGTH01','ICHCHPCOA00','ICHCHPCOA01', >> MainBatchUpload.sql
echo 'ICHCHPFCH01','ICHCHPGT01','ICHCHPHFO00','ICHCHPLFO00', >> MainBatchUpload.sql
echo 'ICHCHPLPG00','ICHCHPLPG01','ICHCHPNGA00','ICHCHPPRO00', >> MainBatchUpload.sql
echo 'ICHCHPPRO01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01', >> MainBatchUpload.sql
echo 'IFDCHPCCGT01','IFDCHPCCGTH01','IFDCHPCOA00','IFDCHPCOA01', >> MainBatchUpload.sql
echo 'IFDCHPFCH01','IFDCHPGT01','IFDCHPHFO00','IFDCHPLFO00', >> MainBatchUpload.sql
echo 'IFDCHPNGA00','IISCHPBFG00','IISCHPBFG01','IISCHPBIOG01', >> MainBatchUpload.sql
echo 'IISCHPBIOS01','IISCHPCCGT01','IISCHPCCGTH01','IISCHPCOG00', >> MainBatchUpload.sql
echo 'IISCHPCOG01','IISCHPFCH01','IISCHPGT01','IISCHPHFO00', >> MainBatchUpload.sql
echo 'IISCHPNGA00','INMCHPBIOG01','INMCHPBIOS01','INMCHPCCGT01', >> MainBatchUpload.sql
echo 'INMCHPCCGTH01','INMCHPCOA01','INMCHPCOG00','INMCHPCOG01', >> MainBatchUpload.sql
echo 'INMCHPFCH01','INMCHPGT01','INMCHPNGA00','IOICHPBIOG01', >> MainBatchUpload.sql
echo 'IOICHPBIOS00','IOICHPBIOS01','IOICHPCCGT01','IOICHPCCGTH01', >> MainBatchUpload.sql
echo 'IOICHPCOA01','IOICHPFCH01','IOICHPGT01','IOICHPHFO00', >> MainBatchUpload.sql
echo 'IOICHPNGA00','IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01', >> MainBatchUpload.sql
echo 'IPPCHPCCGT01','IPPCHPCCGTH01','IPPCHPCOA00','IPPCHPCOA01', >> MainBatchUpload.sql
echo 'IPPCHPFCH01','IPPCHPGT01','IPPCHPNGA00','IPPCHPWST00', >> MainBatchUpload.sql
echo 'IPPCHPWST01','PCHP-CCP00','PCHP-CCP01','RCHPEA-CCG00', >> MainBatchUpload.sql
echo 'RCHPEA-CCG01','RCHPEA-CCH01','RCHPEA-FCH01','RCHPEA-STW01', >> MainBatchUpload.sql
echo 'RCHPNA-CCG01','RCHPNA-CCH01','RCHPNA-FCH01','RCHPNA-STW01', >> MainBatchUpload.sql
echo 'RHEACHPRG01','RHEACHPRH01','RHEACHPRW01','RHNACHPRG01', >> MainBatchUpload.sql
echo 'RHNACHPRH01','RHNACHPRW01','RCHPEA-EFW01','RCHPNA-EFW01', >> MainBatchUpload.sql
echo 'SCHP-ADM01','SCHP-CCG00','SCHP-CCG01','SCHP-CCH01', >> MainBatchUpload.sql
echo 'SCHP-FCH01','SCHP-GES00','SCHP-GES01','SCHP-STM01', >> MainBatchUpload.sql
echo 'SCHP-STW00','SCHP-STW01','SHLCHPRG01','SHLCHPRH01', >> MainBatchUpload.sql
echo 'SHLCHPRW01','SCHP-EFW01','UCHP-CCG00','UCHP-CCG01', >> MainBatchUpload.sql
echo 'RHFCCHPRH01','RHFSCHPRH01','RHHCCHPRH01','RHHSCHPRH01', >> MainBatchUpload.sql
echo 'RHFCCHPRG01','RHFSCHPRG01','RHHCCHPRG01','RHHSCHPRG01', >> MainBatchUpload.sql
echo 'RHFCCHPRW01','RHFSCHPRW01','RHHCCHPRW01','RHHSCHPRW01') then 'elec-gen_chp' else null >> MainBatchUpload.sql
echo end proc_set >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where period in('2010','2011','2012','2015','2020','2025','2030','2035','2040','2045','2050','2055','2060') and attribute='VAR_FOut' >> MainBatchUpload.sql
echo and commodity in('ELCGEN','INDELC','RESELC','RESHOUSEELC','SERBUILDELC','SERDISTELC','SERELC') >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where proc_set is not null >> MainBatchUpload.sql
echo group by tablename, period,proc_set >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select proc_set,tablename,period, sum(pv) "pv" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select tablename,period, pv, >> MainBatchUpload.sql
echo case when process='EWSTHEAT-OFF-01' then 'elec-gen_waste-heat-penalty' else null >> MainBatchUpload.sql
echo end::varchar(50) proc_set >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where period in('2010','2011','2012','2015','2020','2025','2030','2035','2040','2045','2050','2055','2060') and commodity = 'ELCGEN' and attribute = 'VAR_FIn' >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where proc_set is not null >> MainBatchUpload.sql
echo group by tablename, period,proc_set >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , cofiring_fuel as( >> MainBatchUpload.sql
echo select tablename, fuel, period, sum(pv) "pv" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select tablename,commodity "fuel",period,pv >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where process in('ECOA00','ECOABIO00','ECOAQ01','ECOARR01','ECOAQDEMO01') and attribute='VAR_FIn' >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select tablename,commodity "fuel",period,pv >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where commodity in ('ELCBIOLFO','ELCBIOOIL','ELCHFO','ELCLFO','ELCLPG') and attribute='VAR_FIn' >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select tablename,commodity "fuel",period,pv >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where commodity in('ELCMAINSBOM','ELCMAINSGAS','ELCTRANSBOM','ELCTRANSGAS') and attribute='VAR_FIn' >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo group by tablename, fuel,period >> MainBatchUpload.sql
echo order by fuel, period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , cofiring_fuel_percents as( >> MainBatchUpload.sql
echo select tablename, period, >> MainBatchUpload.sql
echo case when sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end ) ^> 0 then >> MainBatchUpload.sql
echo sum(case when fuel='ELCCOA' then pv else 0 end) / sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end ) >> MainBatchUpload.sql
echo else 0 end "coal", >> MainBatchUpload.sql
echo case when sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end ) ^> 0 then >> MainBatchUpload.sql
echo sum(case when fuel in('ELCBIOCOA','ELCBIOCOA2','ELCPELL') then pv else 0 end) / sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end ) >> MainBatchUpload.sql
echo else 0 end "biocoal", >> MainBatchUpload.sql
echo case when sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end ) ^> 0 then >> MainBatchUpload.sql
echo sum(case when fuel in('ELCMSC') then pv else 0 end) / sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end ) >> MainBatchUpload.sql
echo else 0 end "oilcoal", >> MainBatchUpload.sql
echo case when sum(case when fuel in('ELCHFO','ELCLFO','ELCLPG','ELCBIOOIL','ELCBIOLFO') then pv else 0 end ) ^> 0 then >> MainBatchUpload.sql
echo sum(case when fuel in('ELCHFO','ELCLFO','ELCLPG') then pv else 0 end) / sum(case when fuel in('ELCHFO','ELCLFO','ELCLPG','ELCBIOOIL','ELCBIOLFO') then pv else 0 end ) >> MainBatchUpload.sql
echo else 0 end "oil", >> MainBatchUpload.sql
echo case when sum(case when fuel in('ELCHFO','ELCLFO','ELCLPG','ELCBIOOIL','ELCBIOLFO') then pv else 0 end ) ^> 0 then >> MainBatchUpload.sql
echo sum(case when fuel in('ELCBIOOIL','ELCBIOLFO') then pv else 0 end) / sum(case when fuel in('ELCHFO','ELCLFO','ELCLPG','ELCBIOOIL','ELCBIOLFO') then pv else 0 end ) >> MainBatchUpload.sql
echo else 0 end "biooil", >> MainBatchUpload.sql
echo case when sum(case when fuel in('ELCMAINSGAS','ELCTRANSGAS','ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end ) ^> 0 then >> MainBatchUpload.sql
echo sum(case when fuel in('ELCMAINSGAS','ELCTRANSGAS') then pv else 0 end) / sum(case when fuel in('ELCMAINSGAS','ELCTRANSGAS','ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end ) >> MainBatchUpload.sql
echo else 0 end "gas", >> MainBatchUpload.sql
echo case when sum(case when fuel in('ELCMAINSGAS','ELCTRANSGAS','ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end ) ^> 0 then >> MainBatchUpload.sql
echo sum(case when fuel in('ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end) / sum(case when fuel in('ELCMAINSGAS','ELCTRANSGAS','ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end ) >> MainBatchUpload.sql
echo else 0 end "biogas" >> MainBatchUpload.sql
echo from cofiring_fuel >> MainBatchUpload.sql
echo group by tablename, period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , elc_waste_heat_process as ( >> MainBatchUpload.sql
echo select tablename, process,userconstraint,attribute,commodity,period,sum(pv) "pv" >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where process='EWSTHEAT-OFF-01' and commodity='ELCGEN' and attribute='VAR_FIn' >> MainBatchUpload.sql
echo group by tablename, process,userconstraint,attribute,commodity, period >> MainBatchUpload.sql
echo order by tablename, process,userconstraint,attribute,commodity, period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , elc_waste_heat_available as ( >> MainBatchUpload.sql
echo select tablename,attribute,commodity,process,period, sum(pv) "pv" >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where commodity='ELCWSTHEAT' and attribute in ('VAR_FIn','VAR_FOut') >> MainBatchUpload.sql
echo group by tablename,attribute,commodity,process,period >> MainBatchUpload.sql
echo order by tablename,attribute,commodity,process,period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , waste_heat_type as( >> MainBatchUpload.sql
echo select tablename, period, >> MainBatchUpload.sql
echo sum(case when "waste_heat"='Biomass' then pv else 0 end) "Biomass", >> MainBatchUpload.sql
echo sum(case when "waste_heat"='Biomass CCS' then pv else 0 end) "Biomass CCS", >> MainBatchUpload.sql
echo sum(case when "waste_heat"='Hydrogen' then pv else 0 end) "Hydrogen", >> MainBatchUpload.sql
echo sum(case when "waste_heat"='Nuclear' then pv else 0 end) "Nuclear", >> MainBatchUpload.sql
echo sum(case when "waste_heat"='Coal' then pv else 0 end) "Coal", >> MainBatchUpload.sql
echo sum(case when "waste_heat"='Coal CCS' then pv else 0 end) "Coal CCS", >> MainBatchUpload.sql
echo sum(case when "waste_heat"='Coal RR' then pv else 0 end) "Coal RR", >> MainBatchUpload.sql
echo sum(case when "waste_heat"='Natural Gas' then pv else 0 end) "Natural Gas", >> MainBatchUpload.sql
echo sum(case when "waste_heat"='Natural Gas CCS' then pv else 0 end) "Natural Gas CCS", >> MainBatchUpload.sql
echo sum(case when "waste_heat"='Natural Gas RR' then pv else 0 end) "Natural Gas RR", >> MainBatchUpload.sql
echo sum(case when "waste_heat"='Oil' then pv else 0 end) "Oil", >> MainBatchUpload.sql
echo sum(case when "waste_heat"='OIL CCS' then pv else 0 end) "OIL CCS" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select tablename,attribute,period,pv, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('ESTWWST00','EPOLWST00','EBIOS00','EBOG-LFE00','EBOG-SWE00','EMSW00','EBIOCON00','ESTWWST01','EBIO01','EBOG-ADE01','EBOG-LFE01','EBOG-SWE01','EMSW01') then 'Biomass' >> MainBatchUpload.sql
echo when process in('EBIOQ01') then 'Biomass CCS' >> MainBatchUpload.sql
echo when process in('EHYGCCT01') then 'Hydrogen' >> MainBatchUpload.sql
echo when process in('ENUCPWR00','ENUCPWR101','ENUCPWR102') then 'Nuclear' >> MainBatchUpload.sql
echo end "waste_heat" >> MainBatchUpload.sql
echo from elc_waste_heat_available >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select tablename,attribute,period,pv, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('ECOA00','ECOABIO00') then 'Coal' >> MainBatchUpload.sql
echo when process in('ECOAQ01','ECOAQDEMO01') then 'Coal CCS' >> MainBatchUpload.sql
echo when process in('ECOARR01') then 'Coal RR' >> MainBatchUpload.sql
echo when process in('ENGACCT00','ENGAOCT00','ENGAOCT01','ENGARCPE00','ENGARCPE01') then 'Natural Gas' >> MainBatchUpload.sql
echo when process in('ENGACCTQ01','ENGACCTQDEMO01','ENGAQR01') then 'Natural Gas CCS' >> MainBatchUpload.sql
echo when process in('ENGACCTRR01') then 'Natural Gas RR' >> MainBatchUpload.sql
echo when process in('EDSTRCPE00','EDSTRCPE01','EOILL00','EOILS00','EOILS01','EOILL01','EHFOIGCC01') then 'Oil' >> MainBatchUpload.sql
echo when process in('EHFOIGCCQ01') then 'OIL CCS' >> MainBatchUpload.sql
echo end "waste_heat" >> MainBatchUpload.sql
echo from elc_waste_heat_available >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where "waste_heat" is not null >> MainBatchUpload.sql
echo group by tablename, period >> MainBatchUpload.sql
echo order by tablename, period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , retrofit_plants as( >> MainBatchUpload.sql
echo select a.tablename, a.period, >> MainBatchUpload.sql
echo sum(a."coal_rr"*b."Coal RR") "coal_rr", >> MainBatchUpload.sql
echo sum(a."gas_rr"*b."Natural Gas RR") "gas_rr", >> MainBatchUpload.sql
echo sum(a."coalccs_rr"*b."Coal RR") "coalccs_rr", >> MainBatchUpload.sql
echo sum(a."gasccs_rr"*b."Natural Gas RR") "gasccs_rr" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select tablename, period, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when sum(case when proc_set in('ELC FROM COAL RR','ELC FROM COAL CCSRET') then pv else 0 end) ^> 0 then >> MainBatchUpload.sql
echo (sum(case when proc_set='ELC FROM COAL RR' then pv else 0 end)/sum(case when proc_set in('ELC FROM COAL RR','ELC FROM COAL CCSRET') then pv else 0 end)) >> MainBatchUpload.sql
echo else 0 end "coal_rr", >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when sum(case when proc_set in('ELC FROM GAS RR','ELC FROM GAS CCSRET') then pv else 0 end) ^> 0 then >> MainBatchUpload.sql
echo (sum(case when proc_set='ELC FROM GAS RR' then pv else 0 end)/sum(case when proc_set in('ELC FROM GAS RR','ELC FROM GAS CCSRET') then pv else 0 end)) >> MainBatchUpload.sql
echo else 0 end "gas_rr", >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when sum(case when proc_set in('ELC FROM COAL RR','ELC FROM COAL CCSRET') then pv else 0 end) ^> 0 then >> MainBatchUpload.sql
echo (sum(case when proc_set='ELC FROM COAL CCSRET' then pv else 0 end)/sum(case when proc_set in('ELC FROM COAL RR','ELC FROM COAL CCSRET') then pv else 0 end)) >> MainBatchUpload.sql
echo else 0 end "coalccs_rr", >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when sum(case when proc_set in('ELC FROM GAS RR','ELC FROM GAS CCSRET') then pv else 0 end) ^> 0 then >> MainBatchUpload.sql
echo (sum(case when proc_set='ELC FROM GAS CCSRET' then pv else 0 end)/sum(case when proc_set in('ELC FROM GAS RR','ELC FROM GAS CCSRET') then pv else 0 end)) >> MainBatchUpload.sql
echo else 0 end "gasccs_rr" >> MainBatchUpload.sql
echo from elc_prd_fuel >> MainBatchUpload.sql
echo group by tablename, period >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo inner join waste_heat_type b >> MainBatchUpload.sql
echo on a.tablename=b.tablename and a.period=b.period >> MainBatchUpload.sql
echo group by a.tablename, a.period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , fuel_shares_to_groups as( >> MainBatchUpload.sql
echo select tablename, period, >> MainBatchUpload.sql
echo "coal_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "coal_grp", >> MainBatchUpload.sql
echo "coalccs_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "coalccs_grp", >> MainBatchUpload.sql
echo "gas_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "gas_grp", >> MainBatchUpload.sql
echo "gasccs_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "gasccs_grp", >> MainBatchUpload.sql
echo "oil_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "oil_grp", >> MainBatchUpload.sql
echo "oilccs_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "oilccs_grp", >> MainBatchUpload.sql
echo "bio_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "bio_grp", >> MainBatchUpload.sql
echo "bioccs_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "bioccs_grp", >> MainBatchUpload.sql
echo "nuclear_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "nuclear_grp", >> MainBatchUpload.sql
echo "h2_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "h2_grp" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select a.tablename, a.period, >> MainBatchUpload.sql
echo (sum(c."Coal")+sum("coal_rr"))*sum(a.coal) "coal_grp", >> MainBatchUpload.sql
echo (sum(c."Coal CCS")+sum("coalccs_rr"))*sum(a.coal) "coalccs_grp", >> MainBatchUpload.sql
echo (sum(c."Natural Gas")+sum("gas_rr"))*sum(a.gas) "gas_grp", >> MainBatchUpload.sql
echo (sum(c."Natural Gas CCS")+sum("gasccs_rr"))*sum(a.gas) "gasccs_grp", >> MainBatchUpload.sql
echo (sum(c."Coal")+sum("coal_rr"))*sum(a.oilcoal) + sum(c."Oil")*sum(a.oil) "oil_grp", >> MainBatchUpload.sql
echo sum(c."OIL CCS")*sum(a.oil) + (sum(c."Coal CCS")+sum("coalccs_rr"))*sum(a.oilcoal) "oilccs_grp", >> MainBatchUpload.sql
echo sum(c."Biomass") + (sum(c."Coal")+sum("coal_rr"))*sum(a.biocoal) + >> MainBatchUpload.sql
echo (sum("Natural Gas")+sum("gas_rr"))*sum(a.biogas) + sum(c."Oil")*sum(a.biooil) "bio_grp", >> MainBatchUpload.sql
echo sum(c."Biomass CCS") + (sum(c."Coal CCS")+sum("coalccs_rr"))*sum(a.biocoal) + >> MainBatchUpload.sql
echo (sum(c."Natural Gas CCS")+sum("gasccs_rr"))*sum(a.biogas) + sum(c."OIL CCS")*sum(a.biooil) "bioccs_grp", >> MainBatchUpload.sql
echo sum(c."Nuclear") "nuclear_grp", >> MainBatchUpload.sql
echo sum(c."Hydrogen") "h2_grp" >> MainBatchUpload.sql
echo from cofiring_fuel_percents a full outer join retrofit_plants b >> MainBatchUpload.sql
echo on a.tablename=b.tablename and a.period=b.period >> MainBatchUpload.sql
echo full outer join waste_heat_type c >> MainBatchUpload.sql
echo on a.tablename=c.tablename and a.period=c.period >> MainBatchUpload.sql
echo group by a.tablename, a.period >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , elec_penalty as ( >> MainBatchUpload.sql
echo select a.tablename, a.period, >> MainBatchUpload.sql
echo case when coal_grp*b."ELCGEN" is null then 0 else coal_grp*b."ELCGEN" end "coal", >> MainBatchUpload.sql
echo case when coalccs_grp*b."ELCGEN" is null then 0 else coalccs_grp*b."ELCGEN" end "coalccs", >> MainBatchUpload.sql
echo case when gas_grp*b."ELCGEN" is null then 0 else gas_grp*b."ELCGEN" end "gas", >> MainBatchUpload.sql
echo case when gasccs_grp*b."ELCGEN" is null then 0 else gasccs_grp*b."ELCGEN" end "gasccs", >> MainBatchUpload.sql
echo case when oil_grp*b."ELCGEN" is null then 0 else oil_grp*b."ELCGEN" end "oil", >> MainBatchUpload.sql
echo case when oilccs_grp*b."ELCGEN" is null then 0 else oilccs_grp*b."ELCGEN" end "oilccs", >> MainBatchUpload.sql
echo case when bio_grp*b."ELCGEN" is null then 0 else bio_grp*b."ELCGEN" end "bio", >> MainBatchUpload.sql
echo case when bioccs_grp*b."ELCGEN" is null then 0 else bioccs_grp*b."ELCGEN" end "bioccs", >> MainBatchUpload.sql
echo case when nuclear_grp*b."ELCGEN" is null then 0 else nuclear_grp*b."ELCGEN" end "nuclear", >> MainBatchUpload.sql
echo case when h2_grp*b."ELCGEN" is null then 0 else h2_grp*b."ELCGEN" end "h2" >> MainBatchUpload.sql
echo from fuel_shares_to_groups a >> MainBatchUpload.sql
echo left join ( >> MainBatchUpload.sql
echo select tablename, period, >> MainBatchUpload.sql
echo sum(pv) "ELCGEN" >> MainBatchUpload.sql
echo from elc_waste_heat_process >> MainBatchUpload.sql
echo group by tablename, period >> MainBatchUpload.sql
echo ) b >> MainBatchUpload.sql
echo on a.tablename=b.tablename and a.period=b.period >> MainBatchUpload.sql
echo order by period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo select cols ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when cols='elec-gen_intercon' then 'various'::varchar >> MainBatchUpload.sql
echo when cols='elec-gen_waste-heat-penalty' then 'VAR_FIn'::varchar >> MainBatchUpload.sql
echo else 'VAR_FOut'::varchar >> MainBatchUpload.sql
echo end ^|^| '^|various^|various'::varchar "id", >> MainBatchUpload.sql
echo cols::varchar "analysis", >> MainBatchUpload.sql
echo tablename, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when cols='elec-gen_intercon' then 'various'::varchar >> MainBatchUpload.sql
echo when cols='elec-gen_waste-heat-penalty' then 'VAR_FIn'::varchar >> MainBatchUpload.sql
echo else 'VAR_FOut'::varchar >> MainBatchUpload.sql
echo end "attribute", >> MainBatchUpload.sql
echo 'various'::varchar "commodity", >> MainBatchUpload.sql
echo 'various'::varchar "process", >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when cols='elec-gen_inten' then avg(vals) >> MainBatchUpload.sql
echo else sum(vals) >> MainBatchUpload.sql
echo end "all", >> MainBatchUpload.sql
echo sum(case when d.period='2010' then vals else 0 end) as "2010" , >> MainBatchUpload.sql
echo sum(case when d.period='2011' then vals else 0 end) as "2011", >> MainBatchUpload.sql
echo sum(case when d.period='2012' then vals else 0 end) as "2012", >> MainBatchUpload.sql
echo sum(case when d.period='2015' then vals else 0 end) as "2015", >> MainBatchUpload.sql
echo sum(case when d.period='2020' then vals else 0 end) as "2020", >> MainBatchUpload.sql
echo sum(case when d.period='2025' then vals else 0 end) as "2025", >> MainBatchUpload.sql
echo sum(case when d.period='2030' then vals else 0 end) as "2030", >> MainBatchUpload.sql
echo sum(case when d.period='2035' then vals else 0 end) as "2035", >> MainBatchUpload.sql
echo sum(case when d.period='2040' then vals else 0 end) as "2040", >> MainBatchUpload.sql
echo sum(case when d.period='2045' then vals else 0 end) as "2045", >> MainBatchUpload.sql
echo sum(case when d.period='2050' then vals else 0 end) as "2050", >> MainBatchUpload.sql
echo sum(case when d.period='2055' then vals else 0 end) as "2055", >> MainBatchUpload.sql
echo sum(case when d.period='2060' then vals else 0 end) as "2060" >> MainBatchUpload.sql
echo from( >> MainBatchUpload.sql
echo SELECT unnest(array['elec-gen_coal','elec-gen_coal-ccs','elec-gen_nga','elec-gen_nga-ccs','elec-gen_other-ff','elec-gen_bio' >> MainBatchUpload.sql
echo ,'elec-gen_bio-ccs','elec-gen_other-rens','elec-gen_solar','elec-gen_nuclear','elec-gen_offw','elec-gen_onw','elec-gen_chp','elec-gen_total-cen' >> MainBatchUpload.sql
echo ,'elec-gen_intercon','elec-gen_waste-heat-penalty','elec-gen_inten']) AS "cols", >> MainBatchUpload.sql
echo tablename,period, >> MainBatchUpload.sql
echo unnest(array["elec-gen_coal","elec-gen_coal-ccs","elec-gen_nga","elec-gen_nga-ccs","elec-gen_other-ff","elec-gen_bio","elec-gen_bio-ccs" >> MainBatchUpload.sql
echo ,"elec-gen_other-rens","elec-gen_solar","elec-gen_nuclear","elec-gen_offw","elec-gen_onw","elec-gen_chp","elec-gen_total-cen","elec-gen_intercon", >> MainBatchUpload.sql
echo "elec-gen_waste-heat-penalty","elec-gen_inten"]) AS "vals" >> MainBatchUpload.sql
echo FROM ( >> MainBatchUpload.sql
echo select a.tablename,a.period, "coal-unad"*b.coal-d.coal "elec-gen_coal", >> MainBatchUpload.sql
echo "coalccs-unad"*b.coal-d.coalccs "elec-gen_coal-ccs", >> MainBatchUpload.sql
echo "gas-unad"*b.gas-d.gas "elec-gen_nga", >> MainBatchUpload.sql
echo "gasccs-unad"*b.gas-d.gasccs "elec-gen_nga-ccs", >> MainBatchUpload.sql
echo ("ELC FROM OIL"*b.oil+"coal-unad"*b.oilcoal)-d.oil >> MainBatchUpload.sql
echo +("ELC FROM OIL CCS"*b.oil+"coalccs-unad"*b.oilcoal)-d.oilccs >> MainBatchUpload.sql
echo +"ELC FROM MANFUELS" >> MainBatchUpload.sql
echo "elec-gen_other-ff", >> MainBatchUpload.sql
echo ("ELC FROM BIO"+"coal-unad"*biocoal+"ELC FROM OIL"*biooil+"gas-unad"*b.biogas)-d.bio "elec-gen_bio", >> MainBatchUpload.sql
echo ("ELC FROM BIO CCS"+"coalccs-unad"*biocoal+"ELC FROM OIL CCS"*biooil+"gasccs-unad"*b.biogas)-d.bioccs "elec-gen_bio-ccs", >> MainBatchUpload.sql
echo "elec-gen_other-rens"-d.h2 "elec-gen_other-rens", >> MainBatchUpload.sql
echo "elec-gen_solar", >> MainBatchUpload.sql
echo "elec-gen_nuclear"-d.nuclear "elec-gen_nuclear", >> MainBatchUpload.sql
echo "elec-gen_offw", >> MainBatchUpload.sql
echo "elec-gen_onw", >> MainBatchUpload.sql
echo "elec-gen_chp", >> MainBatchUpload.sql
echo "coal-unad"*b.coal-d.coal+"coalccs-unad"*b.coal-d.coalccs+"gas-unad"*b.gas-d.gas+"gasccs-unad"*b.gas-d.gasccs+("ELC FROM OIL"*b.oil+"coal-unad"*b.oilcoal)-d.oil+ >> MainBatchUpload.sql
echo ("ELC FROM OIL CCS"*b.oil+"coalccs-unad"*b.oilcoal)-d.oilccs+"ELC FROM MANFUELS"+("ELC FROM BIO"+"coal-unad"*b.biocoal+"ELC FROM OIL"*b.biooil+ >> MainBatchUpload.sql
echo "gas-unad"*b.biogas)-d.bio+("ELC FROM BIO CCS"+"coalccs-unad"*b.biocoal+"ELC FROM OIL CCS"*b.biooil+ >> MainBatchUpload.sql
echo "gasccs-unad"*b.biogas)-d.bioccs+"elec-gen_other-rens"-d.h2+"elec-gen_solar"+"elec-gen_nuclear"-d.nuclear+"elec-gen_offw"+"elec-gen_onw"+"elec-gen_chp" "elec-gen_total-cen", >> MainBatchUpload.sql
echo "elec-gen_intercon", >> MainBatchUpload.sql
echo "elec-gen_waste-heat-penalty", >> MainBatchUpload.sql
echo "elc-emis"/ >> MainBatchUpload.sql
echo ("coal-unad"*b.coal+"coalccs-unad"*b.coal+"gas-unad"*b.gas+"gasccs-unad"*b.gas+"ELC FROM OIL"*b.oil+"coal-unad"*b.oilcoal+"ELC FROM OIL CCS"*b.oil+"coalccs-unad"*b.oilcoal+ >> MainBatchUpload.sql
echo "ELC FROM MANFUELS"+"ELC FROM BIO"+"coal-unad"*b.biocoal+"ELC FROM OIL"*b.biooil+"gas-unad"*b.biogas+"ELC FROM BIO CCS"+"coalccs-unad"*b.biocoal+"ELC FROM OIL CCS"*b.biooil+ >> MainBatchUpload.sql
echo "gasccs-unad"*b.biogas+"elec-gen_other-rens"+"elec-gen_solar"+"elec-gen_nuclear"+"elec-gen_offw"+"elec-gen_onw"+"elec-gen_chp"-"elec-gen_waste-heat-penalty" >> MainBatchUpload.sql
echo -(case when "elec-gen_intercon"^<0 then "elec-gen_intercon" else 0 end))*3600 >> MainBatchUpload.sql
echo "elec-gen_inten" >> MainBatchUpload.sql
echo from( >> MainBatchUpload.sql
echo select a.period, a.tablename, >> MainBatchUpload.sql
echo sum(case when proc_set='ELC TO EXPORTS' then -pv when proc_set='ELC FROM IMPORTS' then pv else 0 end) "elec-gen_intercon", >> MainBatchUpload.sql
echo sum(case when proc_set in ('ELC FROM TIDAL','ELC FROM WAVE','ELC FROM GEO','ELC FROM HYDRO','ELC FROM HYDROGEN') then pv else 0 end) "elec-gen_other-rens", >> MainBatchUpload.sql
echo sum(case when proc_set in ('ELC FROM SOL-PV') then pv else 0 end) "elec-gen_solar", >> MainBatchUpload.sql
echo sum(case when proc_set in ('ELC FROM NUCLEAR') then pv else 0 end) "elec-gen_nuclear", >> MainBatchUpload.sql
echo sum(case when proc_set in ('ELC FROM WIND-OFFSH') then pv else 0 end) "elec-gen_offw", >> MainBatchUpload.sql
echo sum(case when proc_set in ('ELC FROM WIND-ONSH') then pv else 0 end) "elec-gen_onw", >> MainBatchUpload.sql
echo sum(case when proc_set in ('elec-gen_chp') then pv else 0 end) "elec-gen_chp", >> MainBatchUpload.sql
echo sum(case when proc_set='ELC FROM COAL-COF' then pv else 0 end)+sum(case when proc_set='ELC FROM COAL RR' then pv else 0 end) "coal-unad", >> MainBatchUpload.sql
echo sum(case when proc_set='ELC FROM COALCOF CCS' then pv else 0 end)+sum(case when proc_set='ELC FROM COAL CCSRET' then pv else 0 end) "coalccs-unad", >> MainBatchUpload.sql
echo sum(case when proc_set='ELC FROM GAS' then pv else 0 end)+sum(case when proc_set='ELC FROM GAS RR' then pv else 0 end) "gas-unad", >> MainBatchUpload.sql
echo sum(case when proc_set='ELC FROM GAS CCS' then pv else 0 end)+sum(case when proc_set='ELC FROM GAS CCSRET' then pv else 0 end) "gasccs-unad", >> MainBatchUpload.sql
echo sum(case when proc_set='ELC FROM OIL' then pv else 0 end) "ELC FROM OIL", >> MainBatchUpload.sql
echo sum(case when proc_set='ELC FROM OIL CCS' then pv else 0 end) "ELC FROM OIL CCS", >> MainBatchUpload.sql
echo sum(case when proc_set='ELC FROM MANFUELS' then pv else 0 end) "ELC FROM MANFUELS", >> MainBatchUpload.sql
echo sum(case when proc_set='ELC FROM BIO' then pv else 0 end) "ELC FROM BIO", >> MainBatchUpload.sql
echo sum(case when proc_set='ELC FROM BIO CCS' then pv else 0 end) "ELC FROM BIO CCS", >> MainBatchUpload.sql
echo sum(case when proc_set='elec-gen_waste-heat-penalty' then pv else 0 end) "elec-gen_waste-heat-penalty" >> MainBatchUpload.sql
echo from elc_prd_fuel a >> MainBatchUpload.sql
echo group by a.tablename, a.period >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo left join cofiring_fuel_percents b >> MainBatchUpload.sql
echo on a.tablename=b.tablename and a.period=b.period >> MainBatchUpload.sql
echo left join "elc-emis" c >> MainBatchUpload.sql
echo on a.tablename=c.tablename and a.period=c.period >> MainBatchUpload.sql
echo left join "elec_penalty" d >> MainBatchUpload.sql
echo on a.tablename=d.tablename and a.period=d.period >> MainBatchUpload.sql
echo ) c >> MainBatchUpload.sql
echo ) d >> MainBatchUpload.sql
echo group by tablename,cols >> MainBatchUpload.sql
echo ORDER BY tablename,analysis >> MainBatchUpload.sql
echo ) TO '%~dp0ElecGenOut.csv' delimiter ',' CSV; >> MainBatchUpload.sql
rem /* *Electricity storage by type* */echo /* *Electricity storage by type* */ >> MainBatchUpload.sql
echo copy ( >> MainBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| '-^|various'::varchar(300) "id", >> MainBatchUpload.sql
echo analysis::varchar(50), tablename,attribute,commodity,'various'::varchar(50) "process", >> MainBatchUpload.sql
echo sum(pv)::numeric "all", >> MainBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> MainBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> MainBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> MainBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> MainBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> MainBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> MainBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> MainBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> MainBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> MainBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> MainBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> MainBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> MainBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select process,period,pv, >> MainBatchUpload.sql
echo 'elec-stor-out_' ^|^| >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('EHYDPMP00','EHYDPMP01') then 'hyd' >> MainBatchUpload.sql
echo when process in ('ECAESCON01','ESTGCAES01','ECAESTUR01','ESTGAACAES01') then 'caes' >> MainBatchUpload.sql
echo when process in ('ESTGBNAS01','ESTGBALA01','ESTGBRF01') then 'batt' >> MainBatchUpload.sql
echo end as "analysis", tablename, attribute,commodity >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute = 'VAR_FOut' and commodity='ELC' >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where analysis is not null >> MainBatchUpload.sql
echo group by id,analysis,tablename,attribute,commodity >> MainBatchUpload.sql
echo order by tablename, analysis >> MainBatchUpload.sql
echo ) to '%~dp0ElecStor.csv' delimiter ',' CSV; >> MainBatchUpload.sql
rem /* *Electricity capacity by process* */echo /* *Electricity capacity by process* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| '-^|various'::varchar(300) "id", analysis, tablename,attribute, >> MainBatchUpload.sql
echo '-'::varchar(50) "commodity", >> MainBatchUpload.sql
echo 'various'::varchar(50) "process", >> MainBatchUpload.sql
echo sum(pv)::numeric "all", >> MainBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> MainBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> MainBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> MainBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> MainBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> MainBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> MainBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> MainBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> MainBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> MainBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> MainBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> MainBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> MainBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select process, >> MainBatchUpload.sql
echo period,pv, >> MainBatchUpload.sql
echo 'elec-cap_' ^|^| >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('ESTWWST00','EPOLWST00', 'EBIOS00','EBOG-LFE00','EBOG-SWE00', >> MainBatchUpload.sql
echo 'EMSW00','EBIOCON00','ESTWWST01','EBIO01','EBOG-ADE01', >> MainBatchUpload.sql
echo 'EBOG-LFE01','EBOG-SWE01','EMSW01') then 'bio' >> MainBatchUpload.sql
echo when process = 'EBIOQ01' then 'bio-ccs' >> MainBatchUpload.sql
echo when process in('ECOA00','ECOABIO00', 'ECOARR01') then 'coal' >> MainBatchUpload.sql
echo when process in('ECOAQ01' ,'ECOAQDEMO01','ECOAQR01') then 'coal-ccs' >> MainBatchUpload.sql
echo when process in('EHYGCCT01' ,'EHYGOCT01') then 'h2' >> MainBatchUpload.sql
echo when process in('ENGACCT00','ENGACCTRR01','ENGAOCT00','ENGAOCT01','ENGARCPE00','ENGARCPE01') then >> MainBatchUpload.sql
echo 'nga' >> MainBatchUpload.sql
echo when process in('ENGACCTQ01','ENGACCTQDEMO01','ENGAQR01') then 'nga-ccs' >> MainBatchUpload.sql
echo when process in('ENUCPWR00','ENUCPWR101','ENUCPWR102') then >> MainBatchUpload.sql
echo 'nuclear' >> MainBatchUpload.sql
echo when process in('EWNDOFF00','EWNDOFF101','EWNDOFF201') then 'offw' >> MainBatchUpload.sql
echo when process in('EWNDONS00','EWNDONS101','EWNDONS201') then 'onw' >> MainBatchUpload.sql
echo when process ='EHFOIGCCQ01' then 'other-ccs' >> MainBatchUpload.sql
echo when process in('EOILL00','EOILL01','EMANOCT00','EMANOCT01','EOILS00','EOILS01','EHFOIGCC01','EDSTRCPE00','EDSTRCPE01') then >> MainBatchUpload.sql
echo 'other-ff' >> MainBatchUpload.sql
echo when process in('EHYD00','EHYD01','EGEO01','ETIR101','ETIB101','ETIS101','EWAV101') then >> MainBatchUpload.sql
echo 'other-rens' >> MainBatchUpload.sql
echo when process in('ESOL00','ESOLPV00','ESOL01','ESOLPV01') then 'solar' >> MainBatchUpload.sql
echo when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01', >> MainBatchUpload.sql
echo 'ICHCHPCCGT01','ICHCHPCCGTH01','ICHCHPCOA00','ICHCHPCOA01', >> MainBatchUpload.sql
echo 'ICHCHPFCH01','ICHCHPGT01','ICHCHPHFO00','ICHCHPLFO00', >> MainBatchUpload.sql
echo 'ICHCHPLPG00','ICHCHPLPG01','ICHCHPNGA00','ICHCHPPRO00', >> MainBatchUpload.sql
echo 'ICHCHPPRO01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01', >> MainBatchUpload.sql
echo 'IFDCHPCCGT01','IFDCHPCCGTH01','IFDCHPCOA00','IFDCHPCOA01', >> MainBatchUpload.sql
echo 'IFDCHPFCH01','IFDCHPGT01','IFDCHPHFO00','IFDCHPLFO00', >> MainBatchUpload.sql
echo 'IFDCHPNGA00','IISCHPBFG00','IISCHPBFG01','IISCHPBIOG01', >> MainBatchUpload.sql
echo 'IISCHPBIOS01','IISCHPCCGT01','IISCHPCCGTH01','IISCHPCOG00', >> MainBatchUpload.sql
echo 'IISCHPCOG01','IISCHPFCH01','IISCHPGT01','IISCHPHFO00', >> MainBatchUpload.sql
echo 'IISCHPNGA00','INMCHPBIOG01','INMCHPBIOS01','INMCHPCCGT01', >> MainBatchUpload.sql
echo 'INMCHPCCGTH01','INMCHPCOA01','INMCHPCOG00','INMCHPCOG01', >> MainBatchUpload.sql
echo 'INMCHPFCH01','INMCHPGT01','INMCHPNGA00','IOICHPBIOG01', >> MainBatchUpload.sql
echo 'IOICHPBIOS00','IOICHPBIOS01','IOICHPCCGT01','IOICHPCCGTH01', >> MainBatchUpload.sql
echo 'IOICHPCOA01','IOICHPFCH01','IOICHPGT01','IOICHPHFO00', >> MainBatchUpload.sql
echo 'IOICHPNGA00','IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01', >> MainBatchUpload.sql
echo 'IPPCHPCCGT01','IPPCHPCCGTH01','IPPCHPCOA00','IPPCHPCOA01', >> MainBatchUpload.sql
echo 'IPPCHPFCH01','IPPCHPGT01','IPPCHPNGA00','IPPCHPWST00', >> MainBatchUpload.sql
echo 'IPPCHPWST01','PCHP-CCP00','PCHP-CCP01','RCHPEA-CCG00', >> MainBatchUpload.sql
echo 'RCHPEA-CCG01','RCHPEA-CCH01','RCHPEA-FCH01','RCHPEA-STW01', >> MainBatchUpload.sql
echo 'RCHPNA-CCG01','RCHPNA-CCH01','RCHPNA-FCH01','RCHPNA-STW01', >> MainBatchUpload.sql
echo 'RHEACHPRG01','RHEACHPRH01','RHEACHPRW01','RHNACHPRG01', >> MainBatchUpload.sql
echo 'RHNACHPRH01','RHNACHPRW01','RCHPEA-EFW01','RCHPNA-EFW01', >> MainBatchUpload.sql
echo 'SCHP-ADM01','SCHP-CCG00','SCHP-CCG01','SCHP-CCH01', >> MainBatchUpload.sql
echo 'SCHP-FCH01','SCHP-GES00','SCHP-GES01','SCHP-STM01', >> MainBatchUpload.sql
echo 'SCHP-STW00','SCHP-STW01','SHLCHPRG01','SHLCHPRH01', >> MainBatchUpload.sql
echo 'SHLCHPRW01','SCHP-EFW01','UCHP-CCG00','UCHP-CCG01', >> MainBatchUpload.sql
echo 'RHFCCHPRH01','RHFSCHPRH01','RHHCCHPRH01','RHHSCHPRH01', >> MainBatchUpload.sql
echo 'RHFCCHPRG01','RHFSCHPRG01','RHHCCHPRG01','RHHSCHPRG01', >> MainBatchUpload.sql
echo 'RHFCCHPRW01','RHFSCHPRW01','RHHCCHPRW01','RHHSCHPRW01') then 'chp' >> MainBatchUpload.sql
echo when process in('ELCIE00','ELCII00','ELCIE01','ELCII01') then 'intercon' >> MainBatchUpload.sql
echo when process in('EHYDPMP00','EHYDPMP01') then 'hyd' >> MainBatchUpload.sql
echo when process in ('ECAESCON01','ESTGCAES01','ECAESTUR01','ESTGAACAES01') then 'caes' >> MainBatchUpload.sql
echo when process in ('ESTGBNAS01','ESTGBALA01','ESTGBRF01') then 'batt' >> MainBatchUpload.sql
echo end::varchar(50) as "analysis", >> MainBatchUpload.sql
echo tablename, attribute >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute = 'VAR_Cap' and commodity = '-' >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where analysis is not null >> MainBatchUpload.sql
echo group by id, analysis,tablename, attribute >> MainBatchUpload.sql
echo order by tablename,  analysis, attribute, commodity >> MainBatchUpload.sql
echo ) TO '%~dp0ElecCap.csv' delimiter ',' CSV; >> MainBatchUpload.sql
rem /* *costs by sector and type* */echo /* *costs by sector and type* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^|'^|'^|^| attribute ^|^| '^|various' ^|^| '^|various'::varchar(300) "id", analysis, tablename,attribute, >> MainBatchUpload.sql
echo 'various'::varchar(50) "commodity", >> MainBatchUpload.sql
echo 'various'::varchar(50) "process", >> MainBatchUpload.sql
echo sum(pv)::numeric "various", >> MainBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> MainBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> MainBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> MainBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> MainBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> MainBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> MainBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> MainBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> MainBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> MainBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> MainBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> MainBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> MainBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select process, >> MainBatchUpload.sql
echo period,pv, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process like 'T%%' then 'costs_tra' >> MainBatchUpload.sql
echo when process like 'A%%' then 'costs_agr' >> MainBatchUpload.sql
echo when process like 'E%%' AND process not like 'EXP%%' then 'costs_elc' >> MainBatchUpload.sql
echo when process like 'I%%' AND process not like 'IMP%%' then 'costs_ind' >> MainBatchUpload.sql
echo when process like 'P%%' or process like 'C%%' then 'costs_prc' >> MainBatchUpload.sql
echo when process like 'R%%' then 'costs_res' >> MainBatchUpload.sql
echo when process like any(array['M%%','U%%','IMP%%','EXP%%']) then 'costs_rsr' >> MainBatchUpload.sql
echo when process like 'S%%' then 'costs_ser' >> MainBatchUpload.sql
echo else 'costs_other' >> MainBatchUpload.sql
echo end::varchar(50) as "analysis",tablename, attribute >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute in('Cost_Act', 'Cost_Flo', 'Cost_Fom', 'Cost_Inv', 'Cost_Salv') >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select 'various'::varchar(50) "process", >> MainBatchUpload.sql
echo period,pv, >> MainBatchUpload.sql
echo 'costs_all'::varchar(50) "analysis", >> MainBatchUpload.sql
echo tablename, >> MainBatchUpload.sql
echo attribute >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute in('Cost_Act','Cost_Flo','Cost_Fom','Cost_Inv','Cost_Salv','ObjZ') >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo group by id, analysis, tablename, attribute >> MainBatchUpload.sql
echo order by tablename,  analysis, attribute >> MainBatchUpload.sql
echo ) TO '%~dp0CostsBySec.csv' delimiter ',' CSV; >> MainBatchUpload.sql
rem /* *Marginal prices for emissions* */echo /* *Marginal prices for emissions* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo select 'marg-price^|' ^|^| tablename ^|^| '^|EQ_CombalM^|' ^|^| commodity ^|^| '^|-'::varchar(300) "id", >> MainBatchUpload.sql
echo 'marg-price'::varchar(50) "analysis", >> MainBatchUpload.sql
echo tablename, >> MainBatchUpload.sql
echo 'EQ_CombalM'::varchar(50) "attribute", >> MainBatchUpload.sql
echo commodity, >> MainBatchUpload.sql
echo '-'::varchar(50) "process", >> MainBatchUpload.sql
echo NULL::numeric "all", >> MainBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> MainBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> MainBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> MainBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> MainBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> MainBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> MainBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> MainBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> MainBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> MainBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> MainBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> MainBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> MainBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='EQ_CombalM' and commodity in('GHG-NO-IAS-YES-LULUCF-NET','GHG-NO-AS-YES-LULUCF-NET', >> MainBatchUpload.sql
echo 'GHG-ETS-NO-IAS-NET','GHG-YES-IAS-YES-LULUCF-NET','GHG-ETS-YES-IAS-NET') >> MainBatchUpload.sql
echo group by tablename, commodity >> MainBatchUpload.sql
echo order by tablename, commodity >> MainBatchUpload.sql
echo ) TO '%~dp0MarginalPricesOut.csv' delimiter ',' CSV; >> MainBatchUpload.sql
rem /* *Whole stock heat output by process for residential* */echo /* *Whole stock heat output by process for residential* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| 'various^|various'::varchar(300) "id", analysis::varchar(50), tablename,attribute, >> MainBatchUpload.sql
echo 'various'::varchar(50) "commodity", >> MainBatchUpload.sql
echo 'various'::varchar(50) "process", >> MainBatchUpload.sql
echo sum(pv)::numeric "all", >> MainBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> MainBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> MainBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> MainBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> MainBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> MainBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> MainBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> MainBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> MainBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> MainBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> MainBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> MainBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> MainBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select process, >> MainBatchUpload.sql
echo period,pv, >> MainBatchUpload.sql
echo 'heat-res_' ^|^| >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in ('RHEABLCRP01','RHEABLRRW00','RHEABLRRW01','RHEABLSRP01','RHEABLSRW01', >> MainBatchUpload.sql
echo 'RHNABLCRP01','RHNABLRRW01','RHNABLSRP01','RHNABLSRW01') then 'boiler-bio' >> MainBatchUpload.sql
echo when process in('RHEABLCRH01','RHEABLSRH01','RHNABLCRH01','RHNABLSRH01') then 'boiler-h2' >> MainBatchUpload.sql
echo when process in('RHEABLCRO00','RHEABLCRO01','RHEABLRRC00','RHEABLRRO00','RHEABLSRO01','RHNABLCRO01' >> MainBatchUpload.sql
echo ,'RHNABLSRO01') then 'boiler-otherFF' >> MainBatchUpload.sql
echo when process in('RHEABLRRE00','RHEABLRRE01','RHEABLSRE01','RHEASHTRE00', >> MainBatchUpload.sql
echo 'RHEASHTRE01','RHNABLRRE01','RHNABLSRE01','RHNAGHPUE01','RHNASHTRE01', >> MainBatchUpload.sql
echo 'RWEAWHTRE00','RWEAWHTRE01','RWNAWHTRE01') then 'boiler/heater-elec' >> MainBatchUpload.sql
echo when process in('RHEABLCRG00','RHEABLCRG01', >> MainBatchUpload.sql
echo 'RHEABLRRG00','RHEABLSRG01','RHEASHTRG00','RHEASHTRG01','RHNABLCRG01', >> MainBatchUpload.sql
echo 'RHNABLSRG01','RHNASHTRG01','RWEAWHTRG00','RWEAWHTRG01','RWNAWHTRG01') then >> MainBatchUpload.sql
echo 'boiler/heater-nga' >> MainBatchUpload.sql
echo when process='RHEACSVCAV01' then 'easy-cav' >> MainBatchUpload.sql
echo when process='RHEACSVCAV02' then 'hard-cav' >> MainBatchUpload.sql
echo when process='RHEACSVSOL01' then 'solid-sysbld' >> MainBatchUpload.sql
echo when process in('RHEACSVLOF01','RHEACSVFLR01', >> MainBatchUpload.sql
echo 'RHEACSVWIN01','RHEACSVFLU01','RHEACSVDFT01','RHEACSVCON01','RHEACSVCYL01') then >> MainBatchUpload.sql
echo 'other-conserv' >> MainBatchUpload.sql
echo when process in('RHEADHP100','RHEADHP101','RHEADHP201','RHEADHP301','RHEADHP401', >> MainBatchUpload.sql
echo 'RHNADHP101','RHNADHP201','RHNADHP301','RHNADHP401') then 'dh' >> MainBatchUpload.sql
echo when process in('RHEAAHPRE00','RHEAAHPRE01','RHEAAHPUE01','RHEAAHSRE01', 'RHEAAHSUE01', >> MainBatchUpload.sql
echo 'RHEAGHPRE01','RHEAGHPUE01','RHEAGHSRE01','RHEAGHSUE01','RHNAAHPRE01','RHNAAHPUE01', >> MainBatchUpload.sql
echo 'RHNAAHSRE01','RHNAAHSUE01','RHNAGHPRE01','RHNAGHSRE01','RHNAGHSUE01') then >> MainBatchUpload.sql
echo 'heatpump-elec' >> MainBatchUpload.sql
echo when process in('RHEAAHHRE01','RHEAAHHUE01', >> MainBatchUpload.sql
echo 'RHEAGHHRE01','RHEAGHHUE01','RHNAAHHRE01','RHNAAHHUE01','RHNAGHHRE01','RHNAGHHUE01') then >> MainBatchUpload.sql
echo 'hyb-boil+hp-h2' >> MainBatchUpload.sql
echo when process in('RHEAAHBRE01','RHEAAHBUE01', >> MainBatchUpload.sql
echo 'RHEAGHBRE01','RHEAGHBUE01','RHNAAHBRE01','RHNAAHBUE01','RHNAGHBRE01','RHNAGHBUE01') then >> MainBatchUpload.sql
echo 'hyb-boil+hp-nga' >> MainBatchUpload.sql
echo when process in('RHEACHPRW01','RHNACHPRW01','RHFCCHPRW01', >> MainBatchUpload.sql
echo 'RHFSCHPRW01','RHHCCHPRW01','RHHSCHPRW01') then 'microchp-bio' >> MainBatchUpload.sql
echo when process in('RHEACHBRH01','RHEACHPRH01','RHNACHBRH01', >> MainBatchUpload.sql
echo 'RHNACHPRH01','RHFCCHPRH01','RHFSCHPRH01','RHHCCHPRH01','RHHSCHPRH01' >> MainBatchUpload.sql
echo ) then 'microchp-h2' >> MainBatchUpload.sql
echo when process in('RHEACHPRG01','RHNACHPRG01','RHFCCHPRG01', >> MainBatchUpload.sql
echo 'RHFSCHPRG01','RHHCCHPRG01','RHHSCHPRG01') then 'microchp-nga' >> MainBatchUpload.sql
echo when process in('RHEANSTRE00','RHEANSTRE01','RHEASTGNT00','RHEASTGNT01', >> MainBatchUpload.sql
echo 'RHNANSTRE01','RHNASTGNT01') then 'storheater-elec' >> MainBatchUpload.sql
echo else 'heat-res_other' >> MainBatchUpload.sql
echo end::varchar(50) as "analysis", >> MainBatchUpload.sql
echo tablename, attribute >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute = 'VAR_FOut' AND commodity in('RHCSV-RHEA','RHEATPIPE-EA','RHEATPIPE-NA','RHSTAND-EA', >> MainBatchUpload.sql
echo 'RHSTAND-NA','RHUFLOOR-EA','RHUFLOOR-NA','RWCSV-RWEA','RWSTAND-EA','RWSTAND-NA') >> MainBatchUpload.sql
echo group by period,process, pv,tablename, id, analysis, attribute order by tablename, attribute >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo group by id, analysis,tablename, attribute >> MainBatchUpload.sql
echo order by tablename,  analysis, attribute, commodity >> MainBatchUpload.sql
echo ) TO '%~dp0ResWholeHeatOut.csv' delimiter ',' CSV; >> MainBatchUpload.sql
rem /* *New build residential heat output by source* */echo /* *New build residential heat output by source* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| 'various^|various'::varchar(300) "id", analysis::varchar(50), tablename,attribute, >> MainBatchUpload.sql
echo 'various'::varchar(50) "commodity", >> MainBatchUpload.sql
echo 'various'::varchar(50) "process", >> MainBatchUpload.sql
echo sum(pv)::numeric "all", >> MainBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> MainBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> MainBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> MainBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> MainBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> MainBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> MainBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> MainBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> MainBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> MainBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> MainBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> MainBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> MainBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select process,commodity, >> MainBatchUpload.sql
echo period,pv, >> MainBatchUpload.sql
echo 'new-heat-res_' ^|^| >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('RHEABLCRP01','RHEABLRRW01','RHEABLSRP01', >> MainBatchUpload.sql
echo 'RHEABLSRW01','RHNABLCRP01','RHNABLRRW01','RHNABLSRP01','RHNABLSRW01') then 'boiler-bio' >> MainBatchUpload.sql
echo when process in('RHEABLCRH01','RHEABLSRH01','RHNABLCRH01','RHNABLSRH01') then 'boiler-h2' >> MainBatchUpload.sql
echo when process in('RHEABLCRO01','RHEABLSRO01','RHNABLCRO01','RHNABLSRO01') then 'boiler-otherFF' >> MainBatchUpload.sql
echo when process in('RHEABLRRE01','RHEABLSRE01','RHEASHTRE01','RHNABLRRE01', >> MainBatchUpload.sql
echo 'RHNABLSRE01','RHNAGHPUE01','RHNASHTRE01','RWEAWHTRE01','RWNAWHTRE01') >> MainBatchUpload.sql
echo then 'boiler/heater-elec' >> MainBatchUpload.sql
echo when process in('RHEABLCRG01','RHEABLSRG01','RHEASHTRG01','RHNABLCRG01','RHNABLSRG01','RHNASHTRG01' >> MainBatchUpload.sql
echo ,'RWEAWHTRG01','RWNAWHTRG01') then 'boiler/heater-nga' >> MainBatchUpload.sql
echo when process='RHEACSVCAV01' then 'easy-cav' >> MainBatchUpload.sql
echo when process='RHEACSVCAV02' then 'hard-cav' >> MainBatchUpload.sql
echo when process='RHEACSVSOL01' then 'solid-sysbld' >> MainBatchUpload.sql
echo when process in('RHEACSVLOF01','RHEACSVFLR01', >> MainBatchUpload.sql
echo 'RHEACSVWIN01','RHEACSVFLU01','RHEACSVDFT01','RHEACSVCON01','RHEACSVCYL01') then >> MainBatchUpload.sql
echo 'other-conserv' >> MainBatchUpload.sql
echo when process in('RHEADHP101','RHEADHP201','RHEADHP301','RHEADHP401', >> MainBatchUpload.sql
echo 'RHNADHP101','RHNADHP201','RHNADHP301','RHNADHP401') then 'dh' >> MainBatchUpload.sql
echo when process in('RHEAAHPRE01','RHEAAHPUE01','RHEAAHSRE01','RHEAAHSUE01','RHEAGHPRE01', >> MainBatchUpload.sql
echo 'RHEAGHPUE01','RHEAGHSRE01','RHEAGHSUE01','RHNAAHPRE01','RHNAAHPUE01','RHNAAHSRE01', >> MainBatchUpload.sql
echo 'RHNAAHSUE01','RHNAGHPRE01','RHNAGHSRE01','RHNAGHSUE01') then 'heatpump-elec' >> MainBatchUpload.sql
echo when process in('RHEAAHHRE01','RHEAAHHUE01', >> MainBatchUpload.sql
echo 'RHEAGHHRE01','RHEAGHHUE01','RHNAAHHRE01','RHNAAHHUE01','RHNAGHHRE01','RHNAGHHUE01') then >> MainBatchUpload.sql
echo 'hyb-boil+hp-h2' >> MainBatchUpload.sql
echo when process in('RHEAAHBRE01','RHEAAHBUE01', >> MainBatchUpload.sql
echo 'RHEAGHBRE01','RHEAGHBUE01','RHNAAHBRE01','RHNAAHBUE01','RHNAGHBRE01','RHNAGHBUE01') then >> MainBatchUpload.sql
echo 'hyb-boil+hp-nga' >> MainBatchUpload.sql
echo when process in('RHEACHPRW01','RHNACHPRW01','RHFCCHPRW01', >> MainBatchUpload.sql
echo 'RHFSCHPRW01','RHHCCHPRW01','RHHSCHPRW01') then 'microchp-bio' >> MainBatchUpload.sql
echo when process in('RHEACHBRH01','RHEACHPRH01','RHNACHBRH01', >> MainBatchUpload.sql
echo 'RHNACHPRH01','RHFCCHPRH01','RHFSCHPRH01','RHHCCHPRH01','RHHSCHPRH01' >> MainBatchUpload.sql
echo ) then 'microchp-h2' >> MainBatchUpload.sql
echo when process in('RHEACHPRG01','RHNACHPRG01','RHFCCHPRG01', >> MainBatchUpload.sql
echo 'RHFSCHPRG01','RHHCCHPRG01','RHHSCHPRG01') then 'microchp-nga' >> MainBatchUpload.sql
echo when process in('RHEANSTRE01','RHEASTGNT01','RHNANSTRE01','RHNASTGNT01') then 'storheater-elec' >> MainBatchUpload.sql
echo end as "analysis", >> MainBatchUpload.sql
echo tablename, attribute >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute = 'VAR_FOut' AND commodity in('RHCSV-RHEA','RHEATPIPE-EA','RHEATPIPE-NA','RHSTAND-EA','RHSTAND-NA', >> MainBatchUpload.sql
echo 'RHUFLOOR-EA','RHUFLOOR-NA','RWCSV-RWEA','RWSTAND-EA','RWSTAND-NA') and vintage=period >> MainBatchUpload.sql
echo group by period,commodity,process, pv,tablename, id, analysis, attribute order by tablename, attribute >> MainBatchUpload.sql
echo ) a where analysis ^<^> '' >> MainBatchUpload.sql
echo group by id, analysis,tablename, attribute >> MainBatchUpload.sql
echo order by tablename,  analysis, attribute, commodity >> MainBatchUpload.sql
echo ) TO '%~dp0NewResHeatOut.csv' delimiter ',' CSV; >> MainBatchUpload.sql
rem /* *Whole stock heat output for services* */echo /* *Whole stock heat output for services* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| 'various^|various'::varchar(300) "id", analysis, tablename,attribute, >> MainBatchUpload.sql
echo 'various'::varchar(50) "commodity", >> MainBatchUpload.sql
echo 'various'::varchar(50) "process", >> MainBatchUpload.sql
echo sum(pv)::numeric "all", >> MainBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> MainBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> MainBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> MainBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> MainBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> MainBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> MainBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> MainBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> MainBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> MainBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> MainBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> MainBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> MainBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select process, >> MainBatchUpload.sql
echo period,pv, >> MainBatchUpload.sql
echo 'heat-ser_' ^|^| >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in ('SHLSHTRE00','SWLWHTRE00','SHLBLRRE01','SHLSHTRE01', >> MainBatchUpload.sql
echo 'SWLWHTRE01','SHLBLSRE01','SHHBLRRE00','SWHWHTRE00','SHHBLRRE01','SWHWHTRE01','SHLBLRRE00','SHH-BLRE01') >> MainBatchUpload.sql
echo then 'boiler/heater-elec' >> MainBatchUpload.sql
echo when process in('SHLBLCRG00','SHLSHTRG00','SWLWHTRG00','SHLBLCRG01','SWLWHTRG01', >> MainBatchUpload.sql
echo 'SHLBLSRG01','SHHBLRRG00','SWHBLRRG00','SHHBLRRG01','SWHBLRRG01','SHLBLRRG00','SHH-BLRG01') >> MainBatchUpload.sql
echo then 'boiler/heater-nga' >> MainBatchUpload.sql
echo when process in('SHLBLCRP01','SHLBLRRW01','SHLBLSRP01','SHLBLSRW01','SHHBLRRW00', >> MainBatchUpload.sql
echo 'SWHBLRRW00','SHHBLRRW01','SWHBLRRW01','SHLBLRRW00','SHH-BLRB01') >> MainBatchUpload.sql
echo then 'boiler-bio' >> MainBatchUpload.sql
echo when process in('SHLBLSRH01','SHHBLRRH01','SWHBLRRH01','SHLBLCRH01','SHH-BLRH01') >> MainBatchUpload.sql
echo then 'boiler-h2' >> MainBatchUpload.sql
echo when process in('SHLBLCRO00','SHLBLRRC00','SHLSHTRO00','SHLBLCRO01','SHLBLSRO01', >> MainBatchUpload.sql
echo 'SHHBLRRO00','SHHBLRRC00','SWHBLRRO00','SWHBLRRC00','SHHBLRRO01','SHHBLRRC01', >> MainBatchUpload.sql
echo 'SWHBLRRO01','SWHBLRRC01','SHLBLRRO00','SHH-BLRO01') >> MainBatchUpload.sql
echo then 'boiler-otherFF' >> MainBatchUpload.sql
echo when process in('SCSVSHL-METERS01','SCSVSHL-INSULAT01','SCSVSHL-GLAZING01','SCSVSHL-OTH_THM01', >> MainBatchUpload.sql
echo 'SCSVSHL-VENT_RC01','SCSVSHH-METERS01','SCSVSHH-INSULAT01','SCSVSHH-GLAZING01','SCSVSHH-OTH_THM01', >> MainBatchUpload.sql
echo 'SCSVSHH-VENT_RC01') then 'conserv' >> MainBatchUpload.sql
echo when process in('SHLAHBUE01','SHLGHBRE01','SHLGHBUE01','SHLAHBRE01') then  'hyb-boil+hp-nga' >> MainBatchUpload.sql
echo when process in('SHLAHPRE01','SHLAHPUE01','SHLAHSRE01','SHLAHSUE01','SHLAHPRE00','SHH-ASHP01','SHH-ASHP-R01') >> MainBatchUpload.sql
echo then 'heatpump-air-elec' >> MainBatchUpload.sql
echo when process in ('SHLGHPRE01','SHLGHPUE01','SHLGHSRE01','SHLGHSUE01','SHH-GSHP-V01','SHH-GSHP-H01') >> MainBatchUpload.sql
echo then 'heatpump-ground-elec' >> MainBatchUpload.sql
echo when process in('SHH-WSHP01') then 'heatpump-water-elec' >> MainBatchUpload.sql
echo when process in('SHHVACAE01','SHHVACAE00') then 'hvac' >> MainBatchUpload.sql
echo when process in('SHHVACAE02') then 'hvac-ad' >> MainBatchUpload.sql
echo when process in('SHLAHHUE01','SHLGHHRE01','SHLGHHUE01','SHLAHHRE01') then 'hyb-boil+hp-h2' >> MainBatchUpload.sql
echo when process in('SHLDHP101','SHHDHP100','SHHDHP101','SHLDHP100') then 'dh' >> MainBatchUpload.sql
echo when process in('SHLCHPRW01') then 'microchp-bio' >> MainBatchUpload.sql
echo when process in('SHLCHBRH01','SHLCHPRH01') then 'microchp-h2' >> MainBatchUpload.sql
echo when process in('SHLCHPRG01') then 'microchp-nga' >> MainBatchUpload.sql
echo when process in('SHLNSTRE01','SHLNSTRE00') then 'storheater-elec' >> MainBatchUpload.sql
echo when process in('SHH-DUM-PIP01') then 'dummy-process' >> MainBatchUpload.sql
echo else 'other' >> MainBatchUpload.sql
echo end as "analysis", >> MainBatchUpload.sql
echo tablename, attribute >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute = 'VAR_FOut' AND commodity in('SHHCSVDMD','SERHEAT','SHHDELVAIR','SHHDELVRAD', >> MainBatchUpload.sql
echo 'SHLCSVDMD','SHLDELVAIR','SHLDELVRAD','SHLDELVUND','SWHDELVPIP','SWHDELVSTD','SWLDELVSTD') >> MainBatchUpload.sql
echo group by period,process, pv,tablename, id, analysis, attribute order by tablename, attribute >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo group by id, analysis,tablename, attribute >> MainBatchUpload.sql
echo order by tablename,  analysis, attribute, commodity >> MainBatchUpload.sql
echo ) TO '%~dp0ServWholeHeatOut.csv' delimiter ',' CSV; >> MainBatchUpload.sql
rem /* *New build services heat output by source* */echo /* *New build services heat output by source* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| 'various^|various'::varchar(300) "id", analysis, tablename,attribute, >> MainBatchUpload.sql
echo 'various'::varchar(50) "commodity", >> MainBatchUpload.sql
echo 'various'::varchar(50) "process", >> MainBatchUpload.sql
echo sum(pv)::numeric "all", >> MainBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> MainBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> MainBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> MainBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> MainBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> MainBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> MainBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> MainBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> MainBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> MainBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> MainBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> MainBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> MainBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select process, >> MainBatchUpload.sql
echo period,pv, >> MainBatchUpload.sql
echo 'new-heat-ser_' ^|^| >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in ('SHLBLRRE01','SHLSHTRE01','SWLWHTRE01','SHLBLSRE01','SHHBLRRE01','SWHWHTRE01') >> MainBatchUpload.sql
echo then 'boiler/heater-elec' >> MainBatchUpload.sql
echo when process in('SHLBLCRG01','SWLWHTRG01','SHLBLSRG01','SHHBLRRG01','SWHBLRRG01') >> MainBatchUpload.sql
echo then 'boiler/heater-nga' >> MainBatchUpload.sql
echo when process in('SHLBLCRP01','SHLBLRRW01','SHLBLSRP01','SHLBLSRW01','SHHBLRRW01','SWHBLRRW01') >> MainBatchUpload.sql
echo then 'boiler-bio' >> MainBatchUpload.sql
echo when process in('SHLBLSRH01','SHHBLRRH01','SWHBLRRH01','SHLBLCRH01') then 'boiler-h2' >> MainBatchUpload.sql
echo when process in('SHLBLCRO01','SHLBLSRO01','SHHBLRRO01','SHHBLRRC01','SWHBLRRO01','SWHBLRRC01') >> MainBatchUpload.sql
echo then 'boiler-otherFF' >> MainBatchUpload.sql
echo when process in('SCSLROFF01','SCSLROFP01','SCSLCAVW01','SCSHPTHM01','SCSHROFF01', >> MainBatchUpload.sql
echo 'SCSHROFP01','SCSHCAVW01','SCSLPTHM01') then 'conserv' >> MainBatchUpload.sql
echo when process in('SHLAHBUE01','SHLGHBRE01','SHLGHBUE01','SHLAHBRE01') >> MainBatchUpload.sql
echo then 'hyb-boil+hp-nga' >> MainBatchUpload.sql
echo when process in('SHLAHPRE01','SHLAHPUE01','SHLGHPRE01','SHLGHPUE01','SHLAHSRE01', >> MainBatchUpload.sql
echo 'SHLAHSUE01','SHLGHSRE01','SHLGHSUE01') then 'heatpump-elec' >> MainBatchUpload.sql
echo when process in('SHHVACAE01') then 'hvac' >> MainBatchUpload.sql
echo when process in('SHHVACAE02') then 'hvac-ad' >> MainBatchUpload.sql
echo when process in('SHLAHHUE01','SHLGHHRE01','SHLGHHUE01','SHLAHHRE01') then 'hyb-boil+hp-h2' >> MainBatchUpload.sql
echo when process in('SHLDHP101','SHHDHP101') then 'dh' >> MainBatchUpload.sql
echo when process in('SHLCHPRW01') then 'microchp-bio' >> MainBatchUpload.sql
echo when process in('SHLCHBRH01','SHLCHPRH01') then 'microchp-h2' >> MainBatchUpload.sql
echo when process in('SHLCHPRG01') then 'microchp-nga' >> MainBatchUpload.sql
echo when process in('SHLNSTRE01') then 'storheater-elec' >> MainBatchUpload.sql
echo else 'new-other' >> MainBatchUpload.sql
echo end as "analysis", >> MainBatchUpload.sql
echo tablename, attribute >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute = 'VAR_FOut' AND commodity in('SHHCSVDMD','SHHDELVAIR','SHHDELVRAD', >> MainBatchUpload.sql
echo 'SHLCSVDMD','SHLDELVAIR','SHLDELVRAD','SHLDELVUND','SWHDELVPIP','SWHDELVSTD','SWLDELVSTD') >> MainBatchUpload.sql
echo and vintage=period >> MainBatchUpload.sql
echo group by period,process, pv,tablename, id, analysis, attribute order by tablename, attribute >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo group by id, analysis,tablename, attribute >> MainBatchUpload.sql
echo order by tablename,  analysis, attribute, commodity >> MainBatchUpload.sql
echo ) TO '%~dp0NewServHeatOut.csv' delimiter ',' CSV; >> MainBatchUpload.sql
rem /* *End user final energy demand by sector* */echo /* *End user final energy demand by sector* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo with hydrogen_chp as ( >> MainBatchUpload.sql
echo select chp_hyd,commodity, period,tablename,sum(pv) "pv" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select case >> MainBatchUpload.sql
echo when process in ('RHEABLCRH01','RHEACHBRH01','RHFCBLCRH01','RHFCCHBRH01','RHFSBLCRH01','RHFSCHBRH01','RHHCBLCRH01' >> MainBatchUpload.sql
echo ,'RHHCCHBRH01','RHHSBLCRH01','RHHSCHBRH01','RHNABLCRH01','RHNACHBRH01') then 'RES BOI HYG' >> MainBatchUpload.sql
echo when process in('RHFCCHPRH01','RHFSCHPRH01','RHHCCHPRH01', >> MainBatchUpload.sql
echo 'RHHSCHPRH01','RHNACHPRH01','RHEACHPRH01' >> MainBatchUpload.sql
echo ) then 'RES MCHP HYG' >> MainBatchUpload.sql
echo when process in ('RHEAREFCG01','RHFCREFCG01','RHFSREFCG01','RHHCREFCG01','RHHSREFCG01','RHNAREFCG01') then 'RES REFORMER' >> MainBatchUpload.sql
echo when process in ('SHHBLRRH01','SHLBLCRH01','SHLCHBRH01') then 'SER BOI HYG' >> MainBatchUpload.sql
echo when process in('SHLCHPRH01') then 'SER MCHP HYG' >> MainBatchUpload.sql
echo when process in ('SHLREFCG01') then 'SER REFORMER' >> MainBatchUpload.sql
echo else null >> MainBatchUpload.sql
echo end as chp_hyd, >> MainBatchUpload.sql
echo tablename, commodity,pv,period from vedastore where attribute='VAR_FIn' >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where chp_hyd is not null >> MainBatchUpload.sql
echo group by tablename, period, chp_hyd,commodity >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo ,reformer_factors as( >> MainBatchUpload.sql
echo select period, tablename, >> MainBatchUpload.sql
echo case when res_chp_reformer_h2+res_chp_mains_h2^>0 then res_chp_reformer_h2/(res_chp_reformer_h2+res_chp_mains_h2) else 0 end chp_gas_for_h_res_mult, >> MainBatchUpload.sql
echo case when ser_chp_reformer_h2+ser_chp_mains_h2^>0 then ser_chp_reformer_h2/(ser_chp_reformer_h2+ser_chp_mains_h2) else 0 end chp_gas_for_h_ser_mult >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo sum(case when chp_hyd='RES MCHP HYG' and commodity='RESHOUSEHYG' then pv else 0 end) res_chp_mains_h2, >> MainBatchUpload.sql
echo sum(case when chp_hyd='RES MCHP HYG' and commodity in('RESHYGREF-FC','RESHYGREF-FS', >> MainBatchUpload.sql
echo 'RESHYGREF-HC','RESHYGREF-HS','RESHYGREF-NA') then pv else 0 end) res_chp_reformer_h2, >> MainBatchUpload.sql
echo sum(case when chp_hyd='SER MCHP HYG' and commodity ='SERHYGREF' then pv else 0 end) ser_chp_reformer_h2, >> MainBatchUpload.sql
echo sum(case when chp_hyd='SER MCHP HYG' and commodity in('SERBUILDHYG','SERMAINSHYG') then pv else 0 end) ser_chp_mains_h2 >> MainBatchUpload.sql
echo ,tablename,period >> MainBatchUpload.sql
echo from hydrogen_chp >> MainBatchUpload.sql
echo group by tablename,period >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , chp_fuels as ( >> MainBatchUpload.sql
echo select chp_sec, chp_fuel, period, tablename,sum(pv) "pv" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select case >> MainBatchUpload.sql
echo when commodity in('AGRBIODST','AGRBIOLPG','AGRBOM','AGRGRASS','AGRMAINSBOM','AGRPOLWST','BGRASS','BIODST','BIODST-FT','BIOJET-FT','BIOKER-FT','BIOLFO' >> MainBatchUpload.sql
echo ,'BIOLPG','BIOOIL','BOG-AD','BOG-G','BOG-LF','BOM','BPELH','BPELL','BRSEED','BSEWSLG','BSLURRY','BSTARCH' >> MainBatchUpload.sql
echo ,'BSTWWST','BSUGAR','BTREATSTW','BTREATWOD','BVOIL','BWOD','BWODLOG','BWODWST','ELCBIOCOA','ELCBIOCOA2','ELCBIOLFO','ELCBIOOIL' >> MainBatchUpload.sql
echo ,'ELCBOG-AD','ELCBOG-LF','ELCBOG-SW','ELCBOM','ELCMAINSBOM','ELCMSWINO','ELCMSWORG','ELCPELH','ELCPELL','ELCPOLWST','ELCSTWWST','ELCTRANSBOM' >> MainBatchUpload.sql
echo ,'ETH','HYGBIOO','HYGBPEL','HYGMSWINO','HYGMSWORG','INDBIOLFO','INDBIOLPG','INDBIOOIL','INDBOG-AD','INDBOG-LF','INDBOM','INDGRASS' >> MainBatchUpload.sql
echo ,'INDMAINSBOM','INDMSWINO','INDMSWORG','INDPELH','INDPELL','INDPOLWST','INDWOD','INDWODWST','METH','MSWBIO','MSWINO','MSWORG' >> MainBatchUpload.sql
echo ,'PWASTEDUM','RESBIOLFO','RESBOM','RESHOUSEBOM','RESMAINSBOM','RESMSWINO','RESMSWORG','RESPELH','RESWOD','RESWODL','SERBIOLFO','SERBOG','SERBOM','SERBUILDBOM' >> MainBatchUpload.sql
echo ,'SERMAINSBOM','SERMSWBIO','SERMSWINO','SERMSWORG','SERPELH','SERWOD','TRABIODST','TRABIODST-FT','TRABIODST-FTL','TRABIODST-FTS','TRABIODSTL','TRABIODSTS' >> MainBatchUpload.sql
echo ,'TRABIOJET-FTDA','TRABIOJET-FTDAL','TRABIOJET-FTIA','TRABIOJET-FTIAL','TRABIOLFO','TRABIOLFODS','TRABIOLFODSL','TRABIOLFOL','TRABIOOILIS','TRABIOOILISL','TRABOM','TRAETH','TRAETHL','TRAETHS','TRAMAINSBOM','TRAMETH') then 'ALL BIO' >> MainBatchUpload.sql
echo when commodity in ('AGRCOA','COA','COA-E','COACOK','ELCCOA','HYGCOA','INDCOA','INDCOACOK','INDSYNCOA','PRCCOA','PRCCOACOK','RESCOA' >> MainBatchUpload.sql
echo ,'SERCOA','SYNCOA','TRACOA') then 'ALL COALS' >> MainBatchUpload.sql
echo when commodity in('AGRHYG','ELCHYG','ELCHYGIGCC','HYGL','HYGL-IGCC','HYGLHPD','HYGLHPT','HYL','HYLTK','INDHYG','INDMAINSHYG','RESHOUSEHYG' >> MainBatchUpload.sql
echo ,'RESHYG','RESHYGREF-EA','RESHYGREF-NA','RESMAINSHYG','SERBUILDHYG','SERHYG','SERMAINSHYG','TRAHYG','TRAHYGDCN','TRAHYGL','TRAHYGS','TRAHYL' >> MainBatchUpload.sql
echo ,'UPSHYG','UPSMAINSHYG') then 'ALL HYDROGEN' >> MainBatchUpload.sql
echo when commodity in ('BENZ','BFG','COG','COK','ELCBFG','ELCCOG','IISBFGB','IISBFGC','IISCOGB','IISCOGC','IISCOKB','IISCOKE' >> MainBatchUpload.sql
echo ,'IISCOKS','INDBENZ','INDBFG','INDCOG','INDCOK','RESCOK') then 'ALL MANFUELS' >> MainBatchUpload.sql
echo when commodity in ('AGRHFO','AGRLFO','AGRLPG','ELCHFO','ELCLFO','ELCLPG','ELCMSC','IISHFOB','INDHFO','INDKER','INDLFO','INDLPG' >> MainBatchUpload.sql
echo ,'INDNEULFO','INDNEULPG','INDNEUMSC','INDSYNOIL','OILCRD','OILCRDRAW','OILCRDRAW-E','OILDST','OILHFO','OILJET','OILKER','OILLFO' >> MainBatchUpload.sql
echo ,'OILLPG','OILMSC','OILPET','PRCHFO','PRCOILCRD','RESKER','RESLFO','RESLPG','SERHFO','SERKER','SERLFO','SERLPG' >> MainBatchUpload.sql
echo ,'SYNOIL','TRADST','TRADSTL','TRADSTS','TRAHFO','TRAHFODS','TRAHFODSL','TRAHFOIS','TRAHFOISL','TRAJETDA','TRAJETDAEL','TRAJETIA' >> MainBatchUpload.sql
echo ,'TRAJETIAEL','TRAJETIANL','TRAJETL','TRALFO','TRALFODS','TRALFODSL','TRALFOL','TRALPG','TRALPGL','TRALPGS','TRAPET','TRAPETL' >> MainBatchUpload.sql
echo ,'TRAPETS','UPSLFO') then 'ALL OIL PRODUCTS' >> MainBatchUpload.sql
echo when commodity in('INDMAINSGAS','INDNGA') then 'IND GAS' >> MainBatchUpload.sql
echo when commodity in('ICHPRO') then 'IND PRO' >> MainBatchUpload.sql
echo when commodity in('PRCNGA') then 'PRC GAS' >> MainBatchUpload.sql
echo when commodity in('PREFGAS') then 'PRC REFGAS' >> MainBatchUpload.sql
echo when commodity in('RESMAINSGAS','RESNGA') then 'RES GAS' >> MainBatchUpload.sql
echo when commodity in('SERMAINSGAS','SERNGA') then 'SER GAS' >> MainBatchUpload.sql
echo when commodity in('UPSNGA') then 'UPS GAS' >> MainBatchUpload.sql
echo else null >> MainBatchUpload.sql
echo end as chp_fuel, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','ICHCHPCCGT01','ICHCHPCCGTH01','ICHCHPCOA00','ICHCHPCOA01','ICHCHPFCH01','ICHCHPGT01','ICHCHPHFO00','ICHCHPLFO00','ICHCHPLPG00' >> MainBatchUpload.sql
echo ,'ICHCHPLPG01','ICHCHPNGA00','ICHCHPPRO00','ICHCHPPRO01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01','IFDCHPCCGT01','IFDCHPCCGTH01','IFDCHPCOA00','IFDCHPCOA01','IFDCHPFCH01' >> MainBatchUpload.sql
echo ,'IFDCHPGT01','IFDCHPHFO00','IFDCHPLFO00','IFDCHPNGA00','IISCHPBFG00','IISCHPBFG01','IISCHPBIOG01','IISCHPBIOS01','IISCHPCCGT01','IISCHPCCGTH01','IISCHPCOG00','IISCHPCOG01' >> MainBatchUpload.sql
echo ,'IISCHPFCH01','IISCHPGT01','IISCHPHFO00','IISCHPNGA00','INMCHPBIOG01','INMCHPBIOS01','INMCHPCCGT01','INMCHPCCGTH01','INMCHPCOA01','INMCHPCOG00','INMCHPCOG01','INMCHPFCH01' >> MainBatchUpload.sql
echo ,'INMCHPGT01','INMCHPNGA00','IOICHPBIOG01','IOICHPBIOS00','IOICHPBIOS01','IOICHPCCGT01','IOICHPCCGTH01','IOICHPCOA01','IOICHPFCH01','IOICHPGT01','IOICHPHFO00','IOICHPNGA00' >> MainBatchUpload.sql
echo ,'IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPCCGT01','IPPCHPCCGTH01','IPPCHPCOA00','IPPCHPCOA01','IPPCHPFCH01','IPPCHPGT01','IPPCHPNGA00','IPPCHPWST00','IPPCHPWST01' >> MainBatchUpload.sql
echo ) then 'CHP IND SECTOR' >> MainBatchUpload.sql
echo when process in('PCHP-CCP00','PCHP-CCP01') then 'CHP PRC SECTOR' >> MainBatchUpload.sql
echo when process in('RCHPEA-CCG00','RCHPEA-CCG01','RCHPEA-CCH01', >> MainBatchUpload.sql
echo 'RCHPEA-FCH01','RCHPEA-STW01','RCHPNA-CCG01','RCHPNA-CCH01', >> MainBatchUpload.sql
echo 'RCHPNA-FCH01','RCHPNA-STW01','RHEACHPRG01','RHEACHPRH01', >> MainBatchUpload.sql
echo 'RHEACHPRW01','RHNACHPRG01','RHNACHPRH01','RHNACHPRW01', >> MainBatchUpload.sql
echo 'RCHPEA-EFW01','RCHPNA-EFW01','RHFCCHPRH01','RHFSCHPRH01', >> MainBatchUpload.sql
echo 'RHHCCHPRH01','RHHSCHPRH01','RHFCCHPRG01','RHFSCHPRG01', >> MainBatchUpload.sql
echo 'RHHCCHPRG01','RHHSCHPRG01','RHFCCHPRW01','RHFSCHPRW01', >> MainBatchUpload.sql
echo 'RHHCCHPRW01','RHHSCHPRW01') then 'CHP RES SECTOR' >> MainBatchUpload.sql
echo when process in('SCHP-ADM01','SCHP-CCG00','SCHP-CCG01', >> MainBatchUpload.sql
echo 'SCHP-CCH01','SCHP-FCH01','SCHP-GES00','SCHP-GES01', >> MainBatchUpload.sql
echo 'SCHP-STM01','SCHP-STW00','SCHP-STW01','SHLCHPRG01', >> MainBatchUpload.sql
echo 'SHLCHPRH01','SHLCHPRW01','SCHP-EFW01') then 'CHP SER SECTOR' >> MainBatchUpload.sql
echo when process in('UCHP-CCG00','UCHP-CCG01') then 'CHP UPS SECTOR' >> MainBatchUpload.sql
echo else null >> MainBatchUpload.sql
echo end as chp_sec,* >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FIn' >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where chp_sec is not null and chp_fuel is not null >> MainBatchUpload.sql
echo group by tablename, period,chp_sec,chp_fuel >> MainBatchUpload.sql
echo ), >> MainBatchUpload.sql
echo chp_fuels_used as ( >> MainBatchUpload.sql
echo select a.tablename,a.period, >> MainBatchUpload.sql
echo a.res_bio, >> MainBatchUpload.sql
echo a.res_gas+(case when b.chp_gas_for_h_res is null then 0 else b.chp_gas_for_h_res end) "res_gas", >> MainBatchUpload.sql
echo a.res_hyd, >> MainBatchUpload.sql
echo a.ser_bio, >> MainBatchUpload.sql
echo a.ser_gas+(case when b.chp_gas_for_h_ser is null then 0 else b.chp_gas_for_h_ser end) "ser_gas", >> MainBatchUpload.sql
echo a.ser_hyd,a.ind_bio,a.ind_gas,a.ind_hyd,a.ind_coa,a.ind_oil,a.ind_man,a.ind_bypro,a.prc_gas, >> MainBatchUpload.sql
echo a.prc_refgas,a.prc_oil, ups_gas >> MainBatchUpload.sql
echo from( >> MainBatchUpload.sql
echo select tablename,period, >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP RES SECTOR' and chp_fuel='ALL BIO' then pv else 0 end) "res_bio", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP RES SECTOR' and chp_fuel='RES GAS' then pv else 0 end) "res_gas", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP RES SECTOR' and chp_fuel='ALL HYDROGEN' then pv else 0 end) "res_hyd", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP SER SECTOR' and chp_fuel='ALL BIO' then pv else 0 end) "ser_bio", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP SER SECTOR' and chp_fuel='SER GAS' then pv else 0 end) "ser_gas", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP SER SECTOR' and chp_fuel='ALL HYDROGEN' then pv else 0 end) "ser_hyd", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL BIO' then pv else 0 end) "ind_bio", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='IND GAS' then pv else 0 end) "ind_gas", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL HYDROGEN' then pv else 0 end) "ind_hyd", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL COALS' then pv else 0 end) "ind_coa", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL OIL PRODUCTS' then pv else 0 end) "ind_oil", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL MANFUELS' then pv else 0 end) "ind_man", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='IND PRO' then pv else 0 end) "ind_bypro", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP PRC SECTOR' and chp_fuel='PRC GAS' then pv else 0 end) "prc_gas", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP PRC SECTOR' and chp_fuel='PRC REFGAS' then pv else 0 end) "prc_refgas", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP PRC SECTOR' and chp_fuel='ALL OIL PRODUCTS' then pv else 0 end) "prc_oil", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP UPS SECTOR' and chp_fuel='UPS GAS' then pv else 0 end) "ups_gas" >> MainBatchUpload.sql
echo from chp_fuels >> MainBatchUpload.sql
echo group by tablename,period >> MainBatchUpload.sql
echo ) a left join >> MainBatchUpload.sql
echo ( >> MainBatchUpload.sql
echo select tablename,period, >> MainBatchUpload.sql
echo case when res_chp_reformer_h2+res_boi_reformer_h2^>0 then res_reformer*res_chp_reformer_h2/(res_chp_reformer_h2+res_boi_reformer_h2) else 0 end chp_gas_for_h_res, >> MainBatchUpload.sql
echo case when ser_chp_reformer_h2+ser_boi_reformer_h2^>0 then ser_reformer*ser_chp_reformer_h2/(ser_chp_reformer_h2+ser_boi_reformer_h2) else 0 end chp_gas_for_h_ser from >> MainBatchUpload.sql
echo ( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo sum(case when chp_hyd='RES BOI HYG' and commodity in('RESHYGREF-FC','RESHYGREF-FS', >> MainBatchUpload.sql
echo 'RESHYGREF-HC','RESHYGREF-HS','RESHYGREF-NA') then pv else 0 end) res_boi_reformer_h2, >> MainBatchUpload.sql
echo sum(case when chp_hyd='RES MCHP HYG' and commodity in('RESHYGREF-FC','RESHYGREF-FS', >> MainBatchUpload.sql
echo 'RESHYGREF-HC','RESHYGREF-HS','RESHYGREF-NA') then pv else 0 end) res_chp_reformer_h2, >> MainBatchUpload.sql
echo sum(case when chp_hyd='RES REFORMER' then pv else 0 end) res_reformer, >> MainBatchUpload.sql
echo sum(case when chp_hyd='SER BOI HYG' and commodity ='SERHYGREF' then pv else 0 end) ser_boi_reformer_h2, >> MainBatchUpload.sql
echo sum(case when chp_hyd='SER MCHP HYG' and commodity ='SERHYGREF' then pv else 0 end) ser_chp_reformer_h2, >> MainBatchUpload.sql
echo sum(case when chp_hyd='SER REFORMER' then pv else 0 end) ser_reformer >> MainBatchUpload.sql
echo ,tablename,period >> MainBatchUpload.sql
echo from hydrogen_chp >> MainBatchUpload.sql
echo group by tablename,period >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo ) b on a.period=b.period and a.tablename=b.tablename >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , chp_heatgen as( >> MainBatchUpload.sql
echo select chp_sec, period,tablename,sum(pv) "pv" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01','IISCHPBIOG01','IISCHPBIOS01','INMCHPBIOG01','INMCHPBIOS01' >> MainBatchUpload.sql
echo ,'IOICHPBIOG01','IOICHPBIOS00','IOICHPBIOS01','IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPWST00','IPPCHPWST01') then 'CHP IND BIO' >> MainBatchUpload.sql
echo when process in('ICHCHPPRO00','ICHCHPPRO01') then 'CHP IND BY PRODUCTS' >> MainBatchUpload.sql
echo when process in('ICHCHPCOA00','ICHCHPCOA01','IFDCHPCOA00','IFDCHPCOA01','INMCHPCOA01','IOICHPCOA01','IPPCHPCOA00','IPPCHPCOA01') then 'CHP IND COAL' >> MainBatchUpload.sql
echo when process in('ICHCHPCCGT01','ICHCHPGT01','ICHCHPNGA00','IFDCHPCCGT01','IFDCHPGT01','IFDCHPNGA00','IISCHPCCGT01','IISCHPGT01','IISCHPNGA00','INMCHPCCGT01' >> MainBatchUpload.sql
echo ,'INMCHPGT01','INMCHPNGA00','IOICHPCCGT01','IOICHPGT01','IOICHPNGA00','IPPCHPCCGT01','IPPCHPGT01','IPPCHPNGA00') then 'CHP IND GAS' >> MainBatchUpload.sql
echo when process in('ICHCHPCCGTH01','ICHCHPFCH01','IFDCHPCCGTH01','IFDCHPFCH01','IISCHPCCGTH01','IISCHPFCH01','INMCHPCCGTH01','INMCHPFCH01','IOICHPCCGTH01' >> MainBatchUpload.sql
echo ,'IOICHPFCH01','IPPCHPCCGTH01','IPPCHPFCH01') then 'CHP IND HYDROGEN' >> MainBatchUpload.sql
echo when process in('IISCHPBFG00','IISCHPBFG01','IISCHPCOG00','IISCHPCOG01','INMCHPCOG00','INMCHPCOG01') then 'CHP IND MAN FUELS' >> MainBatchUpload.sql
echo when process in('ICHCHPHFO00','ICHCHPLFO00','ICHCHPLPG00','ICHCHPLPG01','IFDCHPHFO00','IFDCHPLFO00','IISCHPHFO00','IOICHPHFO00') then 'CHP IND OIL PRODUCTS' >> MainBatchUpload.sql
echo when process in('PCHP-CCP00','PCHP-CCP01') then 'CHP PRC SECTOR' >> MainBatchUpload.sql
echo when process in('RCHPEA-STW01','RCHPNA-STW01','RHEACHPRW01', >> MainBatchUpload.sql
echo 'RHNACHPRW01','RCHPEA-EFW01','RCHPNA-EFW01','RHFCCHPRW01', >> MainBatchUpload.sql
echo 'RHFSCHPRW01','RHHCCHPRW01','RHHSCHPRW01') then 'CHP RES BIO' >> MainBatchUpload.sql
echo when process in('RCHPEA-CCG00','RCHPEA-CCG01','RCHPNA-CCG01', >> MainBatchUpload.sql
echo 'RHEACHPRG01','RHNACHPRG01','RHFCCHPRG01','RHFSCHPRG01', >> MainBatchUpload.sql
echo 'RHHCCHPRG01','RHHSCHPRG01') then 'CHP RES GAS' >> MainBatchUpload.sql
echo when process in('RCHPEA-CCH01','RCHPEA-FCH01','RCHPNA-CCH01', >> MainBatchUpload.sql
echo 'RCHPNA-FCH01','RHEACHPRH01','RHNACHPRH01','RHFCCHPRH01','RHFSCHPRH01','RHHCCHPRH01','RHHSCHPRH01' >> MainBatchUpload.sql
echo ) then 'CHP RES HYDROGEN' >> MainBatchUpload.sql
echo when process in('SCHP-ADM01','SCHP-GES00','SCHP-GES01','SCHP-STM01','SCHP-STW00','SCHP-STW01','SHLCHPRW01','SCHP-EFW01') then 'CHP SER BIO' >> MainBatchUpload.sql
echo when process in('SCHP-CCG00','SCHP-CCG01','SHLCHPRG01') then 'CHP SER GAS' >> MainBatchUpload.sql
echo when process in('SHLCHPRG01','SHLCHPRH01','SHLCHPRW01') then 'CHP SER MICRO' >> MainBatchUpload.sql
echo when process in('UCHP-CCG00','UCHP-CCG01') then 'CHP UPS SECTOR' >> MainBatchUpload.sql
echo end as chp_sec, * from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FOut' and commodity in ('ICHSTM','IFDSTM','IISLTH','INMSTM','IOISTM','IPPLTH','PCHPHEAT','RESLTH-NA','RHEATPIPE-NA', >> MainBatchUpload.sql
echo 'SERLTH','SHLDELVRAD','SHHDELVRAD','UPSHEAT','RESLTH-FC','RESLTH-FS','RESLTH-HC','RESLTH-HS','RHEATPIPE-FC', >> MainBatchUpload.sql
echo 'RHEATPIPE-FS','RHEATPIPE-HC','RHEATPIPE-HS') >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where chp_sec is not null is not null >> MainBatchUpload.sql
echo group by tablename, period,chp_sec order by chp_sec >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , process_fuel_pcs as ( >> MainBatchUpload.sql
echo select tablename, period, >> MainBatchUpload.sql
echo sum(case when (prc_gas+prc_refgas+prc_oil)=0 then 0 else prc_gas/(prc_gas+prc_refgas+prc_oil) end) "prc_gas_pc", >> MainBatchUpload.sql
echo sum(case when (prc_gas+prc_refgas+prc_oil)=0 then 0 else prc_refgas/(prc_gas+ prc_refgas+ prc_oil) end) "prc_refgas_pc", >> MainBatchUpload.sql
echo sum(case when (prc_gas+prc_refgas+prc_oil)=0 then 0 else prc_oil/(prc_gas+ prc_refgas+ prc_oil) end) "prc_oil_pc" >> MainBatchUpload.sql
echo from chp_fuels_used >> MainBatchUpload.sql
echo group by tablename, period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo ,chp_heat as( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo a.tablename,a.period, >> MainBatchUpload.sql
echo a.res_bio, >> MainBatchUpload.sql
echo a.res_gas+a.res_hyd*(case when b.chp_gas_for_h_res_mult is null then 0 else b.chp_gas_for_h_res_mult end) res_gas, >> MainBatchUpload.sql
echo a.res_hyd*(1-(case when b.chp_gas_for_h_res_mult is null then 0 else b.chp_gas_for_h_res_mult end)) res_hyd, >> MainBatchUpload.sql
echo a.ser_bio, >> MainBatchUpload.sql
echo a.ser_gas+a.ser_hyd*(case when b.chp_gas_for_h_ser_mult is null then 0 else b.chp_gas_for_h_ser_mult end) ser_gas, >> MainBatchUpload.sql
echo a.ser_hyd*(1-(case when b.chp_gas_for_h_ser_mult is null then 0 else b.chp_gas_for_h_ser_mult end)) ser_hyd, >> MainBatchUpload.sql
echo a.ind_bio,a.ind_gas,a.ind_hyd,a.ind_coa,a.ind_oil,a.ind_man,a.ind_bypro,a.ups_gas, >> MainBatchUpload.sql
echo a.prc_heat*c.prc_gas_pc "prc_gas",a.prc_heat*c.prc_refgas_pc "prc_refgas", a.prc_heat*c.prc_oil_pc "prc_oil" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP RES BIO' then pv else 0 end) res_bio >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP RES GAS' then pv else 0 end) res_gas >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP RES HYDROGEN' then pv else 0 end) res_hyd >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP SER BIO' then pv else 0 end) ser_bio >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP SER GAS' then pv else 0 end) ser_gas >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP SER HYDROGEN' then pv else 0 end) ser_hyd >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP IND BIO' then pv else 0 end) ind_bio >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP IND GAS' then pv else 0 end) ind_gas >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP IND HYDROGEN' then pv else 0 end) ind_hyd >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP IND COAL' then pv else 0 end) ind_coa >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP IND OIL PRODUCTS' then pv else 0 end) ind_oil >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP IND MAN FUELS' then pv else 0 end) ind_man >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP IND BY PRODUCTS' then pv else 0 end) ind_bypro >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP UPS SECTOR' then pv else 0 end) ups_gas >> MainBatchUpload.sql
echo ,sum(case when chp_sec='CHP PRC SECTOR' then pv else 0 end) prc_heat >> MainBatchUpload.sql
echo ,period,tablename >> MainBatchUpload.sql
echo from chp_heatgen >> MainBatchUpload.sql
echo group by period,tablename >> MainBatchUpload.sql
echo )a >> MainBatchUpload.sql
echo left join reformer_factors b >> MainBatchUpload.sql
echo on a.period=b.period and a.tablename=b.tablename >> MainBatchUpload.sql
echo left join process_fuel_pcs c >> MainBatchUpload.sql
echo on a.period=c.period and a.tablename=c.tablename >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , chp_elcgen as ( >> MainBatchUpload.sql
echo select tablename, chp_sec, period, sum(pv) "pv" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select tablename, period, pv, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01','IISCHPBIOG01','IISCHPBIOS01','INMCHPBIOG01','INMCHPBIOS01','IOICHPBIOG01' >> MainBatchUpload.sql
echo ,'IOICHPBIOS00','IOICHPBIOS01','IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPWST00','IPPCHPWST01') then 'CHP IND BIO' >> MainBatchUpload.sql
echo when process in('ICHCHPPRO00','ICHCHPPRO01') then 'CHP IND BY PRODUCTS' >> MainBatchUpload.sql
echo when process in('ICHCHPCOA00','ICHCHPCOA01','IFDCHPCOA00','IFDCHPCOA01','INMCHPCOA01','IOICHPCOA01','IPPCHPCOA00','IPPCHPCOA01') then 'CHP IND COAL' >> MainBatchUpload.sql
echo when process in('ICHCHPCCGT01','ICHCHPGT01','ICHCHPNGA00','IFDCHPCCGT01','IFDCHPGT01','IFDCHPNGA00','IISCHPCCGT01','IISCHPGT01','IISCHPNGA00','INMCHPCCGT01' >> MainBatchUpload.sql
echo ,'INMCHPGT01','INMCHPNGA00','IOICHPCCGT01','IOICHPGT01','IOICHPNGA00','IPPCHPCCGT01','IPPCHPGT01','IPPCHPNGA00') then 'CHP IND GAS' >> MainBatchUpload.sql
echo when process in('ICHCHPCCGTH01','ICHCHPFCH01','IFDCHPCCGTH01','IFDCHPFCH01','IISCHPCCGTH01','IISCHPFCH01','INMCHPCCGTH01','INMCHPFCH01','IOICHPCCGTH01','IOICHPFCH01' >> MainBatchUpload.sql
echo ,'IPPCHPCCGTH01','IPPCHPFCH01') then 'CHP IND HYDROGEN' >> MainBatchUpload.sql
echo when process in('IISCHPBFG00','IISCHPBFG01','IISCHPCOG00','IISCHPCOG01','INMCHPCOG00','INMCHPCOG01') then 'CHP IND MAN FUELS' >> MainBatchUpload.sql
echo when process in('ICHCHPHFO00','ICHCHPLFO00','ICHCHPLPG00','ICHCHPLPG01','IFDCHPHFO00','IFDCHPLFO00','IISCHPHFO00','IOICHPHFO00') then 'CHP IND OIL PRODUCTS' >> MainBatchUpload.sql
echo when process in('PCHP-CCP00','PCHP-CCP01') then 'CHP PRC SECTOR' >> MainBatchUpload.sql
echo when process in('RCHPEA-STW01','RCHPNA-STW01','RHEACHPRW01', >> MainBatchUpload.sql
echo 'RHNACHPRW01','RCHPEA-EFW01','RCHPNA-EFW01','RHFCCHPRW01', >> MainBatchUpload.sql
echo 'RHFSCHPRW01','RHHCCHPRW01','RHHSCHPRW01') then 'CHP RES BIO' >> MainBatchUpload.sql
echo when process in('RCHPEA-CCG00','RCHPEA-CCG01','RCHPNA-CCG01', >> MainBatchUpload.sql
echo 'RHEACHPRG01','RHNACHPRG01','RHFCCHPRG01','RHFSCHPRG01', >> MainBatchUpload.sql
echo 'RHHCCHPRG01','RHHSCHPRG01') then 'CHP RES GAS' >> MainBatchUpload.sql
echo when process in('RCHPEA-CCH01','RCHPEA-FCH01','RCHPNA-CCH01', >> MainBatchUpload.sql
echo 'RCHPNA-FCH01','RHEACHPRH01','RHNACHPRH01','RHFCCHPRH01','RHFSCHPRH01','RHHCCHPRH01','RHHSCHPRH01' >> MainBatchUpload.sql
echo ) then 'CHP RES HYDROGEN' >> MainBatchUpload.sql
echo when process in('SCHP-ADM01','SCHP-GES00','SCHP-GES01','SCHP-STM01','SCHP-STW00','SCHP-STW01','SHLCHPRW01','SCHP-EFW01') then 'CHP SER BIO' >> MainBatchUpload.sql
echo when process in('SCHP-CCG00','SCHP-CCG01','SHLCHPRG01') then 'CHP SER GAS' >> MainBatchUpload.sql
echo when process in('SHLCHPRG01','SHLCHPRH01','SHLCHPRW01') then 'CHP SER MICRO' >> MainBatchUpload.sql
echo when process in('UCHP-CCG00','UCHP-CCG01') then 'CHP UPS SECTOR' >> MainBatchUpload.sql
echo end as chp_sec >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FOut' and commodity in('ELCGEN','INDELC','RESELC','RESHOUSEELC','SERBUILDELC','SERDISTELC','SERELC') >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where chp_sec is not null >> MainBatchUpload.sql
echo group by tablename, chp_sec, period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , chp_elc as ( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo a.tablename,a.period, >> MainBatchUpload.sql
echo a.ind_bio,a.ind_coa,a.ind_gas,a.ind_hyd,a.ind_oil,a.ind_man,a.ind_bypro, >> MainBatchUpload.sql
echo a.res_bio, >> MainBatchUpload.sql
echo a.res_gas+a.res_hyd*(case when b.chp_gas_for_h_res_mult is null then 0 else b.chp_gas_for_h_res_mult end) res_gas, >> MainBatchUpload.sql
echo a.res_hyd*(1-(case when b.chp_gas_for_h_res_mult is null then 0 else b.chp_gas_for_h_res_mult end)) res_hyd, >> MainBatchUpload.sql
echo a.ser_bio, >> MainBatchUpload.sql
echo a.ser_gas+a.res_hyd*(case when b.chp_gas_for_h_ser_mult is null then 0 else b.chp_gas_for_h_ser_mult end) ser_gas, >> MainBatchUpload.sql
echo a.ser_hyd*(1-(case when b.chp_gas_for_h_ser_mult is null then 0 else b.chp_gas_for_h_ser_mult end)) ser_hyd, >> MainBatchUpload.sql
echo a.prc_elc*c.prc_gas_pc "prc_gas",a.prc_elc*c.prc_oil_pc "prc_oil",a.prc_elc*c.prc_refgas_pc "prc_refgas", >> MainBatchUpload.sql
echo a.ups_gas >> MainBatchUpload.sql
echo from >> MainBatchUpload.sql
echo ( >> MainBatchUpload.sql
echo select tablename,period, >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP RES BIO' then pv else 0 end) as "res_bio", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP RES GAS' then pv else 0 end) as "res_gas", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP RES HYDROGEN' then pv else 0 end) as "res_hyd", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP SER BIO' then pv else 0 end) "ser_bio", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP SER GAS' then pv else 0 end) "ser_gas", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP SER HYDROGEN' then pv else 0 end) "ser_hyd", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND BIO' then pv else 0 end) "ind_bio", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND GAS' then pv else 0 end) "ind_gas", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND HYDROGEN' then pv else 0 end) "ind_hyd", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND COAL' then pv else 0 end) "ind_coa", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND OIL PRODUCTS' then pv else 0 end) "ind_oil", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND MAN FUELS' then pv else 0 end) "ind_man", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP IND BY PRODUCTS' then pv else 0 end) "ind_bypro", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP PRC SECTOR' then pv else 0 end) "prc_elc", >> MainBatchUpload.sql
echo sum(case when chp_sec='CHP UPS SECTOR' then pv else 0 end) "ups_gas" >> MainBatchUpload.sql
echo from chp_elcgen >> MainBatchUpload.sql
echo group by tablename,period >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo left join reformer_factors b >> MainBatchUpload.sql
echo on a.tablename=b.tablename and a.period=b.period >> MainBatchUpload.sql
echo left join process_fuel_pcs c >> MainBatchUpload.sql
echo on a.tablename=c.tablename and a.period=c.period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , chp as( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo elc.tablename, elc.period, >> MainBatchUpload.sql
echo sum(case when elc.ind_bio+heat.ind_bio^>0 then (2*fuel.ind_bio*elc.ind_bio)/(2*elc.ind_bio+heat.ind_bio) else 0 end) "ind_bio_chp", >> MainBatchUpload.sql
echo sum(case when elc.ind_coa+heat.ind_coa^>0 then (2*fuel.ind_coa*elc.ind_coa)/(2*elc.ind_coa+heat.ind_coa) else 0 end) "ind_coa_chp", >> MainBatchUpload.sql
echo sum(case when elc.ind_gas+heat.ind_gas^>0 then (2*fuel.ind_gas*elc.ind_gas)/(2*elc.ind_gas+heat.ind_gas) else 0 end) "ind_gas_chp", >> MainBatchUpload.sql
echo sum(case when elc.ind_hyd+heat.ind_hyd^>0 then (2*fuel.ind_hyd*elc.ind_hyd)/(2*elc.ind_hyd+heat.ind_hyd) else 0 end) "ind_hyd_chp", >> MainBatchUpload.sql
echo sum(case when elc.ind_oil+heat.ind_oil^>0 then (2*fuel.ind_oil*elc.ind_oil)/(2*elc.ind_oil+heat.ind_oil) else 0 end) "ind_oil_chp", >> MainBatchUpload.sql
echo sum(case when elc.ind_man+heat.ind_man^>0 then (2*fuel.ind_man*elc.ind_man)/(2*elc.ind_man+heat.ind_man) else 0 end) "ind_man_chp", >> MainBatchUpload.sql
echo sum(case when elc.ind_bypro+heat.ind_bypro^>0 then (2*fuel.ind_bypro*elc.ind_bypro)/(2*elc.ind_bypro+heat.ind_bypro) else 0 end) "ind_bypro_chp", >> MainBatchUpload.sql
echo sum(case when elc.res_bio+heat.res_bio^>0 then (2*fuel.res_bio*elc.res_bio)/(2*elc.res_bio+heat.res_bio) else 0 end) "res_bio_chp", >> MainBatchUpload.sql
echo sum(case when elc.res_gas+heat.res_gas^>0 then (2*fuel.res_gas*elc.res_gas)/(2*elc.res_gas+heat.res_gas) else 0 end) "res_gas_chp", >> MainBatchUpload.sql
echo sum(case when elc.res_hyd+heat.res_hyd^>0 then (2*fuel.res_hyd*elc.res_hyd)/(2*elc.res_hyd+heat.res_hyd) else 0 end) "res_hyd_chp", >> MainBatchUpload.sql
echo sum(case when elc.ser_bio+heat.ser_bio^>0 then (2*fuel.ser_bio*elc.ser_bio)/(2*elc.ser_bio+heat.ser_bio) else 0 end) "ser_bio_chp", >> MainBatchUpload.sql
echo sum(case when elc.ser_gas+heat.ser_gas^>0 then (2*fuel.ser_gas*elc.ser_gas)/(2*elc.ser_gas+heat.ser_gas) else 0 end) "ser_gas_chp", >> MainBatchUpload.sql
echo sum(case when elc.ser_hyd+heat.ser_hyd^>0 then (2*fuel.ser_hyd*elc.ser_hyd)/(2*elc.ser_hyd+heat.ser_hyd) else 0 end) "ser_hyd_chp", >> MainBatchUpload.sql
echo sum(case when elc.prc_gas+heat.prc_gas^>0 then (2*fuel.prc_gas*elc.prc_gas)/(2*elc.prc_gas+heat.prc_gas) else 0 end) "prc_gas_chp", >> MainBatchUpload.sql
echo sum(case when elc.prc_oil+heat.prc_oil^>0 then (2*fuel.prc_oil*elc.prc_oil)/(2*elc.prc_oil+heat.prc_oil) else 0 end) "prc_oil_chp", >> MainBatchUpload.sql
echo sum(case when elc.prc_refgas+heat.prc_refgas^>0 then (2*fuel.prc_refgas*elc.prc_refgas)/(2*elc.prc_refgas+heat.prc_refgas) else 0 end) "prc_refgas_chp", >> MainBatchUpload.sql
echo sum(case when elc.ups_gas+heat.ups_gas^>0 then (2*fuel.ups_gas*elc.ups_gas)/(2*elc.ups_gas+heat.ups_gas) else 0 end) "ups_gas_chp" >> MainBatchUpload.sql
echo from chp_fuels_used fuel inner join chp_heat heat on fuel.period=heat.period and fuel.tablename=heat.tablename inner join chp_elc elc >> MainBatchUpload.sql
echo on elc.period=fuel.period and elc.tablename=fuel.tablename >> MainBatchUpload.sql
echo group by elc.tablename, elc.period >> MainBatchUpload.sql
echo order by elc.period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , "all_finencon_all" as( >> MainBatchUpload.sql
echo select tablename, proc_set,comm_set,period,sum(pv) "pv" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select tablename, period, pv, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('AGRBIODST01','AGRBIOLPG01','AGRBOM01','AGRCOA00','AGRELC00','AGRELC01','AGRGRASS00','AGRGRASS01','AGRHFO00','AGRHFO01','AGRHYG01','AGRLAND00' >> MainBatchUpload.sql
echo ,'AGRLAND01','AGRLFO00','AGRLFO01','AGRLPG00','AGRLPG01','AGRNGA00','AGRNGA01','AGRPOLWST00','AGRPOLWST01') then 'FUEL TECHS AGR' >> MainBatchUpload.sql
echo when process in('ELCBFG00','ELCBFG01','ELCBIOLFO01','ELCBIOOIL01','ELCBOG-AD01','ELCBOG-LF00','ELCBOG-LF01','ELCBOG-SW00','ELCBOG-SW01','ELCBOM01','ELCCOA00','ELCCOA01' >> MainBatchUpload.sql
echo ,'ELCCOG00','ELCCOG01','ELCGEO01','ELCHFO00','ELCHFO01','ELCHYD00','ELCHYD01','ELCHYG01','ELCHYGD01','ELCHYGI01','ELCLFO00','ELCLFO01' >> MainBatchUpload.sql
echo ,'ELCLPG00','ELCLPG01','ELCMSC00','ELCMSC01','ELCMSWINO00','ELCMSWINO01','ELCMSWORG00','ELCMSWORG01','ELCNGA00','ELCNGA01','ELCPELH01','ELCPELL00' >> MainBatchUpload.sql
echo ,'ELCPELL01','ELCPOLWST00','ELCPOLWST01','ELCSOL00','ELCSOL01','ELCSTWWST00','ELCSTWWST01','ELCTID01','ELCURN00','ELCURN01','ELCWAV01','ELCWNDOFS00' >> MainBatchUpload.sql
echo ,'ELCWNDOFS01','ELCWNDONS00','ELCWNDONS01') then 'FUEL TECHS ELC' >> MainBatchUpload.sql
echo when process in('INDBENZ00','INDBENZ01','INDBFG00','INDBFG01','INDBIOLFO01','INDBIOLPG01','INDBIOOIL01','INDBIOPOL01','INDBOG-AD01','INDBOG-LF00','INDBOG-LF01','INDBOM01' >> MainBatchUpload.sql
echo ,'INDCOA00','INDCOA01','INDCOACOK00','INDCOACOK01','INDCOG00','INDCOG01','INDCOK00','INDCOK01','INDELC00','INDELC01','INDHFO00','INDHFO01' >> MainBatchUpload.sql
echo ,'INDHYG01','INDKER00','INDKER01','INDLFO00','INDLFO01','INDLPG01','INDMSWINO00','INDMSWINO01','INDMSWORG00','INDMSWORG01','INDNGA00','INDNGA01' >> MainBatchUpload.sql
echo ,'INDOILLPG00','INDPELH01','INDPELL00','INDPELL01','INDPOLWST00','INDSYGCOA01','INDSYGOIL01','INDWHO01','INDWOD01','INDWODWST00','INDWODWST01') then 'FUEL TECHS INDUS' >> MainBatchUpload.sql
echo when process in('PHBIOOIL01','PHCOA01','PHELC01','PHELCSURP01','PHMSWINO01','PHMSWORG01','PHNGAL01','PHPELH01','PHPELL01') then 'FUEL TECHS HYG' >> MainBatchUpload.sql
echo when process in('PRCCOA00','PRCCOA01','PRCCOACOK00','PRCCOACOK01','PRCELC00','PRCELC01','PRCHFO00','PRCHFO01','PRCNGA00','PRCNGA01','PRCOILCRD00','PRCOILCRD01') >> MainBatchUpload.sql
echo then 'FUEL TECHS PRC' >> MainBatchUpload.sql
echo when process in('RESBIOLFO01','RESBIOM01','RESCOA00','RESCOA01','RESCOK00','RESCOK01','RESELC00','RESELC01','RESHYG01','RESKER00','RESKER01','RESLFO00' >> MainBatchUpload.sql
echo ,'RESLFO01','RESLPG00','RESLPG01','RESNGAS00','RESNGAS01','RESPELH01','RESSOL00','RESSOL01','RESWOD00','RESWOD01','RESWODL00','RESWODL01','RESMSWINO01','RESMSWORG01') then 'FUEL TECHS RES' >> MainBatchUpload.sql
echo when process in('SERBIOLFO01','SERBOG-SW00','SERBOG-SW01','SERBOM01','SERCOA00','SERCOA01','SERELC00','SERELC01','SERGEO00','SERGEO01','SERHFO00','SERHFO01' >> MainBatchUpload.sql
echo ,'SERHYG01','SERKER01','SERLFO00','SERLFO01','SERLPG01','SERMSWBIO01','SERMSWINO00','SERMSWINO01','SERMSWORG00','SERMSWORG01','SERNGA00','SERNGA01' >> MainBatchUpload.sql
echo ,'SERPELH01','SERSOL01','SERWOD01') then 'FUEL TECHS SERV' >> MainBatchUpload.sql
echo when process in('TRABIODST00','TRACOA00','TRADST00','TRAELC00','TRAETH00','TRAHFODS00','TRAHFOIS00','TRAJETDA00','TRAJETIA00','TRALFO00','TRALFODS00','TRALPG00','TRAPET00', >> MainBatchUpload.sql
echo 'TRABIODST01','TRABIODST-FT01','TRABIOJET-FTDA01','TRABIOJET-FTIA01','TRABIOLFO01','TRABIOLFODS01','TRABIOOILIS01','TRABOM01','TRADST01','TRAELC01','TRAETH01', >> MainBatchUpload.sql
echo 'TRAHFODS01','TRAHFOIS01','TRAHYGP01','TRAHYGPDS01','TRAHYGPIS01','TRAHYL01','TRAHYLDA01','TRAHYLIA01','TRAJETDA01','TRAJETIA01','TRALFO01','TRALFODS01','TRALNGDS01', >> MainBatchUpload.sql
echo 'TRALNGIS01','TRALPG01','TRANGA01','TRAPET01') then 'FUEL TECHS TRA' >> MainBatchUpload.sql
echo when process in('UPSELC00','UPSELC01','UPSHYG01','UPSLFO00','UPSLFO01','UPSNGA00','UPSNGA01') then 'FUEL TECHS UPSTREAM' >> MainBatchUpload.sql
echo end as proc_set, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when commodity in('BENZ','BFG','COG','COK','ELCBFG','ELCCOG','IISBFGB','IISBFGC','IISCOGB','IISCOGC','IISCOKB','IISCOKE' >> MainBatchUpload.sql
echo ,'IISCOKS','INDBENZ','INDBFG','INDCOG','INDCOK','RESCOK') then 'ALL MANFUELS' >> MainBatchUpload.sql
echo when commodity in('AGRNGA','ELCNGA','HYGLNGA','HYGSNGA','IISNGAB','IISNGAC','IISNGAE','INDNEUNGA','INDNGA','LNG','NGA','NGA-E' >> MainBatchUpload.sql
echo ,'NGA-E-EU','NGA-E-IRE','NGA-I-EU','NGA-I-N','NGAPTR','PRCNGA','RESNGA','SERNGA','TRACNGL','TRACNGS','TRALNG','TRALNGDS' >> MainBatchUpload.sql
echo ,'TRALNGDSL','TRALNGIS','TRALNGISL','TRANGA','UPSNGA') then 'ALL GAS' >> MainBatchUpload.sql
echo when commodity in('AGRDISTELC','AGRELC','ELC','ELC-E-EU','ELC-E-IRE','ELC-I-EU','ELC-I-IRE','ELCGEN','ELCSURPLUS','HYGELC','HYGELCSURP','HYGLELC' >> MainBatchUpload.sql
echo ,'HYGSELC','INDDISTELC','INDELC','PRCELC','RESDISTELC','RESELC','RESELCSURPLUS','RESHOUSEELC','SERBUILDELC','SERDISTELC','SERELC','TRACELC' >> MainBatchUpload.sql
echo ,'TRACPHB','TRADISTELC','TRAELC','UPSELC') then 'ALL ELECTRICITY' >> MainBatchUpload.sql
echo when commodity in('ICHOTH','ICHSTM','IFDSTM','INDSTM','INMSTM','IOISTM','PCHPHEAT','RHCSV-RHEA','RHEATPIPE-EA','RHEATPIPE-NA','UPSHEAT') then 'ALL HEAT' >> MainBatchUpload.sql
echo when commodity in('ELCGEO','ELCHYDDAM','ELCSOL','ELCTID','ELCWAV','ELCWNDOFS','ELCWNDONS','GEO','HYDDAM','HYDROR','RESSOL','SERGEO' >> MainBatchUpload.sql
echo ,'SERSOL','SOL','TID','WAV','WNDOFF','WNDONS') then 'ALL OTHER RNW' >> MainBatchUpload.sql
echo when commodity in('AGRCOA','COA','COA-E','COACOK','ELCCOA','HYGCOA','INDCOA','INDCOACOK','INDSYNCOA','PRCCOA','PRCCOACOK','RESCOA' >> MainBatchUpload.sql
echo ,'SERCOA','SYNCOA','TRACOA') then 'ALL COALS' >> MainBatchUpload.sql
echo when commodity in('AGRBIODST','AGRBIOLPG','AGRBOM','AGRGRASS','AGRMAINSBOM','AGRPOLWST','BGRASS','BIODST','BIODST-FT','BIOJET-FT','BIOKER-FT','BIOLFO' >> MainBatchUpload.sql
echo ,'BIOLPG','BIOOIL','BOG-AD','BOG-G','BOG-LF','BOM','BPELH','BPELL','BRSEED','BSEWSLG','BSLURRY','BSTARCH' >> MainBatchUpload.sql
echo ,'BSTWWST','BSUGAR','BTREATSTW','BTREATWOD','BVOIL','BWOD','BWODLOG','BWODWST','ELCBIOCOA','ELCBIOCOA2','ELCBIOLFO','ELCBIOOIL' >> MainBatchUpload.sql
echo ,'ELCBOG-AD','ELCBOG-LF','ELCBOG-SW','ELCBOM','ELCMAINSBOM','ELCMSWINO','ELCMSWORG','ELCPELH','ELCPELL','ELCPOLWST','ELCSTWWST','ELCTRANSBOM' >> MainBatchUpload.sql
echo ,'ETH','HYGBIOO','HYGBPEL','HYGMSWINO','HYGMSWORG','INDBIOLFO','INDBIOLPG','INDBIOOIL','INDBOG-AD','INDBOG-LF','INDBOM','INDGRASS' >> MainBatchUpload.sql
echo ,'INDMAINSBOM','INDMSWINO','INDMSWORG','INDPELH','INDPELL','INDPOLWST','INDWOD','INDWODWST','METH','MSWBIO','MSWINO','MSWORG' >> MainBatchUpload.sql
echo ,'PWASTEDUM','RESBIOLFO','RESBOM','RESHOUSEBOM','RESMAINSBOM','RESMSWINO','RESMSWORG','RESPELH','RESWOD','RESWODL','SERBIOLFO','SERBOG','SERBOM','SERBUILDBOM' >> MainBatchUpload.sql
echo ,'SERMAINSBOM','SERMSWBIO','SERMSWINO','SERMSWORG','SERPELH','SERWOD','TRABIODST','TRABIODST-FT','TRABIODST-FTL','TRABIODST-FTS','TRABIODSTL','TRABIODSTS' >> MainBatchUpload.sql
echo ,'TRABIOJET-FTDA','TRABIOJET-FTDAL','TRABIOJET-FTIA','TRABIOJET-FTIAL','TRABIOLFO','TRABIOLFODS','TRABIOLFODSL','TRABIOLFOL','TRABIOOILIS','TRABIOOILISL','TRABOM','TRAETH' >> MainBatchUpload.sql
echo ,'TRAETHL','TRAETHS','TRAMAINSBOM','TRAMETH') then 'ALL BIO' >> MainBatchUpload.sql
echo when commodity in('AGRHFO','AGRLFO','AGRLPG','ELCHFO','ELCLFO','ELCLPG','ELCMSC','IISHFOB','INDHFO','INDKER','INDLFO','INDLPG' >> MainBatchUpload.sql
echo ,'INDNEULFO','INDNEULPG','INDNEUMSC','INDSYNOIL','OILCRD','OILCRDRAW','OILCRDRAW-E','OILDST','OILHFO','OILJET','OILKER','OILLFO' >> MainBatchUpload.sql
echo ,'OILLPG','OILMSC','OILPET','PRCHFO','PRCOILCRD','RESKER','RESLFO','RESLPG','SERHFO','SERKER','SERLFO','SERLPG' >> MainBatchUpload.sql
echo ,'SYNOIL','TRADST','TRADSTL','TRADSTS','TRAHFO','TRAHFODS','TRAHFODSL','TRAHFOIS','TRAHFOISL','TRAJETDA','TRAJETDAEL','TRAJETIA' >> MainBatchUpload.sql
echo ,'TRAJETIAEL','TRAJETIANL','TRAJETL','TRALFO','TRALFODS','TRALFODSL','TRALFOL','TRALPG','TRALPGL','TRALPGS','TRAPET','TRAPETL' >> MainBatchUpload.sql
echo ,'TRAPETS','UPSLFO') then 'ALL OIL PRODUCTS' >> MainBatchUpload.sql
echo when commodity in('AGRHYG','ELCHYG','ELCHYGIGCC','HYGL','HYGL-IGCC','HYGLHPD','HYGLHPT','HYL','HYLTK','INDHYG','INDMAINSHYG','RESHOUSEHYG' >> MainBatchUpload.sql
echo ,'RESHYG','RESHYGREF-EA','RESHYGREF-NA','RESMAINSHYG','SERBUILDHYG','SERHYG','SERMAINSHYG','TRAHYG','TRAHYGDCN','TRAHYGL','TRAHYGS','TRAHYL' >> MainBatchUpload.sql
echo ,'UPSHYG','UPSMAINSHYG') then 'ALL HYDROGEN' >> MainBatchUpload.sql
echo end as comm_set >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FIn' >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where proc_set is not null and comm_set is not null >> MainBatchUpload.sql
echo group by tablename, proc_set,comm_set,period >> MainBatchUpload.sql
echo order by proc_set,comm_set >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , "elc+gas_final_consumption" as( >> MainBatchUpload.sql
echo select tablename, commodity,period,sum(pv) "pv" >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FOut' and commodity in('AGRBOM','AGRDISTELC','AGRMAINSBOM','AGRMAINSGAS','INDBOM','INDDISTELC','INDMAINSBOM','INDMAINSGAS','RESBOM','RESDISTELC','RESMAINSBOM','RESMAINSGAS', >> MainBatchUpload.sql
echo 'SERBOM','SERDISTELC','SERMAINSBOM','SERMAINSGAS','TRABOM','TRADISTELC','TRAMAINSBOM','TRAMAINSGAS','RESELC-NS-E','RESELC-NS-N') >> MainBatchUpload.sql
echo group by tablename, period, commodity >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , mainsbom as( >> MainBatchUpload.sql
echo select tablename, period, sum(case when commodity='RESMAINSBOM' then pv else 0 end) "resmainsbom" >> MainBatchUpload.sql
echo ,sum(case when commodity='INDMAINSBOM' then pv else 0 end) "indmainsbom" >> MainBatchUpload.sql
echo from "elc+gas_final_consumption" >> MainBatchUpload.sql
echo group by tablename, period >> MainBatchUpload.sql
echo ), elc_waste_heat_distribution as( >> MainBatchUpload.sql
echo select tablename, commodity,attribute,process,period,sum(pv) "pv" >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where commodity='ELCLTH' and attribute in ('VAR_FIn','VAR_FOut') >> MainBatchUpload.sql
echo group by tablename, commodity,attribute,process,period >> MainBatchUpload.sql
echo ), >> MainBatchUpload.sql
echo elc_prd_fuel as ( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo proc_set,tablename,period, sum(pv) "pv" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select tablename,period, pv, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('EBIO01','EBIOCON00','EBIOS00','EBOG-ADE01','EBOG-LFE00','EBOG-LFE01','EBOG-SWE00','EBOG-SWE01','EMSW00','EMSW01','EPOLWST00','ESTWWST00' >> MainBatchUpload.sql
echo ,'ESTWWST01') then 'ELC FROM BIO' >> MainBatchUpload.sql
echo when process in('EBIOQ01') then 'ELC FROM BIO CCS' >> MainBatchUpload.sql
echo when process in('PCHP-CCP00','PCHP-CCP01','UCHP-CCG00','UCHP-CCG01') then 'ELC FROM CHP' >> MainBatchUpload.sql
echo when process='ECOAQR01' then 'ELC FROM COAL CCSRET' >> MainBatchUpload.sql
echo when process in('ECOARR01') then 'ELC FROM COAL RR' >> MainBatchUpload.sql
echo when process in('ECOA00','ECOABIO00') then 'ELC FROM COAL-COF' >> MainBatchUpload.sql
echo when process in('ECOAQ01','ECOAQDEMO01') then 'ELC FROM COALCOF CCS' >> MainBatchUpload.sql
echo when process in('ENGACCT00','ENGAOCT00','ENGAOCT01','ENGARCPE00','ENGARCPE01') then 'ELC FROM GAS' >> MainBatchUpload.sql
echo when process in('ENGACCTQ01','ENGACCTQDEMO01') then 'ELC FROM GAS CCS' >> MainBatchUpload.sql
echo when process='ENGAQR01' then 'ELC FROM GAS CCSRET' >> MainBatchUpload.sql
echo when process in('ENGACCTRR01') then 'ELC FROM GAS RR' >> MainBatchUpload.sql
echo when process in('EGEO01') then 'ELC FROM GEO' >> MainBatchUpload.sql
echo when process in('EHYD00','EHYD01') then 'ELC FROM HYDRO' >> MainBatchUpload.sql
echo when process in('EHYGCCT01','EHYGOCT01') then 'ELC FROM HYDROGEN' >> MainBatchUpload.sql
echo when process in('ELCIE00','ELCIE01','ELCII00','ELCII01') then 'ELC FROM IMPORTS' >> MainBatchUpload.sql
echo when process in('EMANOCT00','EMANOCT01') then 'ELC FROM MANFUELS' >> MainBatchUpload.sql
echo when process in('ENUCPWR00','ENUCPWR101','ENUCPWR102') then 'ELC FROM NUCLEAR' >> MainBatchUpload.sql
echo when process in('EDSTRCPE00','EDSTRCPE01','EHFOIGCC01','EOILL00','EOILL01','EOILS00','EOILS01') then 'ELC FROM OIL' >> MainBatchUpload.sql
echo when process in('EHFOIGCCQ01') then 'ELC FROM OIL CCS' >> MainBatchUpload.sql
echo when process in('ESOL00','ESOL01','ESOLPV00','ESOLPV01') then 'ELC FROM SOL-PV' >> MainBatchUpload.sql
echo when process in('ETIB101','ETIR101','ETIS101') then 'ELC FROM TIDAL' >> MainBatchUpload.sql
echo when process in('EWAV101') then 'ELC FROM WAVE' >> MainBatchUpload.sql
echo when process in('EWNDOFF00','EWNDOFF101','EWNDOFF201') then 'ELC FROM WIND-OFFSH' >> MainBatchUpload.sql
echo when process in('EWNDONS00','EWNDONS101','EWNDONS201') then 'ELC FROM WIND-ONSH' >> MainBatchUpload.sql
echo when process in('ELCEE00','ELCEE01','ELCEI00','ELCEI01') then 'ELC TO EXPORTS' >> MainBatchUpload.sql
echo end as proc_set >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FOut' and commodity in('ELCDUMMY','ELC','ELC-E-IRE','ELC-E-EU','ELCGEN') >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where proc_set is not null >> MainBatchUpload.sql
echo group by tablename, period,proc_set >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo , end_demand as( >> MainBatchUpload.sql
echo select a.tablename >> MainBatchUpload.sql
echo ,sec_fuel, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when sec_fuel='ind-bio' then sum(a.pv-ind_bio_chp-(1-0.9828)/0.9828*(case when c.indmainsbom is null then 0 else c.indmainsbom end)) >> MainBatchUpload.sql
echo when sec_fuel='ind-coa' then sum(a.pv-ind_coa_chp) >> MainBatchUpload.sql
echo when sec_fuel='ind-gas' then sum(a.pv-ind_gas_chp) >> MainBatchUpload.sql
echo when sec_fuel='ind-hyd' then sum(a.pv-ind_hyd_chp) >> MainBatchUpload.sql
echo when sec_fuel='ind-man' then sum(a.pv-ind_man_chp) >> MainBatchUpload.sql
echo when sec_fuel='ind-oil' then sum(a.pv-ind_oil_chp) >> MainBatchUpload.sql
echo when sec_fuel='res-bio' then sum(a.pv-res_bio_chp-(1-0.9828)/0.9828*(case when c.resmainsbom is null then 0 else c.resmainsbom end)) >> MainBatchUpload.sql
echo when sec_fuel='res-gas' then sum(a.pv-res_gas_chp) >> MainBatchUpload.sql
echo when sec_fuel='ser-bio' then sum(a.pv-ser_bio_chp) >> MainBatchUpload.sql
echo when sec_fuel='ser-gas' then sum(a.pv-ser_gas_chp) >> MainBatchUpload.sql
echo when sec_fuel='elc-bio' then sum(a.pv+ind_bio_chp+res_bio_chp+ser_bio_chp) >> MainBatchUpload.sql
echo when sec_fuel='elc-coa' then sum(a.pv+ind_coa_chp) >> MainBatchUpload.sql
echo when sec_fuel='elc-gas' then sum(a.pv+ind_gas_chp+res_gas_chp+ser_gas_chp+prc_gas_chp+ups_gas_chp) >> MainBatchUpload.sql
echo when sec_fuel='elc-man' then sum(a.pv+ind_bypro_chp+ind_man_chp) >> MainBatchUpload.sql
echo when sec_fuel='elc-oil' then sum(a.pv+ind_oil_chp+prc_oil_chp+prc_refgas_chp) >> MainBatchUpload.sql
echo when sec_fuel='elc-oil' then sum(a.pv+ind_oil_chp+prc_oil_chp+prc_refgas_chp) >> MainBatchUpload.sql
echo when sec_fuel='elc-hyd' then sum(a.pv+ind_hyd_chp+res_hyd_chp+ser_hyd_chp) >> MainBatchUpload.sql
echo else sum(pv) >> MainBatchUpload.sql
echo end as pv,a.period >> MainBatchUpload.sql
echo from( >> MainBatchUpload.sql
echo select case >> MainBatchUpload.sql
echo when commodity='AGRDISTELC' then 'agr-elc' >> MainBatchUpload.sql
echo when commodity='AGRMAINSGAS' then 'agr-gas' >> MainBatchUpload.sql
echo when commodity='INDDISTELC' then 'ind-elc' >> MainBatchUpload.sql
echo when commodity='INDMAINSGAS' then 'ind-gas' >> MainBatchUpload.sql
echo when commodity='SERDISTELC' then 'ser-elc' >> MainBatchUpload.sql
echo when commodity='SERMAINSGAS' then 'ser-gas' >> MainBatchUpload.sql
echo when commodity='TRADISTELC' then 'tra-elc' >> MainBatchUpload.sql
echo when commodity='RESDISTELC' then 'res-elc' >> MainBatchUpload.sql
echo when commodity='RESMAINSGAS' then 'res-gas' >> MainBatchUpload.sql
echo end as sec_fuel, >> MainBatchUpload.sql
echo tablename, period,pv >> MainBatchUpload.sql
echo from "elc+gas_final_consumption" >> MainBatchUpload.sql
echo where commodity in('AGRDISTELC' ,'AGRMAINSGAS' ,'INDDISTELC' ,'INDMAINSGAS' ,'SERDISTELC' ,'SERMAINSGAS' ,'TRADISTELC' ,'RESDISTELC' ,'RESMAINSGAS') >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select case >> MainBatchUpload.sql
echo when proc_set='FUEL TECHS AGR' then 'agr-' >> MainBatchUpload.sql
echo when proc_set='FUEL TECHS INDUS' then 'ind-' >> MainBatchUpload.sql
echo when proc_set='FUEL TECHS PRC' then 'prc-' >> MainBatchUpload.sql
echo when proc_set='FUEL TECHS RES' then 'res-' >> MainBatchUpload.sql
echo when proc_set='FUEL TECHS SERV' then 'ser-' >> MainBatchUpload.sql
echo when proc_set='FUEL TECHS TRA' then 'tra-' >> MainBatchUpload.sql
echo when proc_set='FUEL TECHS HYG' then 'hyd-' >> MainBatchUpload.sql
echo when proc_set='FUEL TECHS ELC' then 'elc-' >> MainBatchUpload.sql
echo end ^|^| >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when comm_set='ALL BIO' then 'bio' >> MainBatchUpload.sql
echo when comm_set='ALL COALS' then 'coa' >> MainBatchUpload.sql
echo when comm_set='ALL ELECTRICITY' then 'elc' >> MainBatchUpload.sql
echo when comm_set='ALL GAS' then 'gas' >> MainBatchUpload.sql
echo when comm_set='ALL HYDROGEN' then 'hyd' >> MainBatchUpload.sql
echo when comm_set='ALL OIL PRODUCTS' then 'oil' >> MainBatchUpload.sql
echo when comm_set='ALL OTHER RNW' then 'orens' >> MainBatchUpload.sql
echo when comm_set='ALL MANFUELS' then 'man' >> MainBatchUpload.sql
echo end as sec_fuel,tablename, period,pv >> MainBatchUpload.sql
echo from all_finencon_all >> MainBatchUpload.sql
echo where proc_set in('FUEL TECHS HYG','FUEL TECHS PRC') or (proc_set in('FUEL TECHS AGR','FUEL TECHS INDUS','FUEL TECHS RES','FUEL TECHS SERV') and >> MainBatchUpload.sql
echo comm_set in('ALL BIO','ALL COALS','ALL HYDROGEN','ALL OIL PRODUCTS','ALL MANFUELS','ALL OTHER RNW')) or >> MainBatchUpload.sql
echo (proc_set in('FUEL TECHS TRA','FUEL TECHS ELC') and comm_set in('ALL BIO','ALL COALS','ALL HYDROGEN','ALL OIL PRODUCTS','ALL MANFUELS','ALL OTHER RNW','ALL GAS')) >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select case >> MainBatchUpload.sql
echo when process='SDH-WHO01' then 'ser-wh' >> MainBatchUpload.sql
echo when process in('RDHEA-WHO01','RDHHC-WHO01','RDHHS-WHO01','RDHFC-WHO01','RDHFS-WHO01','RDHNA-WHO01') then 'res-wh' >> MainBatchUpload.sql
echo end as sec_fuel, tablename, period,sum(pv) "pv" >> MainBatchUpload.sql
echo from elc_waste_heat_distribution >> MainBatchUpload.sql
echo where process in('RDHEA-WHO01','RDHHC-WHO01','RDHHS-WHO01','RDHFC-WHO01','RDHFS-WHO01','RDHNA-WHO01','SDH-WHO01') >> MainBatchUpload.sql
echo group by sec_fuel, tablename, period >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select 'elc-urn' "sec_fuel",tablename, period,sum(pv/0.398) >> MainBatchUpload.sql
echo from elc_prd_fuel >> MainBatchUpload.sql
echo where proc_set='ELC FROM NUCLEAR' >> MainBatchUpload.sql
echo group by tablename, period >> MainBatchUpload.sql
echo ) a left join chp b on a.period=b.period and a.tablename=b.tablename >> MainBatchUpload.sql
echo left join mainsbom c on a.period=c.period and a.tablename=c.tablename >> MainBatchUpload.sql
echo group by a.tablename, sec_fuel, a.period >> MainBatchUpload.sql
echo order by a.period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo select 'fin-en-main-secs_' ^|^| sec_fuel ^|^| '^|' ^|^| tablename ^|^| '^|various^|various^|various'::varchar "id", >> MainBatchUpload.sql
echo 'fin-en-main-secs_'^|^| sec_fuel::varchar "analysis", >> MainBatchUpload.sql
echo tablename, >> MainBatchUpload.sql
echo 'various'::varchar "attribute", >> MainBatchUpload.sql
echo 'various'::varchar "commodity", >> MainBatchUpload.sql
echo 'various'::varchar "process", >> MainBatchUpload.sql
echo sum(pv) "all", >> MainBatchUpload.sql
echo sum(case when a.period='2010' then pv else 0 end) as "2010", >> MainBatchUpload.sql
echo sum(case when a.period='2011' then pv else 0 end) as "2011", >> MainBatchUpload.sql
echo sum(case when a.period='2012' then pv else 0 end) as "2012", >> MainBatchUpload.sql
echo sum(case when a.period='2015' then pv else 0 end) as "2015", >> MainBatchUpload.sql
echo sum(case when a.period='2020' then pv else 0 end) as "2020", >> MainBatchUpload.sql
echo sum(case when a.period='2025' then pv else 0 end) as "2025", >> MainBatchUpload.sql
echo sum(case when a.period='2030' then pv else 0 end) as "2030", >> MainBatchUpload.sql
echo sum(case when a.period='2035' then pv else 0 end) as "2035", >> MainBatchUpload.sql
echo sum(case when a.period='2040' then pv else 0 end) as "2040", >> MainBatchUpload.sql
echo sum(case when a.period='2045' then pv else 0 end) as "2045", >> MainBatchUpload.sql
echo sum(case when a.period='2050' then pv else 0 end) as "2050", >> MainBatchUpload.sql
echo sum(case when a.period='2055' then pv else 0 end) as "2055", >> MainBatchUpload.sql
echo sum(case when a.period='2060' then pv else 0 end) as "2060" >> MainBatchUpload.sql
echo from end_demand a >> MainBatchUpload.sql
echo group by tablename,sec_fuel >> MainBatchUpload.sql
echo order by tablename,analysis >> MainBatchUpload.sql
echo ) TO '%~dp0FinEnOut.csv' delimiter ',' CSV; >> MainBatchUpload.sql
rem /* *Primary energy demand and biomass, imports exports and domestic production* */echo /* *Primary energy demand and biomass, imports exports and domestic production* */ >> MainBatchUpload.sql
echo COPY ( >> MainBatchUpload.sql
echo with rsr_min as( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo sum(case when proc_set='IMPORT URN' then pv else 0 end) "IMPORT URN" >> MainBatchUpload.sql
echo ,sum(case when proc_set='MINING BIOMASS' then pv else 0 end) "MINING BIOMASS" >> MainBatchUpload.sql
echo ,sum(case when proc_set='MINING COAL' then pv else 0 end) "MINING COAL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='MINING GEOTHERMAL' then pv else 0 end) "MINING GEOTHERMAL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='MINING HYDRO' then pv else 0 end) "MINING HYDRO" >> MainBatchUpload.sql
echo ,sum(case when proc_set='MINING NGA' then pv else 0 end) "MINING NGA" >> MainBatchUpload.sql
echo ,sum(case when proc_set='MINING NGA-SHALE' then pv else 0 end) "MINING NGA-SHALE" >> MainBatchUpload.sql
echo ,sum(case when proc_set='MINING OIL' then pv else 0 end) "MINING OIL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='MINING SOLAR' then pv else 0 end) "MINING SOLAR" >> MainBatchUpload.sql
echo ,sum(case when proc_set='MINING TIDAL' then pv else 0 end) "MINING TIDAL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='MINING WIND' then pv else 0 end) "MINING WIND" >> MainBatchUpload.sql
echo ,sum(case when proc_set='MINING WAVE' then pv else 0 end) "MINING WAVE" >> MainBatchUpload.sql
echo ,sum(case when proc_set='MINING INORGANIC WASTE' then pv else 0 end) "MINING INORGANIC WASTE", >> MainBatchUpload.sql
echo tablename,period >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select tablename,period, pv, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when  process in('IMPURN') then 'IMPORT URN' >> MainBatchUpload.sql
echo when  process in('MINBGRASS1','MINBGRASS2','MINBGRASS3','MINBIOOILCRP','MINBOG-LF','MINBRSEED','MINBSEWSLG','MINBSLURRY1','MINBSTWWST1','MINBSUGAR','MINBTALLOW','MINBVOFAT' >> MainBatchUpload.sql
echo ,'MINBWHT1','MINBWHT2','MINBWHT3','MINBWOD1','MINBWOD2','MINBWOD3','MINBWOD4','MINBWODLOG','MINBWODWST','MINBWODWSTSAW','MINMSWBIO', >> MainBatchUpload.sql
echo 'MINMSWORG') then 'MINING BIOMASS' >> MainBatchUpload.sql
echo when  process in('MINCOA1','MINCOA2','MINCOA3','MINCOA4','MINCOA5','MINCOA6','MINCOACOK1','MINCOACOK2') then 'MINING COAL' >> MainBatchUpload.sql
echo when  process in('RNWGEO') then 'MINING GEOTHERMAL' >> MainBatchUpload.sql
echo when  process in('RNWHYDDAM','RNWHYDROR') then 'MINING HYDRO' >> MainBatchUpload.sql
echo when  process in('MINNGA1','MINNGA2','MINNGA3','MINNGA4','MINNGA5','MINNGA6','MINNGA7','MINNGA8','MINNGA9') then 'MINING NGA' >> MainBatchUpload.sql
echo when  process in('MINNGASHL1','MINNGASHL2','MINNGASHL3') then 'MINING NGA-SHALE' >> MainBatchUpload.sql
echo when  process in('MINOILCRD1','MINOILCRD2','MINOILCRD3','MINOILCRD4','MINOILCRD5','MINOILCRD6','MINOILCRD7','MINOILCRD8','MINOILCRD9') then 'MINING OIL' >> MainBatchUpload.sql
echo when  process in('RNWSOL') then 'MINING SOLAR' >> MainBatchUpload.sql
echo when  process in('RNWTID') then 'MINING TIDAL' >> MainBatchUpload.sql
echo when  process in('RNWWAV') then 'MINING WAVE' >> MainBatchUpload.sql
echo when  process in('RNWWNDOFF','RNWWNDONS') then 'MINING WIND' >> MainBatchUpload.sql
echo when process in('MINMSWINO') then 'MINING INORGANIC WASTE' >> MainBatchUpload.sql
echo else null >> MainBatchUpload.sql
echo end as proc_set >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FOut' >> MainBatchUpload.sql
echo and commodity in('AGRBIODST','AGRBIOLPG','AGRBOM','AGRCOA','AGRGRASS','AGRHFO','AGRLFO', >> MainBatchUpload.sql
echo 'AGRLPG','AGRMAINSBOM','AGRNGA','AGRPOLWST','BGRASS','BIODST','BIODST-FT','BIOJET-FT', >> MainBatchUpload.sql
echo 'BIOKER-FT','BIOLFO','BIOLPG','BIOOIL','BOG-AD','BOG-G','BOG-LF','BOM','BPELH','BPELL', >> MainBatchUpload.sql
echo 'BRSEED','BSEWSLG','BSLURRY','BSTARCH','BSTWWST','BSUGAR','BTREATSTW','BTREATWOD','BVOIL', >> MainBatchUpload.sql
echo 'BWOD','BWODLOG','BWODWST','COA','COACOK','COA-E','ELCBIOCOA','ELCBIOCOA2','ELCBIOLFO', >> MainBatchUpload.sql
echo 'ELCBIOOIL','ELCBOG-AD','ELCBOG-LF','ELCBOG-SW','ELCBOM','ELCCOA','ELCGEO','ELCHFO', >> MainBatchUpload.sql
echo 'ELCHYDDAM','ELCLFO','ELCLPG','ELCMAINSBOM','ELCMSC','ELCMSWINO','ELCMSWORG','ELCNGA', >> MainBatchUpload.sql
echo 'ELCPELH','ELCPELL','ELCPOLWST','ELCSOL','ELCSTWWST','ELCTID','ELCTRANSBOM','ELCWAV', >> MainBatchUpload.sql
echo 'ELCWNDOFS','ELCWNDONS','ETH','GEO','HYDDAM','HYDROR','HYGBIOO','HYGBPEL','HYGCOA', >> MainBatchUpload.sql
echo 'HYGLNGA','HYGMSWINO','HYGMSWORG','HYGSNGA','IISHFOB','IISNGAB','IISNGAC','IISNGAE', >> MainBatchUpload.sql
echo 'INDBIOLFO','INDBIOLPG','INDBIOOIL','INDBOG-AD','INDBOG-LF','INDBOM','INDCOA', >> MainBatchUpload.sql
echo 'INDCOACOK','INDGRASS','INDHFO','INDKER','INDLFO','INDLPG','INDMAINSBOM','INDMSWINO', >> MainBatchUpload.sql
echo 'INDMSWORG','INDNEULFO','INDNEULPG','INDNEUMSC','INDNEUNGA','INDNGA','INDPELH','INDPELL', >> MainBatchUpload.sql
echo 'INDPOLWST','INDSYNCOA','INDSYNOIL','INDWOD','INDWODWST','LNG','METH','MSWBIO','MSWINO', >> MainBatchUpload.sql
echo 'MSWORG','NGA','NGA-E','NGA-E-EU','NGA-E-IRE','NGA-I-EU','NGA-I-N','NGAPTR','OILCRD', >> MainBatchUpload.sql
echo 'OILCRDRAW','OILCRDRAW-E','OILDST','OILHFO','OILJET','OILKER','OILLFO','OILLPG','OILMSC', >> MainBatchUpload.sql
echo 'OILPET','PRCCOA','PRCCOACOK','PRCHFO','PRCNGA','PRCOILCRD','PWASTEDUM','RESBIOLFO', >> MainBatchUpload.sql
echo 'RESBOM','RESCOA','RESHOUSEBOM','RESKER','RESLFO','RESLPG','RESMAINSBOM','RESMSWINO', >> MainBatchUpload.sql
echo 'RESMSWORG','RESNGA','RESPELH','RESSOL','RESWOD','RESWODL','SERBIOLFO','SERBOG','SERBOM', >> MainBatchUpload.sql
echo 'SERBUILDBOM','SERCOA','SERGEO','SERHFO','SERKER','SERLFO','SERLPG','SERMAINSBOM', >> MainBatchUpload.sql
echo 'SERMSWBIO','SERMSWINO','SERMSWORG','SERNGA','SERPELH','SERSOL','SERWOD','SOL','SYNCOA', >> MainBatchUpload.sql
echo 'SYNOIL','TID','TRABIODST','TRABIODST-FT','TRABIODST-FTL','TRABIODST-FTS','TRABIODSTL', >> MainBatchUpload.sql
echo 'TRABIODSTS','TRABIOJET-FTDA','TRABIOJET-FTDAL','TRABIOJET-FTIA','TRABIOJET-FTIAL', >> MainBatchUpload.sql
echo 'TRABIOLFO','TRABIOLFODS','TRABIOLFODSL','TRABIOLFOL','TRABIOOILIS','TRABIOOILISL','TRABOM', >> MainBatchUpload.sql
echo 'TRACNGL','TRACNGS','TRACOA','TRADST','TRADSTL','TRADSTS','TRAETH','TRAETHL','TRAETHS', >> MainBatchUpload.sql
echo 'TRAHFO','TRAHFODS','TRAHFODSL','TRAHFOIS','TRAHFOISL','TRAJETDA','TRAJETDAEL','TRAJETIA', >> MainBatchUpload.sql
echo 'TRAJETIAEL','TRAJETIANL','TRAJETL','TRALFO','TRALFODS','TRALFODSL','TRALFOL','TRALNG', >> MainBatchUpload.sql
echo 'TRALNGDS','TRALNGDSL','TRALNGIS','TRALNGISL','TRALPG','TRALPGL','TRALPGS','TRAMAINSBOM', >> MainBatchUpload.sql
echo 'TRAMETH','TRANGA','TRAPET','TRAPETL','TRAPETS','UPSLFO','UPSNGA','URN','WAV','WNDOFF', >> MainBatchUpload.sql
echo 'WNDONS') >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where proc_set is not null group by tablename, period order by tablename,period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo ,rsr_imports as( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo sum(case when proc_set='IMPORT BDL' then pv else 0 end) "IMPORT BDL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT FTD' then pv else 0 end) "IMPORT FTD" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT FTK-AVI' then pv else 0 end) "IMPORT FTK-AVI" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT FTK-HEA' then pv else 0 end) "IMPORT FTK-HEA" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT BIOOIL' then pv else 0 end) "IMPORT BIOOIL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT BIOMASS' then pv else 0 end) "IMPORT BIOMASS" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT COAL' then pv else 0 end) "IMPORT COAL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT COKE' then pv else 0 end) "IMPORT COKE" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT ELC' then pv else 0 end) "IMPORT ELC" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT ETHANOL' then pv else 0 end) "IMPORT ETHANOL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT HYL' then pv else 0 end) "IMPORT HYL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT NGA' then pv else 0 end) "IMPORT NGA" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT OIL' then pv else 0 end) "IMPORT OIL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT DST' then pv else 0 end) "IMPORT DST" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT HFO' then pv else 0 end) "IMPORT HFO" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT JET' then pv else 0 end) "IMPORT JET" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT KER' then pv else 0 end) "IMPORT KER" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT LFO' then pv else 0 end) "IMPORT LFO" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT LPG' then pv else 0 end) "IMPORT LPG" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT MOIL' then pv else 0 end) "IMPORT MOIL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT GSL' then pv else 0 end) "IMPORT GSL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='IMPORT URN' then pv else 0 end) "IMPORT URN" >> MainBatchUpload.sql
echo ,tablename,period >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select tablename,period, pv, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('IMPBIODST') then 'IMPORT BDL' >> MainBatchUpload.sql
echo when process in('IMPBIODST-FT') then 'IMPORT FTD' >> MainBatchUpload.sql
echo when process in('IMPBIOJET-FT') then 'IMPORT FTK-AVI' >> MainBatchUpload.sql
echo when process in('IMPBIOKET-FT') then 'IMPORT FTK-HEA' >> MainBatchUpload.sql
echo when process in('IMPBIOOIL','IMPBVOFAT','IMPBVOIL') then 'IMPORT BIOOIL' >> MainBatchUpload.sql
echo when process in('IMPAGWST','IMPBGRASS','IMPBSTARCH','IMPBWOD','IMPBWODWST') then 'IMPORT BIOMASS' >> MainBatchUpload.sql
echo when process in('IMPCOA','IMPCOA-E','IMPCOACOK') then 'IMPORT COAL' >> MainBatchUpload.sql
echo when process in('IMPCOK') then 'IMPORT COKE' >> MainBatchUpload.sql
echo when process in('IMPELC-EU','IMPELC-IRE') then 'IMPORT ELC' >> MainBatchUpload.sql
echo when process in('IMPETH') then 'IMPORT ETHANOL' >> MainBatchUpload.sql
echo when process in('IMPHYL') then 'IMPORT HYL' >> MainBatchUpload.sql
echo when process in('IMPNGA-E','IMPNGA-EU','IMPNGA-LNG','IMPNGA-N') then 'IMPORT NGA' >> MainBatchUpload.sql
echo when process in('IMPOILCRD1','IMPOILCRD1-E','IMPOILCRD2') then 'IMPORT OIL' >> MainBatchUpload.sql
echo when process in('IMPOILDST') then 'IMPORT DST' >> MainBatchUpload.sql
echo when process in('IMPOILHFO') then 'IMPORT HFO' >> MainBatchUpload.sql
echo when process in('IMPOILJET') then 'IMPORT JET' >> MainBatchUpload.sql
echo when process in('IMPOILKER') then 'IMPORT KER' >> MainBatchUpload.sql
echo when process in('IMPOILLFO') then 'IMPORT LFO' >> MainBatchUpload.sql
echo when process in('IMPOILLPG') then 'IMPORT LPG' >> MainBatchUpload.sql
echo when process in('IMPOILMSC') then 'IMPORT MOIL' >> MainBatchUpload.sql
echo when process in('IMPOILPET') then 'IMPORT GSL' >> MainBatchUpload.sql
echo when process in('IMPURN') then 'IMPORT URN' >> MainBatchUpload.sql
echo end as proc_set >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FOut' >> MainBatchUpload.sql
echo and commodity in('INDPELL','BIOLPG','MSWINO','AGRLPG','HYLTK','AGRBOM','HYL','BOG-AD','SERBOM','TRALFODS','BIOJET-FT','NGA-I-EU' >> MainBatchUpload.sql
echo ,'OILCRDRAW','SYNOIL','IOISTM','RESHYG','RESHYGREF-NA','HYGLHPD','PRCOILCRD','TRAHYGS','PRCCOA','AGRBIODST','IISNGAE','SERWOD' >> MainBatchUpload.sql
echo ,'ELCMSWORG','BTREATWOD','INDCOK','TRABIOLFODS','NGAPTR','HYGSNGA','METH','BIODST-FT','TRALNGISL','TRAJETIANL','SERBOG','AGRELC' >> MainBatchUpload.sql
echo ,'HYDROR','UPSHYG','TRABIOOILISL','HYGMSWINO','ELCSTWWST','MSWORG','UPSNGA','TRAJETIA','INDSTM','SERELC','SERBUILDHYG','ELCCOG' >> MainBatchUpload.sql
echo ,'AGRDISTELC','TRADISTELC','AGRGRASS','TRALFO','HYGELCSURP','OILLPG','WNDOFF','PCHPHEAT','INDGRASS','HYGL-IGCC','BVOIL','COK' >> MainBatchUpload.sql
echo ,'RESHOUSEBOM','TRABIODST-FTS','ELC','IISCOGB','INDCOACOK','IISCOGC','TRAJETIAEL','UPSHEAT','AGRMAINSBOM','ELCBOM','HYGBIOO','TRAHFODSL' >> MainBatchUpload.sql
echo ,'COG','NGA','ELC-I-IRE','RESDISTELC','HYGL','ELCBIOCOA','AGRLFO','BIOKER-FT','TRALPGS','RESHOUSEELC','RESMAINSBOM','COACOK' >> MainBatchUpload.sql
echo ,'TRAHYGL','MSWBIO','RESWOD','PRCCOACOK','ELCPELL','BGRASS','INDNEUMSC','INDMAINSHYG','INDBOM','INDBOG-AD','TRAHYG','TRADST' >> MainBatchUpload.sql
echo ,'BENZ','INDCOA','SERBUILDBOM','ELCHYDDAM','ELCWNDOFS','TRALNGDS','ELCLFO','ELCWAV','HYGLNGA','TRACPHB','BOM','INDWODWST' >> MainBatchUpload.sql
echo ,'SERMSWBIO','SERPELH','INDBIOOIL','RHEATPIPE-EA','TRAPET','TRABIODSTS','TRALFODSL','BOG-LF','RESWODL','INDKER','TRACOA','ELCHFO' >> MainBatchUpload.sql
echo ,'INDNEULFO','ETH','INDBIOLPG','INDNEUNGA','TRANGA','AGRNGA','HYGSELC','BRSEED','AGRPOLWST','INDNGA','TRACNGL','ELCMSWINO' >> MainBatchUpload.sql
echo ,'TRALNGIS','TRABIODSTL','SERNGA','TRAELC','BSLURRY','TRABOM','ELCWNDONS','TRABIOJET-FTDA','TRAHFOIS','BSEWSLG','SERMSWORG','TRAHFOISL' >> MainBatchUpload.sql
echo ,'COA','NGA-E-IRE','AGRHFO','ELC-E-IRE','RESBOM','INDBENZ','RESELC','RESELCSURPLUS','AGRHYG','COA-E','GEO','IISBFGB' >> MainBatchUpload.sql
echo ,'ELCLPG','SERGEO','BOG-G','TRABIODST','TRABIOOILIS','IISCOKE','INDHYG','TRADSTL','BFG','INDLPG','OILMSC','OILPET' >> MainBatchUpload.sql
echo ,'PRCHFO','ELCBOG-AD','ELCBIOOIL','INDNEULPG','RESHYGREF-EA','BSTWWST','RESHOUSEHYG','IISBFGC','BSTARCH','NGA-E-EU','OILJET','HYDDAM' >> MainBatchUpload.sql
echo ,'TRAETH','UPSLFO','INDMSWINO','SERBIOLFO','IISNGAB','ELC-E-EU','BWODLOG','TRAJETDAEL','IISCOKS','TRAMETH','SERMAINSBOM','ELCPOLWST' >> MainBatchUpload.sql
echo ,'PWASTEDUM','NGA-I-N','SERMAINSHYG','BPELL','TRAJETL','TRAPETS','INDPELH','INDPOLWST','WAV','HYGELC','RESCOK','ELCSOL' >> MainBatchUpload.sql
echo ,'ELCBFG','RESNGA','TRABIODST-FT','RESMAINSHYG','INDWOD','INDSYNOIL','TRAHFO','INDBFG','ELCBOG-SW','SERLFO','TRAPETL','ELCHYGIGCC' >> MainBatchUpload.sql
echo ,'ELCMAINSBOM','TRAJETDA','TRABIOLFODSL','TRABIOLFOL','RESKER','INDSYNCOA','TRALNG','ELCBOG-LF','TRAETHL','ELCTRANSBOM','IISHFOB','ELCGEO' >> MainBatchUpload.sql
echo ,'ELCSURPLUS','BIODST','ELCNGA','INDHFO','BIOLFO','ELC-I-EU','LNG','INDBOG-LF','TRABIOJET-FTIAL','OILHFO','TRABIOJET-FTDAL','SERCOA' >> MainBatchUpload.sql
echo ,'TRALPGL','SERSOL','HYGBPEL','BSUGAR','TRAETHS','HYGCOA','NGA-E','TRADSTS','OILLFO','TRALPG','TRABIODST-FTL','TRALNGDSL' >> MainBatchUpload.sql
echo ,'IISNGAC','ELCTID','INDCOG','RHEATPIPE-NA','SERHFO','SERDISTELC','SERMSWINO','BWOD','INMSTM','BPELH','SERBUILDELC','TRABIOJET-FTIA' >> MainBatchUpload.sql
echo ,'TRACNGS','ELCGEN','HYGLHPT','RESBIOLFO','AGRCOA','INDDISTELC','HYGLELC','BTREATSTW','BWODWST','IISCOKB','SYNCOA','UPSMAINSHYG' >> MainBatchUpload.sql
echo ,'ICHOTH','TRAMAINSBOM','RESLPG','TRACELC','TID','INDMAINSBOM','TRAHFODS','RESSOL','TRAHYGDCN','TRALFOL','PRCELC','ELCPELH' >> MainBatchUpload.sql
echo ,'WNDONS','OILCRDRAW-E','ELCBIOLFO','ELCHYG','OILDST','PRCNGA','OILKER','AGRBIOLPG','SOL','ICHSTM','RESCOA','INDELC' >> MainBatchUpload.sql
echo ,'OILCRD','SERLPG','ELCBIOCOA2','HYGMSWORG','ELCCOA','URN','RHCSV-RHEA','INDMSWORG','TRAHYL','BIOOIL','ELCMSC','SERHYG' >> MainBatchUpload.sql
echo ,'UPSELC','RESPELH','TRABIOLFO','RESLFO','INDBIOLFO','SERKER','INDLFO','IFDSTM','RESMSWINO','RESMSWORG') >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where proc_set is not null group by tablename, period order by tablename,period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo ,rsr_export as( >> MainBatchUpload.sql
echo select sum(case when proc_set='EXPORT BIOMASS' then pv else 0 end) "EXPORT BIOMASS" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT COAL' then pv else 0 end) "EXPORT COAL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT COKE' then pv else 0 end) "EXPORT COKE" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT ELC' then pv else 0 end) "EXPORT ELC" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT ETH' then pv else 0 end) "EXPORT ETH" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT NGA' then pv else 0 end) "EXPORT NGA" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT OIL' then pv else 0 end) "EXPORT OIL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT DST' then pv else 0 end) "EXPORT DST" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT HFO' then pv else 0 end) "EXPORT HFO" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT JET' then pv else 0 end) "EXPORT JET" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT KER' then pv else 0 end) "EXPORT KER" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT LFO' then pv else 0 end) "EXPORT LFO" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT LPG' then pv else 0 end) "EXPORT LPG" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT MOIL' then pv else 0 end) "EXPORT MOIL" >> MainBatchUpload.sql
echo ,sum(case when proc_set='EXPORT GSL' then pv else 0 end) "EXPORT GSL" >> MainBatchUpload.sql
echo ,tablename,period >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select tablename,period, pv, >> MainBatchUpload.sql
echo case >> MainBatchUpload.sql
echo when process in('EXPCOA','EXPCOA-E') then 'EXPORT COAL' >> MainBatchUpload.sql
echo when process in('EXPCOK') then 'EXPORT COKE' >> MainBatchUpload.sql
echo when process in('EXPELC-EU','EXPELC-IRE') then 'EXPORT ELC' >> MainBatchUpload.sql
echo when process in('EXPETH') then 'EXPORT ETH' >> MainBatchUpload.sql
echo when process in('EXPNGA-E','EXPNGA-EU','EXPNGA-IRE') then 'EXPORT NGA' >> MainBatchUpload.sql
echo when process in('EXPOILCRD1','EXPOILCRD1-E','EXPOILCRD2') then 'EXPORT OIL' >> MainBatchUpload.sql
echo when process in('EXPOILDST') then 'EXPORT DST' >> MainBatchUpload.sql
echo when process in('EXPOILHFO') then 'EXPORT HFO' >> MainBatchUpload.sql
echo when process in('EXPOILJET') then 'EXPORT JET' >> MainBatchUpload.sql
echo when process in('EXPOILKER') then 'EXPORT KER' >> MainBatchUpload.sql
echo when process in('EXPOILLFO') then 'EXPORT LFO' >> MainBatchUpload.sql
echo when process in('EXPOILLPG') then 'EXPORT LPG' >> MainBatchUpload.sql
echo when process in('EXPOILMSC') then 'EXPORT MOIL' >> MainBatchUpload.sql
echo when process in('EXPOILPET') then 'EXPORT GSL' >> MainBatchUpload.sql
echo end as proc_set >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FIn' >> MainBatchUpload.sql
echo and commodity in('SYNCOA','RESLPG','TRAMAINSBOM','BPELH','SERBUILDELC','ELCGEN','HYGLHPT','INFOTH','INMHTH','RHUFLOOR-HC','INDCOG','SHLDELVRAD' >> MainBatchUpload.sql
echo ,'SERHFO','RHEATPIPE-HS','SERMSWINO','BWOD','OILLFO','RHUFLOOR-FS','SHHDELVRAD','SWHDELVSTD','INDMAINSGAS','IISELCC','TRALNGDSL','ICHPRO' >> MainBatchUpload.sql
echo ,'TRALPGL','BSUGAR','IPPLTHD2','TRAETHS','TRAMAINSGAS','RESHYGREF-FS','RHUFLOOR-HS','RWSTAND-EA','ELCSURPLUS','RESLTHSURPLUS-FS','INDHFO','RESELC-NS-HC' >> MainBatchUpload.sql
echo ,'BIOLFO','ELC-I-EU','LNG','SCHCSVDMD','RHUFLOOR-FC','IPPLTHP','TRALNG','ELCBOG-LF','TRAETHL','ELCTRANSBOM','ELCGEO','TRAHFO' >> MainBatchUpload.sql
echo ,'RESELC-NS-EA','SERLFO','TRAPETL','IFDOTH','ELCMAINSBOM','RHCSV-RHHS','TRAJETDA','RWSTAND-HC','TRABIOLFODSL','INDPELH','WAV','ELCSOL' >> MainBatchUpload.sql
echo ,'IOIOTH','IOIREF','TRABIODST-FT','INDWOD','INMOTH','PWASTEDUM','ICHHTH','NGA-I-N','RESHYGREF-FC','TRAPETS','HYDDAM','NGA-E-EU' >> MainBatchUpload.sql
echo ,'UPSLFO','INDMSWINO','SHLCSVDMD','IISNGAB','IOIMOT','SLOFCSV','TRAJETDAEL','IISCOKS','BFG','INDLPG','PRCHFO','ELCBOG-AD' >> MainBatchUpload.sql
echo ,'ELCBIOOIL','INDNEULPG','RESHYGREF-EA','BSTWWST','IISBFGC','BSTARCH','ELCLPG','IPPELCO','TRABIODST','IISCOKE','ICHREF','IISLTHS' >> MainBatchUpload.sql
echo ,'AGRHYG','IISBFGB','SERMSWORG','IPPLTHD4','NGA-E-IRE','RHSTAND-HC','URN045','RHCSV-RHFC','RESBOM','IOILTH','IPPLTHD','INDBENZ' >> MainBatchUpload.sql
echo ,'IPPLTHD3','SERBUILDGAS','RESHYGREF-HC','SERNGA','TRAELC','BSLURRY','ELCWNDONS','IOIHTH','TRAHFOIS','ETH','INDNEUNGA','TRANGA' >> MainBatchUpload.sql
echo ,'BRSEED','INDNGA','TRALNGIS','IISLTHE','SHLCSV','TRAPET','TRABIODSTS','TRALFODSL','BOG-LF','IPPLTHD5','RESWODL','INDKER' >> MainBatchUpload.sql
echo ,'INFMOT','RWCSV-RWHS','ELCHFO','ELCLFO','IISLTH','TRALNGDS','IFDMOT','IISELCE','IISELCB','INDWODWST','IPPELCD','SERMSWBIO' >> MainBatchUpload.sql
echo ,'INDBIOOIL','IPPELCD4','ELCMAINSGAS','INDBOG-AD','INDCOA','ELCBIOCOA','PREFGAS','AGRLFO','RESHOUSEELC','RESLTHSURPLUS-HS','RESMAINSBOM','MSWBIO' >> MainBatchUpload.sql
echo ,'ELCPELL','COK','RESHOUSEBOM','ELC','IISCOGB','IISCOGC','INDCOACOK','TRAJETIAEL','UPSHEAT','AGRMAINSBOM','ELCBOM','COG' >> MainBatchUpload.sql
echo ,'ELCTRANSGAS','INMDRY','TRAHFODSL','AGRGRASS','TRALFO','OILLPG','PCHPHEAT','WNDOFF','INDGRASS','HYGL-IGCC','BVOIL','RESELC-NS-HS' >> MainBatchUpload.sql
echo ,'RESLTH-FC','ELCSTWWST','INDSTM','MSWORG','RHSTAND-FS','TRAJETIA','UPSNGA','WAT','SERELC','ELCCOG','RESLTHSURPLUS-EA','AGRDISTELC' >> MainBatchUpload.sql
echo ,'TRADISTELC','RESLFO','RWCSV-RWFC','TRABIOLFO','IPPELCD5','TRAJETIANL','INDBIOLFO','AGRELC','SERBOG','URND','SERKER','HYDROR' >> MainBatchUpload.sql
echo ,'IFDSTM','INDLFO','IPPLTHO1','RESLTH-EA','SHLDELVUND','TRABIOOILISL','NGAPTR','RHUFLOOR-EA','TRABIOLFODS','BIOOIL','ELCMSC','SERHYG' >> MainBatchUpload.sql
echo ,'SWHDELVPIP','AGRMAINSGAS','METH','UPSELC','BIODST-FT','IPPLTHD1','RESHYGREF-HS','RESPELH','RHEATPIPE-FS','TRALNGISL','ELCCOA','INDCOK' >> MainBatchUpload.sql
echo ,'URN','RHCSV-RHEA','ICHLTH','INDMSWORG','RWSTAND-FS','ICHSTM','IISNGAE','SWLDELVSTD','RESCOA','SERWOD','INDELC','OILCRD' >> MainBatchUpload.sql
echo ,'RHSTAND-EA','SERLPG','SHHCSVDMD','ELCMSWORG','ELCWSTHEAT','SOL','HYGLHPD','SERELC-NS','PRCOILCRD','IPPELCD1','PRCCOA','RHCSV-RHFS' >> MainBatchUpload.sql
echo ,'AGRBIODST','IISLTHB','RWCSV-RWFS','BOG-AD','OILKER','PRCNGA','SERBOM','TRALFODS','BIOJET-FT','URN19','NGA-I-EU','OILCRDRAW' >> MainBatchUpload.sql
echo ,'SYNOIL','IOISTM','AGRBIOLPG','IISCOACOKB','RESHYG','ELCPELH','IPPELCD3','MSWINO','WNDONS','OILCRDRAW-E','SHHCSV','AGRLPG' >> MainBatchUpload.sql
echo ,'HYLTK','AGRBOM','ELCBIOLFO','ELCHYG','ICHDRY','URN09','HYL','ISO','OILDST','INDMAINSBOM','INMLTH','RESLTHSURPLUS-FC' >> MainBatchUpload.sql
echo ,'TRAHFODS','RESSOL','INDPELL','RESELC-NS-FS','RESLTH-HC','BIOLPG','ELCMAN','TRALFOL','PRCELC','BWODWST','IISCOKB','ICHOTH' >> MainBatchUpload.sql
echo ,'RWSTAND-HS','TID','ICHMOT','RESHOUSEGAS','TRABIOJET-FTIA','RESBIOLFO','AGRCOA','INDDISTELC','IISNGAC','RWCSV-RWEA','IFDREF','RHEATPIPE-FC' >> MainBatchUpload.sql
echo ,'SERDISTELC','INMSTM','RESLTH-HS','IISELCS','IISLTHC','RESELC-NS-FC','TRADSTS','SERLTH','TRALPG','ELCURN','OILHFO','TRABIOJET-FTIAL' >> MainBatchUpload.sql
echo ,'RHSTAND-HS','TRABIOJET-FTDAL','SERCOA','SERSOL','NGA-E','RESLTH-FS','BIODST','ELCNGA','IPPELCD2','IPPELCP','INDBOG-LF','IISTGS' >> MainBatchUpload.sql
echo ,'RESKER','INDSYNCOA','RWSTAND-FC','IISHFOB','INDBFG','INDSYNOIL','ELCBOG-SW','URNU','IPPLTHO','TRABIOLFOL','IPPLTH','INDPOLWST' >> MainBatchUpload.sql
echo ,'SHHDELVAIR','RESCOK','ELCBFG','RESNGA','SERHYGREF','INMMOT','TRAMETH','INFHTH','SERMAINSBOM','ELCPOLWST','SERLTHSURPLUS','BPELL' >> MainBatchUpload.sql
echo ,'TRAJETL','OILJET','TRAETH','SERBIOLFO','ELC-E-EU','BWODLOG','RHCSV-RHHC','TRADSTL','OILMSC','OILPET','SERMAINSGAS','RHSTAND-FC' >> MainBatchUpload.sql
echo ,'SERGEO','BOG-G','IOIDRY','SHLDELVAIR','TRABIOOILIS','INDHYG','RESELCSURPLUS','COA-E','GEO','BSEWSLG','TRAHFOISL','AGRHFO' >> MainBatchUpload.sql
echo ,'COA','ELC-E-IRE','IFDDRY','RESELC','RWCSV-RWHC','TRABIODSTL','TRABOM','TRABIOJET-FTDA','INDBIOLPG','AGRNGA','AGRPOLWST','ELCMSWINO' >> MainBatchUpload.sql
echo ,'IPPELCO1','RESMAINSGAS','RHEATPIPE-HC','RESLTHSURPLUS-HC','INDNEULFO','TRACOA','ELCHYDDAM','ELCWNDOFS','BOM','SERPELH','RHEATPIPE-EA','BGRASS' >> MainBatchUpload.sql
echo ,'INDNEUMSC','INDBOM','BENZ','TRADST','SERBUILDBOM','ELC-I-IRE','NGA','RESDISTELC','SCHDELVAIR','BIOKER-FT','TRALPGS','COACOK' >> MainBatchUpload.sql
echo ,'IFDLTH','PRCCOACOK','RESWOD','RESMSWINO','RESMSWORG') >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo where proc_set is not null group by tablename, period order by tablename,period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo ,nuclear as( >> MainBatchUpload.sql
echo select sum(pv)/0.398 "ELC FROM NUCLEAR", >> MainBatchUpload.sql
echo tablename,period >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FOut' >> MainBatchUpload.sql
echo and commodity in('ELCDUMMY','ELC','ELC-E-IRE','ELC-E-EU','ELCGEN') >> MainBatchUpload.sql
echo and process in('ENUCPWR101','ENUCPWR102','ENUCPWR00') >> MainBatchUpload.sql
echo group by tablename,period order by tablename,period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo ,domestic_bio as ( >> MainBatchUpload.sql
echo select a.tablename, a.period,sum(a.bio+case when b.bio^>0 then b.bio else 0 end) "DOMESTIC BIO PROD" >> MainBatchUpload.sql
echo from ( >> MainBatchUpload.sql
echo select distinct tablename, period, 0::numeric "bio" from vedastore >> MainBatchUpload.sql
echo where period in('2010','2011','2012','2015','2020','2025','2030','2035','2040','2045','2050','2055','2060') >> MainBatchUpload.sql
echo ) a left join ( >> MainBatchUpload.sql
echo select sum(pv) "bio",tablename,period >> MainBatchUpload.sql
echo from vedastore >> MainBatchUpload.sql
echo where attribute='VAR_FOut' and commodity in('BWODWST','BWOD') >> MainBatchUpload.sql
echo and process in('ALUFOR02','ALUFOR03','ALUFOR04A') >> MainBatchUpload.sql
echo group by tablename,period >> MainBatchUpload.sql
echo order by tablename,period >> MainBatchUpload.sql
echo ) b on a.tablename=b.tablename and a.period=b.period >> MainBatchUpload.sql
echo group by a.tablename,a.period >> MainBatchUpload.sql
echo order by a.tablename,a.period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo ,end_demand as( >> MainBatchUpload.sql
echo select >> MainBatchUpload.sql
echo sum("MINING BIOMASS")+sum("DOMESTIC BIO PROD")+sum("IMPORT BIOMASS")+sum("IMPORT BDL")+sum("IMPORT BIOOIL") >> MainBatchUpload.sql
echo +sum("IMPORT ETHANOL")+sum("IMPORT FTD")+sum("IMPORT FTK-AVI")-SUM("EXPORT ETH")-sum("EXPORT BIOMASS") "bio" >> MainBatchUpload.sql
echo ,sum("MINING COAL")+sum("IMPORT COAL")-sum("EXPORT COAL")+sum("IMPORT COKE")-sum("EXPORT COKE") "coa" >> MainBatchUpload.sql
echo ,sum("IMPORT ELC")-sum("EXPORT ELC") "elec" >> MainBatchUpload.sql
echo ,sum("MINING NGA")+sum("IMPORT NGA")+sum("MINING NGA-SHALE")-sum("EXPORT NGA") "gas" >> MainBatchUpload.sql
echo ,sum("IMPORT HYL") "h2" >> MainBatchUpload.sql
echo ,sum("MINING OIL")+sum("IMPORT OIL")-sum("EXPORT OIL")+sum("IMPORT DST")+sum("IMPORT GSL")+sum("IMPORT HFO")+sum("IMPORT JET")+ >> MainBatchUpload.sql
echo sum("IMPORT KER")+sum("IMPORT LFO")+sum("IMPORT LPG")+sum("IMPORT MOIL")-sum("EXPORT DST")-sum("EXPORT GSL") >> MainBatchUpload.sql
echo -sum("EXPORT HFO")-sum("EXPORT JET")-sum("EXPORT KER")-sum("EXPORT LFO")-sum("EXPORT LPG")-sum("EXPORT MOIL") "oil" >> MainBatchUpload.sql
echo ,sum("MINING HYDRO")+sum("MINING WIND")+sum("MINING SOLAR")+sum("MINING GEOTHERMAL")+sum("MINING TIDAL")+sum("MINING WAVE") "rens" >> MainBatchUpload.sql
echo ,sum(d."ELC FROM NUCLEAR") "nuc" >> MainBatchUpload.sql
echo ,sum("MINING INORGANIC WASTE") "was" >> MainBatchUpload.sql
echo ,a.period,a.tablename >> MainBatchUpload.sql
echo from rsr_min a join rsr_imports b >> MainBatchUpload.sql
echo on a.period=b.period and a.tablename=b.tablename left join rsr_export c >> MainBatchUpload.sql
echo on a.period=c.period and a.tablename=c.tablename left join nuclear d >> MainBatchUpload.sql
echo on a.period=d.period and a.tablename=d.tablename left join domestic_bio e >> MainBatchUpload.sql
echo on a.period=e.period and a.tablename=e.tablename >> MainBatchUpload.sql
echo group by a.tablename,a.period order by a.period >> MainBatchUpload.sql
echo ) >> MainBatchUpload.sql
echo select 'pri-en_' ^|^| cols ^|^| '^|' ^|^| tablename ^|^| '^|various^|various^|various'::varchar "id", >> MainBatchUpload.sql
echo 'pri-en_'^|^| cols::varchar "analysis", >> MainBatchUpload.sql
echo tablename, >> MainBatchUpload.sql
echo 'various'::varchar "attribute", >> MainBatchUpload.sql
echo 'various'::varchar "commodity", >> MainBatchUpload.sql
echo 'various'::varchar "process", >> MainBatchUpload.sql
echo sum(vals) "all", >> MainBatchUpload.sql
echo sum(case when a.period='2010' then vals else 0 end) as "2010", >> MainBatchUpload.sql
echo sum(case when a.period='2011' then vals else 0 end) as "2011", >> MainBatchUpload.sql
echo sum(case when a.period='2012' then vals else 0 end) as "2012", >> MainBatchUpload.sql
echo sum(case when a.period='2015' then vals else 0 end) as "2015", >> MainBatchUpload.sql
echo sum(case when a.period='2020' then vals else 0 end) as "2020", >> MainBatchUpload.sql
echo sum(case when a.period='2025' then vals else 0 end) as "2025", >> MainBatchUpload.sql
echo sum(case when a.period='2030' then vals else 0 end) as "2030", >> MainBatchUpload.sql
echo sum(case when a.period='2035' then vals else 0 end) as "2035", >> MainBatchUpload.sql
echo sum(case when a.period='2040' then vals else 0 end) as "2040", >> MainBatchUpload.sql
echo sum(case when a.period='2045' then vals else 0 end) as "2045", >> MainBatchUpload.sql
echo sum(case when a.period='2050' then vals else 0 end) as "2050", >> MainBatchUpload.sql
echo sum(case when a.period='2055' then vals else 0 end) as "2055", >> MainBatchUpload.sql
echo sum(case when a.period='2060' then vals else 0 end) as "2060" >> MainBatchUpload.sql
echo from >> MainBatchUpload.sql
echo ( >> MainBatchUpload.sql
echo SELECT unnest(array['bio','coa','elc','gas','hyd','oil','orens','nuc','was']) as "cols", >> MainBatchUpload.sql
echo tablename,period, >> MainBatchUpload.sql
echo unnest(array[bio,coa,elec,gas,h2,oil,rens,nuc,was]) AS "vals" >> MainBatchUpload.sql
echo FROM end_demand >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo group by tablename,cols >> MainBatchUpload.sql
echo UNION ALL >> MainBatchUpload.sql
echo select 'bio-en_' ^|^| cols ^|^| '^|' ^|^| tablename ^|^| '^|VAR_FOut^|various^|' ^|^| process::varchar "id", >> MainBatchUpload.sql
echo 'bio-en_'^|^| cols::varchar "analysis", >> MainBatchUpload.sql
echo tablename, >> MainBatchUpload.sql
echo 'VAR_FOut'::varchar "attribute", >> MainBatchUpload.sql
echo 'various'::varchar "commodity", >> MainBatchUpload.sql
echo process, >> MainBatchUpload.sql
echo sum(vals) "all", >> MainBatchUpload.sql
echo sum(case when a.period='2010' then vals else 0 end) as "2010", >> MainBatchUpload.sql
echo sum(case when a.period='2011' then vals else 0 end) as "2011", >> MainBatchUpload.sql
echo sum(case when a.period='2012' then vals else 0 end) as "2012", >> MainBatchUpload.sql
echo sum(case when a.period='2015' then vals else 0 end) as "2015", >> MainBatchUpload.sql
echo sum(case when a.period='2020' then vals else 0 end) as "2020", >> MainBatchUpload.sql
echo sum(case when a.period='2025' then vals else 0 end) as "2025", >> MainBatchUpload.sql
echo sum(case when a.period='2030' then vals else 0 end) as "2030", >> MainBatchUpload.sql
echo sum(case when a.period='2035' then vals else 0 end) as "2035", >> MainBatchUpload.sql
echo sum(case when a.period='2040' then vals else 0 end) as "2040", >> MainBatchUpload.sql
echo sum(case when a.period='2045' then vals else 0 end) as "2045", >> MainBatchUpload.sql
echo sum(case when a.period='2050' then vals else 0 end) as "2050", >> MainBatchUpload.sql
echo sum(case when a.period='2055' then vals else 0 end) as "2055", >> MainBatchUpload.sql
echo sum(case when a.period='2060' then vals else 0 end) as "2060" >> MainBatchUpload.sql
echo from >> MainBatchUpload.sql
echo ( >> MainBatchUpload.sql
echo select 'dom-prod' "cols", 'various' "process", "MINING BIOMASS"+"DOMESTIC BIO PROD" "vals", a.period, a.tablename from rsr_min a >> MainBatchUpload.sql
echo join domestic_bio b on a.tablename=b.tablename and a.period=b.period >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select 'imports' "cols", 'various' "process", >> MainBatchUpload.sql
echo "IMPORT BDL"+"IMPORT BIOOIL"+"IMPORT ETHANOL"+"IMPORT FTD"+"IMPORT FTK-AVI"+"IMPORT BIOMASS" "vals", period, tablename from rsr_imports >> MainBatchUpload.sql
echo union all >> MainBatchUpload.sql
echo select 'exports' "cols", 'various' "process", >> MainBatchUpload.sql
echo "EXPORT BIOMASS"+"EXPORT ETH" "vals", period, tablename from rsr_export >> MainBatchUpload.sql
echo ) a >> MainBatchUpload.sql
echo group by tablename,cols,process >> MainBatchUpload.sql
echo ORDER BY tablename,analysis >> MainBatchUpload.sql
echo ) TO '%~dp0PriEnOut.csv' delimiter ',' CSV; >> MainBatchUpload.sql
rem following line actually runs the SQL code generated by the above using the postgres command utility "psql".
echo running sql code and generating cross tabs
rem Comment this line out if you just want the SQL code to create the populated temp tables + the associated analysis queries:
"C:\Program Files\PostgreSQL\9.4\bin\psql.exe" -h localhost -p 5432 -U postgres -d postgres -f %~dp0MainBatchUpload.sql
rem following concatenates individual results to the GHGout.csv
type GHGOut.csv >> dummiesout.csv
type GHGsectorOut.csv >> dummiesout.csv
type IndSubGHG.csv >> dummiesout.csv
type ElecGenOut.csv >> dummiesout.csv
type ElecStor.csv >> dummiesout.csv
type ElecCap.csv >> dummiesout.csv
type CostsBySec.csv >> dummiesout.csv
type MarginalPricesOut.csv >> dummiesout.csv
type ResWholeHeatOut.csv >> dummiesout.csv
type NewResHeatOut.csv >> dummiesout.csv
type ServWholeHeatOut.csv >> dummiesout.csv
type NewServHeatOut.csv >> dummiesout.csv
type FinEnOut.csv >> dummiesout.csv
type PriEnOut.csv >> dummiesout.csv
rem before deleting the individual files and renaming dummiesout as ResultsOut
IF EXIST ResultsOut.csv del /F ResultsOut.csv
IF EXIST GHGOut.csv del /F GHGOut.csv
IF EXIST GHGsectorOut.csv del /F GHGsectorOut.csv
IF EXIST IndSubGHG.csv del /F IndSubGHG.csv
IF EXIST ElecGenOut.csv del /F ElecGenOut.csv
IF EXIST ElecStor.csv del /F ElecStor.csv
IF EXIST ElecCap.csv del /F ElecCap.csv
IF EXIST CostsBySec.csv del /F CostsBySec.csv
IF EXIST MarginalPricesOut.csv del /F MarginalPricesOut.csv
IF EXIST ResWholeHeatOut.csv del /F ResWholeHeatOut.csv
IF EXIST NewResHeatOut.csv del /F NewResHeatOut.csv
IF EXIST ServWholeHeatOut.csv del /F ServWholeHeatOut.csv
IF EXIST NewServHeatOut.csv del /F NewServHeatOut.csv
IF EXIST FinEnOut.csv del /F FinEnOut.csv
IF EXIST PriEnOut.csv del /F PriEnOut.csv
rename dummiesout.csv ResultsOut.csv
rem finally, delete dummiesout.csv if it exists
IF EXIST dummiesout.csv del /F dummiesout.csv