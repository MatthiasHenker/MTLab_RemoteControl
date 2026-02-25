classdef ComboSource6301 < VisaIF
    % documentation for class 'ComboSource6301'
    % ---------------------------------------------------------------------
    % This class defines methods for controlling the ComboSource 6301 laser
    % controller via RS-232/USB interface. This class is a subclass of the
    % superclass 'VisaIF'. For full HTML documentation, use 'ComboSource6301.doc'.
    %
    % Type in command window:
    % 'ComboSource6301' - to get a list of accessible devices
    % 'ComboSource6301.doc' - to open comprehensive HTML documentation
    %
    % All public properties and methods from superclass 'VisaIF' can also
    % be used. See 'VisaIF.doc' for details (min. VisaIFVersion 3.0.0).
    %
    % CONSTRUCTOR:
    %   myLaser = ComboSource6301(device)
    %   myLaser = ComboSource6301(device, interface)
    %   myLaser = ComboSource6301(device, interface, showmsg)
    %
    % NOTES:
    %     * The output parameter 'status' has the same meaning for all methods
    %           status   : == 0 when okay
    %                      != 0 when something went wrong
    %     * All parameter names and values are NOT case sensitive
    %     * Check for warnings and errors
    %     * VERIFIED CONFIGURATION: COM1, 9600 baud, CR terminator
    %     * This device uses Arroyo custom commands, NOT standard SCPI
    %
    % MAIN METHODS:
    %   Device Information:
    %     - getID()             : Get device identification string (*IDN?)
    %     - getVersion()        : Get firmware version (VER?)
    %     - getSerialNumber()   : Get serial number (SN?)
    %     - getError()          : Get last error code (ERR?)
    %     - getErrorString()    : Get last error description (ERRSTR?)
    %     - clear()             : Clear device status (*CLS)
    %     - setLocalMode()      : Return to local front panel control (LOCAL)
    %
    %   Laser Current Control:
    %     - setLaserCurrent(mA)      : Set laser drive current (LAS:LDI)
    %     - getLaserCurrent()        : Get laser current setpoint (LAS:LDI?)
    %     - setLaserCurrentLimit(mA) : Set current limit (LAS:LIM:LDI)
    %     - getLaserCurrentLimit()   : Get current limit (LAS:LIM:LDI?)
    %
    %   Laser Output Control:
    %     - enableLaser()       : Enable laser output (LAS:OUT 1)
    %     - disableLaser()      : Disable laser output (LAS:OUT 0)
    %     - isLaserEnabled()    : Query laser state (LAS:OUT?)
    %     - getLaserCondition() : Get laser status register (LAS:COND?)
    %
    %   TEC Temperature Control:
    %     - setTemperature(C)    : Set TEC temperature setpoint (TEC:T)
    %     - getTemperature()     : Get measured temperature (TEC:T?)
    %     - getTempSetpoint()    : Get temperature setpoint (TEC:SET:T?)
    %
    %   TEC Current Control:
    %     - getTECCurrent()          : Get TEC current (TEC:ITE?)
    %     - setTECCurrentLimit(A)    : Set TEC current limit (TEC:LIM:ITE)
    %     - getTECCurrentLimit()     : Get TEC current limit (TEC:LIM:ITE?)
    %
    %   TEC Output Control:
    %     - enableTEC()         : Enable TEC output (TEC:OUT 1)
    %     - disableTEC()        : Disable TEC output (TEC:OUT 0)
    %     - isTECEnabled()      : Query TEC state (TEC:OUT?)
    %
    %   TEC Mode Control:
    %     - setTECModeTemperature() : Set TEC to temperature mode (TEC:MODE:T)
    %     - setTECModeCurrent()     : Set TEC to current mode (TEC:MODE:ITE)
    %     - getTECMode()            : Get TEC mode (TEC:MODE?)
    %
    %   TEC PID Control:
    %     - setTECPID(p,i,d)    : Set PID parameters (TEC:PID)
    %     - getTECPID()         : Get PID parameters (TEC:PID?)
    %
    %   Temperature Limits:
    %     - setTECTempLimitHigh(C)   : Set max TEC temp limit (TEC:LIM:THI)
    %     - setTECTempLimitLow(C)    : Set min TEC temp limit (TEC:LIM:TLO)
    %     - setLaserTempLimitHigh(C) : Set max laser temp limit (LAS:LIM:THI)
    %
    %   Status and Safety:
    %     - getStatus()          : Get device status byte (*STB?)
    %     - getLaserCondition()  : Get laser condition register (LAS:COND?)
    %     - getTECCondition()    : Get TEC condition register (TEC:COND?)
    %     - getInterlockState()  : Get interlock digital input (DIO:IN? 0)
    %     - isInterlockClosed()  : Check if interlock is safe (DIO:IN? 0)
    %     - isOverTemp()         : Check over-temp from TEC:COND?
    %
    % PROPERTIES:
    %   Read-only:
    %     - ComboSourceVersion : Version of this class file
    %     - ComboSourceDate    : Release date of this class file
    %     - ErrorMessages      : Error list from device error buffer
    %
    % ---------------------------------------------------------------------
    % EXAMPLE USAGE:
    %
    %   % Create object and connect (VERIFIED: COM1, 9600 baud, CR terminator)
    %   myLaser = ComboSource6301('Arroyo-6301');
    %
    %   % Get device info
    %   disp(myLaser.getID());
    %   disp(myLaser.getVersion());
    %
    %   % Enable TEC and set temperature
    %   myLaser.setTECModeTemperature();
    %   myLaser.setTemperature(25);  % 25°C
    %   myLaser.enableTEC();
    %
    %   % Wait for temperature stabilization
    %   pause(30);
    %
    %   % Configure laser current limit and setpoint
    %   myLaser.setLaserCurrentLimit(150);  % Set limit to 150 mA
    %   myLaser.setLaserCurrent(100);       % Set current to 100 mA
    %
    %   % Enable laser
    %   myLaser.enableLaser();
    %
    %   % Monitor status
    %   fprintf('Temperature: %.2f °C\n', myLaser.getTemperature());
    %   fprintf('TEC Current: %.3f A\n', myLaser.getTECCurrent());
    %   fprintf('Laser Current: %.2f mA\n', myLaser.getLaserCurrent());
    %
    %   % Check safety status
    %   if myLaser.isInterlockClosed()
    %       disp('Interlock is closed (safe)');
    %   else
    %       disp('WARNING: Interlock is open!');
    %   end
    %
    %   % Disable laser and TEC
    %   myLaser.disableLaser();
    %   myLaser.disableTEC();
    %
    %   % Close connection
    %   myLaser.delete;
    %
    % ---------------------------------------------------------------------
    % HTW Dresden, faculty of electrical engineering
    %   for version and release date see properties 'ComboSourceVersion' and
    %   'ComboSourceDate'
    %
    % tested with
    %   - Matlab (version 24.1 = 2024a update 6) and
    %   - Instrument Control Toolbox (version 24.1)
    %   - NI-VISA 21.5 (download from NI, separate installation)
    %
    % known issues and planned extensions / fixes
    %   - none reported yet
    %
    % development, support and contact:
    %   - Florian Römer
    % ---------------------------------------------------------------------

    properties(Constant = true)
        ComboSourceVersion = '2.0.0';      % release version (updated for Arroyo commands)
        ComboSourceDate    = '2026-02-24'; % release date
    end

    properties(Dependent, SetAccess = private, GetAccess = public)
        ErrorMessages
    end

    % ---------------------------------------------------------------------
    methods(Static)
        
        function doc(className)
            %DOC Open HTML documentation in browser
            %
            %   DOC() opens the ComboSource6301 documentation.
            %   DOC(CLASSNAME) opens documentation for specified class.
            %
            %   This method opens the HTML documentation file using
            %   MATLAB's web browser.
            %
            %   Example:
            %       ComboSource6301.doc()
            %
            
            if nargin == 0
                className = mfilename('class');
            end

            htmlFile = which([className '.html']);
            if isempty(htmlFile)
                % Try to construct path manually
                classFile = which(className);
                if ~isempty(classFile)
                    [classPath, ~, ~] = fileparts(classFile);
                    htmlFile = fullfile(classPath, [className '.html']);
                end
            end
            
            if isfile(htmlFile)
                web(htmlFile, '-new', '-notoolbar');
            else
                error('ComboSource6301:doc', ...
                    'HTML documentation file not found: %s.html', className);
            end
        end
    end

    % ---------------------------------------------------------------------
    methods

        function obj = ComboSource6301(device, interface, showmsg)
            % Constructor for ComboSource6301 object
            %
            % Usage:
            %   myLaser = ComboSource6301(device)
            %   myLaser = ComboSource6301(device, interface)
            %   myLaser = ComboSource6301(device, interface, showmsg)
            %
            % Parameters:
            %   device    - device name from config file
            %   interface - 'visa-serial', 'visa-usb', or 'visa-tcpip'
            %   showmsg   - 'none', 'few', or 'all'

            % Check number of input arguments
            narginchk(0, 3);

            % Set default values when no input is given
            if nargin < 3 || isempty(showmsg)
                showmsg = 'few';
            end

            if nargin < 2 || isempty(interface)
                interface = '';
            end

            if nargin < 1 || isempty(device)
                device = '';
            end

            % Call superclass constructor with 'Other' as instrument type
            % Note: VisaIF requires 'Other' for Arroyo devices, not 'ComboSource6301'
            instrument = 'Other';
            obj = obj@VisaIF(device, interface, showmsg, instrument);

            if isempty(obj.Device)
                error('Initialization failed.');
            end

            % Display connection message
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  ComboSource6301 initialized successfully');
            end
        end

        function delete(obj)
            % Destructor - cleanup before closing connection
            
            % Display closing message
            if ~strcmpi(obj.ShowMessages, 'none') && ~isempty(obj.DeviceName)
                disp([obj.DeviceName ':']);
                disp('  Closing ComboSource6301 connection');
            end
        end

        % -----------------------------------------------------------------
        % Extend methods from super class (VisaIF)
        % Note: reset(), lock(), unlock() are not supported by Arroyo devices
        % -----------------------------------------------------------------

        % -----------------------------------------------------------------
        % Device Information Methods (Arroyo Commands)
        % -----------------------------------------------------------------

        function [status, idString] = getID(obj)
            % Get device identification string
            % Arroyo Command: *IDN?
            %
            % Usage:
            %   idString = myLaser.getID()
            %   [status, idString] = myLaser.getID()
            %
            % Returns:
            %   idString - Format: "Arroyo 6301 SN Ver Build"
            
            [status, idString] = obj.query('*IDN?');
            
            if nargout < 2
                status = idString;
            end
        end

        function [status, version] = getVersion(obj)
            % Get firmware version
            % Arroyo Command: VER?
            %
            % Usage:
            %   version = myLaser.getVersion()
            %   [status, version] = myLaser.getVersion()
            %
            % Returns:
            %   version - Firmware version string (e.g., "v2.23")
            
            [status, version] = obj.query('VER?');
            
            if nargout < 2
                status = version;
            end
        end

        function [status, serialNum] = getSerialNumber(obj)
            % Get device serial number
            % Arroyo Command: SN?
            %
            % Usage:
            %   serialNum = myLaser.getSerialNumber()
            %   [status, serialNum] = myLaser.getSerialNumber()
            %
            % Returns:
            %   serialNum - Serial number string
            
            [status, serialNum] = obj.query('SN?');
            
            if nargout < 2
                status = serialNum;
            end
        end

        function [status, errorCode] = getError(obj)
            % Get last error code from device
            % Arroyo Command: ERR?
            %
            % Usage:
            %   errorCode = myLaser.getError()
            %   [status, errorCode] = myLaser.getError()
            %
            % Returns:
            %   errorCode - Error number (0 = no error, 1-599 = error code)
            
            [status, response] = obj.query('ERR?');
            
            if status == 0
                errorCode = str2double(response);
            else
                errorCode = NaN;
            end
            
            if nargout < 2
                status = errorCode;
            end
        end

        function [status, errorMsg] = getErrorString(obj)
            % Get last error description string
            % Arroyo Command: ERRSTR?
            %
            % Usage:
            %   errorMsg = myLaser.getErrorString()
            %   [status, errorMsg] = myLaser.getErrorString()
            %
            % Returns:
            %   errorMsg - Error description text
            
            [status, errorMsg] = obj.query('ERRSTR?');
            
            if nargout < 2
                status = errorMsg;
            end
        end

        function status = clear(obj)
            % Clear device status and error queue
            % Arroyo Command: *CLS
            %
            % Usage:
            %   status = myLaser.clear()
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  Clearing device status');
            end

            status = obj.write('*CLS');

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Clear failed');
            end
        end

        function status = setLocalMode(obj)
            % Set device to local mode (front panel control)
            % Arroyo Command: LOCAL
            %
            % Usage:
            %   status = myLaser.setLocalMode()
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  Setting to local mode');
            end

            status = obj.write('LOCAL');

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Set local mode failed');
            end
        end

        % -----------------------------------------------------------------
        % Laser Current Control Methods (Arroyo Commands)
        % -----------------------------------------------------------------

        function status = setLaserCurrent(obj, currentMA)
            % Set laser drive current in mA
            % Arroyo Command: LAS:LDI <value>
            %
            % Usage:
            %   status = myLaser.setLaserCurrent(currentMA)
            %
            % Parameters:
            %   currentMA - Current setpoint in milliamperes (0 to hardware max)
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                fprintf('  Setting laser current to %.3f mA\n', currentMA);
            end

            status = obj.write(sprintf('LAS:LDI %.6f', currentMA));

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Set laser current failed');
            end
        end

        function [status, currentMA] = getLaserCurrent(obj)
            % Get laser current setpoint in mA
            % Arroyo Command: LAS:LDI?
            %
            % Usage:
            %   currentMA = myLaser.getLaserCurrent()
            %   [status, currentMA] = myLaser.getLaserCurrent()
            %
            % Returns:
            %   currentMA - Current setpoint in milliamperes
            
            [status, response] = obj.query('LAS:LDI?');
            
            if status == 0
                currentMA = str2double(response);
            else
                currentMA = NaN;
            end
            
            if nargout < 2
                status = currentMA;
            end
        end

        function status = setLaserCurrentLimit(obj, limitMA)
            % Set maximum laser current limit in mA
            % Arroyo Command: LAS:LIM:LDI <value>
            %
            % Usage:
            %   status = myLaser.setLaserCurrentLimit(limitMA)
            %
            % Parameters:
            %   limitMA - Maximum current limit in milliamperes
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                fprintf('  Setting laser current limit to %.3f mA\n', limitMA);
            end

            status = obj.write(sprintf('LAS:LIM:LDI %.6f', limitMA));

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Set laser current limit failed');
            end
        end

        function [status, limitMA] = getLaserCurrentLimit(obj)
            % Get maximum laser current limit in mA
            % Arroyo Command: LAS:LIM:LDI?
            %
            % Usage:
            %   limitMA = myLaser.getLaserCurrentLimit()
            %   [status, limitMA] = myLaser.getLaserCurrentLimit()
            %
            % Returns:
            %   limitMA - Maximum current limit in milliamperes
            
            [status, response] = obj.query('LAS:LIM:LDI?');
            
            if status == 0
                limitMA = str2double(response);
            else
                limitMA = NaN;
            end
            
            if nargout < 2
                status = limitMA;
            end
        end

        % -----------------------------------------------------------------
        % Laser Output Control Methods (Arroyo Commands)
        % -----------------------------------------------------------------

        function status = enableLaser(obj)
            % Enable laser output
            % Arroyo Command: LAS:OUT 1
            %
            % Usage:
            %   status = myLaser.enableLaser()
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  Enabling laser output');
            end

            status = obj.write('LAS:OUT 1');

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Enable laser failed');
            end
        end

        function status = disableLaser(obj)
            % Disable laser output
            % Arroyo Command: LAS:OUT 0
            %
            % Usage:
            %   status = myLaser.disableLaser()
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  Disabling laser output');
            end

            status = obj.write('LAS:OUT 0');

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Disable laser failed');
            end
        end

        function [status, isEnabled] = isLaserEnabled(obj)
            % Query laser output state
            % Arroyo Command: LAS:OUT?
            %
            % Usage:
            %   isEnabled = myLaser.isLaserEnabled()
            %   [status, isEnabled] = myLaser.isLaserEnabled()
            %
            % Returns:
            %   isEnabled - true if laser is on (1), false if off (0)
            
            [status, response] = obj.query('LAS:OUT?');
            
            if status == 0
                isEnabled = strcmpi(strtrim(response), '1');
            else
                isEnabled = false;
            end
            
            if nargout < 2
                status = isEnabled;
            end
        end

        % -----------------------------------------------------------------
        % TEC Temperature Control Methods (Arroyo Commands)
        % -----------------------------------------------------------------

        function status = setTemperature(obj, tempC)
            % Set TEC temperature setpoint in °C
            % Arroyo Command: TEC:T <value>
            %
            % Usage:
            %   status = myLaser.setTemperature(tempC)
            %
            % Parameters:
            %   tempC - Temperature setpoint in degrees Celsius
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                fprintf('  Setting temperature to %.2f °C\n', tempC);
            end

            status = obj.write(sprintf('TEC:T %.3f', tempC));

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Set temperature failed');
            end
        end

        function [status, tempC] = getTemperature(obj)
            % Get measured TEC temperature in °C
            % Arroyo Command: TEC:T?
            %
            % Usage:
            %   tempC = myLaser.getTemperature()
            %   [status, tempC] = myLaser.getTemperature()
            %
            % Returns:
            %   tempC - Measured temperature in degrees Celsius
            
            [status, response] = obj.query('TEC:T?');
            
            if status == 0
                tempC = str2double(response);
            else
                tempC = NaN;
            end
            
            if nargout < 2
                status = tempC;
            end
        end

        function [status, tempC] = getTempSetpoint(obj)
            % Get TEC temperature setpoint in °C
            % Arroyo Command: TEC:SET:T?
            %
            % Usage:
            %   tempC = myLaser.getTempSetpoint()
            %   [status, tempC] = myLaser.getTempSetpoint()
            %
            % Returns:
            %   tempC - Temperature setpoint in degrees Celsius
            
            [status, response] = obj.query('TEC:SET:T?');
            
            if status == 0
                tempC = str2double(response);
            else
                tempC = NaN;
            end
            
            if nargout < 2
                status = tempC;
            end
        end

        function [status, tecCurrentA] = getTECCurrent(obj)
            % Get TEC (thermoelectric cooler) current in A
            % Arroyo Command: TEC:ITE?
            %
            % Usage:
            %   tecCurrentA = myLaser.getTECCurrent()
            %   [status, tecCurrentA] = myLaser.getTECCurrent()
            %
            % Returns:
            %   tecCurrentA - TEC current in amperes
            
            [status, response] = obj.query('TEC:ITE?');
            
            if status == 0
                tecCurrentA = str2double(response);
            else
                tecCurrentA = NaN;
            end
            
            if nargout < 2
                status = tecCurrentA;
            end
        end

        function status = setTECCurrentLimit(obj, limitA)
            % Set TEC current limit in A
            % Arroyo Command: TEC:LIM:ITE <value>
            %
            % Usage:
            %   status = myLaser.setTECCurrentLimit(limitA)
            %
            % Parameters:
            %   limitA - TEC current limit in amperes
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                fprintf('  Setting TEC current limit to %.3f A\n', limitA);
            end

            status = obj.write(sprintf('TEC:LIM:ITE %.6f', limitA));

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Set TEC current limit failed');
            end
        end

        function [status, limitA] = getTECCurrentLimit(obj)
            % Get TEC current limit in A
            % Arroyo Command: TEC:LIM:ITE?
            %
            % Usage:
            %   limitA = myLaser.getTECCurrentLimit()
            %   [status, limitA] = myLaser.getTECCurrentLimit()
            %
            % Returns:
            %   limitA - TEC current limit in amperes
            
            [status, response] = obj.query('TEC:LIM:ITE?');
            
            if status == 0
                limitA = str2double(response);
            else
                limitA = NaN;
            end
            
            if nargout < 2
                status = limitA;
            end
        end

        % -----------------------------------------------------------------
        % TEC Output Control Methods (Arroyo Commands)
        % -----------------------------------------------------------------

        function status = enableTEC(obj)
            % Enable TEC output
            % Arroyo Command: TEC:OUT 1
            %
            % Usage:
            %   status = myLaser.enableTEC()
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  Enabling TEC output');
            end

            status = obj.write('TEC:OUT 1');

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Enable TEC failed');
            end
        end

        function status = disableTEC(obj)
            % Disable TEC output
            % Arroyo Command: TEC:OUT 0
            %
            % Usage:
            %   status = myLaser.disableTEC()
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  Disabling TEC output');
            end

            status = obj.write('TEC:OUT 0');

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Disable TEC failed');
            end
        end

        function [status, isEnabled] = isTECEnabled(obj)
            % Query TEC output state
            % Arroyo Command: TEC:OUT?
            %
            % Usage:
            %   isEnabled = myLaser.isTECEnabled()
            %   [status, isEnabled] = myLaser.isTECEnabled()
            %
            % Returns:
            %   isEnabled - true if TEC is on (1), false if off (0)
            
            [status, response] = obj.query('TEC:OUT?');
            
            if status == 0
                isEnabled = strcmpi(strtrim(response), '1');
            else
                isEnabled = false;
            end
            
            if nargout < 2
                status = isEnabled;
            end
        end

        % -----------------------------------------------------------------
        % TEC Mode Control Methods (Arroyo Commands)
        % -----------------------------------------------------------------

        function status = setTECModeTemperature(obj)
            % Set TEC to temperature control mode
            % Arroyo Command: TEC:MODE:T
            %
            % Usage:
            %   status = myLaser.setTECModeTemperature()
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  Setting TEC to temperature mode');
            end

            status = obj.write('TEC:MODE:T');

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Set TEC mode failed');
            end
        end

        function status = setTECModeCurrent(obj)
            % Set TEC to current control mode
            % Arroyo Command: TEC:MODE:ITE
            %
            % Usage:
            %   status = myLaser.setTECModeCurrent()
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                disp('  Setting TEC to current mode');
            end

            status = obj.write('TEC:MODE:ITE');

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Set TEC mode failed');
            end
        end

        function [status, mode] = getTECMode(obj)
            % Get TEC control mode
            % Arroyo Command: TEC:MODE?
            %
            % Usage:
            %   mode = myLaser.getTECMode()
            %   [status, mode] = myLaser.getTECMode()
            %
            % Returns:
            %   mode - 'T' for temperature mode, 'ITE' for current mode
            
            [status, mode] = obj.query('TEC:MODE?');
            
            if status == 0
                mode = strtrim(mode);
            else
                mode = '';
            end
            
            if nargout < 2
                status = mode;
            end
        end

        % -----------------------------------------------------------------
        % TEC PID Control Methods (Arroyo Commands)
        % -----------------------------------------------------------------

        function status = setTECPID(obj, p, i, d)
            % Set TEC PID control parameters
            % Arroyo Command: TEC:PID <P>,<I>,<D>
            %
            % Usage:
            %   status = myLaser.setTECPID(p, i, d)
            %
            % Parameters:
            %   p - Proportional gain
            %   i - Integral gain
            %   d - Derivative gain
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                fprintf('  Setting TEC PID to P=%.3f, I=%.3f, D=%.3f\n', p, i, d);
            end

            status = obj.write(sprintf('TEC:PID %.6f,%.6f,%.6f', p, i, d));

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Set TEC PID failed');
            end
        end

        function [status, p, i, d] = getTECPID(obj)
            % Get TEC PID control parameters
            % Arroyo Command: TEC:PID?
            %
            % Usage:
            %   [p, i, d] = myLaser.getTECPID()
            %   [status, p, i, d] = myLaser.getTECPID()
            %
            % Returns:
            %   p - Proportional gain
            %   i - Integral gain
            %   d - Derivative gain
            
            [status, response] = obj.query('TEC:PID?');
            
            if status == 0
                values = sscanf(response, '%f,%f,%f');
                if length(values) == 3
                    p = values(1);
                    i = values(2);
                    d = values(3);
                else
                    p = NaN;
                    i = NaN;
                    d = NaN;
                end
            else
                p = NaN;
                i = NaN;
                d = NaN;
            end
            
            if nargout < 4
                % Return as array if fewer outputs requested
                status = [p, i, d];
            end
        end

        % -----------------------------------------------------------------
        % Temperature Limit Methods (Arroyo Commands)
        % -----------------------------------------------------------------

        function status = setTECTempLimitHigh(obj, tempC)
            % Set maximum TEC temperature limit in °C
            % Arroyo Command: TEC:LIM:THI <value>
            %
            % Usage:
            %   status = myLaser.setTECTempLimitHigh(tempC)
            %
            % Parameters:
            %   tempC - Maximum temperature limit in degrees Celsius
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                fprintf('  Setting TEC max temperature limit to %.2f °C\n', tempC);
            end

            status = obj.write(sprintf('TEC:LIM:THI %.3f', tempC));

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Set TEC max temperature limit failed');
            end
        end

        function status = setTECTempLimitLow(obj, tempC)
            % Set minimum TEC temperature limit in °C
            % Arroyo Command: TEC:LIM:TLO <value>
            %
            % Usage:
            %   status = myLaser.setTECTempLimitLow(tempC)
            %
            % Parameters:
            %   tempC - Minimum temperature limit in degrees Celsius
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                fprintf('  Setting TEC min temperature limit to %.2f °C\n', tempC);
            end

            status = obj.write(sprintf('TEC:LIM:TLO %.3f', tempC));

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Set TEC min temperature limit failed');
            end
        end

        function status = setLaserTempLimitHigh(obj, tempC)
            % Set maximum laser temperature limit in °C
            % Arroyo Command: LAS:LIM:THI <value>
            %
            % Usage:
            %   status = myLaser.setLaserTempLimitHigh(tempC)
            %
            % Parameters:
            %   tempC - Maximum laser temperature limit in degrees Celsius
            
            if ~strcmpi(obj.ShowMessages, 'none')
                disp([obj.DeviceName ':']);
                fprintf('  Setting laser max temperature limit to %.2f °C\n', tempC);
            end

            status = obj.write(sprintf('LAS:LIM:THI %.3f', tempC));

            if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
                disp('  Set laser max temperature limit failed');
            end
        end

        % -----------------------------------------------------------------
        % Status and Condition Methods (Arroyo Commands)
        % -----------------------------------------------------------------

        function [status, conditionCode] = getLaserCondition(obj)
            % Get laser condition register
            % Arroyo Command: LAS:COND?
            %
            % Usage:
            %   conditionCode = myLaser.getLaserCondition()
            %   [status, conditionCode] = myLaser.getLaserCondition()
            %
            % Returns:
            %   conditionCode - Laser condition register value (bitfield)
            %                   Bit meanings depend on device configuration
            
            [status, response] = obj.query('LAS:COND?');
            
            if status == 0
                conditionCode = str2double(response);
            else
                conditionCode = NaN;
            end
            
            if nargout < 2
                status = conditionCode;
            end
        end

        function [status, conditionCode] = getTECCondition(obj)
            % Get TEC condition register
            % Arroyo Command: TEC:COND?
            %
            % Usage:
            %   conditionCode = myLaser.getTECCondition()
            %   [status, conditionCode] = myLaser.getTECCondition()
            %
            % Returns:
            %   conditionCode - TEC condition register value (bitfield)
            %                   Check manual for bit definitions
            
            [status, response] = obj.query('TEC:COND?');
            
            if status == 0
                conditionCode = str2double(response);
            else
                conditionCode = NaN;
            end
            
            if nargout < 2
                status = conditionCode;
            end
        end

        function [status, statusByte] = getStatus(obj)
            % Get device status byte
            % Arroyo Command: *STB?
            %
            % Usage:
            %   statusByte = myLaser.getStatus()
            %   [status, statusByte] = myLaser.getStatus()
            %
            % Returns:
            %   statusByte - Status byte value
            
            [status, response] = obj.query('*STB?');
            
            if status == 0
                statusByte = str2double(response);
            else
                statusByte = NaN;
            end
            
            if nargout < 2
                status = statusByte;
            end
        end

        function [status, interlockState] = getInterlockState(obj)
            % Check interlock input state via digital I/O
            % Arroyo Command: DIO:IN? 0
            %
            % Usage:
            %   interlockState = myLaser.getInterlockState()
            %   [status, interlockState] = myLaser.getInterlockState()
            %
            % Returns:
            %   interlockState - 1 if interlock closed (safe), 0 if open
            
            [status, response] = obj.query('DIO:IN? 0');
            
            if status == 0
                interlockState = str2double(response);
            else
                interlockState = NaN;
            end
            
            if nargout < 2
                status = interlockState;
            end
        end

        function [status, isClosed] = isInterlockClosed(obj)
            % Check if interlock is closed (safe to operate)
            % Arroyo Command: DIO:IN? 0
            %
            % Usage:
            %   isClosed = myLaser.isInterlockClosed()
            %   [status, isClosed] = myLaser.isInterlockClosed()
            %
            % Returns:
            %   isClosed - true if interlock is closed (safe), false if open
            
            [status, response] = obj.query('DIO:IN? 0');
            
            if status == 0
                interlockState = str2double(response);
                isClosed = (interlockState == 1);
            else
                isClosed = false;
            end
            
            if nargout < 2
                status = isClosed;
            end
        end

        function [status, isOverTemp] = isOverTemp(obj)
            % Check over-temperature condition using TEC condition register
            % Arroyo Command: TEC:COND?
            %
            % Usage:
            %   isOverTemp = myLaser.isOverTemp()
            %   [status, isOverTemp] = myLaser.isOverTemp()
            %
            % Returns:
            %   isOverTemp - true if over-temperature detected, false otherwise
            %
            % Note: TEC:COND register bit definitions (from Arroyo manual):
            %   Bit 0 (1)    : Current limit
            %   Bit 1 (2)    : Voltage limit
            %   Bit 2 (4)    : Sensor limit
            %   Bit 3 (8)    : Temperature high limit
            %   Bit 4 (16)   : Temperature low limit
            %   Bit 5 (32)   : Sensor shorted
            %   Bit 6 (64)   : Sensor open
            %   Bit 7 (128)  : TEC open circuit
            %   Bit 12 (4096): Thermal run-away
            
            [status, response] = obj.query('TEC:COND?');
            
            if status == 0
                conditionCode = str2double(response);
                % Check bit 3 (temperature high limit) and bit 12 (thermal run-away)
                % bitget uses 1-based indexing: bit 3 = index 4, bit 12 = index 13
                isOverTemp = bitget(conditionCode, 4) == 1 || ...
                             bitget(conditionCode, 13) == 1;
            else
                isOverTemp = false;
            end
            
            if nargout < 2
                status = isOverTemp;
            end
        end

        % -----------------------------------------------------------------
        % Property Accessors
        % -----------------------------------------------------------------

        function errorMsgs = get.ErrorMessages(obj)
            % Get error messages from device using Arroyo commands
            errorMsgs = {};
            
            % Read all errors from queue using ERR? and ERRSTR?
            for i = 1:10 % Max 10 errors
                [~, errCode] = obj.query('ERR?');
                errorNum = str2double(errCode);
                
                if errorNum == 0
                    break; % No more errors
                end
                
                % Get error description
                [~, errStr] = obj.query('ERRSTR?');
                errorMsgs{end+1} = sprintf('%d: %s', errorNum, strtrim(errStr)); %#ok<AGROW>
            end
            
            if isempty(errorMsgs)
                errorMsgs = {'No errors'};
            end
        end

    end
end
