classdef ScopeMacros < handle
    % ToDo documentation
    %
    %
    % for Scope: Rigol DS2072A series
    % (for Rigol firmware: 00.03.06 (2019-01-29) ==> see myScope.identify)

    properties(Constant = true)
        MacrosVersion = '1.2.1';      % release version
        MacrosDate    = '2021-04-12'; % release date
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
                disp(['Object destructor called for class ' class(obj)]);
            end
        end

        function status = runAfterOpen(obj)

            % init output
            status = NaN;

            % add some device specific commands:
            %
            % set language
            if obj.VisaIFobj.write(':SYSTem:LANGuage ENGLish')
                status = -1;
            end

            % enable autoscale (see method autoset)
            if obj.VisaIFobj.write(':SYSTem:AUToscale ON')
                status = -1;
            end

            % selects range of samples for download of wavedata
            % MAXimum: in the run state, read the waveform data displayed
            % on the screen; in the stop state, read the waveform data in
            % the internal memory. (default after reset is NORMal)
            if obj.VisaIFobj.write(':WAVeform:MODE MAXimum')
                status = -1;
            end
            % set return format of waveform data
            % (default after reset is BYTE)
            if obj.VisaIFobj.write(':WAVeform:FORMat BYTE')
                status = -1;
            end

            % disable the antialiasing function of the oscilloscope
            % (default after reset is off)
            if obj.VisaIFobj.write(':ACQuire:AALias OFF')
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
            if obj.VisaIFobj.write('*CLS')
                status = -1;
            end

            % selects range of samples for download of wavedata
            if obj.VisaIFobj.write(':WAVeform:MODE MAXimum')
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
            % init output
            status = NaN;

            % clear status at scope
            if obj.VisaIFobj.write('*CLS')
                status = -1;
            end

            % clear also all the waveforms on the screen
            if obj.VisaIFobj.write(':CLEar')
                status = -1;
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = lock(obj)
            % lock all buttons at scope

            %status = obj.VisaIFobj.write('SYSTEM:REMOTE'); % not available
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

            %status = obj.VisaIFobj.write('SYSTEM:LOCAL'); % not available
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

            status = obj.VisaIFobj.write(':RUN');
        end

        function status = acqStop(obj)
            % stop data acquisitions at scope

            status = obj.VisaIFobj.write(':STOP');
        end

        function status = autoset(obj)
            % performs an autoset process for analog channels: analyzes the
            % enabled analog channel signals, and adjusts the horizontal,
            % vertical, and trigger settings to display stable waveforms

            % init output
            status = NaN;

            % actual autoset command
            if obj.VisaIFobj.write(':AUToscale')
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
            %   'impedance'   : '50', '1e6'
            %   'vDiv'        : real > 0
            %   'vOffset'     : real
            %   'coupling'    : 'DC', 'AC', 'GND'
            %   'inputDiv'    : 1, 10, 20, 50, 100, 200, 500, 1000
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
                                    trace = '0';
                                case {'on',  '1'}
                                    trace = '1';
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
                            if impedance == 50 || impedance == 1e6
                                coerced   = false;
                            elseif isnan(impedance) || impedance >= 1e3
                                coerced   = true;
                                impedance = 1e6;
                            else
                                coerced   = true;
                                impedance = 50;
                            end
                            if obj.ShowMessages && coerced
                                disp(['  - impedance    : ' ...
                                    num2str(impedance, '%g') ' (coerced)']);
                            end
                            if impedance < 1e3
                                impedance = 'FIFT';  % FIFTy = 50 Ohm
                            else
                                impedance = 'OMEG';  % 1 MOhm
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
                                    coupling = 'AC';
                                case 'dc'
                                    coupling = 'DC';
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
                                case {'0.01', '0.02', '0.05', ...
                                        '0.1', '0.2', '0.5', ...
                                        '1', '2', '5', ...
                                        '10', '20', '50', ...
                                        '100', '200', '500', '1000'}
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
                                    bwLimit = '20M';
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
                                    invert = '0';
                                case {'on',  '1'}
                                    invert = '1';
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
                            elseif skew > 200e-9
                                skew = 200e-9;   % max.  200 ns
                                if obj.ShowMessages
                                    disp('  - skew         : 200e-9 (coerced)');
                                end
                            elseif skew < -200e-9
                                skew = -200e-9;  % min. -500 ns
                                if obj.ShowMessages
                                    disp('  - skew         : -200e-9 (coerced)');
                                end
                            elseif skew ~= round(skew/20e-9)*20e-9
                                % round to 20ns steps
                                skew = round(skew/20e-9)*20e-9;
                                if obj.ShowMessages
                                    disp(['  - skew         : ' ...
                                        num2str(skew, '%g') ' (coerced)']);
                                end
                            end
                        end
                    case 'unit'
                        if ~isempty(paramValue)
                            switch upper(paramValue)
                                case 'V'
                                    unit = 'VOLT';
                                case 'A'
                                    unit = 'AMP';
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

                % 'impedance'
                if ~isempty(impedance)
                    % set parameter
                    obj.VisaIFobj.write([':CHANnel' channel ':IMPedance ' ...
                        impedance]);
                    % read and verify
                    response = obj.VisaIFobj.query([':CHANnel' channel ...
                        ':IMPedance?']);
                    if ~strcmpi(impedance, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'impedance parameter could not be set correctly.']);
                        status = -1;
                    end
                end

                % 'coupling'         : 'DC', 'AC', 'GND'
                if ~isempty(coupling)
                    % set parameter
                    obj.VisaIFobj.write([':CHANnel' channel ':COUPling ' coupling]);
                    % read and verify
                    response = obj.VisaIFobj.query([':CHANnel' channel ':COUPling?']);
                    if ~strcmpi(coupling, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'coupling parameter could not be set correctly.']);
                        status = -1;
                    end
                end

                % 'inputDiv', 'probe': .. 1, 10, 20, 50, 100, ..
                if ~isempty(inputDiv)
                    % set parameter
                    obj.VisaIFobj.write([':CHANnel' channel ':PROBe ' inputDiv]);
                    % read and verify
                    response = obj.VisaIFobj.query([':CHANnel' channel ':PROBe?']);
                    if str2double(inputDiv) ~= str2double(char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'inputDiv parameter could not be set correctly.']);
                        status = -1;
                    end
                end

                % 'unit'             : 'V' or 'A'
                if ~isempty(unit)
                    % set parameter
                    obj.VisaIFobj.write([':CHANnel' channel ':UNITs ' unit]);
                    % read and verify
                    response = obj.VisaIFobj.query([':CHANnel' channel ':UNITs?']);
                    if ~strcmpi(unit, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'unit parameter could not be set correctly.']);
                        status = -1;
                    end
                end

                % 'bwLimit'          : 'off', 'on'
                if ~isempty(bwLimit)
                    % set parameter
                    obj.VisaIFobj.write([':CHANnel' channel ...
                        ':BWLimit ' bwLimit]);
                    % read and verify
                    response = obj.VisaIFobj.query([':CHANnel' channel ...
                        ':BWLimit?']);
                    if ~strcmpi(bwLimit, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'bwLimit parameter could not be set correctly.']);
                        status = -1;
                    end
                end

                % 'invert'           : 'off', 'on'
                if ~isempty(invert)
                    % set parameter
                    obj.VisaIFobj.write([':CHANnel' channel ...
                        ':INVert ' invert]);
                    % read and verify
                    response = obj.VisaIFobj.query([':CHANnel' channel ...
                        ':INVert?']);
                    if ~strcmpi(invert, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'invert parameter could not be set correctly.']);
                        status = -1;
                    end
                end

                % 'skew'           : (-200e-9 ... 200e-9 = +/- 200ns)
                if ~isempty(skew)
                    % format (round) numeric value
                    skewString = num2str(skew, '%1.1e');
                    skew       = str2double(skewString);
                    % set parameter
                    obj.VisaIFobj.write([':CHANnel' channel ...
                        ':TCAL ' skewString]);
                    % read and verify
                    response   = obj.VisaIFobj.query([':CHANnel' channel ...
                        ':TCAL?']);
                    skewActual = str2double(char(response));
                    if skew ~= skewActual
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'skew parameter could not be set correctly. ' ...
                            'Check limits.']);
                    end
                end

                % 'trace'          : 'off', 'on'
                if ~isempty(trace)
                    % set parameter
                    obj.VisaIFobj.write([':CHANnel' channel ...
                        ':DISPlay ' trace]);
                    % read and verify
                    response = obj.VisaIFobj.query([':CHANnel' channel ...
                        ':DISPlay?']);
                    if ~strcmpi(trace, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'trace parameter could not be set correctly.']);
                        status = -1;
                    end
                end

                % 'vDiv'           : positive double in V/div
                if ~isempty(vDiv)
                    % format (round) numeric value
                    vDivString = num2str(vDiv, '%1.2e');
                    vDiv       = str2double(vDivString);
                    % set parameter
                    obj.VisaIFobj.write([':CHANnel' channel ...
                        ':SCALe ' vDivString]);
                    % read and verify
                    response   = obj.VisaIFobj.query([':CHANnel' channel ...
                        ':SCALe?']);
                    vDivActual = str2double(char(response));
                    if vDiv ~= vDivActual
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'vDiv parameter could not be set correctly. ' ...
                            'Check limits.']);
                    end
                elseif ~isempty(vOffset)
                    % read vDiv: required for vOffset scaling
                    response   = obj.VisaIFobj.query([':CHANnel' channel ...
                        ':SCALe?']);
                    vDivActual = str2double(char(response));
                end

                % 'vOffset'        : positive double in V
                if ~isempty(vOffset)
                    % format (round) numeric value
                    vOffString = num2str(-vOffset, '%1.2e');
                    vOffset    = str2double(vOffString);
                    % set parameter
                    obj.VisaIFobj.write([':CHANnel' channel ...
                        ':OFFSet ' vOffString]);
                    % read and verify
                    response   = obj.VisaIFobj.query([':CHANnel' channel ...
                        ':OFFSet?']);
                    vOffActual = str2double(char(response));
                    if abs(vOffset - vOffActual) > vDivActual*0.5
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'vOffset parameter could not be set correctly. ' ...
                            'Check limits.']);
                    end
                end
            end

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
                                tDiv    = 0.5e-3;   % 500us
                            end
                            if obj.ShowMessages && coerced
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
                        end
                    case 'maxLength'
                        if ~isempty(paramValue)
                            maxLength = round(abs(str2double(paramValue)));
                            coerced   = false;
                            if isnan(maxLength) || isinf(maxLength)
                                disp(['Scope: Warning - ''configureAcquisition'' ' ...
                                    'maxLength parameter value is invalid ' ...
                                    '--> coerce and continue']);
                                maxLength = 70e3;
                                coerced   = true;
                            end
                            switch maxLength
                                case {7e3, 70e3, 700e3, 7e6}
                                    % do nothing (for dual-channel)
                                otherwise
                                    coerced   = true;
                                    if maxLength < 1
                                        maxLength = 0;    % AUTO
                                    elseif maxLength < 7e3
                                        maxLength = 7e3;
                                    elseif maxLength < 70e3
                                        maxLength = 70e3;
                                    elseif maxLength < 700e3
                                        maxLength = 700e3;
                                    else
                                        maxLength = 7e6;
                                    end
                            end
                            if obj.ShowMessages && coerced
                                disp(['  - maxLength    : ' ...
                                    num2str(maxLength, '%g') ' (coerced)']);
                            end
                        end
                    case 'mode'
                        mode = paramValue;
                        switch lower(mode)
                            case ''
                                mode = '';
                            case {'sample', 'normal', 'norm'}
                                mode = 'NORM';  % NORMal
                            case {'peakdetect', 'peak'}
                                mode = 'PEAK';  % PEAK
                            case {'average', 'aver'}
                                mode = 'AVER';  % AVERages
                            case {'highres', 'hres', 'highresolution'}
                                mode = 'HRES';  % HRESolution
                            otherwise
                                mode = '';
                                disp(['Scope: Warning - ''configureAcquisition'' ' ...
                                    'mode parameter value is unknown ' ...
                                    '--> ignore and continue']);
                        end
                    case 'numAverage'
                        if ~isempty(paramValue)
                            numAverage = round(abs(str2double(paramValue)));
                            coerced    = false;
                            if isnan(numAverage) || isinf(numAverage)
                                disp(['Scope: Warning - ''configureAcquisition'' ' ...
                                    'numAverage parameter value is invalid ' ...
                                    '--> coerce and continue']);
                                numAverage = 4;
                                coerced    = true;
                            end
                            switch numAverage
                                case {2, 4, 8, 16, 32, 64, 128, 256, ...
                                        512, 1024, 2048, 4096, 8192}
                                    % fine
                                otherwise
                                    numAverage = 2^min(13, max(1, ...
                                        round(log2(numAverage))));
                                    coerced    = true;
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
            %               [5e-9 ... 1e3]
            if ~isempty(tDiv)
                % format (round) numeric value
                tDivString = num2str(tDiv, '%1.2e');
                tDiv       = str2double(tDivString);
                % set parameter
                obj.VisaIFobj.write([':TIMebase:SCALe ' tDivString]);
                % read and verify
                response = obj.VisaIFobj.query('TIMebase:SCALe?');
                tDivActual = str2double(char(response));
                if (tDiv/tDivActual) < 0.95 || (tDiv/tDivActual) > 1.05
                    disp(['Scope: WARNING - ''configureAcquisition'' ' ...
                        'tDiv parameter could not be set correctly. ' ...
                        'Check limits. ']);
                end
            end

            % maxLength : 0 for AUTO
            %             7k, 70k, 700k, 7M for dual channel
            %             value*2           for single channel
            if ~isempty(maxLength)
                % check if dual or single channel
                response = obj.VisaIFobj.query(':CHANnel1:DISPlay?');
                if strcmpi(char(response), '0')
                    maxLength = maxLength *2;
                elseif strcmpi(char(response), '1')
                    % fine
                else
                    status = -5;
                    disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                        'unexpected response. --> exit and continue']);
                    return;
                end

                % set parameter
                if maxLength == 0
                    obj.VisaIFobj.write(':ACQuire:MDEPth AUTO');
                else
                    obj.VisaIFobj.write([':ACQuire:MDEPth ' ...
                        num2str(maxLength, '%d')]);
                end
                % read and verify is not really possible
                % ==> actual acquisition length is reported which can be
                % smaller
            end

            % mode     : 'sample', 'peakdetect', 'average'
            %            and additionally also 'highres'
            if ~isempty(mode)
                % set parameter
                obj.VisaIFobj.write([':ACQuire:TYPE ' mode]);
                % read and verify
                response = obj.VisaIFobj.query(':ACQuire:TYPE?');
                if ~strcmpi(mode, char(response))
                    disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                        'mode parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % numAverage  : 2 .. 8192
            if ~isempty(numAverage)
                % set parameter
                obj.VisaIFobj.write([':ACQuire:AVERages ' ...
                    num2str(numAverage, '%d')]);
                % read and verify
                response  = obj.VisaIFobj.query(':ACQuire:AVERages?');
                actualVal = str2double(char(response));
                if numAverage ~= actualVal
                    disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                        'numAverage parameter could not be set correctly.']);
                    status = -1;
                end
            end

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
            %   'coupling'    : 'AC', 'DC', 'LFReject', 'HFRreject', 'NoiseReject'
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
                                mode = 'SING'; % SINGle
                            case 'normal'
                                mode = 'NORM'; % NORMal
                            case 'auto'
                                mode = 'AUTO'; % AUTO
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
                                source = 'CHAN1';  % CHANel1
                            case 'ch2'
                                source = 'CHAN2';  % CHANel2
                            case 'ext'
                                source = 'EXT';
                            case 'ext5'
                                source = 'EXT';
                                if obj.ShowMessages
                                    disp('  - source       : ext (coerced)');
                                end
                            case 'ac-line'
                                source = 'ACL';    % ACLine
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
                                coupling = 'LFR'; % 75 kHz high pass
                            case {'hfreject', 'hfrej'}
                                coupling = 'HFR'; % 75 kHz low pass
                            case {'noisereject', 'noiserej'}
                                coupling = 'addLPNoiseFilter';
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
                obj.VisaIFobj.write([':TRIGger:SWEep ' mode]);
                % read and verify
                response = obj.VisaIFobj.query('TRIGger:SWEep?');
                if ~strcmpi(mode, char(response))
                    disp(['Scope: Error - ''configureTrigger'' ' ...
                        'mode parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % source   : 'CHAN1..2', 'EXT', 'ACL'
            if ~isempty(source)
                obj.VisaIFobj.write(':TRIGger:MODE EDGE');
                % set parameter
                obj.VisaIFobj.write([':TRIGger:EDGe:SOURce ' source]);
                % read and verify
                response = obj.VisaIFobj.query(':TRIGger:EDGe:SOURce?');
                if ~strcmpi(source, char(response))
                    disp(['Scope: Error - ''configureTrigger'' ' ...
                        'source parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % type      : rising or falling edge
            if ~isempty(type)
                obj.VisaIFobj.write(':TRIGger:MODE EDGE');
                % set parameter
                obj.VisaIFobj.write([':TRIGger:EDGe:SLOPe ' type]);
                % read and verify
                response = obj.VisaIFobj.query(':TRIGger:EDGe:SLOPe?');
                if ~strcmpi(type, char(response))
                    disp(['Scope: Error - ''configureTrigger'' ' ...
                        'type parameter could not be set correctly.']);
                    status = -1;
                end
            end

            % coupling
            if ~isempty(coupling)
                obj.VisaIFobj.write(':TRIGger:MODE EDGE');
                switch coupling
                    case {'DC', 'AC', 'LFR', 'HFR'}
                        % set parameter
                        obj.VisaIFobj.write([':TRIGger:COUPling ' ...
                            coupling]);
                        % read and verify
                        response = obj.VisaIFobj.query( ...
                            ':TRIGger:COUPling?');
                        if ~strcmpi(coupling, char(response))
                            disp(['Scope: Error - ''configureTrigger'' ' ...
                                'coupling parameter could not be set ' ...
                                'correctly.']);
                            status = -1;
                        end
                        % disable noise rejection
                        obj.VisaIFobj.write(':TRIGger:NREJect 0');
                    case 'addLPNoiseFilter'
                        % when LFReject then change to AC
                        response = obj.VisaIFobj.query( ...
                            ':TRIGger:COUPling?');
                        if strcmpi('LFR', char(response))
                            obj.VisaIFobj.write( ...
                                ':TRIGger:COUPling AC');
                        end
                        % enable additional noise rejection filter
                        obj.VisaIFobj.write(':TRIGger:NREJect 1');
                    otherwise
                        disp(['Scope: Error - ''configureTrigger'' ' ...
                            'invalid state ==> ignore and continue.']);
                        status = -1;
                end
            end

            % level    : double, in V; NaN for set level to 50%
            if isnan(level)
                % set trigger level to 50% of input signal
                obj.VisaIFobj.write(':TLHAlf');
                obj.VisaIFobj.opc;
            elseif ~isempty(level)
                obj.VisaIFobj.write(':TRIGger:MODE EDGE');
                % format (round) numeric value
                levelString = num2str(level, '%1.1e');
                level       = str2double(levelString);
                % set parameter
                obj.VisaIFobj.write([':TRIGger:EDGe:LEVel ' levelString]);
                % read and verify
                response    = obj.VisaIFobj.query(':TRIGger:EDGe:LEVel?');
                levelActual = str2double(char(response));
                if abs(level - levelActual) > 1 % !!!
                    % sensible threshold depends on vDiv of trigger source
                    disp(['Scope: Warning - ''configureTrigger'' ' ...
                        'level parameter could not be set correctly. ' ...
                        'Check limits.']);
                end
            end

            % delay    : double, in s
            if ~isempty(delay)
                % format (round) numeric value
                delayString = num2str(delay, '%1.2e');
                delay       = str2double(delayString);
                % set parameter
                obj.VisaIFobj.write([':TIMebase:OFFSet ' delayString]);
                % read and verify
                response    = obj.VisaIFobj.query(':TIMebase:OFFSet?');
                delayActual = str2double(char(response));
                if abs(delay - delayActual) > 1e-2 % !!!
                    % sensible threshold depends on tDiv
                    disp(['Scope: Warning - ''configureTrigger'' ' ...
                        'delay parameter could not be set correctly. ' ...
                        'Check limits.']);
                end
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = configureZoom(obj, varargin)
            % configureZoom   : configure zoom window

            status = 0;

            if obj.ShowMessages
                disp(['Scope WARNING - Method ''configureZoom'' is ' ...
                    'not supported for ']);
                disp(['      ' obj.VisaIFobj.Vendor '/' ...
                    obj.VisaIFobj.Product ...
                    ' -->  Zoom can only be configured manually']);
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
            %
            % ratio of ADC-fullscale range
            % > 1.25  ATTENTION: ADC will be overloaded: (-5 ..+5) vDiv
            %     scaling factor up to 1.25 is possible (ADC-full range)
            % 1.00 means full display-range (-4 ..+4) vDiv
            % sensible range 0.3 .. 0.9
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

            % vertical scaling: adjust vDiv, vOffset
            if strcmpi(mode, 'vertical') || strcmpi(mode, 'both')
                for cnt = 1:length(channels)
                    % check if trace is on or off
                    traceOn = obj.VisaIFobj.query( ...
                        [':CHANnel' channels{cnt} ':DISPlay?']);
                    traceOn = abs(str2double(char(traceOn)));
                    if isnan(traceOn)
                        traceOn = false;
                        status  = -3;
                    else
                        traceOn = logical(traceOn);
                    end
                    if traceOn
                        % init
                        loopcnt  = 0;
                        maxcnt   = 9;
                        while loopcnt < maxcnt
                            % time for settlement
                            pause(0.4);

                            % measure min and max voltage
                            result = obj.runMeasurement( ...
                                'channel', channels{cnt}, ...
                                'parameter', 'minimum');
                            vMin   = result.value;
                            result = obj.runMeasurement( ...
                                'channel', channels{cnt}, ...
                                'parameter', 'maximum');
                            vMax   = result.value;

                            % ADC is clipped?
                            adcMax = isnan(vMax);
                            adcMin = isnan(vMin);

                            % estimate voltage scaling (gain)
                            % 8 vertical divs at display
                            vDiv = (vMax - vMin) / 8;
                            if isnan(vDiv)
                                % request current vDiv setting
                                vDiv = obj.VisaIFobj.query( ...
                                    [':CHANnel' channels{cnt} ':SCALe?']);
                                vDiv = str2double(char(vDiv));
                                if isnan(vDiv)
                                    status = -6;
                                    break;
                                end
                            end

                            % estimate voltage offset
                            vOffset = (vMax + vMin)/2;
                            if isnan(vOffset)
                                % request current vOffset setting
                                vOffset = obj.VisaIFobj.query( ...
                                    [':CHANnel' channels{cnt} ':OFFSet?']);
                                vOffset = str2double(char(vOffset));
                                if isnan(vOffset)
                                    status = -7;
                                    break;
                                end
                            end

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
                                status = -8;
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
            end

            % horizontal scaling: adjust tDiv
            if strcmpi(mode, 'horizontal') || strcmpi(mode, 'both')
                % which channel is used for trigger
                %obj.VisaIFobj.write(':TRIGger:MODE EDGe');
                trigSrc = obj.VisaIFobj.query(':TRIGger:EDGe:SOURce?');
                trigSrc = upper(char(trigSrc));
                switch trigSrc
                    case {'CHAN1', 'CHAN2'}
                        % additional settling time
                        pause(0.2);
                        % measure frequency
                        result = obj.runMeasurement( ...
                            'channel', trigSrc(end), ...
                            'parameter', 'frequency');
                        freq   = result.value;

                        if ~isnan(freq)
                            % adjust tDiv parameter
                            % calculate sensible tDiv parameter (14*tDiv@screen)
                            tDiv = numOfSignalPeriods / (14*freq);

                            % now send new tDiv parameter to scope
                            %obj.VisaIFobj.configureAcquisition('tDiv', tDiv);
                            statConf = obj.configureAcquisition( ...
                                'tDiv', num2str(tDiv, '%1.1e'));
                            if statConf
                                status = -10;
                            end

                            % wait for completion
                            obj.VisaIFobj.opc;
                        else
                            disp(['Scope: Warning - ''autoscale'': ' ...
                                'invalid frequency measurement results. ' ...
                                'Skip horizontal scaling.']);
                        end

                    otherwise
                        disp(['Scope: Warning - ''autoscale'': ' ...
                            'invalid trigger channel. ' ...
                            'Skip horizontal scaling.']);
                end
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = makeScreenShot(obj, varargin)
            % make a screenshot of scope display (BMP-file)
            %   'fileName' : file name with optional extension
            %                optional, default is './Rigol_Scope_DS2072A.bmp'
            %   'darkMode' : on/off, dark or white background color
            %                optional, default is 'off', 0, false,
            %                unsupported parameter

            % init output
            status = NaN;

            % configuration and default values
            listOfSupportedFormats = {'.bmp'};
            filename = './Rigol_Scope_DS2072A.bmp';
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

            % request actual binary screen shot data
            bitMapData = obj.VisaIFobj.query(':DISPlay:DATA?');

            % check data header
            headerChar = char(bitMapData(1));
            if ~strcmpi(headerChar, '#') || length(bitMapData) < 20
                disp(['Scope: WARNING - ''makeScreenShot'' missing ' ...
                    'data header. Check screenshot file.']);
                status = -1;
            else
                HeaderLen  = str2double(char(bitMapData(2)));
                if isnan(HeaderLen)
                    bitMapSize = 0;
                else
                    bitMapSize = str2double(char(bitMapData(3:HeaderLen+2)));
                end

                if bitMapSize > 0
                    bitMapData = bitMapData(HeaderLen+3:end);
                    if length(bitMapData) ~= bitMapSize
                        disp(['Scope: WARNING - ''makeScreenShot'' ' ...
                            'incorrect size of data. Check screenshot file.']);
                        status = -1;
                    end
                else
                    disp(['Scope: WARNING - ''makeScreenShot'' incorrect ' ...
                        'data header. Check screenshot file.']);
                    status = -1;
                end
            end

            % save data to file
            fid = fopen(filename, 'wb+');  % open as binary
            fwrite(fid, bitMapData, 'uint8');
            fclose(fid);

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
                                parameter = 'FREQuency';
                                unit      = 'Hz';
                            case {'period', 'peri', 'per'}
                                parameter = 'PERiod';
                                unit      = 's';
                            case 'mean'
                                parameter = 'VAVG';
                            case {'cycrms', 'crms'}
                                parameter = 'PVRMs';
                            case 'rms'
                                parameter = 'VRMS';
                            case {'pk-pk', 'pkpk', 'pk2pk', 'peak'}
                                parameter = 'VPP';
                            case {'maximum', 'max'}
                                parameter = 'VMAX';
                            case {'minimum', 'min'}
                                parameter = 'VMIN';
                            case {'high', 'top'}
                                parameter = 'VTOP';
                            case {'low', 'base'}
                                parameter = 'VBASe';
                            case {'amplitude', 'amp'}
                                parameter = 'VAMP';
                            case {'overshoot', 'over'}
                                parameter = 'OVERshoot';
                                unit      = '%';
                            case {'preshoot', 'pre'}
                                parameter = 'PREShoot';
                                unit      = '%';
                            case {'risetime', 'rise'}
                                parameter = 'RTIMe';
                                unit      = 's';
                            case {'falltime', 'fall'}
                                parameter = 'FTIMe';
                                unit      = 's';
                            case {'poswidth', 'pwidth'}
                                parameter = 'PWIDth';
                                unit      = 's';
                            case {'negwidth', 'nwidth'}
                                parameter = 'NWIDth';
                                unit      = 's';
                            case {'dutycycle', 'dutycyc', 'dcycle', 'dcyc'}
                                parameter = 'PDUTy';
                                unit      = '%';
                            case 'phase'
                                parameter = 'RPHase';
                                unit      = 'deg';
                            case 'delay'
                                parameter = 'RDELay';
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
                    disp('  ''mean''');
                    disp('  ''cycrms''');
                    disp('  ''rms''');
                    disp('  ''pk-pk''');
                    disp('  ''maximum''');
                    disp('  ''minimum''');
                    disp('  ''high''');
                    disp('  ''low''');
                    disp('  ''amplitude''');
                    disp('  ''overshoot''');
                    disp('  ''preshoot''');
                    disp('  ''risetime''');
                    disp('  ''falltime''');
                    disp('  ''poswidth''');
                    disp('  ''negwidth''');
                    disp('  ''dutycycle''');
                    disp('  ''phase''');
                    disp('  ''delay''');
                    meas.status = -1;
                    return
                case {'rphase', 'rdelay'}
                    if length(channels) ~= 2
                        disp(['Scope: ERROR ''runMeasurement'' ' ...
                            'two source channels have to be specified ' ...
                            'for phase or delay measurements ' ...
                            '--> skip and exit']);
                        meas.status = -1;
                        return
                    else
                        source    = ['CHAN' channels{1} ',CHAN' channels{2}];
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
                        source    = ['CHAN' channels{1}];
                    end
            end

            % copy to output
            meas.parameter = lower(parameter);
            meas.channel   = strjoin(channels, ', ');

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------

            % additional settling time
            pause(0.2);

            % request measurement value
            value = obj.VisaIFobj.query([':MEASure:' parameter '? ' source]);
            value = str2double(char(value));
            if isnan(value)
                meas.status = -5;     % error   (negative status)
            elseif abs(value) > 1e36
                meas.status = 1;      % warning (positive status)
                value = NaN;          % invalid measurement
            end

            % copy to output
            if strcmpi(unit, '%')
                meas.value = 100* value;
            else
                meas.value = value;
            end
            meas.unit  = unit;

            % set final status
            if isnan(meas.status)
                % no error so far ==> set to 0 (fine)
                meas.status = 0;
            end
        end

        function waveData = captureWaveForm(obj, varargin)
            % captureWaveForm: download waveform data
            %   'channel' : one or more channels
            % outputs:
            %   waveData.status     : 0 for okay
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
                                case '1'
                                    channels{cnt} = 'CHANnel1';
                                case '2'
                                    channels{cnt} = 'CHANnel2';
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
            if isempty(channels)
                channels = {'CHANnel1', 'CHANnel2'};
                if obj.ShowMessages
                    disp('  - channel      : 1, 2 (coerced)');
                end
            end

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------

            % loop over channels
            for cnt = 1 : length(channels)
                channel = channels{cnt};
                % select channel
                obj.VisaIFobj.write([':WAVeform:SOURce ' channel]);

                % ---------------------------------------------------------
                % read data header
                header = obj.VisaIFobj.query(':WAVeform:PREamble?');
                header = split(char(header), ',');
                if length(header) == 10
                    % response consists of 10 parameters separated by commas
                    % ( 1) <format>,     (should be 0 for BYTE)
                    % ( 2) <type>,       (should be 1 for MAXimum)
                    % ( 3) <points>,     (should be 1400 when acq is running
                    %                     and up to 14e6 when acq is stopped)
                    % ( 4) <count>,      (averages, not really of interest)
                    % ( 5) <xincrement>,
                    % ( 6) <xorigin>,
                    % ( 7) <xreference>,
                    % ( 8) <yincrement>,
                    % ( 9) <yorigin>,
                    % (10) <yreference>
                    xlength    = str2double(header{3});
                    %
                    xinc       = str2double(header{5});
                    xorigin    = str2double(header{6});
                    xref       = str2double(header{7});
                    %
                    yinc       = str2double(header{8});
                    yorigin    = str2double(header{9});
                    yref       = str2double(header{10});
                else
                    % logical error or data error
                    waveData.status = -10;
                    return; % exit
                end

                % ---------------------------------------------------------
                % always download waveform data ==> will be all zero when
                % channel is not active (we don't care)
                %
                % resolution of data is always 8-bit (Byte)

                % ---------------------------------------------------------
                % check all meta information and initialize output values
                if ~isnan(xlength) && ...
                        ~isnan(xinc) && ~isnan(xorigin) && ~isnan(xref) && ...
                        ~isnan(yinc) && ~isnan(yorigin) && ~isnan(yref)

                    % set sample time (identical for all channels)
                    waveData.time = xref + xorigin + xinc*(0 : xlength-1);
                    % sample rate
                    waveData.samplerate = 1/xinc;
                    if isempty(waveData.volt)
                        % initialize result matrix
                        waveData.volt   = zeros(length(channels), xlength);
                    elseif size(waveData.volt, 2) ~= xlength
                        % logical error or data error
                        waveData.status = -14;
                        return; % exit
                    end
                else
                    % logical error or data error
                    waveData.status = -15;
                    return; % exit
                end

                % ---------------------------------------------------------
                % actual download of waveform data
                %
                % wavedata must downloaded in chunks with max. 2.5e5
                % samples (when format is BYTE)
                xstart = 1;
                xstop  = min(xstart + 250e3 - 1, xlength);


                while xstop <= xlength && xstart < xstop
                    % set addresses for data block to be read
                    obj.VisaIFobj.write([':WAVeform:STARt ' ...
                        num2str(xstart, '%d')]);
                    obj.VisaIFobj.write([':WAVeform:STOP ' ...
                        num2str(xstop, '%d')]);

                    % read data block
                    data = obj.VisaIFobj.query(':WAVeform:DATA?');
                    % check and extract header: e.g. #41000binarydata with
                    % next 4 chars indicating number of bytes for actual data
                    if length(data) < 4
                        % logical error or data error
                        waveData.status = -16;
                        return; % exit
                    end
                    headchar = char(data(1));
                    headlen  = round(str2double(char(data(2))));
                    if strcmpi(headchar, '#') && headlen >= 1
                        % fine and go on  (test negative for headlen = NaN)
                    else
                        % logical error or data error
                        waveData.status = -17;
                        return; % exit
                    end
                    datalen = str2double(char(data(2+1 : ...
                        min(2+headlen,length(data)))));
                    if length(data) ~= 2 + headlen + datalen
                        % logical error or data error
                        waveData.status = -18;
                        return; % exit
                    end
                    % extract binary data (uint8)
                    data = data(2 + headlen + (1:datalen));
                    % convert data
                    data = double(data);

                    % check and reformat
                    if length(data) ~= xstop - xstart + 1
                        % logical error or data error
                        waveData.status = -19;
                        return; % exit
                    end
                    % convert byte values to sample values in V
                    waveData.volt(cnt, xstart : xstop) = ...
                        (data - yref - yorigin) * yinc;

                    % updates addresses for next loop run
                    xstart = xstop + 1;
                    xstop  = min(xstart + 250e3 - 1, xlength);
                end

            end

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

            % there is only one command for trigger and acquisition state
            [acqState, status] = obj.VisaIFobj.query(':TRIGger:STATus?');
            %
            if status ~= 0
                % failure
                acqState = 'visa error. couldn''t read acquisition state';
            else
                % remap trigger state
                acqState = lower(char(acqState));
                switch acqState
                    case 'stop'
                        acqState = 'stopped';
                    case {'wait', 'run', 'td', 'auto'}
                        acqState = 'running';
                    otherwise
                        acqState = '';
                end
            end
        end

        function trigState = get.TriggerState(obj)
            % get trigger state
            % 'waitfortrigger' or 'triggered', '' when unknown response

            % there is only one command for trigger and acquisition state
            [trigState, status] = obj.VisaIFobj.query(':TRIGger:STATus?');
            %
            if status ~= 0
                % failure
                trigState = 'visa error. couldn''t read trigger state';
            else
                % remap trigger state
                trigState = lower(char(trigState));
                switch trigState
                    case {'stop', 'td', 'auto'}
                        trigState = 'triggered';
                    case {'wait', 'run'}
                        trigState = 'waitfortrigger';
                    otherwise
                        trigState = '';
                end
            end
        end

        function errMsg = get.ErrorMessages(obj)
            % read error list from the scope’s error buffer

            % config
            maxErrCnt = 16;  % size of error stack
            errCell   = cell(1, maxErrCnt);
            cnt       = 0;
            done      = false;

            % read error from buffer until done
            while ~done && cnt < maxErrCnt
                cnt = cnt + 1;
                % read error and convert to characters
                errMsg = obj.VisaIFobj.query(':SYSTem:ERRor?');
                errMsg = char(errMsg);
                % no errors anymore?
                if startsWith(errMsg, '0,')
                    done = true;
                else
                    errCell{cnt} = errMsg;
                end
            end

            % remove empty cell elements
            errCell = errCell(~cellfun(@isempty, errCell));

            % optionally display results
            if obj.ShowMessages
                if ~isempty(errCell)
                    disp('Scope error list:');
                    for cnt = 1:length(errCell)
                        disp(['  (' num2str(cnt,'%02i') ') ' ...
                            errCell{cnt} ]);
                    end
                else
                    disp('Scope error list is empty');
                end
            end

            % copy result to output
            errMsg = strjoin(errCell, '; ');

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