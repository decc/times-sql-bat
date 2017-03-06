@echo off
rem *****Ad Hoc Transport batch queries*****
rem DOS Batch file to construct SQL queries, run the code, amalgamate the results and tidy up (delete) the intermediate stages
rem this version is for more in-depth analysis of transport metrics than the "standard" query
rem version as filename. By Fernley Symons 5:39 PM 15 July, 2016
rem works by: 
rem 1) constructing SQL code file to create temp files from TIMES runs (creates one script entry for each file)
rem 2) adding analysis SQL to generate summaries which are output to CSVs
rem 3) amalgamates the CSVs
rem 4) deletes the intermediate CSVs leaving a single output file
rem By Fernley Symons
rem ***********
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
rem 6) Make replacements for other reserved DOS words. See below for example (set "texta..." etc).
rem    In general there will only be a few of these; define more as needed
rem    ****Note that the first 2 queries contain reserved words****
rem    NB No need to replace "~" in output file locations since these are DOS commands meaning "put it in the same folder as this BAT file".
rem    "~" only needs replacing if part of a query (i.e. regex in postgres).
rem 7) Change the single "%" to double "%%" but leave filenames for copy statements unchanged. Regex replace "(%[^~])" with "%\1"
rem 8) Escape other characters: Regex replace "(\||<|>)" with "^\1"
rem 9) Regex replace "(.+)" with "echo \1 >> TraBatchUpload.sql"
rem 10) Regex replace "echo (\/\*.+\/)" with "rem \1\r\necho \1". This duplicates the header in a way which is more obvious to read in the BAT file
rem 11) Copy the edited text back over the body of the BAT below (below the upload statements and before the run SQL statement) and save file
rem 12) comment out the run SQL statement, run the BAT and check the SQL appears sensible.
rem 13) Uncomment the run SQL statement and use the file
rem ***********
rem 5:40 PM 15 July, 2016: First version: moved from main batch query
REM 8:36 PM 06 September, 2016: changed to add postgres ver as a variable near top of script for ease of change
rem 8:42 PM 15 November, 2016: added extract of fuel by transport mode to extract international transport fuel use (temporary measure)
rem 2:10 PM 16 December, 2016: BF added 'RESMSWINO','RESMSWORG' to Filter 287 to match locations of equivalent service sector commodities 'SERMSWINO','SERMSWORG'
REM 3:53 PM 20 January, 2017: FS: Road transport fuel by mode query added
REM 6:19 PM 23 February, 2017 FS: various updates to reflect human readable, change to instructions for how to produce this file (above)
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
rem cannot use != - have to use ^<^> instead. Make sure that the file destination doesn't have two %% it [just one]
rem can't have very long lines - need to break statements
rem filename at end of line, no spaces afterwards
rem delete the SQL script if it exists - code below (re-) generates it.
IF EXIST TraBatchUpload.sql del /F TraBatchUpload.sql
set "texta=IF"
set "textb=IF NOT"
set "textc=~"
set "textd=^"
rem this block creates the 2 temp table definitions. First stores the unformatted data from the VD file, second parses this into fields and inserts into the "vedastore" table against which the 
rem queries are run.
rem NB in the below uses the same temp table names as the main BAT script (vedastore etc). This doesn't matter as this BAT is a separate process (=separate connection) on the database
rem and so will not interfere with the main Q BAT. Note, however, that the names of the SQL file and CSVs generated need to be different so as not to collide with the main Q files
echo CREATE temp TABLE !textb! EXISTS vedastore( tablename varchar(100), id serial, attribute varchar(50), commodity >> TraBatchUpload.sql
echo varchar(50), process varchar(50), period varchar(50), region varchar(50), vintage varchar(50), timeslice varchar(50), >> TraBatchUpload.sql
echo userconstraint varchar(50), pv numeric ); drop table !texta! exists veda; create temp table veda( id serial, stuff >> TraBatchUpload.sql
echo varchar(1000) ); >> TraBatchUpload.sql
rem the following creates a block of sql for each VD file to upload it, delete the header rows and break the entries into fields
for /f "delims=|" %%i in ('dir /b *.vd') do echo delete from veda; ALTER SEQUENCE veda_id_seq RESTART WITH 1; copy veda (stuff) from '%%~fi'; insert into vedastore (tablename, attribute ,commodity ,process ,period ,region ,vintage ,timeslice ,userconstraint ,pv) select '%%~ni', trim(both '"' from a[1]), trim(both '"' from a[2]), trim(both '"' from a[3]), trim(both '"' from a[4]), trim(both '"' from a[5]), trim(both '"' from a[6]), trim(both '"' from a[7]), trim(both '"' from a[8]), cast(a[9] as numeric) from ( select string_to_array(stuff, ',') from veda order by id offset 13 ) as dt(a); >> TraBatchUpload.sql
rem /* *Whole stock vehicle kms, emissions and emission intensity for 29 vehicle types* */
echo /* *Whole stock vehicle kms, emissions and emission intensity for 29 vehicle types* */ >> TraBatchUpload.sql
echo copy( >> TraBatchUpload.sql
echo with base_cng_emissions as( >> TraBatchUpload.sql
echo select tablename, period,'cars-emis_lpg-and-cng-fueled'::varchar(50) "analysis", >> TraBatchUpload.sql
echo 'VAR_FOut'::varchar(50) "attribute", >> TraBatchUpload.sql
echo 'GHG-TRA-NON-ETS-NO-AS'::varchar(50) "commodity", >> TraBatchUpload.sql
echo 0::numeric "pv" >> TraBatchUpload.sql
echo from vedastore group by tablename, period >> TraBatchUpload.sql
echo union >> TraBatchUpload.sql
echo select tablename, period,'hgv-emis_lpg-and-cng-fueled'::varchar(50) "analysis", >> TraBatchUpload.sql
echo 'VAR_FOut'::varchar(50) "attribute", >> TraBatchUpload.sql
echo 'GHG-TRA-NON-ETS-NO-AS'::varchar(50) "commodity", >> TraBatchUpload.sql
echo 0::numeric "pv" >> TraBatchUpload.sql
echo from vedastore group by tablename, period >> TraBatchUpload.sql
echo union >> TraBatchUpload.sql
echo select tablename, period,'lgv-emis_lpg-and-cng-fueled'::varchar(50) "analysis", >> TraBatchUpload.sql
echo 'VAR_FOut'::varchar(50) "attribute", >> TraBatchUpload.sql
echo 'GHG-TRA-NON-ETS-NO-AS'::varchar(50) "commodity", >> TraBatchUpload.sql
echo 0::numeric "pv" >> TraBatchUpload.sql
echo from vedastore group by tablename, period >> TraBatchUpload.sql
echo ) >> TraBatchUpload.sql
echo , cng_emis_shares as( >> TraBatchUpload.sql
echo select tablename,period, >> TraBatchUpload.sql
echo sum(case when proc_set='cars-cng-in' then pv else 0 end) "cars-cng-in", >> TraBatchUpload.sql
echo sum(case when proc_set='lgv-cng-in' then pv else 0 end) "lgv-cng-in", >> TraBatchUpload.sql
echo sum(case when proc_set='hgv-cng-in' then pv else 0 end) "hgv-cng-in", >> TraBatchUpload.sql
echo sum(case when proc_set in('cars-cng-in','lgv-cng-in','hgv-cng-in') then pv else 0 end) "total_cng_in", >> TraBatchUpload.sql
echo sum(case when proc_set='cng-conv-emis' then pv else 0 end) "cng-conv-emis" >> TraBatchUpload.sql
echo from ( >> TraBatchUpload.sql
echo select >> TraBatchUpload.sql
echo tablename,process,period,pv, >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when process = 'TFSSCNG01' and attribute ='VAR_FOut' and commodity in('GHG-TRA-NON-ETS-NO-AS') then 'cng-conv-emis'  >> TraBatchUpload.sql
echo when attribute = 'VAR_FIn' and commodity in('TRACNGS','TRACNGL') then >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when process like 'TC%%' then 'cars-cng-in'  >> TraBatchUpload.sql
echo when process like 'TL%%' then 'lgv-cng-in'  >> TraBatchUpload.sql
echo when process like 'TH%%' then 'hgv-cng-in'  >> TraBatchUpload.sql
echo end >> TraBatchUpload.sql
echo end as "proc_set" >> TraBatchUpload.sql
echo from vedastore >> TraBatchUpload.sql
echo where (attribute = 'VAR_FIn' or attribute ='VAR_FOut') and commodity in('TRACNGS','TRACNGL','GHG-AGR-NO-LULUCF', >> TraBatchUpload.sql
echo 'GHG-ELC','GHG-ELC-CAPTURED','GHG-ETS-NET', >> TraBatchUpload.sql
echo 'GHG-ETS-NO-IAS-NET','GHG-ETS-NO-IAS-TER','GHG-ETS-TER','GHG-ETS-YES-IAS-NET', >> TraBatchUpload.sql
echo 'GHG-ETS-YES-IAS-TER','GHG-IAS-ETS','GHG-IAS-NON-ETS','GHG-IND-ETS', >> TraBatchUpload.sql
echo 'GHG-IND-ETS-CAPTURED','GHG-IND-NON-ETS','GHG-IND-NON-ETS-CAPTURED','GHG-LULUCF', >> TraBatchUpload.sql
echo 'GHG-NO-IAS-NO-LULUCF-NET','GHG-NO-IAS-NO-LULUCF-TER', >> TraBatchUpload.sql
echo 'GHG-NO-IAS-YES-LULUCF-NET','GHG-NO-IAS-YES-LULUCF-TER', >> TraBatchUpload.sql
echo 'GHG-NON-ETS-NO-LULUCF-NET','GHG-NON-ETS-NO-LULUCF-TER', >> TraBatchUpload.sql
echo 'GHG-NON-ETS-YES-LULUCF-NET','GHG-NON-ETS-YES-LULUCF-TER','GHG-OTHER-ETS', >> TraBatchUpload.sql
echo 'GHG-OTHER-ETS-CAPTURED','GHG-OTHER-NON-ETS','GHG-RES-ETS','GHG-RES-NON-ETS', >> TraBatchUpload.sql
echo 'GHG-SER-ETS','GHG-SER-NON-ETS','GHG-TRA-NON-ETS-NO-AS', >> TraBatchUpload.sql
echo 'GHG-YES-IAS-NO-LULUCF-NET','GHG-YES-IAS-NO-LULUCF-TER', >> TraBatchUpload.sql
echo 'GHG-YES-IAS-YES-LULUCF-NET','GHG-YES-IAS-YES-LULUCF-TER') and >> TraBatchUpload.sql
echo (process = 'TFSSCNG01' or process like any(array['TC%%','TL%%','TH%%','TB%%']))  >> TraBatchUpload.sql
echo order by process >> TraBatchUpload.sql
echo ) a >> TraBatchUpload.sql
echo where proc_set ^<^>'' >> TraBatchUpload.sql
echo group by tablename,period >> TraBatchUpload.sql
echo ) >> TraBatchUpload.sql
echo , main_crosstab as( >> TraBatchUpload.sql
echo select analysis::varchar(50), tablename,attribute,commodity,period,sum(pv) "pv" >> TraBatchUpload.sql
echo from ( >> TraBatchUpload.sql
echo select a.tablename, a.analysis, a.period,a.attribute,a.commodity, >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when analysis='cars-emis_lpg-and-cng-fueled' then >> TraBatchUpload.sql
echo case when "total_cng_in" ^> 0 then "cars-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end >> TraBatchUpload.sql
echo when analysis='lgv-emis_lpg-and-cng-fueled' then >> TraBatchUpload.sql
echo case when "total_cng_in" ^> 0 then "lgv-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end >> TraBatchUpload.sql
echo when analysis='hgv-emis_lpg-and-cng-fueled' then >> TraBatchUpload.sql
echo case when "total_cng_in" ^> 0 then "hgv-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end >> TraBatchUpload.sql
echo else pv >> TraBatchUpload.sql
echo end "pv" >> TraBatchUpload.sql
echo from ( >> TraBatchUpload.sql
echo select tablename, period, analysis, attribute, commodity,sum(pv) "pv" >> TraBatchUpload.sql
echo from ( >> TraBatchUpload.sql
echo select tablename, process, period,pv,attribute,commodity, >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when process like 'TC%%' then 'cars-' >> TraBatchUpload.sql
echo when process like 'TL%%' then 'lgv-' >> TraBatchUpload.sql
echo when process like 'TH%%' then 'hgv-' >> TraBatchUpload.sql
echo when process like 'TB%%' or process='TFSLCNG01' then 'bus-' >> TraBatchUpload.sql
echo when process like 'TW%%' then 'bike-' >> TraBatchUpload.sql
echo end ^|^| >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when commodity in('TC','TL','TH1','TH2','TH3','TB','TW') then 'km_' >> TraBatchUpload.sql
echo when commodity in('GHG-TRA-NON-ETS-NO-AS') then 'emis_' >> TraBatchUpload.sql
echo end ^|^| >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when process in('TBDST00','TBDST01','TCDST00','TCDST01','TH1DST00','TH2DST00','TH3DST00','TH1DST01', >> TraBatchUpload.sql
echo 'TH2DST01','TH3DST01','TLDST00','TLDST01') then 'diesel'  >> TraBatchUpload.sql
echo when process in('TCE8501','TLE8501') then 'E85'  >> TraBatchUpload.sql
echo when process in('TBELC01','TCELC01','TLELC01','TH3ELC01','TWELC01') then 'electric'  >> TraBatchUpload.sql
echo when process in('TBFCHBHYG01','TCFCHBHYG01','TCFCHYG01','TCHBE8501','TCHBHYL01','TH1FCHBHYG01', >> TraBatchUpload.sql
echo 'TH2FCHBHYG01','TH3FCHBHYG01','TLFCHBHYG01','TLFCHYG01','TLHBHYL01','TWFCHYG01') then 'h2+hybrid'  >> TraBatchUpload.sql
echo when process in('TCFCPHBHYG01') then 'h2-plug-in-hybrid'  >> TraBatchUpload.sql
echo when process in('TBHBDST01','TCHBDST01','TCHBPET00','TCHBPET01','TH1HBDST01','TH2HBDST01', >> TraBatchUpload.sql
echo 'TH3HBDST01','TLHBDST01','TLHBPET01') then 'hybrid'  >> TraBatchUpload.sql
echo when process in('TBCNG01','TCCNG01','TCLPG00','TCLPG01','TH1CNG01','TH2CNG01', >> TraBatchUpload.sql
echo 'TH3CNG01','TLCNG01','TLLPG01','TFSLCNG01') then 'lpg-and-cng-fueled'  >> TraBatchUpload.sql
echo when process in('TCPET00','TCPET01','TLPET00','TLPET01','TWPET00','TWPET01') then 'petrol'  >> TraBatchUpload.sql
echo when process in('TCPHBDST01','TCPHBPET01','TLPHBDST01','TLPHBPET01') then 'plug-in-hybrid'  >> TraBatchUpload.sql
echo when process in('TH2CNGDST01','TH3CNGDST01') then 'Dual fuel diesel-CNG'  >> TraBatchUpload.sql
echo end as "analysis" >> TraBatchUpload.sql
echo from vedastore >> TraBatchUpload.sql
echo where attribute = 'VAR_FOut' and commodity in('GHG-TRA-NON-ETS-NO-AS','TB','TC','TH1','TH2','TH3','TL','TW') >> TraBatchUpload.sql
echo and (process like any(array['TC%%','TL%%','TB%%','TW%%']) or process !textc!'!textd!TH[!textd!Y]' or process='TFSLCNG01') >> TraBatchUpload.sq
echo ) a >> TraBatchUpload.sql
echo where analysis ^<^>'' >> TraBatchUpload.sql
echo group by tablename, period, analysis, attribute, commodity >> TraBatchUpload.sql
echo union >> TraBatchUpload.sql
echo select * from base_cng_emissions >> TraBatchUpload.sql
echo ) a >> TraBatchUpload.sql
echo left join cng_emis_shares b on a.tablename=b.tablename and a.period=b.period >> TraBatchUpload.sql
echo ) b >> TraBatchUpload.sql
echo group by analysis, tablename,attribute,commodity,period >> TraBatchUpload.sql
echo order by tablename, analysis >> TraBatchUpload.sql
echo ) >> TraBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| commodity ^|^| '^|various'::varchar(300) "id", analysis::varchar(50), tablename,attribute, >> TraBatchUpload.sql
echo commodity, >> TraBatchUpload.sql
echo 'various'::varchar(50) "process", >> TraBatchUpload.sql
echo case when analysis like '%%-inten%%' then avg(pv)::numeric else sum(pv)::numeric end "all", >> TraBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> TraBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> TraBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> TraBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> TraBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> TraBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> TraBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> TraBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> TraBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> TraBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> TraBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> TraBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> TraBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> TraBatchUpload.sql
echo from ( >> TraBatchUpload.sql
echo select a.* from main_crosstab a >> TraBatchUpload.sql
echo where period^<^>'-' >> TraBatchUpload.sql
echo union >> TraBatchUpload.sql
echo select left(analysis, position('_' in analysis)) ^|^|'all' "analysis", tablename, 'VAR_FOut' "attribute", commodity, period,sum(pv) "pv" from main_crosstab >> TraBatchUpload.sql
echo where period^<^>'-' >> TraBatchUpload.sql
echo group by left(analysis, position('_' in analysis)), tablename,commodity,period >> TraBatchUpload.sql
echo union >> TraBatchUpload.sql
echo select left(analysis, position('-' in analysis))^|^|'emis-inten_all' "analysis", tablename, 'VAR_FOut' "attribute", '-' "commodity", period, >> TraBatchUpload.sql
echo sum(pv) filter(where analysis like '%%-emis%%')/sum(pv) filter(where analysis like '%%-km%%') "pv" >> TraBatchUpload.sql
echo from main_crosstab >> TraBatchUpload.sql
echo where period^<^>'-' and period^<^>'2200' >> TraBatchUpload.sql
echo group by left(analysis, position('-' in analysis)), tablename,period >> TraBatchUpload.sql
echo order by tablename, period, analysis >> TraBatchUpload.sql
echo ) a >> TraBatchUpload.sql
echo group by analysis, tablename,attribute,commodity >> TraBatchUpload.sql
echo order by tablename, analysis >> TraBatchUpload.sql
echo ) TO '%~dp0vehKms.csv' delimiter ',' CSV; >> TraBatchUpload.sql
rem /* *New stock vehicle kms, emissions and emission intensity for 29 vehicle types* */
echo /* *New stock vehicle kms, emissions and emission intensity for 29 vehicle types* */ >> TraBatchUpload.sql
echo COPY ( >> TraBatchUpload.sql
echo with base_cng_emissions as( >> TraBatchUpload.sql
echo select tablename, period,'cars-new-emis_lpg-and-cng-fueled'::varchar "analysis", >> TraBatchUpload.sql
echo 'VAR_FOut'::varchar "atttribute", 'GHG-TRA-NON-ETS-NO-AS'::varchar "commodity", >> TraBatchUpload.sql
echo 0::numeric "pv" >> TraBatchUpload.sql
echo from vedastore group by tablename, period >> TraBatchUpload.sql
echo union >> TraBatchUpload.sql
echo select tablename, period,'hgv-new-emis_lpg-and-cng-fueled'::varchar "analysis", >> TraBatchUpload.sql
echo 'VAR_FOut'::varchar "atttribute", 'GHG-TRA-NON-ETS-NO-AS'::varchar "commodity", >> TraBatchUpload.sql
echo 0::numeric "pv" >> TraBatchUpload.sql
echo from vedastore group by tablename, period >> TraBatchUpload.sql
echo union >> TraBatchUpload.sql
echo select tablename, period,'lgv-new-emis_lpg-and-cng-fueled'::varchar "analysis", >> TraBatchUpload.sql
echo 'VAR_FOut'::varchar "atttribute", 'GHG-TRA-NON-ETS-NO-AS'::varchar "commodity", >> TraBatchUpload.sql
echo 0::numeric "pv" >> TraBatchUpload.sql
echo from vedastore group by tablename, period >> TraBatchUpload.sql
echo union >> TraBatchUpload.sql
echo select tablename, period,'bus-new-emis_lpg-and-cng-fueled'::varchar "analysis", >> TraBatchUpload.sql
echo 'VAR_FOut'::varchar "atttribute", 'GHG-TRA-NON-ETS-NO-AS'::varchar "commodity", >> TraBatchUpload.sql
echo 0::numeric "pv" >> TraBatchUpload.sql
echo from vedastore group by tablename, period >> TraBatchUpload.sql
echo ) >> TraBatchUpload.sql
echo , cng_emis_shares as( >> TraBatchUpload.sql
echo select tablename,period, >> TraBatchUpload.sql
echo sum(case when proc_set='cars-new-cng-in' then pv else 0 end) "cars-new-cng-in", >> TraBatchUpload.sql
echo sum(case when proc_set='lgv-new-cng-in' then pv else 0 end) "lgv-new-cng-in", >> TraBatchUpload.sql
echo sum(case when proc_set='hgv-new-cng-in' then pv else 0 end) "hgv-new-cng-in", >> TraBatchUpload.sql
echo sum(case when proc_set in('cars-new-cng-in','lgv-new-cng-in','hgv-new-cng-in','older-veh-cng-in') then pv else 0 end) "total_cng_in", >> TraBatchUpload.sql
echo sum(case when proc_set='cng-conv-emis' then pv else 0 end) "cng-conv-emis", >> TraBatchUpload.sql
echo sum(case when proc_set='bus-new-cng-in' then pv else 0 end) "bus-new-cng-in", >> TraBatchUpload.sql
echo sum(case when proc_set in('bus-new-cng-in','older-bus-cng-in') then pv else 0 end) "total_bus_cng_in", >> TraBatchUpload.sql
echo sum(case when proc_set='bus-cng-conv-emis' then pv else 0 end) "bus-cng-conv-emis" >> TraBatchUpload.sql
echo from ( >> TraBatchUpload.sql
echo select tablename,process,period,pv, >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when process = 'TFSSCNG01' and attribute ='VAR_FOut' and >> TraBatchUpload.sql
echo commodity in('GHG-TRA-NON-ETS-NO-AS') then 'cng-conv-emis'  >> TraBatchUpload.sql
echo when process = 'TFSLCNG01' and attribute ='VAR_FOut' and commodity='GHG-TRA-NON-ETS-NO-AS' then 'bus-cng-conv-emis'  >> TraBatchUpload.sql
echo when attribute = 'VAR_FIn' and commodity in('TRACNGS','TRACNGL') then >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when process like 'TC%%' and vintage=period then 'cars-new-cng-in'  >> TraBatchUpload.sql
echo when process like 'TL%%' and vintage=period then 'lgv-new-cng-in'  >> TraBatchUpload.sql
echo when process like 'TH%%' and vintage=period then 'hgv-new-cng-in'  >> TraBatchUpload.sql
echo when process like any(array['TC%%','TL%%','TH%%']) and vintage^<^>period then 'older-veh-cng-in'  >> TraBatchUpload.sql
echo when process like 'TB%%' and vintage=period then 'bus-new-cng-in'  >> TraBatchUpload.sql
echo when process like 'TB%%' and vintage^<^>period then 'older-bus-cng-in'  >> TraBatchUpload.sql
echo end >> TraBatchUpload.sql
echo end as "proc_set" >> TraBatchUpload.sql
echo from vedastore >> TraBatchUpload.sql
echo order by process >> TraBatchUpload.sql
echo ) a >> TraBatchUpload.sql
echo where proc_set ^<^>'' >> TraBatchUpload.sql
echo group by tablename,period >> TraBatchUpload.sql
echo ) >> TraBatchUpload.sql
echo , main_crosstab as( >> TraBatchUpload.sql
echo select analysis, tablename,attribute,commodity,period,sum(pv) "pv" from ( >> TraBatchUpload.sql
echo select a.tablename, a.analysis, a.period,a.attribute,a.commodity, >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when analysis='cars-new-emis_lpg-and-cng-fueled' then >> TraBatchUpload.sql
echo case when "total_cng_in" ^> 0 then "cars-new-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end >> TraBatchUpload.sql
echo when analysis='lgv-new-emis_lpg-and-cng-fueled' then >> TraBatchUpload.sql
echo case when "total_cng_in" ^> 0 then "lgv-new-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end >> TraBatchUpload.sql
echo when analysis='hgv-new-emis_lpg-and-cng-fueled' then >> TraBatchUpload.sql
echo case when "total_cng_in" ^> 0 then "hgv-new-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end >> TraBatchUpload.sql
echo when analysis='bus-new-emis_lpg-and-cng-fueled' then >> TraBatchUpload.sql
echo case when "total_bus_cng_in" ^> 0 then "bus-new-cng-in"/"total_bus_cng_in"*"bus-cng-conv-emis" + pv else pv end >> TraBatchUpload.sql
echo else pv >> TraBatchUpload.sql
echo end "pv" >> TraBatchUpload.sql
echo from ( >> TraBatchUpload.sql
echo select tablename, period, analysis, attribute, commodity,sum(pv) "pv" >> TraBatchUpload.sql
echo from ( >> TraBatchUpload.sql
echo select tablename, process, period,pv,attribute,commodity, >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when process like 'TC%%' then 'cars-new-' >> TraBatchUpload.sql
echo when process like 'TL%%' then 'lgv-new-' >> TraBatchUpload.sql
echo when process like 'TH%%' then 'hgv-new-' >> TraBatchUpload.sql
echo when process like 'TB%%' then 'bus-new-' >> TraBatchUpload.sql
echo when process like 'TW%%' then 'bike-new-' >> TraBatchUpload.sql
echo end ^|^| >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when commodity in('TC','TL','TH1','TH2','TH3','TB','TW') then 'km_' >> TraBatchUpload.sql
echo when commodity in('GHG-TRA-NON-ETS-NO-AS') then 'emis_' >> TraBatchUpload.sql
echo end ^|^| >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when process in('TBDST00','TBDST01','TCDST00','TCDST01','TH1DST00','TH2DST00','TH3DST00','TH1DST01','TH2DST01', >> TraBatchUpload.sql
echo 'TH3DST01','TLDST00','TLDST01') then 'diesel'  >> TraBatchUpload.sql
echo when process in('TCE8501','TLE8501') then 'E85'  >> TraBatchUpload.sql
echo when process in('TBELC01','TCELC01','TLELC01','TH3ELC01','TWELC01') then 'electric'  >> TraBatchUpload.sql
echo when process in('TBFCHBHYG01','TCFCHBHYG01','TCFCHYG01','TCHBE8501','TCHBHYL01','TH1FCHBHYG01','TH2FCHBHYG01', >> TraBatchUpload.sql
echo 'TH3FCHBHYG01','TLFCHBHYG01','TLFCHYG01','TLHBHYL01','TWFCHYG01') then 'h2+hybrid'  >> TraBatchUpload.sql
echo when process in('TCFCPHBHYG01') then 'h2-plug-in-hybrid'  >> TraBatchUpload.sql
echo when process in('TBHBDST01','TCHBDST01','TCHBPET00','TCHBPET01','TH1HBDST01','TH2HBDST01', >> TraBatchUpload.sql
echo 'TH3HBDST01','TLHBDST01','TLHBPET01') then 'hybrid'   >> TraBatchUpload.sql
echo when process in('TBCNG01','TCCNG01','TCLPG00','TCLPG01','TH1CNG01','TH2CNG01', >> TraBatchUpload.sql
echo 'TH3CNG01','TLCNG01','TLLPG01') then 'lpg-and-cng-fueled'  >> TraBatchUpload.sql
echo when process in('TCPET00','TCPET01','TLPET00','TLPET01','TWPET00','TWPET01') then 'petrol'  >> TraBatchUpload.sql
echo when process in('TCPHBDST01','TCPHBPET01','TLPHBDST01','TLPHBPET01') then 'plug-in-hybrid'  >> TraBatchUpload.sql
echo when process in('TH2CNGDST01','TH3CNGDST01') then 'Dual fuel diesel-CNG'  >> TraBatchUpload.sql
echo end as "analysis" >> TraBatchUpload.sql
echo from vedastore >> TraBatchUpload.sql
echo where attribute = 'VAR_FOut' and commodity in('TC','TL','TH1','TH2','TH3','TW','TB','GHG-TRA-NON-ETS-NO-AS') >> TraBatchUpload.sql
echo and (process like any(array['TC%%%','TL%%%','TB%%%','TW%%%']) or process !textc!'!textd!TH[!textd!Y]') and vintage=period and process like '%%01' >> TraBatchUpload.sql
echo ) a >> TraBatchUpload.sql
echo where analysis ^<^>'' >> TraBatchUpload.sql
echo group by tablename, period, analysis, attribute, commodity >> TraBatchUpload.sql
echo union >> TraBatchUpload.sql
echo select * from base_cng_emissions >> TraBatchUpload.sql
echo ) a >> TraBatchUpload.sql
echo left join cng_emis_shares b on a.tablename=b.tablename and a.period=b.period >> TraBatchUpload.sql
echo ) b >> TraBatchUpload.sql
echo group by analysis, tablename,attribute,commodity,period >> TraBatchUpload.sql
echo order by tablename, analysis >> TraBatchUpload.sql
echo ) >> TraBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| commodity ^|^| '^|various'::varchar(300) "id", analysis::varchar(50), tablename,attribute, >> TraBatchUpload.sql
echo commodity, >> TraBatchUpload.sql
echo 'various'::varchar(50) "process", >> TraBatchUpload.sql
echo case when analysis like '%%-inten%%' then avg(pv)::numeric else sum(pv)::numeric end "all", >> TraBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> TraBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> TraBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> TraBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> TraBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> TraBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> TraBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> TraBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> TraBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> TraBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> TraBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> TraBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> TraBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> TraBatchUpload.sql
echo from ( >> TraBatchUpload.sql
echo select a.* from main_crosstab a >> TraBatchUpload.sql
echo where period^<^>'-' >> TraBatchUpload.sql
echo union >> TraBatchUpload.sql
echo select left(analysis, position('_' in analysis)) ^|^|'all' "analysis", tablename, 'VAR_FOut' "attribute", commodity, period,sum(pv) "pv" from main_crosstab >> TraBatchUpload.sql
echo where period^<^>'-' >> TraBatchUpload.sql
echo group by left(analysis, position('_' in analysis)), tablename,commodity,period >> TraBatchUpload.sql
echo union >> TraBatchUpload.sql
echo select left(analysis, position('-' in analysis))^|^|'new-emis-inten_all' "analysis", tablename, 'VAR_FOut' "attribute", '-' "commodity", period, >> TraBatchUpload.sql
echo sum(pv) filter(where analysis like '%%-emis%%')/sum(pv) filter(where analysis like '%%-km%%') "pv" >> TraBatchUpload.sql
echo from main_crosstab >> TraBatchUpload.sql
echo where period^<^>'-' and period^<^>'2200' >> TraBatchUpload.sql
echo group by left(analysis, position('-' in analysis)), tablename,period >> TraBatchUpload.sql
echo order by tablename, period, analysis >> TraBatchUpload.sql
echo ) a >> TraBatchUpload.sql
echo group by analysis, tablename,attribute,commodity >> TraBatchUpload.sql
echo order by tablename, analysis >> TraBatchUpload.sql
echo ) TO '%~dp0newVehKms.csv' delimiter ',' CSV; >> TraBatchUpload.sql
rem /* *Whole stock capacity for vehicles for 29 vehicle types* */
echo /* *Whole stock capacity for vehicles for 29 vehicle types* */ >> TraBatchUpload.sql
echo COPY ( >> TraBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| commodity ^|^| '^|various'::varchar(300) "id", analysis, tablename,attribute, >> TraBatchUpload.sql
echo commodity, >> TraBatchUpload.sql
echo 'various'::varchar(50) "process", >> TraBatchUpload.sql
echo sum(pv)::numeric "all", >> TraBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> TraBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> TraBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> TraBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> TraBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> TraBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> TraBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> TraBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> TraBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> TraBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> TraBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> TraBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> TraBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> TraBatchUpload.sql
echo from ( >> TraBatchUpload.sql
echo select process,period,pv, >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when process like 'TC%%' then 'cars-cap_' >> TraBatchUpload.sql
echo when process like 'TL%%' then 'lgv-cap_' >> TraBatchUpload.sql
echo when process like 'TH%%' then 'hgv-cap_' >> TraBatchUpload.sql
echo when process like 'TB%%' then 'bus-cap_' >> TraBatchUpload.sql
echo when process like 'TW%%' then 'bike-cap_' >> TraBatchUpload.sql
echo end ^|^| >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when process in('TBDST00','TBDST01','TCDST00','TCDST01','TH1DST00','TH2DST00','TH3DST00','TH1DST01', >> TraBatchUpload.sql
echo 'TH2DST01','TH3DST01','TLDST00','TLDST01') then 'diesel'  >> TraBatchUpload.sql
echo when process in('TCE8501','TLE8501') then 'E85'  >> TraBatchUpload.sql
echo when process in('TBELC01','TCELC01','TLELC01','TH3ELC01','TWELC01') then 'electric'  >> TraBatchUpload.sql
echo when process in('TBFCHBHYG01','TCFCHBHYG01','TCFCHYG01','TCHBE8501','TCHBHYL01','TH1FCHBHYG01', >> TraBatchUpload.sql
echo 'TH2FCHBHYG01','TH3FCHBHYG01','TLFCHBHYG01','TLFCHYG01','TLHBHYL01','TWFCHYG01') then 'h2+hybrid'  >> TraBatchUpload.sql
echo when process in('TCFCPHBHYG01') then 'h2-plug-in-hybrid'  >> TraBatchUpload.sql
echo when process in('TBHBDST01','TCHBDST01','TCHBPET00','TCHBPET01','TH1HBDST01','TH2HBDST01', >> TraBatchUpload.sql
echo 'TH3HBDST01','TLHBDST01','TLHBPET01') then 'hybrid'   >> TraBatchUpload.sql
echo when process in('TBCNG01','TCCNG01','TCLPG00','TCLPG01','TH1CNG01','TH2CNG01','TH3CNG01', >> TraBatchUpload.sql
echo 'TLCNG01','TLLPG01') then 'lpg-and-cng-fueled'  >> TraBatchUpload.sql
echo when process in('TCPET00','TCPET01','TLPET00','TLPET01','TWPET00','TWPET01') then 'petrol'  >> TraBatchUpload.sql
echo when process in('TCPHBDST01','TCPHBPET01','TLPHBDST01','TLPHBPET01') then 'plug-in-hybrid'  >> TraBatchUpload.sql
echo when process in('TH2CNGDST01','TH3CNGDST01') then 'Dual fuel diesel-CNG'  >> TraBatchUpload.sql
echo end as "analysis", >> TraBatchUpload.sql
echo tablename, attribute,commodity >> TraBatchUpload.sql
echo from vedastore >> TraBatchUpload.sql
echo where attribute = 'VAR_Cap' and process like any(array['TC%%','TL%%','TH%%','TB%%','TW%%'])  >> TraBatchUpload.sql
echo ) a >> TraBatchUpload.sql
echo where analysis ^<^>'' >> TraBatchUpload.sql
echo group by id, analysis,tablename, attribute, commodity >> TraBatchUpload.sql
echo order by tablename,  analysis, attribute, commodity >> TraBatchUpload.sql
echo ) TO '%~dp0VehCapOut.csv' delimiter ',' CSV; >> TraBatchUpload.sql
rem /* *New build capacity for vehicles for 29 vehicle types* */
echo /* *New build capacity for vehicles for 29 vehicle types* */ >> TraBatchUpload.sql
echo COPY ( >> TraBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| commodity ^|^| '^|various'::varchar(300) "id", analysis::varchar(50), tablename,attribute, >> TraBatchUpload.sql
echo commodity, >> TraBatchUpload.sql
echo 'various'::varchar(50) "process", >> TraBatchUpload.sql
echo sum(pv)::numeric "all", >> TraBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> TraBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> TraBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> TraBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> TraBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> TraBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> TraBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> TraBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> TraBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> TraBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> TraBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> TraBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> TraBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> TraBatchUpload.sql
echo from ( >> TraBatchUpload.sql
echo select process,period,pv, >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when process like 'TC%%' then 'cars-new-cap_' >> TraBatchUpload.sql
echo when process like 'TL%%' then 'lgv-new-cap_' >> TraBatchUpload.sql
echo when process like 'TH%%' then 'hgv-new-cap_' >> TraBatchUpload.sql
echo when process like 'TB%%' then 'bus-new-cap_' >> TraBatchUpload.sql
echo when process like 'TW%%' then 'bike-new-cap_' >> TraBatchUpload.sql
echo end ^|^| >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when process in('TBDST00','TBDST01','TCDST00','TCDST01','TH1DST00','TH2DST00','TH3DST00','TH1DST01', >> TraBatchUpload.sql
echo 'TH2DST01','TH3DST01','TLDST00','TLDST01') then 'diesel'  >> TraBatchUpload.sql
echo when process in('TCE8501','TLE8501') then 'E85'  >> TraBatchUpload.sql
echo when process in('TBELC01','TCELC01','TLELC01','TH3ELC01','TWELC01') then 'electric'  >> TraBatchUpload.sql
echo when process in('TBFCHBHYG01','TCFCHBHYG01','TCFCHYG01','TCHBE8501','TCHBHYL01','TH1FCHBHYG01', >> TraBatchUpload.sql
echo 'TH2FCHBHYG01','TH3FCHBHYG01','TLFCHBHYG01','TLFCHYG01','TLHBHYL01','TWFCHYG01') then 'h2+hybrid'  >> TraBatchUpload.sql
echo when process in('TCFCPHBHYG01') then 'h2-plug-in-hybrid'  >> TraBatchUpload.sql
echo when process in('TBHBDST01','TCHBDST01','TCHBPET00','TCHBPET01','TH1HBDST01','TH2HBDST01', >> TraBatchUpload.sql
echo 'TH3HBDST01','TLHBDST01','TLHBPET01') then 'hybrid'  >> TraBatchUpload.sql
echo when process in('TBCNG01','TCCNG01','TCLPG00','TCLPG01','TH1CNG01','TH2CNG01','TH3CNG01', >> TraBatchUpload.sql
echo 'TLCNG01','TLLPG01') then 'lpg-and-cng-fueled'  >> TraBatchUpload.sql
echo when process in('TCPET00','TCPET01','TLPET00','TLPET01','TWPET00','TWPET01') then 'petrol'  >> TraBatchUpload.sql
echo when process in('TCPHBDST01','TCPHBPET01','TLPHBDST01','TLPHBPET01') then 'plug-in-hybrid'  >> TraBatchUpload.sql
echo when process in('TH2CNGDST01','TH3CNGDST01') then 'Dual fuel diesel-CNG'  >> TraBatchUpload.sql
echo end as "analysis", >> TraBatchUpload.sql
echo tablename, attribute,commodity >> TraBatchUpload.sql
echo from vedastore >> TraBatchUpload.sql
echo where attribute = 'VAR_Ncap' and process like any(array['TC%%','TL%%','TH%%','TB%%','TW%%'])  >> TraBatchUpload.sql
echo ) a >> TraBatchUpload.sql
echo where analysis ^<^>'' >> TraBatchUpload.sql
echo group by id, analysis,tablename, attribute, commodity >> TraBatchUpload.sql
echo order by tablename,  analysis, attribute, commodity >> TraBatchUpload.sql
echo ) TO '%~dp0newVehCapOut.csv' delimiter ',' CSV; >> TraBatchUpload.sql
rem /* *TRA_Fuel_by_mode* */
echo /* *TRA_Fuel_by_mode* */ >> TraBatchUpload.sql
echo COPY ( >> TraBatchUpload.sql
echo with fuels_in as ( >> TraBatchUpload.sql
echo select process,period,pv, >> TraBatchUpload.sql
echo case  >> TraBatchUpload.sql
echo when process in('TAIJETE00','TAIJETE01','TAIJETN00','TAIJETN01','TAIJET02','TAIHYLE01','TAIHYLN01') then 'TRA-AVI-INT'  >> TraBatchUpload.sql
echo when process in('TSIHYG01','TSIOIL00','TSIOIL01') then 'TRA-SHIP-INT'  >> TraBatchUpload.sql
echo end as proc, >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when commodity in('AGRBIODST','AGRBIOLPG','AGRBOM','AGRGRASS','AGRMAINSBOM','AGRPOLWST','BGRASS','BIODST','BIODST-FT','BIOJET-FT','BIOKER-FT','BIOLFO' >> TraBatchUpload.sql
echo ,'BIOLPG','BIOOIL','BOG-AD','BOG-G','BOG-LF','BOM','BPELH','BPELL','BRSEED','BSEWSLG','BSLURRY','BSTARCH' >> TraBatchUpload.sql
echo ,'BSTWWST','BSUGAR','BTREATSTW','BTREATWOD','BVOIL','BWOD','BWODLOG','BWODWST','ELCBIOCOA','ELCBIOCOA2','ELCBIOLFO','ELCBIOOIL' >> TraBatchUpload.sql
echo ,'ELCBOG-AD','ELCBOG-LF','ELCBOG-SW','ELCBOM','ELCMAINSBOM','ELCMSWINO','ELCMSWORG','ELCPELH','ELCPELL','ELCPOLWST','ELCSTWWST','ELCTRANSBOM' >> TraBatchUpload.sql
echo ,'ETH','HYGBIOO','HYGBPEL','HYGMSWINO','HYGMSWORG','INDBIOLFO','INDBIOLPG','INDBIOOIL','INDBOG-AD','INDBOG-LF','INDBOM','INDGRASS' >> TraBatchUpload.sql
echo ,'INDMAINSBOM','INDMSWINO','INDMSWORG','INDPELH','INDPELL','INDPOLWST','INDWOD','INDWODWST','METH','MSWBIO','MSWINO','MSWORG' >> TraBatchUpload.sql
echo ,'PWASTEDUM','RESBIOLFO','RESBOM','RESHOUSEBOM','RESMSWINO','RESMSWORG','RESMAINSBOM','RESPELH','RESWOD','RESWODL','SERBIOLFO','SERBOG','SERBOM','SERBUILDBOM' >> TraBatchUpload.sql
echo ,'SERMAINSBOM','SERMSWBIO','SERMSWINO','SERMSWORG','SERPELH','SERWOD','TRABIODST','TRABIODST-FT','TRABIODST-FTL','TRABIODST-FTS','TRABIODSTL','TRABIODSTS' >> TraBatchUpload.sql
echo ,'TRABIOJET-FTDA','TRABIOJET-FTDAL','TRABIOJET-FTIA','TRABIOJET-FTIAL','TRABIOLFO','TRABIOLFODS','TRABIOLFODSL','TRABIOLFOL','TRABIOOILIS','TRABIOOILISL','TRABOM','TRAETH' >> TraBatchUpload.sql
echo ,'TRAETHL','TRAETHS','TRAMAINSBOM','TRAMETH') then 'ALL BIO'  >> TraBatchUpload.sql
echo when commodity in('AGRDISTELC','AGRELC','ELC','ELC-E-EU','ELC-E-IRE','ELC-I-EU','ELC-I-IRE','ELCGEN','ELCSURPLUS','HYGELC','HYGELCSURP','HYGLELC' >> TraBatchUpload.sql
echo ,'HYGSELC','INDDISTELC','INDELC','PRCELC','RESDISTELC','RESELC','RESELCSURPLUS','RESHOUSEELC','SERBUILDELC','SERDISTELC','SERELC','TRACELC' >> TraBatchUpload.sql
echo ,'TRACPHB','TRADISTELC','TRAELC','UPSELC') then 'ALL ELECTRICITY'  >> TraBatchUpload.sql
echo when commodity in('AGRNGA','ELCNGA','HYGLNGA','HYGSNGA','IISNGAB','IISNGAC','IISNGAE','INDNEUNGA','INDNGA','LNG','NGA','NGA-E' >> TraBatchUpload.sql
echo ,'NGA-E-EU','NGA-E-IRE','NGA-I-EU','NGA-I-N','NGAPTR','PRCNGA','RESNGA','SERNGA','TRACNGL','TRACNGS','TRALNG','TRALNGDS' >> TraBatchUpload.sql
echo ,'TRALNGDSL','TRALNGIS','TRALNGISL','TRANGA','UPSNGA') then 'ALL GAS'  >> TraBatchUpload.sql
echo when commodity in('AGRCOA','COA','COACOK','COA-E','ELCCOA','HYGCOA','INDCOA','INDCOACOK','INDSYNCOA','PRCCOA','PRCCOACOK','RESCOA' >> TraBatchUpload.sql
echo ,'SERCOA','SYNCOA','TRACOA') then 'ALL COALS'  >> TraBatchUpload.sql
echo when commodity in('SERHFO','SERLFO','TRAPETL','OILLFO','TRAJETDA','TRALFO','TRALPGS','ELCMSC','INDLFO','AGRHFO','TRAHFOIS','TRADSTS' >> TraBatchUpload.sql
echo ,'SERKER','TRAJETIANL','RESLFO','RESLPG','TRAHFODSL','TRALFOL','TRAJETIA','TRAJETL','TRAPETS','TRAHFODS','OILJET','OILDST' >> TraBatchUpload.sql
echo ,'AGRLPG','OILCRDRAW-E','UPSLFO','ELCLFO','INDNEULFO','ELCHFO','TRAJETDAEL','SYNOIL','TRADSTL','INDLPG','OILMSC','OILPET' >> TraBatchUpload.sql
echo ,'PRCHFO','OILCRDRAW','TRALFODSL','INDNEULPG','ELCLPG','TRADST','TRALFODS','OILKER','OILHFO','OILCRD','TRALPGL','SERLPG' >> TraBatchUpload.sql
echo ,'INDNEUMSC','PRCOILCRD','INDKER','INDHFO','OILLPG','TRALPG','RESKER','TRAJETIAEL','TRAHFOISL','IISHFOB','TRAPET','INDSYNOIL' >> TraBatchUpload.sql
echo ,'TRAHFO','AGRLFO') then 'ALL OIL PRODUCTS'  >> TraBatchUpload.sql
echo when commodity in('AGRHYG','ELCHYG','ELCHYGIGCC','HYGL','HYGL-IGCC','HYGLHPD','HYGLHPT','HYL','HYLTK','INDHYG','INDMAINSHYG','RESHOUSEHYG' >> TraBatchUpload.sql
echo ,'RESHYG','RESHYGREF-EA','RESHYGREF-NA','RESMAINSHYG','SERBUILDHYG','SERHYG','SERMAINSHYG','TRAHYG','TRAHYGDCN','TRAHYGL','TRAHYGS','TRAHYL' >> TraBatchUpload.sql
echo ,'UPSHYG','UPSMAINSHYG') then 'ALL HYDROGEN'  >> TraBatchUpload.sql
echo when commodity in('WNDONS','GEO','ELCWAV','RESSOL','HYDROR','ELCTID','SERSOL','HYDDAM','TID','ELCSOL','WNDOFF','WAV' >> TraBatchUpload.sql
echo ,'SOL','ELCWNDOFS','ELCGEO','ELCWNDONS','ELCHYDDAM','SERGEO') then 'ALL OTHER RNW'  >> TraBatchUpload.sql
echo end as "analysis", >> TraBatchUpload.sql
echo tablename, attribute >> TraBatchUpload.sql
echo from vedastore >> TraBatchUpload.sql
echo where attribute = 'VAR_FIn' >> TraBatchUpload.sql
echo ) >> TraBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| 'various' ^|^| '^|various'::varchar(300) "id", analysis::varchar(50), tablename,'VAR_FIn' "attribute", >> TraBatchUpload.sql
echo 'various'::varchar(50) "commodity", >> TraBatchUpload.sql
echo 'various'::varchar(50) "process", >> TraBatchUpload.sql
echo sum(pv)::numeric "all", >> TraBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> TraBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> TraBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> TraBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> TraBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> TraBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> TraBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> TraBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> TraBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> TraBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> TraBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> TraBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> TraBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> TraBatchUpload.sql
echo from ( >> TraBatchUpload.sql
echo select process,period,pv, >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when proc='TRA-AVI-INT' then 'int-air-fuel_' >> TraBatchUpload.sql
echo when proc='TRA-SHIP-INT' then 'int-ship-fuel_' >> TraBatchUpload.sql
echo end  >> TraBatchUpload.sql
echo ^|^| >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when analysis='ALL BIO' then 'bio' >> TraBatchUpload.sql
echo when analysis='ALL ELECTRICITY' then 'elc' >> TraBatchUpload.sql
echo when analysis='ALL GAS' then 'gas' >> TraBatchUpload.sql
echo when analysis='ALL COALS' then 'coa' >> TraBatchUpload.sql
echo when analysis='ALL OIL PRODUCTS' then 'oil' >> TraBatchUpload.sql
echo when analysis='ALL HYDROGEN' then 'hyd' >> TraBatchUpload.sql
echo when analysis='ALL OTHER RNW' then 'orens' >> TraBatchUpload.sql
echo end as "analysis", >> TraBatchUpload.sql
echo tablename, attribute >> TraBatchUpload.sql
echo from fuels_in >> TraBatchUpload.sql
echo where analysis ^<^>'' and proc ^<^>'' >> TraBatchUpload.sql
echo ) a >> TraBatchUpload.sql
echo group by id, analysis,tablename >> TraBatchUpload.sql
echo order by tablename, analysis >> TraBatchUpload.sql
echo ) TO '%~dp0fuelByModeOut.csv' delimiter ',' CSV; >> TraBatchUpload.sql
rem /* *Road transport fuel by mode and fuel* */
echo /* *Road transport fuel by mode and fuel* */ >> TraBatchUpload.sql
echo COPY ( >> TraBatchUpload.sql
echo select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|various' ^|^| '^|various'::varchar(300) "id", analysis, tablename,attribute, >> TraBatchUpload.sql
echo 'various'::varchar(50) "commodity", >> TraBatchUpload.sql
echo 'various'::varchar(50) "process", >> TraBatchUpload.sql
echo sum(pv)::numeric "all", >> TraBatchUpload.sql
echo sum(case when period='2010' then pv else 0 end)::numeric "2010", >> TraBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", >> TraBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", >> TraBatchUpload.sql
echo sum(case when period='2015' then pv else 0 end)::numeric "2015", >> TraBatchUpload.sql
echo sum(case when period='2020' then pv else 0 end)::numeric "2020", >> TraBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", >> TraBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", >> TraBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", >> TraBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", >> TraBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", >> TraBatchUpload.sql
echo sum(case when period='2050' then pv else 0 end)::numeric "2050", >> TraBatchUpload.sql
echo sum(case when period='2055' then pv else 0 end)::numeric "2055", >> TraBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" >> TraBatchUpload.sql
echo from ( >> TraBatchUpload.sql
echo select process,period,pv, >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when process like 'TC%%' then 'cars-fuel_' >> TraBatchUpload.sql
echo when process like 'TL%%' then 'lgv-fuel_' >> TraBatchUpload.sql
echo when process like 'TH%%' then 'hgv-fuel_' >> TraBatchUpload.sql
echo when process like 'TB%%' then 'bus-fuel_' >> TraBatchUpload.sql
echo when process like 'TW%%' then 'bike-fuel_' >> TraBatchUpload.sql
echo end ^|^| >> TraBatchUpload.sql
echo case >> TraBatchUpload.sql
echo when commodity in('TRABIODST-FTL','TRABIODST-FTS') then 'sec-gen-biodiesel'  >> TraBatchUpload.sql
echo when commodity in('TRABIODSTL','TRABIODSTS') then 'biodiesel'  >> TraBatchUpload.sql
echo when commodity in('TRACNGL','TRACNGS') then 'cng'  >> TraBatchUpload.sql
echo when commodity in('TRADSTL','TRADSTS') then 'diesel'  >> TraBatchUpload.sql
echo when commodity in('TRACELC','TRACPHB') then 'elc'  >> TraBatchUpload.sql
echo when commodity in('TRAETHS') then 'ethanol'  >> TraBatchUpload.sql
echo when commodity in('TRAHYGL','TRAHYGS') then 'hydrogen'  >> TraBatchUpload.sql
echo when commodity in('TRALPGS') then 'lpg'  >> TraBatchUpload.sql
echo when commodity in('TRAPETS') then 'petrol'  >> TraBatchUpload.sql
echo end as "analysis", >> TraBatchUpload.sql
echo tablename, attribute,commodity >> TraBatchUpload.sql
echo from vedastore >> TraBatchUpload.sql
echo where attribute = 'VAR_FIn' and process like any(array['TC%%','TL%%','TH%%','TB%%','TW%%'])  >> TraBatchUpload.sql
echo ) a >> TraBatchUpload.sql
echo where analysis ^<^>'' >> TraBatchUpload.sql
echo group by id, analysis,tablename, attribute >> TraBatchUpload.sql
echo order by tablename,  analysis, attribute >> TraBatchUpload.sql
echo ) TO '%~dp0rdTransFuel.csv' delimiter ',' CSV; >> TraBatchUpload.sql
rem following line actually runs the SQL code generated by the above using the postgres command utility "psql".
rem Comment this line out if you just want the SQL code to create the populated temp tables + the associated analysis queries:
"C:\Program Files\PostgreSQL\%postgresver%\bin\psql.exe" -h localhost -p 5432 -U postgres -d gams -f %~dp0TraBatchUpload.sql
rem following concatenates individual results to the lulucfout.csv
type newVehKms.csv >> VehKms.csv
type VehCapOut.csv >> VehKms.csv
type nVCapOut.csv >> VehKms.csv
type fuelByModeOut.csv >> VehKms.csv
type rdTransFuel.csv >> VehKms.csv
rem before deleting the individual files and renaming VehKms as TraResultsOut
IF EXIST TraResultsOut.csv del /F TraResultsOut.csv
IF EXIST newVehKms.csv del /F newVehKms.csv
IF EXIST VehCapOut.csv del /F VehCapOut.csv
IF EXIST newVehCapOut.csv del /F newVehCapOut.csv
IF EXIST fuelByModeOut.csv del /F fuelByModeOut.csv
IF EXIST rdTransFuel.csv del /F rdTransFuel.csv
rename VehKms.csv TraResultsOut.csv
rem finally, delete VehKms.csv if it exists
IF EXIST VehKms.csv del /F VehKms.csv