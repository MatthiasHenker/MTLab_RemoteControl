classdef SMUMacros < handle
    % SMUMacros class for Keithley 2450 SMU
    % Provides device-specific macros for SMU class operations
    % Located in +SMU/+Keithley/+Model2450 package
    %
    % Modeled after ScopeMacros for consistent VISA communication and error handling

    properties(Constant = true)
        MacrosVersion = '0.9.0';      % Updated release version
        MacrosDate    = '2025-07-10'; % Updated release date
    end

    properties(Dependent, SetAccess = private, GetAccess = public)
        ShowMessages       logical
        OutputState        double % 0 = 'off', 1 = 'on', -1 = 'unknown'
        ErrorMessages      char
    end

    properties(SetAccess = private, GetAccess = private)
        VisaIFobj         % Reference to SMU object for communication
    end

    % ------- basic methods -----------------------------------------------
    methods
        function obj = SMUMacros(VisaIFobj)
            % Constructor

            obj.VisaIFobj = VisaIFobj;

            if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                disp(['SMUMacros initialized for ' obj.VisaIFobj.Device]);
            end
        end

        function delete(obj)
            % destructor

            if obj.ShowMessages
                disp(['Object destructor called for class ''' ...
                    class(obj) '''.']);
            end
        end

        function status = runAfterOpen(obj)
            % execute some first configuration commands

            % init output
            status = NaN;

            % add some device specific commands:
            %
            % switch off output for safety reasons
            if obj.VisaIFobj.write(':OUTP OFF')
                status = -1;
            end

            % ...

            % wait for operation complete
            obj.VisaIFobj.opc;
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
            if obj.VisaIFobj.write(':OUTP OFF')
                status = -1;
            end

            % ...

            % wait for operation complete
            obj.VisaIFobj.opc;
            % ...

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = reset(obj)
            % reset the SMU to default settings

            % init output
            status = NaN;

            % use standard reset command (Factory Default)
            if obj.VisaIFobj.write('*RST')
                status = -1;
            end

            % clear status (event logs and error queue)
            if obj.VisaIFobj.write('*CLS')
                status = -1;
            end

            % reconfigure device after reset
            if obj.runAfterOpen()
                status = -1;
            end

            % wait for operation complete
            obj.VisaIFobj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = clear(obj)
            % clears the event registers and queues

            % init output
            status = -1;

            % clear status (event logs and error queue)
            if obj.VisaIFobj.write('*CLS')
                status = -1;
            end

            % wait for operation complete
            obj.VisaIFobj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = outputEnable(obj)

            status = -1; % default to error state

            if obj.VisaIFobj.write(':OUTP ON')
                status = -1;
            end

            % wait for operation complete
            obj.VisaIFobj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = outputDisable(obj)

            status = -1; % default to error state

            if obj.VisaIFobj.write(':OUTP OFF')
                status = -1;
            end

            % wait for operation complete
            obj.VisaIFobj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end






        % ToDo
        function status = configureSenseMode(obj, varargin)
            % Configure sense mode (2-wire or 4-wire)
            % Expected varargin: 'function', 'mode'
            % function: 'VOLTAGE', 'CURRENT', 'RESISTANCE'
            % mode: '2WIRE', '4WIRE'

            try
                parser = inputParser;
                addParameter(parser, 'function', '', @ischar);
                addParameter(parser, 'mode', '', @ischar);
                parse(parser, varargin{:});

                func = upper(parser.Results.function);
                mode = upper(parser.Results.mode);

                if ~ismember(func, {'VOLTAGE', 'CURRENT', 'RESISTANCE'})
                    disp(['  Invalid function: ' func]);
                    status = -1;
                    return;
                end

                if ~ismember(mode, {'2WIRE', '4WIRE'})
                    disp(['  Invalid sense mode: ' mode]);
                    status = -1;
                    return;
                end

                % Map function to SCPI function name
                switch func
                    case 'VOLTAGE'
                        scpiFunc = 'VOLT';
                    case 'CURRENT'
                        scpiFunc = 'CURR';
                    case 'RESISTANCE'
                        scpiFunc = 'RES';
                end

                % Set sense mode
                if strcmp(mode, '4WIRE')
                    cmd = sprintf(':SENS:%s:RSEN ON', scpiFunc);
                else % 2WIRE
                    cmd = sprintf(':SENS:%s:RSEN OFF', scpiFunc);
                end
                obj.VisaIFobj.write(cmd);
                disp(['  sent: ' strtrim(cmd)]);

                obj.VisaIFobj.opc;
                status = 0;
            catch ME
                status = -1;
            end
            if isnan(status)
                status = 0;
            end
            if status ~= 0
                disp('  configureSenseMode failed');
            end
            return
        end
        %%

        % mySMU.configureSource('function', 'VOLTAGE', 'level', '1','range', '20');
        function status = configureSource(obj, varargin)
            % Configure source function and parameters
            % Expected varargin: 'function', 'level', 'limit', 'range'
            status = -1; % Default to error state

            try
                
                % Input parameter parsing
                parser = inputParser;
                addParameter(parser, 'function', '', @ischar);
                addParameter(parser, 'level', '', @ischar);
                addParameter(parser, 'limit', '', @ischar);
                addParameter(parser, 'range', '', @ischar);
                parse(parser, varargin{:});

                func = upper(parser.Results.function);
                level = parser.Results.level;
                %limit = parser.Results.limit;
                range = parser.Results.range;

                % Validate function type
                if ~isempty(func) && ~ismember(func, {'VOLTAGE', 'CURRENT'})
                    error('Invalid function specified. Must be ''voltage'' or ''current''');
                end

                % Configure source function
                if ~isempty(func)
                    switch func
                        case 'VOLTAGE'
                            scpiFunc = 'VOLT';
                        case 'CURRENT'
                            scpiFunc = 'CURR';
                        otherwise
                            error('Unexpected function value');
                    end
                    cmd = sprintf('SOUR:FUNC %s', scpiFunc);
                    if ischar(cmd)
                        disp(['  Sending to SMU: ' cmd]);
                        obj.VisaIFobj.write(cmd);
                        pause(0.1);
                    end
                end

                % Configure source level
                if ~isempty(level)
                    if strcmp(func, 'VOLTAGE')
                        cmd = sprintf('SOUR:VOLT:LEV %s', level);
                    elseif strcmp(func, 'CURRENT')
                        cmd = sprintf('SOUR:CURR:LEV %s', level);
                    end
                    if ischar(cmd)
                        disp(['  Sending to SMU: ' cmd]);
                        obj.VisaIFobj.write(cmd);
                        pause(0.1);
                    else
                        error('Invalid command format for source level: not text');
                    end
                end


                % Configure range (Worked)
                if ~isempty(range)
                    if strcmp(range, 'AUTO')
                        if strcmp(func, 'VOLTAGE')
                            cmd = 'SOUR:VOLT:RANG:AUTO ON';
                        elseif strcmp(func, 'CURRENT')
                            cmd = 'SOUR:CURR:RANG:AUTO ON';
                        end
                    else
                        % Validate range as a numeric value
                        rangeValue = str2double(range);
                        if isnan(rangeValue)
                            error('Invalid range value: must be ''AUTO'' or a numeric value (e.g., ''1'', ''20'')');
                        end
                        if strcmp(func, 'VOLTAGE')
                            cmd = sprintf('SOUR:VOLT:RANG %s', range);
                        elseif strcmp(func, 'CURRENT')
                            cmd = sprintf('SOUR:CURR:RANG %s', range);
                        end
                    end
                    if ischar(cmd)
                        disp(['  Sending to SMU: ' cmd]);
                        obj.VisaIFobj.write(cmd);
                        pause(0.1);
                    else
                        error('Invalid command format for source range: not text');
                    end
                end

                obj.VisaIFobj.opc;
                status = 0; % Success
            catch ME
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp(['Error in configureSource: ' ME.message]);
                end
            end
        end
        %%
        %Tested, Work
        %mySMU.configureMeasure('function', 'Current');
        function status = configureMeasure(obj, varargin)
            % Configure measurement function (Voltage, Current, Resistance, Power)
            % Expected varargin: 'function', 'range', 'nplc'
            % Does not perform measurement, only sets sense function
            status = -1; % Default to error state

            try
                
                % Input parameter parsing
                parser = inputParser;
                addParameter(parser, 'function', '', @ischar);
                addParameter(parser, 'range', '', @ischar);
                addParameter(parser, 'nplc', '', @ischar);
                parse(parser, varargin{:});

                func = upper(parser.Results.function);
                range = parser.Results.range;
                nplc = parser.Results.nplc;

                % Validate function type
                if ~isempty(func) && ~ismember(func, {'VOLTAGE', 'CURRENT', 'RESISTANCE', 'POWER'})
                    error('Invalid function specified. Must be ''voltage'', ''current'', ''resistance'', or ''power''');
                end

                % Clear error queue
                cmd = '*CLS';
                if ischar(cmd)
                    disp(['  Sending to SMU: ' cmd]);
                    obj.VisaIFobj.write(cmd);
                    pause(0.2);
                end

                % Configure measurement function
                if ~isempty(func)
                    if strcmp(func, 'POWER')
                        cmd = 'SENS:FUNC "VOLT"';
                    else
                        switch func
                            case 'VOLTAGE'
                                scpiFunc = 'VOLT';
                            case 'CURRENT'
                                scpiFunc = 'CURR';
                            case 'RESISTANCE'
                                scpiFunc = 'RES';
                            otherwise
                                error('Unexpected function value');
                        end
                        cmd = sprintf('SENS:FUNC "%s"', scpiFunc);
                    end

                    if ischar(cmd)
                        disp(['  Sending to SMU: ' cmd]);
                        obj.VisaIFobj.write(cmd);
                        pause(0.1);
                    end
                end

                % Configure range
                if ~isempty(range)
                    if strcmp(func, 'POWER')
                        scpiFunc = 'VOLT';
                    else
                        switch func
                            case 'VOLTAGE'
                                scpiFunc = 'VOLT';
                            case 'CURRENT'
                                scpiFunc = 'CURR';
                            case 'RESISTANCE'
                                scpiFunc = 'RES';
                        end
                    end
                    if strcmp(range, 'AUTO')
                        cmd = sprintf('SENS:%s:RANG:AUTO ON', scpiFunc);
                    else
                        cmd = sprintf('SENS:%s:RANG %s', scpiFunc, range);
                    end
                    if ischar(cmd)
                        disp(['  Sending to SMU: ' cmd]);
                        obj.VisaIFobj.write(cmd);
                        pause(0.1);
                    end
                end

                % Configure NPLC
                if ~isempty(nplc)
                    if strcmp(func, 'POWER')
                        scpiFunc = 'VOLT';
                    else
                        switch func
                            case 'VOLTAGE'
                                scpiFunc = 'VOLT';
                            case 'CURRENT'
                                scpiFunc = 'CURR';
                            case 'RESISTANCE'
                                scpiFunc = 'RES';
                        end
                    end
                    cmd = sprintf('SENS:%s:NPLC %s', scpiFunc, nplc);
                    if ischar(cmd)
                        disp(['  Sending to SMU: ' cmd]);
                        obj.VisaIFobj.write(cmd);
                        pause(0.1);
                    end
                end

                status = 0; % Success
            catch ME
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp(['Error in configureMeasure: ' ME.message]);
                end
            end
        end
        %%

        function meas = measure(obj, varargin)
            % Perform a measurement
            % Returns struct with status, value, unit, function
            % Displays measurement result if ShowMessages is 'few' or 'all'
            meas = struct('status', -1, 'value', NaN, 'unit', '', 'function', '');

            try
                
                % Clear error queue
                cmd = '*CLS';
                if ischar(cmd)
                    disp(['  Sending to SMU: ' cmd]);
                    obj.VisaIFobj.write(cmd);
                    pause(0.2);
                end

                % Get requested function from varargin
                parser = inputParser;
                addParameter(parser, 'function', '', @ischar);
                parse(parser, varargin{:});
                requestedFunc = upper(parser.Results.function);

                % Query current sense function
                cmd = 'SENS:FUNC?';
                disp(['  Sending to SMU: ' cmd]);
                senseFunc = obj.VisaIFobj.query(cmd);
                % Convert uint8 to char if necessary
                if isa(senseFunc, 'uint8')
                    senseFunc = char(senseFunc);
                end
                senseFunc = strtrim(senseFunc);

                if contains(senseFunc, '"VOLT') && ~strcmp(requestedFunc, 'POWER')
                    meas.function = 'VOLTAGE';
                    meas.unit = 'V';
                    cmd = ':MEAS?';
                    disp(['  Sending to SMU: ' cmd]);
                    response = obj.VisaIFobj.query(cmd);
                    if isa(response, 'uint8')
                        response = char(response);
                    end
                    parts = split(response, ',');
                    meas.value = str2double(parts{1});
                    if isnan(meas.value)
                        error('Invalid measurement value received');
                    end
                    meas.status = 0;

                elseif contains(senseFunc, '"CURR')
                    meas.function = 'CURRENT';
                    meas.unit = 'A';
                    cmd = ':MEAS?';
                    disp(['  Sending to SMU: ' cmd]);
                    response = obj.VisaIFobj.query(cmd);
                    if isa(response, 'uint8')
                        response = char(response);
                    end
                    parts = split(response, ',');
                    meas.value = str2double(parts{1});
                    if isnan(meas.value)
                        error('Invalid measurement value received');
                    end
                    meas.status = 0;

                elseif contains(senseFunc, '"RES"')
                    meas.function = 'RESISTANCE';
                    meas.unit = 'Ohm';
                    cmd = ':MEAS?';
                    disp(['  Sending to SMU: ' cmd]);
                    response = obj.VisaIFobj.query(cmd);
                    if isa(response, 'uint8')
                        response = char(response);
                    end
                    parts = split(response, ',');
                    meas.value = str2double(parts{1});
                    if isnan(meas.value)
                        error('Invalid measurement value received');
                    end
                    meas.status = 0;

                elseif contains(senseFunc, '"VOLT') && strcmp(requestedFunc, 'POWER')
                    % Power measurement: measure voltage, then current
                    cmd = ':MEAS?';
                    disp(['  Sending to SMU: ' cmd]);
                    response = obj.VisaIFobj.query(cmd);
                    if isa(response, 'uint8')
                        response = char(response);
                    end
                    parts = split(response, ',');
                    voltValue = str2double(parts{1});
                    if isnan(voltValue)
                        error('Invalid voltage measurement value received');
                    end

                    % Configure and measure current
                    cmd = 'SENS:FUNC "CURR"';
                    if ischar(cmd)
                        disp(['  Sending to SMU: ' cmd]);
                        obj.VisaIFobj.write(cmd);
                        pause(0.1);
                        cmd = 'OPC';
                        disp(['  Sending to SMU: ' cmd]);
                        obj.VisaIFobj.write(cmd);
                        pause(0.5);
                        cmd = 'OPC?';
                        disp(['  Sending to SMU: ' cmd]);
                        opcResponse = obj.VisaIFobj.query(cmd);
                        if isa(opcResponse, 'uint8')
                            opcResponse = char(opcResponse);
                        end
                        if ~contains(opcResponse, '1')
                            error('Operation did not complete for current measurement');
                        end
                    end

                    cmd = ':MEAS?';
                    disp(['  Sending to SMU: ' cmd]);
                    response = obj.VisaIFobj.query(cmd);
                    if isa(response, 'uint8')
                        response = char(response);
                    end
                    parts = split(response, ',');
                    currValue = str2double(parts{1});
                    if isnan(currValue)
                        error('Invalid current measurement value received');
                    end

                    meas.function = 'POWER';
                    meas.unit = 'W';
                    meas.value = voltValue * currValue;
                    meas.status = 0;

                else
                    error('Unknown sense function: %s', senseFunc);
                end

                % Display measurement result if successful and ShowMessages is not 'none'
                if meas.status == 0 && ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp([meas.function ': ' num2str(meas.value) ' ' meas.unit]);
                end

            catch ME
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp(['Error in measure: ' ME.message]);
                end
            end
        end
        %%

        function [voltages, currents] = VoltageLinearSweep(obj, start, stop, numPoints, delay) %limit

            try
                
                % Increase timeout
                obj.VisaIFobj.Timeout = 30; % Set to 30 seconds

                % Reset instrument
                obj.VisaIFobj.write('*RST');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: *RST');
                end

                % Configure measurement and source
                obj.VisaIFobj.write('SOUR:FUNC VOLT');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: SOUR:FUNC VOLT');
                end

                %Set the source range to 20 V
                obj.VisaIFobj.write('SOUR:VOLT:RANG 20');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: SOUR:VOLT:RANG 20');
                end

                %Set the source limit for measurements to 1A
                obj.VisaIFobj.write('SOUR:VOLT:ILIM 1');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: SENS:CURR:RANG:AUTO ON');
                end

                %Set the measure function to current
                obj.VisaIFobj.write('SENS:FUNC "CURR"');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: SENS:FUNC "CURR"');
                end

                %Set the current range to automatic
                obj.VisaIFobj.write('SENS:CURR:RANG:AUTO ON');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: SENS:CURR:RANG:AUTO ON');
                end

                %Set  4-wire remote sensing on
                obj.VisaIFobj.write('SENS:CURR:RSEN ON');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: SENS:CURR:RANG:AUTO ON');
                end

                %clear data from the reading buffer
                obj.VisaIFobj.write(':TRAC:CLEAR');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: :TRAC:CLEAR');
                end

                % Configure sweep
                obj.VisaIFobj.write(sprintf('SOUR:SWE:VOLT:LIN %f, %f, %f, %f', start, stop, numPoints, delay));
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp(['  Sending to SMU: SOUR:SWE:VOLT:LIN ' num2str(start) ', ' num2str(stop) ', ' num2str(numPoints) ', ' num2str(delay) '']);
                end

                % Initiate and wait for sweep
                obj.VisaIFobj.write('INIT');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: INIT');
                end

                obj.VisaIFobj.write('*WAI');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: *WAI');
                end

                % Disable output
                obj.VisaIFobj.write('OUTP OFF'); % replace by internal macro
                
                pause (10);

                % Read data from buffer
                cmd = sprintf('TRAC:DATA? 1, %f, "defbuffer1", SOUR, READ', numPoints);

                response = obj.VisaIFobj.query(cmd);
                if isa(response, 'uint8')
                    response = char(response);
                end

                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp(['  Raw response: ' response]);
                end

                % Parse response
                data = str2double(strsplit(strtrim(response), ','));

                % Split data into voltages and currents
                voltages = data(1:2:end);
                currents = data(2:2:end);


                % Plot results
                figure(1);
                %cla reset;
                plot(voltages, currents);
                title('I-V Characterization');
                xlabel('Voltage (V)');
                ylabel('Current (A)');
                grid on;
                drawnow;

            catch ME
                obj.VisaIFobj.write('OUTP OFF');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp(['Error in VoltageLinearSweep: ' ME.message]);
                end
                rethrow(ME);
            end
        end


        function [currents, voltages] = CurrentLinearSweep(obj, start, stop, step, delay)
            % Perform a linear current sweep for V-I characterization of a diode using LINear:STEP
            % Inputs:
            %   start - Starting current (A)
            %   stop - Stopping current (A)
            %   step - step size (A)
            %   delay - Delay per step in seconds
            % Outputs:
            %   currents - Array of applied currents (A)
            %   voltages - Array of measured voltages (V)

            try
                
                % Increase timeout
                obj.VisaIFobj.Timeout = 30; % Set to 30 seconds

                % Reset instrument
                obj.VisaIFobj.write('*RST');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: *RST');
                end

                % Configure measurement and source
                obj.VisaIFobj.write('SOUR:FUNC CURR');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: SOUR:FUNC CURR');
                end

                %Set the source range to 1 A
                obj.VisaIFobj.write('SOUR:CURR:RANGE 1');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: SOUR:CURR:RANGE 1');
                end

                %Set the measure function to voltage
                obj.VisaIFobj.write('SENS:FUNC "VOLT"');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: SENS:FUNC "VOLT"');
                end

                %Set the voltage range to 20 V
                obj.VisaIFobj.write('SENS:VOLT:RANGE 20');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: SENS:VOLT:RANGE 20');
                end

                %Set  4-wire remote sensing on
                obj.VisaIFobj.write('SENS:CURR:RSEN ON');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: SENS:CURR:RANG:AUTO ON');
                end

                %clear data from the reading buffer
                obj.VisaIFobj.write(':TRAC:CLEAR');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: :TRAC:CLEAR');
                end

                % Configure sweep
                obj.VisaIFobj.write(sprintf('SOUR:SWE:CURR:LIN:STEP %f, %f, %f, %f, 1, AUTO', start, stop, step, delay));
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp(['  Sending to SMU: SOUR:SWE:CURR:LIN:STEP ' num2str(start) ', ' num2str(stop) ', ' num2str(step) ', ' num2str(delay) ', 1, AUTO']);
                end

                % Initiate and wait for sweep
                obj.VisaIFobj.write('INIT');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: INIT');
                end

                obj.VisaIFobj.write('*WAI');
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp('  Sending to SMU: *WAI');
                end

                % Disable output
                obj.VisaIFobj.write('OUTP OFF'); % replace by internal macro
                
                pause (10);

                % Calculate number of points
                Points = floor((stop - start) / step) + 1;

                % Read data from buffer
                cmd = sprintf('TRAC:DATA? 1, %f, "defbuffer1", SOUR, READ', Points);

                response = obj.VisaIFobj.query(cmd);
                if isa(response, 'uint8')
                    response = char(response);
                end

                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp(['  Raw response: ' response]);
                end

                % Parse response
                data = str2double(strsplit(strtrim(response), ','));

                % Split data into currents and voltages
                currents = data(1:2:end);
                voltages = data(2:2:end);

                % Plot results
                figure(2);
                plot(currents, voltages);
                title('V-I Characterization');
                xlabel('Current (A)');
                ylabel('Voltage (V)');
                grid on;
                drawnow;

            catch ME
                obj.VisaIFobj.write('OUTP OFF'); % replace by internal macro
                if ~strcmpi(obj.VisaIFobj.ShowMessages, 'none')
                    disp(['Error in VoltageLinearSweep: ' ME.message]);
                end
                rethrow(ME);
            end

        end
    end






    % -----------------------------------------------------------------
    % get methods (dependent)
    % -----------------------------------------------------------------

    methods
        function outputState = get.OutputState(obj)
            % read output state ('on' or 'off')

            [outpState, status] = obj.VisaIFobj.query(':OUTP?');
                        %
            if status ~= 0
                outputState = -1; % unknown state, error
            else
                % remap trigger state
                outpState = lower(char(outpState));
                switch outpState
                    case '0'   , outputState = 0;
                    case '1'   , outputState = 1;
                    otherwise  , outputState = -1; % unknown state, error
                end
            end
        end

        function errMsg = get.ErrorMessages(obj)
            % read error list from the SMU’s error buffer

            if obj.ShowMessages
                disp(['SMU WARNING - Method ''ErrorMessages'' is not ' ...
                    'implemented yet for ']);
                disp(['      ' obj.VisaIFobj.Vendor '/' ...
                    obj.VisaIFobj.Product ]);
            end

            % copy result to output
            errMsg = '0, no error buffer at Scope';

        end

    end

    % ---------------------------------------------------------------------
    methods           % get/set methods

        function showmsg = get.ShowMessages(obj)

            switch lower(obj.VisaIFobj.ShowMessages)
                case 'none'
                    showmsg = false;
                case {'few', 'all'}
                    showmsg = true;
                otherwise
                    disp('SMUMacros: invalid state in get.ShowMessages');
            end
        end

    end

end