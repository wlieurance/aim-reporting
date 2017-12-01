# AIM Reporting Database Install/Use/HowTo
## INTRODUCTION
The purpose of this project is to give users storing Assessment Inventory and Monitoring (AIM) data within the Database for Inventory, Monitoring and Assessment (DIMA) a quick and portable way to aggregate and process raw data for a variety of available methods. This project also provides a number of quality control checks that can be used to find errors in the collected data. Data are imported from DIMA (MS Access) into a SQLite/SpatiaLite database for processing.

## INSTALL
_NOTE: This program can be run (theoretically) in Windows, Mac or Linux. However, **THERE IS CURRENTLY NO WAY TO IMPORT DATA FROM DIMA INTO THE RD ON ANY SYSTEM OTHER THAN MS WINDOWS!!!**_ So make sure to import the data while the DIMA is still on a windows machine.  Support for the Mac and Linux is in development, but it is very difficult (almost impossible) to work with the proprietary MS Access container outside of a Windows environment. 

Almost all of the required python modules can be installed via the 'requirements.txt' file and the 'pip' command (e.g. pip install -r "/path/to/requirements.txt"). Users unfamiliar with the pip command should read the documentation on their specific version of python for how to use it, as the command may need to be altered depending on the nature of the user's system (i.e. 'pip' vs. 'pip3' vs. 'pip3.x' vs 'py -3 -m pip', etc.).

