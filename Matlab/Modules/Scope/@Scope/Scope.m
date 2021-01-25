classdef Scope < VisaIF
    % documentation for class 'Scope'
    % ---------------------------------------------------------------------
    % This class defines common methods for scope control. This class is a
    % sub class of the super class 'VisaIF'. Type (in command window):
    % 'Scope' - to get a full list of accessible scopes which means that
    %           their IP-addresses (for visa-tcpip) or USB IDs (for 
    %           visa-usb) are listed in config files 
    % 'Scope.listAvailablePackages' - to get a list of installed scope
    %           packages.
    % Your scope can be controlled by the Scope class, when it is
    % accessible and a suiting support package is installed.
    %
    % All public properties and methods from super class 'VisaIF' can also
    % be used. See 'VisaIF.doc' for details (min. VisaIFVersion 2.4.3).
    %
    % Use 'Scope.doc' for this help page. 
    %
    %   - Scope : constructor of sub class (class name)
    %     * use this function to create an object for your scope
    %     * same syntax as for VisaIF class ==> see 'doc VisaIF'
    %     * default value of showmsg is 'few'
    %     * overloads VisaIF
    %
    % NOTES: 
    %     * the output parameter 'status' has the same meaning for all 
    %       listed methods 
    %           status   :  0 when okay
    %                      -1 when something went wrong
    %     * all parameter names and values (varargin) are NOT case sensitive
    %     * vargargin are input as pairs NAME, VALUE
    %     * any number and order of NAME, VALUE pairs can be specified
    %     * not all parameters and values are supported by all scopes 
    %     * check for warnings and errors
    %
    % additional methods (static) of class 'Scope':
    %   - listAvailablePackages : print out a list of installed scope
    %                      support packages (Macros)
    %     * usage:
    %           Scope.listAvailablePackages
    %
    % additional methods (public) of class 'Scope':
    %   - clear          : clear status at scope 
    %     * send SCPI command '*CLS' to scope
    %     * usage:
    %           status = myScope.clear  or  myScope.clear
    %
    %   - lock & unlock  : lock/unlock all buttons at scope 
    %     * usage:
    %           status = myScope.lock or myScope.unlock
    %
    %   - configureInput : configure input of specified channels at scope
    %     * usage:
    %           status = myScope.configureInput(varargin)
    %       with varargin: pairs of parameters NAME, VALUE
    %           'channel' : specifies channel(s) to be configured
    %                       [1 2], 'ch1, ch2', '{'1', 'ch3'} ...
    %           'trace'   : enables or disables specified channel
    %                       'on', "on", 1, true or 'off', "off", 0, false
    %           'impedance':specifies input termination (when supported) 
    %                       50, '50', "50" or 1e6, '1M', '1e6', "1e6" ...
    %           'vDiv'    : input voltage scaling, positive numeric value,
    %                       in Volt/div; scope will display [-x ..+x]*vDiv;
    %                       ADC@scope will often quantize wider range than
    %                       displayed ==> check for clipping,
    %                       vDiv input value will be rounded internally
    %           'vOffset' : specifies the vertical offset in Volts
    %                       vOffset input value will be rounded internally
    %           'coupling': 'DC', 'AC', 'GND'
    %                        AC or DC coupling of input signal
    %           'inputdiv': ..., 1, 10, 20, 50, 100, 200, 500, 1000, ...
    %           or 'probe'  used to display correct voltage values
    %                       at display, 
    %                       =  1 for BNC-BNC cable,
    %                       = 10 for standard probe (10:1)
    %           'bwlimit' : 'off', false, 0 or 'on', true, 1
    %                       20MHz low pass filter to reduce noise
    %           'invert'  : 'off', false, 0 or 'on', true, 1
    %                       invert input signal
    %           'skew'    : specifies input skew (when supported),
    %                       real number
    %           'unit'    : 'V', "V" or 'A', "A"; quite senseless parameter;
    %                       only affects displayed unit at scope
    %
    %   - configureAcquisition : configure acquisition parameters
    %     * usage:
    %           status = myScope.configureAcquisition(varargin)
    %       with varargin: pairs of parameters NAME, VALUE
    %           'tDiv'    : positive numeric value, specifies the 
    %                       horizontal (time) scale per division; input 
    %                       value will be rounded internally,
    %                       scope will show [-N ..+N]*tDiv at display
    %           'samplerate' : alternative to tDiv, sample rate of
    %                       signals, 2*N*tDiv = numOfSamples / samplerate,
    %                       affects tDiv and numOfSamples
    %           'maxLength' : positive numeric value, specifies the maximum
    %                       number of samples for waveforms
    %           'mode'    : 'sample', 'peakdetect', average, ...
    %           'numAverage' : positive numeric value, specifies the number
    %                       of waveform acquisitions that make up an 
    %                       averaged waveform (only of interest when 
    %                       mode=average)
    %
    %   - configureTrigger : configure trigger parameters
    %     * usage:
    %           status = myScope.configureTrigger(varargin)
    %       with varargin: pairs of parameters NAME, VALUE
    %           'mode'    : specify the relation between trigger events and 
    %                       taking acquisitions;
    %                       'single'- wait for next trigger event, capture
    %                                 waveform and stop acquisitions
    %                       'normal'- wait for next trigger event, capture
    %                                 waveform and wait for next trigger 
    %                                 event 
    %                       'auto'  - similar to normal, but a trigger
    %                                 event will be generated automatically
    %                                 when no trigger is detected within a 
    %                                 specific time period
    %           'type'    : selects trigger option; e.g.
    %                       'risingedge', 'fallingedge', ...
    %           'source'  : selects trigger source,
    %                       'ch1', 'ch2'  for channel 1 or 2
    %                       'ext', 'ext5' for external trigger 
    %                                     (ext5 with attuation factor 5)
    %                       'AC-line'     for power line signal trigger
    %           'coupling': coupling of trigger signal,
    %                       'AC'         - AC coupling
    %                       'DC'         - DC coupling
    %                       'LFReject'   - like AC, but with additional
    %                                      high pass filter to remove 
    %                                      low-frequency signal parts
    %                       'HFRreject'  - like DC, but with additional
    %                                      low pass filter to remove 
    %                                      high-frequency signal parts
    %                       'NoiseReject'- low DC sensitivity
    %           'level'   : set trigger level in Volt, double;
    %                       use NaN to set level to 50% of signal range
    %           'delay'   : set (horizontal) delay in s, double;
    %                       value 0 means trigger event at center of
    %                       display, neg. values shift curve to the right 
    %
    %   - configureZoom : configure zoom window 
    %     * usage:
    %           status = myScope.configureTrigger(varargin)
    %       with varargin: pairs of parameters NAME, VALUE
    %           'zoomFactor'  : specifies zoom factor (greater than 1), 
    %                           default is 1 (dectivates zoom window)
    %                           value >= 2 activates zoom window
    %           'zoomPosition': specifies position of zoom window in s,
    %                           default is 0 (center of waveform/trigger)
    %
    %   - autoset        : Causes the oscilloscope to adjust its vertical, 
    %                      horizontal, and trigger controls to display a 
    %                      stable waveform 
    %     * uses the scope-internal (builtin) AUTOSET function (button)
    %     * because quite a lot of vertical, horizontal, and trigger
    %       parameters will be modified, it is sensible to use this method
    %       for initial setup only, use autoscale method to adjust
    %       horizontal or vertical scaling while measurements
    %     * it initiates a single execution of parameter adjustment. That 
    %       means later signal changes (level, frequency) will not change 
    %       vertical, horizontal or trigger settings
    %     * usage:
    %           status = myScope.autoset
    %
    %   - autoscale      : macro to adjust voltage (vertical) and/or time 
    %                      (horizontal) scaling parameters
    %     * similar to autoset, but no trigger option are modified
    %     * preferred method in automated test scripts
    %     * autoscale is not as powerful as autoset ==> it is intended for
    %       adjustment and not for initial setup
    %     * autoscale can be configured by properties 
    %       AutoscaleHorizontalSignalPeriods and AutoscaleVerticalScalingFactor
    %     * usage:
    %           status = myScope.autoscale(varargin)
    %       with varargin: pairs of parameters NAME, VALUE
    %           'mode'    : 'hor'  - (or 'horizontal') only horizontal 
    %                                (tDiv) parameter will be adjusted 
    %                       'vert' - (or 'vertical') only vertical (vDiv, 
    %                                vOffset) parameters will be adjusted
    %                                on active channels
    %                       'both' - vertical and horizontal scaling
    %                                parameters will be adjusted
    %
    %   - acqRun          : start data acquisitions at scope like pressing
    %                       run/stop button at scope
    %     * usage:
    %           status = myScope.acqRun   or   myScope.acqRun
    %       
    %   - acqStop         : stop data acquisitions at scope like pressing
    %                       run/stop button at scope
    %     * usage:
    %           status = myScope.acqStop   or   myScope.acqStop
    %       
    %   - makeScreenShot : make a screenshot of scope display and save to
    %                      file
    %     * usage:
    %           status = myScope.makeScreenShot(varargin)
    %       with varargin: pairs of parameters NAME, VALUE
    %           'filename' : file name as char,  
    %           filename: char array, specifying filename; omit file
    %                     extension for default
    %           darkmode: 'off', 0, false (default): white background color
    %                     'on', 1, true: dark background color 
    %
    %   - runMeasurement : request measurement value
    %     * usage:
    %           result = myScope.runMeasurement(varargin)
    %       with output
    %          result.status    : status =  0 for okay       (double)
    %                                    = -1 for error
    %          result.value     : reported measurement value (double)
    %          result.unit      : corresponding unit         (char)
    %          result.channel   : specified channel/source   (char)
    %          result.parameter : specified parameter        (char)
    %       with varargin: pairs of parameters NAME, VALUE
    %          'channel'  : specifies source for measurement
    %                       [1 2], 'ch1, ch2', '{'1', 'ch3'} ...
    %                       ATTENTION: will always be internally sorted in
    %                       ascending order ==> affects sign in phase meas.
    %          'parameter': specifies parameter for measurement, e.g.
    %                         'frequency' - frequency
    %                         'period'    - period
    %                         'mean'      - mean value
    %                         'pk-pk'     - peak-to-peak value
    %                         'crms'      - cyclic RMS value
    %                         'rms'       - RMS value
    %                         'min'       - minimum value
    %                         'max'       - maximum value
    %                         'risetime'  - 10% to 90% rise time
    %                         'falltime'  - 90% to 10% fall time
    %                         'poswidth'  - pos. width at 50% level
    %                         'negwidth'  - neg. width at 50% level
    %                         'dutycycle' - duty cycle
    %                         'phase'     - phase between channels
    %
    %   - captureWaveForm : download waveform data
    %     * it is sensible to stop acquisition before
    %     * usage:
    %          waveData = myScope.captureWaveForm(varargin)
    %       with output
    %          waveData.status     : status =  0 for okay
    %                                       = -1 for error
    %          waveData.volt       : waveform data in Volt
    %                                number of rows = number of channels
    %                                number of cols = number of samples
    %          waveData.time       : corresponding time vector in s
    %                                number of rows = 1
    %                                number of cols = same as for .volt
    %          wavedata.samplerate : sample rate in Sa/s (Hz)
    %       with varargin: pairs of parameters NAME, VALUE
    %          'channel'  : channel selector
    %                       [1 2], 'ch1, ch2', '{'1', 'ch3'} ...
    %
    % additional properties of class 'Scope':
    %   - with read access only
    %     * ScopeVersion  : version of this class file (char)
    %     * ScopeDate     : release date of this class file (char)
    %     * MacrosVersion : version of support package class (char)
    %     * MacrosDate    : release date of support package class (char)
    %     * AcquisitionState : current acquisition state (run or stop)
    %                       'running' when acquisition is running either 
    %                               waiting for trigger or acquiring data
    %                               repeatingly
    %                       'stopped', ['stopped (unfinished)', 
    %                               'stopped (finished and completed)', 
    %                               'stopped (finished but interrupted)'] 
    %                               when acquisition is stopped either 
    %                               finished (triggered acquisition) or 
    %                               unfinished (no trigger and trigger mode 
    %                               is either 'single' or 'normal')
    %     * TriggerState  : current trigger state, e.g. 
    %                       'ready' when scope is waiting for trigger 
    %                               (acquisition is running); trigger mode
    %                               is either 'single' or 'normal'
    %                       'auto'  when scope is waiting for trigger,
    %                               but waveform data were acquired even
    %                               in absence of a trigger; acquisition
    %                               is running; trigger mode is 'auto'
    %                       'triggered' when scope has been triggered and
    %                               acquisition is still running (waiting
    %                               for new trigger); trigger mode is
    %                               'auto' or 'normal'
    %                       'stop'  when acquisition is stopped (either acq
    %                               mode is 'single' and trigger causes a 
    %                               single acquisition or acq was stopped 
    %                               manually) or all channels are off
    %     * ErrorMessages : error list from the scope’s error buffer
    %
    %   - with read/write access
    %     * AutoscaleHorizontalSignalPeriods : config parameter for
    %       autoscale method, specifies number of signal periods in
    %       display, sensible range is 2 .. 50        
    %     * AutoscaleVerticalScalingFactor : config parameter for
    %       autoscale method, specifies amplitude range in display,
    %       1.00 means full display@scope range (-N ..+n) vDiv,
    %       sensible range is 0.3 .. 0.95,
    %       >1 is possible (most scopes allow up to 1.25), but ADC
    %       overloading can occure and trigger stage will possibly fail 
    %
    % ---------------------------------------------------------------------
    % example for usage of class 'Scope':
    %   myScope = Scope('TDS'); % create object (e.g. Tektronix TDS1001C)
    %
    %   disp(['Version: ' myScope.ScopeVersion]); % show versions
    %   disp(['Version: ' myScope.VisaIFVersion]);
    % 
    %   myScope.open;                     % open interface
    %   myScope.reset;                    % reset scope 
    % 
    %   myScope.configureInput( ...
    %       'channel',  [1 2] , ...
    %       'trace',    'on'  , ...
    %       'vDiv',     0.05  , ...
    %       'vOffset',  0.07  , ...
    %       'coupling', 'dc'  , ...
    %       'bwlimit',  'off' , ...
    %       'inputdiv', 1);    % or 'probe'
    %   
    %   % set up scope with 'configureAcquisition',  'configureTrigger'
    %   
    %   myScope.acqStop;
    %   wavedata = myScope.captureWaveForm('channel', 'ch1');
    %
    %   myScope.makeScreenShot('filename', 'myScreenShot.bmp');
    %
    %   % low level commands (inherited from super class 'VisaIF')
    %   % for supported SCPI commands see programmer guide of your scope
    %   myScope.query('wfmpre:wfid?');         % list some settings
    %   myScope.write('display:persitence 5'); % 5s 
    % 
    %   myScope.close;                    % close interface
    %   myScope.delete;                   % delete object
    % 
    % ---------------------------------------------------------------------
    % HTW Dresden, faculty of electrical engineering
    %   for version and release date see properties 'ScopeVersion' and
    %   'ScopeDate'
    %
    % tested with
    %   - Matlab (version 9.9 = 2020b update 3) and
    %   - Instrument Control Toolbox (version 4.3)
    %   - NI-Visa 19.5 (download from NI, separate installation)
    %
    % known issues and planned extensions / fixes
    %   - no bugs reported so far (version 1.0.3) ==> winter term 2020/21
    %
    % development, support and contact:
    %   - Constantin Wimmer (student, automation)
    %   - Matthias Henker   (professor)
    % ---------------------------------------------------------------------
       
    
    % ---------------------------------------------------------------------
    % Rules:
    %   - class name and package name are identical
    %     ==> '@Scope' and '+Scope'
    %   - class name of macros in support packages are always named like
    %     [classname 'Macros'] in a single m-file
    %     ==> +Scope\'VendorDir'\'ProductDir'\ScopeMacros.m'
    %
    % important change (compared to former ScopeTekTDS1001C class)
    % runMeasurement: phase : always ch1, ch2 (ch1 -> ch2) inverted sign
    % 
    % trace  (syntax examples)
    % 'off', "off", '0', "0", 0, false  ==> '0'
    % 'on',  "on",  '1', "1", 1, true   ==> '1'
    
    
    properties(Constant = true)
        ScopeVersion    = '1.0.4';      % release version (= class version)
        ScopeDate       = '2021-01-25'; % release date
    end
    
    properties(Dependent, SetAccess = private, GetAccess = public)
        MacrosVersion
        MacrosDate
        AcquisitionState
        TriggerState
        ErrorMessages
    end
    
    properties
        AutoscaleHorizontalSignalPeriods double = 5;
        AutoscaleVerticalScalingFactor   double = 0.9;
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
        
        function obj = Scope(device, interface, showmsg)
            % constructor for a Scope object (same variables as for VisaIF
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
            catch
                error(['No support package available for: ' fString]);
            end
            
        end
        
        function delete(obj)
            % destructor

            try 
                % save property
                myShowMsg = obj.ShowMessages;
                % close connection silently
                obj.ShowMessages = false;
                obj.close;
                % restore property
                obj.ShowMessages = myShowMsg;
            catch
                disp('Closing connection to scope causes warnings.');
            end
            
            % only run delete when object exists 
            if ~isempty(obj.MacrosObj)
                % delete MacroObj
                obj.MacrosObj.delete;
            end
            
            % regular deletion of this class object follows now
        end
        
        % -----------------------------------------------------------------
        % extend some methods from super class (VisaIF)
        % -----------------------------------------------------------------
        
        function status = open(obj)
            % extend open method (inherited from super class VisaIF)

            % init output
            status = NaN;
            
            % execute "standard" open method from VisaIF class
            if open@VisaIF(obj)
                status = -1;
                return;
            end
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  execute post-open macro');
            end
            
            % execute device specific macros after opening connection
            if obj.MacrosObj.runAfterOpen
                status = -1;
            end
            
            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end
        
        function status = close(obj)
            % extend close method (inherited from super class VisaIF)
            
            % init output
            status = NaN;
            
            % execute device specific macros before closing connection
            % skip when interface is already closed
            if strcmpi(obj.CommStatus, 'open')
                
                if ~strcmpi(obj.ShowMessages, 'none')
                    disp([obj.DeviceName ':']);
                    disp('  execute pre-close macro');
                end
                
                if obj.MacrosObj.runBeforeClose
                    status = -1;
                end
            end
            
            % execute "standard" close method from super class
            if close@VisaIF(obj)
                status = -1;
            end
            
            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end
        
        function status = reset(obj)
            % override reset method (inherited from super class VisaIF)
            % restore default settings at scope
            
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
        % actual scope methods: actions without input parameters
        % -----------------------------------------------------------------
        
        function status = clear(obj)
            % clear status at scope
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
            % lock all buttons at scope
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  lock all buttons at scope');
            end
            
            % execute device specific macro
            status = obj.MacrosObj.lock;
            
            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  lock failed');
            end
        end
        
        function status = unlock(obj)
            % unlock all buttons at scope
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  unlock all buttons at scope');
            end
            
            % execute device specific macro
            status = obj.MacrosObj.unlock;
            
            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  unlock failed');
            end
        end
        
        function status = acqRun(obj)
            % start data acquisitions at scope
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  start data acquisitions');
            end
            
            % execute device specific macro
            status = obj.MacrosObj.acqRun;
            
            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  acqRun failed');
            end
        end
        
        function status = acqStop(obj)
            % stop data acquisitions at scope
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  stop data acquisitions');
            end
            
            % execute device specific macro
            status = obj.MacrosObj.acqStop;
            
            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  acqStop failed');
            end
        end
        
        function status = autoset(obj)
            % autoset : causes the oscilloscope to adjust its vertical,
            % horizontal, and trigger controls to display a stable waveform
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  autoset vertical, horizontal and trigger parameters');
            end
            
            % execute device specific macro
            status = obj.MacrosObj.autoset;
            
            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  autoset failed');
            end
        end
        
        % -----------------------------------------------------------------
        % actual scope methods: actions with varargin parameters
        % -----------------------------------------------------------------
        
        function status = configureInput(obj, varargin)
            % configureInput  : configure input of specified channels
            %   'channel'     : 1 .. 4, [1 2], 'ch1, ch2', '{'1', 'ch3'} ...
            %   'trace'       : 'on', "on", 1, true or 'off', "off", 0, false
            %   'impedance'   : 50, '50', "50" or 1e6, '1M', '1e6', "1e6" ...
            %   'vDiv'        : real > 0
            %   'vOffset'     : real
            %   'coupling'    : 'DC', 'AC', 'GND'
            %   'inputDiv'    : ... , 1, 10, 20, 50, 100, 200, 500, ...
            %   'bwLimit'     : on/off
            %   'invert'      : on/off
            %   'skew'        : real
            %   'unit'        : 'V', "V" or 'A', "A"
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  configure input channels');
                params = obj.checkParams(varargin, 'configureInput', true);
            else
                params = obj.checkParams(varargin, 'configureInput');
            end
            
            % execute device specific macro
            status = obj.MacrosObj.configureInput(params{:});
            
            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  configureInput failed');
            end
        end
        
        function status = configureAcquisition(obj, varargin)
            % configureAcquisition : configure acquisition parameters
            %   'tDiv'        : real > 0
            %   'sampleRate'  : real > 0
            %   'maxLength'   : integer > 0
            %   'mode'        : 'sample', 'peakdetect', average ...
            %   'numAverage'  : integer > 0
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  configure acquisition parameters');
                params = obj.checkParams(varargin, 'configureAcquisition', true);
            else
                params = obj.checkParams(varargin, 'configureAcquisition');
            end
            
            % execute device specific macro
            status = obj.MacrosObj.configureAcquisition(params{:});
            
            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  configureAcquisition failed');
            end
        end
        
        function status = configureTrigger(obj, varargin)
            % configureTrigger : configure trigger parameters
            %   'mode'        : 'single', 'normal', 'auto'
            %   'type'        : 'risingedge', 'fallingedge' ...
            %   'source'      : 'ch1', 'ch2' , 'ext', 'ext5' ...
            %   'coupling'    : 'AC', 'DC', 'LFReject', 'HFRreject', 'NoiseReject'
            %   'level'       : real
            %   'delay'       : real
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  configure trigger parameters');
                params = obj.checkParams(varargin, 'configureTrigger', true);
            else
                params = obj.checkParams(varargin, 'configureTrigger');
            end
            
            % execute device specific macro
            status = obj.MacrosObj.configureTrigger(params{:});
            
            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  configureTrigger failed');
            end
        end
        
        function status = configureZoom(obj, varargin)
            % configureZoom   : configure zoom window
            %   'zoomFactor'  :
            %   'zoomPosition':
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  configure zoom window');
                params = obj.checkParams(varargin, 'configureZoom', true);
            else
                params = obj.checkParams(varargin, 'configureZoom');
            end
            
            % execute device specific macro
            status = obj.MacrosObj.configureZoom(params{:});
            
            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  configureZoom failed');
            end
        end
        
        function status = autoscale(obj, varargin)
            % autoscale       : adjust vertical and/or horizontal scaling
            %   'mode'        : 'hor', 'vert', 'both'
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  adjust vertical and/or horizontal scaling');
                params = obj.checkParams(varargin, 'autoscale', true);
            else
                params = obj.checkParams(varargin, 'autoscale');
            end
            
            % execute device specific macro
            status = obj.MacrosObj.autoscale(params{:});
            
            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  autoscale failed');
            end
        end
        
        function status = makeScreenShot(obj, varargin)
            % makeScreenShot  : make a screenshot of scope display
            %   'fileName'    : file name with optional extension
            %   'darkMode'    : on/off
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  make a screenshot of scope display');
                params = obj.checkParams(varargin, 'makeScreenShot', true);
            else
                params = obj.checkParams(varargin, 'makeScreenShot');
            end
            
            % execute device specific macro
            status = obj.MacrosObj.makeScreenShot(params{:});
            
            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  makeScreenShot failed');
            end
        end
        
        function meas = runMeasurement(obj, varargin)
            % runMeasurement  : request measurement value
            %   'channel'
            %   'parameter'
            % meas.status
            % meas.value     : reported measurement value (double)
            % meas.unit      : corresponding unit         (char)
            % meas.channel   : specified channel(s)       (char)
            % meas.parameter : specified parameter        (char)
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  request measurement value');
                params = obj.checkParams(varargin, 'runMeasurement', true);
            else
                params = obj.checkParams(varargin, 'runMeasurement');
            end
            
            % execute device specific macro
            meas = obj.MacrosObj.runMeasurement(params{:});
            
            if ~strcmpi(obj.ShowMessages, 'none') && meas.status ~= 0
                disp('  runMeasurement failed');
            end
        end
        
        function waveData = captureWaveForm(obj, varargin)
            % captureWaveForm: download waveform data
            %   'channel' : one or more channels
            % outputs:
            %   waveData.status
            %   waveData.volt       : waveform data in Volt
            %   waveData.time       : corresponding time vector in s
            %   waveData.samplerate : sample rate in Sa/s (Hz)
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  download waveform data');
                params = obj.checkParams(varargin, 'captureWaveForm', true);
            else
                params = obj.checkParams(varargin, 'captureWaveForm');
            end
            
            % execute device specific macro
            waveData = obj.MacrosObj.captureWaveForm(params{:});
            
            if ~strcmpi(obj.ShowMessages, 'none') && waveData.status ~= 0
                disp('  captureWaveForm failed');
            end
        end
        
        % -----------------------------------------------------------------
        % actual scope methods: get methods (dependent)
        % -----------------------------------------------------------------
        
        function acqState = get.AcquisitionState(obj)
            % get acquisition state (running, stopped, ...)
            acqState = obj.MacrosObj.AcquisitionState;
        end
        
        function trigState = get.TriggerState(obj)
            % get trigger state (ready, auto, triggered, ...)
            trigState = obj.MacrosObj.TriggerState;
        end
        
        function errMsg = get.ErrorMessages(obj)
            % read error list from the scope’s error buffer
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
        
        function periods = get.AutoscaleHorizontalSignalPeriods(obj)
            periods = obj.AutoscaleHorizontalSignalPeriods;
        end
        
        function set.AutoscaleHorizontalSignalPeriods(obj, periods)
            
            % check input argument
            if isscalar(periods) && isnumeric(periods) ...
                    && isreal(periods) && periods > 0
                % check and limit
                periods = double(periods);
                periods = min(periods, 60);
                periods = max(periods, 0.5);
                % set property
                obj.AutoscaleHorizontalSignalPeriods = periods;
            else
                disp(['Scope: Invalid parameter value for property ' ...
                    '''AutoscaleHorizontalSignalPeriods''.']);
            end
        end
        
        function factor = get.AutoscaleVerticalScalingFactor(obj)
            factor = obj.AutoscaleVerticalScalingFactor;
        end
        
        function set.AutoscaleVerticalScalingFactor(obj, factor)
            
            % check input argument
            if isscalar(factor) && isnumeric(factor) ...
                    && isreal(factor) && factor > 0
                % check and limit
                factor = double(factor);
                factor = min(factor, 1.1);
                factor = max(factor, 0.15);
                % set property
                obj.AutoscaleVerticalScalingFactor = factor;
            else
                disp(['Scope: Invalid parameter value for property ' ...
                    '''AutoscaleVerticalScalingFactor''.']);
            end
        end
        
    end
end