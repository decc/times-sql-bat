rem *****UK TIMES standard outputs tool*****
rem DOS Batch file to construct SQL queries, run the code, amalgamate the results and tidy up (delete) the intermediate stages
rem version as filename. By Fernley Symons 8:02 PM 12 January, 2016
rem works by: 
rem 1) constructing SQL code file to create temp files from TIMES runs (creates one script entry for each file)
rem 2) adding analysis SQL to generate summaries which are output to CSVs
rem 3) amalgamates the CSVs
rem 4) deletes the intermediate CSVs leaving a single output file
rem By Fernley Symons
rem ***********
rem 9:34 PM 19 January, 2016 Correction of error in new vehicles capacity script
rem 2:04 PM 01 February, 2016; addition of whole vehicle stock capacity
rem 2:58 PM 04 February, 2016; addition of new vehicle emissions intensity
rem 1:39 PM 08 February, 2016; correction of new vehicle emissions intensity
rem 3:30 PM 16 February, 2016; a slew of new queries, refactored code, re-ordered queries. Baseline version for git:-replaces v18
rem 7:50 PM 04 April, 2016: addition of final end use energy demand by main sector; renamed some analysis entities
rem 1:48 PM 12 April, 2016: addition of primary energy demand by main fuel
rem ***********
rem The following allows us to insert text which is otherwise outlawed in DOS:
setlocal enableDelayedExpansion
rem Things to bear in mind:
rem if '%' is part of a sql query (e.g. "like 'x%'), then % needs to be doubled "like 'x%%'"
rem Other characters (|, <, > etc) need to be escaped in a similar way with ^:- ^| etc
rem can't have very long lines - need to break statements
rem filename at end of line, no spaces afterwards
REM Also note that doesn't like labels (col names or values etc) which break across lines. Inserts a break into them so that they don't match any more
rem delete the SQL script if it exists - code below (re-) generates it.
IF EXIST VedaBatchUpload.sql del /F VedaBatchUpload.sql
rem need to define some variables which contain DOS reserved words. These are replaced by the preprocessor in the script:
set "texta=IF"
set "textb=IF NOT"
set "textc=~"
set "textd=^"
set "texte=&"
rem this block creates the 2 temp table definitions. First stores the unformatted data from the VD file, second parses this into fields and inserts into the "vedastore" table against which the 
rem queries are run.
echo CREATE temp TABLE !textb! EXISTS vedastore( tablename varchar(100), id serial, attribute varchar(50), commodity varchar(50), process varchar(50), period varchar(50), region varchar(50), vintage varchar(50), timeslice varchar(50), userconstraint varchar(50), pv numeric ); drop table !texta! exists veda; create temp table veda( id serial, stuff varchar(1000) ); >> VedaBatchUpload.sql
rem the following creates a block of sql for each VD file to upload it, delete the header rows and break the entries into fields
for /f "delims=|" %%i in ('dir /b *.vd') do echo delete from veda; ALTER SEQUENCE veda_id_seq RESTART WITH 1; copy veda (stuff) from '%%~fi'; insert into vedastore (tablename, attribute ,commodity ,process ,period ,region ,vintage ,timeslice ,userconstraint ,pv) select '%%~ni', trim(both '"' from a[1]), trim(both '"' from a[2]), trim(both '"' from a[3]), trim(both '"' from a[4]), trim(both '"' from a[5]), trim(both '"' from a[6]), trim(both '"' from a[7]), trim(both '"' from a[8]), cast(a[9] as numeric) from ( select string_to_array(stuff, ',') from veda order by id offset 13 ) as dt(a); >> VedaBatchUpload.sql
rem /* *Dummy imports by table* */
echo /* *Dummy imports by table* */ COPY ( select 'dummies' ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| 'Cost_Act' ^|^| >> VedaBatchUpload.sql
echo '^|' ^|^| 'various' ^|^| '^|various'::varchar(300) "id", 'dummies'::varchar(300) "analysis", tablename, >> VedaBatchUpload.sql
echo 'Cost_Act'::varchar(50) "attribute", 'various'::varchar(50) "commodity", 'various'::varchar(50) "process", >> VedaBatchUpload.sql
echo sum(pv)::numeric "all", sum(case when period='2010' then pv else 0 end)::numeric "2010", sum(case when period='2011' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2011", sum(case when period='2012' then pv else 0 end)::numeric "2012", sum(case when >> VedaBatchUpload.sql
echo period='2015' then pv else 0 end)::numeric "2015", sum(case when period='2020' then pv else 0 end)::numeric "2020", >> VedaBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", sum(case when period='2030' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2030", sum(case when period='2035' then pv else 0 end)::numeric "2035", sum(case when period='2040' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2040", sum(case when period='2045' then pv else 0 end)::numeric "2045", sum(case when >> VedaBatchUpload.sql
echo period='2050' then pv else 0 end)::numeric "2050", sum(case when period='2055' then pv else 0 end)::numeric "2055", >> VedaBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" from vedastore where process in('IMPDEMZ','IMPMATZ', >> VedaBatchUpload.sql
echo 'IMPNRGZ') and attribute = 'Cost_Act' group by tablename order by tablename, analysis ) TO '%~dp0dummiesout.csv' >> VedaBatchUpload.sql
echo delimiter ',' CSV >> VedaBatchUpload.sql
echo HEADER; >> VedaBatchUpload.sql
rem /* *All GHG emissions* */
echo /* *All GHG emissions* */ COPY ( select 'ghg_all^|' ^|^| tablename ^|^| '^|Var_FOut^|' ^|^| commodity ^|^| >> VedaBatchUpload.sql
echo '^|all'::varchar(300) "id", 'ghg_all'::varchar(50) "analysis", tablename, 'Var_FOut'::varchar(50) "attribute", >> VedaBatchUpload.sql
echo commodity, 'all'::varchar(50) "process", sum(pv)::numeric "all", sum(case when period='2010' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2010", sum(case when period='2011' then pv else 0 end)::numeric "2011", sum(case when period='2012' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2012", sum(case when period='2015' then pv else 0 end)::numeric "2015", sum(case when >> VedaBatchUpload.sql
echo period='2020' then pv else 0 end)::numeric "2020", sum(case when period='2025' then pv else 0 end)::numeric "2025", >> VedaBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", sum(case when period='2035' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2035", sum(case when period='2040' then pv else 0 end)::numeric "2040", sum(case when period='2045' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2045", sum(case when period='2050' then pv else 0 end)::numeric "2050", sum(case when >> VedaBatchUpload.sql
echo period='2055' then pv else 0 end)::numeric "2055", sum(case when period='2060' then pv else 0 end)::numeric "2060" >> VedaBatchUpload.sql
echo from vedastore where attribute='VAR_FOut' and commodity in('GHG-ETS-NO-IAS-NET','GHG-ETS-NO-IAS-TER', >> VedaBatchUpload.sql
echo 'GHG-ETS-YES-IAS-NET','GHG-ETS-YES-IAS-TER', 'GHG-NO-IAS-YES-LULUCF-NET','GHG-NO-IAS-YES-LULUCF-TER', >> VedaBatchUpload.sql
echo 'GHG-NON-ETS-YES-LULUCF-NET','GHG-NON-ETS-YES-LULUCF-TER', 'GHG-YES-IAS-YES-LULUCF-NET','GHG-YES-IAS-YES-LULUCF-TER') >> VedaBatchUpload.sql
echo group by tablename, commodity order by tablename, commodity ) TO '%~dp0GHGOut.csv' delimiter ',' >> VedaBatchUpload.sql
echo CSV; >> VedaBatchUpload.sql
rem /* *GHG emissions by sector* */
echo /* *GHG emissions by sector* */ COPY ( select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute ^|^| >> VedaBatchUpload.sql
echo '^|' ^|^| commodity ^|^| '^|' ^|^| process::varchar(300) "id", analysis, tablename,attribute, commodity, process, >> VedaBatchUpload.sql
echo sum(pv)::numeric "all", sum(case when period='2010' then pv else 0 end)::numeric "2010", sum(case when period='2011' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2011", sum(case when period='2012' then pv else 0 end)::numeric "2012", sum(case when >> VedaBatchUpload.sql
echo period='2015' then pv else 0 end)::numeric "2015", sum(case when period='2020' then pv else 0 end)::numeric "2020", >> VedaBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", sum(case when period='2030' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2030", sum(case when period='2035' then pv else 0 end)::numeric "2035", sum(case when period='2040' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2040", sum(case when period='2045' then pv else 0 end)::numeric "2045", sum(case when >> VedaBatchUpload.sql
echo period='2050' then pv else 0 end)::numeric "2050", sum(case when period='2055' then pv else 0 end)::numeric "2055", >> VedaBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" from ( select 'all'::varchar(50) "process", period, >> VedaBatchUpload.sql
echo case when attribute='VAR_FIn' and commodity='Traded-Emission-ETS' then -pv else pv end as pv, tablename, case when >> VedaBatchUpload.sql
echo commodity='Traded-Emission-ETS' then 'various' else attribute end as attribute, case when commodity in('PRCCO2P', >> VedaBatchUpload.sql
echo 'PRCCH4N', 'PRCCH4P', 'PRCN2ON', 'PRCN2OP') then 'various' else commodity end as "commodity", case when >> VedaBatchUpload.sql
echo commodity='Traded-Emission-ETS' then 'ghg_sec-traded-emis-ets' when commodity in('GHG-ELC','GHG-IND-ETS', >> VedaBatchUpload.sql
echo 'GHG-RES-ETS','GHG-SER-ETS','GHG-OTHER-ETS','GHG-TRA-ETS-NO-IAS','GHG-IAS-ETS', 'GHG-IAS-NON-ETS','GHG-IND-NON-ETS', >> VedaBatchUpload.sql
echo 'GHG-RES-NON-ETS','GHG-SER-NON-ETS','GHG-TRA-NON-ETS-NO-IAS', 'GHG-AGR-NO-LULUCF','GHG-OTHER-NON-ETS','GHG-LULUCF', >> VedaBatchUpload.sql
echo 'Traded-Emission-Non-ETS','GHG-ELC-CAPTURED','GHG-IND-ETS-CAPTURED', 'GHG-IND-NON-ETS-CAPTURED', >> VedaBatchUpload.sql
echo 'GHG-OTHER-ETS-CAPTURED') then 'ghg_sec-main-secs' when commodity in('PRCCO2P', 'PRCCH4N', 'PRCCH4P', 'PRCN2ON', >> VedaBatchUpload.sql
echo 'PRCN2OP') then 'ghg_sec-prc-non-ets' when commodity ='PRCCO2N' then 'ghg_sec-prc-ets' end as "analysis" from >> VedaBatchUpload.sql
echo vedastore where (attribute='VAR_FOut' and commodity in('GHG-ELC','GHG-IND-ETS','GHG-RES-ETS','GHG-SER-ETS', >> VedaBatchUpload.sql
echo 'GHG-OTHER-ETS', 'GHG-TRA-ETS-NO-IAS','GHG-IAS-ETS','GHG-IAS-NON-ETS','Traded-Emission-ETS','GHG-IND-NON-ETS', >> VedaBatchUpload.sql
echo 'GHG-RES-NON-ETS', 'GHG-SER-NON-ETS','GHG-TRA-NON-ETS-NO-IAS','GHG-AGR-NO-LULUCF','GHG-OTHER-NON-ETS','GHG-LULUCF', >> VedaBatchUpload.sql
echo 'Traded-Emission-Non-ETS','GHG-ELC-CAPTURED','GHG-IND-ETS-CAPTURED','GHG-IND-NON-ETS-CAPTURED', >> VedaBatchUpload.sql
echo 'GHG-OTHER-ETS-CAPTURED','PRCCO2P','PRCCH4N','PRCCH4P','PRCN2ON','PRCN2OP', 'PRCCO2N')) or (attribute='VAR_FIn' and >> VedaBatchUpload.sql
echo commodity='Traded-Emission-ETS') order by period ) a where analysis ^<^>'' group by id, analysis,tablename, attribute, >> VedaBatchUpload.sql
echo commodity,process order by tablename, analysis, attribute, commodity ) TO '%~dp0GHGsectorOut.csv' delimiter ',' >> VedaBatchUpload.sql
echo CSV; >> VedaBatchUpload.sql
rem /* *GHG and sequestered emissions by industry sub-sector* */
echo /* *GHG and sequestered emissions by industry sub-sector* */ COPY ( select 'ghg_ind-subsec-'^|^|sector ^|^| '^|' >> VedaBatchUpload.sql
echo ^|^| tablename ^|^| '^|' ^|^| 'VAR_FOut' ^|^| '^|' ^|^| 'various' ^|^| '^|various'::varchar(300) "id", >> VedaBatchUpload.sql
echo 'ghg_ind-subsec-'^|^|sector::varchar(300) "analysis", tablename, 'VAR_Fout'::varchar(50) "attribute", >> VedaBatchUpload.sql
echo 'various'::varchar(50) "commodity", 'various'::varchar(50) "process", sum(pv)::numeric "all", sum(case when >> VedaBatchUpload.sql
echo period='2010' then pv else 0 end)::numeric "2010", sum(case when period='2011' then pv else 0 end)::numeric "2011", >> VedaBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", sum(case when period='2015' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2015", sum(case when period='2020' then pv else 0 end)::numeric "2020", sum(case when period='2025' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2025", sum(case when period='2030' then pv else 0 end)::numeric "2030", sum(case when >> VedaBatchUpload.sql
echo period='2035' then pv else 0 end)::numeric "2035", sum(case when period='2040' then pv else 0 end)::numeric "2040", >> VedaBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", sum(case when period='2050' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2050", sum(case when period='2055' then pv else 0 end)::numeric "2055", sum(case when period='2060' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2060" from( select tablename, case when left(process,3)='ICH' then 'ich' when >> VedaBatchUpload.sql
echo left(process,3)='ICM' then 'icm' when left(process,3)='IFD' then 'ifd' when left(process,3)='IIS' then 'iis' when >> VedaBatchUpload.sql
echo left(process,3)='INF' then 'inf' when left(process,3)='INM' then 'inm' when left(process,3)='IOI' or process like >> VedaBatchUpload.sql
echo 'INDHFCOTH0%%' then 'ioi' when left(process,3)='IPP' then 'ipp' when process='-' then 'other' else null end "sector", >> VedaBatchUpload.sql
echo period, sum(case when commodity in('SKNINDCO2N','SKNINDCO2P') then -pv else pv end) "pv" from vedastore where >> VedaBatchUpload.sql
echo commodity in ('SKNINDCO2N','SKNINDCO2P','INDCO2N','INDCO2P','INDNEUCO2N','INDCH4N','INDN2ON','INDHFCP') and >> VedaBatchUpload.sql
echo attribute='VAR_FOut' group by tablename, sector,period ) a where sector is not null group by tablename, sector union >> VedaBatchUpload.sql
echo all select 'ghgseq_ind-subsec-'^|^|sector ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| 'VAR_FOut' ^|^| '^|' ^|^| 'various' >> VedaBatchUpload.sql
echo ^|^| '^|various'::varchar(300) "id", 'ghgseq_ind-subsec-'^|^|sector::varchar(300) "analysis", tablename, >> VedaBatchUpload.sql
echo 'VAR_Fout'::varchar(50) "attribute", 'various'::varchar(50) "commodity", 'various'::varchar(50) "process", >> VedaBatchUpload.sql
echo sum(pv)::numeric "all", sum(case when period='2010' then pv else 0 end)::numeric "2010", sum(case when period='2011' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2011", sum(case when period='2012' then pv else 0 end)::numeric "2012", sum(case when >> VedaBatchUpload.sql
echo period='2015' then pv else 0 end)::numeric "2015", sum(case when period='2020' then pv else 0 end)::numeric "2020", >> VedaBatchUpload.sql
echo sum(case when period='2025' then pv else 0 end)::numeric "2025", sum(case when period='2030' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2030", sum(case when period='2035' then pv else 0 end)::numeric "2035", sum(case when period='2040' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2040", sum(case when period='2045' then pv else 0 end)::numeric "2045", sum(case when >> VedaBatchUpload.sql
echo period='2050' then pv else 0 end)::numeric "2050", sum(case when period='2055' then pv else 0 end)::numeric "2055", >> VedaBatchUpload.sql
echo sum(case when period='2060' then pv else 0 end)::numeric "2060" from( select tablename, case when left(process, >> VedaBatchUpload.sql
echo 3)='ICH' then 'ich' when left(process,3)='ICM' then 'icm' when left(process,3)='IFD' then 'ifd' when left(process, >> VedaBatchUpload.sql
echo 3)='IIS' then 'iis' when left(process,3)='INF' then 'inf' when left(process,3)='INM' then 'inm' when left(process, >> VedaBatchUpload.sql
echo 3)='IOI' or process like 'INDHFCOTH0%%' then 'ioi' when left(process,3)='IPP' then 'ipp' when process='-' then >> VedaBatchUpload.sql
echo 'other' else null end "sector", period, sum(case when commodity in('SKNINDCO2N','SKNINDCO2P') then -pv else pv end) >> VedaBatchUpload.sql
echo "pv" from vedastore where commodity in ('SKNINDCO2N','SKNINDCO2P') and attribute='VAR_FOut' group by tablename, >> VedaBatchUpload.sql
echo sector,period ) a where sector is not null group by tablename, sector ) TO '%~dp0IndSubGHG.csv' >> VedaBatchUpload.sql
echo CSV; >> VedaBatchUpload.sql
rem /* *Electricity generation by source* */
echo /* *Electricity generation by source* */ COPY ( with emissions_chp as ( select tablename, proc_set, commodity, >> VedaBatchUpload.sql
echo period,sum(pv) "pv" from ( select period, pv,commodity,process,tablename, case when process in('IISCHPCCGT01', >> VedaBatchUpload.sql
echo 'IISCHPGT01','IPPCHPCCGTH01','IFDCHPFCH01','IISCHPHFO00','IPPCHPBIOG01','IOICHPCOA01','IOICHPFCH01','ICHCHPCCGTH01', >> VedaBatchUpload.sql
echo 'IPPCHPFCH01','INMCHPCCGT01','IOICHPBIOG01' ,'IFDCHPNGA00','ICHCHPLFO00','IISCHPCOG00','IOICHPNGA00','IOICHPHFO00', >> VedaBatchUpload.sql
echo 'IOICHPCCGTH01','INMCHPCOG00','ICHCHPCOA00','IFDCHPBIOS00','IOICHPBIOS00','IISCHPBFG00','IISCHPBIOS01' , >> VedaBatchUpload.sql
echo 'ICHCHPCCGT01','IISCHPCCGTH01','IFDCHPBIOS01','IISCHPCOG01','IISCHPNGA00','ICHCHPBIOS00','IFDCHPCCGTH01', >> VedaBatchUpload.sql
echo 'IOICHPCCGT01','INMCHPBIOS01','ICHCHPLPG00','IISCHPBIOG01','IPPCHPCOA00' ,'ICHCHPFCH01','IFDCHPBIOG01','IFDCHPHFO00', >> VedaBatchUpload.sql
echo 'IPPCHPWST01','ICHCHPHFO00','IISCHPBFG01','ICHCHPBIOS01','ICHCHPNGA00','IPPCHPCCGT01','IFDCHPGT01','IPPCHPBIOS01', >> VedaBatchUpload.sql
echo 'INMCHPBIOG01' ,'ICHCHPGT01','INMCHPGT01','IPPCHPCOA01','IISCHPFCH01','IOICHPBIOS01','ICHCHPCOA01','IFDCHPLFO00', >> VedaBatchUpload.sql
echo 'IPPCHPNGA00','IFDCHPCOA00','INMCHPFCH01','IFDCHPCCGT01','ICHCHPPRO01' ,'INMCHPNGA00','INMCHPCOG01','IOICHPGT01', >> VedaBatchUpload.sql
echo 'IPPCHPGT01','ICHCHPBIOG01','ICHCHPLPG01','INMCHPCCGTH01','ICHCHPPRO00','INMCHPCOA01','IPPCHPWST00','IFDCHPCOA01', >> VedaBatchUpload.sql
echo 'IPPCHPBIOS00') then 'CHP IND SECTOR' when process in('PCHP-CCP01','PCHP-CCP00') then 'CHP PRC SECTOR' when process >> VedaBatchUpload.sql
echo in('SHLCHPRH01','SCHP-STM01','SHLCHPRW01','SCHP-FCH01','SHLCHPRG01','SHHFCLRH01','SCHP-CCH01','SCHP-STW00', >> VedaBatchUpload.sql
echo 'SCHP-CCG00','SCHP-CCG01','SCHP-GES00','SCHP-STW01' ,'SCHP-GES01','SCHP-ADM01') then 'CHP SER SECTOR' when process >> VedaBatchUpload.sql
echo in('UCHP-CCG01','UCHP-CCG00') then 'CHP UPS SECTOR' when process in('RHEACHPRG01','RHEACHPRW01','RHEACHPRH01', >> VedaBatchUpload.sql
echo 'RHHCCHPRG01','RHHCCHPRW01','RHHCCHPRH01','RHHSCHPRG01','RHHSCHPRW01','RHHSCHPRH01','RHFCCHPRG01','RHFCCHPRW01', >> VedaBatchUpload.sql
echo 'RHFCCHPRH01','RHFSCHPRG01','RHFSCHPRW01','RHFSCHPRH01','RHNACHPRG01','RHNACHPRW01','RHNACHPRH01') then 'CHP RES MICRO' >> VedaBatchUpload.sql
echo end proc_set from vedastore where attribute='VAR_FOut' and commodity in('RESCH4N','SERN2ON','INDCO2N', >> VedaBatchUpload.sql
echo 'SERCH4N','INDCH4N','INDN2ON','UPSN2ON','UPSCO2N','UPSCH4N','PRCCH4N','PRCCO2N','PRCN2ON' ,'SERCO2N','RESCO2N', >> VedaBatchUpload.sql
echo 'RESN2ON') union all select period, pv,commodity,process,tablename, case when process in('IPPCHPBIOS00', >> VedaBatchUpload.sql
echo 'ICHCHPBIOS00','IPPCHPWST00','IFDCHPBIOS00','IFDCHPBIOS01','ICHCHPBIOS01','IPPCHPWST01','IOICHPBIOS00','INMCHPBIOS01', >> VedaBatchUpload.sql
echo 'IPPCHPBIOS01', 'IOICHPBIOS01','IISCHPBIOS01') then 'CHP IND BIO' when process in('SCHP-ADM01','SCHP-STM01', >> VedaBatchUpload.sql
echo 'SCHP-GES01','SCHP-GES00','SCHP-STW01','SHLCHPRW01','SCHP-STW00') then 'CHP SER BIO' when process in('SHHFCLRH01', >> VedaBatchUpload.sql
echo 'SHLCHPRG01','SHLCHPRH01','SHLCHPRW01') then 'CHP SER MICRO' when process in('RCHPEA-CCH01','RCHPEA-CCG00', >> VedaBatchUpload.sql
echo 'RCHPNA-CCH01','RCHPEA-CCG01','RHEACHPRW01','RHNACHPRW01','RCHPNA-STW01','RCHPEA-STW01','RHNACHPRG01','RHEACHPRH01', >> VedaBatchUpload.sql
echo 'RHNACHPRH01','RCHPNA-CCG01' ,'RCHPEA-FCH01','RHEACHPRG01','RCHPNA-FCH01') then 'CHP RES SECTOR' else null end >> VedaBatchUpload.sql
echo proc_set from vedastore where attribute='VAR_FOut' and commodity in('RESCH4N','SERN2ON','INDCO2N','SERCH4N','INDCH4N', >> VedaBatchUpload.sql
echo 'INDN2ON','UPSN2ON','UPSCO2N','UPSCH4N','PRCCH4N','PRCCO2N','PRCN2ON' ,'SERCO2N','RESCO2N','RESN2ON') ) a where >> VedaBatchUpload.sql
echo proc_set is not null group by tablename, proc_set, commodity,period ) , emis_co2_sector as( select tablename, >> VedaBatchUpload.sql
echo comm_set, commodity,period, pv from ( select case when commodity in('AGRCO2N','AGRCO2P') then 'EMIS CO2 AGR' when >> VedaBatchUpload.sql
echo commodity in('ELCCO2N','ELCCO2P') then 'EMIS CO2 ELC' when commodity in('HYGCO2N','HYGCO2P') then 'EMIS CO2 HYG' when >> VedaBatchUpload.sql
echo commodity in('INDCO2N','INDCO2P') then 'EMIS CO2 IND' when commodity in('INDNEUCO2N','PRCCO2N') then 'EMIS CO2 NEU' >> VedaBatchUpload.sql
echo when commodity in('PRCCO2P') then 'EMIS CO2 PRC' when commodity in('RESCO2N','RESCO2P') then 'EMIS CO2 RES' when >> VedaBatchUpload.sql
echo commodity in('SERCO2N','SERCO2P') then 'EMIS CO2 SER' when commodity in('TRACO2N','TRACO2P') then 'EMIS CO2 TRA' when >> VedaBatchUpload.sql
echo commodity in('UPSCO2N','UPSCO2P') then 'EMIS CO2 UPS' end as comm_set,commodity,pv,period,tablename from vedastore >> VedaBatchUpload.sql
echo where attribute='VAR_FOut' ) a where comm_set is not null ) , emis_ghg_dif as ( select tablename, comm_set, commodity, >> VedaBatchUpload.sql
echo period,pv from ( select case when commodity in ('AGRCH4N','AGRCH4P','AGRCO2N','AGRCO2P','AGRHFCN','AGRHFCP','AGRN2ON', >> VedaBatchUpload.sql
echo 'AGRN2OP','AGRNH3','AGRNOX','AGRPM10','AGRPM25','AGRSO2','AGRVOC') then 'EMIS GHG AGR' when commodity in ('ELCCH4N', >> VedaBatchUpload.sql
echo 'ELCCH4P','ELCCO2N','ELCCO2P','ELCHFCN','ELCHFCP','ELCN2ON','ELCN2OP','ELCNH3','ELCNOX','ELCPM10','ELCPM25','ELCSO2', >> VedaBatchUpload.sql
echo 'ELCVOC') then 'EMIS GHG ELC' when commodity in ('HYGCH4N','HYGCH4P','HYGCO2N','HYGCO2P','HYGHFCN','HYGHFCP', >> VedaBatchUpload.sql
echo 'HYGN2ON','HYGN2OP','HYGNH3','HYGNOX','HYGPM10','HYGPM25','HYGSO2','HYGVOC') then 'EMIS GHG HYG' when commodity in >> VedaBatchUpload.sql
echo ('INDCH4N','INDCH4P','INDCO2N','INDCO2P','INDHFCN','INDHFCP','INDN2ON','INDN2OP') then 'EMIS GHG IND' when commodity >> VedaBatchUpload.sql
echo in ('INDNEUCO2N') then 'EMIS GHG NEU' when commodity in ('PRCCH4N','PRCCH4P','PRCCO2N','PRCCO2P','PRCHFCN','PRCHFCP', >> VedaBatchUpload.sql
echo 'PRCN2ON','PRCN2OP','PRCNH3','PRCNOX','PRCPM10','PRCPM25','PRCSO2','PRCVOC') then 'EMIS GHG PRC' when commodity in >> VedaBatchUpload.sql
echo ('RESCH4N','RESCH4P','RESCO2N','RESCO2P','RESHFCN','RESHFCP','RESN2ON','RESN2OP','RESNH3','RESNOX','RESPM10', >> VedaBatchUpload.sql
echo 'RESPM25','RESSO2','RESVOC') then 'EMIS GHG RES' when commodity in ('SERCH4N','SERCH4P','SERCO2N','SERCO2P','SERHFCN', >> VedaBatchUpload.sql
echo 'SERHFCP','SERN2ON','SERN2OP','SERNH3','SERNOX','SERPM10','SERPM25','SERSO2','SERVOC') then 'EMIS GHG SER' when >> VedaBatchUpload.sql
echo commodity in ('TRACH4N','TRACH4P','TRACO2N','TRACO2P','Traded-Emission-ETS','Traded-Emission-Non-ETS','TRAHFCN', >> VedaBatchUpload.sql
echo 'TRAHFCP','TRAN2ON','TRAN2OP','TRANH3','TRANOX','TRAPM10','TRAPM25','TRASO2','TRAVOC') then 'EMIS GHG TRA' when >> VedaBatchUpload.sql
echo commodity in ('UPSCH4N','UPSCH4P','UPSCO2N','UPSCO2P','UPSHFCN','UPSHFCP','UPSN2ON','UPSN2OP') then 'EMIS GHG UPS' >> VedaBatchUpload.sql
echo end as comm_set,commodity,pv,period, tablename from vedastore where attribute in('EQ_Combal','VAR_Comnet') ) a where >> VedaBatchUpload.sql
echo comm_set is not null ) , "elc-emis" as( select tablename,period,sum(pv)/1000 "elc-emis" from ( select tablename,pv, >> VedaBatchUpload.sql
echo period from "emis_co2_sector" where comm_set='EMIS CO2 ELC' union all select tablename,pv,period from "emis_ghg_dif" >> VedaBatchUpload.sql
echo where commodity in('ELCCH4N','ELCN2ON') union all select tablename,sum(pv) "pv", period from "emissions_chp" where >> VedaBatchUpload.sql
echo proc_set in('CHP IND SECTOR','CHP PRC SECTOR','CHP RES SECTOR','CHP SER SECTOR','CHP UPS SECTOR') and commodity >> VedaBatchUpload.sql
echo in('INDCO2N','INDCH4N','INDN2ON','PRCCO2N','PRCCH4N','PRCN2ON','RESCO2N','RESCH4N','RESN2ON','SERCO2N','SERCH4N', >> VedaBatchUpload.sql
echo 'SERN2ON','UPSCO2N','UPSCH4N','UPSN2ON') group by tablename, period ) a group by tablename,period ) , elc_prd_fuel as >> VedaBatchUpload.sql
echo ( select proc_set,tablename,period, sum(pv) "pv" from ( select tablename,period, pv, case when process in('EBIOS00', >> VedaBatchUpload.sql
echo 'EBIOCON00','EBIO01','EBOG-LFE00','EBOG-SWE00','EMSW00','EPOLWST00','ESTWWST01','EBOG-ADE01','EBOG-SWE01','EMSW01', >> VedaBatchUpload.sql
echo 'ESTWWST00','EBOG-LFE01') then 'ELC FROM BIO' when process in('EBIOQ01') then 'ELC FROM BIO CCS' when process >> VedaBatchUpload.sql
echo in('PCHP-CCP00','UCHP-CCG00','PCHP-CCP01','UCHP-CCG01') then 'ELC FROM CHP' when process='ECOAQR01' then 'ELC FROM >> VedaBatchUpload.sql
echo COAL CCSRET' when process in('ECOARR01') then 'ELC FROM COAL RR' when process in('ECOABIO00','ECOA00') then 'ELC FROM COAL-COF' >> VedaBatchUpload.sql
echo when process in('ECOAQ01') then 'ELC FROM COALCOF CCS' when process in('ENGAOCT01','ENGAOCT00','ENGACCT00') >> VedaBatchUpload.sql
echo then 'ELC FROM GAS' when process in('ENGACCTQ01') then 'ELC FROM GAS CCS' when process='ENGAQR01' then 'ELC FROM GAS CCSRET' >> VedaBatchUpload.sql
echo when process in('ENGACCTRR01') then 'ELC FROM GAS RR' when process in('EGEO01') then 'ELC FROM GEO' when >> VedaBatchUpload.sql
echo process in('EHYD01','EHYD00') then 'ELC FROM HYDRO' when process in('EHYGCCT01','EHYGOCT01') then 'ELC FROM HYDROGEN' >> VedaBatchUpload.sql
echo when process in('ELCIE00','ELCIE01') then 'ELC FROM IMPORTS' when process in('EMANOCT00','EMANOCT01') then 'ELC FROM MANFUELS' >> VedaBatchUpload.sql
echo when process in('ENUCAGRN00','ENUCPWR101','ENUCPWR102','ENUCAGRO00','ENUCPWR00') then 'ELC FROM NUCLEAR' >> VedaBatchUpload.sql
echo when process in('EOILS00','EHFOIGCC01','EOILL00','EOILS01','EOILL01') then 'ELC FROM OIL' when process >> VedaBatchUpload.sql
echo in('EHFOIGCCQ01') then 'ELC FROM OIL CCS' when process in('ESOL01','ESOLPV00','ESOLPV01','ESOL00') then 'ELC FROM SOL-PV' >> VedaBatchUpload.sql
echo  when process in('ETIB101','ETIS101','ETIR101') then 'ELC FROM TIDAL' when process in('EWAV101') then 'ELC FROM WAVE' >> VedaBatchUpload.sql
echo when process in('EWNDOFF301','EWNDOFF00','EWNDOFF101','EWNDOFF201') then 'ELC FROM WIND-OFFSH' when >> VedaBatchUpload.sql
echo process in('EWNDONS501','EWNDONS401','EWNDONS00','EWNDONS301','EWNDONS601','EWNDONS101','EWNDONS901','EWNDONS201', >> VedaBatchUpload.sql
echo 'EWNDONS801','EWNDONS701') then 'ELC FROM WIND-ONSH' when process in('ELCEE00','ELCEI00','ELCEE01','ELCEI01') then >> VedaBatchUpload.sql
echo 'ELC TO EXPORTS' end as proc_set from vedastore where attribute='VAR_FOut' and commodity in('ELCDUMMY','ELC', >> VedaBatchUpload.sql
echo 'ELC-E-IRE','ELC-E-EU','ELCGEN') ) a where proc_set is not null group by tablename, period,proc_set union all select >> VedaBatchUpload.sql
echo proc_set,tablename,period, sum(pv) "pv" from ( select tablename,period, pv, case when process in( 'ICHCHPBIOG01', >> VedaBatchUpload.sql
echo 'ICHCHPBIOS00','ICHCHPBIOS01','ICHCHPCCGT01','ICHCHPCCGTH01','ICHCHPCOA00','ICHCHPCOA01','ICHCHPFCH01', 'ICHCHPGT01', >> VedaBatchUpload.sql
echo 'ICHCHPHFO00','ICHCHPLFO00','ICHCHPLPG00','ICHCHPLPG01','ICHCHPNGA00','ICHCHPPRO00','ICHCHPPRO01', 'IFDCHPBIOG01', >> VedaBatchUpload.sql
echo 'IFDCHPBIOS00','IFDCHPBIOS01','IFDCHPCCGT01','IFDCHPCCGTH01','IFDCHPCOA00','IFDCHPCOA01','IFDCHPFCH01', 'IFDCHPGT01', >> VedaBatchUpload.sql
echo 'IFDCHPHFO00','IFDCHPLFO00','IFDCHPNGA00','IISCHPBFG00','IISCHPBFG01','IISCHPBIOG01','IISCHPBIOS01', 'IISCHPCCGT01', >> VedaBatchUpload.sql
echo 'IISCHPCCGTH01','IISCHPCOG00','IISCHPCOG01','IISCHPFCH01','IISCHPGT01','IISCHPHFO00','IISCHPNGA00', 'INMCHPBIOG01', >> VedaBatchUpload.sql
echo 'INMCHPBIOS01','INMCHPCCGT01','INMCHPCCGTH01','INMCHPCOA01','INMCHPCOG00','INMCHPCOG01','INMCHPFCH01', 'INMCHPGT01', >> VedaBatchUpload.sql
echo 'INMCHPNGA00','IOICHPBIOG01','IOICHPBIOS00','IOICHPBIOS01','IOICHPCCGT01','IOICHPCCGTH01','IOICHPCOA01', >> VedaBatchUpload.sql
echo 'IOICHPFCH01','IOICHPGT01','IOICHPHFO00','IOICHPNGA00','IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPCCGT01', >> VedaBatchUpload.sql
echo 'IPPCHPCCGTH01','IPPCHPCOA00','IPPCHPCOA01','IPPCHPFCH01','IPPCHPGT01','IPPCHPNGA00','IPPCHPWST00','IPPCHPWST01', >> VedaBatchUpload.sql
echo 'PCHP-CCP00','PCHP-CCP01','RCHPEA-CCG00','RCHPEA-CCG01','RCHPEA-CCH01','RCHPEA-FCH01','RCHPEA-STW01','RCHPNA-CCG01', >> VedaBatchUpload.sql
echo 'RCHPNA-CCH01','RCHPNA-FCH01','RCHPNA-STW01','RHEACHPRG01','RHEACHPRH01','RHEACHPRW01','RHNACHPRG01','RHNACHPRH01', >> VedaBatchUpload.sql
echo 'RHNACHPRW01','SCHP-ADM01','SCHP-CCG00','SCHP-CCG01','SCHP-CCH01','SCHP-FCH01','SCHP-GES00','SCHP-GES01','SCHP-STM01', >> VedaBatchUpload.sql
echo 'SCHP-STW00','SCHP-STW01','SHLCHPRG01','SHLCHPRH01','SHLCHPRW01','UCHP-CCG00','UCHP-CCG01') then 'elec-gen_chp' else >> VedaBatchUpload.sql
echo null end proc_set from vedastore where period in('2010','2011','2012','2015','2020','2025','2030','2035','2040', >> VedaBatchUpload.sql
echo '2045','2050','2055','2060') and attribute='VAR_FOut' and commodity in('ELCGEN','INDELC','RESELC','RESHOUSEELC', >> VedaBatchUpload.sql
echo 'SERBUILDELC','SERDISTELC','SERELC') ) a where proc_set is not null group by tablename, period,proc_set union all >> VedaBatchUpload.sql
echo select proc_set,tablename,period, sum(pv) "pv" from ( select tablename,period, pv, case when >> VedaBatchUpload.sql
echo process='EWSTHEAT-OFF-01' then 'elec-gen_waste-heat-penalty'::varchar(50) else null end proc_set from vedastore where >> VedaBatchUpload.sql
echo period in('2010','2011','2012','2015','2020','2025','2030','2035','2040','2045','2050','2055','2060') and commodity = >> VedaBatchUpload.sql
echo 'ELCGEN' and attribute = 'VAR_FIn' ) a where proc_set is not null group by tablename, period,proc_set ) , >> VedaBatchUpload.sql
echo cofiring_fuel as( select tablename, fuel, period, sum(pv) "pv" from ( select tablename,commodity "fuel",period,pv >> VedaBatchUpload.sql
echo from vedastore where process in('ECOA00','ECOABIO00','ECOAQ01','ECOARR01') and attribute='VAR_FIn' union all select >> VedaBatchUpload.sql
echo tablename,commodity "fuel",period,pv from vedastore where process in('EHFOIGCC01','EHFOIGCCQ01','EOILL00','EOILL01', >> VedaBatchUpload.sql
echo 'EOILS00','EOILS01') and attribute='VAR_FIn' union all select tablename,commodity "fuel",period,pv from vedastore >> VedaBatchUpload.sql
echo where commodity in('ELCMAINSBOM','ELCMAINSGAS','ELCTRANSBOM','ELCTRANSGAS') and attribute='VAR_FIn' ) a group by >> VedaBatchUpload.sql
echo tablename, fuel,period order by fuel, period ) , cofiring_fuel_percents as( select tablename, period, case when >> VedaBatchUpload.sql
echo sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end ) ^> 0 then sum(case >> VedaBatchUpload.sql
echo when fuel='ELCCOA' then pv else 0 end) / sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') >> VedaBatchUpload.sql
echo then pv else 0 end ) else 0 end "coal", case when sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL', >> VedaBatchUpload.sql
echo 'ELCMSC') then pv else 0 end ) ^> 0 then sum(case when fuel in('ELCBIOCOA','ELCBIOCOA2','ELCPELL') then pv else 0 >> VedaBatchUpload.sql
echo end) / sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end ) else 0 end >> VedaBatchUpload.sql
echo "biocoal", case when sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end ) >> VedaBatchUpload.sql
echo ^> 0 then sum(case when fuel in('ELCMSC') then pv else 0 end) / sum(case when fuel in('ELCCOA','ELCBIOCOA', >> VedaBatchUpload.sql
echo 'ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end ) else 0 end "oilcoal", case when sum(case when fuel in('ELCHFO', >> VedaBatchUpload.sql
echo 'ELCLFO','ELCLPG','ELCBIOOIL','ELCBIOLFO') then pv else 0 end ) ^> 0 then sum(case when fuel in('ELCHFO','ELCLFO', >> VedaBatchUpload.sql
echo 'ELCLPG') then pv else 0 end) / sum(case when fuel in('ELCHFO','ELCLFO','ELCLPG','ELCBIOOIL','ELCBIOLFO') then pv >> VedaBatchUpload.sql
echo else 0 end ) else 0 end "oil", case when sum(case when fuel in('ELCHFO','ELCLFO','ELCLPG','ELCBIOOIL','ELCBIOLFO') >> VedaBatchUpload.sql
echo then pv else 0 end ) ^> 0 then sum(case when fuel in('ELCBIOOIL','ELCBIOLFO') then pv else 0 end) / sum(case when >> VedaBatchUpload.sql
echo fuel in('ELCHFO','ELCLFO','ELCLPG','ELCBIOOIL','ELCBIOLFO') then pv else 0 end ) else 0 end "biooil", case when >> VedaBatchUpload.sql
echo sum(case when fuel in('ELCMAINSGAS','ELCTRANSGAS','ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end ) ^> 0 then >> VedaBatchUpload.sql
echo sum(case when fuel in('ELCMAINSGAS','ELCTRANSGAS') then pv else 0 end) / sum(case when fuel in('ELCMAINSGAS', >> VedaBatchUpload.sql
echo 'ELCTRANSGAS','ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end ) else 0 end "gas", case when sum(case when fuel >> VedaBatchUpload.sql
echo in('ELCMAINSGAS','ELCTRANSGAS','ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end ) ^> 0 then sum(case when fuel >> VedaBatchUpload.sql
echo in('ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end) / sum(case when fuel in('ELCMAINSGAS','ELCTRANSGAS','ELCMAINSBOM', >> VedaBatchUpload.sql
echo 'ELCTRANSBOM') then pv else 0 end ) else 0 end "biogas" from cofiring_fuel group by tablename, period ) , >> VedaBatchUpload.sql
echo elc_waste_heat_process as ( select tablename, process,userconstraint,attribute,commodity,period,sum(pv) "pv" from >> VedaBatchUpload.sql
echo vedastore where process='EWSTHEAT-OFF-01' group by tablename, process,userconstraint,attribute,commodity, period >> VedaBatchUpload.sql
echo order by tablename, process,userconstraint,attribute,commodity, period ) , elc_waste_heat_available as ( select >> VedaBatchUpload.sql
echo tablename,attribute,commodity,process,period, sum(pv) "pv" from vedastore where commodity='ELCWSTHEAT' and attribute >> VedaBatchUpload.sql
echo in ('VAR_FIn','VAR_FOut') group by tablename,attribute,commodity,process,period order by tablename,attribute, >> VedaBatchUpload.sql
echo commodity,process,period ) , waste_heat_type as( select tablename, period, sum(case when "waste_heat"='Biomass' then >> VedaBatchUpload.sql
echo pv else 0 end) "Biomass", sum(case when "waste_heat"='Biomass CCS' then pv else 0 end) "Biomass CCS", sum(case when >> VedaBatchUpload.sql
echo "waste_heat"='Hydrogen' then pv else 0 end) "Hydrogen", sum(case when "waste_heat"='Nuclear' then pv else 0 end) >> VedaBatchUpload.sql
echo "Nuclear", sum(case when "waste_heat"='Coal' then pv else 0 end) "Coal", sum(case when "waste_heat"='Coal CCS' then >> VedaBatchUpload.sql
echo pv else 0 end) "Coal CCS", sum(case when "waste_heat"='Coal RR' then pv else 0 end) "Coal RR", sum(case when >> VedaBatchUpload.sql
echo "waste_heat"='Natural Gas' then pv else 0 end) "Natural Gas", sum(case when "waste_heat"='Natural Gas CCS' then pv >> VedaBatchUpload.sql
echo else 0 end) "Natural Gas CCS", sum(case when "waste_heat"='Natural Gas RR' then pv else 0 end) "Natural Gas RR", >> VedaBatchUpload.sql
echo sum(case when "waste_heat"='Oil' then pv else 0 end) "Oil", sum(case when "waste_heat"='OIL CCS' then pv else 0 end) >> VedaBatchUpload.sql
echo "OIL CCS" from ( select tablename,attribute,period,pv, case when process in('ESTWWST00','EPOLWST00','EBIOS00', >> VedaBatchUpload.sql
echo 'EBOG-LFE00','EBOG-SWE00','EMSW00','EBIOCON00','ESTWWST01','EBIO01','EBOG-ADE01','EBOG-LFE01','EBOG-SWE01','EMSW01') >> VedaBatchUpload.sql
echo then 'Biomass' when process in('EBIOQ01') then 'Biomass CCS' when process in('EHYGCCT01') then 'Hydrogen' when >> VedaBatchUpload.sql
echo process in('ENUCPWR00','ENUCAGRN00','ENUCAGRO00','ENUCPWR101','ENUCPWR102') then 'Nuclear' end "waste_heat" from >> VedaBatchUpload.sql
echo elc_waste_heat_available union all select tablename,attribute,period,pv, case when process in('ECOA00','ECOABIO00') >> VedaBatchUpload.sql
echo then 'Coal' when process in('ECOAQ01','ECOAQDEMO01') then 'Coal CCS' when process in('ECOARR01') then 'Coal RR' when >> VedaBatchUpload.sql
echo process in('ENGACCT00') then 'Natural Gas' when process in('ENGACCTQ01','ENGACCTQDEMO01') then 'Natural Gas CCS' when >> VedaBatchUpload.sql
echo process in('ENGACCTRR01') then 'Natural Gas RR' when process in('EOILL00','EOILS00','EOILS01','EOILL01','EHFOIGCC01') >> VedaBatchUpload.sql
echo then 'Oil' when process in('EHFOIGCCQ01') then 'OIL CCS' end "waste_heat" from elc_waste_heat_available ) a where >> VedaBatchUpload.sql
echo "waste_heat" is not null group by tablename, period order by tablename, period ) , retrofit_plants as( select >> VedaBatchUpload.sql
echo a.tablename, a.period, sum(a."coal_rr"*b."Coal RR") "coal_rr", sum(a."gas_rr"*b."Natural Gas RR") "gas_rr", >> VedaBatchUpload.sql
echo sum(a."coalccs_rr"*b."Coal RR") "coalccs_rr", sum(a."gasccs_rr"*b."Natural Gas RR") "gasccs_rr" from ( select >> VedaBatchUpload.sql
echo tablename, period, case when sum(case when proc_set='ELC FROM COAL RR' then pv else 0 end) ^> 0 and sum(case when >> VedaBatchUpload.sql
echo proc_set='ELC FROM COAL RR' then pv else 0 end) ^> sum(case when proc_set='ELC FROM COAL CCSRET' then pv else 0 end) >> VedaBatchUpload.sql
echo then (sum(case when proc_set='ELC FROM COAL RR' then pv else 0 end)-sum(case when proc_set='ELC FROM COAL CCSRET' >> VedaBatchUpload.sql
echo then pv else 0 end))/sum(case when proc_set='ELC FROM COAL RR' then pv else 0 end) else 0 end "coal_rr", case when >> VedaBatchUpload.sql
echo sum(case when proc_set='ELC FROM GAS RR' then pv else 0 end) ^> 0 and sum(case when proc_set='ELC FROM GAS RR' then >> VedaBatchUpload.sql
echo pv else 0 end) ^> sum(case when proc_set='ELC FROM GAS CCSRET' then pv else 0 end) then (sum(case when proc_set='ELC FROM GAS RR' >> VedaBatchUpload.sql
echo  then pv else 0 end)-sum(case when proc_set='ELC FROM GAS CCSRET' then pv else 0 end))/sum(case when >> VedaBatchUpload.sql
echo proc_set='ELC FROM GAS RR' then pv else 0 end) else 0 end "gas_rr", case when sum(case when proc_set='ELC FROM COAL RR' >> VedaBatchUpload.sql
echo then pv else 0 end) ^> 0 then sum(case when proc_set='ELC FROM COAL CCSRET' then pv else 0 end)/sum(case when >> VedaBatchUpload.sql
echo proc_set='ELC FROM COAL RR' then pv else 0 end) else 0 end "coalccs_rr", case when sum(case when proc_set='ELC FROM GAS RR' >> VedaBatchUpload.sql
echo then pv else 0 end) ^> 0 then sum(case when proc_set='ELC FROM GAS CCSRET' then pv else 0 end)/sum(case when >> VedaBatchUpload.sql
echo proc_set='ELC FROM GAS RR' then pv else 0 end) else 0 end "gasccs_rr" from elc_prd_fuel group by tablename, period ) >> VedaBatchUpload.sql
echo a inner join waste_heat_type b on a.tablename=b.tablename and a.period=b.period group by a.tablename, a.period ) , >> VedaBatchUpload.sql
echo fuel_shares_to_groups as( select tablename, period, >> VedaBatchUpload.sql
echo "coal_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") >> VedaBatchUpload.sql
echo "coal_grp", >> VedaBatchUpload.sql
echo "coalccs_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") >> VedaBatchUpload.sql
echo "coalccs_grp", >> VedaBatchUpload.sql
echo "gas_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") >> VedaBatchUpload.sql
echo "gas_grp", >> VedaBatchUpload.sql
echo "gasccs_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") >> VedaBatchUpload.sql
echo "gasccs_grp", >> VedaBatchUpload.sql
echo "oil_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") >> VedaBatchUpload.sql
echo "oil_grp", >> VedaBatchUpload.sql
echo "oilccs_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") >> VedaBatchUpload.sql
echo "oilccs_grp", >> VedaBatchUpload.sql
echo "bio_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") >> VedaBatchUpload.sql
echo "bio_grp", >> VedaBatchUpload.sql
echo "bioccs_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") >> VedaBatchUpload.sql
echo "bioccs_grp", >> VedaBatchUpload.sql
echo "nuclear_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") >> VedaBatchUpload.sql
echo "nuclear_grp", >> VedaBatchUpload.sql
echo "h2_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "h2_grp" >> VedaBatchUpload.sql
echo from ( select a.tablename, a.period, (sum(c."Coal")+sum("coal_rr"))*sum(a.coal) "coal_grp", (sum(c."Coal CCS") >> VedaBatchUpload.sql
echo +sum("coalccs_rr"))*sum(a.coal) "coalccs_grp", (sum(c."Natural Gas")+sum("gas_rr"))*sum(a.gas) "gas_grp", >> VedaBatchUpload.sql
echo (sum(c."Natural Gas CCS")+sum("gasccs_rr"))*sum(a.gas) "gasccs_grp", (sum(c."Coal")+sum("coal_rr"))*sum(a.oilcoal) + >> VedaBatchUpload.sql
echo sum(c."Oil")*sum(a.oil) "oil_grp", sum(c."OIL CCS")*sum(a.oil) + (sum(c."Coal CCS")+sum("coalccs_rr"))*sum(a.oilcoal) >> VedaBatchUpload.sql
echo "oilccs_grp", sum(c."Biomass") + (sum(c."Coal")+sum("coal_rr"))*sum(a.biocoal) + (sum("Natural Gas") >> VedaBatchUpload.sql
echo +sum("gas_rr"))*sum(a.biogas) + sum(c."Oil")*sum(a.biooil) "bio_grp", sum(c."Biomass CCS") + (sum(c."Coal CCS") >> VedaBatchUpload.sql
echo +sum("coalccs_rr"))*sum(a.biocoal) + (sum(c."Natural Gas CCS")+sum("gasccs_rr"))*sum(a.biogas) + sum(c."OIL CCS")>> VedaBatchUpload.sql
echo *sum(a.biooil) "bioccs_grp", sum(c."Nuclear") "nuclear_grp", sum(c."Hydrogen") "h2_grp" from >> VedaBatchUpload.sql
echo cofiring_fuel_percents a full outer join retrofit_plants b on a.tablename=b.tablename and a.period=b.period full >> VedaBatchUpload.sql
echo outer join waste_heat_type c on a.tablename=c.tablename and a.period=c.period group by a.tablename, a.period ) a ) , >> VedaBatchUpload.sql
echo elec_penalty as ( select a.tablename, a.period, case when coal_grp*b."ELCGEN" is null then 0 else coal_grp*b."ELCGEN" >> VedaBatchUpload.sql
echo end "coal", case when coalccs_grp*b."ELCGEN" is null then 0 else coalccs_grp*b."ELCGEN" end "coalccs", case when >> VedaBatchUpload.sql
echo gas_grp*b."ELCGEN" is null then 0 else gas_grp*b."ELCGEN" end "gas", case when gasccs_grp*b."ELCGEN" is null then 0 >> VedaBatchUpload.sql
echo else gasccs_grp*b."ELCGEN" end "gasccs", case when oil_grp*b."ELCGEN" is null then 0 else oil_grp*b."ELCGEN" end >> VedaBatchUpload.sql
echo "oil", case when oilccs_grp*b."ELCGEN" is null then 0 else oilccs_grp*b."ELCGEN" end "oilccs", case when >> VedaBatchUpload.sql
echo bio_grp*b."ELCGEN" is null then 0 else bio_grp*b."ELCGEN" end "bio", case when bioccs_grp*b."ELCGEN" is null then 0 >> VedaBatchUpload.sql
echo else bioccs_grp*b."ELCGEN" end "bioccs", case when nuclear_grp*b."ELCGEN" is null then 0 else nuclear_grp*b."ELCGEN" >> VedaBatchUpload.sql
echo end "nuclear", case when h2_grp*b."ELCGEN" is null then 0 else h2_grp*b."ELCGEN" end "h2" from fuel_shares_to_groups >> VedaBatchUpload.sql
echo a left join ( select tablename, period, sum(case when commodity='ELCGEN' then pv else 0 end) "ELCGEN" from >> VedaBatchUpload.sql
echo elc_waste_heat_process group by tablename, period ) b on a.tablename=b.tablename and a.period=b.period order by >> VedaBatchUpload.sql
echo period ) select cols ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| case when cols='elec-gen_intercon' then >> VedaBatchUpload.sql
echo 'various'::varchar when cols='elec-gen_waste-heat-penalty' then 'VAR_FIn'::varchar else 'VAR_FOut'::varchar end ^|^| >> VedaBatchUpload.sql
echo '^|various^|various'::varchar "id", cols::varchar "analysis", tablename, case when cols='elec-gen_intercon' then >> VedaBatchUpload.sql
echo 'various'::varchar when cols='elec-gen_waste-heat-penalty' then 'VAR_FIn'::varchar else 'VAR_FOut'::varchar end >> VedaBatchUpload.sql
echo "attribute", 'various'::varchar "commodity", 'various'::varchar "process", case when cols='elec-gen_inten' then >> VedaBatchUpload.sql
echo avg(vals) else sum(vals) end "all", sum(case when d.period='2010' then vals else 0 end) as "2010" , sum(case when >> VedaBatchUpload.sql
echo d.period='2011' then vals else 0 end) as "2011", sum(case when d.period='2012' then vals else 0 end) as "2012", >> VedaBatchUpload.sql
echo sum(case when d.period='2015' then vals else 0 end) as "2015", sum(case when d.period='2020' then vals else 0 end) as >> VedaBatchUpload.sql
echo "2020", sum(case when d.period='2025' then vals else 0 end) as "2025", sum(case when d.period='2030' then vals else 0 >> VedaBatchUpload.sql
echo end) as "2030", sum(case when d.period='2035' then vals else 0 end) as "2035", sum(case when d.period='2040' then >> VedaBatchUpload.sql
echo vals else 0 end) as "2040", sum(case when d.period='2045' then vals else 0 end) as "2045", sum(case when >> VedaBatchUpload.sql
echo d.period='2050' then vals else 0 end) as "2050", sum(case when d.period='2055' then vals else 0 end) as "2055", >> VedaBatchUpload.sql
echo sum(case when d.period='2060' then vals else 0 end) as "2060" from( SELECT unnest(array['elec-gen_coal', >> VedaBatchUpload.sql
echo 'elec-gen_coal-ccs','elec-gen_nga','elec-gen_nga-ccs','elec-gen_other-ff','elec-gen_bio','elec-gen_bio-ccs', >> VedaBatchUpload.sql
echo 'elec-gen_other-rens','elec-gen_solar','elec-gen_nuclear','elec-gen_offw','elec-gen_onw','elec-gen_chp', >> VedaBatchUpload.sql
echo 'elec-gen_total-cen','elec-gen_intercon','elec-gen_waste-heat-penalty','elec-gen_inten']) AS "cols", tablename,period, >> VedaBatchUpload.sql
echo unnest(array["elec-gen_coal","elec-gen_coal-ccs","elec-gen_nga","elec-gen_nga-ccs","elec-gen_other-ff", >> VedaBatchUpload.sql
echo "elec-gen_bio","elec-gen_bio-ccs","elec-gen_other-rens", "elec-gen_solar","elec-gen_nuclear","elec-gen_offw", >> VedaBatchUpload.sql
echo "elec-gen_onw","elec-gen_chp","elec-gen_total-cen","elec-gen_intercon","elec-gen_waste-heat-penalty", >> VedaBatchUpload.sql
echo "elec-gen_inten"]) AS "vals" FROM ( select a.tablename,a.period, "coal-unad"*b.coal-d.coal "elec-gen_coal", >> VedaBatchUpload.sql
echo "coalccs-unad"*b.coal-d.coalccs "elec-gen_coal-ccs", "gas-unad"*b.gas-d.gas "elec-gen_nga", >> VedaBatchUpload.sql
echo "gasccs-unad"*b.gas-d.gasccs "elec-gen_nga-ccs", ("ELC FROM OIL"*b.oil+"coal-unad"*b.oilcoal)-d.oil/*ie oil*/+("ELC FROM OIL CCS" >> VedaBatchUpload.sql
echo *b.oil+"coalccs-unad"*b.oilcoal)-d.oilccs/*oil ccs*/+"ELC FROM MANFUELS"/*man fuels*/ >> VedaBatchUpload.sql
echo "elec-gen_other-ff", ("ELC FROM BIO"+"coal-unad"*biocoal+"ELC FROM OIL"*biooil+"gas-unad"*b.biogas)-d.bio >> VedaBatchUpload.sql
echo "elec-gen_bio", ("ELC FROM BIO CCS"+"coalccs-unad"*biocoal+"ELC FROM OIL CCS"*biooil+"gasccs-unad"*b.biogas)-d.bioccs >> VedaBatchUpload.sql
echo "elec-gen_bio-ccs", "elec-gen_other-rens"-d.h2 "elec-gen_other-rens", "elec-gen_solar", "elec-gen_nuclear"-d.nuclear >> VedaBatchUpload.sql
echo "elec-gen_nuclear", "elec-gen_offw", "elec-gen_onw", "elec-gen_chp", >> VedaBatchUpload.sql
echo "coal-unad"*b.coal-d.coal+"coalccs-unad"*b.coal-d.coalccs+"gas-unad"*b.gas-d.gas+"gasccs-unad"*b.gas-d.gasccs+("ELC FROM OIL" >> VedaBatchUpload.sql
echo *b.oil+"coal-unad"*b.oilcoal)-d.oil+("ELC FROM OIL CCS"*b.oil+"coalccs-unad"*b.oilcoal)-d.oilccs+ "ELC FROM MANFUELS" >> VedaBatchUpload.sql
echo +("ELC FROM BIO"+"coal-unad"*b.biocoal+"ELC FROM OIL"*b.biooil+"gas-unad"*b.biogas)-d.bio+("ELC FROM BIO CCS" >> VedaBatchUpload.sql
echo +"coalccs-unad"*b.biocoal+"ELC FROM OIL CCS"*b.biooil+ >> VedaBatchUpload.sql
echo "gasccs-unad"*b.biogas)-d.bioccs+"elec-gen_other-rens"-d.h2+"elec-gen_solar"+"elec-gen_nuclear"-d.nuclear+"elec-gen_offw"+"elec-gen_onw"+"elec-gen_chp" >> VedaBatchUpload.sql
echo "elec-gen_total-cen", "elec-gen_intercon", "elec-gen_waste-heat-penalty", "elc-emis"/ >> VedaBatchUpload.sql
echo ("coal-unad"*b.coal+"coalccs-unad"*b.coal+"gas-unad"*b.gas+"gasccs-unad"*b.gas+"ELC FROM OIL" >> VedaBatchUpload.sql
echo *b.oil+"coal-unad"*b.oilcoal+"ELC FROM OIL CCS"*b.oil+"coalccs-unad"*b.oilcoal+ "ELC FROM MANFUELS"+ >> VedaBatchUpload.sql
echo "ELC FROM BIO"+"coal-unad"*b.biocoal+"ELC FROM OIL"*b.biooil+"gas-unad"*b.biogas+"ELC FROM BIO CCS" >> VedaBatchUpload.sql
echo +"coalccs-unad"*b.biocoal+"ELC FROM OIL CCS"*b.biooil+ >> VedaBatchUpload.sql
echo "gasccs-unad"*b.biogas+"elec-gen_other-rens"+"elec-gen_solar"+"elec-gen_nuclear"+"elec-gen_offw"+"elec-gen_onw"+"elec-gen_chp"-"elec-gen_waste-heat-penalty" >> VedaBatchUpload.sql
echo +(case when "elec-gen_intercon"^>0 then "elec-gen_intercon" else 0 end))*3600 "elec-gen_inten" from( select a.period, >> VedaBatchUpload.sql
echo a.tablename, sum(case when proc_set='ELC TO EXPORTS' then pv when proc_set='ELC FROM IMPORTS' then -pv else 0 end) >> VedaBatchUpload.sql
echo "elec-gen_intercon", sum(case when proc_set in ('ELC FROM TIDAL','ELC FROM WAVE','ELC FROM GEO','ELC FROM HYDRO','ELC FROM HYDROGEN') >> VedaBatchUpload.sql
echo then pv else 0 end) "elec-gen_other-rens", sum(case when proc_set in ('ELC FROM SOL-PV') then pv else >> VedaBatchUpload.sql
echo 0 end) "elec-gen_solar", sum(case when proc_set in ('ELC FROM NUCLEAR') then pv else 0 end) "elec-gen_nuclear", >> VedaBatchUpload.sql
echo sum(case when proc_set in ('ELC FROM WIND-OFFSH') then pv else 0 end) "elec-gen_offw", sum(case when proc_set in >> VedaBatchUpload.sql
echo ('ELC FROM WIND-ONSH') then pv else 0 end) "elec-gen_onw", sum(case when proc_set in ('elec-gen_chp') then pv else 0 >> VedaBatchUpload.sql
echo end) "elec-gen_chp", sum(case when proc_set='ELC FROM COAL-COF' then pv else 0 end)+sum(case when proc_set='ELC FROM COAL RR' >> VedaBatchUpload.sql
echo  then pv else 0 end)-sum(case when proc_set='ELC FROM COAL CCSRET' then pv else 0 end) "coal-unad", sum(case >> VedaBatchUpload.sql
echo when proc_set='ELC FROM COALCOF CCS' then pv else 0 end)+sum(case when proc_set='ELC FROM COAL CCSRET' then pv else 0 >> VedaBatchUpload.sql
echo end) "coalccs-unad", sum(case when proc_set='ELC FROM GAS' then pv else 0 end)+sum(case when proc_set='ELC FROM GAS RR' >> VedaBatchUpload.sql
echo  then pv else 0 end)-sum(case when proc_set='ELC FROM GAS CCSRET' then pv else 0 end) "gas-unad", sum(case when >> VedaBatchUpload.sql
echo proc_set='ELC FROM GAS CCS' then pv else 0 end)+sum(case when proc_set='ELC FROM GAS CCSRET' then pv else 0 end) >> VedaBatchUpload.sql
echo "gasccs-unad", sum(case when proc_set='ELC FROM OIL' then pv else 0 end) "ELC FROM OIL", sum(case when proc_set='ELC FROM OIL CCS' >> VedaBatchUpload.sql
echo  then pv else 0 end) "ELC FROM OIL CCS", sum(case when proc_set='ELC FROM MANFUELS' then pv else 0 end) >> VedaBatchUpload.sql
echo "ELC FROM MANFUELS", sum(case when proc_set='ELC FROM BIO' then pv else 0 end) "ELC FROM BIO", sum(case when >> VedaBatchUpload.sql
echo proc_set='ELC FROM BIO CCS' then pv else 0 end) "ELC FROM BIO CCS", sum(case when >> VedaBatchUpload.sql
echo proc_set='elec-gen_waste-heat-penalty' then pv else 0 end) "elec-gen_waste-heat-penalty" from elc_prd_fuel a group by >> VedaBatchUpload.sql
echo a.tablename, a.period ) a left join cofiring_fuel_percents b on a.tablename=b.tablename and a.period=b.period left >> VedaBatchUpload.sql
echo join "elc-emis" c on a.tablename=c.tablename and a.period=c.period left join "elec_penalty" d on >> VedaBatchUpload.sql
echo a.tablename=d.tablename and a.period=d.period ) c ) d group by tablename,cols ORDER BY tablename,analysis ) TO >> VedaBatchUpload.sql
echo '%~dp0ElecGenOut.csv' delimiter ',' >> VedaBatchUpload.sql
echo CSV; >> VedaBatchUpload.sql
rem /* *Elec storage* */
echo /* *Elec storage* */ copy ( >> VedaBatchUpload.sql
echo select 'elec-stor^|' ^|^| tablename ^|^| '^|Var_FOut^|ELC^|various'::varchar(300) "id", 'elec-stor'::varchar(25) "analysis" >> VedaBatchUpload.sql
echo , tablename, 'VAR_FOut'::varchar "attribute", 'ELC'::varchar "commodity", 'various'::varchar(50) "process", sum(pv)::numeric >> VedaBatchUpload.sql
echo "all", sum(case when period='2010' then pv else 0 end)::numeric "2010", sum(case when period='2011' then pv else 0 end)::numeric >> VedaBatchUpload.sql
echo "2011", sum(case when period='2012' then pv else 0 end)::numeric "2012", sum(case when period='2015' then pv else 0 end)::numeric >> VedaBatchUpload.sql
echo "2015", sum(case when period='2020' then pv else 0 end)::numeric "2020", sum(case when period='2025' then pv else 0 end)::numeric >> VedaBatchUpload.sql
echo "2025", sum(case when period='2030' then pv else 0 end)::numeric "2030", sum(case when period='2035' then pv else 0 end)::numeric >> VedaBatchUpload.sql
echo "2035", sum(case when period='2040' then pv else 0 end)::numeric "2040", sum(case when period='2045' then pv else 0 end)::numeric >> VedaBatchUpload.sql
echo "2045", sum(case when period='2050' then pv else 0 end)::numeric "2050", sum(case when period='2055' then pv else 0 end)::numeric >> VedaBatchUpload.sql
echo "2055", sum(case when period='2060' then pv else 0 end)::numeric "2060" from vedastore where attribute = 'VAR_FOut' and >> VedaBatchUpload.sql
echo commodity = 'ELC' and process in('EHYDPMP00','EHYDPMP01','ECAESCON01','ESTGCAES01','ECAESTUR01','ESTGAACAES01','ESTGBNAS01' >> VedaBatchUpload.sql
echo ,'ESTGBALA01','ESTGBRF01') >> VedaBatchUpload.sql
echo group by tablename >> VedaBatchUpload.sql
echo ) to '%~dp0ElecStor.csv' delimiter ',' CSV; >> VedaBatchUpload.sql
rem /* *Electricity capacity by process* */
echo /* *Electricity capacity by process* */ COPY ( select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| attribute >> VedaBatchUpload.sql
echo ^|^| '^|' ^|^| '-^|various'::varchar(300) "id", analysis, tablename,attribute, '-'::varchar(50) "commodity", >> VedaBatchUpload.sql
echo 'various'::varchar(50) "process", sum(pv)::numeric "all", sum(case when period='2010' then pv else 0 end)::numeric >> VedaBatchUpload.sql
echo "2010", sum(case when period='2011' then pv else 0 end)::numeric "2011", sum(case when period='2012' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2012", sum(case when period='2015' then pv else 0 end)::numeric "2015", sum(case when period='2020' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2020", sum(case when period='2025' then pv else 0 end)::numeric "2025", sum(case when >> VedaBatchUpload.sql
echo period='2030' then pv else 0 end)::numeric "2030", sum(case when period='2035' then pv else 0 end)::numeric "2035", >> VedaBatchUpload.sql
echo sum(case when period='2040' then pv else 0 end)::numeric "2040", sum(case when period='2045' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2045", sum(case when period='2050' then pv else 0 end)::numeric "2050", sum(case when period='2055' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2055", sum(case when period='2060' then pv else 0 end)::numeric "2060" from ( select >> VedaBatchUpload.sql
echo process, period,pv, case when process in('ESTWWST00','EPOLWST00', 'EBIOS00','EBOG-LFE00','EBOG-SWE00', 'EMSW00', >> VedaBatchUpload.sql
echo 'EBIOCON00','ESTWWST01','EBIO01','EBOG-ADE01', 'EBOG-LFE01','EBOG-SWE01','EMSW01') then 'elec-cap_bio'::varchar(50) >> VedaBatchUpload.sql
echo when process = 'EBIOQ01' then 'elec-cap_bio-ccs'::varchar(50) when process in('ECOA00','ECOABIO00', 'ECOARR01') then >> VedaBatchUpload.sql
echo 'elec-cap_coal'::varchar(50) when process in('ECOAQ01' ,'ECOAQDEMO01') then 'elec-cap_coal-ccs'::varchar(50) when >> VedaBatchUpload.sql
echo process in('EHYGCCT01' ,'EHYGOCT01') then 'elec-cap_h2'::varchar(50) when process in('ENGACCT00' ,'ENGAOCT00' , >> VedaBatchUpload.sql
echo 'ENGACCTRR01' ,'ENGAOCT01') then 'elec-cap_nga'::varchar(50) when process in('ENGACCTQ01' ,'ENGACCTQDEMO01') then >> VedaBatchUpload.sql
echo 'elec-cap_nga-ccs'::varchar(50) when process in('ENUCPWR00' ,'ENUCAGRN00' ,'ENUCAGRO00' ,'ENUCPWR101' ,'ENUCPWR102') >> VedaBatchUpload.sql
echo then 'elec-cap_nuclear'::varchar(50) when process in('EWNDOFF00' ,'EWNDOFF101' ,'EWNDOFF201' ,'EWNDOFF301') then >> VedaBatchUpload.sql
echo 'elec-cap_offw'::varchar(50) when process in('EWNDONS00','EWNDONS101','EWNDONS201','EWNDONS301','EWNDONS401', >> VedaBatchUpload.sql
echo 'EWNDONS501', 'EWNDONS601','EWNDONS701','EWNDONS801','EWNDONS901') then 'elec-cap_onw'::varchar(50) when process >> VedaBatchUpload.sql
echo ='EHFOIGCCQ01' then 'elec-cap_other-ccs'::varchar(50) when process in('EOILL00','EOILS00','EMANOCT00','EMANOCT01', >> VedaBatchUpload.sql
echo 'EOILS01','EOILL01','EHFOIGCC01') then 'elec-cap_other-ff'::varchar(50) when process in('EHYD00','EHYD01','EGEO01', >> VedaBatchUpload.sql
echo 'ETIR101','ETIB101','ETIS101','EWAV101') then 'elec-cap_other-rens'::varchar(50) when process in('ESOL00','ESOLPV00', >> VedaBatchUpload.sql
echo 'ESOL01','ESOLPV01') then 'elec-cap_solar'::varchar(50) when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01', >> VedaBatchUpload.sql
echo 'ICHCHPCCGT01','ICHCHPCCGTH01', 'ICHCHPCOA00','ICHCHPCOA01','ICHCHPFCH01','ICHCHPGT01','ICHCHPHFO00', 'ICHCHPLFO00', >> VedaBatchUpload.sql
echo 'ICHCHPLPG00','ICHCHPLPG01','ICHCHPNGA00','ICHCHPPRO00', 'ICHCHPPRO01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01', >> VedaBatchUpload.sql
echo 'IFDCHPCCGT01', 'IFDCHPCCGTH01','IFDCHPCOA00','IFDCHPCOA01','IFDCHPFCH01','IFDCHPGT01', 'IFDCHPHFO00','IFDCHPLFO00', >> VedaBatchUpload.sql
echo 'IFDCHPNGA00','IISCHPBFG00','IISCHPBFG01', 'IISCHPBIOG01','IISCHPBIOS01','IISCHPCCGT01','IISCHPCCGTH01','IISCHPCOG00', >> VedaBatchUpload.sql
echo 'IISCHPCOG01','IISCHPFCH01','IISCHPGT01','IISCHPHFO00','IISCHPNGA00', 'INMCHPBIOG01','INMCHPBIOS01','INMCHPCCGT01', >> VedaBatchUpload.sql
echo 'INMCHPCCGTH01','INMCHPCOA01', 'INMCHPCOG00','INMCHPCOG01','INMCHPFCH01','INMCHPGT01','INMCHPNGA00', 'IOICHPBIOG01', >> VedaBatchUpload.sql
echo 'IOICHPBIOS00','IOICHPBIOS01','IOICHPCCGT01','IOICHPCCGTH01', 'IOICHPCOA01','IOICHPFCH01','IOICHPGT01','IOICHPHFO00', >> VedaBatchUpload.sql
echo 'IOICHPNGA00', 'IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPCCGT01','IPPCHPCCGTH01', 'IPPCHPCOA00', >> VedaBatchUpload.sql
echo 'IPPCHPCOA01','IPPCHPFCH01','IPPCHPGT01','IPPCHPNGA00', 'IPPCHPWST00','IPPCHPWST01','PCHP-CCP00','PCHP-CCP01', >> VedaBatchUpload.sql
echo 'RCHPEA-CCG00', 'RCHPEA-CCG01','RCHPEA-CCH01','RCHPEA-FCH01','RCHPEA-STW01','RCHPNA-CCG01', 'RCHPNA-CCH01', >> VedaBatchUpload.sql
echo 'RCHPNA-FCH01','RCHPNA-STW01','RHEACHPRG01','RHEACHPRH01', 'RHEACHPRW01','RHNACHPRG01','RHNACHPRH01','RHNACHPRW01', >> VedaBatchUpload.sql
echo 'SCHP-ADM01', 'SCHP-CCG00','SCHP-CCG01','SCHP-CCH01','SCHP-FCH01','SCHP-GES00','SCHP-GES01', 'SCHP-STM01', >> VedaBatchUpload.sql
echo 'SCHP-STW00','SCHP-STW01','SHLCHPRG01','SHLCHPRH01','SHLCHPRW01', 'UCHP-CCG00','UCHP-CCG01') then >> VedaBatchUpload.sql
echo 'elec-cap_chp'::varchar(50) when process in('ELCIE00','ELCII00','ELCIE01','ELCII01') then >> VedaBatchUpload.sql
echo 'elec-cap_intercon'::varchar(50) end as "analysis", tablename, attribute from vedastore where attribute = 'VAR_Cap' >> VedaBatchUpload.sql
echo and commodity = '-' AND process in( 'ESTWWST00','EPOLWST00', 'EBIOS00','EBOG-LFE00','EBOG-SWE00','EMSW00', >> VedaBatchUpload.sql
echo 'EBIOCON00','ESTWWST01','EBIO01','EBOG-ADE01','EBOG-LFE01','EBOG-SWE01','EMSW01', 'EBIOQ01' ,'ECOA00','ECOABIO00', >> VedaBatchUpload.sql
echo 'ECOARR01','ECOAQ01' ,'ECOAQDEMO01', 'EHYGCCT01' ,'EHYGOCT01','ENGACCT00' ,'ENGAOCT00' ,'ENGACCTRR01' ,'ENGAOCT01', >> VedaBatchUpload.sql
echo 'ENGACCTQ01' ,'ENGACCTQDEMO01','ENUCPWR00' ,'ENUCAGRN00' ,'ENUCAGRO00' , 'ENUCPWR101' ,'ENUCPWR102','EWNDOFF00' , >> VedaBatchUpload.sql
echo 'EWNDOFF101' ,'EWNDOFF201' ,'EWNDOFF301', 'EWNDONS00','EWNDONS101','EWNDONS201','EWNDONS301','EWNDONS401', >> VedaBatchUpload.sql
echo 'EWNDONS501', 'EWNDONS601','EWNDONS701','EWNDONS801','EWNDONS901','EHFOIGCCQ01' ,'EOILL00', 'EOILS00','EMANOCT00', >> VedaBatchUpload.sql
echo 'EMANOCT01','EOILS01','EOILL01','EHFOIGCC01','EHYD00', 'EHYD01','EGEO01','ETIR101','ETIB101','ETIS101','EWAV101', >> VedaBatchUpload.sql
echo 'ESOL00','ESOLPV00', 'ESOL01','ESOLPV01','ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','ICHCHPCCGT01', 'ICHCHPCCGTH01', >> VedaBatchUpload.sql
echo 'ICHCHPCOA00','ICHCHPCOA01','ICHCHPFCH01','ICHCHPGT01', 'ICHCHPHFO00','ICHCHPLFO00','ICHCHPLPG00','ICHCHPLPG01', >> VedaBatchUpload.sql
echo 'ICHCHPNGA00', 'ICHCHPPRO00','ICHCHPPRO01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01', 'IFDCHPCCGT01', >> VedaBatchUpload.sql
echo 'IFDCHPCCGTH01','IFDCHPCOA00','IFDCHPCOA01','IFDCHPFCH01', 'IFDCHPGT01','IFDCHPHFO00','IFDCHPLFO00','IFDCHPNGA00', >> VedaBatchUpload.sql
echo 'IISCHPBFG00', 'IISCHPBFG01','IISCHPBIOG01','IISCHPBIOS01','IISCHPCCGT01','IISCHPCCGTH01', 'IISCHPCOG00', >> VedaBatchUpload.sql
echo 'IISCHPCOG01','IISCHPFCH01','IISCHPGT01','IISCHPHFO00', 'IISCHPNGA00','INMCHPBIOG01','INMCHPBIOS01','INMCHPCCGT01', >> VedaBatchUpload.sql
echo 'INMCHPCCGTH01', 'INMCHPCOA01','INMCHPCOG00','INMCHPCOG01','INMCHPFCH01','INMCHPGT01', 'INMCHPNGA00','IOICHPBIOG01', >> VedaBatchUpload.sql
echo 'IOICHPBIOS00','IOICHPBIOS01','IOICHPCCGT01', 'IOICHPCCGTH01','IOICHPCOA01','IOICHPFCH01','IOICHPGT01','IOICHPHFO00', >> VedaBatchUpload.sql
echo 'IOICHPNGA00','IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPCCGT01', 'IPPCHPCCGTH01','IPPCHPCOA00', >> VedaBatchUpload.sql
echo 'IPPCHPCOA01','IPPCHPFCH01','IPPCHPGT01', 'IPPCHPNGA00','IPPCHPWST00','IPPCHPWST01','PCHP-CCP00','PCHP-CCP01', >> VedaBatchUpload.sql
echo 'RCHPEA-CCG00','RCHPEA-CCG01','RCHPEA-CCH01','RCHPEA-FCH01','RCHPEA-STW01', 'RCHPNA-CCG01','RCHPNA-CCH01', >> VedaBatchUpload.sql
echo 'RCHPNA-FCH01','RCHPNA-STW01','RHEACHPRG01', 'RHEACHPRH01','RHEACHPRW01','RHNACHPRG01','RHNACHPRH01','RHNACHPRW01', >> VedaBatchUpload.sql
echo 'SCHP-ADM01','SCHP-CCG00','SCHP-CCG01','SCHP-CCH01','SCHP-FCH01','SCHP-GES00', 'SCHP-GES01','SCHP-STM01','SCHP-STW00', >> VedaBatchUpload.sql
echo 'SCHP-STW01','SHLCHPRG01','SHLCHPRH01', 'SHLCHPRW01','UCHP-CCG00','UCHP-CCG01','ELCIE00','ELCII00','ELCIE01', >> VedaBatchUpload.sql
echo 'ELCII01') ) a group by id, analysis,tablename, attribute order by tablename, analysis, attribute, commodity ) TO >> VedaBatchUpload.sql
echo '%~dp0ElecCap.csv' delimiter ',' >> VedaBatchUpload.sql
echo CSV; >> VedaBatchUpload.sql
rem /* *costs by sector and type* */
echo /* *costs by sector and type* */ COPY ( select analysis ^|^| '^|' ^|^| tablename ^|^|'^|'^|^| attribute ^|^| >> VedaBatchUpload.sql
echo '^|various' ^|^| '^|various'::varchar(300) "id", analysis, tablename,attribute, 'various'::varchar(50) "commodity", >> VedaBatchUpload.sql
echo 'various'::varchar(50) "process", sum(pv)::numeric "various", sum(case when period='2010' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2010", sum(case when period='2011' then pv else 0 end)::numeric "2011", sum(case when period='2012' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2012", sum(case when period='2015' then pv else 0 end)::numeric "2015", sum(case when >> VedaBatchUpload.sql
echo period='2020' then pv else 0 end)::numeric "2020", sum(case when period='2025' then pv else 0 end)::numeric "2025", >> VedaBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", sum(case when period='2035' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2035", sum(case when period='2040' then pv else 0 end)::numeric "2040", sum(case when period='2045' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2045", sum(case when period='2050' then pv else 0 end)::numeric "2050", sum(case when >> VedaBatchUpload.sql
echo period='2055' then pv else 0 end)::numeric "2055", sum(case when period='2060' then pv else 0 end)::numeric "2060" >> VedaBatchUpload.sql
echo from ( select process, period,pv, case when process like 'T%%' then 'costs_tra'::varchar(50) when process like 'A%%' >> VedaBatchUpload.sql
echo then 'costs_agr'::varchar(50) when process like 'E%%' AND process not like 'EXP%%' then 'costs_elc'::varchar(50) when >> VedaBatchUpload.sql
echo process like 'I%%' AND process not like 'IMP%%' then 'costs_ind'::varchar(50) when process like 'P%%' or process like >> VedaBatchUpload.sql
echo 'C%%' then 'costs_prc'::varchar(50) when process like 'R%%' then 'costs_res'::varchar(50) when process like >> VedaBatchUpload.sql
echo any(array['M%%','U%%','IMP%%','EXP%%']) then 'costs_rsr'::varchar(50) when process like 'S%%' then >> VedaBatchUpload.sql
echo 'costs_ser'::varchar(50) else 'costs_other'::varchar(50) end as "analysis",tablename, attribute from vedastore where >> VedaBatchUpload.sql
echo attribute in('Cost_Act', 'Cost_Flo', 'Cost_Fom', 'Cost_Inv', 'Cost_Salv') union all select 'various'::varchar(50) >> VedaBatchUpload.sql
echo "process", period,pv, 'costs_all'::varchar(50) "analysis", tablename, attribute from vedastore where attribute >> VedaBatchUpload.sql
echo in('Cost_Act','Cost_Flo','Cost_Fom','Cost_Inv','Cost_Salv','ObjZ') ) a group by id, analysis, tablename, attribute >> VedaBatchUpload.sql
echo order by tablename, analysis, attribute ) TO '%~dp0CostsBySec.csv' delimiter ',' >> VedaBatchUpload.sql
echo CSV; >> VedaBatchUpload.sql
rem /* *Marginal prices for emissions* */
echo /* *Marginal prices for emissions* */ COPY ( select 'marg-price^|' ^|^| tablename ^|^| '^|EQ_CombalM^|' ^|^| >> VedaBatchUpload.sql
echo commodity ^|^| '^|-'::varchar(300) "id", 'marg-price'::varchar(50) "analysis", tablename, 'EQ_CombalM'::varchar(50) >> VedaBatchUpload.sql
echo "attribute", commodity, '-'::varchar(50) "process", NULL::numeric "all", sum(case when period='2010' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2010", sum(case when period='2011' then pv else 0 end)::numeric "2011", sum(case when period='2012' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2012", sum(case when period='2015' then pv else 0 end)::numeric "2015", sum(case when >> VedaBatchUpload.sql
echo period='2020' then pv else 0 end)::numeric "2020", sum(case when period='2025' then pv else 0 end)::numeric "2025", >> VedaBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", sum(case when period='2035' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2035", sum(case when period='2040' then pv else 0 end)::numeric "2040", sum(case when period='2045' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2045", sum(case when period='2050' then pv else 0 end)::numeric "2050", sum(case when >> VedaBatchUpload.sql
echo period='2055' then pv else 0 end)::numeric "2055", sum(case when period='2060' then pv else 0 end)::numeric "2060" >> VedaBatchUpload.sql
echo from vedastore where attribute='EQ_CombalM' and commodity in('GHG-NO-IAS-YES-LULUCF-NET','GHG-ETS-NO-IAS-NET', >> VedaBatchUpload.sql
echo 'GHG-YES-IAS-YES-LULUCF-NET','GHG-ETS-YES-IAS-NET') group by tablename, commodity order by tablename, commodity ) TO >> VedaBatchUpload.sql
echo '%~dp0MarginalPricesOut.csv' delimiter ',' >> VedaBatchUpload.sql
echo CSV; >> VedaBatchUpload.sql
rem /* *Whole stock heat output by process for residential* */
echo /* *Whole stock heat output by process for residential* */ COPY ( select analysis ^|^| '^|' ^|^| tablename ^|^| >> VedaBatchUpload.sql
echo '^|' ^|^| attribute ^|^| '^|' ^|^| 'various^|various'::varchar(300) "id", analysis, tablename,attribute, >> VedaBatchUpload.sql
echo 'various'::varchar(50) "commodity", 'various'::varchar(50) "process", sum(pv)::numeric "all", sum(case when >> VedaBatchUpload.sql
echo period='2010' then pv else 0 end)::numeric "2010", sum(case when period='2011' then pv else 0 end)::numeric "2011", >> VedaBatchUpload.sql
echo sum(case when period='2012' then pv else 0 end)::numeric "2012", sum(case when period='2015' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2015", sum(case when period='2020' then pv else 0 end)::numeric "2020", sum(case when period='2025' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2025", sum(case when period='2030' then pv else 0 end)::numeric "2030", sum(case when >> VedaBatchUpload.sql
echo period='2035' then pv else 0 end)::numeric "2035", sum(case when period='2040' then pv else 0 end)::numeric "2040", >> VedaBatchUpload.sql
echo sum(case when period='2045' then pv else 0 end)::numeric "2045", sum(case when period='2050' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2050", sum(case when period='2055' then pv else 0 end)::numeric "2055", sum(case when period='2060' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2060" from ( select process, period,pv, case when process in ('RHEABLCRP01', >> VedaBatchUpload.sql
echo 'RHEABLRRW00', 'RHEABLRRW01','RHEABLSRP01','RHEABLSRW01','RHNABLCRP01','RHNABLRRW01', 'RHNABLSRP01','RHNABLSRW01') >> VedaBatchUpload.sql
echo then 'heat-res_boiler-bio'::varchar(50) when process in('RHEABLCRH01','RHEABLSRH01', 'RHNABLCRH01','RHNABLSRH01') >> VedaBatchUpload.sql
echo then 'heat-res_boiler-h2'::varchar(50) when process in('RHEABLCRO00','RHEABLCRO01', 'RHEABLRRC00','RHEABLRRO00', >> VedaBatchUpload.sql
echo 'RHEABLSRO01','RHNABLCRO01','RHNABLSRO01') then 'heat-res_boiler-otherFF'::varchar(50) when process in('RHEABLRRE00', >> VedaBatchUpload.sql
echo 'RHEABLRRE01', 'RHEABLSRE01','RHEAGHPUE01','RHEASHTRE00','RHEASHTRE01','RHNABLRRE01', 'RHNABLSRE01','RHNAGHPUE01', >> VedaBatchUpload.sql
echo 'RHNASHTRE01','RWEAWHTRE00','RWEAWHTRE01','RWNAWHTRE01') then 'heat-res_boiler/heater-elec'::varchar(50) when process >> VedaBatchUpload.sql
echo in('RHEABLCRG00','RHEABLCRG01', 'RHEABLRRG00','RHEABLSRG01','RHEASHTRG00','RHEASHTRG01','RHNABLCRG01', 'RHNABLSRG01', >> VedaBatchUpload.sql
echo 'RHNASHTRG01','RWEAWHTRG00','RWEAWHTRG01','RWNAWHTRG01') then 'heat-res_boiler/heater-nga'::varchar(50) when process >> VedaBatchUpload.sql
echo in('RHEACSV01','RHEACSVCAV01', 'RHEACSVCAV02','RHEACSVFLR01','RHEACSVLOF02','RHEACSVSOL01','RHEACSVSOL02', >> VedaBatchUpload.sql
echo 'RHEACSVSOL03') then 'heat-res_conserv'::varchar(50) when process in('RHEADHP100','RHEADHP101','RHEADHP201', >> VedaBatchUpload.sql
echo 'RHEADHP301','RHEADHP401', 'RHNADHP101','RHNADHP201','RHNADHP301','RHNADHP401') then 'heat-res_dh'::varchar(50) when >> VedaBatchUpload.sql
echo process in('RHEAAHPRE00','RHEAAHPRE01', 'RHEAAHPUE01','RHEAAHSRE01', 'RHEAAHSUE01','RHEAGHPRE01','RHEAGHSRE01', >> VedaBatchUpload.sql
echo 'RHEAGHSUE01','RHNAAHPRE01','RHNAAHPUE01','RHNAAHSRE01','RHNAAHSUE01', 'RHNAGHPRE01','RHNAGHSRE01','RHNAGHSUE01') >> VedaBatchUpload.sql
echo then 'heat-res_heatpump-elec'::varchar(50) when process in('RHEAAHHRE01','RHEAAHHUE01', 'RHEAGHHRE01','RHEAGHHUE01', >> VedaBatchUpload.sql
echo 'RHNAAHHRE01','RHNAAHHUE01','RHNAGHHRE01','RHNAGHHUE01') then 'heat-res_hyb-boil+hp-h2'::varchar(50) when process >> VedaBatchUpload.sql
echo in('RHEAAHBRE01','RHEAAHBUE01', 'RHEAGHBRE01','RHEAGHBUE01','RHNAAHBRE01','RHNAAHBUE01','RHNAGHBRE01','RHNAGHBUE01') >> VedaBatchUpload.sql
echo then 'heat-res_hyb-boil+hp-nga'::varchar(50) when process in('RHEACHPRW01','RHNACHPRW01') then >> VedaBatchUpload.sql
echo 'heat-res_microchp-bio'::varchar(50) when process in('RHEACHBRH01','RHEACHPRH01', 'RHNACHBRH01','RHNACHPRH01') then >> VedaBatchUpload.sql
echo 'heat-res_microchp-h2'::varchar(50) when process in('RHEACHPRG01','RHNACHPRG01') then >> VedaBatchUpload.sql
echo 'heat-res_microchp-nga'::varchar(50) when process in('RHEANSTRE00','RHEANSTRE01','RHEASTGNT00','RHEASTGNT01', >> VedaBatchUpload.sql
echo 'RHNANSTRE01','RHNASTGNT01') then 'heat-res_storheater-elec'::varchar(50) else 'heat-res_other' end as "analysis", >> VedaBatchUpload.sql
echo tablename, attribute from vedastore where attribute = 'VAR_FOut' AND commodity in('RHCSV-RHEA','RHEATPIPE-EA', >> VedaBatchUpload.sql
echo 'RHEATPIPE-NA','RHSTAND-EA', 'RHSTAND-NA','RHUFLOOR-EA','RHUFLOOR-NA','RWCSV-RWEA','RWSTAND-EA','RWSTAND-NA') group >> VedaBatchUpload.sql
echo by period,process, pv,tablename, id, analysis, attribute order by tablename, attribute ) a group by id, analysis, >> VedaBatchUpload.sql
echo tablename, attribute order by tablename, analysis, attribute, commodity ) TO '%~dp0ResWholeHeatOut.csv' delimiter ',' >> VedaBatchUpload.sql
echo CSV; >> VedaBatchUpload.sql
rem /* *New build residential heat output by source* */
echo /* *New build residential heat output by source* */ COPY ( select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| >> VedaBatchUpload.sql
echo attribute ^|^| '^|' ^|^| 'various^|various'::varchar(300) "id", analysis, tablename,attribute, 'various'::varchar(50) >> VedaBatchUpload.sql
echo "commodity", 'various'::varchar(50) "process", sum(pv)::numeric "all", sum(case when period='2010' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2010", sum(case when period='2011' then pv else 0 end)::numeric "2011", sum(case when period='2012' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2012", sum(case when period='2015' then pv else 0 end)::numeric "2015", sum(case when >> VedaBatchUpload.sql
echo period='2020' then pv else 0 end)::numeric "2020", sum(case when period='2025' then pv else 0 end)::numeric "2025", >> VedaBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", sum(case when period='2035' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2035", sum(case when period='2040' then pv else 0 end)::numeric "2040", sum(case when period='2045' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2045", sum(case when period='2050' then pv else 0 end)::numeric "2050", sum(case when >> VedaBatchUpload.sql
echo period='2055' then pv else 0 end)::numeric "2055", sum(case when period='2060' then pv else 0 end)::numeric "2060" >> VedaBatchUpload.sql
echo from ( select process,commodity, period,pv, case when process in('RHEABLCRP01','RHEABLRRW00','RHEABLRRW01', >> VedaBatchUpload.sql
echo 'RHEABLSRP01', 'RHEABLSRW01','RHNABLCRP01','RHNABLRRW01','RHNABLSRP01','RHNABLSRW01') then >> VedaBatchUpload.sql
echo 'new-heat-res_boiler-bio'::varchar(50) when process in('RHEABLCRH01','RHEABLSRH01','RHNABLCRH01','RHNABLSRH01') then >> VedaBatchUpload.sql
echo 'new-heat-res_boiler-h2'::varchar(50) when process in('RHEABLCRO00','RHEABLCRO01','RHEABLRRC00','RHEABLRRO00', >> VedaBatchUpload.sql
echo 'RHEABLSRO01','RHNABLCRO01','RHNABLSRO01') then 'new-heat-res_boiler-otherFF'::varchar(50) when process >> VedaBatchUpload.sql
echo in('RHEABLRRE00','RHEABLRRE01','RHEABLSRE01','RHEAGHPUE01', 'RHEASHTRE00','RHEASHTRE01','RHNABLRRE01','RHNABLSRE01', >> VedaBatchUpload.sql
echo 'RHNAGHPUE01', 'RHNASHTRE01','RWEAWHTRE00','RWEAWHTRE01','RWNAWHTRE01') then >> VedaBatchUpload.sql
echo 'new-heat-res_boiler/heater-elec'::varchar(50) when process in('RHEABLCRG00','RHEABLCRG01','RHEABLRRG00', >> VedaBatchUpload.sql
echo 'RHEABLSRG01', 'RHEASHTRG00','RHEASHTRG01','RHNABLCRG01','RHNABLSRG01','RHNASHTRG01', 'RWEAWHTRG00','RWEAWHTRG01', >> VedaBatchUpload.sql
echo 'RWNAWHTRG01') then 'new-heat-res_boiler/heater-nga'::varchar(50) when process in('RHEACSV01','RHEACSVCAV01', >> VedaBatchUpload.sql
echo 'RHEACSVCAV02','RHEACSVFLR01', 'RHEACSVLOF02','RHEACSVSOL01','RHEACSVSOL02','RHEACSVSOL03') then >> VedaBatchUpload.sql
echo 'new-heat-res_conserv'::varchar(50) when process in('RHEADHP100','RHEADHP101','RHEADHP201','RHEADHP301','RHEADHP401', >> VedaBatchUpload.sql
echo 'RHNADHP101','RHNADHP201','RHNADHP301','RHNADHP401') then 'new-heat-res_dh'::varchar(50) when process >> VedaBatchUpload.sql
echo in('RHEAAHPRE00','RHEAAHPRE01','RHEAAHPUE01','RHEAAHSRE01', 'RHEAAHSUE01','RHEAGHPRE01','RHEAGHSRE01','RHEAGHSUE01', >> VedaBatchUpload.sql
echo 'RHNAAHPRE01', 'RHNAAHPUE01','RHNAAHSRE01','RHNAAHSUE01','RHNAGHPRE01','RHNAGHSRE01','RHNAGHSUE01') then >> VedaBatchUpload.sql
echo 'new-heat-res_heatpump-elec'::varchar(50) when process in('RHEAAHHRE01','RHEAAHHUE01','RHEAGHHRE01','RHEAGHHUE01', >> VedaBatchUpload.sql
echo 'RHNAAHHRE01','RHNAAHHUE01','RHNAGHHRE01','RHNAGHHUE01') then 'new-heat-res_hyb-boil+hp-h2'::varchar(50) when process >> VedaBatchUpload.sql
echo in('RHEAAHBRE01','RHEAAHBUE01','RHEAGHBRE01','RHEAGHBUE01', 'RHNAAHBRE01','RHNAAHBUE01','RHNAGHBRE01','RHNAGHBUE01') >> VedaBatchUpload.sql
echo then 'new-heat-res_hyb-boil+hp-nga'::varchar(50) when process in('RHEACHPRW01','RHNACHPRW01') then >> VedaBatchUpload.sql
echo 'new-heat-res_microchp-bio'::varchar(50) when process in('RHEACHBRH01','RHEACHPRH01','RHNACHBRH01','RHNACHPRH01') >> VedaBatchUpload.sql
echo then 'new-heat-res_microchp-h2'::varchar(50) when process in('RHEACHPRG01','RHNACHPRG01') then >> VedaBatchUpload.sql
echo 'new-heat-res_microchp-nga'::varchar(50) when process in('RHEANSTRE00','RHEANSTRE01','RHEASTGNT00','RHEASTGNT01', >> VedaBatchUpload.sql
echo 'RHNANSTRE01','RHNASTGNT01') then 'new-heat-res_storheater-elec'::varchar(50) end as "analysis", tablename, attribute >> VedaBatchUpload.sql
echo from vedastore where attribute = 'VAR_FOut' AND commodity in('RHCSV-RHEA','RHEATPIPE-EA','RHEATPIPE-NA','RHSTAND-EA', >> VedaBatchUpload.sql
echo 'RHSTAND-NA', 'RHUFLOOR-EA','RHUFLOOR-NA','RWCSV-RWEA','RWSTAND-EA','RWSTAND-NA') and vintage=period group by period, >> VedaBatchUpload.sql
echo commodity,process, pv,tablename, id, analysis, attribute order by tablename, attribute ) a where analysis ^<^> '' >> VedaBatchUpload.sql
echo group by id, analysis,tablename, attribute order by tablename, analysis, attribute, commodity ) TO >> VedaBatchUpload.sql
echo '%~dp0NewResHeatOut.csv' delimiter ',' >> VedaBatchUpload.sql
echo CSV; >> VedaBatchUpload.sql
rem /* *Whole stock heat output for services* */
echo /* *Whole stock heat output for services* */ COPY ( select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| >> VedaBatchUpload.sql
echo attribute ^|^| '^|' ^|^| 'various^|various'::varchar(300) "id", analysis, tablename,attribute, 'various'::varchar(50) >> VedaBatchUpload.sql
echo "commodity", 'various'::varchar(50) "process", sum(pv)::numeric "all", sum(case when period='2010' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2010", sum(case when period='2011' then pv else 0 end)::numeric "2011", sum(case when period='2012' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2012", sum(case when period='2015' then pv else 0 end)::numeric "2015", sum(case when >> VedaBatchUpload.sql
echo period='2020' then pv else 0 end)::numeric "2020", sum(case when period='2025' then pv else 0 end)::numeric "2025", >> VedaBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", sum(case when period='2035' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2035", sum(case when period='2040' then pv else 0 end)::numeric "2040", sum(case when period='2045' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2045", sum(case when period='2050' then pv else 0 end)::numeric "2050", sum(case when >> VedaBatchUpload.sql
echo period='2055' then pv else 0 end)::numeric "2055", sum(case when period='2060' then pv else 0 end)::numeric "2060" >> VedaBatchUpload.sql
echo from ( select process, period,pv, case when process in ('SHLSHTRE00','SWLWHTRE00','SHLBLRRE01','SHLSHTRE01', >> VedaBatchUpload.sql
echo 'SWLWHTRE01','SHLBLSRE01','SHHBLRRE00','SWHWHTRE00','SHHBLRRE01','SWHWHTRE01','SHLBLRRE00') then >> VedaBatchUpload.sql
echo 'heat-ser_boiler/heater-elec' when process in('SHLBLCRG00','SHLSHTRG00','SWLWHTRG00','SHLBLCRG01','SWLWHTRG01', >> VedaBatchUpload.sql
echo 'SHLBLSRG01','SHHBLRRG00','SWHBLRRG00','SHHBLRRG01','SWHBLRRG01','SHLBLRRG00') then 'heat-ser_boiler/heater-nga' when >> VedaBatchUpload.sql
echo process in('SHLBLCRP01','SHLBLRRW01','SHLBLSRP01','SHLBLSRW01','SHHBLRRW00', 'SWHBLRRW00','SHHBLRRW01','SWHBLRRW01', >> VedaBatchUpload.sql
echo 'SHLBLRRW00') then 'heat-ser_boiler-bio' when process in('SHLBLSRH01','SHHBLRRH01','SWHBLRRH01','SHLBLCRH01') then >> VedaBatchUpload.sql
echo 'heat-ser_boiler-h2' when process in('SHLBLCRO00','SHLBLRRC00','SHLSHTRO00','SHLBLCRO01','SHLBLSRO01', 'SHHBLRRO00', >> VedaBatchUpload.sql
echo 'SHHBLRRC00','SWHBLRRO00','SWHBLRRC00','SHHBLRRO01','SHHBLRRC01', 'SWHBLRRO01','SWHBLRRC01','SHLBLRRO00') then >> VedaBatchUpload.sql
echo 'heat-ser_boiler-otherFF' when process in('SCSLROFF01','SCSLROFP01','SCSLCAVW01','SCSHPTHM01','SCSHROFF01', >> VedaBatchUpload.sql
echo 'SCSHROFP01','SCSHCAVW01','SCSLPTHM01') then 'heat-ser_conserv' when process in('SHLAHBUE01','SHLGHBRE01', >> VedaBatchUpload.sql
echo 'SHLGHBUE01','SHLAHBRE01') then 'heat-ser_hyb-boil+hp-nga' when process in('SHLAHPRE01','SHLAHPUE01','SHLGHPRE01', >> VedaBatchUpload.sql
echo 'SHLGHPUE01','SHLAHSRE01', 'SHLAHSUE01','SHLGHSRE01','SHLGHSUE01','SHLAHPRE00') then 'heat-ser_heatpump-elec' when >> VedaBatchUpload.sql
echo process in('SHHVACAE01','SHHVACAE00') then 'heat-ser_hvac' when process in('SHHVACAE02') then 'heat-ser_hvac-ad' when >> VedaBatchUpload.sql
echo process in('SHLAHHUE01','SHLGHHRE01','SHLGHHUE01','SHLAHHRE01') then 'heat-ser_hyb-boil+hp-h2' when process >> VedaBatchUpload.sql
echo in('SHLDHP101','SHHDHP100','SHHDHP101','SHLDHP100') then 'heat-ser_dh' when process in('SHLCHPRW01') then >> VedaBatchUpload.sql
echo 'heat-ser_microchp-bio' when process in('SHLCHBRH01','SHHFCLRH01','SHLCHPRH01') then 'heat-ser_microchp-h2' when >> VedaBatchUpload.sql
echo process in('SHLCHPRG01') then 'heat-ser_microchp-nga' when process in('SHLNSTRE01','SHLNSTRE00') then >> VedaBatchUpload.sql
echo 'heat-ser_storheater-elec' else 'heat-ser_other' end as "analysis", tablename, attribute from vedastore where >> VedaBatchUpload.sql
echo attribute = 'VAR_FOut' AND commodity in('SHHCSVDMD','SHHDELVAIR','SHHDELVRAD', 'SHLCSVDMD','SHLDELVAIR','SHLDELVRAD', >> VedaBatchUpload.sql
echo 'SHLDELVUND','SWHDELVPIP','SWHDELVSTD','SWLDELVSTD') group by period,process, pv,tablename, id, analysis, attribute >> VedaBatchUpload.sql
echo order by tablename, attribute ) a group by id, analysis,tablename, attribute order by tablename, analysis, attribute, >> VedaBatchUpload.sql
echo commodity ) TO '%~dp0ServWholeHeatOut.csv' delimiter ',' >> VedaBatchUpload.sql
echo CSV; >> VedaBatchUpload.sql
rem /* *New build services heat output by source* */
echo /* *New build services heat output by source* */ COPY ( select analysis ^|^| '^|' ^|^| tablename ^|^| '^|' ^|^| >> VedaBatchUpload.sql
echo attribute ^|^| '^|' ^|^| 'various^|various'::varchar(300) "id", analysis, tablename,attribute, 'various'::varchar(50) >> VedaBatchUpload.sql
echo "commodity", 'various'::varchar(50) "process", sum(pv)::numeric "all", sum(case when period='2010' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2010", sum(case when period='2011' then pv else 0 end)::numeric "2011", sum(case when period='2012' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2012", sum(case when period='2015' then pv else 0 end)::numeric "2015", sum(case when >> VedaBatchUpload.sql
echo period='2020' then pv else 0 end)::numeric "2020", sum(case when period='2025' then pv else 0 end)::numeric "2025", >> VedaBatchUpload.sql
echo sum(case when period='2030' then pv else 0 end)::numeric "2030", sum(case when period='2035' then pv else 0 >> VedaBatchUpload.sql
echo end)::numeric "2035", sum(case when period='2040' then pv else 0 end)::numeric "2040", sum(case when period='2045' >> VedaBatchUpload.sql
echo then pv else 0 end)::numeric "2045", sum(case when period='2050' then pv else 0 end)::numeric "2050", sum(case when >> VedaBatchUpload.sql
echo period='2055' then pv else 0 end)::numeric "2055", sum(case when period='2060' then pv else 0 end)::numeric "2060" >> VedaBatchUpload.sql
echo from ( select process, period,pv, case when process in ('SHLSHTRE00','SWLWHTRE00','SHLBLRRE01','SHLSHTRE01', >> VedaBatchUpload.sql
echo 'SWLWHTRE01','SHLBLSRE01','SHHBLRRE00','SWHWHTRE00','SHHBLRRE01','SWHWHTRE01', 'SHLBLRRE00') then >> VedaBatchUpload.sql
echo 'new-heat-ser_boiler/heater-elec' when process in('SHLBLCRG00','SHLSHTRG00','SWLWHTRG00','SHLBLCRG01','SWLWHTRG01', >> VedaBatchUpload.sql
echo 'SHLBLSRG01','SHHBLRRG00','SWHBLRRG00','SHHBLRRG01','SWHBLRRG01','SHLBLRRG00') then 'new-heat-ser_boiler/heater-nga' >> VedaBatchUpload.sql
echo when process in('SHLBLCRP01','SHLBLRRW01','SHLBLSRP01','SHLBLSRW01','SHHBLRRW00', 'SWHBLRRW00','SHHBLRRW01', >> VedaBatchUpload.sql
echo 'SWHBLRRW01','SHLBLRRW00') then 'new-heat-ser_boiler-bio' when process in('SHLBLSRH01','SHHBLRRH01','SWHBLRRH01', >> VedaBatchUpload.sql
echo 'SHLBLCRH01') then 'new-heat-ser_boiler-h2' when process in('SHLBLCRO00','SHLBLRRC00','SHLSHTRO00','SHLBLCRO01', >> VedaBatchUpload.sql
echo 'SHLBLSRO01', 'SHHBLRRO00','SHHBLRRC00','SWHBLRRO00','SWHBLRRC00','SHHBLRRO01','SHHBLRRC01', 'SWHBLRRO01', >> VedaBatchUpload.sql
echo 'SWHBLRRC01','SHLBLRRO00') then 'new-heat-ser_boiler-otherFF' when process in('SCSLROFF01','SCSLROFP01','SCSLCAVW01', >> VedaBatchUpload.sql
echo 'SCSHPTHM01','SCSHROFF01', 'SCSHROFP01','SCSHCAVW01','SCSLPTHM01') then 'new-heat-ser_conserv' when process >> VedaBatchUpload.sql
echo in('SHLAHBUE01','SHLGHBRE01','SHLGHBUE01','SHLAHBRE01') then 'new-heat-ser_hyb-boil+hp-nga' when process >> VedaBatchUpload.sql
echo in('SHLAHPRE01','SHLAHPUE01','SHLGHPRE01','SHLGHPUE01','SHLAHSRE01', 'SHLAHSUE01','SHLGHSRE01','SHLGHSUE01', >> VedaBatchUpload.sql
echo 'SHLAHPRE00') then 'new-heat-ser_heatpump-elec' when process in('SHHVACAE01','SHHVACAE00') then 'new-heat-ser_hvac' >> VedaBatchUpload.sql
echo when process in('SHHVACAE02') then 'new-heat-ser_hvac-ad' when process in('SHLAHHUE01','SHLGHHRE01','SHLGHHUE01', >> VedaBatchUpload.sql
echo 'SHLAHHRE01') then 'new-heat-ser_hyb-boil+hp-h2' when process in('SHLDHP101','SHHDHP100','SHHDHP101','SHLDHP100') >> VedaBatchUpload.sql
echo then 'new-heat-ser_dh' when process in('SHLCHPRW01') then 'new-heat-ser_microchp-bio' when process in('SHLCHBRH01', >> VedaBatchUpload.sql
echo 'SHHFCLRH01','SHLCHPRH01') then 'new-heat-ser_microchp-h2' when process in('SHLCHPRG01') then >> VedaBatchUpload.sql
echo 'new-heat-ser_microchp-nga' when process in('SHLNSTRE01','SHLNSTRE00') then 'new-heat-ser_storheater-elec' else >> VedaBatchUpload.sql
echo 'new-new-heat-ser_other' end as "analysis", tablename, attribute from vedastore where attribute = 'VAR_FOut' AND >> VedaBatchUpload.sql
echo commodity in('SHHCSVDMD','SHHDELVAIR','SHHDELVRAD','SHLCSVDMD', 'SHLDELVAIR','SHLDELVRAD','SHLDELVUND','SWHDELVPIP', >> VedaBatchUpload.sql
echo 'SWHDELVSTD','SWLDELVSTD') and vintage=period group by period,process, pv,tablename, id, analysis, attribute order by >> VedaBatchUpload.sql
echo tablename, attribute ) a group by id, analysis,tablename, attribute order by tablename, analysis, attribute, >> VedaBatchUpload.sql
echo commodity ) TO '%~dp0NewServHeatOut.csv' delimiter ',' >> VedaBatchUpload.sql
echo CSV; >> VedaBatchUpload.sql
rem /* *End user final energy demand by sector* */
echo /* *End user final energy demand by sector* */ COPY ( with hydrogen_chp as ( select chp_hyd,commodity, period, >> VedaBatchUpload.sql
echo tablename,sum(pv) "pv" from ( select case when process in ('RHFCBLCRH01','RHFSBLCRH01','RHHCBLCRH01','RHHSBLCRH01', >> VedaBatchUpload.sql
echo 'RHNABLCRH01', 'RHFCCHBRH01','RHFSCHBRH01','RHHCCHBRH01','RHHSCHBRH01','RHNACHBRH01','RHEABLCRH01','RHEACHBRH01') >> VedaBatchUpload.sql
echo then 'RES BOI HYG' when process in ('RHFCCHPRH01','RHFSCHPRH01','RHHCCHPRH01','RHHSCHPRH01','RHNACHPRH01', >> VedaBatchUpload.sql
echo 'RHEACHPRH01') then 'RES MCHP HYG' when process in ('RHFCREFCG01','RHFSREFCG01','RHHCREFCG01','RHHSREFCG01', >> VedaBatchUpload.sql
echo 'RHNAREFCG01','RHEAREFCG01') then 'RES REFORMER' when process in ('SHHBLRRH01','SHLBLCRH01','SHLCHBRH01') then 'SER BOI HYG' >> VedaBatchUpload.sql
echo when process in ('SHHFCLRH01','SHLCHPRH01') then 'SER MCHP HYG' when process in ('SHLREFCG01') then 'SER REFORMER' >> VedaBatchUpload.sql
echo else null end as chp_hyd, tablename, commodity,pv,period from vedastore where attribute='VAR_FIn' ) a where >> VedaBatchUpload.sql
echo chp_hyd is not null group by tablename, period, chp_hyd,commodity ) ,reformer_factors as( select period, tablename, >> VedaBatchUpload.sql
echo case when res_chp_reformer_h2+res_chp_mains_h2^>0 then res_chp_reformer_h2/(res_chp_reformer_h2+res_chp_mains_h2) >> VedaBatchUpload.sql
echo else 0 end chp_gas_for_h_res_mult, case when ser_chp_reformer_h2+ser_chp_mains_h2^>0 then >> VedaBatchUpload.sql
echo ser_chp_reformer_h2/(ser_chp_reformer_h2+ser_chp_mains_h2) else 0 end chp_gas_for_h_ser_mult from ( select sum(case >> VedaBatchUpload.sql
echo when chp_hyd='RES MCHP HYG' and commodity='RESHOUSEHYG' then pv else 0 end) res_chp_mains_h2, sum(case when >> VedaBatchUpload.sql
echo chp_hyd='RES MCHP HYG' and commodity in('RESHYGREF-FC','RESHYGREF-FS', 'RESHYGREF-HC','RESHYGREF-HS','RESHYGREF-NA') >> VedaBatchUpload.sql
echo then pv else 0 end) res_chp_reformer_h2, sum(case when chp_hyd='SER MCHP HYG' and commodity ='SERHYGREF' then pv else >> VedaBatchUpload.sql
echo 0 end) ser_chp_reformer_h2, sum(case when chp_hyd='SER MCHP HYG' and commodity in('SERBUILDHYG','SERMAINSHYG') then >> VedaBatchUpload.sql
echo pv else 0 end) ser_chp_mains_h2 ,tablename,period from hydrogen_chp group by tablename,period ) a ) , chp_fuels as ( >> VedaBatchUpload.sql
echo select chp_sec, chp_fuel, period, tablename,sum(pv) "pv" from ( select case when commodity in('AGRBIODST','AGRBIOLPG', >> VedaBatchUpload.sql
echo 'AGRBOM','AGRGRASS', 'AGRMAINSBOM','AGRPOLWST','BGRASS','BIODST','BIODST-FT','BIOJET-FT','BIOKER-FT','BIOLFO', >> VedaBatchUpload.sql
echo 'BIOLPG','BIOOIL','BOG-AD', 'BOG-G','BOG-LF','BOM','BPELH','BPELL','BRSEED','BSEWSLG','BSLURRY','BSTARCH','BSTWWST', >> VedaBatchUpload.sql
echo 'BSUGAR','BTREATSTW', 'BTREATWOD','BVOIL','BWOD','BWODLOG','BWODWST','ELCBIOLFO','ELCBIOOIL','ELCBOG-AD','ELCBOG-LF', >> VedaBatchUpload.sql
echo 'ELCBOG-SW', 'ELCBOM','ELCMAINSBOM','ELCMSWINO','ELCMSWORG','ELCPELH','ELCPELL','ELCPOLWST','ELCSTWWST','ELCTRANSBOM', >> VedaBatchUpload.sql
echo 'ETH', 'HYGBIOO','HYGBPEL','HYGMSWINO','HYGMSWORG','INDBIOLFO','INDBIOLPG','INDBIOOIL','INDBOG-AD','INDBOG-LF', >> VedaBatchUpload.sql
echo 'INDBOM', 'INDGRASS','INDMAINSBOM','INDMSWINO','INDMSWORG','INDPELH','INDPELL','INDPOLWST','INDWOD','INDWODWST', >> VedaBatchUpload.sql
echo 'METH', 'MSWBIO','MSWINO','MSWORG','PWASTEDUM','RESBIOLFO','RESBOM','RESHOUSEBOM','RESMAINSBOM','RESPELH','RESWOD', >> VedaBatchUpload.sql
echo 'RESWODL','SERBIOLFO','SERBOG','SERBOM','SERBUILDBOM','SERMAINSBOM','SERMSWBIO','SERMSWINO','SERMSWORG', 'SERPELH', >> VedaBatchUpload.sql
echo 'SERWOD','TRABIODST','TRABIODST-FT','TRABIODST-FTL','TRABIODST-FTS','TRABIODSTL','TRABIODSTS','TRABIOJET-FTDA', >> VedaBatchUpload.sql
echo 'TRABIOJET-FTDAL','TRABIOJET-FTIA','TRABIOJET-FTIAL','TRABIOLFO','TRABIOLFODS','TRABIOLFODSL','TRABIOLFOL', >> VedaBatchUpload.sql
echo 'TRABIOOILIS', 'TRABIOOILISL','TRABOM','TRAETH','TRAETHL','TRAETHS','TRAMAINSBOM','TRAMETH','ELCBIOCOA','ELCBIOCOA2', >> VedaBatchUpload.sql
echo 'TRAPET','TRAPETS' ) then 'ALL BIO' when commodity in ('AGRCOA','COA','COA-E','COACOK','ELCCOA','HYGCOA','INDCOA', >> VedaBatchUpload.sql
echo 'INDCOACOK','INDSYNCOA','PRCCOA','PRCCOACOK','RESCOA','SERCOA','SYNCOA','TRACOA') then 'ALL COALS' when commodity >> VedaBatchUpload.sql
echo in('AGRHYG','ELCHYG','ELCHYGIGCC','HYGL','HYGL-IGCC','HYGLHPD','HYGLHPT','HYL','HYLTK','INDHYG','INDMAINSHYG', >> VedaBatchUpload.sql
echo 'RESHOUSEHYG', 'RESHYG','RESHYGREF-EA','RESHYGREF-NA','RESMAINSHYG','SERBUILDHYG','SERHYG','SERMAINSHYG','TRAHYG', >> VedaBatchUpload.sql
echo 'TRAHYGDCN','TRAHYGL', 'TRAHYGS','TRAHYL','UPSHYG','UPSMAINSHYG') then 'ALL HYDROGEN' when commodity in ('BENZ','BFG', >> VedaBatchUpload.sql
echo 'COG','COK','ELCBFG','ELCCOG','IISBFGB','IISBFGC','IISCOGB','IISCOGC','IISCOKB','IISCOKE','IISCOKS', 'INDBENZ', >> VedaBatchUpload.sql
echo 'INDBFG','INDCOG','INDCOK','RESCOK') then 'ALL MANFUELS' when commodity in ('AGRHFO','AGRLFO','AGRLPG','ELCHFO', >> VedaBatchUpload.sql
echo 'ELCLFO','ELCLPG','ELCMSC','IISHFOB','INDHFO','INDKER','INDLFO','INDLPG','INDNEULFO', 'INDNEULPG','INDNEUMSC', >> VedaBatchUpload.sql
echo 'INDSYNOIL','OILCRD','OILCRDRAW','OILCRDRAW-E','OILDST','OILHFO','OILJET','OILKER','OILLFO','OILLPG','OILMSC', >> VedaBatchUpload.sql
echo 'OILPET','PRCHFO','PRCOILCRD','RESKER','RESLFO','RESLPG','SERHFO','SERKER','SERLFO','SERLPG','SYNOIL','TRADST', >> VedaBatchUpload.sql
echo 'TRADSTL','TRADSTS','TRAHFO', 'TRAHFODS','TRAHFODSL','TRAHFOIS','TRAHFOISL','TRAJETDA','TRAJETDAEL','TRAJETIA', >> VedaBatchUpload.sql
echo 'TRAJETIAEL','TRAJETIANL','TRAJETL','TRALFO','TRALFODS', 'TRALFODSL','TRALFOL','TRALPG','TRALPGL','TRALPGS','TRAPET', >> VedaBatchUpload.sql
echo 'TRAPETL','TRAPETS','UPSLFO') then 'ALL OIL PRODUCTS' when commodity in('INDMAINSGAS','INDNGA') then 'IND GAS' when >> VedaBatchUpload.sql
echo commodity in('ICHPRO') then 'IND PRO' when commodity in('PRCNGA') then 'PRC GAS' when commodity in('PREFGAS') then >> VedaBatchUpload.sql
echo 'PRC REFGAS' when commodity in('RESMAINSGAS','RESNGA') then 'RES GAS' when commodity in('SERMAINSGAS','SERNGA') then >> VedaBatchUpload.sql
echo 'SER GAS' when commodity in('UPSNGA') then 'UPS GAS' else null end as chp_fuel, case when process in('ICHCHPBIOG01', >> VedaBatchUpload.sql
echo 'ICHCHPBIOS00','ICHCHPBIOS01','ICHCHPCCGT01','ICHCHPCCGTH01','ICHCHPCOA00','ICHCHPCOA01', 'ICHCHPFCH01','ICHCHPGT01', >> VedaBatchUpload.sql
echo 'ICHCHPHFO00','ICHCHPLFO00','ICHCHPLPG00','ICHCHPLPG01','ICHCHPNGA00','ICHCHPPRO00', 'ICHCHPPRO01','IFDCHPBIOG01', >> VedaBatchUpload.sql
echo 'IFDCHPBIOS00','IFDCHPBIOS01','IFDCHPCCGT01','IFDCHPCCGTH01','IFDCHPCOA00', 'IFDCHPCOA01','IFDCHPFCH01','IFDCHPGT01', >> VedaBatchUpload.sql
echo 'IFDCHPHFO00','IFDCHPLFO00','IFDCHPNGA00','IISCHPBFG00','IISCHPBFG01', 'IISCHPBIOG01','IISCHPBIOS01','IISCHPCCGT01', >> VedaBatchUpload.sql
echo 'IISCHPCCGTH01','IISCHPCOG00','IISCHPCOG01','IISCHPFCH01', 'IISCHPGT01','IISCHPHFO00','IISCHPNGA00','INMCHPBIOG01', >> VedaBatchUpload.sql
echo 'INMCHPBIOS01','INMCHPCCGT01','INMCHPCCGTH01','INMCHPCOA01', 'INMCHPCOG00','INMCHPCOG01','INMCHPFCH01','INMCHPGT01', >> VedaBatchUpload.sql
echo 'INMCHPNGA00','IOICHPBIOG01','IOICHPBIOS00','IOICHPBIOS01', 'IOICHPCCGT01','IOICHPCCGTH01','IOICHPCOA01', >> VedaBatchUpload.sql
echo 'IOICHPFCH01','IOICHPGT01','IOICHPHFO00','IOICHPNGA00','IPPCHPBIOG01', 'IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPCCGT01', >> VedaBatchUpload.sql
echo 'IPPCHPCCGTH01','IPPCHPCOA00','IPPCHPCOA01','IPPCHPFCH01','IPPCHPGT01', 'IPPCHPNGA00','IPPCHPWST00','IPPCHPWST01') >> VedaBatchUpload.sql
echo then 'CHP IND SECTOR' when process in('PCHP-CCP00','PCHP-CCP01') then 'CHP PRC SECTOR' when process in('RCHPEA-CCG00', >> VedaBatchUpload.sql
echo 'RCHPEA-CCG01','RCHPEA-CCH01','RCHPEA-FCH01','RCHPEA-STW01','RCHPNA-CCG01','RCHPNA-CCH01', 'RCHPNA-FCH01', >> VedaBatchUpload.sql
echo 'RCHPNA-STW01','RHEACHPRG01','RHEACHPRH01','RHEACHPRW01','RHNACHPRG01','RHNACHPRH01', 'RHNACHPRW01') then 'CHP RES SECTOR' >> VedaBatchUpload.sql
echo  when process in('SCHP-ADM01','SCHP-CCG00','SCHP-CCG01','SCHP-CCH01','SCHP-FCH01','SCHP-GES00','SCHP-GES01', >> VedaBatchUpload.sql
echo 'SCHP-STM01','SCHP-STW00','SCHP-STW01','SHHFCLRH01','SHLCHPRG01','SHLCHPRH01','SHLCHPRW01') then 'CHP SER SECTOR' >> VedaBatchUpload.sql
echo when process in('UCHP-CCG00','UCHP-CCG01') then 'CHP UPS SECTOR' else null end as chp_sec,* from vedastore where >> VedaBatchUpload.sql
echo attribute='VAR_FIn' ) a where chp_sec is not null and chp_fuel is not null group by tablename, period,chp_sec, >> VedaBatchUpload.sql
echo chp_fuel ), chp_fuels_used as ( select a.tablename,a.period, a.res_bio, a.res_gas+(case when b.chp_gas_for_h_res is >> VedaBatchUpload.sql
echo null then 0 else b.chp_gas_for_h_res end) "res_gas", a.res_hyd, a.ser_bio, a.ser_gas+(case when b.chp_gas_for_h_ser >> VedaBatchUpload.sql
echo is null then 0 else b.chp_gas_for_h_ser end) "ser_gas", a.ser_hyd,a.ind_bio,a.ind_gas,a.ind_hyd,a.ind_coa,a.ind_oil, >> VedaBatchUpload.sql
echo a.ind_man,a.ind_bypro,a.prc_gas, a.prc_refgas,a.prc_oil, ups_gas from( select tablename,period, sum(case when >> VedaBatchUpload.sql
echo chp_sec='CHP RES SECTOR' and chp_fuel='ALL BIO' then pv else 0 end) "res_bio", sum(case when chp_sec='CHP RES SECTOR' >> VedaBatchUpload.sql
echo and chp_fuel='RES GAS' then pv else 0 end) "res_gas", sum(case when chp_sec='CHP RES SECTOR' and chp_fuel='ALL HYDROGEN' >> VedaBatchUpload.sql
echo  then pv else 0 end) "res_hyd", sum(case when chp_sec='CHP SER SECTOR' and chp_fuel='ALL BIO' then pv else 0 >> VedaBatchUpload.sql
echo end) "ser_bio", sum(case when chp_sec='CHP SER SECTOR' and chp_fuel='SER GAS' then pv else 0 end) "ser_gas", sum(case >> VedaBatchUpload.sql
echo when chp_sec='CHP SER SECTOR' and chp_fuel='ALL HYDROGEN' then pv else 0 end) "ser_hyd", sum(case when chp_sec='CHP IND SECTOR' >> VedaBatchUpload.sql
echo  and chp_fuel='ALL BIO' then pv else 0 end) "ind_bio", sum(case when chp_sec='CHP IND SECTOR' and >> VedaBatchUpload.sql
echo chp_fuel='IND GAS' then pv else 0 end) "ind_gas", sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL HYDROGEN' >> VedaBatchUpload.sql
echo then pv else 0 end) "ind_hyd", sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL COALS' then pv else 0 end) >> VedaBatchUpload.sql
echo "ind_coa", sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL OIL PRODUCTS' then pv else 0 end) "ind_oil", >> VedaBatchUpload.sql
echo sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL MANFUELS' then pv else 0 end) "ind_man", sum(case when >> VedaBatchUpload.sql
echo chp_sec='CHP IND SECTOR' and chp_fuel='IND PRO' then pv else 0 end) "ind_bypro", sum(case when chp_sec='CHP PRC SECTOR' >> VedaBatchUpload.sql
echo  and chp_fuel='PRC GAS' then pv else 0 end) "prc_gas", sum(case when chp_sec='CHP PRC SECTOR' and >> VedaBatchUpload.sql
echo chp_fuel='PRC REFGAS' then pv else 0 end) "prc_refgas", sum(case when chp_sec='CHP PRC SECTOR' and chp_fuel='ALL OIL PRODUCTS' >> VedaBatchUpload.sql
echo  then pv else 0 end) "prc_oil", sum(case when chp_sec='CHP UPS SECTOR' and chp_fuel='UPS GAS' then pv else 0 >> VedaBatchUpload.sql
echo end) "ups_gas" from chp_fuels group by tablename,period ) a left join ( select tablename,period, case when >> VedaBatchUpload.sql
echo res_chp_reformer_h2+res_boi_reformer_h2^>0 then >> VedaBatchUpload.sql
echo res_reformer*res_chp_reformer_h2/(res_chp_reformer_h2+res_boi_reformer_h2) else 0 end chp_gas_for_h_res, case when >> VedaBatchUpload.sql
echo ser_chp_reformer_h2+ser_boi_reformer_h2^>0 then >> VedaBatchUpload.sql
echo ser_reformer*ser_chp_reformer_h2/(ser_chp_reformer_h2+ser_boi_reformer_h2) else 0 end chp_gas_for_h_ser from ( select >> VedaBatchUpload.sql
echo sum(case when chp_hyd='RES BOI HYG' and commodity in('RESHYGREF-FC','RESHYGREF-FS', 'RESHYGREF-HC','RESHYGREF-HS', >> VedaBatchUpload.sql
echo 'RESHYGREF-NA') then pv else 0 end) res_boi_reformer_h2, sum(case when chp_hyd='RES MCHP HYG' and commodity >> VedaBatchUpload.sql
echo in('RESHYGREF-FC','RESHYGREF-FS', 'RESHYGREF-HC','RESHYGREF-HS','RESHYGREF-NA') then pv else 0 end) >> VedaBatchUpload.sql
echo res_chp_reformer_h2, sum(case when chp_hyd='RES REFORMER' then pv else 0 end) res_reformer, sum(case when >> VedaBatchUpload.sql
echo chp_hyd='SER BOI HYG' and commodity ='SERHYGREF' then pv else 0 end) ser_boi_reformer_h2, sum(case when chp_hyd='SER MCHP HYG' >> VedaBatchUpload.sql
echo  and commodity ='SERHYGREF' then pv else 0 end) ser_chp_reformer_h2, sum(case when chp_hyd='SER REFORMER' >> VedaBatchUpload.sql
echo then pv else 0 end) ser_reformer ,tablename,period from hydrogen_chp group by tablename,period ) a ) b on >> VedaBatchUpload.sql
echo a.period=b.period and a.tablename=b.tablename ) , chp_heatgen as( select chp_sec, period,tablename,sum(pv) "pv" from >> VedaBatchUpload.sql
echo ( select case when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','IFDCHPBIOG01','IFDCHPBIOS00', >> VedaBatchUpload.sql
echo 'IFDCHPBIOS01','IISCHPBIOG01','IISCHPBIOS01', 'INMCHPBIOG01','INMCHPBIOS01','IOICHPBIOG01','IOICHPBIOS00', >> VedaBatchUpload.sql
echo 'IOICHPBIOS01','IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01', 'IPPCHPWST00','IPPCHPWST01') then 'CHP IND BIO' when >> VedaBatchUpload.sql
echo process in('ICHCHPPRO00','ICHCHPPRO01') then 'CHP IND BY PRODUCTS' when process in('ICHCHPCOA00','ICHCHPCOA01', >> VedaBatchUpload.sql
echo 'IFDCHPCOA00','IFDCHPCOA01','INMCHPCOA01','IOICHPCOA01','IPPCHPCOA00','IPPCHPCOA01') then 'CHP IND COAL' when process >> VedaBatchUpload.sql
echo in('ICHCHPCCGT01','ICHCHPGT01','ICHCHPNGA00','IFDCHPCCGT01','IFDCHPGT01','IFDCHPNGA00','IISCHPCCGT01', 'IISCHPGT01', >> VedaBatchUpload.sql
echo 'IISCHPNGA00','INMCHPCCGT01','INMCHPGT01','INMCHPNGA00','IOICHPCCGT01','IOICHPGT01','IOICHPNGA00', 'IPPCHPCCGT01', >> VedaBatchUpload.sql
echo 'IPPCHPGT01','IPPCHPNGA00') then 'CHP IND GAS' when process in('ICHCHPCCGTH01','ICHCHPFCH01','IFDCHPCCGTH01', >> VedaBatchUpload.sql
echo 'IFDCHPFCH01','IISCHPCCGTH01','IISCHPFCH01','INMCHPCCGTH01', 'INMCHPFCH01','IOICHPCCGTH01','IOICHPFCH01', >> VedaBatchUpload.sql
echo 'IPPCHPCCGTH01','IPPCHPFCH01') then 'CHP IND HYDROGEN' when process in('IISCHPBFG00','IISCHPBFG01','IISCHPCOG00', >> VedaBatchUpload.sql
echo 'IISCHPCOG01','INMCHPCOG00','INMCHPCOG01') then 'CHP IND MAN FUELS' when process in('ICHCHPHFO00','ICHCHPLFO00', >> VedaBatchUpload.sql
echo 'ICHCHPLPG00','ICHCHPLPG01','IFDCHPHFO00','IFDCHPLFO00','IISCHPHFO00', 'IOICHPHFO00') then 'CHP IND OIL PRODUCTS' >> VedaBatchUpload.sql
echo when process in('PCHP-CCP00','PCHP-CCP01') then 'CHP PRC SECTOR' when process in('RCHPEA-STW01','RCHPNA-STW01', >> VedaBatchUpload.sql
echo 'RHEACHPRW01','RHNACHPRW01') then 'CHP RES BIO' when process in('RCHPEA-CCG00','RCHPEA-CCG01','RCHPNA-CCG01', >> VedaBatchUpload.sql
echo 'RHEACHPRG01','RHNACHPRG01') then 'CHP RES GAS' when process in('RCHPEA-CCH01','RCHPEA-FCH01','RCHPNA-CCH01', >> VedaBatchUpload.sql
echo 'RCHPNA-FCH01','RHEACHPRH01','RHNACHPRH01') then 'CHP RES HYDROGEN' when process in('SCHP-ADM01','SCHP-GES00', >> VedaBatchUpload.sql
echo 'SCHP-GES01','SCHP-STM01','SCHP-STW00','SCHP-STW01','SHLCHPRW01') then 'CHP SER BIO' when process in('SCHP-CCG00', >> VedaBatchUpload.sql
echo 'SCHP-CCG01','SHLCHPRG01') then 'CHP SER GAS' when process in('SCHP-CCH01','SCHP-FCH01','SHHFCLRH01','SHLCHPRH01') >> VedaBatchUpload.sql
echo then 'CHP SER HYDROGEN' when process in('UCHP-CCG00','UCHP-CCG01') then 'CHP UPS SECTOR' end as chp_sec, * from >> VedaBatchUpload.sql
echo vedastore where attribute='VAR_FOut' and commodity in ('ICHSTM','IFDSTM','IISLTH','INMSTM','IOISTM','IPPLTH', >> VedaBatchUpload.sql
echo 'PCHPHEAT','RESLTH-NA','RHEATPIPE-NA', 'SERLTH','SHLDELVRAD','SHHDELVRAD','UPSHEAT','RESLTH-FC','RESLTH-FS', >> VedaBatchUpload.sql
echo 'RESLTH-HC','RESLTH-HS','RHEATPIPE-FC', 'RHEATPIPE-FS','RHEATPIPE-HC','RHEATPIPE-HS') ) a where chp_sec is not null >> VedaBatchUpload.sql
echo is not null group by tablename, period,chp_sec order by chp_sec ) , process_fuel_pcs as ( select tablename, period, >> VedaBatchUpload.sql
echo sum(case when (prc_gas+prc_refgas+prc_oil)=0 then 0 else prc_gas/(prc_gas+prc_refgas+prc_oil) end) "prc_gas_pc", >> VedaBatchUpload.sql
echo sum(case when (prc_gas+prc_refgas+prc_oil)=0 then 0 else prc_refgas/(prc_gas+ prc_refgas+ prc_oil) end) >> VedaBatchUpload.sql
echo "prc_refgas_pc", sum(case when (prc_gas+prc_refgas+prc_oil)=0 then 0 else prc_oil/(prc_gas+ prc_refgas+ prc_oil) end) >> VedaBatchUpload.sql
echo "prc_oil_pc" from chp_fuels_used group by tablename, period ) ,chp_heat as( select a.tablename,a.period, a.res_bio, >> VedaBatchUpload.sql
echo a.res_gas+a.res_hyd*(case when b.chp_gas_for_h_res_mult is null then 0 else b.chp_gas_for_h_res_mult end) res_gas, >> VedaBatchUpload.sql
echo a.res_hyd*(1-(case when b.chp_gas_for_h_res_mult is null then 0 else b.chp_gas_for_h_res_mult end)) res_hyd, >> VedaBatchUpload.sql
echo a.ser_bio, a.ser_gas+a.ser_hyd*(case when b.chp_gas_for_h_ser_mult is null then 0 else b.chp_gas_for_h_ser_mult end) >> VedaBatchUpload.sql
echo ser_gas, a.ser_hyd*(1-(case when b.chp_gas_for_h_ser_mult is null then 0 else b.chp_gas_for_h_ser_mult end)) ser_hyd, >> VedaBatchUpload.sql
echo a.ind_bio,a.ind_gas,a.ind_hyd,a.ind_coa,a.ind_oil,a.ind_man,a.ind_bypro,a.ups_gas, a.prc_heat*c.prc_gas_pc "prc_gas", >> VedaBatchUpload.sql
echo a.prc_heat*c.prc_refgas_pc "prc_refgas", a.prc_heat*c.prc_oil_pc "prc_oil" from ( select sum(case when chp_sec='CHP RES BIO' >> VedaBatchUpload.sql
echo  then pv else 0 end) res_bio ,sum(case when chp_sec='CHP RES GAS' then pv else 0 end) res_gas ,sum(case when >> VedaBatchUpload.sql
echo chp_sec='CHP RES HYDROGEN' then pv else 0 end) res_hyd ,sum(case when chp_sec='CHP SER BIO' then pv else 0 end) >> VedaBatchUpload.sql
echo ser_bio ,sum(case when chp_sec='CHP SER GAS' then pv else 0 end) ser_gas ,sum(case when chp_sec='CHP SER HYDROGEN' >> VedaBatchUpload.sql
echo then pv else 0 end) ser_hyd ,sum(case when chp_sec='CHP IND BIO' then pv else 0 end) ind_bio ,sum(case when >> VedaBatchUpload.sql
echo chp_sec='CHP IND GAS' then pv else 0 end) ind_gas ,sum(case when chp_sec='CHP IND HYDROGEN' then pv else 0 end) >> VedaBatchUpload.sql
echo ind_hyd ,sum(case when chp_sec='CHP IND COAL' then pv else 0 end) ind_coa ,sum(case when chp_sec='CHP IND OIL PRODUCTS' >> VedaBatchUpload.sql
echo  then pv else 0 end) ind_oil ,sum(case when chp_sec='CHP IND MAN FUELS' then pv else 0 end) ind_man , >> VedaBatchUpload.sql
echo sum(case when chp_sec='CHP IND BY PRODUCTS' then pv else 0 end) ind_bypro ,sum(case when chp_sec='CHP UPS SECTOR' >> VedaBatchUpload.sql
echo then pv else 0 end) ups_gas ,sum(case when chp_sec='CHP PRC SECTOR' then pv else 0 end) prc_heat ,period,tablename >> VedaBatchUpload.sql
echo from chp_heatgen group by period,tablename )a left join reformer_factors b on a.period=b.period and >> VedaBatchUpload.sql
echo a.tablename=b.tablename left join process_fuel_pcs c on a.period=c.period and a.tablename=c.tablename ) , chp_elcgen >> VedaBatchUpload.sql
echo as ( select tablename, chp_sec, period, sum(pv) "pv" from ( select tablename, period, pv, case when process >> VedaBatchUpload.sql
echo in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01','IISCHPBIOG01', >> VedaBatchUpload.sql
echo 'IISCHPBIOS01', 'INMCHPBIOG01','INMCHPBIOS01','IOICHPBIOG01','IOICHPBIOS00','IOICHPBIOS01','IPPCHPBIOG01', >> VedaBatchUpload.sql
echo 'IPPCHPBIOS00','IPPCHPBIOS01', 'IPPCHPWST00','IPPCHPWST01') then 'CHP IND BIO' when process in('ICHCHPPRO00', >> VedaBatchUpload.sql
echo 'ICHCHPPRO01') then 'CHP IND BY PRODUCTS' when process in('ICHCHPCOA00','ICHCHPCOA01','IFDCHPCOA00','IFDCHPCOA01', >> VedaBatchUpload.sql
echo 'INMCHPCOA01','IOICHPCOA01','IPPCHPCOA00','IPPCHPCOA01') then 'CHP IND COAL' when process in('ICHCHPCCGT01', >> VedaBatchUpload.sql
echo 'ICHCHPGT01','ICHCHPNGA00','IFDCHPCCGT01','IFDCHPGT01','IFDCHPNGA00','IISCHPCCGT01', 'IISCHPGT01','IISCHPNGA00', >> VedaBatchUpload.sql
echo 'INMCHPCCGT01','INMCHPGT01','INMCHPNGA00','IOICHPCCGT01','IOICHPGT01','IOICHPNGA00', 'IPPCHPCCGT01','IPPCHPGT01', >> VedaBatchUpload.sql
echo 'IPPCHPNGA00') then 'CHP IND GAS' when process in('ICHCHPCCGTH01','ICHCHPFCH01','IFDCHPCCGTH01','IFDCHPFCH01', >> VedaBatchUpload.sql
echo 'IISCHPCCGTH01','IISCHPFCH01','INMCHPCCGTH01', 'INMCHPFCH01','IOICHPCCGTH01','IOICHPFCH01','IPPCHPCCGTH01', >> VedaBatchUpload.sql
echo 'IPPCHPFCH01') then 'CHP IND HYDROGEN' when process in('IISCHPBFG00','IISCHPBFG01','IISCHPCOG00','IISCHPCOG01', >> VedaBatchUpload.sql
echo 'INMCHPCOG00','INMCHPCOG01') then 'CHP IND MAN FUELS' when process in('ICHCHPHFO00','ICHCHPLFO00','ICHCHPLPG00', >> VedaBatchUpload.sql
echo 'ICHCHPLPG01','IFDCHPHFO00','IFDCHPLFO00','IISCHPHFO00', 'IOICHPHFO00') then 'CHP IND OIL PRODUCTS' when process >> VedaBatchUpload.sql
echo in('PCHP-CCP00','PCHP-CCP01') then 'CHP PRC SECTOR' when process in('RCHPEA-STW01','RCHPNA-STW01','RHEACHPRW01', >> VedaBatchUpload.sql
echo 'RHNACHPRW01') then 'CHP RES BIO' when process in('RCHPEA-CCG00','RCHPEA-CCG01','RCHPNA-CCG01','RHEACHPRG01', >> VedaBatchUpload.sql
echo 'RHNACHPRG01') then 'CHP RES GAS' when process in('RCHPEA-CCH01','RCHPEA-FCH01','RCHPNA-CCH01','RCHPNA-FCH01', >> VedaBatchUpload.sql
echo 'RHEACHPRH01','RHNACHPRH01') then 'CHP RES HYDROGEN' when process in('SCHP-ADM01','SCHP-GES00','SCHP-GES01', >> VedaBatchUpload.sql
echo 'SCHP-STM01','SCHP-STW00','SCHP-STW01','SHLCHPRW01') then 'CHP SER BIO' when process in('SCHP-CCG00','SCHP-CCG01', >> VedaBatchUpload.sql
echo 'SHLCHPRG01') then 'CHP SER GAS' when process in('SCHP-CCH01','SCHP-FCH01','SHHFCLRH01','SHLCHPRH01') then 'CHP SER HYDROGEN' >> VedaBatchUpload.sql
echo  when process in('UCHP-CCG00','UCHP-CCG01') then 'CHP UPS SECTOR' end as chp_sec from vedastore where >> VedaBatchUpload.sql
echo attribute='VAR_FOut' and commodity in('ELCGEN','INDELC','RESELC','RESHOUSEELC','SERBUILDELC','SERDISTELC','SERELC') ) >> VedaBatchUpload.sql
echo a where chp_sec is not null group by tablename, chp_sec, period ) , chp_elc as ( select a.tablename,a.period, >> VedaBatchUpload.sql
echo a.ind_bio,a.ind_coa,a.ind_gas,a.ind_hyd,a.ind_oil,a.ind_man,a.ind_bypro, a.res_bio, a.res_gas+a.res_hyd*(case when >> VedaBatchUpload.sql
echo b.chp_gas_for_h_res_mult is null then 0 else b.chp_gas_for_h_res_mult end) res_gas, a.res_hyd*(1-(case when >> VedaBatchUpload.sql
echo b.chp_gas_for_h_res_mult is null then 0 else b.chp_gas_for_h_res_mult end)) res_hyd, a.ser_bio, >> VedaBatchUpload.sql
echo a.ser_gas+a.res_hyd*(case when b.chp_gas_for_h_ser_mult is null then 0 else b.chp_gas_for_h_ser_mult end) ser_gas, >> VedaBatchUpload.sql
echo a.ser_hyd*(1-(case when b.chp_gas_for_h_ser_mult is null then 0 else b.chp_gas_for_h_ser_mult end)) ser_hyd, >> VedaBatchUpload.sql
echo a.prc_elc*c.prc_gas_pc "prc_gas",a.prc_elc*c.prc_oil_pc "prc_oil",a.prc_elc*c.prc_refgas_pc "prc_refgas", a.ups_gas >> VedaBatchUpload.sql
echo from ( select tablename,period, sum(case when chp_sec='CHP RES BIO' then pv else 0 end) as "res_bio", sum(case when >> VedaBatchUpload.sql
echo chp_sec='CHP RES GAS' then pv else 0 end) as "res_gas", sum(case when chp_sec='CHP RES HYDROGEN' then pv else 0 end) >> VedaBatchUpload.sql
echo as "res_hyd", sum(case when chp_sec='CHP SER BIO' then pv else 0 end) "ser_bio", sum(case when chp_sec='CHP SER GAS' >> VedaBatchUpload.sql
echo then pv else 0 end) "ser_gas", sum(case when chp_sec='CHP SER HYDROGEN' then pv else 0 end) "ser_hyd", sum(case when >> VedaBatchUpload.sql
echo chp_sec='CHP IND BIO' then pv else 0 end) "ind_bio", sum(case when chp_sec='CHP IND GAS' then pv else 0 end) >> VedaBatchUpload.sql
echo "ind_gas", sum(case when chp_sec='CHP IND HYDROGEN' then pv else 0 end) "ind_hyd", sum(case when chp_sec='CHP IND COAL' >> VedaBatchUpload.sql
echo  then pv else 0 end) "ind_coa", sum(case when chp_sec='CHP IND OIL PRODUCTS' then pv else 0 end) "ind_oil", >> VedaBatchUpload.sql
echo sum(case when chp_sec='CHP IND MAN FUELS' then pv else 0 end) "ind_man", sum(case when chp_sec='CHP IND BY PRODUCTS' >> VedaBatchUpload.sql
echo then pv else 0 end) "ind_bypro", sum(case when chp_sec='CHP PRC SECTOR' then pv else 0 end) "prc_elc", sum(case when >> VedaBatchUpload.sql
echo chp_sec='CHP UPS SECTOR' then pv else 0 end) "ups_gas" from chp_elcgen group by tablename,period ) a left join >> VedaBatchUpload.sql
echo reformer_factors b on a.tablename=b.tablename and a.period=b.period left join process_fuel_pcs c on >> VedaBatchUpload.sql
echo a.tablename=c.tablename and a.period=c.period ) , chp as( select elc.tablename, elc.period, sum(case when >> VedaBatchUpload.sql
echo elc.ind_bio+heat.ind_bio^>0 then (2*fuel.ind_bio*elc.ind_bio)/(2*elc.ind_bio+heat.ind_bio) else 0 end) "ind_bio_chp", >> VedaBatchUpload.sql
echo sum(case when elc.ind_coa+heat.ind_coa^>0 then (2*fuel.ind_coa*elc.ind_coa)/(2*elc.ind_coa+heat.ind_coa) else 0 end) >> VedaBatchUpload.sql
echo "ind_coa_chp", sum(case when elc.ind_gas+heat.ind_gas^>0 then >> VedaBatchUpload.sql
echo (2*fuel.ind_gas*elc.ind_gas)/(2*elc.ind_gas+heat.ind_gas) else 0 end) "ind_gas_chp", sum(case when >> VedaBatchUpload.sql
echo elc.ind_hyd+heat.ind_hyd^>0 then (2*fuel.ind_hyd*elc.ind_hyd)/(2*elc.ind_hyd+heat.ind_hyd) else 0 end) "ind_hyd_chp", >> VedaBatchUpload.sql
echo sum(case when elc.ind_oil+heat.ind_oil^>0 then (2*fuel.ind_oil*elc.ind_oil)/(2*elc.ind_oil+heat.ind_oil) else 0 end) >> VedaBatchUpload.sql
echo "ind_oil_chp", sum(case when elc.ind_man+heat.ind_man^>0 then >> VedaBatchUpload.sql
echo (2*fuel.ind_man*elc.ind_man)/(2*elc.ind_man+heat.ind_man) else 0 end) "ind_man_chp", sum(case when >> VedaBatchUpload.sql
echo elc.ind_bypro+heat.ind_bypro^>0 then (2*fuel.ind_bypro*elc.ind_bypro)/(2*elc.ind_bypro+heat.ind_bypro) else 0 end) >> VedaBatchUpload.sql
echo "ind_bypro_chp", sum(case when elc.res_bio+heat.res_bio^>0 then >> VedaBatchUpload.sql
echo (2*fuel.res_bio*elc.res_bio)/(2*elc.res_bio+heat.res_bio) else 0 end) "res_bio_chp", sum(case when >> VedaBatchUpload.sql
echo elc.res_gas+heat.res_gas^>0 then (2*fuel.res_gas*elc.res_gas)/(2*elc.res_gas+heat.res_gas) else 0 end) "res_gas_chp", >> VedaBatchUpload.sql
echo sum(case when elc.res_hyd+heat.res_hyd^>0 then (2*fuel.res_hyd*elc.res_hyd)/(2*elc.res_hyd+heat.res_hyd) else 0 end) >> VedaBatchUpload.sql
echo "res_hyd_chp", sum(case when elc.ser_bio+heat.ser_bio^>0 then >> VedaBatchUpload.sql
echo (2*fuel.ser_bio*elc.ser_bio)/(2*elc.ser_bio+heat.ser_bio) else 0 end) "ser_bio_chp", sum(case when >> VedaBatchUpload.sql
echo elc.ser_gas+heat.ser_gas^>0 then (2*fuel.ser_gas*elc.ser_gas)/(2*elc.ser_gas+heat.ser_gas) else 0 end) "ser_gas_chp", >> VedaBatchUpload.sql
echo sum(case when elc.ser_hyd+heat.ser_hyd^>0 then (2*fuel.ser_hyd*elc.ser_hyd)/(2*elc.ser_hyd+heat.ser_hyd) else 0 end) >> VedaBatchUpload.sql
echo "ser_hyd_chp", sum(case when elc.prc_gas+heat.prc_gas^>0 then >> VedaBatchUpload.sql
echo (2*fuel.prc_gas*elc.prc_gas)/(2*elc.prc_gas+heat.prc_gas) else 0 end) "prc_gas_chp", sum(case when >> VedaBatchUpload.sql
echo elc.prc_oil+heat.prc_oil^>0 then (2*fuel.prc_oil*elc.prc_oil)/(2*elc.prc_oil+heat.prc_oil) else 0 end) "prc_oil_chp", >> VedaBatchUpload.sql
echo sum(case when elc.prc_refgas+heat.prc_refgas^>0 then >> VedaBatchUpload.sql
echo (2*fuel.prc_refgas*elc.prc_refgas)/(2*elc.prc_refgas+heat.prc_refgas) else 0 end) "prc_refgas_chp", sum(case when >> VedaBatchUpload.sql
echo elc.ups_gas+heat.ups_gas^>0 then (2*fuel.ups_gas*elc.ups_gas)/(2*elc.ups_gas+heat.ups_gas) else 0 end) "ups_gas_chp" >> VedaBatchUpload.sql
echo from chp_fuels_used fuel inner join chp_heat heat on fuel.period=heat.period and fuel.tablename=heat.tablename inner >> VedaBatchUpload.sql
echo join chp_elc elc on elc.period=fuel.period and elc.tablename=fuel.tablename group by elc.tablename, elc.period order >> VedaBatchUpload.sql
echo by elc.period ) , "all_finencon_all" as( select tablename, proc_set,comm_set,period,sum(pv) "pv" from ( select >> VedaBatchUpload.sql
echo tablename, period, pv, case when process in('AGRLFO00','AGRBOM01','AGRLPG01','AGRPOLWST00','AGRLAND00','AGRBIODST01', >> VedaBatchUpload.sql
echo 'AGRBIOLPG01','AGRNGA00','AGRLFO01','AGRHFO00','AGRLPG00','AGRELC00' ,'AGRPOLWST01','AGRGRASS00','AMAINPHYG01', >> VedaBatchUpload.sql
echo 'AGRNGA01','AGRLAND01','AGRHFO01','AGRHYG01','AGRELC01','AGRCOA00','AMAINPGAS01','AGRGRASS01') then 'FUEL TECHS AGR' >> VedaBatchUpload.sql
echo when process in('ELCSOL01','ELCMSWINO01','ELCMSC00','ELCPELL01','ELCHYGD01','ELCURN01','ELCMSWORG00','ELCBIOLFO01', >> VedaBatchUpload.sql
echo 'ELCSTWWST00','ELCWAV01','ELCCOA01','ELCMSC01' ,'ELCTID01','ELCPOLWST00','ELCSOL00','ELCNGA01','ELCBOG-AD01', >> VedaBatchUpload.sql
echo 'ELCBFG00','ELCCOG00','ELCLPG01','ELCBOG-LF00','ELCMSWORG01','ELCPELL00','ELCNGA00' ,'ELCBOM01','ELCBOG-LF01', >> VedaBatchUpload.sql
echo 'ELCHYGI01','ELCGEO01','ELCWNDOFS00','ELCHYG01','ELCLFO00','ELCURN00','ELCWNDONS01','ELCBIOOIL01','ELCHFO01', >> VedaBatchUpload.sql
echo 'ELCHFO00' ,'ELCBOG-SW00','ELCHYD00','ELCLFO01','ELCHYD01','ELCCOA00','ELCBOG-SW01','ELCWNDONS00','ELCLPG00', >> VedaBatchUpload.sql
echo 'ELCBFG01','ELCCOG01','ELCPOLWST01','ELCSTWWST01' ,'ELCPELH01','ELCMSWINO00','ELCWNDOFS01') then 'FUEL TECHS ELC' >> VedaBatchUpload.sql
echo when process in('INDSYGOIL01','INDKER00','INDELC00','INDBIOLFO01','INDBIOPOL01','INDWOD01','INDBOG-LF00','INDNGA01', >> VedaBatchUpload.sql
echo 'INDCOK00','INDBFG01','INDBENZ00','INDLFO00' ,'INDBENZ01','INDBIOLPG01','INDHFO00','INDSYGCOA01','INDKER01', >> VedaBatchUpload.sql
echo 'INDCOACOK01','INDLPG01','INDMSWINO01','INDCOG01','INDELC01','INDBFG00','INDPELL00' ,'INDCOA01','INDBOG-AD01', >> VedaBatchUpload.sql
echo 'INDBOM01','INDPOLWST00','INDPELL01','INDOILLPG00','INDCOA00','INDNGA00','INDHFO01','INDWODWST00','INDCOACOK00', >> VedaBatchUpload.sql
echo 'INDMSWORG00' ,'INDWHO01','INDLFO01','INDPELH01','INDHYG01','INDCOK01','INDCOG00','INDWODWST01','INDBIOOIL01', >> VedaBatchUpload.sql
echo 'INDMSWINO00','INDBOG-LF01','INDMSWORG01') then 'FUEL TECHS INDUS' when process in('PHBIOOIL01','PHPELL01','PHPELH01', >> VedaBatchUpload.sql
echo 'PHNGAL01','PHELC01','PHCOA01','PHELCSURP01','PHMSWINO01','PHMSWORG01') then 'FUEL TECHS HYG' when process >> VedaBatchUpload.sql
echo in('PRCHFO01','PRCCOACOK01','PRCNGA00','PRCELC00','PRCOILCRD00','PRCCOA01','PRCCOA00','PRCHFO00','PRCOILCRD01', >> VedaBatchUpload.sql
echo 'PRCELC01','PRCNGA01','PRCCOACOK00') then 'FUEL TECHS PRC' when process in('RESBIOLFO01','RESNGAS01','RESLFO00', >> VedaBatchUpload.sql
echo 'RESLPG00','RESBIOM01','RESLFO01','RESLPG01','RESCOK01','RESELC00','RESCOA01','RESCOA00','RESCOK00' ,'RESHYG01', >> VedaBatchUpload.sql
echo 'RESSOL01','RESELC01','RESPELH01','RESKER01','RESWODL00','RESWODL01','RESNGAS00','RESWOD00','RESWOD01','RESSOL00', >> VedaBatchUpload.sql
echo 'RESKER00') then 'FUEL TECHS RES' when process in('SERHYG01','SERBOG-SW01','SERKER01','SERCOA00','SERSOL01', >> VedaBatchUpload.sql
echo 'SERBOG-SW00','SERBIOLFO01','SERBOM01','SERLFO01','SERLPG01','SERCOA01','SERGEO00' ,'SERMSWORG00','SERELC00', >> VedaBatchUpload.sql
echo 'SERNGA00','SERMSWINO00','SERELC01','SERWOD01','SERNGA01','SERMSWORG01','SERMSWBIO01','SERGEO01','SERPELH01', >> VedaBatchUpload.sql
echo 'SERMSWINO01' ,'SERHFO01','SERHFO00','SERLFO00') then 'FUEL TECHS SERV' when process in('TRABIODST-FT01', >> VedaBatchUpload.sql
echo 'TRABIOOILIS01','TRAELC00','TRALFO01','TRAJETDA01','TRABOM01','TRALPG01','TRAJETIA01','TRAETH00','TRABIOJET-FTIA01', >> VedaBatchUpload.sql
echo 'TRAJETIA00','TRABIODST01' ,'TRAHYGPIS01','TRADST01','TRAHFOIS00','TRADST00','TRALFODS01','TRAHYL01','TRALPG00', >> VedaBatchUpload.sql
echo 'TRAHFOIS01','TRALFODS00','TRAHYLIA01','TRABIODST00','TRAHYGPDS01' ,'TRAHFODS00','TRANGA01','TRAPET01', >> VedaBatchUpload.sql
echo 'TRABIOJET-FTDA01','TRAHYGP01','TRABIOLFO01','TRAETH01','TRAHYLDA01','TRAELC01','TRACOA00','TRAJETDA00', >> VedaBatchUpload.sql
echo 'TRABIOLFODS01' ,'TRAHFODS01','TRAPET00','TRALFO00','TRALNGDS01','TRALNGIS01') then 'FUEL TECHS TRA' when process >> VedaBatchUpload.sql
echo in('UPSELC00','UPSLFO00','UPSNGA01','UPSLFO01','UPSELC01','UPSNGA00','UPSHYG01') then 'FUEL TECHS UPSTREAM' end as >> VedaBatchUpload.sql
echo proc_set, case when commodity in('COK','INDBFG','INDCOG','BFG','IISCOGB','INDCOK','IISCOKB','BENZ','IISCOGC', >> VedaBatchUpload.sql
echo 'IISCOKS','ELCBFG','ELCCOG' ,'IISBFGC','IISCOKE','IISBFGB','RESCOK','COG','INDBENZ') then 'ALL MANFUELS' when >> VedaBatchUpload.sql
echo commodity in('ELCNGA','AGRNGA','NGA-I-EU','NGA-E','PRCNGA','TRALNGISL','TRALNGIS','LNG','INDNEUNGA','NGA-E-IRE', >> VedaBatchUpload.sql
echo 'IISNGAC','TRALNGDS' ,'UPSNGA','TRALNG','IISNGAE','RESNGA','TRANGA','TRACNGS','NGA-I-N','INDNGA','NGA-E-EU','NGA', >> VedaBatchUpload.sql
echo 'NGAPTR','TRACNGL' ,'TRALNGDSL','HYGSNGA','SERNGA','IISNGAB','HYGLNGA') then 'ALL GAS' when commodity in('INDDISTELC', >> VedaBatchUpload.sql
echo 'HYGLELC','RESELCSURPLUS','RESHOUSEELC','TRADISTELC','ELC','HYGSELC','HYGELCSURP','SERDISTELC','ELCSURPLUS', >> VedaBatchUpload.sql
echo 'AGRDISTELC','SERELC' ,'AGRELC','TRACELC','INDELC','RESELC','SERBUILDELC','ELC-E-IRE','UPSELC','HYGELC','ELC-I-EU', >> VedaBatchUpload.sql
echo 'ELCGEN','TRAELC','PRCELC' ,'ELC-E-EU','TRACPHB','RESDISTELC','ELC-I-IRE') then 'ALL ELECTRICITY' when commodity >> VedaBatchUpload.sql
echo in('RHEATPIPE-NA','PCHPHEAT','INDSTM','RHEATPIPE-EA','IOISTM','RHCSV-RHEA','ICHSTM','IFDSTM','INMSTM','ICHOTH', >> VedaBatchUpload.sql
echo 'UPSHEAT') then 'ALL HEAT' when commodity in('SOL','ELCWNDONS','RESSOL','WNDOFF','SERSOL','ELCTID','ELCGEO','SERGEO', >> VedaBatchUpload.sql
echo 'HYDROR','WNDONS','WAV','TID' ,'ELCSOL','GEO','HYDDAM','ELCWAV','ELCHYDDAM','ELCWNDOFS') then 'ALL OTHER RNW' when >> VedaBatchUpload.sql
echo commodity in('SYNCOA','ELCCOA','INDCOA','TRACOA','AGRCOA','COA','PRCCOA','HYGCOA','PRCCOACOK','INDSYNCOA','COACOK', >> VedaBatchUpload.sql
echo 'RESCOA' ,'COA-E','SERCOA','INDCOACOK') then 'ALL COALS' when commodity in('TRABOM','SERWOD','RESWODL','BOG-LF', >> VedaBatchUpload.sql
echo 'BIOLFO','INDBOG-LF','AGRGRASS','BVOIL','BIODST','ELCMSWORG','INDGRASS','AGRBIOLPG' ,'MSWORG','ELCSTWWST','HYGMSWINO', >> VedaBatchUpload.sql
echo 'HYGBPEL','TRAETHS','BSUGAR','BIOKER-FT','ELCBIOCOA','TRABIOJET-FTIAL','ELCPELL','TRABIOJET-FTDAL','MSWBIO' ,'RESWOD', >> VedaBatchUpload.sql
echo 'RESMAINSBOM','SERBOG','TRABIOLFOL','RESHOUSEBOM','TRABIODST-FTS','TRABIOLFODSL','AGRMAINSBOM','ELCBOM','HYGBIOO', >> VedaBatchUpload.sql
echo 'INDMSWINO','SERBIOLFO' ,'TRAETH','ELCBOG-SW','ELCMAINSBOM','TRAETHL','BWODLOG','ELCBOG-AD','ELCBOG-LF','BSTARCH', >> VedaBatchUpload.sql
echo 'BSTWWST','ELCTRANSBOM','ELCBIOOIL','TRABIOJET-FTIA' ,'INDPELH','INDPOLWST','INDWOD','TRABIODST-FT','SERMAINSBOM', >> VedaBatchUpload.sql
echo 'TRAMETH','BPELL','ELCPOLWST','PWASTEDUM','RESBIOLFO','BPELH','BTREATWOD' ,'BSEWSLG','SERMSWORG','TRAMAINSBOM', >> VedaBatchUpload.sql
echo 'BTREATSTW','BWODWST','TRABIODST-FTL','SERMSWINO','RESBOM','INDMAINSBOM','BWOD','TRABIODSTL','TRABIOJET-FTDA' , >> VedaBatchUpload.sql
echo 'BSLURRY','TRABIOOILIS','BOG-G','TRABIODST','ELCBIOLFO','TRABIOOILISL','TRABIOLFODS','BIODST-FT','METH','MSWINO', >> VedaBatchUpload.sql
echo 'AGRBOM','BIOLPG' ,'INDPELL','AGRBIODST','BIOJET-FT','BOG-AD','SERBOM','ELCPELH','RESPELH','INDBIOOIL','BOM', >> VedaBatchUpload.sql
echo 'INDWODWST','SERMSWBIO','SERPELH' ,'BIOOIL','INDBOM','TRABIOLFO','BGRASS','SERBUILDBOM','INDBIOLFO','ELCBIOCOA2', >> VedaBatchUpload.sql
echo 'INDBOG-AD','ETH','INDBIOLPG','ELCMSWINO','AGRPOLWST' ,'BRSEED','INDMSWORG','HYGMSWORG','TRABIODSTS') then 'ALL BIO' >> VedaBatchUpload.sql
echo when commodity in('TRADST','TRAPETS','UPSLFO','OILJET','TRAJETDAEL','INDSYNOIL','TRAHFO','PRCHFO','SERLFO','TRAPETL', >> VedaBatchUpload.sql
echo 'OILPET','TRAJETDA' ,'IISHFOB','OILMSC','RESKER','INDLPG','TRADSTL','INDNEULPG','INDHFO','OILHFO','ELCLPG','TRALPGL', >> VedaBatchUpload.sql
echo 'TRALPG','AGRHFO' ,'TRAHFOISL','TRADSTS','OILLFO','TRAHFOIS','SERHFO','TRALFODSL','TRAPET','INDNEULFO','ELCHFO', >> VedaBatchUpload.sql
echo 'INDKER','ELCLFO','INDNEUMSC' ,'RESLPG','TRAJETL','TRALPGS','AGRLFO','TRALFOL','TRAHFODS','TRAHFODSL','TRAJETIAEL', >> VedaBatchUpload.sql
echo 'OILDST','OILLPG','OILCRDRAW-E','TRALFO' ,'OILKER','TRAJETIA','OILCRD','SERLPG','TRAJETIANL','PRCOILCRD','TRALFODS', >> VedaBatchUpload.sql
echo 'SYNOIL','OILCRDRAW','ELCMSC','SERKER','INDLFO' ,'AGRLPG','RESLFO') then 'ALL OIL PRODUCTS' when commodity >> VedaBatchUpload.sql
echo in('TRAHYL','RESMAINSHYG','INDMAINSHYG','TRAHYGL','RESHOUSEHYG','INDHYG','HYLTK','HYGL','ELCHYGIGCC','HYL', >> VedaBatchUpload.sql
echo 'RESHYGREF-EA','ELCHYG' ,'TRAHYGS','HYGLHPD','SERHYG','HYGLHPT','UPSMAINSHYG','RESHYG','AGRHYG','TRAHYG','HYGL-IGCC', >> VedaBatchUpload.sql
echo 'RESHYGREF-NA','UPSHYG','SERBUILDHYG' ,'TRAHYGDCN','SERMAINSHYG') then 'ALL HYDROGEN' end as comm_set from vedastore >> VedaBatchUpload.sql
echo where attribute='VAR_FIn' ) a where proc_set is not null and comm_set is not null group by tablename, proc_set, >> VedaBatchUpload.sql
echo comm_set,period order by proc_set,comm_set ) , "elc+gas_final_consumption" as( select tablename, commodity,period, >> VedaBatchUpload.sql
echo sum(pv) "pv" from vedastore where attribute='VAR_FOut' and commodity in('AGRBOM','AGRDISTELC','AGRMAINSBOM', >> VedaBatchUpload.sql
echo 'AGRMAINSGAS','INDBOM','INDDISTELC','INDMAINSBOM','INDMAINSGAS','RESBOM','RESDISTELC','RESMAINSBOM','RESMAINSGAS', >> VedaBatchUpload.sql
echo 'SERBOM','SERDISTELC','SERMAINSBOM','SERMAINSGAS','TRABOM','TRADISTELC','TRAMAINSBOM','TRAMAINSGAS','RESELC-NS-E', >> VedaBatchUpload.sql
echo 'RESELC-NS-N') group by tablename, period, commodity ) , mainsbom as( select tablename, period, sum(case when >> VedaBatchUpload.sql
echo commodity='RESMAINSBOM' then pv else 0 end) "resmainsbom" ,sum(case when commodity='INDMAINSBOM' then pv else 0 end) >> VedaBatchUpload.sql
echo "indmainsbom" from "elc+gas_final_consumption" group by tablename, period ), elc_waste_heat_distribution as( select >> VedaBatchUpload.sql
echo tablename, commodity,attribute,process,period,sum(pv) "pv" from vedastore where commodity='ELCLTH' and attribute in >> VedaBatchUpload.sql
echo ('VAR_FIn','VAR_FOut') group by tablename, commodity,attribute,process,period ), elc_prd_fuel as ( select proc_set, >> VedaBatchUpload.sql
echo tablename,period, sum(pv) "pv" from ( select tablename,period, pv, case when process in('EBIOS00','EBIOCON00', >> VedaBatchUpload.sql
echo 'EBIO01','EBOG-LFE00','EBOG-SWE00','EMSW00','EPOLWST00','ESTWWST01','EBOG-ADE01','EBOG-SWE01','EMSW01','ESTWWST00', >> VedaBatchUpload.sql
echo 'EBOG-LFE01') then 'ELC FROM BIO' when process in('EBIOQ01') then 'ELC FROM BIO CCS' when process in('PCHP-CCP00', >> VedaBatchUpload.sql
echo 'UCHP-CCG00','PCHP-CCP01','UCHP-CCG01') then 'ELC FROM CHP' when process='ECOAQR01' then 'ELC FROM COAL CCSRET' when >> VedaBatchUpload.sql
echo process in('ECOARR01') then 'ELC FROM COAL RR' when process in('ECOABIO00','ECOA00') then 'ELC FROM COAL-COF' when >> VedaBatchUpload.sql
echo process in('ECOAQ01') then 'ELC FROM COALCOF CCS' when process in('ENGAOCT01','ENGAOCT00','ENGACCT00') then 'ELC FROM GAS' >> VedaBatchUpload.sql
echo  when process in('ENGACCTQ01') then 'ELC FROM GAS CCS' when process='ENGAQR01' then 'ELC FROM GAS CCSRET' when >> VedaBatchUpload.sql
echo process in('ENGACCTRR01') then 'ELC FROM GAS RR' when process in('EGEO01') then 'ELC FROM GEO' when process >> VedaBatchUpload.sql
echo in('EHYD01','EHYD00') then 'ELC FROM HYDRO' when process in('EHYGCCT01','EHYGOCT01') then 'ELC FROM HYDROGEN' when >> VedaBatchUpload.sql
echo process in('ELCIE00','ELCIE01') then 'ELC FROM IMPORTS' when process in('EMANOCT00','EMANOCT01') then 'ELC FROM MANFUELS' >> VedaBatchUpload.sql
echo  when process in('ENUCAGRN00','ENUCPWR101','ENUCPWR102','ENUCAGRO00','ENUCPWR00') then 'ELC FROM NUCLEAR' >> VedaBatchUpload.sql
echo when process in('EOILS00','EHFOIGCC01','EOILL00','EOILS01','EOILL01') then 'ELC FROM OIL' when process >> VedaBatchUpload.sql
echo in('EHFOIGCCQ01') then 'ELC FROM OIL CCS' when process in('ESOL01','ESOLPV00','ESOLPV01','ESOL00') then 'ELC FROM SOL-PV' >> VedaBatchUpload.sql
echo  when process in('ETIB101','ETIS101','ETIR101') then 'ELC FROM TIDAL' when process in('EWAV101') then 'ELC FROM WAVE' >> VedaBatchUpload.sql
echo  when process in('EWNDOFF301','EWNDOFF00','EWNDOFF101','EWNDOFF201') then 'ELC FROM WIND-OFFSH' when >> VedaBatchUpload.sql
echo process in('EWNDONS501','EWNDONS401','EWNDONS00','EWNDONS301','EWNDONS601','EWNDONS101','EWNDONS901','EWNDONS201', >> VedaBatchUpload.sql
echo 'EWNDONS801','EWNDONS701') then 'ELC FROM WIND-ONSH' when process in('ELCEE00','ELCEI00','ELCEE01','ELCEI01') then >> VedaBatchUpload.sql
echo 'ELC TO EXPORTS' end as proc_set from vedastore where attribute='VAR_FOut' and commodity in('ELCDUMMY','ELC', >> VedaBatchUpload.sql
echo 'ELC-E-IRE','ELC-E-EU','ELCGEN') ) a where proc_set is not null group by tablename, period,proc_set ) , end_demand >> VedaBatchUpload.sql
echo as( select a.tablename ,sec_fuel, case when sec_fuel='ind-bio' then sum(a.pv-ind_bio_chp-(1-0.9828)/0.9828*(case when >> VedaBatchUpload.sql
echo c.indmainsbom is null then 0 else c.indmainsbom end)) when sec_fuel='ind-coa' then sum(a.pv-ind_coa_chp) when >> VedaBatchUpload.sql
echo sec_fuel='ind-gas' then sum(a.pv-ind_gas_chp) when sec_fuel='ind-hyd' then sum(a.pv-ind_hyd_chp) when >> VedaBatchUpload.sql
echo sec_fuel='ind-man' then sum(a.pv-ind_man_chp) when sec_fuel='ind-oil' then sum(a.pv-ind_oil_chp) when >> VedaBatchUpload.sql
echo sec_fuel='res-bio' then sum(a.pv-res_bio_chp-(1-0.9828)/0.9828*(case when c.resmainsbom is null then 0 else >> VedaBatchUpload.sql
echo c.resmainsbom end)) when sec_fuel='res-gas' then sum(a.pv-res_gas_chp) when sec_fuel='ser-bio' then >> VedaBatchUpload.sql
echo sum(a.pv-ser_bio_chp) when sec_fuel='ser-gas' then sum(a.pv-ser_gas_chp) when sec_fuel='elc-bio' then >> VedaBatchUpload.sql
echo sum(a.pv+ind_bio_chp+res_bio_chp+ser_bio_chp) when sec_fuel='elc-coa' then sum(a.pv+ind_coa_chp) when >> VedaBatchUpload.sql
echo sec_fuel='elc-gas' then sum(a.pv+ind_gas_chp+res_gas_chp+ser_gas_chp+prc_gas_chp+ups_gas_chp) when sec_fuel='elc-man' >> VedaBatchUpload.sql
echo then sum(a.pv+ind_bypro_chp+ind_man_chp) when sec_fuel='elc-oil' then >> VedaBatchUpload.sql
echo sum(a.pv+ind_oil_chp+prc_oil_chp+prc_refgas_chp) when sec_fuel='elc-oil' then >> VedaBatchUpload.sql
echo sum(a.pv+ind_oil_chp+prc_oil_chp+prc_refgas_chp) when sec_fuel='elc-hyd' then >> VedaBatchUpload.sql
echo sum(a.pv+ind_hyd_chp+res_hyd_chp+ser_hyd_chp) else sum(pv) end as pv,a.period from( select case when >> VedaBatchUpload.sql
echo commodity='AGRDISTELC' then 'agr-elc' when commodity='AGRMAINSGAS' then 'agr-gas' when commodity='INDDISTELC' then >> VedaBatchUpload.sql
echo 'ind-elc' when commodity='INDMAINSGAS' then 'ind-gas' when commodity='SERDISTELC' then 'ser-elc' when >> VedaBatchUpload.sql
echo commodity='SERMAINSGAS' then 'ser-gas' when commodity='TRADISTELC' then 'tra-elc' when commodity='RESDISTELC' then >> VedaBatchUpload.sql
echo 'res-elc' when commodity='RESMAINSGAS' then 'res-gas' end as sec_fuel, tablename, period,pv from >> VedaBatchUpload.sql
echo "elc+gas_final_consumption" where commodity in('AGRDISTELC' ,'AGRMAINSGAS' ,'INDDISTELC' ,'INDMAINSGAS' ,'SERDISTELC' >> VedaBatchUpload.sql
echo ,'SERMAINSGAS' ,'TRADISTELC' ,'RESDISTELC' ,'RESMAINSGAS') union all select case when proc_set='FUEL TECHS AGR' then >> VedaBatchUpload.sql
echo 'agr-' when proc_set='FUEL TECHS INDUS' then 'ind-' when proc_set='FUEL TECHS PRC' then 'prc-' when proc_set='FUEL TECHS RES' >> VedaBatchUpload.sql
echo  then 'res-' when proc_set='FUEL TECHS SERV' then 'ser-' when proc_set='FUEL TECHS TRA' then 'tra-' when >> VedaBatchUpload.sql
echo proc_set='FUEL TECHS HYG' then 'hyd-' when proc_set='FUEL TECHS ELC' then 'elc-' end ^|^| case when comm_set='ALL BIO' >> VedaBatchUpload.sql
echo  then 'bio' when comm_set='ALL COALS' then 'coa' when comm_set='ALL ELECTRICITY' then 'elc' when comm_set='ALL GAS' >> VedaBatchUpload.sql
echo  then 'gas' when comm_set='ALL HYDROGEN' then 'hyd' when comm_set='ALL OIL PRODUCTS' then 'oil' when >> VedaBatchUpload.sql
echo comm_set='ALL OTHER RNW' then 'orens' when comm_set='ALL MANFUELS' then 'man' end as sec_fuel,tablename, period,pv >> VedaBatchUpload.sql
echo from all_finencon_all where proc_set in('FUEL TECHS HYG','FUEL TECHS PRC') or (proc_set in('FUEL TECHS AGR','FUEL TECHS INDUS' >> VedaBatchUpload.sql
echo ,'FUEL TECHS RES','FUEL TECHS SERV') and comm_set in('ALL BIO','ALL COALS','ALL HYDROGEN','ALL OIL PRODUCTS' >> VedaBatchUpload.sql
echo ,'ALL MANFUELS','ALL OTHER RNW')) or (proc_set in('FUEL TECHS TRA','FUEL TECHS ELC') and comm_set in('ALL BIO' >> VedaBatchUpload.sql
echo ,'ALL COALS','ALL HYDROGEN','ALL OIL PRODUCTS','ALL MANFUELS','ALL OTHER RNW','ALL GAS')) union all select case >> VedaBatchUpload.sql
echo when process='SDH-WHO01' then 'ser-wh' when process in('RDHEA-WHO01','RDHHC-WHO01','RDHHS-WHO01','RDHFC-WHO01', >> VedaBatchUpload.sql
echo 'RDHFS-WHO01','RDHNA-WHO01') then 'res-wh' end as sec_fuel, tablename, period,sum(pv) "pv" from >> VedaBatchUpload.sql
echo elc_waste_heat_distribution where process in('RDHEA-WHO01','RDHHC-WHO01','RDHHS-WHO01','RDHFC-WHO01','RDHFS-WHO01', >> VedaBatchUpload.sql
echo 'RDHNA-WHO01','SDH-WHO01') group by sec_fuel, tablename, period union all select 'elc-urn' "sec_fuel",tablename, >> VedaBatchUpload.sql
echo period,sum(pv/0.398) from elc_prd_fuel where proc_set='ELC FROM NUCLEAR' group by tablename, period ) a left join chp >> VedaBatchUpload.sql
echo b on a.period=b.period and a.tablename=b.tablename left join mainsbom c on a.period=c.period and >> VedaBatchUpload.sql
echo a.tablename=c.tablename group by a.tablename, sec_fuel, a.period order by a.period ) select 'fin-en-main-secs_' ^|^| >> VedaBatchUpload.sql
echo sec_fuel ^|^| '^|' ^|^| tablename ^|^| '^|various^|various^|various'::varchar "id", 'fin-en-main-secs_'^|^| >> VedaBatchUpload.sql
echo sec_fuel::varchar "analysis", tablename, 'various'::varchar "attribute", 'various'::varchar "commodity", >> VedaBatchUpload.sql
echo 'various'::varchar "process", sum(pv) "all", sum(case when a.period='2010' then pv else 0 end) as "2010", sum(case >> VedaBatchUpload.sql
echo when a.period='2011' then pv else 0 end) as "2011", sum(case when a.period='2012' then pv else 0 end) as "2012", >> VedaBatchUpload.sql
echo sum(case when a.period='2015' then pv else 0 end) as "2015", sum(case when a.period='2020' then pv else 0 end) as >> VedaBatchUpload.sql
echo "2020", sum(case when a.period='2025' then pv else 0 end) as "2025", sum(case when a.period='2030' then pv else 0 >> VedaBatchUpload.sql
echo end) as "2030", sum(case when a.period='2035' then pv else 0 end) as "2035", sum(case when a.period='2040' then pv >> VedaBatchUpload.sql
echo else 0 end) as "2040", sum(case when a.period='2045' then pv else 0 end) as "2045", sum(case when a.period='2050' >> VedaBatchUpload.sql
echo then pv else 0 end) as "2050", sum(case when a.period='2055' then pv else 0 end) as "2055", sum(case when >> VedaBatchUpload.sql
echo a.period='2060' then pv else 0 end) as "2060" from end_demand a group by tablename,sec_fuel order by tablename, >> VedaBatchUpload.sql
echo analysis ) TO '%~dp0FinEnOut.csv' delimiter ',' >> VedaBatchUpload.sql
echo CSV; >> VedaBatchUpload.sql
rem /* *Primary energy demand & biomass, imports exports and domestic production* */
echo /* *Primary energy demand !texte! biomass, imports exports and domestic production* */ COPY ( with rsr_min as( select sum(case >> VedaBatchUpload.sql
echo when proc_set='IMPORT URN' then pv else 0 end) "IMPORT URN", sum(case when proc_set='MINING BIOMASS' then pv >> VedaBatchUpload.sql
echo else 0 end) "MINING BIOMASS" ,sum(case when proc_set='MINING COAL' then pv else 0 end) "MINING COAL" ,sum(case when >> VedaBatchUpload.sql
echo proc_set='MINING GEOTHERMAL' then pv else 0 end) "MINING GEOTHERMAL" ,sum(case when proc_set='MINING HYDRO' then pv >> VedaBatchUpload.sql
echo else 0 end) "MINING HYDRO" ,sum(case when proc_set='MINING NGA' then pv else 0 end) "MINING NGA" ,sum(case when >> VedaBatchUpload.sql
echo proc_set='MINING NGA-SHALE' then pv else 0 end) "MINING NGA-SHALE" ,sum(case when proc_set='MINING OIL' then pv else >> VedaBatchUpload.sql
echo 0 end) "MINING OIL" ,sum(case when proc_set='MINING SOLAR' then pv else 0 end) "MINING SOLAR" ,sum(case when >> VedaBatchUpload.sql
echo proc_set='MINING TIDAL' then pv else 0 end) "MINING TIDAL" ,sum(case when proc_set='MINING WIND' then pv else 0 end) >> VedaBatchUpload.sql
echo "MINING WIND" ,sum(case when proc_set='MINING WAVE' then pv else 0 end) "MINING WAVE", tablename,period from ( select >> VedaBatchUpload.sql
echo tablename,period, pv, case when process in('IMPURN') then 'IMPORT URN' when process in('MINBGRASS1','MINBGRASS2', >> VedaBatchUpload.sql
echo 'MINBGRASS3','MINBIOOILCRP','MINBOG-LF','MINBRSEED','MINBSEWSLG', 'MINBSLURRY1','MINBSTWWST1','MINBSUGAR', >> VedaBatchUpload.sql
echo 'MINBTALLOW','MINBVOFAT','MINBWHT1','MINBWHT2','MINBWHT3','MINBWOD1', 'MINBWOD2','MINBWOD3','MINBWOD4','MINBWODLOG', >> VedaBatchUpload.sql
echo 'MINBWODWST','MINBWODWSTSAW','MINMSWBIO','MINMSWINO','MINMSWORG') then 'MINING BIOMASS' when process in('MINCOA1', >> VedaBatchUpload.sql
echo 'MINCOA2','MINCOA3','MINCOA4','MINCOA5','MINCOA6','MINCOACOK1','MINCOACOK2') then 'MINING COAL' when process >> VedaBatchUpload.sql
echo in('RNWGEO') then 'MINING GEOTHERMAL' when process in('RNWHYDDAM','RNWHYDROR') then 'MINING HYDRO' when process >> VedaBatchUpload.sql
echo in('MINNGA1','MINNGA2','MINNGA3','MINNGA4','MINNGA5','MINNGA6','MINNGA7','MINNGA8','MINNGA9') then 'MINING NGA' when >> VedaBatchUpload.sql
echo process in('MINNGASHL1','MINNGASHL2','MINNGASHL3') then 'MINING NGA-SHALE' when process in('MINOILCRD1','MINOILCRD2', >> VedaBatchUpload.sql
echo 'MINOILCRD3','MINOILCRD4','MINOILCRD5','MINOILCRD6','MINOILCRD7','MINOILCRD8','MINOILCRD9') then 'MINING OIL' when >> VedaBatchUpload.sql
echo process in('RNWSOL') then 'MINING SOLAR' when process in('RNWTID') then 'MINING TIDAL' when process in('RNWWAV') then >> VedaBatchUpload.sql
echo 'MINING WIND' when process in('RNWWNDOFF','RNWWNDONS') then 'MINING WAVE' end as proc_set from vedastore where >> VedaBatchUpload.sql
echo attribute='VAR_FOut' and process in('IMPURN','MINBGRASS1','MINBGRASS2','MINBGRASS3','MINBIOOILCRP','MINBOG-LF', >> VedaBatchUpload.sql
echo 'MINBRSEED','MINBSEWSLG','MINBSLURRY1','MINBSTWWST1', 'MINBSUGAR','MINBTALLOW','MINBVOFAT','MINBWHT1','MINBWHT2', >> VedaBatchUpload.sql
echo 'MINBWHT3','MINBWOD1','MINBWOD2','MINBWOD3','MINBWOD4','MINBWODLOG','MINBWODWST', 'MINBWODWSTSAW','MINMSWBIO', >> VedaBatchUpload.sql
echo 'MINMSWINO','MINMSWORG','MINCOA1','MINCOA2','MINCOA3','MINCOA4','MINCOA5','MINCOA6','MINCOACOK1','MINCOACOK2', >> VedaBatchUpload.sql
echo 'RNWGEO','RNWHYDDAM','RNWHYDROR','MINNGA1','MINNGA2','MINNGA3','MINNGA4','MINNGA5','MINNGA6','MINNGA7','MINNGA8', >> VedaBatchUpload.sql
echo 'MINNGA9','MINNGASHL1', 'MINNGASHL2','MINNGASHL3','MINNGASHL1','MINNGASHL2','MINNGASHL3','MINOILCRD1','MINOILCRD2', >> VedaBatchUpload.sql
echo 'MINOILCRD3','MINOILCRD4','MINOILCRD5','MINOILCRD6', 'MINOILCRD7','MINOILCRD8','MINOILCRD9','RNWSOL','RNWTID', >> VedaBatchUpload.sql
echo 'RNWWAV','RNWWNDOFF','RNWWNDONS') and commodity in('AGRBIODST','AGRBIOLPG','AGRBOM','AGRGRASS','AGRMAINSBOM', >> VedaBatchUpload.sql
echo 'AGRPOLWST','BGRASS','BIODST','BIODST-FT', 'BIOJET-FT','BIOKER-FT','BIOLFO','BIOLPG','BIOOIL','BOG-AD','BOG-G', >> VedaBatchUpload.sql
echo 'BOG-LF','BOM','BPELH','BPELL','BRSEED','BSEWSLG', 'BSLURRY','BSTARCH','BSTWWST','BSUGAR','BTREATSTW','BTREATWOD', >> VedaBatchUpload.sql
echo 'BVOIL','BWOD','BWODLOG','BWODWST','ELCBIOCOA', 'ELCBIOCOA2','ELCBIOLFO','ELCBIOOIL','ELCBOG-AD','ELCBOG-LF', >> VedaBatchUpload.sql
echo 'ELCBOG-SW','ELCBOM','ELCMAINSBOM','ELCMSWINO','ELCMSWORG', 'ELCPELH','ELCPELL','ELCPOLWST','ELCSTWWST','ELCTRANSBOM', >> VedaBatchUpload.sql
echo 'ETH','HYGBIOO','HYGBPEL','HYGMSWINO','HYGMSWORG','INDBIOLFO', 'INDBIOLPG','INDBIOOIL','INDBOG-AD','INDBOG-LF', >> VedaBatchUpload.sql
echo 'INDBOM','INDGRASS','INDMAINSBOM','INDMSWINO','INDMSWORG','INDPELH', 'INDPELL','INDPOLWST','INDWOD','INDWODWST', >> VedaBatchUpload.sql
echo 'METH','MSWBIO','MSWINO','MSWORG','PWASTEDUM','RESBIOLFO','RESBOM', 'RESHOUSEBOM','RESMAINSBOM','RESPELH','RESWOD', >> VedaBatchUpload.sql
echo 'RESWODL','SERBIOLFO','SERBOG','SERBOM','SERBUILDBOM','SERMAINSBOM', 'SERMSWBIO','SERMSWINO','SERMSWORG','SERPELH', >> VedaBatchUpload.sql
echo 'SERWOD','TRABIODST','TRABIODST-FT','TRABIODST-FTL','TRABIODST-FTS', 'TRABIODSTL','TRABIODSTS','TRABIOJET-FTDA', >> VedaBatchUpload.sql
echo 'TRABIOJET-FTDAL','TRABIOJET-FTIA','TRABIOJET-FTIAL','TRABIOLFO','TRABIOLFODS', 'TRABIOLFODSL','TRABIOLFOL', >> VedaBatchUpload.sql
echo 'TRABIOOILIS','TRABIOOILISL','TRABOM','TRAETH','TRAETHL','TRAETHS','TRAMAINSBOM','TRAMETH', 'AGRCOA','COA','COACOK', >> VedaBatchUpload.sql
echo 'COA-E','ELCCOA','HYGCOA','INDCOA','INDCOACOK','INDSYNCOA','PRCCOA','PRCCOACOK','RESCOA', 'SERCOA','SYNCOA','TRACOA', >> VedaBatchUpload.sql
echo 'AGRNGA','ELCNGA','HYGLNGA','HYGSNGA','IISNGAB','IISNGAC','IISNGAE','INDNEUNGA','INDNGA', 'LNG','NGA','NGA-E', >> VedaBatchUpload.sql
echo 'NGA-E-EU','NGA-E-IRE','NGA-I-EU','NGA-I-N','NGAPTR','PRCNGA','RESNGA','SERNGA','TRACNGL','TRACNGS', 'TRANGA', >> VedaBatchUpload.sql
echo 'UPSNGA','TRALNG','TRALNGDS','TRALNGDSL','TRALNGIS','TRALNGISL','AGRHFO','AGRLFO','AGRLPG','ELCHFO','ELCLFO', >> VedaBatchUpload.sql
echo 'ELCLPG','ELCMSC','IISHFOB','INDHFO','INDKER','INDLFO','INDLPG','INDNEULFO','INDNEULPG','INDNEUMSC','INDSYNOIL', >> VedaBatchUpload.sql
echo 'OILCRD','OILCRDRAW','OILCRDRAW-E','OILDST','OILHFO','OILJET','OILKER','OILLFO','OILLPG','OILMSC','OILPET','PRCHFO', >> VedaBatchUpload.sql
echo 'PRCOILCRD','RESKER','RESLFO','RESLPG','SERHFO','SERKER','SERLFO','SERLPG','SYNOIL','TRADST','TRADSTL','TRADSTS', >> VedaBatchUpload.sql
echo 'TRAHFO','TRAHFODS','TRAHFODSL','TRAHFOIS','TRAHFOISL','TRAJETDA','TRAJETDAEL','TRAJETIA','TRAJETIAEL','TRAJETIANL', >> VedaBatchUpload.sql
echo 'TRAJETL','TRALFO','TRALFODS','TRALFODSL','TRALFOL','TRALPG','TRALPGL','TRALPGS','TRAPET','TRAPETL','TRAPETS', >> VedaBatchUpload.sql
echo 'UPSLFO', 'ELCGEO','ELCHYDDAM','ELCSOL','ELCTID','ELCWAV','ELCWNDOFS','ELCWNDONS','GEO','HYDDAM','HYDROR','RESSOL', >> VedaBatchUpload.sql
echo 'SERGEO', 'SERSOL','SOL','TID','WAV','WNDOFF','WNDONS','URN') ) a where proc_set is not null group by tablename, >> VedaBatchUpload.sql
echo period order by tablename,period ) ,rsr_imports as( select sum(case when proc_set='IMPORT BDL' then pv else 0 end) >> VedaBatchUpload.sql
echo "IMPORT BDL" ,sum(case when proc_set='IMPORT FTD' then pv else 0 end) "IMPORT FTD" ,sum(case when proc_set='IMPORT FTK-AVI' >> VedaBatchUpload.sql
echo  then pv else 0 end) "IMPORT FTK-AVI" ,sum(case when proc_set='IMPORT FTK-HEA' then pv else 0 end) "IMPORT FTK-HEA" >> VedaBatchUpload.sql
echo  ,sum(case when proc_set='IMPORT BIOOIL' then pv else 0 end) "IMPORT BIOOIL" ,sum(case when proc_set='IMPORT BIOMASS' >> VedaBatchUpload.sql
echo  then pv else 0 end) "IMPORT BIOMASS" ,sum(case when proc_set='IMPORT COAL' then pv else 0 end) "IMPORT COAL" >> VedaBatchUpload.sql
echo ,sum(case when proc_set='IMPORT COKE' then pv else 0 end) "IMPORT COKE" ,sum(case when proc_set='IMPORT ELC' then pv >> VedaBatchUpload.sql
echo else 0 end) "IMPORT ELC" ,sum(case when proc_set='IMPORT ETHANOL' then pv else 0 end) "IMPORT ETHANOL" ,sum(case when >> VedaBatchUpload.sql
echo proc_set='IMPORT HYL' then pv else 0 end) "IMPORT HYL" ,sum(case when proc_set='IMPORT NGA' then pv else 0 end) >> VedaBatchUpload.sql
echo "IMPORT NGA" ,sum(case when proc_set='IMPORT OIL' then pv else 0 end) "IMPORT OIL" ,sum(case when proc_set='IMPORT DST' >> VedaBatchUpload.sql
echo  then pv else 0 end) "IMPORT DST" ,sum(case when proc_set='IMPORT HFO' then pv else 0 end) "IMPORT HFO" ,sum(case >> VedaBatchUpload.sql
echo when proc_set='IMPORT JET' then pv else 0 end) "IMPORT JET" ,sum(case when proc_set='IMPORT KER' then pv else 0 end) >> VedaBatchUpload.sql
echo "IMPORT KER" ,sum(case when proc_set='IMPORT LFO' then pv else 0 end) "IMPORT LFO" ,sum(case when proc_set='IMPORT LPG' >> VedaBatchUpload.sql
echo  then pv else 0 end) "IMPORT LPG" ,sum(case when proc_set='IMPORT MOIL' then pv else 0 end) "IMPORT MOIL" , >> VedaBatchUpload.sql
echo sum(case when proc_set='IMPORT GSL' then pv else 0 end) "IMPORT GSL" ,sum(case when proc_set='IMPORT URN' then pv >> VedaBatchUpload.sql
echo else 0 end) "IMPORT URN" ,tablename,period from ( select tablename,period, pv, case when process in('IMPBIODST') then >> VedaBatchUpload.sql
echo 'IMPORT BDL' when process in('IMPBIODST-FT') then 'IMPORT FTD' when process in('IMPBIOJET-FT') then 'IMPORT FTK-AVI' >> VedaBatchUpload.sql
echo when process in('IMPBIOKET-FT') then 'IMPORT FTK-HEA' when process in('IMPBVOIL','IMPBVOFAT','IMPBIOOIL') then >> VedaBatchUpload.sql
echo 'IMPORT BIOOIL' when process in('IMPBWODWST','IMPBGRASS','IMPBSTARCH','IMPAGWST','IMPBWOD') then 'IMPORT BIOMASS' >> VedaBatchUpload.sql
echo when process in('IMPCOA-E','IMPCOA','IMPCOACOK') then 'IMPORT COAL' when process in('IMPCOK') then 'IMPORT COKE' when >> VedaBatchUpload.sql
echo process in('IMPELC-EU','IMPELC-IRE') then 'IMPORT ELC' when process in('IMPETH') then 'IMPORT ETHANOL' when process >> VedaBatchUpload.sql
echo in('IMPHYL') then 'IMPORT HYL' when process in('IMPNGA-LNG','IMPNGA-N','IMPNGA-E','IMPNGA-EU') then 'IMPORT NGA' when >> VedaBatchUpload.sql
echo process in('IMPOILCRD2','IMPOILCRD1','IMPOILCRD1-E') then 'IMPORT OIL' when process in('IMPOILDST') then 'IMPORT DST' >> VedaBatchUpload.sql
echo when process in('IMPOILHFO') then 'IMPORT HFO' when process in('IMPOILJET') then 'IMPORT JET' when process >> VedaBatchUpload.sql
echo in('IMPOILKER') then 'IMPORT KER' when process in('IMPOILLFO') then 'IMPORT LFO' when process in('IMPOILLPG') then >> VedaBatchUpload.sql
echo 'IMPORT LPG' when process in('IMPOILMSC') then 'IMPORT MOIL' when process in('IMPOILPET') then 'IMPORT GSL' when >> VedaBatchUpload.sql
echo process in('IMPURN') then 'IMPORT URN' end as proc_set from vedastore where attribute='VAR_FOut' and commodity >> VedaBatchUpload.sql
echo in('INDPELL','BIOLPG','MSWINO','AGRLPG','HYLTK','AGRBOM','HYL','BOG-AD','SERBOM','TRALFODS','BIOJET-FT','NGA-I-EU' , >> VedaBatchUpload.sql
echo 'OILCRDRAW','SYNOIL','IOISTM','RESHYG','RESHYGREF-NA','HYGLHPD','PRCOILCRD','TRAHYGS','PRCCOA','AGRBIODST','IISNGAE', >> VedaBatchUpload.sql
echo 'SERWOD' ,'ELCMSWORG','BTREATWOD','INDCOK','TRABIOLFODS','NGAPTR','HYGSNGA','METH','BIODST-FT','TRALNGISL', >> VedaBatchUpload.sql
echo 'TRAJETIANL','SERBOG','AGRELC' ,'HYDROR','UPSHYG','TRABIOOILISL','HYGMSWINO','ELCSTWWST','MSWORG','UPSNGA','TRAJETIA', >> VedaBatchUpload.sql
echo 'INDSTM','SERELC','SERBUILDHYG','ELCCOG' ,'AGRDISTELC','TRADISTELC','AGRGRASS','TRALFO','HYGELCSURP','OILLPG', >> VedaBatchUpload.sql
echo 'WNDOFF','PCHPHEAT','INDGRASS','HYGL-IGCC','BVOIL','COK' ,'RESHOUSEBOM','TRABIODST-FTS','ELC','IISCOGB','INDCOACOK', >> VedaBatchUpload.sql
echo 'IISCOGC','TRAJETIAEL','UPSHEAT','AGRMAINSBOM','ELCBOM','HYGBIOO','TRAHFODSL' ,'COG','NGA','ELC-I-IRE','RESDISTELC', >> VedaBatchUpload.sql
echo 'HYGL','ELCBIOCOA','AGRLFO','BIOKER-FT','TRALPGS','RESHOUSEELC','RESMAINSBOM','COACOK' ,'TRAHYGL','MSWBIO','RESWOD', >> VedaBatchUpload.sql
echo 'PRCCOACOK','ELCPELL','BGRASS','INDNEUMSC','INDMAINSHYG','INDBOM','INDBOG-AD','TRAHYG','TRADST' ,'BENZ','INDCOA', >> VedaBatchUpload.sql
echo 'SERBUILDBOM','ELCHYDDAM','ELCWNDOFS','TRALNGDS','ELCLFO','ELCWAV','HYGLNGA','TRACPHB','BOM','INDWODWST' ,'SERMSWBIO', >> VedaBatchUpload.sql
echo 'SERPELH','INDBIOOIL','RHEATPIPE-EA','TRAPET','TRABIODSTS','TRALFODSL','BOG-LF','RESWODL','INDKER','TRACOA','ELCHFO' , >> VedaBatchUpload.sql
echo 'INDNEULFO','ETH','INDBIOLPG','INDNEUNGA','TRANGA','AGRNGA','HYGSELC','BRSEED','AGRPOLWST','INDNGA','TRACNGL', >> VedaBatchUpload.sql
echo 'ELCMSWINO' ,'TRALNGIS','TRABIODSTL','SERNGA','TRAELC','BSLURRY','TRABOM','ELCWNDONS','TRABIOJET-FTDA','TRAHFOIS', >> VedaBatchUpload.sql
echo 'BSEWSLG','SERMSWORG','TRAHFOISL' ,'COA','NGA-E-IRE','AGRHFO','ELC-E-IRE','RESBOM','INDBENZ','RESELC','RESELCSURPLUS', >> VedaBatchUpload.sql
echo 'AGRHYG','COA-E','GEO','IISBFGB' ,'ELCLPG','SERGEO','BOG-G','TRABIODST','TRABIOOILIS','IISCOKE','INDHYG','TRADSTL', >> VedaBatchUpload.sql
echo 'BFG','INDLPG','OILMSC','OILPET' ,'PRCHFO','ELCBOG-AD','ELCBIOOIL','INDNEULPG','RESHYGREF-EA','BSTWWST','RESHOUSEHYG', >> VedaBatchUpload.sql
echo 'IISBFGC','BSTARCH','NGA-E-EU','OILJET','HYDDAM' ,'TRAETH','UPSLFO','INDMSWINO','SERBIOLFO','IISNGAB','ELC-E-EU', >> VedaBatchUpload.sql
echo 'BWODLOG','TRAJETDAEL','IISCOKS','TRAMETH','SERMAINSBOM','ELCPOLWST' ,'PWASTEDUM','NGA-I-N','SERMAINSHYG','BPELL', >> VedaBatchUpload.sql
echo 'TRAJETL','TRAPETS','INDPELH','INDPOLWST','WAV','HYGELC','RESCOK','ELCSOL' ,'ELCBFG','RESNGA','TRABIODST-FT', >> VedaBatchUpload.sql
echo 'RESMAINSHYG','INDWOD','INDSYNOIL','TRAHFO','INDBFG','ELCBOG-SW','SERLFO','TRAPETL','ELCHYGIGCC' ,'ELCMAINSBOM', >> VedaBatchUpload.sql
echo 'TRAJETDA','TRABIOLFODSL','TRABIOLFOL','RESKER','INDSYNCOA','TRALNG','ELCBOG-LF','TRAETHL','ELCTRANSBOM','IISHFOB', >> VedaBatchUpload.sql
echo 'ELCGEO' ,'ELCSURPLUS','BIODST','ELCNGA','INDHFO','BIOLFO','ELC-I-EU','LNG','INDBOG-LF','TRABIOJET-FTIAL','OILHFO', >> VedaBatchUpload.sql
echo 'TRABIOJET-FTDAL','SERCOA' ,'TRALPGL','SERSOL','HYGBPEL','BSUGAR','TRAETHS','HYGCOA','NGA-E','TRADSTS','OILLFO', >> VedaBatchUpload.sql
echo 'TRALPG','TRABIODST-FTL','TRALNGDSL' ,'IISNGAC','ELCTID','INDCOG','RHEATPIPE-NA','SERHFO','SERDISTELC','SERMSWINO', >> VedaBatchUpload.sql
echo 'BWOD','INMSTM','BPELH','SERBUILDELC','TRABIOJET-FTIA' ,'TRACNGS','ELCGEN','HYGLHPT','RESBIOLFO','AGRCOA', >> VedaBatchUpload.sql
echo 'INDDISTELC','HYGLELC','BTREATSTW','BWODWST','IISCOKB','SYNCOA','UPSMAINSHYG' ,'ICHOTH','TRAMAINSBOM','RESLPG', >> VedaBatchUpload.sql
echo 'TRACELC','TID','INDMAINSBOM','TRAHFODS','RESSOL','TRAHYGDCN','TRALFOL','PRCELC','ELCPELH' ,'WNDONS','OILCRDRAW-E', >> VedaBatchUpload.sql
echo 'ELCBIOLFO','ELCHYG','OILDST','PRCNGA','OILKER','AGRBIOLPG','SOL','ICHSTM','RESCOA','INDELC' ,'OILCRD','SERLPG', >> VedaBatchUpload.sql
echo 'ELCBIOCOA2','HYGMSWORG','ELCCOA','URN','RHCSV-RHEA','INDMSWORG','TRAHYL','BIOOIL','ELCMSC','SERHYG' ,'UPSELC', >> VedaBatchUpload.sql
echo 'RESPELH','TRABIOLFO','RESLFO','INDBIOLFO','SERKER','INDLFO','IFDSTM') and process in('IMPBIODST-FT','IMPCOA-E', >> VedaBatchUpload.sql
echo 'IMPOILMSC','IMPOILLPG','IMPCOACOK','IMPBIOJET-FT','IMPBIOOIL','IMPETH','IMPOILCRD2','IMPOILHFO','IMPBSTARCH', >> VedaBatchUpload.sql
echo 'IMPBVOIL' ,'IMPAGWST','IMPCOK','IMPBIODST','IMPOILJET','IMPBGRASS','IMPOILCRD1-E','IMPOILKER','IMPOILDST','IMPNGA-E', >> VedaBatchUpload.sql
echo 'IMPBWODWST','IMPELC-IRE','IMPELC-EU' ,'IMPNGA-N','IMPOILCRD1','IMPBWOD','IMPHYL','IMPBIOKET-FT','IMPBVOFAT', >> VedaBatchUpload.sql
echo 'IMPNGA-EU','IMPOILPET','IMPOILLFO','IMPNGA-LNG','IMPURN','IMPCOA') ) a where proc_set is not null group by tablename, >> VedaBatchUpload.sql
echo period order by tablename,period ) ,rsr_export as( select sum(case when proc_set='EXPORT BIOMASS' then pv else 0 >> VedaBatchUpload.sql
echo end) "EXPORT BIOMASS" ,sum(case when proc_set='EXPORT COAL' then pv else 0 end) "EXPORT COAL" ,sum(case when >> VedaBatchUpload.sql
echo proc_set='EXPORT COKE' then pv else 0 end) "EXPORT COKE" ,sum(case when proc_set='EXPORT ELC' then pv else 0 end) >> VedaBatchUpload.sql
echo "EXPORT ELC" ,sum(case when proc_set='EXPORT ETH' then pv else 0 end) "EXPORT ETH" ,sum(case when proc_set='EXPORT NGA' >> VedaBatchUpload.sql
echo  then pv else 0 end) "EXPORT NGA" ,sum(case when proc_set='EXPORT OIL' then pv else 0 end) "EXPORT OIL" ,sum(case >> VedaBatchUpload.sql
echo when proc_set='EXPORT DST' then pv else 0 end) "EXPORT DST" ,sum(case when proc_set='EXPORT HFO' then pv else 0 end) >> VedaBatchUpload.sql
echo "EXPORT HFO" ,sum(case when proc_set='EXPORT JET' then pv else 0 end) "EXPORT JET" ,sum(case when proc_set='EXPORT KER' >> VedaBatchUpload.sql
echo  then pv else 0 end) "EXPORT KER" ,sum(case when proc_set='EXPORT LFO' then pv else 0 end) "EXPORT LFO" ,sum(case >> VedaBatchUpload.sql
echo when proc_set='EXPORT LPG' then pv else 0 end) "EXPORT LPG" ,sum(case when proc_set='EXPORT MOIL' then pv else 0 end) >> VedaBatchUpload.sql
echo "EXPORT MOIL" ,sum(case when proc_set='EXPORT GSL' then pv else 0 end) "EXPORT GSL" ,tablename,period from ( select >> VedaBatchUpload.sql
echo tablename,period, pv, case when process in('EXPCOA','EXPCOA-E') then 'EXPORT COAL' when process in('EXPCOK') then >> VedaBatchUpload.sql
echo 'EXPORT COKE' when process in('EXPELC-IRE','EXPELC-EU') then 'EXPORT ELC' when process in('EXPETH') then 'EXPORT ETH' >> VedaBatchUpload.sql
echo when process in('EXPNGA-E','EXPNGA-IRE','EXPNGA-EU') then 'EXPORT NGA' when process in('EXPOILCRD1-E','EXPOILCRD1', >> VedaBatchUpload.sql
echo 'EXPOILCRD2') then 'EXPORT OIL' when process in('EXPOILDST') then 'EXPORT DST' when process in('EXPOILHFO') then >> VedaBatchUpload.sql
echo 'EXPORT HFO' when process in('EXPOILJET') then 'EXPORT JET' when process in('EXPOILKER') then 'EXPORT KER' when >> VedaBatchUpload.sql
echo process in('EXPOILLFO') then 'EXPORT LFO' when process in('EXPOILLPG') then 'EXPORT LPG' when process in('EXPOILMSC') >> VedaBatchUpload.sql
echo then 'EXPORT MOIL' when process in('EXPOILPET') then 'EXPORT GSL' end as proc_set from vedastore where >> VedaBatchUpload.sql
echo attribute='VAR_FIn' and commodity in('SYNCOA','RESLPG','TRAMAINSBOM','BPELH','SERBUILDELC','ELCGEN','HYGLHPT', >> VedaBatchUpload.sql
echo 'INFOTH','INMHTH','RHUFLOOR-HC','INDCOG','SHLDELVRAD' ,'SERHFO','RHEATPIPE-HS','SERMSWINO','BWOD','OILLFO', >> VedaBatchUpload.sql
echo 'RHUFLOOR-FS','SHHDELVRAD','SWHDELVSTD','INDMAINSGAS','IISELCC','TRALNGDSL','ICHPRO' ,'TRALPGL','BSUGAR','IPPLTHD2', >> VedaBatchUpload.sql
echo 'TRAETHS','TRAMAINSGAS','RESHYGREF-FS','RHUFLOOR-HS','RWSTAND-EA','ELCSURPLUS','RESLTHSURPLUS-FS','INDHFO', >> VedaBatchUpload.sql
echo 'RESELC-NS-HC' ,'BIOLFO','ELC-I-EU','LNG','SCHCSVDMD','RHUFLOOR-FC','IPPLTHP','TRALNG','ELCBOG-LF','TRAETHL', >> VedaBatchUpload.sql
echo 'ELCTRANSBOM','ELCGEO','TRAHFO' ,'RESELC-NS-EA','SERLFO','TRAPETL','IFDOTH','ELCMAINSBOM','RHCSV-RHHS','TRAJETDA', >> VedaBatchUpload.sql
echo 'RWSTAND-HC','TRABIOLFODSL','INDPELH','WAV','ELCSOL' ,'IOIOTH','IOIREF','TRABIODST-FT','INDWOD','INMOTH','PWASTEDUM', >> VedaBatchUpload.sql
echo 'ICHHTH','NGA-I-N','RESHYGREF-FC','TRAPETS','HYDDAM','NGA-E-EU' ,'UPSLFO','INDMSWINO','SHLCSVDMD','IISNGAB','IOIMOT', >> VedaBatchUpload.sql
echo 'SLOFCSV','TRAJETDAEL','IISCOKS','BFG','INDLPG','PRCHFO','ELCBOG-AD' ,'ELCBIOOIL','INDNEULPG','RESHYGREF-EA', >> VedaBatchUpload.sql
echo 'BSTWWST','IISBFGC','BSTARCH','ELCLPG','IPPELCO','TRABIODST','IISCOKE','ICHREF','IISLTHS' ,'AGRHYG','IISBFGB', >> VedaBatchUpload.sql
echo 'SERMSWORG','IPPLTHD4','NGA-E-IRE','RHSTAND-HC','URN045','RHCSV-RHFC','RESBOM','IOILTH','IPPLTHD','INDBENZ' , >> VedaBatchUpload.sql
echo 'IPPLTHD3','SERBUILDGAS','RESHYGREF-HC','SERNGA','TRAELC','BSLURRY','ELCWNDONS','IOIHTH','TRAHFOIS','ETH','INDNEUNGA', >> VedaBatchUpload.sql
echo 'TRANGA' ,'BRSEED','INDNGA','TRALNGIS','IISLTHE','SHLCSV','TRAPET','TRABIODSTS','TRALFODSL','BOG-LF','IPPLTHD5', >> VedaBatchUpload.sql
echo 'RESWODL','INDKER' ,'INFMOT','RWCSV-RWHS','ELCHFO','ELCLFO','IISLTH','TRALNGDS','IFDMOT','IISELCE','IISELCB', >> VedaBatchUpload.sql
echo 'INDWODWST','IPPELCD','SERMSWBIO' ,'INDBIOOIL','IPPELCD4','ELCMAINSGAS','INDBOG-AD','INDCOA','ELCBIOCOA','PREFGAS', >> VedaBatchUpload.sql
echo 'AGRLFO','RESHOUSEELC','RESLTHSURPLUS-HS','RESMAINSBOM','MSWBIO' ,'ELCPELL','COK','RESHOUSEBOM','ELC','IISCOGB', >> VedaBatchUpload.sql
echo 'IISCOGC','INDCOACOK','TRAJETIAEL','UPSHEAT','AGRMAINSBOM','ELCBOM','COG' ,'ELCTRANSGAS','INMDRY','TRAHFODSL', >> VedaBatchUpload.sql
echo 'AGRGRASS','TRALFO','OILLPG','PCHPHEAT','WNDOFF','INDGRASS','HYGL-IGCC','BVOIL','RESELC-NS-HS' ,'RESLTH-FC', >> VedaBatchUpload.sql
echo 'ELCSTWWST','INDSTM','MSWORG','RHSTAND-FS','TRAJETIA','UPSNGA','WAT','SERELC','ELCCOG','RESLTHSURPLUS-EA', >> VedaBatchUpload.sql
echo 'AGRDISTELC' ,'TRADISTELC','RESLFO','RWCSV-RWFC','TRABIOLFO','IPPELCD5','TRAJETIANL','INDBIOLFO','AGRELC','SERBOG', >> VedaBatchUpload.sql
echo 'URND','SERKER','HYDROR' ,'IFDSTM','INDLFO','IPPLTHO1','RESLTH-EA','SHLDELVUND','TRABIOOILISL','NGAPTR','RHUFLOOR-EA', >> VedaBatchUpload.sql
echo 'TRABIOLFODS','BIOOIL','ELCMSC','SERHYG' ,'SWHDELVPIP','AGRMAINSGAS','METH','UPSELC','BIODST-FT','IPPLTHD1', >> VedaBatchUpload.sql
echo 'RESHYGREF-HS','RESPELH','RHEATPIPE-FS','TRALNGISL','ELCCOA','INDCOK' ,'URN','RHCSV-RHEA','ICHLTH','INDMSWORG', >> VedaBatchUpload.sql
echo 'RWSTAND-FS','ICHSTM','IISNGAE','SWLDELVSTD','RESCOA','SERWOD','INDELC','OILCRD' ,'RHSTAND-EA','SERLPG','SHHCSVDMD', >> VedaBatchUpload.sql
echo 'ELCMSWORG','ELCWSTHEAT','SOL','HYGLHPD','SERELC-NS','PRCOILCRD','IPPELCD1','PRCCOA','RHCSV-RHFS' ,'AGRBIODST', >> VedaBatchUpload.sql
echo 'IISLTHB','RWCSV-RWFS','BOG-AD','OILKER','PRCNGA','SERBOM','TRALFODS','BIOJET-FT','URN19','NGA-I-EU','OILCRDRAW' , >> VedaBatchUpload.sql
echo 'SYNOIL','IOISTM','AGRBIOLPG','IISCOACOKB','RESHYG','ELCPELH','IPPELCD3','MSWINO','WNDONS','OILCRDRAW-E','SHHCSV', >> VedaBatchUpload.sql
echo 'AGRLPG' ,'HYLTK','AGRBOM','ELCBIOLFO','ELCHYG','ICHDRY','URN09','HYL','ISO','OILDST','INDMAINSBOM','INMLTH', >> VedaBatchUpload.sql
echo 'RESLTHSURPLUS-FC' ,'TRAHFODS','RESSOL','INDPELL','RESELC-NS-FS','RESLTH-HC','BIOLPG','ELCMAN','TRALFOL','PRCELC', >> VedaBatchUpload.sql
echo 'BWODWST','IISCOKB','ICHOTH' ,'RWSTAND-HS','TID','ICHMOT','RESHOUSEGAS','TRABIOJET-FTIA','RESBIOLFO','AGRCOA', >> VedaBatchUpload.sql
echo 'INDDISTELC','IISNGAC','RWCSV-RWEA','IFDREF','RHEATPIPE-FC' ,'SERDISTELC','INMSTM','RESLTH-HS','IISELCS','IISLTHC', >> VedaBatchUpload.sql
echo 'RESELC-NS-FC','TRADSTS','SERLTH','TRALPG','ELCURN','OILHFO','TRABIOJET-FTIAL' ,'RHSTAND-HS','TRABIOJET-FTDAL', >> VedaBatchUpload.sql
echo 'SERCOA','SERSOL','NGA-E','RESLTH-FS','BIODST','ELCNGA','IPPELCD2','IPPELCP','INDBOG-LF','IISTGS' ,'RESKER', >> VedaBatchUpload.sql
echo 'INDSYNCOA','RWSTAND-FC','IISHFOB','INDBFG','INDSYNOIL','ELCBOG-SW','URNU','IPPLTHO','TRABIOLFOL','IPPLTH', >> VedaBatchUpload.sql
echo 'INDPOLWST' ,'SHHDELVAIR','RESCOK','ELCBFG','RESNGA','SERHYGREF','INMMOT','TRAMETH','INFHTH','SERMAINSBOM', >> VedaBatchUpload.sql
echo 'ELCPOLWST','SERLTHSURPLUS','BPELL' ,'TRAJETL','OILJET','TRAETH','SERBIOLFO','ELC-E-EU','BWODLOG','RHCSV-RHHC', >> VedaBatchUpload.sql
echo 'TRADSTL','OILMSC','OILPET','SERMAINSGAS','RHSTAND-FC' ,'SERGEO','BOG-G','IOIDRY','SHLDELVAIR','TRABIOOILIS','INDHYG', >> VedaBatchUpload.sql
echo 'RESELCSURPLUS','COA-E','GEO','BSEWSLG','TRAHFOISL','AGRHFO' ,'COA','ELC-E-IRE','IFDDRY','RESELC','RWCSV-RWHC', >> VedaBatchUpload.sql
echo 'TRABIODSTL','TRABOM','TRABIOJET-FTDA','INDBIOLPG','AGRNGA','AGRPOLWST','ELCMSWINO' ,'IPPELCO1','RESMAINSGAS', >> VedaBatchUpload.sql
echo 'RHEATPIPE-HC','RESLTHSURPLUS-HC','INDNEULFO','TRACOA','ELCHYDDAM','ELCWNDOFS','BOM','SERPELH','RHEATPIPE-EA', >> VedaBatchUpload.sql
echo 'BGRASS' ,'INDNEUMSC','INDBOM','BENZ','TRADST','SERBUILDBOM','ELC-I-IRE','NGA','RESDISTELC','SCHDELVAIR','BIOKER-FT', >> VedaBatchUpload.sql
echo 'TRALPGS','COACOK' ,'IFDLTH','PRCCOACOK','RESWOD') and process in('EXPCOA','EXPCOA-E','EXPETH','EXPCOK','EXPOILLPG', >> VedaBatchUpload.sql
echo 'EXPOILJET','EXPOILPET','EXPOILLFO','EXPOILCRD1','EXPNGA-E','EXPOILCRD2','EXPELC-EU' ,'EXPOILMSC','EXPOILDST', >> VedaBatchUpload.sql
echo 'EXPOILCRD1-E','EXPNGA-IRE','EXPNGA-EU','EXPOILHFO','EXPELC-IRE','EXPOILKER') ) a where proc_set is not null group by >> VedaBatchUpload.sql
echo tablename, period order by tablename,period ) ,nuclear as( select sum(pv)/0.398 "ELC FROM NUCLEAR", tablename,period >> VedaBatchUpload.sql
echo from vedastore where attribute='VAR_FOut' and commodity in('ELCDUMMY','ELC','ELC-E-IRE','ELC-E-EU','ELCGEN') and >> VedaBatchUpload.sql
echo process in('ENUCAGRN00','ENUCPWR101','ENUCPWR102','ENUCAGRO00','ENUCPWR00') group by tablename,period order by >> VedaBatchUpload.sql
echo tablename,period ) ,end_demand as( select sum("MINING BIOMASS")+sum("IMPORT BIOMASS")+sum("IMPORT BDL")+sum("IMPORT BIOOIL" >> VedaBatchUpload.sql
echo )+sum("IMPORT ETHANOL")+sum("IMPORT FTD")+sum("IMPORT FTK-AVI")-SUM("EXPORT ETH")-sum("EXPORT BIOMASS") "bio" , >> VedaBatchUpload.sql
echo sum("MINING COAL")+sum("IMPORT COAL")-sum("EXPORT COAL")+sum("IMPORT COKE")-sum("EXPORT COKE") "coa" ,sum("IMPORT ELC" >> VedaBatchUpload.sql
echo )-sum("EXPORT ELC") "elec" ,sum("MINING NGA")+sum("IMPORT NGA")+sum("MINING NGA-SHALE")-sum("EXPORT NGA") "gas" , >> VedaBatchUpload.sql
echo sum("IMPORT HYL") "h2" ,sum("MINING OIL")+sum("IMPORT OIL")-sum("EXPORT OIL")+sum("IMPORT DST")+sum("IMPORT GSL" >> VedaBatchUpload.sql
echo )+sum("IMPORT HFO")+sum("IMPORT JET")+ sum("IMPORT KER")+sum("IMPORT LFO")+sum("IMPORT LPG")+sum("IMPORT MOIL" >> VedaBatchUpload.sql
echo )-sum("EXPORT DST")-sum("EXPORT GSL") -sum("EXPORT HFO")-sum("EXPORT JET")-sum("EXPORT KER")-sum("EXPORT LFO" >> VedaBatchUpload.sql
echo )-sum("EXPORT LPG")-sum("EXPORT MOIL") "oil" ,sum("MINING HYDRO")+sum("MINING WIND")+sum("MINING SOLAR" >> VedaBatchUpload.sql
echo )+sum("MINING GEOTHERMAL")+sum("MINING TIDAL")+sum("MINING WAVE") "rens" ,sum(d."ELC FROM NUCLEAR") "nuc" , >> VedaBatchUpload.sql
echo a.period,a.tablename from rsr_min a join rsr_imports b on a.period=b.period and a.tablename=b.tablename join >> VedaBatchUpload.sql
echo rsr_export c on a.period=c.period and a.tablename=c.tablename join nuclear d on a.period=d.period and >> VedaBatchUpload.sql
echo a.tablename=d.tablename group by a.tablename,a.period order by a.period ) select 'pri-en_' ^|^| cols ^|^| '^|' ^|^| >> VedaBatchUpload.sql
echo tablename ^|^| '^|various^|various^|various'::varchar "id", 'pri-en_'^|^| cols::varchar "analysis", tablename, >> VedaBatchUpload.sql
echo 'various'::varchar "attribute", 'various'::varchar "commodity", 'various'::varchar "process", sum(vals) "all", >> VedaBatchUpload.sql
echo sum(case when a.period='2010' then vals else 0 end) as "2010", sum(case when a.period='2011' then vals else 0 end) as >> VedaBatchUpload.sql
echo "2011", sum(case when a.period='2012' then vals else 0 end) as "2012", sum(case when a.period='2015' then vals else 0 >> VedaBatchUpload.sql
echo end) as "2015", sum(case when a.period='2020' then vals else 0 end) as "2020", sum(case when a.period='2025' then >> VedaBatchUpload.sql
echo vals else 0 end) as "2025", sum(case when a.period='2030' then vals else 0 end) as "2030", sum(case when >> VedaBatchUpload.sql
echo a.period='2035' then vals else 0 end) as "2035", sum(case when a.period='2040' then vals else 0 end) as "2040", >> VedaBatchUpload.sql
echo sum(case when a.period='2045' then vals else 0 end) as "2045", sum(case when a.period='2050' then vals else 0 end) as >> VedaBatchUpload.sql
echo "2050", sum(case when a.period='2055' then vals else 0 end) as "2055", sum(case when a.period='2060' then vals else 0 >> VedaBatchUpload.sql
echo end) as "2060" from ( SELECT unnest(array['bio','coa','elc','gas','hyd','oil','orens','nuc']) as "cols", tablename, >> VedaBatchUpload.sql
echo period, unnest(array[bio,coa,elec,gas,h2,oil,rens,nuc]) AS "vals" FROM end_demand ) a group by tablename,cols UNION >> VedaBatchUpload.sql
echo ALL select 'bio-en_' ^|^| cols ^|^| '^|' ^|^| tablename ^|^| '^|VAR_FOut^|various^|' ^|^| process::varchar "id", >> VedaBatchUpload.sql
echo 'bio-en_'^|^| cols::varchar "analysis", tablename, 'VAR_FOut'::varchar "attribute", 'various'::varchar "commodity", >> VedaBatchUpload.sql
echo process, sum(vals) "all", sum(case when a.period='2010' then vals else 0 end) as "2010", sum(case when >> VedaBatchUpload.sql
echo a.period='2011' then vals else 0 end) as "2011", sum(case when a.period='2012' then vals else 0 end) as "2012", >> VedaBatchUpload.sql
echo sum(case when a.period='2015' then vals else 0 end) as "2015", sum(case when a.period='2020' then vals else 0 end) as >> VedaBatchUpload.sql
echo "2020", sum(case when a.period='2025' then vals else 0 end) as "2025", sum(case when a.period='2030' then vals else 0 >> VedaBatchUpload.sql
echo end) as "2030", sum(case when a.period='2035' then vals else 0 end) as "2035", sum(case when a.period='2040' then >> VedaBatchUpload.sql
echo vals else 0 end) as "2040", sum(case when a.period='2045' then vals else 0 end) as "2045", sum(case when >> VedaBatchUpload.sql
echo a.period='2050' then vals else 0 end) as "2050", sum(case when a.period='2055' then vals else 0 end) as "2055", >> VedaBatchUpload.sql
echo sum(case when a.period='2060' then vals else 0 end) as "2060" from ( select 'dom-prod' "cols", 'MINING BIOMASS' >> VedaBatchUpload.sql
echo "process", "MINING BIOMASS" "vals", period, tablename from rsr_min union all select 'imports' "cols", 'various' >> VedaBatchUpload.sql
echo "process", "IMPORT BDL"+"IMPORT BIOOIL"+"IMPORT ETHANOL"+"IMPORT FTD"+"IMPORT FTK-AVI"+"IMPORT BIOMASS" "vals", >> VedaBatchUpload.sql
echo period, tablename from rsr_imports union all select 'exports' "cols", 'various' "process", "EXPORT BIOMASS"+"EXPORT ETH" >> VedaBatchUpload.sql
echo  "vals", period, tablename from rsr_export ) a group by tablename,cols,process ORDER BY tablename,analysis ) TO >> VedaBatchUpload.sql
echo '%~dp0PriEnOut.csv' delimiter ',' CSV; >> VedaBatchUpload.sql
rem following line actually runs the SQL code generated by the above using the postgres command utility "psql".
rem Comment this line out if you just want the SQL code to create the populated temp tables + the associated analysis queries:
"C:\Program Files\PostgreSQL\9.4\bin\psql.exe" -h localhost -p 5432 -U postgres -d gams -f %~dp0VedaBatchUpload.sql
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
