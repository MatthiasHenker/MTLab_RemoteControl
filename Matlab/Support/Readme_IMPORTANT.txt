# ----------------------------------------------------------------------------
# 2025-07-10
# Prof. Matthias Henker (HTW Dresden, Germany)
# ----------------------------------------------------------------------------

The files in this directory provide methods managed 
in classes to control measurement devices in the lab.

Most of these files are saved in binary format (p-files).

ATTENTION: You will have to extend the Matlab path to 
the top folder holding these files to use these classes.

ACTIONS:
  - save the files in a dir (e.g. with name 'Support')
  - type 'pathtool' in Matlab
  - add your folder 'Support' to your path (without subfolders!)
  - press save or close button and exit pathtool
  ==> Matlab will find these files now

# ----------------------------------------------------------------------------
VisaIF       : VisaIF             class    v3.0.2   (2025-07-09)
  - addons   : VisaDemo           class    v3.0.0   (2024-08-18)
               VisaIFLogger       class    v3.0.0   (2024-08-20)
               VisaIFLogEventData class    v2.0.1   (2021-01-09)
  - configs  : VisaIF_HTW_Labs.csv                  (2025-07-07)
               VisaIF_HTW_Henker.csv                (2024-08-20)

# ----------------------------------------------------------------------------
Scope        : Scope              class    v3.0.0   (2024-08-18)
  - packages : Tektronix.TDS1000_2000      v3.0.1   (2024-08-26)
               Keysight.DSOX1000           v3.0.1   (2024-08-28)
               RS.RTB2000                  v3.0.0   (2024-08-22)
               Rigol.DS2072A               v3.0.0   (2024-08-23)
               Siglent.SDS2000X            v3.0.0   (2024-08-22)
               Siglent.SDS1000X_E          v3.0.1   (2024-08-26)

# ----------------------------------------------------------------------------
FGen         : FGen               class    v3.0.0   (2024-08-22)
  - packages : Agilent.Gen33220A           v3.0.0   (2024-08-23)
               Keysight.Gen33511B          v3.0.0   (2024-08-23)
               Siglent.SDG6000X            v3.0.0   (2024-08-23)

# ----------------------------------------------------------------------------
!!! SMU class and packackes still in preparation !!!
SMU          : SMU                class    v0.9.0   (2025-07-10)
  - packages : Keithley.Model2450          v0.9.0   (2025-07-10)
 
# ----------------------------------------------------------------------------
HandheldDMM  : HandheldDMM        class    v2.1.0   (2022-08-10)
  - addons   : serialportDemo     class    v1.1.0   (2022-08-10)
  - packages : UT61E                       v1.1.0   (2022-08-10)
               UT161E                      v0.5.0   (2022-08-10)
               VC820                       v1.1.0   (2022-08-10)
               VC830                       v1.1.0   (2022-08-10)
               VC920                       v1.1.0   (2022-08-10)
# ----------------------------------------------------------------------------
