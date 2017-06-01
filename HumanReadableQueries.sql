/* ***Human readable versions of "standard" queries analysing results from the UK TIMES [UKTM] model*** 

/*Developed against model ver = uktm_model_v1.2.3_d0.1.2_DNP

This file is a "human readable" (= formatted) version of key regularly re-used crosstabs in various DOS batch files (.BAT). As far as possible, these replicate
Veda BE tables (here reproduced as CTEs). There are several sections in the file, each corresponding to a different BAT. These are themed
(e.g. transport), and the final batch is a general set of model output metrics which are likely to be useful most of the time. This version of the code includes
comments which are not included in the BAT versions.

Requires: postgres 9.4 or higher, DOS. Works on plain text "VD" file outputs from Veda / UKTM

NB  *   If a particular model run doesn't build it, then there will be no entry in the VD file for it and hence no line in the results output —
        with few exceptions lines which are completely zero are not reported
    *   Queries are "wrapped" with a "copy" statement. Destinations of these files ") TO... " are in BAT syntax. In interactive mode (if running these queries in a postgres browser),
        you'll have to change these to a full path (e.g. C:\0\...csv) or else the q will  not run. By default, headings are not output for all except the first q.
        Can add these by adding the "HEADER" keyword after the "CSV" statement but before the ';'. Instead, and if you don't want CSV output, you can copy the q without the surrounding
        "copy (... ) TO " statement. If taking this approach, may require a terminating ';' (When a q is wrapped with "copy", the last SQL statement _should_not_ be terminated
        with a ";".)
    *   Filters are as specific as possible with wildcards removed. This means that the qs will have to be carefully revised if the structure of the model changes.
    *   There is Ruby code to build batch files from this file. It recognises what goes in which batch by looking for headings with 2 asterisks together and
        "BAT" in capitals, + no "End of". It looks for these things + "End of" to figure out where a set of batch queries ends. Be careful not to change these and to set up any other batch entries in the same way. 

General comment: order of headings in output is:
    id [= concatenation of all other fields]
    analysis
    tablename
    attribute
    commodity
    process
    ...followed by years to 2060

Fernley Symons, 2015 ff

Original version:
FS 7:12 PM 20-Nov-15
Revisions section placed at end of file.
*/

/* ******List of completed queries*******/
/* **Miscellaneous queries (not included in batch files): ** */
/* ----------------------------------------------------------*/
/* *Total fuel consumption by fuel for other industry (industry sub-sector)* */ --line 80

/* **Electricity Batch File: ** */ --line 181
/* ------------------------------------------*/
/* *Annual timesliced elec storage output (techs grouped)* */ --line 183

/* **For agriculture / LULUCF batch file: ** */ --line 227
/* ------------------------------------------*/
/* *Landfill CH4 emission mitigation and residual emissions* */ --line 229
/* *Land use and crop / livestock mitigation (MACC) measures* */ --line 266
/* *Afforestation rate* */ --line 307

/* **For transport batch file: ** */ --line 334
/* -------------------------------*/
/* *Whole stock vehicle kms, emissions and emission intensity for 29 vehicle types* */ --line 337
/* *New stock vehicle kms, emissions and emission intensity for 29 vehicle types* */ --line 505
/* *Whole stock capacity for vehicles for 29 vehicle types* */ --line 660
/* *New build capacity for vehicles for 29 vehicle types* */ --line 714
/* *TRA_Fuel_by_mode* */ --line 769
/* *Road transport fuel by mode and fuel* */ --line 859

/* **Main "key outputs" crosstabs** */ --line 909
/* -------------------------------*/
/* *Dummy imports by table* */ --line 911
/* *All GHG emissions* */ --line 941
/* *GHG emissions by sector* */ --line 972
/* *GHG and sequestered emissions by industry sub-sector* */ --line 1036
/* *Electricity generation by source* */ --line 1130
/* *Electricity storage by type* */ --line 1674
/* *Electricity capacity by process* */ --line 1708
/* *Costs by sector and type* */ --line 1790
/* *Marginal prices for emissions* */ --line 1843
/* *Whole stock heat output by process for residential* */ --line 1873
/* *New build residential heat output by source* */ --line 1946
/* *Whole stock heat output for services* */ --line 2012
/* *New build services heat output by source* */ --line 2100
/* *End user final energy demand by sector* */ --line 2160
/* *Primary energy demand and biomass, imports exports and domestic production* */ --line 2778

/* *Total fuel consumption by fuel for other industry (industry sub-sector)* */
with ind_oi_chp as (
-- I.e. the Veda BE table of the same name
    select comm_set,tablename, period,pv
    from (
        select tablename, period,pv,
        case 
            when commodity in('INDBENZ','INDBFG','INDCOK','INDCOG') then 'IND MANFUELS' --Filter 278
            when commodity in('INDCOACOK','INDCOA') then 'IND COALS' --Filter 257
            when commodity in('INDELC','INDDISTELC') then 'IND ELEC' --Filter 242
            when commodity in('INDHFO','INDLFO','INDLPG','INDKER') then 'IND OIL' --Filter 360
            when commodity in('INDMAINSGAS','INDNGA') then 'IND GAS' --Filter 313
            when commodity in('INDMAINSHYG','INDHYG') then 'IND HYDROGEN' --Filter 268
            when commodity in('INDMSWORG','INDMSWINO','INDWOD','INDPELH','INDPOLWST','INDBIOLFO','INDPELL','INDMAINSBOM',
                'INDBIOOIL','INDWODWST','INDBOG-AD','INDBIOLPG','INDGRASS','INDBOG-LF') then 'IND BIO' --Filter 376
            else null
        end as comm_set
        from vedastore
        where attribute='VAR_FIn' and 
            process in('IOICHPBIOS01','IOICHPCCGT01','IOICHPBIOS00','IOICHPCCGTH01','IOICHPNGA00','IOICHPHFO00','IOICHPGT01','IOICHPBIOG01','IOICHPFCH01','IOICHPCOA01')
    ) a
    where comm_set is not null
), ind_oi_prd as (
-- I.e. the Veda BE table of the same name
    select comm_set,tablename, period,pv
    from (
        select tablename, period,pv,
        case 
            when commodity in('INDBENZ','INDBFG','INDCOK','INDCOG') then 'IND MANFUELS' --Filter 278
            when commodity in('INDCOA','INDCOACOK') then 'IND COALS' --Filter 257
            when commodity in('INDELC','INDDISTELC') then 'IND ELEC' --Filter 242
            when commodity in('INDHFO','INDLFO','INDLPG','INDKER') then 'IND OIL' --Filter 360
            when commodity in('INDMAINSGAS','INDNGA') then 'IND GAS' --Filter 313
            when commodity in('INDMAINSHYG','INDHYG') then 'IND HYDROGEN' --Filter 268
            when commodity in('INDMSWORG','INDMSWINO','INDWOD','INDPELH','INDPOLWST','INDBIOLFO','INDPELL','INDMAINSBOM',
                'INDBIOOIL','INDWODWST','INDBOG-AD','INDBIOLPG','INDGRASS','INDBOG-LF') then 'IND BIO' --Filter 376
            else null
        end as comm_set
        from vedastore
        where attribute='VAR_FIn' and 
            process in('IOIDRYBIOL01','IOILTHBIOS02','IOIDRYCOK00','IOIDRYELC00','IOILTHELC02','IOIOTHLFO00','IOIHTHLFO01','IOILTHHCO01','IOIHTHHFO01','IOIOTHNGA01','IOILTHLPG02','IOILTHKER00'
            ,'IOIDRYHDG02','IOILTHCOK00','IOILTHHFO00','IOIMOTELC00','IOILTHCOK01','IOIDRYNGA01','IOIDRYSTM01','IOIDRYKER00','IOILTHHCO02','IOIHTHKER01','IOIOTHBIOS01','IOIREFEHFC00'
            ,'IOIDRYCOK01','IOIOTHCOK01','IOIOTHHFO00','IOIOTHLFO01','IOIOTHBENZ00','IOIDRYBIOS00','IOIREFEHFO01','IOIHTHBIOG01','IOIHTHLPG00','IOIDRYHCO02','IOIOTHKER00','IOIOTHNGA00'
            ,'IOIDRYBIOG02','IOIDRYHFO02','IOIHTHBIOS00','IOIHTHCOK00','IOILTHLPG01','IOIDRYCOK02','IOILTHHCO00','IOIHTHBIOS01','IOIDRYHDG01','IOIDRYLFO01','IOILTHBIOG02','IOIOTHSTM01'
            ,'IOILTHNGA01','IOIOTHBIOS00','IOIDRYBIOS02','IOIDRYLPG00','IOIDRYBENZ02','IOILTHCOK02','IOIHTHHCO01','IOILTHSTM01','IOIREFEHFC01','IOIHTHCOK01','IOIHTHLFO00','IOIHTHBIOL01'
            ,'IOILTHBIOG01','IOIMOTELC02','IOIDRYNGA00','IOILTHBIOS00','IOILTHELC00','IOIOTHKER01','IOIDRYHFO00','IOIDRYKER02','IOIDRYLPG01','IOIHTHNGA00','IOIOTHELC01','IOIDRYKER01'
            ,'IOIDRYSTM00','IOIHTHBENZ00','IOILTHBIOL02','IOIHTHELC01','IOIHTHLPG01','IOIOTHELC00','IOILTHSTM00','IOIHTHBIOG00','IOILTHLPG00','IOIDRYBIOG01','IOILTHHDG02','IOILTHKER01'
            ,'IOIOTHSTM00','IOIDRYBIOG00','IOILTHLFO00','IOIOTHBIOL01','IOIDRYHCO00','IOIOTHHCO01','IOIDRYELC01','IOIOTHHCO00','IOIOTHLPG01','IOILTHELC01','IOIHTHBENZ01','IOILTHNGA00'
            ,'IOIDRYBENZ01','IOIDRYHCO01','IOILTHNGA02','IOIOTHBIOG01','IOIHTHELC00','IOIDRYELC02','IOILTHLFO01','IOIDRYBENZ00','IOIDRYLFO00','IOIHTHHFO00','IOILTHBENZ02','IOILTHBIOG00'
            ,'IOIOTHCOK00','IOIHTHKER00','IOIOTHHFO01','IOILTHLFO02','IOIHTHNGA01','IOIHTHHCO00','IOILTHBIOL01','IOIMOTELC01','IOIDRYBIOS01','IOIDRYHFO01','IOIDRYLFO02','IOIOTHBIOG00'
            ,'IOIDRYNGA02','IOILTHBENZ01','IOIOTHBENZ01','IOILTHHDG01','IOIOTHHDG01','IOIDRYBIOL02','IOIHTHHDG01','IOILTHBENZ00','IOILTHBIOS01','IOIOTHLPG00','IOIDRYLPG02','IOILTHHFO02'
            ,'IOILTHKER02','IOILTHHFO01')
    ) a
    where comm_set is not null
)
select 'fin-en-other-ind_'|| comm_set ||'|' || tablename || '|' || 'VAR_FIn' || '|' || 'various' || '|various'::varchar(300) "id",
    'fin-en-other-ind_' || comm_set::varchar(300) "analysis", tablename, 'VAR_FIn'::varchar(50) "attribute",
    'various'::varchar(50) "commodity",
    'various'::varchar(50) "process",
    sum(pv)::numeric "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
    select case
        when comm_set='IND COALS' then 'coa'
        when comm_set='IND HYDROGEN' then 'hyd'
        when comm_set='IND MANFUELS' then 'man'
        when comm_set='IND GAS' then 'gas'
        when comm_set='IND ELEC' then 'elc'
        when comm_set='IND BIO' then 'bio'
        when comm_set='IND OIL' then 'oil'
        end as comm_set,
    tablename,period,pv
    from ind_oi_chp
    union all
    select case
        when comm_set='IND COALS' then 'coa'
        when comm_set='IND HYDROGEN' then 'hyd'
        when comm_set='IND MANFUELS' then 'man'
        when comm_set='IND GAS' then 'gas'
        when comm_set='IND ELEC' then 'elc'
        when comm_set='IND BIO' then 'bio'
        when comm_set='IND OIL' then 'oil'
        end as comm_set,
    tablename,period,pv
    from ind_oi_prd
) a
group by tablename, comm_set
order by tablename, comm_set

/* **Electricity BAT (ElecBatchUpload.bat): ** */
/* ------------------------------------------*/
/* *Annual timesliced elec storage output (techs grouped)* */

COPY (
select analysis || '|' || tablename || '|Var_FOut|ELC|various'::varchar(300) "id",
    analysis::varchar(50),
        tablename,
        'VAR_FOut'::varchar "attribute",
        'ELC'::varchar "commodity",
        'various'::varchar(50) "process",
        sum(pv)::numeric "all",
        sum(case when period='2010' then pv else 0 end)::numeric "2010",
        sum(case when period='2011' then pv else 0 end)::numeric "2011",
        sum(case when period='2012' then pv else 0 end)::numeric "2012",
        sum(case when period='2015' then pv else 0 end)::numeric "2015",
        sum(case when period='2020' then pv else 0 end)::numeric "2020",
        sum(case when period='2025' then pv else 0 end)::numeric "2025",
        sum(case when period='2030' then pv else 0 end)::numeric "2030",
        sum(case when period='2035' then pv else 0 end)::numeric "2035",
        sum(case when period='2040' then pv else 0 end)::numeric "2040",
        sum(case when period='2045' then pv else 0 end)::numeric "2045",
        sum(case when period='2050' then pv else 0 end)::numeric "2050",
        sum(case when period='2055' then pv else 0 end)::numeric "2055",
        sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
select process,period,pv,
    case
        when attribute='VAR_FOut' then 'elec-stor-out_'
        when attribute='VAR_FIn' then 'elec-stor-in_'
    end ||
    case
        when process in('EHYDPMP00','EHYDPMP01') then 'hyd' --Filter 394
        when process in ('ECAESCON01','ESTGCAES01','ECAESTUR01','ESTGAACAES01') then 'caes' --Filter 395
        when process in ('ESTGBNAS01','ESTGBALA01','ESTGBRF01') then 'batt' --Filter 396
    end || '-' ||
    TimeSlice "analysis",
    tablename, attribute, TimeSlice
from vedastore
where attribute in('VAR_FOut','VAR_FIn') and commodity = 'ELC'
) a
where analysis is not null
group by id, analysis,tablename, attribute, TimeSlice
order by tablename, analysis, attribute, commodity
) TO '%~dp0elecstortime.csv' delimiter ',' CSV HEADER;
/* **End of Electricity BAT (ElecBatchUpload.bat): ** */

/* **For agriculture / LULUCF BAT (AgBatchUpload.bat): ** */
/* ------------------------------------------------------*/
/* *Landfill CH4 emission mitigation and residual emissions* */
-- Note that the mitigation measures take CH4 in

COPY ( 
select 'landfill-ghg_'|| proc_set || '|' || tablename || '|' || attribute || '|' || commodity || '|various'::varchar(300) "id",
    'landfill-ghg_' || proc_set "analysis", tablename, attribute,
    commodity,'various'::varchar "process",
    sum(pv) "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
    from (
        select tablename, attribute, period,pv,
        case
            when process='PWLFWM00' and commodity='PRCN2OP' then 'landfill-unab-N2O' --Filter 411
            when process='PWLFWM00' and commodity='PRCCH4P' then 'landfill-unab-CH4' --Filter 412
            when process in ('PWLFWMM01','PWLFWMM02','PWLFWMM03','PWLFWMM04') then 'landfill-mit-CH4' --Filter 413
        end as proc_set
        ,commodity
        from vedastore
        where attribute in('VAR_FIn','VAR_FOut') and commodity in('PRCCH4P','PRCN2OP') --Filter 414
       ) a
where proc_set is not null
group by tablename, attribute, proc_set, commodity
order by tablename, attribute, proc_set, commodity
) TO '%~dp0landfillemiss.csv' delimiter ',' CSV HEADER;

/* *Land use and crop / livestock mitigation (MACC) measures* */
-- Gives  breakdown for "agr-GHG-land","agr-GHG-livestock-mitigation","agr-GHG-crop-mitigation","agr-GHG-afforestation","agr-GHG-energy" by table.
-- This is GHG emissions and so some measures are not included here (biomass / h2 boilers, reduced cultivation, elc/heat energy efficiency options) as they don't produce GHG

COPY ( 
select 'ag-lulucf-meas-ghg_'|| proc_set || '|' || tablename || '|' || attribute || '|' || 'various' || '|various'::varchar(300) "id",
    'ag-lulucf-meas-ghg_' || proc_set "analysis", tablename, attribute,
    'various'::varchar(50) "commodity",'various'::varchar "process",
    sum(pv) "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
    from (
        select tablename, attribute, period,pv,
        case
            when process in ('ALUFOR01','ALUFOR02','ALUFOR03','ALUFOR04A','ALUFOR04B') then 'affor'  --Filter 210
            when process in ('AGCRP01','AGCRP02','AGCRP04','AGCRP05','AGCRP06','AGCRP07','AGCRP08','AGCRP09') then 'crops' --Filter 211
            when process in ('AHTBLRC00','AHTBLRG00','AHTBLRG01','AHTBLRO00','AHTBLRO01','ATRA00','ATRA01','AATRA01') then 'agr-en' --Filter 212
            when process in ('AGSOI01','AGSOI02','AGSOI03','AGSOI04') then 'soils' --Filter 417
            when process in ('ALU00') then 'lulucf' --Filter 213
            when process in ('AGLIV03','AGLIV04','AGLIV05','AGLIV06','AGLIV07','AGLIV09') then 'livestock' --Filter 214
            when process in('AGRCUL00','MINBSLURRY1') then 'bau-livestock' --Filter 416
        end as proc_set
        from vedastore
        where attribute='VAR_FOut' and commodity in ('GHG-LULUCF','GHG-AGR-NO-LULUCF') --Filter 1
       ) a
where proc_set is not null
group by tablename, attribute, proc_set
order by tablename, attribute, proc_set
) TO '%~dp0lulucfout.csv' delimiter ',' CSV;

/* *Afforestation rate* */
-- This is the amount of afforestation over the BAU level (in current model formulation)
-- Note that only ALUFOR04A "creates" ALAND

COPY ( 
select 'ag-lulucf-meas_aff_level' || '|' || tablename || '|' || attribute || '|' || commodity || '|' || process::varchar(300) "id",
    'ag-lulucf-meas_aff_level'::varchar(50) "analysis",
    tablename, attribute,
    commodity,process,
    sum(pv) "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from vedastore
where attribute='VAR_FOut' and commodity='ALAND' and process in('ALUFOR01','ALUFOR02','ALUFOR03','ALUFOR04A') --Filter 2
group by tablename, attribute,commodity,process
) TO '%~dp0afforestout.csv' delimiter ',' CSV;
/* **End of For agriculture / LULUCF BAT (AgBatchUpload.bat): ** */

/* **Transport BAT (TraBatchUpload.bat): ** */
/* -------------------------------------*/

/* *Whole stock vehicle kms, emissions and emission intensity for 29 vehicle types* */
-- Includes estimates of CNG-in by vehicle types and associated emissions- This requires apportioning
-- emissions from the process converting mains gas to CNG (=different process for lgv/hgv/car vs bus) according to CNG input
-- In the model there seem to be cases where there is no CNG used by any of the vehicles (lgv,hgv,car or bus) and no CNG is created
-- but there are still emissions from the process which turns mains gas into CNG-

-- NB following codes for 'cars_h2+hybrid' doesn't seem to exist in the online acronym list:
    -- TCHBHYL01
-- This code exists in the acronym list but not in the test dataset:
    -- TCHBE8501    New hybrid flexible-fuel car (for E85) (seems not to be read in according to the XL model def sheet)
-- Uses the postgres 9-4+ "specific filter(where---" construction so won't work with other DBs

copy(
with base_cng_emissions as(
    select tablename, period,'cars-emis_lpg-and-cng-fueled'::varchar(50) "analysis",
        'VAR_FOut'::varchar(50) "attribute",
        'GHG-TRA-NON-ETS-NO-AS'::varchar(50) "commodity",
        0::numeric "pv"
    from vedastore group by tablename, period
    union
    select tablename, period,'hgv-emis_lpg-and-cng-fueled'::varchar(50) "analysis",
        'VAR_FOut'::varchar(50) "attribute",
        'GHG-TRA-NON-ETS-NO-AS'::varchar(50) "commodity",
        0::numeric "pv"
    from vedastore group by tablename, period
    union
    select tablename, period,'lgv-emis_lpg-and-cng-fueled'::varchar(50) "analysis",
        'VAR_FOut'::varchar(50) "attribute",
        'GHG-TRA-NON-ETS-NO-AS'::varchar(50) "commodity",
        0::numeric "pv"
    from vedastore group by tablename, period
)
, cng_emis_shares as(
    select tablename,period,
        sum(case when proc_set='cars-cng-in' then pv else 0 end) "cars-cng-in",
        sum(case when proc_set='lgv-cng-in' then pv else 0 end) "lgv-cng-in",
        sum(case when proc_set='hgv-cng-in' then pv else 0 end) "hgv-cng-in",
        sum(case when proc_set in('cars-cng-in','lgv-cng-in','hgv-cng-in') then pv else 0 end) "total_cng_in",
        sum(case when proc_set='cng-conv-emis' then pv else 0 end) "cng-conv-emis"
    from (
        select
            tablename,process,period,pv,
        case
            when process = 'TFSSCNG01' and attribute ='VAR_FOut' and commodity in('GHG-TRA-NON-ETS-NO-AS') then 'cng-conv-emis' --Filter 18
            when attribute = 'VAR_FIn' and commodity in('TRACNGS','TRACNGL') then
                case
                    when process like 'TC%' then 'cars-cng-in' --Filter 4
                    when process like 'TL%' then 'lgv-cng-in' --Filter 5
                    when process like 'TH%' then 'hgv-cng-in' --Filter 6
                end
        end as "proc_set"
        from vedastore
        where (attribute = 'VAR_FIn' or attribute ='VAR_FOut') and commodity in('TRACNGS','TRACNGL','GHG-AGR-NO-LULUCF',
            'GHG-ELC','GHG-ELC-CAPTURED','GHG-ETS-NET',
            'GHG-ETS-NO-IAS-NET','GHG-ETS-NO-IAS-TER','GHG-ETS-TER','GHG-ETS-YES-IAS-NET',
            'GHG-ETS-YES-IAS-TER','GHG-IAS-ETS','GHG-IAS-NON-ETS','GHG-IND-ETS',
            'GHG-IND-ETS-CAPTURED','GHG-IND-NON-ETS','GHG-IND-NON-ETS-CAPTURED','GHG-LULUCF',
            'GHG-NO-IAS-NO-LULUCF-NET','GHG-NO-IAS-NO-LULUCF-TER',
            'GHG-NO-IAS-YES-LULUCF-NET','GHG-NO-IAS-YES-LULUCF-TER',
            'GHG-NON-ETS-NO-LULUCF-NET','GHG-NON-ETS-NO-LULUCF-TER',
            'GHG-NON-ETS-YES-LULUCF-NET','GHG-NON-ETS-YES-LULUCF-TER','GHG-OTHER-ETS',
            'GHG-OTHER-ETS-CAPTURED','GHG-OTHER-NON-ETS','GHG-RES-ETS','GHG-RES-NON-ETS',
            'GHG-SER-ETS','GHG-SER-NON-ETS','GHG-TRA-NON-ETS-NO-AS',
            'GHG-YES-IAS-NO-LULUCF-NET','GHG-YES-IAS-NO-LULUCF-TER',
            'GHG-YES-IAS-YES-LULUCF-NET','GHG-YES-IAS-YES-LULUCF-TER') and
            (process = 'TFSSCNG01' or process like any(array['TC%','TL%','TH%','TB%'])) --Filter 7
            order by process
    ) a
    where proc_set <>''
    group by tablename,period
)
, main_crosstab as(
    select analysis::varchar(50), tablename,attribute,commodity,period,sum(pv) "pv"
    from (
        select a.tablename, a.analysis, a.period,a.attribute,a.commodity,
        case
            when analysis='cars-emis_lpg-and-cng-fueled' then
                case when "total_cng_in" > 0 then "cars-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end
            when analysis='lgv-emis_lpg-and-cng-fueled' then
                case when "total_cng_in" > 0 then "lgv-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end
            when analysis='hgv-emis_lpg-and-cng-fueled' then
                case when "total_cng_in" > 0 then "hgv-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end
            else pv
         end "pv"
        from (
            select tablename, period, analysis, attribute, commodity,sum(pv) "pv"
            from (
                    select tablename, process, period,pv,attribute,commodity,
                    case
                        when process like 'TC%' then 'cars-'
                        when process like 'TL%' then 'lgv-'
                        when process like 'TH%' then 'hgv-'
                        when process like 'TB%' or process='TFSLCNG01' then 'bus-'
                        when process like 'TW%' then 'bike-'
                    end ||
                    case
                        when commodity in('TC','TL','TH1','TH2','TH3','TB','TW') then 'km_'
                        when commodity in('GHG-TRA-NON-ETS-NO-AS') then 'emis_'
                    end ||
                    case
                        when process in('TBDST00','TBDST01','TCDST00','TCDST01','TH1DST00','TH2DST00','TH3DST00','TH1DST01',
                            'TH2DST01','TH3DST01','TLDST00','TLDST01') then 'diesel' --Filter 8
                        when process in('TCE8501','TLE8501') then 'E85' --Filter 9
                        when process in('TBELC01','TCELC01','TLELC01','TH3ELC01','TWELC01') then 'electric' --Filter 10
                        when process in('TBFCHBHYG01','TCFCHBHYG01','TCFCHYG01','TCHBE8501','TCHBHYL01','TH1FCHBHYG01',
                            'TH2FCHBHYG01','TH3FCHBHYG01','TLFCHBHYG01','TLFCHYG01','TLHBHYL01','TWFCHYG01') then 'h2+hybrid' --Filter 11
                        when process in('TCFCPHBHYG01') then 'h2-plug-in-hybrid' --Filter 12
                        when process in('TBHBDST01','TCHBDST01','TCHBPET00','TCHBPET01','TH1HBDST01','TH2HBDST01',
                            'TH3HBDST01','TLHBDST01','TLHBPET01') then 'hybrid' --Filter 13
                        when process in('TBCNG01','TCCNG01','TCLPG00','TCLPG01','TH1CNG01','TH2CNG01',
                            'TH3CNG01','TLCNG01','TLLPG01','TFSLCNG01') then 'lpg-and-cng-fueled' --Filter 14
                        -- NB Includes the bus mains gas => CNG conversion process 'TFSLCNG01'. This is because emissions are counted at this point here but the demand is counted at "TBCNG01"
                        when process in('TCPET00','TCPET01','TLPET00','TLPET01','TWPET00','TWPET01') then 'petrol' --Filter 15
                        when process in('TCPHBDST01','TCPHBPET01','TLPHBDST01','TLPHBPET01') then 'plug-in-hybrid' --Filter 16
                        when process in('TH2CNGDST01','TH3CNGDST01') then 'Dual fuel diesel-CNG' --Filter 221
                    end as "analysis"
                    from vedastore
                    where attribute = 'VAR_FOut' and commodity in('GHG-TRA-NON-ETS-NO-AS','TB','TC','TH1','TH2','TH3','TL','TW')
                        and (process like any(array['TC%','TL%','TB%','TW%']) or process ~'^TH[^Y]' or process='TFSLCNG01')  --Filter 17
                    ) a
            where analysis <>''
            group by tablename, period, analysis, attribute, commodity
            union
            select * from base_cng_emissions
           ) a
        left join cng_emis_shares b on a.tablename=b.tablename and a.period=b.period
        ) b
    group by analysis, tablename,attribute,commodity,period
    order by tablename, analysis
)
select analysis || '|' || tablename || '|' || attribute || '|' || commodity || '|various'::varchar(300) "id", analysis::varchar(50), tablename,attribute,
    commodity,
    'various'::varchar(50) "process",
    case when analysis like '%-inten%' then avg(pv)::numeric else sum(pv)::numeric end "all",
    -- I.e is the average emission intensity of each year for the emission intensity rather than the sum- This is _not_ (sum emissions) / (sum kms)
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
-- NB This following uses a postgres 9-4 specific syntax ( filter(where--- ) and won't work with earlier vers
    select a.* from main_crosstab a
    where period<>'-'
    union
    select left(analysis, position('_' in analysis)) ||'all' "analysis", tablename, 'VAR_FOut' "attribute", commodity, period,sum(pv) "pv" from main_crosstab
    where period<>'-'
    group by left(analysis, position('_' in analysis)), tablename,commodity,period
    union
    select left(analysis, position('-' in analysis))||'emis-inten_all' "analysis", tablename, 'VAR_FOut' "attribute", '-' "commodity", period,
        sum(pv) filter(where analysis like '%-emis%')/sum(pv) filter(where analysis like '%-km%') "pv"
    from main_crosstab
    where period<>'-' and period<>'2200'
    group by left(analysis, position('-' in analysis)), tablename,period
    order by tablename, period, analysis
) a
group by analysis, tablename,attribute,commodity
order by tablename, analysis
) TO '%~dp0vehKms.csv' delimiter ',' CSV HEADER;

/* *New stock vehicle kms, emissions and emission intensity for 29 vehicle types* */
-- This script only includes new vehicles in the year of introduction- Apportions emissions from conversion of mains gas to CNG according to CNG-in for each vehicle type
-- Uses the postgres 9-4+ "specific filter(where---" construction so won't work with other DBs

