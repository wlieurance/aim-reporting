import os
import json
import xlsxwriter
import sqlite3 as sqlite

import tkinter
#separate imports needed due to tkinter idiosyncrasies
from tkinter import ttk
from tkinter import filedialog, messagebox

from import_data import ImportFromAccess
from update import Update
from export_data import ExportForm, Export
from classes import stdevs, meanw, stdevw


class MainForm:
    def __init__(self, master):
        frame = tkinter.Frame(master)
        frame.grid()
        master.title("Reporting Database v2.0")
        self.style = ttk.Style()
        self.style.configure("TButton", padding=6, relief="flat", background="#ccc", width=20)

        self.lblRDpath = ttk.Label(master, text="Current database: " + var['RDpath'])
        self.lblRDpath.grid(row=0, column=0, columnspan=3, sticky="W")
        
        self.btnChRD = ttk.Button(master, text='Connect to Database', style="TButton", command=self.choose_RD)
        self.btnChRD.grid(row=1, column=0)
        
        self.btnImport = ttk.Button(master, text='Import DIMA Data', style="TButton", command=self.choose_DIMA)
        self.btnImport.grid(row=1, column=1)

        self.btnOptions = ttk.Button(master, text='Manage Options', style="TButton", command=self.Options)
        self.btnOptions.grid(row=1, column=2)

        self.btnChRD = ttk.Button(master, text='Create New Database', style="TButton", command=self.create_RD)
        self.btnChRD.grid(row=2, column=0)
        
        self.btnExport = ttk.Button(master, text='Export', style="TButton", command=self.Export_RD)
        self.btnExport.grid(row=2, column=1)        
        
        self.lblAction = ttk.Label(master, text="", width=47)
        self.lblAction.grid(row=3, column=0, columnspan=2, sticky="W")

        self.lblProgress = ttk.Label(master, text="", width=47)
        self.lblProgress.grid(row=4, column=0, columnspan=2, sticky="W")

        self.pBar = ttk.Progressbar(master, orient="horizontal", length=140, mode="determinate")
        self.pBar.grid(row=3, column=2)
        self.pBar.grid_remove()

        self.pBar2 = ttk.Progressbar(master, orient="horizontal", length=140, mode="determinate")
        self.pBar2.grid(row=4, column=2)
        self.pBar2.grid_remove()
        

    def choose_RD(self):
        path = tkinter.filedialog.askopenfilename(title = "Choose Reporting Database to use:", filetypes = (("sqlite files", "*.sqlite;*.db"),("All files", "*.*")))
        if path:
            print("Changing path")
            var['RDpath'] = os.path.abspath(path)
            self.lblRDpath['text'] = "Current database: " + var['RDpath']
            with open('vardict.txt', 'w') as out_file:
                json.dump(var, out_file)

    def create_RD(self):
        path = tkinter.filedialog.asksaveasfilename(title = "Choose Reporting Database to use:", filetypes = (("sqlite files", "*.sqlite"),))
        if os.path.isfile(path):
            os.remove(path)
        if path:
            print("Creating Database")
            conn = sqlite.connect(path)
            c = conn.cursor()
            sqldir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "sql")
            
            #the following blocks open sql statements from the 'sql' directory and execute them in the newly created file
            with open(os.path.join(sqldir, 'create_tables.sql')) as f:
                create_tables = f.read()
            msg = 'Creating tables...'
            self.lblAction['text'] = msg
            print(msg)
            c.executescript(create_tables)

            with open(os.path.join(sqldir, 'insert_config.sql')) as f:
                insert_config = f.read()
            msg =  'Inserting configuration data...'
            self.lblAction['text'] = msg
            print(msg)
            c.executescript(insert_config)

            with open(os.path.join(sqldir, 'create_views.sql')) as f:
                create_views = f.read()
            msg = 'Creating views...'
            self.lblAction['text'] = msg
            print(msg)
            c.executescript(create_views)

            with open(os.path.join(sqldir, 'create_qaqc.sql')) as f:
                create_qaqc = f.read()
            msg = 'Creating QAQC views and inserting QAQC config data...'
            self.lblAction['text'] = msg
            print(msg) 
            c.executescript(create_qaqc)
            
            msg = 'Database created successfully.'
            self.lblAction['text'] = msg
            print(msg) 
            
            var['RDpath'] = os.path.abspath(path)
            self.lblRDpath['text'] = "Current database: " + var['RDpath']
            with open('vardict.txt', 'w') as out_file:
                json.dump(var, out_file)

    def choose_DIMA(self):
        path = tkinter.filedialog.askopenfilename(title = "Choose DIMA to import data from:", filetypes = (("Access files", "*.mdb;*.accdb"),("All files", "*.*")))
        if path:
            var['DIMApath'] = os.path.abspath(path)
            root.config(cursor="wait")
            root.update()
            self.pBar.grid()
            self.pBar2.grid()
            self.lblProgress['text'] = "Total Progress:"
            log = ImportFromAccess(var['DIMApath'], var['RDpath'], self)
            Update(var['RDpath'], self)
            root.config(cursor="")
            self.lblAction['text'] = ""
            self.lblProgress['text'] = ""
            self.pBar2.grid_remove()
            self.pBar.grid_remove()
            if not log:
                tkinter.messagebox.showinfo("Import complete.", "Data successfully transferred from DIMA.")
            else:
                tkinter.messagebox.showinfo("Import incomplete.", log)
            with open('vardict.txt', 'w') as out_file:
                json.dump(var, out_file)

    def update_RD(self):
        root.config(cursor="wait")
        root.update()
        self.pBar.grid()
        #self.pBar2.grid()
        #self.lblProgress['text'] = "Total Progress:"
        log = Update(var['RDpath'], self)
        root.config(cursor="")
        self.lblAction['text'] = ""
        #self.lblProgress['text'] = ""
        #self.pBar2.grid_remove()
        self.pBar.grid_remove()
        if not log:
            tkinter.messagebox.showinfo("Update complete.", "Data successfully updated.")
        else:
            tkinter.messagebox.showinfo(log)

    def Export_RD(self):
        Export(var['RDpath'], self)

    def Options(self):
        ManageVariables(var['RDpath'], self)

    
with open('vardict.txt', 'r') as in_file:
    var = json.load(in_file)
root = tkinter.Tk()
mf = MainForm(root)
root.mainloop()
with open('vardict.txt', 'w') as out_file:
    json.dump(var, out_file)
    




