% release matlab class files (p-file and m-file)
%
% I do not want to release m-file: avoid unwanted changes by colleagues
% or students
% ==> create (content-obscured) p-file out of original m-file
% ==> create an additional m-file for the help/doc: p-files contain no help
% 
% this script creates a p-file out of the original m-file and
% and additional m-file with the help text
% ATTENTION: to avoid overwriting the original m-file the help file will be
% written to a separate release directory
%
% howto release code:
%   - run this script
%   - keep content of source dir for yourself
%   - use content of release directory for public
%   - be careful not to overwrite your original code

mFileFolder = pwd;

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
copyfile('./test_FGen.m'                  , SourceDir);
copyfile('./FGen_History.txt'             , SourceDir);
copyfile('./FGen_ReleaseCode.m'           , SourceDir);

mkdir([SourceDir '@FGen/']);
copyfile('./@FGen/FGen.m'                 , [SourceDir '@FGen/']);
copyfile('./@FGen/checkParams.m'          , [SourceDir '@FGen/']);
copyfile('./@FGen/listAvailablePackages.m', [SourceDir '@FGen/']);

% support packages
mkdir([SourceDir '+FGen/+Agilent/+Gen33220A/']);
copyfile('./+FGen/+Agilent/+Gen33220A/FGenMacros.m', ...
    [SourceDir '+FGen/+Agilent/+Gen33220A/']);
%
mkdir([SourceDir '+FGen/+Siglent/+SDG6000X/']);
copyfile('./+FGen/+Siglent/+SDG6000X/FGenMacros.m', ...
    [SourceDir '+FGen/+Siglent/+SDG6000X/']);
%
mkdir([SourceDir '+FGen/template/']);
copyfile('./+FGen/template/FGenMacros.m', [SourceDir '+FGen/template/']);

% -------------------------------------------------------------------------
% 2nd step: create p-file and m-file (help) in release directory

mkdir([ReleaseDir '@FGen/']);
% create additional .m files with help (documentation)
mhelp = help('./@FGen/FGen.m');
fid = fopen([ReleaseDir '@FGen/FGen.m'], 'w');
fwrite(fid,['%' strrep(mhelp, newline, sprintf('\n%%'))]);
fclose(fid);

% create a pcode file out of original m-files
% m-file for internal use only
% p-file for public
cd([ReleaseDir '@FGen/']);
pcode(fullfile(mFileFolder, '@FGen', 'FGen.m'));
pcode(fullfile(mFileFolder, '@FGen', 'checkParams.m'));
pcode(fullfile(mFileFolder, '@FGen', 'listAvailablePackages.m'));

cd(mFileFolder);
mkdir([ReleaseDir '+FGen/+Agilent/+Gen33220A/']);
cd([ReleaseDir '+FGen/+Agilent/+Gen33220A/']);
pcode(fullfile(mFileFolder, '+FGen', '+Agilent', '+Gen33220A', ...
    'FGenMacros.m'));

cd(mFileFolder);
mkdir([ReleaseDir '+FGen/+Siglent/+SDG6000X/']);
cd([ReleaseDir '+FGen/+Siglent/+SDG6000X/']);
pcode(fullfile(mFileFolder, '+FGen', '+Siglent', '+SDG6000X', ...
    'FGenMacros.m'));

cd(mFileFolder);
% -------------------------------------------------------------------------
