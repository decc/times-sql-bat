rem *****Ad Hoc Agriculture / LULUCF batch queries*****
rem DOS Batch file to construct SQL queries, run the code, amalgamate the results and tidy up (delete) the intermediate stages
rem this version is for more in-depth analysis of Agriculture / LULUC-related metrics than the "standard" query
rem version as filename. By Fernley Symons 3:53 PM 05 July, 2016
rem works by: 
rem 1) constructing SQL code file to create temp files from TIMES runs (creates one script entry for each file)
rem 2) adding analysis SQL to generate summaries which are output to CSVs
rem 3) amalgamates the CSVs
rem 4) deletes the intermediate CSVs leaving a single output file
rem By Fernley Symons
rem ***********
rem 3:53 PM 05 July, 2016: First version: MACC measures for agriculture / LULUCF; and afforestation rate over and above BAU
rem ***********
rem The following allows us to insert text which is otherwise outlawed in DOS:
setlocal enableDelayedExpansion
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
rem first cross-tabs sql is here. This is the Ag / LULUCF MACC measures;
echo /* Land use and crop / livestock mitigation (MACC) measures */ COPY ( select 'ag-lulucf-meas-ghg_'^|^| proc_set ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| 'various' ^|^| '^|various'::varchar(300) "id", 'ag-lulucf-meas-ghg_' ^|^| proc_set "analysis", tablename, attribute, 'various'::varchar(50) "commodity",'various'::varchar "process", sum(pv) "all", sum(case when period='2010' then pv else 0 end)::numeric "2010", sum(case when period='2011' then pv else 0 end)::numeric "2011", sum(case when period='2012' then pv else 0 end)::numeric "2012", sum(case when period='2015' then pv else 0 end)::numeric "2015", sum(case when period='2020' then pv else 0 end)::numeric "2020", sum(case when period='2025' then pv else 0 end)::numeric "2025", sum(case when period='2030' then pv else 0 end)::numeric "2030", sum(case when period='2035' then pv else 0 end)::numeric "2035", sum(case when period='2040' then pv else 0 end)::numeric "2040", sum(case when period='2045' then pv else 0 end)::numeric "2045", sum(case when period='2050' then pv else 0 end)::numeric "2050", sum(case when period='2055' then pv else 0 end)::numeric "2055", sum(case when period='2060' then pv else 0 end)::numeric "2060" from ( select tablename, attribute, period,pv, case when process in ('ALUFOR01') then 'affor' when process in ('AGCRP01','AGCRP02','AGCRP03','AGCRP04','AGCRP05','AGCRP06','AGCRP07','AGCRP08','AGCRP09') then 'crops' when process in ('AHTBLRC00','AHTBLRG00','AHTBLRG01','AHTBLRO00','AHTBLRO01','ATRA00','ATRA01') then 'agr-en' when process in ('ALU00','ALU01','MINBSLURRY1') then 'lulucf' when process in ('AGLIV01','AGLIV02','AGLIV03','AGLIV04','AGLIV05','AGLIV06','AGLIV07','AGLIV08','AGLIV09','AGLIV10') then 'livestock' end as proc_set from vedastore where attribute='VAR_FOut' and commodity in ('GHG-LULUCF','GHG-AGR-NO-LULUCF') ) a where proc_set is not null group by tablename, attribute, proc_set ) TO '%~dp0lulucfout.csv' delimiter ',' CSV HEADER; >> AgBatchUpload.sql
rem afforestation over and above BAU rate
echo /* Afforestation rate */ COPY ( select 'ag-lulucf-meas_aff_level' ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| commodity ^|^| '^|' ^|^| process::varchar(300) "id", 'ag-lulucf-meas_aff_level'::varchar(50) "analysis", tablename, attribute, commodity,process, sum(pv) "all", sum(case when period='2010' then pv else 0 end)::numeric "2010", sum(case when period='2011' then pv else 0 end)::numeric "2011", sum(case when period='2012' then pv else 0 end)::numeric "2012", sum(case when period='2015' then pv else 0 end)::numeric "2015", sum(case when period='2020' then pv else 0 end)::numeric "2020", sum(case when period='2025' then pv else 0 end)::numeric "2025", sum(case when period='2030' then pv else 0 end)::numeric "2030", sum(case when period='2035' then pv else 0 end)::numeric "2035", sum(case when period='2040' then pv else 0 end)::numeric "2040", sum(case when period='2045' then pv else 0 end)::numeric "2045", sum(case when period='2050' then pv else 0 end)::numeric "2050", sum(case when period='2055' then pv else 0 end)::numeric "2055", sum(case when period='2060' then pv else 0 end)::numeric "2060" from vedastore where attribute='VAR_FOut' and commodity='ALAND' and process='ALUFOR01' group by tablename, attribute,commodity,process ) TO '%~dp0afforestout.csv' delimiter ',' CSV; >> AgBatchUpload.sql
rem following line actually runs the SQL code generated by the above using the postgres command utility "psql".
rem Comment this line out if you just want the SQL code to create the populated temp tables + the associated analysis queries:
"C:\Program Files\PostgreSQL\9.4\bin\psql.exe" -h localhost -p 5432 -U postgres -d gams -f %~dp0AgBatchUpload.sql
rem following concatenates individual results to the lulucfout.csv
type afforestout.csv >> lulucfout.csv
rem before deleting the individual files and renaming lulucfout as AgResultsOut
IF EXIST AgResultsOut.csv del /F AgResultsOut.csv
IF EXIST afforestout.csv del /F afforestout.csv
rename lulucfout.csv AgResultsOut.csv
rem finally, delete lulucfout.csv if it exists
IF EXIST lulucfout.csv del /F lulucfout.csv