COPY (
with base_cng_emissions as(
    select tablename, period,'cars-new-emis_lpg-and-cng-fueled'::varchar "analysis",
        'VAR_FOut'::varchar "atttribute", 'GHG-TRA-NON-ETS-NO-AS'::varchar "commodity",
        0::numeric "pv"
    from vedastore group by tablename, period
    union
    select tablename, period,'hgv-new-emis_lpg-and-cng-fueled'::varchar "analysis",
        'VAR_FOut'::varchar "atttribute", 'GHG-TRA-NON-ETS-NO-AS'::varchar "commodity",
        0::numeric "pv"
    from vedastore group by tablename, period
    union
    select tablename, period,'lgv-new-emis_lpg-and-cng-fueled'::varchar "analysis",
        'VAR_FOut'::varchar "atttribute", 'GHG-TRA-NON-ETS-NO-AS'::varchar "commodity",
        0::numeric "pv"
    from vedastore group by tablename, period
    union
    select tablename, period,'bus-new-emis_lpg-and-cng-fueled'::varchar "analysis",
        'VAR_FOut'::varchar "atttribute", 'GHG-TRA-NON-ETS-NO-AS'::varchar "commodity",
        0::numeric "pv"
   from vedastore group by tablename, period
)
, cng_emis_shares as(
    select tablename,period,
        sum(case when proc_set='cars-new-cng-in' then pv else 0 end) "cars-new-cng-in",
        sum(case when proc_set='lgv-new-cng-in' then pv else 0 end) "lgv-new-cng-in",
        sum(case when proc_set='hgv-new-cng-in' then pv else 0 end) "hgv-new-cng-in",
        sum(case when proc_set in('cars-new-cng-in','lgv-new-cng-in','hgv-new-cng-in','older-veh-cng-in') then pv else 0 end) "total_cng_in",
        sum(case when proc_set='cng-conv-emis' then pv else 0 end) "cng-conv-emis",
        sum(case when proc_set='bus-new-cng-in' then pv else 0 end) "bus-new-cng-in",
        sum(case when proc_set in('bus-new-cng-in','older-bus-cng-in') then pv else 0 end) "total_bus_cng_in",
        sum(case when proc_set='bus-cng-conv-emis' then pv else 0 end) "bus-cng-conv-emis"
    from (
        select tablename,process,period,pv,
        case
            when process = 'TFSSCNG01' and attribute ='VAR_FOut' and
                commodity in('GHG-TRA-NON-ETS-NO-AS') then 'cng-conv-emis' --Filter 18
            when process = 'TFSLCNG01' and attribute ='VAR_FOut' and commodity='GHG-TRA-NON-ETS-NO-AS' then 'bus-cng-conv-emis' --Filter 19
            when attribute = 'VAR_FIn' and commodity in('TRACNGS','TRACNGL') then
                case
                    when process like 'TC%' and vintage=period then 'cars-new-cng-in' --Filter 20
                    when process like 'TL%' and vintage=period then 'lgv-new-cng-in' --Filter 21
                    when process like 'TH%' and vintage=period then 'hgv-new-cng-in' --Filter 22
                    when process like any(array['TC%','TL%','TH%']) and vintage<>period then 'older-veh-cng-in' --Filter 23
                    when process like 'TB%' and vintage=period then 'bus-new-cng-in' --Filter 24
                    when process like 'TB%' and vintage<>period then 'older-bus-cng-in' --Filter 25
                end
        end as "proc_set"
        from vedastore
        order by process
    ) a
    where proc_set <>''
    group by tablename,period
)
, main_crosstab as(
    select analysis, tablename,attribute,commodity,period,sum(pv) "pv" from (
       select a.tablename, a.analysis, a.period,a.attribute,a.commodity,
        case
            when analysis='cars-new-emis_lpg-and-cng-fueled' then
                case when "total_cng_in" > 0 then "cars-new-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end
            when analysis='lgv-new-emis_lpg-and-cng-fueled' then
                case when "total_cng_in" > 0 then "lgv-new-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end
            when analysis='hgv-new-emis_lpg-and-cng-fueled' then
                case when "total_cng_in" > 0 then "hgv-new-cng-in"/"total_cng_in"*"cng-conv-emis" + pv else pv end
            when analysis='bus-new-emis_lpg-and-cng-fueled' then
                case when "total_bus_cng_in" > 0 then "bus-new-cng-in"/"total_bus_cng_in"*"bus-cng-conv-emis" + pv else pv end
            else pv
         end "pv"
        from (
            select tablename, period, analysis, attribute, commodity,sum(pv) "pv"
            from (
                    select tablename, process, period,pv,attribute,commodity,
                    case
                        when process like 'TC%' then 'cars-new-'
                        when process like 'TL%' then 'lgv-new-'
                        when process like 'TH%' then 'hgv-new-'
                        when process like 'TB%' then 'bus-new-'
                        when process like 'TW%' then 'bike-new-'
                    end ||
                    case
                        when commodity in('TC','TL','TH1','TH2','TH3','TB','TW') then 'km_'
                        when commodity in('GHG-TRA-NON-ETS-NO-AS') then 'emis_'
                    end ||
                    case
                        when process in('TBDST00','TBDST01','TCDST00','TCDST01','TH1DST00','TH2DST00','TH3DST00','TH1DST01','TH2DST01',
                            'TH3DST01','TLDST00','TLDST01') then 'diesel' --Filter 8
                        when process in('TCE8501','TLE8501') then 'E85' --Filter 9
                        when process in('TBELC01','TCELC01','TLELC01','TH3ELC01','TWELC01') then 'electric' --Filter 10
                        when process in('TBFCHBHYG01','TCFCHBHYG01','TCFCHYG01','TCHBE8501','TCHBHYL01','TH1FCHBHYG01','TH2FCHBHYG01',
                            'TH3FCHBHYG01','TLFCHBHYG01','TLFCHYG01','TLHBHYL01','TWFCHYG01') then 'h2+hybrid' --Filter 11
                        when process in('TCFCPHBHYG01') then 'h2-plug-in-hybrid' --Filter 12
                        when process in('TBHBDST01','TCHBDST01','TCHBPET00','TCHBPET01','TH1HBDST01','TH2HBDST01',
                            'TH3HBDST01','TLHBDST01','TLHBPET01') then 'hybrid'  --Filter 13
                        when process in('TBCNG01','TCCNG01','TCLPG00','TCLPG01','TH1CNG01','TH2CNG01',
                            'TH3CNG01','TLCNG01','TLLPG01') then 'lpg-and-cng-fueled' --Filter 220
                        when process in('TCPET00','TCPET01','TLPET00','TLPET01','TWPET00','TWPET01') then 'petrol' --Filter 15
                        when process in('TCPHBDST01','TCPHBPET01','TLPHBDST01','TLPHBPET01') then 'plug-in-hybrid' --Filter 16
                        when process in('TH2CNGDST01','TH3CNGDST01') then 'Dual fuel diesel-CNG' --Filter 221
                    end as "analysis"
                    from vedastore
                    where attribute = 'VAR_FOut' and commodity in('TC','TL','TH1','TH2','TH3','TW','TB','GHG-TRA-NON-ETS-NO-AS')
                        and (process like any(array['TC%','TL%','TB%','TW%']) or process ~'^TH[^Y]') and vintage=period and process like '%01' --Filter 35
                    ) a
                where analysis <>''
                group by tablename, period, analysis, attribute, commodity
                union
                select * from base_cng_emissions
           ) a
        left join cng_emis_shares b on a.tablename=b.tablename and a.period=b.period
    ) b
    group by analysis, tablename,attribute,commodity,period
    order by tablename, analysis
)
select analysis || '|' || tablename || '|' || attribute || '|' || commodity || '|various'::varchar(300) "id", analysis::varchar(50), tablename,attribute,
    commodity,
    'various'::varchar(50) "process",
    case when analysis like '%-inten%' then avg(pv)::numeric else sum(pv)::numeric end "all",
    -- I.e is the average emission intensity of each year for the emission intensity rather than the sum- This is _not_ (sum emissions) / (sum kms)
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
-- NB This following uses a postgres 9-4 specific syntax ( filter(where... ) and won't work with earlier vers
    select a.* from main_crosstab a
    where period<>'-'
    union
    select left(analysis, position('_' in analysis)) ||'all' "analysis", tablename, 'VAR_FOut' "attribute", commodity, period,sum(pv) "pv" from main_crosstab
    where period<>'-'
    group by left(analysis, position('_' in analysis)), tablename,commodity,period
    union
    select left(analysis, position('-' in analysis))||'new-emis-inten_all' "analysis", tablename, 'VAR_FOut' "attribute", '-' "commodity", period,
        sum(pv) filter(where analysis like '%-emis%')/sum(pv) filter(where analysis like '%-km%') "pv"
    from main_crosstab
    where period<>'-' and period<>'2200'
    group by left(analysis, position('-' in analysis)), tablename,period
    order by tablename, period, analysis
) a
group by analysis, tablename,attribute,commodity
order by tablename, analysis
 ) TO '%~dp0newVehKms.csv' delimiter ',' CSV;

/* *Whole stock capacity for vehicles for 29 vehicle types* */

COPY (
select analysis || '|' || tablename || '|' || attribute || '|' || commodity || '|various'::varchar(300) "id", analysis, tablename,attribute,
    commodity,
    'various'::varchar(50) "process",
    sum(pv)::numeric "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
    select process,period,pv,
    case
        when process like 'TC%' then 'cars-cap_'
        when process like 'TL%' then 'lgv-cap_'
        when process like 'TH%' then 'hgv-cap_'
        when process like 'TB%' then 'bus-cap_'
        when process like 'TW%' then 'bike-cap_'
    end ||
    case
        when process in('TBDST00','TBDST01','TCDST00','TCDST01','TH1DST00','TH2DST00','TH3DST00','TH1DST01',
            'TH2DST01','TH3DST01','TLDST00','TLDST01') then 'diesel' --Filter 8
        when process in('TCE8501','TLE8501') then 'E85' --Filter 9
        when process in('TBELC01','TCELC01','TLELC01','TH3ELC01','TWELC01') then 'electric' --Filter 10
        when process in('TBFCHBHYG01','TCFCHBHYG01','TCFCHYG01','TCHBE8501','TCHBHYL01','TH1FCHBHYG01',
            'TH2FCHBHYG01','TH3FCHBHYG01','TLFCHBHYG01','TLFCHYG01','TLHBHYL01','TWFCHYG01') then 'h2+hybrid' --Filter 11
        when process in('TCFCPHBHYG01') then 'h2-plug-in-hybrid' --Filter 12
        when process in('TBHBDST01','TCHBDST01','TCHBPET00','TCHBPET01','TH1HBDST01','TH2HBDST01',
            'TH3HBDST01','TLHBDST01','TLHBPET01') then 'hybrid'  --Filter 13
        when process in('TBCNG01','TCCNG01','TCLPG00','TCLPG01','TH1CNG01','TH2CNG01','TH3CNG01',
            'TLCNG01','TLLPG01') then 'lpg-and-cng-fueled' --Filter 220
        when process in('TCPET00','TCPET01','TLPET00','TLPET01','TWPET00','TWPET01') then 'petrol' --Filter 15
        when process in('TCPHBDST01','TCPHBPET01','TLPHBDST01','TLPHBPET01') then 'plug-in-hybrid' --Filter 16
        when process in('TH2CNGDST01','TH3CNGDST01') then 'Dual fuel diesel-CNG' --Filter 221
    end as "analysis",
    tablename, attribute,commodity
    from vedastore
    where attribute = 'VAR_Cap' and process like any(array['TC%','TL%','TH%','TB%','TW%']) --Filter 45
) a
where analysis <>''
group by id, analysis,tablename, attribute, commodity
order by tablename,  analysis, attribute, commodity
 ) TO '%~dp0VehCapOut.csv' delimiter ',' CSV;

/* *New build capacity for vehicles for 29 vehicle types* */
-- NB are no commodities associated with new build, only processes - commodity='-'

COPY (
select analysis || '|' || tablename || '|' || attribute || '|' || commodity || '|various'::varchar(300) "id", analysis::varchar(50), tablename,attribute,
    commodity,
    'various'::varchar(50) "process",
    sum(pv)::numeric "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
    select process,period,pv,
    case
        when process like 'TC%' then 'cars-new-cap_'
        when process like 'TL%' then 'lgv-new-cap_'
        when process like 'TH%' then 'hgv-new-cap_'
        when process like 'TB%' then 'bus-new-cap_'
        when process like 'TW%' then 'bike-new-cap_'
    end ||
    case
        when process in('TBDST00','TBDST01','TCDST00','TCDST01','TH1DST00','TH2DST00','TH3DST00','TH1DST01',
            'TH2DST01','TH3DST01','TLDST00','TLDST01') then 'diesel' --Filter 8
        when process in('TCE8501','TLE8501') then 'E85' --Filter 9
        when process in('TBELC01','TCELC01','TLELC01','TH3ELC01','TWELC01') then 'electric' --Filter 10
        when process in('TBFCHBHYG01','TCFCHBHYG01','TCFCHYG01','TCHBE8501','TCHBHYL01','TH1FCHBHYG01',
            'TH2FCHBHYG01','TH3FCHBHYG01','TLFCHBHYG01','TLFCHYG01','TLHBHYL01','TWFCHYG01') then 'h2+hybrid' --Filter 11
        when process in('TCFCPHBHYG01') then 'h2-plug-in-hybrid' --Filter 12
        when process in('TBHBDST01','TCHBDST01','TCHBPET00','TCHBPET01','TH1HBDST01','TH2HBDST01',
            'TH3HBDST01','TLHBDST01','TLHBPET01') then 'hybrid' --Filter 13
        when process in('TBCNG01','TCCNG01','TCLPG00','TCLPG01','TH1CNG01','TH2CNG01','TH3CNG01',
            'TLCNG01','TLLPG01') then 'lpg-and-cng-fueled' --Filter 220
        when process in('TCPET00','TCPET01','TLPET00','TLPET01','TWPET00','TWPET01') then 'petrol' --Filter 15
        when process in('TCPHBDST01','TCPHBPET01','TLPHBDST01','TLPHBPET01') then 'plug-in-hybrid' --Filter 16
        when process in('TH2CNGDST01','TH3CNGDST01') then 'Dual fuel diesel-CNG' --Filter 221
    end as "analysis",
    tablename, attribute,commodity
    from vedastore
    where attribute = 'VAR_Ncap' and process like any(array['TC%','TL%','TH%','TB%','TW%']) --Filter 55
) a
where analysis <>''
group by id, analysis,tablename, attribute, commodity
order by tablename,  analysis, attribute, commodity
 ) TO '%~dp0newVehCapOut.csv' delimiter ',' CSV;
 
/* *TRA_Fuel_by_mode* */
-- A version of the above Veda table with just international shipping and aviation
-- Added as a temporary measure to be able to remove international shipping / aviation from the main final energy and primary energy queries

COPY (
with fuels_in as (
-- Add this sub-query for compatibility with the other instances of these fuel filters / processes. Not strictly needed...
-- These fuels are only those which are used or have been used for these modes (not all fuels)
    select process,period,pv,
    case 
        when process in('TAIJETE00','TAIJETE01','TAIJETN00','TAIJETN01','TAIJET02','TAIHYLE01','TAIHYLN01') then 'TRA-AVI-INT' --Filter 386
        --last 3 of these might not be real processes
        when process in('TSIHYG01','TSIOIL00','TSIOIL01') then 'TRA-SHIP-INT' --Filter 364
    end as proc,
    case
        when commodity in('AGRBIODST','AGRBIOLPG','AGRBOM','AGRGRASS','AGRMAINSBOM','AGRPOLWST','BGRASS','BIODST','BIODST-FT','BIOJET-FT','BIOKER-FT','BIOLFO'
            ,'BIOLPG','BIOOIL','BOG-AD','BOG-G','BOG-LF','BOM','BPELH','BPELL','BRSEED','BSEWSLG','BSLURRY','BSTARCH'
            ,'BSTWWST','BSUGAR','BTREATSTW','BTREATWOD','BVOIL','BWOD','BWODLOG','BWODWST','ELCBIOCOA','ELCBIOCOA2','ELCBIOLFO','ELCBIOOIL'
            ,'ELCBOG-AD','ELCBOG-LF','ELCBOG-SW','ELCBOM','ELCMAINSBOM','ELCMSWINO','ELCMSWORG','ELCPELH','ELCPELL','ELCPOLWST','ELCSTWWST','ELCTRANSBOM'
            ,'ETH','HYGBIOO','HYGBPEL','HYGMSWINO','HYGMSWORG','INDBIOLFO','INDBIOLPG','INDBIOOIL','INDBOG-AD','INDBOG-LF','INDBOM','INDGRASS'
            ,'INDMAINSBOM','INDMSWINO','INDMSWORG','INDPELH','INDPELL','INDPOLWST','INDWOD','INDWODWST','METH','MSWBIO','MSWINO','MSWORG'
            ,'PWASTEDUM','RESBIOLFO','RESBOM','RESHOUSEBOM','RESMSWINO','RESMSWORG','RESMAINSBOM','RESPELH','RESWOD','RESWODL','SERBIOLFO','SERBOG','SERBOM','SERBUILDBOM'
            ,'SERMAINSBOM','SERMSWBIO','SERMSWINO','SERMSWORG','SERPELH','SERWOD','TRABIODST','TRABIODST-FT','TRABIODST-FTL','TRABIODST-FTS','TRABIODSTL','TRABIODSTS'
            ,'TRABIOJET-FTDA','TRABIOJET-FTDAL','TRABIOJET-FTIA','TRABIOJET-FTIAL','TRABIOLFO','TRABIOLFODS','TRABIOLFODSL','TRABIOLFOL','TRABIOOILIS','TRABIOOILISL','TRABOM','TRAETH'
            ,'TRAETHL','TRAETHS','TRAMAINSBOM','TRAMETH') then 'ALL BIO' --Filter 287
        when commodity in('AGRDISTELC','AGRELC','ELC','ELC-E-EU','ELC-E-IRE','ELC-I-EU','ELC-I-IRE','ELCGEN','ELCSURPLUS','HYGELC','HYGELCSURP','HYGLELC'
            ,'HYGSELC','INDDISTELC','INDELC','PRCELC','RESDISTELC','RESELC','RESELCSURPLUS','RESHOUSEELC','SERBUILDELC','SERDISTELC','SERELC','TRACELC'
            ,'TRACPHB','TRADISTELC','TRAELC','UPSELC') then 'ALL ELECTRICITY' --Filter 235
        when commodity in('AGRNGA','ELCNGA','HYGLNGA','HYGSNGA','IISNGAB','IISNGAC','IISNGAE','INDNEUNGA','INDNGA','LNG','NGA','NGA-E'
            ,'NGA-E-EU','NGA-E-IRE','NGA-I-EU','NGA-I-N','NGAPTR','PRCNGA','RESNGA','SERNGA','TRACNGL','TRACNGS','TRALNG','TRALNGDS'
            ,'TRALNGDSL','TRALNGIS','TRALNGISL','TRANGA','UPSNGA') then 'ALL GAS' --Filter 354
        when commodity in('AGRCOA','COA','COACOK','COA-E','ELCCOA','HYGCOA','INDCOA','INDCOACOK','INDSYNCOA','PRCCOA','PRCCOACOK','RESCOA'
            ,'SERCOA','SYNCOA','TRACOA') then 'ALL COALS' --Filter 246
        when commodity in('SERHFO','SERLFO','TRAPETL','OILLFO','TRAJETDA','TRALFO','TRALPGS','ELCMSC','INDLFO','AGRHFO','TRAHFOIS','TRADSTS'
            ,'SERKER','TRAJETIANL','RESLFO','RESLPG','TRAHFODSL','TRALFOL','TRAJETIA','TRAJETL','TRAPETS','TRAHFODS','OILJET','OILDST'
            ,'AGRLPG','OILCRDRAW-E','UPSLFO','ELCLFO','INDNEULFO','ELCHFO','TRAJETDAEL','SYNOIL','TRADSTL','INDLPG','OILMSC','OILPET'
            ,'PRCHFO','OILCRDRAW','TRALFODSL','INDNEULPG','ELCLPG','TRADST','TRALFODS','OILKER','OILHFO','OILCRD','TRALPGL','SERLPG'
            ,'INDNEUMSC','PRCOILCRD','INDKER','INDHFO','OILLPG','TRALPG','RESKER','TRAJETIAEL','TRAHFOISL','IISHFOB','TRAPET','INDSYNOIL'
            ,'TRAHFO','AGRLFO') then 'ALL OIL PRODUCTS' --Filter 302
        when commodity in('AGRHYG','ELCHYG','ELCHYGIGCC','HYGL','HYGL-IGCC','HYGLHPD','HYGLHPT','HYL','HYLTK','INDHYG','INDMAINSHYG','RESHOUSEHYG'
            ,'RESHYG','RESHYGREF-EA','RESHYGREF-NA','RESMAINSHYG','SERBUILDHYG','SERHYG','SERMAINSHYG','TRAHYG','TRAHYGDCN','TRAHYGL','TRAHYGS','TRAHYL'
            ,'UPSHYG','UPSMAINSHYG') then 'ALL HYDROGEN' --Filter 371
        when commodity in('WNDONS','GEO','ELCWAV','RESSOL','HYDROR','ELCTID','SERSOL','HYDDAM','TID','ELCSOL','WNDOFF','WAV'
        ,'SOL','ELCWNDOFS','ELCGEO','ELCWNDONS','ELCHYDDAM','SERGEO') then 'ALL OTHER RNW' --Filter 226
    end as "analysis",
    tablename, attribute
    from vedastore
    where attribute = 'VAR_FIn'
)
select analysis || '|' || tablename || '|' || attribute || '|' || 'various' || '|various'::varchar(300) "id", analysis::varchar(50), tablename,'VAR_FIn' "attribute",
    'various'::varchar(50) "commodity",
    'various'::varchar(50) "process",
    sum(pv)::numeric "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
    select process,period,pv,
    case
        when proc='TRA-AVI-INT' then 'int-air-fuel_'
        when proc='TRA-SHIP-INT' then 'int-ship-fuel_'
    end 
     ||
    case
        when analysis='ALL BIO' then 'bio'
        when analysis='ALL ELECTRICITY' then 'elc'
        when analysis='ALL GAS' then 'gas'
        when analysis='ALL COALS' then 'coa'
        when analysis='ALL OIL PRODUCTS' then 'oil'
        when analysis='ALL HYDROGEN' then 'hyd'
        when analysis='ALL OTHER RNW' then 'orens'
    end as "analysis",
    tablename, attribute
    from fuels_in
    where analysis <>'' and proc <>''
) a
group by id, analysis,tablename
order by tablename, analysis
) TO '%~dp0fuelByModeOut.csv' delimiter ',' CSV;

/* *Road transport fuel by mode and fuel* */
-- Breakdown of input fuels by road transport modes

COPY (
select analysis || '|' || tablename || '|' || attribute || '|various' || '|various'::varchar(300) "id", analysis, tablename,attribute,
    'various'::varchar(50) "commodity",
    'various'::varchar(50) "process",
    sum(pv)::numeric "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
    select process,period,pv,
    case
        when process like 'TC%' then 'cars-fuel_'
        when process like 'TL%' then 'lgv-fuel_'
        when process like 'TH%' then 'hgv-fuel_'
        when process like 'TB%' then 'bus-fuel_'
        when process like 'TW%' then 'bike-fuel_'
    end ||
    case
        when commodity in('TRABIODST-FTL','TRABIODST-FTS') then 'sec-gen-biodiesel' --Filter 400
        when commodity in('TRABIODSTL','TRABIODSTS') then 'biodiesel' --Filter 401
        when commodity in('TRACNGL','TRACNGS') then 'cng' --Filter 402
        when commodity in('TRADSTL','TRADSTS') then 'diesel' --Filter 403
        when commodity in('TRACELC','TRACPHB') then 'elc' --Filter 404
        when commodity in('TRAETHS') then 'ethanol' --Filter 405
        when commodity in('TRAHYGL','TRAHYGS') then 'hydrogen' --Filter 406
        when commodity in('TRALPGS') then 'lpg' --Filter 407
        when commodity in('TRAPETS') then 'petrol' --Filter 408
    end as "analysis",
    tablename, attribute,commodity
    from vedastore
    where attribute = 'VAR_FIn' and process like any(array['TC%','TL%','TH%','TB%','TW%']) --Filter 45
) a
where analysis <>''
group by id, analysis,tablename, attribute
order by tablename,  analysis, attribute
) TO '%~dp0rdTransFuel.csv' delimiter ',' CSV;
/* **End of Transport BAT (TraBatchUpload.bat): ** */

/* **Main "key outputs" BAT (MainBatchUpload.bat)** */
/* ------------------------------------------------*/
/* *Dummy imports by table* */
-- NB this only sums Cost_Act to see impact on the objective function- Filter was previously:
-- "where process like 'IMP%Z'" [not clear how these processes are created
-- as are not defined explicitly as part of the model topology]

COPY (
select 'dummies' || '|' || tablename || '|' || 'Cost_Act' || '|' || 'various' || '|various'::varchar(300) "id",
    'dummies'::varchar(300) "analysis", tablename, 'Cost_Act'::varchar(50) "attribute",
    'various'::varchar(50) "commodity",
    'various'::varchar(50) "process",
    sum(pv)::numeric "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from vedastore
where process in('IMPDEMZ','IMPMATZ','IMPNRGZ') and attribute = 'Cost_Act' --Filter 56
group by tablename
order by tablename, analysis
 ) TO '%~dp0dummiesout.csv' delimiter ',' CSV HEADER;

/* *All GHG emissions* */
-- Was ghg; now ghg_all- These are DECC categories
COPY (
select 'ghg_all|' || tablename || '|Var_FOut|' || commodity || '|all'::varchar(300) "id",
        'ghg_all'::varchar(50) "analysis",
        tablename,
        'Var_FOut'::varchar(50) "attribute",
        commodity,
        'all'::varchar(50) "process",
        sum(pv)::numeric "all",
        sum(case when period='2010' then pv else 0 end)::numeric "2010",
        sum(case when period='2011' then pv else 0 end)::numeric "2011",
        sum(case when period='2012' then pv else 0 end)::numeric "2012",
        sum(case when period='2015' then pv else 0 end)::numeric "2015",
        sum(case when period='2020' then pv else 0 end)::numeric "2020",
        sum(case when period='2025' then pv else 0 end)::numeric "2025",
        sum(case when period='2030' then pv else 0 end)::numeric "2030",
        sum(case when period='2035' then pv else 0 end)::numeric "2035",
        sum(case when period='2040' then pv else 0 end)::numeric "2040",
        sum(case when period='2045' then pv else 0 end)::numeric "2045",
        sum(case when period='2050' then pv else 0 end)::numeric "2050",
        sum(case when period='2055' then pv else 0 end)::numeric "2055",
        sum(case when period='2060' then pv else 0 end)::numeric "2060"
from vedastore
where attribute='VAR_FOut' and commodity in('GHG-ETS-NO-IAS-NET','GHG-ETS-NO-IAS-TER','GHG-ETS-YES-IAS-NET','GHG-ETS-YES-IAS-TER',
    'GHG-NO-IAS-YES-LULUCF-NET','GHG-NO-IAS-YES-LULUCF-TER','GHG-NON-ETS-YES-LULUCF-NET','GHG-NON-ETS-YES-LULUCF-TER',
    'GHG-YES-IAS-YES-LULUCF-NET','GHG-YES-IAS-YES-LULUCF-TER','GHG-NO-AS-YES-LULUCF-NET') --Filter 57
group by tablename, commodity
order by tablename, commodity
 ) TO '%~dp0GHGOut.csv' delimiter ',' CSV;

/* *GHG emissions by sector* */
-- Energy-related process CO2 is reported separately- Non-energy process CO2, CH4, N20 etc are lumped- Separate line
-- for ETS traded emissions- Otherwise, broken down by commodities- Analysis field entries:
-- 'ghg_sec-main-secs'    main sector breakdown
-- 'ghg_sec-prc-ets'    energy-related CO2 process emissions from ETS
-- 'ghg_sec-prc-non-ets'    Other non-ETS (process-related) emissions like CH4,N2O
-- 'ghg_sec-traded-emis-ets'    traded ETS emissions

COPY (
select analysis || '|' || tablename || '|' || attribute || '|' || commodity || '|' || process::varchar(300) "id", analysis, tablename,attribute,
    commodity, process,
    sum(pv)::numeric "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
    select 'all'::varchar(50) "process", period,
        case
            when attribute='VAR_FIn' and commodity in('Traded-Emission-ETS','PRCCH4P') then -pv
            else pv
        end as pv,
        tablename,
        case
            when commodity in('Traded-Emission-ETS','PRCCO2P','PRCCH4P','PRCN2OP') then 'various'
            else attribute
        end as attribute,
        case
            when commodity in('PRCCO2P', 'PRCCH4N', 'PRCCH4P', 'PRCN2ON', 'PRCN2OP') then 'various'
            else commodity
        end as "commodity",
        case
            when commodity='Traded-Emission-ETS' then 'ghg_sec-traded-emis-ets' --Filter 58
            when commodity in('GHG-ELC','GHG-IND-ETS','GHG-RES-ETS','GHG-SER-ETS','GHG-OTHER-ETS','GHG-IAS-ETS',
                'GHG-IAS-NON-ETS','GHG-IND-NON-ETS','GHG-RES-NON-ETS','GHG-SER-NON-ETS','GHG-TRA-NON-ETS-NO-AS',
                'GHG-AGR-NO-LULUCF','GHG-OTHER-NON-ETS','GHG-LULUCF','GHG-HFC-NON-ETS','Traded-Emission-Non-ETS','GHG-ELC-CAPTURED','GHG-IND-ETS-CAPTURED',
                'GHG-IND-NON-ETS-CAPTURED','GHG-OTHER-ETS-CAPTURED','GHG-DAS-ETS','GHG-DAS-NON-ETS') then 'ghg_sec-main-secs' --Filter 59
            when commodity in('PRCCH4N','PRCN2ON') then 'ghg_sec-prc-non-waste-non-ets' --Filter 60
            when commodity in('PRCCO2P','PRCCH4P','PRCN2OP') then 'ghg_sec-prc-waste-non-ets' --Filter 3
            when commodity ='PRCCO2N' then 'ghg_sec-prc-ets'  --Filter 61
        end as "analysis"
    from vedastore
    where (attribute='VAR_FOut' and commodity in('GHG-ELC','GHG-IND-ETS','GHG-RES-ETS','GHG-SER-ETS','GHG-OTHER-ETS',
        'GHG-IAS-ETS','GHG-IAS-NON-ETS','Traded-Emission-ETS','GHG-IND-NON-ETS','GHG-RES-NON-ETS',
        'GHG-SER-NON-ETS','GHG-TRA-NON-ETS-NO-AS','GHG-AGR-NO-LULUCF','GHG-OTHER-NON-ETS','GHG-LULUCF','GHG-HFC-NON-ETS',
        'Traded-Emission-Non-ETS','GHG-ELC-CAPTURED','GHG-IND-ETS-CAPTURED','GHG-IND-NON-ETS-CAPTURED',
        'GHG-OTHER-ETS-CAPTURED','PRCCO2P','PRCCH4N','PRCCH4P','PRCN2ON','PRCN2OP',
        'PRCCO2N','GHG-DAS-ETS','GHG-DAS-NON-ETS')) or (attribute='VAR_FIn' and commodity in('Traded-Emission-ETS','PRCCH4P')) --Filter 62
    order by period
) a
where analysis <>''
group by id, analysis,tablename, attribute, commodity,process
order by tablename,  analysis, attribute, commodity
 ) TO '%~dp0GHGsectorOut.csv' delimiter ',' CSV;

/* *GHG and sequestered emissions by industry sub-sector* */
-- Includes non-energy use of CO2 (industrial is only non-energy use commodity there is)
COPY (
    select 'ghg_ind-subsec-'||sector || '|' || tablename || '|' || 'VAR_FOut' || '|' || 'various' || '|various'::varchar(300) "id",
        'ghg_ind-subsec-'||sector::varchar(300) "analysis", tablename, 'VAR_Fout'::varchar(50) "attribute",
        'various'::varchar(50) "commodity",
        'various'::varchar(50) "process",
        sum(pv)::numeric "all",
        sum(case when period='2010' then pv else 0 end)::numeric "2010",
        sum(case when period='2011' then pv else 0 end)::numeric "2011",
        sum(case when period='2012' then pv else 0 end)::numeric "2012",
        sum(case when period='2015' then pv else 0 end)::numeric "2015",
        sum(case when period='2020' then pv else 0 end)::numeric "2020",
        sum(case when period='2025' then pv else 0 end)::numeric "2025",
        sum(case when period='2030' then pv else 0 end)::numeric "2030",
        sum(case when period='2035' then pv else 0 end)::numeric "2035",
        sum(case when period='2040' then pv else 0 end)::numeric "2040",
        sum(case when period='2045' then pv else 0 end)::numeric "2045",
        sum(case when period='2050' then pv else 0 end)::numeric "2050",
        sum(case when period='2055' then pv else 0 end)::numeric "2055",
        sum(case when period='2060' then pv else 0 end)::numeric "2060"
    from(
        select tablename,
            case
                when left(process,3)='ICH' then 'ich' --Filter 63
                when left(process,3)='ICM' then 'icm' --Filter 64
                when left(process,3)='IFD' then 'ifd' --Filter 65
                when left(process,3)='IIS' then 'iis' --Filter 66
                when left(process,3)='INF' then 'inf' --Filter 67
                when left(process,3)='INM' then 'inm' --Filter 68
                when left(process,3)='IOI' or process like 'INDHFCOTH0%' then 'ioi'  --Filter 69
                when left(process,3)='IPP' then 'ipp'  --Filter 70
                when process='-' then 'other'
                else null
            end "sector",
            period, sum(case when commodity in('SKNINDCO2N','SKNINDCO2P') then -pv else pv end) "pv"
    -- These are sequestered emissions (emissions to CCS) so given negative emissions (-ve pv)
        from vedastore
        where commodity in ('SKNINDCO2N','SKNINDCO2P','INDCO2N','INDCO2P','INDNEUCO2N','INDCH4N','INDN2ON','INDHFCP') and attribute='VAR_FOut' --Filter 71
    -- NB In the Veda BE table the emissions for 'INDCH4N','INDN2ON','INDHFCP','INDNEUCO2N' are based on attribute in('EQ_Combal','VAR_Comnet')- This is nec- because
    -- some sectors (e.g. agr) or balance commodities (e.g. 'Traded-Emission-ETS') require the balance of VAR_FIn & VAR_FOut- This doesn't seem to be
    -- the case for industry where sum of VAR_FOut = balance- But might not always be the case---
    -- ---Specific case where you need a balance is where you have a BAU process which produces emissions and then a mitigation process which
    -- takes as input the same emissions and produces an output of reduced emissions- Here you need to subtract VAR_FIn from VAR_FOut
    -- Non-e- emissions are reported separately in UCL template
        group by tablename, sector,period
    ) a
    where sector is not null
    group by tablename, sector
union all
-- This bit is just the CCS part (sequestered emissions) by sub-sector
    select 'ghgseq_ind-subsec-'||sector || '|' || tablename || '|' || 'VAR_FOut' || '|' || 'various' || '|various'::varchar(300) "id",
        'ghgseq_ind-subsec-'||sector::varchar(300) "analysis", tablename, 'VAR_Fout'::varchar(50) "attribute",
        'various'::varchar(50) "commodity",
        'various'::varchar(50) "process",
        sum(pv)::numeric "all",
        sum(case when period='2010' then pv else 0 end)::numeric "2010",
        sum(case when period='2011' then pv else 0 end)::numeric "2011",
        sum(case when period='2012' then pv else 0 end)::numeric "2012",
        sum(case when period='2015' then pv else 0 end)::numeric "2015",
        sum(case when period='2020' then pv else 0 end)::numeric "2020",
        sum(case when period='2025' then pv else 0 end)::numeric "2025",
        sum(case when period='2030' then pv else 0 end)::numeric "2030",
        sum(case when period='2035' then pv else 0 end)::numeric "2035",
        sum(case when period='2040' then pv else 0 end)::numeric "2040",
        sum(case when period='2045' then pv else 0 end)::numeric "2045",
        sum(case when period='2050' then pv else 0 end)::numeric "2050",
        sum(case when period='2055' then pv else 0 end)::numeric "2055",
        sum(case when period='2060' then pv else 0 end)::numeric "2060"
    from(
        select tablename,
            case
                when left(process,3)='ICH' then 'ich' --Filter 63
                when left(process,3)='ICM' then 'icm' --Filter 64
                when left(process,3)='IFD' then 'ifd' --Filter 65
                when left(process,3)='IIS' then 'iis' --Filter 66
                when left(process,3)='INF' then 'inf' --Filter 67
                when left(process,3)='INM' then 'inm' --Filter 68
                when left(process,3)='IOI' or process like 'INDHFCOTH0%' then 'ioi'  --Filter 69
                when left(process,3)='IPP' then 'ipp' --Filter 70
                when process='-' then 'other'
                else null
            end "sector",
            period, sum(case when commodity in('SKNINDCO2N','SKNINDCO2P') then -pv else pv end) "pv"
    -- These are sequestered emissions (emissions to CCS) so given negative emissions (-ve pv)
        from vedastore
        where commodity in ('SKNINDCO2N','SKNINDCO2P') and attribute='VAR_FOut' --Filter 72
    -- See above
        group by tablename, sector,period
    ) a
    where sector is not null
    group by tablename, sector
 ) TO '%~dp0IndSubGHG.csv' CSV;

