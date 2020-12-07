function varargout = listAvailableVisaUsbDevices
% returns a cell array of available (connected) visa-usb devices
% function calls
%   VisaIF.listAvailableVisaUsbDevices
%   visaUsbDeviceList = VisaIF.listAvailableVisaUsbDevices

className   = mfilename('class');

% init output variables
if nargout > 1
    error([className ': Too many output arguments.']);
else
    varargout  = cell(1, nargout);
end

visaUsbDevices  = {};
numOfUsbDevices = 0;

% list known hardware (for connected hardware via USB)
HardwareInfo     = instrhwinfo('visa', 'ni');
connectedDevices = HardwareInfo.ObjectConstructorName;

for cnt = 1 : length(connectedDevices)
    % RsrcName has form USB[0]::0x<VID>::0x<PID>::<SID>
    RsrcName = regexpi(connectedDevices{cnt}, ...
        'USB\d?::\w*::\w*::\w*', 'match', 'ignorecase');
    if ~isempty(RsrcName)
        numOfUsbDevices = numOfUsbDevices + 1;
        visaUsbDevices{numOfUsbDevices} = char(RsrcName);
    end
end

% either return results in output variables or display results
if nargout == 0
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
            disp(['      ManufacturerID (VID): ' char(RsrcCell{2})]);
            disp(['      ModelCode      (PID): ' char(RsrcCell{3})]);
            disp(['      SerialNumber   (SID): ' char(RsrcCell{4})]);
        end
    end
elseif nargout == 1
    % silent mode when called with outputs
    if numOfUsbDevices > 0
        varargout(1) = {visaUsbDevices};
    end
end

end
