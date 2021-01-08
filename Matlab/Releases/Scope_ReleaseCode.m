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
copyfile('./test_Scope.m'                  , SourceDir);
copyfile('./Scope_History.txt'             , SourceDir);
copyfile('./Scope_ReleaseCode.m'           , SourceDir);

mkdir([SourceDir '@Scope/']);
copyfile('./@Scope/Scope.m'                , [SourceDir '@Scope/']);
copyfile('./@Scope/checkParams.m'          , [SourceDir '@Scope/']);
copyfile('./@Scope/listAvailablePackages.m', [SourceDir '@Scope/']);

% support packages
mkdir([SourceDir '+Scope/+Keysight/+DSOX1000/']);
copyfile('./+Scope/+Keysight/+DSOX1000/ScopeMacros.m', ...
    [SourceDir '+Scope/+Keysight/+DSOX1000/']);
% ToDo
mkdir([SourceDir '+Scope/+Rigol/']);
%
mkdir([SourceDir '+Scope/+RS/+RTB2000/']);
copyfile('./+Scope/+RS/+RTB2000/ScopeMacros.m', ...
    [SourceDir '+Scope/+RS/+RTB2000/']);
% ToDo
mkdir([SourceDir '+Scope/+Siglent/']);
%
mkdir([SourceDir '+Scope/+Tektronix/+TDS1000_2000/']);
copyfile('./+Scope/+Tektronix/+TDS1000_2000/ScopeMacros.m', ...
    [SourceDir '+Scope/+Tektronix/+TDS1000_2000/']);
%
mkdir([SourceDir '+Scope/template/']);
copyfile('./+Scope/template/ScopeMacros.m', ...
    [SourceDir '+Scope/template/']);

% -------------------------------------------------------------------------
% 2nd step: create p-file and m-file (help) in release directory

mkdir([ReleaseDir '@Scope/']);
% create additional .m files with help (documentation)
mhelp = help('./@Scope/Scope.m');
fid = fopen([ReleaseDir '@Scope/Scope.m'], 'w');
fwrite(fid,['%' strrep(mhelp, newline, sprintf('\n%%'))]);
fclose(fid);

% create a pcode file out of original m-files
% m-file for internal use only
% p-file for public
cd([ReleaseDir '@Scope/']);
pcode(fullfile(mFileFolder, '@Scope', 'Scope.m'));
pcode(fullfile(mFileFolder, '@Scope', 'checkParams.m'));
pcode(fullfile(mFileFolder, '@Scope', 'listAvailablePackages.m'));

cd(mFileFolder);
mkdir([ReleaseDir '+Scope/+Keysight/+DSOX1000/']);
cd([ReleaseDir '+Scope/+Keysight/+DSOX1000/']);
pcode(fullfile(mFileFolder, '+Scope', '+Keysight', '+DSOX1000', ...
    'ScopeMacros.m'));

cd(mFileFolder);
mkdir([ReleaseDir '+Scope/+Rigol/']);    % ToDo
cd([ReleaseDir '+Scope/+Rigol/']);       % ToDo
%pcode();

cd(mFileFolder);
mkdir([ReleaseDir '+Scope/+RS/+RTB2000/']);
cd([ReleaseDir '+Scope/+RS/+RTB2000/']);
pcode(fullfile(mFileFolder, '+Scope', '+RS', '+RTB2000', ...
    'ScopeMacros.m'));

cd(mFileFolder);
mkdir([ReleaseDir '+Scope/+Siglent/']);  % ToDo
cd([ReleaseDir '+Scope/+Siglent/']);     % ToDo
%pcode();

cd(mFileFolder);
mkdir([ReleaseDir '+Scope/+Tektronix/+TDS1000_2000/']);
cd([ReleaseDir '+Scope/+Tektronix/+TDS1000_2000/']);
pcode(fullfile(mFileFolder, '+Scope', '+Tektronix', '+TDS1000_2000', ...
    'ScopeMacros.m'));

cd(mFileFolder);
% -------------------------------------------------------------------------
