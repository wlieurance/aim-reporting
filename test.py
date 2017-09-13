import os
from sqlalchemy import text, create_engine, MetaData, Table
from classes import stdevs
from numpy import std

RDpath = "C:\\Users\\wlieurance\\Documents\\Reporting Database\\AIMRD.sqlite"
RDconstring = "sqlite:///" + RDpath
engine = create_engine(RDconstring)
connection = engine.connect()
dbapi_connection = connection.connection
dbapi_connection.create_aggregate("sd", 1, stdevs)

SQL = "SELECT PlotID, sd(CoverPct) AS SD FROM Cover_Line GROUP BY PlotID ORDER BY PlotID"
rows = connection.execute(SQL)
r = rows.fetchone()
print(r)
