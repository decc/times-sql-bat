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
rem 5:40 PM 15 July, 2016: First version: moved from main batch query
rem ***********
rem The following allows us to insert text which is otherwise outlawed in DOS:
setlocal enableDelayedExpansion
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
echo /* *Whole stock vehicle kms, emissions and emission intensity for 29 vehicle types* */ copy( with base_cng_emissions >> TraBatchUpload.sql
echo as( select tablename, period,'cars-emis_lpg-and-cng-fueled'::varchar "analysis", 'VAR_FOut'::varchar "atttribute", >> TraBatchUpload.sql
echo 'GHG-TRA-NON-ETS-NO-IAS'::varchar "commodity",0::numeric "pv" from vedastore group by tablename, period union select >> TraBatchUpload.sql
echo tablename, period,'hgv-emis_lpg-and-cng-fueled'::varchar "analysis", 'VAR_FOut'::varchar "atttribute", >> TraBatchUpload.sql
echo 'GHG-TRA-NON-ETS-NO-IAS'::varchar "commodity",0::numeric "pv" from vedastore group by tablename, period union select >> TraBatchUpload.sql
echo tablename, period,'lgv-emis_lpg-and-cng-fueled'::varchar "analysis", 'VAR_FOut'::varchar "atttribute", >> TraBatchUpload.sql
echo 'GHG-TRA-NON-ETS-NO-IAS'::varchar "commodity",0::numeric "pv" from vedastore group by tablename, period ) , >> TraBatchUpload.sql
echo cng_emis_shares as( select tablename,period, sum(case when proc_set='cars-cng-in' then pv else 0 end) "cars-cng-in", >> TraBatchUpload.sql
echo sum(case when proc_set='lgv-cng-in' then pv else 0 end) "lgv-cng-in", sum(case when proc_set='hgv-cng-in' then pv >> TraBatchUpload.sql
echo else 0 end) "hgv-cng-in", sum(case when proc_set in('cars-cng-in','lgv-cng-in','hgv-cng-in') then pv else 0 end) >> TraBatchUpload.sql
echo "total_cng_in", sum(case when proc_set='cng-conv-emis' then pv else 0 end) "cng-conv-emis" from ( select >> TraBatchUpload.sql
echo tablename,process,period,pv, case when process = 'TFSSCNG01' and attribute ='VAR_FOut' and commodity >> TraBatchUpload.sql
echo in('GHG-AGR-NO-LULUCF', 'GHG-ELC','GHG-ELC-CAPTURED','GHG-ETS-NET', >> TraBatchUpload.sql
echo 'GHG-ETS-NO-IAS-NET','GHG-ETS-NO-IAS-TER','GHG-ETS-TER','GHG-ETS-YES-IAS-NET', >> TraBatchUpload.sql
echo 'GHG-ETS-YES-IAS-TER','GHG-IAS-ETS','GHG-IAS-NON-ETS','GHG-IND-ETS', >> TraBatchUpload.sql
echo 'GHG-IND-ETS-CAPTURED','GHG-IND-NON-ETS','GHG-IND-NON-ETS-CAPTURED','GHG-LULUCF', >> TraBatchUpload.sql
echo 'GHG-NO-IAS-NO-LULUCF-NET','GHG-NO-IAS-NO-LULUCF-TER', 'GHG-NO-IAS-YES-LULUCF-NET','GHG-NO-IAS-YES-LULUCF-TER', >> TraBatchUpload.sql
echo 'GHG-NON-ETS-NO-LULUCF-NET','GHG-NON-ETS-NO-LULUCF-TER', >> TraBatchUpload.sql
echo 'GHG-NON-ETS-YES-LULUCF-NET','GHG-NON-ETS-YES-LULUCF-TER','GHG-OTHER-ETS', >> TraBatchUpload.sql
echo 'GHG-OTHER-ETS-CAPTURED','GHG-OTHER-NON-ETS','GHG-RES-ETS','GHG-RES-NON-ETS', >> TraBatchUpload.sql
echo 'GHG-SER-ETS','GHG-SER-NON-ETS','GHG-TRA-ETS-NO-IAS','GHG-TRA-NON-ETS-NO-IAS', >> TraBatchUpload.sql
echo 'GHG-YES-IAS-NO-LULUCF-NET','GHG-YES-IAS-NO-LULUCF-TER', 'GHG-YES-IAS-YES-LULUCF-NET','GHG-YES-IAS-YES-LULUCF-TER') >> TraBatchUpload.sql
echo then 'cng-conv-emis' when attribute = 'VAR_FIn' and commodity in('TRACNGS','TRACNGL') then case when process like >> TraBatchUpload.sql
echo 'TC%%' then 'cars-cng-in' when process like 'TL%%' then 'lgv-cng-in' when process like 'TH%%' then 'hgv-cng-in' end end >> TraBatchUpload.sql
echo as "proc_set" from vedastore where (attribute = 'VAR_FIn' or attribute ='VAR_FOut') and commodity >> TraBatchUpload.sql
echo in('TRACNGS','TRACNGL','GHG-AGR-NO-LULUCF', 'GHG-ELC','GHG-ELC-CAPTURED','GHG-ETS-NET', >> TraBatchUpload.sql
echo 'GHG-ETS-NO-IAS-NET','GHG-ETS-NO-IAS-TER','GHG-ETS-TER','GHG-ETS-YES-IAS-NET', >> TraBatchUpload.sql
echo 'GHG-ETS-YES-IAS-TER','GHG-IAS-ETS','GHG-IAS-NON-ETS','GHG-IND-ETS', >> TraBatchUpload.sql
echo 'GHG-IND-ETS-CAPTURED','GHG-IND-NON-ETS','GHG-IND-NON-ETS-CAPTURED','GHG-LULUCF', >> TraBatchUpload.sql
echo 'GHG-NO-IAS-NO-LULUCF-NET','GHG-NO-IAS-NO-LULUCF-TER', 'GHG-NO-IAS-YES-LULUCF-NET','GHG-NO-IAS-YES-LULUCF-TER', >> TraBatchUpload.sql
echo 'GHG-NON-ETS-NO-LULUCF-NET','GHG-NON-ETS-NO-LULUCF-TER', >> TraBatchUpload.sql
echo 'GHG-NON-ETS-YES-LULUCF-NET','GHG-NON-ETS-YES-LULUCF-TER','GHG-OTHER-ETS', >> TraBatchUpload.sql
echo 'GHG-OTHER-ETS-CAPTURED','GHG-OTHER-NON-ETS','GHG-RES-ETS','GHG-RES-NON-ETS', >> TraBatchUpload.sql
echo 'GHG-SER-ETS','GHG-SER-NON-ETS','GHG-TRA-ETS-NO-IAS','GHG-TRA-NON-ETS-NO-IAS', >> TraBatchUpload.sql
echo 'GHG-YES-IAS-NO-LULUCF-NET','GHG-YES-IAS-NO-LULUCF-TER', 'GHG-YES-IAS-YES-LULUCF-NET','GHG-YES-IAS-YES-LULUCF-TER') >> TraBatchUpload.sql
echo and (process = 'TFSSCNG01' or process like any(array['TC%%','TL%%','TH%%','TB%%'])) order by process ) a where proc_set >> TraBatchUpload.sql
echo ^<^>'' group by tablename,period ) , main_crosstab as( select analysis, tablename,attribute,commodity,period,sum(pv) >> TraBatchUpload.sql
echo "pv" from ( select a.tablename, a.analysis, a.period,a.attribute,a.commodity, case when >> TraBatchUpload.sql
echo analysis='cars-emis_lpg-and-cng-fueled' then case when "total_cng_in" ^> 0 then >> TraBatchUpload.sql
echo "cars-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end when analysis='lgv-emis_lpg-and-cng-fueled' then case >> TraBatchUpload.sql
echo when "total_cng_in" ^> 0 then "lgv-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end when >> TraBatchUpload.sql
echo analysis='hgv-emis_lpg-and-cng-fueled' then case when "total_cng_in" ^> 0 then >> TraBatchUpload.sql
echo "hgv-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end else pv end "pv" from ( select tablename, period, >> TraBatchUpload.sql
echo analysis, attribute, commodity,sum(pv) "pv" from ( select tablename, process, period,pv,attribute,commodity, case >> TraBatchUpload.sql
echo when process like 'TC%%' then 'cars-' when process like 'TL%%' then 'lgv-' when process like 'TH%%' then 'hgv-' when >> TraBatchUpload.sql
echo process like 'TB%%' or process='TFSLCNG01' then 'bus-' when process like 'TW%%' then 'bike-' end ^|^| case >> TraBatchUpload.sql
echo when commodity in('TC','TL','TH','TB','TW') then 'km_' when commodity in('GHG-TRA-NON-ETS-NO-IAS') then 'emis_' end >> TraBatchUpload.sql
echo ^|^| case when process in('TBDST00','TBDST01','TCDST00','TCDST01','THDST00','THDST01','TLDST00','TLDST01') then >> TraBatchUpload.sql
echo 'diesel'::varchar(50) when process in('TCE8501','TLE8501') then 'E85'::varchar(50) when process >> TraBatchUpload.sql
echo in('TBELC01','TCELC01','TLELC01','TWELC01') then 'electric'::varchar(50) when process >> TraBatchUpload.sql
echo in('TBFCHBHYG01','TCFCHBHYG01','TCFCHYG01','TCHBE8501','TCHBHYL01','THFCHBHYG01','TLFCHBHYG01','TLFCHYG01','TLHBHYL01','TWFCHYG01') >> TraBatchUpload.sql
echo then 'h2+hybrid'::varchar(50) when process in('TCFCPHBHYG01') then 'h2-plug-in-hybrid'::varchar(50) when process >> TraBatchUpload.sql
echo in('TBHBDST01','TCHBDST01','TCHBPET00','TCHBPET01','THHBDST01','TLHBDST01','TLHBPET01') then 'hybrid'::varchar(50) >> TraBatchUpload.sql
echo when process in('TBCNG01','TCCNG01','TCLPG00','TCLPG01','THCNG01','TLCNG01','TLLPG01','TFSLCNG01') then >> TraBatchUpload.sql
echo 'lpg-and-cng-fueled'::varchar(50) when process in('TCPET00','TCPET01','TLPET00','TLPET01','TWPET00','TWPET01') then >> TraBatchUpload.sql
echo 'petrol'::varchar(50) when process in('TCPHBDST01','TCPHBPET01','TLPHBDST01','TLPHBPET01') then >> TraBatchUpload.sql
echo 'plug-in-hybrid'::varchar(50) end as "analysis" from vedastore where attribute = 'VAR_FOut' and commodity >> TraBatchUpload.sql
echo in('GHG-TRA-NON-ETS-NO-IAS','TB','TC','TH','TL','TW') and (process like any(array['TC%%','TL%%','TB%%','TW%%']) or >> TraBatchUpload.sql
echo process !textc!'!textd!TH[!textd!Y]' or process='TFSLCNG01') ) a where analysis ^<^>'' group by tablename, period, analysis, attribute, >> TraBatchUpload.sql
echo commodity union select * from base_cng_emissions ) a left join cng_emis_shares b on a.tablename=b.tablename and >> TraBatchUpload.sql
echo a.period=b.period ) b group by analysis, tablename,attribute,commodity,period order by tablename, analysis ) select >> TraBatchUpload.sql
echo analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| '^|' ^|^| commodity ^|^| '^|various'::varchar(300) "id", analysis, >> TraBatchUpload.sql
echo tablename,attribute, commodity, 'various'::varchar(50) "process", case when analysis like '%%-inten%%' then >> TraBatchUpload.sql
echo avg(pv)::numeric else sum(pv)::numeric end "all", sum(case when period='2010' then pv else 0 end)::numeric "2010", >> TraBatchUpload.sql
echo sum(case when period='2011' then pv else 0 end)::numeric "2011", sum(case when period='2012' then pv else 0 >> TraBatchUpload.sql
echo end)::numeric "2012", sum(case when period='2015' then pv else 0 end)::numeric "2015", sum(case when period='2020' >> TraBatchUpload.sql
echo then pv else 0 end)::numeric "2020", sum(case when period='2025' then pv else 0 end)::numeric "2025", sum(case when >> TraBatchUpload.sql
echo period='2030' then pv else 0 end)::numeric "2030", sum(case when period='2035' then pv else 0 end)::numeric "2035", >> TraBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", sum(case when period='2045' then pv else 0 >> TraBatchUpload.sql
echo end)::numeric "2045", sum(case when period='2050' then pv else 0 end)::numeric "2050", sum(case when period='2055' >> TraBatchUpload.sql
echo then pv else 0 end)::numeric "2055", sum(case when period='2060' then pv else 0 end)::numeric "2060" from ( select >> TraBatchUpload.sql
echo a.* from main_crosstab a where period^<^>'-' union select left(analysis, position('_' in analysis)) ^|^|'all' >> TraBatchUpload.sql
echo "analysis", tablename, 'VAR_FOut' "attribute", commodity, period,sum(pv) "pv" from main_crosstab where period^<^>'-' >> TraBatchUpload.sql
echo group by left(analysis, position('_' in analysis)), tablename,commodity,period union select left(analysis, >> TraBatchUpload.sql
echo position('-' in analysis))^|^|'emis-inten_all' "analysis", tablename, 'VAR_FOut' "attribute", '-' "commodity", period, >> TraBatchUpload.sql
echo sum(pv) filter(where analysis like '%%-emis%%')/sum(pv) filter(where analysis like '%%-km%%') "pv" from main_crosstab >> TraBatchUpload.sql
echo where period^<^>'-' and period^<^>'2200' group by left(analysis, position('-' in analysis)), tablename,period order by >> TraBatchUpload.sql
echo tablename, period, analysis ) a group by analysis, tablename,attribute,commodity order by tablename, analysis ) TO '%~dp0vehKms.csv' delimiter ',' CSV HEADER; >> TraBatchUpload.sql
rem /* *New stock vehicle kms, emissions and emission intensity for 29 vehicle types* */ 
echo /* *New stock vehicle kms, emissions and emission intensity for 29 vehicle types* */ COPY ( with base_cng_emissions >> TraBatchUpload.sql
echo as( select tablename, period,'cars-new-emis_lpg-and-cng-fueled'::varchar "analysis", 'VAR_FOut'::varchar >> TraBatchUpload.sql
echo "atttribute", 'GHG-TRA-NON-ETS-NO-IAS'::varchar "commodity",0::numeric "pv" from vedastore group by tablename, period >> TraBatchUpload.sql
echo union select tablename, period,'hgv-new-emis_lpg-and-cng-fueled'::varchar "analysis", 'VAR_FOut'::varchar >> TraBatchUpload.sql
echo "atttribute", 'GHG-TRA-NON-ETS-NO-IAS'::varchar "commodity",0::numeric "pv" from vedastore group by tablename, period >> TraBatchUpload.sql
echo union select tablename, period,'lgv-new-emis_lpg-and-cng-fueled'::varchar "analysis", 'VAR_FOut'::varchar >> TraBatchUpload.sql
echo "atttribute", 'GHG-TRA-NON-ETS-NO-IAS'::varchar "commodity",0::numeric "pv" from vedastore group by tablename, period >> TraBatchUpload.sql
echo union select tablename, period,'bus-new-emis_lpg-and-cng-fueled'::varchar "analysis", 'VAR_FOut'::varchar >> TraBatchUpload.sql
echo "atttribute", 'GHG-TRA-NON-ETS-NO-IAS'::varchar "commodity",0::numeric "pv" from vedastore group by tablename, period >> TraBatchUpload.sql
echo ) , cng_emis_shares as( select tablename,period, sum(case when proc_set='cars-new-cng-in' then pv else 0 end) >> TraBatchUpload.sql
echo "cars-new-cng-in", sum(case when proc_set='lgv-new-cng-in' then pv else 0 end) "lgv-new-cng-in", sum(case when >> TraBatchUpload.sql
echo proc_set='hgv-new-cng-in' then pv else 0 end) "hgv-new-cng-in", sum(case when proc_set >> TraBatchUpload.sql
echo in('cars-new-cng-in','lgv-new-cng-in','hgv-new-cng-in','older-veh-cng-in') then pv else 0 end) "total_cng_in", >> TraBatchUpload.sql
echo sum(case when proc_set='cng-conv-emis' then pv else 0 end) "cng-conv-emis", sum(case when proc_set='bus-new-cng-in' >> TraBatchUpload.sql
echo then pv else 0 end) "bus-new-cng-in", sum(case when proc_set in('bus-new-cng-in','older-bus-cng-in') then pv else 0 >> TraBatchUpload.sql
echo end) "total_bus_cng_in", sum(case when proc_set='bus-cng-conv-emis' then pv else 0 end) "bus-cng-conv-emis" from ( >> TraBatchUpload.sql
echo select tablename,process,period,pv, case when process = 'TFSSCNG01' and attribute ='VAR_FOut' and commodity >> TraBatchUpload.sql
echo in('GHG-TRA-NON-ETS-NO-IAS') then 'cng-conv-emis' when process = 'TFSLCNG01' and attribute ='VAR_FOut' and >> TraBatchUpload.sql
echo commodity='GHG-TRA-NON-ETS-NO-IAS' then 'bus-cng-conv-emis' when attribute = 'VAR_FIn' and commodity >> TraBatchUpload.sql
echo in('TRACNGS','TRACNGL') then case when process like 'TC%%' and vintage=period then 'cars-new-cng-in' when process >> TraBatchUpload.sql
echo like 'TL%%' and vintage=period then 'lgv-new-cng-in' when process like 'TH%%' and vintage=period then 'hgv-new-cng-in' >> TraBatchUpload.sql
echo when process like any(array['TC%%','TL%%','TH%%']) and vintage^<^>period then 'older-veh-cng-in' when process like 'TB%%' >> TraBatchUpload.sql
echo and vintage=period then 'bus-new-cng-in' when process like 'TB%%' and vintage^<^>period then 'older-bus-cng-in' end end >> TraBatchUpload.sql
echo as "proc_set" from vedastore order by process ) a where proc_set ^<^>'' group by tablename,period ) , main_crosstab as( >> TraBatchUpload.sql
echo select analysis, tablename,attribute,commodity,period,sum(pv) "pv" from ( select a.tablename, a.analysis, >> TraBatchUpload.sql
echo a.period,a.attribute,a.commodity, case when analysis='cars-new-emis_lpg-and-cng-fueled' then case when >> TraBatchUpload.sql
echo "total_cng_in" ^> 0 then "cars-new-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end when >> TraBatchUpload.sql
echo analysis='lgv-new-emis_lpg-and-cng-fueled' then case when "total_cng_in" ^> 0 then >> TraBatchUpload.sql
echo "lgv-new-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end when analysis='hgv-new-emis_lpg-and-cng-fueled' then >> TraBatchUpload.sql
echo case when "total_cng_in" ^> 0 then "hgv-new-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end when >> TraBatchUpload.sql
echo analysis='bus-new-emis_lpg-and-cng-fueled' then case when "total_bus_cng_in" ^> 0 then >> TraBatchUpload.sql
echo "bus-new-cng-in"/"total_bus_cng_in"*"bus-cng-conv-emis" + pv else pv end else pv end "pv" from ( >> TraBatchUpload.sql
echo select tablename, period, analysis, attribute, commodity,sum(pv) "pv" from ( select tablename, process, >> TraBatchUpload.sql
echo period,pv,attribute,commodity, case when process like 'TC%%' then 'cars-new-' when process like 'TL%%' then 'lgv-new-' >> TraBatchUpload.sql
echo when process like 'TH%%' then 'hgv-new-' when process like 'TB%%' then 'bus-new-' when process like 'TW%%' then >> TraBatchUpload.sql
echo 'bike-new-' end ^|^| case when commodity in('TC','TL','TH','TB','TW') then 'km_' when commodity >> TraBatchUpload.sql
echo in('GHG-TRA-NON-ETS-NO-IAS') then 'emis_' end ^|^| case when process >> TraBatchUpload.sql
echo in('TBDST00','TBDST01','TCDST00','TCDST01','THDST00','THDST01','TLDST00','TLDST01') then 'diesel'::varchar(50) when >> TraBatchUpload.sql
echo process in('TCE8501','TLE8501') then 'E85'::varchar(50) when process in('TBELC01','TCELC01','TLELC01','TWELC01') then >> TraBatchUpload.sql
echo 'electric'::varchar(50) when process >> TraBatchUpload.sql
echo in('TBFCHBHYG01','TCFCHBHYG01','TCFCHYG01','TCHBE8501','TCHBHYL01','THFCHBHYG01','TLFCHBHYG01','TLFCHYG01','TLHBHYL01','TWFCHYG01') >> TraBatchUpload.sql
echo then 'h2+hybrid'::varchar(50) when process in('TCFCPHBHYG01') then 'h2-plug-in-hybrid'::varchar(50) when process >> TraBatchUpload.sql
echo in('TBHBDST01','TCHBDST01','TCHBPET00','TCHBPET01','THHBDST01','TLHBDST01','TLHBPET01') then 'hybrid'::varchar(50) >> TraBatchUpload.sql
echo when process in('TBCNG01','TCCNG01','TCLPG00','TCLPG01','THCNG01','TLCNG01','TLLPG01') then >> TraBatchUpload.sql
echo 'lpg-and-cng-fueled'::varchar(50) when process >> TraBatchUpload.sql
echo in('TCPET00','TCPET01','TLPET00','TLPET01','TWPET00','TWPET01','TWPET01') then 'petrol'::varchar(50) when process >> TraBatchUpload.sql
echo in('TCPHBDST01','TCPHBPET01','TLPHBDST01','TLPHBPET01') then 'plug-in-hybrid'::varchar(50) end as "analysis" from >> TraBatchUpload.sql
echo vedastore where attribute = 'VAR_FOut' and commodity in('TC','TL','TH','TW','TB','GHG-TRA-NON-ETS-NO-IAS') and >> TraBatchUpload.sql
echo (process like any(array['TC%%','TL%%','TB%%','TW%%']) or process !textc!'!textd!TH[!textd!Y]') and vintage=period and process like '%%01' ) >> TraBatchUpload.sql
echo a where analysis ^<^>'' group by tablename, period, analysis, attribute, commodity union select * from >> TraBatchUpload.sql
echo base_cng_emissions ) a left join cng_emis_shares b on a.tablename=b.tablename and a.period=b.period ) b group by >> TraBatchUpload.sql
echo analysis, tablename,attribute,commodity,period order by tablename, analysis ) select analysis ^|^| '^|' ^|^| tablename ^|^| >> TraBatchUpload.sql
echo '^|' ^|^| attribute ^|^| '^|' ^|^| commodity ^|^| '^|various'::varchar(300) "id", analysis, tablename,attribute, commodity, >> TraBatchUpload.sql
echo 'various'::varchar(50) "process", case when analysis like '%%-inten%%' then avg(pv)::numeric else sum(pv)::numeric end >> TraBatchUpload.sql
echo "all", sum(case when period='2010' then pv else 0 end)::numeric "2010", sum(case when period='2011' then pv else 0 >> TraBatchUpload.sql
echo end)::numeric "2011", sum(case when period='2012' then pv else 0 end)::numeric "2012", sum(case when period='2015' >> TraBatchUpload.sql
echo then pv else 0 end)::numeric "2015", sum(case when period='2020' then pv else 0 end)::numeric "2020", sum(case when >> TraBatchUpload.sql
echo period='2025' then pv else 0 end)::numeric "2025", sum(case when period='2030' then pv else 0 end)::numeric "2030", >> TraBatchUpload.sql
echo sum(case when period='2035' then pv else 0 end)::numeric "2035", sum(case when period='2040' then pv else 0 >> TraBatchUpload.sql
echo end)::numeric "2040", sum(case when period='2045' then pv else 0 end)::numeric "2045", sum(case when period='2050' >> TraBatchUpload.sql
echo then pv else 0 end)::numeric "2050", sum(case when period='2055' then pv else 0 end)::numeric "2055", sum(case when >> TraBatchUpload.sql
echo period='2060' then pv else 0 end)::numeric "2060" from ( select a.* from main_crosstab a where period^<^>'-' union >> TraBatchUpload.sql
echo select left(analysis, position('_' in analysis)) ^|^|'all' "analysis", tablename, 'VAR_FOut' "attribute", commodity, >> TraBatchUpload.sql
echo period,sum(pv) "pv" from main_crosstab where period^<^>'-' group by left(analysis, position('_' in analysis)), >> TraBatchUpload.sql
echo tablename,commodity,period union select left(analysis, position('-' in analysis))^|^|'new-emis-inten_all' "analysis", >> TraBatchUpload.sql
echo tablename, 'VAR_FOut' "attribute", '-' "commodity", period, sum(pv) filter(where analysis like '%%-emis%%')/sum(pv) >> TraBatchUpload.sql
echo filter(where analysis like '%%-km%%') "pv" from main_crosstab where period^<^>'-' and period^<^>'2200' group by >> TraBatchUpload.sql
echo left(analysis, position('-' in analysis)), tablename,period order by tablename, period, analysis ) a group by >> TraBatchUpload.sql
echo analysis, tablename,attribute,commodity order by tablename, analysis ) TO '%~dp0newVehKms.csv' delimiter ',' CSV; >> TraBatchUpload.sql
rem /* *Whole stock capacity for vehicles for 29 vehicle types* */ 
echo /* *Whole stock capacity for vehicles for 29 vehicle types* */ COPY ( select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| >> TraBatchUpload.sql
echo attribute ^|^| '^|' ^|^| commodity ^|^| '^|various'::varchar(300) "id", analysis, tablename,attribute, commodity, >> TraBatchUpload.sql
echo 'various'::varchar(50) "process", sum(pv)::numeric "all", sum(case when period='2010' then pv else 0 end)::numeric >> TraBatchUpload.sql
echo "2010", sum(case when period='2011' then pv else 0 end)::numeric "2011", sum(case when period='2012' then pv else 0 >> TraBatchUpload.sql
echo end)::numeric "2012", sum(case when period='2015' then pv else 0 end)::numeric "2015", sum(case when period='2020' >> TraBatchUpload.sql
echo then pv else 0 end)::numeric "2020", sum(case when period='2025' then pv else 0 end)::numeric "2025", sum(case when >> TraBatchUpload.sql
echo period='2030' then pv else 0 end)::numeric "2030", sum(case when period='2035' then pv else 0 end)::numeric "2035", >> TraBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", sum(case when period='2045' then pv else 0 >> TraBatchUpload.sql
echo end)::numeric "2045", sum(case when period='2050' then pv else 0 end)::numeric "2050", sum(case when period='2055' >> TraBatchUpload.sql
echo then pv else 0 end)::numeric "2055", sum(case when period='2060' then pv else 0 end)::numeric "2060" from ( select >> TraBatchUpload.sql
echo process,period,pv, case when process like 'TC%%' then 'cars-cap_' when process like 'TL%%' then 'lgv-cap_' when >> TraBatchUpload.sql
echo process like 'TH%%' then 'hgv-cap_' when process like 'TB%%' then 'bus-cap_' when process like 'TW%%' then 'bike-cap_' >> TraBatchUpload.sql
echo end ^|^| case when process in('TBDST00','TBDST01','TCDST00','TCDST01','THDST00','THDST01','TLDST00','TLDST01') then >> TraBatchUpload.sql
echo 'diesel'::varchar(50) when process in('TCE8501','TLE8501') then 'E85'::varchar(50) when process >> TraBatchUpload.sql
echo in('TBELC01','TCELC01','TLELC01','TWELC01') then 'electric'::varchar(50) when process >> TraBatchUpload.sql
echo in('TBFCHBHYG01','TCFCHBHYG01','TCFCHYG01','TCHBE8501','TCHBHYL01','THFCHBHYG01','TLFCHBHYG01','TLFCHYG01','TLHBHYL01','TWFCHYG01') >> TraBatchUpload.sql
echo then 'h2+hybrid'::varchar(50) when process in('TCFCPHBHYG01') then 'h2-plug-in-hybrid'::varchar(50) when process >> TraBatchUpload.sql
echo in('TBHBDST01','TCHBDST01','TCHBPET00','TCHBPET01','THHBDST01','TLHBDST01','TLHBPET01') then 'hybrid'::varchar(50) >> TraBatchUpload.sql
echo when process in('TBCNG01','TCCNG01','TCLPG00','TCLPG01','THCNG01','TLCNG01','TLLPG01') then >> TraBatchUpload.sql
echo 'lpg-and-cng-fueled'::varchar(50) when process in('TCPET00','TCPET01','TLPET00','TLPET01','TWPET00','TWPET01') then >> TraBatchUpload.sql
echo 'petrol'::varchar(50) when process in('TCPHBDST01','TCPHBPET01','TLPHBDST01','TLPHBPET01') then >> TraBatchUpload.sql
echo 'plug-in-hybrid'::varchar(50) end as "analysis", tablename, attribute,commodity from vedastore where attribute = >> TraBatchUpload.sql
echo 'VAR_Cap' and process like any(array['TC%%','TL%%','TH%%','TB%%','TW%%']) ) a where analysis ^<^>'' group by id, >> TraBatchUpload.sql
echo analysis,tablename, attribute, commodity order by tablename, analysis, attribute, commodity ) TO >> TraBatchUpload.sql
echo '%~dp0VehCapOut.csv' delimiter ',' CSV; >> TraBatchUpload.sql
rem /* *New build capacity for vehicles for 29 vehicle types* */ 
echo /* *New build capacity for vehicles for 29 vehicle types* */ COPY ( select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| >> TraBatchUpload.sql
echo attribute ^|^| '^|' ^|^| commodity ^|^| '^|various'::varchar(300) "id", analysis, tablename,attribute, commodity, >> TraBatchUpload.sql
echo 'various'::varchar(50) "process", sum(pv)::numeric "all", sum(case when period='2010' then pv else 0 end)::numeric >> TraBatchUpload.sql
echo "2010", sum(case when period='2011' then pv else 0 end)::numeric "2011", sum(case when period='2012' then pv else 0 >> TraBatchUpload.sql
echo end)::numeric "2012", sum(case when period='2015' then pv else 0 end)::numeric "2015", sum(case when period='2020' >> TraBatchUpload.sql
echo then pv else 0 end)::numeric "2020", sum(case when period='2025' then pv else 0 end)::numeric "2025", sum(case when >> TraBatchUpload.sql
echo period='2030' then pv else 0 end)::numeric "2030", sum(case when period='2035' then pv else 0 end)::numeric "2035", >> TraBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", sum(case when period='2045' then pv else 0 >> TraBatchUpload.sql
echo end)::numeric "2045", sum(case when period='2050' then pv else 0 end)::numeric "2050", sum(case when period='2055' >> TraBatchUpload.sql
echo then pv else 0 end)::numeric "2055", sum(case when period='2060' then pv else 0 end)::numeric "2060" from ( select >> TraBatchUpload.sql
echo process,period,pv, case when process like 'TC%%' then 'cars-new-cap_' when process like 'TL%%' then 'lgv-new-cap_' when >> TraBatchUpload.sql
echo process like 'TH%%' then 'hgv-new-cap_' when process like 'TB%%' then 'bus-new-cap_' when process like 'TW%%' then 'bike-new-cap_' >> TraBatchUpload.sql
echo end ^|^| case when process in('TBDST00','TBDST01','TCDST00','TCDST01','THDST00','THDST01','TLDST00','TLDST01') then >> TraBatchUpload.sql
echo 'diesel'::varchar(50) when process in('TCE8501','TLE8501') then 'E85'::varchar(50) when process >> TraBatchUpload.sql
echo in('TBELC01','TCELC01','TLELC01','TWELC01') then 'electric'::varchar(50) when process >> TraBatchUpload.sql
echo in('TBFCHBHYG01','TCFCHBHYG01','TCFCHYG01','TCHBE8501','TCHBHYL01','THFCHBHYG01','TLFCHBHYG01','TLFCHYG01','TLHBHYL01','TWFCHYG01') >> TraBatchUpload.sql
echo then 'h2+hybrid'::varchar(50) when process in('TCFCPHBHYG01') then 'h2-plug-in-hybrid'::varchar(50) when process >> TraBatchUpload.sql
echo in('TBHBDST01','TCHBDST01','TCHBPET00','TCHBPET01','THHBDST01','TLHBDST01','TLHBPET01') then 'hybrid'::varchar(50) >> TraBatchUpload.sql
echo when process in('TBCNG01','TCCNG01','TCLPG00','TCLPG01','THCNG01','TLCNG01','TLLPG01') then >> TraBatchUpload.sql
echo 'lpg-and-cng-fueled'::varchar(50) when process in('TCPET00','TCPET01','TLPET00','TLPET01','TWPET00','TWPET01') then >> TraBatchUpload.sql
echo 'petrol'::varchar(50) when process in('TCPHBDST01','TCPHBPET01','TLPHBDST01','TLPHBPET01') then >> TraBatchUpload.sql
echo 'plug-in-hybrid'::varchar(50) end as "analysis", tablename, attribute,commodity from vedastore where attribute = >> TraBatchUpload.sql
echo 'VAR_Ncap' and process like any(array['TC%%','TL%%','TH%%','TB%%','TW%%']) ) a where analysis ^<^>'' group by id, >> TraBatchUpload.sql
echo analysis,tablename, attribute, commodity order by tablename, analysis, attribute, commodity ) TO >> TraBatchUpload.sql
echo '%~dp0nVCapOut.csv' delimiter ',' CSV; >> TraBatchUpload.sql
rem following line actually runs the SQL code generated by the above using the postgres command utility "psql".
rem Comment this line out if you just want the SQL code to create the populated temp tables + the associated analysis queries:
"C:\Program Files\PostgreSQL\9.4\bin\psql.exe" -h localhost -p 5432 -U postgres -d gams -f %~dp0TraBatchUpload.sql
rem following concatenates individual results to the lulucfout.csv
type newVehKms.csv >> VehKms.csv
type VehCapOut.csv >> VehKms.csv
type nVCapOut.csv >> VehKms.csv
rem before deleting the individual files and renaming VehKms as TraResultsOut
IF EXIST TraResultsOut.csv del /F TraResultsOut.csv
IF EXIST newVehKms.csv del /F newVehKms.csv
IF EXIST VehCapOut.csv del /F VehCapOut.csv
IF EXIST nVCapOut.csv del /F nVCapOut.csv
rename VehKms.csv TraResultsOut.csv
rem finally, delete VehKms.csv if it exists
IF EXIST VehKms.csv del /F VehKms.csv
