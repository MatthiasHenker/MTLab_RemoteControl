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

ModuleName = 'VisaIF';  % name of class file
VersionID  = '2.4.3_2021-04-12_refresh'; % should match name of tag in git (version control)
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

% -------------------------------------------------------------------------
% pcode cannot handle '..' in path string
cd(SourceDir);
SourceDir = pwd;
cd(ThisDir);

% -------------------------------------------------------------------------
workSourceDir  = SourceDir;
workReleaseDir = ReleaseDir;
mkdir(workReleaseDir);
cd(workReleaseDir);

% create additional .m file with help (documentation)
mhelp   = help(fullfile(workSourceDir, 'VisaIFLogEventData.m'));
fid     = fopen(fullfile(workReleaseDir, 'VisaIFLogEventData.m'), 'w');
fwrite(fid,['%' strrep(mhelp, newline, sprintf('\n%%'))]);
fclose(fid);

% create additional .m file with help (documentation)
mhelp   = help(fullfile(workSourceDir, 'VisaIFLogger.m'));
fid     = fopen(fullfile(workReleaseDir, 'VisaIFLogger.m'), 'w');
fwrite(fid,['%' strrep(mhelp, newline, sprintf('\n%%'))]);
fclose(fid);

% create p-files out of original m-files
pcode(fullfile(workSourceDir, 'VisaDemo.m'));
pcode(fullfile(workSourceDir, 'VisaIFLogEventData.m'));
pcode(fullfile(workSourceDir, 'VisaIFLogger.m'));

% -------------------------------------------------------------------------
workSourceDir  = fullfile(SourceDir,  ClassDirName);
workReleaseDir = fullfile(ReleaseDir, ClassDirName);
mkdir(workReleaseDir);
cd(workReleaseDir);

% create additional .m file with help (documentation)
mhelp   = help(fullfile(workSourceDir, 'VisaIF.m'));
fid     = fopen(fullfile(workReleaseDir, 'VisaIF.m'), 'w');
fwrite(fid,['%' strrep(mhelp, newline, sprintf('\n%%'))]);
fclose(fid);

copyfile( ...
    fullfile(workSourceDir,  'VisaIF_HTW_Labs.csv'), ...
    fullfile(workReleaseDir, 'VisaIF_HTW_Labs.csv'));
copyfile( ...
    fullfile(workSourceDir,  'VisaIF_HTW_Henker.csv'), ...
    fullfile(workReleaseDir, 'VisaIF_HTW_Henker.csv'));

% create p-files out of original m-files
pcode(fullfile(workSourceDir, 'VisaIF.m'));
pcode(fullfile(workSourceDir, 'listAvailableConfigFiles.m'));
pcode(fullfile(workSourceDir, 'listContentOfConfigFiles.m'));
pcode(fullfile(workSourceDir, 'listAvailableVisaUsbDevices.m'));
pcode(fullfile(workSourceDir, 'listSupportedPackages.m'));
pcode(fullfile(workSourceDir, 'coerceConfigTable.m'));
pcode(fullfile(workSourceDir, 'filterConfigFiles.m'));

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