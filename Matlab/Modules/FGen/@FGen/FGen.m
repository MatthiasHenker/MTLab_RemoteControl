classdef FGen < VisaIF
    % documentation for class 'FGen'
    % ---------------------------------------------------------------------
    % This class defines common methods for generator control. This class
    % is a subclass of the superclass 'VisaIF'. Type (in command window):
    % 'FGen' - to get a full list of accessible generators which means that
    %          their IP-addresses (for visa-tcpip) or USB-IDs (for
    %          visa-usb) are published in config files
    % 'FGen.listAvailablePackages' - to get a list of installed generator
    %           packages.
    % Your generator can be controlled by the FGen class, when it is
    % accessible and a matching support package is installed.
    %
    % All public properties and methods from superclass 'VisaIF' can also
    % be used. See 'VisaIF.doc' for details (min. VisaIFVersion 3.0.0).
    %
    % Use 'FGen.doc' for this help page.
    %
    %   - FGen : constructor of subclass (class name)
    %     * use this function to create an object for your generator
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
    %     * vargargin are input as pairs NAME = VALUE
    %     * any number and order of NAME = VALUE pairs can be specified
    %     * not all parameters and values are supported by all generators
    %     * check for warnings and errors
    %
    % additional methods (static) of class 'FGen':
    %   - listAvailablePackages : print out a list of installed generator
    %                      support packages (Macros)
    %     * usage:
    %           FGen.listAvailablePackages
    %
    % additional methods (public) of class 'FGen':
    %   - clear          : clear status at generator
    %     * send SCPI command '*CLS' to generator
    %     * usage:
    %           status = myFGen.clear  or just  myFGen.clear
    %
    %   - lock & unlock  : lock/unlock all buttons at generator (some generators)
    %     * usage:
    %           status = myFGen.lock or just  myFGen.lock
    %
    %   - configureOutput : configure output of specified channels at
    %     generator
    %     * usage:
    %           status = myFGen.configureOutput(varargin)
    %       with optional varargin: pairs of parameters NAME = VALUE
    %           'channel'    : specifies channel(s) to be configured
    %                          [1 2], 'ch1, ch2', '{'1', 'ch2'} ...
    %                          optional parameter, default is 'ch1'
    %           'waveform'   : specifies type of output signal
    %                          most commonly supported values are
    %                          'sin' or 'sine'   for sine wave
    %                          'squ' or 'square' for square wave
    %                          'ramp'            for ramp wave
    %                          'puls' or 'pulse' for pulse wave
    %                          'nois' or 'noise' for (pseudo) noise
    %                          'dc'              for dc (constant value)
    %                          'user' or 'arb'   for arbitrary wave
    %           'amplitude'  : amplitude of signal, depends on unit
    %           'unit'       : unit of amplitude like e.g. 'Vpp', 'Vrms',
    %                          'dBm', Attention: dBm is only allowed when
    %                          output impedance is not set to HighZ (inf)
    %           'offset'     : DC offset of signal in V
    %           'frequency'  : frequency of signal in Hz
    %           'phase'      : phase offset of signal (0 .. 360), mainly of
    %                          interest for generators with two channels
    %           'dutycycle'  : duty cycle of signal in % (0 .. 100),
    %                          for waveform = square or pulse only
    %           'symmetry'   : symmetry of signal in % (0 .. 100),
    %                          for waveform = ramp only
    %           'transition' : transition time in s of signal,
    %                          for waveform = pulse only
    %           'stdev'      : standard deviation of signal in V(rms),
    %                          for waveform = noise
    %           'bandwidth'  : bandwidth of signal in Hz,
    %                          for waveform = noise only
    %           'outputimp'  : output impedance in Ohm, most typical value
    %                          is 50 (Ohm), set to inf for HighZ state,
    %                          Attention: does not affect the actual output
    %                          impedance, but is used to calculate the
    %                          correct amplitude depending on connected
    %                          load impedance
    %           'samplerate' : sample rate of signal, for waveform = arb
    %
    %   - arbWaveform : upload, download, list, select arbitrary waveforms
    %     * usage:
    %           status = myFGen.arbWaveform(varargin) or
    %           [status, waveout] = myFGen.arbWaveform(varargin)
    %       with output arguments: (additional outputs to status)
    %           waveout  = when 'mode' = 'download'
    %                      sample values of arbitrary wave signal, vector
    %                      of real numbers in range (-1 ... +1) (signal is
    %                      internally downscaled by 2^(#numBITSofDAC-1)-1
    %           waveout  = when 'mode' = 'list'
    %                      character array with comma separated wavenames
    %       with optional varargin: pairs of parameters NAME = VALUE
    %           'channel' : specifies channel(s) to be configured when
    %                       'mode' is set to 'select',
    %                       [1 2], 'ch1, ch2', '{'1', 'ch2'} ...
    %                       optional parameter, default is 'ch1'
    %           'mode'    : selects the configuration mode like
    %                       'list'     - list available wavenames at
    %                                    generator, default if empty
    %                       'select'   - select wavename as output signal
    %                                    for specified channel
    %                                    Attention: affects output only
    %                                    when waveform is set to arb in
    %                                    configureOutput
    %                       'delete'   - select wavename to be deleted,
    %                                    only user waveforms can be deleted
    %                       'upload'   - upload signal from host to FGen
    %                       'download' - download signal from FGen to host
    %           'submode' : select an option for certain config modes
    %                         for mode = list (maybe also for select):
    %                           'user'    - user-defined wavenames only
    %                           'builtin' - pre-defined wavenames only
    %                           'all'     - all wavenames (default)
    %                         for mode = upload:
    %                           'override'- override an existing wavename
    %                                       at generator, if not specified
    %                                       file will not be overridden
    %                         for mode = upload and select:
    %                           'volatile'- do not save to hard disk and
    %                                       keep wavedata in volatile
    %                                       memory only (only supported by
    %                                       few generators)
    %           'wavename': specifies signal name at generator, starts with
    %                       a letter and contains word characters only,
    %                       a file extension would be ignored
    %           'wavedata': sample values of arbitrary wave signal, vector
    %                       of real numbers (for all FGen) or
    %                       complex numbers (for dual channel FGen),
    %                       data has to be in range (-1 ... +1)
    %                       (signal is internally upscaled by
    %                       2^(#numBITSofDAC-1)-1, clipped and rounded)
    %
    %   - enableOutput  : enable output of specified channels at generator
    %     * usage:
    %           status = myFGen.enableOutput(varargin)
    %       with optional varargin: pairs of parameters NAME = VALUE
    %           'channel' : specifies channel(s) to be configured
    %                       [1 2], 'ch1, ch2', '{'1', 'ch2'} ...
    %                       optional parameter, default is 'ch1'
    %
    %   - disableOutput : disable output of specified channels at generator
    %     * usage:
    %           status = myFGen.disableOutput(varargin)
    %       with optional varargin: pairs of parameters NAME = VALUE
    %           'channel' : specifies channel(s) to be configured
    %                       [1 2], 'ch1, ch2', '{'1', 'ch2'} ...
    %                       optional parameter, default is 'ch1'
    %
    % additional properties of class 'FGen':
    %   - with read access only
    %     * FGenVersion   : version of this class file (char)
    %     * FGenDate      : release date of this class file (char)
    %     * MacrosVersion : version of support package class (char)
    %     * MacrosDate    : release date of support package class (char)
    %     * ErrorMessages : error list from the generator’s error buffer
    %
    %   - with read/write access
    %     * none
    %
    % ---------------------------------------------------------------------
    % example for usage of class 'FGen': assuming Agilent 33220A is listed
    % in config file (run 'FGen.listContentOfConfigFiles')
    %
    %   myFGen = FGen('33220'); % create object and open interface
    %
    %   disp(['Version: ' myFGen.FGenVersion]);   % show versions
    %   disp(['Version: ' myFGen.VisaIFVersion]);
    %
    %   myFGen.configureOutput( ...
    %       waveform  = 'sin' , ...
    %       outputImp = 50    );
    %   myFGen.configureOutput( ...
    %       frequency = 1.2e3 , ...
    %       amplitude = 2     , ...
    %       unit      = 'Vpp' );
    %   myFGen.configureOutput( ...
    %       offset    = -0.5  );
    %
    %   myFGen.enableOutput;    % or myFGen.enableOutput(channel = 1);
    %
    %   % arb waveform commands
    %   myFGen.arbWaveform(          ...
    %       mode      = 'upload'   , ...
    %       wavedata  = [-1:0.01:1], ...
    %       wavename  = 'ramp201pts' );
    %   myFGen.arbWaveform(          ...
    %       mode      = 'select'   , ...
    %       wavename  = 'ramp201pts' );
    %   myFGen.configureOutput(      ...
    %       waveform  = 'arb'      );
    %
    %   % low level commands (inherited from super class 'VisaIF')
    %   % for supported SCPI commands see programmer guide of your
    %   % generator (here an example for Agilent 33220A)
    %   myFGen.write('freq 1234.5'); % set frequency to 1234.5 Hz
    %   myFGen.query('freq?');       % request actual frequency
    %
    %   myFGen.delete;                   % close interface and delete object
    %
    % ---------------------------------------------------------------------
    % HTW Dresden, faculty of electrical engineering
    %   for version and release date see properties 'FGenVersion' and
    %   'FGenDate'
    %
    % tested with
    %   - Matlab (version 24.1 = 2024a update 6) and
    %   - Instrument Control Toolbox (version 24.1)
    %   - NI-Visa 21.5 (download from NI, separate installation)
    %
    % known issues and planned extensions / fixes
    %   - no severe bugs reported (version 3.0.0) ==> winter term 2024/25
    %
    % planned extensions / fixes
    %   - support modulation, sweep, burst, ...
    %
    % development, support and contact:
    %   - Constantin Wimmer (student, automation)
    %   - Matthias Henker   (professor)
    % ---------------------------------------------------------------------

    % think about new property in arbWaveform:
    %           'filename': file name specifying wave data at host computer
    %                         for mode = upload:
    %                           when no wavedata are specified then data
    %                           are read from host and uploaded
    %                         for mode = download:
    %                           downloaded wave data are additionally saved
    %                           to file at host

    properties(Constant = true)
        FGenVersion    = '3.0.0';      % release version (= class version)
        FGenDate       = '2024-08-22'; % release date
    end

    properties(Dependent, SetAccess = private, GetAccess = public)
        MacrosVersion
        MacrosDate
        % ...
        ErrorMessages
    end

    properties
        %tbd    double = 1;
    end

    properties(SetAccess = private, GetAccess = private)
        MacrosObj       % access to actual device specific macros
    end

    % ---------------------------------------------------------------------
    methods(Static)

        varargout = listAvailablePackages

        function doc
            % Normally the command 'doc NAME_OF_FUNCTIONOR_CLASS' is used
            % to display the help text. For classes named FGen or Scope
            % conflicts with other classes causes troubles.
            %
            % This method open a help windows using web-command.

            className  = mfilename('class');
            VisaIF.doc(className);

        end
    end

    % ---------------------------------------------------------------------
    methods

        function obj = FGen(device, interface, showmsg)
            % constructor for a FGen object (same variables as for VisaIF
            % except for missing last "hidden" parameter instrument)

            % check number of input arguments
            narginchk(0, 3);

            % -------------------------------------------------------------
            % set default values when no input is given (all further checks
            % in superclass 'VisaIF')

            if nargin < 3 || isempty(showmsg)
                showmsg = 'few';
            end

            if nargin < 2 || isempty(interface)
                interface = '';
            end

            if nargin < 1 || isempty(device)
                device   = '';
            end

            % -------------------------------------------------------------
            className  = mfilename('class');

            % create object: inherited from superclass 'VisaIF'
            instrument = className; % see VisaIF.SupportedInstrumentClasses
            obj = obj@VisaIF(device, interface, showmsg, instrument);

            if isempty(obj.Device)
                error('Initialization failed.');
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
                error(['No support package available for: ' fString]);
            end

            % execute device specific macros after opening connection
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  execute post-open macro');
            end
            if obj.MacrosObj.runAfterOpen
                error('Initial configuration of FGen failed.');
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
                    error('Reconfiguration of FGen before closing connecting failed.');
                end
                % delete MacroObj
                obj.MacrosObj.delete;
            end

            % regular deletion of this class object follows now
        end

        % -----------------------------------------------------------------
        % extend some methods from super class (VisaIF)
        % -----------------------------------------------------------------

        function status = reset(obj)
            % override reset method (inherited from super class VisaIF)
            % restore default settings at generator

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
        % actual generator methods: actions without input parameters
        % -----------------------------------------------------------------

        function status = clear(obj)
            % clear status at generator
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
            % lock all buttons at generator
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  lock all buttons at generator');
            end

            % execute device specific macro
            status = obj.MacrosObj.lock;

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  lock failed');
            end
        end

        function status = unlock(obj)
            % unlock all buttons at generator
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  unlock all buttons at generator');
            end

            % execute device specific macro
            status = obj.MacrosObj.unlock;

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  unlock failed');
            end
        end

        % -----------------------------------------------------------------
        % actual generator methods: actions with varargin parameters
        % -----------------------------------------------------------------

        function status = configureOutput(obj, varargin)
            % configureOutput: configure output of specified channels
            %   'channel'    : [1 2], 'ch1, ch2', '{'1', 'ch2'} ...
            %   'waveform'   : specifies waveform like e.g. 'sine', 'ramp',
            %                 'square', 'dc', 'pulse', 'noise', 'arb'
            %   'amplitude'  : specifies real
            %   'unit'       : 'Vpp', 'Vrms', 'dBm'
            %   'offset'     : real
            %   'frequency'  : real > 0
            %   'phase'      : real > 0
            %   'dutycycle'  : real > 0
            %   'symmetry'   : real > 0
            %   'transition' : real > 0
            %   'stdev'      : real > 0
            %   'bandwidth'  : real > 0
            %   'outputimp'  : real > 0
            %   'samplerate' : real > 0

            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  configure output channels');
                params = obj.checkParams(varargin, 'configureOutput', true);
            else
                params = obj.checkParams(varargin, 'configureOutput');
            end

            % execute device specific macro
            status = obj.MacrosObj.configureOutput(params{:});

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  configureOutput failed');
            end
        end

        function varargout = arbWaveform(obj, varargin)
            % arbWaveform  : upload, download, list, select arbitrary
            % waveforms
            %   'channel'  : [1 2], 'ch1, ch2', '{'1', 'ch2'} ...
            %   'mode'     : 'list', 'select', 'delete', 'upload',
            %                'download'
            %   'submode'  : 'user', 'builtin', 'all', 'override'
            %   'wavename' : 'xyz' (char)
            %   'wavedata' : vector of real (range -1 ... +1)
            %   (for future use???)    'filename' : 'xyz' (char)
            %
            % varargout is either
            % status            (1 output variable)
            % [status, waveout] (2 output variables)

            % init output variables
            if nargout > 2
                error('FGen: ''arbWaveform'' - Too many output arguments.');
            else
                varargout  = cell(1, nargout);
            end

            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  configure arbitrary waveforms');
                params = obj.checkParams(varargin, 'arbWaveform', true);
            else
                params = obj.checkParams(varargin, 'arbWaveform');
            end

            % execute device specific macro
            [status, waveout] = obj.MacrosObj.arbWaveform(params{:});

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  arbWaveform failed');
            end

            if nargout >= 1
                varargout(1) = {status};
            end
            if nargout == 2
                varargout(2) = {waveout};
            end
        end

        function status = enableOutput(obj, varargin)
            % enableOutput  : enable output of specified channels
            %   'channel'   : [1 2], 'ch1, ch2', '{'1', 'ch2'} ...

            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  enable output channels');
                params = obj.checkParams(varargin, 'enableOutput', true);
            else
                params = obj.checkParams(varargin, 'enableOutput');
            end

            % execute device specific macro
            status = obj.MacrosObj.enableOutput(params{:});

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  enableOutput failed');
            end
        end

        function status = disableOutput(obj, varargin)
            % disableOutput : disable output of specified channels
            %   'channel'   : [1 2], 'ch1, ch2', '{'1', 'ch2'} ...

            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  disable output channels');
                params = obj.checkParams(varargin, 'disableOutput', true);
            else
                params = obj.checkParams(varargin, 'disableOutput');
            end

            % execute device specific macro
            status = obj.MacrosObj.disableOutput(params{:});

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  disableOutput failed');
            end
        end

        % -----------------------------------------------------------------
        % actual generator methods: get methods (dependent)
        % -----------------------------------------------------------------

        function errMsg = get.ErrorMessages(obj)
            % read error list from the generator’s error buffer
            errMsg = obj.MacrosObj.ErrorMessages;
        end

    end

    % ---------------------------------------------------------------------
    methods(Static, Access = private)

        outVars = checkParams(inVars, command, showmsg)

    end

    % ---------------------------------------------------------------------
    methods           % get/set methods

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