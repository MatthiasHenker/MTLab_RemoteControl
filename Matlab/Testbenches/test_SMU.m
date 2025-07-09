% test_SMU.m

clear variables;
close all;
clc;

SMUName = 'KEITHLEY-2450';

%interface = 'visa-usb';
interface = 'visa-tcpip';
%interface = '';

showmsg   = 'all';
%showmsg   = 'few';
%showmsg   = 'none';

% -------------------------------------------------------------------------
% display versions
disp(['Version of SMU               : ' SMU.SMUVersion ...
    ' (' SMU.SMUDate ')']);
disp(['Version of VisaIF            : ' SMU.VisaIFVersion ...
    ' (' SMU.VisaIFDate ')']);
disp(['Version of VisaIFLogEventData: ' ...
    VisaIFLogEventData.VisaIFLogEventVersion ...
    ' (' VisaIFLogEventData.VisaIFLogEventDate ')']);
disp(['Version of VisaIFLogger      : ' ...
    VisaIFLogger.VisaIFLoggerVersion ...
    ' (' VisaIFLogger.VisaIFLoggerDate ')']);
disp(' ');

% -------------------------------------------------------------------------
% print out some information
%SMU.listAvailableConfigFiles;
%SMU.listContentOfConfigFiles;
%SMU.listAvailableVisaUsbDevices;
SMU.listAvailablePackages;

%mySMU = SMU({SMUName, SMUID}, interface);
mySMU = SMU(SMUName, interface, showmsg);
%mySMU.EnableCommandLog = true;
%mySMU.ShowMessages     = 'few';

%myLog = VisaIFLogger();
%myLog.ShowMessages = 0;

% display details (properties) of SMU object
mySMU

return

mySMU.clear;
mySMU.reset;


% still unknown
mySMU.unlock;
mySMU.lock;

errMsgs = mySMU.ErrorMessages;
disp(['SMU error messages: ' errMsgs]);


% -------------------------------------------------------------------------
% low level commands
if false
    mySMU.ShowMessages = 'all';

    %mySMU.write('***');
    %mySMU.query('*opc?');

end

%return
mySMU.delete;

return
% -------------------------------------------------------------------------
% regexp: full line that does not contain a certain word
% '^((?!meas).)*$' ==> must not contain 'meas'
% '^(?!meas).'     ==> simplier, but not whole line for sure

myLog.Filter            = true;
myLog.FilterLine        = [-1000 0];
myLog.FilterCmdID       = [-inf 0];
myLog.FilterDevice      = 'agi'; %'^a';
myLog.FilterMode        = '.'; %'^w';
%myLog.FilterSCPIcommand = '^(?!meas).'; % must not contain 'meas'
myLog.FilterSCPIcommand = 'cata';
myLog.FilterNumBytes    = [1 inf];
myLog.listCommandHistory(inf);  % inf for all lines
%myLog.CommandHistory
myLog.saveHistoryTable('abc.csv');

myLog.delete;

return

myLog = VisaIFLogger;
myLog.readHistoryTable('abc.csv');
myLog.Filter = false;
myLog.listCommandHistory(inf);
myLog.delete;

% -------------------------------------------------------------------------
