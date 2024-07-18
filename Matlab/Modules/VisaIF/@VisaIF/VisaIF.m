classdef VisaIF < handle
    % documentation for class 'VisaIF'
    % ---------------------------------------------------------------------
    % This class defines functions for the communication with measurement
    % devices (Visa). This is a basic class providing standard functions
    % for writing commands to and reading values from measurement devices.
    % This class is a wrapper for the Matlab 'visa' class coming with the
    % Instrument Control Toolbox to provide more convenience. Current focus
    % is set on measurement devices with USB or TCPIP interface. Devices
    % can be made accessible by adding device information to a config file.
    %
    % methods (static) of class 'VisaIF'
    %  - listAvailableConfigFiles : list path of config files
    %
    %  - listContentOfConfigFiles : list all device information stored in
    %                   config files
    %
    %  - listAvailableVisaUsbDevices : list all connected USB-TMC devices
    %
    %  - doc : open web browser with help (like 'help VisaIF') but in an
    %                   extra window
    %          * usage: VisaIF.doc
    %
    % See also contact at end of this documentation.
    % ---------------------------------------------------------------------
    % methods (public) of class 'VisaIF':
    %   - VisaIF  : constructor of this class (same name as class)
    %     * use this function to create an object for your Visa device
    %     * creates also an Visa object (visible in GUI of 'tmtool')
    %     * usage:
    %         myDevice = VisaIF(device, interface, showmsg);
    %         myDevice = VisaIF({device, serialID}, interface, showmsg);
    %       with
    %         myDevice: object of class 'VisaIF' (mandatory output)
    %         device  : device name (char, mandatory input), use the
    %                   command 'VisaIF.listContentOfConfigFiles' or
    %                   'VisaIF' to get a list of all accessible devices
    %         serialID: serial identifier of device with 'visa-usb'
    %                   interface (char, optional input), default value
    %                   is 1st found USB device, it's an ignored input for
    %                   'visa-tcpip', this parameter is only of interest
    %                   when more than one device of same type is connected
    %                   via USB, see 'VisaIF.listAvailableVisaUsbDevices'
    %         interface:specifies interface type (char), (optional input),
    %                   only of interest when more than one interface type
    %                   is supported for this device,
    %                   see VisaIF.SupportedInterfaceTypes,
    %                   run VisaIF.listContentOfConfigFiles to get a list
    %                   of all supported devices and respective interface
    %                   types, use [] or '' for default
    %         showmsg : 'none', 0 or false   for silent mode,
    %                   'few' or 1           for taciturn mode,
    %                   'all', 2, or true    for talkative mode,
    %                   (optional input: default value is 'all')
    %                   use [] or '' for default
    %                   this parameter can also be changed later again,
    %                   see property myDevice.ShowMessages
    %
    %   - delete  : destructor of this class
    %     * deletes VisaIF and visa object (and also execute close before)
    %     * usage:
    %           myDevice.delete
    %       without any input or output parameters
    %
    % General Notes:
    %     * methods with an output parameter 'status' behave identically
    %     * status has the same meaning for all those methods
    %         status   :  0 when okay
    %                    -1 when something went wrong
    %     * status output is optional
    %
    %   - open    : opens the visa interface
    %     * actual status of interface can be read via property
    %       myDevice.CommStatus
    %     * usage:
    %           status = myDevice.open or simply myDevice.open
    %
    %   - write   : send SCPI command to device
    %     * the SCPI command must NOT return a response (set command)
    %     * the SCPI command must be supported by device (see its manual)
    %     * usage:
    %           status = myDevice.write(VisaCommand)
    %       with
    %           VisaCommand : SCPI command (char)
    %
    %   - query   : send SCPI command to device and read back its response
    %     * the SCPI command must return a response (get command)
    %     * the SCPI command must be supported by device (see its manual)
    %     * usage:
    %           [VisaResponse, status] = myDevice.query(VisaCommand)
    %       with
    %           VisaResponse : response from device as binary (uint8)
    %                   use char(VisaResponse) to read in text form
    %           VisaCommand : SCPI command (char)
    %
    %   - identify: it's actually a specific query macro
    %     * the SCPI (get) command '*IDN?' is sent
    %     * equivalent to myDevice.query('*IDN?')
    %     * returns the Visa identifier of the device containing vendor
    %       name, device type, serial ID, software versions
    %     * works with all accessible devices
    %     * usage:
    %           [idnMessage, status] = myDevice.identify
    %       with
    %           idnMessage : response from device as text (char)
    %                   text is also stored in property myDevice.Identifier
    %
    %   - opc     : it's actually a specific query macro
    %     * the SCPI (get) command '*OPC?' is sent
    %     * equivalent to myDevice.query('*OPC?')
    %     * means 'operation complete?'
    %     * returns '1' when all previous commands are executed
    %     * works with most devices (except for e.g. Siglent-SPD3303X)
    %     * usage:
    %           [opcMessage, status] = myDevice.opc
    %       with
    %           opcMessage : response from device as text (char)
    %
    %   - reset   : it's actually a specific write macro
    %     * the SCPI (set) command '*RST' is sent
    %     * equivalent to myDevice.write('*RST')
    %     * initiate a device reset (no feedback from device)
    %     * works with most supported devices (except for e.g.
    %       Siglent-SPD3303X)
    %     * usage:
    %           status = myDevice.reset
    %
    %   - close   : closes the visa interface
    %     * actual status of interface can be read via property
    %       myDevice.CommStatus
    %     * usage:
    %           status = myDevice.close
    %
    % properties of class 'VisaIF':
    %   - with read/write access
    %     * ShowMessages     : 'all',  2, true (default) for talkative mode
    %                          'few',  1                 for taciturn mode
    %                          'none', 0, false          for silent mode
    %     * EnableCommandLog : 1, true            to enable notifications
    %                          0, false (default) no command logging
    %       (requires external VisaIFLogger and VisaIFLogEventData classes)
    %     * Timeout          : timeout in s
    %     * InputBufferSize  : size of input buffer
    %     * OutputBufferSize : size of output buffer
    %   - with read only access (constant, can be used as static property)
    %     * VisaIFVersion  : version of this class file (char)
    %     * VisaIFDate     : release date of this class file (char)
    %     * SupportedInstrumentClasses : lists all instrument classes
    %     * SupportedInterfaceTypes : lists all interface types
    %     * SupportedRsrcNames : format of resource names
    %   - with read only access (when object is created)
    %     * Device         : actually selected device (char)
    %     * Instrument     : type of instrument (char)
    %     * Identifier     : device response of *IDN? request (char)
    %     * Vendor         : name of vendor (for sub classes)
    %     * Product        : name of product family (for sub classes)
    %     * Name           : more readable than RsrcName (char)
    %     * RsrcName       : resource name required to create VisaObject
    %     * Alias          : alias name (if set in e.g. NI-MAX) (char)
    %     * Type           : out of SupportedInterfaceTypes (char)
    %     * RemoteHost     : ip-address, for type visa-tcpip only (char)
    %     * ManufacturerID : vendor ID, for type visa-usb only (char)
    %     * ModelCode      : product ID, for type visa-usb only (char)
    %     * SerialNumber   : serial ID, for type visa-usb only (char)
    %     * CommStatus     : current communication status open/close (char)
    %     * SupportedDevices: table of supported devices (table of chars)
    %
    % example for usage of class 'VisaIF':
    %   VisaIF.VisaIFVersion                % shows version
    %   VisaIF.listAvailableVisaUsbDevices  % shows connected USB devices
    %   VisaIF.listContentOfConfigFiles     % lists known devices
    %
    %   FgenName = 'Agilent-33220A'; % or e.g. just '33220' or 'Agi'
    %   myGen    = VisaIF(FgenName);
    %
    %   disp(['Vendor: ' myGen.Vendor]);    % shows property 'Vendor'
    %
    %   myGen.open;                         % opens interface
    %   myGen.write('FREQ 5231.789');       % set frequency in Hz
    %   myGen.query('FREQ?');               % query actually set frequency
    %   myGen.reset;                        % reset of measurement device
    %   ...
    %   myGen.close;                        % close interface
    %   myGen.delete;                       % deletes object
    %
    % ---------------------------------------------------------------------
    % HTW Dresden, faculty of electrical engineering
    %   for version and release date see properties 'VisaIFVersion' and
    %   'VisaIFDate'
    %
    % tested with
    %   - Matlab (version 9.10 = 2021a update 7) and
    %   - Instrument Control Toolbox (version 4.4)
    %   - NI-Visa 2022 Q3 (download from NI, separate installation)
    %
    % currently available measurement devices (lab in room S110):
    %   - device = 'Tek-TDS1001C-EDU' with interface = 'visa-usb'
    %        for Tektronix Scope (2 channels, 40MHz, 500MSa/s)
    %   - device = 'Agilent-33220A'   with interface = 'visa-usb'
    %        for Agilent Function Generator (20MHz)
    %
    % required setup (connection of visa device with computer)
    %  - either connect computer with measurement device via USB or LAN
    %  - measurement device must support visa
    %  - device information must be added to config file .\@VisaIF\*.csv
    %
    % known issues and planned extensions / fixes
    %   - no bugs reported so far (version 1.5.2) ==> winter term 2019/20
    %                             (version 2.4.1) ==> winter term 2020/21
    %                             (version 2.4.3) ==> summer term 2021
    %                             (version 2.4.4) ==> winter term 2022/23
    %
    % development, support and contact:
    %   - Constantin Wimmer (student, automation for VisaIFLogger class)
    %   - Matthias Henker   (professor)
    % ---------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % this VisaIF class is a wrapper for Matlab visa class for more
    % convenience (Instrument Control Toolbox)
    %
    % as introduction for basic visa class in Matlab see also instrhelp
    %
    % how to create a VISA-USB or VISA-TCPIP object connected either to a
    % USBTMC (USB Test & Measurement Class) or TCPIP instrument using
    % NI-VISA
    %
    % the VISA-Ressourcename can be obtained by using NI-MAX
    % or
    % by using tmtool in Matlab
    % or
    % by using matlab command
    % hwinfo = instrhwinfo('visa', 'ni')   % or 'rs'
    % hwinfo.ObjectConstructorName
    % result: e.g.
    % 'USB0::0xF4EC::0x1101::SDG6XBAC2R0003::INSTR' for SGD6022X
    % 'TCPIP0::192.168.178.11::INSTR'               for SGD6022X
    % e.g. vFgen = visa('ni','TCPIP0::192.168.178.11::INSTR');
    %
    % ---------------------------------------------------------------------



    %% ToDos
    % move from visa to visa dev
    %
    % update documentation
    %
    % test also with MAC computers




    properties(Constant = true)
        VisaIFVersion = '3.0.0';      % current version of VisaIF
        VisaIFDate    = '2024-07-18'; % release date
    end

    properties(SetAccess = private, GetAccess = public)
        Device        char = '';     % selected device
        Instrument    char = '';     % type of instrument
        Identifier    char = '';     % device response of *IDN? request
        Vendor        char = '';     %
        Product       char = '';     %
    end

    properties(Dependent = true)
        Name             % more readable than RsrcName
        RsrcName         % resource name of actual VisaObject
        Alias            % can be set externally ==> use NI-MAX instead
        %                      - select Tools => NI-VISA => VISA Options
        %                      - and add alias names
        Type             % visa-tcpip or visa-usb
        PreferredVisa    % NI, RS, Keysight
        RemoteHost       % for type visa-tcpip only
        ManufacturerID   % for type visa-usb only   ( VendorID)
        ModelCode        % for type visa-usb only   (ProductID)
        SerialNumber     %                          ( SerialID)
        VendorIdentified % reported vendor
        ProductIdentified% reported model
        Timeout          % will be initialized by constructor
        InputBufferSize  % ditto
        OutputBufferSize % ditto
        CommStatus       % communication status: open or closed
    end

    properties(SetAccess = private, GetAccess = public)
        SupportedDevices % table of supported devices in config files
    end

    properties(Constant = true)
        SupportedInstrumentClasses = { ...
            'Scope'             ...
            'DMM'               ...
            'FGen'              ...
            'DCPwr'             ...
            'ACPwr'             ...
            'Swtch'             ...
            'PwrMeter'          ...
            'SpecAn'            ...
            'RFSigGen'          ...
            'Counter'           ...
            'DownCnv'           ...
            'UpConv'            ...
            'Digitizer'         };
        SupportedInterfaceTypes    = { ...
            'visa-tcpip'        ...
            'visa-usb'          ...
            'demo'              };
        SupportedRsrcNames         = { ...
            '^TCPIP\S*$' ...
            '^USB\S*$'   ...
            '^DEMO$'            };
        % SupportedRsrcNames = { ...
        %     '^TCPIP\d?::\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}' ...
        %     '^USB\d?::0x[a-fA-F\d]+::0x[a-fA-F\d]+::' ...
        %     '^DEMO$'};     % original idea (above seems better)
    end

    properties
        ShowMessages             = 'all'; % talkative mode as default
        EnableCommandLog logical = false; % enable notifications for logs
    end

    properties(SetAccess = private, GetAccess = protected)
        DeviceName     char   % identifier displayed when ShowMessages on
    end

    properties(SetAccess = private, GetAccess = private)
        VisaObject            % interface object of class visa
        ExtraWait      double % optional extra pause between write & read
        CommandCounter double % SCPI command counter (write & read)
    end

    properties(Constant = true, GetAccess = private)
        MaxNumOfChars = 62; % max. number of characters shown in Visa
        % command history (notifications for external VisaIFLog) and
        % shown in optional display messages (see property ShowMessages)
    end

    events
        VisaIFLogEvent
    end

    % ---------------------------------------------------------------------
    methods(Static)  % auxiliary

        varargout = listAvailableConfigFiles

        varargout = listContentOfConfigFiles

        varargout = listAvailableVisaUsbDevices

        function doc(className)
            % Normally the command 'doc NAME_OF_FUNCTION_OR_CLASS' is used
            % to display the help text. Classes named FGen or Scope
            % conflict with other classes and cause troubles.
            %
            % This method open a help windows using web-command.

            narginchk(0, 1);
            if nargin == 0
                className  = mfilename('class');
            end

            web(regexprep(which(className), '.p$', '.m'), ...
                '-new', '-notoolbar');
        end

    end

    % ---------------------------------------------------------------------
    methods(Static, Access = protected)

        [selectedDevice, configTable] = filterConfigFiles( ...
            device, instrument, type, serialID) % ==> set to private ?

        varargout = listSupportedPackages(className)

    end

    methods(Static, Access = private)

        cfgTableOut = coerceConfigTable(cfgTableIn)

    end

    % ---------------------------------------------------------------------
    methods          % main

        function obj = VisaIF(device, interface, showmsg, instrument)
            % constructor for a VisaIF object
            %
            % either device = '<DeviceType>'
            % or     device = {'<DeviceType>', '<SerialId>'}

            % check number of input arguments
            narginchk(0, 4);

            % -------------------------------------------------------------
            % set default values when no input is given

            if nargin < 4 || isempty(instrument)
                instrument = '';
            end

            if nargin < 3 || isempty(showmsg)
                showmsg = '';
            end

            if nargin < 2 || isempty(interface)
                interface = '';
            end

            if nargin < 1 || isempty(device)
                device   = '';
            end

            % -------------------------------------------------------------
            % check input parameters

            if ~isempty(showmsg)
                % try to set ShowMessages property (includes syntax check)
                obj.ShowMessages = showmsg;
            end

            if iscell(device)
                % check if a specific SerialID (visa-usb only) is specified
                if numel(device) == 2
                    serialId = device{2};
                    device   = device{1};
                else
                    error(['First input parameter {device, serialID}' ...
                        'is not a cell array with two elements.']);
                end
            else
                serialId = '';
            end

            % -------------------------------------------------------------
            % device, serialID, interface are defined as char inputs now

            % search for a matching device
            [selectedDevice, configTable] = VisaIF.filterConfigFiles( ...
                device, instrument, interface, serialId);

            if isempty(selectedDevice)
                % exit when no matching device was found and
                % print out table with all supported devices as info
                disp(['First input argument has to be a device name ' ...
                    'listed in the following table:']);
                disp(configTable);
                error('Initialization failed.');
            else
                % save config table, obj.SupportedDevices (table) lists all
                % devices found in config files matching the specified
                % interface type and instrument class
                obj.SupportedDevices = configTable;
            end

            % selectedDevice (table) contains a single row with same
            % column names as obj.SupportedDevices, but all field entries
            % are chars or doubles; RsrcName points to a specific device
            % (no regexp anymore)

            % -------------------------------------------------------------
            % with 'visadev' no multiple objects for the same device can be
            % created ==> neither check necessary nor easily feasible
            %
            % no deletion of old visa object(s) before creating a new
            % visa object necessary

            % -------------------------------------------------------------
            % hurray, all preparations done:
            % a new Visa object can be created
            if ~strcmpi(selectedDevice.Type, 'demo')
                try
                    obj.VisaObject = visadev(selectedDevice.RsrcName);
                catch ME
                    if (strcmp(ME.identifier, ...
                            'instrument:interface:visa:multipleIdenticalResources'))
                        msg = ['constructor method of class VisaIF for ' ...
                            'resource ' selectedDevice.RsrcName ' failed.'];
                        causeException = MException('VisaIF:RsrcAlreadyExists', msg);
                        ME = addCause(ME, causeException);
                    end
                    % exit with error
                    rethrow(ME);
                end
            else
                obj.VisaObject = VisaDemo(selectedDevice.RsrcName);
            end

            obj.Device     = selectedDevice.Device;
            obj.Instrument = selectedDevice.Instrument;
            % define identifier which should be displayed in messages
            switch selectedDevice.Type
                case 'visa-tcpip'
                    obj.DeviceName = [char(obj.Instrument) ' ''' ...
                        char(obj.Device) ''' (' char(obj.RemoteHost) ')'];
                case 'visa-usb'
                    obj.DeviceName = [char(obj.Instrument) ' ''' ...
                        char(obj.Device) ''' (' char(obj.SerialNumber) ')'];
                otherwise
                    obj.DeviceName = [char(obj.Instrument) ' ''' ...
                        char(obj.Device) ''' (demo)'];
            end

            obj.Vendor     = selectedDevice.Vendor;
            obj.Product    = selectedDevice.Product;

            % -------------------------------------------------------------
            % last step before we can use the new Visa object
            % => configure some parameters

            % some common settings for all types of supported devices
            obj.VisaObject.Timeout      = 1;  % in s, default value is 10
            %                                    max value is 1000
            obj.VisaObject.ByteOrder    = 'little-endian';   % default
            %
            % defines if EOI (end or identify) line is asserted at end of
            % write operation ==> has to be 'on'
            obj.VisaObject.EOIMode      = 'on';              % default
            %
            % terminator for read and write communications (ASCII only)
            %obj.VisaObject.configureTerminator('CR/LF', 'LF');
            %
            % Rules for Completing a Read Operation
            %   For any EOSMode value, the read operation completes when:
            %   - The EOI line is asserted.
            %   - Specified number of values is read.
            %   - A timeout occurs.
            %   Additionally, if EOSMode is read or read&write (reading is
            %   enabled), then the read operation can complete when the
            %   EOSCharCode property value is detected. (for ASCII only)
            %
            %obj.VisaObject.EOSMode      = 'read&write';      % default
            % EOSCharCode is not of interest when EOSMode = 'none'
            % EOSCharCode depends on Terminator (see configureTerminator)

            % buffer sizes are defined in external config table
            obj.VisaObject.InputBufferSize  = selectedDevice.InBufSize;
            obj.VisaObject.OutputBufferSize = selectedDevice.OutBufSize;

            % pause parameter (between write and read in visa queries)
            obj.ExtraWait                   = selectedDevice.ExtraWait;

            if ~strcmp(obj.ShowMessages, 'none')
                disp([class(obj) ' object created.']);
            end

            % init command counter (for external command logging)
            obj.CommandCounter = 0;

            % disable timeout warnings while reading data from device
            warning('off', 'transportlib:client:ReadWarning');
        end

        function delete(obj)
            % destructor for a VisaIF object

            % enable timeout warnings again
            warning('off', 'transportlib:client:ReadWarning');

            % save value of property ShowMessages
            ShowMsgs = obj.ShowMessages;

            % close and delete visa instrument object again
            if ~isempty(obj.VisaObject) && isvalid(obj.VisaObject)
                % close should be silent anyway
                obj.ShowMessages = false;
                % there is no dedicated visadev close method but
                % it calls optional actions to restore instrument states
                obj.close;
            end

            % call delete in all cases (silent mode)
            % clearing the VISA object is closing the connection
            delete(obj.VisaObject);
            %obj.VisaObject = [];

            % print out message
            if ~strcmp(ShowMsgs, 'none')
                disp(['Object destructor called for class ' class(obj)]);
            end
        end

        function status = open(obj)
            % opens interface

            % init output
            status = NaN;

            % the interface was already opened in constructor method
            %
            % check actual state
            if ~strcmpi(obj.VisaObject.Status, 'open')
                % something went wrong
                status = -1; %#ok<NASGU>
                % error or warning
                error(['Connection to ''' ...
                    obj.DeviceName ''' could not be opened.']);
            else

                if ~strcmpi(obj.ShowMessages, 'none')
                    disp(['Connection to ''' obj.DeviceName ''' is open.']);
                    disp(['VisaIF: Open method only executes optional hook to ' ...
                        'configure required settings of connected device '''  ...
                        obj.DeviceName '''.']);
                end

                % test communication with device by requesting
                % identifier ('*IDN?')
                [~, status_idn] = obj.identify;
                if status_idn
                    status = -1;
                end
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end

        end

        function status = close(obj)
            % to close interface

            % init output
            status = NaN;

            if ~strcmpi(obj.ShowMessages, 'none')
                disp(['VisaIF: Close method only executes optional hook to ' ...
                    'restore states of connected device '''  ...
                    obj.DeviceName '''.']);
                disp(['        Actually you will have to run the ' ...
                    'delete method to close the interface.']);
            end

            % actual state of obj.VisaObject.Status is still 'open'
            % instead of 'closed'

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end

        end

        % -----------------------------------------------------------------
        % some notes about write, read, query:
        %
        % the 'VisaCommand' (SCPI command) can be either
        %  - a set command (command string does not end with a '?') or
        %  - a get command (command string ends with a '?')
        %  - Note: the '?' cannot be used as rule, there are some exceptions
        %
        % Matlab provides two dedicated functions for both types
        %  - 'fprintf(VisaObject, VisaCommand);'
        %      for set commands
        %  - '[VisaResponse, ResLength, ErrMsg] = ...
        %                        query(VisaObject, VisaCommand,'%s','%s')'
        %      for get commands or
        %      alternatively with 'fprintf(VisaObject, VisaCommand);' and
        %      '[VisaResponse, RespLength, ErrMsg] = ...
        %                        fscanf(VisaObject,'%s');
        %
        % both commands work fine a regular string based SCPI commands,
        % but problems come up when
        %  - binary data (or mixed form: ASCII + binary) should be
        %    transferred or
        %  - response (get command) is not available immediately
        %
        % selected solution:
        %  - cast VisaCommand to 'uint8' and use 'fwrite' intead of
        %    'fprintf' to send binary data to VisaObject
        %  - use binary 'fread' instead of fscanf to read data and
        %    convert data to ASCII later
        %  - use separate write and read functions with optional ExtraWait
        %    between write & read actions
        %
        % sounds great, but ...
        %  - we have to know if read data is plain text or contains binary
        %  - we do not know when end of line is reached ==> when using
        %    fscanf the EOSChar can be used as indicator for end of
        %    message

        function status = write(obj, VisaCommand)
            % to write a Visa command to device

            % init output
            status = NaN;

            if nargin < 2
                VisaCommand = '';
            end

            if ischar(VisaCommand)
                % cast to binary
                VisaCommand = uint8(VisaCommand);
            elseif isa(VisaCommand, 'uint8')
                % fine
            else
                status = -1;
                disp(['Visa write: Error - Visa command must be a ' ...
                    'char array or uint8.']);
                VisaCommand = '';
            end

            if isempty(VisaCommand)
                status = -1;
                disp(['Visa write: Error - Visa command is empty. ' ...
                    'Skip write command.']);
            else
                % write VisaCommand to device (as binary data)
                fwrite(obj.VisaObject, VisaCommand, 'uint8');
                % optionally display message and log command in history
                obj.ShowAndLogSCPICommand('write', VisaCommand);
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function [VisaResponse, status] = query(obj, VisaCommand)
            % to query a Visa command to device

            % init output
            VisaResponse = uint8([]);
            status       = NaN;

            if nargin < 2 || isempty(VisaCommand)
                status = -1;
                disp(['Visa query: Error - Visa command is empty. ' ...
                    'Skip query command.']);
            else
                % write Visa command to device
                if 0 ~= obj.write(VisaCommand)
                    status = -1;
                end
            end

            if ~isnan(status)
                status = -1;
                disp(['Visa query: Error - Write was not successful. ' ...
                    'Skip read command.']);
            else
                % read back response

                % optional extra wait
                if obj.ExtraWait > 0
                    % save current state and activate pause feature
                    PauseState = pause('on');
                    % run a short pause before next try
                    pause(obj.ExtraWait);
                    % restore original state
                    pause(PauseState);
                end

                % now read response (in binary format)
                %
                % the number of bytes to receive is not known beforehand
                % ==> maximum number is requested (InputBufferSize)
                %     but normally less data are available
                % ==> normally an error will pop up (timeout, ...)

                VisaResponse = read( ...
                    obj.VisaObject, ...
                    obj.VisaObject.InputBufferSize, 'uint8');

                ErrMsg = '';


                % check error message
                expectedErrorText = {...
                    ['The EOI line was asserted before SIZE values ' ...
                    'were available'], ...
                    'XYZ second error text (for future use)'};

                if isempty(ErrMsg)
                    ErrMsg = ''; % replace ErrMsg = [] by ''
                elseif contains(ErrMsg, expectedErrorText)
                    % also clear error meassage again
                    ErrMsg = '';
                end
                if ~isempty(ErrMsg)
                    status = -1;
                    disp(['Visa query: Error - ' ErrMsg]);
                end

                % fread/read is converting binary data to double at the end
                % ==> revert this action
                VisaResponse = uint8(VisaResponse);

                % convert to row vector if needed
                if iscolumn(VisaResponse)
                    VisaResponse = transpose(VisaResponse);
                end

                % check response: last character should be a 'LF'
                if isempty(VisaResponse)
                    % no response at all
                    status       = -1;     % allowed state ???
                    if ~strcmpi(obj.ShowMessages, 'none')
                        disp(['Visa query: Warning - Empty message ' ...
                            '(0 bytes received) from ' obj.DeviceName ]);
                    end
                elseif VisaResponse(end) == 10 % 'LF' = \n = char(10)
                    % remove last character (= obj.VisaObject.EOSCharCode)
                    VisaResponse = VisaResponse(1:end-1);
                else
                    % 'LF' is missing
                    % some devices show missing LF sometimes, but response
                    % was always still okay (except for missing LF)
                    status       = -1;
                    if ~strcmpi(obj.ShowMessages, 'none')
                        disp(['Visa query: Warning - ''LF'' as last ' ...
                            'character in response is missing.']);
                    end
                end
            end

            % optionally display message and log command in history
            obj.ShowAndLogSCPICommand('read', VisaResponse);

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        % -----------------------------------------------------------------
        % some notes about standard SCPI commands:
        %
        % *IDN? (identify): works with all supported devices
        % *OPC? (opc)     : not implemented at Siglent DC-Power Supply
        % *RST  (reset)   : not implemented at Siglent DC-Power Supply

        function [idnMessage, status] = identify(obj)
            % request identifier (*IDN?) and update property Identifier

            % init output
            idnMessage = '';
            status     = NaN;

            VisaCommand = '*IDN?';
            [VisaResponse, status_query]  = obj.query(VisaCommand);

            if status_query ~= 0
                status = -1;
            else
                idnMessage     = char(VisaResponse);
                obj.Identifier = idnMessage;
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function [opcMessage, status] = opc(obj)
            % request operation complete state (*OPC?)

            % init output
            opcMessage = '';
            status     = NaN;

            VisaCommand = '*OPC?';
            [VisaResponse, status_query]  = obj.query(VisaCommand);

            if status_query ~= 0
                status = -1;
            else
                opcMessage     = char(VisaResponse);
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = reset(obj)
            % send reset command (*RST)

            % init output
            status     = NaN;

            % clear buffers (for visa-usb only)
            clrdevice(obj.VisaObject);

            VisaCommand = '*RST';
            status_write  = obj.write(VisaCommand);

            if status_write ~= 0
                status = -1;
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = clrdevice(obj)
            % clear buffers (for visa-usb only)

            % init output
            status     = NaN;

            % actual clear command
            clrdevice(obj.VisaObject);

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

    end

    % ---------------------------------------------------------------------
    methods(Access = private)

        function ShowAndLogSCPICommand(obj, mode, VisaCommand)
            % optionally display message (sent/received SCPI command)
            %  ==> depends on obj.ShowMessages
            % optionally sent event notification to external listener to
            % enable a shared visa command history for all measurement
            % devices
            %  ==> depends on obj.EnableCommandLog

            % -------------------------------------------------------------
            if strcmpi(obj.ShowMessages, 'all') || obj.EnableCommandLog
                % display and log only heading characters of Visa commands
                % cut out header of Visa command and convert to char
                % replace all lower ASCII characters (0:31) by 'space' (32)
                VisaCommandHead = char(max(32, VisaCommand( ...
                    1 : min(length(VisaCommand), obj.MaxNumOfChars))));
            end

            % -------------------------------------------------------------
            % display messages
            switch lower(mode)
                case 'write'
                    % update command message counter
                    obj.CommandCounter = obj.CommandCounter + 1;

                    if strcmpi(obj.ShowMessages, 'all')
                        disp(['SCPI: ' obj.DeviceName]);
                        disp(['  ''' VisaCommandHead ''' (' ...
                            num2str(length(VisaCommand)) ' bytes sent).']);
                    end
                case 'read'
                    if strcmpi(obj.ShowMessages, 'all')
                        % no headline (response belongs to prev. write)
                        disp(['  ''' VisaCommandHead ''' (' ...
                            num2str(length(VisaCommand)) ' bytes ' ...
                            'received).']);
                    end
                otherwise
                    error('VisaIF: Invalid command mode. Fix Code.');
            end

            % -------------------------------------------------------------
            % sent notification to external logging class
            if obj.EnableCommandLog
                notify(obj, 'VisaIFLogEvent', ...
                    VisaIFLogEventData( ...
                    obj.CommandCounter , ...
                    obj.Device         , ...
                    mode               , ...
                    VisaCommandHead    , ...
                    length(VisaCommand)));
            end

        end

    end

    % ---------------------------------------------------------------------
    methods           % get/set methods

        function showmsg = get.ShowMessages(obj)
            % get method of property

            showmsg = obj.ShowMessages;
        end

        function set.ShowMessages(obj, showmsg)
            % set method of property

            % without return value (obj = ...) in a handle class

            % check input argument
            if ischar(showmsg)
                showmsg = lower(showmsg);
            elseif isscalar(showmsg) && ...
                    (islogical(showmsg) || isnumeric(showmsg))
                showmsg = round(double(showmsg));
            elseif isempty(showmsg)
                % do nothing
                if ~strcmp(obj.ShowMessages, 'none')
                    disp(['Empty parameter value for property ' ...
                        '''ShowMessages''. Ignore input.']);
                end
                return
            elseif ~strcmp(obj.ShowMessages, 'none')
                disp(['Invalid parameter type for property ' ...
                    '''ShowMessages''.']);
                return
            end

            % convert and set property
            switch showmsg
                case {'none', 0}
                    obj.ShowMessages = 'none';
                case {'few' , 1}
                    obj.ShowMessages = 'few';
                case {'all' , 2}
                    obj.ShowMessages = 'all';
                otherwise
                    if ~strcmp(obj.ShowMessages, 'none')
                        disp(['Invalid parameter value for property ' ...
                            '''ShowMessages''. Ignore input.']);
                    end
            end
        end

        function enableLog = get.EnableCommandLog(obj)
            % get method of property

            % nothing to do here: it is a logical by property declaration
            enableLog = obj.EnableCommandLog;
        end

        function set.EnableCommandLog(obj, enableLog)
            % set method of property

            % nothing to do here: it is a logical by property declaration
            obj.EnableCommandLog = enableLog;
        end

        function Status = get.CommStatus(obj)
            try
                Status = obj.VisaObject.Status;
            catch ME
                if (strcmp(ME.identifier,'MATLAB:structRefFromNonStruct'))
                    Status = 'closed';
                else
                    Status = 'unknown';
                    %rethrow(ME)
                end
            end
        end

        function Name = get.Name(obj)
            Name = obj.VisaObject.Name;
        end

        function RsrcName = get.RsrcName(obj)
            RsrcName = obj.VisaObject.RsrcName;
        end

        function Alias = get.Alias(obj)
            Alias = obj.VisaObject.Alias;
        end

        function Type = get.Type(obj)
            Type = obj.VisaObject.Type;
        end

        function PreferredVisa = get.PreferredVisa(obj)
            PreferredVisa = obj.VisaObject.PreferredVisa;
        end

        function RemoteHost = get.RemoteHost(obj)
            % visa-tcpip only
            RemoteHost = obj.VisaObject.InstrumentAddress;
        end

        function ManufacturerID = get.ManufacturerID(obj)
            % visa-usb only
            ManufacturerID = obj.VisaObject.VendorID;
        end

        function ModelCode = get.ModelCode(obj)
            % visa-usb only
            ModelCode = obj.VisaObject.ProductID;
        end

        function SerialNumber = get.SerialNumber(obj)
            % of connected instrument device
            SerialNumber = obj.VisaObject.SerialNumber;
        end

        function VendorIdentified = get.VendorIdentified(obj)
            VendorIdentified = obj.VisaObject.Vendor;
        end

        function ProductIdentified = get.ProductIdentified(obj)
            ProductIdentified = obj.VisaObject.Model;
        end

        function Timeout = get.Timeout(obj)
            Timeout = obj.VisaObject.Timeout;
        end

        function set.Timeout(obj, Timeout)

            % check input argument
            if isscalar(Timeout) && isnumeric(Timeout) ...
                    && isreal(Timeout) && Timeout > 0
                % check and limit
                Timeout = double(Timeout);
                % set property
                obj.VisaObject.Timeout = Timeout;
            else
                disp(['Invalid parameter value for property ' ...
                    '''Timeout''. Ignore input.']);
            end
        end

        function InputBufferSize = get.InputBufferSize(obj)
            InputBufferSize = obj.VisaObject.InputBufferSize;
        end

        function set.InputBufferSize(obj, InputBufferSize)

            % check input argument
            if isscalar(InputBufferSize) && isnumeric(InputBufferSize) ...
                    && isreal(InputBufferSize) && InputBufferSize > 0
                % check and limit
                InputBufferSize = ceil(double(InputBufferSize));
                % set property
                obj.VisaObject.InputBufferSize = InputBufferSize;
            else
                disp(['Invalid parameter value for property ' ...
                    '''InputBufferSize''. Ignore input.']);
            end
        end

        function OutputBufferSize = get.OutputBufferSize(obj)
            OutputBufferSize = obj.VisaObject.OutputBufferSize;
        end

        function set.OutputBufferSize(obj, OutputBufferSize)

            % check input argument
            if isscalar(OutputBufferSize) && isnumeric(OutputBufferSize) ...
                    && isreal(OutputBufferSize) && OutputBufferSize > 0
                % check and limit
                OutputBufferSize = ceil(double(OutputBufferSize));
                % set property
                obj.VisaObject.OutputBufferSize = OutputBufferSize;
            else
                disp(['Invalid parameter value for property ' ...
                    '''OutputBufferSize''. Ignore input.']);
            end
        end

        function tableOfDevices = get.SupportedDevices(obj)
            tableOfDevices = obj.SupportedDevices;
        end

        function set.SupportedDevices(obj, tableOfDevices)
            obj.SupportedDevices = tableOfDevices;
        end

    end

end
