import os
import datetime
import calendar
import sqlalchemy
from classes import stdevs, meanw, stdevw

def Update(RDpath, form = None):
    log = ""
    sqldir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "sql")
    
    ### connect to SQLite3 DB
    RDconstring = "sqlite:///" + RDpath
    dirpath = os.path.dirname(RDpath)
    dbname = os.path.basename(RDpath)
    engine = sqlalchemy.create_engine(RDconstring)
    connection = engine.connect()
    dbapi_connection = connection.connection #connects to the raw sqlite3 db api
    dbapi_connection.create_aggregate("stdev", 1, stdevs)
    dbapi_connection.create_aggregate("meanw", 2, meanw)
    dbapi_connection.create_aggregate("stdevw", 2, stdevw)
    c = dbapi_connection.cursor()
    meta = sqlalchemy.MetaData()

    speciesrichness(dbapi_connection)
    SeasonsCalc(connection, engine, meta)
    with open(os.path.join(sqldir, 'update.sql')) as f:
        update = f.read()
        msg = "Running update script..."
        if form != None:
            form.lblAction['text'] = msg
            form.lblAction.update_idletasks()
        print(msg)
        c.executescript(update)
    with open(os.path.join(sqldir, 'insert_tags.sql')) as f:
        tags = f.read()
        msg = "Inserting plot/species tags into database..."
        if form != None:
            form.lblAction['text'] = msg
            form.lblAction.update_idletasks()
        print(msg)
        c.executescript(tags) #must access raw dbapi for this one
    connection.execute("VACUUM")
    connection.close()
    return log

def SeasonsCalc(connection, engine, meta):
    connection.execute("DELETE FROM SeasonDefinition")

    #checks if a data date range is provided and if not inserts a default range based on date values from tblPlots 
    rcount = connection.execute("SELECT Count(*) FROM Data_DateRange").fetchone()[0]
    if rcount == 0:
        sql = """INSERT INTO Data_DateRange SELECT strftime('%Y', Min(EstablishDate)) || 
                '-01-01' AS StartDate, strftime('%Y', Max(EstablishDate)) || '-12-31' 
                AS EndDate, 12 AS SeasonLength_Months FROM tblPlots;"""
        connection.execute(sql)

    result = connection.execute("SELECT * FROM Data_DateRange")
    row = result.fetchone()
    startdate = datetime.datetime.strptime(row['StartDate'],'%Y-%m-%d')
    enddate = datetime.datetime.strptime(row['EndDate'],'%Y-%m-%d')
    slength = row['SeasonLength_Months']
    slength_years = slength / 12
    table = sqlalchemy.Table('SeasonDefinition', meta, autoload=True, autoload_with=engine)
    date = startdate
    while date < enddate:
        if calendar.isleap(date.year):
            days = 366
        else:
            days = 365
        nextdate = date + datetime.timedelta(days = (slength_years * days))
        send = nextdate - datetime.timedelta(microseconds = 1)
        season = date.strftime('%Y%m%d') + "-" + send.strftime('%Y%m%d')
        dic = {'SeasonStart': date, 'SeasonEnd': send, 'SeasonLabel': season}
        insert = table.insert().values(dic)
        connection.execute(insert)
        date = nextdate   
    return
    
def speciesrichness(connection):
    result = connection.execute("SELECT RecKey, subPlotID, SpeciesList FROM tblSpecRichDetail")
    for row in result:
        speclist = []
        species = row[2].split(sep=';')
        for s in species:
            if s and row[0] and row[1]:
                speclist.append((row[0],row[1],s))
        #print(speclist)
        connection.executemany('INSERT OR IGNORE INTO SR_Raw VALUES (?,?,?)', speclist)
    connection.commit()



