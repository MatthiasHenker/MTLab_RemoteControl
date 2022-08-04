function varargout = listSupportedPackages(varargin)
% displays information about available support packages
%
% optional input to disable display messages
%   - ShowMessages : logical (default is true)
%
% output lists available HandheldDMM suport packages
%   - Listpackages : cell array of char array
%

% get name of class (where this method belongs to)
className   = mfilename('class');

% check input
narginchk(0, 1);
if nargin == 0
    ShowMessages = true;
else
    if isscalar(varargin{1}) && ...
            (islogical(varargin{1}) || isnumeric(varargin{1}))
        % finally convert and set property
        ShowMessages = logical(varargin{1});
    else
        ShowMessages = false;
    end
end

% init output variables
if nargout > 1
    error([className ': Too many output arguments.']);
else
    varargout  = cell(1, nargout);
end

% -------------------------------------------------------------------------
% 1) search for macros class files in sub dirs of root package dir
%    RootDir\ProductDir\XXXMacros.m with XXX = className
% 2) display search results
% 3) set output
% -------------------------------------------------------------------------

% root package directory name is same as class name
RootDirName = ['+' className];
% check if root package name is available in Matlab search path
mpathlist = split(path,';');

for cnt = 1 : length(mpathlist)
    RootDir = fullfile(mpathlist{cnt}, RootDirName);
    if exist(RootDir, 'dir')
        break
    else
        RootDir = '';
    end
end

% start a loop over all product folders
if isempty(RootDir)
    disp(['No package directory (''' RootDirName ...
        ''') found in Matlab search path.']);
else
    % get a list of all files and folders in this folder ==> Product
    files = dir(RootDir);
    % extract only those that are directories
    ProductDirs = files([files.isdir]);
    % remove all dirs not starting with '+'
    ProductDirs = ProductDirs(~cellfun(@isempty, ...
        regexp({ProductDirs.name}, '^\+\w+$')));
    
    PackageList = {};
    % check each Product dir
    for pIdx = 1 : length(ProductDirs)
        % get product name (without leading '+')
        Product = regexprep(ProductDirs(pIdx).name, '^\+', '');
        
        % init
        MacrosVersion = '';
        MacrosDate    = '';
        errMsg        = '';
        
        % full path and name of macros class file (m- or p-file)
        macroFile = fullfile(ProductDirs(pIdx).folder, ...
            ProductDirs(pIdx).name, [className 'Macros']);
        
        % check if a macro class file is available
        if exist([macroFile '.m'], 'file') || exist([macroFile '.p'], 'file')
            % build up path to selected device package directory
            fString = [ className '.' Product '.' className 'Macros'];
            % check if it is a accessible macro class file
            try
                MacrosVersion = eval([fString '.MacrosVersion']);
                MacrosDate    = eval([fString '.MacrosDate']);
            catch ME
                if strcmp(ME.identifier, ...
                        'MATLAB:subscripting:classHasNoPropertyOrMethod')
                    errMsg = 'no valid support package found in this directory';
                else
                    errMsg = 'unknown error';
                end
            end
        else
            errMsg = 'no support package found in this directory';
        end
        
        if ~isempty(MacrosVersion) && ~isempty(MacrosDate)
            PackageList = [PackageList, {Product}];
        end
        
        if ShowMessages
            if pIdx == 1
                fprintf('%s support packages are located at\n', ...
                    className);
                fprintf('  Path   : %s\n', ProductDirs(pIdx).folder);
            end
            
            % display information about support package
            fprintf('#%d: \n', pIdx);
            fprintf('  Product: %s\n', Product);
            if ~isempty(MacrosVersion) && ~isempty(MacrosDate)
                fprintf('  Version: %s\n', MacrosVersion);
                fprintf('  Date   : %s\n', MacrosDate);
            else
                fprintf('  Error  : %s\n', errMsg);
            end
        end
        
    end
    
    % done
    if nargout == 1
        varargout(1) = {PackageList};
    end
end

end
