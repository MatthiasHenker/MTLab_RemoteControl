function varargout = listContentOfConfigFiles
% returns a table listing all supported devices found in config files
%
% function call without any output arguments, then results are
% displayed as text messages
%   VisaIF.listContentOfConfigFiles
%
% function call with output argument then no messages are
% displayed at all
%   cfgTable = VisaIF.listContentOfConfigFiles
%   ==> table containing all settings

className   = mfilename('class');

% init output variables
if nargout > 1
    error([className ': Too many output arguments.']);
else
    varargout  = cell(1, nargout);
end

% initialize config table with specified names and types
colNamesTypes = [ ...
    ["Device"    , "categorical"] ; ...
    ["Vendor"    , "categorical"] ; ...
    ["Product"   , "categorical"] ; ...
    ["Instrument", "categorical"] ; ...
    ["Type"      , "categorical"] ; ...
    ["RsrcName"  , "categorical"] ; ...
    ["OutBufSize", "double"     ] ; ...
    ["InBufSize" , "double"     ] ; ...
    ["ExtraWait" , "double"     ] ];
% now create an empty table (starting with header only)
cfgTable = table( ...
    'Size',          [0 size(colNamesTypes, 1)], ...
    'VariableNames', colNamesTypes(:, 1) , ...
    'VariableTypes', colNamesTypes(:, 2) );

% create list of VisaIF config files
cfgFileList = VisaIF.listAvailableConfigFiles;
if isempty(cfgFileList) && nargout == 0
    disp('No config files were found.');
end

% read in content of all found config files
numOfRows = 0;
for cfgFile = cfgFileList
    % read in cfg file (and detect options automaically)
    opts = detectImportOptions(cfgFile          , ...
        'FileType'            , 'delimitedtext' , ...
        'Encoding'            , 'UTF-8'         , ...
        'CommentStyle'        , '#'             , ...
        'Delimiter'           , ';;'            , ...
        'ReadVariableNames'   , true            , ...
        'ExpectedNumVariables', 9               , ...
        'ReadRowNames'        , false           );
    newPartOfCfgTable = readtable(cfgFile, opts);
    
    % select matching columns (variable names in header)
    matchingCols = intersect(colNamesTypes(:, 1), ...
        newPartOfCfgTable.Properties.VariableNames);
    numOfNewRows = height(newPartOfCfgTable);
    
    if isempty(matchingCols)
        % ignore new config data (cfg file seems to be empty)
        if nargout == 0
            warning(['No content found in ' char(cfgFile)]);
        end
    else
        % define row vector for config table and update counter
        rowIdx    = numOfRows + (1 : numOfNewRows);
        numOfRows = numOfRows + numOfNewRows;
        
        % copy matching columns to cfgTable and fill missing
        % columns by default values (<undefined> for categorical
        % and 0 (zero) for double)
        warning('off');
        cfgTable(rowIdx, matchingCols) = ...
            newPartOfCfgTable(:, matchingCols);
        warning('on');
        
        % check field entries (e.g. remove invalid categories)
        cfgTable(rowIdx, :) = ...
            VisaIF.coerceConfigTable(cfgTable(rowIdx, :));
        
        if nargout == 0
            % display results only
            disp(['Content of ' char(cfgFile) ':']);
            disp(cfgTable(rowIdx, :));
            if any(ismissing(cfgTable(rowIdx, :)), 'all')
                warning(['Some fields of config file ' ...
                    'contain invalid or missing entries.']);
            end
        end
    end
end

% copy final table to output
if nargout > 0
    
    % remove duplicate rows
    cfgTable = unique(cfgTable);
    
    % sort table (a-z)
    cfgTable.Device = setcats(cfgTable.Device, ...
        categories(reordercats(cfgTable.Device)));
    cfgTable = sortrows(cfgTable, 'Device');
    
    % finally add a column 'Id' with row numbers to table
    cfgTable = [table((1 : height(cfgTable))', ...
        'VariableNames', {'Id'}) cfgTable];
    
    varargout(1) = {cfgTable};
end

end