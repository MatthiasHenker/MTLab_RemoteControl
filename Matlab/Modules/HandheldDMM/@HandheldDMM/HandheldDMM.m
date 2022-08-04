classdef HandheldDMM < handle
    % documentation for class 'HandheldDMM'
    % ---------------------------------------------------------------------
    % This class provides functions for acquisition of handheld DMM
    % measurement values. At the moment very few handheld DMM types are
    % supported only. The DMM has to be connected to a serial port of the
    % computer. This class can be extended easily to support further
    % DMM types. See contact at end of this documentation.
    %
    % methods (static) of class 'HandheldDMM'
    %  - listSupportedPackages : displays informations about packages
    %     * usage:
    %           list = HandheldDMM.listSupportedPackages(showMsg)
    %       with
    %           showMsg  : optional input to enable/disable display output
    %                      (logical), default is true
    %           list     : optional output (cell array of char) with all
    %                      found DMM support packages
    %  - listSerialPorts: displays informations about serial ports
    %     * usage:
    %           [all, available, busy] = HandheldDMM.listSerialPorts(showMsg)
    %       with
    %           showMsg  : optional input to enable/disable display output
    %                      (logical), default is true
    %           all      : optional output (cell array of char) with all
    %                      found serial ports
    %           available: optional output (cell array of char) with all
    %                      availabe (non busy) ports
    %           busy      : optional output (cell array of char) with all
    %                      busy (non available) serial ports
    %  - doc : open web browser with help (alternatives to
    %          'help HandheldDMM' or 'doc HandheldDMM')
    %          * usage: HandheldDMM.doc
    %
    % See also contact at end of this documentation.
    % ---------------------------------------------------------------------
    %
    % methods (public) of class 'HandheldDMM':
    %   - HandheldDMM: constructor of this class (same name as class)
    %     * use this function to create an object for your DMM
    %     * usage:
    %           myDMM = HandheldDMM(type, port, showmsg);
    %       with
    %           myDMM  : object of class 'HandheldDMM'
    %                    (mandatory output, otherwise no use of this class)
    %           type   : DMM type (char), has to be in list of property
    %                    myDMM.SupportedDmmTypes (optional input: default
    %                    value is myDMM.SupportedDmmTypes{1})
    %                    use [] or '' for default
    %           port   : name of serial port (char), optional input 
    %                   (default is []),
    %                    use [] or '' for default,
    %                    use 'demo' for virtual DMM (no DMM needed),
    %                    this parameter can also be set later,
    %                    see property myDMM.Port
    %           showmsg: 0 or false for silent mode,
    %                    1 or true  for verbose mode
    %                    (optional input: default value is true)
    %                    use [] or '' for default
    %                    this parameter can also be changed later again,
    %                    see property myDMM.ShowMessages
    %   - delete     : destructor of this class
    %     * also disconnects and deletes serial object
    %     * usage:
    %           myDMM.delete
    %       without any input or output parameters
    %   - connect    : connect to serial interface
    %     * actual status of interface can be read via property
    %       myDMM.PortStatus
    %     * usage:
    %           status = myDMM.connect
    %       with
    %           status:  0 when okay      (optional output)
    %                   -1 when something went wrong
    %   - flush      : clears input buffer and resync to data stream again
    %     * use this function to remove all older measurement data in input
    %       buffer ==> use flush before read when measurement setup has
    %       changed to avoid reading old data
    %     * usage:
    %           status = myDMM.flush
    %       with
    %           status:  0 when okay      (optional output)
    %                   -1 when something went wrong
    %   - read       : fetch data from serial interface
    %     * a single measurement value will be fetched
    %     * optionally check myDMM.ValuesAvailable if more data is in the
    %       input buffer
    %     * read will wait for next measurement value when input buffer is
    %       empty (or timeout when e.g. DMM was switched off)
    %     * usage:
    %           [value, mode, status] = myDMM.read
    %       with
    %           value : measurement value without unit (double)
    %                   for unit see mode
    %           mode  : measurement mode like 'V', 'A', 'F', 'Ohm'
    %                   depends on manual setup at DMM
    %                   Attention: a prefix 'DC-' or 'AC-' is added for
    %                   'V' or 'A' resulting e.g. 'DC-V', 'AC-V' ...
    %           status:  0 when okay
    %                   -1 when something went wrong
    %   - disconnect  : disconnect serial interface
    %     * actual status of interface can be read via property
    %       myDMM.PortStatus
    %     * usage:
    %           status = myDMM.disconnect
    %       with
    %           status :  0 when okay      (optional output)
    %                    -1 when something went wrong
    %
    % properties of class 'HandheldDMM':
    %   - with read/write access
    %     * ShowMessages  : 1, true (default) for verbose mode
    %                       0, false          for silent mode
    %   - with read only access
    %     * Version        : version of this class file (char)
    %     * Date           : release date of this class file (char)
    %     * SupportedDmmTypes: list of supported DMMs (cell array of char)
    %     * DmmType        : selected DMM type (char)
    %     * MacrosName     : name of loaded package (same name as DmmType)
    %     * MacrosVersion  : version of loaded package
    %     * MacrosDate     : date of loaded package
    %     * SamplePeriod   : period between measurement values
    %                        (in s, double)
    %     * SupportedPorts : struct with
    %           .All       : string array with a found serial ports
    %           .Available : string array with availabe ports
    %           .Busy      : string array with busy ports
    %     * SupportedPorts : string array with all supported ports
    %     * Port           : selected serial port (string)
    %     * PortStatus     : current communication status open/close (char)
    %     * BytesAvailable : number of bytes in input buffer (double)
    %     * ValuesAvailable: number of meas values in input buffer (double)
    %     * DemoMode       : indicates demo mode (logical)
    %
    % example for usage of class 'HandheldDMM':
    %   HandheldDMM.listSupportedPackages  % display all supported DMMs
    %   HandheldDMM.listSerialPorts        % display all serial ports
    %   type    = 'VC820';
    %   port    = 'COM7';   % see HandheldDMM.listSerialPorts
    %   myDMM   = HandheldDMM(type, port);
    %   myDMM.connect;
    %   value = myDMM.read;
    %   % ...               % possibly change measurement setup
    %   myDMM.flush;        % empty queue
    %   value = myDMM.read; % read new data (old data was removed by flush)
    %   % ...
    %   myDMM.disconnect;
    %   myDMM.delete;
    %
    % ---------------------------------------------------------------------
    % HTW Dresden, faculty of electrical engineering
    %   for version and release date see properties 'Version' and 'Date'
    %
    % tested with
    %   - Matlab (version 9.10 = 2021a update 7) and additional
    %   - optional Instrument Control Toolbox (version 4.0)
    %   - optional NI-Visa 18.5 (download from NI, separate installation)
    %
    % currently supported DMM types:
    %   - UT61E by Uni-T: quite modern TrueRMS DMM, available at e.g.
    %     Reichelt.de (summer 2019, about 85 EUR incl. cable)
    %     ATTENTION: cable has to be modified (USB-HID to USB-virtualCOM)
    %   - VC820 by Voltcraft: quite old, available second hand only
    %   - VC830 by Voltcraft: available at e.g. Conrad.de (summer 2019,
    %     about 89 EUR)
    %
    % list of DMM which use the same type of cable and similar interface
    % protocol (it should be possible to extend this software to support
    % the following DMMs):
    %   - Voltcraft: VC820/30/40/50/70, VC920/40/60
    %   - Uni-T    : UT61B/C/D/E, UT71A/B/C/D/E
    %   - ???
    %
    % required cable to connect DMM with computer
    %  - at DMM with Photodiode (Rx only) and RS232 for computer
    %    (125640-ce-01-en-VOLTCRAFT_RS_232_SCHNITTSTELLENADAPTER @ Conrad)
    %  - for computer without RS232 use an additional adapter USB-to-RS232
    %    to get a virtual serial port at computer again
    %  - since about 2014 new cables with USB instead of RS232 are
    %    delivered instead => it does not provide a virtual serial port
    %    but USB-HID instead (Uni-T UT-D04 USB Adapterkabel) or
    %    (120317-an-01-de-Voltcraft_USB_SCHNITTSTELLENADPTER @ Conrad)
    %    => possible solution
    %    * open DMM adapter side and remove/desolder USB cable
    %    * the PCB inside the housing holds a photo-diode receiver stage
    %      with 5V TTL output which is connected to a Serial-to-USB-HID
    %      converter IC
    %    * desolder the series resistor between Rx-TTL stage and this
    %      converter IC and connect a USB-to-Serial cable (e.g. Raspberry
    %      Serial Cable) instead and close housing with some glue again
    %    => or implement a USB-HID to UART bridge
    %
    % known issues and planned extensions / fixes
    %   - code and interface was restructured
    %       * versions up to 1.1.2 (2019-10-01)
    %       * versions from 2.0.0  (2022-08-04), e.g. connect intead of
    %                                            open
    %   - no bugs reported so far (version 2.0.0)
    %   - add support of further DMMs available in labs of HTW Dresden
    %
    % initial versions (v0.x.x) created by
    %   - Jannis Seeger     (student, communications)
    %
    % further development, support and contact:
    %   - Matthias Henker   (professor)
    % ---------------------------------------------------------------------
    
    % ---------------------------------------------------------------------
    % some hints and notes for future extensions when an additional DMM
    % should be supported by this class  ==> how to add another DMM type:
    %
    % basic prerequisites:
    %     - DMM with serial interface
    %     - DMM sends data unidirectional without any requests from PC
    %     - DMM data structure is known (data sheet, internet)
    %     - each data block of received data represents one meas. value
    %
    % add package in folder +HandheldDMM
    % ---------------------------------------------------------------------
    
    properties (Constant = true)
        Version = '2.0.0';
        Date    = '2022-08-04';
    end
    
    properties (SetAccess = private, GetAccess = public)
        SupportedDmmTypes% list of all supported DMMs
        DmmType char ='';% DMM type
    end
    
    properties(Dependent, SetAccess = private, GetAccess = public)
        MacrosName       % package name
        MacrosVersion    % package version
        MacrosDate       % package date
        %
        SamplePeriod     % period (in s) of measurement values from DMM
        SerialPorts      % struct with port informations
        SupportedPorts   % string array with all supported ports
    end
    
    properties (Constant = true, GetAccess = private)
        % will be internally attached to public property 'SupportedPorts'
        AdditionalPorts = "DEMO";   % later ["DEMO", "USB-HID"] ?
    end
    
    properties
        Port string = "";% selected interface to DMM
    end
    
    properties(Dependent, SetAccess = private, GetAccess = public)
        PortStatus       % 'connected' or 'disconnected'
        BytesAvailable   % number of bytes in input buffer
        ValuesAvailable  % number of meas. values in input buffer
    end
    
    properties(SetAccess = private, GetAccess = public)
        DemoMode logical = false; % true when connected to 'serialportDemo'
    end
    
    properties
        ShowMessages logical = true;% print out more detailed information
    end
    
    properties (SetAccess = private, GetAccess = private)
        MacrosObj        % access to actual device specific macros
        SerialObj        % interface object of class serial (or demo)
        %
        Connected logical = false;
    end
    
    % ---------------------------------------------------------------------
    methods(Static)  % auxiliary
        
        function doc
            % Normally the command 'doc NAME_OF_FUNCTIONOR_CLASS' is used
            % to display the help text.
            %
            % This method opens a help windows using web-command.
            
            narginchk(0, 0);
            if nargin == 0
                className  = mfilename('class');
            end
            
            web(regexprep(which(className), '.p$', '.m'), ...
                '-new', '-notoolbar');
        end
        
        varargout = listSupportedPackages(varargin)
        
        varargout = listSerialPorts(varargin)
        
    end
    
    % ---------------------------------------------------------------------
    methods          % main
        
        function obj = HandheldDMM(type, port, showmsg)
            % Constructor for a serial DMM device object
            % for help see 'help HandheldDMM'
            
            % check available support packages for DMMs
            obj.SupportedDmmTypes = obj.listSupportedPackages(false);
            if isempty(obj.SupportedDmmTypes)
                % it makes no sense to go on further
                error('No support package for ''HandheldDMM'' found.');
            end
            
            % check input parameters
            %
            % check number of input arguments
            narginchk(0,3);
            
            % check input parameter 'showmsg'
            if nargin < 3 || isempty(showmsg)
                % use default value ==> nothing to do now
            else
                % try to set ShowMessages property (includes syntax check)
                obj.ShowMessages = showmsg;
            end
            
            % check input parameter 'port': is missing or empty
            if nargin < 2 || isempty(port)
                % use default value ==> nothing to do now
            else
                % try to set Port property (includes syntax check)
                obj.Port = port;
            end
            
            % check input parameter 'type'
            if nargin < 1 || isempty(type)
                % 'type' is missing or empty ==> use default value
                % default valaue is first in row
                type = obj.SupportedDmmTypes{1};
            elseif ~ischar(type) && ~(isscalar(type) && isstring(type))
                error(['First input argument (''type'') ' ...
                    'has to be a character array or string.']);
            else
                % convert to char array with uppercase letters
                type = char(upper(type));
                % exit when type is not supported
                if ~any(strcmpi(type, obj.SupportedDmmTypes))
                    disp(['Supported DMMs: ' ...
                        strjoin(obj.SupportedDmmTypes, ', ')]);
                    disp(['Your selection: ' type]);
                    disp('Your specified DMM type is not supported.');
                    error(['type ''HandheldDMM.listSupportedPackages'' to ' ...
                        'output all supported DMMs']);
                end
            end
            % check is done: set property
            obj.DmmType = type;
            
            % build up path to selected device package directory
            className  = mfilename('class');
            fString = [ ...
                className    '.' ...
                obj.DmmType  '.' ...
                className 'Macros'];
            fHandle = str2func(fString);
            % create object with actual macros for selected device
            try
                obj.MacrosObj = fHandle(obj);
                clear fHandle;
            catch ME
                disp(ME.identifier);
                error(['No support package accessible for: ' fString]);
            end
            
            % finally optionally print out some messages
            if obj.ShowMessages
                % search for serial ports at computer system
                obj.listSerialPorts(true);
                %
                disp(['Selected (serial) port           : ' ...
                    char(obj.Port) ' (disconnected)']);
                disp(['DMM type                         : ' ...
                    obj.DmmType]);
            end
            
        end
        
        function delete(obj)
            % destructor for a serial DMM device object
            
            % delete(disconnect) serial interface object
            obj.disconnect;
            
            % only run delete when object exists
            if ~isempty(obj.MacrosObj)
                % delete MacroObj
                obj.MacrosObj.delete;
            end
            
            % regular deletion of this class object follows now
            
            % print out message
            disp(['Object destructor called for class ' class(obj)]);
        end
        
        function status = connect(obj)
            % method to connect (create) the interface object
            % normally as serial interface, optionally as DEMO mode
            % (or possibly in future as USB-HID)
            
            % init
            status = NaN;
            
            if obj.Connected
                if obj.ShowMessages
                    disp(['Already connected to ''Port = ' ...
                        char(obj.Port) '''.']);
                end
                warning(['Interface port is already connected. ' ...
                    'Connection failed.']);
                status = -1;
                return
            end
            
            if obj.Port == ""
                if obj.ShowMessages
                    disp(['Set property ''Port'' to one of these ' ...
                        'serial ports:']);
                    disp(['  ' char(strjoin(obj.SupportedPorts, ', '))]);
                end
                warning(['Serial port (property ''Port'') is not ' ...
                    'defined (empty). Connection failed.']);
                status = -1;
                return
            end
            
            if strcmpi(obj.Port, 'DEMO')
                % demo mode for serialport (small own implementation)
                obj.SerialObj = serialportDemo();
                obj.Connected = true;
                obj.DemoMode  = true;
            else
                % create a new serial interface object
                try
                    obj.SerialObj = serialport( ...
                        obj.Port, ...
                        obj.MacrosObj.BaudRate, ...
                        'DataBits'   , obj.MacrosObj.DataBits   , ...
                        'StopBits'   , obj.MacrosObj.StopBits   , ...
                        'Parity'     , obj.MacrosObj.Parity     , ...
                        'FlowControl', obj.MacrosObj.FlowControl, ...
                        'ByteOrder'  , obj.MacrosObj.ByteOrder  , ...
                        'Timeout'    , obj.MacrosObj.Timeout    );
                    if ~isempty(char(obj.MacrosObj.Terminator))
                        obj.SerialObj.configureTerminator( ...
                            obj.MacrosObj.Terminator);
                    end
                catch ME
                    warning(['Connection to port ''' char(obj.Port) ...
                        ''' failed. (' ME.identifier ')']);
                    if obj.ShowMessages
                        disp('Serial ports:');
                        disp(obj.SerialPorts);
                    end
                    status = -1;
                    return
                end
                obj.DemoMode  = false;
                obj.Connected = true;
                % disable specific warning (e.g. timeout)
                warning('off', 'serialport:serialport:ReadlineWarning');
                
                % set DTR and RTS
                obj.SerialObj.setRTS(false); % RequestToSend     = 'off';
                obj.SerialObj.setDTR(true);  % DataTerminalReady = 'on';
                
                % finally clear input buffer and resync
                if (obj.flush)
                    status = -1;
                end
                
            end
            
            % set final status
            if isnan(status)
                status = 0;
            else
                status = -1;
            end
            
        end
        
        function status = disconnect(obj)
            % method to disconnect (delete) the interface object
            
            % init
            status = NaN;
            
            % delete serial object
            delete(obj.SerialObj);
            obj.Connected = false;
            obj.DemoMode  = false;
            
            % enaable specific warnings again
            warning('on', 'serialport:serialport:ReadlineWarning');
            
            % set final status
            if isnan(status)
                status = 0;
            else
                status = -1;
            end
        end
        
        function status = flush(obj)
            % method to clear input buffer and resync to data stream
            %
            % ToDo also output buffer??? see UT161E
            
            % init output variables
            status = NaN;
            
            if ~obj.Connected
                if obj.ShowMessages
                    disp('Serial port is not connected. Cannot read data.');
                end
                status = -1;
                return
            end
            
            % clear all data from input buffer (old measurement data)
            try
                obj.SerialObj.flush("input"); % input only?
            catch ME
                disp(['Method ''flush'' failed. ' ME.identifier]);
                status = -1;
                return
            end
            
            % -------------------------------------------------------------
            % now resync to data stream
            % good case: first received new data byte is also first byte
            %            of a data packet
            % bad  case: first received new data byte is not the first byte
            %            of a data packet
            % but we are not sure to have the good case
            % Solution:
            %   read one (possibly fragmentary) data packet until
            %   terminator is reached and drop this data packet
            try
                % there are two options:
                %   a) either data packets are separated by a 'Terminator'
                %   b) or we have to search for magic bytes
                foundTerminator = false; % init
                if isempty(obj.MacrosObj.BinaryTerminator)
                    % option a) readline detects regular 'Terminator'
                    for cnt = 1:2
                        if ~isempty(obj.SerialObj.readline)
                            foundTerminator = true;
                            break;
                        end
                    end
                else
                    % option b) read data bytes (one by one) until last
                    % data bytes is detected
                    count            = 1;
                    % wait for new data, fetch a single byte
                    % ==> there has to be a last byte every NumBytes
                    while ~foundTerminator
                        % check if received byte is last byte of packet
                        foundTerminator = any(obj.SerialObj.read( ...
                            obj.MacrosObj.NumBytes, 'uint8') == ...
                            obj.MacrosObj.BinaryTerminator);
                        if count == obj.MacrosObj.NumBytes
                            % something went wrong ==> no last byte found
                            status = -1;
                            break
                        end
                        count = count + 1;
                    end
                    % next byte in input buffer is first data byte
                    % of a new data packet ==> we are synchronized now
                end
            catch ME
                disp(['Connected to serial port but cannot read data ' ...
                    'from DMM. ' ME.identifier]);
                status = -1;
                return
            end
            if ~foundTerminator
                disp(['Connected to serial port but cannot receive ' ...
                    'any data from DMM.']);
                status = -1;
                return
            end
            
            % now all following data should be complete data packets
            if obj.ShowMessages
                disp(['Input buffer of serial interface flushed and ' ...
                    'resynced to DMM data stream.']);
            end
            
            % set final status
            if isnan(status)
                status = 0;
            else
                status = -1;
            end
        end
        
        function [value, mode, status] = read(obj)
            % fetch data from serial interface and convert data to
            % numerical value (double) as well as mode and status
            %
            % value : measurement value without unit
            % mode  : measurement mode like 'Ohm' ==> represents unit
            %         'V' for volts, 'A' for Ampere and so on
            %         for 'V' and 'A' a prefix 'DC-' or 'AC-' is added
            % status:  0 when okay
            %         -1 when something went wrong, see display messages
            
            % init output variables
            value  = NaN;
            mode   = '';
            status = NaN;
            
            if ~obj.Connected
                if obj.ShowMessages
                    disp('Serial port is not connected. Cannot read data.');
                end
                status = -1;
                return
            end
            
            % read one data packet (NumBytes)
            rawData = obj.SerialObj.read(obj.MacrosObj.NumBytes, 'uint8');
            rawData = transpose(double(rawData));
            
            % NumBytes from DMM represent one measurement value
            if length(rawData) ~= obj.MacrosObj.NumBytes
                % something went wrong: incorrect number of bytes
                status = -1;
                if obj.ShowMessages
                    disp(['Received incorrect number of bytes (' ...
                        num2str(length(rawData), '%d') ' instead of ' ...
                        num2str(obj.MacrosObj.NumBytes, '%d') ').']);
                end
            else
                % there is no standard how to interpret the data from DMM
                % thus, we have to convert the raw data by specific
                % functions according to selected DmmType
                [value, mode, cvtStat] = ...
                    obj.MacrosObj.convertData(rawData);
                if cvtStat
                    status = -1;
                end
                
                if obj.ShowMessages
                    disp(['DMM value: ' num2str(value, '%g') ...
                        ' ''' mode ''', status: ' num2str(cvtStat, '%d')]);
                end
            end
            
            % set final status
            if isnan(status)
                status = 0;
            else
                status = -1;
            end
        end
        
    end
    
    % ---------------------------------------------------------------------
    methods          % get/set methods
        
        function name = get.MacrosName(obj)
            % get method of property (dependent)
            name = obj.MacrosObj.MacrosName;
        end
        
        function version = get.MacrosVersion(obj)
            % get method of property (dependent)
            version = obj.MacrosObj.MacrosVersion;
        end
        
        function date = get.MacrosDate(obj)
            % get method of property (dependent)
            date = obj.MacrosObj.MacrosDate;
        end
        
        function SamplePeriod = get.SamplePeriod(obj)
            % get method of property (dependent)
            SamplePeriod = obj.MacrosObj.SamplePeriod;
        end
        
        function SerialPorts = get.SerialPorts(obj)
            [All, Available, Busy] = obj.listSerialPorts(false);
            % output (as strings)
            SerialPorts.All       = string(All);
            SerialPorts.Available = string(Available);
            SerialPorts.Busy      = string(Busy);
        end
        
        function SupportedPorts = get.SupportedPorts(obj)
            allSerialPorts = string(obj.listSerialPorts(false));
            SupportedPorts = [allSerialPorts, obj.AdditionalPorts];
        end
        
        function Port = get.Port(obj)
            % get method of property
            
            % the conversion to string is not really needed here
            % (it is already astring)
            Port = string(obj.Port);
        end
        
        function set.Port(obj, port)
            % set method of property
            
            % without return value (obj = ...) in a handle class
            
            % check input argument
            if obj.Connected           %#ok<MCSUP>
                if obj.ShowMessages    %#ok<MCSUP>
                    disp(['Disconnect port before changing settings. ' ...
                        'Property ''Port'' was not set.']);
                end
            elseif ischar(port) || (isstring(port) && isscalar(port))
                % convert to string with uppercase letters and set property
                port = string(upper(port));
                
                % check sensibility
                if any(port == obj.SupportedPorts) || port == "" %#ok<MCSUP>
                    obj.Port = port;
                elseif obj.ShowMessages    %#ok<MCSUP>
                    disp(['Invalid parameter value. Property ' ...
                        '''Port'' was not set.']);
                end
            elseif obj.ShowMessages    %#ok<MCSUP>
                disp(['Invalid parameter type. Property ' ...
                    '''Port'' was not set.']);
            end
        end
        
        function ShowMessages = get.ShowMessages(obj)
            % get method of property
            
            % the conversion to logical is not really needed here
            % (it is already an boolean)
            ShowMessages = logical(obj.ShowMessages);
        end
        
        function set.ShowMessages(obj, showMsg)
            % set method of property
            
            % without return value (obj = ...) in a handle class
            
            % check input argument
            if isscalar(showMsg) && ...
                    (islogical(showMsg) || isnumeric(showMsg))
                % convert to logical and set property
                obj.ShowMessages = logical(showMsg);
            elseif obj.ShowMessages
                disp(['Invalid parameter type. Property ' ...
                    '''ShowMessages'' was not changed.']);
            end
        end
        
        function PortStatus = get.PortStatus(obj)
            % get method of property
            
            if obj.Connected
                PortStatus = 'connected';
            else
                PortStatus = 'disconnected';
            end
        end
        
        function BytesAvailable = get.BytesAvailable(obj)
            if obj.Connected
                BytesAvailable = obj.SerialObj.NumBytesAvailable;
            else
                BytesAvailable = NaN;
            end
        end
        
        function ValuesAvailable = get.ValuesAvailable(obj)
            if obj.Connected
                ValuesAvailable = floor(obj.SerialObj.NumBytesAvailable ...
                    / obj.MacrosObj.NumBytes);
            else
                ValuesAvailable = NaN;
            end
        end
        
    end
    
end
