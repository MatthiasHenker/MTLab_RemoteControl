% documentation for class 'SMU24xx'
% ---------------------------------------------------------------------
% This class defines specific methods for Source Measure Unit (SMU 2450 by
% Keithley) control. This class is a subclass of the superclass 'VisaIF'.
% Type (in command window):
% 'SMU24xx' - to get a full list of accessible SMUs which means that
%         their IP-addresses (for visa-tcpip) or USB-IDs (for visa-usb)
%         are published in config files
%
% ATTENTION: While there are IVI-C classes with a proposed general command
% structure for devices such as Scope, Signal Generator and DMMs (which
% were used as inspiration for the Scope and FGen classes), there is no
% such IVI-C class for SMU. This SMU class is therefore very much tailored
% to the Keithley 2450 SMU measurement device. Other SMU (Keysight B29xx,
% Rohde&Schwarz NGU4xx) will most probably have a different operating concept.
%
% All public properties and methods from superclass 'VisaIF' can also
% be used. See 'VisaIF.doc' for details (min. VisaIFVersion 3.0.2).
%
% Use 'SMU24xx.doc' or 'doc SMU24xx' for help page.
%
%   - SMU24xx : constructor of subclass (class name)
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
% methods (static) of class 'SMU24xx':
%   - doc            : open window with this help text
%
% methods (public) of class 'SMU24xx':
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
%                        optional parameter, default: 1e3 (1 kHz)
%          'duration'  : length of tone (in s)
%                        range: 1e-3 ... 1e2
%                        optional parameter, default: 1 (1 s)
%
%   - restartTrigger   : set the instrument into local control and start
%                        continuous measurements, aborts any running trigger
%                        models ==> any following remote control command
%                        stops continuous measurements again
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
%    showSettings
%
%
%
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
%     * AvailableBuffers   : list of available reading buffers
%     * OverVoltageProtectionTripped : OVP active (1 = 'on' or 0 = 'off')
%     * TriggerState       : 'idle', 'running', 'aborted' ...
%     * ErrorMessages      : table with event log buffer
%                    .Time      time when the event occurred ('datetime')
%                    .Code      event code                     ('double')
%                    .Type      error, warning or information  ('string')
%                    .Description event message                ('string')
%
%   - with read/write access (numeric values as 'double')
%     * OutputState                : output state (1 = 'on' or 0 = 'off')


% method refreshAutoZero ':Sense:Azero:Once' When autozero is set to off,
% the instrument may gradually drift out of specification. To minimize the
% drift, you can send the once command to make a reference and zero
% measurement immediately before a test sequence.

% SenseMode       measurement function
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

% InterlockState
% InterlockTripped  read-only

% SorceParameters
%     * LimitValue        : safety limit, max current in A or max voltage in V
%     * OVProtectionValue : max. source output in V (coerced)



%
% ---------------------------------------------------------------------
% example for usage of class 'SMU24xx': (Keithley 24xx has to be listed in
% config file)
%
%   SMU24xx.listContentOfConfigFiles; % list all known devices
%   mySMU = SMU24xx('2450');      % create object and open interface
%
%   disp(['Version of SMU class   : ' mySMU.SMUVersion]);
%   disp(['Version of VisaIF class: ' mySMU.VisaIFVersion]);
%
%   mySMU.reset; % reset SMU (optional command)
%
% ToDo
%   mySMU.outputEnable;
%
%   mySMU.outputDisable;
%
%   mySMU.delete;                     % close interface and delete object
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