/* *Electricity generation by source* */
-- This version reproduces many of the nos in the UCL XL template (see table "Electrity Generation, major power producers (electricity-only)", c466
-- prior to removing waste heat penalty; plus total CHP generated)- Note that the total is _not_ centralised generation by MPP only since it includes decentralised
-- CHP- Categories are reconcilable with UCL; they are:

-- This Q                          UCL
-- elec-gen_nga                  = Natural Gas
-- elec-gen_nga-ccs              = Natural Gas CCS
-- elec-gen_nuclear              = Nuclear
-- elec-gen_onw + elec-gen_offw  = Wind (is separated out in table below in template)
-- elec-gen_other-ff             = Oil + OIL CCS + Manufactured fuels
-- elec-gen_other-rens           = Wave + Geothermal + Hydro + Tidal + Hydrogen [generally v small]
-- elec-gen_solar                = Solar
-- elec-gen_total-cen            = not exactly equivalent (=centralised gen w/o storage, net imports + total chp)
-- elec-gen_waste-heat-penalty   = see "Electricity Penalty Allocation" table total at c2090
-- elec-gen_inten                = "GHG intensity of electricity generation (gCO2eq/kWh)" at cell b174
-- In this version, net imports are -ve (interconnectors line), net exports +ve
-- NB The interconnectors bit is confusing; to get exported elec, have to look at VAR_FIn because commodity is then transformed to an export
-- commodity (different name) by the interconnector- Vice versa for imports-

-- For electricity exports, VAR_FIn is summed as ELCGEN is the input to the process removing it from the system-

-- For the offtake penalty, note that ELCGEN input (VAR_FIn ) TO waste heat collection process needs to be subtracted from electricity generation as it
-- represents a reduction in efficiency of the plant the waste heat is collected from (i.e. cf CHP)-
-- 12:59 PM 09 June, 2016: Removed the imports and exports, changed name of interconnectors (to elec-gen_intercon from elec-gen_inter)
-- 12:25 PM 17 June, 2016: Revised q to better reflect the UCL template, inc- apportioning of cofiring to the different input fuels, and
                        -- refactoring to better match UCL veda tables
-- NB total line for this query is net of heat offtake penalty; it does not include interconnectors (or storage; = separate q below)- Grid intensity
-- calc is _not_ net of offtake penalty
-- This q uses postgres-specific arrays - would have to be re-written for another DB

