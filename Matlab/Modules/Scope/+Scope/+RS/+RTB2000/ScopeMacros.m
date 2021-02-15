classdef ScopeMacros < handle
    % ToDo documentation
    %
    %
    % for Scope: Rohde&Schwarz RTB2000 series
    % (for R&S firmware: 02.300 ==> see myScope.identify)
    
    properties(Constant = true)
        MacrosVersion = '1.2.0';      % release version
        MacrosDate    = '2021-02-15'; % release date
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
            % clear status (event registers and error queue)
            if obj.VisaIFobj.write('*CLS')
                status = -1;
            end
            
            % close possibly open message box
            if obj.VisaIFobj.write('DISPLAY:DIALOG:CLOSE')
                status = -1;
            end
            
            % swap order of bytes ==> for download of waveform data in
            % binary form (least-significant byte (LSB) of each data
            % point is first)
            if obj.VisaIFobj.write('FORMAT:BORDER LSBfirst')
                status = -1;
            end
            
            % status:operation bit 3 (wait for trigger) is going low when
            % a trigger event occurs and is going high again afterwards
            % ==> capture trigger event in status:operation:event register
            %
            % cleared at power-on, unchanged by reset (*RST)
            if obj.VisaIFobj.write('STATUS:OPERATION:NTRANSITION 8')
                status = -1;
            end
            if obj.VisaIFobj.write('STATUS:OPERATION:PTRANSITION 0')
                status = -1;
            end
            
            % Sets the number of waveforms acquired with RUNSingle
            % reset (*RST) resets value to 1
            if obj.VisaIFobj.write('ACQUIRE:NSINGLE:COUNT 1')
                status = -1;
            end
            
            % enable fast segmentation
            if obj.VisaIFobj.write('ACQuire:SEGMented:STATe ON')
                status = -1;
            end
            
            % selects range of samples that will be returned to maximum
            if obj.VisaIFobj.write('CHANnel:DATA:POINts MAXimum')
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
            % close possibly open message box
            if obj.VisaIFobj.write('DISPLAY:DIALOG:CLOSE')
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
            
            % close possibly open message box
            if obj.VisaIFobj.write('DISPLAY:DIALOG:CLOSE')
                status = -1;
            end
            
            % swap order of bytes ==> for download of waveform data in
            % binary form (least-significant byte (LSB) of each data
            % point is first)
            if obj.VisaIFobj.write('FORMAT:BORDER LSBfirst')
                status = -1;
            end
            
            % enable fast segmentation
            if obj.VisaIFobj.write('ACQuire:SEGMented:STATe ON')
                status = -1;
            end
            
            % selects range of samples that will be returned to maximum
            if obj.VisaIFobj.write('CHANnel:DATA:POINts MAXimum')
                status = -1;
            end
            
            % XXX
            %if obj.VisaIFobj.write('XXX')
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
        
    end
    
    % ------- main scope macros -------------------------------------------
    methods
        
        function status = clear(obj)
            % clear status at scope
            status = obj.VisaIFobj.write('*CLS');
        end
        
        function status = lock(obj)
            % lock all buttons at scope
            
            %status = obj.VisaIFobj.write('SYSTEM:REMOTE'); % not available
            [~, status] = obj.VisaIFobj.query('*OPC?'); % same result
            
            if obj.ShowMessages
                disp(['Scope Message - Method ''lock'' is not ' ...
                    'supported for ']);
                disp(['      ' obj.VisaIFobj.Vendor '/' ...
                    obj.VisaIFobj.Product ...
                    ' -->  Scope will be automatically locked ' ...
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
                ' -->  Press button ''Local'' at Scope device (touchscreen)']);
        end
        
        function status = acqRun(obj)
            % start data acquisitions at scope
            
            status = obj.VisaIFobj.write('ACQUIRE:STATE RUN');
            %status = obj.VisaIFobj.write('RUN'); % RUNcontinous
        end
        
        function status = acqStop(obj)
            % stop data acquisitions at scope
            
            % stop when not triggered => several waveforms visible at screen
            status = obj.VisaIFobj.write('ACQUIRE:STATE STOP');
            %status = obj.VisaIFobj.write('STOP'); % break (the hard way)
            
            % alternative solution: expects setting 'ACQUIRE:NSINGLE:COUNT 1'
            % (default setting and possible to set in reset & runafteropen)
            %obj.VisaIFobj.write('ACQUIRE:NSINGLE:COUNT 1')
            %obj.VisaIFobj.write('RUNSingle')
        end
        
        function status = autoset(obj)
            % performs an autoset process for analog channels: analyzes the
            % enabled analog channel signals, and adjusts the horizontal,
            % vertical, and trigger settings to display stable waveforms
            
            % init output
            status = NaN;
            
            % actual autoset command
            if obj.VisaIFobj.write('AUTOSCALE')
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
                                case {'', '1', '2', '3', '4'}
                                    % do nothing
                                otherwise
                                    channels{cnt} = '';
                                    disp(['Scope: Warning - ' ...
                                        '''configureInput'' invalid ' ...
                                        'channel (allowed are 1 .. 4) ' ...
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
                                    coupling = 'ACL';
                                case 'dc'
                                    coupling = 'DCL';
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
                                case {'1', '10', '20', '50', '100', '200', '500', '1000'}
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
                                    bwLimit = 'FULL';
                                case {'on',  '1'}
                                    bwLimit = 'B20';
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
                                    invert = 'NORM';
                                case {'on',  '1'}
                                    invert = 'INV';
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
                            elseif skew > 500e-9
                                skew = 500e-9;   % max.  500 ns
                                if obj.ShowMessages
                                    disp('  - skew         : 500e-9 (coerced)');
                                end
                            elseif skew < -500e-9
                                skew = -500e-9;  % min. -500 ns
                                if obj.ShowMessages
                                    disp('  - skew         : -500e-9 (coerced)');
                                end
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
                
                % 'coupling'         : 'DC', 'AC', 'GND'
                if ~isempty(coupling)
                    % set parameter
                    obj.VisaIFobj.write(['CHANnel' channel ':COUPling ' coupling]);
                    % read and verify
                    response = obj.VisaIFobj.query(['CHANnel' channel ':COUPling?']);
                    if ~strcmpi(coupling, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'coupling parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'inputDiv', 'probe': 1, 10, 20, 50, 100, 200, 500, 1000
                if ~isempty(inputDiv)
                    % set parameter
                    obj.VisaIFobj.write(['PROBe' channel ...
                        ':SETup:ATTenuation:MANual ' inputDiv]);
                    % read and verify
                    response = obj.VisaIFobj.query(['PROBe' channel ...
                        ':SETup:ATTenuation:MANual?']);
                    if str2double(inputDiv) ~= str2double(char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'inputDiv parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'unit'             : 'V' or 'A'
                if ~isempty(unit)
                    % set parameter
                    obj.VisaIFobj.write(['PROBe' channel ...
                        ':SETup:ATTenuation:UNIT ' unit]);
                    % read and verify
                    response = obj.VisaIFobj.query(['PROBe' channel ...
                        ':SETup:ATTenuation:UNIT?']);
                    if ~strcmpi(unit, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'unit parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'bwLimit'          : 'off', 'on'
                if ~isempty(bwLimit)
                    % set parameter
                    obj.VisaIFobj.write(['CHANnel' channel ...
                        ':BANDwidth ' bwLimit]);
                    % read and verify
                    response = obj.VisaIFobj.query(['CHANnel' channel ...
                        ':bandwidth?']);
                    if ~strcmpi(bwLimit, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'bwLimit parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'invert'           : 'off', 'on'
                if ~isempty(invert)
                    % set parameter
                    obj.VisaIFobj.write(['CHANnel' channel ...
                        ':POLarity ' invert]);
                    % read and verify
                    response = obj.VisaIFobj.query(['CHANnel' channel ...
                        ':POLarity?']);
                    if ~strcmpi(invert, char(response))
                        disp(['Scope: Warning - ''configureInput'' ' ...
                            'invert parameter could not be set correctly.']);
                        status = -1;
                    end
                end
                
                % 'skew'           : (-500e-9 ... 500e-9 = +/- 500ns)
                if ~isempty(skew)
                    % format (round) numeric value
                    skewString = num2str(skew, '%1.2e');
                    skew       = str2double(skewString);
                    % set parameter
                    obj.VisaIFobj.write(['CHANnel' channel ...
                        ':SKEW ' skewString]);
                    % read and verify
                    response   = obj.VisaIFobj.query(['CHANnel' channel ...
                        ':SKEW?']);
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
                    obj.VisaIFobj.write(['CHANnel' channel ...
                        ':STATe ' trace]);
                    % read and verify
                    response = obj.VisaIFobj.query(['CHANnel' channel ...
                        ':STATe?']);
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
                    obj.VisaIFobj.write(['CHANnel' channel ...
                        ':SCALe ' vDivString]);
                    % read and verify
                    response   = obj.VisaIFobj.query(['CHANnel' channel ...
                        ':SCALe?']);
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
                    response = obj.VisaIFobj.query(['CHANnel' channel ...
                        ':SCALe?']);
                    vDiv     = str2double(char(response));
                end
                
                % 'vOffset'        : positive double in V
                if ~isempty(vOffset)
                    % set position parameter to zero 
                    obj.VisaIFobj.write(['CHANnel' channel ...
                        ':POSition 0']);
                    % format (round) numeric value
                    vOffString = num2str(vOffset, '%1.2e');
                    vOffset    = str2double(vOffString);
                    % set parameter
                    obj.VisaIFobj.write(['CHANnel' channel ...
                        ':OFFSet ' vOffString]);
                    % read and verify
                    response   = obj.VisaIFobj.query(['CHANnel' channel ...
                        ':OFFSet?']);
                    vOffActual = str2double(char(response));
                    if abs(vOffset - vOffActual) > vDiv*0.5
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
            maxLength   = [];
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
                        if ~isempty(paramValue)
                            maxLength = round(abs(str2double(paramValue)));
                            coerced   = false;
                            if isnan(maxLength) || isinf(maxLength)
                                disp(['Scope: Warning - ''configureAcquisition'' ' ...
                                    'maxLength parameter value is invalid ' ...
                                    '--> coerce and continue']);
                                maxLength = 100e3;
                                coerced   = true;
                            end
                            switch maxLength
                                case {1e4, 2e4, 5e4, 1e5, 2e5, 5e5, ...
                                        1e6, 2e6, 5e6, 1e7, 2e7}
                                    % do nothing
                                otherwise
                                    coerced   = true;
                                    if     maxLength < 1e4
                                        maxLength = 1e4;
                                    elseif maxLength < 2e4
                                        maxLength = 2e4;
                                    elseif maxLength < 5e4
                                        maxLength = 5e4;
                                    elseif maxLength < 1e5
                                        maxLength = 1e5;
                                    elseif maxLength < 2e5
                                        maxLength = 2e5;
                                    elseif maxLength < 5e5
                                        maxLength = 5e5;
                                    elseif maxLength < 1e6
                                        maxLength = 1e6;
                                    elseif maxLength < 2e6
                                        maxLength = 2e6;
                                    elseif maxLength < 5e6
                                        maxLength = 5e6;
                                    elseif maxLength < 1e7
                                        maxLength = 1e7;
                                    else
                                        maxLength = 2e7;
                                    end
                            end
                            if obj.ShowMessages && coerced
                                disp(['  - maxLength    : ' ...
                                    num2str(maxLength, '%d') ' (coerced)']);
                            end
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
                            elseif numAverage < 2
                                numAverage = 2;
                                coerced    = true;
                            elseif numAverage > 1e5
                                numAverage = 1e5;
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
            
            % sampleRate
            if ~isempty(sampleRate)
                disp(['Scope: WARNING - sampleRate parameter will be ' ...
                    'ignored. Please specify tDiv only.']);
            end
            
            % tDiv        : numeric value in s
            %               [1e-9 ... 5e2]
            if ~isempty(tDiv)
                % format (round) numeric value
                tDivString = num2str(tDiv, '%1.2e');
                tDiv       = str2double(tDivString);
                % set parameter
                obj.VisaIFobj.write(['TIMebase:SCALe ' tDivString]);
                % read and verify
                response = obj.VisaIFobj.query('TIMebase:SCALe?');
                tDivActual = str2double(char(response));
                if (tDiv/tDivActual) < 0.95 || (tDiv/tDivActual) > 1.05
                    disp(['Scope: WARNING - ''configureAcquisition'' ' ...
                        'tDiv parameter could not be set correctly. ' ...
                        'Check limits. ']);
                end
            end
            
            % maxLength : [10e3 .. 20e6] in MSa
            if ~isempty(maxLength)
                % set parameter
                obj.VisaIFobj.write(['ACQuire:POINts:VALue ' ...
                    num2str(maxLength, '%g')]);
                % read and verify
                response = obj.VisaIFobj.query('ACQuire:POINts:VALue?');
                actualVal = str2double(char(response));
                if isnan(actualVal)
                    disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                        'mode parameter could not be set correctly.']);
                    status = -1;
                elseif maxLength == 20e6 && actualVal == 10e6
                    if obj.ShowMessages
                        disp('  - maxLength    : 10000000 (coerced)');
                    end
                elseif actualVal >= maxLength
                    % fine
                else
                    disp(['Scope: Warning - ''configureAcquisition'' ' ...
                        'mode parameter could not be set correctly.']);
                    status = -1;
                end
            end
            
            % mode     : 'sample', 'peakdetect', 'average'
            if ~isempty(mode)
                % disable high resolution mode first
                obj.VisaIFobj.write('ACQuire:HRESolution OFF');
                
                switch mode
                    case 'sample'
                        typeParam = 'REFResh';
                        typeResp  = 'REFR';
                        peakParam = 'OFF';
                        peakResp  = 'OFF';
                    case 'peakdetect'
                        typeParam = 'REFResh';
                        typeResp  = 'REFR';
                        peakParam = 'AUTO';
                        peakResp  = 'AUTO';
                    case 'average'
                        typeParam = 'AVERage';
                        typeResp  = 'AVER';
                        peakParam = 'OFF';
                        peakResp  = 'OFF';
                    otherwise
                end
                
                % set parameter (1)
                obj.VisaIFobj.write(['ACQuire:TYPE ' typeParam]);
                % read and verify
                response = obj.VisaIFobj.query('ACQuire:TYPE?');
                if ~strcmpi(typeResp, char(response))
                    disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                        'mode parameter could not be set correctly.']);
                    status = -1;
                end
                
                % set parameter (2)
                obj.VisaIFobj.write(['ACQuire:PEAKdetect ' peakParam]);
                % read and verify
                response = obj.VisaIFobj.query('ACQuire:PEAKdetect?');
                if ~strcmpi(peakResp, char(response))
                    disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                        'mode parameter could not be set correctly.']);
                    status = -1;
                end
            end
            
            % numAverage  : 2 .. 100e3
            if ~isempty(numAverage)
                % set parameter
                obj.VisaIFobj.write(['ACQuire:AVERage:COUNt ' ...
                    num2str(numAverage, '%g')]);
                % read and verify
                response  = obj.VisaIFobj.query('ACQuire:AVERage:COUNt?');
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
                                mode = 'single';
                            case 'normal'
                                mode = 'normal';
                            case 'auto'
                                mode = 'auto';
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
                                type = 'pos';
                            case 'fallingedge'
                                type = 'neg';
                            otherwise
                                type = '';
                                disp(['Scope: Warning - ''configureTrigger'' ' ...
                                    'type parameter value is unknown ' ...
                                    '--> ignore and continue']);
                        end
                    case 'source'
                        source = lower(paramValue);
                        switch source
                            case {'', 'ch1', 'ch2', 'ch3', 'ch4', 'ext'}
                                % all fine
                            case 'ext5'
                                source = 'ext';
                                if obj.ShowMessages
                                    disp('  - source       : ext (coerced)');
                                end
                            case 'ac-line'
                                source = 'line';
                            otherwise
                                source = '';
                                disp(['Scope: Warning - ''configureTrigger'' ' ...
                                    'source parameter value is unknown ' ...
                                    '--> ignore and continue']);
                        end
                    case 'coupling'
                        coupling = lower(paramValue);
                        switch coupling
                            case {'', 'ac', 'dc'}
                                % all fine
                            case {'lfreject', 'lfrej'}
                                coupling = 'lfr'; % AC with 15 kHz high pass 
                            case {'noisereject', 'noiserej'}
                                coupling = 'addLP100MHzFilter';
                            case {'hfreject', 'hfrej'}
                                coupling = 'addLP5kHzFilter';
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
                if strcmpi(mode, 'auto')
                    % set parameter
                    obj.VisaIFobj.write('TRIGger:A:MODE AUTO');
                    % read and verify
                    response = obj.VisaIFobj.query('TRIGger:A:MODE?');
                    if ~strcmpi('auto', char(response))
                        disp(['Scope: Error - ''configureTrigger'' ' ...
                            'mode parameter could not be set correctly.']);
                        status = -1;
                    end
                    % continous acquisitions
                    obj.VisaIFobj.write('RUN');
                else
                    % set parameter
                    obj.VisaIFobj.write('TRIGger:A:MODE NORMal');
                    % read and verify
                    response = obj.VisaIFobj.query('TRIGger:A:MODE?');
                    if ~strcmpi('norm', char(response))
                        disp(['Scope: Error - ''configureTrigger'' ' ...
                            'mode parameter could not be set correctly.']);
                        status = -1;
                    end
                    if strcmpi(mode, 'single')
                        % single acquisition (see ACQuire:NSINgle:COUNt)
                        obj.VisaIFobj.write('SINGle');
                    else
                        % continous acquisitions
                        obj.VisaIFobj.write('RUN');
                    end
                end
            end
            
            % source   : 'ch1..4', 'ext', 'line'
            if ~isempty(source)
                if strcmpi(source, 'line')
                    % set parameter
                    obj.VisaIFobj.write(['TRIGger:A:TYPE ' source]);
                    % read and verify
                    response = obj.VisaIFobj.query('TRIGger:A:TYPE?');
                    if ~strcmpi(source, char(response))
                        disp(['Scope: Error - ''configureTrigger'' ' ...
                            'source parameter could not be set correctly.']);
                        status = -1;
                    end
                else % 'ch1..4' or 'ext'
                    obj.VisaIFobj.write('TRIGger:A:TYPE EDGE');
                    % set parameter
                    obj.VisaIFobj.write(['TRIGger:A:SOURce ' source]);
                    % read and verify
                    response = obj.VisaIFobj.query('TRIGger:A:SOURce?');
                    if ~strcmpi(source, char(response))
                        disp(['Scope: Error - ''configureTrigger'' ' ...
                            'source parameter could not be set correctly.']);
                        status = -1;
                    end
                end
            else
                % read back trigger source ==> required for level
                response = obj.VisaIFobj.query('TRIGger:A:SOURce?');
                source   = lower(char(response));
                
            end
            switch source
                case 'ch1', source = '1';
                case 'ch2', source = '2';
                case 'ch3', source = '3';
                case 'ch4', source = '4';
                case 'ext', source = '5';
                otherwise , source = '';
            end
            
            % type      : rising or falling edge
            if ~isempty(type)
                if ~isempty(source)
                    obj.VisaIFobj.write('TRIGger:A:TYPE EDGE');
                    % set parameter
                    obj.VisaIFobj.write(['TRIGger:A:EDGE:SLOPe ' type]);
                    % read and verify
                    response = obj.VisaIFobj.query('TRIGger:A:EDGE:SLOPe?');
                    if ~strcmpi(type, char(response))
                        disp(['Scope: Error - ''configureTrigger'' ' ...
                            'type parameter could not be set correctly.']);
                        status = -1;
                    end
                else
                    disp(['Scope: Warning - ''configureTrigger'' ' ...
                        'ignore type parameter. Specify trigger source.']);
                end
            end
            
            % coupling
            if ~isempty(coupling)
                if ~isempty(source)
                    obj.VisaIFobj.write('TRIGger:A:TYPE EDGE');
                    switch coupling
                        case {'dc', 'ac', 'lfr'}
                            % set parameter
                            obj.VisaIFobj.write(['TRIGger:A:EDGE:COUPling ' ...
                                coupling]);
                            % read and verify
                            response = obj.VisaIFobj.query( ...
                                'TRIGger:A:EDGE:COUPling?');
                            if ~strcmpi(coupling, char(response))
                                disp(['Scope: Error - ''configureTrigger'' ' ...
                                    'coupling parameter could not be set ' ...
                                    'correctly.']);
                                status = -1;
                            end
                        otherwise
                            % when LFReject then change to AC
                            response = obj.VisaIFobj.query( ...
                                'TRIGger:A:EDGE:COUPling?');
                            if strcmpi('LFR', char(response))
                                obj.VisaIFobj.write( ...
                                    'TRIGger:A:EDGE:COUPling AC');
                            end
                    end
                    
                    switch coupling
                        case 'addLP100MHzFilter'
                            obj.VisaIFobj.write( ...
                                'TRIGger:A:EDGE:FILTer:NREJect 1');
                        case 'addLP5kHzFilter'
                            obj.VisaIFobj.write( ...
                                'TRIGger:A:EDGE:FILTer:HFReject 1');
                        otherwise
                            obj.VisaIFobj.write( ...
                                'TRIGger:A:EDGE:FILTer:NREJect 0');
                            obj.VisaIFobj.write( ...
                                'TRIGger:A:EDGE:FILTer:HFReject 0');
                    end
                else
                    disp(['Scope: Warning - ''configureTrigger'' ' ...
                        'ignore coupling parameter. Specify trigger source.']);
                end
            end
            
            % level    : double, in V; NaN for set level to 50%
            if isnan(level)
                % set trigger level to 50% of input signal
                obj.VisaIFobj.opc;
                pause(1);
                obj.VisaIFobj.write('TRIGger:A:FINDlevel');
                obj.VisaIFobj.opc;
            elseif ~isempty(level)
                if ~isempty(source)
                    % format (round) numeric value
                    levelString = num2str(level, '%1.1e');
                    level       = str2double(levelString);
                    % set parameter
                    obj.VisaIFobj.write(['TRIGger:A:LEVel' source ...
                        ':VALue ' levelString]);
                    % read and verify
                    response    = obj.VisaIFobj.query(['TRIGger:A:LEVel' ...
                        source ':VALue?']);
                    levelActual = str2double(char(response));
                    if abs(level - levelActual) > 1 % !!! 
                        % sensible threshold depends on vDiv of trigger source
                        disp(['Scope: Warning - ''configureTrigger'' ' ...
                            'level parameter could not be set correctly. ' ...
                            'Check limits.']);
                    end
                else
                    disp(['Scope: Warning - ''configureTrigger'' ' ...
                        'ignore level parameter. Specify trigger source.']);
                end
            end
            
            % delay    : double, in s
            if ~isempty(delay)
                % format (round) numeric value
                delayString = num2str(delay, '%1.2e');
                delay       = str2double(delayString);
                % set parameter
                obj.VisaIFobj.write(['TIMebase:POSition ' delayString]);
                % read and verify
                response    = obj.VisaIFobj.query('TIMebase:POSition?');
                delayActual = str2double(char(response));
                if abs(delay - delayActual) > 1e-3 % !!!
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
                            if zoomFactor < 1 || isnan(zoomFactor)
                                zoomFactor = 1; % deactivates zoom
                                if obj.ShowMessages
                                    disp('  - zoomFactor   : 1 (coerced)');
                                end
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
            
            if ~isempty(zoomFactor)
                % zoomFactor will be rounded by Scope to nearest value
                
                if zoomFactor == 1
                    % disable zoom window
                    obj.VisaIFobj.write('TIMebase:ZOOM:STATe 0');
                    % verify
                    response = obj.VisaIFobj.query('TIMebase:ZOOM:STATe?');
                    if ~strcmpi('0', char(response))
                        disp(['Scope: ERROR - ''configureZoom'' ' ...
                            'disabling zoom window failed.']);
                        status = -1;
                    end
                else
                    % enable zoom window
                    obj.VisaIFobj.write('TIMebase:ZOOM:STATe 1');
                    % readback and verify
                    response = obj.VisaIFobj.query('TIMebase:ZOOM:STATe?');
                    if ~strcmpi('1', char(response))
                        disp(['Scope: ERROR - ''configureZoom'' ' ...
                            'enabling zoom window failed.']);
                        status = -1;
                        return; % exit
                    end
                    
                    % 1st step: read timebase of main window (tDiv)
                    response = obj.VisaIFobj.query('TIMebase:SCALe?');
                    timebase = str2double(char(response));
                    if isnan(timebase)
                        disp(['Scope: ERROR - ''configureZoom'' ' ...
                            'cannot set zoomFactor.']);
                        status = -1;
                        return; % exit
                    end
                    
                    % 2nd step: set timebase of zoom window (> timebase)
                    zoomTimebase = timebase / zoomFactor;
                    obj.VisaIFobj.write(['TIMebase:ZOOM:SCALe ' ...
                        num2str(zoomTimebase, '%1.1e')]);
                    % readback and verify
                    response = obj.VisaIFobj.query('TIMebase:ZOOM:SCALe?');
                    response = str2double(char(response));
                    if isnan(response)
                        disp(['Scope: ERROR - ''configureZoom'' ' ...
                            'cannot set zoomFactor.']);
                        status = -1;
                        return; % exit
                    elseif response > timebase
                        disp(['Scope: Warning - ''configureZoom'' ' ...
                            'set zoomFactor failed. Check settings.']);
                        status = -1;
                    end
                end
            end
            
            if ~isempty(zoomPosition)
                obj.VisaIFobj.write(['TIMebase:ZOOM:TIME ' ...
                    num2str(zoomPosition, '%1.1e')]);
                % readback and verify
                response = obj.VisaIFobj.query('TIMebase:ZOOM:TIME?');
                response = str2double(char(response));
                if isnan(response)
                    disp(['Scope: ERROR - ''configureZoom'' ' ...
                        'cannot set zoomPosition.']);
                    status = -1;
                end
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
            %   'channel'     : 1 .. 4
            
            % init output
            status = NaN;
            
            % initialize all supported parameters
            mode      = '';
            
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
                                case {'', '1', '2', '3', '4'}
                                    % do nothing
                                otherwise
                                    channels{cnt} = '';
                                    disp(['Scope: Warning - ' ...
                                        '''autoscale'' invalid ' ...
                                        'channel (allowed are 1 .. 4) ' ...
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
            % > 1  ATTENTION: ADC will be overloaded
            % 1.00 means full ADC-range and display range (-5 ..+5) vDiv
            % sensible range 0.5 .. 0.9
            verticalScalingFactor = obj.AutoscaleVerticalScalingFactor;
            
            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------
            
            % define default when channel parameter is missing
            if isempty(channels)
                channels = {'1', '2', '3', '4'};
                if obj.ShowMessages
                    disp('  - channel      : 1, 2, 3, 4 (coerced)');
                end
            end
            
            if ~isempty(mode)
                obj.VisaIFobj.write('MEASurement:TIMeout:AUTO ON');
                % get time span for acquisition
                numPoints = obj.VisaIFobj.query('ACQuire:POINts?');
                sRate     = obj.VisaIFobj.query('ACQuire:SRATe?');
                spanTime  = str2double(char(numPoints)) / ...
                    str2double(char(sRate));
                if isnan(spanTime)
                    spanTime = 1;
                    status   = -2;
                end
            end
            
            % vertical scaling: adjust vDiv, vOffset
            if strcmpi(mode, 'vertical') || strcmpi(mode, 'both')
                for cnt = 1:length(channels)
                    % check if trace is on or off
                    traceOn = obj.VisaIFobj.query( ...
                        ['CHANnel' channels{cnt} ':STATe?']);
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
                        % measurement place 3 for vMin
                        obj.VisaIFobj.write('MEASurement3:ENABle 1');
                        obj.VisaIFobj.write('MEASurement3:MAIN LPEakvalue');
                        obj.VisaIFobj.write(['MEASurement3:SOURce CH' ...
                            channels{cnt}]);
                        % measurement place 4 for vMax
                        obj.VisaIFobj.write('MEASurement4:ENABle 1');
                        obj.VisaIFobj.write('MEASurement4:MAIN UPEakvalue');
                        obj.VisaIFobj.write(['MEASurement4:SOURce CH' ...
                            channels{cnt}]);
                        while loopcnt < maxcnt
                            % a certain settling time is required
                            pause(0.3 + spanTime);
                            
                            % measure min and max voltage
                            vMin = obj.VisaIFobj.query( ...
                                'MEASurement3:RESult:ACTual?');
                            vMin = str2double(char(vMin));
                            vMax = obj.VisaIFobj.query( ...
                                'MEASurement4:RESult:ACTual?');
                            vMax = str2double(char(vMax));
                            if isnan(vMin) || isnan(vMax)
                                status  = -4;
                                break;
                            elseif abs(vMin) > 1e36
                                vMin = NaN;          % invalid measurement
                            elseif abs(vMax) > 1e36
                                vMax = NaN;          % invalid measurement
                            end
                            % ADC is clipped? RTB manual (10v00, page 573)
                            adcState = obj.VisaIFobj.query( ...
                                'STATus:QUEStionable:ADCState:CONDition?');
                            adcState = abs(str2double(char(adcState)));
                            if isnan(adcState)
                                status  = -5;
                                break;
                            else
                                % Bit 1 (LSB): channel 1 positive clipping
                                % Bit 2      : channel 1 negative clipping
                                % ...
                                % Bit 8 (MSB): channel 4 negative clipping
                                adcState = dec2binvec(adcState, 8);
                                adcMax   = adcState( ...
                                    str2double(channels{cnt})*2 -1);
                                adcMin   = adcState( ...
                                    str2double(channels{cnt})*2 -0);
                            end
                            
                            % estimate voltage scaling (gain)
                            % 10 vertical divs at display
                            vDiv = (vMax - vMin) / 10;
                            if isnan(vDiv)
                                % request current vDiv setting
                                vDiv = obj.VisaIFobj.query( ...
                                    ['CHANnel' channels{cnt} ':SCALe?']);
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
                                    ['CHANnel' channels{cnt} ':OFFSet?']);
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
                                vOffset = vOffset + 4* vDiv;
                                vDiv    = vDiv / 0.5;
                            elseif adcMin
                                % negative clipping: scale down
                                vOffset = vOffset - 4* vDiv;
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
                trigSrc = obj.VisaIFobj.query('TRIGger:A:SOURce?');
                trigSrc = upper(char(trigSrc));
                switch trigSrc
                    case {'CH1', 'CH2', 'CH3', 'CH4'}
                        % measurement place 1 for frequency
                        obj.VisaIFobj.write('MEASurement1:ENABle 1');
                        obj.VisaIFobj.write('MEASurement1:MAIN FREQuency');
                        obj.VisaIFobj.write(['MEASurement1:SOURce ' trigSrc]);
                        % a certain settling time is required
                        pause(0.3 + spanTime);
                        % measure frequency
                        freq = obj.VisaIFobj.query( ...
                            'MEASurement1:RESult:ACTual?');
                        freq = str2double(char(freq));
                        if abs(freq) > 1e36
                            freq = NaN;          % invalid measurement
                        end
                        
                        if ~isnan(freq)
                            % adjust tDiv parameter
                            % calculate sensible tDiv parameter (12*tDiv@screen)
                            tDiv = numOfSignalPeriods / (12*freq);
                            
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
            % make a screenshot of scope display (BMP- , PNG- or GIF-file)
            %   'fileName' : file name with optional extension
            %                optional, default is './RS_Scope_RTB2000.png'
            %   'darkMode' : on/off, dark or white background color
            %                optional, default is 'off', 0, false
            
            % init output
            status = NaN;
            
            % configuration and default values
            listOfSupportedFormats = {'.png', '.bmp', '.gif'};
            filename = './RS_Scope_RTB2000.png';
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
            obj.VisaIFobj.write(['hcopy:format ' fileFormat]);
            if darkmode
                obj.VisaIFobj.write('hcopy:color:scheme color');
            else
                obj.VisaIFobj.write('hcopy:color:scheme inverted');
            end
            
            % request actual binary screen shot data
            bitMapData = obj.VisaIFobj.query('hcopy:data?');
            
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
                                case {'', '1', '2', '3', '4'}
                                    % do nothing: all fine
                                otherwise
                                    channels{cnt} = '';
                                    disp(['Scope: WARNING - ' ...
                                        '''runMeasurement'' invalid ' ...
                                        'channel --> ignore and continue']);
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
                            case {'cycmean', 'cmean'}
                                parameter = 'CYCMean';
                            case 'mean'
                                parameter = 'MEAN';
                            case {'cycrms', 'crms'}
                                parameter = 'CYCRms';
                            case 'rms'
                                parameter = 'RMS';
                            case {'cycstddev', 'cycstd', 'cstddev', 'cstd'}
                                parameter = 'CYCStddev';
                            case {'stddev, std'}
                                parameter = 'STDDev';
                            case {'pk-pk', 'pkpk', 'pk2pk', 'peak'}
                                parameter = 'PEAK';
                            case {'minimum', 'min'}
                                parameter = 'LPEakvalue';
                            case {'maximum', 'max'}
                                parameter = 'UPEakvalue';
                            case {'high', 'top'}
                                parameter = 'HIGH';
                            case {'low', 'base'}
                                parameter = 'LOW';
                            case {'amplitude', 'amp'}
                                parameter = 'AMPLitude';
                            case {'posovershoot', 'povershoot', 'pover'}
                                parameter = 'POVershoot';
                                unit      = '%';
                            case {'negovershoot', 'novershoot', 'nover'}
                                parameter = 'NOVershoot';
                                unit      = '%';
                            case {'risetime', 'rise'}
                                parameter = 'RTIMe';
                                unit      = 's';
                            case {'falltime', 'fall'}
                                parameter = 'FTIMe';
                                unit      = 's';
                            case {'posslewrate', 'possr', 'srrise'}
                                parameter = 'SRRise';
                                unit      = 'V/s';
                            case {'negslewrate', 'negsr', 'srfall'}
                                parameter = 'SRFall';
                                unit      = 'V/s';
                            case {'poswidth', 'pwidth'}
                                parameter = 'PPWidth';
                                unit      = 's';
                            case {'negwidth', 'nwidth'}
                                parameter = 'NPWidth';
                                unit      = 's';
                            case {'dutycycle', 'dutycyc', 'dcycle', 'dcyc'}
                                parameter = 'PDCycle';
                                unit      = '%';
                            case 'phase'
                                parameter = 'PHASe';
                                unit      = 'deg';
                            case 'delay'
                                parameter = 'DELay';
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
                    disp('  ''cycstddev''');
                    disp('  ''stddev''');
                    disp('  ''pk-pk''');
                    disp('  ''minimum''');
                    disp('  ''maximum''');
                    disp('  ''high''');
                    disp('  ''low''');
                    disp('  ''amplitude''');
                    disp('  ''povershoot''');
                    disp('  ''novershoot''');
                    disp('  ''risetime''');
                    disp('  ''falltime''');
                    disp('  ''posslewrate''');
                    disp('  ''negslewrate''');
                    disp('  ''poswidth''');
                    disp('  ''negwidth''');
                    disp('  ''dutycycle''');
                    disp('  ''phase''');
                    disp('  ''delay''');
                    meas.status = -1;
                    return
                case {'phase', 'delay'}
                    if length(channels) ~= 2
                        disp(['Scope: ERROR ''runMeasurement'' ' ...
                            'two source channels have to be specified ' ...
                            'for phase or delay measurements ' ...
                            '--> skip and exit']);
                        meas.status = -1;
                        return
                    else
                        source    = ['CH' channels{1} ',CH' channels{2}];
                        measPlace = '2';
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
                        source    = ['CH' channels{1}];
                        if strcmpi(parameter, 'LPEakvalue')
                            measPlace = '3';
                        elseif strcmpi(parameter, 'UPEakvalue')
                            measPlace = '4';
                        else
                            measPlace = '1';
                        end
                    end
            end
            
            % copy to output
            meas.parameter = lower(parameter);
            meas.channel   = strjoin(channels, ', ');
            
            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------
            
            obj.VisaIFobj.write('MEASurement:TIMeout:AUTO ON');
            % get time span for acquisition
            numPoints = obj.VisaIFobj.query('ACQuire:POINts?');
            sRate     = obj.VisaIFobj.query('ACQuire:SRATe?');
            spanTime  = str2double(char(numPoints)) / ...
                str2double(char(sRate));
            if isnan(spanTime)
                spanTime    = 1;
                meas.status = -2;
            end
            
            % setup measurement
            obj.VisaIFobj.write(['MEASurement' measPlace ':ENABle 1']);
            obj.VisaIFobj.write(['MEASurement' measPlace ':MAIN ' parameter]);
            obj.VisaIFobj.write(['MEASurement' measPlace ':SOURce ' source]);
            
            % a certain settling time is required
            pause(0.3 + spanTime);
            
            % request measurement value
            value = obj.VisaIFobj.query( ...
                ['MEASurement' measPlace ':RESult:ACTual?']);
            value = str2double(char(value));
            if isnan(value)
                meas.status = -5;     % error   (negative status)
            elseif abs(value) > 1e36
                meas.status = 1;      % warning (positive status)
                value = NaN;          % invalid measurement
            end
            
            % copy to output
            meas.value = value;
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
                                case '3'
                                    channels{cnt} = 'CHANnel3';
                                case '4'
                                    channels{cnt} = 'CHANnel4';
                                case ''
                                    % do nothing
                                otherwise
                                    channels{cnt} = '';
                                    disp(['Scope: Warning - ' ...
                                        '''captureWaveForm'' invalid ' ...
                                        'channel (allowed are 1 .. 4) ' ...
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
                channels = {'CHANnel1', 'CHANnel2', 'CHANnel3', 'CHANnel4'};
                if obj.ShowMessages
                    disp('  - channel      : 1, 2, 3, 4 (coerced)');
                end
            end
            
            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------
            
            % loop over channels
            for cnt = 1 : length(channels)
                channel = channels{cnt};
                % ---------------------------------------------------------
                % read data header
                header = obj.VisaIFobj.query([channel ':DATA:HEADER?']);
                header = split(char(header), ',');
                if length(header) == 4
                    % response consists of 4 parts separated by commas
                    %   (1) xstart in s,
                    %   (2) xstop  in s,
                    %   (3) record length of the waveform in samples,
                    %   (4) number of values per sample interval
                    xstart  = str2double(header{1});
                    xstop   = str2double(header{2});
                    xlength = str2double(header{3});
                    xnovpsi = str2double(header{4});% 1 (norm.) or 2 (envelope)
                else
                    % logical error or data error
                    waveData.status = -10;
                    return; % exit
                end
                % ==> field (3) is zero when channel is disabled
                % ==> fields (1),(2) and (4) are identical for active ch.
                if xlength > 0
                    % fine ==> continue
                elseif xlength == 0
                    % 0   when channel is not active ==> next channel
                    continue;
                else
                    % NaN (or negative) when error
                    waveData.status = -11;
                    return; % exit
                end
                
                % ---------------------------------------------------------
                % read resolution in bits
                yRes = obj.VisaIFobj.query([channel ':DATA:YRESOLUTION?']);
                % yRes is 10..32 bits ==> set to either uint-16 or uint-32
                %   UINT,16 is sensible for all acq modes except averaging
                %   UINT,32 is relevant for average waveforms
                yRes = str2double(char(yRes));
                if yRes <= 16
                    % saves time when downloading longer waveforms
                    % max 20MSa (40MBytes, uint-16) ==> about 6.8s (47Mbit/s)
                    obj.VisaIFobj.write('FORMAT:DATA UINT,16');
                    uint16format = true;
                elseif yRes <= 32
                    % max 20MSa (80MBytes, uint-32 or real) ==> about 13.5s
                    obj.VisaIFobj.write('FORMAT:DATA UINT,32');
                    uint16format = false;
                else
                    % logical error or data error
                    waveData.status = -12;
                    return; % exit
                end
                
                % ---------------------------------------------------------
                % read further common meta information
                
                % read time of the first sample (should match xstart)
                xorigin = obj.VisaIFobj.query([channel ':DATA:XORIGIN?']);
                xorigin = str2double(char(xorigin));
                % read time between two adjacent samples
                xinc    = obj.VisaIFobj.query([channel ':DATA:XINCREMENT?']);
                xinc    = str2double(char(xinc));
                
                % read voltage value for binary value 0
                yorigin = obj.VisaIFobj.query([channel ':DATA:YORIGIN?']);
                yorigin = str2double(char(yorigin));
                % read voltage value per bit
                yinc    = obj.VisaIFobj.query([channel ':DATA:YINCREMENT?']);
                yinc    = str2double(char(yinc));
                
                % ---------------------------------------------------------
                % check all meta information and initialize output values
                if ~isnan(xstart) && ~isnan(xstop) && ~isnan(xlength) ...
                        && ~isnan(xnovpsi) && ~isnan(xorigin) && ...
                        ~isnan(xinc) && ~isnan(yorigin) && ~isnan(yinc)
                    if (abs(xstop - (xorigin+(xlength-1)*xinc)) > 0.1 * xinc) ...
                            || (abs(xstart - xorigin) > 0.1 * xinc)
                        % logical error or data error
                        waveData.status = -13;
                        return; % exit
                    end
                    % set sample time (identical for all active channels)
                    waveData.time       = xorigin + xinc * (0 : xlength-1);
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
                
                % read channel data
                data = obj.VisaIFobj.query([channel ':DATA?']);
                
                % check and extract header: e.g. #41000binarydata with 4 =
                % next 4 chars indicating number of bytes for actual data
                if length(data) < 4
                    % logical error or data error
                    waveData.status = -16;
                    return; % exit
                end
                headchar = char(data(1));
                headlen  = round(str2double(char(data(2))));
                if strcmpi(headchar, '#') && headlen >= 1
                    % fine and go on    (test negative for headlen = NaN)
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
                % convert data, requires setting 'FORMAT:BORDER LSBfirst'
                % (see 'runAfterOpen' and 'reset' macro)
                if uint16format
                    data = double(typecast(data, 'uint16'));
                else
                    data = double(typecast(data, 'uint32'));
                end
                % check and reformat
                if length(data) ~= xlength * xnovpsi
                    % logical error or data error
                    waveData.status = -19;
                    return; % exit
                elseif xnovpsi == 2 && floor(length(data)/2) == ...
                        ceil(length(data)/2)
                    %data = reshape(data, 2, []);
                    % chance to extend code for acq mode = envelope
                    % replace ':DATA' by ':DATA:ENVELOPE' in commands
                    % via cmdString with two options
                    % and store both rows of data
                    
                    % logical error or data error
                    waveData.status = -20;
                    return; % exit
                end
                
                % Sample value: Yn = yOrigin + (yIncrement * byteValuen)
                waveData.volt(cnt, :) = yorigin + yinc * data(1, :);
                
                
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
            [acqState, status] = obj.VisaIFobj.query('ACQUIRE:STATE?');
            %
            if status ~= 0
                % failure
                acqState = 'visa error. couldn''t read acquisition state';
            else
                % remap trigger state
                acqState = lower(char(acqState));
                switch acqState
                    case 'stop'
                        acqState = 'stopped (unfinished)';
                    case 'comp'   % complete
                        acqState = 'stopped (finished and completed)';
                    case 'bre'    % break
                        acqState = 'stopped (finished but interrupted)';
                    case 'run'
                        acqState = 'running';
                    otherwise, acqState = '';
                end
            end
        end
        
        function trigState = get.TriggerState(obj)
            % get trigger state ('waitfortrigger', 'triggered', '')
            
            % expected settings: ==> set in runAfterOpen method
            % 'STATus:OPERation:NTRansition 8'
            % 'STATus:OPERation:PTRansition 0'
            
            % event registers cleared after reading
            % trigger event register
            [respTriggered, stat1]   = ...
                obj.VisaIFobj.query('STATUS:OPERATION:EVENT?');
            % responding condition register (remain unchanged)
            [respWaitTrigger, stat2] = ...
                obj.VisaIFobj.query('STATUS:OPERATION:CONDITION?');
            
            statQuery = abs(stat1) + abs(stat2);
            
            if statQuery ~= 0
                trigState = 'visa error. couldn''t read trigger state';
            else
                Triggered   = str2double(char(respTriggered));
                if ~isnan(Triggered) && ~isinf(Triggered)
                    Triggered = dec2binvec(Triggered, 8);
                    Triggered = Triggered(1+3); % bit 3
                else
                    Triggered = false;
                end
                
                WaitTrigger = str2double(char(respWaitTrigger));
                if ~isnan(WaitTrigger) && ~isinf(WaitTrigger)
                    WaitTrigger = dec2binvec(WaitTrigger, 8);
                    WaitTrigger = WaitTrigger(1+3); % bit 3
                else
                    WaitTrigger = false;
                end
                
                if Triggered
                    trigState = 'triggered';
                elseif WaitTrigger
                    trigState = 'waitfortrigger';
                else
                    trigState = '';
                end
            end
        end
        
        function errMsg = get.ErrorMessages(obj)
            % read error list from the scope’s error buffer
            
            % config
            maxErrCnt = 20;  % size of error stack
            errCell   = cell(1, maxErrCnt);
            cnt       = 0;
            done      = false;
            
            % read error from buffer until done
            while ~done && cnt < maxErrCnt
                cnt = cnt + 1;
                % read error and convert to characters
                errMsg = obj.VisaIFobj.query('SYSTEM:ERROR?');
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