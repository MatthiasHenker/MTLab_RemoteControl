classdef RotaryPlatformDriver < handle
%ROTARYPLATFORMDRIVER Control interface for HTWD-DT-2025 rotary platform
%
%   For full HTML documentation, run: RotaryPlatformDriver.doc
%
%   ROTARYPLATFORMDRIVER provides a MATLAB interface to control a custom
%   rotary platform via serial communication using the VisaIF class.
%   The class handles all SCPI commands for position control, limit 
%   configuration, and status queries.
%
%   The device communicates at 115200 baud, 8N1, LF terminator and
%   echoes every command sent to it. Echo handling is managed by VisaIF.
%
%   REQUIREMENTS:
%       - VisaIF class must be in MATLAB path
%       - Device must be configured in VisaIF_HTW_Labs.csv
%       - Default configuration: HTWD-DT-2025 on COM7
%
%   BASIC USAGE:
%       platform = RotaryPlatformDriver();        % Use default COM7
%       platform = RotaryPlatformDriver('COM13'); % Override to COM13
%       platform.setAngle(90);
%       pos = platform.getPosition();
%       platform.delete();
%
%   ADVANCED USAGE:
%       % Configure safety limits
%       platform = RotaryPlatformDriver('COM5');
%       upper = platform.getUpperLimit();
%       lower = platform.getLowerLimit();
%       
%       % Move to position and wait
%       platform.setAngle(180);
%       pause(2);
%       reached = platform.isReached();
%       
%       % Check motor status
%       enabled = platform.isMotorEnabled();
%
%   SEE ALSO:
%       VisaIF, serialport, configureTerminator
%
    
    properties(Constant = true)
        RotaryPlatformDriverVersion = '2.1.0';
        RotaryPlatformDriverDate    = '2026-02-25';
    end
    
    properties(Access = private)
        VisaObj         % VisaIF object for communication
        DeviceName char % Device name in config file
    end

    methods(Static)
        function doc(className)
            %DOC Open HTML documentation in browser
            %
            %   DOC() opens the RotaryPlatformDriver documentation.
            %   DOC(CLASSNAME) opens documentation for specified class.
            %
            %   This method opens the HTML documentation file using
            %   MATLAB's web browser.
            %
            %   Example:
            %       RotaryPlatformDriver.doc()
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
                error('RotaryPlatformDriver:doc', ...
                    'HTML documentation file not found: %s.html', className);
            end
        end
    end

    methods
        function obj = RotaryPlatformDriver(comPort)
            %ROTARYPLATFORMDRIVER Constructor
            %
            %   OBJ = ROTARYPLATFORMDRIVER(COMPORT) creates a connection
            %   to the rotary platform via VisaIF.
            %
            %   COMPORT: optional COM port override (e.g., 'COM13')
            %
            
            deviceName = 'HTWD-DT-2025';
            portOverride = '';
            
            if nargin < 1 || isempty(comPort)
                portOverride = '';
            elseif iscell(comPort)
                if numel(comPort) >= 2
                    deviceName = comPort{1};
                    portOverride = comPort{2};
                end
            elseif ischar(comPort) || isstring(comPort)
                portOverride = char(comPort);
            end
            
            obj.DeviceName = deviceName;
            
            try
                if isempty(portOverride)
                    obj.VisaObj = VisaIF(deviceName, 'visa-serial', 'none');
                else
                    obj.VisaObj = VisaIF({deviceName, portOverride}, 'visa-serial', 'none');
                end
            catch ME
                error('RotaryPlatformDriver:constructor', ...
                    'Failed to create VisaIF connection:\n%s\n\nMake sure:\n1) Device is configured in VisaIF_HTW_Labs.csv\n2) COM port is correct\n3) Device is powered on\n4) No other program is using the port', ...
                    ME.message);
            end
            
            fprintf('RotaryPlatformDriver connected via VisaIF\n');
            fprintf('Device: %s\n', obj.DeviceName);
            fprintf('Port: %s, Settings: 115200 baud, 8N1, LF terminator\n', obj.VisaObj.SerialPort);
            
            try
                fprintf('Sending *IDN? command...\n');
                id = obj.getID();
                fprintf('Device: %s\n', id);
                
                % Clear any errors in the queue from initialization
                obj.clearErrorQueue();
            catch ME
                warning('RotaryPlatformDriver:connection', ...
                    'Could not communicate with device:\n%s\nCheck: 1) Device is powered on, 2) Correct COM port, 3) No other program is using the port', ...
                    ME.message);
            end
        end

        function delete(obj)
            %DELETE Destructor - close VisaIF connection
            %
            if ~isempty(obj.VisaObj) && isvalid(obj.VisaObj)
                obj.VisaObj.delete();
                fprintf('RotaryPlatformDriver disconnected\n');
            end
        end

        % -----------------------------------------------------------------
        % Methods for device commands
        % -----------------------------------------------------------------
        
        function idString = getID(obj)
            %GETID Get device identification string
            %
            idString = obj.queryDevice('*IDN?');
        end
        
        function errorMsg = getError(obj)
            %GETERROR Get error from error queue
            %
            errorMsg = obj.queryDevice('SYSTem:ERRor?');
        end
        
        function lockLocal(obj)
            %LOCKLOCAL Lock local control at device
            %
            obj.writeDevice('SYSTem:LOCal:LOCK');
        end
        
        function unlockLocal(obj)
            %UNLOCKLOCAL Unlock local control at device
            %
            obj.writeDevice('SYSTem:LOCal:UNLock');
        end
        
        function locked = isLocked(obj)
            %ISLOCKED Query if local control is locked
            %
            response = obj.queryDevice('SYSTem:LOCal:LOCK?');
            locked = str2double(response) == 1;
        end
        
        function setAngle(obj, angle)
            %SETANGLE Set target angle in degrees
            %
            obj.writeDevice(['ROTAtion:ANGLE ' num2str(angle)]);
        end
        
        function angle = getTargetAngle(obj)
            %GETTARGETANGLE Query target angle in degrees
            %
            response = obj.queryDevice('ROTAtion:ANGLE?');
            angle = str2double(response);
        end
        
        function angle = getPosition(obj)
            %GETPOSITION Query actual position in degrees
            %
            response = obj.queryDevice('ROTAtion:POSition?');
            angle = str2double(response);
        end
        
        function reached = isReached(obj)
            %ISREACHED Query if target position is reached
            %
            response = obj.queryDevice('ROTAtion:REACHED?');
            reached = str2double(response) == 1;
        end
        
        function setUpperLimit(obj, angle)
            %SETUPPERLIMIT Set upper angle safety limit
            %
            obj.writeDevice(['ROTAtion:LIMit:UPPer ' num2str(angle)]);
        end
        
        function angle = getUpperLimit(obj)
            %GETUPPERLIMIT Query upper angle safety limit
            %
            response = obj.queryDevice('ROTAtion:LIMit:UPPer?');
            angle = str2double(response);
        end
        
        function setLowerLimit(obj, angle)
            %SETLOWERLIMIT Set lower angle safety limit
            %
            obj.writeDevice(['ROTAtion:LIMit:LOWer ' num2str(angle)]);
        end
        
        function angle = getLowerLimit(obj)
            %GETLOWERLIMIT Query lower angle safety limit
            %
            response = obj.queryDevice('ROTAtion:LIMit:LOWer?');
            angle = str2double(response);
        end
        
        function enabled = isMotorEnabled(obj)
            %ISMOTORENABLED Query if motor is currently active
            %
            response = obj.queryDevice('MOTOR:ENABLED?');
            enabled = str2double(response) == 1;
        end
        
        function enabled = isMotorEnableLocal(obj)
            %ISMOTORENABLELOCAL Query if green enable button is pressed
            %
            response = obj.queryDevice('MOTOR:ENABLELOCal?');
            enabled = str2double(response) == 1;
        end
        
        function enabled = isMotorEnableRemote(obj)
            %ISMOTORENABLEREMOTE Query remote motor enable status
            %
            response = obj.queryDevice('MOTOR:ENABLEREMote?');
            enabled = str2double(response) == 1;
        end
        
        function setMotorEnableRemote(obj, enable)
            %SETMOTORENABLEREMOTE Set remote motor enable status
            %
            value = double(logical(enable));
            obj.writeDevice(['MOTOR:ENABLEREMote ' num2str(value)]);
        end
        
        function lockout = isMotorVoltLockout(obj)
            %ISMOTORVOLTLOCKOUT Query if under-voltage lockout is active
            %
            response = obj.queryDevice('MOTOR:VOLTLOCKout?');
            lockout = str2double(response) == 1;
        end
        
    end

    methods (Access = private)
        function writeDevice(obj, cmd)
            % Write command to device using VisaIF
            obj.VisaObj.write(cmd);
        end
        
        function response = queryDevice(obj, cmd)
            % Query device using VisaIF
            responseRaw = obj.VisaObj.query(cmd);
            response = strtrim(char(responseRaw));
        end
        
        function clearErrorQueue(obj)
            % Clear all errors from the error queue
            % Read errors until we get "No error"
            maxAttempts = 10;
            for i = 1:maxAttempts
                err = obj.queryDevice('SYSTem:ERRor?');
                if contains(err, '0,') || contains(err, 'No error')
                    break;
                end
            end
        end
    end
end
