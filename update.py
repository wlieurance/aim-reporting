import os
import datetime
import calendar
import sqlite3 as sqlite
import geomag
import tkinter
from tkinter import filedialog, messagebox  # separate imports needed due to tkinter idiosyncrasies
# from tkinter import ttk
import sqlparse

# local objects
from classes import stdevs, meanw, stdevw


# begin function definition
def run_sqlscript(conn, script_path, form=None, msg=None):
    if script_path is None:
        script_path = tkinter.filedialog.askopenfilename(title="Choose SQL script to run on Database.",
                                                         filetypes=(("SQL files", "*.sql"), ("All files", "*.*")))
    if os.path.isfile(script_path):
        with open(script_path) as f:
            script = f.read()
        stmts = sqlparse.split(script)

        # update messages
        if msg is not None:
            print(msg)
        if form is not None:
            form.lblAction['text'] = msg
            form.lblAction.update_idletasks()
            
        # initial values get the while loop to run at least once.
        curlength = 1
        pastlength = 2 
        counter = 0
        while pastlength > curlength > 0:
            errors = []
            counter += 1
            # print("Script pass",str(counter))
            pastlength = len(stmts)
            for stmt in stmts:
                try:
                    # print(stmt, '\n', '------------------------------------------------------', '\n',
                    #       '------------------------------------------------------')
                    conn.execute(stmt)
                    # removes SQL statement from list if completed successfully
                    stmts = [x for x in stmts if x != stmt]
                except sqlite.OperationalError:
                    errors.append(stmt)
            curlength = len(stmts)   

        if len(stmts) == 0:
            return True, None
        else:
            return False, stmts
    else:
        return False, None


def Update(var, form=None):
    RDpath = var['RDpath']
    log = ""
    sqldir = var['SQLpath']
    
    # connect to SQLite3 DB
    dirpath = os.path.dirname(RDpath)
    dbname = os.path.basename(RDpath)
    connection = sqlite.connect(RDpath)

    # creating these functions allows for custom aggreate functions within the database. See classes.py for definition.
    connection.create_aggregate("stdev", 1, stdevs)
    connection.create_aggregate("meanw", 2, meanw)
    connection.create_aggregate("stdevw", 2, stdevw)
    connection.enable_load_extension(True)
    connection.row_factory = sqlite.Row
    c = connection.cursor()

    # converts DIMA species list semi-colon concatenated values to individual species records for ease of processing.
    speciesrichness(connection)
    # runs update SQL script to perform various post import updates given in the script.
    run_sqlscript(connection, script_path=os.path.join(sqldir, 'update.sql'),
                  form=form, msg='Running update script...')
    # runs insert_tags SQL script to automatically create some species and plot tags given in the SQL script
    # (e.g. sagebrush = woody Artemisia sp.)
    run_sqlscript(connection, script_path=os.path.join(sqldir, 'insert_tags.sql'), form=form,
                  msg=r'Inserting plot/species tags into database...')
    # runs insert_custom SQL script to insert custom data defined by the user into the db.
    run_sqlscript(connection, script_path=os.path.join(sqldir, 'insert_custom.sql'), form=form,
                  msg=r'Inserting custom data into the database...')
    # defines how to group plots together when looking at plot level info. Only one plot with the same plotkey is
    # shown per season.
    SeasonsCalc(connection)
    
    # add declination information to tblPlots
    msg = "Adding declination information to plots."
    print(msg)
    if form is not None:
        form.lblAction['text'] = msg
        form.lblAction.update_idletasks()
        
    if var['WMMpath'] is None:
        getwmm = True
    elif not os.path.isfile(var['WMMpath']):
        getwmm = True
    else:
        getwmm = False
        mmpath = var['WMMpath']
    mmpath = None
    if getwmm:
        getmm = tkinter.messagebox.askyesno("Calculate declination?",
                                            "Would you like to calulate the magnetic declination of imported plots "
                                            "(is required for some spatial QC checks)?")
        if getmm:
            mmpath = tkinter.filedialog.askopenfilename(
                title="Choose NOAA World Magnetic Model location (i.e. WMM.COF).",
                filetypes=(("Magnetic Model files", "*.COF"), ("All files", "*.*")))
            var['WMMpath'] = mmpath
    if mmpath:
        gm = geomag.geomag.GeoMag(mmpath)
        i = connection.cursor()
        rows = connection.execute('\n'.join((
            "SELECT PlotKey, PlotID, Latitude, Longitude, Elevation, ElevationType, EstablishDate, Declination ",
            "  FROM tblPlots WHERE PlotKey NOT IN ('888888888','999999999') AND Declination IS NULL;"
        )))
        for row in rows:
            if row['EstablishDate']:
                dt = datetime.datetime.strptime(row['EstablishDate'], '%Y-%m-%d %H:%M:%S')
                if row['ElevationType'] == 1:
                    elev = row['Elevation']*3.28084
                elif row['ElevationType'] == 2:
                    elev = row['Elevation']
                else:
                    elev = 0
                mag = gm.GeoMag(row['Latitude'], row['Longitude'], elev, dt.date())
                i.execute("UPDATE tblPlots SET Declination = ? WHERE PlotKey = ?;", (mag.dec, row['PlotKey']),)
            else:
                print("Plot", row['PlotID'], "has no EstablishDate. Skipping.")
        connection.commit()

    # connection.execute("VACUUM")
    connection.close()
    return var


