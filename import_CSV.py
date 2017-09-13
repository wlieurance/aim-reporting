import sqlite3, csv
#from csvkit.utilities.csvsql import CSVSQL
conn = sqlite3.connect('AIMRD.sqlite')
c = conn.cursor()
c.execute('SELECT * FROM TablesToImport ORDER BY TableName')
result = c.fetchall()

with open ('.\\CSVData\\tblSites.csv', 'r') as f:
    reader = csv.reader(f, dialect='excel')
    columns = next(reader) 
    print(columns)
    c.execute("DELETE FROM {!s}".format('tblSites'))
    query = 'INSERT INTO TblSites({0}) values ({1})'
    query = query.format(','.join(columns), ','.join('?' * len(columns)))
    cursor = conn.cursor()
    for data in reader:
        data = [x if x else None for x in data]
        print(data)
        cursor.execute(query, data)
    conn.commit()
conn.close()
