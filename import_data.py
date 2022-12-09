# import math
import sqlite3 as sqlite
import pyodbc
import os
import subprocess
import json
import re
import sqlparse


def check_compatible(path):
    ret = {'method': None, 'error_msg': None, 'odbc_driver': None}
    if os.path.splitext(path)[1].lower() in ["mdb", "accdb"]:
        if not os.path.isfile(path):
            ret['error_msg'] = "File does not exist."
            return ret
    try_mdbtools = False

    # should put the newer ACE driver {Microsoft Access Driver (*.mdb, *.accdb)} first
    drivers = sorted([x for x in pyodbc.drivers() if x.startswith('Microsoft Access Driver')], reverse=True)
    if not drivers:
        try_mdbtools = True
    else:
        driver = drivers[0]
        ret['odbc_driver'] = driver
        access_head = "Driver={" + f"{driver}" + "};DBQ="
        access_constring = ''.join((access_head, path))
        try:
            con = pyodbc.connect(access_constring)
        except pyodbc.Error as e:
            ret['error_msg'] = e
            try_mdbtools = True
            pass
        else:
            ret['method'] = 'odbc'
            con.close()
    # try mdbtools
    if try_mdbtools:
        try:
            subprocess.check_call(['mdb-json', '--version'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except (FileNotFoundError, subprocess.CalledProcessError) as e:
            ret['error_msg'] = e
            pass
        else:
            ret['method'] = 'mdbtools'
    return ret


def access_to_sqlite(access_path, sqlite_path, method, return_con=False, spatialite=False, verbose=False):
    if method == 'mdbtools':
        tables = subprocess.run(['mdb-tables', '-d', '|', access_path], stdout=subprocess.PIPE) \
            .stdout.decode('UTF-8').strip().split('|')
        tables = [x for x in tables if x]
        converted = sqlite.connect(sqlite_path)
        converted.row_factory = sqlite.Row
        if spatialite:
            converted.enable_load_extension(True)
            converted.execute("SELECT load_extension('mod_spatialite')")
            if verbose:
                print("Initializing Spatialite metadata...")
            converted.execute("SELECT InitSpatialMetaData(1);")
        c = converted.cursor()
        for tbl in tables:
            if verbose:
                print(f"Importing {tbl}...")
            c.execute(f'DROP TABLE IF EXISTS "{tbl}";')
            ddl = subprocess.run(['mdb-schema', '-T', tbl, access_path],
                                 stdout=subprocess.PIPE).stdout.decode('UTF-8')
            ddl = ddl.replace(r"Memo/Hyperlink", "Text")
            c.execute(ddl)
            # json alternative approach kept for reference.
            # raw = subprocess.run(['mdb-json', '-D', '%Y-%m-%d', '-T', '%Y-%m-%d %H:%M:%S',
            #                       access_path, tbl], stdout=subprocess.PIPE).stdout.decode('UTF-8')
            # data = json.loads(re.sub("$", "]", re.sub("^", "[", re.sub(r"}[\r\n]+{", "},{", raw.strip()))))
            inserts = subprocess.run(['mdb-export', '-I', 'sqlite', '-q', "'", '-D', '%Y-%m-%d', '-T',
                                      '%Y-%m-%d %H:%M:%S', access_path, tbl],
                                     stdout=subprocess.PIPE).stdout.decode('UTF-8')
            stmts = sqlparse.split(inserts)
            for stmt in stmts:
                c.execute(stmt)
            converted.commit()

    # elif method == 'pyodbc':
    #     access = pyodbc.connect(access_path)
    if return_con:
        return converted
    else:
        converted.close()
        return None


def ImportFromAccess(DIMApath, RDpath, delrecords, form=None):
    pyodbc.lowercase = False
    log = ""
    # connect to Access DB
    con_test = check_compatible(path=DIMApath)
    if not con_test.get('method'):
        print("Database connection error. Please ensure that the file exists, that you have either an ODBC driver of "
              "the same n-bit architecture as python installed, or that mdbtools is installed and in your PATH.")
        print(con_test)
        quit()
    else:
        method = con_test.get('method')
    if method == 'odbc':
        DIMAconstring = "Driver={" + con_test.get('odbc_driver') + "};DBQ=" + DIMApath
        DIMA = pyodbc.connect(DIMAconstring)
    elif method == 'mdbtools':
        print("Converting MS Access file to SQLite database using mdbtools.")
        DIMA = access_to_sqlite(access_path=DIMApath, sqlite_path=':memory:', method='mdbtools', return_con=True,
                                spatialite=False, verbose=True)
    else:
        print("MS Access connection method must be either 'odbc' or 'mdbtools'. Quitting..")
        quit()
    dcur = DIMA.cursor()


    # connect to SQLite3 DB
    connection = sqlite.connect(RDpath)
    connection.row_factory = sqlite.Row
    connection.enable_load_extension(True)
    connection.execute("SELECT load_extension('mod_spatialite')")

    # to be used later
    # best bet for not reworking whole thing is a transfer from mdb to :memory: sqlite first


    r = connection.execute("SELECT Value FROM Data_DBconfig WHERE VariableName = 'empty';").fetchone()
    if r[0] == '1':
        dbempty = True
    else:
        dbempty = False
        
    # get the names of tables to transfer between databases
    result = connection.execute("SELECT TableName, ImportTable, FieldString, DeleteTable "
                                "FROM TablesToImport ORDER BY TableName").fetchall()
    
    totalrows = 0
    for row in result:
        r = row['TableName']
        totalrows = totalrows + dcur.execute("SELECT Count(*) FROM {!s};".format(r)).fetchone()[0]
    print("Total rows =", totalrows)
    if form is not None:
        form.pBar2['maximum'] = totalrows
        
    # loop through tables, deleting existing SQLite data and importing new data from MS Access tables
    for row in result:
        r = row['TableName']
        i = row['ImportTable']
        if i is None:
            i = r
        if delrecords:
            if form is not None:
                form.lblAction['text'] = "Deleting rows in " + r
                form.lblAction.update_idletasks()
            if row['DeleteTable'] == 1:
                print("Deleting rows in", r, "...")
                sql = "DELETE FROM {!s};".format(r)
                connection.execute(sql)
        
        # determine which fields to import and then construct relevant SQL
        fieldstring = ""
        cursor = connection.execute("SELECT * FROM {!s};".format(i))
        fields = [description[0] for description in cursor.description]
        cursor2 = dcur.execute("SELECT * FROM {!s};".format(r))
        fields2 = [description[0] for description in cursor2.description]
        fieldsmatch = set(fields).intersection(fields2)  # this restricts to only matching fields.
        fieldsmatch = ['[' + s + ']' for s in fieldsmatch]  # in case we have stupidly named fields
        fieldstring = ', '.join(fieldsmatch)

        # necessary to add fields/values not already present in source database
        if row['FieldString'] is not None:
            additions = row['FieldString'].split(',')
            fields_add = [s.strip().split('AS') for s in additions]
            fs = []
            vs = []
            for f in fields_add:
                fs.append(f[1].strip())
                vs.append(f[0].strip().replace("'", ""))
            fs_insert = ', '.join((fieldstring, ', '.join(fs)))
        else:
            fs_insert = fieldstring
            vs = []

        # determine number of rows in table to import
        dcur.execute("SELECT Count(*) FROM {!s};".format(r))
        rownum = dcur.fetchone()[0]

        dcur.execute("SELECT {!s} FROM {!s};".format(fieldstring, r))
        fieldnum = len(dcur.description)
        if form is not None:
            form.lblAction['text'] = "Transferring data to " + i
            form.lblAction.update_idletasks()
            form.pBar['maximum'] = rownum
        print("Transferring data to", i, "...")
        
        # transfer rows of data with an SQL INSERT statement
        rows = dcur.fetchall()
        isql = "INSERT OR IGNORE INTO {!s} ({!s}) VALUES ({!s});".format(i, fs_insert,
                                                                         ','.join('?'*len(fieldsmatch+vs)))
        # print(isql)
        if len(rows) > 0:
            for r in rows:
                connection.execute(isql, list(r) + vs)
                # print(row)
                if form is not None:
                    form.pBar.step()
                    form.pBar.update_idletasks()
        form.pBar2.step(rownum)
        form.pBar2.update_idletasks()

    # connection.execute("VACUUM")  #Compresses and defrags database

    # close open connections
    connection.commit()
    connection.close()
    DIMA.close()
    return log