COPY (
with emissions_chp as (
-- See veda table with same name
-- NB there are duplications in this table - a process can belong to more than one process set / row- the overlaps are represented by the 2 parts of the union q-
    select tablename, proc_set, commodity,period,sum(pv) "pv"
    from (
        select period, pv,commodity,process,tablename,
        case
            when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','ICHCHPCCGT01','ICHCHPCCGTH01','ICHCHPCOA00','ICHCHPCOA01','ICHCHPFCH01','ICHCHPGT01','ICHCHPHFO00','ICHCHPLFO00','ICHCHPLPG00'
                ,'ICHCHPLPG01','ICHCHPNGA00','ICHCHPPRO00','ICHCHPPRO01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01','IFDCHPCCGT01','IFDCHPCCGTH01','IFDCHPCOA00','IFDCHPCOA01','IFDCHPFCH01'
                ,'IFDCHPGT01','IFDCHPHFO00','IFDCHPLFO00','IFDCHPNGA00','IISCHPBFG00','IISCHPBFG01','IISCHPBIOG01','IISCHPBIOS01','IISCHPCCGT01','IISCHPCCGTH01','IISCHPCOG00','IISCHPCOG01'
                ,'IISCHPFCH01','IISCHPGT01','IISCHPHFO00','IISCHPNGA00','INMCHPBIOG01','INMCHPBIOS01','INMCHPCCGT01','INMCHPCCGTH01','INMCHPCOA01','INMCHPCOG00','INMCHPCOG01','INMCHPFCH01'
                ,'INMCHPGT01','INMCHPNGA00','IOICHPBIOG01','IOICHPBIOS00','IOICHPBIOS01','IOICHPCCGT01','IOICHPCCGTH01','IOICHPCOA01','IOICHPFCH01','IOICHPGT01','IOICHPHFO00','IOICHPNGA00'
                ,'IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPCCGT01','IPPCHPCCGTH01','IPPCHPCOA00','IPPCHPCOA01','IPPCHPFCH01','IPPCHPGT01','IPPCHPNGA00','IPPCHPWST00','IPPCHPWST01')
                then 'CHP IND SECTOR'      --Filter 270
            when process in('PCHP-CCP00','PCHP-CCP01') then 'CHP PRC SECTOR'      --Filter 333
            when process in('SCHP-ADM01','SCHP-CCG00','SCHP-CCG01','SCHP-CCH01','SCHP-FCH01','SCHP-GES00','SCHP-GES01','SCHP-STM01','SCHP-STW00','SCHP-STW01','SHHFCLRH01','SHLCHPRG01'
                ,'SHLCHPRH01','SHLCHPRW01','SCHP-EFW01') then 'CHP SER SECTOR'      --Filter 230
            when process in('UCHP-CCG00','UCHP-CCG01') then 'CHP UPS SECTOR'      --Filter 337
            when process in('RHEACHPRG01','RHEACHPRH01','RHEACHPRW01','RHFCCHPRG01','RHFCCHPRH01','RHFCCHPRW01','RHFSCHPRG01','RHFSCHPRH01','RHFSCHPRW01','RHHCCHPRG01','RHHCCHPRH01','RHHCCHPRW01'
                ,'RHHSCHPRG01','RHHSCHPRH01','RHHSCHPRW01','RHNACHPRG01','RHNACHPRH01','RHNACHPRW01') then 'CHP RES MICRO' --Filter 393
        end proc_set
        from vedastore
        where attribute='VAR_FOut' and commodity in('RESCH4N','SERN2ON','INDCO2N','SERCH4N','INDCH4N','INDN2ON','UPSN2ON','UPSCO2N','UPSCH4N','PRCCH4N','PRCCO2N','PRCN2ON'
            ,'SERCO2N','RESCO2N','RESN2ON')
        union all
        select period, pv,commodity,process,tablename,
        case
            when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01','IISCHPBIOG01','IISCHPBIOS01','INMCHPBIOG01','INMCHPBIOS01','IOICHPBIOG01'
                ,'IOICHPBIOS00','IOICHPBIOS01','IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPWST00','IPPCHPWST01') then 'CHP IND BIO'      --Filter 336
            when process in('SCHP-ADM01','SCHP-GES00','SCHP-GES01','SCHP-STM01','SCHP-STW00','SCHP-STW01','SHLCHPRW01','SCHP-EFW01') then 'CHP SER BIO'      --Filter 368
            when process in('SHHFCLRH01','SHLCHPRG01','SHLCHPRH01','SHLCHPRW01') then 'CHP SER MICRO'      --Filter 324
            when process in('RCHPEA-CCG00','RCHPEA-CCG01','RCHPEA-CCH01','RCHPEA-FCH01','RCHPEA-STW01','RCHPNA-CCG01','RCHPNA-CCH01','RCHPNA-FCH01','RCHPNA-STW01','RHEACHPRG01','RHEACHPRH01','RHEACHPRW01'
                ,'RHNACHPRG01','RHNACHPRH01','RHNACHPRW01','RCHPEA-EFW01','RCHPNA-EFW01') 
                then 'CHP RES SECTOR'      --Filter 303
            else null
        end proc_set
        from vedastore
        where attribute='VAR_FOut' and commodity in('RESCH4N','SERN2ON','INDCO2N','SERCH4N','INDCH4N','INDN2ON','UPSN2ON','UPSCO2N','UPSCH4N','PRCCH4N','PRCCO2N','PRCN2ON'
            ,'SERCO2N','RESCO2N','RESN2ON')  --Filter 73
    ) a
    where proc_set is not null
    group by tablename, proc_set, commodity,period
)
, emis_co2_sector as(
--see veda table of same name
    select tablename, comm_set,
    commodity,period, pv
    from (
        select case
            when commodity in('AGRCO2N','AGRCO2P') then 'EMIS CO2 AGR'      --Filter 365
            when commodity in('ELCCO2N') then 'EMIS CO2 ELC'      --Filter 331
            when commodity in('HYGCO2N') then 'EMIS CO2 HYG'      --Filter 370
            when commodity in('INDCO2N','INDCO2P') then 'EMIS CO2 IND'      --Filter 237
            when commodity in('INDNEUCO2N') then 'EMIS CO2 NEU'      --Filter 233
            when commodity in('PRCCO2N','PRCCO2P') then 'EMIS CO2 PRC'      --Filter 264
            when commodity in('RESCO2N') then 'EMIS CO2 RES'      --Filter 292
            when commodity in('SERCO2N') then 'EMIS CO2 SER'      --Filter 323
            when commodity in('TRACO2N') then 'EMIS CO2 TRA'      --Filter 321
            when commodity in('UPSCO2N','UPSCO2P') then 'EMIS CO2 UPS'      --Filter 281
            end as comm_set,commodity,pv,period,tablename
        from vedastore
        where attribute='VAR_FOut'
    ) a where comm_set is not null
)
, emis_ghg_dif as (
-- see veda table of same name
    select tablename, comm_set,
    commodity,period,pv
    from (
        select case
            when commodity in ('AGRCH4N','AGRCH4P','AGRCO2N','AGRCO2P','AGRHFCN','AGRHFCP','AGRN2ON','AGRN2OP','AGRNH3','AGRNOX','AGRPM10','AGRPM25','AGRSO2','AGRVOC') then 'EMIS GHG AGR' --Filter 349
            when commodity in ('ELCCH4N','ELCCH4P','ELCCO2N','ELCCO2P','ELCHFCN','ELCHFCP','ELCN2ON','ELCN2OP','ELCNH3','ELCNOX','ELCPM10','ELCPM25','ELCSO2','ELCVOC') then 'EMIS GHG ELC' --Filter 284
            when commodity in ('HYGCH4N','HYGCH4P','HYGCO2N','HYGCO2P','HYGHFCN','HYGHFCP','HYGN2ON','HYGN2OP','HYGNH3','HYGNOX','HYGPM10','HYGPM25','HYGSO2','HYGVOC') then 'EMIS GHG HYG' --Filter 227
            when commodity in ('INDCH4N','INDCH4P','INDCO2N','INDCO2P','INDHFCN','INDHFCP','INDN2ON','INDN2OP') then 'EMIS GHG IND' --Filter 288
            when commodity in ('INDNEUCO2N') then 'EMIS GHG NEU' --Filter 319
    -- NB These commodities are not included in the veda set: should they be? 'INDNEUCH4S','INDNEUCO2S','INDNEUN2OS'
            when commodity in ('PRCCH4N','PRCCH4P','PRCCO2N','PRCCO2P','PRCHFCN','PRCHFCP','PRCN2ON','PRCN2OP','PRCNH3','PRCNOX','PRCPM10','PRCPM25','PRCSO2','PRCVOC') then 'EMIS GHG PRC' --Filter 329
            when commodity in ('RESCH4N','RESCH4P','RESCO2N','RESCO2P','RESHFCN','RESHFCP','RESN2ON','RESN2OP','RESNH3','RESNOX','RESPM10','RESPM25','RESSO2','RESVOC') then 'EMIS GHG RES' --Filter 363
            when commodity in ('SERCH4N','SERCH4P','SERCO2N','SERCO2P','SERHFCN','SERHFCP','SERN2ON','SERN2OP','SERNH3','SERNOX','SERPM10','SERPM25','SERSO2','SERVOC') then 'EMIS GHG SER' --Filter 339
            when commodity in ('TRACH4N','TRACH4P','TRACO2N','TRACO2P','Traded-Emission-ETS','Traded-Emission-Non-ETS','TRAHFCN','TRAHFCP','TRAN2ON','TRAN2OP','TRANH3','TRANOX','TRAPM10'
                ,'TRAPM25','TRASO2','TRAVOC') then 'EMIS GHG TRA' --Filter 311
            when commodity in ('UPSCH4N','UPSCH4P','UPSCO2N','UPSCO2P','UPSHFCN','UPSHFCP','UPSN2ON','UPSN2OP') then 'EMIS GHG UPS' --Filter 285
        end as comm_set,commodity,pv,period, tablename
        from vedastore
        where attribute in('EQ_Combal','VAR_Comnet') --Filter 74
    ) a where comm_set is not null
)
, "elc-emis" as(
    select
        tablename,period,sum(pv)/1000 "elc-emis" --/1000 = Convert from kilo to Mega tonnes
    from (
        select tablename,pv,period from "emis_co2_sector" where comm_set='EMIS CO2 ELC'
        union all
        select tablename,pv,period from "emis_ghg_dif"
		where commodity in('ELCCH4N','ELCN2ON')  --Filter 76
        union all
        select tablename,sum(pv) "pv", period from "emissions_chp"
		where proc_set in('CHP IND SECTOR','CHP PRC SECTOR','CHP RES SECTOR','CHP SER SECTOR','CHP UPS SECTOR') and
            commodity in('INDCO2N','INDCH4N','INDN2ON','PRCCO2N','PRCCH4N','PRCN2ON','RESCO2N','RESCH4N','RESN2ON','SERCO2N','SERCH4N','SERN2ON','UPSCO2N','UPSCH4N','UPSN2ON') --Filter 77
        group by tablename, period
    ) a group by tablename,period
)
, elc_prd_fuel as (
-- This is the same as the Veda BE table (same name) with the addition of more years & the addition of CHP & the heat offtake generation penalty
-- NB CCSRET lines currently missing from veda (sets not defined since are part of PRE set not ELE which is in the filter definition)
    select
        proc_set,tablename,period, sum(pv) "pv"
    from (
        select
        tablename,period, pv,
        case
            when process in('EBIO01','EBIOCON00','EBIOS00','EBOG-ADE01','EBOG-LFE00','EBOG-LFE01','EBOG-SWE00','EBOG-SWE01','EMSW00','EMSW01','EPOLWST00','ESTWWST00'
                ,'ESTWWST01') then 'ELC FROM BIO' --Filter 297
            when process in('EBIOQ01') then 'ELC FROM BIO CCS' --Filter 306
            when process in('PCHP-CCP00','PCHP-CCP01','UCHP-CCG00','UCHP-CCG01') then 'ELC FROM CHP' --Filter 358
            when process='ECOAQR01' then 'ELC FROM COAL CCSRET' --Filter 245
            when process in('ECOARR01') then 'ELC FROM COAL RR' --Filter 238
            when process in('ECOA00','ECOABIO00') then 'ELC FROM COAL-COF' --Filter 347
            when process in('ECOAQ01','ECOAQDEMO01') then 'ELC FROM COALCOF CCS' --Filter 248
            when process in('ENGACCT00','ENGAOCT00','ENGAOCT01','ENGARCPE00','ENGARCPE01') then 'ELC FROM GAS' --Filter 243
            when process in('ENGACCTQ01','ENGACCTQDEMO01') then 'ELC FROM GAS CCS' --Filter 301
            when process='ENGAQR01' then 'ELC FROM GAS CCSRET' --Filter 240
            when process in('ENGACCTRR01') then 'ELC FROM GAS RR' --Filter 392
            when process in('EGEO01') then 'ELC FROM GEO' --Filter 338
            when process in('EHYD00','EHYD01') then 'ELC FROM HYDRO' --Filter 373
            when process in('EHYGCCT01','EHYGOCT01') then 'ELC FROM HYDROGEN' --Filter 283
            when process in('ELCIE00','ELCIE01','ELCII00','ELCII01') then 'ELC FROM IMPORTS' --Filter 225
            when process in('EMANOCT00','EMANOCT01') then 'ELC FROM MANFUELS' --Filter 294
            when process in('ENUCPWR00','ENUCPWR101','ENUCPWR102') then 'ELC FROM NUCLEAR' --Filter 261
            when process in('EDSTRCPE00','EDSTRCPE01','EHFOIGCC01','EOILL00','EOILL01','EOILS00','EOILS01') then 'ELC FROM OIL' --Filter 341
            when process in('EHFOIGCCQ01') then 'ELC FROM OIL CCS' --Filter 290
            when process in('ESOL00','ESOL01','ESOLPV00','ESOLPV01') then 'ELC FROM SOL-PV' --Filter 366
            when process in('ETIB101','ETIR101','ETIS101') then 'ELC FROM TIDAL' --Filter 352
            when process in('EWAV101') then 'ELC FROM WAVE' --Filter 239
            when process in('EWNDOFF00','EWNDOFF101','EWNDOFF201','EWNDOFF301') then 'ELC FROM WIND-OFFSH' --Filter 299
            when process in('EWNDONS00','EWNDONS101','EWNDONS201','EWNDONS301','EWNDONS401','EWNDONS501','EWNDONS601','EWNDONS701','EWNDONS801','EWNDONS901') then 'ELC FROM WIND-ONSH' --Filter 236
            when process in('ELCEE00','ELCEE01','ELCEI00','ELCEI01') then 'ELC TO EXPORTS' --Filter 298
         end as proc_set
        from vedastore
        where attribute='VAR_FOut' and commodity in('ELCDUMMY','ELC','ELC-E-IRE','ELC-E-EU','ELCGEN')  --Filter 78
    ) a
    where proc_set is not null
    group by tablename, period,proc_set
    union all
    select proc_set,tablename,period, sum(pv) "pv"
        from (
            select tablename,period, pv,
            case when process in(
                'ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','ICHCHPCCGT01','ICHCHPCCGTH01','ICHCHPCOA00','ICHCHPCOA01','ICHCHPFCH01',
                'ICHCHPGT01','ICHCHPHFO00','ICHCHPLFO00','ICHCHPLPG00','ICHCHPLPG01','ICHCHPNGA00','ICHCHPPRO00','ICHCHPPRO01',
                'IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01','IFDCHPCCGT01','IFDCHPCCGTH01','IFDCHPCOA00','IFDCHPCOA01','IFDCHPFCH01',
                'IFDCHPGT01','IFDCHPHFO00','IFDCHPLFO00','IFDCHPNGA00','IISCHPBFG00','IISCHPBFG01','IISCHPBIOG01','IISCHPBIOS01',
                'IISCHPCCGT01','IISCHPCCGTH01','IISCHPCOG00','IISCHPCOG01','IISCHPFCH01','IISCHPGT01','IISCHPHFO00','IISCHPNGA00',
                'INMCHPBIOG01','INMCHPBIOS01','INMCHPCCGT01','INMCHPCCGTH01','INMCHPCOA01','INMCHPCOG00','INMCHPCOG01','INMCHPFCH01',
                'INMCHPGT01','INMCHPNGA00','IOICHPBIOG01','IOICHPBIOS00','IOICHPBIOS01','IOICHPCCGT01','IOICHPCCGTH01','IOICHPCOA01',
                'IOICHPFCH01','IOICHPGT01','IOICHPHFO00','IOICHPNGA00','IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPCCGT01',
                'IPPCHPCCGTH01','IPPCHPCOA00','IPPCHPCOA01','IPPCHPFCH01','IPPCHPGT01','IPPCHPNGA00','IPPCHPWST00','IPPCHPWST01',
                'PCHP-CCP00','PCHP-CCP01','RCHPEA-CCG00','RCHPEA-CCG01','RCHPEA-CCH01','RCHPEA-FCH01','RCHPEA-STW01','RCHPNA-CCG01',
                'RCHPNA-CCH01','RCHPNA-FCH01','RCHPNA-STW01','RHEACHPRG01','RHEACHPRH01','RHEACHPRW01','RHNACHPRG01','RHNACHPRH01',
                'RHNACHPRW01','RCHPEA-EFW01','RCHPNA-EFW01','SCHP-ADM01','SCHP-CCG00','SCHP-CCG01','SCHP-CCH01','SCHP-FCH01','SCHP-GES00','SCHP-GES01','SCHP-STM01',
                'SCHP-STW00','SCHP-STW01','SHHFCLRH01','SHLCHPRG01','SHLCHPRH01','SHLCHPRW01','SCHP-EFW01','UCHP-CCG00','UCHP-CCG01') then 'elec-gen_chp' else null --Filter 79
    -- NB This is different from the Veda BE chp gen q as that only looks at centralised chp generation - not all chp generation which is what we report in the overall q here
            end proc_set
            from vedastore
            where period in('2010','2011','2012','2015','2020','2025','2030','2035','2040','2045','2050','2055','2060') and attribute='VAR_FOut'
                and commodity in('ELCGEN','INDELC','RESELC','RESHOUSEELC','SERBUILDELC','SERDISTELC','SERELC') --Filter 80
        ) a
    where proc_set is not null
    group by tablename, period,proc_set
    union all
    select proc_set,tablename,period, sum(pv) "pv"
    from (
        select tablename,period, pv,
        case when process='EWSTHEAT-OFF-01' then 'elec-gen_waste-heat-penalty' else null --Filter 81
-- heat penalty - stuff which is recorded as electricity but is actually electricity which is sacrificed to produce heat (in e.g. CHP)
        end::varchar(50) proc_set
        from vedastore
        where period in('2010','2011','2012','2015','2020','2025','2030','2035','2040','2045','2050','2055','2060') and commodity = 'ELCGEN' and attribute = 'VAR_FIn'
    ) a
    where proc_set is not null
    group by tablename, period,proc_set
)
, cofiring_fuel as(
-- Replicates the calcs in c 571
-- Just gives the input fuel used for key co-firing elec gen processes
    select tablename, fuel, period, sum(pv) "pv"
        from (
            select tablename,commodity "fuel",period,pv
            from vedastore
            where process in('ECOA00','ECOABIO00','ECOAQ01','ECOARR01','ECOAQDEMO01') and attribute='VAR_FIn' --Filter 82
-- co-firing coal
            union all
            select tablename,commodity "fuel",period,pv
            from vedastore
            where commodity in ('ELCBIOLFO','ELCBIOOIL','ELCHFO','ELCLFO','ELCLPG') and attribute='VAR_FIn' --Filter 83
-- co-firing oil
            union all
            select tablename,commodity "fuel",period,pv
            from vedastore
            where commodity in('ELCMAINSBOM','ELCMAINSGAS','ELCTRANSBOM','ELCTRANSGAS') and attribute='VAR_FIn' --Filter 84
-- co-firing gas
        ) a
    group by tablename, fuel,period
    order by fuel, period
)
, cofiring_fuel_percents as(
    select tablename, period,
-- Replicates the calcs in c 595 ff
-- Produces the percentage of each fuel type used for inputs to key elec gen processes
-- NB have to include the sum>0 test (wrapper part of each of below) because otherwise generates div zero errors
    case when sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end ) > 0 then
        sum(case when fuel='ELCCOA' then pv else 0 end) / sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end )
    else 0 end "coal",
    case when sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end ) > 0 then
        sum(case when fuel in('ELCBIOCOA','ELCBIOCOA2','ELCPELL') then pv else 0 end) / sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end )
    else 0 end "biocoal",
    case when sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end ) > 0 then
        sum(case when fuel in('ELCMSC') then pv else 0 end) / sum(case when fuel in('ELCCOA','ELCBIOCOA','ELCBIOCOA2','ELCPELL','ELCMSC') then pv else 0 end )
    else 0 end "oilcoal",
    case when sum(case when fuel in('ELCHFO','ELCLFO','ELCLPG','ELCBIOOIL','ELCBIOLFO') then pv else 0 end ) > 0 then
        sum(case when fuel in('ELCHFO','ELCLFO','ELCLPG') then pv else 0 end) / sum(case when fuel in('ELCHFO','ELCLFO','ELCLPG','ELCBIOOIL','ELCBIOLFO') then pv else 0 end )
    else 0 end "oil",
    case when sum(case when fuel in('ELCHFO','ELCLFO','ELCLPG','ELCBIOOIL','ELCBIOLFO') then pv else 0 end ) > 0 then
        sum(case when fuel in('ELCBIOOIL','ELCBIOLFO') then pv else 0 end) / sum(case when fuel in('ELCHFO','ELCLFO','ELCLPG','ELCBIOOIL','ELCBIOLFO') then pv else 0 end )
    else 0 end "biooil",
    case when sum(case when fuel in('ELCMAINSGAS','ELCTRANSGAS','ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end ) > 0 then
        sum(case when fuel in('ELCMAINSGAS','ELCTRANSGAS') then pv else 0 end) / sum(case when fuel in('ELCMAINSGAS','ELCTRANSGAS','ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end )
    else 0 end "gas",
    case when sum(case when fuel in('ELCMAINSGAS','ELCTRANSGAS','ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end ) > 0 then
        sum(case when fuel in('ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end) / sum(case when fuel in('ELCMAINSGAS','ELCTRANSGAS','ELCMAINSBOM','ELCTRANSBOM') then pv else 0 end )
    else 0 end "biogas"
    from cofiring_fuel
    group by tablename, period
)
, elc_waste_heat_process as (
--This is the total waste heat to be divvidied up between candidate gen processes
    select tablename, process,userconstraint,attribute,commodity,period,sum(pv) "pv"
    from vedastore
    where process='EWSTHEAT-OFF-01' and commodity='ELCGEN' and attribute='VAR_FIn'--Filter 85
    group by tablename, process,userconstraint,attribute,commodity, period
    order by tablename, process,userconstraint,attribute,commodity, period
)
, elc_waste_heat_available as (
    select tablename,attribute,commodity,process,period, sum(pv) "pv"
    from vedastore
    where commodity='ELCWSTHEAT' and attribute in ('VAR_FIn','VAR_FOut') --Filter 86
    group by tablename,attribute,commodity,process,period
    order by tablename,attribute,commodity,process,period
)
, waste_heat_type as(
-- NB need to remember to update this to reflect any technology changes
    select tablename, period,
    sum(case when "waste_heat"='Biomass' then pv else 0 end) "Biomass",
    sum(case when "waste_heat"='Biomass CCS' then pv else 0 end) "Biomass CCS",
    sum(case when "waste_heat"='Hydrogen' then pv else 0 end) "Hydrogen",
    sum(case when "waste_heat"='Nuclear' then pv else 0 end) "Nuclear",
    sum(case when "waste_heat"='Coal' then pv else 0 end) "Coal",
    sum(case when "waste_heat"='Coal CCS' then pv else 0 end) "Coal CCS",
    sum(case when "waste_heat"='Coal RR' then pv else 0 end) "Coal RR",
    sum(case when "waste_heat"='Natural Gas' then pv else 0 end) "Natural Gas",
    sum(case when "waste_heat"='Natural Gas CCS' then pv else 0 end) "Natural Gas CCS",
    sum(case when "waste_heat"='Natural Gas RR' then pv else 0 end) "Natural Gas RR",
    sum(case when "waste_heat"='Oil' then pv else 0 end) "Oil",
    sum(case when "waste_heat"='OIL CCS' then pv else 0 end) "OIL CCS"
    from (
    -- These are the first category of waste heat by process - in formula c2061ff
        select tablename,attribute,period,pv,
        case
            when process in('ESTWWST00','EPOLWST00','EBIOS00','EBOG-LFE00','EBOG-SWE00','EMSW00','EBIOCON00','ESTWWST01','EBIO01','EBOG-ADE01','EBOG-LFE01','EBOG-SWE01','EMSW01') then 'Biomass' --Filter 87
            when process in('EBIOQ01') then 'Biomass CCS' --Filter 88
            when process in('EHYGCCT01') then 'Hydrogen' --Filter 89
            when process in('ENUCPWR00','ENUCPWR101','ENUCPWR102') then 'Nuclear' --Filter 90
            end "waste_heat"
        from elc_waste_heat_available
        union all
        select tablename,attribute,period,pv,
    -- These are the "second" set of waste heat candidates - see cell c2043ff- These form part of the formula which goes into the second part of cells c2061ff- This is added to
    -- "Seperation of retrofit ready and retrofited plants" and multiplied by the proportion of biomass/non- for coal etc
        case
            when process in('ECOA00','ECOABIO00') then 'Coal' --Filter 91
            when process in('ECOAQ01','ECOAQDEMO01') then 'Coal CCS' --Filter 92
            when process in('ECOARR01') then 'Coal RR' --Filter 93
            when process in('ENGACCT00','ENGAOCT00','ENGAOCT01','ENGARCPE00','ENGARCPE01') then 'Natural Gas' --Filter 94
            when process in('ENGACCTQ01','ENGACCTQDEMO01','ENGAQR01') then 'Natural Gas CCS' --Filter 95
            when process in('ENGACCTRR01') then 'Natural Gas RR' --Filter 96
            when process in('EDSTRCPE00','EDSTRCPE01','EOILL00','EOILS00','EOILS01','EOILL01','EHFOIGCC01') then 'Oil' --Filter 216
            when process in('EHFOIGCCQ01') then 'OIL CCS' --Filter 97
            end "waste_heat"
        from elc_waste_heat_available
    ) a
    where "waste_heat" is not null
    group by tablename, period
    order by tablename, period
)
, retrofit_plants as(
-- This replicates the block c2034ff
-- NB have to have the q in 2 parts like this, with the sum() wrapping the multiplication or else it demands you group by the constituents of the *
-- previously, CCS plant was a subset of retrofit ready. Now they are independent (thanks to dummy parameter)
    select a.tablename, a.period,
    sum(a."coal_rr"*b."Coal RR") "coal_rr",
    sum(a."gas_rr"*b."Natural Gas RR") "gas_rr",
    sum(a."coalccs_rr"*b."Coal RR") "coalccs_rr",
    sum(a."gasccs_rr"*b."Natural Gas RR") "gasccs_rr"
    from (
        select tablename, period,
-- Following includes a check for div zero errors:
        case
            when sum(case when proc_set in('ELC FROM COAL RR','ELC FROM COAL CCSRET') then pv else 0 end) > 0 then
            (sum(case when proc_set='ELC FROM COAL RR' then pv else 0 end)/sum(case when proc_set in('ELC FROM COAL RR','ELC FROM COAL CCSRET') then pv else 0 end))
            else 0 end "coal_rr",
        case
            when sum(case when proc_set in('ELC FROM GAS RR','ELC FROM GAS CCSRET') then pv else 0 end) > 0 then
            (sum(case when proc_set='ELC FROM GAS RR' then pv else 0 end)/sum(case when proc_set in('ELC FROM GAS RR','ELC FROM GAS CCSRET') then pv else 0 end))
            else 0 end "gas_rr",
        case
            when sum(case when proc_set in('ELC FROM COAL RR','ELC FROM COAL CCSRET') then pv else 0 end) > 0 then
            (sum(case when proc_set='ELC FROM COAL CCSRET' then pv else 0 end)/sum(case when proc_set in('ELC FROM COAL RR','ELC FROM COAL CCSRET') then pv else 0 end))
            else 0 end "coalccs_rr",
        case
            when sum(case when proc_set in('ELC FROM GAS RR','ELC FROM GAS CCSRET') then pv else 0 end) > 0 then
            (sum(case when proc_set='ELC FROM GAS CCSRET' then pv else 0 end)/sum(case when proc_set in('ELC FROM GAS RR','ELC FROM GAS CCSRET') then pv else 0 end))
            else 0 end "gasccs_rr"
        from elc_prd_fuel
        group by tablename, period
        ) a
    inner join waste_heat_type b
    on a.tablename=b.tablename and a.period=b.period
    group by a.tablename, a.period
)
, fuel_shares_to_groups as(
-- Replicates the formulae at c2043ff, and c2061ff
    select tablename, period,
        "coal_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "coal_grp",
        "coalccs_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "coalccs_grp",
        "gas_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "gas_grp",
        "gasccs_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "gasccs_grp",
        "oil_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "oil_grp",
        "oilccs_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "oilccs_grp",
        "bio_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "bio_grp",
        "bioccs_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "bioccs_grp",
        "nuclear_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "nuclear_grp",
        "h2_grp"/("coal_grp"+"coalccs_grp"+"gas_grp"+"gasccs_grp"+"oil_grp"+"oilccs_grp"+"bio_grp"+"bioccs_grp"+"nuclear_grp"+"h2_grp") "h2_grp"
-- i.e. take the below as a proportion of the total
    from (
        select a.tablename, a.period,
            (sum(c."Coal")+sum("coal_rr"))*sum(a.coal) "coal_grp",
--row 2061 = row2043
            (sum(c."Coal CCS")+sum("coalccs_rr"))*sum(a.coal) "coalccs_grp",
--row 2062 = row2046
            (sum(c."Natural Gas")+sum("gas_rr"))*sum(a.gas) "gas_grp",
--row 2063 = row2049
            (sum(c."Natural Gas CCS")+sum("gasccs_rr"))*sum(a.gas) "gasccs_grp",
--row 2064 = row2051
            (sum(c."Coal")+sum("coal_rr"))*sum(a.oilcoal) + sum(c."Oil")*sum(a.oil) "oil_grp",
-- This is the sum of oil pure, and oil in coal fired generation (rows 2045, 2053)
            sum(c."OIL CCS")*sum(a.oil) + (sum(c."Coal CCS")+sum("coalccs_rr"))*sum(a.oilcoal) "oilccs_grp",
-- This is sum of oil ccs pure, and oil in coal fired ccs generation (rows (2048+2055)=2066)
            sum(c."Biomass") + (sum(c."Coal")+sum("coal_rr"))*sum(a.biocoal) +
                (sum("Natural Gas")+sum("gas_rr"))*sum(a.biogas) + sum(c."Oil")*sum(a.biooil) "bio_grp",
-- This is sum of biomass pure (from "waste_heat"), bio in coal fired, bio in oil fired and bio in gas fired generation (rows 2044+2050+2054)
            sum(c."Biomass CCS") + (sum(c."Coal CCS")+sum("coalccs_rr"))*sum(a.biocoal) +
                (sum(c."Natural Gas CCS")+sum("gasccs_rr"))*sum(a.biogas) + sum(c."OIL CCS")*sum(a.biooil) "bioccs_grp",
-- This is sum of biomass CCS pure (from "waste_heat"), bio in coal fired, bio in oil fired and bio in gas fired generation (rows 2044+2050+2054)
            sum(c."Nuclear") "nuclear_grp",
            sum(c."Hydrogen") "h2_grp"
        from cofiring_fuel_percents a full outer join retrofit_plants b
        on a.tablename=b.tablename and a.period=b.period
        full outer join waste_heat_type c
        on a.tablename=c.tablename and a.period=c.period
        group by a.tablename, a.period
-- i.e. just in case there are blank years
     ) a
)
, elec_penalty as (
    select a.tablename, a.period,
    -- Replicates block starting row 2095, "Electricity Penalty Allocation"
    -- Have to have the case--- statement to catch any nulls or else that line will evaluate to null in the final q
        case when coal_grp*b."ELCGEN" is null then 0 else coal_grp*b."ELCGEN" end "coal",
        case when coalccs_grp*b."ELCGEN" is null then 0 else coalccs_grp*b."ELCGEN" end "coalccs",
        case when gas_grp*b."ELCGEN" is null then 0 else gas_grp*b."ELCGEN" end "gas",
        case when gasccs_grp*b."ELCGEN" is null then 0 else gasccs_grp*b."ELCGEN" end "gasccs",
        case when oil_grp*b."ELCGEN" is null then 0 else oil_grp*b."ELCGEN" end "oil",
        case when oilccs_grp*b."ELCGEN" is null then 0 else oilccs_grp*b."ELCGEN" end "oilccs",
        case when bio_grp*b."ELCGEN" is null then 0 else bio_grp*b."ELCGEN" end "bio",
        case when bioccs_grp*b."ELCGEN" is null then 0 else bioccs_grp*b."ELCGEN" end "bioccs",
        case when nuclear_grp*b."ELCGEN" is null then 0 else nuclear_grp*b."ELCGEN" end "nuclear",
        case when h2_grp*b."ELCGEN" is null then 0 else h2_grp*b."ELCGEN" end "h2"
    from fuel_shares_to_groups a
    left join (
            select tablename, period,
            sum(pv) "ELCGEN"
            from elc_waste_heat_process
            group by tablename, period
        ) b
    on a.tablename=b.tablename and a.period=b.period
    order by period
)
-- Final query bringing it all together
select cols || '|' || tablename || '|' ||
    case
        when cols='elec-gen_intercon' then 'various'::varchar
        when cols='elec-gen_waste-heat-penalty' then 'VAR_FIn'::varchar
        else 'VAR_FOut'::varchar
    end || '|various|various'::varchar "id",
    cols::varchar "analysis",
    tablename,
    case
        when cols='elec-gen_intercon' then 'various'::varchar
        when cols='elec-gen_waste-heat-penalty' then 'VAR_FIn'::varchar
        else 'VAR_FOut'::varchar
    end "attribute",
    'various'::varchar "commodity",
    'various'::varchar "process",
    case
        when cols='elec-gen_inten' then avg(vals)
        else sum(vals)
    end "all",
    sum(case when d.period='2010' then vals else 0 end) as "2010" ,
    sum(case when d.period='2011' then vals else 0 end) as "2011",
    sum(case when d.period='2012' then vals else 0 end) as "2012",
    sum(case when d.period='2015' then vals else 0 end) as "2015",
    sum(case when d.period='2020' then vals else 0 end) as "2020",
    sum(case when d.period='2025' then vals else 0 end) as "2025",
    sum(case when d.period='2030' then vals else 0 end) as "2030",
    sum(case when d.period='2035' then vals else 0 end) as "2035",
    sum(case when d.period='2040' then vals else 0 end) as "2040",
    sum(case when d.period='2045' then vals else 0 end) as "2045",
    sum(case when d.period='2050' then vals else 0 end) as "2050",
    sum(case when d.period='2055' then vals else 0 end) as "2055",
    sum(case when d.period='2060' then vals else 0 end) as "2060"
    from(
        SELECT unnest(array['elec-gen_coal','elec-gen_coal-ccs','elec-gen_nga','elec-gen_nga-ccs','elec-gen_other-ff','elec-gen_bio'
           ,'elec-gen_bio-ccs','elec-gen_other-rens','elec-gen_solar','elec-gen_nuclear','elec-gen_offw','elec-gen_onw','elec-gen_chp','elec-gen_total-cen'
           ,'elec-gen_intercon','elec-gen_waste-heat-penalty','elec-gen_inten']) AS "cols",
           tablename,period,
           unnest(array["elec-gen_coal","elec-gen_coal-ccs","elec-gen_nga","elec-gen_nga-ccs","elec-gen_other-ff","elec-gen_bio","elec-gen_bio-ccs"
           ,"elec-gen_other-rens","elec-gen_solar","elec-gen_nuclear","elec-gen_offw","elec-gen_onw","elec-gen_chp","elec-gen_total-cen","elec-gen_intercon",
           "elec-gen_waste-heat-penalty","elec-gen_inten"]) AS "vals"
        FROM (
            select a.tablename,a.period, "coal-unad"*b.coal-d.coal "elec-gen_coal",
-- =unadjusted coal * co-firing percents for coal - elec penalty for coal. Similar calcs for others below
            "coalccs-unad"*b.coal-d.coalccs "elec-gen_coal-ccs",
            "gas-unad"*b.gas-d.gas "elec-gen_nga",
            "gasccs-unad"*b.gas-d.gasccs "elec-gen_nga-ccs",
            ("ELC FROM OIL"*b.oil+"coal-unad"*b.oilcoal)-d.oil
            --ie oil [not ccs]
            +("ELC FROM OIL CCS"*b.oil+"coalccs-unad"*b.oilcoal)-d.oilccs
            -- oil ccs
            +"ELC FROM MANFUELS"
            --man fuels
             "elec-gen_other-ff",
            ("ELC FROM BIO"+"coal-unad"*biocoal+"ELC FROM OIL"*biooil+"gas-unad"*b.biogas)-d.bio "elec-gen_bio",
            ("ELC FROM BIO CCS"+"coalccs-unad"*biocoal+"ELC FROM OIL CCS"*biooil+"gasccs-unad"*b.biogas)-d.bioccs "elec-gen_bio-ccs",
            "elec-gen_other-rens"-d.h2 "elec-gen_other-rens",
            "elec-gen_solar",
            "elec-gen_nuclear"-d.nuclear "elec-gen_nuclear",
            "elec-gen_offw",
            "elec-gen_onw",
            "elec-gen_chp",
            "coal-unad"*b.coal-d.coal+"coalccs-unad"*b.coal-d.coalccs+"gas-unad"*b.gas-d.gas+"gasccs-unad"*b.gas-d.gasccs+("ELC FROM OIL"*b.oil+"coal-unad"*b.oilcoal)-d.oil+
            ("ELC FROM OIL CCS"*b.oil+"coalccs-unad"*b.oilcoal)-d.oilccs+"ELC FROM MANFUELS"+("ELC FROM BIO"+"coal-unad"*b.biocoal+"ELC FROM OIL"*b.biooil+
            "gas-unad"*b.biogas)-d.bio+("ELC FROM BIO CCS"+"coalccs-unad"*b.biocoal+"ELC FROM OIL CCS"*b.biooil+
            "gasccs-unad"*b.biogas)-d.bioccs+"elec-gen_other-rens"-d.h2+"elec-gen_solar"+"elec-gen_nuclear"-d.nuclear+"elec-gen_offw"+"elec-gen_onw"+"elec-gen_chp" "elec-gen_total-cen",
            -- i.e. everything above except interconn- NB includes not just "centralised" chp [in refineries etc] but all chp- Done this way to reduce rounding errors cf the individual [constituent] lines above
            "elec-gen_intercon",
            "elec-gen_waste-heat-penalty",
            "elc-emis"/
            ("coal-unad"*b.coal+"coalccs-unad"*b.coal+"gas-unad"*b.gas+"gasccs-unad"*b.gas+"ELC FROM OIL"*b.oil+"coal-unad"*b.oilcoal+"ELC FROM OIL CCS"*b.oil+"coalccs-unad"*b.oilcoal+
            "ELC FROM MANFUELS"+"ELC FROM BIO"+"coal-unad"*b.biocoal+"ELC FROM OIL"*b.biooil+"gas-unad"*b.biogas+"ELC FROM BIO CCS"+"coalccs-unad"*b.biocoal+"ELC FROM OIL CCS"*b.biooil+
            "gasccs-unad"*b.biogas+"elec-gen_other-rens"+"elec-gen_solar"+"elec-gen_nuclear"+"elec-gen_offw"+"elec-gen_onw"+"elec-gen_chp"-"elec-gen_waste-heat-penalty"
            -(case when "elec-gen_intercon"<0 then "elec-gen_intercon" else 0 end))*3600
            "elec-gen_inten"
            -- i.e. emissions (from sub-qs near top) / elc generated * conversion to get to g/kWh- Need to capture any net elc exports hence the case...when statement*/
            from(
                select a.period, a.tablename,
                sum(case when proc_set='ELC TO EXPORTS' then -pv when proc_set='ELC FROM IMPORTS' then pv else 0 end) "elec-gen_intercon",
                sum(case when proc_set in ('ELC FROM TIDAL','ELC FROM WAVE','ELC FROM GEO','ELC FROM HYDRO','ELC FROM HYDROGEN') then pv else 0 end) "elec-gen_other-rens",
                --incls e- from H2
                sum(case when proc_set in ('ELC FROM SOL-PV') then pv else 0 end) "elec-gen_solar",
                sum(case when proc_set in ('ELC FROM NUCLEAR') then pv else 0 end) "elec-gen_nuclear",
                sum(case when proc_set in ('ELC FROM WIND-OFFSH') then pv else 0 end) "elec-gen_offw",
                sum(case when proc_set in ('ELC FROM WIND-ONSH') then pv else 0 end) "elec-gen_onw",
                sum(case when proc_set in ('elec-gen_chp') then pv else 0 end) "elec-gen_chp",
                sum(case when proc_set='ELC FROM COAL-COF' then pv else 0 end)+sum(case when proc_set='ELC FROM COAL RR' then pv else 0 end) "coal-unad",
-- Above was minus CCSRET but now this is not a subset of RR
                sum(case when proc_set='ELC FROM COALCOF CCS' then pv else 0 end)+sum(case when proc_set='ELC FROM COAL CCSRET' then pv else 0 end) "coalccs-unad",
                sum(case when proc_set='ELC FROM GAS' then pv else 0 end)+sum(case when proc_set='ELC FROM GAS RR' then pv else 0 end) "gas-unad",
-- Above was minus CCSRET but now this is not a subset of RR
                sum(case when proc_set='ELC FROM GAS CCS' then pv else 0 end)+sum(case when proc_set='ELC FROM GAS CCSRET' then pv else 0 end) "gasccs-unad",
                sum(case when proc_set='ELC FROM OIL' then pv else 0 end) "ELC FROM OIL",
                sum(case when proc_set='ELC FROM OIL CCS' then pv else 0 end) "ELC FROM OIL CCS",
                sum(case when proc_set='ELC FROM MANFUELS' then pv else 0 end) "ELC FROM MANFUELS",
                sum(case when proc_set='ELC FROM BIO' then pv else 0 end) "ELC FROM BIO",
                sum(case when proc_set='ELC FROM BIO CCS' then pv else 0 end) "ELC FROM BIO CCS",
                sum(case when proc_set='elec-gen_waste-heat-penalty' then pv else 0 end) "elec-gen_waste-heat-penalty"
                from elc_prd_fuel a
                group by a.tablename, a.period
            ) a
            left join cofiring_fuel_percents b
            on a.tablename=b.tablename and a.period=b.period
            left join "elc-emis" c
            on a.tablename=c.tablename and a.period=c.period
            left join "elec_penalty" d
            on a.tablename=d.tablename and a.period=d.period
        ) c
    ) d
group by tablename,cols
ORDER BY tablename,analysis
) TO '%~dp0ElecGenOut.csv' delimiter ',' CSV;

-- **END OF End Electricity generation by source**

/* *Electricity storage by type* */
copy (
select analysis || '|' || tablename || '|' || attribute || '|' || '-|various'::varchar(300) "id", 
    analysis::varchar(50), tablename,attribute,commodity,'various'::varchar(50) "process",
        sum(pv)::numeric "all",
        sum(case when period='2010' then pv else 0 end)::numeric "2010",
        sum(case when period='2011' then pv else 0 end)::numeric "2011",
        sum(case when period='2012' then pv else 0 end)::numeric "2012",
        sum(case when period='2015' then pv else 0 end)::numeric "2015",
        sum(case when period='2020' then pv else 0 end)::numeric "2020",
        sum(case when period='2025' then pv else 0 end)::numeric "2025",
        sum(case when period='2030' then pv else 0 end)::numeric "2030",
        sum(case when period='2035' then pv else 0 end)::numeric "2035",
        sum(case when period='2040' then pv else 0 end)::numeric "2040",
        sum(case when period='2045' then pv else 0 end)::numeric "2045",
        sum(case when period='2050' then pv else 0 end)::numeric "2050",
        sum(case when period='2055' then pv else 0 end)::numeric "2055",
        sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
    select process,period,pv,
    'elec-stor-out_' ||
    case
        when process in('EHYDPMP00','EHYDPMP01') then 'hyd' --Filter 394
        when process in ('ECAESCON01','ESTGCAES01','ECAESTUR01','ESTGAACAES01') then 'caes' --Filter 395
        when process in ('ESTGBNAS01','ESTGBALA01','ESTGBRF01') then 'batt' --Filter 396
    end as "analysis", tablename, attribute,commodity
    from vedastore
    where attribute = 'VAR_FOut' and commodity='ELC'
) a
where analysis is not null
group by id,analysis,tablename,attribute,commodity
order by tablename, analysis
) to '%~dp0ElecStor.csv' delimiter ',' CSV;

/* *Electricity capacity by process* */
-- These figures should match those in the relevant UCL template tables (i.e. code replicates the XL formulae)
COPY (
select analysis || '|' || tablename || '|' || attribute || '|' || '-|various'::varchar(300) "id", analysis, tablename,attribute,
         '-'::varchar(50) "commodity",
        'various'::varchar(50) "process",
        sum(pv)::numeric "all",
        sum(case when period='2010' then pv else 0 end)::numeric "2010",
        sum(case when period='2011' then pv else 0 end)::numeric "2011",
        sum(case when period='2012' then pv else 0 end)::numeric "2012",
        sum(case when period='2015' then pv else 0 end)::numeric "2015",
        sum(case when period='2020' then pv else 0 end)::numeric "2020",
        sum(case when period='2025' then pv else 0 end)::numeric "2025",
        sum(case when period='2030' then pv else 0 end)::numeric "2030",
        sum(case when period='2035' then pv else 0 end)::numeric "2035",
        sum(case when period='2040' then pv else 0 end)::numeric "2040",
        sum(case when period='2045' then pv else 0 end)::numeric "2045",
        sum(case when period='2050' then pv else 0 end)::numeric "2050",
        sum(case when period='2055' then pv else 0 end)::numeric "2055",
        sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
    select process,
        period,pv,
        'elec-cap_' ||
        case
            when process in('ESTWWST00','EPOLWST00', 'EBIOS00','EBOG-LFE00','EBOG-SWE00',
                'EMSW00','EBIOCON00','ESTWWST01','EBIO01','EBOG-ADE01',
                'EBOG-LFE01','EBOG-SWE01','EMSW01') then 'bio' --Filter 100
            when process = 'EBIOQ01' then 'bio-ccs' --Filter 101
            when process in('ECOA00','ECOABIO00', 'ECOARR01') then 'coal' --Filter 102
            when process in('ECOAQ01' ,'ECOAQDEMO01') then 'coal-ccs' --Filter 103
            when process in('EHYGCCT01' ,'EHYGOCT01') then 'h2' --Filter 104
            when process in('ENGACCT00','ENGACCTRR01','ENGAOCT00','ENGAOCT01','ENGARCPE00','ENGARCPE01') then
                'nga' --Filter 105
            when process in('ENGACCTQ01','ENGACCTQDEMO01','ENGAQR01') then 'nga-ccs' --Filter 106
            when process in('ENUCPWR00','ENUCPWR101','ENUCPWR102') then
                'nuclear'  --Filter 107
            when process in('EWNDOFF00' ,'EWNDOFF101' ,'EWNDOFF201' ,'EWNDOFF301') then
                'offw' --Filter 108
            when process in('EWNDONS00','EWNDONS101','EWNDONS201','EWNDONS301','EWNDONS401','EWNDONS501',
                'EWNDONS601','EWNDONS701','EWNDONS801','EWNDONS901') then 'onw' --Filter 109
            when process ='EHFOIGCCQ01' then 'other-ccs' --Filter 110
            when process in('EOILL00','EOILL01','EMANOCT00','EMANOCT01','EOILS00','EOILS01','EHFOIGCC01','EDSTRCPE00','EDSTRCPE01') then
                'other-ff' --Filter 111
            when process in('EHYD00','EHYD01','EGEO01','ETIR101','ETIB101','ETIS101','EWAV101') then
                'other-rens' --Filter 112
            when process in('ESOL00','ESOLPV00','ESOL01','ESOLPV01') then 'solar' --Filter 113
            when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','ICHCHPCCGT01','ICHCHPCCGTH01',
                'ICHCHPCOA00','ICHCHPCOA01','ICHCHPFCH01','ICHCHPGT01','ICHCHPHFO00',
                'ICHCHPLFO00','ICHCHPLPG00','ICHCHPLPG01','ICHCHPNGA00','ICHCHPPRO00',
                'ICHCHPPRO01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01','IFDCHPCCGT01',
                'IFDCHPCCGTH01','IFDCHPCOA00','IFDCHPCOA01','IFDCHPFCH01','IFDCHPGT01',
                'IFDCHPHFO00','IFDCHPLFO00','IFDCHPNGA00','IISCHPBFG00','IISCHPBFG01',
                'IISCHPBIOG01','IISCHPBIOS01','IISCHPCCGT01','IISCHPCCGTH01','IISCHPCOG00',
                'IISCHPCOG01','IISCHPFCH01','IISCHPGT01','IISCHPHFO00','IISCHPNGA00',
                'INMCHPBIOG01','INMCHPBIOS01','INMCHPCCGT01','INMCHPCCGTH01','INMCHPCOA01',
                'INMCHPCOG00','INMCHPCOG01','INMCHPFCH01','INMCHPGT01','INMCHPNGA00',
                'IOICHPBIOG01','IOICHPBIOS00','IOICHPBIOS01','IOICHPCCGT01','IOICHPCCGTH01',
                'IOICHPCOA01','IOICHPFCH01','IOICHPGT01','IOICHPHFO00','IOICHPNGA00',
                'IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPCCGT01','IPPCHPCCGTH01',
                'IPPCHPCOA00','IPPCHPCOA01','IPPCHPFCH01','IPPCHPGT01','IPPCHPNGA00',
                'IPPCHPWST00','IPPCHPWST01','PCHP-CCP00','PCHP-CCP01','RCHPEA-CCG00',
                'RCHPEA-CCG01','RCHPEA-CCH01','RCHPEA-FCH01','RCHPEA-STW01','RCHPNA-CCG01',
                'RCHPNA-CCH01','RCHPNA-FCH01','RCHPNA-STW01','RHEACHPRG01','RHEACHPRH01',
                'RHEACHPRW01','RHNACHPRG01','RHNACHPRH01','RHNACHPRW01','RCHPEA-EFW01','RCHPNA-EFW01',
                'SCHP-ADM01','SCHP-CCG00','SCHP-CCG01','SCHP-CCH01','SCHP-FCH01','SCHP-GES00','SCHP-GES01',
                'SCHP-STM01','SCHP-STW00','SCHP-STW01','SHHFCLRH01','SHLCHPRG01','SHLCHPRH01','SHLCHPRW01','SCHP-EFW01',
                'UCHP-CCG00','UCHP-CCG01') then 'chp' --Filter 114
            when process in('ELCIE00','ELCII00','ELCIE01','ELCII01') then 'intercon' --Filter 115
            when process in('EHYDPMP00','EHYDPMP01') then 'hyd' --Filter 394
            when process in ('ECAESCON01','ESTGCAES01','ECAESTUR01','ESTGAACAES01') then 'caes' --Filter 395
            when process in ('ESTGBNAS01','ESTGBALA01','ESTGBRF01') then 'batt' --Filter 396
        end::varchar(50) as "analysis",
    tablename, attribute
    from vedastore
    where attribute = 'VAR_Cap' and commodity = '-'
) a
where analysis is not null
group by id, analysis,tablename, attribute
order by tablename,  analysis, attribute, commodity
) TO '%~dp0ElecCap.csv' delimiter ',' CSV;

/* *costs by sector and type* */
-- NB Have left as wildcard filters because a) are start of process, no matches to middle (i.e. main sectors in UKTM-
-- Also, would be a huge no of processes if made explicit- Checked whether there's any speed increase from using
-- substring functions like "left()" cf "like" and wildcards- Identical results for one letter, left is slower for
-- multiple letters like left(process,3)='IMP'

COPY (
select analysis || '|' || tablename ||'|'|| attribute || '|various' || '|various'::varchar(300) "id", analysis, tablename,attribute,
    'various'::varchar(50) "commodity",
    'various'::varchar(50) "process",
    sum(pv)::numeric "various",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
    select process,
        period,pv,
        case
            when process like 'T%' then 'costs_tra' --Filter 116
            when process like 'A%' then 'costs_agr' --Filter 117
            when process like 'E%' AND process not like 'EXP%' then 'costs_elc' --Filter 118
            when process like 'I%' AND process not like 'IMP%' then 'costs_ind' --Filter 119
            when process like 'P%' or process like 'C%' then 'costs_prc' --Filter 120
            when process like 'R%' then 'costs_res' --Filter 121
            when process like any(array['M%','U%','IMP%','EXP%']) then 'costs_rsr' --Filter 122
            when process like 'S%' then 'costs_ser' --Filter 123
            else 'costs_other'
        end::varchar(50) as "analysis",tablename, attribute
    from vedastore
    where attribute in('Cost_Act', 'Cost_Flo', 'Cost_Fom', 'Cost_Inv', 'Cost_Salv') --Filter 217
    union all
    select 'various'::varchar(50) "process",
        period,pv,
        'costs_all'::varchar(50) "analysis",
        tablename,
        attribute
    from vedastore
    where attribute in('Cost_Act','Cost_Flo','Cost_Fom','Cost_Inv','Cost_Salv','ObjZ') --Filter 124
) a
group by id, analysis, tablename, attribute
order by tablename,  analysis, attribute
 ) TO '%~dp0CostsBySec.csv' delimiter ',' CSV;

/* *Marginal prices for emissions* */
-- Note that the "all" column is left blank since it doesn't make sense to sum the marginal prices- Could substitute an average or similar if required
COPY (
select 'marg-price|' || tablename || '|EQ_CombalM|' || commodity || '|-'::varchar(300) "id",
        'marg-price'::varchar(50) "analysis",
        tablename,
        'EQ_CombalM'::varchar(50) "attribute",
        commodity,
        '-'::varchar(50) "process",
        NULL::numeric "all",
        sum(case when period='2010' then pv else 0 end)::numeric "2010",
        sum(case when period='2011' then pv else 0 end)::numeric "2011",
        sum(case when period='2012' then pv else 0 end)::numeric "2012",
        sum(case when period='2015' then pv else 0 end)::numeric "2015",
        sum(case when period='2020' then pv else 0 end)::numeric "2020",
        sum(case when period='2025' then pv else 0 end)::numeric "2025",
        sum(case when period='2030' then pv else 0 end)::numeric "2030",
        sum(case when period='2035' then pv else 0 end)::numeric "2035",
        sum(case when period='2040' then pv else 0 end)::numeric "2040",
        sum(case when period='2045' then pv else 0 end)::numeric "2045",
        sum(case when period='2050' then pv else 0 end)::numeric "2050",
        sum(case when period='2055' then pv else 0 end)::numeric "2055",
        sum(case when period='2060' then pv else 0 end)::numeric "2060"
from vedastore
where attribute='EQ_CombalM' and commodity in('GHG-NO-IAS-YES-LULUCF-NET','GHG-NO-AS-YES-LULUCF-NET',
    'GHG-ETS-NO-IAS-NET','GHG-YES-IAS-YES-LULUCF-NET','GHG-ETS-YES-IAS-NET') --Filter 125
group by tablename, commodity
order by tablename, commodity
 ) TO '%~dp0MarginalPricesOut.csv' delimiter ',' CSV;

/* *Whole stock heat output by process for residential* */

COPY (
select analysis || '|' || tablename || '|' || attribute || '|' || 'various|various'::varchar(300) "id", analysis::varchar(50), tablename,attribute,
    'various'::varchar(50) "commodity",
    'various'::varchar(50) "process",
    sum(pv)::numeric "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
    select process,
        period,pv,
        'heat-res_' ||
        case
            when process in ('RHEABLCRP01','RHEABLRRW00','RHEABLRRW01','RHEABLSRP01','RHEABLSRW01',
                'RHNABLCRP01','RHNABLRRW01','RHNABLSRP01','RHNABLSRW01') then 'boiler-bio' --Filter 126
            when process in('RHEABLCRH01','RHEABLSRH01','RHNABLCRH01','RHNABLSRH01') then 'boiler-h2' --Filter 127
            when process in('RHEABLCRO00','RHEABLCRO01','RHEABLRRC00','RHEABLRRO00','RHEABLSRO01','RHNABLCRO01'
                ,'RHNABLSRO01') then 'boiler-otherFF' --Filter 128
            when process in('RHEABLRRE00','RHEABLRRE01','RHEABLSRE01','RHEASHTRE00',
                'RHEASHTRE01','RHNABLRRE01','RHNABLSRE01','RHNAGHPUE01','RHNASHTRE01',
                'RWEAWHTRE00','RWEAWHTRE01','RWNAWHTRE01') then 'boiler/heater-elec' --Filter 415
            when process in('RHEABLCRG00','RHEABLCRG01',
                'RHEABLRRG00','RHEABLSRG01','RHEASHTRG00','RHEASHTRG01','RHNABLCRG01',
                'RHNABLSRG01','RHNASHTRG01','RWEAWHTRG00','RWEAWHTRG01','RWNAWHTRG01') then
                    'boiler/heater-nga' --Filter 130
            when process='RHEACSVCAV01' then 'easy-cav' --Filter 397
            when process='RHEACSVCAV02' then 'hard-cav' --Filter 398
            when process='RHEACSVSOL01' then 'solid-sysbld' --Filter 399
            when process in('RHEACSVLOF01','RHEACSVFLR01',
                'RHEACSVWIN01','RHEACSVFLU01','RHEACSVDFT01','RHEACSVCON01','RHEACSVCYL01') then
                    'other-conserv' --Filter 131
            when process in('RHEADHP100','RHEADHP101','RHEADHP201','RHEADHP301','RHEADHP401',
                'RHNADHP101','RHNADHP201','RHNADHP301','RHNADHP401') then 'dh' --Filter 132
            when process in('RHEAAHPRE00','RHEAAHPRE01','RHEAAHPUE01','RHEAAHSRE01', 'RHEAAHSUE01',
                'RHEAGHPRE01','RHEAGHPUE01','RHEAGHSRE01','RHEAGHSUE01','RHNAAHPRE01','RHNAAHPUE01',
                'RHNAAHSRE01','RHNAAHSUE01','RHNAGHPRE01','RHNAGHSRE01','RHNAGHSUE01') then 
                    'heatpump-elec' --Filter 133
            when process in('RHEAAHHRE01','RHEAAHHUE01',
                'RHEAGHHRE01','RHEAGHHUE01','RHNAAHHRE01','RHNAAHHUE01','RHNAGHHRE01','RHNAGHHUE01') then
                    'hyb-boil+hp-h2' --Filter 134
            when process in('RHEAAHBRE01','RHEAAHBUE01',
                'RHEAGHBRE01','RHEAGHBUE01','RHNAAHBRE01','RHNAAHBUE01','RHNAGHBRE01','RHNAGHBUE01') then
                'hyb-boil+hp-nga'  --Filter 135
            when process in('RHEACHPRW01','RHNACHPRW01') then 'microchp-bio' --Filter 136
            when process in('RHEACHBRH01','RHEACHPRH01',
                'RHNACHBRH01','RHNACHPRH01') then 'microchp-h2'  --Filter 137
            when process in('RHEACHPRG01','RHNACHPRG01') then 'microchp-nga'  --Filter 138
            when process in('RHEANSTRE00','RHEANSTRE01','RHEASTGNT00','RHEASTGNT01',
                'RHNANSTRE01','RHNASTGNT01') then 'storheater-elec' --Filter 139
            else 'heat-res_other'
        end::varchar(50) as "analysis",
    tablename, attribute
    from vedastore
    where attribute = 'VAR_FOut' AND commodity in('RHCSV-RHEA','RHEATPIPE-EA','RHEATPIPE-NA','RHSTAND-EA',
        'RHSTAND-NA','RHUFLOOR-EA','RHUFLOOR-NA','RWCSV-RWEA','RWSTAND-EA','RWSTAND-NA') --Filter 140
    group by period,process, pv,tablename, id, analysis, attribute order by tablename, attribute
) a
group by id, analysis,tablename, attribute
order by tablename,  analysis, attribute, commodity
 ) TO '%~dp0ResWholeHeatOut.csv' delimiter ',' CSV;

/* *New build residential heat output by source* */
COPY (
select analysis || '|' || tablename || '|' || attribute || '|' || 'various|various'::varchar(300) "id", analysis::varchar(50), tablename,attribute,
    'various'::varchar(50) "commodity",
    'various'::varchar(50) "process",
    sum(pv)::numeric "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
    select process,commodity,
        period,pv,
        'new-heat-res_' ||
        case
            when process in('RHEABLCRP01','RHEABLRRW01','RHEABLSRP01',
                'RHEABLSRW01','RHNABLCRP01','RHNABLRRW01','RHNABLSRP01','RHNABLSRW01') then 'boiler-bio'  --Filter 141
            when process in('RHEABLCRH01','RHEABLSRH01','RHNABLCRH01','RHNABLSRH01') then 'boiler-h2' --Filter 127
            when process in('RHEABLCRO01','RHEABLSRO01','RHNABLCRO01','RHNABLSRO01') then 'boiler-otherFF'  --Filter 143
            when process in('RHEABLRRE01','RHEABLSRE01','RHEASHTRE01','RHNABLRRE01',
                'RHNABLSRE01','RHNAGHPUE01','RHNASHTRE01','RWEAWHTRE01','RWNAWHTRE01') 
                then 'boiler/heater-elec'    --Filter 144
            when process in('RHEABLCRG01','RHEABLSRG01','RHEASHTRG01','RHNABLCRG01','RHNABLSRG01','RHNASHTRG01'
                ,'RWEAWHTRG01','RWNAWHTRG01') then 'boiler/heater-nga'  --Filter 145
            when process='RHEACSVCAV01' then 'easy-cav' --Filter 397
            when process='RHEACSVCAV02' then 'hard-cav' --Filter 398
            when process='RHEACSVSOL01' then 'solid-sysbld' --Filter 399
            when process in('RHEACSVLOF01','RHEACSVFLR01',
                'RHEACSVWIN01','RHEACSVFLU01','RHEACSVDFT01','RHEACSVCON01','RHEACSVCYL01') then
                    'other-conserv' --Filter 131
            when process in('RHEADHP101','RHEADHP201','RHEADHP301','RHEADHP401',
                'RHNADHP101','RHNADHP201','RHNADHP301','RHNADHP401') then 'dh'  --Filter 147
            when process in('RHEAAHPRE01','RHEAAHPUE01','RHEAAHSRE01','RHEAAHSUE01','RHEAGHPRE01',
                'RHEAGHPUE01','RHEAGHSRE01','RHEAGHSUE01','RHNAAHPRE01','RHNAAHPUE01','RHNAAHSRE01',
                'RHNAAHSUE01','RHNAGHPRE01','RHNAGHSRE01','RHNAGHSUE01') then 'heatpump-elec' --Filter 148
            when process in('RHEAAHHRE01','RHEAAHHUE01',
                'RHEAGHHRE01','RHEAGHHUE01','RHNAAHHRE01','RHNAAHHUE01','RHNAGHHRE01','RHNAGHHUE01') then
                    'hyb-boil+hp-h2' --Filter 134
            when process in('RHEAAHBRE01','RHEAAHBUE01',
                'RHEAGHBRE01','RHEAGHBUE01','RHNAAHBRE01','RHNAAHBUE01','RHNAGHBRE01','RHNAGHBUE01') then
                'hyb-boil+hp-nga'  --Filter 135
            when process in('RHEACHPRW01','RHNACHPRW01') then 'microchp-bio' --Filter 136
            when process in('RHEACHBRH01','RHEACHPRH01',
                'RHNACHBRH01','RHNACHPRH01') then 'microchp-h2'  --Filter 137
            when process in('RHEACHPRG01','RHNACHPRG01') then 'microchp-nga'  --Filter 138
            when process in('RHEANSTRE01','RHEASTGNT01','RHNANSTRE01','RHNASTGNT01') then 'storheater-elec' --Filter 153
        end as "analysis",
    tablename, attribute
    from vedastore
    where attribute = 'VAR_FOut' AND commodity in('RHCSV-RHEA','RHEATPIPE-EA','RHEATPIPE-NA','RHSTAND-EA','RHSTAND-NA',
        'RHUFLOOR-EA','RHUFLOOR-NA','RWCSV-RWEA','RWSTAND-EA','RWSTAND-NA') and vintage=period  --Filter 154
    group by period,commodity,process, pv,tablename, id, analysis, attribute order by tablename, attribute
) a where analysis <> ''
group by id, analysis,tablename, attribute
order by tablename,  analysis, attribute, commodity
 ) TO '%~dp0NewResHeatOut.csv' delimiter ',' CSV;

