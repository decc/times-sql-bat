Guide to extracting/viewing UKTM outputs through PostGres database
==================================================================

The batch files described below create SQL scripts which upload and process all the VD files in the directory they're in. The SQL crosstab queries run by the batch files are repeated in "HumanReadableQueries.sql" with added commentary and formatted for readability.

Because the SQL scripts include all the VD files and create temporary database tables, they can be used to generate the same temporary tables for an interactive query session—you can then run bespoke cross-tabs or other analyses against these. Instructions for this below.

Note that the code creates the following 2 temp tables on the database:
*	*vedastore:* contains the data from all the VD files. Point any bespoke code at this
*	*veda:* temp table used solely to remove first 13 lines of VD file. Ignore

Since each postgres session is independent, the fact that the same table names are used for each batch file doesn't matter.

*1)	To run the DOS scripts:*

*	Requires a postgres (database) installation on the same machine as the one where you're processing the results. This must have been set up to have a superuser called "postgres" and to have the password stored. Must also have a database called "gams" [or change the batch file below to reflect some other database name: note that there is always a postgres database so you could use that].
*	You may need to set authentification to "trust" for local connections and to create a pgpass.conf file to prevent the batch process from asking for a password at every step. See the postgres help docs for more info.
*	Put your VD files in a separate folder. The script currently has the limitation that the path to this must not contain spaces. For example, put here:
C:\VTI_Local_4\Veda_FE\GAMS_WrkTIMES\upload_results
*	Put the batch file(s) in the folder and double-click on each to run it/them. The batch file(s) will be called something like "UploadResults.BAT".
*	Each batch file processes all the VD files in the folder. It creates a CSV called "ResultsOut.csv" (or similar) in the same folder. This contains the standardised results for the cross-tabs. If the batch process doesn't work check that the command line which invokes psql is pointing to the correct location. This will vary with the postgres installation and will be something like "C:\Program Files\PostgreSQL\9.4\bin"

*2)	To run manual (bespoke) queries:*
SQL script generated as part of above is called "VedaBatchUpload.sql" (or similar) in the same folder

Run manual postgres queries with PostgreSQL by: 
*	Opening C:\Program Files\PostgreSQL\9.4\bin\pgAdmin3
(This has the elephant logo; will be under "all programs" =>"PostgreSQL" if a quick link hasn't been added to the taskbar.) This will show a closed tree list of servers (i.e. postgres installations) and, under this, databases, tables etc.
*	Ensure that File=>Options=>Browser [rh panel]=>UI Miscellaneous=> "Show System Objects in the treeview" is ticked on. This allows you to see and manipulate temporary tables in the Graphical Query Builder described below. Not necessary if you're just writing SQL code.
*	Double-click on the postgres (server) installation to open its folder tree.
*	Open the "gams" [or whatever] database folder tree. Selecting this or one of its child objects is important prior to running code as queries are run against the currently selected object in the tree and the code we're about to run points to this database.
*	Click on the SQL query icon to generate a new blank query.
*	Generate the SQL upload code with the batch script:—you can comment out the line which actually runs the code if you just want the sql code itself. Open the resulting file "VedaBatchUpload.sql" (or similar) with a text editor like notepad++.
*	Select & copy the text as far down as just before the first "COPY ( select…" statement [starts on a new line] and paste this into the PgAdmin3 SQL query window. The location of this line in the file will depend on how many VD files have been processed.
*	Select and run the code. Do this by either pressing F5 or by pressing the first green arrow next to the magnifying glass. This creates a temporary table called "vedastore" which contains all the data from the VD files.
*	You can then run SQL queries such as:
    *	Select * from vedastore limit 667;
    *	Select * from vedastore where process like 'ADIS%'
    *	Select * from vedastore where period = ‘2010’
    etc
*	You can now write bespoke cross-tabs etc. against this using SQL (select and run any code as above); or by using the graphical query builder (other tab of the window). The latter is something like the MS Access query builder window. Note that to see the temporary table vedastore in the graphical query builder, you need to find the correct schema in the tree to the left of the screen. The temporary tables will be in the schema called something like "pg_temp_<some number>". It will be the one with the cross next to it to show that there's more than one entry. Click on this. Then drag the vedastore table to the main window and construct your query. Run as above.
*	You can select, copy and paste the results from the results window below the query window. If you do this, note that field [column] headings will be missing. If you instead do "Query"=>"Execute to file" you will have the headings. In both cases will need to break results into fields again when in XLS [default delimiter is ";" but you can change this in the settings.]. In Excel this is done by Data -> data tools -> Text to columns

*3)	Notes / caveats on what is being extracted*

*	Bio calculations: CHP consumption is included at end-use sector level rather than central electricity level. No adjustments are made for biomethane losses.
*	Grid intensity:
    *	emissions = ("CHP_out_emis" + "elec_out_emis" – “elec_sav_emis”)/1000
    *	electricity = ("CHP+Other_elec" - "WasteHeat_elec")/3600
    *	Intensity (gCO2e/KWh) = emissions / electricity

*4)   List of BAT files*
*  UploadResults.bat. The main batch file with high level outputs like GHG by main sector
*  transport.bat. Road transport-specific queries giving mileage, emissions, capacity etc. for various types of vehicle
*  Ag_&_LULUCF.bat. Queries relating to agriculture and Land Use and Land Use Change and Forestry (LULUCF)

