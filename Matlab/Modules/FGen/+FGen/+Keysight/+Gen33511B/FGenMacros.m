classdef FGenMacros < handle
    % generator macros for Keysight 33511B
    %
    % add device specific documentation (when sensible)
    
    properties(Constant = true)
        MacrosVersion = '1.0.0';      % release version
        MacrosDate    = '2021-01-13'; % release date
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
            
            % add an Keysight 33511B specific command:
            %
            % clear display
            if obj.VisaIFobj.write('DISPLAY:TEXT:CLEAR')
                status = -1;
            end
            % set larger font size at screen (and smaller waveform preview)
            if obj.VisaIFobj.write('DISPLAY:VIEW TEXT')
                status = -1;
            end
            % turn display on (no effect when already on
            if obj.VisaIFobj.write('DISPLAY ON')
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
            
            % add an Keysight 33511B specific command:
            %
            % no SCPI command available to set to local state again
            % (buttons at generator are still locked after closing)
            % ==> PRESS "Local" button at generator to unlock again
            %
            % clear display
            if obj.VisaIFobj.write('DISPLAY:TEXT:CLEAR')
                status = -1;
            end
            % set standard view of display again
            if obj.VisaIFobj.write('DISPLAY:VIEW STANDARD')
                status = -1;
            end
            % turn display on (no effect when already on
            if obj.VisaIFobj.write('DISPLAY ON')
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
            
            % add Keysight 33511B specific commands
            %
            % reset
            if obj.VisaIFobj.write('*RST')
                status = -1;
            end
            % clear status (event registers and error queue)
            if obj.VisaIFobj.write('*CLS')
                status = -1;
            end
            % clear display
            if obj.VisaIFobj.write('DISPLAY:TEXT:CLEAR')
                status = -1;
            end
            % set larger font size at screen (and smaller waveform preview)
            if obj.VisaIFobj.write('DISPLAY:VIEW TEXT')
                status = -1;
            end
            % turn display on (no effect when already on
            if obj.VisaIFobj.write('DISPLAY ON')
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
    
    % ------- main generator macros -------------------------------------------
    methods
        
        function status = clear(obj)
            % clear status at generator
            status = obj.VisaIFobj.write('*CLS');
            % clear display
            if obj.VisaIFobj.write('DISPLAY:TEXT:CLEAR')
                status = -1;
            end
        end
        
        function status = lock(obj)
            % lock all buttons at generator
            disp(['FGen WARNING - Method ''lock'' is not ' ...
                'supported for ']);
            disp(['      ' obj.VisaIFobj.Vendor '/' ...
                obj.VisaIFobj.Product ...
                %' -->  Ignore and continue']);
                ' -->  FGen will be automatically locked by remote access']);
            %status = obj.VisaIFobj.write('SYSTEM:REMOTE');
            status = 0;
        end
        
        function status = unlock(obj)
            % unlock all buttons at generator
            disp(['FGen WARNING - Method ''unlock'' is not ' ...
                'supported for ']);
            disp(['      ' obj.VisaIFobj.Vendor '/' ...
                obj.VisaIFobj.Product ...
                %' -->  Ignore and continue']);
                ' -->  Press button ''System/Local'' at FGen device']);
            %status = obj.VisaIFobj.write('SYSTEM:LOCAL');
            status = 0;
        end
        
        % -----------------------------------------------------------------
        
        function status = configureOutput(obj, varargin)
            % configureOutput : configure output of specified channels
            %   'channel'     : '1' '1, 2'
            %   'waveform'    : 'sine', 'square', ramp', 'dc', arb', ...
            %   'amplitude'   : real
            %   'unit'        : 'Vpp', 'Vrms', 'dBm'
            %   'offset'      : real
            %   'frequency'   : real > 0
            %   'phase'       : real > 0
            %   'dutycycle'   : real > 0
            %   'symmetry'    : real > 0
            %   'transition'  : real > 0
            %   'stdev'       : real > 0
            %   'bandwidth'   : real > 0
            %   'outputimp'   : real > 0
            %   'samplerate'  : real > 0
            
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
                                    channels{cnt} = 'ch1';
                                    if obj.ShowMessages
                                        disp(['  - channel      : 1 ' ...
                                            '(default)']);
                                    end
                                case '1'
                                    channels{cnt} = 'ch1';
                                otherwise
                                    channels{cnt} = '';
                                    disp(['FGen: Warning - ''configureOutput'' ' ...
                                        'invalid channel --> ignore ' ...
                                        'and continue']);
                            end
                        end
                        % remove invalid (empty) entries
                        channels = channels(~cellfun(@isempty, channels));
                    case 'waveform'
                        if ~isempty(paramValue)
                            switch upper(paramValue)
                                case {'SIN',   'SINE'}, waveform = 'SIN';
                                case {'SQU', 'SQUARE'}, waveform = 'SQU';
                                case {'RAMP'},          waveform = 'RAMP';
                                case {'PULS', 'PULSE'}, waveform = 'PULS';
                                case {'NOIS', 'NOISE'}, waveform = 'NOIS';
                                case {'DC'},            waveform = 'DC';
                                case {'USER', 'ARB'},   waveform = 'ARB';
                                otherwise
                                    waveform = '';
                                    disp(['FGen: Warning - ' ...
                                        '''configureOutput'' ' ...
                                        'waveform parameter is unknown ' ...
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
                        if ~isempty(paramValue)
                            switch upper(paramValue)
                                case {'VPP', 'VRMS', 'DBM'}
                                    unit = upper(paramValue);
                                otherwise
                                    unit = upper(paramValue);
                                    disp(['FGen: Warning - ' ...
                                        '''configureOutput'' ' ...
                                        'unit parameter value ''' ...
                                        unit ''' is unknown ' ...
                                        '--> ignore and continue']);
                                    unit = '';
                            end
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
                            frequency = str2double(paramValue);
                            if isnan(frequency) || isinf(frequency)
                                frequency = [];
                            end
                        end
                    case 'phase'
                        if ~isempty(paramValue)
                            phase = str2double(paramValue);
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
                            transition = str2double(paramValue);
                            if isnan(transition) || isinf(transition)
                                transition = [];
                            end
                        end
                    case 'stdev'
                        if ~isempty(paramValue)
                            stdev = str2double(paramValue);
                            if isnan(stdev) || isinf(stdev)
                                stdev = [];
                            end
                        end
                    case 'bandwidth'
                        if ~isempty(paramValue)
                            bandwidth = str2double(paramValue);
                            if isnan(bandwidth) || isinf(bandwidth)
                                bandwidth = [];
                            end
                        end
                    case 'outputimp'
                        if ~isempty(paramValue)
                            outputimp = str2double(paramValue);
                            if isnan(outputimp)
                                outputimp = [];
                            end
                        end
                    case 'samplerate'
                        if ~isempty(paramValue)
                            samplerate = str2double(paramValue);
                            if isnan(samplerate) || isinf(samplerate)
                                samplerate = [];
                            end
                        end
                        %
                    otherwise
                        if ~isempty(paramValue)
                            disp(['  WARNING - parameter ''' ...
                                paramName ''' is unknown --> ignore']);
                            %
                            %disp(['FGen: Warning - ''configureOutput'' ' ...
                            %    'XXX parameter is not available ' ...
                            %    '--> ignore and continue']);
                        end
                end
            end
            
            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------
            
            % loop over channels
            for cnt = 1:length(channels)
                %channel = channels{cnt};   % 33511B has one channel only
                
                % --- set waveform ----------------------------------------
                if ~isempty(waveform)
                    % set parameter
                    obj.VisaIFobj.write(['FUNCTION ' waveform]);
                    % read and verify
                    response = obj.VisaIFobj.query('FUNCTION?');
                    if ~strcmpi(waveform, char(response))
                        status = -1;
                    end
                end
                % no text message needed; waveform displayed by dedicated LEDs
                
                % --- set outputimp ---------------------------------------
                if ~isempty(outputimp)
                    % round and coerce input value
                    outputimp = round(outputimp);
                    if outputimp > 1e4
                        outputimp = inf;
                    end
                    % set parameter
                    obj.VisaIFobj.write(['OUTPUT:LOAD ' num2str(outputimp)]);
                    % read back
                    response = obj.VisaIFobj.query('OUTPUT:LOAD?');
                    response = str2double(char(response));
                    if response >= 1e37
                        response = inf;
                    end
                    % finally verify setting
                    if outputimp ~= response
                        status = -1;
                    end
                    % display actually set value at generator
                    %obj.VisaIFobj.write(['DISPLAY:TEXT "Output Load = ' ...
                    %    num2str(response, '%g') ' Ohm"']);
                end
                
                % --- set stdev -------------------------------------------
                if ~isempty(stdev)
                    if isempty(amplitude) && isempty(unit)
                        amplitude = stdev;
                        unit      = 'VRMS';
                    else
                        disp(['FGen: Warning - ''configureOutput'' ' ...
                            'stdev parameter conflicts with ' ...
                            'amplitude/unit --> ignore and continue']);
                    end
                end
                
                % --- set bandwidth ---------------------------------------
                if ~isempty(bandwidth)
                    % set parameter
                    obj.VisaIFobj.write(['FUNCTION:NOISE:BANDWIDTH ' ...
                        num2str(bandwidth, '%.6f')]);
                    % read back
                    response = obj.VisaIFobj.query('FUNCTION:NOISE:BANDWIDTH?');
                    response = str2double(char(response));
                    % finally verify setting
                    if abs(bandwidth - response) > 1e-6 || isnan(response)
                        status = -1;
                        if obj.ShowMessages
                            disp(['  WARNING - set bandwidth ' ...
                                'reports problems. Check limits.']);
                            disp(['  requested bandwidth: ' ...
                                num2str(bandwidth) ' (Hz)']);
                            disp(['  actual bandwidth   : ' ...
                                num2str(response)  ' (Hz)']);
                        end
                    end
                    % display actually set value at generator
                    %obj.VisaIFobj.write(['DISPLAY:TEXT "Bandwidth = ' ...
                    %    num2str(response, '%g') ' Hz"']);
                end
                
                % --- set unit and amplitude ------------------------------
                if ~isempty(unit)
                    % set unit at Fgen
                    obj.VisaIFobj.write(['VOLTAGE:UNIT ' unit]);
                    % read back
                    response = obj.VisaIFobj.query('VOLTAGE:UNIT?');
                    response = char(response);
                    % finally verify setting
                    if ~strcmpi(unit, response)
                        %status = -1;
                        unit = 'VPP';
                    end
                elseif ~isempty(amplitude)
                    % read actually set unit only
                    response = obj.VisaIFobj.query('VOLTAGE:UNIT?');
                    response = char(response);
                    switch upper(response)
                        case {'VPP', 'VRMS', 'DBM'}
                            unit = response;
                        otherwise
                            status = -1;
                    end
                end
                
                if ~isempty(amplitude) && isnan(status)
                    % limit number of signicant digits
                    switch upper(unit)
                        case 'VPP'
                            unit = 'Vpp';
                            amplitudeString = num2str(amplitude, '%.4g');
                        case 'VRMS'
                            unit = 'Vrms';
                            amplitudeString = num2str(amplitude, '%.4g');
                        case 'DBM'
                            unit = 'dBm';
                            amplitudeString = num2str(amplitude, '%.2f');
                        otherwise
                            % this state should not be reached
                            status = -1;
                    end
                    amplitude = str2double(amplitudeString);
                    
                    % set amplitude at Fgen
                    obj.VisaIFobj.write(['VOLTAGE ' amplitudeString]);
                    % read back
                    response = obj.VisaIFobj.query('VOLTAGE?');
                    response = str2double(char(response));
                    
                    % finally verify setting
                    if abs(amplitude - response) > 1e-4 || isnan(response)
                        status = -1;
                        if obj.ShowMessages
                            disp(['  WARNING - set amplitude ' ...
                                'reports problems. Check limits.']);
                            disp(['  requested amplitude: ' ...
                                num2str(amplitude) ' (' unit ')']);
                            disp(['  actual amplitude   : ' ...
                                num2str(response)  ' (' unit ')']);
                        end
                    end
                    
                    % display actually set value at generator
                    %obj.VisaIFobj.write(['DISPLAY:TEXT "Amplitude = ' ...
                    %    num2str(response, '%g') ' ' unit '"']);
                end
                
                % --- set offset ------------------------------------------
                if ~isempty(offset)
                    % set parameter
                    obj.VisaIFobj.write(['VOLTAGE:OFFSET ' ...
                        num2str(offset, '%.4g')]);
                    % read back
                    response = obj.VisaIFobj.query('VOLTAGE:OFFSET?');
                    response = str2double(char(response));
                    % finally verify setting
                    if abs(offset - response) > 1e-4 || isnan(response)
                        status = -1;
                        if obj.ShowMessages
                            disp(['  WARNING - set offset ' ...
                                'reports problems. Check limits.']);
                            disp(['  requested offset: ' ...
                                num2str(offset)   ' (V)']);
                            disp(['  actual offset   : ' ...
                                num2str(response) ' (V)']);
                        end
                    end
                    % display actually set value at generator
                    %obj.VisaIFobj.write(['DISPLAY:TEXT "Offset = ' ...
                    %    num2str(response, '%g') ' V"']);
                end
                
                % --- set samplerate --------------------------------------
                if ~isempty(samplerate)
                    % set parameter
                    obj.VisaIFobj.write(['FUNCTION:ARBITRARY:SRATE ' ...
                        num2str(samplerate, '%g')]);
                    % read back
                    response = obj.VisaIFobj.query('FUNCTION:ARBITRARY:SRATE?');
                    response = str2double(char(response));
                    % finally verify setting
                    if abs(samplerate - response) > 1e-3 || isnan(response)
                        status = -1;
                        if obj.ShowMessages
                            disp(['  WARNING - set samplerate ' ...
                                'reports problems. Check limits.']);
                            disp(['  requested samplerate: ' ...
                                num2str(samplerate) ' (Sa/s)']);
                            disp(['  actual samplerate   : ' ...
                                num2str(response)   ' (Sa/s)']);
                        end
                    end
                end
                
                % --- set frequency ---------------------------------------
                if ~isempty(frequency)
                    if strcmpi(waveform, 'arb')
                        % set parameter
                        obj.VisaIFobj.write(['FUNCTION:ARBITRARY:FREQUENCY ' ...
                            num2str(frequency, '%.6f')]);
                        % read back
                        response = obj.VisaIFobj.query('FUNCTION:ARBITRARY:FREQUENCY?');
                    else
                        % set parameter
                        obj.VisaIFobj.write(['FREQUENCY ' ...
                            num2str(frequency, '%.6f')]);
                        % read back
                        response = obj.VisaIFobj.query('FREQUENCY?');
                    end
                    response = str2double(char(response));
                    
                    
                    % finally verify setting
                    if abs(frequency - response) > 1e-6 || isnan(response)
                        status = -1;
                        if obj.ShowMessages
                            disp(['  WARNING - set frequency ' ...
                                'reports problems. Check limits.']);
                            disp(['  requested frequency: ' ...
                                num2str(frequency) ' (Hz)']);
                            disp(['  actual frequency   : ' ...
                                num2str(response)  ' (Hz)']);
                        end
                    end
                    % display actually set value at generator
                    %obj.VisaIFobj.write(['DISPLAY:TEXT "Frequency = ' ...
                    %    num2str(response, '%g') ' Hz"']);
                end
                
                % --- set phase -------------------------------------------
                if ~isempty(phase)
                    % set phase unit to deg
                    obj.VisaIFobj.write('UNIT:ANGLE DEG');
                    % set parameter
                    obj.VisaIFobj.write(['PHASE ' ...
                        num2str(phase, '%.4f')]);
                    % read back
                    response = obj.VisaIFobj.query('PHASE?');
                    response = str2double(char(response));
                    % finally verify setting
                    if abs(phase - response) > 1e-3 || isnan(response)
                        status = -1;
                        if obj.ShowMessages
                            disp(['  WARNING - set phase ' ...
                                'reports problems. Check limits.']);
                            disp(['  requested phase: ' ...
                                num2str(phase)    ' (deg)']);
                            disp(['  actual phase   : ' ...
                                num2str(response) ' (deg)']);
                        end
                    end
                    % display actually set value at generator
                    %obj.VisaIFobj.write(['DISPLAY:TEXT "Phase = ' ...
                    %    num2str(response, '%g') ' deg"']);
                end
                
                % --- set dutycycle ---------------------------------------
                if ~isempty(dutycycle)
                    % check: duty cycle for square (default) or pulse?
                    response = obj.VisaIFobj.query('FUNCTION?');
                    switch upper(char(response))
                        case {'PULSE', 'PULS'}
                            % set parameter
                            obj.VisaIFobj.write(['FUNCTION:PULSE:DCYCLE ' ...
                                num2str(dutycycle, '%.3f')]);
                            % read back
                            response = obj.VisaIFobj.query( ...
                                'FUNCTION:PULSE:DCYCLE?');
                            errlim    = 1e-3;
                            pulseform = true;
                        otherwise % square as default
                            % set parameter
                            obj.VisaIFobj.write(['FUNCTION:SQUARE:DCYCLE ' ...
                                num2str(dutycycle, '%.2f')]);
                            % read back
                            response = obj.VisaIFobj.query( ...
                                'FUNCTION:SQUARE:DCYCLE?');
                            errlim    = 1e-1;
                            pulseform = false;
                    end
                    response = str2double(char(response));
                    % finally verify setting
                    if abs(dutycycle - response) > errlim || isnan(response)
                        status = -1;
                        if obj.ShowMessages
                            disp(['  WARNING - set dutycycle ' ...
                                'reports problems. Check limits.']);
                            disp(['  requested dutycycle: ' ...
                                num2str(dutycycle) ' (%)']);
                            disp(['  actual dutycycle   : ' ...
                                num2str(response)  ' (%)']);
                        end
                    end
                    % display actually set value at generator
                    if pulseform
                        %    obj.VisaIFobj.write(['DISPLAY:TEXT "Pulse: ' ...
                        %        'DutyC. = ' num2str(response, '%g') ' %"']);
                    else
                        %    obj.VisaIFobj.write(['DISPLAY:TEXT "Square: ' ...
                        %        'DutyC. = ' num2str(response, '%g') ' %"']);
                    end
                end
                
                % --- set symmetry ----------------------------------------
                if ~isempty(symmetry)
                    % set parameter
                    obj.VisaIFobj.write(['FUNCTION:RAMP:SYMMETRY ' ...
                        num2str(symmetry, '%.2f')]);
                    % read back
                    response = obj.VisaIFobj.query('FUNCTION:RAMP:SYMMETRY?');
                    response = str2double(char(response));
                    % finally verify setting
                    if abs(symmetry - response) > 1e-2 || isnan(response)
                        status = -1;
                        if obj.ShowMessages
                            disp(['  WARNING - set symmetry ' ...
                                'reports problems. Check limits.']);
                            disp(['  requested symmetry: ' ...
                                num2str(symmetry) ' (%)']);
                            disp(['  actual symmetry   : ' ...
                                num2str(response)  ' (%)']);
                        end
                    end
                    % display actually set value at generator
                    %obj.VisaIFobj.write(['DISPLAY:TEXT "Ramp: Symm. = ' ...
                    %num2str(response, '%g') ' %"']);
                end
                
                % --- set transition --------------------------------------
                if ~isempty(transition)
                    % limit input parameter (8.4ns ... 1000ns)
                    transition = min(1e-6,   transition);
                    transition = max(8.4e-9, transition);
                    
                    % set parameter
                    obj.VisaIFobj.write(['FUNCTION:PULSE:TRANSITION ' ...
                        num2str(transition, '%g')]);
                    % read back
                    response = obj.VisaIFobj.query('FUNCTION:PULSE:TRANSITION?');
                    response = str2double(char(response));
                    % finally verify setting
                    if abs(transition - response) > 1e-10 || isnan(response)
                        status = -1;
                        if obj.ShowMessages
                            disp(['  WARNING - set transition ' ...
                                'reports problems. Check limits.']);
                            disp(['  requested transition: ' ...
                                num2str(transition) ' (%)']);
                            disp(['  actual transition   : ' ...
                                num2str(response)  ' (%)']);
                        end
                    end
                    % display actually set value at generator
                    %obj.VisaIFobj.write(['DISPLAY:TEXT "Pulse: EdgeTime = ' ...
                    %    num2str(response*1e9, '%g') ' ns"']);
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
            allwaves    = true;   % default submode @ list
            
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
                                    channels{cnt} = 'ch1';
                                    if obj.ShowMessages
                                        disp(['  - channel      : 1 ' ...
                                            '   (default)']);
                                    end
                                case '1'
                                    channels{cnt} = 'ch1';
                                otherwise
                                    channels{cnt} = '';
                                    disp(['FGen: Warning - ''configureOutput'' ' ...
                                        'invalid channel --> ignore ' ...
                                        'and continue']);
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
                                        'mode parameter is unknown ' ...
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
                                                'parameter is unknown ' ...
                                                '--> ignore and continue']);
                                    end
                                case 'list'
                                    switch lower(paramValue)
                                        case 'user'
                                            submode  = lower(paramValue);
                                            allwaves = false;
                                        case 'all'
                                            submode  = lower(paramValue);
                                        case 'builtin'
                                            submode  = 'all';
                                            if obj.ShowMessages
                                                disp(['  - submode      : ' ...
                                                    'ALL  (coerced)']);
                                            end
                                        otherwise
                                            submode = '';
                                            disp(['FGen: Warning - ' ...
                                                '''arbWaveform'' submode ' ...
                                                'parameter is unknown ' ...
                                                '--> ignore and continue']);
                                    end
                                otherwise
                                    disp(['FGen: Warning - ' ...
                                        '''arbWaveform'' submode ' ...
                                        'parameter is senseless ' ...
                                        '--> ignore and continue']);
                            end
                        end
                    case 'wavename'
                        if ~isempty(paramValue)
                            if length(paramValue) > 12
                                wavename = paramValue(1:12);
                                if obj.ShowMessages
                                    disp(['  - wavename     : ' ...
                                        wavename ' (truncated)']);
                                end
                            else
                                wavename = paramValue;
                            end
                            if strcmpi('wavename', 'volatile')
                                disp(['FGen: Warning - ' ...
                                    '''arbWaveform'' wavename ' ...
                                    'parameter is invalid ' ...
                                    '--> ignore and continue']);
                                wavename = '';
                            end
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
                        %                     case 'filename'
                        %                         if ~isempty(paramValue)
                        %                             % no further tests needed
                        %                             filename = paramValue;
                        %                         end
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
            
            % download wavedata data from FGen
            if strcmp(mode, 'download')
                % waveout is used for wavedata (nothing downloaded)
                waveout = [];
                status = -1; % 'failed', but we can continue
                disp(['FGen: Warning - ''arbWaveform'' download ' ...
                    'parameter is not supported ' ...
                    '--> ignore and continue']);
            end
            
            % upload wavedata data to FGen
            if strcmp(mode, 'upload') && ~isempty(wavedata)
                if length(wavedata) > 2^16
                    wavedata = wavedata(1:2^16);
                    disp(['FGen: Warning - ''arbWaveform'' maximum ' ...
                        'length of wavedata is 65536 ' ...
                        '--> truncate and continue']);
                end
                
                % convert to integers (14-bit)
                wavedata = round(2^(14-1) * wavedata);
                
                % clip wave data
                wavedata = min( 2^(14-1)-1, wavedata);
                wavedata = max(-2^(14-1)+1, wavedata);
                
                % convert to characters (list of comma separated values
                % starting with a comma)
                wavedata = num2str(wavedata, ',%d');
                % remove spaces
                wavedata = regexprep(wavedata, '\s+', '');
                
                % clear volatile memory before
                if obj.VisaIFobj.write('DATA:VOLATILE:CLEAR')
                    status = -1;
                end
                % 1st step: upload wave data to volatile memory of generator
                if obj.VisaIFobj.write(['DATA:DAC VOLATILE' wavedata])
                    status = -1;
                end
                
                if strcmpi(wavename, 'VOLATILE')
                    disp(['FGen: Warning - ''arbWaveform'' wavename ' ...
                        '''VOLATILE'' is reserved ' ...
                        '--> ignore and continue']);
                    status = -1; % 'failed', but we can continue
                else
                    % get list of wavenames already stored at FGen
                    namelist = obj.VisaIFobj.query('DATA:NVOLATILE:CATALOG?');
                    % convert to characters
                    namelist = char(namelist);
                    % remove all "
                    namelist = strrep(namelist, '"', '');
                    % split (csv list of wave names)
                    namelist = split(namelist, ',');
                    
                    % check if wavename is already available
                    if any(strcmpi(namelist, wavename))
                        if ~override
                            disp(['FGen: Warning - ''arbWaveform'' ' ...
                                'wavename already exists ' ...
                                '--> ignore and continue']);
                            status = -1; % 'failed', but we can continue
                        else
                            % 33511B doesn't allow overriding of data
                            disp(['FGen: Warning - ''arbWaveform'' ' ...
                                'wavename already exists ' ...
                                '--> delete waveform (no overriding allowed)']);
                            status = -1; % 'failed', but we can continue
                        end
                    else
                        % check if enough memory space is available
                        response = obj.VisaIFobj.query('DATA:NVOLATILE:FREE?');
                        number   = str2double(char(response));
                        if number < 1
                            disp(['FGen: Warning - ''arbWaveform'' not ' ...
                                'enough memory available ' ...
                                '--> ignore and continue']);
                            status = -1; % 'failed', but we can continue
                        else
                            % 2nd step: copy wave data to non-volatile memory
                            obj.VisaIFobj.write(['DATA:COPY ' wavename]);
                        end
                    end
                end
                
                % wait for operation complete (can take a while)
                obj.VisaIFobj.opc;
                
                % finally display actually set value at generator
                if isnan(status)
                    %obj.VisaIFobj.write(['DISPLAY:TEXT "Upload: ' ...
                    %    wavename '"']);
                else
                    %obj.VisaIFobj.write(['DISPLAY:TEXT "Upload: ' ...
                    %   ' no success"']);
                end
            end
            
            if strcmp(mode, 'list')
                % get list of wavenames already stored at FGen
                if allwaves
                    namelist = obj.VisaIFobj.query('DATA:CATALOG?');
                else
                    namelist = obj.VisaIFobj.query('DATA:NVOLATILE:CATALOG?');
                end
                % convert to characters
                namelist = char(namelist);
                % remove all "
                namelist = strrep(namelist, '"', '');
                
                % copy result to output variable
                waveout  = namelist;
                
                % display results
                if obj.ShowMessages
                    disp(['  available waveforms (submode = ' submode ...
                        ') at generator are:']);
                    % split (csv list of wave names)
                    namelist = split(namelist, ',');
                    % sort list alphabetically
                    namelist = sort(namelist);
                    
                    if isempty(namelist{1})
                        disp( '  <none>');
                    else
                        for cnt = 1 : length(namelist)
                            disp(['  (' num2str(cnt,'%02i') ') ''' ...
                                namelist{cnt} '''']);
                        end
                    end
                    disp( '  ATTENTION: max 4 user waveforms can be stored.');
                end
            end
            
            if strcmp(mode, 'delete')
                % get list of wavenames already stored at FGen
                namelist = obj.VisaIFobj.query('DATA:NVOLATILE:CATALOG?');
                % convert to characters
                namelist = char(namelist);
                % remove all "
                namelist = strrep(namelist, '"', '');
                % split (csv list of wave names)
                namelist = split(namelist, ',');
                
                % check if wavename is already available
                if any(strcmpi(namelist, wavename))
                    obj.VisaIFobj.write(['DATA:DELETE ' wavename]);
                    %obj.VisaIFobj.write(['DISPLAY:TEXT "Delete: ' ...
                    %    wavename '"']);
                elseif obj.ShowMessages
                    disp(['  Warning: wavename does not exist ' ...
                        '--> ignore and continue']);
                end
            end
            
            if strcmp(mode, 'select')
                % get list of wavenames already stored at FGen
                namelist = obj.VisaIFobj.query('DATA:CATALOG?');
                % convert to characters
                namelist = char(namelist);
                % remove all "
                namelist = strrep(namelist, '"', '');
                % split (csv list of wave names)
                namelist = split(namelist, ',');
                
                % select waveform only when wavename is available
                if any(strcmpi(namelist, wavename))
                    % loop over channels
                    for cnt = 1:length(channels)
                        %channel = channels{cnt};   % 33511B has one channel only
                        
                        obj.VisaIFobj.write(['FUNC:USER ' wavename]);
                        
                    end
                    % display actually set value at generator
                    %obj.VisaIFobj.write(['DISPLAY:TEXT "Wave: ' ...
                    %    wavename '"']);
                else
                    disp(['FGen: Warning - ''arbWaveform'' cannot ' ...
                        'select non-existing wavename ' ...
                        '--> ignore and continue']);
                    status = -1; % 'failed', but we can continue
                end
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
                                    channels{cnt} = 'ch1';
                                    if obj.ShowMessages
                                        disp(['  - channel      : 1 ' ...
                                            '(default)']);
                                    end
                                case '1'
                                    channels{cnt} = 'ch1';
                                otherwise
                                    channels{cnt} = '';
                                    disp(['FGen: Warning - ' ...
                                        '''enableOutput'' invalid ' ...
                                        'channel --> ignore and ' ...
                                        'continue']);
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
                %channel = channels{cnt};   % 33511B has one channel only
                
                % set output at Fgen
                obj.VisaIFobj.write('OUTPUT ON');
                
                % read back actual setting and verify
                response = obj.VisaIFobj.query('OUTPUT?');
                if ~strcmpi(char(response), '1')
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
                                    channels{cnt} = 'ch1';
                                    if obj.ShowMessages
                                        disp(['  - channel      : 1 ' ...
                                            '(default)']);
                                    end
                                case '1'
                                    channels{cnt} = 'ch1';
                                otherwise
                                    channels{cnt} = '';
                                    disp(['FGen: Warning - ' ...
                                        '''disableOutput'' invalid ' ...
                                        'channel --> ignore and ' ...
                                        'continue']);
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
                %channel = channels{cnt};   % 33511B has one channel only
                
                % set output at Fgen
                obj.VisaIFobj.write('OUTPUT OFF');
                
                % read back actual setting and verify
                response = obj.VisaIFobj.query('OUTPUT?');
                if ~strcmpi(char(response), '0')
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
            
            % config
            maxErrCnt = 20;  % size of error stack at 33511B
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
                if startsWith(errMsg, '+0,')
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
                    disp('FGen error list:');
                    for cnt = 1:length(errCell)
                        disp(['  (' num2str(cnt,'%02i') ') ' ...
                            errCell{cnt} ]);
                    end
                else
                    disp('FGen error list is empty');
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
                    disp('FGenMacros: invalid state in get.ShowMessages');
            end
        end
        
    end
    
end
