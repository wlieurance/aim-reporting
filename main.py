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
from update import Update, run_sqlscript
from export_data import ExportForm, Export
from classes import stdevs, meanw, stdevw

###begin class definition###
class MainForm:
    def __init__(self, master):
        frame = tkinter.Frame(master)
        frame.grid()
        master.title("AIM Reporting Database v2.0a")
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
        try:
            if os.path.isfile(path):
                os.remove(path)
        except PermissionError:
            tkinter.messagebox.showerror("Error", "Chosen file is in use by another process or user does not have permission to overwrite file.")
            path = None
        if path:
            if os.path.basename(path).find('.') == -1:
                path = '.'.join((path, 'sqlite'))
            if not os.path.isdir(var['SQLpath']):
                tkinter.messagebox.showwarning('SQL path not found.','Default SQL script directory (/path/to/main.py/sql) not found. Please choose custom SQL script directory.')
                sqldir = tkinter.filedialog.askdirectory(title = "Choose custom SQL directory to use.")
                if not sqldir:
                    tkinter.messagebox.showerror("Error", "Need a valid SQL script directory to continue.")
                    msg = 'Database creation aborted.'
                    self.lblAction['text'] = msg
                    self.lblAction.update_idletasks()
                    print(msg)
                    return
            else:
                sqldir = var['SQLpath']

            print("Creating database...")
            self.lblAction['text'] = 'Creating database...'
            self.lblAction.update_idletasks()

            conn = sqlite.connect(path)
            conn.enable_load_extension(True)
            c = conn.cursor()
            c.execute("SELECT load_extension('mod_spatialite')")
            ###checks if db has been initialized to spatialite and intitializes if not.
            c.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='geometry_columns';")
            data = c.fetchone()
            if data is None:
                self.lblAction['text'] = 'Initializing spatialite...'
                self.lblAction.update_idletasks()
                print('Initializing spatialite...')
                
                c.execute("SELECT InitSpatialMetaData(1)")
            
            #the following blocks open sql statements from the 'sql' directory and execute them in the newly created file
            script_list = [[os.path.join(sqldir, 'create_tables.sql'), 'Creating tables...'],
                           [os.path.join(sqldir, 'insert_config.sql'), 'Inserting configuration data...'],
                           [os.path.join(sqldir, 'create_views.sql'), 'Creating views...'],
                           [os.path.join(sqldir, 'create_qaqc.sql'), 'Creating QAQC views and inserting QAQC config data...']]
            success = True
            finished = False
            while success and not finished:
                for scr in script_list:
                    success, errors = run_sqlscript(conn, script_path = scr[0], form = self, msg = scr[1])
                    if not success:
                        break
                finished = True
                    
            
            if success:
                msg = 'Database created successfully.'
                self.lblAction['text'] = msg
                self.lblAction.update_idletasks()
                print(msg)
                var['RDpath'] = os.path.abspath(path)
                self.lblRDpath['text'] = "Current database: " + var['RDpath']
                with open('vardict.json', 'w') as out_file:
                    json.dump(var, out_file)
            else:
                msg = 'Error in creating database.'
                self.lblAction['text'] = msg
                self.lblAction.update_idletasks()
                print(msg)
                print(errors)

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

                    conn = sqlite.connect(var['RDpath'])
                    c = conn.cursor()
                    rows = c.execute("SELECT Value FROM Data_DBconfig WHERE VariableName = 'empty';")
                    r = rows.fetchone()
                    if r[0] == '0':
                        delrecords = tkinter.messagebox.askyesno("Delete?", "Would you like to delete current data before import?")
                    else:
                        delrecords = False
                    log = ImportFromAccess(var['DIMApath'], var['RDpath'], delrecords, self)
                    var1 = Update(var, self)
                    root.config(cursor="")
                    self.lblAction['text'] = ""
                    self.lblProgress['text'] = ""
                    self.pBar2.grid_remove()
                    self.pBar.grid_remove()
                    var['WMMpath'] = var1['WMMpath']
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
        if RDpath != None:
            if os.path.isfile(RDpath):
                conn = sqlite.connect(var['RDpath'])
                run_sqlscript(conn, None)
                tkinter.messagebox.showinfo("Done.", "SQL script run.")
                conn.close()
            else:
                tkinter.messagebox.showerror("Error", "Current database path does not exist. Please connect to valid database.")
        else:
            tkinter.messagebox.showerror("Error", "Database path not chosen. Please connect to valid database or create a new one first.")
            
###end class definition###

###begin main execution block###            
scriptdir = os.path.dirname(os.path.realpath(__file__))
if not os.path.isfile('vardict.json'):
    var = {'RDpath':None, 'DIMApath':None, 'SQLpath':os.path.join(scriptdir, 'sql'), 'WMMpath':None}
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
###end main execution block###   





