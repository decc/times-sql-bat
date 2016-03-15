/* ***Human readable versions of "standard" queries*** 
...with annotations
NB for electricity and emissions, only have the individual rows which go into the calculations, not the aggregated results. Have to calculate these in an XLS
Note also, emissions saved are often blank (don't) exist in the VD files. These rows will be missing from the outputs if missing from the VD inputs.

Original version:
FS 7:12 PM 20-Nov-15
Revised:
3:07 PM 12 January, 2016. Changes include:
    revisions to code (more compact, faster; substituting subqueries for unions.)
    Changing [standardising] nomenclature.
    Reordering queries to put related things together
    New queries:- incorporating stand alone queries for (e.g. elec gen)
    Expansion of existing queries (e.g. cars=> all road vehicles)
12:59 PM 14 January, 2016:
    correction to case...when statement for all vehicles to ensure more refined filters come first (prevent incorrect assignments)
    All other case...whens in other queries checked
    Other syntactic refinements
    Standardisation of commodities etc with the equivalent component of the id
    Addition of new build vehicles
5:14 PM 14 January, 2016
    Addition of the marginal emissions prices analysis
1:42 PM 15 January, 2016
    Addition of ghg by sector analysis
2:02 PM 01 February, 2016
    Addition of whole vehicle stock capacity, some changes to descriptions
2:42 PM 04 February, 2016
    Addition of new vehicle emissions intensity (cars,lgs,hgv)
1:38 PM 08 February, 2016
    Correction of the new veh emissions intensity to remove misleading CNG conversion GHG
    change of new residential heat capacity to new res heat output
    added objective function to costs by sector, and deleted "all costs" query
    changed biofuel to not report biofuel (broad) type, just overall quantity
    whole stock vehicle kms, emissions amalgamated to single query; original kms one removed. Expanded to 19 veh types
    "CHP & other elec generation" query removed (was sum of individual queries for CHP and other gen, within rounding errors: largest difference = 7.95808E-12)
    GHG from electricity generation; Elec Interconnectors; Electricity Generation and Elec waste heat removed (duplicated in "GHG emissions by sector" or the revised 
    Electricity generation by source query)
    Electricity generation by source revised to include a temporary table giving total generation & interconnectors
    Services whole stock, and new build heat output added
    Addition of dummy imports by table, incomplete industrial fuel use by sub-sector
    Elec generation part of the chp emissions generated/saved query removed
    
    ********* NB May need to add a line for CHP emissions due to generation to emissions by sector **************
    
    Broken into blocks to get around the DOS character limits
*/

/* ******List of completed queries*******/
/* *Dummy imports by table* */
/* *All GHG emissions* */
/* *GHG emissions by sector* */
/* *CHP emissions from electricity generation* */
/* *Electricity generation by source* */
/* *Elec storage* */
/* *Electricity capacity by process* */
/* *Biofuels by sector* */
/* *Costs by sector and type* */
/* *Marginal prices for emissions* */
/* *Whole stock heat output by process for residential* */
/* *New build residential heat output by source* */
/* *Whole stock heat output for services* */
/* *New build services heat output by source* */
/* *Whole stock vehicle kms, emissions for 19 vehicle types and CNG use (car, lgv, hgv)* */
/* *New vehicle kms, emissions for 19 vehicle types and CNG use (car, lgv, hgv)* */
/* *Whole stock capacity for vehicles for 19 vehicle types* */
/* *New build vehicle capacity for 19 vehicle types* */

/* *** Emissions and electricity generation *** */
/*The relevant queries are concatenated together in the batch file script so that the lines appear together. Are broken into 
individual queries here for clarity
Note that summing items together is easy (just change the filter to the union of the 2 individual filters) but
subtracting lines is more difficult. I've not had time to implement this.

analysis
tablename
attribute
commodity
process
*/

/* *Dummy imports by table* */
/* NB this only sums Cost_Act to see impact on the objective function*/

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
where process like 'IMP%Z' and attribute = 'Cost_Act'
group by tablename
order by tablename, analysis;

/* *All GHG emissions* */
/*Was ghg; now ghg_all*/

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
where attribute='VAR_FOut' and commodity in('GHG-ETS-NO-IAS-NET', 'GHG-ETS-NO-IAS-TER', 'GHG-ETS-YES-IAS-NET', 'GHG-ETS-YES-IAS-TER', 'GHG-NO-IAS-YES-LULUCF-NET', 'GHG-NO-IAS-YES-LULUCF-TER', 'GHG-NON-ETS-YES-LULUCF-NET', 'GHG-NON-ETS-YES-LULUCF-TER', 'GHG-YES-IAS-YES-LULUCF-NET', 'GHG-YES-IAS-YES-LULUCF-TER')
group by tablename, commodity
order by tablename, commodity;

/* *GHG emissions by sector* */
/*Energy-related process CO2 is reported separately. Non-energy process CO2, CH4, N20 etc are lumped. Separate line
for ETS traded emissions. Otherwise, broken down by commodities. Analysis field entries:
'ghg_sec-main-secs'    main sector breakdown
'ghg_sec-prc-ets'    energy-related CO2 process emissions from ETS
'ghg_sec-prc-non-ets'    Other non-ETS (process-related) emissions like CH4,N2O
'ghg_sec-traded-emis-ets'    traded ETS emissions
*/
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
    select 'all'::varchar(50) "process", period, pv,
    tablename, attribute,
    case
            when commodity in('PRCCO2P', 'PRCCH4N', 'PRCCH4P', 'PRCN2ON', 'PRCN2OP') then 'various'
            else commodity
    end as "commodity",
    case when attribute='VAR_FIn' then 'ghg_sec-traded-emis-ets'
        when commodity in('GHG-ELC','GHG-IND-ETS','GHG-RES-ETS','GHG-SER-ETS','GHG-OTHER-ETS','GHG-TRA-ETS-NO-IAS','GHG-IAS-ETS',
        'GHG-IAS-NON-ETS','Traded-Emission-ETS','GHG-IND-NON-ETS','GHG-RES-NON-ETS','GHG-SER-NON-ETS','GHG-TRA-NON-ETS-NO-IAS',
        'GHG-AGR-NO-LULUCF','GHG-OTHER-NON-ETS','GHG-LULUCF','Traded-Emission-Non-ETS','GHG-ELC-CAPTURED','GHG-IND-ETS-CAPTURED',
        'GHG-IND-NON-ETS-CAPTURED','GHG-OTHER-ETS-CAPTURED') then 'ghg_sec-main-secs'
        when commodity in('PRCCO2P', 'PRCCH4N', 'PRCCH4P', 'PRCN2ON', 'PRCN2OP')  then 'ghg_sec-prc-non-ets'
        when commodity ='PRCCO2N' then 'ghg_sec-prc-ets'
    end as "analysis"
    from vedastore
    where (attribute='VAR_FOut' and commodity in('GHG-ELC','GHG-IND-ETS','GHG-RES-ETS','GHG-SER-ETS','GHG-OTHER-ETS','GHG-TRA-ETS-NO-IAS','GHG-IAS-ETS','GHG-IAS-NON-ETS','Traded-Emission-ETS','GHG-IND-NON-ETS','GHG-RES-NON-ETS','GHG-SER-NON-ETS','GHG-TRA-NON-ETS-NO-IAS','GHG-AGR-NO-LULUCF','GHG-OTHER-NON-ETS','GHG-LULUCF','Traded-Emission-Non-ETS','GHG-ELC-CAPTURED','GHG-IND-ETS-CAPTURED','GHG-IND-NON-ETS-CAPTURED','GHG-OTHER-ETS-CAPTURED','PRCCO2P','PRCCH4N','PRCCH4P','PRCN2ON','PRCN2OP','PRCCO2N')) or (attribute='VAR_FIn' and commodity='Traded-Emission-ETS')
) a
where analysis <>''
group by id, analysis,tablename, attribute, commodity,process
order by tablename,  analysis, attribute, commodity;

