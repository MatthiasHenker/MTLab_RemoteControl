# ----------------------------------------------------------------------------
# Prof. Matthias Henker  (HTW Dresden, Germany)
# 
# notes howto release code

- save all code with git (git add FILES, git commit -m "MESSAGE")
- create release with Matlab script 
- create a tag (git tag -a XXX_vx.y.z -m "Release of XXX version x.y.z")
- sync with remote repo (git push origin --tags)

- Rename a git tag old to new:
    git tag new old
    git tag -d old
    git push origin :refs/tags/old        (remove tags)
    git push --tags


# ----------------------------------------------------------------------------
# for current versions see Matlab/Support/Readme_IMPORTANT.txt
  
# ----------------------------------------------------------------------------
not in git yet

HandheldDMM & DemoHandheldDMM   => Rework planned: merge into one class file
  - Version  : 1.1.2
  - Date     : 2019-10-01

# ----------------------------------------------------------------------------
