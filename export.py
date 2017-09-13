from tkinter import *
from tkinter import Frame, Label, Listbox, Button, Tk, filedialog, messagebox, END, MULTIPLE, SINGLE
from tkinter.ttk import *
from sqlalchemy import text, create_engine, MetaData, Table, select
import os.path
import xlsxwriter
from classes import stdevs, meanw, stdevw

class ExportForm:
    def __init__(self, parent, child, RDpath, connection):
        cframe = Frame(child)
        cframe.grid()

        self.valueCat = []
        self.valueData = []
        self.valueScale = []
        self.connection = connection

        self.style = Style()
        self.style.configure("TButton", padding=6, relief="flat", background="#ccc", width=20)

        self.lblExport = Label(child, text="Export:")
        self.lblExport.grid(row=0, column = 0, columnspan =3, sticky = "W")

        self.lstCategory = Listbox(child, selectmode = MULTIPLE, exportselection =0)
        self.lstCategory.grid(row=1, column = 0)

        self.lstDataType = Listbox(child, selectmode = MULTIPLE, exportselection =0)
        self.lstDataType.grid(row=1, column = 1)

        self.lstScale = Listbox(child, selectmode = MULTIPLE, exportselection =0)
        self.lstScale.grid(row=1, column = 2)

        self.btnSelectAll = Button(child, text='Select All', style="TButton", command=self.selectall)
        self.btnSelectAll.grid(row=2, column = 0)

        self.btnClear = Button(child, text='Clear Selection', style="TButton", command=self.clearall)
        self.btnClear.grid(row=2, column = 1)

        self.btnExport = Button(child, text='Export Selection', style="TButton", command=self.exportselection)
        self.btnExport.grid(row=2, column = 2)

        result = connection.execute("SELECT Category FROM Exports GROUP BY Category ORDER BY Category")
        for row in result:
            # print(row)
            self.lstCategory.insert(END, row['Category'])

        def onselect_Category(evt):
            self.lstDataType.delete(0, END)
            self.lstScale.delete(0, END)
            w = evt.widget
            c = w.curselection()
            value = []
            li = len(c)
            for i in range(0, li):
                value.append(w.get(c[i]))
            #print(value)
            self.valueCat = value
            where = "'"
            for i in value:
                where = where + "'" + i + "', "
            where = where[1:len(where)-2]
            result = connection.execute("SELECT DataType FROM Exports WHERE Category IN (" + where + ") GROUP BY DataType ORDER BY DataType")
            for row in result:
                #print(row)
                self.lstDataType.insert(END, row['DataType'])

        def onselect_DataType(evt):
            self.lstScale.delete(0, END)
            w = evt.widget
            c = w.curselection()
            value = []
            li = len(c)
            for i in range(0, li):
                value.append(w.get(c[i]))
            #print(value)
            self.valueData = value
            where = "'"
            for i in value:
                where = where + "'" + i + "', "
            where = where[1:len(where)-2]
            where2 = "'"
            for i in self.valueCat:
                where2 = where2 + "'" + i + "', "
            where2 = where2[1:len(where2)-2]
            result = connection.execute("SELECT Scale FROM Exports WHERE DataType IN (" + where + ") AND Category IN (" + where2 + ") GROUP BY Scale ORDER BY Scale")
            for row in result:
                #print(row)
                self.lstScale.insert(END, row['Scale'])

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
        self.lstCategory.select_set(0, END)
        c = self.lstCategory.curselection()
        value = []
        li = len(c)
        for i in range(0, li):
            value.append(self.lstCategory.get(c[i]))
        self.valueCat = value

        result = self.connection.execute("SELECT DataType FROM Exports GROUP BY DataType ORDER BY DataType")
        for row in result:
            self.lstDataType.insert(END, row['DataType'])
        self.lstDataType.select_set(0, END)
        c = self.lstDataType.curselection()
        value = []
        li = len(c)
        for i in range(0, li):
            value.append(self.lstDataType.get(c[i]))
        self.valueData = value

        result = self.connection.execute("SELECT Scale FROM Exports GROUP BY Scale ORDER BY Scale")
        for row in result:
            self.lstScale.insert(END, row['Scale'])
        self.lstScale.select_set(0, END)
        c = self.lstScale.curselection()
        value = []
        li = len(c)
        for i in range(0, li):
            value.append(self.lstScale.get(c[i]))
        self.valueScale = value

    def clearall(self):
        self.lstDataType.delete(0, END)
        self.lstScale.delete(0, END)
        self.lstCategory.selection_clear(0, END)

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

        result = self.connection.execute("SELECT ObjectName, ExportName FROM Exports WHERE Category IN (" + where1 + ") AND DataType IN (" + where2 + ") AND Scale IN (" + where3 + ") ORDER BY Category, Scale, DataType, ExportName")
        path = filedialog.asksaveasfilename(defaultextension = ".xlsx", title="Choose filename for export:", filetypes=(("Excel files", "*.xlsx"),("All files", "*.*")))

        if path:
            try:
                workbook = xlsxwriter.Workbook(path)
                for row in result:
                    worksheet = workbook.add_worksheet(row["ExportName"])
                    r = 0
                    c = 0
                    self.lblExport['text'] = "                                                                                          "
                    self.lblExport.update_idletasks()
                    self.lblExport['text'] = "Exporting " + row["ExportName"] + "..."
                    self.lblExport.update_idletasks()
                    print("Exporting",row["ExportName"],"...")
                    result2 = self.connection.execute("SELECT * FROM " + row["ObjectName"])
                    colnames = result2.keys()
                    for i in colnames:
                        worksheet.write(r, c, i)
                        c += 1
                    r = 1
                    for row2 in result2:
                        c = 0
                        for i in colnames:
                            worksheet.write(r, c, row2[i])
                            c += 1
                        r += 1
                workbook.close()
                print("Finished Exporting.")
                messagebox.showinfo("Success", "Export complete.")
                self.lblExport['text'] = "Export:"
                self.lblExport.update_idletasks()
                self.clearall()

            except PermissionError:
                messagebox.showinfo("Error", "Could not access" + os.linesep + path + os.linesep +"File may be in use.")





def Export(RDpath, form = None):
    RDconstring = "sqlite:///" + RDpath
    dirpath = os.path.dirname(RDpath)
    dbname = os.path.basename(RDpath)
    
    engine = create_engine(RDconstring)
    connection = engine.connect()
    dbapi_connection = connection.connection
    dbapi_connection.create_aggregate("stdev", 1, stdevs)
    dbapi_connection.create_aggregate("meanw", 2, meanw)
    dbapi_connection.create_aggregate("stdevw", 2, stdevw)
    meta = MetaData()

    child = Tk()
    cf = ExportForm(form, child, RDpath, connection)
    child.mainloop()
    connection.close()
    return;



