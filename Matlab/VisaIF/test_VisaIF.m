% test_VisaIF

clear all;
close all;
clc;

% Tektronix Scope
ScopeName = 'Tek-TDS1001C-EDU';
ScopeID   = '';         % don't care ==> connect to first found scope
%ScopeID   = 'C011107';  % a specific scope
%ScopeID   = 'C011127';  % (when more than one scope is connected)

% Agilent Generator
FgenName  = 'Agilent-33220A';
FgenID    = '';
%FgenID    = 'MY44022964';

% demo mode or with real hardware?
%interface = 'demo';
%interface = 'visa-usb';

% -------------------------------------------------------------------------
% display versions
disp(['Version of VisaIF            : ' VisaIF.VisaIFVersion]);
disp(['Version of VisaIFLogEventData: ' VisaIFLogEventData.VisaIFLogEventVersion]);
disp(['Version of VisaIFLogger      : ' VisaIFLogger.VisaIFLoggerVersion]);

% -------------------------------------------------------------------------
% print out some information
%VisaIF.listAvailableConfigFiles;
%VisaIF.listContentOfConfigFiles;
%VisaIF.listAvailableVisaUsbDevices;

%myScope = VisaIF({ScopeName, ScopeID}, interface);
myScope = VisaIF(ScopeName, 'demo', 0);
myScope.EnableCommandLog = true;

myFgen  = VisaIF(FgenName,  'demo', 0);
myFgen.EnableCommandLog  = true;

myLog = VisaIFLogger();
%myLog.ShowMessages = 0;

% myFgen.delete;
% myScope.delete;
% myScope2 = VisaIF(ScopeName, 'demo');
% myScope3 = VisaIF(ScopeName, 'demo');
% myScope3.EnableCommandLog = true;
% myScope4 = VisaIF(ScopeName, 'demo');
% myScope3.delete;
% myScope5 = VisaIF(ScopeName, 'demo');
% clear myScope3
% clear myScope5
% clear myScope4
% clear myScope2
% clear all
% myScope6 = VisaIF(ScopeName, 'demo');
% myScope2.delete;
% clear all
% return

% display details (properties) of VisaIF object
%myScope
%disp(['Identifier: ' myScope.Identifier]);
%myScope.Device;

myScope.open;
myFgen.open;


for cnt = 1 : 50
    % for Agilent Fgen only
    myFgen.write('FREQ 5231.789'); % in Hz
    myFgen.query('FREQ?');
    myFgen.reset;
    myFgen.query('FREQ?');
    myFgen.opc;
    
    myScope.query('MEASU:IMM:TYP?');
    myScope.query('MEASU:IMM:VAL?');
    myScope.write('MEASU:IMM:TYP FREQ');
    myScope.query('MEASU:IMM:TYP?');
    myScope.query('MEASU:IMM:VAL?');
    
    myFgen.write('FREQ 12.345'); % in Hz
    myFgen.query('FREQ?');
    
    myScope.opc;
end

% regexp: full line that does not contain a certain word
% '^((?!meas).)*$' ==> must not contain 'meas'
% '^(?!meas).'     ==> simplier, but not whole line for sure

myLog.Filter            = true;
myLog.FilterLine        = [-1000 0];
myLog.FilterCmdID       = [-inf 0];
myLog.FilterDevice      = 'tds'; %'^a';
myLog.FilterMode        = '.'; %'^w';
%myLog.FilterSCPIcommand = '^(?!meas).'; % must not contain 'meas'
myLog.FilterSCPIcommand = 'freq';
myLog.FilterNumBytes    = [1 inf];
myLog.listCommandHistory(inf);  % inf for all lines
%myLog.CommandHistory

%myLog.saveHistoryTable('abc.csv');
%myLog.readHistoryTable('abc.csv');

% ...

myScope.close;
myFgen.close;

myScope.delete;
myFgen.delete;
myLog.delete;

return

% -------------------------------------------------------------------------
