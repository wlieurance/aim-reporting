from tkinter import *
from tkinter import filedialog
from tkinter import messagebox
from tkinter.ttk import *
import json
from import_Access import ImportFromAccess
from update import Update
#from variables import ManageVariables
from export import ExportForm, Export
import os.path

class MainForm:
    def __init__(self, master):
        frame = Frame(master)
        frame.grid()
        master.title("Reporting Database v2.0")
        self.style = Style()
        self.style.configure("TButton", padding=6, relief="flat", background="#ccc", width=20)

        self.lblRDpath = Label(master, text="Current database: " + var['RDpath'])
        self.lblRDpath.grid(row=0, column=0, columnspan=3, sticky=W)
        
        self.btnChRD = Button(master, text='Change Database Path', style="TButton", command=self.choose_RD)
        self.btnChRD.grid(row=1, column=0)
        
        self.btnImport = Button(master, text='Import DIMA Data', style="TButton", command=self.choose_DIMA)
        self.btnImport.grid(row=1, column=1)

        self.btnOptions = Button(master, text='Manage Options', style="TButton", command=self.Options)
        self.btnOptions.grid(row=1, column=2)

        self.btnExport = Button(master, text='Export', style="TButton", command=self.Export_RD)
        self.btnExport.grid(row=2, column=0)        
        
        self.lblAction = Label(master, text="", width=47)
        self.lblAction.grid(row=3, column=0, columnspan=2, sticky=W)

        self.lblProgress = Label(master, text="", width=47)
        self.lblProgress.grid(row=4, column=0, columnspan=2, sticky=W)

        self.pBar = Progressbar(master, orient="horizontal", length=140, mode="determinate")
        self.pBar.grid(row=3, column=2)
        self.pBar.grid_remove()

        self.pBar2 = Progressbar(master, orient="horizontal", length=140, mode="determinate")
        self.pBar2.grid(row=4, column=2)
        self.pBar2.grid_remove()
        

    def choose_RD(self):
        path = filedialog.askopenfilename(title = "Choose Reporting Database to use:", filetypes = (("sqlite files", "*.sqlite;*.db"),("All files", "*.*")))
        if path:
            print("Changing path")
            var['RDpath'] = os.path.abspath(path)
            self.lblRDpath['text'] = "Current database: " + var['RDpath']
            with open('vardict.txt', 'w') as out_file:
                json.dump(var, out_file)

    def choose_DIMA(self):
        path = filedialog.askopenfilename(title = "Choose DIMA to import data from:", filetypes = (("Access files", "*.mdb;*.accdb"),("All files", "*.*")))
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
                messagebox.showinfo("Import complete.", "Data successfully transferred from DIMA.")
            else:
                messagebox.showinfo("Import incomplete.", log)
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
            messagebox.showinfo("Update complete.", "Data successfully updated.")
        else:
            messagebox.showinfo(log)

    def Export_RD(self):
        Export(var['RDpath'], self)

    def Options(self):
        ManageVariables(var['RDpath'], self)

    
with open('vardict.txt', 'r') as in_file:
    var = json.load(in_file)
root = Tk()
mf = MainForm(root)
root.mainloop()
with open('vardict.txt', 'w') as out_file:
    json.dump(var, out_file)
    