Also required is the 'tkinter' library, which on a Windows environment should come with a standard python3 install.  Linux/Unix users may have to install the tkinter library on their system (e.g. sudo apt-get install python3-tk). MacOS 10.x users will also likely need to download and install the library separately (see [IDLE and tkinter with Tcl/Tk on macOS](https://www.python.org/download/mac/tcltk/) for more info).

Lastly, the database requires the use of the most recent stable version of the SpatiaLite library (4.3+). The database uses extension loading from the SQLite engine. 
* For Linux users for the Debian/Ubuntu/Mint variety, a package may already exists for install (e.g. sudo apt-get install libsqlite3-mod-SpatiaLite). 
* For Windows users, so as long as the SpatiaLite module files (this includes the 'mod_SpatiaLite' library as well as other associated libraries) are somewhere in the system's PATH variable, the database will find it automatically. See [libspatialite](https://www.gaia-gis.it/fossil/libspatialite/index) for more information on how to get and compile the SpatiaLite loadable extension. 
* Windows users who would prefer not to compile their own SpatiaLite library from source can also download pre-compiled binaries at [Gaia-SINS](http://www.gaia-gis.it/gaia-sins/). If a user chooses to use the pre-compiled binaries, they must put the files located in the 'mod' folder somewhere already in the system's PATH (e.g. C:\Windows\System32) or modify the system's (or user's) PATH variable to contain its location (e.g. C:\Users\someuser\somedirs\SpatiaLite\mod)

### CONSIDERATIONS FOR USERS WITHOUT SUPERUSER PRIVILEGES OR BEHIND FIREWALLS
* Python relies on a package system where users may be downloading multiple packages specific to their use. If the user does not have root/administrator access, the best practice is probably to install python in their home/User directory.  This is the default install location for at least the Windows Python install. If a user has their sysadmin install Python to a system directory, it is important to also have them install all the required packages and libraries also at that time.
* For those users behind a firewall who are not finding packages (with pip) due to SSL/TLS certificate errors, you can alter you pip command in the following way: *pip install --index-url=http://pypi.python.org/simple/ --trusted-host pypi.python.org pythonPackageToInstall*
* It is also possible to install the SpatiaLite libraries in your home or User directory.  The basic process would be to: 
  1. Place the libraries in an appropriate location (e.g. C:\Users\someuser\somedirs\SpatiaLite\mod)
  2. From the start menu go to _Search for Programs and Files_ and type _Edit environment variables for your account_, then choose the resulting option.
  3. Click on the PATH Variable in the Environment Variables dialog box and hit the _Edit..._ button.
  4. Go to the end of the Variable value text in the _Edit User Variable_ and append a semicolon followed by the directory of the path where the SpatiaLite libraries are located (e.g. Long\String\of\Other\Directories;C:\Users\someuser\somedirs\SpatiaLite\mod).
  5. Hit _OK_ and _OK_ again.  Now your system knows where to find the SpatiaLite libraries (restart may be required).


## USE
Users need to have python 3.x installed and from their command line environment run the main.py file (e.g. python3 "/path/to/main.py" or py -3 "/path/to/main.py"). If the memory architecture of your python install differs from that of your MS Office (i.e. Access) install you will likely need to install an ODBC driver that matches your python architecture. A search of 'Microsoft Access Database Engine 2010 Redistributable' should provide the relevant Microsoft download page.

Simple usage would be the following:
1. Create a new blank database with the 'Create New Database' button.  This will create a new blank reporting database.  Users can customize the SQL scripts in the /sql/ folder to alter the database as needed for a specific project.  Users can also use the 'Run SQL Script' Button to run custom SQL in the database after creation in order to customize.
2. Use the 'Import DIMA Data' button to import one or more DIMA data sets into the database. Users will be asked if they prefer to delete existing data or not.  In the case of records with identical primary keys, existing data are given precedence.
3. Run any custom sql scripts desired with the *Run SQL Script* button.
4. Hit the *Recalculate* button in order to process intermediate calculations and store them in tables (needed due to complicated queries and MemoryError issues with large datasets).
5. Users can then click the 'Export' button in order to export final products or QC checks into a Microsoft Excel format.
6. If users want to switch back and forth between different reporting databases they can use the 'Connect to Database' button to change the database they are connected to, which is listed at the top of the form.

A couple more things to note: 
* Users customizing the SQL scripts must maintain the same script names within the /sql/ path.  It is recommended at this time for multiple projects needing different setup scripts, that users create different paths for the script sets (e.g. /sql_project1, /sql_project2, etc.). 
* The database will ask you for a sql path a time of creation if it cannot find the default path. An alternative to this method would be to write a customization script for each project and run it/them via the 'Run SQL script' button. As SQLite does not use the ALTER VIEW statement, users will have to use the DROP VIEW and CREATE VIEW statements.

### OPTIONAL USE
Some spatial QC checks depend on knowing what the magnetic declinations were at the time and place where the plot/lines were established. In order to calculate this information, the database uses the python 'geomag' module and the NOAA/NGA World Magnetic Model to calculate these declinations. 

During data imports the user may be asked if they want to calculate declinations, and if so need to provide the 'WMM.COF' file (World Magnetic Model coefficient file).  Users can find (at the time of writing) the WMM.COF file at [NOAA.gov](https://www.ngdc.noaa.gov/geomag/WMM/DoDWMM.shtml).

## CONFIGURATION
Currently the way the database behaves can be modified through altering certain data inserted into the database via the insert_config.sql script. 

**CAUTION: changing these values without knowing how it will affect the database may result in a broken database, or in one that produces incorrect or unexpected values.  See documentation within the SQL scripts to better understand DB function.**

Turning on and off the export of certain QAQC scripts during the export process can be done via the 'use_check' field of the QAQC_Queries table.  A zero (False) in this field will tell the database not to use/export that particular query while a 1 (True) will do the opposite. For this process, an UPDATE statement post DB creation will work via a script to control which QC checks are utilized.

### ADDING NON-DIMA DATA
Currently there are a number of tables in the database that may need to be populated manually if they want to be used.  
1. EcositeGroups: serves as a way to group plots of the same ecosite together into bigger groups for processing.
2. PlotTags: serves as a way to group plots together for processing.  Some are populated automatically via the insert_tags.sql script, but users may want to create manual groupings themselves.
3. SoilSeries: serves as a way to check if valid soil series are listed in plot data during QAQC checks.
4. SpeciesTags: serves as a way to group plant species together for processing.  Some are populated automatically via the insert_tags.sql script, but users may want to create manual groupings themselves.
5. Data_DateRange: serves to define valid data ranges and to demarcate separate data collection seasons.  This will be populated automatically with some default values on DB creation, but users may want to create a different setup for non-standard seasonality.  *NOTE: Currently data date ranges must be inserted into sql scripts before the database is created.  A good place to do this would be at the end of the insert_config.sql script.*
6. Examples of adding data via a sql script can be found in the /sql folder in the 'example_data.sql' file.

## KNOWN ISSUES
* Occasional MemoryError exceptions may be raised in python due to the large amount of data and the complexity of the views. Python 64 bit is recommended for this reason.  If this continues to be an issue, methods will have to be developed to mitigate the issue.

### COMMON INSTALL ISSUES
* Linux users may need to install the additional packages if the install of pyodbc fails. Check the [pyodbc wiki](https://github.com/mkleehammer/pyodbc/wiki/Install) for more information.
* If the following error occurs: "AttributeError: 'sqlite3.Connection' object has no attribute 'enable_load_extension'" then most likely your python installation needs to be built from source again with the '--enable-loadable-sqlite-extensions' flag.
* Ubuntu/Mint/Debian users should be able to install the 'libsqlite3-mod-SpatiaLite' package for the SpatiaLite extension.  Those looking to build SpatiaLite from source might try the following packages for the prerequisites listed in the SpatiaLite README file: libsqlite3-dev, libproj-dev, libgeos-dev, and libfreexl-dev.
Building prerequisites from source is always an option.