/* *Whole stock heat output for services* */
-- List of technology groupings (hvac ones are not in residential)
--NEEDS UPDATING following Nov 2016 work
-- SER_Heat_Elec_Boiler_or_Heater(inc_SolarTherm)        'heat-ser_boiler/heater-elec'
-- SER_Heat_NGA_Boiler_or_Heater(inc_SolarTherm)        'heat-ser_boiler/heater-nga'
-- SER_Heat_Bio-Boiler                                    'heat-ser_boiler-bio'
-- SER_Heat_Hydrogen_Boiler                            'heat-ser_boiler-h2'
-- SER_Heat_Other_FF_Boiler                            'heat-ser_boiler-otherFF'
-- SER_Heat_Conservation                                'heat-ser_conserv'
-- SER_Heat_Hybrid_Heat_Pump_NGA_Boiler                'heat-ser_dh'
-- SER_Heat_Heat_Pump                                    'heat-ser_heatpump-elec'
-- SER_Heat_hvac                                        'heat-ser_hvac'
-- SER_Heat_hvac_advanced                                'heat-ser_hvac-ad'
-- SER_Heat_Hybrid_Heat_Pump_Hydrogen_Boiler            'heat-ser_hyb-boil+hp-h2'
-- SER_Heat_District-Heat                                'heat-ser_hyb-boil+hp-nga'
-- SER_Heat_Micro_CHP_Biomass                            'heat-ser_microchp-bio'
-- SER_Heat_Micro_CHP_Hydrogen                            'heat-ser_microchp-h2'
-- SER_Heat_Micro_CHP_NGA                                'heat-ser_microchp-nga'
-- SER_Heat_Elec_Storage_Heater                        'heat-ser_storheater-elec'

COPY (
select analysis || '|' || tablename || '|' || attribute || '|' || 'various|various'::varchar(300) "id", analysis, tablename,attribute,
    'various'::varchar(50) "commodity",
    'various'::varchar(50) "process",
    sum(pv)::numeric "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
    select process,
        period,pv,
        'heat-ser_' ||
        case
            when process in ('SHLSHTRE00','SWLWHTRE00','SHLBLRRE01','SHLSHTRE01',
                'SWLWHTRE01','SHLBLSRE01','SHHBLRRE00','SWHWHTRE00','SHHBLRRE01','SWHWHTRE01','SHLBLRRE00','SHH-BLRE01')
                    then 'boiler/heater-elec'  --Filter 155
            when process in('SHLBLCRG00','SHLSHTRG00','SWLWHTRG00','SHLBLCRG01','SWLWHTRG01',
                'SHLBLSRG01','SHHBLRRG00','SWHBLRRG00','SHHBLRRG01','SWHBLRRG01','SHLBLRRG00','SHH-BLRG01')
                    then 'boiler/heater-nga'  --Filter 156
            when process in('SHLBLCRP01','SHLBLRRW01','SHLBLSRP01','SHLBLSRW01','SHHBLRRW00',
                'SWHBLRRW00','SHHBLRRW01','SWHBLRRW01','SHLBLRRW00','SHH-BLRB01') 
                    then 'boiler-bio' --Filter 157
            when process in('SHLBLSRH01','SHHBLRRH01','SWHBLRRH01','SHLBLCRH01','SHH-BLRH01') 
                    then 'boiler-h2' --Filter 158
            when process in('SHLBLCRO00','SHLBLRRC00','SHLSHTRO00','SHLBLCRO01','SHLBLSRO01',
                'SHHBLRRO00','SHHBLRRC00','SWHBLRRO00','SWHBLRRC00','SHHBLRRO01','SHHBLRRC01',
                'SWHBLRRO01','SWHBLRRC01','SHLBLRRO00','SHH-BLRO01') 
                    then 'boiler-otherFF' --Filter 159
            when process in('SCSVSHL-METERS01','SCSVSHL-INSULAT01','SCSVSHL-GLAZING01','SCSVSHL-OTH_THM01',
                'SCSVSHL-VENT_RC01','SCSVSHH-METERS01','SCSVSHH-INSULAT01','SCSVSHH-GLAZING01','SCSVSHH-OTH_THM01',
                'SCSVSHH-VENT_RC01') then 'conserv'  --Filter 160
            when process in('SHLAHBUE01','SHLGHBRE01','SHLGHBUE01','SHLAHBRE01') then  'hyb-boil+hp-nga' --Filter 161
            when process in('SHLAHPRE01','SHLAHPUE01','SHLAHSRE01','SHLAHSUE01','SHLAHPRE00','SHH-ASHP01','SHH-ASHP-R01') 
                    then 'heatpump-air-elec' --Filter 162
            when process in ('SHLGHPRE01','SHLGHPUE01','SHLGHSRE01','SHLGHSUE01','SHH-GSHP-V01','SHH-GSHP-H01')
                    then 'heatpump-ground-elec' --Filter 222
            when process in('SHH-WSHP01') then 'heatpump-water-elec' --Filter 223
            when process in('SHHVACAE01','SHHVACAE00') then 'hvac' --Filter 163
            when process in('SHHVACAE02') then 'hvac-ad' --Filter 164
            when process in('SHLAHHUE01','SHLGHHRE01','SHLGHHUE01','SHLAHHRE01') then 'hyb-boil+hp-h2' --Filter 165
            when process in('SHLDHP101','SHHDHP100','SHHDHP101','SHLDHP100') then 'dh' --Filter 166
            when process in('SHLCHPRW01') then 'microchp-bio' --Filter 167
            when process in('SHLCHBRH01','SHHFCLRH01','SHLCHPRH01') then 'microchp-h2' --Filter 168
            when process in('SHLCHPRG01') then 'microchp-nga' --Filter 169
            when process in('SHLNSTRE01','SHLNSTRE00') then 'storheater-elec' --Filter 170
            when process in('SHH-DUM-PIP01') then 'dummy-process' --Filter 224
            else 'other'
        end as "analysis",
    tablename, attribute
    from vedastore
    where attribute = 'VAR_FOut' AND commodity in('SHHCSVDMD','SERHEAT','SHHDELVAIR','SHHDELVRAD',
        'SHLCSVDMD','SHLDELVAIR','SHLDELVRAD','SHLDELVUND','SWHDELVPIP','SWHDELVSTD','SWLDELVSTD') --Filter 171
    group by period,process, pv,tablename, id, analysis, attribute order by tablename, attribute
) a
group by id, analysis,tablename, attribute
order by tablename,  analysis, attribute, commodity
 ) TO '%~dp0ServWholeHeatOut.csv' delimiter ',' CSV;

/* *New build services heat output by source* */
COPY (
select analysis || '|' || tablename || '|' || attribute || '|' || 'various|various'::varchar(300) "id", analysis, tablename,attribute,
    'various'::varchar(50) "commodity",
    'various'::varchar(50) "process",
    sum(pv)::numeric "all",
    sum(case when period='2010' then pv else 0 end)::numeric "2010",
    sum(case when period='2011' then pv else 0 end)::numeric "2011",
    sum(case when period='2012' then pv else 0 end)::numeric "2012",
    sum(case when period='2015' then pv else 0 end)::numeric "2015",
    sum(case when period='2020' then pv else 0 end)::numeric "2020",
    sum(case when period='2025' then pv else 0 end)::numeric "2025",
    sum(case when period='2030' then pv else 0 end)::numeric "2030",
    sum(case when period='2035' then pv else 0 end)::numeric "2035",
    sum(case when period='2040' then pv else 0 end)::numeric "2040",
    sum(case when period='2045' then pv else 0 end)::numeric "2045",
    sum(case when period='2050' then pv else 0 end)::numeric "2050",
    sum(case when period='2055' then pv else 0 end)::numeric "2055",
    sum(case when period='2060' then pv else 0 end)::numeric "2060"
from (
    select process,
        period,pv,
        'new-heat-ser_' ||
        case
            when process in ('SHLBLRRE01','SHLSHTRE01','SWLWHTRE01','SHLBLSRE01','SHHBLRRE01','SWHWHTRE01')
                then 'boiler/heater-elec' --Filter 172
            when process in('SHLBLCRG01','SWLWHTRG01','SHLBLSRG01','SHHBLRRG01','SWHBLRRG01')
                then 'boiler/heater-nga' --Filter 173
            when process in('SHLBLCRP01','SHLBLRRW01','SHLBLSRP01','SHLBLSRW01','SHHBLRRW01','SWHBLRRW01')
                then 'boiler-bio' --Filter 174
            when process in('SHLBLSRH01','SHHBLRRH01','SWHBLRRH01','SHLBLCRH01') then 'boiler-h2' --Filter 175
            when process in('SHLBLCRO01','SHLBLSRO01','SHHBLRRO01','SHHBLRRC01','SWHBLRRO01','SWHBLRRC01')
                then 'boiler-otherFF' --Filter 176
            when process in('SCSLROFF01','SCSLROFP01','SCSLCAVW01','SCSHPTHM01','SCSHROFF01',
                'SCSHROFP01','SCSHCAVW01','SCSLPTHM01') then 'conserv' --Filter 177
            when process in('SHLAHBUE01','SHLGHBRE01','SHLGHBUE01','SHLAHBRE01') 
                then 'hyb-boil+hp-nga' --Filter 161
            when process in('SHLAHPRE01','SHLAHPUE01','SHLGHPRE01','SHLGHPUE01','SHLAHSRE01',
                'SHLAHSUE01','SHLGHSRE01','SHLGHSUE01') then 'heatpump-elec' --Filter 179
            when process in('SHHVACAE01') then 'hvac' --Filter 180
            when process in('SHHVACAE02') then 'hvac-ad' --Filter 164
            when process in('SHLAHHUE01','SHLGHHRE01','SHLGHHUE01','SHLAHHRE01') then 'hyb-boil+hp-h2' --Filter 165
            when process in('SHLDHP101','SHHDHP101') then 'dh' --Filter 183
            when process in('SHLCHPRW01') then 'microchp-bio' --Filter 167
            when process in('SHLCHBRH01','SHHFCLRH01','SHLCHPRH01') then 'microchp-h2' --Filter 168
            when process in('SHLCHPRG01') then 'microchp-nga' --Filter 169
            when process in('SHLNSTRE01') then 'storheater-elec' --Filter 187
            else 'new-other'
        end as "analysis",
    tablename, attribute
    from vedastore
    where attribute = 'VAR_FOut' AND commodity in('SHHCSVDMD','SHHDELVAIR','SHHDELVRAD',
        'SHLCSVDMD','SHLDELVAIR','SHLDELVRAD','SHLDELVUND','SWHDELVPIP','SWHDELVSTD','SWLDELVSTD') 
    and vintage=period --Filter 219
    group by period,process, pv,tablename, id, analysis, attribute order by tablename, attribute
) a
group by id, analysis,tablename, attribute
order by tablename,  analysis, attribute, commodity
) TO '%~dp0NewServHeatOut.csv' delimiter ',' CSV;

/* *End user final energy demand by sector* */
-- This table uses common table expressions- In postgres these can make the crosstab slower than other ways of implementing the query because
-- PG creates a temporary table for each one- But refactoring this code to make all the CTEs sub-selects actually made the query slower rather
-- than faster so have retained the original ver here [also easier to read]- Have tried to replicate the relevant Veda BE tables where possible-

-- NB includes FE for hydrogen production, fuel use for processing and for elec gen
-- Includes non-energy use of fuels in the industry chemicals sub-sector
COPY (
with hydrogen_chp as (
-- This is the Veda table of the same name with added tablename and with period in a single column
-- NB currently excludes existing average houses, def of "hydrogen boiler" might be wrong
    select chp_hyd,commodity, period,tablename,sum(pv) "pv"
    from (
        select case
            when process in ('RHEABLCRH01','RHEACHBRH01','RHFCBLCRH01','RHFCCHBRH01','RHFSBLCRH01','RHFSCHBRH01','RHHCBLCRH01'
                ,'RHHCCHBRH01','RHHSBLCRH01','RHHSCHBRH01','RHNABLCRH01','RHNACHBRH01') then 'RES BOI HYG' --Filter 228
            when process in ('RHFCCHPRH01','RHFSCHPRH01','RHHCCHPRH01','RHHSCHPRH01','RHNACHPRH01','RHEACHPRH01') then 'RES MCHP HYG' --Filter 328
            when process in ('RHEAREFCG01','RHFCREFCG01','RHFSREFCG01','RHHCREFCG01','RHHSREFCG01','RHNAREFCG01') then 'RES REFORMER' --Filter 315
            when process in ('SHHBLRRH01','SHLBLCRH01','SHLCHBRH01') then 'SER BOI HYG' --Filter 275
            when process in ('SHHFCLRH01','SHLCHPRH01') then 'SER MCHP HYG' --Filter 351
            when process in ('SHLREFCG01') then 'SER REFORMER' --Filter 342
            else null
        end as chp_hyd,
        tablename, commodity,pv,period from vedastore where attribute='VAR_FIn'
    ) a
    where chp_hyd is not null
    group by tablename, period, chp_hyd,commodity
)
,reformer_factors as(
-- This sub-query gives the correction factors which determine what proportion of h2 for chp comes from gas reformers
-- replicates the formulae in the UCL XL template (appears in both "Electricity generation in CHP plants" row 497ff and "Heat generation in CHP plants"
-- row 1004ff
     select period, tablename,
        case when res_chp_reformer_h2+res_chp_mains_h2>0 then res_chp_reformer_h2/(res_chp_reformer_h2+res_chp_mains_h2) else 0 end chp_gas_for_h_res_mult,
        -- i.e. the multiplier for res h for elec gen
        case when ser_chp_reformer_h2+ser_chp_mains_h2>0 then ser_chp_reformer_h2/(ser_chp_reformer_h2+ser_chp_mains_h2) else 0 end chp_gas_for_h_ser_mult
        -- i.e. the multiplier for ser h for elec gen
    from (
-- Items here relate to veda table "Hydrogen_CHP" but it's not the same because that has a commodity col, and some items there are not here-
        select
            sum(case when chp_hyd='RES MCHP HYG' and commodity='RESHOUSEHYG' then pv else 0 end) res_chp_mains_h2,  --Filter 189
-- residential hydrogen from network in CHP; NB doesn't exist in equivalent Veda table in XL [is in tbl def]- Part of hydrogen_chp q entity
            sum(case when chp_hyd='RES MCHP HYG' and commodity in('RESHYGREF-FC','RESHYGREF-FS',
                'RESHYGREF-HC','RESHYGREF-HS','RESHYGREF-NA') then pv else 0 end) res_chp_reformer_h2,  --Filter 190
-- residential hydrogen from reformer in CHP; NB doesn't exist in equivalent Veda table in XL [is in tbl def]- Part of hydrogen_chp q entity
            sum(case when chp_hyd='SER MCHP HYG' and commodity ='SERHYGREF' then pv else 0 end) ser_chp_reformer_h2,  --Filter 191
-- services hydrogen from reformer in CHP- Part of hydrogen_chp q entity
            sum(case when chp_hyd='SER MCHP HYG' and commodity in('SERBUILDHYG','SERMAINSHYG') then pv else 0 end) ser_chp_mains_h2 --Filter 192
-- services hydrogen from network in CHP- Part of hydrogen_chp q entity
            ,tablename,period
        from hydrogen_chp
        group by tablename,period
    ) a
)
, chp_fuels as (
-- chp fuel in- This is essentially the same as "CHP_fuels" Veda BE table, but with period as column instead of individual yr cols,
-- also addition of tablename- Not all fuels and sectors get used later, although do get assigned - only gas, bio and h2 for res and ser; several more fuels for ind
-- combination of chp_fuel_in + (a) of chp_fuels gives Veda table 'CHP_fuels' (this has all the fuels)
-- Incorporates change to include hydrogen generated by chp (from 2020 on in XLS)
-- This table creates the basic assignments to sector and fuel which are then used to derive the "main" chp fuel use table [below]
    select chp_sec, chp_fuel, period, tablename,sum(pv) "pv"
    from (
        select case
                when commodity in('AGRBIODST','AGRBIOLPG','AGRBOM','AGRGRASS','AGRMAINSBOM','AGRPOLWST','BGRASS','BIODST','BIODST-FT','BIOJET-FT','BIOKER-FT','BIOLFO'
                    ,'BIOLPG','BIOOIL','BOG-AD','BOG-G','BOG-LF','BOM','BPELH','BPELL','BRSEED','BSEWSLG','BSLURRY','BSTARCH'
                    ,'BSTWWST','BSUGAR','BTREATSTW','BTREATWOD','BVOIL','BWOD','BWODLOG','BWODWST','ELCBIOCOA','ELCBIOCOA2','ELCBIOLFO','ELCBIOOIL'
                    ,'ELCBOG-AD','ELCBOG-LF','ELCBOG-SW','ELCBOM','ELCMAINSBOM','ELCMSWINO','ELCMSWORG','ELCPELH','ELCPELL','ELCPOLWST','ELCSTWWST','ELCTRANSBOM'
                    ,'ETH','HYGBIOO','HYGBPEL','HYGMSWINO','HYGMSWORG','INDBIOLFO','INDBIOLPG','INDBIOOIL','INDBOG-AD','INDBOG-LF','INDBOM','INDGRASS'
                    ,'INDMAINSBOM','INDMSWINO','INDMSWORG','INDPELH','INDPELL','INDPOLWST','INDWOD','INDWODWST','METH','MSWBIO','MSWINO','MSWORG'
                    ,'PWASTEDUM','RESBIOLFO','RESBOM','RESHOUSEBOM','RESMAINSBOM','RESMSWINO','RESMSWORG','RESPELH','RESWOD','RESWODL','SERBIOLFO','SERBOG','SERBOM','SERBUILDBOM'
                    ,'SERMAINSBOM','SERMSWBIO','SERMSWINO','SERMSWORG','SERPELH','SERWOD','TRABIODST','TRABIODST-FT','TRABIODST-FTL','TRABIODST-FTS','TRABIODSTL','TRABIODSTS'
                    ,'TRABIOJET-FTDA','TRABIOJET-FTDAL','TRABIOJET-FTIA','TRABIOJET-FTIAL','TRABIOLFO','TRABIOLFODS','TRABIOLFODSL','TRABIOLFOL','TRABIOOILIS','TRABIOOILISL','TRABOM','TRAETH','TRAETHL','TRAETHS','TRAMAINSBOM','TRAMETH') then 'ALL BIO' --Filter 287
                when commodity in ('AGRCOA','COA','COA-E','COACOK','ELCCOA','HYGCOA','INDCOA','INDCOACOK','INDSYNCOA','PRCCOA','PRCCOACOK','RESCOA'
                    ,'SERCOA','SYNCOA','TRACOA') then 'ALL COALS' --Filter 246
-- NB excludes 'IISCOACOKB' for compatibility with VEDA
                when commodity in('AGRHYG','ELCHYG','ELCHYGIGCC','HYGL','HYGL-IGCC','HYGLHPD','HYGLHPT','HYL','HYLTK','INDHYG','INDMAINSHYG','RESHOUSEHYG'
                    ,'RESHYG','RESHYGREF-EA','RESHYGREF-NA','RESMAINSHYG','SERBUILDHYG','SERHYG','SERMAINSHYG','TRAHYG','TRAHYGDCN','TRAHYGL','TRAHYGS','TRAHYL'
                    ,'UPSHYG','UPSMAINSHYG') then 'ALL HYDROGEN' --Filter 371
                when commodity in ('BENZ','BFG','COG','COK','ELCBFG','ELCCOG','IISBFGB','IISBFGC','IISCOGB','IISCOGC','IISCOKB','IISCOKE'
                    ,'IISCOKS','INDBENZ','INDBFG','INDCOG','INDCOK','RESCOK') then 'ALL MANFUELS' --Filter 330
                when commodity in ('AGRHFO','AGRLFO','AGRLPG','ELCHFO','ELCLFO','ELCLPG','ELCMSC','IISHFOB','INDHFO','INDKER','INDLFO','INDLPG'
                    ,'INDNEULFO','INDNEULPG','INDNEUMSC','INDSYNOIL','OILCRD','OILCRDRAW','OILCRDRAW-E','OILDST','OILHFO','OILJET','OILKER','OILLFO'
                    ,'OILLPG','OILMSC','OILPET','PRCHFO','PRCOILCRD','RESKER','RESLFO','RESLPG','SERHFO','SERKER','SERLFO','SERLPG'
                    ,'SYNOIL','TRADST','TRADSTL','TRADSTS','TRAHFO','TRAHFODS','TRAHFODSL','TRAHFOIS','TRAHFOISL','TRAJETDA','TRAJETDAEL','TRAJETIA'
                    ,'TRAJETIAEL','TRAJETIANL','TRAJETL','TRALFO','TRALFODS','TRALFODSL','TRALFOL','TRALPG','TRALPGL','TRALPGS','TRAPET','TRAPETL'
                    ,'TRAPETS','UPSLFO') then 'ALL OIL PRODUCTS' --Filter 302
                when commodity in('INDMAINSGAS','INDNGA') then 'IND GAS' --Filter 313
                when commodity in('ICHPRO') then 'IND PRO' --Filter 252
                when commodity in('PRCNGA') then 'PRC GAS' --Filter 353
                when commodity in('PREFGAS') then 'PRC REFGAS' --Filter 308
                when commodity in('RESMAINSGAS','RESNGA') then 'RES GAS' --Filter 320
                when commodity in('SERMAINSGAS','SERNGA') then 'SER GAS' --Filter 277
                when commodity in('UPSNGA') then 'UPS GAS' --Filter 289
            else null
        end as chp_fuel,
        case
            when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','ICHCHPCCGT01','ICHCHPCCGTH01','ICHCHPCOA00','ICHCHPCOA01','ICHCHPFCH01','ICHCHPGT01','ICHCHPHFO00','ICHCHPLFO00','ICHCHPLPG00'
                ,'ICHCHPLPG01','ICHCHPNGA00','ICHCHPPRO00','ICHCHPPRO01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01','IFDCHPCCGT01','IFDCHPCCGTH01','IFDCHPCOA00','IFDCHPCOA01','IFDCHPFCH01'
                ,'IFDCHPGT01','IFDCHPHFO00','IFDCHPLFO00','IFDCHPNGA00','IISCHPBFG00','IISCHPBFG01','IISCHPBIOG01','IISCHPBIOS01','IISCHPCCGT01','IISCHPCCGTH01','IISCHPCOG00','IISCHPCOG01'
                ,'IISCHPFCH01','IISCHPGT01','IISCHPHFO00','IISCHPNGA00','INMCHPBIOG01','INMCHPBIOS01','INMCHPCCGT01','INMCHPCCGTH01','INMCHPCOA01','INMCHPCOG00','INMCHPCOG01','INMCHPFCH01'
                ,'INMCHPGT01','INMCHPNGA00','IOICHPBIOG01','IOICHPBIOS00','IOICHPBIOS01','IOICHPCCGT01','IOICHPCCGTH01','IOICHPCOA01','IOICHPFCH01','IOICHPGT01','IOICHPHFO00','IOICHPNGA00'
                ,'IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPCCGT01','IPPCHPCCGTH01','IPPCHPCOA00','IPPCHPCOA01','IPPCHPFCH01','IPPCHPGT01','IPPCHPNGA00','IPPCHPWST00','IPPCHPWST01'
                ) then 'CHP IND SECTOR' --Filter 270
            when process in('PCHP-CCP00','PCHP-CCP01') then 'CHP PRC SECTOR' --Filter 333
            when process in('RCHPEA-CCG00','RCHPEA-CCG01','RCHPEA-CCH01','RCHPEA-FCH01','RCHPEA-STW01','RCHPNA-CCG01','RCHPNA-CCH01','RCHPNA-FCH01','RCHPNA-STW01','RHEACHPRG01','RHEACHPRH01'
                ,'RHEACHPRW01','RHNACHPRG01','RHNACHPRH01','RHNACHPRW01','RCHPEA-EFW01','RCHPNA-EFW01') 
                then 'CHP RES SECTOR' --Filter 303
            when process in('SCHP-ADM01','SCHP-CCG00','SCHP-CCG01','SCHP-CCH01','SCHP-FCH01','SCHP-GES00','SCHP-GES01','SCHP-STM01','SCHP-STW00','SCHP-STW01','SHHFCLRH01','SHLCHPRG01'
                ,'SHLCHPRH01','SHLCHPRW01','SCHP-EFW01') then 'CHP SER SECTOR' --Filter 230
            when process in('UCHP-CCG00','UCHP-CCG01') then 'CHP UPS SECTOR' --Filter 337
            else null
        end as chp_sec,*
        from vedastore
        where attribute='VAR_FIn'
    ) a
    where chp_sec is not null and chp_fuel is not null
    group by tablename, period,chp_sec,chp_fuel
),
chp_fuels_used as (
-- This just renames entities above and adds a correction for gas used to create h2 in reformers-
-- Recreates the UCL XLS template formulae- See first table, "Fuel use in CHP plants" UCL template row 615, col bff
    select a.tablename,a.period,
        a.res_bio,
        a.res_gas+(case when b.chp_gas_for_h_res is null then 0 else b.chp_gas_for_h_res end) "res_gas",
        -- chp_gas_for_h_res is methane used to generate h2 via reformer
        a.res_hyd,
        a.ser_bio,
        a.ser_gas+(case when b.chp_gas_for_h_ser is null then 0 else b.chp_gas_for_h_ser end) "ser_gas",
        -- chp_gas_for_h_res is methane used to generate h2 via reformer
        a.ser_hyd,a.ind_bio,a.ind_gas,a.ind_hyd,a.ind_coa,a.ind_oil,a.ind_man,a.ind_bypro,a.prc_gas,
    a.prc_refgas,a.prc_oil, ups_gas
    from(
        select tablename,period,
            sum(case when chp_sec='CHP RES SECTOR' and chp_fuel='ALL BIO' then pv else 0 end) "res_bio",
            sum(case when chp_sec='CHP RES SECTOR' and chp_fuel='RES GAS' then pv else 0 end) "res_gas",
            sum(case when chp_sec='CHP RES SECTOR' and chp_fuel='ALL HYDROGEN' then pv else 0 end) "res_hyd",
            sum(case when chp_sec='CHP SER SECTOR' and chp_fuel='ALL BIO' then pv else 0 end) "ser_bio",
            sum(case when chp_sec='CHP SER SECTOR' and chp_fuel='SER GAS' then pv else 0 end) "ser_gas",
            sum(case when chp_sec='CHP SER SECTOR' and chp_fuel='ALL HYDROGEN' then pv else 0 end) "ser_hyd",
            sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL BIO' then pv else 0 end) "ind_bio",
            sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='IND GAS' then pv else 0 end) "ind_gas",
            sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL HYDROGEN' then pv else 0 end) "ind_hyd",
            sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL COALS' then pv else 0 end) "ind_coa",
            sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL OIL PRODUCTS' then pv else 0 end) "ind_oil",
            sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='ALL MANFUELS' then pv else 0 end) "ind_man",
            sum(case when chp_sec='CHP IND SECTOR' and chp_fuel='IND PRO' then pv else 0 end) "ind_bypro",
            sum(case when chp_sec='CHP PRC SECTOR' and chp_fuel='PRC GAS' then pv else 0 end) "prc_gas",
            sum(case when chp_sec='CHP PRC SECTOR' and chp_fuel='PRC REFGAS' then pv else 0 end) "prc_refgas",
            sum(case when chp_sec='CHP PRC SECTOR' and chp_fuel='ALL OIL PRODUCTS' then pv else 0 end) "prc_oil",
            sum(case when chp_sec='CHP UPS SECTOR' and chp_fuel='UPS GAS' then pv else 0 end) "ups_gas"
        from chp_fuels
        group by tablename,period
    ) a left join
