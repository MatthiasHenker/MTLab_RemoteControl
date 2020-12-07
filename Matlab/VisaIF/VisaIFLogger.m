classdef VisaIFLogger < handle
    % documentation for class 'VisaIFLogger'
    % ---------------------------------------------------------------------
    % Intention: This class listen to events by VisaIF class (notify) and
    % store the event data. Thus, the SCPI commands of all Visa devices
    % where stored in a central history in the right order. This enables
    % easier debugging.
    % ---------------------------------------------------------------------
    % methods (public) of class 'VisaIFLogger':
    %   - VisaIFLogger  : constructor of this class (same name as class)
    %     * use this function to create an logger object
    %     * create listeners to event notifications created by VisaIF
    %     * all sent/received SCPI commands will be stored in a single
    %       place
    %     * usage:
    %         myLog = VisaIFLogger;          % with default settings
    %         myLog = VisaIFLogger(showmsg);
    %       with
    %         showmsg : 'none', 0 or false   for silent mode,
    %                   'few' or 1           for taciturn mode,
    %                   'all', 2, or true    for talkative mode,
    %                   (optional input: default value is 'all')
    %                   use [] or '' for default
    %                   this parameter can also be changed later again,
    %                   see property myLogger.ShowMessages
    %   - delete  : destructor of this class
    %     * deletes listeners and VisaIFLogger object
    %     * writes command history table to file (myLog.AutoSaveFileName 
    %       when myLog.AutoSave = true)
    %     * usage:
    %           myLog.delete
    %       without any input or output parameters
    %   - listVisaListener   : displays list of existing listeners to 
    %                   VisaIF log events
    %   - listCommandHistory : displays content of property CommandHistory
    %     * with additional information when myLog.ShowMessages = 'all'
    %     * usage:
    %         myLog.listCommandHistory    % with default numLines = 10
    %         myLog.listCommandHistory(numLines)
    %       with
    %         numLines : positive integer (double), inf for all lines
    %   - saveHistoryTable   : save full command history table to csv file
    %     * usage:
    %         myLogger.saveHistoryTable('fileName');
    %       with
    %         fileName (optional): string or character array;
    %                   supported file format is '.csv' only
    %                   default is myLogger.AutoSaveFileName
    %   - readHistoryTable   : imports history from csv file 
    %     * overwrites internal command history table
    %     * be careful to prevent manipulation of history table (disable 
    %       notifiers)
    %     * usage:
    %         myLogger.readHistoryTable('fileName');
    %       with
    %         fileName (optional): string or character array;
    %                   supported file format is '.csv' only
    %                   default is myLogger.AutoSaveFileName
    % 
    % properties of class 'VisaIFLogger':
    %   - with read/write access
    %     * ShowMessages   : 'all',  2, true (default) for talkative mode
    %                        'few',  1                 for taciturn mode
    %                        'none', 0, false          for silent mode
    %
    %     * AutoSave         : logical; default is true; save history to
    %                   file with period myLog.AutoSaveInterval
    %     * AutoSaveInterval : positive integer (double); default is 500
    %     * AutoSaveFileName : char; default is './VisaIFLog_AutoSave.csv'
    %     * Filter           : logical; default is false; 
    %         false: all lines command history will be output
    %         true : only lines matching the filter settings will be output
    %     * FilterLine       : array of doubles with numel = 2;
    %         default is [-inf 0]; specifying lines to be displayed;
    %         positive values    : index relates to table head 
    %           ==> [1:3] for lines 1 .. 3 of history table
    %         non positive values: index relates to table tail
    %           ==> [-inf : -2] for all lines except for last 2 lines
    %     * FilterCmdID      : array of doubles with numel = 2
    %         same as above, but for column CmdID
    %     * FilterDevice     : char array as regexp; default is '.'
    %         filter column Device; not case sensitive; some examples
    %         '.'        : any character (no filter)
    %         '^Agi'     : starting with 'Agi'
    %         'X$'       : ending with 'X'
    %         'TDS'      : name has to contain 'TDS'
    %         '^(?!ABC).': name must not contain 'ABC' (or '^((?!ABC).)*$')
    %     * FilterMode       : char array as regexp; default is '.'
    %         filter column Mode; same as for filter Device
    %     * FilterSCPIcommand: char array as regexp; default is '.'
    %         filter column SCPIcommand; same as for filter Device
    %     * FilterNumBytes   : array of doubles with numel = 2;
    %         default is [1 inf]; show lines only where NumBytes is within
    %         specified range
    %         [1  10]  : up to 10 bytes
    %         [10 inf] : at least 10 bytes
    %         [5 20]   : from 5 to 20 bytes 
    %
    %   - with read only access
    %     * CommandHistory : command history table; filtered according to
    %                   filter settings
    %     * LineCounter    : number of last logged SCPI command
    %
    %   - with read only access (constant, can be used as static property)
    %     * VisaIFLoggerVersion : version of this class file (char)
    %     * VisaIFLoggerDate    : release date of this class file (char)
    %
    % example for usage of class 'VisaIFLogger':
    %   VisaIFLogger.VisaIFLoggerVersion % shows version
    %   myLog = VisaIFLogger;            % creates logger object
    %   myLog.listVisaListener;          % list registered listeners
    %   myLog.Filter       = true;       % enable filter for history
    %   myLog.FilterLine   = [-19 0];    % last 20 commands only
    %   myLog.FilterDevice = '^T';       % devices beginning with 'T' only
    %   myLog.listCommandHistory;        % show command history
    %
    % ---------------------------------------------------------------------
    % HTW Dresden, faculty of electrical engineering
    %   for version and release date see properties 'VisaIFLoggerVersion'
    %   and 'VisaIFLoggerDate'
    %
    % tested with
    %   - VisaIF             v2.3.0  (2020-05-25)
    %   - VisaIFLogEventData v2.0.0  (2020-05-25)
    %   - Matlab 2019b update 5 (Windows 10)
    %   - for further requirements see VisaIF
    %
    % ---------------------------------------------------------------------
    % development, support and contact:
    %   - Constantin Wimmer (student, automation)
    %   - Matthias Henker   (professor)
    % ---------------------------------------------------------------------
    
    properties(Constant = true)
        VisaIFLoggerVersion = '2.0.0';      % current version
        VisaIFLoggerDate    = '2020-05-25'; % release date
    end
    
    properties
        ShowMessages              = 'all';  % talkative mode as default
        AutoSave          logical = true;   %
        AutoSaveInterval  double  = 500;    %
        AutoSaveFileName  char    = './VisaIFLog_AutoSave.csv';
        Filter            logical = false; 
        FilterLine        double  = [-inf 0];
        FilterCmdID       double  = [-inf 0]; 
        FilterDevice      char    = '.';
        FilterMode        char    = '.';
        FilterSCPIcommand char    = '.';
        FilterNumBytes    double  = [1 inf];
    end
    
    properties(Dependent, SetAccess = private, GetAccess = public)
        CommandHistory
    end
    
    properties(SetAccess = private, GetAccess = public)
        LineCounter     double % number of entries in command history table
    end
    
    properties(Constant = true, GetAccess = private)
        CmdHistTableLength = 5000; % like a FIFO: older entries get lost
    end
    
    properties(SetAccess = private, GetAccess = private)
        ListenToVisaIFCreation % listener to VisaIF instance creation
        ListenToVisaIFDeletion % listener to VisaIF instance deletion
        VisaListener           % listener to notifications from VisaIF
        TableNames             % header names of command history table
        TableTypes             % header types of command history table
        CmdHistTable           % history table (internal full table)
    end
    
    methods
        
        function obj = VisaIFLogger(showmsg)
            % constructor of logger class
            
            % check number of input arguments
            narginchk(0, 1);
            
            % -------------------------------------------------------------
            % set default values when no input is given
            if nargin < 1 || isempty(showmsg)
                showmsg = '';
            end
            
            % -------------------------------------------------------------
            % check input parameters
            if ~isempty(showmsg)
                % try to set ShowMessages property (includes syntax check)
                obj.ShowMessages = showmsg;
            end
            
            % -------------------------------------------------------------
            % actual code: search for already existing VisaIF objects
            
            % fetch all variables in base workspace ==> cell array
            baseVariables = evalin('base', 'who');
            
            % init empty cell array for search results
            VisaIFObj     = cell(0);
            
            % evaluate which variables are VisaIF objects
            for idx = 1 : length(baseVariables)
                var = evalin('base', baseVariables{idx});
                if isa(var, 'VisaIF') && isvalid(var)
                    % attach handle to found VisaIF (and sub-classes)
                    % objects to the end of VisaIFObj (cell array)
                    VisaIFObj{length(VisaIFObj) +1} = var;
                end
            end
            
            % -------------------------------------------------------------
            % create actual listener to VisaIF notifications
            for idx = 1 : length(VisaIFObj)
                if idx == 1
                    % create listener
                    obj.VisaListener = listener(VisaIFObj{idx},...
                        'VisaIFLogEvent', @obj.writeToHistTable);
                else
                    % attach to listener (cell array)
                    obj.VisaListener.Source(idx) = VisaIFObj(idx);
                end
            end
            
            % optionally display search results
            if strcmp(obj.ShowMessages, 'all')
                if isempty(VisaIFObj)
                    disp(['VisaIFLogger: No VisaIF objects have been ' ...
                        'found. Wait for creation of VisaIF objects.']);
                else
                    disp(['VisaIFLogger: ' ...
                        num2str(length(obj.VisaListener.Source)) ...
                        ' listeners to VisaIF log events were created:']);
                    for cnt = 1 : length(obj.VisaListener.Source)
                        disp([' (' num2str(cnt, '%02d') ') ' ...
                            pad(obj.VisaListener.Source{cnt}.Device, ...
                            18) ' (' ...
                            obj.VisaListener.Source{cnt}.RsrcName ')']);
                    end
                end
            end
            
            % -------------------------------------------------------------
            % add listener to detect VisaIF object creation in future
            VisaIFMeta = ?VisaIF;
            obj.ListenToVisaIFCreation = listener(VisaIFMeta, ...
                'InstanceCreated', @obj.addVisaListener);
            obj.ListenToVisaIFDeletion = listener(VisaIFMeta, ...
                'InstanceDestroyed', @obj.removeVisaListener);
            
            % optionally display message
            if strcmp(obj.ShowMessages, 'all')
                disp(['VisaIFLogger: Listener to creation & deletion ' ...
                    'of VisaIF objects was created.']);
            end
            
            % -------------------------------------------------------------
            % init command history table and counter
            
            % create an empty table
            obj.initCmdHistTable;
            
            % initialize counter for entries in command history table
            obj.LineCounter = 0;
            
            % all other relevant properties are declared with sensible
            % default values ==> nothing to do here
            
            % -------------------------------------------------------------
            % done
            if ~strcmp(obj.ShowMessages, 'none')
                disp([class(obj) ' object created.']);
            end
        end
        
        function delete(obj)
            % destructor of this class
            
            % optionally save command history to file
            if obj.AutoSave
                % optionally display message
                if strcmp(obj.ShowMessages, 'all')
                    disp(['VisaIFLogger: save history before ' ...
                        'deleting object']);
                end
                % actual save method
                obj.saveHistoryTable;
            end
            
            % remove listeners
            delete(obj.VisaListener);
            delete(obj.ListenToVisaIFCreation);
            
            if ~strcmp(obj.ShowMessages, 'none')
                disp(['Object destructor called for class ' class(obj) ...
                    ' (includes listeners).']);
            end
        end
        
        function listVisaListener(obj)
            % displays all listeners for VisaIF notifications
            
            if isvalid(obj.VisaListener)
                disp(['VisaIFLogger: ' ...
                    num2str(length(obj.VisaListener.Source)) ...
                    ' listeners to VisaIF log events exist:']);
                for cnt = 1 : length(obj.VisaListener.Source)
                    disp([' (' num2str(cnt, '%02d') ') ' ...
                        pad(obj.VisaListener.Source{cnt}.Device, ...
                        18) ' (' ...
                        obj.VisaListener.Source{cnt}.RsrcName ')']);
                end
            else
                disp(['VisaIFLogger: Empty or invalid list of VisaIF ' ...
                    'log event listeners.']);
            end
        end
        
        function listCommandHistory(obj, maxLines)
            % display content of property CommandHistory and optionally
            % some additional information
            
            narginchk(1, 2);
            if nargin == 1 || isempty(maxLines)
                % set default value
                maxLines = 10;
            end
            
            % check input
            if ~isscalar(maxLines) || ~isa(maxLines, 'double')
                error(['VisaIFLogger: Invalid parameter type. ' ...
                    'Scalar double for ''maxLines'' expected.']);
            end
            cmdHist  = obj.CommandHistory;
            numLines = size(cmdHist, 1);
            % coerce input
            maxLines = round(maxLines);         % no fractionals
            maxLines = max(maxLines, 1);        % min is 1
            maxLines = min(maxLines, numLines); % max is number of lines
            
            disp('VisaIFLogger: content of command history');
            lineIdx = numLines + (1- maxLines : 0);
            disp(cmdHist(lineIdx, :));
            
            % optionally display some more details
            if strcmp(obj.ShowMessages, 'all')
                disp([' Filter settings for ''Filter''           : ' ...
                    num2str(obj.Filter)]);
                disp([' Filter settings for ''FilterLine''       : ' ...
                    '[' num2str(obj.FilterLine) ']']);
                disp([' Filter settings for ''FilterCmdID''      : ' ...
                    '[' num2str(obj.FilterCmdID) ']']);
                disp([' Filter settings for ''FilterDevice''     : ' ...
                    obj.FilterDevice ]);
                disp([' Filter settings for ''FilterMode''       : ' ...
                    obj.FilterMode ]);
                disp([' Filter settings for ''FilterSCPIcommand'': ' ...
                    obj.FilterSCPIcommand ]);
                disp([' Filter settings for ''FilterNumBytes''   : ' ...
                    '[' num2str(obj.FilterNumBytes) ']']);
            end
        end
        
        function status = saveHistoryTable(obj, fileName)
            % save full command history table to file
            
            % init output
            status = NaN;
            
            narginchk(1, 2);
            if nargin == 1 || isempty(fileName)
                % set default value
                fileName = obj.AutoSaveFileName;
            end
            
            % check if fileName is a valid path
            try
                fileName = char(java.io.File(fileName).toPath);
            catch
                disp('VisaIFLogger: Error - filename is not a valid path.');
                status = -1;
                return
            end
            
            % check file extension
            if ~endsWith(fileName, '.csv', 'IgnoreCase', true)
                disp('VisaIFLogger: Error - invalid file extension.');
                status = -1;
                return
            end
            
            % -------------------------------------------------------------
            % actual code
            
            % optionally display message
            if strcmp(obj.ShowMessages, 'all')
                disp('VisaIFLogger: save command history to file');
                disp([' ''' fileName '''']);
            end
            
            % save only non-empty lines
            matches      = ~isnan(obj.CmdHistTable.Line);
            try
                writetable(obj.CmdHistTable(matches, :), fileName, ...
                    'WriteVariableNames', true  , ...
                    'Delimiter'         , ';'   );
            catch
                disp('VisaIFLogger: Error - write table to file.');
                status = -1;
                return
            end
            
            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end
        
        function status = readHistoryTable(obj, fileName)
            % imports command history from csv file;
            % Attention: internal command history table will be overwritten
            
            % init output
            status = NaN;
            
            narginchk(1, 2);
            if nargin == 1 || isempty(fileName)
                % set default value
                fileName = obj.AutoSaveFileName;
            end
            
            % check if fileName is a valid path
            try
                fileName = char(java.io.File(fileName).toPath);
            catch
                disp('VisaIFLogger: Error - filename is not a valid path.');
                status = -1;
                return
            end
            
            % check file extension
            if ~endsWith(fileName, '.csv', 'IgnoreCase', true)
                disp('VisaIFLogger: Error - invalid file extension.');
                status = -1;
                return
            end
            
            % check if file exists
            if ~isfile(fileName)
                disp('VisaIFLogger: Error - file not found.');
                status = -1;
                return
            end
            
            % -------------------------------------------------------------
            % actual code
            
            % optionally display message
            if strcmp(obj.ShowMessages, 'all')
                disp('VisaIFLogger: read command history from file');
                disp([' ''' fileName '''']);
            end
            
            % read in cfg file (and detect options automaically)
            opts = detectImportOptions(fileName         , ...
                'FileType'            , 'delimitedtext' , ...
                'Encoding'            , 'UTF-8'         , ...
                'Delimiter'           , ';'             , ...
                'ReadVariableNames'   , true            , ...
                'ExpectedNumVariables', 6               , ...
                'ReadRowNames'        , false           );
            inTable = readtable(fileName, opts);
            
            % select matching columns (variable names in header)
            matchingCols = intersect(obj.TableNames, ...
                inTable.Properties.VariableNames);
            if length(inTable.Properties.VariableNames) ~= ...
                    length(obj.TableNames)
                disp('VisaIFLogger: Error - column names do not match.');
                status = -1;
                return
            end
            
            % clear command history table
            obj.initCmdHistTable
            
            % copy content of loaded table to internal command history
            lineIdx = (1-size(inTable, 1) : 0) + obj.CmdHistTableLength;
            obj.CmdHistTable(lineIdx , matchingCols) = ...
                inTable(:, matchingCols);
            
            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end
        
    end
        
    methods(Access = private)
        
        % it would be possible to merge addVisaListener and
        % removeVisaListener into a single method (e.g. UpdateVisaListener)
        % ==> select right mode by EventSource.EventName ==
        % 'InstanceCreated' or 'InstanceDestroyed'
        % ==> code seems to be easier to read when having two methods
        
        function addVisaListener(obj, ~, EventSource)
            % attach new listener to listener's object reference list
            
            if ~isempty(obj.VisaListener) && isvalid(obj.VisaListener)
                % add new reference at the end of listener's source list
                obj.VisaListener.Source(end+1) = {EventSource.Instance};
            else
                % create listener when none is created yet; this might
                % happen if no object was found when calling VisaIFLogger
                obj.VisaListener = listener(EventSource.Instance,...
                    'VisaIFLogEvent', @obj.writeToHistTable);
            end
            
            if strcmp(obj.ShowMessages, 'all')
                disp(['VisaIFLogger: Listener to VisaIF log events ' ...
                    'was created:']);
                disp([' (' num2str(length(obj.VisaListener.Source), ...
                    '%02d') ') ' ...
                    pad(obj.VisaListener.Source{end}.Device, 18) ...
                    ' (' obj.VisaListener.Source{end}.RsrcName ')']);
            end
        end
        
        function removeVisaListener(obj, ~, EventSource)
            % remove listener from listener's object reference list
            
            if isvalid(obj.VisaListener)
                % check which listener should be deleted
                matches = cellfun(@(x) eq(x, EventSource.Instance), ...
                    obj.VisaListener.Source);
                
                % optionally display messages
                if strcmp(obj.ShowMessages, 'all')
                    disp(['VisaIFLogger: Remove listener to VisaIF ' ...
                        'log events:']);
                    for deletedListeners = obj.VisaListener.Source{matches}
                        disp(['      ' pad(deletedListeners.Device, 18) ...
                            ' (' deletedListeners.RsrcName ')']);
                    end
                end
                
                if all(matches)
                    % last listener ==> delete listener object
                    delete(obj.VisaListener);
                else
                    % at least one listener will remain ==> remove element(s)
                    obj.VisaListener.Source = obj.VisaListener.Source(~matches);
                end
            elseif ~strcmp(obj.ShowMessages, 'none')
                disp(['VisaIFLogger: Remove VisaIF listener - ' ...
                    'invalid listener object.']);
            end
        end
        
        function writeToHistTable(obj, ~, EventData)
            % callback function for VisaIF log event
            
            % update counter (elements im command history table)
            obj.LineCounter = obj.LineCounter + 1;
            
            % table acts like a FIFO: shift rows up (first row will get lost)
            obj.CmdHistTable(1:end-1, :) = obj.CmdHistTable(2:end, :);
            
            % save new data in the last line of the table
            obj.CmdHistTable.Line(end, :)        = obj.LineCounter;
            obj.CmdHistTable.CmdID(end, :)       = EventData.CmdNumber;
            obj.CmdHistTable.Device(end, :)      = EventData.Device;
            obj.CmdHistTable.Mode(end, :)        = EventData.Mode;
            obj.CmdHistTable.SCPIcommand(end, :) = EventData.SCPIcommand;
            obj.CmdHistTable.NumBytes(end, :)    = EventData.CmdLength;
            
            % optionally run autosave periodically
            if obj.AutoSave
                if mod(obj.LineCounter, obj.AutoSaveInterval) == 0
                    % optionally display message
                    if strcmp(obj.ShowMessages, 'all')
                        disp('VisaIFLogger: AutoSave initiated.');
                    end
                    % actual save method
                    obj.saveHistoryTable;
                end
            end
        end
        
        function initCmdHistTable(obj)
            % initialize empty table for command history
            
            % initialize config table with specified names and types
            colNamesTypes = [ ...
                ["Line"        , "double"     ] ; ...
                ["CmdID"       , "double"     ] ; ...
                ["Device"      , "categorical"] ; ...
                ["Mode"        , "categorical"] ; ...
                ["SCPIcommand" , "string"     ] ; ...
                ["NumBytes"    , "double"     ] ];
            
            obj.TableNames = colNamesTypes(:, 1);
            obj.TableTypes = colNamesTypes(:, 2);
            
            % now create an empty table (with default entries)
            obj.CmdHistTable = table( ...
                'Size',          [obj.CmdHistTableLength ...
                size(colNamesTypes, 1)], ...
                'VariableNames', obj.TableNames , ...
                'VariableTypes', obj.TableTypes );
            
            % overwrite some default settings
            obj.CmdHistTable.Line(:)     = NaN;
            obj.CmdHistTable.CmdID(:)    = NaN;
            obj.CmdHistTable.NumBytes(:) = NaN;
        end
        
    end
    
    % ---------------------------------------------------------------------
    methods   % get/set methods
        
        function cmdHistTable = get.CommandHistory(obj)
            % filter lines of command history according to filter settings
            % and copy respective contant to output
            
            % copy non-empty lines to cmdHistTable as starting point
            % unfiltered command history table
            matches      = ~isnan(obj.CmdHistTable.Line);
            cmdHistTable = obj.CmdHistTable(matches, :);
            
            if obj.Filter
                % FilterLine ----------------------------------------------
                tableValues = cmdHistTable.Line;
                if max(obj.FilterLine) < 1
                    filter = obj.FilterLine + max(tableValues);
                else
                    filter = obj.FilterLine;
                end
                matches = tableValues <= max(filter) & ...
                    tableValues >= min(filter);
                % filter table
                cmdHistTable = cmdHistTable(matches, :);
                
                % FilterCmdID ---------------------------------------------
                tableValues = cmdHistTable.CmdID;
                if max(obj.FilterCmdID) < 1
                    filter   = obj.FilterCmdID + max(tableValues);
                else
                    filter   = obj.FilterCmdID;
                end
                matches      = tableValues <= max(filter) & ...
                    tableValues >= min(filter);
                % filter table
                cmdHistTable = cmdHistTable(matches, :);
                
                % FilterDevice --------------------------------------------
                existingCats = categories(cmdHistTable.Device);
                % which categories match the regexp filter setting?
                filterCats   = existingCats(~cellfun(@isempty, ...
                    regexpi(existingCats, obj.FilterDevice)));
                % set non matching elements to <undefined>
                cmdHistTable.Device = setcats(cmdHistTable.Device, ...
                    filterCats);
                matches      = ~isundefined(cmdHistTable.Device);
                cmdHistTable = cmdHistTable(matches , :);
                
                % FilterMode ----------------------------------------------
                existingCats = categories(cmdHistTable.Mode);
                % which categories match the regexp filter setting?
                filterCats   = existingCats(~cellfun(@isempty, ...
                    regexpi(existingCats, obj.FilterMode)));
                % set non matching elements to <undefined>
                cmdHistTable.Mode = setcats(cmdHistTable.Mode, ...
                    filterCats);
                matches      = ~isundefined(cmdHistTable.Mode);
                cmdHistTable = cmdHistTable(matches , :);
                
                % FilterSCPIcommand ---------------------------------------
                filter = regexpi(cmdHistTable.SCPIcommand, ...
                    obj.FilterSCPIcommand);
                if ~iscell(filter)
                    filter   = {filter};
                end
                matches      = ~cellfun(@isempty, filter);
                cmdHistTable = cmdHistTable(matches , :);
                
                % FilterNumBytes ------------------------------------------
                tableValues = cmdHistTable.NumBytes;
                filter      = obj.FilterNumBytes;
                matches     = tableValues <= max(filter) & ...
                    tableValues >= min(filter);
                % filter table
                cmdHistTable = cmdHistTable(matches, :);
            end
        end
        
        function showmsg = get.ShowMessages(obj)
            % get method of property
            
            % this get method is not needed here; default would be fine
            showmsg = obj.ShowMessages;
        end
        
        function set.ShowMessages(obj, showmsg)
            % set method of property
            
            % without return value (obj = ...) in a handle class
            
            % check input argument
            if ischar(showmsg)
                showmsg = lower(showmsg);
            elseif isscalar(showmsg) && ...
                    (islogical(showmsg) || isnumeric(showmsg))
                showmsg = round(double(showmsg));
            elseif isempty(showmsg)
                % do nothing
                if ~strcmp(obj.ShowMessages, 'none')
                    disp(['VisaIFLogger: Empty parameter value for ' ...
                        'property ''ShowMessages''. Ignore input.']);
                end
                return
            elseif ~strcmp(obj.ShowMessages, 'none')
                disp(['VisaIFLogger: Invalid parameter type for ' ...
                    'property ''ShowMessages''.']);
                return
            end
            
            % convert and set property
            switch showmsg
                case {'none', 0}
                    obj.ShowMessages = 'none';
                case {'few' , 1}
                    obj.ShowMessages = 'few';
                case {'all' , 2}
                    obj.ShowMessages = 'all';
                otherwise
                    if ~strcmp(obj.ShowMessages, 'none')
                        disp(['VisaIFLogger: Invalid parameter value ' ...
                            'for property ''ShowMessages''. ' ...
                            'Ignore input.']);
                    end
            end
        end
        
        % default get methods for these properties are fine => no get.*
        
        function set.AutoSave(obj, autosave)
            % logical, scalar
            
            if ~isscalar(autosave)
                disp('VisaIFLogger: Error - scalar logical expected.');
                return
            end
            
            obj.AutoSave = autosave;
        end
        
        function set.AutoSaveInterval(obj, interval)
            % double, integer, positive, scalar
            
            if ~isscalar(interval)
                disp('VisaIFLogger: Error - scalar integer expected.');
                return
            end
            
            interval = round(interval);
            
            if interval < 1
                disp('VisaIFLogger: Error - positive integer expected.');
                return
            end
            
            if isnan(interval)
                disp('VisaIFLogger: Error - NaN is not allowed.');
                return
            end
            
            obj.AutoSaveInterval = interval;
        end
        
        function set.AutoSaveFileName(obj, fileName)
            % char array, valid path and file with extension .csv
            
            % check if fileName is a valid path
            try
                fileName = char(java.io.File(fileName).toPath);
            catch
                disp('VisaIFLogger: Error - filename is not a valid path.');
                return
            end
            
            % check file extension
            if ~endsWith(fileName, '.csv', 'IgnoreCase', true)
                disp('VisaIFLogger: Error - invalid file extension.');
                return
            end
            obj.AutoSaveFileName = fileName;
        end
        
        function set.Filter(obj, filter)
            % logical, scalar
            
            if ~isscalar(filter)
                disp('VisaIFLogger: Error - scalar logical expected.');
                return
            end
            
            obj.Filter = filter;
        end
        
        function set.FilterLine(obj, lines)
            % double, numel = 2, integers, both >= 1 or both < 1,
            % in ascending order or equal
            
            if numel(lines) ~= 2
                disp('VisaIFLogger: Error - array of 2 integers expected.');
                return
            end
            
            lines = round(lines);
            
            if lines(1) > lines(2)
                disp('VisaIFLogger: Error - descending order is not allowed.');
                return
            end
            
            if any(isnan(lines))
                disp('VisaIFLogger: Error - NaN is not allowed.');
                return
            end
            
            if min(lines) < 1 && max(lines) >= 1
                disp('VisaIFLogger: Error - invalid range.');
                return
            end
            
            obj.FilterLine = lines;
        end
        
        function set.FilterCmdID(obj, lines)
            % double, numel = 2, integers, both >= 1 or both < 1,
            % in ascending order or equal
            
            if numel(lines) ~= 2
                disp('VisaIFLogger: Error - array of 2 integers expected.');
                return
            end
            
            lines = round(lines);
            
            if lines(1) > lines(2)
                disp('VisaIFLogger: Error - descending order is not allowed.');
                return
            end
            
            if any(isnan(lines))
                disp('VisaIFLogger: Error - NaN is not allowed.');
                return
            end
            
            if min(lines) < 1 && max(lines) >= 1
                disp('VisaIFLogger: Error - invalid range.');
                return
            end
            
            obj.FilterCmdID = lines;
        end
        
        function set.FilterDevice(obj, device)
            % char array, regexp
            
            if ~isvector(device)
                disp('VisaIFLogger: Error - string scalar expected.');
                return
            end
            
            obj.FilterDevice = device;
        end
        
        function set.FilterMode(obj, mode)
            % char array, regexp
            
            if ~isvector(mode)
                disp('VisaIFLogger: Error - string scalar expected.');
                return
            end
            
            obj.FilterMode = mode;
        end
        
        function set.FilterSCPIcommand(obj, command)
            % char array, regexp
            
            if ~isvector(command)
                disp('VisaIFLogger: Error - string scalar expected.');
                return
            end
            
            obj.FilterSCPIcommand = command;
        end
        
        function set.FilterNumBytes(obj, numBytes)
            % double, numel = 2, integers, both >= 1,
            % in ascending order or equal
            
            if numel(numBytes) ~= 2
                disp('VisaIFLogger: Error - array of 2 integers expected.');
                return
            end
            
            numBytes = round(numBytes);
            
            if numBytes(1) > numBytes(2)
                disp('VisaIFLogger: Error - descending order is not allowed.');
                return
            end
            
            if any(isnan(numBytes))
                disp('VisaIFLogger: Error - NaN is not allowed.');
                return
            end
            
            if min(numBytes) < 1
                disp('VisaIFLogger: Error - invalid range.');
                return
            end
            
            obj.FilterNumBytes = numBytes;
        end
        
    end
end