/* CHP emissions from electricity generation* */
/*
2a) chp-out_emis = Emissions generated
2b) chp-sav_emis = emissions saved

Component of overall grid intensity calculations. Elec generated is in the generation by source query
*/

select analysis || '|' || tablename || '|VAR_FOut|' || commodity || '|' || process::varchar(300) "id", analysis, tablename,attribute,
        commodity,process,
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
    select  '*CHP*'::varchar(50) "process",period,pv,
    case 
        when commodity in ('GHG-IND-NON-ETS-CAPTURED','GHG-OTHER-ETS-CAPTURED','GHG-IND-ETS-CAPTURED') then 'chp-sav_emis'::varchar(25)
        when commodity in ('GHG-IND-ETS','GHG-IND-NON-ETS','GHG-OTHER-ETS','GHG-OTHER-NON-ETS') or commodity like 'PRCCH4%' or commodity like 
            'PRCCO2%' or commodity like 'PRCN2O%' or commodity like 'GHG-RES-%' or commodity like 'GHG-SER-%' then 'chp-out_emis'::varchar(25)
    end as "analysis",
    tablename, attribute,'various'::varchar(50) "commodity"
    from vedastore
    where attribute = 'VAR_FOut' and (process like 'I%CHP%' or process like 'P%CHP%' or process like 'R%CHP%' or process like 'S%CHP%' or process like 'U%CHP%')
) a
where analysis <>''
group by id, analysis,tablename, attribute, commodity,process
order by tablename,  analysis, attribute, commodity;

/* *Electricity generation by source* */
/*A previous version had following names (replaced by right hand col):

ElcGen_Bio    elec-gen_bio
ElcGen_BioCCS    elec-gen_bio-ccs
ElcGen_Coal    elec-gen_coal
ElcGen_CoalCCS    elec-gen_coal-ccs
ElcGen_Hydrogen    elec-gen_h2
ElcGen_NGA    elec-gen_nga
ElcGen_NGA_CCS    elec-gen_nga-ccs
ElcGen_Nuclear    elec-gen_nuclear
ElcGen_OffW    elec-gen_offw
ElcGen_OnW    elec-gen_onw
ElcGen_OtherCCS    elec-gen_other-ccs
ElcGen_OtherFF    elec-gen_other-ff
ElcGen_OtherRenewable    elec-gen_other-rens
ElcGen_Solar    elec-gen_solar
ElcGen_Imports    elec-gen_imports
ElcGen_CHP    elec-gen_chp
ElcGen_Exports    elec-gen_exports
ElcGen_Waste-Heat-Offtake-Penalty    elec-gen_waste-heat-penalty

This version also has
elec-gen_inter    interconnects (imports - exports)
elec-gen_total    sum of generation except imports, exports, waste heat penalty and chp

NB order is important in the case...when statements below: e.g. if first filter is placed last query doesn't work (should always have most specific criteria first).
NB this query creates some duplicate outputs (sums of primary outputs) to get total generation and interconnectors. It uses a temporary table to achieve this.
NB The interconnectors bit is confusing; to get exported elec, have to look at VAR_FIn because commodity is then transformed to an export commodity (different name) by the interconnector. Vice versa for imports.

For electricity exports, VAR_FIn is summed as ELCGEN is the input to the process removing it from the system.

For the offtake penalty, note that ELCGEN input (VAR_FIn) to waste heat collection process needs to be subtracted from electricity generation as it represents a reduction in efficiency of the plant the waste heat is collected from.
*/
select process, period,pv,
    case 
    when attribute = 'VAR_FOut' and commodity in('ELCGEN','INDELC','RESELC','RESHOUSEELC','SERBUILDELC','SERDISTELC','SERELC') and (process like 
        'I%CHP%' or process like 'P%CHP%' or process like 'R%CHP%' or process like 'S%CHP%' or process like 'U%CHP%') then 
        'elec-gen_chp'::varchar(50)
    when commodity = 'ELCGEN' and attribute = 'VAR_FOut' then
        case
            when process in ('ESTWWST00','EPOLWST00', 'EBIOS00','EBOG-LFE00','EBOG-SWE00','EMSW00','EBIOCON00',
                'ESTWWST01','EBIO01','EBOG-ADE01','EBOG-LFE01','EBOG-SWE01','EMSW01') then 'elec-gen_bio'::varchar(50)
            when process ='EBIOQ01' then 'elec-gen_bio-ccs'::varchar(50)
            when process in ('ECOA00','ECOABIO00', 'ECOARR01') then 'elec-gen_coal'::varchar(50)
            when process in ('ECOAQ01','ECOAQDEMO01') then 'elec-gen_coal-ccs'::varchar(50)
            when process in ('EHYGCCT01','EHYGOCT01') then 'elec-gen_h2'::varchar(50)
            when process in ('ENGACCT00','ENGAOCT00','ENGACCTRR01','ENGAOCT01') then 'elec-gen_nga'::varchar(50)
            when process in ('ENGACCTQ01','ENGACCTQDEMO01') then 'elec-gen_nga-ccs'::varchar(50)
            when process in ('ENUCPWR00','ENUCAGRN00','ENUCAGRO00','ENUCPWR101','ENUCPWR102') then 'elec-gen_nuclear'::varchar(50)
            when process in ('EWNDOFF00','EWNDOFF101','EWNDOFF201','EWNDOFF301') then 'elec-gen_offw'::varchar(50)
            when process in ('EWNDONS00','EWNDONS101','EWNDONS201','EWNDONS301','EWNDONS401','EWNDONS501',
                'EWNDONS601','EWNDONS701','EWNDONS801','EWNDONS901') then 'elec-gen_onw'::varchar(50)
            when process ='EHFOIGCCQ01' then 'elec-gen_other-ccs'::varchar(50)
            when process in ('EOILL00','EOILS00','EMANOCT00','EMANOCT01','EOILS01','EOILL01','EHFOIGCC01') then 'elec-gen_other-ff'::varchar(50)
            when process in ('EHYD00','EHYD01','EGEO01','ETIR101','ETIB101','ETIS101','EWAV101') then 'elec-gen_other-rens'::varchar(50)
            when process in ('ESOL00','ESOLPV00','ESOL01','ESOLPV01') then 'elec-gen_solar'::varchar(50)
            when process like 'ELCIE%' or process like 'ELCII%' then 'elec-gen_imports'::varchar(50)
        end
    when commodity = 'ELCGEN' and attribute = 'VAR_FIn' then
        case 
            when process like 'ELCEE%' or process like 'ELCEI%' then 'elec-gen_exports'::varchar(50)
            when process like 'EWSTHEAT-OFF%' then 'elec-gen_waste-heat-penalty'::varchar(50)
        end
    end as "analysis",
    tablename, attribute
into temp elecgen    
from vedastore
where commodity in('ELCGEN','INDELC','RESELC','RESHOUSEELC','SERBUILDELC','SERDISTELC','SERELC') and 
    (attribute = 'VAR_FOut' or attribute = 'VAR_FIn');
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
from elecgen        
where analysis <>''
group by id, analysis,tablename, attribute
union
select 'elec-gen_total' || '|' || tablename || '|' || attribute || '|' || 'various|various'::varchar(300) "id", 'elec-gen_total', tablename,attribute,
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
from elecgen        
where analysis in ('elec-gen_bio','elec-gen_bio-ccs','elec-gen_coal','elec-gen_coal-ccs','elec-gen_nga','elec-gen_nga-ccs','elec-gen_nuclear','elec-gen_offw','elec-gen_onw',
    'elec-gen_other-ff','elec-gen_other-rens','elec-gen_solar')
