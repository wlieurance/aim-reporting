#!/usr/bin/env python3

import os
import json
import sqlite3 as sqlite
import re

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

        if var['RDpath'] == None:
            rdlbl = 'None selected.'
        else:
            rdlbl = var['RDpath']
        self.lblRDpath = ttk.Label(master, text="Current database: " + rdlbl)
        self.lblRDpath.grid(row=0, column=0, columnspan=3, sticky="W")

        self.btnChRD = ttk.Button(master, text='Connect to Database', style="TButton", command=self.choose_RD)
        self.btnChRD.grid(row=1, column=0)

        self.btnImport = ttk.Button(master, text='Import DIMA Data', style="TButton", command=self.choose_DIMA)
        self.btnImport.grid(row=1, column=1)

        self.btnOptions = ttk.Button(master, text='Run SQL Script', style="TButton", command=self.SQLscript)
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
            with open('vardict.json', 'w') as out_file:
                json.dump(var, out_file)
            msg = 'Database path updated.'
            self.lblAction['text'] = msg
            print(msg)

    def create_RD(self):
        path = tkinter.filedialog.asksaveasfilename(title = "Choose Reporting Database to use:", filetypes = (("sqlite files", "*.sqlite"),))
        if os.path.isfile(path):
            os.remove(path)
        if path:
            ans = tkinter.messagebox.askyesno('Custom SQL Path?','Would you like to choose a custom SQL path for database creation/configuration?')
            if ans:
                sqldir = tkinter.filedialog.askdirectory(title = "Choose custom SQL directory to use (default is ./sql/):")
            else:
                sqldir = var['SQLpath']
            print("Creating Database")
            conn = sqlite.connect(path)
            c = conn.cursor()

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
            with open('vardict.json', 'w') as out_file:
                json.dump(var, out_file)

    def choose_DIMA(self):
        if var['RDpath'] != None:
            if os.path.isfile(var['RDpath']):
                path = tkinter.filedialog.askopenfilename(title = "Choose DIMA to import data from:", filetypes = (("Access files", "*.mdb;*.accdb"),("All files", "*.*")))
                if path:
                    var['DIMApath'] = os.path.abspath(path)
                    root.config(cursor="wait")
                    root.update()
                    self.pBar.grid()
                    self.pBar2.grid()
                    self.lblProgress['text'] = "Total Progress:"
                    delrecords = tkinter.messagebox.askyesno("Delete?", "Would you like to delete current data before import?")
                    log = ImportFromAccess(var['DIMApath'], var['RDpath'], delrecords, self)
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
                    with open('vardict.json', 'w') as out_file:
                        json.dump(var, out_file)
            else:
                tkinter.messagebox.showerror("Error", "Current database path does not exist. Please connect to valid database.")
        else:
            tkinter.messagebox.showerror("Error", "Database path not chosen. Please connect to valid database or create a new one first.")

    def Export_RD(self):
        if var['RDpath'] != None:
            if os.path.isfile(var['RDpath']):
                Export(var['RDpath'], self)
            else:
                tkinter.messagebox.showerror("Error", "Current database path does not exist. Please connect to valid database.")
        else:
            tkinter.messagebox.showerror("Error", "Database path not chosen. Please connect to valid database or create a new one first.")

    def SQLscript(self):
        if var['RDpath'] != None:
            if os.path.isfile(var['RDpath']):
                script_path = tkinter.filedialog.askopenfilename(title = "Choose SQL script to run on Database.", filetypes = (("SQL files", "*.sql"),("All files", "*.*")))
                conn = sqlite.connect(var['RDpath'])
                c = conn.cursor()
                with open(script_path) as f:
                        script = f.read()
                c.executescript(script)
                tkinter.messagebox.showinfo("Done.", "SQL script run.")
            else:
                tkinter.messagebox.showerror("Error", "Current database path does not exist. Please connect to valid database.")
        else:
            tkinter.messagebox.showerror("Error", "Database path not chosen. Please connect to valid database or create a new one first.")

scriptdir = os.path.dirname(os.path.realpath(__file__))
if not os.path.isfile('vardict.json'):
    var = {'RDpath':None, 'DIMApath':None, 'SQLpath':os.path.join(scriptdir, 'sql')}
    with open(os.path.join(scriptdir, 'vardict.json'), 'w') as out_file:
        json.dump(var, out_file)
else:
    with open('vardict.json', 'r') as in_file:
        var = json.load(in_file)
root = tkinter.Tk()
mf = MainForm(root)
root.mainloop()
with open('vardict.json', 'w') as out_file:
    json.dump(var, out_file)





