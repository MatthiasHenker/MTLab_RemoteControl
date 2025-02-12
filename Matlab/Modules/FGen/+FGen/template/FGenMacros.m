classdef FGenMacros < handle
    % template for: generator macros for DEVICE XYZ
    %
    % add device specific documentation (when sensible)

    properties(Constant = true)
        MacrosVersion = '0.0.0';      % release version
        MacrosDate    = '2020-08-05'; % release date
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
                disp(['Object destructor called for class ''' ...
                    class(obj) '''.']);
            end
        end

        function status = runAfterOpen(obj)

            % init output
            status = NaN;

            disp('ToDo ...');
            % add some device specific commands:
            % XXX
            %if obj.VisaIFobj.write('XXX')
            %    status = -1;
            %end
            % set XXX
            %if obj.VisaIFobj.write('XXX')
            %    status = -1;
            %end
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

            disp('ToDo ...');
            % add some device specific commands:
            % XXX
            %if obj.VisaIFobj.write('XXX')
            %    status = -1;
            %end

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
            if obj.VisaIFobj.write('*CLS')
                status = -1;
            end

            disp('ToDo ...');
            % XXX
            %if obj.VisaIFobj.write('XXX')
            %    status = -1;
            %end
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

    % ------- main FGen macros -------------------------------------------
    methods

        function status = clear(obj)
            % clear status at generator
            status = obj.VisaIFobj.write('*CLS');
        end

        function status = lock(obj)
            % lock all buttons at generator

            disp('ToDo ...');
            status = 0;
        end

        function status = unlock(obj)
            % unlock all buttons at generator

            disp('ToDo ...');
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
                                    channels{cnt} = 'ch1';
                                    if obj.ShowMessages
                                        disp(['  - channel      : 1 ' ...
                                            '(default)']);
                                    end
                                case '1'
                                    channels{cnt} = 'ch1';
                                    %
                                    %  ToDo ...
                                    %
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
                                case {'USER', 'ARB'},   waveform = 'USER';
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
                                    unit = '';
                                    disp(['FGen: Warning - ' ...
                                        '''configureOutput'' ' ...
                                        'unit parameter is unknown ' ...
                                        '--> ignore and continue']);
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
                        end
                end
            end

            % -------------------------------------------------------------
            % actual code
            % -------------------------------------------------------------

            % loop over channels
            for cnt = 1:length(channels)
                %channel = channels{cnt};   % when >1 channel only

                % --- set waveform ----------------------------------------
                if ~isempty(waveform)

                    disp('ToDo ... (waveform)');

                end

                % --- set outputimp ---------------------------------------
                if ~isempty(outputimp)

                    disp('ToDo ... (outputimp)');

                end

                % --- set stdev -------------------------------------------
                if ~isempty(stdev)

                    disp('ToDo ... (stdev)');

                end

                % --- set unit and amplitude ------------------------------
                if ~isempty(unit)

                    disp('ToDo ... (unit)');

                end

                if ~isempty(amplitude) && isnan(status)

                    disp('ToDo ... (amplitude)');

                end

                % --- set offset ------------------------------------------
                if ~isempty(offset)

                    disp('ToDo ... (offset)');

                end

                % --- set samplerate --------------------------------------
                if ~isempty(samplerate)

                    disp('ToDo ... (samplerate)');

                end

                % --- set frequency ---------------------------------------
                if ~isempty(frequency)

                    disp('ToDo ... (frequency)');

                end

                % --- set phase -------------------------------------------
                if ~isempty(phase)

                    disp('ToDo ... (phase)');

                end

                % --- set dutycycle ---------------------------------------
                if ~isempty(dutycycle)

                    disp('ToDo ... (dutycycle)');

                end

                % --- set symmetry ----------------------------------------
                if ~isempty(symmetry)

                    disp('ToDo ... (symmetry)');

                end

                % --- set bandwidth ---------------------------------------
                if ~isempty(bandwidth)

                    disp('ToDo ... (bandwidth)');

                end

                % --- set transition --------------------------------------
                if ~isempty(transition)

                    disp('ToDo ... (transition)');

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
                                    %
                                    %  ToDo ...
                                    %
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
                                        case {'user', 'all', 'builtin'}
                                            submode  = lower(paramValue);
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

            % download wavedata data from FGen
            if strcmp(mode, 'download')

                disp('ToDo ... (download)');
                waveout = [];

            end

            % upload wavedata data to FGen
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
                                    channels{cnt} = 'ch1';
                                    if obj.ShowMessages
                                        disp(['  - channel      : 1 ' ...
                                            '(default)']);
                                    end
                                case '1'
                                    channels{cnt} = 'ch1';
                                    %
                                    %  ToDo ...
                                    %
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
                %channel = channels{cnt};   % when >1 channel only

                disp('ToDo ... (enableOutput)');

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
                                    %
                                    %  ToDo ...
                                    %
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
                %channel = channels{cnt};   % when >1 channel only

                disp('ToDo ... (disableOutput)');

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
            maxErrCnt = 20;  % size of error stack at 33220A
            errCell   = cell(1, maxErrCnt);
            cnt       = 0;
            done      = false;

            % read error from buffer until done
            while ~done && cnt < maxErrCnt
                cnt = cnt + 1;


                disp('ToDo ...');
                errMsg = '<undefined>';

                errCell{cnt} = errMsg;

                done = true;


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
