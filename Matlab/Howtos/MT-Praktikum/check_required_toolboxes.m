% 2025-09-08
%
% This script checks and lists the required licenses and toolboxes by the
% Howto-files of this directory. (tested with Matlab 2024a, 2024b)
%
% Matthias Henker, HTW Dresden

%% preparations -----------------------------------------------------------

% clear workspace
if true    % set to false when you want to keep your old data in workspace
    clear;
    close all;
    clc;
end

%% configuration part (adapt to your needs !!!) ---------------------------

% Specify the directory that contains the m-files to be checked.
myFilePath = fileparts(mfilename('fullpath')); % dir holding this m-file 
%myFilePath = 'C:\Users\Henker\GitHub\MTLab_RemoteControl\Matlab\Howtos\Sonstiges';
cd(myFilePath);

% Specify all files to be checked (dependencies on files and licenses)
myFolderInfo = dir('Howto_*.m');  % only Howto-files
%myFolderInfo = dir('*.m');        % all m- files
%
% or a specific one
%myFolderInfo = dir('Howto_create_figures_with_swapped_labels.m');


%% actual code ------------------------------------------------------------

disp('Check dependencies on files and licenses: ...')

% init
numOfFiles  = size(myFolderInfo, 1);
fileList    = {};
productList = [];

for cnt = 1 : numOfFiles
    disp([' - File ' num2str(cnt, '%02d') '/' num2str(numOfFiles, '%d') ...
        ': ' myFolderInfo(cnt).name]);

    % check dependencies and save results
    [fList, pList] = matlab.codetools.requiredFilesAndProducts( ...
        myFolderInfo(cnt).name);

    % concat lists
    fileList    = [fileList    ; fList']; %#ok<AGROW>
    productList = [productList ; pList']; %#ok<AGROW>

end

% remove duplicates and sort in order
fileList    = unique(fileList, 'sorted');
productList = unique(struct2table(productList));
% but  want it sorted in respect to ProductNumer
productList = sortrows(productList, ProductNumber = 'ascend');

% display results
disp(' ');
disp('The following files are required: ');
disp(fileList);

disp('The following products (licenses) are required:');
disp(productList);

disp('Done.');
% EOF