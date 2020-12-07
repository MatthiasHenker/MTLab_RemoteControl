function varargout = listSupportedPackages(className)
% displays information about available support packages for a specific sub
% class (input parameter classname, e.g. 'Scope' out of 
% VisaIF.SupportedInstrumentClasses)
%
% no outputs defined yet 
%   - all information are displayed in command window only
%   - extend later when needed

% init output variables
if nargout > 0
    error('VisaIF: Too many output arguments.');
else
    varargout  = cell(1, nargout);
end

% -------------------------------------------------------------------------
% 1) search for macros class files in sub dirs of root package dir
%    RootDir\VendorDir\ProductDir\XXXMacros.m with XXX = className
% 2) display search results
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

cnt = 0;
% start a loop over all vendor and product folders
if isempty(RootDir)
    disp(['No package directory (''' RootDirName ...
        ''') found in Matlab search path.']);
else
    % get a list of all files and folders in this folder ==> Vendor
    files = dir(RootDir);
    % extract only those that are directories
    VendorDirs = files([files.isdir]);
    % remove . and ..
    %VendorDirs(ismember({VendorDirs.name}, {'.', '..'})) = [];
    % remove all dirs not starting with '+'
    VendorDirs = VendorDirs(~cellfun(@isempty, ...
        regexp({VendorDirs.name}, '^\+\w+$')));
    
    % check each Vendor dir
    for vIdx = 1 : length(VendorDirs)
        % get a list of all files and folders in this folder.
        files = dir(fullfile(VendorDirs(vIdx).folder, VendorDirs(vIdx).name));
        % extract only those that are directories.
        ProductDirs = files([files.isdir]);
        % remove . and ..
        %ProductDirs(ismember({ProductDirs.name}, {'.', '..'})) = [];
        % remove all dirs not starting with '+'
        ProductDirs = ProductDirs(~cellfun(@isempty, ...
            regexp({ProductDirs.name}, '^\+\w+$')));
        
        % check each Product dir
        for pIdx = 1 : length(ProductDirs)
            % full path and name of macros class file (m- or p-file)
            macroFile = fullfile(ProductDirs(pIdx).folder, ...
                ProductDirs(pIdx).name, [className 'Macros']);
            
            % check if a macro class file is available
            if exist([macroFile '.m'], 'file') || exist([macroFile '.p'], 'file')
                % get vendor and product name (without leading '+')
                Vendor  = regexprep(VendorDirs(vIdx).name, '^\+', '');
                Product = regexprep(ProductDirs(pIdx).name, '^\+', '');
                
                % build up path to selected device package directory
                fString = [ className '.' Vendor '.' Product '.' ...
                    className 'Macros'];
                % check if it is a macro class file
                try
                    MacrosVersion = eval([fString '.MacrosVersion']);
                    MacrosDate    = eval([fString '.MacrosDate']);
                catch
                    MacrosVersion = '';
                    MacrosDate    = '';
                end
                
                if ~isempty(MacrosVersion) && ~isempty(MacrosDate)
                    if cnt == 0
                        fprintf('%s support packages were found at\n', ...
                            className);
                        fprintf('  Path   : %s\n', VendorDirs(vIdx).folder);
                    end
                    % success
                    cnt = cnt + 1;
                    
                    % display information about support package
                    fprintf('#%d: \n', cnt);
                    fprintf('  Vendor : %s\n', Vendor);
                    fprintf('  Product: %s\n', Product);
                    fprintf('  Version: %s\n', MacrosVersion);
                    fprintf('  Date   : %s\n', MacrosDate);
                end
            end
        end
    end
    
end

end
