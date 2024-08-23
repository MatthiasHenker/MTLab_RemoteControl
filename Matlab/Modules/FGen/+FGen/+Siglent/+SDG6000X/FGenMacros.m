classdef FGenMacros < handle
    % generator macros for Siglent SDG6022X, SDG6032X, SDG6052X
    %
    % add device specific documentation (when sensible)

    properties(Constant = true)
        MacrosVersion = '1.0.0';      % release version
        MacrosDate    = '2021-03-16'; % release date
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

            % coerce waveform
            if isempty(waveform) && ~isempty(samplerate)
                % samplerate command will activate ARB mode anyway
                waveform = 'ARB';
                if obj.ShowMessages
                    disp('  - waveform     : ARB  (coerced)');
                end
            end

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
                            'BANDWIDTH,' num2str(bandwidth, '%1.8e')]);
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
                            % now remove units ('Sa/s')
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
                                case 'VALUE'
                                    if ~isempty(samplerate)
                                        srate = ParamValue;
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

        function [status, waveout] = arbWaveform(obj, varargin)
            % arbWaveform  : upload, download, list, select arbitrary
            % waveforms
            %   'channel'  : '1' '1, 2'
            %   'mode'     : 'list', 'select', 'delete', 'upload',
            %                'download'
            %   'submode'  : 'user', 'builtin', 'all', 'override'
            %   'wavename' : 'xyz' (char)
            %   'wavedata' : vector of real or complex
            %                (range -1 ... +1 for real and imaginary part)
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
                                            '   (default, for mode = ' ...
                                            'select only)']);
                                    end
                                case '1'
                                    channels{cnt} = 'C1';
                                case '2'
                                    channels{cnt} = 'C2';
                                otherwise
                                    channels{cnt} = '';
                                    disp(['FGen: Warning - ''arbWaveform'' ' ...
                                        'invalid channel (allowed are 1 .. 2) ' ...
                                        '--> ignore and continue']);
                            end
                        end
                        % remove invalid (empty) entries
                        channels = channels(~cellfun(@isempty, channels));
                    case 'mode'
                        switch lower(paramValue)
                            case ''
                                mode = 'list';
                                if obj.ShowMessages
                                    disp(['  - mode         : list ' ...
                                        '(default)']);
                                end
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
                    case 'submode'
                        switch mode
                            case 'download'
                                switch lower(paramValue)
                                    case ''
                                        submode = 'user'; % default
                                        if obj.ShowMessages
                                            disp(['  - submode      : ' ...
                                                'USER (default)']);
                                        end
                                    case 'user'
                                        submode = 'user';
                                    case 'builtin'
                                        submode  = 'builtin';
                                    case 'all'
                                        submode  = 'user';
                                        if obj.ShowMessages
                                            disp(['  - submode      : USER ' ...
                                                '   (coerced)']);
                                        end
                                    otherwise
                                        submode = 'user';
                                        if obj.ShowMessages
                                            disp(['  - submode      : USER ' ...
                                                '   (coerced)']);
                                        end
                                        disp(['FGen: Warning - ' ...
                                            '''arbWaveform'' submode ' ...
                                            'parameter value is unknown ' ...
                                            '--> coerce and continue']);
                                end
                            case 'upload'
                                switch lower(paramValue)
                                    case ''
                                        submode = 'user'; % default
                                        if obj.ShowMessages
                                            disp(['  - submode      : ' ...
                                                'USER (default)']);
                                        end
                                    case 'user'
                                        submode = 'user';
                                    case 'override'
                                        submode = 'override';
                                    otherwise
                                        submode = 'user';
                                        if obj.ShowMessages
                                            disp(['  - submode      : ' ...
                                                'USER (coerced)']);
                                        end
                                        disp(['FGen: Warning - ' ...
                                            '''arbWaveform'' submode ' ...
                                            'parameter value is unknown ' ...
                                            '--> coerce and continue']);
                                end
                            case {'list', 'select'}
                                switch lower(paramValue)
                                    case ''
                                        submode = 'user'; % default
                                        if obj.ShowMessages
                                            disp(['  - submode      : ' ...
                                                'USER (default)']);
                                        end
                                    case {'user', 'all', 'builtin'}
                                        submode  = lower(paramValue);
                                    otherwise
                                        submode = 'user';
                                        if obj.ShowMessages
                                            disp(['  - submode      : ' ...
                                                'USER (coerced)']);
                                        end
                                        disp(['FGen: Warning - ' ...
                                            '''arbWaveform'' submode ' ...
                                            'parameter value is unknown ' ...
                                            '--> coerce and continue']);
                                end
                            case 'delete'
                                switch lower(paramValue)
                                    case ''
                                        submode = 'user'; % default
                                        if obj.ShowMessages
                                            disp(['  - submode      : ' ...
                                                'USER (default)']);
                                        end
                                    case 'user'
                                        submode = 'user';
                                    case {'builtin', 'all'}
                                        submode  = 'user';
                                        if obj.ShowMessages
                                            disp(['  - submode      : ' ...
                                                'USER (coerced)']);
                                        end
                                    otherwise
                                        submode = 'user';
                                        if obj.ShowMessages
                                            disp(['  - submode      : ' ...
                                                'USER (coerced)']);
                                        end
                                        disp(['FGen: Warning - ' ...
                                            '''arbWaveform'' submode ' ...
                                            'parameter value is unknown ' ...
                                            '--> coerce and continue']);
                                end
                            otherwise
                                disp(['FGen: Warning - ' ...
                                    '''arbWaveform'' submode ' ...
                                    'parameter value is unused ' ...
                                    '--> ignore and continue']);
                        end
                    case 'wavename'
                        if ~isempty(paramValue)
                            if length(paramValue) > 24
                                wavename = paramValue(1:24);
                                if obj.ShowMessages
                                    disp(['  - wavename     : ' ...
                                        wavename ' (truncated)']);
                                end
                            else
                                wavename = paramValue;
                            end
                        end
                    case 'wavedata'
                        if ~isempty(paramValue)
                            if ischar(paramValue)
                                wavedata = str2num(lower(paramValue));
                            else
                                wavedata = paramValue;
                            end
                            % wavedata can be either real or complex
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
            % real wavedata will be stored at SDG6000X as *.bin files but
            % wavenames will be listed and selected without extension .bin
            % ==> wavename always without file extension
            %
            % complex IQ wavedata will be stored as *.arb files in directory
            % EasyIQ_arb
            % ==> can only be listed at FGen, no remote access
            % ==> cannot upload via SCPI, EasyIQ software has to be used
            % ==> cannot has to be deleted at FGen, no remote access
            %
            % Thus, no arb-feature used here, all wave data as real data in
            % "normal" mode

            if strcmp(mode, 'list')
                % get list of wavenames already stored at FGen
                % Note: submode is not empty (set to 'user' as default)
                if strcmpi(submode, 'all')
                    submodeList = {'user', 'builtin'};
                else
                    % either 'user' or 'builtin'
                    submodeList = {lower(submode)};
                end

                % init list for results
                resultlist = cell(0, 3); % id, wavename, submode
                for selectedsubmode = submodeList
                    switch selectedsubmode{1}
                        case 'user'
                            % command to get a list of wave names
                            response = obj.VisaIFobj.query( ...
                                'SToreList? USER');

                            % convert to characters
                            response = char(response);
                            % remove header
                            if startsWith(response, 'STL WVNM,', ...
                                    'IgnoreCase', true)
                                response = response(10:end);
                            else
                                response = '';
                                status   = -1;
                                disp(['FGen: ERROR - ' ...
                                    '''arbWaveform'' unexpected ' ...
                                    'response from VISA device ' ...
                                    '--> ignore and continue']);
                            end
                        case 'builtin'
                            % command to get a list of wave names
                            response = obj.VisaIFobj.query( ...
                                'SToreList? BUILDIN');

                            % convert to characters
                            response = char(response);
                            % remove header
                            if startsWith(response, 'STL', ...
                                    'IgnoreCase', true)
                                response = response(4:end);
                            else
                                response = '';
                                status   = -1;
                                disp(['FGen: ERROR - ' ...
                                    '''arbWaveform'' unexpected ' ...
                                    'response from VISA device ' ...
                                    '--> ignore and continue']);
                            end
                        otherwise
                            %status   = -1; % 'failed', but we can continue
                            response = '';
                            disp(['FGen: Warning - ''arbWaveform'' list: ' ...
                                'unknown submode --> ignore and continue']);
                    end
                    % split (csv list of wave names)
                    response = split(response, ',');
                    % remove leading spaces from filenames
                    response = strtrim(response);
                    switch selectedsubmode{1}
                        case 'user'
                            % response is list of wavenames
                            %
                            % sort list alphabetically (ignore cases)
                            [~, tidx] = sort(lower(response));
                            response  = response(tidx);
                            % reformat list
                            tmplist  = cell(length(response), 3);
                            tmplist(:, 1) = cellstr(num2str( ...
                                (1:length(response))','%d'));% id
                            tmplist(:, 2) = response;        % wavename
                            tmplist(:, 3) = selectedsubmode; % memory type
                            resultlist    = [resultlist; tmplist];
                        case 'builtin'
                            % response is list of Mxx,wavename,Mxx, ...
                            % length(response) should be even
                            %
                            % resize response
                            lenResp = floor(length(response)/2);
                            if lenResp < 2 || length(response) ~= 2*lenResp
                                status   = 1; % we can continue
                                disp(['FGen: Warning - ''arbWaveform'' ' ...
                                    'list: unexpected response ' ...
                                    '--> ignore and continue']);
                            else
                                response = reshape(response, 2, lenResp);
                                % reformat list
                                tmplist  = cell(lenResp, 3);
                                tmplist(:, 1) = response(1, :)'; % id
                                tmplist(:, 2) = response(2, :)'; % wavename
                                tmplist(:, 3) = selectedsubmode; % memory type
                                % sort list alphabetically (ignore cases)
                                [~, tidx]  = sortrows(lower(tmplist), 2);
                                resultlist = [resultlist; tmplist(tidx, :)];
                            end
                        otherwise
                            % do nothing
                    end
                end

                % copy result to output variable
                if strcmpi(submode, 'builtin')
                    % list of comma separated dupels Mxx,wavenames
                    % (same format as Fgen response 'STL? BUILDIN')
                    waveout  = strjoin(resultlist(:, 1:2)', ',');
                else
                    % list of comma separated wavenames
                    waveout  = strjoin(resultlist(:, 2), ',');
                end

                % was this method called internally
                myStack = dbstack(1, '-completenames');
                internalCall = startsWith(myStack(1).name, 'FGenMacros');

                % display results
                if obj.ShowMessages && ~internalCall
                    % entries of first column should have same length
                    resultlist(:, 1) = pad(resultlist(:, 1), 4, 'left');
                    % entries of third column should have same length
                    resultlist(:, 3) = pad(resultlist(:, 3), 'left');
                    disp('  available waveforms at generator:');
                    if size(resultlist, 1) == 0
                        disp( '  <none>');
                    else
                        for cnt = 1 : size(resultlist, 1)
                            disp(['  ('                  ...
                                resultlist{cnt, 1} ' '   ...
                                resultlist{cnt, 3} '): ' ...
                                resultlist{cnt, 2}]);
                        end
                    end
                end
            end

            % -------------------------------------------------------------
            if strcmp(mode, 'upload') && ~isempty(wavedata)
                % set default when no wavename is defined
                if isempty(wavename)
                    wavename = 'unnamed';
                    if obj.ShowMessages
                        disp(['  - wavename     : ' ...
                            'UNNAMED (default)']);
                    end
                end

                % check length of wavedata
                MaxSamples = 1e7; % max. 10 MSa
                if length(wavedata) > MaxSamples
                    wavedata = wavedata(1:MaxSamples);
                    disp(['FGen: Warning - ''arbWaveform'' maximum ' ...
                        'length of wavedata is ' num2str(MaxSamples, '%g')  ...
                        '--> truncate data vector and continue']);
                end

                % convert to integers (16-bit) and clip wave data
                wavedata = round((2^(16-1)-1) * wavedata);
                wavedata = min( 32767, real(wavedata)) + ...
                    1i*    min( 32767, imag(wavedata));
                wavedata = max(-32767, real(wavedata)) + ...
                    1i*    max(-32767, imag(wavedata));

                % convert to binary values
                if isreal(wavedata)
                    RawWaveData = typecast(int16(wavedata), 'uint8');
                else
                    % complex wave data ==> no IQ-data support
                    % convert to 2x real wavedata for both channels
                    RawWaveData = uint8(zeros(2, 2*length(wavedata)));
                    RawWaveData(1, :) = typecast(int16(real(wavedata)), ...
                        'uint8');
                    RawWaveData(2, :) = typecast(int16(imag(wavedata)), ...
                        'uint8');
                end

                % check data format and number of channels
                if     length(channels) == 1 && size(RawWaveData, 1) == 1
                    % okay:  real wavedata for single channel
                    wavename = {wavename};
                elseif length(channels) == 2 && size(RawWaveData, 1) == 2
                    % okay:  complex wavedata for dual channels
                    wavename = {[wavename '_I'], [wavename '_Q']};
                elseif length(channels) == 1 && size(RawWaveData, 1) == 2
                    % ATTENTION: complex wavedata but single channel
                    wavename = {[wavename '_I'], [wavename '_Q']};
                    channels = {'C1', 'C2'};
                elseif length(channels) == 2 && size(RawWaveData, 1) == 1
                    % ATTENTION: real wavedata but dual channels
                    wavename = {wavename};
                    channels = channels(1);
                else
                    % invalid state
                    disp(['FGen: ERROR - ''arbWaveform'' upload: ' ...
                        'invalid state --> exit and continue']);
                    status = -3;
                    return;
                end

                % optionally check if wavename already exist at generator
                [~, namelist] = obj.arbWaveform( ...
                    'mode'   , 'list', ...
                    'submode', 'user');
                for cnt = 1:length(wavename)
                    % always without file extensions (lists bin-files only)
                    matches = ~cellfun(@isempty, regexpi( ...
                        split(namelist, ','), ...
                        ['^' wavename{cnt} '$'], 'match'));
                    if any(matches)
                        if strcmpi(submode, 'override')
                            disp(['FGen: Warning - ''arbWaveform'' wave ' ...
                                'file ' wavename{cnt} ' already exist ' ...
                                '--> override file']);
                        else
                            disp(['FGen: ERROR - ''arbWaveform'' wave ' ...
                                'file ' wavename{cnt} ' already exist ' ...
                                '--> cannot save file']);
                            status = -1;
                            return;
                        end
                    end
                    % upload waveform data
                    % channel has to be specified, but doesn't effect channel
                    obj.VisaIFobj.write([channels{cnt} ':WVDT WVNM,' ...
                        wavename{cnt} ',WAVEDATA,' RawWaveData(cnt, :)]);
                end

                % wait for operation complete
                obj.VisaIFobj.opc;
            end

            % -------------------------------------------------------------
            if strcmp(mode, 'download')
                % set default when no wavename is defined
                if isempty(wavename)
                    wavename = 'unnamed';
                    if obj.ShowMessages
                        disp(['  - wavename     : ' ...
                            'UNNAMED (default)']);
                    end
                end
                % default
                waveout = [];

                % submode is either set to user or builtin (coerced above)
                %
                % check if wavename exist at generator
                [~, namelist] = obj.arbWaveform( ...
                    'mode'   , 'list', ...
                    'submode', submode);
                nameListCell = split(namelist, ',');
                MidxListCell = cell(size(nameListCell));
                if strcmpi(submode, 'builtin')
                    nameListCell = reshape(nameListCell, 2, ...
                        length(nameListCell)/2);
                    MidxListCell = nameListCell(1, :)';
                    nameListCell = nameListCell(2, :)';
                end
                % always without file extensions (lists bin-files only)
                matches = ~cellfun(@isempty, regexpi( ...
                    nameListCell, ...
                    ['^' wavename '(\.bin|\.arb)?$'], 'match'));
                if ~any(matches)
                    disp(['FGen: Warning - ''arbWaveform'' wave ' ...
                        'file doesn''t exist --> skip and continue']);
                    status  = 1; % report no error but warning
                    return;
                else
                    foundFiles = nameListCell(matches);
                    foundIdxs  = MidxListCell(matches);
                    % file names are case sensitive
                    wavename   = foundFiles{1};
                    waveIdx    = foundIdxs{1};
                end

                % actual download of waveform data
                switch lower(submode)
                    case 'user'
                        [response, statDwld] = obj.VisaIFobj.query( ...
                            ['WVDT? USER,' wavename]);
                    case 'builtin'
                        [response, statDwld] = obj.VisaIFobj.query( ...
                            ['WVDT? ' waveIdx]);
                    otherwise
                        status  = -5;
                        waveout = [];
                        disp(['FGen: ERROR - ''arbWaveform'' download ' ...
                            'invalid submode --> exit and continue']);
                        return;
                end
                % download status okay? header starts with 'WVDT'?
                if statDwld ~= 0
                    status  = -6;
                    disp(['FGen: ERROR - ''arbWaveform'' download ' ...
                        'causes error --> exit and continue']);
                    return;
                elseif length(response) < 5
                    % error (incorrect header of response)
                    status  = -7;
                    disp(['FGen: ERROR - ''arbWaveform'' download: ' ...
                        'unexpected response --> exit and continue']);
                    return;
                elseif ~strcmpi(char(response(1:5)), 'WVDT ')
                    % error (incorrect header of response)
                    status  = -8;
                    disp(['FGen: ERROR - ''arbWaveform'' download: ' ...
                        'unexpected response --> exit and continue']);
                    return;
                end

                % header okay: remove 'WVDT' from response
                response = response(5:end);
                % search heading bytes for keyword 'WAVEDATA,'
                % indicating begin of actual binary waveform data
                searchstr = 'WAVEDATA,';
                % max length of header is estimated as 120
                idx = strfind(upper(char(response(1:min(120, ...
                    length(response))))), searchstr);
                if isempty(idx)
                    % error (incorrect header of response)
                    status  = -9;
                    disp(['FGen: ERROR - ''arbWaveform'' download: ' ...
                        'unexpected response --> exit and continue']);
                    return;
                end
                % set pointer to end of header
                idx         = idx(1) + length(searchstr)-1;
                % separate header and binary wavedata
                header      = char(response(1:idx));
                % remove header to get actual raw waveform data
                if length(response) > idx
                    rawWaveData = response(idx+1:end);
                else
                    rawWaveData = [];
                end
                clear response;

                % check header: separate elements ==> cell of char
                ParamList = split(header, ',');
                ParamList = strtrim(ParamList);
                ParamList = ParamList(1:floor(length(ParamList)/2)*2);
                ParamList = reshape(ParamList, 2, []);
                pNames    = ParamList(1, :);
                pValues   = ParamList(2, :);
                % display parameter names and values
                if obj.ShowMessages
                    disp('  reported wave settings');
                    for idx = 1 : length(pNames)
                        disp(['  - ' pad(pNames{idx}, 13) ': ' ...
                            pValues{idx}]);
                    end
                end
                % verify response: is there a parameter named 'LENGTH'
                matches = ~cellfun(@isempty, regexpi(pNames, '^LENGTH$'));
                if ~any(matches)
                    status  = -10;
                    disp(['FGen: ERROR - ''arbWaveform'' download: ' ...
                        'unexpected response --> exit and continue']);
                    return;
                end
                % corresponding value contains number of bytes ('xxB')
                WVDTlength = pValues(matches);
                WVDTlength = WVDTlength{1};
                % remove trailing 'B' and convert to number
                idx = regexpi(WVDTlength, 'B$');
                if isempty(idx) || idx < 2
                    status  = -11;
                    disp(['FGen: ERROR - ''arbWaveform'' download: ' ...
                        'unexpected response --> exit and continue']);
                    return;
                end
                WVDTlength = str2double(WVDTlength(1:idx-1));
                % length of wavedata must be an even number
                if floor(WVDTlength/2) ~= ceil(WVDTlength/2)
                    status  = -12;
                    disp(['FGen: ERROR - ''arbWaveform'' download: ' ...
                        'unexpected response --> exit and continue']);
                    return;
                end
                % finally check actual length of wavedata
                if WVDTlength ~= length(rawWaveData)
                    status  = -13;
                    disp(['FGen: ERROR - ''arbWaveform'' download: ' ...
                        'unexpected response --> exit and continue']);
                    return;
                end

                % finally cast data to int 16 and convert to double
                waveout = double(typecast(rawWaveData, 'int16'));
                % conversion into double will blow up data memory size
                % by factor 4
                % ==> 8 bytes instead of 2 bytes for each data sample
                clear rawWaveData;

                % scale waveform data (int16) to range [-1 ... +1]
                waveout = waveout / (2^(16-1)-1);
            end

            % -------------------------------------------------------------
            if strcmp(mode, 'select')
                % set default when no wavename is defined
                if isempty(wavename)
                    wavename = 'unnamed';
                    if obj.ShowMessages
                        disp(['  - wavename     : ' ...
                            'UNNAMED (default)']);
                    end
                end

                % Note: submode is not empty ('user' as default)
                if strcmpi(submode, 'all')
                    submodeList = {'user', 'builtin'}; % search order
                else
                    % either 'user' or 'builtin'
                    submodeList = {lower(submode)};
                end

                % init
                foundWave = false;
                for selectedsubmode = submodeList
                    switch selectedsubmode{1}
                        case 'user'
                            % list available wavefiles
                            [~, namelist] = obj.arbWaveform( ...
                                'mode'   , 'list', ...
                                'submode', 'user');
                            nameListCell = split(namelist, ',');
                            if length(channels) == 2
                                wavename2 = {[wavename '_I'], ...
                                    [wavename '_Q']};
                            else
                                wavename2 = {wavename};
                            end
                            for cnt = 1:length(channels)
                                % check if specified wave file exist at FGen
                                matches = ~cellfun(@isempty, regexpi( ...
                                    nameListCell, ...
                                    ['^' wavename2{cnt} '$'], 'match'));
                                if any(matches)
                                    foundFiles = nameListCell(matches);
                                    % wavename is case sensitive
                                    wavename2{cnt} = foundFiles{1};
                                else
                                    % wavename was not found
                                    wavename2{cnt} = '';
                                end
                                % wavename is set to empty when not found
                                if ~isempty(wavename2{cnt})
                                    foundWave = true;
                                    % select waveform file: arbwave command
                                    % also activate waveform 'arb' at FGen
                                    obj.VisaIFobj.write([channels{cnt} ...
                                        ':ARbWaVe NAME,' wavename2{cnt}]);

                                    % verify
                                    response = obj.VisaIFobj.query( ...
                                        [channels{cnt} ':ARbWaVe?']);
                                    % verify response
                                    response = char(response);
                                    if startsWith(response, ...
                                            [channels{cnt} ':ARWV '])
                                        % remove header
                                        response   = response(8:end);
                                        % separate parameter list
                                        ParamList  = split(response, ',');
                                        ParamList  = strtrim(ParamList);
                                        % search for keyword 'NAME'
                                        ParamValue = [];
                                        for idx = 1:2:length(ParamList)
                                            if strcmpi(ParamList{idx}, ...
                                                    'NAME')
                                                try
                                                    % next entry should be
                                                    % the parameter value
                                                    ParamValue = ...
                                                        ParamList{idx+1};
                                                catch
                                                    ParamValue = '';
                                                end
                                            end
                                        end
                                        % verify values
                                        if isempty(regexpi(ParamValue, ...
                                                ['^' wavename2{cnt} ...
                                                '(.bin|.arb)?$']))
                                            % error (incorrect waveform)
                                            status = -1;
                                            disp(['FGen: ERROR - ' ...
                                                '''arbWaveform'' select: ' ...
                                                'failed --> ignore and continue']);
                                        end
                                    else
                                        % error (incorrect header of response)
                                        status = -1;
                                        disp(['FGen: ERROR - ''arbWaveform'' ' ...
                                            'select: invalid response ' ...
                                            '--> ignore and continue']);
                                    end
                                end
                            end
                        case 'builtin'
                            % check if specified wave file exist at FGen
                            [~, namelist] = obj.arbWaveform( ...
                                'mode'   , 'list', ...
                                'submode', 'builtin');
                            nameListCell = split(namelist, ',');
                            if length(nameListCell) >= 2  % even
                                nameListCell = reshape(nameListCell, 2, ...
                                    length(nameListCell)/2);
                                MidxListCell = nameListCell(1, :)';
                                nameListCell = nameListCell(2, :)';
                            else
                                % in this case is nameListCell = {''};
                                MidxListCell = {''};
                            end
                            % ToDo: file extensions
                            matches = ~cellfun(@isempty, regexpi( ...
                                nameListCell, ...
                                ['^' wavename '(\.bin|\.arb)?$'], 'match'));
                            if any(matches)
                                foundIdxs = MidxListCell(matches);
                                waveIdx   = foundIdxs{1};
                                % listed wave index always start with M,
                                % but required index for wave select is
                                % plain index (integer) only => remove 'M'
                                if ~isempty(regexpi(waveIdx, '^M(\d)+$'))
                                    waveIdx = waveIdx(2:end);
                                else
                                    waveIdx = '';
                                    status  = -1;
                                    disp(['FGen: Error - ''arbWaveform'' ' ...
                                        'select: invalid index response ' ...
                                        '--> skip and continue']);
                                end
                            else
                                % wavename was not found
                                waveIdx   = '';
                            end

                            % waveIdx is not empty when wavename was found
                            if ~isempty(waveIdx) && ~foundWave
                                foundWave = true;
                                for cnt = 1:length(channels)
                                    % select waveform file: arbwave command
                                    % also activate waveform 'arb' at FGen
                                    obj.VisaIFobj.write([channels{cnt} ...
                                        ':ARbWaVe INDEX,' waveIdx]);

                                    % verify
                                    response = obj.VisaIFobj.query( ...
                                        [channels{cnt} ':ARbWaVe?']);
                                    % verify response
                                    response = char(response);
                                    if startsWith(response, ...
                                            [channels{cnt} ':ARWV '])
                                        % remove header
                                        response   = response(8:end);
                                        % separate parameter list
                                        ParamList  = split(response, ',');
                                        ParamList  = strtrim(ParamList);
                                        % search for keyword 'NAME'
                                        ParamValue = [];
                                        for idx = 1:2:length(ParamList)
                                            if strcmpi(ParamList{idx}, ...
                                                    'NAME')
                                                try
                                                    % next entry should be
                                                    % the parameter value
                                                    ParamValue = ...
                                                        ParamList{idx+1};
                                                catch
                                                    ParamValue = '';
                                                end
                                            end
                                        end
                                        % verify values
                                        if isempty(regexpi(ParamValue, ...
                                                ['^' wavename '(\.bin|\.arb)?$']))
                                            % error (incorrect waveform)
                                            status = -1;
                                            disp(['FGen: ERROR - ' ...
                                                '''arbWaveform'' select: ' ...
                                                'failed --> ignore and continue']);
                                        end
                                    else
                                        % error (incorrect header of response)
                                        status = -1;
                                        disp(['FGen: ERROR - ''arbWaveform'' ' ...
                                            'select: invalid response ' ...
                                            '--> ignore and continue']);
                                    end
                                end
                            end
                        otherwise
                            % invalid state: submode should be  either
                            % 'user' or 'builtin'
                            disp(['FGen: Warning - ''arbWaveform'' select: ' ...
                                'unknown submode --> ignore and continue']);
                    end
                end

                if ~foundWave
                    disp(['FGen: Warning - ''arbWaveform'' select: ' ...
                        'wavename doesn''t exist --> skip and continue']);
                    status = 1; % warning, but we can continue
                end
            end

            % -------------------------------------------------------------
            if strcmp(mode, 'delete')
                status = -1; % 'failed', but we can continue
                disp(['FGen: ERROR - ''arbWaveform'' wave files ' ...
                    'cannot be deleted remotely (Siglent-SDG6000X)' ...
                    '--> ignore and continue']);
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
