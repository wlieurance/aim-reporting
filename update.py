def Update(RDpath, form = None):
    import tkinter
    import sqlalchemy #needed for sqlite interface
    import math
    import os.path
    from sqlite3 import dbapi2 as sqlite
    from tkinter import Tk, Label
    from sqlalchemy import text, create_engine, MetaData, Table
    from classes import stdevs, meanw, stdevw

    log = ""

    ### connect to SQLite3 DB
    RDconstring = "sqlite:///" + RDpath
    dirpath = os.path.dirname(RDpath)
    dbname = os.path.basename(RDpath)
    
    engine = create_engine(RDconstring)
    connection = engine.connect()
    dbapi_connection = connection.connection #connects to the raw sqlite3 db api
    #extpath = os.path.join(dirpath, 'Libraries', 'libsqlitefunctions64.dll')
    #dbapi_connection.enable_load_extension(True) # turns on extension loading
    #print("Loading SQlite3 extention library at:", extpath)
    #dbapi_connection.load_extension(extpath) #currently cannot load extension needed
    #dbapi_connection.execute("SELECT load_extension('C:\\Path\\To\\libsqlitefunctions64.dll')") #statically load SQlite extention functions. edit to make dynamic
    dbapi_connection.create_aggregate("stdev", 1, stdevs)
    dbapi_connection.create_aggregate("meanw", 2, meanw)
    dbapi_connection.create_aggregate("stdevw", 2, stdevw)
    meta = MetaData()


    speciesrichness(dbapi_connection)

    ### get the names of views to insert into tables & criteria
    #result = connection.execute("SELECT a.RunOrder AS TableOrder, b.* FROM ExecutionOrder AS a JOIN InsertViews AS b ON a.Name = b.InsertTable ORDER BY a.RunOrder, b.RunOrder").fetchall()
    #delTables = connection.execute("SELECT InsertTable FROM InsertViews GROUP BY InsertTable").fetchall()
    
    ### optional update form progress bar maximum to equal number of views to process
    #if form != None:
    #    form.pBar['maximum'] = len(result) + len(delTables)

    ### delete records in tables to update
    #for row in delTables:
    #    if form != None:
    #        form.lblAction['text'] = "Deleting " + row['InsertTable']
    #        form.lblAction.update_idletasks()
    #    r = row['InsertTable']
    #    delSQL = text("DELETE FROM " + r)
    #    print("Deleting data from " + r)
    #    connection.execute(delSQL)
    #    if form != None:
    #        form.pBar.step()
        

    ### loop through records in InsertViews and execute INSERT SQL for each 
    #for row in result:
    #   view = row['ViewName']
    #    table = row['InsertTable']
    #    colstring = row['ColumnString']
    #    valstring = row['ValueString']
    #    wStmt = row['WhereStatement']

        ### optional update from progressbar label
    #   if form != None:
    #        form.lblAction['text'] = "Inserting " + view + " into " + table
    #        form.lblAction.update_idletasks()

    #    SQL = "INSERT OR IGNORE INTO " + table
        #print("colstring:", colstring)
        #print("valstring:", valstring)
    #    if colstring == None:
    #        if valstring == None:
    #            SQL = SQL + " SELECT * FROM " + view
    #        else:
    #            SQL = SQL + " SELECT " + valstring + " FROM " + view
    #    else:
    #       if valstring == None:
    #            SQL = SQL + " (" + colstring + ") SELECT * FROM " + view
    #        else:
    #            SQL = SQL + " (" + colstring + ") SELECT " + valstring + " FROM " + view
    #    if wStmt != None:
    #        SQL = SQL + " WHERE " + wStmt
    #    SQLtext = text(SQL)
    #    print("Inserting " + view + " into " + table)
    #    connection.execute(SQLtext)
        ### optional update form progress bar
    #    if form != None:
    #        form.pBar.step()
    #        form.pBar.update_idletasks()
    SeasonsCalc(RDpath)
    result = connection.execute("SELECT * FROM UpdateViews ORDER BY RunOrder")
    for row in result:
        connection.execute(row['SQL'])
    connection.execute("VACUUM")
    connection.close()
    return log

def SeasonsCalc(RDpath):
    import sqlalchemy #needed for sqlite interface
    from sqlalchemy import text, create_engine, MetaData, Table
    import datetime
    import calendar

    RDconstring = "sqlite:///" + RDpath
    engine = create_engine(RDconstring)
    connection = engine.connect()
    meta = MetaData()

    connection.execute("DELETE FROM SeasonDefinition")
    
    result = connection.execute("SELECT * FROM Data_DateRange")
    row = result.fetchone()
    startdate = datetime.datetime.strptime(row['StartDate'],'%Y-%m-%d')
    enddate = datetime.datetime.strptime(row['EndDate'],'%Y-%m-%d')
    slength = row['SeasonLength_Months']
    
    slength_years = slength / 12

    table = Table('SeasonDefinition', meta, autoload=True, autoload_with=engine)
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
    connection.close()
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



