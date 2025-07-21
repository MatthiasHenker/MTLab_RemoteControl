% test_SMU.m

clear variables;
close all;
clc;

SMUName = 'KEITHLEY-2450';

%interface = 'visa-usb';
%interface = 'visa-tcpip';
interface = 'demo';
%interface = '';

%showmsg   = 'all';
showmsg   = 'few';
%showmsg   = 'none';

% -------------------------------------------------------------------------
% display versions
% disp(['Version of SMU               : ' SMU.SMUVersion ...
%     ' (' SMU.SMUDate ')']);
% disp(['Version of VisaIF            : ' SMU.VisaIFVersion ...
%     ' (' SMU.VisaIFDate ')']);
% disp(['Version of VisaIFLogEventData: ' ...
%     VisaIFLogEventData.VisaIFLogEventVersion ...
%     ' (' VisaIFLogEventData.VisaIFLogEventDate ')']);
% disp(['Version of VisaIFLogger      : ' ...
%     VisaIFLogger.VisaIFLoggerVersion ...
%     ' (' VisaIFLogger.VisaIFLoggerDate ')']);
% disp(' ');

% -------------------------------------------------------------------------
% print out some information
%SMU.listAvailableConfigFiles;
%SMU.listContentOfConfigFiles;
%SMU.listAvailableVisaUsbDevices;
SMU.listAvailablePackages;

%mySMU = SMU({SMUName, SMUID}, interface);
mySMU = SMU(SMUName, interface, showmsg);
mySMU.EnableCommandLog = true;
%mySMU.ShowMessages     = 'few';

myLog = VisaIFLogger();
myLog.ShowMessages = 0;

% display details (properties) of SMU object
%mySMU

%mySMU.reset;
%mySMU.clear;

%mySMU.LimitCurrentValue
%mySMU.LimitCurrentValue = 0.5;
%mySMU.LimitCurrentValue

%mySMU.LimitVoltageValue
%mySMU.LimitVoltageValue = 5.6;
%mySMU.LimitVoltageValue

mySMU.OverVoltageProtectionLevel
mySMU.OverVoltageProtectionLevel = 3;
mySMU.OverVoltageProtectionLevel

%mySMU.configureDisplay(screen= 'X');
%mySMU.configureDisplay(screen= 'hElp');
%mySMU.configureDisplay(screen= 'home');
%mySMU.configureDisplay(screen= 'clear');
%mySMU.configureDisplay(screen= 'hist');
mySMU.configureDisplay(brightness= 25);
mySMU.configureDisplay(digits= '6');
mySMU.configureDisplay(buffer= 'defbuffer2');
%mySMU.configureDisplay(text= 'Running first tests;work in progress ...');


%mySMU.configureSenseMode(funct= 'current', mode= '4WIRE');


mySMU.outputTone;
mySMU.outputTone(freq= 2440, duration= '2.5');

eventLog = mySMU.ErrorMessages;


% still unknown
%mySMU.unlock;
%mySMU.lock;

%errMsgs = mySMU.ErrorMessages;
%disp(['SMU error messages: ' errMsgs]);


% -------------------------------------------------------------------------
% low level commands
if false

    mySMU.write('Source:Function:Mode Current');
    mySMU.write('Source:Current:Range 100e-3'); % or ':Auto On'

    mySMU.write('Sense:Function "Voltage"');
    mySMU.write('Sense:Voltage:Range 20');      % or ':Auto On'
    mySMU.write('Sense:Voltage:Rsense Off');    % On

    mySMU.LimitVoltageValue = 3.5;

    start  = 10e-6;
    stop   = 30e-3;
    points = 1001;
    delay  = 10e-3;
    cmd    = sprintf( ...
        'Source:Sweep:Current:Log %f, %f, %d, %f, 1, Fixed, Off, On, "defbuffer1"', ...
        start, stop, points, delay);
    mySMU.write(cmd);

    mySMU.query('Trace:Actual?');
    mySMU.query('Trace:Actual:Start?');
    mySMU.query('Trace:Actual:End?');
    %
    mySMU.write(':Trace:Clear');

    mySMU.write(':Initiate'); % init trigger and enables output
    %pause;
    mySMU.write('*WAI'); % wait until measurement done
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
myLog.listCommandHistory(inf);  % inf for all lines
%myLog.CommandHistory
%myLog.saveHistoryTable('test_SMU2450.csv');

%myLog.delete;
return

if false %#ok<UNRCH>
    myLog = VisaIFLogger;
    myLog.readHistoryTable('test_SMU2450.csv');
    myLog.Filter = false;
    myLog.listCommandHistory(inf);
    myLog.delete;
end

% -------------------------------------------------------------------------