group by id, tablename, attribute
union
select 'elec-gen_inter' || '|' || tablename || '|' || 'various' || '|' || 'various|various'::varchar(300) "id", 'elec-gen_inter', tablename,'various'::varchar(50) "attribute",
        'various'::varchar(50) "commodity",
        'various'::varchar(50) "process",
        sum(case when analysis='elec-gen_imports' then pv else -pv end)::numeric "all",
        (sum(case when period='2010' and analysis='elec-gen_imports' then pv else 0 end)::numeric - 
            sum(case when period='2010' and analysis='elec-gen_exports' then pv else 0 end)::numeric)::numeric"2010",
        (sum(case when period='2011' and analysis='elec-gen_imports' then pv else 0 end)::numeric - 
            sum(case when period='2011' and analysis='elec-gen_exports' then pv else 0 end)::numeric)::numeric"2011",
        (sum(case when period='2012' and analysis='elec-gen_imports' then pv else 0 end)::numeric - 
            sum(case when period='2012' and analysis='elec-gen_exports' then pv else 0 end)::numeric)::numeric"2012",
        (sum(case when period='2015' and analysis='elec-gen_imports' then pv else 0 end)::numeric - 
            sum(case when period='2015' and analysis='elec-gen_exports' then pv else 0 end)::numeric)::numeric"2015",
        (sum(case when period='2020' and analysis='elec-gen_imports' then pv else 0 end)::numeric - 
            sum(case when period='2020' and analysis='elec-gen_exports' then pv else 0 end)::numeric)::numeric"2020",
        (sum(case when period='2025' and analysis='elec-gen_imports' then pv else 0 end)::numeric - 
            sum(case when period='2025' and analysis='elec-gen_exports' then pv else 0 end)::numeric)::numeric"2025",
        (sum(case when period='2030' and analysis='elec-gen_imports' then pv else 0 end)::numeric - 
            sum(case when period='2030' and analysis='elec-gen_exports' then pv else 0 end)::numeric)::numeric"2030",
        (sum(case when period='2035' and analysis='elec-gen_imports' then pv else 0 end)::numeric - 
            sum(case when period='2035' and analysis='elec-gen_exports' then pv else 0 end)::numeric)::numeric"2035",
        (sum(case when period='2040' and analysis='elec-gen_imports' then pv else 0 end)::numeric - 
            sum(case when period='2040' and analysis='elec-gen_exports' then pv else 0 end)::numeric)::numeric"2040",
        (sum(case when period='2045' and analysis='elec-gen_imports' then pv else 0 end)::numeric - 
            sum(case when period='2045' and analysis='elec-gen_exports' then pv else 0 end)::numeric)::numeric"2045",
        (sum(case when period='2050' and analysis='elec-gen_imports' then pv else 0 end)::numeric - 
            sum(case when period='2050' and analysis='elec-gen_exports' then pv else 0 end)::numeric)::numeric"2050",
        (sum(case when period='2055' and analysis='elec-gen_imports' then pv else 0 end)::numeric - 
            sum(case when period='2055' and analysis='elec-gen_exports' then pv else 0 end)::numeric)::numeric"2055",
        (sum(case when period='2060' and analysis='elec-gen_imports' then pv else 0 end)::numeric - 
            sum(case when period='2060' and analysis='elec-gen_exports' then pv else 0 end)::numeric)::numeric"2060"
from elecgen        
where analysis in ('elec-gen_imports','elec-gen_exports')
group by id, tablename
order by tablename,  analysis, attribute, commodity;

/* *Elec storage* */
/*XLS item 3d) Storage*/
 select 'elec-stor|' || tablename || '|Var_FOut|ELC|various'::varchar(300) "id",
'elec-stor'::varchar(25) "analysis",
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
from vedastore
where attribute = 'VAR_FOut' and commodity = 'ELC'
        and process in('EHYDPMP00','EHYDPMP01','ECAESCON01','ESTGCAES01','ECAESTUR01','ESTGAACAES01','ESTGBNAS01','ESTGBALA01','ESTGBRF01')
group by tablename;

/* *Electricity capacity by process* */
/*Potential Issues and things to note
        Need an extra query for for retrofits.
        we do not account for co-firing (we report all coal-bio co-firing as coal)
        Reports full capacity of CHP not electrical capacity
Limitations
        Lines of zeros are reported blank (nothing comes through) rather than as zeros
        No headings - could be good if adding to overall outputs
        
NB in a previous version of the query the entries were as follows (equivalent below in col to right):

        ElcCapacity_Bio                                elec_capacity_bio
        ElcCapacity_BioCCS                        elec_capacity_bio-ccs
        ElcCapacity_Coal                        elec_capacity_coal
        ElcCapacity_CoalCCS                        elec_capacity_coal-ccs
        ElcCapacity_Hydrogen                elec_capacity_h2
        ElcCapacity_NGA                                elec_capacity_nga
        ElcCapacity_NGA_CCS                        elec_capacity_nga-ccs
        ElcCapacity_Nuclear                        elec_capacity_nuclear
        ElcCapacity_OffW                        elec_capacity_offw
        ElcCapacity_OnW                                elec_capacity_onw
        ElcCapacity_OtherCCS                elec_capacity_other-ccs
        ElcCapacity_OtherFF                        elec_capacity_other-ff
        ElcCapacity_OtherRenewable        elec_capacity_other-rens
        ElcCapacity_Solar                        elec_capacity_solar
        ElcCapacity_CHP                                elec_capacity_chp
        ElcCapacity_Interconnectors        elec_capacity_intercon

For the electrical interconnectors, note that filter only includes interconnectors for imports.
In UKTM import and export interconnectors are modelled as seperate technologies and are assumed to have identical capacity.
*/

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
                case
                        when process like 'ESTWWST00' or process like 'EPOLWST00' or process like  'EBIOS00' or process like 'EBOG-LFE00' or process like 'EBOG-SWE00' or 
                                process like 'EMSW00' or process like 'EBIOCON00' or process like 'ESTWWST01' or process like 'EBIO01' or process like 'EBOG-ADE01' or 
                                process like 'EBOG-LFE01' or process like 'EBOG-SWE01' or process like 'EMSW01' then 'elec-cap_bio'::varchar(50)
                        when process like 'EBIOQ01' then 'elec-cap_bio-ccs'::varchar(50)
                        when process like 'ECOA00' or process like 'ECOABIO00' or process like  'ECOARR01' then 'elec-cap_coal'::varchar(50)
                        when process like 'ECOAQ01' or process like 'ECOAQDEMO01' then 'elec-cap_coal-ccs'::varchar(50)
                        when process like 'EHYGCCT01' or process like 'EHYGOCT01' then 'elec-cap_h2'::varchar(50)
                        when process like 'ENGACCT00' or process like 'ENGAOCT00' or process like 'ENGACCTRR01' or process like 'ENGAOCT01' then 'elec-cap_nga'::varchar(50)
                        when process like 'ENGACCTQ01' or process like 'ENGACCTQDEMO01' then 'elec-cap_nga-ccs'::varchar(50)
                        when process like 'ENUCPWR00' or process like 'ENUCAGRN00' or process like 'ENUCAGRO00' or process like 'ENUCPWR101' or process like 'ENUCPWR102' then 'elec-cap_nuclear'::varchar(50)
                        when process like 'EWNDOFF00' or process like 'EWNDOFF101' or process like 'EWNDOFF201' or process like 'EWNDOFF301' then 'elec-cap_offw'::varchar(50)
                        when process like 'EWNDONS00' or process like 'EWNDONS101' or process like 'EWNDONS201' or process like 'EWNDONS301' or process like 'EWNDONS401' or 
                                process like 'EWNDONS501' or process like 'EWNDONS601' or process like 'EWNDONS701' or process like 'EWNDONS801' or process like 'EWNDONS901' then 'elec-cap_onw'::varchar(50)
                        when process like 'EHFOIGCCQ01' then 'elec-cap_other-ccs'::varchar(50)
                        when process like 'EOILL00' or process like 'EOILS00' or process like 'EMANOCT00' or process like 'EMANOCT01' or process like 'EOILS01' or process like 'EOILL01' or 
                                process like 'EHFOIGCC01' then 'elec-cap_other-ff'::varchar(50)
                        when process like 'EHYD00' or process like 'EHYD01' or process like 'EGEO01' or process like 'ETIR101' or process like 'ETIB101' or process like 'ETIS101' or 
                                process like 'EWAV101' then 'elec-cap_other-rens'::varchar(50)
                        when process like 'ESOL00' or process like 'ESOLPV00' or process like 'ESOL01' or process like 'ESOLPV01' then 'elec-cap_solar'::varchar(50)
                        when process like 'I%CHP%' or process like 'P%CHP%' or process like 'R%CHP%' or process like 'S%CHP%' or process like 'U%CHP%' then 'elec-cap_chp'::varchar(50)
                        when process like 'ELCIE%' or process like 'ELCII%' then 'elec-cap_intercon'::varchar(50)
                        else 'elec-cap_other'
                end as "analysis",
        tablename, attribute
        from vedastore 
        where attribute = 'VAR_Cap' and commodity = '-' AND (process in('ESTWWST00','EPOLWST00','EBIOS00','EBOG-LFE00','EBOG-SWE00','EMSW00','EBIOCON00','ESTWWST01','EBIO01','EBOG-ADE01','EBOG-LFE01','EBOG-SWE01','EMSW01','EBIOQ01','ECOA00','ECOABIO00','ECOARR01','ECOAQ01','ECOAQDEMO01','EHYGCCT01','EHYGOCT01','ENGACCT00','ENGAOCT00','ENGACCTRR01','ENGAOCT01','ENGACCTQ01','ENGACCTQDEMO01','ENUCPWR00','ENUCAGRN00','ENUCAGRO00','ENUCPWR101','ENUCPWR102','EWNDOFF00','EWNDOFF101','EWNDOFF201','EWNDOFF301','EWNDONS00','EWNDONS101','EWNDONS201','EWNDONS301','EWNDONS401','EWNDONS501','EWNDONS601','EWNDONS701','EWNDONS801','EWNDONS901','EHFOIGCCQ01','EOILL00','EOILS00','EMANOCT00','EMANOCT01','EOILS01','EOILL01','EHFOIGCC01','EHYD00','EHYD01','EGEO01','ETIR101','ETIB101','ETIS101','EWAV101','ESOL00','ESOLPV00','ESOL01','ESOLPV01') or process like 'I%CHP%' or process like 'P%CHP%' or process like 'R%CHP%' or process like 'S%CHP%' or process like 'U%CHP%' or process like 'ELCIE%' or process like 'ELCII%')
) a
group by id, analysis,tablename, attribute
order by tablename,  analysis, attribute, commodity;

