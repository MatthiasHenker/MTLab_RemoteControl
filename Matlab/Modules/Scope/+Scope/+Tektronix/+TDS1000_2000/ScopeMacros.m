classdef ScopeMacros < handle
    % include device specific documentation when needed
    %
    %   - autorange   was not included in common scope class
    %         'autorange:settings horizontal' or 'vertical', 'both'
    %         'autorange:settings?'
    %         'autorange:state 0' or '1'
    %         'autorange:state?'
    % 
    % Tektronix TDS1000, TDS 2000 series macros
    
    properties(Constant = true)
        MacrosVersion = '1.2.0';      % release version
        MacrosDate    = '2021-01-30'; % release date
        %
        % ? num of supported channels and so on ...
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
            if obj.VisaIFobj.write('lock all')
                status = -1;
            end
            % set SCPI response header style to 'off'
            if obj.VisaIFobj.write('header off')
                status = -1;
            end
            % set language = english
            if obj.VisaIFobj.write('language english')
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
            if obj.VisaIFobj.write('lock none')  % or 'unlock all'
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
            
            % set to default state (factory settings) as extended reset
            % also clears status register and queues
            if obj.VisaIFobj.write('factory')
                status = -1;
            end
            % set SCPI response header style to 'off' again
            if obj.VisaIFobj.write('header off')
                status = -1;
            end
            %if true % none is already factory default
            %    obj.VisaIFobj.write('measurement:meas1:type none');
            %    obj.VisaIFobj.write('measurement:meas2:type none');
            %    obj.VisaIFobj.write('measurement:meas3:type none');
            %    obj.VisaIFobj.write('measurement:meas4:type none');
            %    obj.VisaIFobj.write('measurement:meas5:type none');
            %end
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
            % clear status at scope
            status = obj.VisaIFobj.write('*CLS');
        end
        
        function status = lock(obj)
            % lock all buttons at scope
            status = obj.VisaIFobj.write('lock all');
        end
        
        function status = unlock(obj)
            % unlock all buttons at scope
            status = obj.VisaIFobj.write('unlock all');
        end
        
        function status = acqRun(obj)
            % start data acquisitions at scope (according to trigger
            % and acquisition settings)
            status = obj.VisaIFobj.write('acquire:state 1');
        end
        
        function status = acqStop(obj)
            % stop data acquisitions at scope
            status = obj.VisaIFobj.write('acquire:state 0');
        end
        
        function status = autoset(obj)
            % causes the oscilloscope to adjust its vertical, horizontal,
            % and trigger controls to display a stable waveform
            
            % init output
            status = NaN;
            
            % actual autoset command
            if obj.VisaIFobj.write('autoset execute')
                status = -1;
            end
            % wait until done
            if obj.VisaIFobj.write('*wai')
                status = -1;
            end
            % request status; which type of signal was detected
            [response, statQuery] = obj.VisaIFobj.query('autoset:signal?');
            if statQuery
                status = -1;
            elseif obj.ShowMessages
                disp(['  autoset done. Detected signal ' ...
                    'type is ''' char(response) '''.']);
            end
            
            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end
        
        % -----------------------------------------------------------------
        
        function status = configureInput(obj, varargin)
            % configureInput  : configure input of specified channels
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
            vDiv           = '';
            vOffset        = '';
            coupling       = '';
            inputDiv       = '';
            bwLimit        = '';
            invert         = '';
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
                                case '1'
                                    channels{cnt} = 'ch1';
                                case '2'
                                    channels{cnt} = 'ch2';
                                case ''
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
                                        'trace parameter is unknown --> ignore ' ...
                                        'and continue']);
                            end
                        end
                    case 'impedance'
                        if str2double(paramValue) ~= 1e6 && ~isempty(paramValue)
                            disp(['Scope: Warning - ''impedance'' ' ...
                                'parameter cannot be configured']);
                            if obj.ShowMessages
                                disp('  - impedance    : 1e6 (coerced)');
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
                                    coupling = 'ac';
                                case 'dc'
                                    coupling = 'dc';
                                case 'gnd'
                                    coupling = 'gnd';
                                otherwise
                                    coupling = '';
                                    disp(['Scope: Warning - ''configureInput'' ' ...
                                        'coupling parameter is unknown --> ignore ' ...
                                        'and continue']);
                            end
                        end
                    case 'inputDiv'
                        if ~isempty(paramValue)
                            switch lower(paramValue)
                                case {'1', '10', '20', '50', '100', '200', '500', '1000'}
                                    inputDiv = paramValue;
                                otherwise
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
                                    bwLimit = 'off';
                                case {'on',  '1'}
                                    bwLimit = 'on';
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
                                    invert = 'off';
                                case {'on',  '1'}
                                    invert = 'on';
                                otherwise
                                    invert = '';
                                    disp(['Scope: Warning - ''configureInput'' ' ...
                                        'invert parameter is unknown --> ignore ' ...
                                        'and continue']);
                            end
                        end
                    case 'skew'
                        if obj.ShowMessages && ~isempty(paramValue)
                            disp(['Scope: Warning - ''skew'' ' ...
                                'parameter cannot be set --> ' ...
                                ' skew = 0']);
                        end
                    case 'unit'
                        if ~isempty(paramValue)
                            switch upper(paramValue)
                                case 'V'
                                    unit = '"V"';
                                case 'A'
                                    unit = '"A"';
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
            
            % loop over channels
            for cnt = 1:length(channels)
                channel = channels{cnt};
                
                % 'coupling'         : 'DC', 'AC', 'GND'
                if ~isempty(coupling)
                    % set parameter
                    obj.VisaIFobj.write([channel ':coupling ' coupling]);
                    % read and verify
                    response = obj.VisaIFobj.query([channel ':coupling?']);
                    if ~strcmpi(coupling, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'coupling parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'inputDiv', 'probe': 1, 10, 20, 50, 100, 200, 500, 1000
                if ~isempty(inputDiv)
                    % set parameter
                    obj.VisaIFobj.write([channel ':probe ' inputDiv]);
                    % read and verify
                    response = obj.VisaIFobj.query([channel ':probe?']);
                    if str2double(inputDiv) ~= str2double(char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'inputDiv parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'bwLimit'          : 'off', 'on'
                if ~isempty(bwLimit)
                    % set parameter
                    obj.VisaIFobj.write([channel ':bandwidth ' bwLimit]);
                    % read and verify
                    response = obj.VisaIFobj.query([channel ':bandwidth?']);
                    if ~strcmpi(bwLimit, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'bwLimit parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'unit'             : 'V' or 'A'
                if ~isempty(unit)
                    % set parameter
                    obj.VisaIFobj.write([channel ':yunit ' unit]);
                    % read and verify
                    response = obj.VisaIFobj.query([channel ':yunit?']);
                    if ~strcmpi(unit, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'unit parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'invert'           : 'off', 'on'
                if ~isempty(invert)
                    % set parameter
                    obj.VisaIFobj.write([channel ':invert ' invert]);
                    % read and verify
                    response = obj.VisaIFobj.query([channel ':invert?']);
                    if ~strcmpi(invert, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'invert parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'trace'          : 'off', 'on'
                if ~isempty(trace)
                    % set parameter
                    obj.VisaIFobj.write(['select:' channel ' ' trace]);
                    % read and verify
                    response = obj.VisaIFobj.query(['select:' channel '?']);
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
                    obj.VisaIFobj.write([channel ':scale ' vDivString]);
                    % read and verify
                    response   = obj.VisaIFobj.query([channel ':scale?']);
                    vDivActual = str2double(char(response));
                    if vDiv ~= vDivActual
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'vDiv parameter could not be set correctly. ' ...
                            'Check limits.']);
                    end
                    % update
                    vDiv = vDivActual;
                elseif ~isempty(vOffset)
                    % read vDiv anyway: required for vOffset scaling
                    response = obj.VisaIFobj.query([channel ':scale?']);
                    vDiv     = str2double(char(response));
                end
                
                % 'vOffset'        : positive double in V
                if ~isempty(vOffset)
                    % convert vOffset from Volt to div
                    vOffsetDiv = - vOffset/vDiv;
                    % offset position (in div) support 0.04 steps only
                    vOffsetDiv = round(vOffsetDiv*25)/25;
                    % format (round) numeric value
                    vOffString = num2str(vOffsetDiv, '%1.2e');
                    vOffsetDiv = str2double(vOffString);
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':position ' vOffString]);
                    % read and verify
                    response   = obj.VisaIFobj.query([channel ':position?']);
                    vOffActual = str2double(char(response));
                    if vOffsetDiv ~= vOffActual
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
            sampleRate  = [];
            mode        = '';
            numAverage  = [];
            
            for idx = 1:2:length(varargin)
                paramName  = varargin{idx};
                paramValue = varargin{idx+1};
                switch paramName
                    case 'tDiv'
                        if ~isempty(paramValue)
                            tDiv = abs(str2double(paramValue));
                            if  isnan(tDiv) || isinf(tDiv)
                                disp(['Scope: Error - ''configureAcquisition'' ' ...
                                    'tDiv parameter is invalid --> ' ...
                                    'abort function']);
                                status = -1;
                                return
                            end
                        end
                    case 'sampleRate'
                        if ~isempty(paramValue)
                            sampleRate = abs(str2double(paramValue));
                            if isnan(sampleRate) || isinf(sampleRate)
                                disp(['Scope: Error - ''configureAcquisition'' ' ...
                                    'sampleRate parameter is invalid --> ' ...
                                    'abort function']);
                                status = -1;
                                return
                            end
                        end
                    case 'maxLength'
                        if obj.ShowMessages && ~isempty(paramValue)
                            disp(['Scope: Warning - ''maxLength'' ' ...
                                    'parameter cannot be set --> ' ...
                                    ' maxLength = 2500']);
                        end
                    case 'mode'
                        mode = paramValue;
                        switch lower(mode)
                            case ''
                                mode = '';
                            case 'sample'
                                mode = 'sample';
                            case 'peakdetect'
                                mode = 'peakdetect';
                            case 'average'
                                mode = 'average';
                            otherwise
                                mode = '';
                                disp(['Scope: Warning - ''configureAcquisition'' ' ...
                                    'mode parameter is unknown --> ignore ' ...
                                    'and continue']);
                        end
                    case 'numAverage'
                        switch paramValue
                            case {'', '4', '16', '64', '128'}
                                numAverage = paramValue;
                            otherwise
                                numAverage = '';
                                disp(['Scope: Warning - ''configureAcquisition'' ' ...
                                    'numAverage parameter is not ' ...
                                    'supported --> ignore and continue']);
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
            
            % sampleRate
            if ~isempty(sampleRate) && ~isempty(tDiv)
                disp(['Scope: WARNING - sample rate and tDiv parameters ' ...
                    'are specified. Ignoring sample rate.']);
            elseif ~isempty(sampleRate)
                % convert sample rate to time scaling value
                tDiv = 250 / sampleRate;
            end
            
            % tDiv        : numeric value in s
            %               [5e-9, 1e-8, 2.5e-8, 5e-8, ... 5e1]
            if ~isempty(tDiv)
                % format (round) numeric value
                tDivString = num2str(tDiv, '%1.1e');
                tDiv       = str2double(tDivString);
                % set parameter
                obj.VisaIFobj.write(['horizontal:main:scale ' tDivString]);
                % read and verify
                response = obj.VisaIFobj.query('horizontal:main:scale?');
                tDivActual = str2double(char(response));
                if (tDiv/tDivActual) < 0.7 || (tDiv/tDivActual) > 1.8
                    disp(['Scope: WARNING - ''configureAcquisition'' ' ...
                        'tDiv parameter could not be set correctly. ' ...
                        'Check limits. ']);
                end
            end
            
            % mode     : 'sample', 'peakdetect', 'average'
            if ~isempty(mode)
                % set parameter
                obj.VisaIFobj.write(['acquire:mode ' mode]);
                % read and verify
                response = obj.VisaIFobj.query('acquire:mode?');
                if ~strcmpi(mode, char(response))
                    disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                        'mode parameter could not be set correctly.']);
                    status = -1;
                end
            end
            
            % numAverage  : 4, 16, 64, 128
            if ~isempty(numAverage)
                % set parameter
                obj.VisaIFobj.write(['acquire:numavg ' numAverage]);
                % read and verify
                response = obj.VisaIFobj.query('acquire:numavg?');
                if ~strcmpi(numAverage, char(response))
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
                                mode = 'single';
                            case 'normal'
                                mode = 'normal';
                            case 'auto'
                                mode = 'auto';
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
                                type = 'rise';
                            case 'fallingedge'
                                type = 'fall';
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
                                source = 'ch1';
                            case 'ch2'
                                source = 'ch2';
                            case 'ext'
                                source = 'ext';
                            case 'ext5'
                                source = 'ext5';
                            case 'ac-line'
                                source = 'line';
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
                                coupling = 'ac';
                            case 'dc'
                                coupling = 'dc';
                            case {'noisereject', 'noiserej'}
                                coupling = 'noiserej';
                            case {'hfreject', 'hfrej'}
                                coupling = 'hfrej';
                            case {'lfreject', 'lfrej'}
                                coupling = 'lfrej';
                            otherwise
                                coupling = '';
                                disp(['Scope: Warning - ''configureTrigger'' ' ...
                                    'coupling parameter is unknown --> ignore ' ...
                                    'and continue']);
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
            modeFailed = false;  % init
            if ~isempty(mode)
                % part 1
                if strcmpi(mode, 'auto')
                    % set parameter
                    obj.VisaIFobj.write('trigger:main:mode auto');
                    % read and verify
                    response = char(obj.VisaIFobj.query('trigger:main:mode?'));
                    if ~strcmpi('auto', response)
                        modeFailed = true;
                    end
                else
                    % set parameter
                    obj.VisaIFobj.write('trigger:main:mode normal');
                    % read and verify
                    response = char(obj.VisaIFobj.query('trigger:main:mode?'));
                    if ~strcmpi('normal', response)
                        modeFailed = true;
                    end
                end
                % part 2
                if strcmpi(mode, 'single')
                    % set parameter
                    obj.VisaIFobj.write('acquire:stopafter sequence');
                    % read and verify
                    response = char(obj.VisaIFobj.query('acquire:stopafter?'));
                    if ~strcmpi('sequence', response)
                        modeFailed = true;
                    end
                else
                    % set parameter
                    obj.VisaIFobj.write('acquire:stopafter runstop');
                    % read and verify
                    response = char(obj.VisaIFobj.query('acquire:stopafter?'));
                    if ~strcmpi('runstop', response)
                        modeFailed = true;
                    end
                end
                %
                if modeFailed
                    disp(['Scope: Error - ''configureTrigger'' ' ...
                        'mode parameter could not be set correctly.']);
                    status = -1;
                end
            end
            
            % type     : 'rise', 'fall'
            if ~isempty(type)
                % set parameter
                obj.VisaIFobj.write('trigger:main:type edge');
                % read and verify
                responseEdge = obj.VisaIFobj.query('trigger:main:type?');
                responseEdge = char(responseEdge);
                %
                % set parameter
                obj.VisaIFobj.write(['trigger:main:edge:slope ' type]);
                % read and verify
                response = obj.VisaIFobj.query('trigger:main:edge:slope?');
                response = char(response);
                if ~strcmpi(type, response) || ~strcmpi('edge', ...
                        responseEdge)
                    disp(['Scope: Error - ''configureTrigger'' ' ...
                        'type parameter could not be set correctly.']);
                    status = -1;
                end
            end
            
            % source   : 'ch1', 'ch2', 'ext', 'ext5', 'line'
            if ~isempty(source)
                % set parameter
                obj.VisaIFobj.write(['trigger:main:edge:source ' source]);
                % read and verify
                response = obj.VisaIFobj.query('trigger:main:edge:source?');
                if ~strcmpi(source, char(response))
                    disp(['Scope: Error - ''configureTrigger'' ' ...
                        'source parameter could not be set correctly.']);
                    status = -1;
                end
            end
            
            % coupling : 'ac', 'dc', 'noiserej', 'hfrej', 'lfrej'
            if ~isempty(coupling)
                % set parameter
                obj.VisaIFobj.write(['trigger:main:edge:coupling ' coupling]);
                % read and verify
                response = obj.VisaIFobj.query('trigger:main:edge:coupling?');
                if ~strcmpi(coupling, char(response))
                    disp(['Scope: Error - ''configureTrigger'' ' ...
                        'coupling parameter could not be set correctly.']);
                    status = -1;
                end
            end
            
            % level    : double, in V; NaN for set level to 50%
            if isnan(level)
                % set trigger level to 50% of input signal
                obj.VisaIFobj.write('trigger:main setlevel');
            elseif ~isempty(level)
                % format (round) numeric value
                levelString = num2str(level, '%1.1e');
                level       = str2double(levelString);
                % set parameter
                obj.VisaIFobj.write(['trigger:main:level ' levelString]);
                % read and verify
                response    = obj.VisaIFobj.query('trigger:main:level?');
                levelActual = str2double(char(response));
                if abs(level - levelActual) > 1    % sensible threshold
                    % depends on vDiv of trigger source
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
                obj.VisaIFobj.write(['horizontal:main:position ' delayString]);
                % read and verify
                response    = obj.VisaIFobj.query('horizontal:main:position?');
                delayActual = str2double(char(response));
                if abs(delay - delayActual) > 1e-3 % sensible threshold
                    % depends on tDiv
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
            % configure zoom window
            
            disp(['Scope WARNING - Method ''configureZoom'' is not ' ...
                'supported for ']);
            disp(['      ' obj.VisaIFobj.Vendor '/' ...
                obj.VisaIFobj.Product ' -->  Ignore and continue']);
            status = 0;
        end
        
        function status = autoscale(obj, varargin)
            % autoscale       : adjust vertical and/or horizontal scaling
            %                   vDiv, vOffset for vertical and 
            %                   tDiv for horizontal
            %   'mode'        : 'hor', 'vert', 'both'
            
            % init output
            status = NaN;
            
            % initialize all supported parameters
            mode      = '';
            
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
            % ratio of ADC-fullscale range
            % 1.27 means full ADC-range, ATTENTION trigger stage will be
            %      overloaded and reports senseless trigger frequencies
            % 1.00 means full display@scope range (-4 ..+4) vDiv
            % 0.55 like with autoset (1 channel is active only)
            % 0.30 like with autoset (2 channels are active)
            verticalScalingFactor = obj.AutoscaleVerticalScalingFactor;
            
            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------
            
            % vertical scaling (vDiv, vOffset)
            if strcmpi(mode, 'vertical') || strcmpi(mode, 'both')
                channels = {'ch1', 'ch2'};
                for cnt = 1:length(channels)
                    % check if trace is on or off
                    trace = obj.VisaIFobj.query(['select:' channels{cnt} '?']);
                    if str2double(char(trace)) == 1
                        % init
                        loopcnt  = 0;
                        maxcnt   = 8;
                        while loopcnt < maxcnt
                            % now measure min and max voltage
                            meas = obj.getAmplMinMax(channels{cnt});
                            if isempty(meas.errorid)
                                cmax = logical(meas.clippingpos);
                                cmin = logical(meas.clippingneg);
                                vmax = meas.max;
                                vmin = meas.min;
                            else
                                disp(['Scope: Warning - ''autoscale'': ' ...
                                    'voltage measurement failed for ' ...
                                    channels{cnt} '.' ...
                                    ' Skip vertical scaling.']);
                                break;
                            end
                            
                            % voltage scaling
                            % ADCraw = [-127:127]digits
                            % and 25 digits / div
                            % display with 8 vertical div
                            % fulldisplayfactor = (8*25)/25 = 8
                            vDiv = (vmax - vmin) / 8;
                            % adjust gain (with some backoff (reserve))
                            if cmax || cmin
                                % +/- clipping: scale down
                                vDiv = vDiv / 0.3;
                            else
                                % adjust gently
                                vDiv = vDiv / verticalScalingFactor;
                            end
                            vOffset = (vmax + vmin)/2;
                            
                            % send new vDiv, vOffset parameters to scope
                            %obj.VisaIFobj.configureInput(...
                            %    'channel' , channels{cnt}, ...
                            %    'vDiv'    , vDiv,  ...
                            %    'vOffset' , vOffset);
                            obj.configureInput(...
                                'channel' , num2str(cnt, '%d'), ...
                                'vDiv'    , num2str(vDiv, 4),  ...
                                'vOffset' , num2str(vOffset, 4));
                            
                            % wait for completion
                            obj.VisaIFobj.opc;
                            
                            % update loop counter
                            loopcnt = loopcnt + 1;
                            
                            if ~cmax && ~cmin && loopcnt ~= maxcnt
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
                % for horizontal scaling use trigger frequency
                
                % request measurement result
                [value, status_query] = ...
                    obj.VisaIFobj.query('trigger:main:frequency?');
                if status_query ~= 0
                    trigFreq =  NaN;
                    status   = -1;
                else
                    trigFreq = str2double(char(value));
                    if trigFreq > 1e37
                        % scope reports max value when no trigger is valid
                        trigFreq = NaN;
                    end
                end
                
                if ~isnan(trigFreq)
                    % adjust tDiv parameter
                    % calculate sensible tDiv parameter (10*tDiv@screen)
                    tDiv = numOfSignalPeriods / (10*trigFreq);
                    % now send new tDiv parameter to scope
                    %obj.VisaIFobj.configureAcquisition('tDiv', tDiv);
                    obj.configureAcquisition('tDiv', num2str(tDiv, 4));
                    % wait for completion
                    obj.VisaIFobj.opc;
                else
                    disp(['Scope: Warning - ''autoscale'': ' ...
                        'no trigger found. Skip horizontal scaling.']);
                end
            end
            
            % set final status
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
            listOfSupportedFormats = {'.bmp', '.tiff'};
            filename = './Tek_Scope_TDS1000.bmp';
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
            obj.VisaIFobj.write('hardcopy:button prints');
            obj.VisaIFobj.write(['hardcopy:format ' fileFormat]);
            if darkmode
                obj.VisaIFobj.write('hardcopy:inksaver off');
            else
                obj.VisaIFobj.write('hardcopy:inksaver on');
            end
            obj.VisaIFobj.write('hardcopy:layout portrait');
            obj.VisaIFobj.write('hardcopy:port usb');
            
            % request actual binary screen shot data
            bitMapData = obj.VisaIFobj.query('hardcopy start');
            
            % some data received?
            if length(bitMapData) < 10000
                disp(['Scope: WARNING - ''makeScreenShot'' missing ' ...
                    'data. Check screenshot file.']);
                status = -1;
            end
            
            % save data to file
            fid = fopen(filename, 'wb+');  % open as binary
            fwrite(fid, bitMapData, 'uint8');
            fclose(fid);
            
            % wait for operation complete
            [~, statQuery] = obj.VisaIFobj.opc;
            if statQuery
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
                                    channels{cnt}     = 'ch1';
                                    meas.channel{cnt} = '1';
                                case '2'
                                    channels{cnt}     = 'ch2';
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
                                parameter = 'mean';
                            case {'pkpk', 'pk-pk', 'pk2pk'}
                                parameter = 'pk2pk';
                            case {'crms', 'crm'}
                                parameter = 'crms';
                            case 'rms'
                                parameter = 'rms';
                            case {'minimum', 'min'}
                                parameter = 'minimum';
                            case {'maximum', 'max'}
                                parameter = 'maximum';
                            case 'cursorrms'
                                parameter = 'cursorrms';
                            case {'risetime', 'rise'}
                                parameter = 'rise';
                            case {'falltime', 'fall'}
                                parameter = 'fall';
                            case {'poswidth', 'pwidth'}
                                parameter = 'pwidth';
                            case {'negwidth', 'nwidth'}
                                parameter = 'nwidth';
                            case 'dutycycle'
                                parameter = 'pduty';
                            case 'phase'
                                parameter = 'phase';
                            otherwise
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
            
            if strcmpi(parameter, 'phase')
                if length(channels) ~= 2
                    disp(['Scope: WARNING - ''runMeasurement'' ' ...
                        'set channel = ''1, 2'' for phase measurement ' ...
                        '--> correct and continue']);
                    % correct settings (always ascending order (framework))
                    channels     = {'ch1', 'ch2'};
                    meas.channel = {'1', '2'};
                end
                % only channel 1 has to be used for configuration
                channels = channels(1); % same as {'ch1'}
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
            % build up config parameter (length of channels is always 1)
            channel      = strjoin(channels);
                        
            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------
            
            % clear status register before (we want to check execution
            % errors after measurement)
            obj.VisaIFobj.write('*CLS');
            
            % setup measurement
            obj.VisaIFobj.write(['measurement:immed:source ' channel]);
            % read and verify
            response = obj.VisaIFobj.query('measurement:immed:source?');
            if ~strcmpi(channel, char(response))
                disp(['Scope: ERROR - ''runMeasurement'' ' ...
                    'setup of measurement was not successful ' ...
                    '--> abort function']);
                meas.status = -1;
            end
            %
            obj.VisaIFobj.write(['measurement:immed:type ' parameter]);
            % read and verify
            response = obj.VisaIFobj.query('measurement:immed:type?');
            if ~strcmpi(parameter, char(response))
                disp(['Scope: ERROR - ''runMeasurement'' ' ...
                    'setup of measurement was not successful ' ...
                    '--> abort function']);
                meas.status = -1;
            end
            
            % read measurement results
            [unit, statQuery] = obj.VisaIFobj.query('measurement:immed:unit?');
            if statQuery ~= 0
                meas.status = -1;
            end
            unit       = char(unit);
            meas.unit  = strrep(unit, '"', ''); % remove "
            
            % send wait command before to ensure correct measurement data
            obj.VisaIFobj.write('*wai');
            %
            % fetch measurement result
            [value, statQuery] = obj.VisaIFobj.query('measurement:immed:value?');
            if statQuery ~= 0
                meas.status = -1;
                meas.value  = NaN;
                return  % exit
            else
                meas.value  = str2double(char(value));
                if meas.value > 9e37
                    % scope reports max value when channel is not active
                    meas.value = NaN;
                end
            end
            
            % any errors pending?
            [value, statQuery] = obj.VisaIFobj.query('*esr?');
            if statQuery ~= 0
                meas.status = -1;
                meas.value  = NaN;
                return % exit
            end
            % optionally read error messages
            ESReg   = str2double(char(value));
            if ESReg > 0
                % yes: pending errors or warnings
                % how many messages? ==> should be 0 or 1 because ESR was
                % cleared before measurement
                NumOfMsg = str2double(char(obj.VisaIFobj.query('evqty?')));
                %
                for cnt = 1 : NumOfMsg
                    meas.errorid = str2double(char(obj.VisaIFobj.query('event?')));
                end
            else
                meas.errorid = 0;
            end
            
            % evaluate error/warning message (read programmer manual)
            switch meas.errorid
                case 0
                    % all fine
                    meas.overload  = 0;
                    meas.underload = 0;
                    meas.errormsg  = 'okay';
                case {547, 548, 549, 2227, 2228, 2229}
                    % positive and/or negative clipping
                    meas.overload  = 1;
                    meas.underload = 0;
                    meas.errormsg  = 'positive and/or negative clipping';
                case 541
                    % too small amplitude
                    meas.overload  = 0;
                    meas.underload = 1;
                    meas.errormsg  = 'too small amplitude';
                case 2225
                    % no waveform to measure (channel is off)
                    meas.errormsg  = ['no waveform to measure ' ...
                        '(channel is off)'];
                otherwise
                    % all other error/warning messages ==> extend later?
                    meas.overload  = NaN;
                    meas.underload = NaN;
                    meas.errormsg  = ['unknown error (read ' ...
                        'programmer manual)'];
            end
            
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
                                    channels{cnt} = 'ch1';
                                case '2'
                                    channels{cnt} = 'ch2';
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
                waveData.status     = -1;
                disp(['Scope: Error - ''captureWaveForm'' no channels ' ...
                    'are specified. --> skip and continue']);
                return
            end
            
            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------
            
            % some common configuration first
            obj.VisaIFobj.write('data:width 1'); % only of inerest when binary
            obj.VisaIFobj.write('data:encdg ribinary');
            %obj.VisaIFobj.write('data:encdg ascii'); % alternative (slow)
            obj.VisaIFobj.write('data:start 1');
            obj.VisaIFobj.write('data:stop 2500');
            
            % allocate arrays
            waveData.time = (0 : 2499);
            waveData.volt = zeros(length(channels), length(waveData.time));
            xIncr         = 1;
            xZero         = 0;
            
            % loop over channels
            for cnt = 1 : length(channels)
                channel = channels{cnt};
                
                % check if channel is active
                response      = obj.VisaIFobj.query(['select:' channel '?']);
                response      = str2double(char(response));
                if isnan(response)
                    channelActive = false;
                else
                    channelActive = logical(response);
                end
                
                if channelActive
                    % specify data source
                    obj.VisaIFobj.write(['data:source ' channel]);
                    
                    % request some time axis related waveform parameters
                    % Note: when both channels are active then both
                    % requests report same values ==> common time axis
                    xIncr = obj.VisaIFobj.query('wfmpre:xincr?');
                    xIncr = str2double(char(xIncr));
                    %
                    xZero = obj.VisaIFobj.query('wfmpre:xzero?');
                    xZero = str2double(char(xZero));
                    
                    % actual download of waveform data
                    rawWaveData = obj.VisaIFobj.query('curve?');
                    
                    % conversion rule when format = ribinary
                    % remove header #42500 with
                    % #    : header
                    % 4    : 4 digits are following to specify length
                    % 2500 : 2500 samples (here fixed number)
                    header = char(rawWaveData(1:6));
                    rawWaveData = double(typecast(rawWaveData(7:end), ...
                        'int8'));
                    if ~strcmpi(header, '#42500') || ...
                            length(rawWaveData) ~= 2500
                        rawWaveData = zeros(1, 2500);
                        waveData.status = -1;
                        disp([functionName ': data format mismatch.']);
                    end
                    %
                    % conversion rule when format = ascii
                    % split (csv list of samples) and convert to numeric
                    %rawWaveData = str2double(split(char(rawWaveData),','));
                    
                    % request some volt axis related waveform parameters
                    yOff  = obj.VisaIFobj.query('wfmpre:yoff?');
                    yOff  = str2double(char(yOff));
                    %
                    yMult = obj.VisaIFobj.query('wfmpre:ymult?');
                    yMult = str2double(char(yMult));
                    %
                    yZero = obj.VisaIFobj.query('wfmpre:yzero?');
                    yZero = str2double(char(yZero));
                    %
                    % convert raw wave data to voltage
                    waveData.volt(cnt, :) = (rawWaveData - yOff)*yMult ...
                        + yZero;
                end
            end
            
            % scale time axis (same time axis for both channels)
            waveData.time = waveData.time *xIncr + xZero;
            % sample rate
            waveData.samplerate = 1/xIncr;
            
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
            
            % request state
            [acqState, status] = obj.VisaIFobj.query('acquire:state?');
            
            if status ~= 0
                % failure
                acqState = 'visa error. couldn''t read acquisition state';
            else
                acqState = char(acqState);
                % remap trigger satte
                switch lower(acqState)
                    case '0',  acqState = 'stopped';
                    case '1',  acqState = 'running';
                    otherwise, acqState = '';
                end
            end
        end
        
        function trigState = get.TriggerState(obj)
            % get trigger state
            
            % request state
            [trigState, status] = obj.VisaIFobj.query('trigger:state?');
            
            if status ~= 0
                % failure
                trigState = 'visa error. couldn''t read trigger state';
            else
                trigState = char(trigState);
                % remap trigger satte
                switch lower(trigState)
                    case 'armed',   trigState = 'waitfortrigger (armed)';
                    case 'ready',   trigState = 'waitfortrigger';
                    case 'auto',    trigState = 'triggered (auto)';
                    case 'trigger', trigState = 'triggered';
                    case 'scan',    trigState = 'triggered (scan)';
                    case 'save',    trigState = '';   % stopped
                    otherwise,      trigState = 'device error. unknown state';
                end
            end
        end
        
        function errMsg = get.ErrorMessages(obj)
            % read errors from the scope’s error buffer
            
            % config
            maxErrCnt = 20;
            errCell   = cell(1, maxErrCnt);
            
            % read first error entry
            [errCell1, stat_qu] = obj.VisaIFobj.query('errlog:first?');
            if stat_qu
                errCell1 = 'visa error, couldn''t read error';
                % do not read next error when read first error failed
                readNextError = false;
            else
                % convert to char
                errCell1 = char(errCell1);
                if strcmpi(errCell1, '""')
                    errCell1 = '';
                end
                % init loop parameter
                readNextError = true;
            end
            cnt          = 1;
            errCell{cnt} = errCell1;
            % read next error from buffer until done
            while readNextError && cnt < maxErrCnt
                % read next error entry
                [errCell2, stat_qu] = obj.VisaIFobj.query('errlog:next?');
                if stat_qu
                    errCell2 = 'visa error, couldn''t read error';
                else
                    % convert to char
                    errCell2 = char(errCell2);
                    if strcmpi(errCell2, '""')
                        errCell2 = '';
                    end
                end
                % increase loop counter
                cnt = cnt + 1;
                % end of error buffer reached?
                if isempty(errCell2)
                    readNextError = false;
                else
                    errCell{cnt} = errCell2;
                end
            end
            % now shrink errCell cell array
            firstEmptyCell = find(cellfun('isempty', errCell), 1);
            if ~isempty(firstEmptyCell)
                if firstEmptyCell > 1
                    errCell = errCell(1:firstEmptyCell-1);
                else
                    errCell = {};
                end
            end
            % optionally display results
            if obj.ShowMessages
                if ~isempty(errCell)
                    disp('Scope error list');
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
    
    % ------- internal aux functions for main scope macros ----------------
    methods (Access = protected)
        
        function result = getAmplMinMax(obj, channel)
            % request measurement values for min & max amplitude
            % and indicators when signal is clipped
            % 
            % channel as char array: either 
            % 'ch1' or '1' for channel 1
            % 'ch2' or '2' for channel 2
            
            % init output
            result.status      = NaN;
            result.max         = NaN;
            result.min         = NaN;
            result.unit        = 'V';
            result.clippingpos = NaN;
            result.clippingneg = NaN;
            result.channel     = '';
            result.errorid     = [];
            result.errormsg    = '';
            
            if ~ischar(channel)
                channel = '';
            end
            switch lower(channel)
                case {'1', 'ch1'}
                    channel = 'ch1';
                case {'2', 'ch2'}
                    channel = 'ch2';
                otherwise
                    disp(['Scope: Error - ''autoscale'' invalid ' ...
                        'internal parameter. Skip and continue.']);
                    result.status = -1;
                    return
            end
            result.channel = channel;
            
            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------
            
            % clear status register to check for new execution errors 
            % while measurement
            obj.VisaIFobj.write('*CLS');
            
            % setup measurement (no read back and verify)
            obj.VisaIFobj.write(['measurement:immed:source ' channel]);
            
            obj.VisaIFobj.write('measurement:immed:type maximum');
            obj.VisaIFobj.write('*wai'); % wait for valid data
            % fetch measurement result
            [value, statQuery] = obj.VisaIFobj.query('measurement:immed:value?');
            if statQuery ~= 0
                result.status = -1;
                return  % exit
            else
                result.max  = str2double(char(value));
                if result.max > 1e37
                    % scope reports max value when channel is not active
                    result.max = NaN;
                end
            end
            
            obj.VisaIFobj.write('measurement:immed:type minimum');
            obj.VisaIFobj.write('*wai'); % wait for valid data
            % fetch measurement result
            [value, statQuery] = obj.VisaIFobj.query('measurement:immed:value?');
            if statQuery ~= 0
                result.status = -1;
                result.min    = NaN;
                return  % exit
            else
                result.min  = str2double(char(value));
                if result.min > 1e37
                    % scope reports max value when channel is not active
                    result.min = NaN;
                end
            end
            
            % any errors pending?
            [value, statQuery] = obj.VisaIFobj.query('*esr?');
            if statQuery ~= 0
                result.status = -1;
                return % exit
            else
                % convert to number
                ESReg   = str2double(char(value));
            end
            
            % read error message queue
            if ESReg > 0
                % yes: pending errors or warnings
                % how many messages? ==> should be 0, 1 or 2 because ESR
                % was cleared before measurement
                NumOfMsg = str2double(char(obj.VisaIFobj.query('evqty?')));
                result.errorid = NaN(1, NumOfMsg);
                %
                for cnt = 1 : NumOfMsg
                    result.errorid(cnt) = ...
                        str2double(char(obj.VisaIFobj.query('event?')));
                end
            end
            
            % evaluate error/warning messages (read programmer manual)
            idx = 1;
            while idx <= length(result.errorid)
                switch result.errorid(idx)
                    case {547, 2227}
                        % positive & negative clipping
                        result.clippingpos  = 1;
                        result.clippingneg  = 1;
                        result.errorid(idx) = []; % delete error
                    case {548, 2228}
                        % positive clipping
                        result.clippingpos  = 1;
                        result.errorid(idx) = []; % delete error
                    case {549, 2229}
                        % negative clipping
                        result.clippingneg  = 1;
                        result.errorid(idx) = []; % delete error
                    case 2225
                        % no waveform to measure (channel is off)
                        idx = idx + 1;
                        result.errormsg  = ['no waveform to measure ' ...
                            '(channel is off)'];
                    otherwise
                        % all other error/warning messages ==> extend later?
                        idx = idx + 1;
                        result.errormsg  = ['unknown error (read ' ...
                            'programmer manual)'];
                end
            end
            
            if isempty(result.errorid)
                result.errorid = [];
                % set remaining fields to zero
                if isnan(result.clippingpos)
                    result.clippingpos = 0;
                end
                if isnan(result.clippingneg)
                    result.clippingneg = 0;
                end
            else
                result.errorid = unique(result.errorid);
            end
            
            % set final status
            if isnan(result.status)
                % no error so far ==> set to 0 (fine)
                result.status = 0;
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