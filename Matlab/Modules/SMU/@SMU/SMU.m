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
% ATTENTION: While there are IVI-C classes with a proposed general command
% structure for devices such as Scope, Signal Generator and DMMs (which
% were used as inspiration for the Scope and FGen classes), there is no
% such IVI-C class for SMU. This SMU class is therefore very much tailored
% to the Keithley 2450 SMU measument device (further packages can possibly
% be created for 2460, 2470). Other SMU (Keysight B29xx, Rohde&Schwarz
% NGU4xx) will most probably have a different operating concept.
%
% All public properties and methods from superclass 'VisaIF' can also
% be used. See 'VisaIF.doc' for details (min. VisaIFVersion 3.0.2).
%
% Use 'SMU.doc' or 'doc SMU' for help page.
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
%   - outputEnable     : enable the SMU output
%     * usage:
%           status = mySMU.outputEnable
%     alternatively set property mySMU.OutputState = 1 (or true)
%
%   - outputDisable    : disable the SMU output
%     * usage:
%           status = mySMU.outputDisable
%     alternatively set property mySMU.OutputState = 0 (or false)
%
%   - outputTone       : emit a tone
%     * usage:
%           status = mySMU.outputTone(varargin)
%       with varargin: pairs of parameters NAME = VALUE
%          'frequency' : frequency of the beep (in Hz)
%                        range: 20 ... 8e3
%                        optional parameter, default: 440 (440 Hz)
%          'duration'  : length of tone (in s)
%                        range: 1e-3 ... 1e2
%                        optional parameter, default: 1 (1 s)
%
%   - restartTrigger   : set the instrument into local control and start
%                        continuous measurements, aborts any running any
%                        trigger models ==> any following remote control
%                        command overwrites this command again
%     * usage:
%           status = mySMU.restartTrigger
%
%   - configureDisplay : configure SMU display
%     * usage:
%           status = mySMU.configureDisplay(varargin)
%       with varargin: pairs of parameters NAME = VALUE
%             'screen' : char to select displayed screen
%                        'clear' to delete user defined text ('text')
%                        'help' to print out list of screen options
%                        'home' to select home screen ...
%             'digits' : determines the number of digits that are displayed
%             'brightness': scalar double to adjust brightness (-1 ... 100)
%             'buffer' : determines which buffer is used for measurements
%                        that are displayed
%             'text'   : text string to print out at SMU display
%                        'ABC'     for single line
%                        'ABC;abc' for dual line with ';' as delimiter
%                        use either 'X;Y', {'X', 'Y'} or ["X", "Y"]
%
%
%
%
%
% ToDo
%
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
%
%
%
%
%
%
%
%
%
%
%
%
% additional properties of class 'SMU':
%   - with read access only
%     * SMUVersion         : version of this class file (char)
%     * SMUDate            : release date of this class file (char)
%     * MacrosVersion      : version of support package class (char)
%     * MacrosDate         : release date of support package class (char)
%     * AvailableBuffers   : list of available reading buffers
%     * OverVoltageProtectionTripped : OVP active (1 = 'on' or 0 = 'off')
%     * TriggerState       : 'idle', 'running', 'aborted' ...
%     * ErrorMessages      : table with event log buffer
%                    .Time      time when the event occurred ('datetime')
%                    .Code      event code                     ('double')
%                    .Type      error, warning or information  ('string')
%                    .Description event message                ('string')
%   - with read/write access (numeric values as 'double')
%     * OutputState                : output state (1 = 'on' or 0 = 'off')
%     * LimitCurrentValue          : safety limit, max current in A
%     * LimitVoltageValue          : safety limit, max voltage in V
%     * OverVoltageProtectionLevel : max. source output in V (coerced)


% method refreshAutoZero ':Sense:Azero:Once' When autozero is set to off,
% the instrument may gradually drift out of specification. To minimize the
% drift, you can send the once command to make a reference and zero
% measurement immediately before a test sequence.

% SenseFunction   measurement function
%                 either 'current = I' or 'voltage = V'
% SenseUnit       either Ohm/Watt/Amp for SenseI or Ohm/Watt/Volt for SenseV
% SenseCount
% SenseRSense     either 0/false for off/2-wire or 1/true for on/4-wire
% SenseAutoRange++ ==> configureAutoRange??
% SenseOffsetCompensated only applied to resistance measurements
%                 (unit = Ohm)
% SenseAutoZero
% SenseNPLC
% SenseAverage++ ==> configureAverage??
%
% SourceFunction
% SourceAutoRange++ ==> configureAutoRange??
% SourceReadback
% LimitVoltageTripped
% LimitCurrentTripped


%
% ---------------------------------------------------------------------
% example for usage of class 'SMU': assuming Keithley 2450
%
%   SMU.listContentOfConfigFiles;   % list all known devices
%   mySMU = SMU('Keithley-2450');   % create object and open interface
%
%   disp(['Version of SMU class   : ' mySMU.SMUVersion]);
%   disp(['Version of VisaIF class: ' mySMU.VisaIFVersion]);
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
%   - no severe bugs reported (version 1.0.0) ==> winter term 2025/26
%
% development, support and contact:
%   - ShanShan Chan (student, E124b Information and Electronics)
%   - Matthias Henker (professor)
% -------------------------------------------------------------------------

