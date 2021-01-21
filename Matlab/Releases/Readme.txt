# Matthias Henker
# 
# notes to release code

- save all code with git (git add FILES, git commit -m "MESSAGE")
- create release with MAtlab script 
- create a tag (git tag -a XXX_vx.y.z -m "Release of XXX version x.y.z")
- sync with remote repo (git push origin --tags)


# ----------------------------------------------------------------------------
# current versions
# 2021-01-21

# ----------------------------------------------------------------------------
VisaIF       : VisaIF             class    v2.4.3   (2021-01-09)
  - addons   : VisaDemo           class    v1.0.2   (2021-01-09)
               VisaIFLogger       class    v2.0.1   (2021-01-09)
               VisaIFLogEventData class    v2.0.1   (2021-01-09)
  - configs  : VisaIF_HTW_Labs.csv                  (2021-01-13)
               VisaIF_HTW_Henker.csv                (2021-01-13)

# ----------------------------------------------------------------------------
Scope        : Scope              class    v1.0.3   (2021-01-09)
  - packages : Tektronix.TDS1000_2000      v1.1.3   (2021-01-09)
               Keysight.DSOX1000           v1.1.1   (2021-01-09)
               RS.RTB2000                  v0.1.1   (2021-01-09)

# ----------------------------------------------------------------------------
FGen         : FGen               class    v1.0.5   (2021-01-09)
  - packages : Agilent.Gen33220A           v1.0.3   (2021-01-16)
               Keysight.Gen33511B          v1.0.1   (2021-01-21)
               Siglent.SDG6000X            v0.0.2   (2021-01-09)
  
# ----------------------------------------------------------------------------
not in git yet

HandheldDMM & DemoHandheldDMM   => Rework planned: merge into one class file
  - Version  : 1.1.2
  - Date     : 2019-10-01
