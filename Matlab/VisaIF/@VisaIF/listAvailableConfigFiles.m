function varargout = listAvailableConfigFiles
% returns a list of available config files in the class dir
%
% function call without any output arguments, then results are
% displayed as text messages
%   VisaIF.listAvailableConfigFiles
%
% function calls with output arguments then no messages are
% displayed at all
%   cfgFileList = VisaIF.listAvailableConfigFiles
%   ==> string array containing all cfg files with full path
%
%   [cfgFileList, cfgFilePath] = VisaIF.listAvailableConfigFiles
%   ==> cfgFileList as string array with file names only
%   ==> cfgFilePath single string with common path to cfg files

% set to false when method is defined inside the class file
methodIsOutsideOfClassFile = true;

className   = mfilename('class');

% init output variables
if nargout > 2
    error([className ': Too many output arguments.']);
else
    varargout  = cell(1, nargout);
end

cfgFileList    = string;
cfgFilePath    = string;

% determine path to VisaIF class directory
pathToMethod = mfilename('fullpath');
if methodIsOutsideOfClassFile
    mStack = dbstack;
    nameOfClassOrFunction = mStack.name;
else
    nameOfClassOrFunction  = mfilename('class');
end

% remove trailing function or class name from full path
if endsWith(pathToMethod, nameOfClassOrFunction)
    % should always be a valid path else output is empty
    cfgFilePath = string( ...
        pathToMethod(1 : end-length(nameOfClassOrFunction)));
end
% list all files in class directory
fileList = dir(cfgFilePath);
% search for config files
numOfCfgFiles = 0;
for fileOrDir = fileList'
    if endsWith(fileOrDir.name, '.csv') && ~fileOrDir.isdir
        numOfCfgFiles = numOfCfgFiles + 1;
        cfgFileList(numOfCfgFiles) = string(fileOrDir.name);
    end
end

% either return results in output variables or display results
if nargout == 0
    % display search results when called with no outputs only
    if isempty(cfgFilePath)
        disp(['Something went wrong. No search path ' ...
            'could be determined.']);
    else
        disp(['Config files (*.csv) for VisaIF class ' ...
            'were searched in:']);
        disp(['  ' char(cfgFilePath)]);
    end
    if numOfCfgFiles == 0
        disp('No config files (*.csv) were found.');
    else
        disp('Found config files (*.csv):');
        for cnt = 1 : numOfCfgFiles
            disp(['  ' char(cfgFileList(cnt))]);
        end
    end
elseif nargout == 1
    % silent mode when called with outputs
    % ==> list of config files as full path
    if numOfCfgFiles > 0
        varargout(1) = {strcat(cfgFilePath, cfgFileList)};
    end
else
    % silent mode when called with outputs
    % ==> separated variables
    if numOfCfgFiles > 0
        varargout(1) = {cfgFileList};
    end
    varargout(2) = {cfgFilePath};
end

end