classdef SMU < VisaIF
    properties(Constant = true)
        SMUVersion    = '0.9.0';      % updated release version
        SMUDate       = '2025-07-21'; % updated release date
    end

    properties(SetAccess = private, GetAccess = public)
        MacrosVersion                char
        MacrosDate                   char
        ErrorMessages                table = table(Size= [0, 4], ...
            VariableNames= {'Time'    , 'Code'  , 'Type'  , 'Description'}, ...
            VariableTypes= {'datetime', 'double', 'string', 'string'});
    end

    properties(Dependent, SetAccess = private, GetAccess = public)
        AvailableBuffers             cell
        OverVoltageProtectionTripped double
        TriggerState                 char
    end

    properties(Dependent)
        OutputState                  double  % 0, false for 'off' ...
        OverVoltageProtectionLevel   double  % in V, scalar, positive
        LimitVoltageValue            double  % in V
        LimitCurrentValue            double  % in A
    end

    properties(SetAccess = private, GetAccess = private)
        MacrosObj       % handle to actual device-specific macro class
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

    % ---------------------------------------------------------------------
    methods(Static, Access = private)

        outVars = checkParams(inVars, command, showmsg)

    end

    % ------- public methods -----------------------------------------------
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
        % additional methods for SMU
        % -----------------------------------------------------------------

        function status = clear(obj)
            % clear status at SMU
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  clear status');
            end

            % execute device specific macro
            status = obj.MacrosObj.clear;

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  clear failed');
            end
        end

        function status = lock(obj)
            % lock all buttons at SMU
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  lock all buttons at SMU');
            end

            % execute device specific macro
            status = obj.MacrosObj.lock;

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  lock failed');
            end
        end

        function status = unlock(obj)
            % unlock all buttons at SMU
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  unlock all buttons at SMU');
            end

            % execute device specific macro
            status = obj.MacrosObj.unlock;

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  unlock failed');
            end
        end

        function status = outputEnable(obj)
            % Enable SMU output
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  enable output');
            end

            % Execute device-specific macro
            status = obj.MacrosObj.outputEnable;

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
            status = obj.MacrosObj.outputDisable;

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  outputDisable failed');
            end
        end

        function status = outputTone(obj, varargin)
            % beeper of the instrument generates an audible signal

            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  generate a tone (default: 1 kHz for 1 s)');
                params = obj.checkParams(varargin, 'outputTone', true);
            else
                params = obj.checkParams(varargin, 'outputTone');
            end

            % Execute device-specific macro
            status = obj.MacrosObj.outputTone(params{:});

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  outputTone failed');
            end
        end

        function status = restartTrigger(obj)
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  restart trigger (continuous measurements)');
            end

            % Execute device-specific macro
            status = obj.MacrosObj.restartTrigger;

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  restartTrigger failed');
            end
        end

        function status = configureDisplay(obj, varargin)
            % configureDisplay : configure display

            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  configure SMU display');
                params = obj.checkParams(varargin, 'configureDisplay', true);
            else
                params = obj.checkParams(varargin, 'configureDisplay');
            end

            % execute device specific macro
            status = obj.MacrosObj.configureDisplay(params{:});

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  configureDisplay failed');
            end
        end





        function status = configureSenseMode(obj, varargin)
            % Configure sense mode (2-wire or 4-wire)
            % Expected varargin: 'function', 'mode'

            % if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
            %     disp([obj.DeviceID ': Configuring source parameters']);
            % end

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

            % if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
            %     disp([obj.DeviceID ': Configuring measurement parameters']);
            % end

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

            % if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
            %     disp([obj.DeviceID ': Performing measurement']);
            % end

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
        % get methods for dependent properties (read only)

        function buffers = get.AvailableBuffers(obj)
            % get list of available reading buffers:
            %  cell array of char with reading buffers

            buffers = obj.MacrosObj.AvailableBuffers;

            % optionally display results
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp(['  buffers = ' char(join(buffers, ', '))]);
            end
        end

        function OVPState = get.OverVoltageProtectionTripped(obj)
            % get OVP state:
            %    0 for 'not exceed the OVP limit',
            %    1 for 'overvoltage protection is active, voltage is restricted'
            %  NaN for unknown state (error)

            OVPState = obj.MacrosObj.OverVoltageProtectionTripped;

            % optionally display results
            if ~strcmpi(obj.ShowMessages, 'none')
                switch OVPState
                    case 0
                        OVPStateDisp = 'voltage does not exceed the OVP limit';
                    case 1
                        OVPStateDisp = 'overvoltage protection is active, voltage is restricted';
                    otherwise , OVPStateDisp = 'unknown state (error)';
                end
                disp([obj.DeviceName ':']);
                disp(['  OVP state = ' OVPStateDisp]);
            end
        end

        function TrigState = get.TriggerState(obj)
            % read trigger state

            TrigState = obj.MacrosObj.TriggerState;

            % optionally display results
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp(['  trigger state = ' TrigState]);
            end
        end

        % -----------------------------------------------------------------
        % get/set methods for dependent properties (read/write)

        function limit = get.LimitCurrentValue(obj)
            limit = obj.MacrosObj.LimitCurrentValue;
        end

        function set.LimitCurrentValue(obj, limit)

            % check input argument (already coerced to type double)
            if ~isscalar(limit) || isnan(limit) || ~isreal(limit)
                disp(['SMU: Invalid parameter value for property ' ...
                    '''LimitCurrentValue''.']);
                return
            end

            % set property
            obj.MacrosObj.LimitCurrentValue = limit;
            % readback and verify (max 1% difference)
            limitSet = obj.LimitCurrentValue;
            if abs(limitSet - limit) > 1e-2*limit || isnan(limitSet)
                disp(['SMU: parameter value for property ' ...
                    '''LimitCurrentValue'' was not set properly.']);
                fprintf('  wanted value      : %1.6f A\n', limit);
                fprintf('  actually set value: %1.6f A\n', limitSet);
            end
        end

        function limit = get.LimitVoltageValue(obj)
            limit = obj.MacrosObj.LimitVoltageValue;
        end

        function set.LimitVoltageValue(obj, limit)

            % check input argument (already coerced to type double)
            if ~isscalar(limit) || isnan(limit) || ~isreal(limit)
                disp(['SMU: Invalid parameter value for property ' ...
                    '''LimitVoltageValue''.']);
                return
            end

            % set property
            obj.MacrosObj.LimitVoltageValue = limit;
            % readback and verify (max 1% difference)
            limitSet = obj.LimitVoltageValue;
            if abs(limitSet - limit) > 1e-2*limit || isnan(limitSet)
                disp(['SMU: parameter value for property ' ...
                    '''LimitVoltageValue'' was not set properly.']);
                fprintf('  wanted value      : %3.3f V\n', limit);
                fprintf('  actually set value: %3.3f V\n', limitSet);
            end
        end

        function limit = get.OverVoltageProtectionLevel(obj)
            limit = obj.MacrosObj.OverVoltageProtectionLevel;
        end

        function set.OverVoltageProtectionLevel(obj, limit)

            % check input argument (already coerced to type double)
            if ~isscalar(limit) || isnan(limit) || ~isreal(limit)
                disp(['SMU: Invalid parameter value for property ' ...
                    '''OverVoltageProtectionLevel''.']);
                return
            end

            % set property
            obj.MacrosObj.OverVoltageProtectionLevel = limit;
            % readback and verify
            limitSet = obj.OverVoltageProtectionLevel;
            if limitSet < limit || isnan(limitSet)
                disp(['SMU: parameter value for property ' ...
                    '''OverVoltageProtectionLevel'' was not set properly.']);
                fprintf('  wanted value      : %3.1f V\n', limit);
                fprintf('  actually set value: %3.1f V\n', limitSet);
            end
        end

        function outputState = get.OutputState(obj)
            % get output state:
            %    0 for 'off',
            %    1 for 'on'
            %  NaN for unknown state (error)

            outputState = obj.MacrosObj.OutputState;

            % optionally display results
            if ~strcmpi(obj.ShowMessages, 'none')
                switch outputState
                    case 0    , outputStateDisp = 'off';
                    case 1    , outputStateDisp = 'on';
                    otherwise , outputStateDisp = 'unknown state (error)';
                end
                disp([obj.DeviceName ':']);
                disp(['  output state = ' outputStateDisp]);
            end
        end

        function set.OutputState(obj, param)

            % check input argument (already coerced to type double)
            if ~isscalar(param) || isnan(param) || ~isreal(param)
                disp(['SMU: Invalid parameter value for property ' ...
                    '''OutputState''.']);
                return
            end

            % set property
            param = double(logical(param));
            obj.MacrosObj.OutputState = param;
            % readback and verify
            paramSet = obj.OutputState;
            if (paramSet - param) ~= 0 || isnan(paramSet)
                disp(['SMU: parameter value for property ' ...
                    '''OutputState'' was not set properly.']);
                fprintf('  wanted value      : %d \n', param);
                fprintf('  actually set value: %d \n', paramSet);
            end
        end

        % -----------------------------------------------------------------
        % more get methods

        function errTable = get.ErrorMessages(obj)
            % read error list from the SMU’s error buffer
            % append received events to table (history is saved here)
            obj.ErrorMessages = ...
                [obj.ErrorMessages; obj.MacrosObj.ErrorMessages];
            errTable = obj.ErrorMessages;
        end

        function version = get.MacrosVersion(obj)
            % get method of property (dependent)
            version = obj.MacrosObj.MacrosVersion;
        end

        function date = get.MacrosDate(obj)
            % get method of property (dependent)
            date = obj.MacrosObj.MacrosDate;
        end

    end

end
