def ImportFromAccess(DIMApath, RDpath, form = None):
    import tkinter
    from tkinter import Tk, Label
    import sqlalchemy #needed for sqlite interface
    import pyodbc #needed for MS Access interface
    import math
    from sqlalchemy import text, create_engine, MetaData, Table

    pyodbc.lowercase = False
    log = ""

    ### connect to Access DB
    DIMAconstring = "Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=" + DIMApath
    DIMA = pyodbc.connect(DIMAconstring)
    dcur = DIMA.cursor()

    ### connect to SQLite3 DB
    RDconstring = "sqlite:///" + RDpath
    engine = create_engine(RDconstring)
    connection = engine.connect()
    meta = MetaData()

    ### get the names of tables to transfer between databases
    result = connection.execute("SELECT TableName, ImportTable, FieldString, DeleteTable FROM TablesToImport ORDER BY TableName").fetchall()
    
    totalrows = 0
    for row in result:
        r = row['TableName']
        totalrows = totalrows + dcur.execute("SELECT Count(*) FROM " + r).fetchone()[0]
    print("Total rows =", totalrows)
    if form != None:
        form.pBar2['maximum'] = totalrows
        
    ### loop through tables, deleting existing SQLite data and importing new data from MS Access tables
    for row in result:
        r = row['TableName']
        i = row['ImportTable']
        if i == None:
            i = r
        if form != None:
            form.lblAction['text'] = "Deleting rows in " + r
            form.lblAction.update_idletasks()
        if row['DeleteTable'] == 1:
            print("Deleting rows in", r, "...")
            SQL = text("DELETE FROM " + r)
            connection.execute(SQL)
        table = Table(i, meta, autoload=True, autoload_with=engine)

        ### determine which fields to import and then construct relevant SQL
        fieldstring = ""
        cursor = connection.execute('SELECT * FROM ' + i)
        fields = [description[0] for description in cursor._cursor_description()]
        cursor2 = dcur.execute('SELECT * FROM ' + r)
        fields2 = [description[0] for description in cursor2.description]
        fieldsmatch = set(fields).intersection(fields2)

        for item in fieldsmatch:
            fieldstring = fieldstring + item + ", "
        fieldstring = fieldstring[0:len(fieldstring)-2]
        if row['FieldString'] != None:
            fieldstring = fieldstring + ', ' + row['FieldString']

        ### determine number of rows in table to import
        dcur.execute("SELECT Count(*) FROM " + r)
        rownum = dcur.fetchone()[0]

        dcur.execute("SELECT " + fieldstring + " FROM " + r)
        fieldnum = len(dcur.description)
        maxrows = math.floor(999/fieldnum) #max sqlite3 entities = 999 so fields x rownumber <= 999
        rowiter = math.ceil(rownum/maxrows) #determine number of loop iterations
        if form != None:
            form.lblAction['text'] = "Transfering data to " + r
            form.lblAction.update_idletasks()
            form.pBar['maximum'] = rowiter
        print("Transfering data to", r, "...")
        
        ### transfer blocks of data with an SQL INSERT statement, keeping each block <= 999 values and iterating till finished
        for t in range(rowiter):
            try:
                rows = dcur.fetchmany(maxrows)
                if len(rows) > 0:
                    dicmat = []
                    for row in rows:
                        dic = {}
                        for i in range(fieldnum):
                            dic[dcur.description[i][0]] = row[i]
                        dicmat.append(dic)
                    insert = table.insert().values(dicmat)
                    connection.execute(insert)
                if form != None:
                    form.pBar.step()
                    form.pBar.update_idletasks()
                    form.pBar2.step(len(rows))
                    form.pBar2.update_idletasks()
            except ValueError as err:
                log += "Import failed for " + r + " due to scientific format in number field (too large or too small)." + '\n'
                print("Import failed for: " + r + " due to scientific format in  number field (too large or too small).")
                break
    connection.execute("VACUUM")  #Compresses and defrags database
    ### close open connections
    dcur.close()
    connection.close()
    DIMA.close()
    return log
