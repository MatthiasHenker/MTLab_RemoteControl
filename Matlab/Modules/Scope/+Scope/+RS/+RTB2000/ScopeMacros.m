classdef ScopeMacros < handle
    % ToDo documentation
    %
    %
    % for Scope: Rohde&Schwarz RTB2000 series 
    % (for R&S firmware: 02.300 ==> see myScope.identify)
            
    properties(Constant = true)
        MacrosVersion = '0.2.0';      % release version (min 1.2.0)
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
        
        % x
        function status = configureInput(obj, varargin)
            % configure input channels
            
            disp('ToDo ...');
            status = 0;
        end
        
        % x
        function status = configureAcquisition(obj, varargin)
            % configure acquisition parameters
            
            disp('ToDo ...');
            status = 0;
        end
        
        % x
        function status = configureTrigger(obj, varargin)
            % configure trigger parameters
            
            disp('ToDo ...');
            status = 0;
        end
        
        % x
        function status = configureZoom(obj, varargin)
            % configure zoom window
            
            disp('ToDo ...');
            status = 0;
        end
        
        % x
        function status = autoscale(obj, varargin)
            % adjust its vertical and/or horizontal scaling
            
            disp('ToDo ...');
            status = 0;
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
        
        % x
        function meas = runMeasurement(obj, varargin)
            % request measurement value
            
            % init output
            meas.status    = NaN;
            meas.value     = NaN;
            meas.unit      = '';
            meas.overload  = NaN;
            meas.underload = NaN;
            meas.channel   = '';
            meas.parameter = '';
            meas.errorid   = NaN;
            meas.errormsg  = '';
            
            
            
            disp('ToDo ...');
            meas.status    = 0;
        end
        
        % x
        function waveData = captureWaveForm(obj, varargin)
            % download waveform data
            
            % init output
            waveData.status     = NaN;
            waveData.volt       = [];
            waveData.time       = [];
            waveData.samplerate = [];
            
            disp('ToDo ...');
            waveData.status = 0;
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
                    case 'stop', 
                        acqState = 'stopped (unfinished)';
                    case 'comp',   % complete    
                        acqState = 'stopped (finished and completed)';
                    case 'bre',    % break
                        acqState = 'stopped (finished but interrupted)';
                    case 'run',     
                        acqState = 'running';
                    otherwise, acqState = '';
                end
            end
        end
        
        % x
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