% documentation for class 'SMU'
% ---------------------------------------------------------------------
% This class defines common methods for Source Measure Unit (SMU)
% control. This class is a subclass of the superclass 'VisaIF'.
% Type (in command window):
% 'SMU' - to get a full list of accessible SMUs which means that
%         their IP-addresses (for visa-tcpip) or USB-IDs (for visa-usb)
%         are published in config files
% 'SMU.listAvailablePackages' - to get a list of installed SMU packages.
% Your SMU can be controlled by the SMU class when it is accessible and
% a matching support package is installed.
%
% All public properties and methods from superclass 'VisaIF' can also
% be used. See 'VisaIF.doc' for details (min. VisaIFVersion 3.0.2).
%
% Use 'SMU.doc' for this help page.
%
%   - SMU : constructor of subclass (class name)
%     * use this function to create an object for your SMU
%     * same syntax as for VisaIF class ==> see 'doc VisaIF'
%     * default value of showmsg is 'few'
%     * overloads VisaIF
%
% NOTES:
%     * the output parameter 'status' has the same meaning for all
%       listed methods
%           status   : == 0 when okay
%                      != 0 when something went wrong
%     * all parameter names and values (varargin) are NOT case sensitive
%     * varargin are input as pairs NAME = VALUE
%     * any number and order of NAME = VALUE pairs can be specified
%     * not all parameters and values are supported by all SMUs
%     * check for warnings and errors
%
% additional methods (static) of class 'SMU':
%   - listAvailablePackages : print out a list of installed SMU
%                      support packages (macros)
%     * usage:
%           SMU.listAvailablePackages
%
% additional methods (public) of class 'SMU':
%   - clear          : clear status at SMU
%     * send SCPI command '*CLS' to SMU
%     * usage:
%           status = mySMU.clear  or just  mySMU.clear
%
%   - configureSource : configure the source function and parameters
%     * usage:
%           status = mySMU.configureSource(varargin)
%       with varargin: pairs of parameters NAME = VALUE
%           'function' : 'voltage' or 'current'
%           'level'    : source level in volts or amps (numeric)
%           'limit'    : compliance limit (current for voltage source,
%                        voltage for current source, numeric)
%           'range'    : measurement range (e.g., 'auto', '100mV', '1A')
%
%   - configureMeasure : configure the measurement function
%     * usage:
%           status = mySMU.configureMeasure(varargin)
%       with varargin: pairs of parameters NAME = VALUE
%           'function' : 'voltage', 'current', or 'resistance'
%           'range'    : measurement range (e.g., 'auto', '100mV', '1A')
%           'nplc'     : number of power line cycles (e.g., 0.01 to 10)
%
%   - outputEnable     : enable the SMU output
%     * usage:
%           status = mySMU.outputEnable
%
%   - outputDisable    : disable the SMU output
%     * usage:
%           status = mySMU.outputDisable
%
%   - measure          : perform a measurement
%     * usage:
%           result = mySMU.measure(varargin)
%       with output
%           result.status : status = 0 for okay, -1 for error
%           result.value  : measured value (double)
%           result.unit   : unit of measurement ('V', 'A', 'Ohm')
%           result.function : measurement function ('voltage',
%                           'current', 'resistance')
%
% additional properties of class 'SMU':
%   - with read access only
%     * SMUVersion    : version of this class file (char)
%     * SMUDate       : release date of this class file (char)
%     * MacrosVersion : version of support package class (char)
%     * MacrosDate    : release date of support package class (char)
%     * OutputState   : current output state ('on' or 'off')
%
% ---------------------------------------------------------------------
% example for usage of class 'SMU': assuming Keithley 2450 is listed
% in config file (run 'SMU.listContentOfConfigFiles')
%
%   mySMU = SMU('Keithley-2450'); % create object and open interface
%
%   disp(['Version: ' mySMU.SMUVersion]); % show versions
%   disp(['Version: ' mySMU.VisaIFVersion]);
%
%   mySMU.reset; % reset SMU (optional command)
%
%   mySMU.configureSource( ...
%       function = 'voltage', ...
%       level    = 5, ...
%       limit    = 0.1);
%
%   mySMU.configureMeasure( ...
%       'function', 'current', ...
%       'range', 'auto');
%
%   mySMU.outputEnable;
%   result = mySMU.measure;
%   mySMU.outputDisable;
%
%   mySMU.delete; % close interface and delete object
%
% ---------------------------------------------------------------------
% HTW Dresden, faculty of electrical engineering
%   for version and release date see properties 'SMUVersion' and
%   'SMUDate'
%
% tested with
%   - Matlab                            (2024b update 6 = version 24.2)
%   - Instrument Control Toolbox                         (version 24.2)
%   - Instrument Control Toolbox Support Package for National
%     Instruments VISA and ICP Interfaces                (version 24.2)
%
% known issues and planned extensions / fixes
%   - no severe bugs reported (version 1.0.2) ==> winter term 2025/26
%
% development, support and contact:
%   - ShanShan Chan (student, E124b Information and Electronics)
%   - Matthias Henker (professor)
% ---------------------------------------------------------------------

