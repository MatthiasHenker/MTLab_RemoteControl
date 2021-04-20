classdef ScopeMacros < handle
    % ToDo documentation
    %
    % known severe issues:
    %   - trigger level can be set temporarily only (will not be updated in
    %     trigger menu at scope display and get lost at next vDiv or
    %     vOffset update) ==> can be a big problem
    %   - measurement cannot be disabled again (first phase or delay
    %     measurement enables measurement mode ==> captureWaveform become
    %     much slower then) ==> reduces download speed, avoid phase
    %     measurements to overcome this problem
    %   - largest parameter value for maxLength of waveform (140MSa or 70
    %     MSa (interleaved)) cannot be set remotely ==> not nice, but not a
    %     big deal
    %   - skew cannot be set remotely ==> not a big deal
    %
    %
    % for Scope: Siglent SDS2304X series
    % (for Siglent firmware: 1.2.2.2R19 (2019-03-25) ==> see myScope.identify)
    
    properties(Constant = true)
        MacrosVersion = '0.5.0';      % release version
        MacrosDate    = '2021-04-20'; % release date
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
            % defines the way the scope formats response to queries
            % off: header is omitted from the response and units in numbers
            % are suppressed ==> shortest feedback
            if obj.VisaIFobj.write('COMM_HEADER OFF')
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
            % ==> not supported by SDS2000X
            %if obj.VisaIFobj.write('*CLS')
            %    status = -1;
            %end
            
            % defines the way the scope formats response to queries
            % off: header is omitted from the response and units in numbers
            % are suppressed ==> shortest feedback
            if obj.VisaIFobj.write('COMM_HEADER OFF')
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
            
            status = obj.VisaIFobj.write('RUN');
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
            if obj.VisaIFobj.write('AUTO_SETUP')
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
            %skew           = '';
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
                                impedance = '50';  % 50 Ohm
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
                            if obj.ShowMessages
                                disp(['  - skew         : ' ...
                                    '<empty> (coerced)']);
                            end
                            disp(['Scope: Warning - ''configureInput'' ' ...
                                'Skew parameter cannot be set remotely ' ...
                                '(BUG in firmware@Scope) ' ...
                                '--> has to be set manually at Scope']);
                            status = 1; % Warning
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
                
                % 'impedance' ('50', '1M') & 'coupling' ('DC', 'AC', 'GND')
                if ~isempty(impedance) || ~isempty(coupling)
                    if ~isempty(impedance) && ~isempty(coupling)
                        % both parts are defined
                        if strcmpi(coupling, 'GND')
                            cpl = 'GND';
                            if obj.ShowMessages
                                disp(['  - impedance    : ' ...
                                    '<empty> (coerced)']);
                            end
                            disp(['Scope: Warning - ''configureInput'' ' ...
                                'impedance parameter will be ignored ' ...
                                'when coupling = GND.']);
                        else
                            % A50, A1M, D50, D1M
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
                % ATTENTION: Bug ('SIGLENT, SDS2304X, 1.2.2.2 R19')
                % only short form of command is working
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
                % ATTENTION: Bug ('SIGLENT, SDS2304X, 1.2.2.2 R19')
                % set skew will end up in totally frozen scope 
                % ==> power off/on required
                % ==> skew cannot be set remotely at the moment
                % ==> can be set manually at scope only
                % ==> read back will report 0.00ns always
                %if ~isempty(skew)
                %    % format (round) numeric value
                %    skewString = num2str(skew, '%1.1e');
                %    skew       = str2double(skewString);
                %    skewString = [num2str(skew *1e9, '%g') 'ns'];
                %    % set parameter
                %    obj.VisaIFobj.write(['C' channel ':SKEW ' skewString]);
                %    % read and verify
                %    response   = obj.VisaIFobj.query(['C' channel ...
                %        ':SKEW?']);
                %    % remove unit and scale properly before
                %    skewActual = str2double(char(response));
                %    if skew ~= skewActual
                %        disp(['Scope: Warning - ''configureInput'' ' ...
                %            'skew parameter could not be set correctly. ' ...
                %            'Check limits.']);
                %    end
                %end
                
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
                % Bug @ scope: attentuation will scale VDiv which is right
                % set: VDiv: unscaled voltage scaling value is expected
                % get: read back value is properly scaled by attentuation
                %
                % workaround: read attenuation value, scale VDiv before set
                if ~isempty(vDiv)
                    if isempty(inputDiv)
                        response = obj.VisaIFobj.query(['C' channel ...
                            ':ATTENUATION?']);
                        probe = str2double(char(response));
                    else
                        probe = str2double(inputDiv);
                    end
                    if isnan(probe)
                        disp(['Scope: ERROR - ''configureInput'' ' ...
                            'unexpected response while setting vDiv ' ...
                            'parameter --> Abort and continue.']);
                        status = -1;
                    else
                        % scale VDiv value before use (in set command)
                        vDiv_temp = num2str(vDiv / probe, '%1.1e');
                        vDiv      = str2double(vDiv_temp) * probe;
                        
                        % set parameter (use scaled value)
                        obj.VisaIFobj.write(['C' channel ...
                            ':VDIV ' vDiv_temp]);
                        % read and verify
                        response   = obj.VisaIFobj.query(['C' channel ...
                            ':VDIV?']);
                        vDivActual = str2double(char(response));
                        if abs(vDiv - vDivActual) / vDiv > 0.1
                            disp(['Scope: Warning - ''configureInput'' ' ...
                                'vDiv parameter could not be set correctly. ' ...
                                'Check limits.']);
                        end
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
                                tDiv    = 5e-4; % 0.5ms as default
                            else
                                % okay ==> round to allowed values in s
                                % 1e-9, 2e-9, 5e-9, ... , 10, 20, 50
                                tmp  = tDiv;
                                tDiv = min(tDiv, 50);
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
                            if obj.ShowMessages
                                disp('  - samplerate   : <empty> (coerced)');
                            end
                        end
                    case 'maxLength'
                        if ~isempty(paramValue)
                            maxLength = abs(str2double(paramValue)) /2;
                            coerced   = false;
                            if isnan(maxLength) || isinf(maxLength)
                                disp(['Scope: Warning - ''configureAcquisition'' ' ...
                                    'maxLength parameter value is invalid ' ...
                                    '--> coerce and continue']);
                                maxLength = 140e3;
                                coerced   = true;
                            end
                            % okay ==> round to allowed values 7e3, 1.4e4,
                            % 7e4, 1.4e5, 7e5, 1.4e6, 7e6, 1.4e7, 7e7
                            % (interleaved mode)
                            tmp       = maxLength;
                            maxLength = min(maxLength, 7e7);
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
                                    num2str(2* maxLength, '%g') ...
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
                                numAverage = 16;
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
            
            % maxLength : 7k, 14k, 70k, .. 70M for interleaved channels
            %             value*2              for single channel
            if ~isempty(maxLength)
                % finally convert to string
                switch maxLength
                    case 7000
                        MaxMemSize = '7k';
                    case 14000
                        MaxMemSize = '14k';
                    case 70000
                        MaxMemSize = '70k';
                    case 140000
                        MaxMemSize = '140k';
                    case 700000
                        MaxMemSize = '700k';
                    case 1400000
                        MaxMemSize = '1.4M';
                    case 7000000
                        MaxMemSize = '7M';
                    case 14000000
                        MaxMemSize = '14M';
                    case 70000000
                        %MaxMemSize = '70M';
                        MaxMemSize = '14M';
                        status = 1;
                        disp(['Scope: Warning - ''configureAcquisition'' ' ...
                            'maxLength = 140e6 cannot be set remotely ' ...
                            '(BUG in firmware@Scope) ' ...
                            '--> has to be set manually at Scope']);
                        if obj.ShowMessages
                            disp('  - maxLength    : 28e6 (coerced)');
                        end
                    otherwise
                        warning('Should be an impossible internal state');
                        status = -1;
                        return
                end
                % set parameter
                obj.VisaIFobj.write(['MEMORY_SIZE ' MaxMemSize]);
                % read and verify
                response = obj.VisaIFobj.query('MEMORY_SIZE?');
                if ~strcmpi(MaxMemSize, char(response))
                    if strcmpi(char(response), '7k')
                        disp(['Scope: WARNING - ''configureAcquisition'' ' ...
                            'maxLength parameter can only be configured ' ...
                            ' when mode = sample or peakdetect.']);
                        if obj.ShowMessages
                            disp('  - maxLength    : 14e3 (coerced)');
                        end
                        status = 1;
                    else
                        disp(['Scope: ERROR - ''configureAcquisition'' ' ...
                            'maxLength parameter could not be set correctly.']);
                        status = -1;
                    end
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
                            case 'ch3'
                                source = 'C3';
                            case 'ch4'
                                source = 'C4';
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
                                    'NoiseReject cannot be set remotely ' ...
                                    '--> has to be set manually at Scope']);
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
            
            % source   : 'C1..4', 'EX', 'EX5', 'LINE'
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
                response = obj.VisaIFobj.query('TRIG_SLOPE?');
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
                % BUG in firmware@Scope
                status = 1;
                disp(['Scope: Warning - ''configureTrigger'' ' ...
                    'set level to center of the trigger source ' ...
                    'waveform does not work --> BUG@Scope']);
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
                idx = regexp(response, '^\-?\d+\.?\d*\e?\-?\d*', 'end');
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
                            if zoomFactor <= 1 || isnan(zoomFactor)
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
                % zoomFactor will be rounded by Scope to nearest value
                                
                if zoomFactor == 1
                    % disable zoom window (indirectly)
                    obj.VisaIFobj.write(['TIME_DIV ' num2str(tdiv, '%g')]);
                    skipHPOS = true;
                else
                    % enable zoom window
                    obj.VisaIFobj.write(['HOR_MAGNIFY ' ...
                        num2str(zoomFactor, '%1.1e')]);
                    % no readback and verify
                end
            end
            
            if ~isempty(zoomPosition) && ~skipHPOS
                % request zoom timebase
                hmag = obj.VisaIFobj.query('HOR_MAGNIFY?');
                hmag = str2double(char(hmag));
                tdiv = tdiv / hmag;
                if isnan(tdiv)
                    disp(['Scope: ERROR - ''configureZoom'' ' ...
                        'unexpected response ' ...
                        '--> abort and continue']);
                    status = -2;
                    return
                end
                % convert time offset (in s) to tdiv scaling
                zoomPosition = zoomPosition / tdiv;
                
                obj.VisaIFobj.write(['HOR_POSITION ' ...
                    num2str(zoomPosition, '%1.1e')]);
                % no readback and verify
            end
            
            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end
        
        % code copied from Rigol-DS2072A
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
            %                optional, default is './Siglent_Scope_SDS2000X.bmp'
            %   'darkMode' : on/off, dark or white background color
            %                optional, default is 'off', 0, false,
            %                unsupported parameter
            
            % init output
            status = NaN;
            
            % configuration and default values
            listOfSupportedFormats = {'.bmp'};
            filename = './Siglent_Scope_SDS2000X.bmp';
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
            
            % save display settings
            % 1st step: save current intensity settings of display
            dispSettings = obj.VisaIFobj.query('INTENSITY?');
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
            
            % -------------------------------------------------------------
            % request actual binary screen shot data
            bitMapData = obj.VisaIFobj.query('SCREEN_DUMP');
            
            % response is always 1152056 bytes for plain bitmap data
            % without any additional header
            if length(bitMapData) ~= 1152056
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
            % restore Display settings
            if ~isnan(TraceValue) && ~isnan(GridValue)
                obj.VisaIFobj.write(['INTENSITY ' ...
                    'TRACE,' num2str(TraceValue, '%g') ...
                    ',GRID,' num2str(GridValue, '%g')]);
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
                                        'channel (allowed are 1 .. 4) ' ...
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
                obj.VisaIFobj.write(['MEASURE_DELAY ' parameter ',' source]);
                % additional settling time
                pause(0.2);
                % request measurement value
                value = obj.VisaIFobj.query([source ...
                    ':MEASURE_DELY? ' parameter]);
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
                meas.status = -1;
                return
            elseif isnan(str2double(value{2}))
                disp(['Scope: ERROR ''runMeasurement'' ' ...
                    'unexpected response (parameter value) ' ...
                    '--> skip and exit']);
                meas.status = -5;
                return
            end
            value = str2double(value{2});
            
            if abs(value) > 1e36
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
                                case {'1', '2', '3', '4'}
                                    channels{cnt} = ['C' channels{cnt}];
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
            % ==> channels contain at least one element
            if isempty(channels)
                channels = {'C1', 'C2', 'C3', 'C4'};
                if obj.ShowMessages
                    disp('  - channel      : 1, 2, 3, 4 (coerced)');
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
            % format of response is xxxUnit with Unit
            [value, unit] = regexpi(char(response), '^\d+\.?\d*', ...
                'match', 'split');
            switch lower(unit{end})
                case 'gsa/s'
                    srate  = str2double(value) *1e9;
                case 'msa/s'
                    srate  = str2double(value) *1e6;
                case 'ksa/s'
                    srate  = str2double(value) *1e3;
                case 'sa/s'
                    srate  = str2double(value) *1e0;
                otherwise
                    waveData.status = -5; % error
                    return
            end
            if ~isnan(srate) && length(srate) == 1 && srate > 0
                % fine
            else
                waveData.status = -6; % error
                return
            end
            % copy result to output
            waveData.samplerate = srate;
            
            
            % number of available samples
            response = obj.VisaIFobj.query(['SAMPLE_NUM? ' channels{1}]);
            % format of response is xxxUnit with Unit
            [value, unit] = regexpi(char(response), '^\d+\.?\d*', ...
                'match', 'split');
            switch lower(unit{end})
                case 'mpts'
                    xlength = str2double(value) *1e6;
                case 'kpts'
                    xlength = str2double(value) *1e3;
                case 'pts'
                    xlength = str2double(value) *1e0;
                otherwise
                    waveData.status = -7; % error
                    return
            end
            if xlength == round(xlength) && length(xlength) == 1
                % fine
            else
                waveData.status = -8; % error
                return
            end
            % initialize result matrix (acquired voltages = 0)
            waveData.volt = zeros(length(channels), xlength);
            
            
            % parameter trigger delay (offset) in s
            response = obj.VisaIFobj.query('TRIG_DELAY?');
            % format of response is xxxUnit with Unit
            [value, unit] = regexpi(char(response), '^\d+\.?\d*', ...
                'match', 'split');
            switch lower(unit{end})
                case 's'
                    tDelay = str2double(value) *1e0;
                case 'ms'
                    tDelay = str2double(value) *1e-3;
                case 'us'
                    tDelay = str2double(value) *1e-6;
                case 'ns'
                    tDelay = str2double(value) *1e-9;
                otherwise
                    waveData.status = -9; % error
                    return
            end
            if ~isnan(tDelay) && length(tDelay) == 1
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
            waveData.time = (0:xlength-1)/srate +tDelay -tDiv *numGrid/2;
            
            
            % -------------------------------------------------------------
            % 2nd step: configure data segments to download data in chunks
            
            % data chunks must be smaller than obj.VisaIFobj.InputBufferSize
            % 1.4MSa will divide all possible larger NumSamples without rest
            NSampleMax  = 1.4e6;
            % calculate size of data chunks and number of data chunks
            NumSegments = ceil(xlength / NSampleMax);  % >= 1
            NSamplesSeg =      xlength / NumSegments;  % >= 1
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
                    RawData  = obj.VisaIFobj.query([channel ':WF? DAT2']);
                    
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