# defines seasons, which the database uses to separate out plot revisits. When data are shown at the plot level,
# a season is given to it in order to view multiple visitations of the same plot.  For above plot summations,
# only the most recent data in a revisit cycle is used.
def SeasonsCalc(connection):
    connection.execute("DELETE FROM SeasonDefinition")

    # checks if a data date range is provided and if not inserts a default range based on date values from tblPlots
    rcount = connection.execute("SELECT Count(*) FROM Data_DateRange").fetchone()[0]
    if rcount == 0:
        sql = """INSERT INTO Data_DateRange SELECT strftime('%Y', Min(EstablishDate)) || 
                '-01-01' AS StartDate, strftime('%Y', Max(EstablishDate)) || '-12-31' 
                AS EndDate, 12 AS SeasonLength_Months FROM tblPlots;"""
        connection.execute(sql)

    result = connection.execute("SELECT * FROM Data_DateRange")
    row = result.fetchone()
    startdate = datetime.datetime.strptime(row['StartDate'], '%Y-%m-%d')
    enddate = datetime.datetime.strptime(row['EndDate'], '%Y-%m-%d')
    slength = row['SeasonLength_Months']
    slength_years = slength / 12
    date = startdate
    while date < enddate:
        if calendar.isleap(date.year):
            days = 366
        else:
            days = 365
        nextdate = date + datetime.timedelta(days=(slength_years * days))
        send = nextdate - datetime.timedelta(microseconds=1)
        season = date.strftime('%Y%m%d') + "-" + send.strftime('%Y%m%d')
        sql = "INSERT INTO SeasonDefinition (SeasonStart, SeasonEnd, SeasonLabel) VALUES (?,?,?);"
        connection.execute(sql, (date, send, season,))
        date = nextdate   
    return


# this function is used to convert the semicolon delimited species richness fields into individual records for ease
# of processing.
def speciesrichness(connection):
    connection.execute("DELETE FROM SR_Raw;")
    result = connection.execute("SELECT RecKey, subPlotID, SpeciesList FROM tblSpecRichDetail;")
    for row in result:
        speclist = []
        species = row[2].split(sep=';')
        for s in species:
            if s and row[0] and row[1]:
                speclist.append((row[0], row[1], s))
        # print(speclist)
        connection.executemany('INSERT OR IGNORE INTO SR_Raw VALUES (?,?,?)', speclist)
    connection.commit()
# end function definition