-- Following is replicating the UCL XLS template which apportions h2 use between chp and other, and estimates how much comes from methane reformer
    (
        select tablename,period,
        case when res_chp_reformer_h2+res_boi_reformer_h2>0 then res_reformer*res_chp_reformer_h2/(res_chp_reformer_h2+res_boi_reformer_h2) else 0 end chp_gas_for_h_res,
        case when ser_chp_reformer_h2+ser_boi_reformer_h2>0 then ser_reformer*ser_chp_reformer_h2/(ser_chp_reformer_h2+ser_boi_reformer_h2) else 0 end chp_gas_for_h_ser from
        (
-- Following required because the hydrogen_chp table is split by commodity:
        select
            sum(case when chp_hyd='RES BOI HYG' and commodity in('RESHYGREF-FC','RESHYGREF-FS',
                'RESHYGREF-HC','RESHYGREF-HS','RESHYGREF-NA') then pv else 0 end) res_boi_reformer_h2,  --Filter 193
--                 i.e. only part of hydrogen boilers; bit which is from reformers
            sum(case when chp_hyd='RES MCHP HYG' and commodity in('RESHYGREF-FC','RESHYGREF-FS',
                'RESHYGREF-HC','RESHYGREF-HS','RESHYGREF-NA') then pv else 0 end) res_chp_reformer_h2,  --Filter 190
--                 i.e. only part of hydrogen chp; bit which is from reformers
            sum(case when chp_hyd='RES REFORMER' then pv else 0 end) res_reformer,  --Filter 195
--                    i.e. same as hydrogen_chp q but summed across commodities
            sum(case when chp_hyd='SER BOI HYG' and commodity ='SERHYGREF' then pv else 0 end) ser_boi_reformer_h2, --Filter 196
--                 i.e. only part of hydrogen boilers; bit which is from reformers
            sum(case when chp_hyd='SER MCHP HYG' and commodity ='SERHYGREF' then pv else 0 end) ser_chp_reformer_h2,  --Filter 191
--                 i.e. only part of hydrogen chp; bit which is from reformers
            sum(case when chp_hyd='SER REFORMER' then pv else 0 end) ser_reformer --Filter 198
--                    i.e. same as hydrogen_chp q but summed across commodities
            ,tablename,period
        from hydrogen_chp
        group by tablename,period
        ) a
    ) b on a.period=b.period and a.tablename=b.tablename
)
, chp_heatgen as(
-- This is the Veda BE "CHP_heatgen" query- The only differences are that the periods are in a single column (cf separate cols across the top),
-- tablename is added and pv is a separate col
    select chp_sec, period,tablename,sum(pv) "pv"
        from (
            select
                case
                    when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01','IISCHPBIOG01','IISCHPBIOS01','INMCHPBIOG01','INMCHPBIOS01'
                        ,'IOICHPBIOG01','IOICHPBIOS00','IOICHPBIOS01','IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPWST00','IPPCHPWST01') then 'CHP IND BIO' --Filter 336
                    when process in('ICHCHPPRO00','ICHCHPPRO01') then 'CHP IND BY PRODUCTS' --Filter 260
                    when process in('ICHCHPCOA00','ICHCHPCOA01','IFDCHPCOA00','IFDCHPCOA01','INMCHPCOA01','IOICHPCOA01','IPPCHPCOA00','IPPCHPCOA01') then 'CHP IND COAL' --Filter 343
                    when process in('ICHCHPCCGT01','ICHCHPGT01','ICHCHPNGA00','IFDCHPCCGT01','IFDCHPGT01','IFDCHPNGA00','IISCHPCCGT01','IISCHPGT01','IISCHPNGA00','INMCHPCCGT01'
                        ,'INMCHPGT01','INMCHPNGA00','IOICHPCCGT01','IOICHPGT01','IOICHPNGA00','IPPCHPCCGT01','IPPCHPGT01','IPPCHPNGA00') then 'CHP IND GAS' --Filter 385
                    when process in('ICHCHPCCGTH01','ICHCHPFCH01','IFDCHPCCGTH01','IFDCHPFCH01','IISCHPCCGTH01','IISCHPFCH01','INMCHPCCGTH01','INMCHPFCH01','IOICHPCCGTH01'
                        ,'IOICHPFCH01','IPPCHPCCGTH01','IPPCHPFCH01') then 'CHP IND HYDROGEN' --Filter 279
                    when process in('IISCHPBFG00','IISCHPBFG01','IISCHPCOG00','IISCHPCOG01','INMCHPCOG00','INMCHPCOG01') then 'CHP IND MAN FUELS' --Filter 265
                    when process in('ICHCHPHFO00','ICHCHPLFO00','ICHCHPLPG00','ICHCHPLPG01','IFDCHPHFO00','IFDCHPLFO00','IISCHPHFO00','IOICHPHFO00') then 'CHP IND OIL PRODUCTS' --Filter 286
                    when process in('PCHP-CCP00','PCHP-CCP01') then 'CHP PRC SECTOR' --Filter 333
                    when process in('RCHPEA-STW01','RCHPNA-STW01','RHEACHPRW01','RHNACHPRW01','RCHPEA-EFW01','RCHPNA-EFW01') then 'CHP RES BIO' --Filter 335
                    when process in('RCHPEA-CCG00','RCHPEA-CCG01','RCHPNA-CCG01','RHEACHPRG01','RHNACHPRG01') then 'CHP RES GAS' --Filter 271
                    when process in('RCHPEA-CCH01','RCHPEA-FCH01','RCHPNA-CCH01','RCHPNA-FCH01','RHEACHPRH01','RHNACHPRH01') then 'CHP RES HYDROGEN' --Filter 316
                    when process in('SCHP-ADM01','SCHP-GES00','SCHP-GES01','SCHP-STM01','SCHP-STW00','SCHP-STW01','SHLCHPRW01','SCHP-EFW01') then 'CHP SER BIO' --Filter 368
                    when process in('SCHP-CCG00','SCHP-CCG01','SHLCHPRG01') then 'CHP SER GAS' --Filter 255
                    when process in('SCHP-CCH01','SCHP-FCH01','SHHFCLRH01','SHLCHPRH01') then 'CHP SER HYDROGEN' --Filter 344
                    when process in('UCHP-CCG00','UCHP-CCG01') then 'CHP UPS SECTOR' --Filter 337
            end as chp_sec, * from vedastore
            where attribute='VAR_FOut' and commodity in ('ICHSTM','IFDSTM','IISLTH','INMSTM','IOISTM','IPPLTH','PCHPHEAT','RESLTH-NA','RHEATPIPE-NA',
                'SERLTH','SHLDELVRAD','SHHDELVRAD','UPSHEAT','RESLTH-FC','RESLTH-FS','RESLTH-HC','RESLTH-HS','RHEATPIPE-FC',
                'RHEATPIPE-FS','RHEATPIPE-HC','RHEATPIPE-HS') --Filter 199
        ) a
    where chp_sec is not null is not null
    group by tablename, period,chp_sec order by chp_sec
)
, process_fuel_pcs as (
    select tablename, period,
        sum(case when (prc_gas+prc_refgas+prc_oil)=0 then 0 else prc_gas/(prc_gas+prc_refgas+prc_oil) end) "prc_gas_pc",
        sum(case when (prc_gas+prc_refgas+prc_oil)=0 then 0 else prc_refgas/(prc_gas+ prc_refgas+ prc_oil) end) "prc_refgas_pc",
        sum(case when (prc_gas+prc_refgas+prc_oil)=0 then 0 else prc_oil/(prc_gas+ prc_refgas+ prc_oil) end) "prc_oil_pc"
    from chp_fuels_used
    group by tablename, period
)
,chp_heat as(
-- Replicates the UCL template calcs- See formulae in c1006ff
    select
        a.tablename,a.period,
        a.res_bio,
        a.res_gas+a.res_hyd*(case when b.chp_gas_for_h_res_mult is null then 0 else b.chp_gas_for_h_res_mult end) res_gas,
    -- i.e. add fraction of h2 used in res which is generated from methane
        a.res_hyd*(1-(case when b.chp_gas_for_h_res_mult is null then 0 else b.chp_gas_for_h_res_mult end)) res_hyd,
    -- i.e. subtract the fraction of h2 used in res which is generated from methane
        a.ser_bio,
    -- [below] see notes on res above
        a.ser_gas+a.ser_hyd*(case when b.chp_gas_for_h_ser_mult is null then 0 else b.chp_gas_for_h_ser_mult end) ser_gas,
        a.ser_hyd*(1-(case when b.chp_gas_for_h_ser_mult is null then 0 else b.chp_gas_for_h_ser_mult end)) ser_hyd,
        a.ind_bio,a.ind_gas,a.ind_hyd,a.ind_coa,a.ind_oil,a.ind_man,a.ind_bypro,a.ups_gas,
        a.prc_heat*c.prc_gas_pc "prc_gas",a.prc_heat*c.prc_refgas_pc "prc_refgas", a.prc_heat*c.prc_oil_pc "prc_oil"
    from (
            select
            sum(case when chp_sec='CHP RES BIO' then pv else 0 end) res_bio
            ,sum(case when chp_sec='CHP RES GAS' then pv else 0 end) res_gas
            ,sum(case when chp_sec='CHP RES HYDROGEN' then pv else 0 end) res_hyd
            ,sum(case when chp_sec='CHP SER BIO' then pv else 0 end) ser_bio
            ,sum(case when chp_sec='CHP SER GAS' then pv else 0 end) ser_gas
            ,sum(case when chp_sec='CHP SER HYDROGEN' then pv else 0 end) ser_hyd
            ,sum(case when chp_sec='CHP IND BIO' then pv else 0 end) ind_bio
            ,sum(case when chp_sec='CHP IND GAS' then pv else 0 end) ind_gas
            ,sum(case when chp_sec='CHP IND HYDROGEN' then pv else 0 end) ind_hyd
            ,sum(case when chp_sec='CHP IND COAL' then pv else 0 end) ind_coa
            ,sum(case when chp_sec='CHP IND OIL PRODUCTS' then pv else 0 end) ind_oil
            ,sum(case when chp_sec='CHP IND MAN FUELS' then pv else 0 end) ind_man
            ,sum(case when chp_sec='CHP IND BY PRODUCTS' then pv else 0 end) ind_bypro
            ,sum(case when chp_sec='CHP UPS SECTOR' then pv else 0 end) ups_gas
            ,sum(case when chp_sec='CHP PRC SECTOR' then pv else 0 end) prc_heat
            ,period,tablename
            from chp_heatgen
            group by period,tablename
        )a
    left join reformer_factors b
    on a.period=b.period and a.tablename=b.tablename
    left join process_fuel_pcs c
    on a.period=c.period and a.tablename=c.tablename
)
, chp_elcgen as (
-- This is the same as the Veda BE table with period in one col and tablename added
    select tablename, chp_sec, period, sum(pv) "pv"
    from (
        select tablename, period, pv,
        case
            when process in('ICHCHPBIOG01','ICHCHPBIOS00','ICHCHPBIOS01','IFDCHPBIOG01','IFDCHPBIOS00','IFDCHPBIOS01','IISCHPBIOG01','IISCHPBIOS01','INMCHPBIOG01','INMCHPBIOS01','IOICHPBIOG01'
                ,'IOICHPBIOS00','IOICHPBIOS01','IPPCHPBIOG01','IPPCHPBIOS00','IPPCHPBIOS01','IPPCHPWST00','IPPCHPWST01') then 'CHP IND BIO' --Filter 336
            when process in('ICHCHPPRO00','ICHCHPPRO01') then 'CHP IND BY PRODUCTS' --Filter 260
            when process in('ICHCHPCOA00','ICHCHPCOA01','IFDCHPCOA00','IFDCHPCOA01','INMCHPCOA01','IOICHPCOA01','IPPCHPCOA00','IPPCHPCOA01') then 'CHP IND COAL' --Filter 343
            when process in('ICHCHPCCGT01','ICHCHPGT01','ICHCHPNGA00','IFDCHPCCGT01','IFDCHPGT01','IFDCHPNGA00','IISCHPCCGT01','IISCHPGT01','IISCHPNGA00','INMCHPCCGT01'
                ,'INMCHPGT01','INMCHPNGA00','IOICHPCCGT01','IOICHPGT01','IOICHPNGA00','IPPCHPCCGT01','IPPCHPGT01','IPPCHPNGA00') then 'CHP IND GAS' --Filter 385
            when process in('ICHCHPCCGTH01','ICHCHPFCH01','IFDCHPCCGTH01','IFDCHPFCH01','IISCHPCCGTH01','IISCHPFCH01','INMCHPCCGTH01','INMCHPFCH01','IOICHPCCGTH01','IOICHPFCH01'
                ,'IPPCHPCCGTH01','IPPCHPFCH01') then 'CHP IND HYDROGEN' --Filter 279
            when process in('IISCHPBFG00','IISCHPBFG01','IISCHPCOG00','IISCHPCOG01','INMCHPCOG00','INMCHPCOG01') then 'CHP IND MAN FUELS' --Filter 265
            when process in('ICHCHPHFO00','ICHCHPLFO00','ICHCHPLPG00','ICHCHPLPG01','IFDCHPHFO00','IFDCHPLFO00','IISCHPHFO00','IOICHPHFO00') then 'CHP IND OIL PRODUCTS' --Filter 286
            when process in('PCHP-CCP00','PCHP-CCP01') then 'CHP PRC SECTOR' --Filter 333
            when process in('RCHPEA-STW01','RCHPNA-STW01','RHEACHPRW01','RHNACHPRW01','RCHPEA-EFW01','RCHPNA-EFW01') then 'CHP RES BIO' --Filter 335
            when process in('RCHPEA-CCG00','RCHPEA-CCG01','RCHPNA-CCG01','RHEACHPRG01','RHNACHPRG01') then 'CHP RES GAS' --Filter 271
            when process in('RCHPEA-CCH01','RCHPEA-FCH01','RCHPNA-CCH01','RCHPNA-FCH01','RHEACHPRH01','RHNACHPRH01') then 'CHP RES HYDROGEN' --Filter 316
            when process in('SCHP-ADM01','SCHP-GES00','SCHP-GES01','SCHP-STM01','SCHP-STW00','SCHP-STW01','SHLCHPRW01','SCHP-EFW01') then 'CHP SER BIO' --Filter 368
            when process in('SCHP-CCG00','SCHP-CCG01','SHLCHPRG01') then 'CHP SER GAS' --Filter 255
            when process in('SCHP-CCH01','SCHP-FCH01','SHHFCLRH01','SHLCHPRH01') then 'CHP SER HYDROGEN' --Filter 344
            when process in('UCHP-CCG00','UCHP-CCG01') then 'CHP UPS SECTOR' --Filter 337
        end as chp_sec
        from vedastore
        where attribute='VAR_FOut' and commodity in('ELCGEN','INDELC','RESELC','RESHOUSEELC','SERBUILDELC','SERDISTELC','SERELC') --Filter 215
    ) a
    where chp_sec is not null
    group by tablename, chp_sec, period
)
, chp_elc as (
-- chp elc out- Replicates formulae in UCL template table "Electricity generation in CHP plants" b499 ff- & renames entities from Veda BE base table
-- Incorporates change to include hydrogen generated by chp (from 2020 on); processing sector fuel source is apportioned based on fuel use
    select
    a.tablename,a.period,
        a.ind_bio,a.ind_coa,a.ind_gas,a.ind_hyd,a.ind_oil,a.ind_man,a.ind_bypro,
        a.res_bio,
        a.res_gas+a.res_hyd*(case when b.chp_gas_for_h_res_mult is null then 0 else b.chp_gas_for_h_res_mult end) res_gas,
-- i.e. add fraction of h2 used in res which is generated from methane
        a.res_hyd*(1-(case when b.chp_gas_for_h_res_mult is null then 0 else b.chp_gas_for_h_res_mult end)) res_hyd,
-- i.e. subtract fraction of h2 used in res which is generated from methane
        a.ser_bio,
-- [below] see notes on res above
        a.ser_gas+a.res_hyd*(case when b.chp_gas_for_h_ser_mult is null then 0 else b.chp_gas_for_h_ser_mult end) ser_gas,
        a.ser_hyd*(1-(case when b.chp_gas_for_h_ser_mult is null then 0 else b.chp_gas_for_h_ser_mult end)) ser_hyd,
        a.prc_elc*c.prc_gas_pc "prc_gas",a.prc_elc*c.prc_oil_pc "prc_oil",a.prc_elc*c.prc_refgas_pc "prc_refgas",
-- i.e. apportion generated elc by fuel shares of fuel used
        a.ups_gas
    from
        (
        select tablename,period,
            sum(case when chp_sec='CHP RES BIO' then pv else 0 end) as "res_bio",
            sum(case when chp_sec='CHP RES GAS' then pv else 0 end) as "res_gas",
            sum(case when chp_sec='CHP RES HYDROGEN' then pv else 0 end) as "res_hyd",
            sum(case when chp_sec='CHP SER BIO' then pv else 0 end) "ser_bio",
            sum(case when chp_sec='CHP SER GAS' then pv else 0 end) "ser_gas",
            sum(case when chp_sec='CHP SER HYDROGEN' then pv else 0 end) "ser_hyd",
            sum(case when chp_sec='CHP IND BIO' then pv else 0 end) "ind_bio",
            sum(case when chp_sec='CHP IND GAS' then pv else 0 end) "ind_gas",
            sum(case when chp_sec='CHP IND HYDROGEN' then pv else 0 end) "ind_hyd",
            sum(case when chp_sec='CHP IND COAL' then pv else 0 end) "ind_coa",
            sum(case when chp_sec='CHP IND OIL PRODUCTS' then pv else 0 end) "ind_oil",
            sum(case when chp_sec='CHP IND MAN FUELS' then pv else 0 end) "ind_man",
            sum(case when chp_sec='CHP IND BY PRODUCTS' then pv else 0 end) "ind_bypro",
            sum(case when chp_sec='CHP PRC SECTOR' then pv else 0 end) "prc_elc",
            sum(case when chp_sec='CHP UPS SECTOR' then pv else 0 end) "ups_gas"
        from chp_elcgen
        group by tablename,period
    ) a
    left join reformer_factors b
    on a.tablename=b.tablename and a.period=b.period
    left join process_fuel_pcs c
-- Need to get the %ages of fuel used by fuel type for process sector since this is used to apportion elec gen'd to fuel
-- (Another thing which should be moved to explicit calc in UKTM)
    on a.tablename=c.tablename and a.period=c.period
)
, chp as(
-- This table brings the outputs and inputs for chp together to give the chp correction found in the xls
-- See "Fuel use in CHP plants for electricity generation*" row 615
-- Note in the original template says Based on 'DUKES methodology: "twice as many units of fuel are 
-- allocated to each unit of electricity generated, as to each unit of heat"'
    select
        elc.tablename, elc.period,
        sum(case when elc.ind_bio+heat.ind_bio>0 then (2*fuel.ind_bio*elc.ind_bio)/(2*elc.ind_bio+heat.ind_bio) else 0 end) "ind_bio_chp",
        sum(case when elc.ind_coa+heat.ind_coa>0 then (2*fuel.ind_coa*elc.ind_coa)/(2*elc.ind_coa+heat.ind_coa) else 0 end) "ind_coa_chp",
        sum(case when elc.ind_gas+heat.ind_gas>0 then (2*fuel.ind_gas*elc.ind_gas)/(2*elc.ind_gas+heat.ind_gas) else 0 end) "ind_gas_chp",
        sum(case when elc.ind_hyd+heat.ind_hyd>0 then (2*fuel.ind_hyd*elc.ind_hyd)/(2*elc.ind_hyd+heat.ind_hyd) else 0 end) "ind_hyd_chp",
        sum(case when elc.ind_oil+heat.ind_oil>0 then (2*fuel.ind_oil*elc.ind_oil)/(2*elc.ind_oil+heat.ind_oil) else 0 end) "ind_oil_chp",
        sum(case when elc.ind_man+heat.ind_man>0 then (2*fuel.ind_man*elc.ind_man)/(2*elc.ind_man+heat.ind_man) else 0 end) "ind_man_chp",
        sum(case when elc.ind_bypro+heat.ind_bypro>0 then (2*fuel.ind_bypro*elc.ind_bypro)/(2*elc.ind_bypro+heat.ind_bypro) else 0 end) "ind_bypro_chp",
        sum(case when elc.res_bio+heat.res_bio>0 then (2*fuel.res_bio*elc.res_bio)/(2*elc.res_bio+heat.res_bio) else 0 end) "res_bio_chp",
        sum(case when elc.res_gas+heat.res_gas>0 then (2*fuel.res_gas*elc.res_gas)/(2*elc.res_gas+heat.res_gas) else 0 end) "res_gas_chp",
        sum(case when elc.res_hyd+heat.res_hyd>0 then (2*fuel.res_hyd*elc.res_hyd)/(2*elc.res_hyd+heat.res_hyd) else 0 end) "res_hyd_chp",
        sum(case when elc.ser_bio+heat.ser_bio>0 then (2*fuel.ser_bio*elc.ser_bio)/(2*elc.ser_bio+heat.ser_bio) else 0 end) "ser_bio_chp",
        sum(case when elc.ser_gas+heat.ser_gas>0 then (2*fuel.ser_gas*elc.ser_gas)/(2*elc.ser_gas+heat.ser_gas) else 0 end) "ser_gas_chp",
        sum(case when elc.ser_hyd+heat.ser_hyd>0 then (2*fuel.ser_hyd*elc.ser_hyd)/(2*elc.ser_hyd+heat.ser_hyd) else 0 end) "ser_hyd_chp",
        sum(case when elc.prc_gas+heat.prc_gas>0 then (2*fuel.prc_gas*elc.prc_gas)/(2*elc.prc_gas+heat.prc_gas) else 0 end) "prc_gas_chp",
        sum(case when elc.prc_oil+heat.prc_oil>0 then (2*fuel.prc_oil*elc.prc_oil)/(2*elc.prc_oil+heat.prc_oil) else 0 end) "prc_oil_chp",
        sum(case when elc.prc_refgas+heat.prc_refgas>0 then (2*fuel.prc_refgas*elc.prc_refgas)/(2*elc.prc_refgas+heat.prc_refgas) else 0 end) "prc_refgas_chp",
        sum(case when elc.ups_gas+heat.ups_gas>0 then (2*fuel.ups_gas*elc.ups_gas)/(2*elc.ups_gas+heat.ups_gas) else 0 end) "ups_gas_chp"
    from chp_fuels_used fuel inner join chp_heat heat on fuel.period=heat.period and fuel.tablename=heat.tablename inner join chp_elc elc
    on elc.period=fuel.period and elc.tablename=fuel.tablename
    group by elc.tablename, elc.period
    order by elc.period
)
, "all_finencon_all" as(
-- This is the Veda Be "ALL_FinEnCon_all" table- Not all elements are used in FE by end user- Elc and gas come from the "elc+gas_final_consumption" (most
-- secs - only elc in tra)
-- NB Veda table "ELC_SCTR_FC" seems to be covere by the "FUEL TECHS ELC" bit of this table
select tablename, proc_set,comm_set,period,sum(pv) "pv"
from (
    select tablename, period, pv,
    case
        when process in('AGRBIODST01','AGRBIOLPG01','AGRBOM01','AGRCOA00','AGRELC00','AGRELC01','AGRGRASS00','AGRGRASS01','AGRHFO00','AGRHFO01','AGRHYG01','AGRLAND00'
            ,'AGRLAND01','AGRLFO00','AGRLFO01','AGRLPG00','AGRLPG01','AGRNGA00','AGRNGA01','AGRPOLWST00','AGRPOLWST01') then 'FUEL TECHS AGR' --Filter 231
        when process in('ELCBFG00','ELCBFG01','ELCBIOLFO01','ELCBIOOIL01','ELCBOG-AD01','ELCBOG-LF00','ELCBOG-LF01','ELCBOG-SW00','ELCBOG-SW01','ELCBOM01','ELCCOA00','ELCCOA01'
            ,'ELCCOG00','ELCCOG01','ELCGEO01','ELCHFO00','ELCHFO01','ELCHYD00','ELCHYD01','ELCHYG01','ELCHYGD01','ELCHYGI01','ELCLFO00','ELCLFO01'
            ,'ELCLPG00','ELCLPG01','ELCMSC00','ELCMSC01','ELCMSWINO00','ELCMSWINO01','ELCMSWORG00','ELCMSWORG01','ELCNGA00','ELCNGA01','ELCPELH01','ELCPELL00'
            ,'ELCPELL01','ELCPOLWST00','ELCPOLWST01','ELCSOL00','ELCSOL01','ELCSTWWST00','ELCSTWWST01','ELCTID01','ELCURN00','ELCURN01','ELCWAV01','ELCWNDOFS00'
            ,'ELCWNDOFS01','ELCWNDONS00','ELCWNDONS01') then 'FUEL TECHS ELC' --Filter 355
        when process in('INDBENZ00','INDBENZ01','INDBFG00','INDBFG01','INDBIOLFO01','INDBIOLPG01','INDBIOOIL01','INDBIOPOL01','INDBOG-AD01','INDBOG-LF00','INDBOG-LF01','INDBOM01'
            ,'INDCOA00','INDCOA01','INDCOACOK00','INDCOACOK01','INDCOG00','INDCOG01','INDCOK00','INDCOK01','INDELC00','INDELC01','INDHFO00','INDHFO01'
            ,'INDHYG01','INDKER00','INDKER01','INDLFO00','INDLFO01','INDLPG01','INDMSWINO00','INDMSWINO01','INDMSWORG00','INDMSWORG01','INDNGA00','INDNGA01'
            ,'INDOILLPG00','INDPELH01','INDPELL00','INDPELL01','INDPOLWST00','INDSYGCOA01','INDSYGOIL01','INDWHO01','INDWOD01','INDWODWST00','INDWODWST01') then 'FUEL TECHS INDUS' --Filter 361
        when process in('PHBIOOIL01','PHCOA01','PHELC01','PHELCSURP01','PHMSWINO01','PHMSWORG01','PHNGAL01','PHPELH01','PHPELL01') then 'FUEL TECHS HYG' --Filter 345
        when process in('PRCCOA00','PRCCOA01','PRCCOACOK00','PRCCOACOK01','PRCELC00','PRCELC01','PRCHFO00','PRCHFO01','PRCNGA00','PRCNGA01','PRCOILCRD00','PRCOILCRD01')
            then 'FUEL TECHS PRC' --Filter 379
        when process in('RESBIOLFO01','RESBIOM01','RESCOA00','RESCOA01','RESCOK00','RESCOK01','RESELC00','RESELC01','RESHYG01','RESKER00','RESKER01','RESLFO00'
            ,'RESLFO01','RESLPG00','RESLPG01','RESNGAS00','RESNGAS01','RESPELH01','RESSOL00','RESSOL01','RESWOD00','RESWOD01','RESWODL00','RESWODL01','RESMSWINO01','RESMSWORG01') then 'FUEL TECHS RES' --Filter 304
        when process in('SERBIOLFO01','SERBOG-SW00','SERBOG-SW01','SERBOM01','SERCOA00','SERCOA01','SERELC00','SERELC01','SERGEO00','SERGEO01','SERHFO00','SERHFO01'
            ,'SERHYG01','SERKER01','SERLFO00','SERLFO01','SERLPG01','SERMSWBIO01','SERMSWINO00','SERMSWINO01','SERMSWORG00','SERMSWORG01','SERNGA00','SERNGA01'
            ,'SERPELH01','SERSOL01','SERWOD01') then 'FUEL TECHS SERV' --Filter 269
        when process in('TRABIODST00','TRACOA00','TRADST00','TRAELC00','TRAETH00','TRAHFODS00','TRAHFOIS00','TRAJETDA00','TRAJETIA00','TRALFO00','TRALFODS00','TRALPG00','TRAPET00',
            'TRABIODST01','TRABIODST-FT01','TRABIOJET-FTDA01','TRABIOJET-FTIA01','TRABIOLFO01','TRABIOLFODS01','TRABIOOILIS01','TRABOM01','TRADST01','TRAELC01','TRAETH01',
            'TRAHFODS01','TRAHFOIS01','TRAHYGP01','TRAHYGPDS01','TRAHYGPIS01','TRAHYL01','TRAHYLDA01','TRAHYLIA01','TRAJETDA01','TRAJETIA01','TRALFO01','TRALFODS01','TRALNGDS01',
            'TRALNGIS01','TRALPG01','TRANGA01','TRAPET01') then 'FUEL TECHS TRA' --Filter 249
        when process in('UPSELC00','UPSELC01','UPSHYG01','UPSLFO00','UPSLFO01','UPSNGA00','UPSNGA01') then 'FUEL TECHS UPSTREAM' --Filter 318
    end as proc_set,
    case
        when commodity in('BENZ','BFG','COG','COK','ELCBFG','ELCCOG','IISBFGB','IISBFGC','IISCOGB','IISCOGC','IISCOKB','IISCOKE'
            ,'IISCOKS','INDBENZ','INDBFG','INDCOG','INDCOK','RESCOK') then 'ALL MANFUELS' --Filter 330
        when commodity in('AGRNGA','ELCNGA','HYGLNGA','HYGSNGA','IISNGAB','IISNGAC','IISNGAE','INDNEUNGA','INDNGA','LNG','NGA','NGA-E'
            ,'NGA-E-EU','NGA-E-IRE','NGA-I-EU','NGA-I-N','NGAPTR','PRCNGA','RESNGA','SERNGA','TRACNGL','TRACNGS','TRALNG','TRALNGDS'
            ,'TRALNGDSL','TRALNGIS','TRALNGISL','TRANGA','UPSNGA') then 'ALL GAS' --Filter 354
        when commodity in('AGRDISTELC','AGRELC','ELC','ELC-E-EU','ELC-E-IRE','ELC-I-EU','ELC-I-IRE','ELCGEN','ELCSURPLUS','HYGELC','HYGELCSURP','HYGLELC'
            ,'HYGSELC','INDDISTELC','INDELC','PRCELC','RESDISTELC','RESELC','RESELCSURPLUS','RESHOUSEELC','SERBUILDELC','SERDISTELC','SERELC','TRACELC'
            ,'TRACPHB','TRADISTELC','TRAELC','UPSELC') then 'ALL ELECTRICITY' --Filter 235
        when commodity in('ICHOTH','ICHSTM','IFDSTM','INDSTM','INMSTM','IOISTM','PCHPHEAT','RHCSV-RHEA','RHEATPIPE-EA','RHEATPIPE-NA','UPSHEAT') then 'ALL HEAT' --Filter 263
        when commodity in('ELCGEO','ELCHYDDAM','ELCSOL','ELCTID','ELCWAV','ELCWNDOFS','ELCWNDONS','GEO','HYDDAM','HYDROR','RESSOL','SERGEO'
            ,'SERSOL','SOL','TID','WAV','WNDOFF','WNDONS') then 'ALL OTHER RNW' --Filter 226
        when commodity in('AGRCOA','COA','COA-E','COACOK','ELCCOA','HYGCOA','INDCOA','INDCOACOK','INDSYNCOA','PRCCOA','PRCCOACOK','RESCOA'
            ,'SERCOA','SYNCOA','TRACOA') then 'ALL COALS' --Filter 246
        when commodity in('AGRBIODST','AGRBIOLPG','AGRBOM','AGRGRASS','AGRMAINSBOM','AGRPOLWST','BGRASS','BIODST','BIODST-FT','BIOJET-FT','BIOKER-FT','BIOLFO'
            ,'BIOLPG','BIOOIL','BOG-AD','BOG-G','BOG-LF','BOM','BPELH','BPELL','BRSEED','BSEWSLG','BSLURRY','BSTARCH'
            ,'BSTWWST','BSUGAR','BTREATSTW','BTREATWOD','BVOIL','BWOD','BWODLOG','BWODWST','ELCBIOCOA','ELCBIOCOA2','ELCBIOLFO','ELCBIOOIL'
            ,'ELCBOG-AD','ELCBOG-LF','ELCBOG-SW','ELCBOM','ELCMAINSBOM','ELCMSWINO','ELCMSWORG','ELCPELH','ELCPELL','ELCPOLWST','ELCSTWWST','ELCTRANSBOM'
            ,'ETH','HYGBIOO','HYGBPEL','HYGMSWINO','HYGMSWORG','INDBIOLFO','INDBIOLPG','INDBIOOIL','INDBOG-AD','INDBOG-LF','INDBOM','INDGRASS'
            ,'INDMAINSBOM','INDMSWINO','INDMSWORG','INDPELH','INDPELL','INDPOLWST','INDWOD','INDWODWST','METH','MSWBIO','MSWINO','MSWORG'
            ,'PWASTEDUM','RESBIOLFO','RESBOM','RESHOUSEBOM','RESMAINSBOM','RESMSWINO','RESMSWORG','RESPELH','RESWOD','RESWODL','SERBIOLFO','SERBOG','SERBOM','SERBUILDBOM'
            ,'SERMAINSBOM','SERMSWBIO','SERMSWINO','SERMSWORG','SERPELH','SERWOD','TRABIODST','TRABIODST-FT','TRABIODST-FTL','TRABIODST-FTS','TRABIODSTL','TRABIODSTS'
            ,'TRABIOJET-FTDA','TRABIOJET-FTDAL','TRABIOJET-FTIA','TRABIOJET-FTIAL','TRABIOLFO','TRABIOLFODS','TRABIOLFODSL','TRABIOLFOL','TRABIOOILIS','TRABIOOILISL','TRABOM','TRAETH'
            ,'TRAETHL','TRAETHS','TRAMAINSBOM','TRAMETH') then 'ALL BIO' --Filter 287
        when commodity in('AGRHFO','AGRLFO','AGRLPG','ELCHFO','ELCLFO','ELCLPG','ELCMSC','IISHFOB','INDHFO','INDKER','INDLFO','INDLPG'
            ,'INDNEULFO','INDNEULPG','INDNEUMSC','INDSYNOIL','OILCRD','OILCRDRAW','OILCRDRAW-E','OILDST','OILHFO','OILJET','OILKER','OILLFO'
            ,'OILLPG','OILMSC','OILPET','PRCHFO','PRCOILCRD','RESKER','RESLFO','RESLPG','SERHFO','SERKER','SERLFO','SERLPG'
            ,'SYNOIL','TRADST','TRADSTL','TRADSTS','TRAHFO','TRAHFODS','TRAHFODSL','TRAHFOIS','TRAHFOISL','TRAJETDA','TRAJETDAEL','TRAJETIA'
            ,'TRAJETIAEL','TRAJETIANL','TRAJETL','TRALFO','TRALFODS','TRALFODSL','TRALFOL','TRALPG','TRALPGL','TRALPGS','TRAPET','TRAPETL'
            ,'TRAPETS','UPSLFO') then 'ALL OIL PRODUCTS' --Filter 302
        when commodity in('AGRHYG','ELCHYG','ELCHYGIGCC','HYGL','HYGL-IGCC','HYGLHPD','HYGLHPT','HYL','HYLTK','INDHYG','INDMAINSHYG','RESHOUSEHYG'
            ,'RESHYG','RESHYGREF-EA','RESHYGREF-NA','RESMAINSHYG','SERBUILDHYG','SERHYG','SERMAINSHYG','TRAHYG','TRAHYGDCN','TRAHYGL','TRAHYGS','TRAHYL'
            ,'UPSHYG','UPSMAINSHYG') then 'ALL HYDROGEN' --Filter 371
    end as comm_set
    from vedastore
    where attribute='VAR_FIn'
) a
where proc_set is not null and comm_set is not null
group by tablename, proc_set,comm_set,period
order by proc_set,comm_set
)
, "elc+gas_final_consumption" as(
-- This is the Veda BE table- Differences are period is in one col, tablename is included
-- Note that only some of the elements of the Veda BE "elc+gas_final_consumption" are used in FE by end user-
    select tablename, commodity,period,sum(pv) "pv"
    from vedastore
    where attribute='VAR_FOut' and commodity in('AGRBOM','AGRDISTELC','AGRMAINSBOM','AGRMAINSGAS','INDBOM','INDDISTELC','INDMAINSBOM','INDMAINSGAS','RESBOM','RESDISTELC','RESMAINSBOM','RESMAINSGAS',
        'SERBOM','SERDISTELC','SERMAINSBOM','SERMAINSGAS','TRABOM','TRADISTELC','TRAMAINSBOM','TRAMAINSGAS','RESELC-NS-E','RESELC-NS-N') --Filter 200
    group by tablename, period, commodity
)
, mainsbom as(
    select tablename, period, sum(case when commodity='RESMAINSBOM' then pv else 0 end) "resmainsbom"
        ,sum(case when commodity='INDMAINSBOM' then pv else 0 end) "indmainsbom"
    from "elc+gas_final_consumption"
    group by tablename, period
), elc_waste_heat_distribution as(
    select tablename, commodity,attribute,process,period,sum(pv) "pv"
    from vedastore
    where commodity='ELCLTH' and attribute in ('VAR_FIn','VAR_FOut')  --Filter 201
    group by tablename, commodity,attribute,process,period
),
elc_prd_fuel as (
-- This is the same as the Veda BE table (same name) with the addition of more years & the addition of CHP & the heat offtake generation penalty
-- NB CCSRET lines currently missing from veda (sets not defined since are part of PRE set not ELE which is in the filter definition)
    select
        proc_set,tablename,period, sum(pv) "pv"
    from (
        select tablename,period, pv,
        case
            when process in('EBIO01','EBIOCON00','EBIOS00','EBOG-ADE01','EBOG-LFE00','EBOG-LFE01','EBOG-SWE00','EBOG-SWE01','EMSW00','EMSW01','EPOLWST00','ESTWWST00'
                ,'ESTWWST01') then 'ELC FROM BIO' --Filter 297
            when process in('EBIOQ01') then 'ELC FROM BIO CCS' --Filter 306
            when process in('PCHP-CCP00','PCHP-CCP01','UCHP-CCG00','UCHP-CCG01') then 'ELC FROM CHP' --Filter 358
            when process='ECOAQR01' then 'ELC FROM COAL CCSRET' --Filter 245
            when process in('ECOARR01') then 'ELC FROM COAL RR' --Filter 238
            when process in('ECOA00','ECOABIO00') then 'ELC FROM COAL-COF' --Filter 347
            when process in('ECOAQ01','ECOAQDEMO01') then 'ELC FROM COALCOF CCS' --Filter 248
            when process in('ENGACCT00','ENGAOCT00','ENGAOCT01','ENGARCPE00','ENGARCPE01') then 'ELC FROM GAS' --Filter 243
            when process in('ENGACCTQ01','ENGACCTQDEMO01') then 'ELC FROM GAS CCS' --Filter 301
            when process='ENGAQR01' then 'ELC FROM GAS CCSRET' --Filter 240
            when process in('ENGACCTRR01') then 'ELC FROM GAS RR' --Filter 392
            when process in('EGEO01') then 'ELC FROM GEO' --Filter 338
            when process in('EHYD00','EHYD01') then 'ELC FROM HYDRO' --Filter 373
            when process in('EHYGCCT01','EHYGOCT01') then 'ELC FROM HYDROGEN' --Filter 283
            when process in('ELCIE00','ELCIE01','ELCII00','ELCII01') then 'ELC FROM IMPORTS' --Filter 225
            when process in('EMANOCT00','EMANOCT01') then 'ELC FROM MANFUELS' --Filter 294
            when process in('ENUCPWR00','ENUCPWR101','ENUCPWR102') then 'ELC FROM NUCLEAR' --Filter 261
            when process in('EDSTRCPE00','EDSTRCPE01','EHFOIGCC01','EOILL00','EOILL01','EOILS00','EOILS01') then 'ELC FROM OIL' --Filter 341
            when process in('EHFOIGCCQ01') then 'ELC FROM OIL CCS' --Filter 290
            when process in('ESOL00','ESOL01','ESOLPV00','ESOLPV01') then 'ELC FROM SOL-PV' --Filter 366
            when process in('ETIB101','ETIR101','ETIS101') then 'ELC FROM TIDAL' --Filter 352
            when process in('EWAV101') then 'ELC FROM WAVE' --Filter 239
            when process in('EWNDOFF00','EWNDOFF101','EWNDOFF201','EWNDOFF301') then 'ELC FROM WIND-OFFSH' --Filter 299
            when process in('EWNDONS00','EWNDONS101','EWNDONS201','EWNDONS301','EWNDONS401','EWNDONS501','EWNDONS601','EWNDONS701','EWNDONS801','EWNDONS901') then 'ELC FROM WIND-ONSH' --Filter 236
            when process in('ELCEE00','ELCEE01','ELCEI00','ELCEI01') then 'ELC TO EXPORTS' --Filter 298
         end as proc_set
        from vedastore
        where attribute='VAR_FOut' and commodity in('ELCDUMMY','ELC','ELC-E-IRE','ELC-E-EU','ELCGEN')  --Filter 78
    ) a
    where proc_set is not null
    group by tablename, period,proc_set
)
, end_demand as(
-- elc_sctr_fc (Electricity Sector Fuel consumption (TOTAL, Major power producers (electricity-only plants) and CHPs in end-use sectors)) not used here
-- as appears to be identical to the "FUEL TECHS ELC" part of "all_finencon_all"
    select a.tablename
        ,sec_fuel,
        case
            when sec_fuel='ind-bio' then sum(a.pv-ind_bio_chp-(1-0.9828)/0.9828*(case when c.indmainsbom is null then 0 else c.indmainsbom end))
        -- incorporating corrections to bio due to chp & biomethane from mains distribution pipes [magic nos are grid losses?])
            when sec_fuel='ind-coa' then sum(a.pv-ind_coa_chp)
            when sec_fuel='ind-gas' then sum(a.pv-ind_gas_chp)
            when sec_fuel='ind-hyd' then sum(a.pv-ind_hyd_chp)
            when sec_fuel='ind-man' then sum(a.pv-ind_man_chp)
            when sec_fuel='ind-oil' then sum(a.pv-ind_oil_chp)
            when sec_fuel='res-bio' then sum(a.pv-res_bio_chp-(1-0.9828)/0.9828*(case when c.resmainsbom is null then 0 else c.resmainsbom end))
        -- incorporating corrections to bio due to chp & biomethane from mains distribution pipes [magic nos are grid losses?])
            when sec_fuel='res-gas' then sum(a.pv-res_gas_chp)
            when sec_fuel='ser-bio' then sum(a.pv-ser_bio_chp)
            when sec_fuel='ser-gas' then sum(a.pv-ser_gas_chp)
            when sec_fuel='elc-bio' then sum(a.pv+ind_bio_chp+res_bio_chp+ser_bio_chp)
            when sec_fuel='elc-coa' then sum(a.pv+ind_coa_chp)
            when sec_fuel='elc-gas' then sum(a.pv+ind_gas_chp+res_gas_chp+ser_gas_chp+prc_gas_chp+ups_gas_chp)
            when sec_fuel='elc-man' then sum(a.pv+ind_bypro_chp+ind_man_chp)
            when sec_fuel='elc-oil' then sum(a.pv+ind_oil_chp+prc_oil_chp+prc_refgas_chp)
            when sec_fuel='elc-oil' then sum(a.pv+ind_oil_chp+prc_oil_chp+prc_refgas_chp)
            when sec_fuel='elc-hyd' then sum(a.pv+ind_hyd_chp+res_hyd_chp+ser_hyd_chp)
            else sum(pv)
        end as pv,a.period
    from(
        select case
                when commodity='AGRDISTELC' then 'agr-elc'
                when commodity='AGRMAINSGAS' then 'agr-gas'
                when commodity='INDDISTELC' then 'ind-elc'
                when commodity='INDMAINSGAS' then 'ind-gas'
                when commodity='SERDISTELC' then 'ser-elc'
                when commodity='SERMAINSGAS' then 'ser-gas'
                when commodity='TRADISTELC' then 'tra-elc'
                when commodity='RESDISTELC' then 'res-elc'
                when commodity='RESMAINSGAS' then 'res-gas'
            end as sec_fuel,
            tablename, period,pv
        from "elc+gas_final_consumption"
        where commodity in('AGRDISTELC' ,'AGRMAINSGAS' ,'INDDISTELC' ,'INDMAINSGAS' ,'SERDISTELC' ,'SERMAINSGAS' ,'TRADISTELC' ,'RESDISTELC' ,'RESMAINSGAS')
        union all
        select case
            when proc_set='FUEL TECHS AGR' then 'agr-'
            when proc_set='FUEL TECHS INDUS' then 'ind-'
            when proc_set='FUEL TECHS PRC' then 'prc-'
            when proc_set='FUEL TECHS RES' then 'res-'
            when proc_set='FUEL TECHS SERV' then 'ser-'
            when proc_set='FUEL TECHS TRA' then 'tra-'
            when proc_set='FUEL TECHS HYG' then 'hyd-'
            when proc_set='FUEL TECHS ELC' then 'elc-'
        end ||
        case
            when comm_set='ALL BIO' then 'bio'
            when comm_set='ALL COALS' then 'coa'
            when comm_set='ALL ELECTRICITY' then 'elc'
            when comm_set='ALL GAS' then 'gas'
            when comm_set='ALL HYDROGEN' then 'hyd'
            when comm_set='ALL OIL PRODUCTS' then 'oil'
            when comm_set='ALL OTHER RNW' then 'orens'
            when comm_set='ALL MANFUELS' then 'man'
        end as sec_fuel,tablename, period,pv
        from all_finencon_all
        where proc_set in('FUEL TECHS HYG','FUEL TECHS PRC') or (proc_set in('FUEL TECHS AGR','FUEL TECHS INDUS','FUEL TECHS RES','FUEL TECHS SERV') and
            comm_set in('ALL BIO','ALL COALS','ALL HYDROGEN','ALL OIL PRODUCTS','ALL MANFUELS','ALL OTHER RNW')) or
            (proc_set in('FUEL TECHS TRA','FUEL TECHS ELC') and comm_set in('ALL BIO','ALL COALS','ALL HYDROGEN','ALL OIL PRODUCTS','ALL MANFUELS','ALL OTHER RNW','ALL GAS'))
-- Filters reflect where the different entitites come from (don't nec- come from the same table, depending which process group it is
-- NB includes FE use for h2 prod
        union all
        select case
        when process='SDH-WHO01' then 'ser-wh'  --Filter 203
        when process in('RDHEA-WHO01','RDHHC-WHO01','RDHHS-WHO01','RDHFC-WHO01','RDHFS-WHO01','RDHNA-WHO01') then 'res-wh'  --Filter 204
            end as sec_fuel, tablename, period,sum(pv) "pv"
        from elc_waste_heat_distribution
        where process in('RDHEA-WHO01','RDHHC-WHO01','RDHHS-WHO01','RDHFC-WHO01','RDHFS-WHO01','RDHNA-WHO01','SDH-WHO01') --Filter 205
        group by sec_fuel, tablename, period
        union all
        select 'elc-urn' "sec_fuel",tablename, period,sum(pv/0.398)
-- Thermal efficiency of nuclear plants: 39-80% DUKES 2013 paragraph 5-46 https://www-gov-uk/government/uploads/system/uploads/attachment_data/file/65818/DUKES_2013_Chapter_5-pdf
-- cell g31 on ucl template
        from elc_prd_fuel
        where proc_set='ELC FROM NUCLEAR'
        group by tablename, period
    ) a left join chp b on a.period=b.period and a.tablename=b.tablename
        left join mainsbom c on a.period=c.period and a.tablename=c.tablename
    group by a.tablename, sec_fuel, a.period
    order by a.period
)
-- Final crosstab which converts to years across the top, sec/fuel down the side
select 'fin-en-main-secs_' || sec_fuel || '|' || tablename || '|various|various|various'::varchar "id",
    'fin-en-main-secs_'|| sec_fuel::varchar "analysis",
    tablename,
    'various'::varchar "attribute",
    'various'::varchar "commodity",
    'various'::varchar "process",
    sum(pv) "all",
    sum(case when a.period='2010' then pv else 0 end) as "2010",
    sum(case when a.period='2011' then pv else 0 end) as "2011",
    sum(case when a.period='2012' then pv else 0 end) as "2012",
    sum(case when a.period='2015' then pv else 0 end) as "2015",
    sum(case when a.period='2020' then pv else 0 end) as "2020",
    sum(case when a.period='2025' then pv else 0 end) as "2025",
    sum(case when a.period='2030' then pv else 0 end) as "2030",
    sum(case when a.period='2035' then pv else 0 end) as "2035",
    sum(case when a.period='2040' then pv else 0 end) as "2040",
    sum(case when a.period='2045' then pv else 0 end) as "2045",
    sum(case when a.period='2050' then pv else 0 end) as "2050",
    sum(case when a.period='2055' then pv else 0 end) as "2055",
    sum(case when a.period='2060' then pv else 0 end) as "2060"