/* *Biofuels by sector* */
/*
6:17 PM 08-Feb-16; now removed different categories of biofuel. Categories were bio-g, bio-s, bio-l for gas, solid, liquid*/
 
select analysis || '|' || tablename || '|VAR_FIn|' || commodity || '|' || process::varchar(300) "id", analysis, tablename,attribute,
        commodity,
        process,
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
    select left(process,3) || '*'::varchar(50) "process",period,pv,
    'biofuels'::varchar(50) as "analysis",
    tablename, attribute,'various'::varchar(50) "commodity"
    from vedastore
    where attribute='VAR_FIn' and left(process,3) in('AGR','ELC','HYG','IND','PRC','RES','SER','TRA')
) a
where analysis <>''
group by id, analysis,tablename, attribute, commodity,process
order by tablename,  analysis, attribute, commodity;

/* *costs by sector and type* */
/*
Includes "catch-all" category in case costs are incurred outside the 
categories of AGR,TRA,RES,SER,ELC,IND,PRC,RSR here
6:15 PM 08-Feb-16; nb objective function added in & total costs query removed. Totals from the below were a max of 8.44011E-10 different due to rounding errors*.
Includes the salvage costs / objective function with the individual costs for each year.
First col for other entries (i.e. not for obj func/salvage) gives total across years
Relies on all costs outputs being "Costs_"...*/

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
            when process like 'T%' then 'costs_tra'::varchar(50)
            when process like 'A%' then 'costs_agr'::varchar(50)
            when process like 'E%' AND process not like 'EXP%' then 'costs_elc'::varchar(50)
            when process like 'I%' AND process not like 'IMP%' then 'costs_ind'::varchar(50)
            when process like 'P%' or process like 'C%' then 'costs_prc'::varchar(50)
            when process like 'R%' then 'costs_res'::varchar(50)
            when process like 'M%'or process like 'U%'or process like 'IMP%'or process like 'EXP%' then 'costs_rsr'::varchar(50)
            when process like 'S%' then 'costs_ser'::varchar(50)
            else 'costs_other'::varchar(50)
        end as "analysis",tablename, attribute
        from vedastore 
        where attribute in('Cost_Act', 'Cost_Flo', 'Cost_Fom', 'Cost_Inv', 'Cost_Salv','ObjZ')
        group by period,process, pv,tablename, id, analysis, attribute
) a
group by id, analysis, tablename, attribute
order by tablename,  analysis, attribute, commodity;

/* *Marginal prices for emissions* */
/*Note that the "all" column is left blank since it doesn't make sense to sum the marginal prices. Could substitute an average or similar if required*/

select 'marg-price|' || tablename || '|VAR_ComnetM|' || commodity || '|-'::varchar(300) "id",
        'marg-price'::varchar(50) "analysis",
        tablename,
        'VAR_ComnetM'::varchar(50) "attribute",
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
where attribute='VAR_ComnetM' and commodity in('GHG-NO-IAS-YES-LULUCF-NET','GHG-ETS-NO-IAS-NET','GHG-YES-IAS-YES-LULUCF-NET','GHG-ETS-YES-IAS-NET')
group by tablename, commodity
order by tablename, commodity;

