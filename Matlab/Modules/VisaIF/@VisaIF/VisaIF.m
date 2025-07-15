classdef VisaIF < handle
    % documentation for class 'VisaIF'
    % ---------------------------------------------------------------------
    % This class defines functions for the communication with measurement
    % devices (Visa). This is a basic class providing standard functions
    % for writing commands to and reading values from measurement devices.
    % This class is a wrapper for the Matlab 'visadev' class coming with the
    % Instrument Control Toolbox to provide more convenience. Current focus
    % is set on measurement devices with USB or TCPIP interface. Devices
    % can be made accessible by adding device information to the config file.
    %
    % methods (static) of class 'VisaIF'
    %  - listAvailableConfigFiles : list path to all config files
    %
    %  - listContentOfConfigFiles : list all device information stored in
    %                   the config files
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
    %     * measurement device has to be available, connection to device
    %       will be opened by constructor
    %     * usage:
    %         myDevice = VisaIF(device);
    %         myDevice = VisaIF(device, interface);
    %         myDevice = VisaIF(device, interface, showmsg);
    %         myDevice = VisaIF({device, serialID}, interface, showmsg);
    %         myDevice = VisaIF(device, interface, {showmsg, enablelog});
    %       with
    %         myDevice: object of class 'VisaIF' (mandatory output)
    %         device  : device name (char, mandatory input), use the
    %                   command 'VisaIF.listContentOfConfigFiles' or
    %                   'VisaIF' to get a list of all known devices
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
    %          enablelog : 0 or false        for disabled logging mode,
    %                   1 or true            for enabled logging mode,
    %                   (optional input: default value is false)
    %                   this parameter can also be changed later again,
    %                   see property myDevice.EnableCommandLog
    %
    %   - delete  : destructor of this class
    %     * deletes 'VisaIF' and internal 'visadev' object (also closes
    %       interface to device before)
    %     * usage:
    %           myDevice.delete
    %       without any input or output parameters
    %
    % General Notes:
    %     * methods with an output parameter 'status' behave identically
    %     * status has the same meaning for all those methods
    %         status   : == 0 when okay
    %                    != 0 when something went wrong
    %     * status output is optional
    %
    %   - open, close  : does nothing, methods will be removed in future,
    %       interface to device will be opened/closed by constructor/destructor
    %
    %   - write   : send SCPI command to device
    %     * the SCPI command must NOT return a response (set command) or
    %       the response is fetched by following read command
    %     * the SCPI command must be supported by device (see its manual)
    %     * the SCPI command can be text or binary data
    %     * usage:
    %           status = myDevice.write(VisaCommand);
    %       with
    %           VisaCommand : SCPI command (char)
    %
    %   - read    : read SCPI response from device
    %     * the SCPI response is treated as binary data (works for text and
    %       binary data)
    %     * method waits for response a specified period (see property Timeout)
    %     * usage:
    %           [VisaResponse, status]  = myDevice.read;
    %       with
    %           VisaResponse : response from device as binary (uint8)
    %                   use char(VisaResponse) to read in text form
    %
    %   - query   : send SCPI command to device and read back its response
    %     * the SCPI command must return a response (get command)
    %     * the SCPI command must be supported by device (see its manual)
    %     * The SCPI command and its response MUST be text (does not
    %       support binary data!)
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
    %     * works with nearly all devices (except for e.g. Siglent-SPD3303X)
    %     * usage:
    %           [opcMessage, status] = myDevice.opc
    %       with
    %           opcMessage : response from device as text (char)
    %
    %   - reset   : it's actually a specific write macro
    %     * the SCPI (set) command '*RST' is sent
    %     * equivalent to myDevice.write('*RST')
    %     * initiate a device reset (no feedback from device)
    %     * works with nearly all devices (except for e.g. Siglent-SPD3303X)
    %     * usage:
    %           status = myDevice.reset
    %
    % properties of class 'VisaIF':
    %   - with read/write access
    %     * ShowMessages     : 'all',  2, true (default) for talkative mode
    %                          'few',  1                 for taciturn mode
    %                          'none', 0, false          for silent mode
    %     * EnableCommandLog : 1, true            to enable notifications
    %                          0, false (default) no command logging
    %       (requires additional VisaIFLogger and VisaIFLogEventData classes)
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
    %     * Vendor         : name of vendor         (addresses required package)
    %     * Product        : name of product family (addresses required package)
    %     * VendorIdentified : reported vendor by device (USB only)
    %     * ProductIdentified: reported model  by device (USB only)
    %     * PreferredVisa  : name of used Visa driver (NI, RS or Keysight)
    %     * Name           : more readable than RsrcName (char)
    %     * RsrcName       : resource name required to create VisaObject
    %     * Alias          : alias name (if set in e.g. NI-MAX) (char)
    %     * Type           : out of SupportedInterfaceTypes (char)
    %     * RemoteHost     : ip-address, for type visa-tcpip only (char)
    %     * ManufacturerID : vendor ID, for type visa-usb only (char)
    %     * ModelCode      : product ID, for type visa-usb only (char)
    %     * SerialNumber   : serial ID, for type visa-usb only (char)
    %     * CommStatus     : communication status, always stated as open (char)
    %     * SupportedDevices: table of supported devices (table of chars)
    %
    % example for usage of class 'VisaIF':
    %   VisaIF.VisaIFVersion                % shows version of class
    %   VisaIF.listAvailableVisaUsbDevices  % list all connected USB devices
    %   VisaIF.listContentOfConfigFiles     % lists all known devices
    %
    %   FgenName = 'Agilent-33220A'; % or e.g. just '33220' or 'Agi'
    %   myGen    = VisaIF(FgenName);
    %
    %   disp(['Vendor: ' myGen.Vendor]);    % shows property 'Vendor'
    %
    %   myGen.write('FREQ 5231.789');       % set frequency in Hz
    %   myGen.query('FREQ?');               % query actually set frequency
    %   myGen.reset;                        % reset of measurement device
    %   ...
    %   myGen.delete;                       % deletes object
    %
    % ---------------------------------------------------------------------
    % HTW Dresden, faculty of electrical engineering
    %   for version and release date see properties 'VisaIFVersion' and
    %   'VisaIFDate'
    %
    % tested with
    %   - Matlab (version 24.1 = 2024a update 6) and
    %   - Instrument Control Toolbox (version 24.1)
    %   - NI-Visa 2022 Q3 (download from NI, separate installation)
    %
    % required setup:
    %  - connect computer with measurement device via either USB or LAN
    %  - measurement device must support VISA
    %  - device information must be added to config file .\@VisaIF\*.csv
    %
    % known issues and planned extensions / fixes
    %   - no bugs reported so far (version 1.5.2) ==> winter term 2019/20
    %                             (version 2.4.1) ==> winter term 2020/21
    %                             (version 2.4.3) ==> summer term 2021
    %                             (version 2.4.4) ==> winter term 2022/23
    %                             (version 3.0.0) ==> winter term 2024/25
    %
    % development, support and contact:
    %   - Constantin Wimmer (student, automation)
    %   - Matthias Henker   (professor)
    % ---------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % this VisaIF class is a wrapper for Matlab 'visadev' class for more
    % convenience (Instrument Control Toolbox)
    %
    % see also help of Instrument Control Toolbox
    %
    % how to create a VISA-USB or VISA-TCPIP object connected either to a
    % USBTMC (USB Test & Measurement Class) or TCPIP instrument using
    % NI-VISA
    %
    % the VISA-Ressourcename can be obtained by using NI-MAX
    % or
    % by using 'visadevlist' in Matlab
    % result: e.g.
    % 'USB0::0xF4EC::0x1101::SDG6XBAC2R0003::INSTR' for SGD6022X
    % 'TCPIP0::192.168.178.11::INSTR'               for SGD6022X
    % e.g. vFgen = visadev('TCPIP0::192.168.178.11::INSTR');
    %
    % ---------------------------------------------------------------------

    properties(Constant = true)
        VisaIFVersion = '3.0.2';      % current version of VisaIF
        VisaIFDate    = '2025-07-15'; % release date
    end

    properties(SetAccess = private, GetAccess = public)
        Device        char = '';     % selected device
        Instrument    char = '';     % type of instrument
        Identifier    char = '';     % device response of *IDN? request
        Vendor        char = '';     %
        Product       char = '';     %
    end

    properties(Dependent = true)
        Name             % <unused>, will be removed in future
        %                  (more descriptive name than RsrcName)
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
            'DCPwr'             ...
            'DMM'               ...
            'FGen'              ...
            'Scope'             ...
            'SMU'               ...
            'SpecAn'                 };
          % more instrument classes for future use
          % 'Digitizer'
          % 'ACPwr'
          % 'Counter'
          % 'Swtch'
          % 'PwrMeter'
          % 'RFSigGen'
          % 'DownCnv'
          % 'UpConv'
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
        MaxNumOfChars = 100; % max. number of characters shown in Visa
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
            % either device  = '<DeviceType>'
            % or     device  = {'<DeviceType>', '<SerialId>'}
            %
            % either showmsg = '<ShowMsgStr>'
            % or     showmsg = {'<ShowMsgStr>', '<EnableLogStr>'}

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

            if iscell(showmsg)
                if numel(showmsg) == 2
                    % try to set properties
                    obj.EnableCommandLog = showmsg{2};
                    obj.ShowMessages     = showmsg{1};
                else
                    error(['Third input parameter {showmsg, enablelog}' ...
                        'is not a cell array with two elements.']);
                end
            else
                if ~isempty(showmsg)
                    % try to set ShowMessages property (includes syntax check)
                    obj.ShowMessages = showmsg;
                end
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
            % created ==> no check and no deletion of old visa object(s) before
            % creating a new visa object is necessary

            % -------------------------------------------------------------
            % hurray, all preparations done:
            % a new Visa object can be created
            if ~strcmpi(selectedDevice.Type, 'demo')
                try
                    % try to access wanted device and create object
                    obj.VisaObject = visadev(selectedDevice.RsrcName);
                catch ME
                    switch ME.identifier
                        case 'instrument:interface:visa:multipleIdenticalResources'
                            disp(['Object for specified resource ''' ...
                                selectedDevice.RsrcName ''' already exists ' ...
                                'and its interface is open.']);
                        case 'instrument:interface:visa:unableToDetermineInterfaceType'
                            disp(['Specified resource ''' selectedDevice.RsrcName ...
                                ''' was not found.']);
                        otherwise
                            disp(['Unknown error: ' ME.identifier]);
                    end
                    % exit with error
                    %rethrow(ME);
                    %throw(ME);
                    error(['Constructor method of class ''' class(obj) ...
                        ''' for resource ''' selectedDevice.RsrcName ...
                        ''' failed.']);
                end
            else
                % object for demo devic only (no real external device)
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

            % for visadevfind
            obj.VisaObject.Tag = char(obj.Instrument);

            % -------------------------------------------------------------
            % last step before we can use the new Visa object
            % => configure some parameters

            % some common settings for all types of supported devices
            obj.VisaObject.Timeout      = 5;  % in s, default value is 10
            %                                     max value is 1000
            obj.VisaObject.ByteOrder    = 'little-endian';   % default
            %
            % defines if EOI (end or identify) line is asserted at end of
            % write operation ==> has to be 'on'
            obj.VisaObject.EOIMode      = 'on';              % default
            %
            % terminator for read and write communications (ASCII only)
            obj.VisaObject.configureTerminator('LF', 'LF');
            %
            % Rules for Completing a Read Operation (binary data)
            % 'read' suspends MATLAB execution until the specified number of
            %  values is read or a timeout occurs.
            %
            % Rules for Completing a Read Operation (text)
            %   the read operation completes when:
            %   - The EOI line is asserted.
            %   - Specified number of values is read.
            %   - A timeout occurs.
            %   - the Terminator character is received ('off', 'LF', 'CR' ...)

            % buffer sizes are defined in external config table
            % ==> still have to be set (Matlab 2024a)
            obj.VisaObject.InputBufferSize  = selectedDevice.InBufSize;
            obj.VisaObject.OutputBufferSize = selectedDevice.OutBufSize;

            % pause parameter (between write and read in visa queries)
            obj.ExtraWait                   = selectedDevice.ExtraWait;

            if ~strcmp(obj.ShowMessages, 'none')
                disp([class(obj) ' object created.']);
            end

            % init command counter (for external command logging)
            obj.CommandCounter = 0;

            % disable timeout warnings while reading binary data from device
            warning('off', 'transportlib:client:ReadWarning');

            % -------------------------------------------------------------
            % the interface was already opened by the 'visadev' constructor
            % method, 'visadev' does not support dedicated open/close methods
            % anymore
            %
            % check actual state
            if strcmpi(obj.VisaObject.Status, 'open')
                if ~strcmpi(obj.ShowMessages, 'none')
                    disp(['Connection to ''' obj.DeviceName ''' is open.']);
                end
                % test communication with device by requesting
                % identifier ('*IDN?')
                [~, status_idn] = obj.identify;
                if status_idn
                    % something went wrong ==> error (or warning?)
                    error(['Identifier of ''' ...
                        obj.DeviceName ''' could not be read.']);
                end
            else
                % something went wrong ==> error (or warning?)
                error(['Connection to ''' ...
                    obj.DeviceName ''' could not be opened.']);
            end
        end

        function delete(obj)
            % destructor for a VisaIF object

            % enable timeout warnings again (read binary data)
            warning('off', 'transportlib:client:ReadWarning');

            % save value of property ShowMessages
            ShowMsgs = obj.ShowMessages;

            % delete and clear visa instrument object
            % deleting the VISA object is closing the connection before
            delete(obj.VisaObject);

            % print out message
            if ~strcmp(ShowMsgs, 'none')
                disp(['Object destructor called for class ''' ...
                    class(obj) '''.']);
            end
        end

        function status = open(obj)
            % opens interface

            % init output
            status = NaN;

            % the interface was already opened by the constructor method,
            % 'visadev' does not support dedicated open/close methods
            % anymore
            if ~strcmpi(obj.ShowMessages, 'none')
                disp('Open and close methods are not required anymore.');
                disp(['Constructor has already opened interface to ''' ...
                    obj.DeviceName '''.'])
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
                disp('Open and close methods are not required anymore.');
                disp(['Destructor (''delete'') will close interface to ''' ...
                    obj.DeviceName '''.'])
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        % -----------------------------------------------------------------
        % some notes about write (set command) and query (get command):
        %
        % the 'VisaCommand' (SCPI command char array) can be either
        %  - a set command (command string does not end with a '?') or
        %  - a get command (command string ends often with a '?')
        %  - Note: the '?' cannot be used as rule, there are some exceptions
        %
        % Matlab provides two dedicated functions for both types
        %  - writeline for set commands (write)
        %  - writeread for get commands (query) or as separate commands
        %    writeline followed by readline
        %
        % these commands work fine a regular string based SCPI commands,
        % but problems come up when
        %  - binary data (or mixed form: ASCII + binary) should be
        %    transferred
        %
        % preferred solution (not working with 'visadev' anymore):
        %  - cast VisaCommand to 'uint8' and use 'write' intead of
        %    'writeline' to send binary data to VisaObject
        %  - use binary 'read' instead of readline to read data and
        %    convert data to ASCII later
        %  - use separate write and read functions with optional ExtraWait
        %    between write & read actions for slow instrument devices
        %
        % sounds great, but ...
        %  - read command requires specification of number of bytes to
        %    be received
        %  - the number of bytes to receive is not known beforehand
        %    ==> maximum number is requested (InputBufferSize)
        %        but normally less data are available
        %    ==> in previous visa class an end-of-message indication terminated
        %        read operation before timeout
        %    ==> in visadev class the read operation will only be
        %        terminated by timeout which SLOWS DOWN all device control
        %
        % finally implemented solution:
        %  - set commands with write method (send always as binary data)
        %  - query commands with writeread method (for ASCII/text data)
        %  - when query binary data then use separate write & read method

        function status = write(obj, VisaCommand)
            % to write a Visa command to device
            %
            % data is always send as binary data to device (always fine)

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
                write(obj.VisaObject, VisaCommand, 'uint8');
                % optionally display message and log command in history
                obj.ShowAndLogSCPICommand('write', VisaCommand);
            end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function [VisaResponse, status] = read(obj)
            % to read a Visa command from device
            %
            % data is always read as binary data from device (always fine,
            % but read can always be terminated by timeout warning only)
            % use only when really binary data should be downloaded

            % init status
            status       = NaN;

            % read method requires specification of number of bytes to read
            % ==> unknown, define as maximum value (size of input buffer)
            % ==> will end up with timeout warning always (disabled in
            %     constructor) which slow down speed
            VisaResponse = read(obj.VisaObject, ...
                obj.VisaObject.InputBufferSize, 'uint8');

            % read is converting binary data to double at the end
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
                % remove last character (Terminator)
                if length(VisaResponse) > 1
                    VisaResponse = VisaResponse(1:end-1);
                else
                    VisaResponse = uint8([]);
                end
            else
                % 'LF' is missing
                % some devices show missing LF sometimes, but response
                % was always still okay (except for missing LF)
                status       = 1;
                if ~strcmpi(obj.ShowMessages, 'none')
                    disp(['Visa query: Warning - ''LF'' as last ' ...
                        'character in response is missing.']);
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

        function [VisaResponse, status] = query(obj, VisaCommand)
            % to query a Visa command to device
            %
            % works for text based data (ASCII) only !!!

            % init output
            VisaResponse = uint8([]);
            status       = NaN;

            if nargin < 2 || isempty(VisaCommand)
                status = -1;
                disp(['Visa query: Error - Visa command is empty. ' ...
                    'Skip query command.']);
            else
                % write Visa command to device and read back response
                %
                % separate writeline and readline commands
                writeline(obj.VisaObject, char(VisaCommand));
                % optional extra wait (for separated writeline & readline)
                if obj.ExtraWait > 0
                    % save current state and activate pause feature
                    PauseState = pause('on');
                    % run a short pause before next try
                    pause(obj.ExtraWait);
                    % restore original state
                    pause(PauseState);
                end
                VisaResponse = readline(obj.VisaObject);

                % received data is a string (text)
                VisaResponse = uint8(char(VisaResponse));

                % convert to row vector if needed
                if iscolumn(VisaResponse)
                    VisaResponse = transpose(VisaResponse);
                end
            end

            % optionally display message and log command in history
            obj.ShowAndLogSCPICommand('write', uint8(VisaCommand));
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
        % *OPC? (opc)     : not implemented e.g. at Siglent DC-Power Supply
        % *RST  (reset)   : not implemented e.g. at Siglent DC-Power Supply

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
            flush(obj.VisaObject, 'input');
            flush(obj.VisaObject, 'output');

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

        function RsrcName = get.RsrcName(obj)
            RsrcName = obj.VisaObject.ResourceName;
        end

        function Alias = get.Alias(obj)
            Alias = obj.VisaObject.Alias;
        end

        function Type = get.Type(obj)
            Type = obj.VisaObject.Type;
        end

        function PreferredVisa = get.PreferredVisa(obj)
            % in case several VISA drivers are installed (NI, RS, Keysight)
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
