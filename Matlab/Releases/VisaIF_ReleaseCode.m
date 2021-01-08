% release matlab class files (p-file and m-file)
%
% I do not want to release m-files: avoid unwanted changes by colleagues
% or students
% ==> create (content-obscured) p-files out of original m-files
% ==> create additional m-files for the help/doc: p-files contain no help
%
% this script creates p-files out of the original m-files and
% and additional m-files with the help text
% ATTENTION: to avoid overwriting the original m-file the help file will be
% written to a separate release directory
%
% howto release code:
%   - run this script (in its folder)
%   - keep content of source dir for yourself
%   - use content of release directory for public
%   - be careful not to overwrite your original code

% -------------------------------------------------------------------------
% some config

% release and source directory (must end with '/')
ReleaseDir = './archive_vx.x.x_release/';
SourceDir  = './archive_vx.x.x_src/';

% -------------------------------------------------------------------------
% actual code to create a new release
% -------------------------------------------------------------------------
% 1st step: save/copy all files to source directory

mkdir(SourceDir);
copyfile('./VisaIFLogEventData.m', SourceDir);
copyfile('./VisaIFLogger.m',       SourceDir);
copyfile('./VisaDemo.m',           SourceDir);
copyfile('./test_VisaIF.m',        SourceDir);
copyfile('./VisaIF_History.txt',   SourceDir);
copyfile('./VisaIF_ReleaseCode.m', SourceDir);

mkdir([SourceDir '@VisaIF/']);
copyfile('./@VisaIF/VisaIF.m',                     [SourceDir '@VisaIF/']);
copyfile('./@VisaIF/listAvailableConfigFiles.m'   ,[SourceDir '@VisaIF/']);
copyfile('./@VisaIF/listContentOfConfigFiles.m'   ,[SourceDir '@VisaIF/']);
copyfile('./@VisaIF/listAvailableVisaUsbDevices.m',[SourceDir '@VisaIF/']);
copyfile('./@VisaIF/filterConfigFiles.m'          ,[SourceDir '@VisaIF/']);
copyfile('./@VisaIF/coerceConfigTable.m'          ,[SourceDir '@VisaIF/']);
copyfile('./@VisaIF/listSupportedPackages.m'      ,[SourceDir '@VisaIF/']);
%
copyfile('./@VisaIF/VisaIF_S110.csv'              ,[SourceDir '@VisaIF/']);
copyfile('./@VisaIF/VisaIF_Sxxx.csv'              ,[SourceDir '@VisaIF/']);
copyfile('./@VisaIF/VisaIF_Z433.csv'              ,[SourceDir '@VisaIF/']);

% -------------------------------------------------------------------------
% 2nd step: create p-file and m-file (help) in release directory

mkdir(ReleaseDir);
mkdir([ReleaseDir '@VisaIF/']);

% create additional .m files with help (documentation)
mhelp = help('./@VisaIF/VisaIF.m');
fid = fopen([ReleaseDir '@VisaIF/VisaIF.m'], 'w');
fwrite(fid,['%' strrep(mhelp, newline, sprintf('\n%%'))]);
fclose(fid);
%
mhelp = help('./VisaIFLogEventData.m');
fid = fopen([ReleaseDir 'VisaIFLogEventData.m'], 'w');
fwrite(fid,['%' strrep(mhelp, newline, sprintf('\n%%'))]);
fclose(fid);
%
mhelp = help('./VisaIFLogger.m');
fid = fopen([ReleaseDir 'VisaIFLogger.m'], 'w');
fwrite(fid,['%' strrep(mhelp, newline, sprintf('\n%%'))]);
fclose(fid);


% create a pcode file out of original m-files
% m-file for internal use only
% p-file for students
mFileFolder = pwd;
cd(ReleaseDir);
pcode(fullfile(mFileFolder, 'VisaIFLogEventData.m'));
pcode(fullfile(mFileFolder, 'VisaIFLogger.m'));
pcode(fullfile(mFileFolder, 'VisaDemo.m'));

cd('./@VisaIF');
pcode(fullfile(mFileFolder, '@VisaIF', 'VisaIF.m'));
pcode(fullfile(mFileFolder, '@VisaIF', 'listAvailableConfigFiles.m'));
pcode(fullfile(mFileFolder, '@VisaIF', 'listContentOfConfigFiles.m'));
pcode(fullfile(mFileFolder, '@VisaIF', 'listAvailableVisaUsbDevices.m'));
pcode(fullfile(mFileFolder, '@VisaIF', 'filterConfigFiles.m'));
pcode(fullfile(mFileFolder, '@VisaIF', 'coerceConfigTable.m'));
pcode(fullfile(mFileFolder, '@VisaIF', 'listSupportedPackages.m'));

cd(mFileFolder);
copyfile('./@VisaIF/VisaIF_S110.csv',       [ReleaseDir '@VisaIF/']);
copyfile('./@VisaIF/VisaIF_Sxxx.csv',       [ReleaseDir '@VisaIF/']);
copyfile('./@VisaIF/VisaIF_Z433.csv',       [ReleaseDir '@VisaIF/']);

% -------------------------------------------------------------------------
