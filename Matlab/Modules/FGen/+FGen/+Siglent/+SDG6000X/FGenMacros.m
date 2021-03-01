classdef FGenMacros < handle
    % generator macros for Siglent SDG6022X, SDG6032X, SDG6052X
    %
    % add device specific documentation (when sensible)
    
    properties(Constant = true)
        MacrosVersion = '0.0.8';      % release version
        MacrosDate    = '2021-03-01'; % release date
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
                                        disp(['  - channel      : 1    ' ...
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
                            dutycycle = str2double(paramValue);
                            dutycycle = min(dutycycle, 100);
                            dutycycle = max(dutycycle, 0);
                            if isnan(dutycycle) || isinf(dutycycle)
                                dutycycle = [];
                            end
                        end
                    case 'symmetry'
                        if ~isempty(paramValue)
                            symmetry = str2double(paramValue);
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
                else
                    outimpStr = '';
                end
                
                % ---------------------------------------------------------
                % verify OUTPut settings (output impedance / load)
                response = obj.VisaIFobj.query([channel ':OUTPut?']);
                response = char(response);
                if ~startsWith(response, [channel ':OUTP '])
                    % error (incorrect header of response)
                    status = -1;
                else
                    % header okay: remove header
                    response = response(8:end);
                    % separate elements ==> list (cell) of char
                    ParamList = split(response, ',');
                    ParamList = strtrim(ParamList);
                    if length(ParamList) > 2
                        % list is a sequence of output state
                        pOutputstate = ParamList{1};
                        % followed by name,value dupels
                        ParamList = ParamList(2:end);
                        ParamList = ParamList(1:floor(length(ParamList)/2)*2);
                        ParamList = reshape(ParamList, 2, []);
                        pNames    = ParamList(1, :);
                        pValues   = ParamList(2, :);
                        % display parameter names and values
                        if obj.ShowMessages
                            disp(['  reported output settings ' ...
                                'for channel ' channel ' (SDG6000X)']);
                            disp(['  - output state : ' pOutputstate]);
                        end
                    else
                        % error (incorrect number of parameters)
                        status  = -1;
                        pNames  = {};
                        pValues = {};
                    end
                    for idx = 1 : length(pNames)
                        % display parameter names and values
                        if obj.ShowMessages
                            disp(['  - ' pad(pNames{idx}, 13) ': ' ...
                                pValues{idx}]);
                        end
                        % verify
                        switch upper(pNames{idx})
                            case 'LOAD'
                                if isempty(outimpStr)
                                    % output was not configured
                                elseif ~strcmpi(pValues{idx}, outimpStr)
                                    % error (incorrect output impedance)
                                    status = -1;
                                end
                            otherwise
                                % do nothing
                        end
                    end
                end
                
                % --- set waveform ----------------------------------------
                if isempty(waveform) && ~isempty(samplerate)
                    % samplerate command will activate ARB mode anyway
                    waveform = 'ARB';
                    if obj.ShowMessages
                        disp('  - waveform     : ARB  (coerced)');
                    end
                end
                if ~isempty(waveform)
                    % waveform is either 'SINE', 'SQUARE', 'RAMP', 'PULSE',
                    % 'NOISE', 'DC' or 'ARB'
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
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
                    obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
                        unit ',' num2str(amplitude, '%1.3e')]);
                end
                
                % --- set stdev -------------------------------------------
                if ~isempty(stdev)
                    % Only settable when waveform is NOISE
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
                        'STDEV,' num2str(stdev, '%1.3e')]);
                end
                
                % --- set offset ------------------------------------------
                if ~isempty(offset)
                    % Not valid when WVTP is NOISE ==> use mean instead
                    
                    % set parameter
                    if strcmpi(waveform, 'noise')
                        obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
                            'MEAN,' num2str(offset, '%1.3e')]);
                    else
                        obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
                            'OFST,' num2str(offset, '%1.3e')]);
                    end
                end
                
                % --- set frequency ---------------------------------------
                if ~isempty(frequency)
                    % Not valid when WVTP is NOISE or DC
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
                        'FRQ,' num2str(frequency, '%1.9e')]);
                end
                
                % --- set phase -------------------------------------------
                if ~isempty(phase)
                    % Not valid when WVTP is NOISE , PULSE or DC
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
                        'PHSE,' num2str(phase, '%1.3e')]);
                end
                
                % --- set dutycycle ---------------------------------------
                if ~isempty(dutycycle)
                    % Only settable when WVTP is SQUARE or PULSE
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
                        'DUTY,' num2str(dutycycle, '%1.4e')]);
                end
                
                % --- set symmetry ----------------------------------------
                if ~isempty(symmetry)
                    % Only settable when WVTP is RAMP
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
                        'SYM,' num2str(symmetry, '%1.3e')]);
                end
                
                % --- set bandwidth ---------------------------------------
                if ~isempty(bandwidth)
                    % Only settable when WVTP is NOISE
                    %
                    % max. Bandwidth for SDG6022X is 200 MHz
                    
                    % set parameter
                    if bandwidth > 200e6
                        % disable bandstate ==> max. noise bandwidth
                        obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
                            'BANDSTATE,OFF']);
                    else
                        % enable bandstate and set noise bandwidth
                        obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
                            'BANDSTATE,ON']);
                        obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
                            'BANDWIDTH,' num2str(bandwidth, '%1.3e')]);
                    end
                end
                
                % --- set transition --------------------------------------
                if ~isempty(transition)
                    % set transition time of rising and falling edge
                    
                    % set parameter
                    obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
                            'RISE,' num2str(transition, '%1.3e')]);
                    obj.VisaIFobj.write([channel ':BaSic_WaVe ' ...
                            'FALL,' num2str(transition, '%1.3e')]);
                end
                
                % ---------------------------------------------------------
                % verify BaSic_WaVe settings (waveform, amplitude, unit, 
                % offset, stdev, frequency, phase, dutycycle, symmetry, 
                % bandwidth, transition)
                response = obj.VisaIFobj.query([channel ':BaSic_WaVe?']);
                response = char(response);
                if ~startsWith(response, [channel ':BSWV '])
                    % error (incorrect header of response)
                    status = -1;
                else
                    % header okay: remove header
                    response = response(8:end);
                    % separate elements ==> list (cell) of char
                    ParamList = split(response, ',');
                    ParamList = strtrim(ParamList);
                    if length(ParamList) > 1
                        % list is a sequence of name,value dupels
                        ParamList = ParamList(1:floor(length(ParamList)/2)*2);
                        ParamList = reshape(ParamList, 2, []);
                        pNames    = ParamList(1, :);
                        pValues   = ParamList(2, :);
                        % display parameter names and values
                        if obj.ShowMessages
                            disp(['  reported basic wave settings ' ...
                                'for channel ' channel ' (SDG6000X)']);
                        end
                    else
                        % error (incorrect number of parameters)
                        status  = -1;
                        pNames  = {};
                        pValues = {};
                    end
                    for idx = 1 : length(pNames)
                        % display parameter names and values
                        if obj.ShowMessages
                            disp(['  - ' pad(pNames{idx}, 13) ': ' ...
                                pValues{idx}]);
                        end
                        % now remove units ('s', 'Hz', V', 'Vrms' or 'dBm')
                        ParamValue = regexp(pValues{idx},'\-?\d+\.?\d*\e?\-?\d*','match');
                        if ~isempty(ParamValue)
                            ParamValue = ParamValue{1};
                            % finally convert string to number
                            ParamValue = str2double(ParamValue);
                        else
                            ParamValue = NaN;
                        end
                        % verify
                        switch upper(pNames{idx})
                            case 'WVTP'
                                if ~isempty(waveform)
                                    if ~strcmpi(pValues{idx}, waveform)
                                        status = -1;
                                    end
                                end
                            case {'AMP', 'AMPVRMS', 'AMPDBM'}
                                % unit & amplitude
                                if strcmpi(unit, pNames{idx})
                                    if abs(ParamValue - amplitude) > 1e-3
                                        status = -2;
                                    elseif isnan(ParamValue)
                                        status = -1;
                                    end
                                end
                            case {'OFST', 'MEAN'}
                                if abs(ParamValue - offset) > 1e-3
                                    status = -2;
                                elseif isnan(ParamValue)
                                    status = -1;
                                end
                            case 'STDEV'
                                if abs(ParamValue - stdev) > 1e-3
                                    status = -2;
                                elseif isnan(ParamValue)
                                    status = -1;
                                end
                            case 'FRQ'
                                if abs(ParamValue - frequency) > 1e-1
                                    status = -2;
                                elseif isnan(ParamValue)
                                    status = -1;
                                end
                            case 'PHSE'
                                if abs(ParamValue - phase) > 0.1
                                    status = -2;
                                elseif isnan(ParamValue)
                                    status = -1;
                                end
                            case 'DUTY'
                                if abs(ParamValue - dutycycle) > 0.1
                                    status = -2;
                                elseif isnan(ParamValue)
                                    status = -1;
                                end
                            case 'SYM'
                                if abs(ParamValue - symmetry) > 0.1
                                    status = -2;
                                elseif isnan(ParamValue)
                                    status = -1;
                                end
                            case 'BANDWIDTH'
                                if abs(ParamValue - bandwidth) > 1
                                    status = -2;
                                elseif isnan(ParamValue)
                                    status = -1;
                                end
                            case {'RISE', 'FALL'}
                                if abs(transition / ParamValue) > 1
                                    status = -2;
                                elseif isnan(ParamValue)
                                    status = -1;
                                end
                            otherwise
                                % do nothing
                        end
                    end
                end
                
                % --- set samplerate --------------------------------------
                if ~isempty(samplerate)
                    % samplerate command will activate ARB mode ==> thus,
                    % it is sensible to allow this parameter only when
                    % waveform = 'arb'
                    if ~strcmpi(waveform, 'arb')
                        disp(['FGen: Warning - ' ...
                            '''configureOutput'' samplerate parameter ' ...
                            'can only be set when waveform is set to ' ...
                            'arb --> ignore and continue']);
                        % warning (status > 0)
                        status  = 1;
                    else
                        % set samplerate parameter incl. TrueARB mode and
                        % sinc interpolation mode (instead of hold or lines)
                        obj.VisaIFobj.write([channel ':SampleRATE ' ...
                            'Mode,TArb,' ...
                            'Value,' num2str(samplerate, '%1.9e') ',' ...
                            'inter,' 'sinc']);
                    end
                end
                
                % ---------------------------------------------------------
                % verify samplerate settings (check samplerate only and
                % skip test of arb-mode and interpolation-mode)
                if strcmpi(waveform, 'arb')
                    response = obj.VisaIFobj.query([channel ':SampleRATE?']);
                    response = char(response);
                    if ~startsWith(response, [channel ':SRATE '])
                        % error (incorrect header of response)
                        status = -1;
                    else
                        % header okay: remove header
                        response = response(9:end);
                        % separate elements ==> list (cell) of char
                        ParamList = split(response, ',');
                        ParamList = strtrim(ParamList);
                        if length(ParamList) > 1
                            % list is a sequence of name,value dupels
                            ParamList = ParamList(1:floor(length(ParamList)/2)*2);
                            ParamList = reshape(ParamList, 2, []);
                            pNames    = ParamList(1, :);
                            pValues   = ParamList(2, :);
                            % display parameter names and values
                            if obj.ShowMessages
                                disp(['  reported samplerate settings ' ...
                                    'for channel ' channel ' (SDG6000X)']);
                            end
                        else
                            % error (incorrect number of parameters)
                            status  = -1;
                            pNames  = {};
                            pValues = {};
                        end
                        for idx = 1 : length(pNames)
                            % display parameter names and values
                            if obj.ShowMessages
                                disp(['  - ' pad(pNames{idx}, 13) ': ' ...
                                    pValues{idx}]);
                            end
                            % verify
                            switch upper(pNames{idx})
                                case 'VALUE'
                                    if ~isempty(samplerate)
                                        srate = str2double(pValues{idx});
                                        if (samplerate / srate -1) < 1e-3
                                            % fine
                                        else
                                            % error (incorrect srate)
                                            status = -1;
                                        end
                                    end
                                otherwise
                                    % do nothing
                            end
                        end
                    end
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
                            % check format
                            if isrow(wavedata)
                                wavedata = real(wavedata);
                            elseif iscolumn(wavedata)
                                wavedata = transpose(real(wavedata));
                            else
                                wavedata = [];
                                disp(['FGen: Warning - ' ...
                                    '''arbWaveform'' wavedata ' ...
                                    'is not a vector ' ...
                                    '--> ignore and continue']);
                            end
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
