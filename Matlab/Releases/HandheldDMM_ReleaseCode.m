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

ModuleName = 'HandheldDMM';  % name of class file
%VersionID  = '2.1.0_2022-08-10'; % should match name of tag in git (version control)
VersionID  = 'x.y.z';

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
workSourceDir  = SourceDir;
workReleaseDir = ReleaseDir;
mkdir(workReleaseDir);
cd(workReleaseDir);

% create p-files out of original m-files
pcode(fullfile(workSourceDir, 'serialportDemo.m'));

% -------------------------------------------------------------------------
workSourceDir  = fullfile(SourceDir,  ClassDirName);
workReleaseDir = fullfile(ReleaseDir, ClassDirName);
mkdir(workReleaseDir);
cd(workReleaseDir);

% create additional .m file with help (documentation)
mhelp   = help(fullfile(workSourceDir, 'HandheldDMM.m'));
fid     = fopen(fullfile(workReleaseDir, 'HandheldDMM.m'), 'w');
fwrite(fid,['%' strrep(mhelp, newline, sprintf('\n%%'))]);
fclose(fid);

% create p-files out of original m-files
pcode(fullfile(workSourceDir, 'HandheldDMM.m'));
pcode(fullfile(workSourceDir, 'listSerialPorts.m'));
pcode(fullfile(workSourceDir, 'listSupportedPackages.m'));

% -------------------------------------------------------------------------
workSourceDir  = fullfile(SourceDir,  PackageDirName, '+UT61E');
workReleaseDir = fullfile(ReleaseDir, PackageDirName, '+UT61E');
mkdir(workReleaseDir);
cd(workReleaseDir);

% create p-files out of original m-files
pcode(fullfile(workSourceDir, 'HandheldDMMMacros.m'));

% -------------------------------------------------------------------------
workSourceDir  = fullfile(SourceDir,  PackageDirName, '+UT161E');
workReleaseDir = fullfile(ReleaseDir, PackageDirName, '+UT161E');
mkdir(workReleaseDir);
cd(workReleaseDir);

% create p-files out of original m-files
pcode(fullfile(workSourceDir, 'HandheldDMMMacros.m'));

% -------------------------------------------------------------------------
workSourceDir  = fullfile(SourceDir,  PackageDirName, '+VC820');
workReleaseDir = fullfile(ReleaseDir, PackageDirName, '+VC820');
mkdir(workReleaseDir);
cd(workReleaseDir);

% create p-files out of original m-files
pcode(fullfile(workSourceDir, 'HandheldDMMMacros.m'));

% -------------------------------------------------------------------------
workSourceDir  = fullfile(SourceDir,  PackageDirName, '+VC830');
workReleaseDir = fullfile(ReleaseDir, PackageDirName, '+VC830');
mkdir(workReleaseDir);
cd(workReleaseDir);

% create p-files out of original m-files
pcode(fullfile(workSourceDir, 'HandheldDMMMacros.m'));

% -------------------------------------------------------------------------
workSourceDir  = fullfile(SourceDir,  PackageDirName, '+VC920');
workReleaseDir = fullfile(ReleaseDir, PackageDirName, '+VC920');
mkdir(workReleaseDir);
cd(workReleaseDir);

% create p-files out of original m-files
pcode(fullfile(workSourceDir, 'HandheldDMMMacros.m'));

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
