% release matlab class files (p-files (for code) and m-files (for doc))
%
% I do not want to release code as (plain text) m-files to avoid unwanted 
% changes by colleagues or students
%
% Thus, this script creates p- and m-files
% ==> create (content-obscured) p-files out of original m-files
% ==> create additional m-files for the help/doc (p-files contain no help)
% 
% ATTENTION: to avoid overwriting the original m-files all files will be
%            written to a separate release directory
%
% Assumptions and Actions:
%   - code is located in directory ./Modules/xxx/*
%   - this file is located at      ./Releases/xxx_ReleaseCode.m
%
% Howto release code:
%   - run this script (in this directory!!!)
%   - use content of created release directory for public

% -------------------------------------------------------------------------
% some config

ModuleName = 'Scope'; % name of class file
VersionID  = '1.2.1'; % should match name of tag in git (version control)
%VersionID  = 'x.y.z';

% copy released files also to Support directory? 
copyFilesToSupportDir = 1;   % true (1) or false (0)

% -------------------------------------------------------------------------
% actual code to create a new release
% -------------------------------------------------------------------------
% save path to current directory
ThisDir    = pwd;
% path to source and release directories
SourceDir  = fullfile(ThisDir, '..', 'Modules', ModuleName);
ReleaseDir = fullfile(ThisDir, [ModuleName '_v' VersionID '_release']);

% names of class and package directories 
ClassDirName   = ['@' ModuleName];
PackageDirName = ['+' ModuleName];

% -------------------------------------------------------------------------
% pcode cannot handle '..' in path string
cd(SourceDir);
SourceDir = pwd;
cd(ThisDir);

% -------------------------------------------------------------------------
workSourceDir  = fullfile(SourceDir,  ClassDirName);
workReleaseDir = fullfile(ReleaseDir, ClassDirName);
mkdir(workReleaseDir);
cd(workReleaseDir);

% create additional .m file with help (documentation)
mhelp   = help(fullfile(workSourceDir, 'Scope.m'));
fid     = fopen(fullfile(workReleaseDir, 'Scope.m'), 'w');
fwrite(fid,['%' strrep(mhelp, newline, sprintf('\n%%'))]);
fclose(fid);

% create p-files out of original m-files
pcode(fullfile(workSourceDir, 'Scope.m'));
pcode(fullfile(workSourceDir, 'checkParams.m'));
pcode(fullfile(workSourceDir, 'listAvailablePackages.m'));

% -------------------------------------------------------------------------
workSourceDir  = fullfile(SourceDir,  PackageDirName, '+Keysight', '+DSOX1000');
workReleaseDir = fullfile(ReleaseDir, PackageDirName, '+Keysight', '+DSOX1000');
mkdir(workReleaseDir);
cd(workReleaseDir);

% create p-files out of original m-files
pcode(fullfile(workSourceDir, 'ScopeMacros.m'));

% -------------------------------------------------------------------------
workSourceDir  = fullfile(SourceDir,  PackageDirName, '+Tektronix', '+TDS1000_2000');
workReleaseDir = fullfile(ReleaseDir, PackageDirName, '+Tektronix', '+TDS1000_2000');
mkdir(workReleaseDir);
cd(workReleaseDir);

% create p-files out of original m-files
pcode(fullfile(workSourceDir, 'ScopeMacros.m'));

% -------------------------------------------------------------------------
workSourceDir  = fullfile(SourceDir,  PackageDirName, '+RS', '+RTB2000');
workReleaseDir = fullfile(ReleaseDir, PackageDirName, '+RS', '+RTB2000');
mkdir(workReleaseDir);
cd(workReleaseDir);

% create p-files out of original m-files
pcode(fullfile(workSourceDir, 'ScopeMacros.m'));

% -------------------------------------------------------------------------
% return to original path
cd(ThisDir);

% -------------------------------------------------------------------------
% finally optionally copy released files to Support directory 
% (dir which is added to Matlab search path using 'pathtool')
if copyFilesToSupportDir
    SupportDir  = fullfile(ThisDir, '..', 'Support');
    copyfile(ReleaseDir, SupportDir);
end

return % end of script