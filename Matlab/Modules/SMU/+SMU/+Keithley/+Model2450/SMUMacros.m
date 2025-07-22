% documentation for class 'SMUmacros' package for +SMU/+Keithley/+Model2450
% ---------------------------------------------------------------------
% this class provides device-specific macros for SMU class operations
% supports firmware: 1.7.16a (2025-03-12) ==> see SMU.Identifier)
% -------------------------------------------------------------------------

classdef SMUMacros < handle
    properties(Constant = true)
        MacrosVersion = '0.9.0';      % Updated release version
        MacrosDate    = '2025-07-21'; % Updated release date
    end

    properties(Dependent)
        OutputState          double  % 0 = 'off', 1 = 'on', NaN = 'error'
        LimitCurrentValue    double; % in A
        LimitVoltageValue    double; % in V
        OverVoltageProtectionLevel   double; % in V, coerced to (2, 5, 10,
        %                                      20, 40, 60, 80, 100, 120,
        %                                      140, 160, 180, inf) V
    end

    properties(Dependent, SetAccess = private, GetAccess = public)
        ShowMessages         logical % false = 'none', true = 'few' or 'all'
        OverVoltageProtectionTripped double % 0 = inactive, 1 = active
        TriggerState         char
        ErrorMessages        table
    end

    properties(SetAccess = private, GetAccess = public)
        AvailableBuffers cell = {''};  % cell array of char
    end

    properties(SetAccess = private, GetAccess = private)
        VisaIFobj             % reference to SMU object for communication
    end

    properties(Constant = true, GetAccess = private)
        DefaultBuffers = {'defbuffer1', 'defbuffer2'};
    end

    % ------- public methods -----------------------------------------------
    methods

        function obj = SMUMacros(VisaIFobj)
            % Constructor

            obj.VisaIFobj = VisaIFobj;
            obj.resetBuffer;

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
            else
                obj.resetBuffer;
            end

            % clear status (event logs and error queue)
            if obj.VisaIFobj.write('*CLS')
                status = -1;
            end

            % reconfigure device after reset
            % inclues a final '*OPC?' to wait for operation complete
            if obj.runAfterOpen()
                status = -1;
            end

            % wait for operation complete
            %obj.VisaIFobj.opc;

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

        function status = lock(obj)
            % lock all buttons at SMU

            status = 0;

            if obj.ShowMessages
                disp(['SMU WARNING - Method ''lock'' is not ' ...
                    'supported for ']);
                disp(['      ' obj.VisaIFobj.Vendor '/' ...
                    obj.VisaIFobj.Product ...
                    ' -->  SMU will never be locked ' ...
                    'by remote access']);
            end
        end

        function status = unlock(obj)
            % unlock all buttons at SMU

            status = 0;

            disp(['SMU WARNING - Method ''unlock'' is not ' ...
                'supported for ']);
            disp(['      ' obj.VisaIFobj.Vendor '/' ...
                obj.VisaIFobj.Product ...
                ' -->  SMU will never be locked ' ...
                'by remote access']);
        end

        function status = outputEnable(obj)

            status = NaN; % init

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

            status = NaN; % init

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

        function status = outputTone(obj, varargin)
            % outputTone : emit a tone
            %   'frequency' : frequency of the beep (in Hz)
            %                 range: 20 ... 8e3
            %                 optional parameter, default: 440 (440 Hz)
            %   'duration'  : length of tone (in s)
            %                 range: 1e-3 ... 1e2
            %                 optional parameter, default: 1 (1 s)

            % init output
            status = NaN;

            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
                switch paramName
                    case 'frequency'
                        defaultFreq = 440;
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
                        defaultDuration = 1;
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
                            disp(['SMU: Warning - ''configureDisplay'' ' ...
                                'parameter ''' paramName ''' is ' ...
                                'unknown --> ignore and continue']);
                        end
                end
            end

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------

            % send command
            obj.VisaIFobj.write([':System:Beeper ' frequency ',' ...
                duration]);
            % read and verify (not applicable)
            pause(max(0, (str2double(duration)-1)));

            % wait for operation complete
            obj.VisaIFobj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = restartTrigger(obj)

            status = NaN; % init

            if obj.VisaIFobj.write(':Trigger:Continuous Restart')
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
        end

        function status = configureDisplay(obj, varargin)
            % configureDisplay : configure display
            %   'screen' : char to select displayed screen
            %              'clear' to delete user defined text ('text')
            %              '' to print out lsit of screen options
            %              'home' to select home screen ...
            %   'digits' : determines the number of digits that are displayed
            %   'brightness': scalar double to adjust brightness (-1 ... 100)
            %   'buffer' : determines which buffer is used for measurements
            %              that are displayed
            %   'text'   : text that is shown on SMU display
            %              'ABC', {'ABC'}, "ABC" for single line
            %              'ABC;abc', {'ABC', 'abc'}, ["ABC", "abc"] for
            %              dual line

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

            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
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
                                disp(['SMU: Warning - ' ...
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
                            disp(['SMU: Warning - ''configureDisplay'' ' ...
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
                obj.VisaIFobj.write(':Display:Clear');
            elseif ~isempty(screen)
                obj.VisaIFobj.write([':Display:Screen ' screen]);
                % read and verify (not applicable)
            end

            % 'digits'           : char
            if ~isempty(digits)
                % set for all modes: curr, res, volt
                obj.VisaIFobj.write([':Display:Digits ' digits]);
                % readback and verify
                response = obj.VisaIFobj.query(':Display:Volt:Digits?');
                response = char(response);
                if ~strcmpi(response, digits)
                    % set command failed
                    disp(['SMU: Warning - ''configureDisplay'' ' ...
                        'digits parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % 'brightness'       : char
            if ~isempty(brightness)
                obj.VisaIFobj.write([':Display:Light:State ' brightness]);
                % readback and verify
                response = obj.VisaIFobj.query(':Display:Light:State?');
                response = char(response);
                if ~strcmpi(response, brightness)
                    % set command failed
                    disp(['SMU: Warning - ''configureDisplay'' ' ...
                        'brightness parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % 'buffer'           : char
            if ~isempty(buffer)
                obj.VisaIFobj.write([':Display:Buffer:Active "' buffer '"']);
                % readback and verify
                response = obj.VisaIFobj.query(':Display:Buffer:Active?');
                response = char(response);
                if ~strcmpi(response, buffer)
                    % set command failed
                    disp(['SMU: Warning - ''configureDisplay'' ' ...
                        'buffer parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % 'text'             : cell array of char
            if ~isempty(text)
                % select user swipe screen
                obj.VisaIFobj.write(':Display:Screen swipe_user');
                % show text on screen
                for cnt = 1 : length(text)
                    if ~isempty(text{cnt})
                        cmd = sprintf(':Display:User%d:Text "%s"', ...
                            cnt, text{cnt});
                        obj.VisaIFobj.write(cmd);
                    end
                end
                % read and verify (not applicable)
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





        % ToDo
        % function: '^(VOLTAGE|CURRENT|RESISTANCE)$'
        % range   : '^(AUTO|[\d\.\+\-eEmMuUkK]+)$'
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





        % -----------------------------------------------------------------
        % get/set methods

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

        % -----------------------------------------------------------------
        % get/set methods for dependent properties

        function limit = get.LimitCurrentValue(obj)
            [limit, status] = obj.VisaIFobj.query( ...
                ':SOURCE:VOLTAGE:ILIMIT?');
            %
            if status ~= 0
                limit = NaN; % unknown value, error
            else
                % convert value
                limit = lower(char(limit));
                limit = str2double(limit);
            end
        end

        function set.LimitCurrentValue(obj, limit)

            % further checks and clipping
            limit = min(limit, 1.05);  % max 1.05 A for Keithley 2450
            limit = max(limit, 1e-9);  % min 1 nA   for Keithley 2450
            % set property ==> check is done via readback and verify
            obj.VisaIFobj.write([':SOURCE:VOLTAGE:ILIMIT ' num2str(limit)]);
        end

        function limit = get.LimitVoltageValue(obj)
            [limit, status] = obj.VisaIFobj.query( ...
                ':SOURCE:CURRENT:VLIMIT?');
            %
            if status ~= 0
                limit = NaN; % unknown value, error
            else
                % convert value
                limit = lower(char(limit));
                limit = str2double(limit);
            end
        end

        function set.LimitVoltageValue(obj, limit)

            % further checks and clipping
            limit = min(limit, 210);   % max  210 V for Keithley 2450
            limit = max(limit, 0.02);  % min 0.02 V for Keithley 2450
            % set property ==> check is done via readback and verify
            obj.VisaIFobj.write([':SOURCE:CURRENT:VLIMIT ' num2str(limit)]);
        end

        function limit = get.OverVoltageProtectionLevel(obj)
            [limit, status] = obj.VisaIFobj.query( ...
                ':SOURCE:VOLTAGE:PROTECTION:LEVEL?');
            %
            if status ~= 0
                limit = NaN; % unknown value, error
            else
                % convert value
                limit = lower(char(limit));
                if strcmp(limit, 'none')
                    limit = inf;
                elseif startsWith(limit, 'prot') && length(limit) >= 5
                    limit = str2double(limit(5:end));
                else
                    limit = NaN; % unknown response
                end
            end
        end

        function set.OverVoltageProtectionLevel(obj, limit)

            % further checks and clipping, coerced to (2, 5, 10, 20, 40,
            % 60, 80, 100, 120, 140, 160, 180, infty) V
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
            else              , setStr = 'PROT2';
            end
            % set property ==> check is done via readback and verify
            obj.VisaIFobj.write([':SOURCE:VOLTAGE:PROTECTION:LEVEL ' ...
                setStr]);
        end

        function outputState = get.OutputState(obj)
            [outpState, status] = obj.VisaIFobj.query(':Output:State?');
            %
            if status ~= 0
                outputState = NaN; % unknown state, error
            else
                % remap state
                outpState = lower(char(outpState));
                switch outpState
                    case '0'   , outputState = 0;  % 'off'
                    case '1'   , outputState = 1;  % 'on'
                    otherwise  , outputState = NaN; % unknown state, error
                end
            end
        end

        function set.OutputState(obj, param)

            % map to on/off
            if logical(param)
                param = 'On';
            else
                param = 'Off';
            end
            % set property ==> check is done via readback and verify
            obj.VisaIFobj.write([':Output:State ' param]);
        end

        % get/set methods for AvailableBuffers are empty
        % ==> only needed when further actions are needed
        % function buffers = get.AvailableBuffers(obj)
        %     buffers = obj.AvailableBuffers;
        % end
        %
        % function set.AvailableBuffers(obj, buffers)
        %     obj.AvailableBuffers = buffers;
        % end

        % -----------------------------------------------------------------
        % get methods for dependent properties (read-only)

        function OVPState = get.OverVoltageProtectionTripped(obj)
            [OVPState, status] = obj.VisaIFobj.query( ...
                ':SOURCE:VOLTAGE:PROTECTION:TRIPPED?');
            %
            if status ~= 0
                OVPState = NaN; % unknown state, error
            else
                % remap state
                OVPState = lower(char(OVPState));
                switch OVPState
                    case '0'   , OVPState = 0;  % 'OVP not active'
                    case '1'   , OVPState = 1;  % 'OVP active'
                    otherwise  , OVPState = NaN; % unknown state, error
                end
            end
        end

        function TrigState = get.TriggerState(obj)
            [TrigState, status] = obj.VisaIFobj.query(':Trigger:State?');
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
        end

        function errTable = get.ErrorMessages(obj)
            % read error list from the SMU's error buffer
            %
            % actually read all types of events (error, warning,
            % informational)

            datetimeFmt = 'yyyy/MM/dd HH:mm:ss.SSS';

            % how many unread events are available?
            numOfEvents = obj.VisaIFobj.query(':System:Eventlog:Count? All');
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
                eventMsg = obj.VisaIFobj.query(':System:Eventlog:Next?');
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
            if obj.ShowMessages
                if ~isempty(eventTable)
                    disp('SMU event list:');
                    disp(eventTable);
                else
                    disp('SMU event list is empty');
                end
            end

            % copy result to output
            errTable = eventTable;

            % reading out the error buffer again results in an empty return
            % value ==> therefore history is saved in 'SMU' class
        end
    end

    % ------- private methods -----------------------------------------------
    methods(Access = private)

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