/* *Whole stock heat output by process for residential* */
/*
NB in a previous version of the query the entries were as follows (equivalent below in col to right):

RES_Heat_Conservation                            'heat_conserv'
RES_Heat_Micro_CHP_Biomass                        'heat_microchp_bio'
RES_Heat_Bio-Boiler                                'heat_boiler_bio'
RES_Heat_Hydrogen_Boiler                        'heat_boiler_h2'
RES_Heat_Hybrid_Heat_Pump_Hydrogen_Boiler        'heat_hyb-boil+hp_h2'
RES_Heat_Heat_Pump                                'heat_heatpump_elec'
RES_Heat_Elec_Storage_Heater                    'heat_storheater_elec'
RES_Heat_Elec_Boiler_or_Heater(inc_SolarTherm)    'heat_boiler/heater_elec'
RES_Heat_Other_FF_Boiler                        'heat_boiler_otherFF'
RES_Heat_NGA_Boiler_or_Heater(inc_SolarTherm)    'heat_boiler/heater_nga'
RES_Heat_Micro_CHP_NGA                            'heat_microchp_nga'
RES_Heat_Micro_CHP_Hydrogen                        'heat_microchp_h2'
RES_Heat_District-Heat                            'heat_dh'
RES_Heat_Hybrid_Heat_Pump_NGA_Boiler            'heat_hyb-boil+hp_nga'

NB original query set had total heat but that was deemed unnecessary to replicate given the other elements.

Note also that there can be some problems with characters in the filters below. Sometimes, for unknown reasons, they won't work even though they appear to be exactly the same as strings which do. Copy and
paste over the below until they do...
*/

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
                case
                        when process like 'RH%CSV%' then 'heat-res_conserv'::varchar(50)
                        when process like 'RH%DHP%' then 'heat-res_dh'::varchar(50)
                        when process like 'RH%CHPRW01' then 'heat-res_microchp_bio'::varchar(50)
                        when process like 'RH%CHPRG01' then 'heat-res_microchp_nga'::varchar(50)
                        when process like 'RH%BLCRH01' or process like 'RH%BLSRH01' then 'heat-res_boiler_h2'::varchar(50)
                        when process like 'RH%CHPRH01' or process like 'RH%CHBRH01' then 'heat-res_microchp_h2'::varchar(50)
                        when process like 'RH%STGNT00' or process like 'RH%NSTRE00' or process like 'RH%STGNT01' or process like 'RH%NSTRE01' then 'heat-res_storheater_elec'::varchar(50)
                        when process like 'RH%AHHRE01' or process like 'RH%AHHUE01' or process like 'RH%GHHRE01' or process like 'RH%GHHUE01' then 'heat-res_hyb-boil+hp_h2'::varchar(50)
                        when process like 'RH%AHBRE01' or process like 'RH%AHBUE01' or process like 'RH%GHBRE01' or process like 'RH%GHBUE01' then 'heat-res_hyb-boil+hp_nga'::varchar(50)
                        when process like 'RH%BLRRW00' or process like 'RH%BLCRP01' or process like 'RH%BLRRW01' or process like 'RH%BLSRP01' or 
                                process like 'RH%BLSRW01' then 'heat-res_boiler_bio'::varchar(50)
                        when process like 'RH%BLRRO00' or process like 'RH%BLCRO00' or process like 'RH%BLRRC00' or process like 'RH%BLCRO01' or
                                process like 'RH%BLSRO01' then 'heat-res_boiler_otherFF'::varchar(50)
                        when process like 'RH%AHPRE00' or process like 'RH%AHPRE01' or process like 'RH%AHPUE01' or process like 'RH%GHPRE01' or
                                process like 'RH%GHSUE01' or process like 'RH%AHSRE01' or process like 'RH%AHSUE01' or process like 'RH%GHSRE01' then 'heat-res_heatpump_elec'::varchar(50)
                        when process like 'RH%BLRRE00' or process like 'RH%SHTRE00' or process like 'RW%WHTRE00' or process like 'RH%BLRRE01' or 
                                process like 'RH%GHPUE01' or process like 'RH%SHTRE01' or process like 'RW%WHTRE01' or process like 'RH%BLSRE01' then 'heat-res_boiler/heater_elec'::varchar(50)
                        when process like 'RH%BLRRG00' or process like 'RH%BLCRG00' or process like 'RH%SHTRG00' or process like 'RW%WHTRG00' or
                                process like 'RW%SOLRS00' or process like 'RH%BLCRG01' or process like 'RH%SHTRG01' or process like 'RW%WHTRG01' or
                                process like 'RH%BLSRG01' then 'heat-res_boiler/heater_nga'::varchar(50)
                        else 'heat-res_other'
                end as "analysis",
        tablename, attribute
        from vedastore 
        where attribute = 'VAR_FOut' AND (commodity like 'RHEATPIPE-%' or commodity like 'RHUFLOOR-%' or commodity like 'RHSTAND-%' or 
            commodity like 'RWSTAND-%' or commodity like 'RHCSV-RH%' or commodity like 'RWCSV-RW%')
        group by period,process, pv,tablename, id, analysis, attribute order by tablename, attribute
) a
group by id, analysis,tablename, attribute
order by tablename,  analysis, attribute, commodity;

/* *New build residential heat output by source* */
/*
*/
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
         select process,commodity,
                period,pv,
                case
                        when process like 'RH%CSV%' then 'new-heat-res_conserv'::varchar(50)
                        when process like 'RH%DHP%' then 'new-heat-res_dh'::varchar(50)
                        when process like 'RH%CHPRW01' then 'new-heat-res_microchp_bio'::varchar(50)
                        when process like 'RH%CHPRG01' then 'new-heat-res_microchp_nga'::varchar(50)
                        when process like 'RH%BLCRH01' or process like 'RH%BLSRH01' then 'new-heat-res_boiler_h2'::varchar(50)
                        when process like 'RH%CHPRH01' or process like 'RH%CHBRH01' then 'new-heat-res_microchp_h2'::varchar(50)
                        when process like 'RH%STGNT00' or process like 'RH%NSTRE00' or process like 'RH%STGNT01' or process like 'RH%NSTRE01' then 'new-heat-res_storheater_elec'::varchar(50)
                        when process like 'RH%AHHRE01' or process like 'RH%AHHUE01' or process like 'RH%GHHRE01' or process like 'RH%GHHUE01' then 'new-heat-res_hyb-boil+hp_h2'::varchar(50)
                        when process like 'RH%AHBRE01' or process like 'RH%AHBUE01' or process like 'RH%GHBRE01' or process like 'RH%GHBUE01' then 'new-heat-res_hyb-boil+hp_nga'::varchar(50)
                        when process like 'RH%BLRRW00' or process like 'RH%BLCRP01' or process like 'RH%BLRRW01' or process like 'RH%BLSRP01' or 
                                process like 'RH%BLSRW01' then 'new-heat-res_boiler_bio'::varchar(50)
                        when process like 'RH%BLRRO00' or process like 'RH%BLCRO00' or process like 'RH%BLRRC00' or process like 'RH%BLCRO01' or
                                process like 'RH%BLSRO01' then 'new-heat-res_boiler_otherFF'::varchar(50)
                        when process like 'RH%AHPRE00' or process like 'RH%AHPRE01' or process like 'RH%AHPUE01' or process like 'RH%GHPRE01' or
                                process like 'RH%GHSUE01' or process like 'RH%AHSRE01' or process like 'RH%AHSUE01' or process like 'RH%GHSRE01' then 'new-heat-res_heatpump_elec'::varchar(50)
                        when process like 'RH%BLRRE00' or process like 'RH%SHTRE00' or process like 'RW%WHTRE00' or process like 'RH%BLRRE01' or 
                                process like 'RH%GHPUE01' or process like 'RH%SHTRE01' or process like 'RW%WHTRE01' or process like 'RH%BLSRE01' then 'new-heat-res_boiler/heater_elec'::varchar(50)
                        when process like 'RH%BLRRG00' or process like 'RH%BLCRG00' or process like 'RH%SHTRG00' or process like 'RW%WHTRG00' or
                                process like 'RW%SOLRS00' or process like 'RH%BLCRG01' or process like 'RH%SHTRG01' or process like 'RW%WHTRG01' or
                                process like 'RH%BLSRG01' then 'new-heat-res_boiler/heater_nga'::varchar(50)
                end as "analysis",
        tablename, attribute
        from vedastore 
        where attribute = 'VAR_FOut' AND (commodity like 'RHEATPIPE-%' or commodity like 'RHUFLOOR-%' or commodity like 'RHSTAND-%' or 
            commodity like 'RWSTAND-%' or commodity like 'RHCSV-RH%' or commodity like 'RWCSV-RW%') and vintage=period
        group by period,commodity,process, pv,tablename, id, analysis, attribute order by tablename, attribute
) a where analysis <> ''
group by id, analysis,tablename, attribute
order by tablename,  analysis, attribute, commodity

