@echo off
rem *****Ad Hoc Electricity batch queries*****
rem DOS Batch file to construct SQL queries, run the code, amalgamate the results and tidy up (delete) the intermediate stages
rem this version is for more in-depth analysis of Agriculture / LULUC-related metrics than the "standard" query
rem version as filename. By Fernley Symons 8:37 PM 12 January, 2017
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
rem 9) Regex replace "(.+)" with "echo \1 >> ElcBatchUpload.sql"
rem 10) Regex replace "echo (\/\*.+\/)" with "rem \1\r\necho \1". This duplicates the header in a way which is more obvious to read in the BAT file
rem 11) Copy the edited text back over the body of the BAT below (below the upload statements and before the run SQL statement) and save file
rem 12) comment out the run SQL statement, run the BAT and check the SQL appears sensible.
rem 13) Uncomment the run SQL statement and use the file
rem ***********
rem 8:37 PM 12 January, 2017: First version: MACC measures for agriculture / LULUCF; and afforestation rate over and above BAU
REM 7:08 PM 23 February, 2017: FS changes to instructions above
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
IF EXIST ElcBatchUpload.sql del /F ElcBatchUpload.sql
rem need to define some variables which contain DOS reserved words. These are replaced by the preprocessor in the script:
set "texta=IF"
set "textb=IF NOT"
set "textc=~"
set "textd=^"
rem this block creates the 2 temp table definitions. First stores the unformatted data from the VD file, second parses this into fields and inserts into the "vedastore" table against which the 
rem queries are run.
rem NB in the below uses the same temp table names as the main BAT script (vedastore etc). This doesn't matter as this BAT is a separate process (=separate connection) on the database
rem and so will not interfere with the main Q BAT. Note, however, that the names of the SQL file and CSVs generated need to be different so as not to collide with the main Q files
echo CREATE temp TABLE !textb! EXISTS vedastore( tablename varchar(100), id serial, attribute varchar(50), commodity varchar(50), process varchar(50), period varchar(50), region varchar(50), vintage varchar(50), timeslice varchar(50), userconstraint varchar(50), pv numeric ); drop table !texta! exists veda; create temp table veda( id serial, stuff varchar(1000) ); >> ElcBatchUpload.sql
rem the following creates a block of sql for each VD file to upload it, delete the header rows and break the entries into fields
for /f "delims=|" %%i in ('dir /b *.vd') do echo delete from veda; ALTER SEQUENCE veda_id_seq RESTART WITH 1; copy veda (stuff) from '%%~fi'; insert into vedastore (tablename, attribute ,commodity ,process ,period ,region ,vintage ,timeslice ,userconstraint ,pv) select '%%~ni', trim(both '"' from a[1]), trim(both '"' from a[2]), trim(both '"' from a[3]), trim(both '"' from a[4]), trim(both '"' from a[5]), trim(both '"' from a[6]), trim(both '"' from a[7]), trim(both '"' from a[8]), cast(a[9] as numeric) from ( select string_to_array(stuff, ',') from veda order by id offset 13 ) as dt(a); >> ElcBatchUpload.sql
rem electrical storage electricity in / out by timeslice;
rem /* *Annual timesliced elec storage output (techs grouped)* */
echo /* *Annual timesliced elec storage output (techs grouped)* */ >> ElcBatchUpload.sql
echo COPY ( >> ElcBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|Var_FOut^|ELC^|various'::varchar(300) "id", >> ElcBatchUpload.sql
echo analysis::varchar(50), >> ElcBatchUpload.sql
echo tablename, >> ElcBatchUpload.sql
echo 'VAR_FOut'::varchar "attribute", >> ElcBatchUpload.sql
echo 'ELC'::varchar "commodity", >> ElcBatchUpload.sql
echo 'various'::varchar(50) "process", >> ElcBatchUpload.sql
echo sum(pv)::numeric "all", >> ElcBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> ElcBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> ElcBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> ElcBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> ElcBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> ElcBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> ElcBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> ElcBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> ElcBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> ElcBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> ElcBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> ElcBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> ElcBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> ElcBatchUpload.sql
echo from ( >> ElcBatchUpload.sql
echo select process,period,pv, >> ElcBatchUpload.sql
echo case >> ElcBatchUpload.sql
echo when attribute='VAR_FOut' then 'elec-stor-out_' >> ElcBatchUpload.sql
echo when attribute='VAR_FIn' then 'elec-stor-in_' >> ElcBatchUpload.sql
echo end ^|^| >> ElcBatchUpload.sql
echo case >> ElcBatchUpload.sql
echo when process in('EHYDPMP00','EHYDPMP01') then 'hyd' --Filter 394 >> ElcBatchUpload.sql
echo when process in ('ECAESCON01','ESTGCAES01','ECAESTUR01','ESTGAACAES01') then 'caes' --Filter 395 >> ElcBatchUpload.sql
echo when process in ('ESTGBNAS01','ESTGBALA01','ESTGBRF01') then 'batt' --Filter 396 >> ElcBatchUpload.sql
echo end ^|^| '-' ^|^| >> ElcBatchUpload.sql
echo TimeSlice "analysis", >> ElcBatchUpload.sql
echo tablename, attribute, TimeSlice >> ElcBatchUpload.sql
echo from vedastore >> ElcBatchUpload.sql
echo where attribute in('VAR_FOut','VAR_FIn') and commodity = 'ELC' >> ElcBatchUpload.sql
echo ) a >> ElcBatchUpload.sql
echo where analysis is not null >> ElcBatchUpload.sql
echo group by id, analysis,tablename, attribute, TimeSlice >> ElcBatchUpload.sql
echo order by tablename, analysis, attribute, commodity >> ElcBatchUpload.sql
echo ) TO '%~dp0elecstortime.csv' delimiter ',' CSV HEADER; >> ElcBatchUpload.sql
rem following line actually runs the SQL code generated by the above using the postgres command utility "psql".
rem Comment this line out if you just want the SQL code to create the populated temp tables + the associated analysis queries:
"C:\Program Files\PostgreSQL\%postgresver%\bin\psql.exe" -h localhost -p 5432 -U postgres -d gams -f %~dp0ElcBatchUpload.sql