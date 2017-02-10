@echo off
rem *****Ad Hoc Agriculture / LULUCF batch queries*****
rem DOS Batch file to construct SQL queries, run the code, amalgamate the results and tidy up (delete) the intermediate stages
rem this version is for more in-depth analysis of Agriculture / LULUC-related metrics than the "standard" query
rem version as filename. By Fernley Symons 3:53 PM 05 July, 2016
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
rem    "^--.+\r\n" (no quotes) replace with blank. Remove embedded comments [appearing on same line as code] with regex replace "--.+" with blank
rem    remove extraneous blank lines with regex replace "(\r\n){2,}" with "\r\n"
rem 4) Change the single "%" to double "%%" but leave filenames for copy statements unchanged. Regex replace "(%[^~])" with "%\1"
rem 5) Escape other characters: Regex replace "(\||<|>)" with "^\1"
rem 6) Make replacements for other reserved DOS words. See below for example (set "texta..." etc). In general there will only be a few of these; define more as needed
REM    NB No need to replace "~" in output file locations since these are DOS commands meaning "put it in the same folder as this BAT file". "~" only needs replacing if part of a query
REM    (i.e. regex in postgres)
rem 7) Regex replace "(.+)" with "echo \1 >> AgBatchUpload.sql"
rem 8) Regex replace "echo (\/\*.+\/)" with "rem \1\r\necho \1". This duplicates the header in a way which is more obvious to read in the BAT file
rem 9) Copy the edited text back over the body of the BAT below (below the upload statements and before the run SQL statement) and save file
rem 10) comment out the run SQL statement, run the BAT and check the SQL appears sensible.
rem 11) Uncomment the run SQL statement and use the file
rem ***********
rem 3:53 PM 05 July, 2016: First version: MACC measures for agriculture / LULUCF; and afforestation rate over and above BAU
REM 8:36 PM 06 September, 2016: changed to add postgres ver as a variable near top of script for ease of change
REM 6:54 PM 12 December, 2016: FS Changed to add update instructions: body of script has changed in line with "Human Readable Queries"
REM 4:13 PM 06 February, 2017: FS addition of landfill mitigation measures, change to reflect new forestry and emissions
rem ***********
echo processing vd files...
@echo off
rem The following allows us to insert text which is otherwise outlawed in DOS:
setlocal enableDelayedExpansion
rem IMPORTANT: change the following if yours is a different postgres version: (this is used at the end of the script to locate the psql program to run the SQL)
set postgresver=9.4
rem Things to bear in mind:
rem if '%' is part of a sql query (e.g. "like 'x%'), then % needs to be doubled "like 'x%%'"
rem Other characters (|, <, > etc) need to be escaped in a similar way with ^:- ^| etc
rem can't have very long lines - need to break statements
rem filename at end of line, no spaces afterwards
rem delete the SQL script if it exists - code below (re-) generates it.
IF EXIST AgBatchUpload.sql del /F AgBatchUpload.sql
rem need to define some variables which contain DOS reserved words. These are replaced by the preprocessor in the script:
set "texta=IF"
set "textb=IF NOT"
set "textc=~"
set "textd=^"
rem this block creates the 2 temp table definitions. First stores the unformatted data from the VD file, second parses this into fields and inserts into the "vedastore" table against which the 
rem queries are run.
rem NB in the below uses the same temp table names as the main BAT script (vedastore etc). This doesn't matter as this BAT is a separate process (=separate connection) on the database
rem and so will not interfere with the main Q BAT. Note, however, that the names of the SQL file and CSVs generated need to be different so as not to collide with the main Q files
echo CREATE temp TABLE !textb! EXISTS vedastore( tablename varchar(100), id serial, attribute varchar(50), commodity varchar(50), process varchar(50), period varchar(50), region varchar(50), vintage varchar(50), timeslice varchar(50), userconstraint varchar(50), pv numeric ); drop table !texta! exists veda; create temp table veda( id serial, stuff varchar(1000) ); >> AgBatchUpload.sql
rem the following creates a block of sql for each VD file to upload it, delete the header rows and break the entries into fields
for /f "delims=|" %%i in ('dir /b *.vd') do echo delete from veda; ALTER SEQUENCE veda_id_seq RESTART WITH 1; copy veda (stuff) from '%%~fi'; insert into vedastore (tablename, attribute ,commodity ,process ,period ,region ,vintage ,timeslice ,userconstraint ,pv) select '%%~ni', trim(both '"' from a[1]), trim(both '"' from a[2]), trim(both '"' from a[3]), trim(both '"' from a[4]), trim(both '"' from a[5]), trim(both '"' from a[6]), trim(both '"' from a[7]), trim(both '"' from a[8]), cast(a[9] as numeric) from ( select string_to_array(stuff, ',') from veda order by id offset 13 ) as dt(a); >> AgBatchUpload.sql
rem first cross-tabs sql is here:
rem /* *Landfill CH4 emission mitigation and residual emissions* */
echo /* *Landfill CH4 emission mitigation and residual emissions* */  >> AgBatchUpload.sql
echo COPY (   >> AgBatchUpload.sql
echo select 'landfill-ghg_'^|^| proc_set ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| commodity ^|^| '^|various'::varchar(300) "id",  >> AgBatchUpload.sql
echo 'landfill-ghg_' ^|^| proc_set "analysis", tablename, attribute,  >> AgBatchUpload.sql
echo commodity,'various'::varchar "process",  >> AgBatchUpload.sql
echo sum(pv) "all",  >> AgBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010",  >> AgBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011",  >> AgBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012",  >> AgBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015",  >> AgBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020",  >> AgBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025",  >> AgBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030",  >> AgBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035",  >> AgBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040",  >> AgBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045",  >> AgBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050",  >> AgBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055",  >> AgBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060"  >> AgBatchUpload.sql
echo from (  >> AgBatchUpload.sql
echo select tablename, attribute, period,pv,  >> AgBatchUpload.sql
echo case  >> AgBatchUpload.sql
echo when process='PWLFWM00' and commodity='PRCN2OP' then 'landfill-unab-N2O'   >> AgBatchUpload.sql
echo when process='PWLFWM00' and commodity='PRCCH4P' then 'landfill-unab-CH4'   >> AgBatchUpload.sql
echo when process in ('PWLFWMM01','PWLFWMM02','PWLFWMM03','PWLFWMM04') then 'landfill-mit-CH4'   >> AgBatchUpload.sql
echo end as proc_set  >> AgBatchUpload.sql
echo ,commodity  >> AgBatchUpload.sql
echo from vedastore  >> AgBatchUpload.sql
echo where attribute in('VAR_FIn','VAR_FOut') and commodity in('PRCCH4P','PRCN2OP')   >> AgBatchUpload.sql
echo ) a  >> AgBatchUpload.sql
echo where proc_set is not null  >> AgBatchUpload.sql
echo group by tablename, attribute, proc_set, commodity  >> AgBatchUpload.sql
echo order by tablename, attribute, proc_set, commodity  >> AgBatchUpload.sql
echo ) TO '%~dp0landfillemiss.csv' delimiter ',' CSV;  >> AgBatchUpload.sql
rem /*  *Land use and crop / livestock mitigation (MACC) measures* */
echo /*  *Land use and crop / livestock mitigation (MACC) measures* */ >> AgBatchUpload.sql
echo COPY (  >> AgBatchUpload.sql
echo select 'ag-lulucf-meas-ghg_'^|^| proc_set ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| 'various' ^|^| '^|various'::varchar(300) "id", >> AgBatchUpload.sql
echo 'ag-lulucf-meas-ghg_' ^|^| proc_set "analysis", tablename, attribute, >> AgBatchUpload.sql
echo 'various'::varchar(50) "commodity",'various'::varchar "process", >> AgBatchUpload.sql
echo sum(pv) "all", >> AgBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> AgBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> AgBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> AgBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> AgBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> AgBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> AgBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> AgBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> AgBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> AgBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> AgBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> AgBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> AgBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> AgBatchUpload.sql
echo from ( >> AgBatchUpload.sql
echo select tablename, attribute, period,pv, >> AgBatchUpload.sql
echo case >> AgBatchUpload.sql
echo when process in ('ALUFOR01','ALUFOR02','ALUFOR03','ALUFOR04') then 'affor'   >> AgBatchUpload.sql
echo when process in ('AGCRP01','AGCRP02','AGCRP04','AGCRP05','AGCRP06','AGCRP07','AGCRP08','AGCRP09') then 'crops'  >> AgBatchUpload.sql
echo when process in ('AHTBLRC00','AHTBLRG00','AHTBLRG01','AHTBLRO00','AHTBLRO01','ATRA00','ATRA01','AATRA01') then 'agr-en'  >> AgBatchUpload.sql
echo when process in ('AGSOI01','AGSOI02','AGSOI03','AGSOI04') then 'soils'  >> AgBatchUpload.sql
echo when process in ('ALU00') then 'lulucf'  >> AgBatchUpload.sql
echo when process in ('AGLIV03','AGLIV04','AGLIV05','AGLIV06','AGLIV07','AGLIV09') then 'livestock'  >> AgBatchUpload.sql
echo when process in('AGRCUL00','MINBSLURRY1') then 'bau-livestock'  >> AgBatchUpload.sql
echo end as proc_set >> AgBatchUpload.sql
echo from vedastore >> AgBatchUpload.sql
echo where attribute='VAR_FOut' and commodity in ('GHG-LULUCF','GHG-AGR-NO-LULUCF')  >> AgBatchUpload.sql
echo ) a >> AgBatchUpload.sql
echo where proc_set is not null >> AgBatchUpload.sql
echo group by tablename, attribute, proc_set >> AgBatchUpload.sql
echo ) TO '%~dp0lulucfout.csv' delimiter ',' CSV HEADER; >> AgBatchUpload.sql
rem /* *Afforestation rate* */
echo /* *Afforestation rate* */ >> AgBatchUpload.sql
echo COPY (  >> AgBatchUpload.sql
echo select 'ag-lulucf-meas_aff_level' ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| commodity ^|^| '^|' ^|^| process::varchar(300) "id", >> AgBatchUpload.sql
echo 'ag-lulucf-meas_aff_level'::varchar(50) "analysis", >> AgBatchUpload.sql
echo tablename, attribute, >> AgBatchUpload.sql
echo commodity,process, >> AgBatchUpload.sql
echo sum(pv) "all", >> AgBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> AgBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> AgBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> AgBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> AgBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> AgBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> AgBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> AgBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> AgBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> AgBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> AgBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> AgBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> AgBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> AgBatchUpload.sql
echo from vedastore >> AgBatchUpload.sql
echo where attribute='VAR_FOut' and commodity='ALAND' and process in('ALUFOR01','ALUFOR02','ALUFOR03','ALUFOR04')  >> AgBatchUpload.sql
echo group by tablename, attribute,commodity,process >> AgBatchUpload.sql
echo ) TO '%~dp0afforestout.csv' delimiter ',' CSV; >> AgBatchUpload.sql
rem following line actually runs the SQL code generated by the above using the postgres command utility "psql".
rem Comment this line out if you just want the SQL code to create the populated temp tables + the associated analysis queries:
"C:\Program Files\PostgreSQL\%postgresver%\bin\psql.exe" -h localhost -p 5432 -U postgres -d gams -f %~dp0AgBatchUpload.sql
rem following concatenates individual results to the lulucfout.csv
type afforestout.csv >> lulucfout.csv
type landfillemiss.csv >> lulucfout.csv
rem before deleting the individual files and renaming lulucfout as AgResultsOut
IF EXIST AgResultsOut.csv del /F AgResultsOut.csv
IF EXIST afforestout.csv del /F afforestout.csv
IF EXIST landfillemiss.csv del /F landfillemiss.csv
rename lulucfout.csv AgResultsOut.csv
rem finally, delete lulucfout.csv if it exists
IF EXIST lulucfout.csv del /F lulucfout.csv
