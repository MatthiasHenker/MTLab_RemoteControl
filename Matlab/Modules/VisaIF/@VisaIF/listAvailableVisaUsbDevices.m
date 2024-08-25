function varargout = listAvailableVisaUsbDevices(showmsg)
% returns a cell array of available (connected) visa-usb devices
% function call
%   VisaIF.listAvailableVisaUsbDevices
%   visaUsbDeviceList = VisaIF.listAvailableVisaUsbDevices
%
% for use within VisaIF (minimum version 3.x.x, Matlab minimum 2022)

arguments (Input)
    showmsg (1,1) {mustBeNumericOrLogical} = false;
end

className   = mfilename('class');

% init output variables
if nargout > 1
    error([className ': Too many output arguments.']);
else
    varargout  = cell(1, nargout);
end

% show all results when results are not stored in an output variable
if nargin == 0 && nargout == 0
    showmsg = true;
else
    showmsg = logical(showmsg);
end

numOfUsbDevices = 0;
visaUsbDevices  = {};

% list available VISA resources
try
    resourceList  = visadevlist(Timeout = 5);
catch
    resourceList  = [];
end
numOfAvailableRes = size(resourceList, 1); % num of rows

for cnt = 1 : numOfAvailableRes
    % RsrcName has form USB[0]::0x<VID>::0x<PID>::<SID>
    RsrcName = regexpi(resourceList.ResourceName(cnt), ...
        'USB\d?::\w*::\w*::\w*', 'match', 'ignorecase');
    if ~isempty(RsrcName)
        numOfUsbDevices = numOfUsbDevices + 1;
        visaUsbDevices{numOfUsbDevices} = char(RsrcName);   %#ok<AGROW>
    end
end

% optionally display results
if showmsg
    % read in config table to check if USB device is in list
    cfgTable = VisaIF.listContentOfConfigFiles;

    % display search results when called with no outputs only
    disp([num2str(numOfUsbDevices) ' visa-usb devices are available.']);

    for cnt = 1 : numOfUsbDevices
        % is USB device listed in column 'RsrcName' of config table?
        searchRsrcName = regexpi(visaUsbDevices{cnt}, ...
            string(cfgTable.RsrcName), 'match', 'ignorecase');
        rowIdx = find(~cellfun(@isempty, searchRsrcName));
        if ~isempty(rowIdx)
            % list all matches (if there are duplicates)
            devName = char(strjoin(string(cfgTable.Device(rowIdx)), ', '));
            % or first match only
            %devName = char(cfgTable.Device(rowIdx(1)));
        else
            devName = '<undefined>';
        end
        % print out results
        disp([' (' num2str(cnt, '%02d') ') Device = ' pad(devName, 19) ...
            ' for RsrcName = ' visaUsbDevices{cnt}]);

        % extract USB-IDs
        RsrcCell = split(visaUsbDevices{cnt}, '::');
        if length(RsrcCell) == 4
            disp(['      ManufacturerID (VID): ' char(RsrcCell{2}) ...
                '     (' char(resourceList.Vendor(cnt)) ')']);
            disp(['      ModelCode      (PID): ' char(RsrcCell{3}) ...
                '     (' char(resourceList.Model(cnt))  ')']);
            disp(['      SerialNumber   (SID): ' char(RsrcCell{4})]);
        end
    end
end

% return result in output variable on demand
if nargout == 1 && numOfUsbDevices > 0
    varargout(1) = {visaUsbDevices};
end

end
