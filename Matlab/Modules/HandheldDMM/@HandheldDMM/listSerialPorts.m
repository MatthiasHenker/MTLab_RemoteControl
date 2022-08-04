function varargout = listSerialPorts(varargin)
% displays information about serial ports
%
% optional input to disable display messages
%   - ShowMessages   : logical (default is true)
%
% outputs list serial ports
%   - allPorts       : cell array of char array
%   - availablePorts : cell array of char array
%   - busyPorts      : cell array of char array
%

% get name of class (where this method belongs to)
className   = mfilename('class');

% check input
narginchk(0, 1);
if nargin == 0
    ShowMessages = true;
else
    if isscalar(varargin{1}) && ...
            (islogical(varargin{1}) || isnumeric(varargin{1}))
        % finally convert and set property
        ShowMessages = logical(varargin{1});
    else
        ShowMessages = false;
    end
end

% init output variables
if nargout > 3
    error([className ': Too many output arguments.']);
else
    varargout  = cell(1, nargout);
end

% -------------------------------------------------------------------------
% checks serial ports (responses are of type "strings")
allPorts       = serialportlist('all');
availablePorts = serialportlist('available');

if ShowMessages
    if isempty(allPorts)
        % maybe USB-HID interface with UART-bridge is available?
        disp('No serial port was found at your system.');
    else
        disp(['Serial ports found at your system: ' ...
            char(strjoin(allPorts, ', '))]);
        disp(['Available serial ports are       : ' ...
            char(strjoin(availablePorts, ', '))]);
    end
end

if nargout >= 1
    varargout(1) = {convertStringsToChars(allPorts)};
end
if nargout >= 2
    varargout(2) = {convertStringsToChars(availablePorts)};
end

% -------------------------------------------------------------------------
% non available ports are busy
for idx = 1 : length(availablePorts)
    allPorts = allPorts(~(allPorts == availablePorts(idx)));
end
busyPorts    = allPorts;

if ShowMessages
    if ~isempty(busyPorts)
        disp(['Busy serial ports are            : ' ...
            char(strjoin(busyPorts, ', '))]);
    end
end

if nargout >= 3
    varargout(3) = {convertStringsToChars(busyPorts)};
end

end
