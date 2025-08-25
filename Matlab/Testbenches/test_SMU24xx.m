% test_SMU.m

clear variables;
close all;
clc;

SMUName = 'KEITHLEY-2450';

%interface = 'visa-usb';
interface = 'visa-tcpip';
%interface = 'demo';
%interface = '';

%showmsg   = 'all';
showmsg   = 'few';
%showmsg   = 'none';

% -------------------------------------------------------------------------
% display versions
% disp(['Version of SMU               : ' SMU24xx.SMUVersion ...
%     ' (' SMU24xx.SMUDate ')']);
% disp(['Version of VisaIF            : ' SMU24xx.VisaIFVersion ...
%     ' (' SMU24xx.VisaIFDate ')']);
% disp(['Version of VisaIFLogEventData: ' ...
%     VisaIFLogEventData.VisaIFLogEventVersion ...
%     ' (' VisaIFLogEventData.VisaIFLogEventDate ')']);
% disp(['Version of VisaIFLogger      : ' ...
%     VisaIFLogger.VisaIFLoggerVersion ...
%     ' (' VisaIFLogger.VisaIFLoggerDate ')']);
% disp(' ');

% -------------------------------------------------------------------------
% print out some information
% SMU24xx.listAvailableConfigFiles;
% SMU24xx.listContentOfConfigFiles;
% SMU24xx.listAvailableVisaUsbDevices;

%mySMU = SMU24xx({SMUName, SMUID}, interface);
mySMU = SMU24xx(SMUName, interface, showmsg);
%mySMU.EnableCommandLog = true;
%mySMU.ShowMessages     = 'few';

%myLog = VisaIFLogger();
%myLog.ShowMessages = 0;

% display details (properties) of SMU object
%mySMU

%mySMU.reset;
%mySMU.clear;

testCase = 1;

switch testCase
    case 1
        mySMU.OperationMode                      = 'SVMI';
        mySMU.SourceParameters.OutputValue       = 2.5;
        mySMU.SourceParameters.OVProtectionValue = 3;
        mySMU.SourceParameters.LimitValue        = 10e-3;
        %
        %mySMU.SenseParameters.NPLCycles          = 5;
        %mySMU.SenseParameters.AverageCount       = 3;
        %
        mySMU.outputEnable;
        mySMU.showSettings;
        %
        tic
        result = mySMU.runMeasurement;
        toc
        %
        mySMU.restartTrigger;
    otherwise, return;
end

return

%mySMU.configureDisplay(screen= 'X');
%mySMU.configureDisplay(screen= 'hElp');
%mySMU.configureDisplay(screen= 'home');
%mySMU.configureDisplay(screen= 'clear');
%mySMU.configureDisplay(screen= 'hist');
mySMU.configureDisplay(brightness= 25);
mySMU.configureDisplay(digits= '6');
mySMU.configureDisplay(buffer= 'defbuffer2');
%mySMU.configureDisplay(text= 'Running first tests;work in progress ...');


mySMU.SourceParameters.LimitValue
mySMU.SourceParameters.OVProtectionValue
mySMU.SourceParameters.Readback = 'on';

%mySMU.configureSenseMode(funct= 'current', mode= '4WIRE');


mySMU.outputTone;
mySMU.outputTone(freq= 2500, duration= '1.5');



% still unknown
%mySMU.unlock;
%mySMU.lock;

eventLog = mySMU.ErrorMessages;
disp('SMU error (event) messages: ');
disp(eventLog);


% -------------------------------------------------------------------------
% low level commands
if false

    start  = 10e-6;
    stop   = 30e-3;
    points = 30;
    delay  = -1;
    cmd    = sprintf( ...
        'Source:Sweep:Current:Log %f, %f, %d, %f, 1, Fixed, Off, On, "defbuffer1"', ...
        start, stop, points, delay);
    mySMU.write(cmd);

    % mySMU.query('Trace:Actual?');
    % mySMU.query('Trace:Actual:Start?');
    % mySMU.query('Trace:Actual:End?');
    %
    %mySMU.write(':Trace:Clear');

    mySMU.write(':Initiate'); % init trigger and enables output

    % loop with pause and trigger state request
    %mySMU.query(':Trigger:State?');
    mySMU.TriggerState

    % ATTENTION: timeout can kill script
    % also disables output again
    %mySMU.write('OUTP OFF');

    % better read points = numOfElements
    % specify buffer
    response = mySMU.query(':Trace:Actual:End? "defbuffer1"');
    points   = str2double(char(response));
    response = mySMU.query(sprintf('Trace:Data? 1, %d, "defbuffer1", SOUR, READ', points));
    response = char(response);


    % Parse response
    data = str2double(strsplit(strtrim(response), ','));

    % Split data into currents and voltages
    currents = data(1:2:end);
    voltages = data(2:2:end);

    % Plot results
    if (~isempty(currents) && ~any(isnan(currents)) && ...
            ~isempty(voltages) && ~any(isnan(voltages)))
        figure(2);
        plot(voltages, currents, '*r-');
        title('V-I Characterization');
        xlabel('Voltage (V)');
        ylabel('Current (A)');
        grid on;
        drawnow;
    end


end

%return
%mySMU.delete;

%return
% -------------------------------------------------------------------------
% regexp: full line that does not contain a certain word
% '^((?!meas).)*$' ==> must not contain 'meas'
% '^(?!meas).'     ==> simplier, but not whole line for sure

%myLog.Filter            = true;
%myLog.FilterLine        = [-1000 0];
%myLog.FilterCmdID       = [-inf 0];
%myLog.FilterDevice      = '2450'; %'^a';
%myLog.FilterMode        = '.'; %'^w';
%myLog.FilterSCPIcommand = '^(?!meas).'; % must not contain 'meas'
%myLog.FilterSCPIcommand = 'cata';
%myLog.FilterNumBytes    = [1 inf];

%myLog.listCommandHistory(inf);  % inf for all lines

%myLog.CommandHistory
%myLog.saveHistoryTable('test_SMU2450.csv');

%myLog.delete;
%return
%
% if false %#ok<UNRCH>
%     myLog = VisaIFLogger;
%     myLog.readHistoryTable('test_SMU2450.csv');
%     myLog.Filter = false;
%     myLog.listCommandHistory(inf);
%     myLog.delete;
% end

% -------------------------------------------------------------------------