from end_demand a
group by tablename,sec_fuel
order by tablename,analysis
  ) TO '%~dp0FinEnOut.csv' delimiter ',' CSV;
-- **END OF End user final energy demand by sector**

/* *Primary energy demand and biomass, imports exports and domestic production* */
-- Includes non-energy use of fuels in the industry chemicals sub-sector
-- Includes domestically grown biomass from forestry (not clear model is constrained to actually use this)
COPY (
with rsr_min as(
-- This is the veda BE table but with MINMSWINO, 'MINING INORGANIC WASTE separated out (was lumped with bio)
    select
        sum(case when proc_set='IMPORT URN' then pv else 0 end) "IMPORT URN"
        ,sum(case when proc_set='MINING BIOMASS' then pv else 0 end) "MINING BIOMASS"
        ,sum(case when proc_set='MINING COAL' then pv else 0 end) "MINING COAL"
        ,sum(case when proc_set='MINING GEOTHERMAL' then pv else 0 end) "MINING GEOTHERMAL"
        ,sum(case when proc_set='MINING HYDRO' then pv else 0 end) "MINING HYDRO"
        ,sum(case when proc_set='MINING NGA' then pv else 0 end) "MINING NGA"
        ,sum(case when proc_set='MINING NGA-SHALE' then pv else 0 end) "MINING NGA-SHALE"
        ,sum(case when proc_set='MINING OIL' then pv else 0 end) "MINING OIL"
        ,sum(case when proc_set='MINING SOLAR' then pv else 0 end) "MINING SOLAR"
        ,sum(case when proc_set='MINING TIDAL' then pv else 0 end) "MINING TIDAL"
        ,sum(case when proc_set='MINING WIND' then pv else 0 end) "MINING WIND"
        ,sum(case when proc_set='MINING WAVE' then pv else 0 end) "MINING WAVE"
        ,sum(case when proc_set='MINING INORGANIC WASTE' then pv else 0 end) "MINING INORGANIC WASTE",
        tablename,period
    from (
        select tablename,period, pv,
            case
                when  process in('IMPURN') then 'IMPORT URN' --Filter 325
                when  process in('MINBGRASS1','MINBGRASS2','MINBGRASS3','MINBIOOILCRP','MINBOG-LF','MINBRSEED','MINBSEWSLG','MINBSLURRY1','MINBSTWWST1','MINBSUGAR','MINBTALLOW','MINBVOFAT'
                    ,'MINBWHT1','MINBWHT2','MINBWHT3','MINBWOD1','MINBWOD2','MINBWOD3','MINBWOD4','MINBWODLOG','MINBWODWST','MINBWODWSTSAW','MINMSWBIO',
                    'MINMSWORG') then 'MINING BIOMASS' --Filter 254
                when  process in('MINCOA1','MINCOA2','MINCOA3','MINCOA4','MINCOA5','MINCOA6','MINCOACOK1','MINCOACOK2') then 'MINING COAL' --Filter 300
                when  process in('RNWGEO') then 'MINING GEOTHERMAL' --Filter 380
                when  process in('RNWHYDDAM','RNWHYDROR') then 'MINING HYDRO' --Filter 317
                when  process in('MINNGA1','MINNGA2','MINNGA3','MINNGA4','MINNGA5','MINNGA6','MINNGA7','MINNGA8','MINNGA9') then 'MINING NGA' --Filter 309
                when  process in('MINNGASHL1','MINNGASHL2','MINNGASHL3') then 'MINING NGA-SHALE' --Filter 247
                when  process in('MINOILCRD1','MINOILCRD2','MINOILCRD3','MINOILCRD4','MINOILCRD5','MINOILCRD6','MINOILCRD7','MINOILCRD8','MINOILCRD9') then 'MINING OIL' --Filter 274
                when  process in('RNWSOL') then 'MINING SOLAR' --Filter 305
                when  process in('RNWTID') then 'MINING TIDAL' --Filter 378
                when  process in('RNWWAV') then 'MINING WAVE' --Filter 272
                when  process in('RNWWNDOFF','RNWWNDONS') then 'MINING WIND' --Filter 310
        when process in('MINMSWINO') then 'MINING INORGANIC WASTE' --Filter 409
                else null
            end as proc_set
        from vedastore
        where attribute='VAR_FOut'
            and commodity in('AGRBIODST','AGRBIOLPG','AGRBOM','AGRCOA','AGRGRASS','AGRHFO','AGRLFO',
                'AGRLPG','AGRMAINSBOM','AGRNGA','AGRPOLWST','BGRASS','BIODST','BIODST-FT','BIOJET-FT',
                'BIOKER-FT','BIOLFO','BIOLPG','BIOOIL','BOG-AD','BOG-G','BOG-LF','BOM','BPELH','BPELL',
                'BRSEED','BSEWSLG','BSLURRY','BSTARCH','BSTWWST','BSUGAR','BTREATSTW','BTREATWOD','BVOIL',
                'BWOD','BWODLOG','BWODWST','COA','COACOK','COA-E','ELCBIOCOA','ELCBIOCOA2','ELCBIOLFO',
                'ELCBIOOIL','ELCBOG-AD','ELCBOG-LF','ELCBOG-SW','ELCBOM','ELCCOA','ELCGEO','ELCHFO',
                'ELCHYDDAM','ELCLFO','ELCLPG','ELCMAINSBOM','ELCMSC','ELCMSWINO','ELCMSWORG','ELCNGA',
                'ELCPELH','ELCPELL','ELCPOLWST','ELCSOL','ELCSTWWST','ELCTID','ELCTRANSBOM','ELCWAV',
                'ELCWNDOFS','ELCWNDONS','ETH','GEO','HYDDAM','HYDROR','HYGBIOO','HYGBPEL','HYGCOA',
                'HYGLNGA','HYGMSWINO','HYGMSWORG','HYGSNGA','IISHFOB','IISNGAB','IISNGAC','IISNGAE',
                'INDBIOLFO','INDBIOLPG','INDBIOOIL','INDBOG-AD','INDBOG-LF','INDBOM','INDCOA',
                'INDCOACOK','INDGRASS','INDHFO','INDKER','INDLFO','INDLPG','INDMAINSBOM','INDMSWINO',
                'INDMSWORG','INDNEULFO','INDNEULPG','INDNEUMSC','INDNEUNGA','INDNGA','INDPELH','INDPELL',
                'INDPOLWST','INDSYNCOA','INDSYNOIL','INDWOD','INDWODWST','LNG','METH','MSWBIO','MSWINO',
                'MSWORG','NGA','NGA-E','NGA-E-EU','NGA-E-IRE','NGA-I-EU','NGA-I-N','NGAPTR','OILCRD',
                'OILCRDRAW','OILCRDRAW-E','OILDST','OILHFO','OILJET','OILKER','OILLFO','OILLPG','OILMSC',
                'OILPET','PRCCOA','PRCCOACOK','PRCHFO','PRCNGA','PRCOILCRD','PWASTEDUM','RESBIOLFO',
                'RESBOM','RESCOA','RESHOUSEBOM','RESKER','RESLFO','RESLPG','RESMAINSBOM','RESMSWINO',
                'RESMSWORG','RESNGA','RESPELH','RESSOL','RESWOD','RESWODL','SERBIOLFO','SERBOG','SERBOM',
                'SERBUILDBOM','SERCOA','SERGEO','SERHFO','SERKER','SERLFO','SERLPG','SERMAINSBOM',
                'SERMSWBIO','SERMSWINO','SERMSWORG','SERNGA','SERPELH','SERSOL','SERWOD','SOL','SYNCOA',
                'SYNOIL','TID','TRABIODST','TRABIODST-FT','TRABIODST-FTL','TRABIODST-FTS','TRABIODSTL',
                'TRABIODSTS','TRABIOJET-FTDA','TRABIOJET-FTDAL','TRABIOJET-FTIA','TRABIOJET-FTIAL',
                'TRABIOLFO','TRABIOLFODS','TRABIOLFODSL','TRABIOLFOL','TRABIOOILIS','TRABIOOILISL','TRABOM',
                'TRACNGL','TRACNGS','TRACOA','TRADST','TRADSTL','TRADSTS','TRAETH','TRAETHL','TRAETHS',
                'TRAHFO','TRAHFODS','TRAHFODSL','TRAHFOIS','TRAHFOISL','TRAJETDA','TRAJETDAEL','TRAJETIA',
                'TRAJETIAEL','TRAJETIANL','TRAJETL','TRALFO','TRALFODS','TRALFODSL','TRALFOL','TRALNG',
                'TRALNGDS','TRALNGDSL','TRALNGIS','TRALNGISL','TRALPG','TRALPGL','TRALPGS','TRAMAINSBOM',
                'TRAMETH','TRANGA','TRAPET','TRAPETL','TRAPETS','UPSLFO','UPSNGA','URN','WAV','WNDOFF',
                'WNDONS') --Filter 206
    ) a
    where proc_set is not null group by tablename, period order by tablename,period
)
,rsr_imports as(
-- This is the veda BE table
    select
        sum(case when proc_set='IMPORT BDL' then pv else 0 end) "IMPORT BDL"
        ,sum(case when proc_set='IMPORT FTD' then pv else 0 end) "IMPORT FTD"
        ,sum(case when proc_set='IMPORT FTK-AVI' then pv else 0 end) "IMPORT FTK-AVI"
        ,sum(case when proc_set='IMPORT FTK-HEA' then pv else 0 end) "IMPORT FTK-HEA"
        ,sum(case when proc_set='IMPORT BIOOIL' then pv else 0 end) "IMPORT BIOOIL"
        ,sum(case when proc_set='IMPORT BIOMASS' then pv else 0 end) "IMPORT BIOMASS"
        ,sum(case when proc_set='IMPORT COAL' then pv else 0 end) "IMPORT COAL"
        ,sum(case when proc_set='IMPORT COKE' then pv else 0 end) "IMPORT COKE"
        ,sum(case when proc_set='IMPORT ELC' then pv else 0 end) "IMPORT ELC"
        ,sum(case when proc_set='IMPORT ETHANOL' then pv else 0 end) "IMPORT ETHANOL"
        ,sum(case when proc_set='IMPORT HYL' then pv else 0 end) "IMPORT HYL"
        ,sum(case when proc_set='IMPORT NGA' then pv else 0 end) "IMPORT NGA"
        ,sum(case when proc_set='IMPORT OIL' then pv else 0 end) "IMPORT OIL"
        ,sum(case when proc_set='IMPORT DST' then pv else 0 end) "IMPORT DST"
        ,sum(case when proc_set='IMPORT HFO' then pv else 0 end) "IMPORT HFO"
        ,sum(case when proc_set='IMPORT JET' then pv else 0 end) "IMPORT JET"
        ,sum(case when proc_set='IMPORT KER' then pv else 0 end) "IMPORT KER"
        ,sum(case when proc_set='IMPORT LFO' then pv else 0 end) "IMPORT LFO"
        ,sum(case when proc_set='IMPORT LPG' then pv else 0 end) "IMPORT LPG"
        ,sum(case when proc_set='IMPORT MOIL' then pv else 0 end) "IMPORT MOIL"
        ,sum(case when proc_set='IMPORT GSL' then pv else 0 end) "IMPORT GSL"
        ,sum(case when proc_set='IMPORT URN' then pv else 0 end) "IMPORT URN"
        ,tablename,period
    from (
        select tablename,period, pv,
        case
            when process in('IMPBIODST') then 'IMPORT BDL' --Filter 232
            when process in('IMPBIODST-FT') then 'IMPORT FTD' --Filter 377
            when process in('IMPBIOJET-FT') then 'IMPORT FTK-AVI' --Filter 383
            when process in('IMPBIOKET-FT') then 'IMPORT FTK-HEA' --Filter 357
            when process in('IMPBIOOIL','IMPBVOFAT','IMPBVOIL') then 'IMPORT BIOOIL' --Filter 381
            when process in('IMPAGWST','IMPBGRASS','IMPBSTARCH','IMPBWOD','IMPBWODWST') then 'IMPORT BIOMASS' --Filter 384
            when process in('IMPCOA','IMPCOA-E','IMPCOACOK') then 'IMPORT COAL' --Filter 390
            when process in('IMPCOK') then 'IMPORT COKE' --Filter 369
            when process in('IMPELC-EU','IMPELC-IRE') then 'IMPORT ELC' --Filter 350
            when process in('IMPETH') then 'IMPORT ETHANOL' --Filter 362
            when process in('IMPHYL') then 'IMPORT HYL' --Filter 293
            when process in('IMPNGA-E','IMPNGA-EU','IMPNGA-LNG','IMPNGA-N') then 'IMPORT NGA' --Filter 280
            when process in('IMPOILCRD1','IMPOILCRD1-E','IMPOILCRD2') then 'IMPORT OIL' --Filter 241
            when process in('IMPOILDST') then 'IMPORT DST' --Filter 250
            when process in('IMPOILHFO') then 'IMPORT HFO' --Filter 359
            when process in('IMPOILJET') then 'IMPORT JET' --Filter 262
            when process in('IMPOILKER') then 'IMPORT KER' --Filter 391
            when process in('IMPOILLFO') then 'IMPORT LFO' --Filter 273
            when process in('IMPOILLPG') then 'IMPORT LPG' --Filter 348
            when process in('IMPOILMSC') then 'IMPORT MOIL' --Filter 334
            when process in('IMPOILPET') then 'IMPORT GSL' --Filter 267
            when process in('IMPURN') then 'IMPORT URN' --Filter 325
        end as proc_set
        from vedastore
        where attribute='VAR_FOut'
            and commodity in('INDPELL','BIOLPG','MSWINO','AGRLPG','HYLTK','AGRBOM','HYL','BOG-AD','SERBOM','TRALFODS','BIOJET-FT','NGA-I-EU'
                ,'OILCRDRAW','SYNOIL','IOISTM','RESHYG','RESHYGREF-NA','HYGLHPD','PRCOILCRD','TRAHYGS','PRCCOA','AGRBIODST','IISNGAE','SERWOD'
                ,'ELCMSWORG','BTREATWOD','INDCOK','TRABIOLFODS','NGAPTR','HYGSNGA','METH','BIODST-FT','TRALNGISL','TRAJETIANL','SERBOG','AGRELC'
                ,'HYDROR','UPSHYG','TRABIOOILISL','HYGMSWINO','ELCSTWWST','MSWORG','UPSNGA','TRAJETIA','INDSTM','SERELC','SERBUILDHYG','ELCCOG'
                ,'AGRDISTELC','TRADISTELC','AGRGRASS','TRALFO','HYGELCSURP','OILLPG','WNDOFF','PCHPHEAT','INDGRASS','HYGL-IGCC','BVOIL','COK'
                ,'RESHOUSEBOM','TRABIODST-FTS','ELC','IISCOGB','INDCOACOK','IISCOGC','TRAJETIAEL','UPSHEAT','AGRMAINSBOM','ELCBOM','HYGBIOO','TRAHFODSL'
                ,'COG','NGA','ELC-I-IRE','RESDISTELC','HYGL','ELCBIOCOA','AGRLFO','BIOKER-FT','TRALPGS','RESHOUSEELC','RESMAINSBOM','COACOK'
                ,'TRAHYGL','MSWBIO','RESWOD','PRCCOACOK','ELCPELL','BGRASS','INDNEUMSC','INDMAINSHYG','INDBOM','INDBOG-AD','TRAHYG','TRADST'
                ,'BENZ','INDCOA','SERBUILDBOM','ELCHYDDAM','ELCWNDOFS','TRALNGDS','ELCLFO','ELCWAV','HYGLNGA','TRACPHB','BOM','INDWODWST'
                ,'SERMSWBIO','SERPELH','INDBIOOIL','RHEATPIPE-EA','TRAPET','TRABIODSTS','TRALFODSL','BOG-LF','RESWODL','INDKER','TRACOA','ELCHFO'
                ,'INDNEULFO','ETH','INDBIOLPG','INDNEUNGA','TRANGA','AGRNGA','HYGSELC','BRSEED','AGRPOLWST','INDNGA','TRACNGL','ELCMSWINO'
                ,'TRALNGIS','TRABIODSTL','SERNGA','TRAELC','BSLURRY','TRABOM','ELCWNDONS','TRABIOJET-FTDA','TRAHFOIS','BSEWSLG','SERMSWORG','TRAHFOISL'
                ,'COA','NGA-E-IRE','AGRHFO','ELC-E-IRE','RESBOM','INDBENZ','RESELC','RESELCSURPLUS','AGRHYG','COA-E','GEO','IISBFGB'
                ,'ELCLPG','SERGEO','BOG-G','TRABIODST','TRABIOOILIS','IISCOKE','INDHYG','TRADSTL','BFG','INDLPG','OILMSC','OILPET'
                ,'PRCHFO','ELCBOG-AD','ELCBIOOIL','INDNEULPG','RESHYGREF-EA','BSTWWST','RESHOUSEHYG','IISBFGC','BSTARCH','NGA-E-EU','OILJET','HYDDAM'
                ,'TRAETH','UPSLFO','INDMSWINO','SERBIOLFO','IISNGAB','ELC-E-EU','BWODLOG','TRAJETDAEL','IISCOKS','TRAMETH','SERMAINSBOM','ELCPOLWST'
                ,'PWASTEDUM','NGA-I-N','SERMAINSHYG','BPELL','TRAJETL','TRAPETS','INDPELH','INDPOLWST','WAV','HYGELC','RESCOK','ELCSOL'
                ,'ELCBFG','RESNGA','TRABIODST-FT','RESMAINSHYG','INDWOD','INDSYNOIL','TRAHFO','INDBFG','ELCBOG-SW','SERLFO','TRAPETL','ELCHYGIGCC'
                ,'ELCMAINSBOM','TRAJETDA','TRABIOLFODSL','TRABIOLFOL','RESKER','INDSYNCOA','TRALNG','ELCBOG-LF','TRAETHL','ELCTRANSBOM','IISHFOB','ELCGEO'
                ,'ELCSURPLUS','BIODST','ELCNGA','INDHFO','BIOLFO','ELC-I-EU','LNG','INDBOG-LF','TRABIOJET-FTIAL','OILHFO','TRABIOJET-FTDAL','SERCOA'
                ,'TRALPGL','SERSOL','HYGBPEL','BSUGAR','TRAETHS','HYGCOA','NGA-E','TRADSTS','OILLFO','TRALPG','TRABIODST-FTL','TRALNGDSL'
                ,'IISNGAC','ELCTID','INDCOG','RHEATPIPE-NA','SERHFO','SERDISTELC','SERMSWINO','BWOD','INMSTM','BPELH','SERBUILDELC','TRABIOJET-FTIA'
                ,'TRACNGS','ELCGEN','HYGLHPT','RESBIOLFO','AGRCOA','INDDISTELC','HYGLELC','BTREATSTW','BWODWST','IISCOKB','SYNCOA','UPSMAINSHYG'
                ,'ICHOTH','TRAMAINSBOM','RESLPG','TRACELC','TID','INDMAINSBOM','TRAHFODS','RESSOL','TRAHYGDCN','TRALFOL','PRCELC','ELCPELH'
                ,'WNDONS','OILCRDRAW-E','ELCBIOLFO','ELCHYG','OILDST','PRCNGA','OILKER','AGRBIOLPG','SOL','ICHSTM','RESCOA','INDELC'
                ,'OILCRD','SERLPG','ELCBIOCOA2','HYGMSWORG','ELCCOA','URN','RHCSV-RHEA','INDMSWORG','TRAHYL','BIOOIL','ELCMSC','SERHYG'
                ,'UPSELC','RESPELH','TRABIOLFO','RESLFO','INDBIOLFO','SERKER','INDLFO','IFDSTM','RESMSWINO','RESMSWORG') --Filter 207
    ) a
    where proc_set is not null group by tablename, period order by tablename,period
)
,rsr_export as(
-- This is the veda BE table
    select sum(case when proc_set='EXPORT BIOMASS' then pv else 0 end) "EXPORT BIOMASS"
-- NB is no biomass export in the model
        ,sum(case when proc_set='EXPORT COAL' then pv else 0 end) "EXPORT COAL"
        ,sum(case when proc_set='EXPORT COKE' then pv else 0 end) "EXPORT COKE"
        ,sum(case when proc_set='EXPORT ELC' then pv else 0 end) "EXPORT ELC"
        ,sum(case when proc_set='EXPORT ETH' then pv else 0 end) "EXPORT ETH"
        ,sum(case when proc_set='EXPORT NGA' then pv else 0 end) "EXPORT NGA"
        ,sum(case when proc_set='EXPORT OIL' then pv else 0 end) "EXPORT OIL"
        ,sum(case when proc_set='EXPORT DST' then pv else 0 end) "EXPORT DST"
        ,sum(case when proc_set='EXPORT HFO' then pv else 0 end) "EXPORT HFO"
        ,sum(case when proc_set='EXPORT JET' then pv else 0 end) "EXPORT JET"
        ,sum(case when proc_set='EXPORT KER' then pv else 0 end) "EXPORT KER"
        ,sum(case when proc_set='EXPORT LFO' then pv else 0 end) "EXPORT LFO"
        ,sum(case when proc_set='EXPORT LPG' then pv else 0 end) "EXPORT LPG"
        ,sum(case when proc_set='EXPORT MOIL' then pv else 0 end) "EXPORT MOIL"
        ,sum(case when proc_set='EXPORT GSL' then pv else 0 end) "EXPORT GSL"
        ,tablename,period
    from (
        select tablename,period, pv,
            case
                when process in('EXPCOA','EXPCOA-E') then 'EXPORT COAL' --Filter 282
                when process in('EXPCOK') then 'EXPORT COKE' --Filter 251
                when process in('EXPELC-EU','EXPELC-IRE') then 'EXPORT ELC' --Filter 340
                when process in('EXPETH') then 'EXPORT ETH' --Filter 322
                when process in('EXPNGA-E','EXPNGA-EU','EXPNGA-IRE') then 'EXPORT NGA' --Filter 389
                when process in('EXPOILCRD1','EXPOILCRD1-E','EXPOILCRD2') then 'EXPORT OIL' --Filter 276
                when process in('EXPOILDST') then 'EXPORT DST' --Filter 327
                when process in('EXPOILHFO') then 'EXPORT HFO' --Filter 266
                when process in('EXPOILJET') then 'EXPORT JET' --Filter 346
                when process in('EXPOILKER') then 'EXPORT KER' --Filter 253
                when process in('EXPOILLFO') then 'EXPORT LFO' --Filter 372
                when process in('EXPOILLPG') then 'EXPORT LPG' --Filter 387
                when process in('EXPOILMSC') then 'EXPORT MOIL' --Filter 374
                when process in('EXPOILPET') then 'EXPORT GSL' --Filter 356
            end as proc_set
        from vedastore
        where attribute='VAR_FIn'
            and commodity in('SYNCOA','RESLPG','TRAMAINSBOM','BPELH','SERBUILDELC','ELCGEN','HYGLHPT','INFOTH','INMHTH','RHUFLOOR-HC','INDCOG','SHLDELVRAD'
                ,'SERHFO','RHEATPIPE-HS','SERMSWINO','BWOD','OILLFO','RHUFLOOR-FS','SHHDELVRAD','SWHDELVSTD','INDMAINSGAS','IISELCC','TRALNGDSL','ICHPRO'
                ,'TRALPGL','BSUGAR','IPPLTHD2','TRAETHS','TRAMAINSGAS','RESHYGREF-FS','RHUFLOOR-HS','RWSTAND-EA','ELCSURPLUS','RESLTHSURPLUS-FS','INDHFO','RESELC-NS-HC'
                ,'BIOLFO','ELC-I-EU','LNG','SCHCSVDMD','RHUFLOOR-FC','IPPLTHP','TRALNG','ELCBOG-LF','TRAETHL','ELCTRANSBOM','ELCGEO','TRAHFO'
                ,'RESELC-NS-EA','SERLFO','TRAPETL','IFDOTH','ELCMAINSBOM','RHCSV-RHHS','TRAJETDA','RWSTAND-HC','TRABIOLFODSL','INDPELH','WAV','ELCSOL'
                ,'IOIOTH','IOIREF','TRABIODST-FT','INDWOD','INMOTH','PWASTEDUM','ICHHTH','NGA-I-N','RESHYGREF-FC','TRAPETS','HYDDAM','NGA-E-EU'
                ,'UPSLFO','INDMSWINO','SHLCSVDMD','IISNGAB','IOIMOT','SLOFCSV','TRAJETDAEL','IISCOKS','BFG','INDLPG','PRCHFO','ELCBOG-AD'
                ,'ELCBIOOIL','INDNEULPG','RESHYGREF-EA','BSTWWST','IISBFGC','BSTARCH','ELCLPG','IPPELCO','TRABIODST','IISCOKE','ICHREF','IISLTHS'
                ,'AGRHYG','IISBFGB','SERMSWORG','IPPLTHD4','NGA-E-IRE','RHSTAND-HC','URN045','RHCSV-RHFC','RESBOM','IOILTH','IPPLTHD','INDBENZ'
                ,'IPPLTHD3','SERBUILDGAS','RESHYGREF-HC','SERNGA','TRAELC','BSLURRY','ELCWNDONS','IOIHTH','TRAHFOIS','ETH','INDNEUNGA','TRANGA'
                ,'BRSEED','INDNGA','TRALNGIS','IISLTHE','SHLCSV','TRAPET','TRABIODSTS','TRALFODSL','BOG-LF','IPPLTHD5','RESWODL','INDKER'
                ,'INFMOT','RWCSV-RWHS','ELCHFO','ELCLFO','IISLTH','TRALNGDS','IFDMOT','IISELCE','IISELCB','INDWODWST','IPPELCD','SERMSWBIO'
                ,'INDBIOOIL','IPPELCD4','ELCMAINSGAS','INDBOG-AD','INDCOA','ELCBIOCOA','PREFGAS','AGRLFO','RESHOUSEELC','RESLTHSURPLUS-HS','RESMAINSBOM','MSWBIO'
                ,'ELCPELL','COK','RESHOUSEBOM','ELC','IISCOGB','IISCOGC','INDCOACOK','TRAJETIAEL','UPSHEAT','AGRMAINSBOM','ELCBOM','COG'
                ,'ELCTRANSGAS','INMDRY','TRAHFODSL','AGRGRASS','TRALFO','OILLPG','PCHPHEAT','WNDOFF','INDGRASS','HYGL-IGCC','BVOIL','RESELC-NS-HS'
                ,'RESLTH-FC','ELCSTWWST','INDSTM','MSWORG','RHSTAND-FS','TRAJETIA','UPSNGA','WAT','SERELC','ELCCOG','RESLTHSURPLUS-EA','AGRDISTELC'
                ,'TRADISTELC','RESLFO','RWCSV-RWFC','TRABIOLFO','IPPELCD5','TRAJETIANL','INDBIOLFO','AGRELC','SERBOG','URND','SERKER','HYDROR'
                ,'IFDSTM','INDLFO','IPPLTHO1','RESLTH-EA','SHLDELVUND','TRABIOOILISL','NGAPTR','RHUFLOOR-EA','TRABIOLFODS','BIOOIL','ELCMSC','SERHYG'
                ,'SWHDELVPIP','AGRMAINSGAS','METH','UPSELC','BIODST-FT','IPPLTHD1','RESHYGREF-HS','RESPELH','RHEATPIPE-FS','TRALNGISL','ELCCOA','INDCOK'
                ,'URN','RHCSV-RHEA','ICHLTH','INDMSWORG','RWSTAND-FS','ICHSTM','IISNGAE','SWLDELVSTD','RESCOA','SERWOD','INDELC','OILCRD'
                ,'RHSTAND-EA','SERLPG','SHHCSVDMD','ELCMSWORG','ELCWSTHEAT','SOL','HYGLHPD','SERELC-NS','PRCOILCRD','IPPELCD1','PRCCOA','RHCSV-RHFS'
                ,'AGRBIODST','IISLTHB','RWCSV-RWFS','BOG-AD','OILKER','PRCNGA','SERBOM','TRALFODS','BIOJET-FT','URN19','NGA-I-EU','OILCRDRAW'
                ,'SYNOIL','IOISTM','AGRBIOLPG','IISCOACOKB','RESHYG','ELCPELH','IPPELCD3','MSWINO','WNDONS','OILCRDRAW-E','SHHCSV','AGRLPG'
                ,'HYLTK','AGRBOM','ELCBIOLFO','ELCHYG','ICHDRY','URN09','HYL','ISO','OILDST','INDMAINSBOM','INMLTH','RESLTHSURPLUS-FC'
                ,'TRAHFODS','RESSOL','INDPELL','RESELC-NS-FS','RESLTH-HC','BIOLPG','ELCMAN','TRALFOL','PRCELC','BWODWST','IISCOKB','ICHOTH'
                ,'RWSTAND-HS','TID','ICHMOT','RESHOUSEGAS','TRABIOJET-FTIA','RESBIOLFO','AGRCOA','INDDISTELC','IISNGAC','RWCSV-RWEA','IFDREF','RHEATPIPE-FC'
                ,'SERDISTELC','INMSTM','RESLTH-HS','IISELCS','IISLTHC','RESELC-NS-FC','TRADSTS','SERLTH','TRALPG','ELCURN','OILHFO','TRABIOJET-FTIAL'
                ,'RHSTAND-HS','TRABIOJET-FTDAL','SERCOA','SERSOL','NGA-E','RESLTH-FS','BIODST','ELCNGA','IPPELCD2','IPPELCP','INDBOG-LF','IISTGS'
                ,'RESKER','INDSYNCOA','RWSTAND-FC','IISHFOB','INDBFG','INDSYNOIL','ELCBOG-SW','URNU','IPPLTHO','TRABIOLFOL','IPPLTH','INDPOLWST'
                ,'SHHDELVAIR','RESCOK','ELCBFG','RESNGA','SERHYGREF','INMMOT','TRAMETH','INFHTH','SERMAINSBOM','ELCPOLWST','SERLTHSURPLUS','BPELL'
                ,'TRAJETL','OILJET','TRAETH','SERBIOLFO','ELC-E-EU','BWODLOG','RHCSV-RHHC','TRADSTL','OILMSC','OILPET','SERMAINSGAS','RHSTAND-FC'
                ,'SERGEO','BOG-G','IOIDRY','SHLDELVAIR','TRABIOOILIS','INDHYG','RESELCSURPLUS','COA-E','GEO','BSEWSLG','TRAHFOISL','AGRHFO'
                ,'COA','ELC-E-IRE','IFDDRY','RESELC','RWCSV-RWHC','TRABIODSTL','TRABOM','TRABIOJET-FTDA','INDBIOLPG','AGRNGA','AGRPOLWST','ELCMSWINO'
                ,'IPPELCO1','RESMAINSGAS','RHEATPIPE-HC','RESLTHSURPLUS-HC','INDNEULFO','TRACOA','ELCHYDDAM','ELCWNDOFS','BOM','SERPELH','RHEATPIPE-EA','BGRASS'
                ,'INDNEUMSC','INDBOM','BENZ','TRADST','SERBUILDBOM','ELC-I-IRE','NGA','RESDISTELC','SCHDELVAIR','BIOKER-FT','TRALPGS','COACOK'
                ,'IFDLTH','PRCCOACOK','RESWOD','RESMSWINO','RESMSWORG')  --Filter 208
    ) a
    where proc_set is not null group by tablename, period order by tablename,period
)
,nuclear as(
    select sum(pv)/0.398 "ELC FROM NUCLEAR",
-- this is DUKES 2013 paragraph 5-46 thermal efficiency of nuclear plants [says 36% for new PWR]
        tablename,period
    from vedastore
    where attribute='VAR_FOut'
        and commodity in('ELCDUMMY','ELC','ELC-E-IRE','ELC-E-EU','ELCGEN')
        and process in('ENUCPWR101','ENUCPWR102','ENUCPWR00')  --Filter 209
    group by tablename,period order by tablename,period
 )
,domestic_bio as (
-- this is wood and waste wood produced by forestry options in UKTM not clear model is constrained to actually use it
-- Have to set up a 'pre-populated' table with zeros in each year as extra bioenergy may not be produced in every model year
-- Only the ALUFOR04A part of energy forestry produces wood
    select a.tablename, a.period,sum(a.bio+case when b.bio>0 then b.bio else 0 end) "DOMESTIC BIO PROD"
    from (
        select distinct tablename, period, 0::numeric "bio" from vedastore
        where period in('2010','2011','2012','2015','2020','2025','2030','2035','2040','2045','2050','2055','2060')
    ) a left join (
        select sum(pv) "bio",tablename,period
        from vedastore
        where attribute='VAR_FOut' and commodity in('BWODWST','BWOD')
            and process in('ALUFOR02','ALUFOR03','ALUFOR04A')  --Filter 410
        group by tablename,period
        order by tablename,period
    ) b on a.tablename=b.tablename and a.period=b.period
    group by a.tablename,a.period
    order by a.tablename,a.period
)
,end_demand as(
    select
        sum("MINING BIOMASS")+sum("DOMESTIC BIO PROD")+sum("IMPORT BIOMASS")+sum("IMPORT BDL")+sum("IMPORT BIOOIL")
            +sum("IMPORT ETHANOL")+sum("IMPORT FTD")+sum("IMPORT FTK-AVI")-SUM("EXPORT ETH")-sum("EXPORT BIOMASS") "bio"
-- NB is no biomass export in the model
        ,sum("MINING COAL")+sum("IMPORT COAL")-sum("EXPORT COAL")+sum("IMPORT COKE")-sum("EXPORT COKE") "coa"
        ,sum("IMPORT ELC")-sum("EXPORT ELC") "elec"
        ,sum("MINING NGA")+sum("IMPORT NGA")+sum("MINING NGA-SHALE")-sum("EXPORT NGA") "gas"
        ,sum("IMPORT HYL") "h2"
        ,sum("MINING OIL")+sum("IMPORT OIL")-sum("EXPORT OIL")+sum("IMPORT DST")+sum("IMPORT GSL")+sum("IMPORT HFO")+sum("IMPORT JET")+
        sum("IMPORT KER")+sum("IMPORT LFO")+sum("IMPORT LPG")+sum("IMPORT MOIL")-sum("EXPORT DST")-sum("EXPORT GSL")
        -sum("EXPORT HFO")-sum("EXPORT JET")-sum("EXPORT KER")-sum("EXPORT LFO")-sum("EXPORT LPG")-sum("EXPORT MOIL") "oil"
        ,sum("MINING HYDRO")+sum("MINING WIND")+sum("MINING SOLAR")+sum("MINING GEOTHERMAL")+sum("MINING TIDAL")+sum("MINING WAVE") "rens"
        ,sum(d."ELC FROM NUCLEAR") "nuc"
    ,sum("MINING INORGANIC WASTE") "was"
        ,a.period,a.tablename
    from rsr_min a join rsr_imports b
    on a.period=b.period and a.tablename=b.tablename left join rsr_export c 
    on a.period=c.period and a.tablename=c.tablename left join nuclear d 
    on a.period=d.period and a.tablename=d.tablename left join domestic_bio e
    on a.period=e.period and a.tablename=e.tablename
    group by a.tablename,a.period order by a.period
)
select 'pri-en_' || cols || '|' || tablename || '|various|various|various'::varchar "id",
-- Primary energy cross-tab
    'pri-en_'|| cols::varchar "analysis",
    tablename,
    'various'::varchar "attribute",
    'various'::varchar "commodity",
    'various'::varchar "process",
    sum(vals) "all",
    sum(case when a.period='2010' then vals else 0 end) as "2010",
    sum(case when a.period='2011' then vals else 0 end) as "2011",
    sum(case when a.period='2012' then vals else 0 end) as "2012",
    sum(case when a.period='2015' then vals else 0 end) as "2015",
    sum(case when a.period='2020' then vals else 0 end) as "2020",
    sum(case when a.period='2025' then vals else 0 end) as "2025",
    sum(case when a.period='2030' then vals else 0 end) as "2030",
    sum(case when a.period='2035' then vals else 0 end) as "2035",
    sum(case when a.period='2040' then vals else 0 end) as "2040",
    sum(case when a.period='2045' then vals else 0 end) as "2045",
    sum(case when a.period='2050' then vals else 0 end) as "2050",
    sum(case when a.period='2055' then vals else 0 end) as "2055",
    sum(case when a.period='2060' then vals else 0 end) as "2060"
    from
    (
        SELECT unnest(array['bio','coa','elc','gas','hyd','oil','orens','nuc','was']) as "cols",
           tablename,period,
           unnest(array[bio,coa,elec,gas,h2,oil,rens,nuc,was]) AS "vals"
        FROM end_demand
    ) a
group by tablename,cols
UNION ALL
-- Biomass domestic, imported and exported
select 'bio-en_' || cols || '|' || tablename || '|VAR_FOut|various|' || process::varchar "id",
    'bio-en_'|| cols::varchar "analysis",
    tablename,
    'VAR_FOut'::varchar "attribute",
    'various'::varchar "commodity",
    process,
    sum(vals) "all",
    sum(case when a.period='2010' then vals else 0 end) as "2010",
    sum(case when a.period='2011' then vals else 0 end) as "2011",
    sum(case when a.period='2012' then vals else 0 end) as "2012",
    sum(case when a.period='2015' then vals else 0 end) as "2015",
    sum(case when a.period='2020' then vals else 0 end) as "2020",
    sum(case when a.period='2025' then vals else 0 end) as "2025",
    sum(case when a.period='2030' then vals else 0 end) as "2030",
    sum(case when a.period='2035' then vals else 0 end) as "2035",
    sum(case when a.period='2040' then vals else 0 end) as "2040",
    sum(case when a.period='2045' then vals else 0 end) as "2045",
    sum(case when a.period='2050' then vals else 0 end) as "2050",
    sum(case when a.period='2055' then vals else 0 end) as "2055",
    sum(case when a.period='2060' then vals else 0 end) as "2060"
    from
    (
        select 'dom-prod' "cols", 'various' "process", "MINING BIOMASS"+"DOMESTIC BIO PROD" "vals", a.period, a.tablename from rsr_min a
        join domestic_bio b on a.tablename=b.tablename and a.period=b.period
        union all
        select 'imports' "cols", 'various' "process",
            "IMPORT BDL"+"IMPORT BIOOIL"+"IMPORT ETHANOL"+"IMPORT FTD"+"IMPORT FTK-AVI"+"IMPORT BIOMASS" "vals", period, tablename from rsr_imports
        union all
        select 'exports' "cols", 'various' "process",
            "EXPORT BIOMASS"+"EXPORT ETH" "vals", period, tablename from rsr_export
    -- NB There is no biomass export in the model
    ) a
group by tablename,cols,process
ORDER BY tablename,analysis
 ) TO '%~dp0PriEnOut.csv' delimiter ',' CSV;
  /* **End of Main "key outputs" BAT (MainBatchUpload.bat)** */
  
