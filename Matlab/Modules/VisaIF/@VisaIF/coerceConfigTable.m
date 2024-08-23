function cfgTableOut = coerceConfigTable(cfgTableIn)
% coerce some fields to valid entries
% cfgTable.Device     : remove invalid characters; allowed characters are
%                       a-zA-Z0-9_- and convert to upper case
% cfgTable.Vendor     : remove invalid characters (as above)
% cfgTable.Product    : remove invalid characters (as above)
% cfgTable.Instrument : set invalid categories to <undefined>
% cfgTable.Type       : set invalid categories to <undefined>
% cfgTable.RsrcName   : set to <undefined> when invalid;
%                       valid is either (case insensitive)
%                       TCPIP.. (starts with TCPIP)
%                       USB..   (starts with USB)
%                       DEMO
% cfgTable.OutBufSize : set invalid values to NaN, replace 0 by 512
% cfgTable.InBufSize  : set invalid values to NaN, replace 0 by 512
% cfgTable.ExtraWait  : set invalid values to NaN

cfgTable = cfgTableIn;

% -------------------------------------------------------------------------
% check 'Device'    remove invalid characters from device name and convert
%   to upper case
cfgTable.Device = categorical(upper(regexprep(string(cfgTable.Device), ...
    '[^-\w]*', ''))); % allowed are only a-zA-Z_0-9 (word characters) and -

% -------------------------------------------------------------------------
% check 'Vendor'    remove invalid characters from device name
cfgTable.Vendor = categorical(regexprep(string(cfgTable.Vendor), ...
    '[^-\w]*', '')); % allowed are only a-zA-Z_0-9 (word characters) and -

% -------------------------------------------------------------------------
% check 'Vendor'    remove invalid characters from device name
cfgTable.Product = categorical(regexprep(string(cfgTable.Product), ...
    '[^-\w]*', '')); % allowed are only a-zA-Z_0-9 (word characters) and -

% -------------------------------------------------------------------------
% check 'Instrument' remove invalid entries (not within categories)
cfgTable.Instrument = setcats(cfgTable.Instrument, ...
    VisaIF.SupportedInstrumentClasses);

% -------------------------------------------------------------------------
% check 'Type'       remove invalid entries (not within categories)
cfgTable.Type       = setcats(cfgTable.Type, ...
    VisaIF.SupportedInterfaceTypes);

% -------------------------------------------------------------------------
% check 'RsrcName'
%   join list of rules: group by () and join by | (or)
SupportedRsrcNames = ['(' strjoin(VisaIF.SupportedRsrcNames, '|')  ')'];

%   check resource names by rules
matches = regexpi(string(cfgTable.RsrcName), SupportedRsrcNames, 'match');
invalid = cellfun(@isempty, matches);

%   remove invalid entries
cfgTable.RsrcName(invalid) = string(missing);

%   do modify any resource name strings, because regular expressions are
%   possibly part of the resource names

% -------------------------------------------------------------------------
% check input and output buffer sizes
%   set default value to 512 (bytes)
cfgTable.OutBufSize(cfgTable.OutBufSize == 0) = 512;
cfgTable.InBufSize(cfgTable.InBufSize   == 0) = 512;
%   set invalid (negative) values to NaN
cfgTable.OutBufSize(cfgTable.OutBufSize < 0) = NaN;
cfgTable.InBufSize(cfgTable.InBufSize   < 0) = NaN;
%   round to integer values
cfgTable.OutBufSize = round(cfgTable.OutBufSize);
cfgTable.InBufSize  = round(cfgTable.InBufSize);

% check additional wait parameter (in s)
%   must be in range 0 .. 1 ==> limit values
cfgTable.ExtraWait(cfgTable.ExtraWait < 0) = 0;
cfgTable.ExtraWait(cfgTable.ExtraWait > 1) = 1;

% -------------------------------------------------------------------------
% copy to output
cfgTableOut = cfgTable;

end