function [selectedDevice, configTable] = filterConfigFiles(device, instrument, type, serialId)
% returns a table listing all supported devices found in config files and
% matching certain requirements as well as no or a single row of this table
% as wanted device to be connected to
%
% inputs:
%   device         : optional (char); default is '';
%                    regexp to search for matching elements in config table
%
%   instrument     : optional (char); default is '';
%                    instrument class out of
%                    VisaIF.SupportedInstrumentClasses;
%                    filter config list according to this setting
%
%   type           : optional (char); default is '';
%                    interface type out of VisaIF.SupportedInterfaceTypes;
%                    filter config list according to this setting
%
%   serialId       : optional (char); for type = 'visa-usb' only;
%                    default is '';
%                    to connect to a USB-TMC device with a defined serial
%                    ID
%
% outputs:
%   selectedDevice : table with same columns as config table, contain no
%                    or a single entry; all elements are of type char or
%                    double (no categoricals anymore)
%   configTable    : table listing all supported device matching instrument
%                    and type requirements
%

% -------------------------------------------------------------------------
% init output (empty table)
selectedDevice = table;
configTable    = table;

% -------------------------------------------------------------------------
% check number of input arguments
narginchk(0, 4);

% -------------------------------------------------------------------------
% set default values when no input is given

if nargin < 4 || isempty(serialId)
    serialId = '';
end

if nargin < 3 || isempty(type)
    type = '';
end

if nargin < 2 || isempty(instrument)
    instrument = '';
end

if nargin < 1 || isempty(device)
    device   = '';
end

% -------------------------------------------------------------------------
% check input parameters (types)

if ~ischar(serialId) && ~isstring(serialId)
    error(['Fourth input parameter (serial ID) ' ...
        'is not a character array or string.']);
else
    serialId = convertStringsToChars(serialId);
end

if ~ischar(type) && ~isstring(type)
    error(['Third input parameter (interface type) ' ...
        'is not a character array or string.']);
else
    type = lower(convertStringsToChars(type));
end

if ~ischar(instrument) && ~isstring(instrument)
    error(['Second input parameter (instrument class) ' ...
        'is not a character array or string.']);
else
    instrument = convertStringsToChars(instrument);
end

if ~ischar(device) && ~isstring(device)
    error(['First input parameter (device name) ' ...
        'is not a character array or string.']);
else
    device = convertStringsToChars(device);
end

% -------------------------------------------------------------------------
% check input parameters (format)

% serial ID must not contain any non word characters
if ~isempty(regexpi(serialId, '[^-\w]*', 'once'))
    warning(['Fourth input parameter (serial ID) ' ...
        'contains invalid charactors.']);
    return
end

% interface type has to be a supported type
switch type
    case ''
        runCheckType = false;
    case VisaIF.SupportedInterfaceTypes
        runCheckType = true;
    otherwise
        disp('Supported interface types are: ');
        disp(VisaIF.SupportedInterfaceTypes);
        warning(['Third input parameter (interface type) ' ...
            'is not supported.']);
        return
end

% instrument class has to be a supported instrument
switch instrument
    case ''
        runCheckInstrument = false;
    case VisaIF.SupportedInstrumentClasses
        runCheckInstrument = true;
    otherwise
        disp('Supported instrument classes are: ');
        disp(VisaIF.SupportedInstrumentClasses);
        warning(['Second input parameter (instrument class) ' ...
            'is not supported.']);
        return
end

% no further check for device

% -------------------------------------------------------------------------
% here starts the actual code: filter config table according to inputs

% create table listing all supported devices (read in config files)
cfgTable = VisaIF.listContentOfConfigFiles;

% filter table (remove non-matching interface types)
if runCheckType
    cfgTable = cfgTable(cfgTable.Type == type, :);
end

% filter table (remove non-matching instrument classes)
if runCheckInstrument
    cfgTable = cfgTable(cfgTable.Instrument == instrument, :);
end

% copy to output
configTable = cfgTable;

% filter table (search matching device name with regexp)
matches = regexpi(string(cfgTable.Device), device, 'match');
if ~iscell(matches)
    matches = {matches};
end
cfgTable = cfgTable(~cellfun(@isempty, matches), :);

% when cfgtable possibly contains more than one interface type
if ~runCheckType
    % sort cfgtable according to list of supported interface types
    cfgTable.Type = setcats(cfgTable.Type, ...
        categories(categorical(VisaIF.SupportedInterfaceTypes, ...
        VisaIF.SupportedInterfaceTypes)));
    cfgTable = sortrows(cfgTable, 'Type');
end

if isempty(cfgTable)
    % no device matches the requirements ==> exit
    return
end

% -------------------------------------------------------------------------
% all filter operations are done: now select one row

if cfgTable.Type(1) ~= 'visa-usb' %#ok<BDSCA>
    % select first row
    cfgTable = cfgTable(1, :);
    if ~isempty(serialId)
        disp('Serial ID will be ignored (for visa-usb only).');
    end
else
    % when usb interface is selected then check if a matching device is
    % connected ==> remove all non usb type from table
    cfgTable = cfgTable(cfgTable.Type == 'visa-usb', :);

    % search for connected USB devices
    connectedUsbDevices = VisaIF.listAvailableVisaUsbDevices;

    if isempty(connectedUsbDevices)
        disp('No visa-usb devices are available.');
        return
    end

    % select first matching device
    matchingUsbDevices = [];
    for idx = 1 : length(cfgTable.RsrcName)
        matches = ~cellfun(@isempty, regexpi(connectedUsbDevices, ...
            char(cfgTable.RsrcName(idx)), 'match'));
        if any(matches)
            cfgTable = cfgTable(idx, :);
            matchingUsbDevices = connectedUsbDevices(matches);
            break
        end
    end

    if isempty(matchingUsbDevices)
        disp('No matching visa-usb devices are available.');
        return
    end

    % cfgTable now with one row
    % one or more matching USB devices found
    if isempty(serialId)
        % select first USB device
        cfgTable.RsrcName = matchingUsbDevices{1};
    else
        % extract serial IDs from found USB devices and compare with input
        success = false;
        for idx = 1 : length(matchingUsbDevices)
            if endsWith(matchingUsbDevices{idx}, serialId, ...
                    'IgnoreCase', true)
                cfgTable.RsrcName = matchingUsbDevices{idx};
                success = true;
            end
        end
        if ~success
            disp('No visa-usb device with matching serial ID found.');
            return
        end
    end
end

% convert from categoricals to char arrays
cfgTable.Device     = char(cfgTable.Device);
cfgTable.Vendor     = char(cfgTable.Vendor);
cfgTable.Product    = char(cfgTable.Product);
cfgTable.Instrument = char(cfgTable.Instrument);
cfgTable.Type       = char(cfgTable.Type);
cfgTable.RsrcName   = char(cfgTable.RsrcName);

% copy to output
selectedDevice = cfgTable;

end