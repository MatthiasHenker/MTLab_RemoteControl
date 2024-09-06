% 2024-09-05
%
% This script checks and lists the required licenses and toolboxes by the
% Howto-files of this directory. (test with Matlab 2024a)
%
% Matthias Henker, HTW Dresden

% clear workspace
clear;
close all;
clc;

%% configuration part (adapt to your needs) ------------------------------------

% script should be run in directory holding this script ==> change dir
currentFilePath = fileparts(mfilename('fullpath'));
cd(currentFilePath);

% now list all Howto-files of this directory ==> adapt to your needs
% these files will be checked (dependencies on files and licenses)
myFolderInfo = dir('Howto_*.m');  % several files
% or a specific one
%myFolderInfo = dir('Howto_create_figures_with_swapped_labels.m');


%% actual code -----------------------------------------------------------------

disp('Check dependencies on files and licenses: ...')

% init
numOfFiles  = size(myFolderInfo, 1);
fileList    = {};
productList = [];

for cnt = 1 : numOfFiles
    disp([' - File ' num2str(cnt, '%02d') '/' num2str(numOfFiles, '%d') ': ' ...
        myFolderInfo(cnt).name]);

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
productList = sortrows(productList, 'ProductNumber', 'ascend');

% display results
disp(' ');
disp('The following files are required: ');
disp(fileList);

disp('The following products (licenses) are required:');
disp(productList);

disp('Done.');
% EOF