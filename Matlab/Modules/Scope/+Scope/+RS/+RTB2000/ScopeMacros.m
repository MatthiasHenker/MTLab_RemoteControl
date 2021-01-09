classdef ScopeMacros < handle
    % ToDo documentation
    %
    %
    % for Scope: Rohde&Schwarz RTB2000 series
            
    properties(Constant = true)
        MacrosVersion = '0.1.1';      % release version
        MacrosDate    = '2021-01-09'; % release date
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
            
            disp('ToDo ...');
            % add some device commands:
            %
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
    
    % ------- main scope macros -------------------------------------------
    methods
        
        function status = clear(obj)
            % clear status at scope
            status = obj.VisaIFobj.write('*CLS');
        end
                 
        function status = lock(obj)
            % lock all buttons at scope
            
            disp('ToDo ...');
            status = 0;
        end
        
        function status = unlock(obj)
            % unlock all buttons at scope
            
            disp('ToDo ...');
            status = 0;
        end
        
        function status = acqRun(obj)
            % start data acquisitions at scope
            
            disp('ToDo ...');
            status = 0;
        end
        
        function status = acqStop(obj)
            % stop data acquisitions at scope
            
            disp('ToDo ...');
            status = 0;
        end
        
        function status = autoset(obj)
            % causes the oscilloscope to adjust its vertical, horizontal,
            % and trigger controls to display a stable waveform
            
            disp('ToDo ...');
            status = 0;
        end
        
        % -----------------------------------------------------------------
        
        function status = configureInput(obj, varargin)
            % configure input channels
            
            disp('ToDo ...');
            status = 0;
        end
        
        function status = configureAcquisition(obj, varargin)
            % configure acquisition parameters
            
            disp('ToDo ...');
            status = 0;
        end
        
        function status = configureTrigger(obj, varargin)
            % configure trigger parameters
            
            disp('ToDo ...');
            status = 0;
        end
        
        function status = configureZoom(obj, varargin)
            % configure zoom window
            
            disp('ToDo ...');
            status = 0;
        end
        
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
            % get acquisition state (run or stop)
            
            disp('ToDo ...');
            acqState = '<undefined>';
        end
        
        function trigState = get.TriggerState(obj)
            % get trigger state (ready, auto, triggered)
            
            disp('ToDo ...');
            trigState = '<undefined>';
        end
        
        function errMsg = get.ErrorMessages(obj)
            % read error list from the scope’s error buffer
            
            disp('ToDo ...');
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