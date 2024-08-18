classdef ScopeMacros < handle
    % ToDo documentation
    %
    % known severe issues:
    %   - channel 2 cannot be set as trigger input source (ch1, ext,
    %     ac-line is working, but not ch2 ==> severe bug, ch2 can only be
    %     set as trigger source manually at scope
    %   - there is no SCPI command to disable Zoom window again ==> not a
    %     big deal, disable manually at scope
    %   - scope always beeps when using 'VDIV' command (no idea why);
    %     implemented workaround: disable buzzer permanently in method
    %     runAfterOpen
    %   - only short form of command COMM_HEADER is allowed
    %     (error in programming guide) ==> use short form CHDR
    %   - same for AUTO_SETUP    ==> use ASET instead
    %   - same for SCREEN_DUMP   ==> use SCDP instead
    %   - same for MEASURE_DELAY ==> use MEAD instead
    %   - RUN command does not exist ==> use work around:
    %     'TRIG_MODE AUTO' instead (method acqRun)
    %
    % for Scope: Siglent SDS1202X-E series
    % (for Siglent firmware: 1.3.27 (2023-04-25) ==> see myScope.identify)

    properties(Constant = true)
        MacrosVersion = '3.0.0';      % release version
        MacrosDate    = '2024-08-18'; % release date
    end

    properties(Dependent, SetAccess = private, GetAccess = public)
        ShowMessages                      logical
        AutoscaleHorizontalSignalPeriods  double
        AutoscaleVerticalScalingFactor    double
        AcquisitionState                  char
        TriggerState                      char
        ErrorMessages                     char
    end

    properties(SetAccess = private, GetAccess = private)
        VisaIFobj         % VisaIF object
    end

    % ------- basic methods -----------------------------------------------
    methods

        function obj = ScopeMacros(VisaIFobj)
            % constructor

            obj.VisaIFobj = VisaIFobj;

        end

        function delete(obj)
            % destructor

            if obj.ShowMessages
                disp(['Object destructor called for class ''' ...
                    class(obj) '''.']);
            end
        end

        function status = runAfterOpen(obj)

            % init output
            status = NaN;

            % add some device specific commands:
            %
            % defines the way the scope formats response to queries
            % off: header is omitted from the response and units in numbers
            % are suppressed ==> shortest feedback
            % only short form of command is allowed (error in programming
            % guide); long form is COMM_HEADER
            if obj.VisaIFobj.write('CHDR OFF')
                status = -1;
            end

            % set the intensity level of the grid and trace
            TraceValue = 95; % 1 ... 100
            GridValue  = 60; % 0 ... 100
            if obj.VisaIFobj.write( ...
                    ['INTENSITY TRACE,' num2str(TraceValue, '%g') ...
                    ',GRID,' num2str(GridValue, '%g')])
                status = -1;
            end

            % Scope always beeps when using 'VDIV' command
            % no idea why
            % workaround: disable buzzer permanently
            if obj.VisaIFobj.write('BUZZER OFF')
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

            % init output
            status = NaN;

            % add some device specific commands:
            %
            % XXX
            %if obj.VisaIFobj.write('xxx')
            %    status = -1;
            %end

            % wait for operation complete
            obj.VisaIFobj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = reset(obj)

            % init output
            status = NaN;

            % use standard reset command Factory Default)
            if obj.VisaIFobj.write('*RST')
                status = -1;
            end

            % clear status (event registers and error queue)
            % ==> not supported by SDS1000X-E & SDS 2000X
            %if obj.VisaIFobj.write('*CLS')
            %    status = -1;
            %end

            % defines the way the scope formats response to queries
            % off: header is omitted from the response and units in numbers
            % are suppressed ==> shortest feedback
            % only short form of command is allowed (error in programming
            % guide); long form is COMM_HEADER
            if obj.VisaIFobj.write('CHDR OFF')
                status = -1;
            end

            % set the intensity level of the grid and trace
            TraceValue = 95; % 1 ... 100
            GridValue  = 60; % 0 ... 100
            if obj.VisaIFobj.write( ...
                    ['INTENSITY TRACE,' num2str(TraceValue, '%g') ...
                    ',GRID,' num2str(GridValue, '%g')])
                status = -1;
            end

            if obj.VisaIFobj.write('BUZZER OFF')
                status = -1;
            end

            % ...

            % wait for operation complete
            obj.VisaIFobj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

    end

    % ------- main scope macros -------------------------------------------
    methods

        function status = clear(obj)
            % clear buffers and registers

            status = 0;

            if obj.ShowMessages
                disp(['Scope WARNING - Method ''clear'' is not ' ...
                    'supported for ']);
                disp(['      ' obj.VisaIFobj.Vendor '/' ...
                    obj.VisaIFobj.Product ...
                    ' --> nothing to clear']);
            end
        end

        function status = lock(obj)
            % lock all buttons at scope

            status = 0;

            if obj.ShowMessages
                disp(['Scope WARNING - Method ''lock'' is not ' ...
                    'supported for ']);
                disp(['      ' obj.VisaIFobj.Vendor '/' ...
                    obj.VisaIFobj.Product ...
                    ' -->  Scope will never be locked ' ...
                    'by remote access']);
            end
        end

        function status = unlock(obj)
            % unlock all buttons at scope

            status = 0;

            disp(['Scope WARNING - Method ''unlock'' is not ' ...
                'supported for ']);
            disp(['      ' obj.VisaIFobj.Vendor '/' ...
                obj.VisaIFobj.Product ...
                ' -->  Scope will never be locked ' ...
                'by remote access']);
        end

        function status = acqRun(obj)
            % start data acquisitions at scope

            % work around: acq_mode = auto (RUN command does not exist)
            disp(['Scope WARNING - Method ''acqRun'' does set ' ...
                'Trigger Mode to ''Auto'' for ']);
            disp(['      ' obj.VisaIFobj.Vendor '/' ...
                obj.VisaIFobj.Product ]);

            status = obj.VisaIFobj.write('TRIG_MODE AUTO');
        end

        function status = acqStop(obj)
            % stop data acquisitions at scope

            status = obj.VisaIFobj.write('STOP');
        end

        function status = autoset(obj)
            % the oscilloscope will automatically adjust the vertical
            % position, the horizontal time base and the trigger mode
            % according to the input signal to make the waveform display
            % to the best state

            % init output
            status = NaN;

            % actual autoset command
            if obj.VisaIFobj.write('ASET') % long form does not work
                status = -1;
            end
            % wait for operation complete
            obj.VisaIFobj.opc;

            % has a valid signal been detected?
            % ==> no option for validation

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        % -----------------------------------------------------------------

        function status = configureInput(obj, varargin)
            % configureInput  : configure input of specified channels
            % examples (for valid options see code below)
            %   'channel'     : '1' '1, 2'
            %   'trace'       : 'on', '1' or 'off', '1'
            %   'impedance'   : '1e6' only
            %   'vDiv'        : real > 0 ==> Scope always beeps, no idea why
            %   'vOffset'     : real
            %   'coupling'    : 'DC', 'AC', 'GND'
            %   'inputDiv'    : 0.1, 0.2, 0.5, 1, 2, 5, ... , 5000, 10000
            %   'bwLimit'     : on/off
            %   'invert'      : on/off
            %   'skew'        : real
            %   'unit'        : 'V' or 'A'

            % init output
            status = NaN;

            % initialize all supported parameters
            channels       = {};
            trace          = '';
            impedance      = '';
            vDiv           = '';
            vOffset        = '';
            coupling       = '';
            inputDiv       = '';
            bwLimit        = '';
            invert         = '';
            skew           = '';
            unit           = '';

            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
                switch paramName
                    case 'channel'
                        % split and copy to cell array of char
                        channels = split(paramValue, ',');
                        % remove spaces
                        channels = regexprep(channels, '\s+', '');
                        % loop
                        for cnt = 1 : length(channels)
                            switch channels{cnt}
                                case {'', '1', '2'}
                                    % do nothing
                                otherwise
                                    channels{cnt} = '';
                                    disp(['Scope: Warning - ' ...
                                        '''configureInput'' invalid ' ...
                                        'channel (allowed are 1 .. 2) ' ...
                                        '--> ignore and continue']);
                            end
                        end
                        % remove invalid (empty) entries
                        channels = channels(~cellfun(@isempty, channels));
                    case 'trace'
                        if ~isempty(paramValue)
                            switch lower(paramValue)
                                case {'off', '0'}
                                    trace = 'OFF';
                                case {'on',  '1'}
                                    trace = 'ON';
                                otherwise
                                    trace = '';
                                    disp(['Scope: Warning - ''configureInput'' ' ...
                                        'trace parameter value is unknown ' ...
                                        '--> ignore and continue']);
                            end
                        end
                    case 'impedance'
                        if ~isempty(paramValue)
                            impedance = abs(str2double(paramValue));
                            if impedance == 1e6
                                coerced   = false;
                            elseif isnan(impedance)
                                coerced   = true;
                                impedance = 1e6;
                            else
                                coerced   = true;
                                impedance = 1e6;
                            end
                            if obj.ShowMessages && coerced
                                disp(['  - impedance    : ' ...
                                    num2str(impedance, '%g') ' (coerced)']);
                            end
                            % convert to char array
                            if impedance < 1e3
                                impedance = '50';  % 50 Ohm : impossible to reach
                            else
                                impedance = '1M';  % 1 MOhm
                            end
                        end
                    case 'vDiv'
                        if ~isempty(paramValue)
                            vDiv = abs(str2double(paramValue));
                            if isnan(vDiv) || isinf(vDiv)
                                vDiv = [];
                            end
                        end
                    case 'vOffset'
                        if ~isempty(paramValue)
                            vOffset = str2double(paramValue);
                            if isnan(vOffset) || isinf(vOffset)
                                vOffset = [];
                            end
                        end
                    case 'coupling'
                        if ~isempty(paramValue)
                            switch lower(paramValue)
                                case 'ac'
                                    coupling = 'A';
                                case 'dc'
                                    coupling = 'D';
                                case 'gnd'
                                    coupling = 'GND';
                                otherwise
                                    coupling = '';
                                    disp(['Scope: Warning - ''configureInput'' ' ...
                                        'coupling parameter value is unknown ' ...
                                        '--> ignore and continue']);
                            end
                        end
                    case 'inputDiv'
                        if ~isempty(paramValue)
                            switch lower(paramValue)
                                case {'0.1', '0.2', '0.5', ...
                                        '1', '2', '5', ...
                                        '10', '20', '50', ...
                                        '100', '200', '500', ...
                                        '1000', '2000', '5000', ...
                                        '10000'}
                                    inputDiv = paramValue;
                                otherwise
                                    inputDiv = '';
                                    disp(['Scope: Warning - ''configureInput'' ' ...
                                        'inputDiv parameter value is unknown ' ...
                                        '--> ignore and continue']);
                            end
                        end
                    case 'bwLimit'
                        if ~isempty(paramValue)
                            switch lower(paramValue)
                                case {'off', '0'}
                                    bwLimit = 'OFF';
                                case {'on',  '1'}
                                    bwLimit = 'ON';
                                otherwise
                                    bwLimit = '';
                                    disp(['Scope: Warning - ''configureInput'' ' ...
                                        'bwLimit parameter value is unknown ' ...
                                        '--> ignore and continue']);
                            end
                        end
                    case 'invert'
                        if ~isempty(paramValue)
                            switch lower(paramValue)
                                case {'off', '0'}
                                    invert = 'OFF';
                                case {'on',  '1'}
                                    invert = 'ON';
                                otherwise
                                    invert = '';
                                    disp(['Scope: Warning - ''configureInput'' ' ...
                                        'invert parameter is unknown --> ignore ' ...
                                        'and continue']);
                            end
                        end
                    case 'skew'
                        if ~isempty(paramValue)
                            skew = str2double(paramValue);
                            if isnan(skew) || isinf(skew)
                                skew = [];
                                disp(['Scope: Warning - ''configureInput'' ' ...
                                    'skew parameter value is unknown ' ...
                                    '--> ignore and continue']);
                            end
                        end
                    case 'unit'
                        if ~isempty(paramValue)
                            switch upper(paramValue)
                                case 'V'
                                    unit = 'V';
                                case 'A'
                                    unit = 'A';
                                otherwise
                                    unit = '';
                                    disp(['Scope: Warning - ''configureInput'' ' ...
                                        'unit parameter value is unknown ' ...
                                        '--> ignore and continue']);
                            end
                        end
                    otherwise
                        if ~isempty(paramValue)
                            disp(['Scope: Warning - ''configureInput'' ' ...
                                'parameter ''' paramName ''' is ' ...
                                'unknown --> ignore and continue']);
                        end
                end
            end

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------

            if isempty(channels)
                disp(['Scope: Warning - ''configureInput'' no channels ' ...
                    'are specified. --> skip and continue']);
            end

            % loop over channels
            for cnt = 1:length(channels)
                channel = channels{cnt};

                % 'impedance' ('1M') & 'coupling' ('DC', 'AC', 'GND')
                if ~isempty(impedance) || ~isempty(coupling)
                    if ~isempty(impedance) && ~isempty(coupling)
                        % both parts are defined
                        if strcmpi(coupling, 'GND')
                            cpl = 'GND';
                        else
                            % A1M, D1M
                            cpl = [coupling impedance];
                        end
                    else
                        % request current settings
                        response = obj.VisaIFobj.query(['C' channel ...
                            ':COUPLING?']);
                        response = char(response);
                        % merge
                        if ~isempty(impedance)
                            if strcmpi(response, 'GND')
                                disp(['Scope: Warning - ''configureInput'' ' ...
                                    'impedance parameter will be ignored ' ...
                                    'as long as coupling = GND.']);
                                cpl = 'GND';
                            else
                                cpl = [cpl(1) impedance];
                            end
                        else
                            if strcmpi(coupling, 'GND')
                                cpl = 'GND';
                            elseif strcmpi(response, 'GND')
                                cpl = [coupling '1M'];
                                if obj.ShowMessages
                                    disp(['  - impedance    : ' ...
                                        '1e6 (coerced)']);
                                end
                            else
                                cpl = [coupling response(2:3)];
                            end
                        end
                    end

                    % set parameter
                    obj.VisaIFobj.write(['C' channel ':COUPLING ' cpl]);
                    % read and verify
                    response = obj.VisaIFobj.query(['C' channel ...
                        ':COUPLING?']);
                    if ~strcmpi(cpl, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'impedance and/or coupling parameter could ' ...
                            'not be set correctly.']);
                        status = -1;
                    end
                end

                % 'inputDiv', 'probe': .. 1, 10, 20, 50, 100, ..
                if ~isempty(inputDiv)
                    % set parameter
                    obj.VisaIFobj.write(['C' channel ':ATTENUATION ' inputDiv]);
                    % read and verify
                    response = obj.VisaIFobj.query(['C' channel ':ATTENUATION?']);
                    if str2double(inputDiv) ~= str2double(char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'inputDiv parameter could not be set correctly.']);
                        status = -1;
                    end
                end

                % 'unit'             : 'V' or 'A'
                if ~isempty(unit)
                    % set parameter
                    obj.VisaIFobj.write(['C' channel ':UNIT ' unit]);
                    % read and verify
                    response = obj.VisaIFobj.query(['C' channel ':UNIT?']);
                    if ~strcmpi(unit, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'unit parameter could not be set correctly.']);
                        status = -1;
                    end
                end

                % 'bwLimit'          : 'off', 'on'
                if ~isempty(bwLimit)
                    % set parameter
                    obj.VisaIFobj.write(['BANDWIDTH_LIMIT ' ...
                        'C' channel ',' bwLimit]);
                    % read and verify
                    response = obj.VisaIFobj.query(['C' channel ...
                        ':BANDWIDTH_LIMIT?']);
                    if ~strcmpi(bwLimit, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'bwLimit parameter could not be set correctly.']);
                        status = -1;
                    end
                end

                % 'invert'           : 'off', 'on'
                % only short form of command is used here
                if ~isempty(invert)
                    % set parameter
                    obj.VisaIFobj.write(['C' channel ...
                        ':INVS ' invert]);
                    % read and verify
                    response = obj.VisaIFobj.query(['C' channel ...
                        ':INVS?']);
                    if ~strcmpi(invert, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'invert parameter could not be set correctly.']);
                        status = -1;
                    end
                end

                % 'skew'           : (-100e-9 ... 100e-9 = +/- 100ns)
                if ~isempty(skew)
                    % format (round) numeric value
                    skewString = num2str(skew, '%1.2e');
                    skew       = str2double(skewString);
                    skewString = [num2str(skew, '%g') 's'];
                    % set parameter
                    obj.VisaIFobj.write(['C' channel ':SKEW ' skewString]);
                    % read and verify
                    response   = obj.VisaIFobj.query(['C' channel ...
                        ':SKEW?']);
                    % remove unit and scale properly before
                    response   = char(response);
                    idx = regexp(response, '^\-?\d+\.?\d*\e?[\-\+]?\d*', 'end', 'ignorecase');
                    if ~isempty(idx)
                        skewActual = str2double(response(1:idx));
                        if length(response) > idx
                            skewUnit  = response(idx+1:end);
                            switch lower(skewUnit)
                                case {'ns'}
                                    skewActual = skewActual * 1e-9;
                                case {'us'}
                                    skewActual = skewActual * 1e-6;
                                case {'ms'}
                                    skewActual = skewActual * 1e-3;
                                case {'s'}
                                    skewActual = skewActual * 1e-0;
                                otherwise
                                    skewActual = skewActual * 0; %??? error
                            end
                        end
                    else
                        skewActual = NaN;
                    end
                    if skew ~= skewActual
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'skew parameter could not be set correctly. ' ...
                            'Check limits.']);
                    end
                end

                % 'trace'          : 'off', 'on'
                if ~isempty(trace)
                    % set parameter
                    obj.VisaIFobj.write(['C' channel ...
                        ':TRACE ' trace]);
                    % read and verify
                    response = obj.VisaIFobj.query(['C' channel ...
                        ':TRACE?']);
                    if ~strcmpi(trace, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'trace parameter could not be set correctly.']);
                        status = -1;
                    end
                end

                % 'vDiv'           : positive double in V/div
                if ~isempty(vDiv)
                    % scale VDiv value before use (in set command)
                    vDivString = num2str(vDiv, '%1.2e');
                    vDiv       = str2double(vDivString);
                    % set parameter
                    obj.VisaIFobj.write(['C' channel ...
                        ':VDIV ' vDivString]);
                    % read and verify
                    response   = obj.VisaIFobj.query(['C' channel ...
                        ':VDIV?']);
                    vDivActual = str2double(char(response));
                    if abs(vDiv - vDivActual) / vDiv > 0.1
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'vDiv parameter could not be set correctly. ' ...
                            'Check limits.']);
                    end
                elseif ~isempty(vOffset)
                    % required for verfication of voffset
                    response   = obj.VisaIFobj.query(['C' channel ...
                        ':VDIV?']);
                    vDivActual = str2double(char(response));
                end

                % 'vOffset'        : positive double in V
                if ~isempty(vOffset)
                    % format (round) numeric value
                    vOffString = num2str(-vOffset, '%1.2e');
                    vOffset    = str2double(vOffString);
                    % set parameter
                    obj.VisaIFobj.write(['C' channel ...
                        ':OFFSET ' vOffString]);
                    % read and verify
                    response   = obj.VisaIFobj.query(['C' channel ...
                        ':OFFSET?']);
                    vOffActual = str2double(char(response));
                    if abs(vOffset - vOffActual) > 0.1 * vDivActual
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'vOffset parameter could not be set correctly. ' ...
                            'Check limits.']);
                    end
                end
            end

            % wait for operation complete
            obj.VisaIFobj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = configureAcquisition(obj, varargin)
            % configureAcquisition : configure acquisition parameters
            %   'tDiv'        : real > 0
            %   'sampleRate'  : real > 0
            %   'maxLength'   : integer > 0
            %   'mode'        : 'sample', 'peakdetect', average ...
            %   'numAverage'  : integer > 0

            % init output
            status = NaN;

            % initialize all supported parameters
            tDiv        = [];
            %sampleRate  = [];
            maxLength   = [];
            mode        = '';
            numAverage  = [];

            % was this method called internally?
            myStack = dbstack(1, '-completenames');
            internalCall = startsWith(myStack(1).name, 'ScopeMacros');

            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
                switch paramName
                    case 'tDiv'
                        if ~isempty(paramValue)
                            tDiv    = abs(str2double(paramValue));
                            coerced = false;
                            if  isnan(tDiv) || isinf(tDiv)
                                disp(['Scope: Warning - ''configureAcquisition'' ' ...
                                    'tDiv parameter is invalid --> ' ...
                                    'coerce and continue']);
                                status  = 1; % warning
                                coerced = true;
                                tDiv    = 5e-4; % 0.5ms as default
                            else
                                % okay ==> round to allowed values in s
                                % 1e-9, 2e-9, 5e-9, ... , 10, 20, 50, 100
                                tmp  = tDiv;
                                tDiv = min(tDiv, 100);
                                tDiv = max(tDiv, 1e-9);
                                Mantissa = 10^(log10(tDiv)-floor(log10(tDiv)));
                                if Mantissa < 1.4
                                    Mantissa = 1;
                                elseif Mantissa < 3
                                    Mantissa = 2;
                                elseif Mantissa < 7
                                    Mantissa = 5;
                                else
                                    Mantissa = 10;
                                end
                                tDiv = Mantissa * 10^floor(log10(tDiv));
                                if tDiv ~= tmp
                                    coerced = true;
                                end
                            end
                            if obj.ShowMessages && coerced && ~internalCall
                                disp(['  - tDiv         : ' ...
                                    num2str(tDiv, '%g') ' (coerced)']);
                            end
                        end
                    case 'sampleRate'
                        if ~isempty(paramValue)
                            disp(['Scope: WARNING - sampleRate parameter ' ...
                                ' is not supported. Please specify tDiv ' ...
                                'and maxLength instead.']);
                            status  = 1; % warning
                            if obj.ShowMessages
                                disp('  - samplerate   : <empty> (coerced)');
                            end
                        end
                    case 'maxLength'
                        if ~isempty(paramValue)
                            maxLength = abs(str2double(paramValue));
                            coerced   = false;
                            if isnan(maxLength) || isinf(maxLength)
                                disp(['Scope: Warning - ''configureAcquisition'' ' ...
                                    'maxLength parameter value is invalid ' ...
                                    '--> coerce and continue']);
                                maxLength = 140e3; % default (non interleaved)
                                coerced   = true;
                            end
                            % okay ==> round to allowed values 7e3, 7e4,
                            % 7e5, 7e6 (interleaved mode)
                            tmp       = maxLength;
                            maxLength = min(maxLength, 14e6);
                            maxLength = max(maxLength, 7e3);
                            Mantissa = 10^(log10(maxLength) - ...
                                floor(log10(maxLength)));
                            if Mantissa < 3
                                Mantissa = 1.4;
                            else
                                Mantissa = 7;
                            end
                            maxLength = Mantissa * 10^floor(log10(maxLength));
                            if maxLength ~= tmp
                                coerced = true;
                            end
                            if obj.ShowMessages && coerced
                                disp(['  - maxLength    : ' ...
                                    num2str(maxLength, '%g') ...
                                    ' (coerced)']);
                            end
                        end
                    case 'mode'
                        mode = paramValue;
                        switch lower(mode)
                            case ''
                                mode = '';
                            case {'sample', 'normal', 'norm'}
                                mode = 'SAMPLING';
                            case {'peakdetect', 'peak'}
                                mode = 'PEAK_DETECT';
                            case {'average', 'aver'}
                                mode = 'AVERAGE';
                            case {'highres', 'hres', 'highresolution'}
                                mode = 'HIGH_RES';
                            otherwise
                                mode = '';
                                disp(['Scope: Warning - ''configureAcquisition'' ' ...
                                    'mode parameter value is unknown ' ...
                                    '--> ignore and continue']);
                        end
                    case 'numAverage'
                        if ~isempty(paramValue)
                            numAverage = abs(str2double(paramValue));
                            coerced    = false;
                            if isnan(numAverage) || isinf(numAverage)
                                disp(['Scope: Warning - ''configureAcquisition'' ' ...
                                    'numAverage parameter value is invalid ' ...
                                    '--> coerce and continue']);
                                numAverage = 4;
                                coerced    = true;
                            end
                            tmp        = numAverage;
                            numAverage = min(numAverage, 1024);
                            numAverage = max(numAverage, 4);
                            if     numAverage <= 8
                                numAverage = 4;
                            elseif numAverage <= 16
                                numAverage = 16;
                            elseif numAverage <= 32
                                numAverage = 32;
                            elseif numAverage <= 64
                                numAverage = 64;
                            elseif numAverage <= 128
                                numAverage = 128;
                            elseif numAverage <= 256
                                numAverage = 256;
                            elseif numAverage <= 512
                                numAverage = 512;
                            elseif numAverage <= 1024
                                numAverage = 1024;
                            end
                            if numAverage ~= tmp
                                coerced = true;
                            end
                            if obj.ShowMessages && coerced
                                disp(['  - numAverage   : ' ...
                                    num2str(numAverage, '%d') ' (coerced)']);
                            end
                        end
                    otherwise
                        if ~isempty(paramValue)
                            disp(['  WARNING - parameter ''' ...
                                paramName ''' is unknown --> ignore']);
                        end
                end
            end

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------

            % tDiv        : numeric value in s
            %               [1e-9 ... 5e1]
            if ~isempty(tDiv)
                % format (round) numeric value
                tDivString = num2str(tDiv, '%1.1e');
                tDiv       = str2double(tDivString);
                % set parameter
                obj.VisaIFobj.write(['TIME_DIV ' tDivString]);
                % read and verify
                response = obj.VisaIFobj.query('TIME_DIV?');
                tDivActual = str2double(char(response));
                if tDiv ~= tDivActual
                    disp(['Scope: WARNING - ''configureAcquisition'' ' ...
                        'tDiv parameter could not be set correctly. ' ...
                        'Check limits. ']);
                end
            end

            % mode     : 'sample', 'peakdetect', 'average', 'highres'
            if ~isempty(mode)
                if strcmpi(mode, 'average')
                    if ~isempty(numAverage)
                        mode = [mode ',' num2str(numAverage, '%d')];
                    else
                        mode = [mode ',4'];
                        if obj.ShowMessages
                            disp('  - numAverage   : 4 (coerced)');
                        end
                    end
                elseif ~isempty(numAverage)
                    if obj.ShowMessages
                        disp('  - numAverage   : <empty> (coerced)');
                    end
                end
                % set parameter
                obj.VisaIFobj.write(['ACQUIRE_WAY ' mode]);
                % read and verify
                response = obj.VisaIFobj.query('ACQUIRE_WAY?');
                if ~strcmpi(mode, char(response))
                    disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                        'mode parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % numAverage  : 4 .. 1024
            if ~isempty(numAverage) && isempty(mode)
                mode = ['AVERAGE,' num2str(numAverage, '%d')];
                % set parameter
                obj.VisaIFobj.write(['ACQUIRE_WAY ' mode]);
                % read and verify
                response = obj.VisaIFobj.query('ACQUIRE_WAY?');
                if ~strcmpi(mode, char(response))
                    disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                        'mode parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % maxLength : 7k, 70k, .. 7M for interleaved channels
            %             value*2        for single channel
            if ~isempty(maxLength)
                % check interleaved mode?
                response = obj.VisaIFobj.query('MEMORY_SIZE?');
                if strcmpi(char(response(1)), '7')
                    % interleaved
                    % finally convert to string
                    switch maxLength
                        case {7e3, 14e3}
                            MaxMemSize = '7k';
                        case {7e4, 14e4}
                            MaxMemSize = '70k';
                        case {7e5, 14e5}
                            MaxMemSize = '700k';
                        case {7e6, 14e6}
                            MaxMemSize = '7M';
                        otherwise
                            warning('Should be an impossible internal state');
                            status = -1;
                            return
                    end
                else
                    % non interleaved (assumption)
                    % finally convert to string
                    switch maxLength
                        case {7e3, 14e3}
                            MaxMemSize = '14k';
                        case {7e4, 14e4}
                            MaxMemSize = '140k';
                        case {7e5, 14e5}
                            MaxMemSize = '1.4M';
                        case {7e6, 14e6}
                            MaxMemSize = '14M';
                        otherwise
                            warning('Should be an impossible internal state');
                            status = -1;
                            return
                    end
                end

                % set parameter
                obj.VisaIFobj.write(['MEMORY_SIZE ' MaxMemSize]);
                % read and verify
                response = obj.VisaIFobj.query('MEMORY_SIZE?');
                if ~strcmpi(MaxMemSize, char(response))
                    disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                        'maxLength parameter could not be set correctly.']);
                    status = -1;

                end
            end

            % wait for operation complete
            obj.VisaIFobj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = configureTrigger(obj, varargin)
            % configureTrigger : configure trigger parameters
            %   'mode'        : 'single', 'normal', 'auto'
            %   'type'        : 'risingedge', 'fallingedge' ...
            %   'source'      : 'ch1', 'ch2' , 'ext', 'ext5' ...
            %   'coupling'    : 'AC', 'DC', 'LFReject', 'HFRreject'
            %   'level'       : real
            %   'delay'       : real

            % init output
            status = NaN;

            % initialize all supported parameters
            mode      = '';
            type      = '';
            source    = '';
            coupling  = '';
            level     = [];
            delay     = [];

            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
                switch paramName
                    case 'mode'
                        mode = paramValue;
                        switch lower(mode)
                            case ''
                                mode = '';
                            case 'single'
                                mode = 'SINGLE';
                            case 'normal'
                                mode = 'NORM';
                            case 'auto'
                                mode = 'AUTO';
                            otherwise
                                mode = '';
                                disp(['Scope: Warning - ''configureTrigger'' ' ...
                                    'mode parameter value is unknown ' ...
                                    '--> ignore and continue']);
                        end
                    case 'type'
                        type = paramValue;
                        switch lower(type)
                            case ''
                                type = '';
                            case 'risingedge'
                                type = 'POS';
                            case 'fallingedge'
                                type = 'NEG';
                            otherwise
                                type = '';
                                disp(['Scope: Warning - ''configureTrigger'' ' ...
                                    'type parameter value is unknown ' ...
                                    '--> ignore and continue']);
                        end
                    case 'source'
                        source = lower(paramValue);
                        switch source
                            case ''
                                % all fine
                            case 'ch1'
                                source = 'C1';
                            case 'ch2'
                                source = 'C2';
                            case 'ext'
                                source = 'EX';
                            case 'ext5'
                                source = 'EX5';
                            case 'ac-line'
                                source = 'LINE';
                            otherwise
                                source = '';
                                disp(['Scope: Warning - ''configureTrigger'' ' ...
                                    'source parameter value is unknown ' ...
                                    '--> ignore and continue']);
                        end
                    case 'coupling'
                        coupling = lower(paramValue);
                        switch coupling
                            case ''
                                % fine
                            case {'ac', 'dc'}
                                coupling = upper(coupling);
                            case {'lfreject', 'lfrej'}
                                coupling = 'LFREJ'; % with high pass
                            case {'hfreject', 'hfrej'}
                                coupling = 'HFREJ'; % with low pass
                            case {'noisereject', 'noiserej'}
                                status = 1;
                                disp(['Scope: Warning - ''configureTrigger'' ' ...
                                    'NoiseReject is not supported by this Scope']);
                                coupling = '';
                                if obj.ShowMessages
                                    disp(['  - coupling     : ' ...
                                        '<empty> (coerced)']);
                                end
                            otherwise
                                coupling = '';
                                disp(['Scope: Warning - ''configureTrigger'' ' ...
                                    'coupling parameter value is unknown ' ...
                                    '--> ignore and continue']);
                        end
                    case 'level'
                        if ~isempty(paramValue)
                            level = str2double(paramValue);
                            if isinf(level)
                                level = NaN;
                            end
                        end
                    case 'delay'
                        if ~isempty(paramValue)
                            delay = str2double(paramValue);
                            if isnan(delay) || isinf(delay)
                                delay = [];
                            end
                        end
                    otherwise
                        if ~isempty(paramValue)
                            disp(['  WARNING - parameter ''' ...
                                paramName ''' is unknown --> ignore']);
                        end
                end
            end

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------

            % mode     : 'single', 'normal', 'auto'
            if ~isempty(mode)
                % set parameter
                obj.VisaIFobj.write(['TRIG_MODE ' mode]);
                % read and verify
                response = obj.VisaIFobj.query('TRIG_MODE?');
                if ~strcmpi(mode, char(response))
                    % when TriggerMode = single then response can be stop
                    % as well
                    if ~strcmpi(mode, 'single') || ...
                            ~strcmpi('STOP', char(response))
                        disp(['Scope: Error - ''configureTrigger'' ' ...
                            'mode parameter could not be set correctly.']);
                        status = -1;
                    end
                end
            end

            % source   : 'C1..2', 'EX', 'EX5', 'LINE'
            if isempty(source) && (~isempty(type) || ~isempty(coupling) ...
                    || (~isempty(level) && ~isnan(level)))
                % request current trigger source setting
                response = obj.VisaIFobj.query('TRIG_SELECT?');
                response = split(char(response), ',');
                idx      = find(strcmpi(response, 'SR'));
                if ~isempty(idx) && idx+1 <= length(response)
                    source = response{idx+1};
                else
                    source = 'C1';  % default
                    if obj.ShowMessages
                        disp(['  - source       : ' ...
                            'CH1 (coerced)']);
                    end
                end
            end
            if ~isempty(source)
                % set parameter
                cmdString = ['EDGE,SR,' source ',HT,OFF'];
                obj.VisaIFobj.write(['TRIG_SELECT ' cmdString]);
                % read and verify
                %
                % known issue: FW1.3.27 setting C2 fails
                response = obj.VisaIFobj.query('TRIG_SELECT?');
                if ~strcmpi(cmdString, char(response))
                    disp(['Scope: Error - ''configureTrigger'' ' ...
                        'source parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % type      : rising or falling edge
            if ~isempty(type)
                % set parameter
                obj.VisaIFobj.write([source ':TRIG_SLOPE ' type]);
                % read and verify
                response = obj.VisaIFobj.query([source ':TRIG_SLOPE?']);
                if ~strcmpi(type, char(response))
                    disp(['Scope: Error - ''configureTrigger'' ' ...
                        'type parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % coupling  : 'AC', DC, ...
            if ~isempty(coupling)
                if strcmpi(source, 'LINE')
                    if obj.ShowMessages
                        disp(['  - coupling     : ' ...
                            '<empty> (coerced)']);
                    end
                else
                    % set parameter
                    obj.VisaIFobj.write([source ':TRIG_COUPLING ' coupling]);
                    % read and verify
                    response = obj.VisaIFobj.query([source ':TRIG_COUPLING?']);
                    if ~strcmpi(coupling, char(response))
                        disp(['Scope: Error - ''configureTrigger'' ' ...
                            'coupling parameter could not be set correctly.']);
                        status = -1;
                    end
                end
            end

            % level    : double, in V; NaN for set level to 50%
            if isnan(level)
                % set trigger level to 50% of input signal
                obj.VisaIFobj.write('SET50');
                obj.VisaIFobj.opc;
                if obj.ShowMessages
                    disp(['  - trigger level is ''NaN'': try to set trigger ' ...
                        'level to center of waveform signal.']);
                end
            elseif ~isempty(level)
                if strcmpi(source, 'LINE')
                    if obj.ShowMessages
                        disp(['  - level        : ' ...
                            '<empty> (coerced)']);
                    end
                else
                    % format (round) numeric value
                    levelString = num2str(level, '%1.1e');
                    level       = str2double(levelString);
                    % set parameter
                    obj.VisaIFobj.write([source ':TRIG_LEVEL ' levelString]);
                    % read and verify
                    response    = obj.VisaIFobj.query([source ...
                        ':TRIG_LEVEL?']);
                    levelActual = str2double(char(response));
                    if abs(level - levelActual) > 1 % !!!
                        % sensible threshold depends on vDiv of trigger source
                        disp(['Scope: Warning - ''configureTrigger'' ' ...
                            'level parameter could not be set correctly. ' ...
                            'Check limits.']);
                    end
                end
            end

            % delay    : double, in s
            if ~isempty(delay)
                % format (round) numeric value
                delayString = num2str(delay, '%1.2e');
                delay       = str2double(delayString);
                % set parameter
                obj.VisaIFobj.write(['TRIG_DELAY ' delayString]);
                % read and verify
                response    = obj.VisaIFobj.query('TRIG_DELAY?');
                response    = char(response); % delay with unit
                % conversion: e.g. 20.0ns to 2e-8
                idx = regexp(response, '^\-?\d+\.?\d*\e?[\-\+]?\d*', 'end', 'ignorecase');
                if ~isempty(idx)
                    delayActual = str2double(response(1:idx));
                    if length(response) > idx
                        unit  = response(idx+1:end);
                        switch lower(unit)
                            case {'ns'}
                                delayActual = delayActual * 1e-9;
                            case {'us'}
                                delayActual = delayActual * 1e-6;
                            case {'ms'}
                                delayActual = delayActual * 1e-3;
                            case {'s'}
                                delayActual = delayActual * 1e-0;
                            otherwise
                                delayActual = delayActual * 1; %???
                        end
                    else
                        % SDS1202X-E give response without any unit
                        delayActual = delayActual * 1;
                    end
                else
                    delayActual = NaN;
                end
                if abs(delay - delayActual) > 1e-2 % !!!
                    % sensible threshold depends on tDiv
                    disp(['Scope: Warning - ''configureTrigger'' ' ...
                        'delay parameter could not be set correctly. ' ...
                        'Check limits.']);
                end
            end

            % wait for operation complete
            obj.VisaIFobj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = configureZoom(obj, varargin)
            % configureZoom   : configure zoom window

            % init output
            status = NaN;

            % initialize all supported parameters
            zoomFactor      = [];
            zoomPosition    = [];

            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
                switch paramName
                    case 'zoomFactor'
                        if ~isempty(paramValue)
                            zoomFactor = abs(real(str2double(paramValue)));
                            coerced    = false;
                            if zoomFactor < 1 || isnan(zoomFactor)
                                zoomFactor = 1; % deactivates zoom
                                coerced    = true;
                            end
                            if obj.ShowMessages && coerced
                                disp(['  - zoomFactor   : ' ...
                                    num2str(zoomFactor, '%g') ...
                                    ' (coerced)']);
                            end
                        end
                    case 'zoomPosition'
                        if ~isempty(paramValue)
                            zoomPosition = real(str2double(paramValue));
                            if isnan(zoomPosition)
                                zoomPosition = 0; % center
                                if obj.ShowMessages
                                    disp('  - zoomPosition : 0 (coerced)');
                                end
                            end
                        end
                    otherwise
                        if ~isempty(paramValue)
                            disp(['  WARNING - parameter ''' ...
                                paramName ''' is unknown --> ignore']);
                        end
                end
            end

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------

            % request current timebase
            tdiv = obj.VisaIFobj.query('TIME_DIV?');
            tdiv = str2double(char(tdiv));
            if isnan(tdiv)
                disp(['Scope: ERROR - ''configureZoom'' ' ...
                    'unexpected response ' ...
                    '--> abort and continue']);
                status = -1;
                return
            end

            skipHPOS = false;
            if ~isempty(zoomFactor)
                % zoomFactor will determine hor_magnify value (like tdiv)
                hmag_tdiv = tdiv / zoomFactor;
                %
                % hmag value will be rounded by Scope to nearest upper value
                if zoomFactor == 1
                    % disable zoom window: there is no command to disable
                    % the zoom window at SDS1202X-E again
                    disp(['Scope: Warning - ' ...
                        '''configureZoom'': zoom window cannot be disabled ' ...
                        'by ''zoomFactor = 1'' again.']);
                    disp(['                 ' ...
                        'Disable zoom windows manually by pressing horizontal ' ...
                        'knob (tDiv) at scope.']);
                    status = 1; % warning
                    skipHPOS = true;
                else
                    % enable zoom window
                    obj.VisaIFobj.write(['HOR_MAGNIFY ' ...
                        num2str(hmag_tdiv, '%1.1e')]);
                    % no readback and verify
                end
            else
                % enable zoom window by writing current settings again
                response = obj.VisaIFobj.query('HOR_MAGNIFY?');
                response = char(response);
                if isnumeric(str2double(response))
                    obj.VisaIFobj.write(['HOR_MAGNIFY ' response]);
                end
            end

            if ~isempty(zoomPosition) && ~skipHPOS
                % write value in s
                obj.VisaIFobj.write(['HOR_POSITION ' ...
                    num2str(zoomPosition, '%1.2e')]);
                % no readback and verify
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = autoscale(obj, varargin)
            % autoscale       : adjust vertical and/or horizontal scaling
            %                   vDiv, vOffset for vertical and
            %                   tDiv for horizontal
            %   'mode'        : 'hor', 'vert', 'both'
            %   'channel'     : 1 .. 2

            % init output
            status = NaN;

            % initialize all supported parameters
            mode      = '';
            channels  = {};

            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
                switch paramName
                    case 'channel'
                        % split and copy to cell array of char
                        channels = split(paramValue, ',');
                        % remove spaces
                        channels = regexprep(channels, '\s+', '');
                        % loop
                        for cnt = 1 : length(channels)
                            switch channels{cnt}
                                case {'', '1', '2'}
                                    % do nothing
                                otherwise
                                    channels{cnt} = '';
                                    disp(['Scope: Warning - ' ...
                                        '''autoscale'' invalid ' ...
                                        'channel (allowed are 1 .. 2) ' ...
                                        '--> ignore and continue']);
                            end
                        end
                        % remove invalid (empty) entries
                        channels = channels(~cellfun(@isempty, channels));
                    case 'mode'
                        switch lower(paramValue)
                            case ''
                                mode = 'both'; % set to default
                                if obj.ShowMessages
                                    disp('  - mode         : BOTH (coerced)');
                                end
                            case 'both'
                                mode = 'both';
                            case {'hor', 'horizontal'}
                                mode = 'horizontal';
                            case {'vert', 'vertical'}
                                mode = 'vertical';
                            otherwise
                                mode = '';
                                disp(['Scope: Warning - ''autoscale'' ' ...
                                    'mode parameter value is unknown ' ...
                                    '--> ignore and continue']);
                        end
                    otherwise
                        if ~isempty(paramValue)
                            disp(['  WARNING - parameter ''' ...
                                paramName ''' is unknown --> ignore']);
                        end
                end
            end

            % two config parameters:
            % how many signal periods should be visible in waveform?
            % sensible range 2 .. 50 (large values result in slow sweeps
            % for horizontal (tDiv) scaling
            numOfSignalPeriods    = obj.AutoscaleHorizontalSignalPeriods;

            % ratio of ADC-fullscale range
            % > 1.25  ATTENTION: ADC will be overloaded: (-5 ..+5) vDiv
            %     scaling factor up to 1.25 is possible (ADC-full range)
            % 1.00 means full display-range (-4 ..+4) vDiv
            % sensible range is 0.3 .. 0.9
            verticalScalingFactor = obj.AutoscaleVerticalScalingFactor;

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------

            % define default when channel parameter is missing
            if isempty(channels)
                channels = {'1', '2'};
                if obj.ShowMessages
                    disp('  - channel      : 1, 2 (coerced)');
                end
            end

            % horizontal scaling: adjust tDiv
            if strcmpi(mode, 'horizontal') || strcmpi(mode, 'both')
                % request trigger frequency
                response = obj.VisaIFobj.query('CYMOMETER?');
                % format of response is xxx without unit
                % value in Hz
                freq     = str2double(char(response));
                if ~isnan(freq)
                    % adjust tDiv parameter
                    % calculate sensible tDiv parameter (14*tDiv@screen)
                    tDiv = numOfSignalPeriods / (14*freq);
                    % now send new tDiv parameter to scope
                    %obj.VisaIFobj.configureAcquisition('tDiv', tDiv);
                    % low level command to avoid display messages
                    statConf = obj.configureAcquisition( ...
                        'tDiv', num2str(tDiv, '%1.2e'));
                    if statConf
                        status = -5;
                    end
                else
                    disp(['Scope: Warning - ''autoscale'': ' ...
                        'invalid frequency measurement results. ' ...
                        'Skip horizontal scaling.']);
                    status = 1; % warning
                    return
                end
            end

            % Siglent scope is quite slow, additional wait is sensible
            pause(0.05);
            % wait for operation complete
            obj.VisaIFobj.opc;

            % vertical scaling: adjust vDiv, vOffset
            if strcmpi(mode, 'vertical') || strcmpi(mode, 'both')
                for cnt = 1:length(channels)
                    % check if channel is active
                    response = obj.VisaIFobj.query(['C' channels{cnt} ...
                        ':TRACE?']);
                    if ~strcmpi('ON', char(response))
                        % break loop ==> try next channel
                        continue;
                    end
                    % init
                    loopcnt  = 0;
                    maxcnt   = 9;
                    while loopcnt < maxcnt
                        % time for settlement
                        pause(0.05);

                        % request current vDiv setting
                        vDiv = obj.VisaIFobj.query( ...
                            ['C' channels{cnt} ':VOLT_DIV?']);
                        vDiv = str2double(char(vDiv));
                        % request current vOffset setting
                        vOffset = obj.VisaIFobj.query( ...
                            ['C' channels{cnt} ':OFFSET?']);
                        vOffset = str2double(char(vOffset));

                        % measure min and max voltage
                        result = obj.runMeasurement( ...
                            'channel', channels{cnt}, ...
                            'parameter', 'minimum');
                        vMin   = result.value;
                        result = obj.runMeasurement( ...
                            'channel', channels{cnt}, ...
                            'parameter', 'maximum');
                        vMax   = result.value;

                        % check values
                        if isnan(vDiv) || isnan(vOffset) || ...
                                isnan(vMin) || isnan(vMax)
                            status = -10;
                            disp(['Scope: Warning - ''autoscale'': ' ...
                                'invalid measurement results. ' ...
                                'Skip vertical scaling.']);
                            break;
                        end

                        % ADC is clipped?
                        % (when vMax ==  5*vDiv - vOffset)
                        % (when vMin == -5*vDiv - vOffset)
                        adcMax = (vMax + vOffset >=  4.9*vDiv);
                        adcMin = (vMin + vOffset <= -4.9*vDiv);

                        % estimate voltage scaling (gain)
                        % 8 vertical divs at display
                        vDiv = (vMax - vMin) / 8;
                        % estimate voltage offset
                        vOffset = (vMax + vMin)/2;

                        if adcMax && adcMin
                            % pos. and neg. clipping: scale down
                            vDiv    = vDiv / 0.34;
                        elseif adcMax
                            % positive clipping: scale down
                            vOffset = vOffset + 3* vDiv;
                            vDiv    = vDiv / 0.5;
                        elseif adcMin
                            % negative clipping: scale down
                            vOffset = vOffset - 3* vDiv;
                            vDiv    = vDiv / 0.5;
                        else
                            % adjust gently
                            vDiv    = vDiv / verticalScalingFactor;
                        end

                        % send new vDiv, vOffset parameters to scope
                        statConf = obj.configureInput(...
                            'channel' , channels{cnt}, ...
                            'vDiv'    , num2str(vDiv   , '%1.1e'),  ...
                            'vOffset' , num2str(vOffset, '%1.1e'));

                        if statConf
                            status = -11;
                        end

                        % wait for completion
                        obj.VisaIFobj.opc;

                        % update loop counter
                        loopcnt = loopcnt + 1;

                        if ~adcMax && ~adcMin && loopcnt ~= maxcnt
                            % shorten loop when no clipping ==> do a
                            % final loop run to ensure proper scaling
                            loopcnt = maxcnt - 1;
                        end
                    end
                end
            end

            % wait for operation complete
            obj.VisaIFobj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = makeScreenShot(obj, varargin)
            % make a screenshot of scope display (BMP-file)
            %   'fileName' : file name with optional extension
            %                optional, default is './Siglent_Scope_SDS1202X-E.bmp'
            %   'darkMode' : on/off, dark or white background color
            %                optional, default is 'off', 0, false,
            %                unsupported parameter

            % init output
            status = NaN;

            % configuration and default values
            listOfSupportedFormats = {'.bmp'};
            filename = './Siglent_Scope_SDS1202X-E.bmp';
            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
                switch paramName
                    case 'fileName'
                        if ~isempty(paramValue)
                            filename = paramValue;
                        end
                    case 'darkMode'
                        switch lower(paramValue)
                            case {'off', '0'}
                                disp(['Scope: WARNING - ''makeScreenShot'' ' ...
                                    'darkMode = off is not supported.']);
                                if obj.ShowMessages
                                    disp('  - darkMode     : 1 (coerced)');
                                end
                            otherwise
                                % fine
                        end
                    otherwise
                        disp(['  WARNING - parameter ''' ...
                            paramName ''' is unknown --> ignore']);
                end
            end

            % check if file extension is supported
            [~, fname, fext] = fileparts(filename);
            if isempty(fname)
                disp(['Scope: ERROR - ''makeScreenShot'' file name ' ...
                    'must not be empty. Skip function.']);
                status = -1;
                return
            elseif any(strcmpi(fext, listOfSupportedFormats))
                %fileFormat = fext(2:end); % without leading .
            else
                % no supported file extension
                if isempty(fext)
                    % use default
                    fileFormat = listOfSupportedFormats{1};
                    fileFormat = fileFormat(2:end);
                    filename   = [filename '.' fileFormat];
                    if obj.ShowMessages
                        disp(['  - fileName     : ' filename ' (coerced)']);
                    end
                else
                    disp(['Scope: ERROR - ''makeScreenShot'' file ' ...
                        'extension is not supported. Skip function.']);
                    disp('Supported file extensions are:')
                    for cnt = 1 : length(listOfSupportedFormats)
                        disp(['  ' listOfSupportedFormats{cnt}]);
                    end
                    status = -1;
                    return
                end
            end

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------
            save_and_restore_display_settings = false;

            if save_and_restore_display_settings
                % save display settings
                % 1st step: save current intensity settings of display
                dispSettings = obj.VisaIFobj.query('INTENSITY?'); %#ok<UNRCH>
                dispSettings = char(dispSettings);

                % response has form
                % 'TRACE,xx,GRID,yy'           for COMM_HEADER = OFF
                % 'INTS TRACE,xx,GRID,yy'                      = SHORT
                % 'INTENSITY TRACE,xx,GRID,yy'                 = LONG
                % with xx, yy - integer values 0 or 1 .. 100
                % separate parameters
                ParamList     = strtrim(split(dispSettings,','));
                if length(ParamList) == 4
                    % save values
                    TraceValue = str2double(ParamList{2});
                    GridValue  = str2double(ParamList{4});
                else
                    TraceValue = NaN;
                    GridValue  = NaN;
                end
                % set highest contrast for screenshot
                if ~isnan(TraceValue) && ~isnan(GridValue)
                    obj.VisaIFobj.write('INTENSITY TRACE,100,GRID,100');
                end
            end

            % -------------------------------------------------------------
            % request actual binary screen shot data
            % only shortform of SCPI command is supported
            %bitMapData = obj.VisaIFobj.query('SCREEN_DUMP');
            %bitMapData = obj.VisaIFobj.query('SCDP');
            % split query command to separate write and read due to binary
            % response
            obj.VisaIFobj.write('SCDP');
            bitMapData = obj.VisaIFobj.read;

            % response is always 768066 bytes for plain bitmap data
            % without any additional header
            % 800x480 pixel with 16 bit depth (for colors) + 66 Bytes
            % header
            if length(bitMapData) ~= 768066
                disp(['Scope: ERROR - ''makeScreenShot'' unexpected ' ...
                    'resonse. Abort function.']);
                % error (incorrect number of bytes)
                status = -1;
            else
                % save data to file
                fid = fopen(filename, 'wb+');  % open as binary
                fwrite(fid, bitMapData, 'uint8');
                fclose(fid);
            end

            % -------------------------------------------------------------
            if save_and_restore_display_settings
                % restore Display settings
                if ~isnan(TraceValue) && ~isnan(GridValue) %#ok<UNRCH>
                    obj.VisaIFobj.write(['INTENSITY ' ...
                        'TRACE,' num2str(TraceValue, '%g') ...
                        ',GRID,' num2str(GridValue, '%g')]);
                end
            end

            % wait for operation complete
            [~, status_query] = obj.VisaIFobj.opc;
            if status_query
                status = -1;
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
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

            % init output
            meas.status    = NaN;
            meas.value     = NaN;
            meas.unit      = '';
            meas.channel   = '';
            meas.parameter = '';

            % default values
            channels  = {};
            parameter = '';
            unit      = '';

            % was this method called internally
            myStack = dbstack(1, '-completenames');
            internalCall = startsWith(myStack(1).name, 'ScopeMacros');

            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
                switch paramName
                    case 'channel'
                        % split and copy to cell array of char
                        channels = split(paramValue, ',');
                        % remove spaces
                        channels = regexprep(channels, '\s+', '');
                        % loop
                        for cnt = 1 : length(channels)
                            switch channels{cnt}
                                case {'', '1', '2'}
                                    % do nothing: all fine
                                otherwise
                                    channels{cnt} = '';
                                    disp(['Scope: WARNING - ' ...
                                        '''runMeasurement'' invalid ' ...
                                        'channel (allowed are 1 .. 2) ' ...
                                        '--> ignore and continue']);
                            end
                        end
                        % remove invalid (empty) entries
                        channels     = ...
                            channels(~cellfun(@isempty, channels));
                    case 'parameter'
                        % default for most measurements (Attention: should
                        % change when unit of channel is set to 'A', see
                        % method configureInput('unit', 'A'))
                        unit = 'V';
                        switch lower(paramValue)
                            case ''
                                % do nothing (skip measurement)
                                unit      = '';
                            case {'frequency', 'freq'}
                                parameter = 'FREQ';
                                unit      = 'Hz';
                            case {'period', 'peri', 'per'}
                                parameter = 'PER';
                                unit      = 's';
                            case {'cycmean', 'cmean'}
                                parameter = 'CMEAN';
                            case 'mean'
                                parameter = 'MEAN';
                            case {'cycrms', 'crms'}
                                parameter = 'CRMS';
                            case 'rms'
                                parameter = 'RMS';
                            case {'pk-pk', 'pkpk', 'pk2pk', 'peak'}
                                parameter = 'PKPK';
                            case {'maximum', 'max'}
                                parameter = 'MAX';
                            case {'minimum', 'min'}
                                parameter = 'MIN';
                            case {'high', 'top'}
                                parameter = 'TOP';
                            case {'low', 'base'}
                                parameter = 'BASE';
                            case {'amplitude', 'amp'}
                                parameter = 'AMPL';
                            case {'povershoot', 'pover'}
                                parameter = 'OVSP';
                                unit      = '%';
                            case {'novershoot', 'nover'}
                                parameter = 'OVSN';
                                unit      = '%';
                            case {'overshoot', 'over'}
                                parameter = 'OVSP';
                                unit      = '%';
                                if obj.ShowMessages
                                    disp(['  - parameter    : ' ...
                                        'povershoot (coerced)']);
                                end
                            case {'ppreshoot', 'ppre'}
                                parameter = 'RPRE';
                                unit      = '%';
                            case {'npreshoot', 'npre'}
                                parameter = 'FPRE';
                                unit      = '%';
                            case {'preshoot', 'pre'}
                                parameter = 'RPRE';
                                unit      = '%';
                                if obj.ShowMessages
                                    disp(['  - parameter    : ' ...
                                        'ppreshoot (coerced)']);
                                end
                            case {'risetime', 'rise'}
                                parameter = 'RISE';
                                unit      = 's';
                            case {'falltime', 'fall'}
                                parameter = 'FALL';
                                unit      = 's';
                            case {'poswidth', 'pwidth'}
                                parameter = 'PWID';
                                unit      = 's';
                            case {'negwidth', 'nwidth'}
                                parameter = 'NWID';
                                unit      = 's';
                            case {'burstwidth', 'bwidth'}
                                parameter = 'WID';
                                unit      = 's';
                            case {'dutycycle', 'dutycyc', 'dcycle', 'dcyc'}
                                parameter = 'DUTY';
                                unit      = '%';
                            case 'phase'
                                parameter = 'PHA';
                                unit      = 'deg';
                            case 'delay'
                                parameter = 'SKEW';
                                unit      = 's';
                            otherwise
                                disp(['Scope: Warning - ''runMeasurement'' ' ...
                                    'measurement type ' paramValue ...
                                    ' is unknown --> skip measurement']);
                        end
                    otherwise
                        disp(['  WARNING - parameter ''' ...
                            paramName ''' is unknown --> ignore']);
                end
            end

            % check inputs (parameter)
            switch lower(parameter)
                case ''
                    disp(['Scope: ERROR ''runMeasurement'' ' ...
                        'supported measurement parameters are ' ...
                        '--> skip and exit']);
                    disp('  ''frequency''');
                    disp('  ''period''');
                    disp('  ''cycmean''');
                    disp('  ''mean''');
                    disp('  ''cycrms''');
                    disp('  ''rms''');
                    disp('  ''pk-pk''');
                    disp('  ''maximum''');
                    disp('  ''minimum''');
                    disp('  ''high''');
                    disp('  ''low''');
                    disp('  ''amplitude''');
                    disp('  ''povershoot''');
                    disp('  ''novershoot''');
                    disp('  ''ppreshoot''');
                    disp('  ''npreshoot''');
                    disp('  ''risetime''');
                    disp('  ''falltime''');
                    disp('  ''poswidth''');
                    disp('  ''negwidth''');
                    disp('  ''burstwidth''');
                    disp('  ''dutycycle''');
                    disp('  ''phase''');
                    disp('  ''delay''');
                    meas.status = -1;
                    return
                case {'pha', 'skew'}
                    if length(channels) ~= 2
                        disp(['Scope: ERROR ''runMeasurement'' ' ...
                            'two source channels have to be specified ' ...
                            'for phase or delay measurements ' ...
                            '--> skip and exit']);
                        meas.status = -1;
                        return
                    else
                        source    = ['C' channels{1} '-C' channels{2}];
                    end
                otherwise
                    if length(channels) ~= 1
                        % all other measurements for single channel only
                        disp(['Scope: ERROR ''runMeasurement'' ' ...
                            'one source channel has to be specified ' ...
                            '--> skip and exit']);
                        meas.status = -1;
                        return
                    else
                        source    = ['C' channels{1}];
                    end
            end

            % copy to output
            meas.parameter = lower(parameter);
            meas.channel   = strjoin(channels, ', ');

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------

            if strcmpi(parameter, 'pha') || strcmpi(parameter, 'skew')
                % install delay measurement
                %(long form "MEASURE_DELAY" is not supported)
                obj.VisaIFobj.write(['MEAD ' parameter ',' source]);
                % additional settling time
                pause(0.05);
                % request measurement value
                value = obj.VisaIFobj.query([source ...
                    ':MEAD? ' parameter]);
                value = char(value);
            else
                % direct request without installing a measurement
                value = obj.VisaIFobj.query([source ...
                    ':PARAMETER_VALUE? ' parameter]);
                value = char(value);
            end
            % convert result
            value = split(value, ',');
            if length(value) ~= 2
                disp(['Scope: ERROR ''runMeasurement'' ' ...
                    'unexpected response (number of elements) ' ...
                    '--> skip and exit']);
                meas.status = -1;
                return
            elseif ~strcmpi(value{1}, parameter)
                disp(['Scope: ERROR ''runMeasurement'' ' ...
                    'unexpected response (parameter name) ' ...
                    '--> skip and exit']);
                meas.status = -2;
                return
            elseif isnan(str2double(value{2}))
                disp(['Scope: Warning ''runMeasurement'' ' ...
                    'unexpected response (parameter value) ']);
                meas.status = 1;
            end
            value = str2double(value{2});

            if abs(value) > 1e36
                meas.status = 1;      % warning (positive status)
                value = NaN;          % invalid measurement
            end

            % wait for operation complete
            obj.VisaIFobj.opc;

            % copy to output
            meas.value = value;
            meas.unit  = unit;

            % set final status
            if isnan(meas.status)
                % no error so far ==> set to 0 (fine)
                meas.status = 0;
                statusFlag = 'okay';
            else
                statusFlag = 'not okay';
            end

            % optionally display results
            if obj.ShowMessages && ~internalCall
                disp(['  - meas.result : ' ...
                    pad(num2str(meas.value, '%g'), 6, 'left') ...
                    ' ' meas.unit ' ' ...
                    '(status = ' statusFlag ')']);
            end
        end

        function waveData = captureWaveForm(obj, varargin)
            % captureWaveForm: download waveform data
            %   'channel' : one or two channels
            % outputs:
            %   waveData.status     : 0 for okay, -1 for error, 1 for warning
            %   waveData.volt       : waveform data in Volt
            %   waveData.time       : corresponding time vector in s
            %   waveData.samplerate : sample rate in Sa/s (Hz)

            % init output
            waveData.status     = NaN;
            waveData.volt       = [];
            waveData.time       = [];
            waveData.samplerate = [];

            % configuration and default values
            channels = {''};
            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
                switch paramName
                    case 'channel'
                        % split and copy to cell array of char
                        channels = split(paramValue, ',');
                        % remove spaces
                        channels = regexprep(channels, '\s+', '');
                        % loop
                        for cnt = 1 : length(channels)
                            switch channels{cnt}
                                case {'1', '2'}
                                    channels{cnt} = ['C' channels{cnt}];
                                case ''
                                    % do nothing
                                otherwise
                                    channels{cnt} = '';
                                    disp(['Scope: Warning - ' ...
                                        '''captureWaveForm'' invalid ' ...
                                        'channel (allowed are 1 .. 2) ' ...
                                        '--> ignore and continue']);
                            end
                        end
                        % remove invalid (empty) entries
                        channels = channels(~cellfun(@isempty, channels));
                    otherwise
                        disp(['Scope: Warning - ''captureWaveForm'' ' ...
                            'parameter ''' paramName ''' will be ignored']);
                end
            end

            % define default when channel parameter is missing
            % ==> channels contain at least one element
            if isempty(channels)
                channels = {'C1', 'C2'};
                if obj.ShowMessages
                    disp('  - channel      : 1, 2 (coerced)');
                end
            end

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------

            % -------------------------------------------------------------
            % 1st step: request settings which are equal for all channels
            %
            % sample rate in Sa/s
            response = obj.VisaIFobj.query('SAMPLE_RATE?');
            % format of response is Value in Sa/s
            srate = str2double(char(response));

            if ~isnan(srate) && srate > 0
                % fine
            else
                waveData.status = -6; % error
                return
            end
            % copy result to output
            waveData.samplerate = srate;

            % number of available samples
            response = obj.VisaIFobj.query(['SAMPLE_NUM? ' channels{1}]);
            % format of response is value in pts
            xlength = str2double(char(response));

            if xlength == round(xlength)
                % fine
            else
                waveData.status = -8; % error
                return
            end
            % initialize result matrix (acquired voltages = 0)
            waveData.volt = zeros(length(channels), xlength);

            % parameter trigger delay (offset) in s
            response = obj.VisaIFobj.query('TRIG_DELAY?');
            % format of response is value in s
            tDelay = str2double(char(response));

            if ~isnan(tDelay)
                % fine
            else
                waveData.status = -10; % error
                return
            end
            % parameter time divider in s
            value = obj.VisaIFobj.query('TIME_DIV?');
            % format of response is x.xxEyyy in s (for comm_header = off)
            tDiv = str2double(char(value));
            if ~isnan(tDiv)
                % fine
            else
                waveData.status = -12; % error
                return
            end
            %
            % display (horizontal = time) is divided into 14 segments (grid)
            % displayed time range is tDelay-7*tDiv .. tDelay+7*tDiv
            numGrid    = 14;
            % copy result to output
            % sign of tDelay is not verified yet ==> correct shift ???
            waveData.time = (0:xlength-1)/srate +tDelay -tDiv *numGrid/2;

            % -------------------------------------------------------------
            % 2nd step: configure data segments to download data in chunks

            % data chunks must be smaller than obj.VisaIFobj.InputBufferSize
            % 700kSa will divide all possible larger NumSamples without rest
            NSampleMax  = 0.7e6;
            % calculate size of data chunks and number of data chunks
            NumSegments = ceil(xlength / NSampleMax);  % >= 1
            NSamplesSeg =      xlength / NumSegments;  % >= 1

            % increase size of junks when number of segments is even
            if floor(NumSegments/2) == ceil(NumSegments/2)
                NumSegments = NumSegments /2;
                NSamplesSeg = NSamplesSeg *2;
            end

            if mod(xlength, NumSegments) ~= 0
                waveData.status = -15; % error
                return
            end

            % -------------------------------------------------------------
            % 3rd step: run loop over all channels
            for cnt = 1 : length(channels)
                channel = channels{cnt};

                % check if channel is active
                response = obj.VisaIFobj.query([channel ':TRACE?']);
                if ~strcmpi('ON', char(response))
                    % break loop ==> try next channel
                    continue;
                end

                % ---------------------------------------------------------
                % now run a loop to download all waveform data in chunks
                % initialize start address
                NSamplesIdx = 0;
                for cnt2 = 0 : NumSegments-1
                    % specify start address and number of samples
                    obj.VisaIFobj.write(['WAVEFORM_SETUP SP,1,NP,' ...
                        num2str(NSamplesSeg) ',FP,' num2str(NSamplesIdx)]);

                    % run actual waveform download
                    if obj.ShowMessages
                        disp(['  - Channel ' channel ': ' ...
                            'download waveform data ' ...
                            num2str(cnt2 +1, '%d') '/' ...
                            num2str(NumSegments, '%d')]);
                    end
                    % split query into separate write and read to due
                    % binary response
                    %RawData  = obj.VisaIFobj.query([channel ':WF? DAT2']);
                    obj.VisaIFobj.write([channel ':WF? DAT2']);
                    RawData  = obj.VisaIFobj.read;

                    % check and extract header:
                    % e.g. DAT2,#9001400000binarydata with 9 chars
                    % indicating number of bytes for actual data
                    if length(RawData) <= 8
                        waveData.status = -20;  % error
                        return; % exit
                    end
                    headchar = char(RawData(1:6));
                    headlen  = round(str2double(char(RawData(7))));
                    if strcmpi(headchar, 'DAT2,#') && headlen >= 1
                        % fine and go on  (test negative for headlen = NaN)
                    else
                        waveData.status = -21; % error
                        return; % exit
                    end
                    datalen = str2double(char(RawData(7+1 : ...
                        min(7+headlen,length(RawData)))));
                    if length(RawData) ~= 7 + headlen + datalen + 1
                        waveData.status = -22; % error
                        return; % exit
                    end
                    if datalen ~= NSamplesSeg
                        waveData.status = -23; % error
                        return; % exit
                    end
                    % extract binary data (uint8): remove header to get raw
                    % waveform data and also remove last byte which is
                    % always '0A' (LF as end of message indicator)
                    RawData = RawData(7 + headlen + (1:datalen));
                    % cast data from uint8 to correct data format
                    RawData = typecast(RawData, 'int8');
                    % finally convert data and copy to output variable
                    waveData.volt(cnt, (1:datalen)+cnt2*NSamplesSeg) = ...
                        double(RawData); % unscaled voltage

                    % update start address for next download
                    NSamplesIdx = NSamplesIdx + NSamplesSeg;
                end
                clear RawData;

                % ---------------------------------------------------------
                % request parameter voltage divider in V for this channel
                response = obj.VisaIFobj.query([channel ':VOLT_DIV?']);
                % format of response is x.xxEyyy in V (for comm_header = off)
                vDiv = str2double(char(response));
                if isnan(vDiv)
                    vDiv = 1;
                    waveData.status = 1; % warning
                end

                % request parameter voltage offset in V for this channel
                response = obj.VisaIFobj.query([channel ':OFFSET?']);
                % format of response is x.xxEyyy in V (for comm_header = off)
                vOffset = str2double(char(response));
                if isnan(vOffset)
                    vOffset = 0;
                    waveData.status = 1; % warning
                end

                % scale waveform data (in V)
                % formulas are given in SDS2304X programming guide
                % same for SDS1202X-E
                %
                % display (vertical=voltage) is divided into 8 segments (grid)
                % voltage range is
                %   -vOffset-4*vDiv .. -vOffset+4*vDiv @ display of Scope
                %   -vOffset-5*vDiv .. -vOffset+5*vDiv @ ADConverter
                % all received integer values are in range [-125 .. +124]
                % => then clipping occures
                waveData.volt(cnt, :) = waveData.volt(cnt, :) ...
                    * vDiv/25 - vOffset;
            end

            % wait for operation complete
            obj.VisaIFobj.opc;

            % set final status
            if isnan(waveData.status)
                % no error so far ==> set to 0 (fine)
                waveData.status = 0;
            end
        end

        % -----------------------------------------------------------------
        % actual scope methods: get methods (dependent)
        % -----------------------------------------------------------------

        function acqState = get.AcquisitionState(obj)
            % get acquisition state
            % 'running' or 'stopped',   '' when invalid/unknown response

            % there is no dedicated command for acquisition state
            [acqState, status] = obj.VisaIFobj.query('SAMPLE_STATUS?');
            %
            if status ~= 0
                % failure
                acqState = 'visa error. couldn''t read acquisition state';
            else
                % remap acquisition (trigger) state
                acqState = lower(char(acqState));
                switch acqState
                    case 'stop'
                        acqState = 'stopped';
                    case {'arm', 'ready', 'trig''d', 'auto'}
                        acqState = 'running';
                    otherwise
                        acqState = '';
                end
            end
        end

        function trigState = get.TriggerState(obj)
            % get trigger state
            % 'waitfortrigger' or 'triggered', '' when unknown response

            [trigState, status] = obj.VisaIFobj.query('SAMPLE_STATUS?');
            %
            if status ~= 0
                % failure
                trigState = 'visa error. couldn''t read trigger state';
            else
                % remap trigger state
                trigState = lower(char(trigState));
                switch trigState
                    case 'stop'   , trigState = 'triggered (stop)';
                    case 'trig''d', trigState = 'triggered';
                    case 'auto'   , trigState = 'triggered (auto)';
                    case 'ready'  , trigState = 'waitfortrigger';
                    case 'arm'    , trigState = 'waitfortrigger (arm)';
                    otherwise     , trigState = 'device error. unknown state';
                end
            end
        end

        function errMsg = get.ErrorMessages(obj)
            % read error list from the scope’s error buffer

            if obj.ShowMessages
                disp(['Scope WARNING - Method ''ErrorMessages'' is not ' ...
                    'supported for ']);
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
                    disp('ScopeMacros: invalid state in get.ShowMessages');
            end
        end

        function period = get.AutoscaleHorizontalSignalPeriods(obj)

            period = obj.VisaIFobj.AutoscaleHorizontalSignalPeriods;
        end

        function factor = get.AutoscaleVerticalScalingFactor(obj)

            factor = obj.VisaIFobj.AutoscaleVerticalScalingFactor;
        end

    end

end