/* *Whole stock heat output for services* */
/*
List of technology groupings (hvac ones are not in residential)

SER_Heat_Elec_Boiler_or_Heater(inc_SolarTherm)        'heat-ser_boiler/heater_elec'
SER_Heat_NGA_Boiler_or_Heater(inc_SolarTherm)        'heat-ser_boiler/heater_nga'
SER_Heat_Bio-Boiler                                    'heat-ser_boiler_bio'
SER_Heat_Hydrogen_Boiler                            'heat-ser_boiler_h2'
SER_Heat_Other_FF_Boiler                            'heat-ser_boiler_otherFF'
SER_Heat_Conservation                                'heat-ser_conserv'
SER_Heat_Hybrid_Heat_Pump_NGA_Boiler                'heat-ser_dh'
SER_Heat_Heat_Pump                                    'heat-ser_heatpump_elec'
SER_Heat_hvac                                        'heat-ser_hvac'
SER_Heat_hvac_advanced                                'heat-ser_hvac-ad'
SER_Heat_Hybrid_Heat_Pump_Hydrogen_Boiler            'heat-ser_hyb-boil+hp_h2'
SER_Heat_District-Heat                                'heat-ser_hyb-boil+hp_nga'
SER_Heat_Micro_CHP_Biomass                            'heat-ser_microchp_bio'
SER_Heat_Micro_CHP_Hydrogen                            'heat-ser_microchp_h2'
SER_Heat_Micro_CHP_NGA                                'heat-ser_microchp_nga'
SER_Heat_Elec_Storage_Heater                        'heat-ser_storheater_elec'

*/
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
                case
                    when process in ('SHLSHTRE00','SWLWHTRE00','SHLBLRRE01','SHLSHTRE01','SWLWHTRE01','SHLBLSRE01','SHHBLRRE00','SWHWHTRE00','SHHBLRRE01','SWHWHTRE01','SHLBLRRE00') then 'heat-ser_boiler/heater_elec'
                    when process in('SHLBLCRG00','SHLSHTRG00','SWLWHTRG00','SHLBLCRG01','SWLWHTRG01','SHLBLSRG01','SHHBLRRG00','SWHBLRRG00','SHHBLRRG01','SWHBLRRG01','SHLBLRRG00') then 'heat-ser_boiler/heater_nga'
                    when process in('SHLBLCRP01','SHLBLRRW01','SHLBLSRP01','SHLBLSRW01','SHHBLRRW00','SWHBLRRW00','SHHBLRRW01','SWHBLRRW01','SHLBLRRW00') then 'heat-ser_boiler_bio'
                    when process in('SHLBLSRH01','SHHBLRRH01','SWHBLRRH01','SHLBLCRH01') then 'heat-ser_boiler_h2'
                    when process in('SHLBLCRO00','SHLBLRRC00','SHLSHTRO00','SHLBLCRO01','SHLBLSRO01','SHHBLRRO00','SHHBLRRC00','SWHBLRRO00','SWHBLRRC00','SHHBLRRO01','SHHBLRRC01','SWHBLRRO01','SWHBLRRC01','SHLBLRRO00') then 'heat-ser_boiler_otherFF'
                    when process in('SCSLROFF01','SCSLROFP01','SCSLCAVW01','SCSHPTHM01','SCSHROFF01','SCSHROFP01','SCSHCAVW01','SCSLPTHM01') then 'heat-ser_conserv'
                    when process in('SHLAHBUE01','SHLGHBRE01','SHLGHBUE01','SHLAHBRE01') then  'heat-ser_hyb-boil+hp_nga'
                    when process in('SHLAHPRE01','SHLAHPUE01','SHLGHPRE01','SHLGHPUE01','SHLAHSRE01','SHLAHSUE01','SHLGHSRE01','SHLGHSUE01','SHLAHPRE00') then 'heat-ser_heatpump_elec'
                    when process in('SHHVACAE01','SHHVACAE00') then 'heat-ser_hvac'
                    when process in('SHHVACAE02') then 'heat-ser_hvac-ad'
                    when process in('SHLAHHUE01','SHLGHHRE01','SHLGHHUE01','SHLAHHRE01') then 'heat-ser_hyb-boil+hp_h2'
                    when process in('SHLDHP101','SHHDHP100','SHHDHP101','SHLDHP100') then 'heat-ser_dh'
                    when process in('SHLCHPRW01') then 'heat-ser_microchp_bio'
                    when process in('SHLCHBRH01','SHHFCLRH01','SHLCHPRH01') then 'heat-ser_microchp_h2'
                    when process in('SHLCHPRG01') then 'heat-ser_microchp_nga'
                    when process in('SHLNSTRE01','SHLNSTRE00') then 'heat-ser_storheater_elec'
                    else 'heat-ser_other'
                end as "analysis",
        tablename, attribute
        from vedastore 
        where attribute = 'VAR_FOut' AND commodity in('SHHCSVDMD','SHHDELVAIR','SHHDELVRAD','SHLCSVDMD','SHLDELVAIR','SHLDELVRAD','SHLDELVUND','SWHDELVPIP','SWHDELVSTD','SWLDELVSTD')
        group by period,process, pv,tablename, id, analysis, attribute order by tablename, attribute
) a
group by id, analysis,tablename, attribute
order by tablename,  analysis, attribute, commodity;

/* *New build services heat output by source* */
/*
*/
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
                case
                    when process in ('SHLSHTRE00','SWLWHTRE00','SHLBLRRE01','SHLSHTRE01','SWLWHTRE01','SHLBLSRE01','SHHBLRRE00','SWHWHTRE00','SHHBLRRE01','SWHWHTRE01','SHLBLRRE00') then 'new-heat-ser_boiler/heater_elec'
                    when process in('SHLBLCRG00','SHLSHTRG00','SWLWHTRG00','SHLBLCRG01','SWLWHTRG01','SHLBLSRG01','SHHBLRRG00','SWHBLRRG00','SHHBLRRG01','SWHBLRRG01','SHLBLRRG00') then 'new-heat-ser_boiler/heater_nga'
                    when process in('SHLBLCRP01','SHLBLRRW01','SHLBLSRP01','SHLBLSRW01','SHHBLRRW00','SWHBLRRW00','SHHBLRRW01','SWHBLRRW01','SHLBLRRW00') then 'new-heat-ser_boiler_bio'
                    when process in('SHLBLSRH01','SHHBLRRH01','SWHBLRRH01','SHLBLCRH01') then 'new-heat-ser_boiler_h2'
                    when process in('SHLBLCRO00','SHLBLRRC00','SHLSHTRO00','SHLBLCRO01','SHLBLSRO01','SHHBLRRO00','SHHBLRRC00','SWHBLRRO00','SWHBLRRC00','SHHBLRRO01','SHHBLRRC01','SWHBLRRO01','SWHBLRRC01','SHLBLRRO00') then 'new-heat-ser_boiler_otherFF'
                    when process in('SCSLROFF01','SCSLROFP01','SCSLCAVW01','SCSHPTHM01','SCSHROFF01','SCSHROFP01','SCSHCAVW01','SCSLPTHM01') then 'new-heat-ser_conserv'
                    when process in('SHLAHBUE01','SHLGHBRE01','SHLGHBUE01','SHLAHBRE01') then  'new-heat-ser_hyb-boil+hp_nga'
                    when process in('SHLAHPRE01','SHLAHPUE01','SHLGHPRE01','SHLGHPUE01','SHLAHSRE01','SHLAHSUE01','SHLGHSRE01','SHLGHSUE01','SHLAHPRE00') then 'new-heat-ser_heatpump_elec'
                    when process in('SHHVACAE01','SHHVACAE00') then 'new-heat-ser_hvac'
                    when process in('SHHVACAE02') then 'new-heat-ser_hvac-ad'
                    when process in('SHLAHHUE01','SHLGHHRE01','SHLGHHUE01','SHLAHHRE01') then 'new-heat-ser_hyb-boil+hp_h2'
                    when process in('SHLDHP101','SHHDHP100','SHHDHP101','SHLDHP100') then 'new-heat-ser_dh'
                    when process in('SHLCHPRW01') then 'new-heat-ser_microchp_bio'
                    when process in('SHLCHBRH01','SHHFCLRH01','SHLCHPRH01') then 'new-heat-ser_microchp_h2'
                    when process in('SHLCHPRG01') then 'new-heat-ser_microchp_nga'
                    when process in('SHLNSTRE01','SHLNSTRE00') then 'new-heat-ser_storheater_elec'
                    else 'new-new-heat-ser_other'
                end as "analysis",
        tablename, attribute
        from vedastore 
        where attribute = 'VAR_FOut' AND commodity in('SHHCSVDMD','SHHDELVAIR','SHHDELVRAD','SHLCSVDMD','SHLDELVAIR','SHLDELVRAD','SHLDELVUND','SWHDELVPIP','SWHDELVSTD','SWLDELVSTD')
            and vintage=period
        group by period,process, pv,tablename, id, analysis, attribute order by tablename, attribute
) a
group by id, analysis,tablename, attribute
order by tablename,  analysis, attribute, commodity;