classdef SMU24xx < VisaIF
    properties(Constant = true)
        SMUVersion    = '0.9.0';      % updated release version
        SMUDate       = '2025-07-28'; % updated release date
    end

    properties(Dependent, SetAccess = private, GetAccess = public)
        TriggerState                 char
    end

    properties(Dependent)
        OutputState                  double  % 0, false for 'off' ...
        OperationMode       % get: categorical; set: char, string or categorical
        SourceParameters             struct
    end

    properties(SetAccess = private, GetAccess = public)
        ErrorMessages                table = table(Size= [0, 4], ...
            VariableNames= {'Time'    , 'Code'  , 'Type'  , 'Description'}, ...
            VariableTypes= {'datetime', 'double', 'string', 'string'});
        AvailableBuffers             cell  = {''};
    end

    % ---------------------------------------------------------------------
    properties(SetAccess = private, GetAccess = private)
        SourceMode                 char
        SenseMode                  char
    end

    properties(Constant = true, GetAccess = private)
        DefaultOperationMode       = categorical({'SVMI'}, ...
            {'SVMI', 'Source:V_Sense:I',  ...
            'SIMV', 'Source:I_Sense:V'});
        %
        DefaultSourceParameters    = struct( ...
            OutputValue         = 0    , ...
            Readback            = true , ...
            Range               = 0    , ...
            AutoRange           = true , ...
            LimitValue          = 0    , ...
            LimitTripped        = []   , ... % read-only
            OVProtectionValue   = 0    , ...
            OVProtectionTripped = []   , ... % read-only
            Delay               = 0    , ...
            AutoDelay           = true , ...
            HighCapMode         = false);
        %
        DefaultBuffers             = {'defbuffer1', 'defbuffer2'};
        DefaultOutputToneFrequency = 1e3; % 1 kHz
        DefaultOutputToneDuration  = 1;   % 1 s
    end

    % ---------------------------------------------------------------------
    methods(Static)

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

        function obj = SMU24xx(device, interface, showmsg)
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
                error(['SMU24xx: Initialization failed. No matching SMU ' ...
                    'device found for "%s". ' ...
                    'Run SMU24xx.listContentOfConfigFiles to see ' ...
                    'available devices.'], device);
            elseif ~strcmpi(obj.Vendor, 'Keithley') || ...
                    ~strcmpi(obj.Product, 'Model2450')
                % for this SMU24xx class were no packages created
                % ==> single class with very specific macros for Keithley 2450
                %
                % check selection
                % ==> for future use: extend this section to load different
                % internal parameters for different models: 2450, 2460,
                % 2461, 2470
                disp(['Vendor  = ' obj.Vendor]);
                disp(['Product = ' obj.Product]);
                error(['SMU24xx: Initialization failed. Currently only ' ...
                    'Vendor = Keithley, Product = Model2450 is supported.'])
            else
                % initialize property 'AvailableBuffers'
                obj.resetBuffer;
            end

            % execute device specific macros after opening connection
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  execute macro-after-opening');
            end
            if obj.runAfterOpen
                error('Initial configuration of SMU failed.');
            end
        end

        function delete(obj)
            % destructor

            % execute device specific macros before closing connection
            if ~strcmpi(obj.ShowMessages, 'none') && ~isempty(obj.DeviceName)
                disp([obj.DeviceName ':']);
                disp('  execute macro-before-closing');
            end

            if obj.runBeforeClose
                error('Reconfiguration of SMU before closing connecting failed.');
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

            % use standard reset command (Factory Default)
            if obj.write('*RST')
                status = -1;
            else
                obj.resetBuffer;
            end

            % clear status (event logs and error queue)
            if obj.write('*CLS')
                status = -1;
            end

            % reconfigure device after reset
            % ends up with '*OPC?' already to wait for operation complete
            if obj.runAfterOpen()
                status = -1;
            end

            % wait for operation complete
            %obj.opc;

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

        function status = runAfterOpen(obj)
            % execute some first configuration commands

            % init output
            status = NaN;

            % add some device specific commands:
            %
            % switch off output for safety reasons
            if obj.outputDisable
                status = -1;
            end

            % optionally set some default values
            %obj.OperationMode = obj.DefaultOperationMode;

            % wait for operation complete
            obj.opc;
            % ...

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = runBeforeClose(obj)
            % execute some commands before closing the connection to
            % restore configuration

            % init output
            status = NaN;

            % switch off output for safety reasons
            if obj.write(':OUTP OFF')
                status = -1;
            end

            % ...

            % wait for operation complete
            obj.opc;
            % ...

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = clear(obj)
            % clears the event registers and queues

            % init output
            status = NaN;

            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  clear status');
            end

            if obj.write('*CLS')
                status = -1;
            end

            % wait for operation complete
            obj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  clear failed');
            end
        end

        function status = lock(obj)
            % lock all buttons at SMU
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  lock all buttons at SMU');
                %
                disp(['SMU WARNING - Method ''lock'' is not ' ...
                    'supported for ']);
                disp(['      ' obj.Vendor '/' ...
                    obj.Product ...
                    ' -->  SMU will never be locked ' ...
                    'by remote access']);
            end

            status = 0;

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  lock failed');
            end
        end

        function status = unlock(obj)
            % unlock all buttons at SMU
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  unlock all buttons at SMU');
                %
                disp(['SMU WARNING - Method ''unlock'' is not ' ...
                    'supported for ']);
                disp(['      ' obj.Vendor '/' ...
                    obj.Product ...
                    ' -->  SMU will never be locked ' ...
                    'by remote access']);
            end

            status = 0;

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
            status = NaN; % init

            if obj.write(':OUTP ON')
                status = -1;
            end

            % wait for operation complete
            obj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
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
            status = NaN; % init

            if obj.write(':OUTP OFF')
                status = -1;
            end

            % wait for operation complete
            obj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  outputDisable failed');
            end
        end

        function status = outputTone(obj, varargin)
            % beeper of the instrument generates an audible signal

            defaultFreq     = obj.DefaultOutputToneFrequency;
            defaultDuration = obj.DefaultOutputToneDuration;

            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp(['  generate a tone (default: ' num2str(defaultFreq) ...
                    ' Hz for ' num2str(defaultDuration) ' s)']);
                params = obj.checkParams(varargin, 'outputTone', true);
            else
                params = obj.checkParams(varargin, 'outputTone');
            end

            % init output
            status = NaN;

            for idx = 1:2:length(params)
                paramName  = params{idx};
                paramValue = params{idx+1};
                switch paramName
                    case 'frequency'
                        if ~isempty(paramValue)
                            frequency = str2double(paramValue);
                            if isnan(frequency)
                                frequency = defaultFreq;
                            else
                                % clip to range
                                frequency = min(frequency, 8e3);
                                frequency = max(frequency, 20);
                            end
                        else
                            frequency = defaultFreq;
                        end
                        frequency = num2str(frequency, '%g');
                    case 'duration'
                        if ~isempty(paramValue)
                            duration = str2double(paramValue);
                            if isnan(duration)
                                duration = defaultDuration;
                            else
                                % clip to range
                                duration = min(duration, 1e2);
                                duration = max(duration, 1e-3);
                            end
                        else
                            duration = defaultDuration;
                        end
                        duration = num2str(duration, '%g');
                    otherwise
                        if ~isempty(paramValue)
                            disp(['SMU24xx Warning - ''configureDisplay'' ' ...
                                'parameter ''' paramName ''' is ' ...
                                'unknown --> ignore and continue']);
                        end
                end
            end

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------

            % send command
            obj.write([':System:Beeper ' frequency ',' ...
                duration]);
            % read and verify (not applicable)
            % pause to avoid timeout error while long beep tone
            pause(max(0, (str2double(duration)-1)));

            % wait for operation complete
            obj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  outputTone failed');
            end
        end

        function status = restartTrigger(obj)
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  restart trigger (continuous measurements)');
            end

            status = NaN; % init

            if obj.write(':Trigger:Continuous Restart')
                status = -1;
            else
                % any following command will stop continuous trigger again
                % ==> no readback for verification
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end

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

            % init output
            status = NaN;

            % initialize all supported parameters
            screen     = '';
            digits     = [];
            brightness = [];
            buffer     = '';
            text       = {};

            % init misc
            screenClear = false;
            screenHelp  = false;

            for idx = 1:2:length(params)
                paramName  = params{idx};
                paramValue = params{idx+1};
                switch paramName
                    case 'screen'
                        switch lower(paramValue)
                            case ''
                                screen = '';
                            case 'help'
                                screenHelp  = true;
                            case 'clear'
                                screenClear = true;
                            case 'home'
                                screen = 'home';
                            case {'home_larg', 'home_large_reading'}
                                screen = 'home_large_reading';
                            case {'read', 'reading_table'}
                                screen = 'reading_table';
                            case {'grap', 'graph'}
                                screen = 'graph';
                            case {'hist', 'histogram'}
                                screen = 'histogram';
                            case {'swipe_grap', 'swipe_graph'}
                                screen = 'swipe_graph';
                            case {'swipe_sett', 'swipe_settings'}
                                screen = 'swipe_settings';
                            case {'sour', 'source'}
                                screen = 'source';
                            case {'swipe_stat', 'swipe_statistics'}
                                screen = 'swipe_statistics';
                            case 'swipe_user'
                                screen = 'swipe_user';
                            case {'proc', 'processing'}
                                screen = 'processing';
                            otherwise
                                disp(['SMU24xx Warning - ' ...
                                    '''configureDisplay(screen)'' ' ...
                                    'invalid parameter value ' ...
                                    '--> ignore and continue']);
                        end
                    case 'digits'
                        if ~isempty(paramValue)
                            digits = str2double(paramValue);
                            if isnan(digits)
                                digits = '';
                            else
                                digits = round(digits);
                                digits = min(digits, 6);
                                digits = max(digits, 3);
                                digits = num2str(digits, '%d');
                            end
                        end
                    case 'brightness'
                        if ~isempty(paramValue)
                            brightness = str2double(paramValue);
                            if isnan(brightness)
                                brightness = [];
                            else
                                brightness = round(brightness);
                                brightness = min(brightness, 100);
                                brightness = max(brightness, -1);
                            end
                            % convert to command string (char)
                            if brightness < 0
                                brightness = 'blackout';
                            elseif brightness < 5
                                brightness = 'off';
                            elseif brightness < 30
                                brightness = 'on25';
                            elseif brightness < 55
                                brightness = 'on50';
                            elseif brightness < 80
                                brightness = 'on75';
                            else
                                brightness = 'on100';
                            end
                        end
                    case 'buffer'
                        if ~isempty(paramValue)
                            if obj.isBuffer(paramValue)
                                buffer = paramValue;
                            end
                        end
                    case 'text'
                        % split and copy to cell array of char
                        if ~isempty(paramValue)
                            text = split(paramValue, ';');
                        end
                        % check and limit number of lines
                        % check and limit also length of lines
                        maxNumOfLines = 2;
                        maxLenLine    = [20 32];
                        if length(text) > maxNumOfLines
                            text = text(1:maxNumOfLines);
                        end
                        for cnt = 1 : length(text)
                            if length(text{cnt}) > maxLenLine(cnt)
                                text{cnt} = text{cnt}(1 : ...
                                    maxLenLine(cnt)); %#ok<AGROW>
                            end
                        end
                    otherwise
                        if ~isempty(paramValue)
                            disp(['SMU24xx Warning - ''configureDisplay'' ' ...
                                'parameter ''' paramName ''' is ' ...
                                'unknown --> ignore and continue']);
                        end
                end
            end

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------
            % 'screen'           : char
            if screenHelp
                disp('Help for ''configureDisplay(screen= OPTIONS)''');
                disp('  available OPTIONS are:');
                disp('  ''HOME''              - Home screen');
                disp('  ''HOME_LARGe_reading''- ... with large readings');
                disp('  ''READing_table''     - Reading table');
                disp('  ''GRAPh''             - Graph screen');
                disp('  ''HISTogram''         - Histogram screen');
                disp('  ''SWIPE_GRAPh''       - GRAPH      swipe screen');
                disp('  ''SWIPE_SETTings''    - SETTINGS   swipe screen');
                disp('  ''SOURce''            - SOURCE     swipe screen');
                disp('  ''SWIPE_STATistics''  - STATISTICS swipe screen');
                disp('  ''SWIPE_USER''        - USER       swipe screen');
                disp('  ''PROCessing''        - screen reducing CPU power');
            elseif screenClear
                obj.write(':Display:Clear');
            elseif ~isempty(screen)
                obj.write([':Display:Screen ' screen]);
                % read and verify (not applicable)
            end

            % 'digits'           : char
            if ~isempty(digits)
                % set for all modes: curr, res, volt
                obj.write([':Display:Digits ' digits]);
                % readback and verify
                response = obj.query(':Display:Volt:Digits?');
                response = char(response);
                if ~strcmpi(response, digits)
                    % set command failed
                    disp(['SMU24xx Warning - ''configureDisplay'' ' ...
                        'digits parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % 'brightness'       : char
            if ~isempty(brightness)
                obj.write([':Display:Light:State ' brightness]);
                % readback and verify
                response = obj.query(':Display:Light:State?');
                response = char(response);
                if ~strcmpi(response, brightness)
                    % set command failed
                    disp(['SMU24xx Warning - ''configureDisplay'' ' ...
                        'brightness parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % 'buffer'           : char
            if ~isempty(buffer)
                obj.write([':Display:Buffer:Active "' buffer '"']);
                % readback and verify
                response = obj.query(':Display:Buffer:Active?');
                response = char(response);
                if ~strcmpi(response, buffer)
                    % set command failed
                    disp(['SMU24xx Warning - ''configureDisplay'' ' ...
                        'buffer parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % 'text'             : cell array of char
            if ~isempty(text)
                % select user swipe screen
                obj.write(':Display:Screen swipe_user');
                % show text on screen
                for cnt = 1 : length(text)
                    if ~isempty(text{cnt})
                        cmd = sprintf(':Display:User%d:Text "%s"', ...
                            cnt, text{cnt});
                        obj.write(cmd);
                    end
                end
                % read and verify (not applicable)
            end

            % wait for operation complete
            obj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  configureDisplay failed');
            end
        end




        % ToDo
        function status = showSettings(obj)

            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  show SMU settings');
            end

            % init output
            status = NaN;

            % save state of ShowMessages and set to silent operation
            showMessages     = obj.ShowMessages;
            obj.ShowMessages = 'none';

            % actual code
            operationMode                = obj.OperationMode;
            sourceMode                   = obj.SourceMode;
            senseMode                    = obj.SenseMode;
            sourceParameters             = obj.SourceParameters;
            %
            outputState                  = obj.OutputState;
            triggerState                 = obj.TriggerState;

            disp(['  OperationMode      = ' char(operationMode)]);
            disp(['  SourceMode         = ' char(sourceMode)]);
            disp(['  SenseMode          = ' char(senseMode)]);
            % disp(['  OVP Level          = ' ...
            %     num2str(overVoltageProtectionLevel) ' V']);
            % disp(['  OVP Tripped        = ' num2str(overVoltageProtectionTripped)]);
            disp(['  Source Parameters  : ' '']);
            disp(sourceParameters); % ToDo : with units !!!
            disp(['  Output State       = ' num2str(outputState)]);
            disp(['  Trigger State      = ' triggerState]);


            % ...


            % wait for operation complete
            obj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end

            % restore state of ShowMessages
            obj.ShowMessages = showMessages;

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  showSettings failed');
            end
        end



        % ToDo
        %configureTerminales (front / rear)
        %configureOutput (mode = Normal / HiZ / Zero / Guard
        %                 interlock = On / Off)
        % property InterlockTripped



        % check: readback value is also filtered like sense value?

        %runSweepMeasurement
        % configure sweep (linear, log, list)
        % obj.TriggerState check (= building)
        % :Initiate
        % while loop until done or timeout (:Abort to stop trigger)
        %   :trigger:state?  (running 'running' or 'idle')
        % download data





        % -----------------------------------------------------------------
        % get/set methods for dependent properties (read/write)

        function outputState = get.OutputState(obj)
            % get output state:
            %    0 for 'off',
            %    1 for 'on'
            %  NaN for unknown state (error)

            [outpState, status] = obj.query(':Output:State?');
            %
            if status ~= 0
                outputState = NaN; % unknown state, error
            else
                % remap state
                outpState = lower(char(outpState));
                switch outpState
                    case '0'   , outputState = 0;
                    case '1'   , outputState = 1;
                    otherwise  , outputState = NaN;
                end
            end

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
                disp(['SMU24xx Invalid parameter value for property ' ...
                    '''OutputState''.']);
                return
            end

            % map to on/off
            if logical(param)
                param = 'On';
            else
                param = 'Off';
            end
            % set property
            obj.write([':Output:State ' param]);

            % readback and verify
            paramSet = obj.OutputState;
            if (paramSet - param) ~= 0 || isnan(paramSet)
                disp(['SMU24xx parameter value for property ' ...
                    '''OutputState'' was not set properly.']);
                fprintf('  wanted value      : %d \n', param);
                fprintf('  actually set value: %d \n', paramSet);
            end
        end

        function operationMode = get.OperationMode(obj)
            myCats = categories(obj.DefaultOperationMode);

            % actual get function
            senseMode  = categorical({obj.SenseMode});
            sourceMode = categorical({obj.SourceMode});
            if sourceMode == "voltage" && senseMode == "current"
                operationMode = categorical("Source:V_Sense:I", myCats);
            elseif sourceMode == "current" && senseMode == "voltage"
                operationMode = categorical("Source:I_Sense:V", myCats);
            else
                operationMode = categorical("unknown", myCats);
            end

        end

        function set.OperationMode(obj, operationMode)
            myCats = categories(obj.DefaultOperationMode);

            % check input and convert to categorical
            if iscategorical(operationMode)
                % already fine
            elseif ischar(operationMode)
                operationMode = categorical({operationMode});
            elseif isstring(operationMode)
                operationMode = categorical(operationMode);
            else
                % set to empty
                operationMode = categorical([]);
            end
            % check input: scalar and valid parameter
            if ~isscalar(operationMode)
                % not exact one element: than set to empty
                operationMode = categorical([]);
            elseif ~any(myCats == operationMode)
                % not a valid parameter value : set to empty
                operationMode = categorical([]);
            end
            %
            if isempty(operationMode)
                % optionally display error message (invalid input)
                if ~strcmpi(obj.ShowMessages, 'none')
                    disp([obj.DeviceName ':']);
                    disp('  invalid ''OperationMode'' ignore and continue.');
                    catList = join(myCats, '", "');
                    catList = ['"' catList{1} '"'];
                    disp(['  valid parameter values are: ' catList]);
                end
                % exit
                return
            end

            % actual set function
            if any(myCats(1:2) == operationMode)
                % 'SVMI', 'Source:V_Sense:I'
                obj.SenseMode  = 'Current';
                obj.SourceMode = 'Voltage';
            else
                % 'SIMV', 'Source:I_Sense:V'
                obj.SenseMode  = 'Voltage';
                obj.SourceMode = 'Current';
            end
        end

        % Merging several dependent properties (parameters) into a struct
        % is helpful to keep the overview. But there is also a drawback:
        % A call in Matlab code with
        %   myobj.myproperty   = struct(a = 1, b = 2) : works fine
        %   myobj.myproperty.a = 5;                   : will call get
        %     method to fetch a copy of 'myproperty' struct, then update
        %     field 'a' and finally write all fields in set method again
        %     ==> very annoying
        %       goal (1) is to set only a single field of struct
        %       goal (2) is to keep original behavior when setting a struct
        %
        % solution:
        %   get method: overload subsref  for field assignment
        %   set method: overload subsasgn for field assignment
        %
        % ATTENTION:
        %   behaviour (code) in overloaded subsasgn/subsref methods
        %   should match code in original set/get method of struct to avoid
        %   trouble
        function params = get.SourceParameters(obj)
            % list of all existing parameters (params is a 'struct')
            allFields = fieldnames(obj.DefaultSourceParameters);

            % which function mode?
            funcMode = obj.SourceMode; % 'voltage' or 'current'

            % loop to get parameters sequentially
            for idx = 1 : length(allFields)
                paramName  = allFields{idx};
                switch paramName
                    case 'OutputValue'
                        paramValue = obj.getSourceOutputValue(funcMode);
                    case 'Readback'
                        paramValue = obj.getSourceReadback(funcMode);
                    case 'Range'
                        paramValue = obj.getSourceRange(funcMode);
                    case 'AutoRange'
                        paramValue = obj.getSourceAutoRange(funcMode);
                    case 'LimitValue'
                        paramValue = obj.getSourceLimitValue(funcMode);
                    case 'LimitTripped'
                        paramValue = obj.getSourceLimitTripped(funcMode);
                    case 'OVProtectionValue'
                        paramValue = obj.getSourceOVProtectionValue(funcMode);
                    case 'OVProtectionTripped'
                        paramValue = obj.getSourceOVProtectionTripped(funcMode);
                    case 'Delay'
                        paramValue = obj.getSourceDelay(funcMode);
                    case 'AutoDelay'
                        paramValue = obj.getSourceAutoDelay(funcMode);
                    case 'HighCapMode'
                        paramValue = obj.getSourceHighCapMode(funcMode);
                    otherwise
                        disp(['Error, missing get command in struct ' ...
                            '"SourceParameters"']);
                end
                % copy parameter value to output variable (struct)
                params.(paramName) = paramValue;
            end
        end

        function set.SourceParameters(obj, params)
            % list of all existing parameters (params is a 'struct')
            allFields = fieldnames(obj.DefaultSourceParameters);
            % list of parameters to be set (parameters of input)
            inFields  = allFields(isfield(params, allFields));

            % which function mode?
            funcMode = obj.SourceMode; % 'voltage' or 'current'

            % loop to set parameters sequentially
            for idx = 1 : length(inFields)
                paramName  = inFields{idx};
                paramValue = params.(paramName);
                switch paramName
                    case 'OutputValue'
                        obj.setSourceOutputValue(paramValue, funcMode);
                    case 'Readback'
                        obj.setSourceReadback(paramValue, funcMode);
                    case 'Range'
                        obj.setSourceRange(paramValue, funcMode);
                    case 'AutoRange'
                        obj.setSourceAutoRange(paramValue, funcMode);
                    case 'LimitValue'
                        obj.setSourceLimitValue(paramValue, funcMode);
                    case 'LimitTripped'
                        if ~strcmpi(obj.ShowMessages, 'none')
                            disp(['Parameter ''LimitTripped'' is ' ...
                                'read-only. Ignore and continue.']);
                        end
                    case 'OVProtectionValue'
                        obj.setSourceOVProtectionValue(paramValue, funcMode);
                    case 'OVProtectionTripped'
                        if ~strcmpi(obj.ShowMessages, 'none')
                            disp(['Parameter ''OVProtectionTripped'' is ' ...
                                'read-only. Ignore and continue.']);
                        end
                    case 'Delay'
                        obj.setSourceDelay(paramValue, funcMode);
                    case 'AutoDelay'
                        obj.setSourceAutoDelay(paramValue, funcMode);
                    case 'HighCapMode'
                        obj.setSourceHighCapMode(paramValue, funcMode);
                    otherwise
                        disp(['Error, missing set command in struct ' ...
                            '"SourceParameters"']);
                end
            end
        end

        % -----------------------------------------------------------------
        % overload method that analyze input to detect patterns like
        % value = obj.myproperty.myfield ==> for get methods
        %
        % ToDo: same for subsref

        % overload method that analyze input to detect patterns like
        % obj.myproperty.myfield = value ==> for set methods
        function obj = subsasgn(obj, S, value)
            % Wenn Sie in einer Klasse subsasgn überschreiben, ruft MATLAB diese
            % Methode automatisch auf, sobald eine Subskript- oder Punktzuweisung
            % erfolgt. Dabei übergibt MATLAB als zweiten Eingabeparameter genau
            % die Informationen, die es über die einzelnen Subskriptstufen
            % gesammelt hat – und zwar in S.
            %
            % Aufbau von S: ist ein Array von Strukturen, jede Struktur
            % beschreibt einen Schritt der Indizierung
            % Je nach Art der Subskripte enthält jede S(i) zwei Felder:
            %
            % type: Zeichenkette, z. B.
            %     '.' für Punktzugriff
            %     '()' für runde Klammern
            %     '{}' für geschweifte Klammern
            %
            % subs: der eigentliche Subskriptinhalt
            %     Bei Punktzugriffen der Feldname als String
            %     Bei () oder {} der Index bzw. ein Zellarray der Indizes

            % ToDo

            myproperty = 'SourceParameters';

            if numel(S) >= 2 && strcmp(S(1).type, '.') ...
                    && strcmp(S(1).subs, myproperty) ...
                    && strcmp(S(2).type, '.')

                % Extract the field name and assign into propInternal
                myfield = S(2).subs;
                %obj.propInternal.(myfield) = value;
                switch myfield
                    case 'OutputValue'  , x = value;
                    case 'LimitValue'   , x = value;
                    otherwise           , disp('ToDo');
                end

                disp(value);

                return
            end

            % otherwise, fall back to default behavior
            obj = builtin('subsasgn', obj, S, value);
        end

        % -----------------------------------------------------------------
        % get methods for dependent properties (read-only)

        function buffers = get.AvailableBuffers(obj)
            % get list of available reading buffers:
            %  cell array of char with reading buffers

            buffers = obj.AvailableBuffers;

            % optionally display results
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp(['  buffers = ' char(join(buffers, ', '))]);
            end
        end

        function TrigState = get.TriggerState(obj)
            % read trigger state

            [TrigState, status] = obj.query(':Trigger:State?');
            %
            if status ~= 0
                TrigState = 'read error, unknown state';
            else
                % remap state
                TrigState = lower(char(TrigState));
                tmp = split(TrigState, ';');
                if size(tmp, 1) == 3
                    TrigState = tmp{1};
                else
                    TrigState = 'unexpected format, unknown state';
                end
            end

            % optionally display results
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp(['  trigger state = ' TrigState]);
            end
        end

        % -----------------------------------------------------------------
        % more get methods (public properties, read-only)

        function errTable = get.ErrorMessages(obj)
            % read error list from the SMU's error buffer
            %
            % read all types of events (error, warning, informational)
            % ==> actually read event list from SMU and append received events
            % to an increasing table (to save history of events)

            datetimeFmt = 'yyyy/MM/dd HH:mm:ss.SSS';

            % how many unread events are available?
            numOfEvents = obj.query(':System:Eventlog:Count? All');
            numOfEvents = str2double(char(numOfEvents));
            if isnan(numOfEvents)
                errTable  = table(datetime('now', ...
                    InputFormat= datetimeFmt), NaN, "<missing>", ...
                    "ERROR: Could not read event buffer from SMU!", ...
                    VariableNames= {'Time', 'Code', 'Type', 'Description'});
                return
            else
                % intialize table for events
                eventTable  = table( ...
                    Size=[numOfEvents, 4], ...
                    VariableNames= {'Time', 'Code', 'Type', 'Description'}, ...
                    VariableTypes= {'datetime', 'double', 'string', ...
                    'string'});
            end

            % read events from buffer
            for cnt = 1 : numOfEvents
                eventMsg = obj.query(':System:Eventlog:Next?');
                eventMsg = char(eventMsg);
                % format: 'Code, "Description;Type;Time"'
                if ~isempty(regexpi(eventMsg, '^(|-)\d+,".*;\d;.*"$', 'once'))
                    tmp = split(eventMsg, ',"');
                    eventTable.Code(cnt)        = str2double(tmp{1});
                    tmp = split(tmp{2}(1:end-1), ';');
                    eventTable.Description(cnt) = tmp{1};
                    switch tmp{2}
                        case '0',   eventTable.Type(cnt) = '';
                        case '1',   eventTable.Type(cnt) = 'Error';
                        case '2',   eventTable.Type(cnt) = 'Warning';
                        case '4',   eventTable.Type(cnt) = 'Information';
                        otherwise , eventTable.Type(cnt) = 'unknown';
                    end
                    eventTable.Time(cnt)        = datetime(tmp{3}, ...
                        InputFormat= datetimeFmt);
                else
                    % unexpected pattern of received string
                    eventTable.Time(cnt)        = NaT;
                    eventTable.Code(cnt)        = NaN;
                    eventTable.Type(cnt)        = 'unknown';
                    eventTable.Description(cnt) = 'unexpected response';
                end
            end

            % optionally display results
            if ~strcmpi(obj.ShowMessages, 'none')
                if ~isempty(eventTable)
                    disp('SMU event list:');
                    disp(eventTable);
                else
                    disp('SMU event list is empty');
                end
            end

            % reading out the error buffer again results in an empty return
            % value ==> therefore history is saved in 'SMU24xx' class

            % append event list to table
            obj.ErrorMessages = [obj.ErrorMessages; eventTable];

            % copy result to output
            errTable = obj.ErrorMessages;
        end

        % -----------------------------------------------------------------
        % get/set for internal properties (private properties)

        function set.SourceMode(obj, mode)
            % mode: 'current' or 'voltage'

            % set property
            obj.write([':Source:Function ' mode]);

            % readback and verify
            modeSet = obj.SourceMode;
            if ~strcmpi(modeSet, mode)
                disp(['SMU24xx parameter value for property ' ...
                    '''SourceMode'' was not set properly.']);
                disp(['  wanted value      : ' mode]);
                disp(['  actually set value: ' modeSet]);
            end
        end

        function mode = get.SourceMode(obj)
            % mode: 'current' or 'voltage'

            % get property
            response = char(obj.query(':Source:Function?'));
            switch lower(response)
                case 'volt', mode = 'voltage';
                case 'curr', mode = 'current';
                otherwise  , mode = 'Error, unknown mode';
                    disp([mode '(get SourceMode)']);
            end
        end

        function set.SenseMode(obj, mode)
            % mode: 'current' or 'voltage'

            % set property
            obj.write([':Sense:Function "' mode '"']);

            % readback and verify
            modeSet = obj.SenseMode;
            if ~strcmpi(modeSet, mode)
                disp(['SMU24xx parameter value for property ' ...
                    '''SenseMode'' was not set properly.']);
                disp(['  wanted value      : ' mode]);
                disp(['  actually set value: ' modeSet]);
            end
        end

        function mode = get.SenseMode(obj)
            % mode: 'current' or 'voltage'

            % get property
            response = char(obj.query(':Sense:Function?'));
            switch lower(response)
                case '"volt:dc"', mode = 'voltage';
                case '"curr:dc"', mode = 'current';
                case '"res"'    , mode = 'resistance';
                otherwise       , mode = 'Error, unknown mode';
                    disp([mode '(get SourceMode)']);
            end
        end

    end

    % ------- private methods ---------------------------------------------
    methods(Access = private)

        % -----------------------------------------------------------------
        % internal methods to get/set source parameters
        % ==> combined in public struct-property 'SourceParameters'

        % get: function mode (of source) is either 'voltage' or 'current'
        function [param, paramAsMsg] = getSourceOutputValue(obj, funcMode)

            % init output
            param      = NaN;
            paramAsMsg = 'get method for this parameter is not implemented yet';

        end

        function [param, paramAsMsg] = getSourceReadback(obj, funcMode)

            % init output
            param      = NaN;
            paramAsMsg = 'get method for this parameter is not implemented yet';

        end

        function [param, paramAsMsg] = getSourceRange(obj, funcMode)

            % init output
            param      = NaN;
            paramAsMsg = 'get method for this parameter is not implemented yet';

        end

        function [param, paramAsMsg] = getSourceAutoRange(obj, funcMode)

            % init output
            param      = NaN;
            paramAsMsg = 'get method for this parameter is not implemented yet';

        end

        function [param, paramAsMsg] = getSourceLimitValue(obj, funcMode)
            % config: request either voltage or current limit value
            if strcmpi(funcMode, 'current')
                limitMode    = 'Vlimit';
                limitUnitMsg = ' V (voltage-limit)';
            elseif strcmpi(funcMode, 'voltage')
                limitMode    = 'Ilimit';
                limitUnitMsg = ' A (current-limit)';
            else
                limitMode    = ' '; % will end up in an SCPI error
                limitUnitMsg = ' Error, unknown source-function-mode';
            end

            % actual request (SCPI-command)
            [limit, status] = obj.query([':Source:' funcMode ':' ...
                limitMode '?']);
            if status ~= 0
                param = NaN; % unknown value, error
            else
                % convert value
                param = str2double(char(limit));
            end

            % create more helpful message to display (method 'showSettings')
            paramAsMsg = [num2str(param) limitUnitMsg];
        end

        function [param, paramAsMsg] = getSourceLimitTripped(obj, funcMode)
            % config: request either voltage or current limit value
            if strcmpi(funcMode, 'current')
                limitMode    = 'Vlimit';
                limitUnitMsg = ' (voltage-limit)';
            elseif strcmpi(funcMode, 'voltage')
                limitMode    = 'Ilimit';
                limitUnitMsg = ' (current-limit)';
            else
                limitMode    = ' '; % will end up in an SCPI error
                limitUnitMsg = ' Error, unknown source-function-mode';
            end

            % actual request (SCPI-command)
            [tripped, status] = obj.query([':Source:' funcMode ':' ...
                limitMode ':Tripped?']);
            if status ~= 0
                param = NaN; % unknown value, error
            else
                % convert value ('0' or '1' else error)
                param = str2double(char(tripped));
            end

            % create more helpful message to display (method 'showSettings')
            if param == 0
                paramAsMsg = 'No';
            elseif param == 1
                paramAsMsg = 'Yes - clipping is active';
            else
                paramAsMsg = [char(tripped) ' unexpected response'];
            end
            paramAsMsg = [paramAsMsg limitUnitMsg];
        end

        function [param, paramAsMsg] = getSourceOVProtectionValue(obj, ~)
            % actual request (SCPI-command)
            [limit, status] = obj.query(':Source:Voltage:Protection:Level?');
            if status ~= 0
                param = NaN; % unknown value, error
            else
                % convert value
                limit = lower(char(limit));
                if strcmp(limit, 'none')
                    param = inf;
                elseif startsWith(limit, 'prot') && length(limit) >= 5
                    param = str2double(limit(5:end));
                else
                    param = NaN; % unknown response
                end
            end

            % create more helpful message to display (method 'showSettings')
            paramAsMsg = [num2str(param) ' V (voltage-limit)'];
        end

        function [param, paramAsMsg] = getSourceOVProtectionTripped(obj, ~)
            % get OVP state:
            %    0 for 'not exceed the OVP limit',
            %    1 for 'overvoltage protection is active, voltage is restricted'
            %  NaN for unknown state (error)

            % actual request (SCPI-command)
            [tripped, status] = obj.query(':Source:Voltage:Protection:Tripped?');
            if status ~= 0
                param = NaN; % unknown value, error
            else
                % convert value ('0' or '1' else error)
                param = str2double(char(tripped));
            end

            % create more helpful message to display (method 'showSettings')
            if param == 0
                paramAsMsg = 'No';
            elseif param == 1
                paramAsMsg = 'Yes - overvoltage protection is active';
            else
                paramAsMsg = [char(tripped) ' unexpected response'];
            end
        end

        function [param, paramAsMsg] = getSourceDelay(obj, funcMode)

            % init output
            param      = NaN;
            paramAsMsg = 'get method for this parameter is not implemented yet';

        end

        function [param, paramAsMsg] = getSourceAutoDelay(obj, funcMode)

            % init output
            param      = NaN;
            paramAsMsg = 'get method for this parameter is not implemented yet';

        end

        function [param, paramAsMsg] = getSourceHighCapMode(obj, funcMode)

            % init output
            param      = NaN;
            paramAsMsg = 'get method for this parameter is not implemented yet';

        end

        % set: function mode (of source) is either 'voltage' or 'current'
        function status = setSourceOutputValue(obj, param, funcMode)

            % init output
            status = NaN;

        end

        function status = setSourceReadback(obj, param, funcMode)

            % init output
            status = NaN;

        end

        function status = setSourceRange(obj, param, funcMode)

            % init output
            status = NaN;

        end

        function status = setSourceAutoRange(obj, param, funcMode)

            % init output
            status = NaN;

        end

        function status = setSourceLimitValue(obj, param, funcMode)
            propName = '''SourceParameters.LimitValue''';

            % check input argument
            if ischar(param) || isStringScalar(param)
                param = str2double(param);
            elseif isscalar(param) && isreal(param)
                param = double(param);
            elseif isempty(param)
                param = [];
            else
                param = NaN;
            end
            if isnan(param) && ~strcmpi(obj.ShowMessages, 'none')
                disp(['SMU24xx Invalid parameter value for ' ...
                    'property ' propName '.']);
            end

            % config: request either voltage or current limit value
            if strcmpi(funcMode, 'current')
                limitMode = 'Vlimit';
                limitMin  = 0.002; % min 0.002 V for Keithley 2450
                limitMax  = 210;   % max  210 V  for Keithley 2450
                limitUnit = 'V';
            elseif strcmpi(funcMode, 'voltage')
                limitMode = 'Ilimit';
                limitMin  = 1e-9;  % min 1 nA    for Keithley 2450
                limitMax  = 1.05;  % max 1.05 A  for Keithley 2450
                limitUnit = 'A';
            else
                limitMode = '';    % will end up in an SCPI error
                limitMin  = [];
                limitMax  = [];
                limitUnit = '';
            end

            % further checks and clipping
            limit = param;
            limit = min(limit, limitMax);
            limit = max(limit, limitMin);

            if ~isempty(limit) && ~isnan(limit)
                % set property
                obj.write([':Source:' funcMode ':' limitMode ' ' ...
                    num2str(limit)]);

                % readback and verify (max 1% difference)
                limitSet = obj.getSourceLimitValue(funcMode);
                if abs(limitSet - limit) > 1e-2*limit || ...
                        isnan(limitSet)
                    disp(['SMU24xx parameter value for property ' propName ...
                        ' was not set properly.']);
                    fprintf('  wanted value      : %3.6f %s\n', ...
                        limit   , limitUnit);
                    fprintf('  actually set value: %3.6f %s\n', ...
                        limitSet, limitUnit);
                    % readback reported mismatch
                    status = 2;
                else
                    % okay
                    status = 0;
                end
            else
                % no parameter was sent to SMU
                status = 1;
            end
        end

        % no setSourceLimitTripped method (parameter is read-only)

        function status = setSourceOVProtectionValue(obj, param, ~)
            propName = '''SourceParameters.OVProtectionValue''';

            % check input argument
            if ischar(param) || isStringScalar(param)
                param = str2double(param);
            elseif isscalar(param) && isreal(param)
                param = double(param);
            elseif isempty(param)
                param = [];
            else
                param = NaN;
            end
            if isnan(param) && ~strcmpi(obj.ShowMessages, 'none')
                disp(['SMU24xx Invalid parameter value for ' ...
                    'property ' propName '.']);
            end

            % further checks and clipping, coerced to (2, 5, 10, 20, 40,
            % 60, 80, 100, 120, 140, 160, 180, infty) V
            limit = param;
            if     limit > 180, setStr = 'NONE';
            elseif limit > 160, setStr = 'PROT180';
            elseif limit > 140, setStr = 'PROT160';
            elseif limit > 120, setStr = 'PROT140';
            elseif limit > 100, setStr = 'PROT120';
            elseif limit >  80, setStr = 'PROT100';
            elseif limit >  60, setStr = 'PROT80';
            elseif limit >  40, setStr = 'PROT60';
            elseif limit >  20, setStr = 'PROT40';
            elseif limit >  10, setStr = 'PROT20';
            elseif limit >   5, setStr = 'PROT10';
            elseif limit >   2, setStr = 'PROT5';
            elseif limit >   0, setStr = 'PROT2';
            else              , setStr = '';
            end

            if ~isempty(setStr)
                % set property
                obj.write([':Source:Voltage:Protection:Level ' setStr]);

                % readback and verify (max 1% difference)
                getStr = obj.query(':Source:Voltage:Protection:Level?');
                if ~strmpi(setStr, getStr)
                    disp(['SMU24xx parameter value for property ' propName ...
                        ' was not set properly.']);
                    disp(['  wanted value      : ' setStr '(voltage)']);
                    disp(['  actually set value: ' getStr '(voltage)']);
                    % readback reported mismatch
                    status = 2;
                else
                    % okay
                    status = 0;
                end
            else
                % no parameter was sent to SMU
                status = 1;
            end
        end

        % no setSourceOVProtectionTripped method (parameter is read-only)

        function status = setSourceDelay(obj, param, funcMode)

            % init output
            status = NaN;

        end

        function status = setSourceAutoDelay(obj, param, funcMode)

            % init output
            status = NaN;

        end

        function status = setSourceHighCapMode(obj, param, funcMode)

            % init output
            status = NaN;

        end

        % -----------------------------------------------------------------
        % internal methods to get/set sense parameters
        % ==> combined in public struct-property 'SenseParameters'

        % get: function mode (of sense) is either 'voltage' or 'current'
        %      manually it can also be set to 'resistance'


        % ToDo



        % -----------------------------------------------------------------
        % internal methods to memorize name of reading buffers at SMU
        function status = resetBuffer(obj)
            status               = 0; % always okay
            obj.AvailableBuffers = obj.DefaultBuffers;
        end

        function status = isBuffer(obj, buffer)
            % status = false when buffer does not exist yet
            % status = true  when buffer already exist
            %
            % buffer : char array (format already checked by 'checkParams')

            status = any(strcmpi(obj.AvailableBuffers, buffer));
        end

        function status = addBuffer(obj, buffer)
            % status =  0 when buffer was added to buffer list
            % status = -1 when buffer cannot be added (already existing)
            %
            % buffer : char array (format already checked by 'checkParams')

            if any(strcmpi(obj.AvailableBuffers, buffer))
                status = -1;
            else
                %obj.AvailableBuffers = [obj.AvailableBuffers {buffer}];
                obj.AvailableBuffers{end+1} = buffer; % shorter
                status =  0;
            end
        end

        function status = deleteBuffer(obj, buffer)
            % status =  0 when buffer was removed from buffer list
            % status = -1 when buffer cannot be deleted (is default buffer)
            % status = -2 when buffer cannot be deleted (does not exist)
            %
            % buffer : char array (format already checked by 'checkParams')

            if any(strcmpi(obj.DefaultBuffers, buffer))
                status = -1;
            elseif ~any(strcmpi(obj.AvailableBuffers, buffer))
                status = -2;
            else
                % index is not empty (see test abaove)
                idx = strcmpi(obj.AvailableBuffers, buffer);
                % remove cell element by replacing it with empty array
                obj.AvailableBuffers(idx) = [];
                status =  0;
            end
        end

    end

end
