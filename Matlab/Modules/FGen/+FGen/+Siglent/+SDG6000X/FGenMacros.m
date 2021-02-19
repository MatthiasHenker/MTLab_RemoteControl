classdef FGenMacros < handle
    % generator macros for Siglent SDG6022X, SDG6032X, SDG6052X
    %
    % add device specific documentation (when sensible)
    
    properties(Constant = true)
        MacrosVersion = '0.0.3';      % release version
        MacrosDate    = '2021-02-19'; % release date
    end
    
    properties(Dependent, SetAccess = private, GetAccess = public)
        ShowMessages                      logical
        ErrorMessages                     char
    end
    
    properties(SetAccess = private, GetAccess = private)
        VisaIFobj         % VisaIF object
    end
    
    % ------- basic methods -----------------------------------------------
    methods
        
        function obj = FGenMacros(VisaIFobj)
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
            
            % set phase-locked mode (both channels are NOT independent)
            % default state after generator reset or power-on is already
            % phase-locked
            if obj.VisaIFobj.write('MODE PHASE-LOCKED')
                status = -1;
            end
            
            % set XXX
            %if obj.VisaIFobj.write('XXX')
            %    status = -1;
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
        
        function status = runBeforeClose(obj)
            
            % init output
            status = NaN;
            
            % add some device specific commands:
            
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
        
        function status = reset(obj)
            
            % init output
            status = NaN;
            
            % add device specific commands
            %
            % reset
            if obj.VisaIFobj.write('*RST')
                status = -1;
            end
            % clear status (event registers and error queue)
            % command not available
            %if obj.VisaIFobj.write('*CLS')
            %    status = -1;
            %end
            
            % set phase-locked mode (both channels are NOT independent)
            % default state after generator reset or power-on is already
            % phase-locked
            if obj.VisaIFobj.write('MODE PHASE-LOCKED')
                status = -1;
            end
            % verify setting
            response = obj.VisaIFobj.query('Mode?');
            if ~strcmpi(char(response), 'MODE PHASE-LOCKED')
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
        
    end
    
    % ------- main FGen macros -------------------------------------------
    methods
        
        function status = clear(obj)
            % clear status at generator
            
            %status = obj.VisaIFobj.write('*CLS');
            status = 0;
            
            disp(['FGen Warning - Method ''clear'' is not ' ...
                'supported for ']);
            disp(['  ' obj.VisaIFobj.Vendor '-' ...
                obj.VisaIFobj.Product ...
                ' --> skip and continue']);
        end
        
        function status = lock(obj)
            % lock all buttons at generator
            
            %status = obj.VisaIFobj.write('XXX');
            status = 0;
            
            disp(['FGen Warning - Method ''lock'' is not ' ...
                'supported for ']);
            disp(['  ' obj.VisaIFobj.Vendor '-' ...
                obj.VisaIFobj.Product ...
                ' --> skip and continue']);
        end
        
        function status = unlock(obj)
            % unlock all buttons at generator
            
            %status = obj.VisaIFobj.write('XXX');
            status = 0;
            
            disp(['FGen Warning - Method ''unlock'' is not ' ...
                'supported for ']);
            disp(['  ' obj.VisaIFobj.Vendor '-' ...
                obj.VisaIFobj.Product ...
                ' --> skip and continue']);
        end
        
        % -----------------------------------------------------------------
        
        % x
        function status = configureOutput(obj, varargin)
            % configureOutput : configure output of specified channels
            %   'channel'     : '1' '1, 2'
            %   'waveform'    : 'sine', 'square', ramp', 'dc', arb', ...
            %   'amplitude'   : real
            %   'unit'        : 'Vpp', 'Vrms', 'dBm'
            %   'offset'      : real
            %   'frequency'   : real
            %   'phase'       : real
            %   'dutycycle'   : real
            %   'symmetry'    : real
            %   'transition'  : real
            %   'stdev'       : real
            %   'bandwidth'   : real
            %   'outputimp'   : real
            %   'samplerate'  : real
            
            % init output
            status = NaN;
            
            % initialize all supported parameters
            channels   = {};
            waveform   = '';
            amplitude  = '';
            unit       = '';
            offset     = '';
            frequency  = '';
            phase      = '';
            dutycycle  = '';
            symmetry   = '';
            transition = '';
            stdev      = '';
            bandwidth  = '';
            outputimp  = '';
            samplerate = '';
            
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
                                case ''
                                    channels{cnt} = 'C1';
                                    if obj.ShowMessages
                                        disp(['  - channel      : 1 ' ...
                                            '(coerced)']);
                                    end
                                case '1'
                                    channels{cnt} = 'C1';
                                case '2'
                                    channels{cnt} = 'C2';
                                otherwise
                                    channels{cnt} = '';
                                    disp(['FGen: Warning - ''configureOutput'' ' ...
                                        'invalid channel (allowed are 1 .. 2) ' ...
                                        '--> ignore and continue']);
                            end
                        end
                        % remove invalid (empty) entries
                        channels = channels(~cellfun(@isempty, channels));
                    case 'waveform'
                        if ~isempty(paramValue)
                            switch upper(paramValue)
                                case {'SIN',   'SINE'}, waveform = 'SINE';
                                case {'SQU', 'SQUARE'}, waveform = 'SQUARE';
                                case {'RAMP'},          waveform = 'RAMP';
                                case {'PULS', 'PULSE'}, waveform = 'PULSE';
                                case {'NOIS', 'NOISE'}, waveform = 'NOISE';
                                case {'DC'},            waveform = 'DC';
                                case {'USER', 'ARB'},   waveform = 'ARB';
                                otherwise
                                    waveform = '';
                                    disp(['FGen: Warning - ' ...
                                        '''configureOutput'' ' ...
                                        'waveform parameter value is unknown ' ...
                                        '--> ignore and continue']);
                            end
                        end
                    case 'amplitude'
                        if ~isempty(paramValue)
                            amplitude = str2double(paramValue);
                            if isnan(amplitude) || isinf(amplitude)
                                amplitude = [];
                            end
                        end
                    case 'unit'
                        switch lower(paramValue)
                            case ''
                                % coerce later
                            case 'vpp'
                                unit = 'AMP';
                            case 'vrms'
                                unit = 'AMPVRMS';
                            case 'dbm'
                                unit = 'AMPDBM';
                            otherwise
                                unit = '';
                                disp(['FGen: Warning - ' ...
                                    '''configureOutput'' ' ...
                                    'unit parameter value is unknown ' ...
                                    '--> coerce and continue']);
                        end
                    case 'offset'
                        if ~isempty(paramValue)
                            offset = str2double(paramValue);
                            if isnan(offset) || isinf(offset)
                                offset = [];
                            end
                        end
                    case 'frequency'
                        if ~isempty(paramValue)
                            frequency = abs(str2double(paramValue));
                            if isnan(frequency) || isinf(frequency)
                                frequency = [];
                            end
                        end
                    case 'phase'
                        if ~isempty(paramValue)
                            phase = str2double(paramValue);
                            phase = mod(phase, 360);
                            if isnan(phase) || isinf(phase)
                                phase = [];
                            end
                        end
                    case 'dutycycle'
                        if ~isempty(paramValue)
                            dutycycle = abs(str2double(paramValue));
                            dutycycle = min(dutycycle, 100);
                            dutycycle = max(dutycycle, 0);
                            if isnan(dutycycle) || isinf(dutycycle)
                                dutycycle = [];
                            end
                        end
                    case 'symmetry'
                        if ~isempty(paramValue)
                            symmetry = abs(str2double(paramValue));
                            symmetry = min(symmetry, 100);
                            symmetry = max(symmetry, 0);
                            if isnan(symmetry) || isinf(symmetry)
                                symmetry = [];
                            end
                        end
                    case 'transition'
                        if ~isempty(paramValue)
                            transition = abs(str2double(paramValue));
                            if isnan(transition) || isinf(transition)
                                transition = [];
                            end
                        end
                    case 'stdev'
                        if ~isempty(paramValue)
                            stdev = abs(str2double(paramValue));
                            if isnan(stdev) || isinf(stdev)
                                stdev = [];
                            end
                        end
                    case 'bandwidth'
                        if ~isempty(paramValue)
                            bandwidth = abs(str2double(paramValue));
                            if isnan(bandwidth) || isinf(bandwidth)
                                bandwidth = [];
                            end
                        end
                    case 'outputimp'
                        if ~isempty(paramValue)
                            outputimp = abs(str2double(paramValue));
                            if isnan(outputimp)
                                outputimp = [];
                            end
                        end
                    case 'samplerate'
                        if ~isempty(paramValue)
                            samplerate = abs(str2double(paramValue));
                            if isnan(samplerate) || isinf(samplerate)
                                samplerate = [];
                            end
                        end
                        %
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
                
                % --- set outputimp ---------------------------------------
                if ~isempty(outputimp)
                    % round and coerce input value
                    if outputimp > 1e5
                        outimpStr = 'HZ';
                        if obj.ShowMessages
                            disp('  - outputimp    : inf (coerced)');
                        end
                    elseif outputimp < 49.5
                        outimpStr = '50';
                        if obj.ShowMessages
                            disp('  - outputimp    : 50 (coerced)');
                        end
                    else
                        outimpStr = num2str(round(outputimp), '%d');
                    end
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':OUTPut ' ...
                        'LOAD,' outimpStr]);
                    
                    % verify
                    response = obj.VisaIFobj.query([channel ':OUTPut?']);
                    response = char(response);
                    if startsWith(response, [channel ':OUTP '])
                        % remove header
                        response = response(7:end);
                        % separate parameter
                        ParamList = split(response, ',');
                        ParamList = strtrim(ParamList);
                        % verify response string with requested settings
                        if length(ParamList) >= 3
                            % ParamList{1} : output state is not of interest
                            if strcmpi(ParamList{2}, 'LOAD')
                                % okay
                                if strcmpi(ParamList{3}, outimpStr)
                                    % okay
                                else
                                    % error (incorrect output impedance)
                                    status = -1;
                                end
                            else
                                % error (incorrect parameter name)
                                status = -1;
                            end
                        else
                            % error (incorrect number of parameters)
                            status = -1;
                        end
                    else
                        % error (incorrect header of response)
                        status = -1;
                    end
                end
                
                % --- set waveform ----------------------------------------
                if ~isempty(waveform)
                    % waveform is either 'SINE', 'SQUARE', 'RAMP', 'PULSE',
                    % 'NOISE', 'DC' or 'ARB'
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic WaVe ' ...
                        'WVTP,' waveform]);
                end
                
                % --- set unit and amplitude ------------------------------
                if ~isempty(amplitude)
                    if isempty(unit)
                        unit = 'AMP';
                        if obj.ShowMessages
                            disp('  - unit         : Vpp (coerced)');
                        end
                    end
                    % unit is either AMP, AMPVRMS or AMPDBM
                    % valid range for amplitude depends on unit:
                    % 0.001 .. 10      for 1mVpp to 10Vpp
                    % 0.00035 .. 3.54  for 0.35mVrms to 3.54Vrms
                    % -56.02 .. +23.98 for -56dBm to +24dBm (load = 50 Ohm)
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic WaVe ' ...
                        unit ',' num2str(amplitude, '%1.3e')]);
                end
                
                % --- set stdev -------------------------------------------
                if ~isempty(stdev)
                    % Only settable when waveform is NOISE
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic WaVe ' ...
                        'STDEV,' num2str(stdev, '%1.3e')]);
                end
                
                % --- set offset ------------------------------------------
                if ~isempty(offset)
                    % Not valid when WVTP is NOISE ==> use mean instead
                    
                    % set parameter
                    if strcmpi(waveform, noise)
                        obj.VisaIFobj.write([channel ':BaSic WaVe ' ...
                            'MEAN,' num2str(offset, '%1.3e')]);
                    else
                        obj.VisaIFobj.write([channel ':BaSic WaVe ' ...
                            'OFST,' num2str(offset, '%1.3e')]);
                    end
                end
                
                % --- set frequency ---------------------------------------
                if ~isempty(frequency)
                    % Not valid when WVTP is NOISE or DC
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic WaVe ' ...
                        'FRQ,' num2str(frequency, '%1.8e')]);
                end
                
                % --- set phase -------------------------------------------
                if ~isempty(phase)
                    % Not valid when WVTP is NOISE , PULSE or DC
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic WaVe ' ...
                        'PHSE,' num2str(phase, '%1.3e')]);
                end
                
                % --- set dutycycle ---------------------------------------
                if ~isempty(dutycycle)
                    % Only settable when WVTP is SQUARE or PULSE
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic WaVe ' ...
                        'DUTY,' num2str(dutycycle, '%1.3e')]);
                end
                
                % --- set symmetry ----------------------------------------
                if ~isempty(symmetry)
                    % Only settable when WVTP is RAMP
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic WaVe ' ...
                        'SYM,' num2str(symmetry, '%1.3e')]);
                end
                
                % --- set bandwidth ---------------------------------------
                if ~isempty(bandwidth)
                    % Only settable when WVTP is NOISE
                    
                    
                    % bandstate on/off define a max bandwidth to turn off
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic WaVe ' ...
                        'BANDWIDTH,' num2str(bandwidth, '%1.3e')]);
                end
                
                % --- set transition --------------------------------------
                if ~isempty(transition)
                    
                    disp('ToDo ... (transition)');
                    % for rise and fall time
                    
                    
                end
                
                
                
                % verify
                response = obj.VisaIFobj.query([channel ':BaSic WaVe?']);
                response = char(response);
                % 'WVTP'   waveform
                % unit     amplitude
                
                
                if startsWith(response, [channel ':BSWV '])
                    % remove header
                    response = response(7:end);
                    % separate parameter
                    ParamList     = split(response,',');
                    ParamList     = strtrim(ParamList);
                    
                    
                    % TEMP: display parameter values
                    if obj.ShowMessages
                        for idx = (1 : 2 : length(ParamList)-1)
                            disp(['Basic_Wave: ' ...
                                pad(ParamList{idx}, 9) ...
                                '= ' ParamList{idx+1}]);
                        end
                        disp(' ');
                    end
                    
                    
                    % verify response string with requested settings
                    ParamValue    = [];
                    for idx = 1 : length(ParamList)
                        % parse parameter list and search for right keyword
                        % either 'AMP', 'AMPVRMS' or 'AMPDBM'
                        if strcmpi(ParamList{idx}, unit)
                            try
                                % next entry should be the actual parameter value
                                ParamValue = ParamList{idx+1};
                            catch
                                ParamValue = '';
                            end
                            % now remove unit from string ('V', 'Vrms' or 'dBm')
                            ParamValue = regexp(ParamValue,'\-?\d+\.?\d*\e?\-?\d*','match');
                            if ~isempty(ParamValue)
                                ParamValue = ParamValue{1};
                                % finally convert string to number
                                ParamValue = str2double(ParamValue);
                            else
                                ParamValue = [];
                            end
                        end
                    end
                    % verify value
                    if isempty(ParamValue)
                        % error (incorrect header, parameter not found)
                        status = -1;
                    elseif abs(amplitude - ParamValue) < 1e-3 || ...
                            abs(ParamValue / amplitude -1) < 1e-4
                        %okay
                    else
                        % error (incorrect parameter value)
                        status = -1;
                    end
                else
                    % error (incorrect header of response)
                    status = -1;
                end
                
                
                
                % --- set samplerate --------------------------------------
                if ~isempty(samplerate)
                    
                    disp('ToDo ... (samplerate)');
                    
                end
                
                
                
                
            end
            
            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
            
        end
        
        % x
        function [status, waveout] = arbWaveform(obj, varargin)
            % arbWaveform  : upload, download, list, select arbitrary
            % waveforms
            %   'channel'     : '1' '1, 2'
            %   'mode'     : 'list', 'select', 'delete', 'upload',
            %                'download'
            %   'submode'  : 'user', 'builtin', 'all', 'override'
            %   'wavename' : 'xyz' (char)
            %   'wavedata' : vector of real (range -1 ... +1)
            %   (for future use???)   'filename' : 'xyz' (char)
            
            % init outputs
            status  = NaN;
            % either list of wavenames (list) or wavedata (download)
            waveout = '';
            
            % initialize all supported parameters
            channels    = {};
            mode        = '';
            submode     = '';
            wavename    = '';
            wavedata    = [];
            %filename    = '';
            
            override    = false;  % default submode @ upload
            
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
                                case ''
                                    channels{cnt} = 'C1';
                                    if obj.ShowMessages
                                        disp(['  - channel      : 1 ' ...
                                            '   (coerced)']);
                                    end
                                case '1'
                                    channels{cnt} = 'C1';
                                case '2'
                                    channels{cnt} = 'C2';
                                otherwise
                                    channels{cnt} = '';
                                    disp(['FGen: Warning - ''configureOutput'' ' ...
                                        'invalid channel (allowed are 1 .. 2) ' ...
                                        '--> ignore and continue']);
                            end
                        end
                        % remove invalid (empty) entries
                        channels = channels(~cellfun(@isempty, channels));
                    case 'mode'
                        if ~isempty(paramValue)
                            switch lower(paramValue)
                                case {'list', 'select', 'delete', ...
                                        'upload', 'download'}
                                    mode = lower(paramValue);
                                otherwise
                                    mode = '';
                                    disp(['FGen: Warning - ' ...
                                        '''arbWaveform'' ' ...
                                        'mode parameter value is unknown ' ...
                                        '--> ignore and continue']);
                            end
                        end
                    case 'submode'
                        if ~isempty(paramValue)
                            switch mode
                                case {'upload'}  % 'download'
                                    switch lower(paramValue)
                                        case {'override'}
                                            submode  = lower(paramValue);
                                            override = true;
                                        otherwise
                                            submode = '';
                                            disp(['FGen: Warning - ' ...
                                                '''arbWaveform'' submode ' ...
                                                'parameter value is unknown ' ...
                                                '--> ignore and continue']);
                                    end
                                case 'list'
                                    switch lower(paramValue)
                                        case {'user', 'all', 'builtin'}
                                            submode  = lower(paramValue);
                                        otherwise
                                            submode = '';
                                            disp(['FGen: Warning - ' ...
                                                '''arbWaveform'' submode ' ...
                                                'parameter value is unknown ' ...
                                                '--> ignore and continue']);
                                    end
                                otherwise
                                    disp(['FGen: Warning - ' ...
                                        '''arbWaveform'' submode ' ...
                                        'parameter value is senseless ' ...
                                        '--> ignore and continue']);
                            end
                        end
                    case 'wavename'
                        if ~isempty(paramValue)
                            
                            
                            
                            wavename = paramValue;
                            
                            
                            
                        end
                    case 'wavedata'
                        if ~isempty(paramValue)
                            if ischar(paramValue)
                                wavedata = str2num(lower(paramValue));
                            else
                                wavedata = paramValue;
                            end
                            wavedata = real(wavedata);
                        end
                        %case 'filename'
                        %    if ~isempty(paramValue)
                        %        % no further tests needed
                        %        filename = paramValue;
                        %    end
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
            
            if strcmp(mode, 'download')
                
                disp('ToDo ... (download)');
                waveout = [];
                
            end
            
            if strcmp(mode, 'upload') && ~isempty(wavedata)
                
                disp('ToDo ... (upload)');
                
            end
            
            if strcmp(mode, 'list')
                
                disp('ToDo ... (list)');
                waveout = '';
                
            end
            
            if strcmp(mode, 'delete')
                
                disp('ToDo ... (delete)');
                
            end
            
            if strcmp(mode, 'select')
                
                disp('ToDo ... (select)');
                
            end
            
            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
            
        end
        
        function status = enableOutput(obj, varargin)
            % enableOutput  : enable output of specified channels
            %   'channel'   : '1' '1, 2'
            
            % init output
            status = NaN;
            
            % initialize all supported parameters
            channels = {};
            
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
                                case ''
                                    channels{cnt} = 'C1';
                                    if obj.ShowMessages
                                        disp(['  - channel      : 1 ' ...
                                            '(coerced)']);
                                    end
                                case '1'
                                    channels{cnt} = 'C1';
                                case '2'
                                    channels{cnt} = 'C2';
                                otherwise
                                    channels{cnt} = '';
                                    disp(['FGen: Warning - ' ...
                                        '''enableOutput'' invalid ' ...
                                        'channel (allowed are 1 .. 2) ' ...
                                        '--> ignore and continue']);
                            end
                        end
                        % remove invalid (empty) entries
                        channels = channels(~cellfun(@isempty, channels));
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
                
                % set output at Fgen
                obj.VisaIFobj.write([channel ':OUTPUT ON']);
                
                % verify
                response = obj.VisaIFobj.query([channel ':OUTPUT?']);
                if ~startsWith(char(response), [channel ':OUTP ON'])
                    status = -1;
                end
            end
            
            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end
        
        function status = disableOutput(obj, varargin)
            % disableOutput : disable output of specified channels
            %   'channel'   : '1' '1, 2'
            
            % init output
            status = NaN;
            
            % initialize all supported parameters
            channels = {};
            
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
                                case ''
                                    channels{cnt} = 'C1';
                                    if obj.ShowMessages
                                        disp(['  - channel      : 1 ' ...
                                            '(coerced)']);
                                    end
                                case '1'
                                    channels{cnt} = 'C1';
                                case '2'
                                    channels{cnt} = 'C2';
                                otherwise
                                    channels{cnt} = '';
                                    disp(['FGen: Warning - ' ...
                                        '''enableOutput'' invalid ' ...
                                        'channel (allowed are 1 .. 2) ' ...
                                        '--> ignore and continue']);
                            end
                        end
                        % remove invalid (empty) entries
                        channels = channels(~cellfun(@isempty, channels));
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
                
                % set output at Fgen
                obj.VisaIFobj.write([channel ':OUTPUT OFF']);
                
                % verify
                response = obj.VisaIFobj.query([channel ':OUTPUT?']);
                if ~startsWith(char(response), [channel ':OUTP OFF'])
                    status = -1;
                end
            end
            
            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end
        
        % -----------------------------------------------------------------
        % actual generator methods: get methods (dependent)
        % -----------------------------------------------------------------
        
        function errMsg = get.ErrorMessages(obj)
            % read error list from the generator’s error buffer
            
            disp(['FGen Warning - Property ''ErrorMessages'' is not ' ...
                'supported for ']);
            disp(['  ' obj.VisaIFobj.Vendor '-' ...
                obj.VisaIFobj.Product ...
                ' --> skip and continue']);
            
            % copy result to output
            errMsg = '<undefined>';
            
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
                    disp('FGenMacros: invalid state in get.ShowMessages');
            end
        end
        
    end
    
end