/* *Whole stock vehicle kms, emissions for 19 vehicle types and CNG use (car, lgv, hgv)* */
/*Includes estimates of CNG-in by vehicle types and GHG associated with overall conversion of NGA to CNG (have to apportion this by GNG-in to get emissions associated with each type of CNG veh)

NB following codes for 'cars_h2+hybrid' doesn't seem to exist in the online acronym list:
    TCHBHYL01
This code exists in the acronym list but not in the test dataset:
    TCHBE8501    New hybrid flexible-fuel car (for E85)

'Flexible fuel' vehicles (*E8501) are assigned to _petrol vehicles in the below...
Case...when order changed to remove spurious assignments
*/

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
        select process, period,pv,vintage,
        case 
            when left(process, 2)='TC' then 'cars-'
            when left(process, 2)='TL' then 'lgv-'
            when left(process, 2)='TH' then 'hgv-'
        end || 
        case
            when commodity in('TC','TL','TH') then 'km_'
            when commodity like 'GHG-%' then 'emis_'
        end ||
        case 
            when process like '%PHBPET01' or process like '%PHBDST01' then 'plug-in-hybrid'::varchar(50)
            when process like '%HBPET00' or process like '%HBPET01' or process like '%HBDST01' then 'hybrid'::varchar(50)
            when process like '%DST00' or process like '%DST01' then 'diesel'::varchar(50)
            when process like '%ELC01' then 'electric'::varchar(50)
            when process like '%FCHYG01' or process like '%FCHBHYG01' or process like '%HBHYL01' then 'h2+hybrid'::varchar(50)
            when process like '%FCPHBHYG01' then 'h2-plug-in-hybrid'::varchar(50)
            when process like '%LPG00' or process like '%LPG01' or process like '%CNG01' then 'lpg-and-cng-fueled'::varchar(50)
            when process like '%PET00' or process like '%PET01' or process like '%E8501' then 'petrol'::varchar(50)
        end as "analysis",
        tablename, attribute,commodity
        from vedastore
        where attribute = 'VAR_FOut' and (commodity in('TC','TL','TH') or commodity like 'GHG-%')
        and (process like 'TC%' or process like ('TL%') or process ~'^TH[^Y]') 
    ) a
    where analysis <>''
    group by id, analysis,tablename, attribute, commodity
union
select analysis || '|' || tablename || '|' || attribute || '|' || commodity || '|' || process::varchar(300) "id", analysis, tablename,attribute,
            commodity,
            process,
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
        select 
        case 
            when process = 'TFSSCNG01' then 'TFSSCNG01'
            else left(process,2) || '%'::varchar(50) 
        end as process, period,pv,
        case 
            when process = 'TFSSCNG01' and attribute ='VAR_FOut' and commodity like 'GHG-%' then 'cars-cng-conv-emis'
            when attribute = 'VAR_FIn' then
            case 
                when process like 'TC%' then 'cars-cng-in'
                when process like 'TL%' then 'lgv-cng-in'
                when process like 'TH%' then 'hgv-cng-in'
            end 
        end as "analysis",
        tablename, attribute,commodity
        from vedastore
        where (attribute = 'VAR_FIn' or attribute ='VAR_FOut') and (commodity = 'TRACNGS' or commodity like 'GHG-%') and 
            (process = 'TFSSCNG01' or process like 'TC%' or process like 'TL%' or process like 'TH%')
    ) a
    where analysis <>''
    group by id, analysis,tablename, attribute, commodity, process;

/* *New vehicle kms, emissions for 19 vehicle types and CNG use (car, lgv, hgv)* */
/*This script only includes new vehicles in the year of introduction. To take account of the GHG from conversion of 
gas to CNG, you need to sum up the total CNG-in into CNG powered vehicles. Then take (new veh CNG-in) / (whole veh stock CNG-in)
* (GHG gases from gas => CNG conversion) = all new CNG veh emissions. I.e. requires elements from other vehicle queries. To get 
new CNG car (e.g.) emissions, take new car CNG-in as proportion of all new veh CNG-in * all new CNG veh emissions.
*/

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
        select process, period,pv,vintage,
        case 
            when left(process, 2)='TC' then 'cars-new-'
            when left(process, 2)='TL' then 'lgv-new-'
            when left(process, 2)='TH' then 'hgv-new-'
        end || 
        case
            when commodity in('TC','TL','TH') then 'km_'
            when commodity like 'GHG-%' then 'emis_'
        end ||
        case 
            when process like '%PHBPET01' or process like '%PHBDST01' then 'plug-in-hybrid'::varchar(50)
            when process like '%HBPET00' or process like '%HBPET01' or process like '%HBDST01' then 'hybrid'::varchar(50)
            when process like '%DST00' or process like '%DST01' then 'diesel'::varchar(50)
            when process like '%ELC01' then 'electric'::varchar(50)
            when process like '%FCHYG01' or process like '%FCHBHYG01' or process like '%HBHYL01' then 'h2+hybrid'::varchar(50)
            when process like '%FCPHBHYG01' then 'h2-plug-in-hybrid'::varchar(50)
            when process like '%LPG00' or process like '%LPG01' or process like '%CNG01' then 'lpg-and-cng-fueled'::varchar(50)
            when process like '%PET00' or process like '%PET01' or process like '%E8501' then 'petrol'::varchar(50)
        end as "analysis",
        tablename, attribute,commodity
        from vedastore
        where attribute = 'VAR_FOut' and (commodity in('TC','TL','TH') or commodity like 'GHG-%')
        and (process like 'TC%' or process like ('TL%') or process ~'^TH[^Y]') and right(process,2)='01' and vintage=period
    ) a
    where analysis <>''
    group by id, analysis,tablename, attribute, commodity
union
select analysis || '|' || tablename || '|' || attribute || '|' || commodity || '|' || process::varchar(300) "id", analysis, tablename,attribute,
            commodity,
            process,
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
        select left(process,2) || '%'::varchar(50) as process, period,pv,vintage,
        case 
            when process like 'TC%' then 'cars-new-cng-in'
            when process like 'TL%' then 'lgv-new-cng-in'
            when process like 'TH%' then 'hgv-new-cng-in'
        end as "analysis",
        tablename, attribute,commodity
        from vedastore
        where  attribute = 'VAR_FIn' and (commodity = 'TRACNGS' or commodity like 'GHG-%') and 
            left(process,2) in ('TC','TL','TH') and right(process,2)='01'
            and vintage=period
) a
where analysis <>''
group by id, analysis,tablename, attribute, commodity, process;

/* *Whole stock capacity for vehicles for 19 vehicle types* */

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
        when left(process, 2)='TC' then 'cars-cap_'
        when left(process, 2)='TL' then 'lgv-cap_'
        when left(process, 2)='TH' then 'hgv-cap_'
    end || case 
        when process like '%PHBPET01' or process like '%PHBDST01' then 'plug-in-hybrid'::varchar(50)
        when process like '%HBPET00' or process like '%HBPET01' or process like '%HBDST01' then 'hybrid'::varchar(50)
        when process like '%DST00' or process like '%DST01' then 'diesel'::varchar(50)
        when process like '%ELC01' then 'electric'::varchar(50)
        when process like '%FCHYG01' or process like '%FCHBHYG01' or process like '%HBHYL01' then 'h2+hybrid'::varchar(50)
        when process like '%FCPHBHYG01' then 'h2-plug-in-hybrid'::varchar(50)
        when process like '%LPG00' or process like '%LPG01' or process like '%CNG01' then 'lpg-and-cng-fueled'::varchar(50)
        when process like '%PET00' or process like '%PET01' or process like '%E8501' then 'petrol'::varchar(50)
    end as "analysis",
    tablename, attribute,commodity
    from vedastore
    where attribute = 'VAR_Cap' and left(process,2) in('TC','TL','TH')
) a
where analysis <>''
group by id, analysis,tablename, attribute, commodity
order by tablename,  analysis, attribute, commodity;