-- Change log follows:
 -- 3:07 PM 12 January, 2016. Changes include:
    -- revisions to code (more compact, faster; substituting subqueries for unions.)
    -- Changing [standardising] nomenclature.
    -- Reordering queries to put related things together
    -- New queries:- incorporating stand alone queries for (e.g. elec gen)
    -- Expansion of existing queries (e.g. cars=> all road vehicles)
-- 12:59 PM 14 January, 2016:
    -- correction to case...when statement for all vehicles to ensure more refined filters come first (prevent incorrect assignments)
    -- All other case...whens in other queries checked
    -- Other syntactic refinements
    -- Standardisation of commodities etc with the equivalent component of the id
    -- Addition of new build vehicles
-- 5:14 PM 14 January, 2016
    -- Addition of the marginal emissions prices analysis
-- 1:42 PM 15 January, 2016
    -- Addition of ghg by sector analysis
-- 2:02 PM 01 February, 2016
    -- Addition of whole vehicle stock capacity, some changes to descriptions
-- 2:42 PM 04 February, 2016
    -- Addition of new vehicle emissions intensity (cars,lgs,hgv)
-- 1:38 PM 08 February, 2016
    -- Correction of the new veh emissions intensity to remove misleading CNG conversion GHG
    -- change of new residential heat capacity to new res heat output
    -- added objective function to costs by sector, and deleted "all costs" query
    -- changed biofuel to not report biofuel (broad) type, just overall quantity
    -- whole stock vehicle kms, emissions amalgamated to single query; original kms one removed. Expanded to 19 veh types
    -- "CHP & other elec generation" query removed (was sum of individual queries for CHP and other gen, within rounding errors: largest difference = 7.95808E-12)
    -- GHG from electricity generation; Elec Interconnectors; Electricity Generation and Elec waste heat removed (duplicated in "GHG emissions by sector" or the revised
    -- Electricity generation by source query)
    -- Electricity generation by source revised to include a temporary table giving total generation & interconnectors
    -- Services whole stock, and new build heat output added
    -- Addition of dummy imports by table, incomplete industrial fuel use by sub-sector
    -- Elec generation part of the chp emissions generated/saved query removed
-- 7:50 PM 04 April, 2016:
    -- Addition of final energy demand by main sector
-- 1:48 PM 12 April, 2016:
    -- Addition of primary energy demand by main fuel, correction of errors in previous query
-- 5:49 PM 26 April, 2016:
    -- Conversion of some wildcard filters into explicit lists of commodities/processes
-- 4:44 PM 16 May, 2016:
    -- [changes listed here represent those over a period but prior to the next major released]
    -- Addition of 2 LNG processes for TRA to the main final energy demand query
    -- Changed the name of the CTEs in the final energy demand by sector to reflect Veda BE table names and expanded defs to match
    -- Corrected small error in final energy CHP services calc part of the final e by end user [was referring to res chp, not ser]
    -- elec-gen_exports, elec-gen_imports removed from elec gen by source. 'elec-gen_total' renamed 'elec-gen_total-cen', 'elec-gen_inter' renamed 'elec-gen_intercon'
    -- corrected an error in the biofuels q [missing commodity filter]
    -- Changes to main final energy q to make its sub-queries better conform to Veda BE tables
    -- Correction to minor error in services chp heat sub query where filter was preventing some tech being included
    -- "All" costs added back into costs q
    -- Biofuels by sector q removed (is in final e- by sector q)
    -- Addition of bio- domestic production, imports and exports (added to primary energy q). Addition of dummy code for exported biomass to primary e quality (doesn't
    -- exist in model)
    -- Addition of FE use for h2 production to FE use by sector q
    -- Changed GHG by sector so that ETS is nett emissions
    -- Correction to e- gen. q: total excluded elec-gen_h2, elec-gen_other-ccs. elec-gen_h2 added into orens, e- gen q aligned with UCL template
    -- CHP emissions from generation removed, grid intensity (which incorporates emissions from CHP) added to elec gen by source
    -- Addition of emissions by industrial sub-sector
-- 5:36 PM 01 July, 2016:
    -- Elec gen. q updated to be net of heat offtake penalty. Sources now report e- only (waste heat reported separately)
    -- FE by end user expanded to include e- for H2 prod, for elec and for process sector
    -- GHG sequestered by industry sub-sector added
-- 5:21 PM 08 July, 2016:
    -- E85 added for vehicle qs
-- 8:50 PM 14 July, 2016:
    -- Changes to vehicle queries including apportioning of emissions for CNG vehicles, adding total lines, and calculating emission intensity. Also broke out buses and "bikes" as new categories.
    -- These transport queries moved to new batch file; agriculture / LULUCF formatted qs moved into this (present) file.
-- 4:12 PM 11 August, 2016:
    -- Changed to match updated model (uktm_model_v1.2.3_d0.1.2_DNP) with some elc gen techs removed (ENUCAGRN00, ENUCAGRO00) and a couple added (ENGARCPE0*,EDSTRCPE0*). Sign of the interconn- reversed.
    -- Changes made to elec gen by source and capacity by type
-- 2:43 PM 12 August, 2016:
    -- Corrections to script including change from VAR_ComnetM to EQ_CombalM
-- 7:47 PM 12 August, 2016:
    -- Consistency check and correction of all set definitions (were some legacy errors from Veda BE)
-- 7:58 PM 18 August, 2016:
    -- Changed definitions of the co-firing tables for oil (changed to commodity consumed basis). Updated the co-firing %s (block 2036ff) to reflect model change so CCS retrofits are no longer a subset of retrofit ready
    -- Minor correction to include 2 ccs demo plant types. Addition of filter identifiers to help in maintaining queries when model changes.
-- 5:24 PM 22 August, 2016:
    -- Correction to grid intensity calculation (sign of interconnection changed to reflect change on 11th Aug.) Removed asterisks from filter numbers. Added ser hydrogen cell "chp" to some filters where missing
-- 5:34 PM 25 August, 2016:
    -- "elc from imports" set wrong (not include ireland); corrected. Filters for new build heat output (res/ser) changed to exclude base year techs
-- 7:12 PM 31 October, 2016:
    -- Addition of miscellaneous queries section with q for other industry fuel use
-- 7:49 PM 15 November, 2016:
    -- Correction of error in FUEL TECHS AGR set to remove mains distribution pipes, AMAINPHYG01, AMAINPGAS01. Added TRA_Fuel_by_mode to transport batch file section of code (temporary measure)
-- 5:25 PM 17 November, 2016:
    -- Correction: FUEL TECHS TRA = domestic and international shipping added ('TRALNGDS01','TRALNGIS01')
-- 4:46 PM 28 November, 2016:
    -- [Jon Tecwyn] Addition of HGV disaggregation to filters 8,11,13,14,222.
-- 5:42 PM 2 December, 2016: 
    -- [Jon Tecwyn] Amended "Whole stock heat output for services" query.
-- 2:23 PM 12 December, 2016:
    -- FS Added filter IDs to all remaining filters and refactored the international shipping and aviation table to conform to these filters. corrected gas CCS code.
-- 2:55 PM 15 December, 2016:
    -- BF edited Filter 131, 'heat-res_conserv'. Added 'RHEACSVWIN01','RHEACSVFLU01','RHEACSVDFT01','RHEACSVCON01','RHEACSVCYL01'. Removed 'RHEACSV01','RHEACSVLOF02','RHEACSVSOL02','RHEACSVSOL03'
    -- BF edited Filter 146, 'new-heat-res_conserv'. Added 'RHEACSVWIN01','RHEACSVFLU01','RHEACSVDFT01','RHEACSVCON01','RHEACSVCYL01'. Removed 'RHEACSV01','RHEACSVLOF02','RHEACSVSOL02','RHEACSVSOL03'
-- 1:50 PM 16 December, 2016
    -- BF added 'RESMSWINO','RESMSWORG' to Filters 287,206,207,208 to match locations of equivalent service sector commodities 'SERMSWINO','SERMSWORG' 
    -- BF added 'RESMSWINO01','RESMSWORG01' to Filter 304 'Fuel Techs RES' to match equivalent locations of equivalent service sector Fuel Techs 'SERMSWINO01','SERMSWORG01'
-- 3:00 PM 16 December, 2016
    -- BF added residential EFW CHP, 'RCHPEA-EFW01','RCHPNA-EFW01' to Filters 79,114,303,335
    -- BF added services EFW CHP, 'SCHP-EFW01' to Filters 79,114,230,368
-- 6:33 PM 12 January, 2017
    -- FS: overall electrical storage capacity query divided into main storage types (water, compressed air, battery)
    -- Removed all the casts to varchar from filters (applied to column names instead)
    -- Addition of electricity storage in / out query for electricity batch file
-- 4:11 PM 13 January, 2017: FS: Broke out easy-/-hard to fill cavity insulation + system build solid from residential heat query and amended the other conservation measures to exclude these. Changed filters to remove redundancy on new/old, res/serv heat qs
-- 2:31 PM 20 January, 2017: FS: added storage techs to the electrical capacity q and simplified the filters there
    -- Added a new transport fuels by road transport query to transport batch
-- 9:02 PM 26 January, 2017: FS correction to filters for electric heaters and heat pumps in residential
-- 6:20 PM 30 January, 2017: FS change to primary en q to separate out inorganic waste from bio and associated change to filters; include agri livestock etc emissions baseline in defra measures q
-- 6:34 PM 31 January, 2017: FS Change to GHG by sector to remove CH4 captured by landfill mitigation measures. Additional q to ag batch to report landfill mitigation. Change to primary energy query to include biomass from forestry, and change of process label from "MINING BIOMASS" to 'various'; for non-ETS waste changed attribute from 'VAR_FOut' to 'various'
-- 12:49 PM 06 February, 2017: FS removal of prefix from some res heat q prefixes
-- 3:40 PM 07 February, 2017: FS Changed the agriculture mitigation q; LULUCF BAU emissions separated out from soil, slurry emissions added to livestock/crop BAU
-- 4:29 PM 23 February, 2017: FS: change to filter 7,57 (add GHG-NO-AS-YES-LULUCF-NET),59,62 (add 'GHG-DAS-ETS','GHG-DAS-NON-ETS' to both); REMOVE GHG-TRA-ETS-NO-IAS (all). GHG-TRA-NON-ETS-NO-IAS replaced with GHG-TRA-NON-ETS-NO-AS
-- 15:28 3 March, 2017: FS change to forestry filters due to energy forestry being split over 2 tied techs
-- 07:27 6 March, 2017: FS changed "!=" to "<>" in transport query as former difficult to escape in DOS
-- 8:59 PM 09 March, 2017: FS change to marginal prices to reflect change in filter
-- 7:34 PM 24 April, 2017: FS change to reflect automated production of BAT files from this master (see ruby code)
-- 12:22 01 June 2017: FS changed elecgen query to make more robust and efficient (refactored)