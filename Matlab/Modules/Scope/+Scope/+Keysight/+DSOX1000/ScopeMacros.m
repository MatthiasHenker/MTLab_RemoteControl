classdef ScopeMacros < handle
    % include device specific documentation when needed
    %
    % Keysight DSOX1000 series macros
    
    % authors: Matthias Henker (prof.), Constantin Wimmer (student)
    
    properties(Constant = true)
        MacrosVersion = '1.2.0';      % release version
        MacrosDate    = '2021-01-26'; % release date
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
            % lock buttons at scope when remote control is active
            if obj.VisaIFobj.write(':SYSTem:LOCK ON')
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
        
        function status = runBeforeClose(obj)
            
            % init output
            status = NaN;
            
            % add some device specific commands:
            % release buttons at scope again
            if obj.VisaIFobj.write(':SYSTem:LOCK OFF')
                status = -1;
            end
            % ...
            
            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end
        
        function status = reset(obj)
            
            % init output
            status = NaN;
            
            % use standard reset command
            % same as pressing [Save/Recall] > Default/Erase >
            % Factory Default on the front panel.
            if obj.VisaIFobj.write('*RST')
                status = -1;
            end
            
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
            % clear status at scope
            status = obj.VisaIFobj.write('*CLS');
        end
        
        function status = lock(obj)
            % lock all buttons at scope
            status = obj.VisaIFobj.write(':SYSTem:LOCK ON');
        end
        
        function status = unlock(obj)
            % unlock all buttons
            status = obj.VisaIFobj.write(':SYSTem:LOCK OFF');
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
            % causes the oscilloscope to adjust its vertical, horizontal,
            % and trigger controls to display a stable waveform
            
            % init output
            status = NaN;
            
            % execute autoset command
            if obj.VisaIFobj.write(':AUToscale:AMODE CURRent')
                status = -1;
            end
            
            if obj.VisaIFobj.write(':AUToscale')
                status = -1;
            end
            
            % wait until done
            obj.VisaIFobj.opc;
            
            % set trigger source taking active channels into consideration
            if str2double(char(obj.VisaIFobj.query(...
                    ':STATus? CHANnel1'))) % channel 1 is active
                TrigSource = '1';
            elseif str2double(char(obj.VisaIFobj.query(...
                    ':STATus? CHANnel2'))) % channel 2 is active
                TrigSource = '2';
            else
                TrigSource = '1'; % none active, set channel 1 anyway
            end
            
            if obj.VisaIFobj.write([':TRIGger:EDGE:SOURce CHANnel',...
                    TrigSource])
                status = -1;
            end
            
            obj.VisaIFobj.opc;
            
            % automatically adjust trigger, use edge triggering as common
            % case
            if obj.VisaIFobj.write(...
                    ':TRIGger:SWEep NORMal;MODE EDGE;LEVel:ASETup')
                status = -1;
            end
            
            obj.VisaIFobj.opc;
            
            if isnan(status)
                status = 0;
            end
            
            % has a valid signal been detected?
            % ==> no option for validation
            
        end
        
        % -----------------------------------------------------------------
        
        function status = configureInput(obj, varargin)
            %possible arguments
            % configureInput  : configure input of specified channels
            %   'channel'     : 1 .. 2, [1 2], 'ch1, ch2', '{'1', 'ch2'} ...
            %   'trace'       : 'on', "on", 1, true or 'off', "off", 0, false
            %   'impedance'   : always 1e6
            %   'vDiv'        : real > 0
            %   'vOffset'     : real
            %   'coupling'    : 'DC', 'AC', 'GND'
            %   'inputDiv'    : ... , 1, 10, 20, 50, 100, 200, 500, ...
            %   'bwLimit'     : on/off
            %   'invert'      : on/off
            %   'skew'        : real
            %   'unit'        : 'V', "V" or 'A', "A"
            
            % init output
            status = NaN;
            
            % initialize all supported parameters
            channels       = {};
            trace          = '';
            vDiv           = '';
            vOffset        = '';
            coupling       = '';
            inputDiv       = '';
            bwLimit        = '';
            invert         = '';
            unit           = '';
            skew           = '';
            
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
                                    channels{cnt} = ':CHANnel1';
                                case '2'
                                    channels{cnt} = ':CHANnel2';
                                otherwise
                                    channels{cnt} = '';
                                    disp(['Scope: Warning - ''configureInput'' ' ...
                                        'invalid channel --> ignore ' ...
                                        'and continue']);
                            end
                        end
                        % remove invalid (empty) entries
                        channels = channels(~cellfun(@isempty, channels));
                    case 'trace' %channel displayed
                        if ~isempty(paramValue)
                            switch lower(paramValue)
                                case {'off', '0'}
                                    trace = '0';
                                case {'on',  '1'}
                                    trace = '1';
                                otherwise
                                    trace = '';
                                    disp(['Scope: Warning - ''configureInput'' ' ...
                                        'trace parameter is unknown --> ignore ' ...
                                        'and continue']);
                            end
                        end
                    case 'impedance'
                        if obj.ShowMessages && ~isempty(paramValue)
                            disp(['Scope: Warning - ''impedance'' ' ...
                                'parameter cannot be set --> ' ...
                                ' impedance = 1e6']);
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
                                    coupling = 'ac';
                                case 'dc'
                                    coupling = 'dc';
                                case 'gnd'
                                    coupling = '';
                                    disp(['Scope: Warning - ''configureInput'' ' ...
                                        'coupling parameter "GND" not supported by' ...
                                        ' this scope --> ignore and continue']);
                                otherwise
                                    coupling = '';
                                    disp(['Scope: Warning - ''configureInput'' ' ...
                                        'coupling parameter is unknown --> ignore ' ...
                                        'and continue']);
                            end
                        end
                    case 'inputDiv'
                        if ~isempty(paramValue)
                            if str2double(paramValue) <= 10000 && ...
                                    str2double(paramValue) >= 0.1
                                inputDiv = paramValue;
                            else
                                inputDiv = '';
                                disp(['Scope: Warning - ''configureInput'' ' ...
                                    'inputDiv parameter is unknown --> ignore ' ...
                                    'and continue']);
                            end
                        end
                    case 'bwLimit'
                        if ~isempty(paramValue)
                            switch lower(paramValue)
                                case {'off', '0'}
                                    bwLimit = '0';
                                case {'on',  '1'}
                                    bwLimit = '1';
                                otherwise
                                    bwLimit = '';
                                    disp(['Scope: Warning - ''configureInput'' ' ...
                                        'bwLimit parameter is unknown --> ignore ' ...
                                        'and continue']);
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
                                        'unit parameter is unknown --> ignore ' ...
                                        'and continue']);
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
            for cnt = 1:length(channels)
                channel = channels{cnt};
                
                % 'coupling'         : 'DC', 'AC'
                if ~isempty(coupling)
                    % set parameter
                    obj.VisaIFobj.write([channel ':COUPling ' coupling]);
                    % read and verify
                    response = obj.VisaIFobj.query([channel ':COUPling?']);
                    if ~strcmpi(coupling, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'coupling parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'inputDiv' '0.1 .. 10000
                if ~isempty(inputDiv)
                    % set parameter
                    obj.VisaIFobj.write([channel ':Probe ' inputDiv]);
                    % read and verify
                    response = obj.VisaIFobj.query([channel ':Probe?']);
                    if str2double(inputDiv) ~= str2double(char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'inputDiv parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'bwLimit'          : 'off', 'on'
                if ~isempty(bwLimit)
                    % set parameter
                    obj.VisaIFobj.write([channel ':BWLimit ' bwLimit]);
                    % read and verify
                    response = obj.VisaIFobj.query([channel ':BWLimit?']);
                    if ~strcmpi(bwLimit, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'bwLimit parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'unit'             : 'VOLT' or 'AMP'
                if ~isempty(unit)
                    % set parameter
                    obj.VisaIFobj.write([channel ':UNITs ' unit]);
                    % read and verify
                    response = obj.VisaIFobj.query([channel ':UNITs?']);
                    if ~strcmpi(unit, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'unit parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'invert'           : 'off', 'on'
                if ~isempty(invert)
                    % set parameter
                    obj.VisaIFobj.write([channel ':INVert ' invert]);
                    % read and verify
                    response = obj.VisaIFobj.query([channel ':INVert?']);
                    if ~strcmpi(invert, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'invert parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'trace'          : 'off', 'on'
                if ~isempty(trace)
                    % set parameter
                    obj.VisaIFobj.write([channel ':DISPlay ' trace]);
                    % read and verify
                    response = obj.VisaIFobj.query([channel ':DISPlay?']);
                    if ~strcmpi(trace, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'trace parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'vDiv'           : positive double in V/div
                if ~isempty(vDiv)
                    % format (round) numeric value
                    vDivString = num2str(vDiv, '%3.2e');
                    vDiv       = str2double(vDivString);
                    % set parameter
                    obj.VisaIFobj.write([channel ':SCALe ' vDivString]);
                    % read and verify
                    response   = obj.VisaIFobj.query([channel ':SCALe?']);
                    vDivActual = str2double(char(response));
                    if abs(1 - vDivActual/vDiv) > 5e-2
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'vDiv parameter could not be set correctly. ' ...
                            'Check limits.']);
                    end
                    % update
                    vDiv = vDivActual;
                end
                
                % 'vOffset'        : positive double in V
                if ~isempty(vOffset)
                    
                    % format (round) numeric value
                    vOffString = num2str(vOffset, '%3.2e');
                    vOffset = str2double(vOffString);
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':OFFSet ' vOffString]);
                    % read and verify
                    response   = obj.VisaIFobj.query([channel ':OFFSet?']);
                    vOffActual = str2double(char(response));
                    if abs(1 - vOffActual/vOffset) > 5e-2
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'vOffset parameter could not be set correctly. ' ...
                            'Check limits.']);
                        status = -1;
                    end
                end
                
                % 'skew'        : positive double (-100E-9 .. 100E-9)
                if ~isempty(skew)
                    % format (round) numeric value
                    skewString = num2str(skew, '%3.2e');
                    
                    skew = str2double(skewString);
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':PROBe:SKEW ' skewString]);
                    % read and verify
                    response   = obj.VisaIFobj.query([channel ':PROBe:SKEW?']);
                    skewActual = str2double(char(response));
                    if skew ~= skewActual
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'skew parameter could not be set correctly. ' ...
                            'Check limits.']);
                    end
                end
            end
            
            if isnan(status)
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
            mode        = '';
            numAverage  = [];
            maxLength   = [];
            
            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
                switch paramName
                    case 'tDiv'
                        if ~isempty(paramValue)
                            tDiv = abs(str2double(paramValue));
                            if  isnan(tDiv) || isinf(tDiv)
                                disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                                    'tDiv parameter is invalid --> ' ...
                                    'abort function']);
                                status = -1;
                                return
                            end
                        end
                    case 'sampleRate'
                        if ~isempty(paramValue) && obj.ShowMessages
                            disp(['Scope: WARNING - ''sampleRate'' ' ...
                                'parameter is not supported by this scope '...
                                '--> ignore and continue']);
                        end
                    case 'maxLength'
                        if ~isempty(paramValue)
                            maxLength = abs(str2double(paramValue));
                            if isnan(maxLength) || isinf(maxLength)
                                disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                                    'maxLength parameter is invalid --> ' ...
                                    'abort function']);
                                status = -1;
                                return
                            end
                        end
                    case 'mode'
                        mode = paramValue;
                        switch lower(mode)
                            case ''
                                mode = '';
                            case 'sample'
                                mode = 'NORM';
                            case 'peakdetect'
                                mode = 'PEAK';
                            case 'average'
                                mode = 'AVER';
                            otherwise
                                mode = '';
                                disp(['Scope: WARNING - ''configureAcquisition'' ' ...
                                    'mode parameter is unknown --> ignore ' ...
                                    'and continue']);
                        end
                    case 'numAverage'
                        if ~isempty(paramValue)
                            if str2double(paramValue) <=  65536 && ...
                                    str2double(paramValue) >= 2
                                numAverage = paramValue;
                            else
                                numAverage = '';
                                disp(['Scope: WARNING - ''configureAcquisition'' ' ...
                                    'numAverage parameter is out of ' ...
                                    'Range --> ignore and continue']);
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
            
            % tdiv 5ns/div .. 50s/div
            if ~isempty(tDiv)
                % format (round) numeric value
                tDivString = num2str(tDiv, '%3.2e');
                tDiv       = str2double(tDivString);
                % set parameter
                obj.VisaIFobj.write([':TIMebase:SCALe ' tDivString]);
                % read and verify
                response = obj.VisaIFobj.query(':TIMebase:SCALe?');
                tDivActual = str2double(char(response));
                if (tDiv/tDivActual) < 0.2 || (tDiv/tDivActual) > 1.2
                    disp(['Scope: WARNING - ''configureAcquisition'' ' ...
                        'tDiv parameter could not be set correctly. ' ...
                        'Check limits. ']);
                end
            end
            
            % mode : average, peakdetect, sample
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
            
            % numAverage  : 2 .. 65536
            if ~isempty(numAverage)
                % set parameter
                obj.VisaIFobj.write(':ACQuire:TYPE AVER');
                response = char(obj.VisaIFobj.query(':ACQuire:TYPE?'));
                if ~strcmpi(response, 'AVER')
                    disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                        '''numAverage'' parameter could not be set correctly.']);
                    disp('Average mode has not been activated.');
                    status = -1;
                else
                    obj.VisaIFobj.write([':ACQuire:COUNt ' numAverage]);
                    % read and verify
                    response = obj.VisaIFobj.query(':ACQuire:COUNt?');
                    if ~strcmpi(numAverage, char(response))
                        disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                            '''numAverage'' parameter could not be set correctly.']);
                        status = -1;
                    end
                end
            end
            
            % maxLength : restricted to max 1000
            % (more is possible but interferes with other options)
            if ~isempty(maxLength)
                if maxLength <= 1000
                    obj.VisaIFobj.write(':WAVeform:POINts:MODE NORMal');
                    response = char(obj.VisaIFobj.query(...
                        ':WAVeform:POINts:MODE?'));
                    if ~strcmpi(response,'NORM')
                        disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                            '''maxLength'' parameter could not be set correctly.']);
                        status = -1;
                    end
                else % >1000
                    % the scope allows more than 1000 without averaging
                    % set aquisition type to normal again and inform the
                    % user
                    obj.VisaIFobj.write(':ACQuire:TYPE NORM');
                    response = char(obj.VisaIFobj.query(':ACQuire:TYPE?'));
                    if ~strcmpi(response, 'NORM')
                        disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                            '''maxLength'' parameter could not be set correctly.']);
                        status = -1;
                    else
                        % inform the user that averaging has been
                        % deactivated
                        disp(['Scope: WARNING - ''configureAcquisition'' ' ...
                            '''maxLength'' > 1000 --> deactivate averaging']);
                        
                        obj.VisaIFobj.write(':WAVeform:POINts:MODE MAX');
                        response = char(obj.VisaIFobj.query(...
                            ':WAVeform:POINts:MODE?'));
                        if ~strcmpi(response, 'MAX')
                            disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                                '''maxLength'' parameter could not be set correctly.']);
                            status = -1;
                        end
                    end
                end
                
                maxLengthStr = num2str(maxLength);
                obj.VisaIFobj.write([':WAVeform:POINts ', maxLengthStr]);
                obj.VisaIFobj.opc();
                % no validation since number of points transferred depends
                % on scaling and other settings
            end
            
            if isnan(status)
                status=0;
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
                            case 'normal'
                                mode = 'NORMal';
                            case 'auto'
                                mode = 'AUTO';
                            case 'single'
                                mode = ':SINGle';
                            otherwise
                                mode = '';
                                disp(['Scope: Warning - ''configureTrigger'' ' ...
                                    'mode parameter is unknown --> ignore ' ...
                                    'and continue']);
                        end
                    case 'type'
                        type = paramValue;
                        switch lower(type)
                            case ''
                                type = '';
                            case 'risingedge'
                                type = 'MODE EDGE;SLOPe POSitive';
                            case 'fallingedge'
                                type = 'MODE EDGE;SLOPe NEGative';
                            otherwise
                                type = '';
                                disp(['Scope: Warning - ''configureTrigger'' ' ...
                                    'type parameter is unknown --> ignore ' ...
                                    'and continue']);
                        end
                    case 'source'
                        source = paramValue;
                        switch lower(source)
                            case ''
                                source = '';
                            case 'ch1'
                                source = 'CHAN1';
                            case 'ch2'
                                source = 'CHAN2';
                            case 'ext'
                                source = 'EXT';
                            case 'ac-line'
                                source = 'LINE';
                            otherwise
                                source = '';
                                disp(['Scope: Warning - ''configureTrigger'' ' ...
                                    'source parameter is unknown --> ignore ' ...
                                    'and continue']);
                        end
                    case 'coupling'
                        coupling = paramValue;
                        switch lower(coupling)
                            case ''
                                coupling = '';
                            case 'ac'
                                coupling = 'AC';
                            case 'dc'
                                coupling = 'DC';
                            case {'noisereject', 'noiserej'}
                                coupling = 'NREJect';
                            case {'hfreject', 'hfrej'}
                                coupling = 'HFReject';
                            case {'lfreject', 'lfrej'}
                                coupling = 'LFR';
                            otherwise
                                coupling = '';
                                disp(['Scope: Warning - ''configureTrigger'' ' ...
                                    'coupling parameter is unknown --> ignore ' ...
                                    'and continue']);
                        end
                    case 'level'
                        if ~isempty(paramValue)
                            level = str2double(paramValue);
                        end
                        if isinf(level)
                            level = NaN;
                        end
                    case 'delay'
                        if ~isempty(paramValue)
                            delay = str2double(paramValue);
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
            if ~isempty(mode)
                
                % single is missing
                % set trigger:sweep first run or single second
                
                
                if strcmpi(mode, 'normal') || strcmpi(mode, 'auto')
                    % leave single mode to change the trigger mode
                    if strcmpi(mode, 'auto')
                        obj.VisaIFobj.write(':RUN');
                        obj.VisaIFobj.opc();
                    end
                    
                    % set parameter
                    obj.VisaIFobj.write([':TRIGger:SWEep ' mode]);
                    
                    % read and verify
                    response = char(obj.VisaIFobj.query(':TRIGger:SWEep?'));
                    if ~strcmpi(mode, response)
                        disp(['Scope: Error - ''configureTrigger'' ' ...
                            'mode parameter could not be set correctly.']);
                        status = -1;
                    end
                else
                    % set parameter
                    obj.VisaIFobj.write(mode);
                    % no verification with query possible
                end
            end
            
            % type     : 'rise', 'fall'
            if ~isempty(type)
                % set parameters (edge and slope)
                obj.VisaIFobj.write([':TRIGger:',type]);
                
                % read and verify
                responseEdge = obj.VisaIFobj.query(':TRIGger:MODE?');
                responseEdge = char(responseEdge);
                
                % read and verify
                response = obj.VisaIFobj.query(':TRIGger:SLOPE?');
                response = char(response);
                if ~contains(type, response) || ~strcmpi('edge', ...
                        responseEdge)
                    disp(['Scope: Error - ''configureTrigger'' ' ...
                        'type parameter could not be set correctly.']);
                    status = -1;
                end
            end
            
            if ~isempty(source)
                % set parameter
                obj.VisaIFobj.write([':TRIGger:SOURce ' source]);
                % read and verify
                response = obj.VisaIFobj.query(':TRIGger:SOURce?');
                if ~strcmpi(source, char(response))
                    disp(['Scope: Error - ''configureTrigger'' ' ...
                        'source parameter could not be set correctly.']);
                    status = -1;
                end
            end
            
            if ~isempty(coupling)
                switch coupling
                    case {'LFR', 'DC', 'AC'}
                        obj.VisaIFobj.write([':TRIGger:COUPling ' coupling]);
                        % read and verify
                        response = char(obj.VisaIFobj.query(...
                            ':TRIGger:COUPling?'));
                        if ~strcmpi(coupling, char(response))
                            status = -1;
                        end
                    case 'HFReject'
                        %HFR cannot be choosen in LFR mode
                        %determine current coupling mode
                        CurrentCoupling = char(obj.VisaIFobj.query(...
                            ':TRIGger:COUPling?'));
                        if strcmpi(CurrentCoupling, 'LFReject')
                            
                            obj.VisaIFobj.write(':TRIGger:COUPling DC');
                            response = char(obj.VisaIFobj.query(...
                                ':TRIGger:COUPling?'));
                            
                            if ~strcmpi('DC', char(response))
                                status = -1;
                            end
                        end
                        
                        obj.VisaIFobj.write([':TRIGger:REJect ' coupling]);
                        response = char(obj.VisaIFobj.query(...
                            ':TRIGger:REJect?'));
                        
                        if ~contains(coupling, response)
                            %just HFR is returned
                            status = -1;
                        end
                        
                    case 'NREJect'
                        obj.VisaIFobj.write(':TRIGger:NREJect ON');
                        response = str2double(char(obj.VisaIFobj.query(...
                            ':TRIGger:NREJect?')));
                        
                        if ~response
                            status = -1;
                        end
                end
                
                if status == -1
                    disp(['Scope: Error - ''configureTrigger'' ' ...
                        'coupling parameter could not be set correctly.']);
                end
            end
            
            if ~isempty(delay)
                % format (round) numeric value
                delayString = num2str(delay, '%3.3e');
                delay       = str2double(delayString);
                
                % set parameter
                obj.VisaIFobj.write([':TIMebase:POSition ' delayString]);
                
                % read and verify
                response    = obj.VisaIFobj.query(':TIMebase:POSition?');
                delayActual = str2double(char(response));
                if abs(delay - delayActual) > 1e-3 % sensible threshold
                    % depends on tDiv
                    disp(['Scope: Warning - ''configureTrigger'' ' ...
                        'delay parameter could not be set correctly. ' ...
                        'Check limits.']);
                end
            end
            
            % level    : double, in V; NaN for set level to 50%
            if ~isempty(level)
                if isnan(level)
                    % set trigger level to 50% of input signal
                    obj.VisaIFobj.write(':TRIGger:LEVel:ASETup');
                elseif ~isempty(level)
                    % format (round) numeric value
                    levelString = num2str(level, '%3.2e');
                    level       = str2double(levelString);
                    % set parameter
                    obj.VisaIFobj.write([':TRIGger:EDGE:LEVel ' levelString]);
                    % read and verify
                    response    = obj.VisaIFobj.query(...
                        ':TRIGger:EDGE:LEVel?');
                    levelActual = str2double(char(response));
                    if abs(level - levelActual) > 1e-3 % sensible threshold
                        disp(['Scope: WARNING - ''configureTrigger'' ' ...
                            'level parameter could not be set correctly.']);
                        status = -1;
                    end
                end
            end
            
            if isnan(status)
                status = 0;
            end
        end
        
        function status = configureZoom(obj, varargin)
            % configureZoom   : configure zoom window
            % zoomFactor = NaN turns zoom off
            
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
                            zoomFactor = str2double(paramValue);
                            if zoomFactor < 1 || isnan(zoomFactor)
                                zoomFactor = 1; % deactivates zoom
                            else
                                zoomFactor = real(zoomFactor);
                            end
                        end
                    case 'zoomPosition'
                        if ~isempty(paramValue)
                            zoomPosition = str2double(paramValue);
                            if isnan(zoomPosition)
                                zoomPosition = 0; % center
                            else
                                zoomPosition = real(zoomPosition);
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
            
            if ~isempty(zoomFactor)
                
                % zoomFactor has to be at least 2
                if zoomFactor > 1 && zoomFactor < 2
                    zoomFactor = 2;
                end
                
                if zoomFactor == 1
                    % disable zoom window
                    obj.VisaIFobj.write('TIMebase:MODE MAIN');
                    obj.VisaIFobj.opc();
                    response = char(obj.VisaIFobj.query('TIMebase:MODE?'));
                    if ~strcmpi(response, 'MAIN')
                        disp(['Scope: ERROR - ''configureZoom'' ' ...
                            'disabling zoom window failed.']);
                        status = -1;
                    end
                else % zoomFactor >= 2
                    % enable zoom window
                    obj.VisaIFobj.write('TIMebase:MODE WINDow');
                    
                    % read current timebase (time/division)
                    response = obj.VisaIFobj.query(':TIMebase:SCALe?');
                    timebase = str2double(char(response));
                    
                    if isnan(timebase)
                        disp(['Scope: ERROR - ''configureZoom'' ' ...
                            'cannot set zoomFactor.']);
                        status = -1;
                    else
                        % calculate timebase of zoom window (time/division)
                        % according to requested zoomFactor
                        zoomTimebase = timebase/zoomFactor;
                        
                        obj.VisaIFobj.write([':TIMebase:WINDow:SCALe ' ...
                            num2str(zoomTimebase, 3)]);
                        % read and verify
                        % zoom mode
                        response = obj.VisaIFobj.query('TIMebase:MODE?');
                        if ~startsWith(char(response), 'WIND', ...
                                'IgnoreCase',true)
                            disp(['Scope: ERROR - ''configureZoom'' ' ...
                                'cannot enable zoom window.']);
                            status = -1;
                        end
                        % timebase of zoom window
                        %response = obj.VisaIFobj.query(':TIMebase:WINDow:SCALe?');
                        % compare str2double(char(response)),  zoomTimebase
                        % ==> do no test here
                    end
                end
            end
            
            if ~isempty(zoomPosition)
                                
                obj.VisaIFobj.write([':TIMebase:WINDow:POSition ' ...
                    num2str(zoomPosition, 4)]);
                % read an verify
                %response = obj.VisaIFobj.query(':TIMebase:WINDow:POSition?');
                % compare str2double(char(response)),  zoomPosition
                        % ==> do no test here
                    
            end
            
            if isnan(status)
                status = 0;
            end
        end
        
        function status = autoscale(obj, varargin)
            % adjust its vertical and/or horizontal scaling
            % autoscale       : adjust vertical and/or horizontal scaling
            %                   vDiv, vOffset for vertical and
            %                   tDiv for horizontal
            %   'mode'        : 'hor', 'vert', 'both'
            
            % init output
            status = NaN;
            
            % initialize all supported parameters
            mode   = '';
            
            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
                switch paramName
                    case 'mode'
                        switch lower(paramValue)
                            case ''
                                mode = 'both'; % set to default
                                disp('  - mode         : BOTH');
                            case {'hor', 'horizontal'}
                                mode = 'horizontal';
                            case {'vert', 'vertical'}
                                mode = 'vertical';
                            case 'both'
                                mode = 'both';
                            otherwise
                                disp(['Scope: Warning - ''autoscale'' ' ...
                                    'mode parameter is unknown --> ignore ' ...
                                    'and continue']);
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
            % ratio of ADC-fullscale range (CHECK description !!!)
            % 1.27 means full ADC-range, ATTENTION trigger stage will be
            %      overloaded and reports senseless trigger frequencies
            % 1.00 means full display@scope range (-4 ..+4) vDiv
            % 0.55 like with autoset (1 channel is active only)
            % 0.30 like with autoset (2 channels are active)
            verticalScalingFactor = obj.AutoscaleVerticalScalingFactor;
            channelOn = [0, 0]; % which channel is displayed?
            channels = {':CHANnel1', ':CHANnel2'};
            for cnt = 1:length(channels)
                % check if trace is on or off
                channelOn(cnt) = str2double(char(obj.VisaIFobj.query(...
                    [channels{cnt} ':DISPlay?'])));
            end
            
            % --> for horizontal scaling
            if strcmpi(mode, 'vertical') || strcmpi(mode, 'both')
                for cnt = 1:length(channels)
                    % check if trace is on or off
                    if channelOn(cnt)
                        % init
                        loopcnt = 0;
                        maxcnt  = 8;
                        while loopcnt < maxcnt
                            % measure min and max voltage
                            %measmax = obj.VisaIFobj.runMeasurement(...
                            %    'channel',num2str(cnt),'parameter', 'max');
                            measmax = obj.runMeasurement(...
                                'channel',num2str(cnt),'parameter', 'max');
                            if ~measmax.errorid
                                vMax = measmax.value;
                                cMax = measmax.overload;
                                % DSO scope does not support overload
                                % detection directly ==> work around
                                if isnan(cMax)
                                    if isnan(vMax)
                                        cMax = 1;
                                    else
                                        cMax = 0;
                                    end
                                end
                            else
                                disp(['Scope: Warning - ''autoscale'': ' ...
                                    'voltage (vMax) measurement failed ' ...
                                    ' for channel ' num2str(cnt) '.' ...
                                    ' Skip vertical scaling.']);
                                break;
                            end
                            
                            %measmin = obj.VisaIFobj.runMeasurement(...
                            %    'channel',num2str(cnt),'parameter', 'min');
                            measmin = obj.runMeasurement(...
                                'channel',num2str(cnt),'parameter', 'min');
                            if ~measmin.errorid
                                vMin = measmin.value;
                                cMin = measmin.overload;
                                % DSO scope does not support overload
                                % detection directly ==> work around
                                if isnan(cMin)
                                    if isnan(vMin)
                                        cMin = 1;
                                    else
                                        cMin = 0;
                                    end
                                end
                            else
                                disp(['Scope: Warning - ''autoscale'': ' ...
                                    'voltage (vMin) measurement failed ' ...
                                    ' for channel ' num2str(cnt) '.' ...
                                    ' Skip vertical scaling.']);
                                break;
                            end
                            
                            % determine vMax and vMin
                            if isnan(vMax) || isnan(vMin)
                                % get current scaling (vDiv)
                                [vDiv, statQuery] = obj.VisaIFobj.query(...
                                    [channels{cnt} ':SCALe?']);
                                vDiv = str2double(char(vDiv));
                                if statQuery ~= 0 || isnan(vDiv)
                                    disp(['Scope: Warning - ''autoscale'': ' ...
                                        'No scaling returned for channel ' ...
                                        num2str(cnt) ...
                                        '. Skip vertical scaling.']);
                                    break
                                end
                                % and get current offset (vOffset)
                                [vOffset, statQuery] = obj.VisaIFobj.query(...
                                    [channels{cnt} ':OFFSet?']);
                                vOffset = str2double(char(vOffset));
                                if statQuery ~= 0 || isnan(vOffset)
                                    disp(['Scope: Warning - ''autoscale'': ' ...
                                        'No offset returned for channel ' ...
                                        num2str(cnt) ...
                                        '. Skip vertical scaling.']);
                                    break
                                end
                                % estimate vMin and/or vMax
                                if isnan(vMax)
                                    % ADC-range : +/-5*vDiv
                                    vMax = vOffset + 5*vDiv;
                                end
                                if isnan(vMin)
                                    % ADC-range : +/-5*vDiv
                                    vMin = vOffset - 5*vDiv;
                                end
                            end
                            
                            % scaling
                            % display : +/-4*vDiv
                            vDiv = (vMax - vMin) / 8;
                            if cMin || cMax
                                % when overload : reduce scaling factor
                                vDiv = vDiv / 0.3;
                            else
                                % no clipping
                                vDiv = vDiv / verticalScalingFactor;
                            end
                            vOffset = (vMax + vMin)/2;
                            
                            % send new vDiv parameter to scope
                            %obj.VisaIFobj.configureInput(...
                            %    'channel' , cnt, ...
                            %    'vDiv'    , vDiv, ...
                            %    'vOffset' , vOffset);
                            obj.configureInput(...
                                'channel' , num2str(cnt, '%d'), ...
                                'vDiv'    , num2str(vDiv, 4),  ...
                                'vOffset' , num2str(vOffset, 4));
                            
                            % wait for completion
                            obj.VisaIFobj.opc;
                            
                            % update loop counter
                            loopcnt = loopcnt + 1;
                            
                            if ~cMax && ~cMin && loopcnt ~= maxcnt
                                % shorten loop when no clipping ==> do a
                                % final loop run to ensure proper scaling
                                loopcnt = maxcnt - 1;
                            end
                        end
                    end
                end
            end
            
            % horizontal scaling (tDiv)
            if strcmpi(mode, 'horizontal') || strcmpi(mode, 'both')
                % use trigger source for frequency measurements
                trigSrc  = obj.VisaIFobj.query(':trigger:source?');
                trigSrc  = char(trigSrc);
                
                if startsWith(upper(trigSrc), 'CHAN') || ...
                        startsWith(upper(trigSrc), 'EXT')
                    % measure frequency
                    measFreq = obj.VisaIFobj.query([':measure:counter? ' ...
                        trigSrc]);
                    measFreq = str2double(char(measFreq));
                else
                    measFreq = NaN;
                end
                
                if ~isnan(measFreq)
                    % display : 10 * tDiv
                    tDiv = numOfSignalPeriods /(10 * measFreq);
                    % now send new tDiv parameter to scope
                    %obj.VisaIFobj.configureAcquisition('tDiv', tDiv);
                    obj.configureAcquisition('tDiv', num2str(tDiv, 4));
                else
                    status   = -1;
                    disp(['Scope: WARNING - ''autoscale'': ' ...
                        'frequency could not be fetched. ' ...
                        'Skip horizontal scaling.']);
                end
                
                % wait for completion
                obj.VisaIFobj.opc();
                
            end
            
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end
        
        function status = makeScreenShot(obj, varargin)
            % make a screenshot of scope display (BMP- or TIFF-file)
            %   'fileName' : file name with optional extension
            %                optional, default is './Tek_Scope_TDS1000.bmp'
            %   'darkMode' : on/off, dark or white background color
            %                optional, default is 'off', 0, false
            
            % init output
            status = NaN;
            
            % configuration and default values
            listOfSupportedFormats = {'.bmp', '.png'};
            filename = './Key_Scope_DSOX1102A.bmp';
            darkmode = false;
            
            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
                switch paramName
                    case 'fileName'
                        filename = paramValue;
                    case 'darkMode'
                        switch lower(paramValue)
                            case {'on', '1'}
                                darkmode = true;
                            otherwise
                                darkmode = false; % incl. {'off', '0'}
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
                fileFormat = fext(2:end); % without leading .
            else
                % no supported file extension
                if isempty(fext)
                    % use default
                    fileFormat = listOfSupportedFormats{1};
                    fileFormat = fileFormat(2:end);
                    filename   = [filename '.' fileFormat];
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
            
            % send some config commands
            if darkmode
                obj.VisaIFobj.write(':HARDcopy:INKSaver OFF');
            else
                obj.VisaIFobj.write(':HARDcopy:INKSaver ON');
            end
            
            obj.VisaIFobj.write(':HARDcopy:LAYout PORTrait');
            
            % request actual binary screen shot data
            bitMapData = obj.VisaIFobj.query([':DISPlay:DATA? ' ...
                upper(fileFormat)]);
            
            % header received?
            if length(bitMapData) < 10
                disp(['Scope: ERROR - ''makeScreenShot'' missing ' ...
                    'header. Abort function.']);
                status = -1;
                return
            else
                % check if bytecount in header is as big as received data
                % leave out #8; cut out number of bytes sent
                ByteCountStr = char(bitMapData(3:10));
                ByteCount = str2double(ByteCountStr);
                
                if length(bitMapData) < ByteCount + 10
                    disp(['Scope: WARNING - ''makeScreenShot'' missing ' ...
                        'data. Check screenshot file.']);
                    status = -1;
                elseif length(bitMapData) > ByteCount + 10
                    disp(['Scope: WARNING - ''makeScreenShot'' received ' ...
                        'too much data. Check screenshot file.']);
                    status = -1;
                end
                
                % save data to file
                fid = fopen(filename, 'wb+');  % open as binary
                fwrite(fid, bitMapData(11:end), 'uint8'); %leave out number
                % of bytes
                fclose(fid);
                
                % wait for operation complete
                [~, statQuery] = obj.VisaIFobj.opc;
                if statQuery
                    status = -1;
                end
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
            % additional elements
            % meas.overload
            % meas.underload
            % meas.errorid
            % meas.errormsg
            
            % init output
            meas.status    = NaN;
            meas.value     = NaN;
            meas.unit      = '';
            meas.overload  = NaN;
            meas.underload = NaN;
            meas.channel   = {};
            meas.parameter = '';
            meas.errorid   = NaN;
            meas.errormsg  = '';
            
            % default values
            channels  = {};
            parameter = '';
            param2    = ''; % additional parameter (option for measurement) 
            
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
                                    channels{cnt}     = 'CHANNEL1';
                                    meas.channel{cnt} = '1';
                                case '2'
                                    channels{cnt}     = 'CHANNEL2';
                                    meas.channel{cnt} = '2';
                                otherwise
                                    channels{cnt}     = '';
                                    meas.channel{cnt} = '';
                                    disp(['Scope: WARNING - ' ...
                                        '''runMeasurement'' invalid ' ...
                                        'channel --> ignore and continue']);
                            end
                        end
                        % remove invalid (empty) entries
                        channels     = ...
                            channels(~cellfun(@isempty, channels));
                        meas.channel = ...
                            meas.channel(~cellfun(@isempty, meas.channel));
                    case 'parameter'
                        switch lower(paramValue)
                            case ''
                                parameter = '';
                            case {'frequency', 'freq'}
                                parameter = 'frequency';
                            case {'period', 'peri'}
                                parameter = 'period';
                            case 'mean'
                                parameter = 'vaverage';
                                param2    = 'cycle';
                            case {'pkpk', 'pk-pk', 'pk2pk'}
                                parameter = 'vpp';
                            case {'crms', 'crm'}
                                parameter = 'vrms';
                                param2    = 'cycle';
                            case 'rms'
                                parameter = 'vrms';
                            case {'minimum', 'min'}
                                parameter = 'vmin';
                            case {'maximum', 'max'}
                                parameter = 'vmax';
                            case {'risetime', 'rise'}
                                parameter = 'risetime';
                            case {'falltime', 'fall'}
                                parameter = 'falltime';
                            case {'poswidth', 'pwidth'}
                                parameter = 'pwidth';
                            case {'negwidth', 'nwidth'}
                                parameter = 'nwidth';
                            case 'dutycycle'
                                parameter = 'dutycycle';
                            case 'phase'
                                parameter = 'phase';
                                %
                                % additional parameters
                            case 'delay'
                                parameter = 'delay';
                            case 'overshoot'
                                parameter = 'overshoot';
                            case 'preshoot'
                                parameter = 'preshoot';
                            case {'amp', 'amplitude'}
                                parameter = 'vamplitude';
                            case 'base'
                                parameter = 'vbase';
                            case 'top'
                                parameter = 'vtop';
                            otherwise
                                % like cursorrms
                                disp(['Scope: ERROR - ''runMeasurement'' ' ...
                                    'measurement type ' paramValue ...
                                    ' is unknown --> abort function']);
                                meas.status = -1;
                                return
                        end
                    otherwise
                        disp(['  WARNING - parameter ''' ...
                            paramName ''' is unknown --> ignore']);
                end
            end
            
            % check inputs (parameter)
            if isempty(parameter)
                disp(['Scope: ERROR ''runMeasurement'' ' ...
                    'measurement parameter must not be empty ' ...
                    '--> abort function']);
                meas.status = -1;
                return
            end
            % copy to output
            meas.parameter = parameter;
            
            % check inputs (channels)
            if length(channels) < 1
                disp(['Scope: ERROR ''runMeasurement'' ' ...
                    'source channel must not be empty ' ...
                    '--> abort function']);
                meas.status  = -1;
                meas.channel = '';
                return
            end
            
            if strcmpi(parameter, 'phase') || strcmpi(parameter, 'delay')
                if length(channels) ~= 2
                    disp(['Scope: WARNING - ''runMeasurement'' ' ...
                        'set channel = ''1, 2'' for phase measurement ' ...
                        '--> correct and continue']);
                    % correct settings (always ascending order (framework))
                    channels     = {'CHANNEL1', 'CHANNEL2'};
                    meas.channel = {'1', '2'};
                end
            elseif length(channels) ~= 1
                % all other measurements for single channels only
                disp(['Scope: ERROR ''runMeasurement'' ' ...
                    'only one channel has to be specified ' ...
                    '--> abort function']);
                meas.status = -1;
                return
            end
            % copy to output
            meas.channel = strjoin(meas.channel, ', ');
            % build up config parameter
            channel      = strjoin(channels, ',');
            
            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------
            
            % clear status register before (we want to check execution
            % errors after measurement)
            obj.VisaIFobj.write('*CLS');
            
            % add comma to additional option
            if ~isempty(param2)
                param2 = [param2 ','];
            end
            
            % run actual measurement
            [value, statQuery] = obj.VisaIFobj.query([...
                ':MEASURE:' parameter '? ' param2 channel]);
            
            if statQuery ~= 0
                meas.status = -1;
                meas.value  = NaN;
                return  % exit
            else
                meas.value  = str2double(char(value));
                if meas.value >= 9e30
                    meas.value = NaN;
                end
            end
            
            % determine unit
            switch upper(parameter)
                case {'VMIN', 'VMAX', 'VAVERAGE', 'VRMS', 'VPP', ...
                        'VAMPLITUDE', 'VBASE', 'VTOP'}
                    % amps or volts
                    response = char(obj.VisaIFobj.query([':' channel ':UNITs?']));
                    if strcmpi(response, 'VOLT')
                        meas.unit = 'V';
                    elseif strcmpi(response, 'AMP')
                        meas.unit = 'A';
                    else
                        disp(['Scope: ERROR - ''runMeasurement'' ' ...
                            'unknown unit!']);
                        meas.status = -1;
                    end
                case 'FREQUENCY'
                    meas.unit = 'Hz';
                case {'PERIOD', 'RISETIME', 'FALLTIME', 'PWIDTH', ...
                        'NWIDTH', 'DELAY'}
                    meas.unit = 's';
                case {'DUTYCYCLE', 'OVERSHOOT', 'PRESHOOT'}
                    meas.unit = '';
                case 'PHASE'
                    meas.unit = 'deg';
                otherwise
                    disp(['Scope: WARNING ''runMeasurement'' ' ...
                        'cannot determine unit of parameter ' ...
                        '--> continue']);
            end
            
            % any errors pending?
            [value, statQuery] = obj.VisaIFobj.query('*ESR?');
            if statQuery ~= 0
                meas.status = -1;
                meas.value  = NaN;
                return % exit
            end
            
            ESReg   = str2double(char(value));
            if ESReg > 0
                % yes: pending errors or warnings
                % how many messages? ==> should be 0 or 1 because ESR was
                % cleared before measurement
                response = char(obj.VisaIFobj.query(':SYSTem:ERRor?'));
                response = strsplit(response,', ');
                meas.errorid = str2double(response{1});
                meas.errormsg = response{2};
            else
                meas.errorid = 0;
                meas.errormsg  = 'okay';
            end
            
            % no direct option to get overload or underload status
            %meas.overload  = 0;
            %meas.underload = 0;
            
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
            
            if isempty(channels)
                waveData.status = -1;
                disp(['Scope: Error - ''captureWaveForm'' no channels ' ...
                    'are specified. --> skip and continue']);
                return
            end
            
            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------
            
            % some common configuration first
            obj.VisaIFobj.write(':WAVeform:FORMat BYTE');
            obj.VisaIFobj.write(':WAVeform:UNSigned OFF');
            
            % allocate empty arrays ==> it is easier to enlarge matrix
            % later on than checking with ':WAVeform:POINts?' (because
            % channel has to be set as source before and has to be active)
            waveData.time = zeros(1, 0);
            waveData.volt = zeros(length(channels), 0);
            
            % loop over channels
            for cnt = 1 : length(channels)
                channel = channels{cnt};
                
                % check if channel is active
                response      = obj.VisaIFobj.query([channel ':DISPlay?']);
                channelActive = str2double(char(response));
                if isnan(channelActive)
                    channelActive = false;
                else
                    channelActive = logical(channelActive);
                end
                
                if channelActive
                    % specify data source
                    obj.VisaIFobj.write([':WAVeform:SOURce ' channel]);
                    
                    % request some axis related waveform parameters
                    % Note: when both channels are active then both
                    % requests report same values ==> common time axis
                    preamble = obj.VisaIFobj.query(':WAVeform:PREamble?');
                    preamble = str2double(split(char(preamble),','));
                    
                    xIncr = preamble(5);
                    xZero = preamble(6);
                    yMult = preamble(8);
                    yOff  = preamble(9);
                    yZero = preamble(10);
                    
                    % actual download of waveform data
                    rawWaveData = obj.VisaIFobj.query(':WAVeform:DATA?');
                    
                    if length(rawWaveData) < 10
                        disp(['Scope: Error - ''captureWaveForm'':' ...
                            ': No header received!']);
                        waveData.status = -1;
                    end
                    
                    % header := #8 + 8Byte (numPointsTransferred)
                    numPointsTransferred = str2double(...
                        char(rawWaveData(3:10)));
                    rawWaveData = double(typecast(rawWaveData(11:end), ...
                        'int8'));
                    
                    if length(rawWaveData) ~= numPointsTransferred
                        disp(['Scope: Error - ''captureWaveForm'':' ...
                            'Wrong amount of data received!']);
                        waveData.status = -1;
                        rawWaveData     = rawWaveData * NaN;
                    end
                    
                    % convert raw wave data to voltage
                    newWaveData = (rawWaveData - yZero)*yMult + yOff;
                    
                    % copy to output
                    len = length(newWaveData);
                    if size(waveData.volt, 2) < len
                        % enlarge matrix
                        waveData.volt = [waveData.volt ...
                            zeros(length(channels), ...
                            len - size(waveData.volt, 2))];
                        waveData.volt(cnt, :)     = newWaveData;
                    else
                        waveData.volt(cnt, 1:len) = newWaveData;
                    end
                end
            end
            
            if ~isempty(waveData.volt)
                waveData.time = (0 : size(waveData.volt, 2)-1);
                % scale time axis (same time axis for both channels)
                waveData.time = waveData.time *xIncr + xZero;
                % sample rate
                waveData.samplerate = 1/xIncr;
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
            
            [response, status] = obj.VisaIFobj.query(':OPERegister:CONDition?');
            if status ~= 0
                % failure
                acqState = 'visa error. couldn''t read acquisition state';
            else
                response = str2double(char(response));
                if ~isnan(response)
                    runBit = bitget(response, 3+1); % bit 3 is RUN bit
                    switch runBit
                        case 0,    acqState = 'stopped';
                        case 1,    acqState = 'running';
                        otherwise, acqState = '';
                    end
                else
                    acqState = '';
                end
            end
        end
        
        function trigState = get.TriggerState(obj)
            % get trigger state
            
            % event registers cleared after reading
            % trigger event register
            [respTriggered, stat1] = obj.VisaIFobj.query(':TER?');
            % arm event register
            % ==> better to read out operation status condition register?
            % check this part of code (see doc Keysight InfiniiVision
            % 1000 X-Series Oscilloscopes, programmers guide 2019, page 150)
            [respArmed,     stat2] = obj.VisaIFobj.query(':AER?');
            
            statQuery = abs(stat1) + abs(stat2);
            
            if statQuery ~= 0
                trigState = 'visa error. couldn''t read trigger state';
            else
                Triggered = str2double(char(respTriggered));
                Armed     = str2double(char(respArmed));
                if Triggered
                    trigState = 'triggered';
                elseif Armed
                    trigState = 'waitfortrigger';
                else
                    trigState = '';
                end
            end
        end
        
        function errMsg = get.ErrorMessages(obj)
            % read error list from the scope’s error buffer
            errNum = 1;
            errCnt = 0;
            while (errCnt < 30) && (errNum ~= 0)
                [response, statQuery] = obj.VisaIFobj.query(':SYSTem:ERRor?');
                if statQuery ~= 0
                    errMsg = 'visa error. couldn''t read error buffer.';
                    break;
                end
                response = split(char(response), ',');
                errNum = str2double(response{1});
                errMsg = response{2};
                errMsg = errMsg(2:(end-1));
                errCnt = errCnt + 1;
            end
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
