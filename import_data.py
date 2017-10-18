import math
import sqlite3 as sqlite
import pyodbc

def ImportFromAccess(DIMApath, RDpath, delrecords, form = None):

    pyodbc.lowercase = False
    log = ""

    ### connect to Access DB
    ### current only works in a windows environment because linux and mac system do not have an odbc driver for Access files.
    DIMAconstring = "Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=" + DIMApath
    DIMA = pyodbc.connect(DIMAconstring)
    dcur = DIMA.cursor()

    ### connect to SQLite3 DB
    connection = sqlite.connect(RDpath)
    connection.row_factory = sqlite.Row
    connection.enable_load_extension(True)
    connection.execute("SELECT load_extension('mod_spatialite')")

    r = connection.execute("SELECT Value FROM Data_DBconfig WHERE VariableName = 'empty';").fetchone()
    if r[0] == '1':
        dbempty = True
    else:
        dbempty = False
        
    ### get the names of tables to transfer between databases
    result = connection.execute("SELECT TableName, ImportTable, FieldString, DeleteTable FROM TablesToImport ORDER BY TableName").fetchall()
    
    totalrows = 0
    for row in result:
        r = row['TableName']
        totalrows = totalrows + dcur.execute("SELECT Count(*) FROM {!s};".format(r)).fetchone()[0]
    print("Total rows =", totalrows)
    if form != None:
        form.pBar2['maximum'] = totalrows
        
    ### loop through tables, deleting existing SQLite data and importing new data from MS Access tables
    for row in result:
        r = row['TableName']
        i = row['ImportTable']
        if i == None:
            i = r
        if delrecords:
            if form != None:
                form.lblAction['text'] = "Deleting rows in " + r
                form.lblAction.update_idletasks()
            if row['DeleteTable'] == 1:
                print("Deleting rows in", r, "...")
                sql = "DELETE FROM {!s};".format(r)
                connection.execute(sql)
        
        ### determine which fields to import and then construct relevant SQL
        fieldstring = ""
        cursor = connection.execute("SELECT * FROM {!s};".format(i))
        fields = [description[0] for description in cursor.description]
        cursor2 = dcur.execute("SELECT * FROM {!s};".format(r))
        fields2 = [description[0] for description in cursor2.description]
        fieldsmatch = set(fields).intersection(fields2) # this restricts to only matching fields.
        fieldsmatch = ['[' + s + ']' for s in fieldsmatch] # in case we have stupidly named fields
        fieldstring = ', '.join(fieldsmatch)

        ###necessary to add fields/values not already present in source database
        if row['FieldString'] != None:
            additions = row['FieldString'].split(',')
            fields_add = [s.strip().split('AS') for s in additions]
            fs = []
            vs = []
            for f in fields_add:
                fs.append(f[1].strip())
                vs.append(f[0].strip().replace("'",""))
            fs_insert = ', '.join(((fieldstring, ', '.join(fs))))
        else:
            fs_insert = fieldstring
            vs = []
        

        ### determine number of rows in table to import
        dcur.execute("SELECT Count(*) FROM {!s};".format(r))
        rownum = dcur.fetchone()[0]

        dcur.execute("SELECT {!s} FROM {!s};".format(fieldstring, r))
        fieldnum = len(dcur.description)
        if form != None:
            form.lblAction['text'] = "Transfering data to " + i
            form.lblAction.update_idletasks()
            form.pBar['maximum'] = rownum
        print("Transfering data to", i, "...")
        
        ### transfer rows of data with an SQL INSERT statement
        rows = dcur.fetchall()
        isql = "INSERT OR IGNORE INTO {!s} ({!s}) VALUES ({!s});".format(i, fs_insert, ','.join('?'*len(fieldsmatch+vs)))
        #print(isql)
        if len(rows) > 0:
            for row in rows:
                connection.execute(isql,list(row) + vs)
                #print(row)
                if form != None:
                    form.pBar.step()
                    form.pBar.update_idletasks()
        form.pBar2.step(rownum)
        form.pBar2.update_idletasks()

    #connection.execute("VACUUM")  #Compresses and defrags database

    ### close open connections
    connection.commit()
    connection.close()
    DIMA.close()
    return log
