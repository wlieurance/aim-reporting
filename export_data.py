import os
import sqlalchemy
import openpyxl

import tkinter
#separate imports needed due to tkinter idiosyncrasies
from tkinter import ttk
from tkinter import filedialog, messagebox

from classes import stdevs, meanw, stdevw

class ExportForm:
    def __init__(self, parent, child, RDpath, connection):
        cframe = tkinter.Frame(child)
        cframe.grid()

        self.valueCat = []
        self.valueData = []
        self.valueScale = []
        self.connection = connection

        self.style = ttk.Style()
        self.style.configure("TButton", padding=6, relief="flat", background="#ccc", width=20)

        self.lblExport = ttk.Label(child, text="Export:")
        self.lblExport.grid(row=0, column = 0, columnspan =3, sticky = "W")

        self.lstCategory = tkinter.Listbox(child, selectmode = tkinter.EXTENDED, exportselection =0)
        self.lstCategory.grid(row=1, column = 0)

        self.lstDataType = tkinter.Listbox(child, selectmode = tkinter.EXTENDED, exportselection =0)
        self.lstDataType.grid(row=1, column = 1)

        self.lstScale = tkinter.Listbox(child, selectmode = tkinter.EXTENDED, exportselection =0)
        self.lstScale.grid(row=1, column = 2)

        self.btnSelectAll = ttk.Button(child, text='Select All', style="TButton", command=self.selectall)
        self.btnSelectAll.grid(row=2, column = 0)

        self.btnClear = ttk.Button(child, text='Clear Selection', style="TButton", command=self.clearall)
        self.btnClear.grid(row=2, column = 1)

        self.btnExport = ttk.Button(child, text='Export Selection', style="TButton", command=self.exportselection)
        self.btnExport.grid(row=2, column = 2)

        result = connection.execute("SELECT Category FROM Exports_All GROUP BY Category ORDER BY Category;")
        for row in result:
            # print(row)
            self.lstCategory.insert(tkinter.END, row['Category'])

        def onselect_Category(evt):
            self.lstDataType.delete(0, tkinter.END)
            self.lstScale.delete(0, tkinter.END)
            w = evt.widget
            c = w.curselection()
            value = []
            li = len(c)
            for i in range(0, li):
                value.append(w.get(c[i]))
            #print(value)
            self.valueCat = value
            where1 = "'"
            for i in value:
                where1 = where1 + "'" + i + "', "
            where1 = where1[1:len(where1)-2]
            s = "SELECT DataType FROM Exports_All WHERE Category IN (" + where1 + ") GROUP BY DataType ORDER BY DataType;"
            result = connection.execute(s)
            for row in result:
                self.lstDataType.insert(tkinter.END, row['DataType'])

        def onselect_DataType(evt):
            self.lstScale.delete(0, tkinter.END)
            w = evt.widget
            c = w.curselection()
            value = []
            li = len(c)
            for i in range(0, li):
                value.append(w.get(c[i]))
            #print(value)
            self.valueData = value
            where1 = "'"
            for i in value:
                where1 = where1 + "'" + i + "', "
            where1 = where1[1:len(where1)-2]
            where2 = "'"
            for i in self.valueCat:
                where2 = where2 + "'" + i + "', "
            where2 = where2[1:len(where2)-2]
            s = "SELECT Scale FROM Exports_All WHERE DataType IN ("+ where1 + ") AND Category IN (" + where2 + ") GROUP BY Scale ORDER BY Scale;"
            result = connection.execute(s)
            for row in result:
                #print(row)
                self.lstScale.insert(tkinter.END, row['Scale'])

        def onselect_Scale(evt):
            w = evt.widget
            c = w.curselection()
            value = []
            li = len(c)
            for i in range(0, li):
                value.append(w.get(c[i]))
            #print(value)
            self.valueScale = value

        self.lstCategory.bind('<<ListboxSelect>>', onselect_Category)
        self.lstDataType.bind('<<ListboxSelect>>', onselect_DataType)
        self.lstScale.bind('<<ListboxSelect>>', onselect_Scale)

    def selectall(self):
        self.lstCategory.select_set(0, tkinter.END)
        c = self.lstCategory.curselection()
        value = []
        li = len(c)
        for i in range(0, li):
            value.append(self.lstCategory.get(c[i]))
        self.valueCat = value

        result = self.connection.execute("SELECT DataType FROM Exports_All GROUP BY DataType ORDER BY DataType;")
        for row in result:
            self.lstDataType.insert(tkinter.END, row['DataType'])
        self.lstDataType.select_set(0, tkinter.END)
        c = self.lstDataType.curselection()
        value = []
        li = len(c)
        for i in range(0, li):
            value.append(self.lstDataType.get(c[i]))
        self.valueData = value

        result = self.connection.execute("SELECT Scale FROM Exports_All GROUP BY Scale ORDER BY Scale;")
        for row in result:
            self.lstScale.insert(tkinter.END, row['Scale'])
        self.lstScale.select_set(0, tkinter.END)
        c = self.lstScale.curselection()
        value = []
        li = len(c)
        for i in range(0, li):
            value.append(self.lstScale.get(c[i]))
        self.valueScale = value

    def clearall(self):
        self.lstDataType.delete(0, tkinter.END)
        self.lstScale.delete(0, tkinter.END)
        self.lstCategory.selection_clear(0, tkinter.END)

    def exportselection(self):
        where1 = "'"
        for i in self.valueCat:
            where1 = where1 + "'" + i + "', "
        where1 = where1[1:len(where1) - 2]

        where2 = "'"
        for i in self.valueData:
            where2 = where2 + "'" + i + "', "
        where2 = where2[1:len(where2) - 2]

        where3 = "'"
        for i in self.valueScale:
            where3 = where3 + "'" + i + "', "
        where3 = where3[1:len(where3) - 2]
        #print(where1, " - ", where2, " - ", where3)
        
        #I know this sort of construction is subject to SQL injection attacks, but constructing it properly through sqlalchemy is super annoying.
        s = "SELECT ObjectName, ExportName FROM Exports_All WHERE Category IN (" + where1 + ") AND DataType IN (" + where2 + ") AND Scale IN (" + where3 + ") ORDER BY Category, Scale, DataType, ExportName;"
        result = self.connection.execute(s)
        path = tkinter.filedialog.asksaveasfilename(defaultextension = ".xlsx", title="Choose filename for export:", filetypes=(("Excel files", "*.xlsx"),("All files", "*.*")))
        if os.path.isfile(path):
            os.remove(path)
        if path:
            try:
                #workbook = xlsxwriter.Workbook(path)
                workbook = openpyxl.Workbook()
                exportEmpty = True # this checks to see if the user wants to export empty views/tables
                asked = False # this keeps track of whether the user was asked to export blanks or not
                for row in result:
                    if os.path.isfile(path):    
                        workbook = openpyxl.load_workbook(filename = path)
                    else:
                        workbook = openpyxl.Workbook()
                    self.lblExport['text'] = "                                                                                          "
                    self.lblExport.update_idletasks()
                    self.lblExport['text'] = "Exporting " + row["ExportName"] + "..."
                    self.lblExport.update_idletasks()
                    result2 = self.connection.execute("SELECT * FROM " + row["ObjectName"])
                    emptytest = result2.fetchone()
                    result2 = self.connection.execute("SELECT * FROM " + row["ObjectName"]) #resents record set after fetchone(). Attempted SELECT Count(*) but kept getting MemoryErrors 
                    if emptytest is None:
                        if not asked:
                            exportEmpty = tkinter.messagebox.askyesno("Export Blanks", "Export blank results?")
                            asked = True
                    if emptytest is not None or (emptytest is None and exportEmpty):          
                        print("Exporting",row["ExportName"],"...")
                        if os.path.isfile(path):
                            worksheet = workbook.create_sheet(title=row["ExportName"])
                        else:
                            worksheet = workbook.active
                            worksheet.title = row["ExportName"]
                        colnames = result2.keys()
                        worksheet.append(colnames)
                        for row2 in result2:
                            d = dict(row2)
                            for key, value in d.items(): #necessary in order to tell excel that strings starting with '=' are not formulas
                                if isinstance(value, str):
                                    if len(value) > 0:
                                        if(value[0]=='='):
                                            d[key]= ''.join(("'",value))
                            worksheet.append(list(d.values()))
                        workbook.save(path)
                    else:
                        print("Skipping",row["ExportName"],"...")
                print("Finished Exporting.")
                tkinter.messagebox.showinfo("Success", "Export complete.")
                self.lblExport['text'] = "Export:"
                self.lblExport.update_idletasks()
                self.clearall()

            except PermissionError:
                tkinter.messagebox.showinfo("Error", "Could not access" + os.linesep + path + os.linesep +"File may be in use.")


def Export(RDpath, form = None):
    RDconstring = "sqlite:///" + RDpath
    dirpath = os.path.dirname(RDpath)
    dbname = os.path.basename(RDpath)
    
    engine = sqlalchemy.create_engine(RDconstring)
    connection = engine.connect()
    dbapi_connection = connection.connection
    dbapi_connection.create_aggregate("stdev", 1, stdevs)
    dbapi_connection.create_aggregate("meanw", 2, meanw)
    dbapi_connection.create_aggregate("stdevw", 2, stdevw)
    meta = sqlalchemy.MetaData()

    child = tkinter.Tk()
    cf = ExportForm(form, child, RDpath, connection)
    child.mainloop()
    connection.close()
    return;