/* *New build vehicle capacity for 19 vehicle types*/
/*NB are no commodities associated with new build, only processes - commodity='-' 
*/
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
        when process like 'TC%' then 'cars-new-cap_'
        when process like 'TL%' then 'lgv-new-cap_'
        when process like 'TH%' then 'hgv-new-cap_'
    end || case 
        when process like '%PHBPET01' or process like '%PHBDST01' then 'plug-in-hybrid'::varchar(50)
        when process like '%HBPET00' or process like '%HBPET01' or process like '%HBDST01' then 'hybrid'::varchar(50)
        when process like '%DST00' or process like '%DST01' then 'diesel'::varchar(50)
        when process like '%ELC01' then 'electric'::varchar(50)
        when process like '%FCHYG01' or process like '%FCHBHYG01' or process like '%HBHYL01' then 'h2+hybrid'::varchar(50)
        when process like '%FCPHBHYG01' then 'h2-plug-in-hybrid'::varchar(50)
        when process like '%LPG00' or process like '%LPG01' or process like '%CNG01' then 'lpg-and-cng-fueled'::varchar(50)
        when process like '%PET00' or process like '%PET01' or process like '%E8501' then 'petrol'::varchar(50)
    end as "analysis",
    tablename, attribute,commodity
    from vedastore
    where attribute='VAR_Ncap' and (process like 'TC%' or process like ('TL%') or process ~'^TH[^Y]')
) a
where analysis <>''
group by id, analysis,tablename, attribute, commodity
order by tablename,  analysis, attribute, commodity;

/* ***********THIS (following) GIVES WRONG RESULTS - needs revision************ */
/* *Industrial fuel use by sub-sector and fuel* */

select analysis || '|' || tablename || '|' || 'various' || '|' || 'various' || '|' || process::varchar(300) "id", analysis, tablename,'various'::varchar(50),
            'various'::varchar(50) "commodity",
            process,
            sum(case when attribute='VAR_FIn' then pv else -pv end)::numeric "all",
                (sum(case when period='2010' and attribute='VAR_FIn' then pv else 0 end)::numeric - 
             sum(case when period='2010' and attribute='VAR_FOut' then pv else 0 end)::numeric)::numeric"2010",
                        (sum(case when period='2011' and attribute='VAR_FIn' then pv else 0 end)::numeric - 
             sum(case when period='2011' and attribute='VAR_FOut' then pv else 0 end)::numeric)::numeric"2011",
                        (sum(case when period='2012' and attribute='VAR_FIn' then pv else 0 end)::numeric - 
             sum(case when period='2012' and attribute='VAR_FOut' then pv else 0 end)::numeric)::numeric"2012",
                        (sum(case when period='2015' and attribute='VAR_FIn' then pv else 0 end)::numeric - 
             sum(case when period='2015' and attribute='VAR_FOut' then pv else 0 end)::numeric)::numeric"2015",
                        (sum(case when period='2020' and attribute='VAR_FIn' then pv else 0 end)::numeric - 
             sum(case when period='2020' and attribute='VAR_FOut' then pv else 0 end)::numeric)::numeric"2020",
                        (sum(case when period='2025' and attribute='VAR_FIn' then pv else 0 end)::numeric - 
             sum(case when period='2025' and attribute='VAR_FOut' then pv else 0 end)::numeric)::numeric"2025",
                        (sum(case when period='2030' and attribute='VAR_FIn' then pv else 0 end)::numeric - 
             sum(case when period='2030' and attribute='VAR_FOut' then pv else 0 end)::numeric)::numeric"2030",
                        (sum(case when period='2035' and attribute='VAR_FIn' then pv else 0 end)::numeric - 
             sum(case when period='2035' and attribute='VAR_FOut' then pv else 0 end)::numeric)::numeric"2035",
                        (sum(case when period='2040' and attribute='VAR_FIn' then pv else 0 end)::numeric - 
             sum(case when period='2040' and attribute='VAR_FOut' then pv else 0 end)::numeric)::numeric"2040",
                        (sum(case when period='2045' and attribute='VAR_FIn' then pv else 0 end)::numeric - 
             sum(case when period='2045' and attribute='VAR_FOut' then pv else 0 end)::numeric)::numeric"2045",
                        (sum(case when period='2050' and attribute='VAR_FIn' then pv else 0 end)::numeric - 
             sum(case when period='2050' and attribute='VAR_FOut' then pv else 0 end)::numeric)::numeric"2050",
                        (sum(case when period='2055' and attribute='VAR_FIn' then pv else 0 end)::numeric - 
             sum(case when period='2055' and attribute='VAR_FOut' then pv else 0 end)::numeric)::numeric"2055",
                        (sum(case when period='2060' and attribute='VAR_FIn' then pv else 0 end)::numeric - 
             sum(case when period='2060' and attribute='VAR_FOut' then pv else 0 end)::numeric)::numeric"2060"
    from (        
        select left(process,3) || '*'::varchar(50) "process", period,pv,vintage,
            case
                when process like 'IIS%' then 'fuel-ind-is_'
                when process like 'ICM%' then 'fuel-ind-cm_'
                when process like 'INM%' then 'fuel-ind-nm_'
                when process like 'IPP%' then 'fuel-ind-pp_'
                when process like 'ICH%' then 'fuel-ind-chhvc_'
                when process like 'INF%' then 'fuel-ind-nf_'
                when process like 'IFD%' then 'fuel-ind-fd_'
                when process like 'IOI%' then 'fuel-ind-oi_'
            end ||
            case
                when commodity in ('INDBIOLFO','INDBIOLPG','INDBIOOIL','INDBOG-AD','INDBOG-LF','INDBOM','INDMAINSBOM','INDMSWORG','INDPELH','INDPELL','INDPOLWST','INDWOD','INDWODWST') then 'bio'
                when commodity in ('INDCOA','INDCOACOK') then 'coal'
                when commodity in ('INDELC','INDDISTELC') then 'elec'
                when commodity in ('INDSYNOIL','INDSYNCOA','INDNGA','INDNEUNGA','INDNEULPG','INDMAINSGAS','INDLPG','INDBFG') then 'nga'
                when commodity in ('INDHYG','INDMAINSHYG') then 'h2'
                when commodity in ('INDMSWINO') then 'inorg'
                when commodity in ('INDBENZ','INDCOG','INDCOK') then 'manf'
                when commodity in ('INDHFO','INDKER','INDLFO','INDNEULFO','INDNEULFO','INDNEUMSC') then 'oil'
                else 'other'
            end as "analysis",
            tablename, attribute, commodity
from vedastore
where attribute in ('VAR_FIn','VAR_FOut') and process like any(array['IIS%','ICM%','INM%','IPP%','ICH%','INF%','IFD%','IOI%'])
and commodity in('INDBIOLFO','INDBIOLPG','INDBIOOIL','INDBOG-AD','INDBOG-LF','INDBOM','INDMAINSBOM','INDMSWORG',
    'INDPELH','INDPELL','INDPOLWST','INDWOD','INDWODWST','INDCOA','INDCOACOK','INDELC','INDDISTELC','INDSYNOIL',
    'INDSYNCOA','INDNGA','INDNEUNGA','INDNEULPG','INDMAINSGAS','INDLPG','INDBFG','INDHYG','INDMAINSHYG','INDMSWINO',
    'INDBENZ','INDCOG','INDCOK','INDHFO','INDKER','INDLFO','INDNEULFO','INDNEULFO','INDNEUMSC')
    --and process like 'IOI%' and period='2010'
) a
    where analysis <>'' 
    group by id, analysis,process,tablename
