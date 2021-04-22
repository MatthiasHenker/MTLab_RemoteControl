# ----------------------------------------------------------------------------
# 2021-04-22
# Prof. Matthias Henker (HTW Dresden, Germany)
# ----------------------------------------------------------------------------

The files in this directory provide methods managed 
in classes to control measurement devices in the lab.

Most of these files are saved in binary format (p-files).

ATTENTION: You will have to extend the Matlab path to 
the top folder holding these files to use these classes.

ACTIONS:
  - save the files in a dir (e.g. with name 'Support_Files')
  - type 'pathtool' in Matlab
  - add your folder 'Support_Files' (without subfolders!)
  - press save or close button and exit pathtool
  ==> Matlab will find these files now

# ----------------------------------------------------------------------------
VisaIF       : VisaIF             class    v2.4.3   (2021-02-15)
  - addons   : VisaDemo           class    v1.0.2   (2021-01-09)
               VisaIFLogger       class    v2.0.2   (2021-02-15)
               VisaIFLogEventData class    v2.0.1   (2021-01-09)
  - configs  : VisaIF_HTW_Labs.csv                  (2021-03-26)
               VisaIF_HTW_Henker.csv                (2021-03-09)

# ----------------------------------------------------------------------------
Scope        : Scope              class    v1.2.1   (2021-04-12)
  - packages : Tektronix.TDS1000_2000      v1.2.1   (2021-04-12)
               Keysight.DSOX1000           v1.2.1   (2021-04-12)
               RS.RTB2000                  v1.2.1   (2021-04-12)
               Rigol.DS2072A               v1.2.1   (2021-04-12)
               Siglent.SDS2000X            v1.2.1   (2021-04-22)

# ----------------------------------------------------------------------------
FGen         : FGen               class    v1.0.7   (2021-03-16)
  - packages : Agilent.Gen33220A           v1.0.5   (2021-03-10)
               Keysight.Gen33511B          v1.0.3   (2021-03-11)
               Siglent.SDG6000X            v1.0.0   (2021-03-16)
  
# ----------------------------------------------------------------------------