classdef SMU < VisaIF
    properties(Constant = true)
        SMUVersion    = '1.0.2';      % updated release version
        SMUDate       = '2025-07-09'; % updated release date
    end

    properties(Dependent, SetAccess = private, GetAccess = public)
        MacrosVersion
        MacrosDate
        OutputState
        % ...
        ErrorMessages
    end

    properties(SetAccess = private, GetAccess = private)
        MacrosObj       % access to actual device-specific macros
    end

    % ---------------------------------------------------------------------
    methods(Static)

        varargout = listAvailablePackages

        function doc
            % Open a help window using web-command
            className = mfilename('class');
            VisaIF.doc(className);
        end

    end


    % ToDo
    % ErrorMessages
    % lock, unlock
    % OutputState




    % ---------------------------------------------------------------------
    methods

        function obj = SMU(device, interface, showmsg)
            % constructor for a SMU object (same variables as for VisaIF
            % except for missing last "hidden" parameter instrument)

            % check number of input arguments
            narginchk(0, 3);

            % Set default values
            if nargin < 3 || isempty(showmsg)
                showmsg = 'few';
            end
            if nargin < 2 || isempty(interface)
                interface = '';
            end
            if nargin < 1 || isempty(device)
                device = '';
            end

            % -------------------------------------------------------------
            className  = mfilename('class');

            % create object: inherited from superclass 'VisaIF'
            instrument = className; % see VisaIF.SupportedInstrumentClasses
            obj = obj@VisaIF(device, interface, showmsg, instrument);

            % validate device selection
            if isempty(obj.Device)
                error(['SMU: Initialization failed. No matching SMU ' ...
                    'device found for "%s". ' ...
                    'Run SMU.listContentOfConfigFiles to see ' ...
                    'available devices.'], device);
            end

            % build up path to selected device package directory
            fString = [ ...
                className    '.' ...
                obj.Vendor   '.' ...
                obj.Product  '.' ...
                className 'Macros'];
            fHandle = str2func(fString);

            % create object with actual macros for selected device
            try
                obj.MacrosObj = fHandle(obj);
                clear fHandle;
            catch %#ok<CTCH>
                error('No support package available for: %s', fString);
            end

            % execute device specific macros after opening connection
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  execute post-open macro');
            end
            if obj.MacrosObj.runAfterOpen
                error('Initial configuration of SMU failed.');
            end
        end

        function delete(obj)
            % destructor

            % execute device specific macros before closing connection
            if ~strcmpi(obj.ShowMessages, 'none') && ~isempty(obj.DeviceName)
                disp([obj.DeviceName ':']);
                disp('  execute pre-close macro');
            end

            % only run delete when object exists
            if ~isempty(obj.MacrosObj)
                if obj.MacrosObj.runBeforeClose
                    error('Reconfiguration of SMU before closing connecting failed.');
                end
                % delete MacroObj
                obj.MacrosObj.delete;
            end

            % regular deletion of this class object follows now
        end

        % -----------------------------------------------------------------
        % Extend some methods from superclass (VisaIF)
        % -----------------------------------------------------------------

        function status = reset(obj)
            % override reset method (inherited from superclass VisaIF)
            % restore default settings at SMU

            % init output
            status = NaN;

            % do not execute "standard" reset method from super class
            % reset@VisaIF(obj)

            % optionally clear buffers (for visa-usb only)
            obj.clrdevice;

            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  execute reset macro');
            end

            % execute device specific macros for reset
            if obj.MacrosObj.reset
                status = -1;
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  reset failed');
            end
        end

        % -----------------------------------------------------------------
        % actual SMU methods: actions without input parameters
        % -----------------------------------------------------------------

        function status = clear(obj)
            % Clear status at SMU
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  clear status');
            end

            % Execute device-specific macro
            try
                status = obj.MacrosObj.clear;
                if ~isscalar(status)
                    error('SMU: clear macro returned non-scalar status.');
                end
            catch ME
                error('SMU: clear macro failed: %s', ME.message);
            end

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  clear failed');
            end
        end

        function status = outputEnable(obj)
            % Enable SMU output
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  enable output');
            end

            % Execute device-specific macro
            try
                status = obj.MacrosObj.outputEnable;
                if ~isscalar(status)
                    error('SMU: outputEnable macro returned non-scalar status.');
                end
            catch ME
                error('SMU: outputEnable macro failed: %s', ME.message);
            end

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  outputEnable failed');
            end
        end

        function status = outputDisable(obj)
            % Disable SMU output
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  disable output');
            end

            % Execute device-specific macro
            try
                status = obj.MacrosObj.outputDisable;
                if ~isscalar(status)
                    error('SMU: outputDisable macro returned non-scalar status.');
                end
            catch ME
                error('SMU: outputDisable macro failed: %s', ME.message);
            end

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  outputDisable failed');
            end
        end

        % -----------------------------------------------------------------
        % Actual SMU methods: actions with varargin parameters
        % -----------------------------------------------------------------

        function status = configureSenseMode(obj, varargin)
            % Configure sense mode (2-wire or 4-wire)
            % Expected varargin: 'function', 'mode'
            status = obj.MacrosObj.configureSenseMode(varargin{:});
        end

        function status = configureSource(obj, varargin)
            % Configure source function and parameters
            %   'function' : 'voltage' or 'current'
            %   'level'    : source level in volts or amps
            %   'limit'    : compliance limit
            %   'range'    : measurement range

            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  configure source parameters');
                params = obj.checkParams(varargin, 'configureSource', true);
            else
                params = obj.checkParams(varargin, 'configureSource');
            end

            % Execute device-specific macro
            try
                status = obj.MacrosObj.configureSource(params{:});
                if ~isscalar(status)
                    error('SMU: configureSource macro returned non-scalar status.');
                end
            catch ME
                error('SMU: configureSource macro failed: %s', ME.message);
            end

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  configureSource failed');
            end
        end

        function status = configureMeasure(obj, varargin)
            % Configure measurement function
            %   'function' : 'voltage', 'current', or 'resistance'
            %   'range'    : measurement range
            %   'nplc'     : number of power line cycles

            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  configure measurement parameters');
                params = obj.checkParams(varargin, 'configureMeasure', true);
            else
                params = obj.checkParams(varargin, 'configureMeasure');
            end

            % Execute device-specific macro
            try
                status = obj.MacrosObj.configureMeasure(params{:});
                if ~isscalar(status)
                    error('SMU: configureMeasure macro returned non-scalar status.');
                end
            catch ME
                error('SMU: configureMeasure macro failed: %s', ME.message);
            end

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  configureMeasure failed');
            end
        end

        function meas = measure(obj, varargin)
            % Perform a measurement
            % Outputs:
            %   meas.status
            %   meas.value
            %   meas.unit
            %   meas.function

            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  perform measurement');
                params = obj.checkParams(varargin, 'measure', true);
            else
                params = obj.checkParams(varargin, 'measure');
            end

            % Execute device-specific macro
            try
                meas = obj.MacrosObj.measure(params{:});
                if ~isstruct(meas) || ~all(isfield(meas, {'status', 'value', 'unit', 'function'}))
                    error('SMU: measure macro returned invalid output structure.');
                end
                if ~isscalar(meas.status)
                    error('SMU: measure macro returned non-scalar status.');
                end
            catch ME
                error('SMU: measure macro failed: %s', ME.message);
            end

            if ~strcmpi(obj.ShowMessages, 'none') && meas.status ~= 0
                disp('  measure failed');
            end
        end

        function [voltages, currents] = VoltageLinearSweep(obj, start, stop, numPoints, delay)
            % Perform a linear sweep, delegated to device-specific macros
            % Inputs:
            %   start - Starting voltage (V)
            %   stop - Stopping voltage (V)
            %   steps - Number of steps (including start and stop)
            %   delay - Delay between steps
            % Outputs:
            %   voltages - Array of applied voltages (V)
            %   currents - Array of measured currents (A)

            voltages = [];
            currents = [];
            try
                if ~strcmpi(obj.ShowMessages, 'none')
                    disp([obj.DeviceName ': Starting Linear Sweep']);
                end
                [voltages, currents] = obj.MacrosObj.VoltageLinearSweep(start, stop, numPoints, delay);
            catch ME
                if ~strcmpi(obj.ShowMessages, 'none')
                    disp(['Error in VoltageLinearSweep: ' ME.message]);
                end
            end
        end

        function [currents, voltages] = CurrentLinearSweep(obj, start, stop, step, delay)
            % Perform a linear current sweep for V-I characterization
            % Inputs:
            %   start - Starting current (A)
            %   stop - Stopping current (A)
            %   step - Step size (A)
            %   delay - Delay per step (s)
            %   vlimit - Voltage limit (V)
            % Outputs:
            %   currents - Array of applied currents (A)
            %   voltages - Array of measured voltages (V)

            % currents = [];
            % voltages = [];
            try
                if ~strcmpi(obj.ShowMessages, 'none')
                    disp([obj.DeviceName ': Starting Current Linear Sweep']);
                end
                [currents, voltages] = obj.MacrosObj.CurrentLinearSweep(start, stop, step, delay);
            catch ME
                if ~strcmpi(obj.ShowMessages, 'none')
                    disp(['Error in CurrentLinearSweep: ' ME.message]);
                end
                rethrow(ME);
            end
        end

        % -----------------------------------------------------------------
        % Actual SMU methods: get methods (dependent)
        % -----------------------------------------------------------------

        function outputState = get.OutputState(obj)
            % Get output state
            %   'on' or 'off'
            try
                if ~isprop(obj.MacrosObj, 'OutputState')
                    error('SMU: MacrosObj does not define OutputState property.');
                end
                outputState = obj.MacrosObj.OutputState;
                if ~ischar(outputState) && ~isstring(outputState)
                    error('SMU: Invalid OutputState type returned by MacrosObj.');
                end
            catch ME
                error('SMU: Failed to get OutputState: %s', ME.message);
            end

            % Optionally display results
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp(['  output state = ' outputState]);
            end
        end

        function version = get.MacrosVersion(obj)
            % Get method of property (dependent)
            try
                if ~isprop(obj.MacrosObj, 'MacrosVersion')
                    error('SMU: MacrosObj does not define MacrosVersion property.');
                end
                version = obj.MacrosObj.MacrosVersion;
                if ~ischar(version) && ~isstring(version)
                    error('SMU: Invalid MacrosVersion type returned by MacrosObj.');
                end
            catch ME
                error('SMU: Failed to get MacrosVersion: %s', ME.message);
            end
        end

        function date = get.MacrosDate(obj)
            % Get method of property (dependent)
            try
                if ~isprop(obj.MacrosObj, 'MacrosDate')
                    error('SMU: MacrosObj does not define MacrosDate property.');
                end
                date = obj.MacrosObj.MacrosDate;
                if ~ischar(date) && ~isstring(date)
                    error('SMU: Invalid MacrosDate type returned by MacrosObj.');
                end
            catch ME
                error('SMU: Failed to get MacrosDate: %s', ME.message);
            end
        end

    end

    % ---------------------------------------------------------------------
    methods(Static, Access = private)

        function outVars = checkParams(inVars, command, showmsg)
            % Check input parameters for SMU methods
            % Extend the checkParams to include SMU-specific parameters

            narginchk(1, 3);
            if nargin < 3
                showmsg = false;
            end
            if nargin < 2 || isempty(command)
                command = '';
            end

            % Validate even number of inputs (NAME=VALUE pairs)
            if mod(length(inVars), 2) ~= 0
                error('SMU: checkParams requires an even number of inputs (NAME=VALUE pairs).');
            end

            % Initialize all parameter values (empty)
            func = ''; % configureSource, configureMeasure
            level = ''; % configureSource
            limit = ''; % configureSource
            range = ''; % configureSource, configureMeasure
            nplc = ''; % configureMeasure

            % Assign parameter values
            for nArgsIn = 2:2:length(inVars)
                paramName = inVars{nArgsIn-1};
                paramValue = inVars{nArgsIn};
                if iscellstr(paramName) || isstring(paramName)
                    paramName = char(strjoin(paramName, ''));
                end
                if ischar(paramName) || isStringScalar(paramName)
                    % Validate parameter value type
                    if ~isvector(paramValue)
                        paramValue = '';
                        disp(['SMU: Invalid type of ''' paramName '''. Ignore input.']);
                    elseif ischar(paramValue)
                        paramValue = upper(paramValue);
                    elseif iscellstr(paramValue) || isstring(paramValue)
                        paramValue = upper(char(strjoin(paramValue, ', ')));
                    elseif isa(paramValue, 'double') && isscalar(paramValue)
                        paramValue = num2str(paramValue, 10);
                    else
                        paramValue = '';
                        disp(['SMU: Invalid type of ''' paramName '''. Ignore input.']);
                    end

                    switch lower(char(paramName))
                        case {'function', 'func'}
                            if ~isempty(regexp(paramValue, '^(VOLTAGE|CURRENT|RESISTANCE)$', 'once'))
                                func = paramValue;
                            else
                                disp(['SMU: Invalid function value ''' paramValue '''. Ignore input.']);
                            end
                        case {'level', 'lvl'}
                            if ~isempty(regexp(paramValue, '^[\d\.\+\-eE]+$', 'once')) && ~isnan(str2double(paramValue))
                                level = paramValue;
                            else
                                disp(['SMU: Invalid level value ''' paramValue '''. Must be numeric. Ignore input.']);
                            end
                        case {'limit', 'lim'}
                            if ~isempty(regexp(paramValue, '^[\d\.\+\-eE]+$', 'once')) && ~isnan(str2double(paramValue))
                                limit = paramValue;
                            else
                                disp(['SMU: Invalid limit value ''' paramValue '''. Must be numeric. Ignore input.']);
                            end
                        case {'range', 'rng'}
                            if ~isempty(regexp(paramValue, '^(AUTO|[\d\.\+\-eEmMuUkK]+)$', 'once'))
                                range = paramValue;
                            else
                                disp(['SMU: Invalid range value ''' paramValue '''. Ignore input.']);
                            end
                        case {'nplc'}
                            if ~isempty(regexp(paramValue, '^[\d\.\+\-eE]+$', 'once')) && ~isnan(str2double(paramValue))
                                nplc = paramValue;
                            else
                                disp(['SMU: Invalid nplc value ''' paramValue '''. Must be numeric. Ignore input.']);
                            end
                        otherwise
                            disp(['SMU: Warning - Parameter name ''' paramName ''' is unknown. Ignore parameter.']);
                    end
                else
                    disp('SMU: Parameter names have to be character arrays. Ignore input.');
                end
            end

            % Copy command-relevant parameters
            switch command
                case 'configureSource'
                    outVars = { ...
                        'function', func, ...
                        'level', level, ...
                        'limit', limit, ...
                        'range', range };
                case 'configureMeasure'
                    outVars = { ...
                        'function', func, ...
                        'range', range, ...
                        'nplc', nplc };
                case 'measure'
                    outVars = {};
                otherwise
                    allVars = { ...
                        'function', func, ...
                        'level', level, ...
                        'limit', limit, ...
                        'range', range, ...
                        'nplc', nplc };
                    outVars = cell(0);
                    idx = 1;
                    for cnt = 1:2:length(allVars)
                        if ~isempty(allVars{cnt+1})
                            outVars{idx} = allVars{cnt};
                            outVars{idx+1} = allVars{cnt+1};
                            idx = idx + 2;
                        end
                    end
            end

            if showmsg
                for cnt = 1:2:length(outVars)
                    if ~isempty(outVars{cnt+1})
                        disp(['  - ' pad(outVars{cnt}, 13) ': ' outVars{cnt+1}]);
                    end
                end
            end
        end

    end
end

