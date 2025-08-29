% test_SMU.m

clear variables;
close all;
clc;

% -------------------------------------------------------------------------
% configuration of measurement device
% -------------------------------------------------------------------------

SMUName = 'KEITHLEY-2450';
%
%interface = 'visa-usb';
interface = 'visa-tcpip';
%interface = 'demo';
%interface = '';
%
%showmsg   = 'all';
showmsg   = 'few';
%showmsg   = 'none';

% -------------------------------------------------------------------------
% configuration of test script
% -------------------------------------------------------------------------
displayClassVersions        = false; % or 0 for false and 1 for true
displayInfoAboutConfigFiles = false;
visaLogging                 = 0;
%
resetSMUatBeginOfTest       = true;
testCase                    = 7;

% -------------------------------------------------------------------------
if displayClassVersions
    disp(['Version of SMU               : ' SMU24xx.SMUVersion ...
        ' (' SMU24xx.SMUDate ')']);
    disp(['Version of VisaIF            : ' SMU24xx.VisaIFVersion ...
        ' (' SMU24xx.VisaIFDate ')']);
    disp(['Version of VisaIFLogEventData: ' ...
        VisaIFLogEventData.VisaIFLogEventVersion ...
        ' (' VisaIFLogEventData.VisaIFLogEventDate ')']);
    disp(['Version of VisaIFLogger      : ' ...
        VisaIFLogger.VisaIFLoggerVersion ...
        ' (' VisaIFLogger.VisaIFLoggerDate ')']);
    disp(' ');
end

% -------------------------------------------------------------------------
if displayInfoAboutConfigFiles
    SMU24xx.listAvailableConfigFiles;
    SMU24xx.listContentOfConfigFiles;
    SMU24xx.listAvailableVisaUsbDevices;
    disp(' ');
end
% -------------------------------------------------------------------------


% -------------------------------------------------------------------------
% actual code starts here
% -------------------------------------------------------------------------
% create object for SMU device
mySMU = SMU24xx(SMUName, interface, showmsg);

if visaLogging
    mySMU.EnableCommandLog = true; %#ok<*UNRCH>
    myLog = VisaIFLogger();
    myLog.ShowMessages = 0;
end

% display details (properties) of SMU object
%mySMU
%mySMU.ShowMessages = 'few'; % change verbose level at runtime
%mySMU.clear;

if resetSMUatBeginOfTest
    mySMU.reset;
end

% show home screen
mySMU.configureDisplay(screen= 'home', brightness= 25, digits= '6');

switch testCase
    case 1
        mySMU.outputDisable;
        mySMU.OperationMode                      = 'SVMI';
        %
        mySMU.SourceParameters.OutputValue       = 2.5;
        mySMU.SourceParameters.OVProtectionValue = 3;
        mySMU.SourceParameters.LimitValue        = 20e-3;
        mySMU.SourceParameters.Readback          = 'on'; % def: on
        %
        mySMU.SenseParameters.NPLCycles          = 1; % def: 1
        mySMU.SenseParameters.AverageCount       = 0; % def: 0
        mySMU.SenseParameters.RemoteSensing      = 'off'; % def: 'off'
        %
        %mySMU.outputEnable;
        mySMU.showSettings;
        %
        result = mySMU.runMeasurement(count = 100, timeout = 20);
        %
        figure(1);
        plot(result.timestamps, result.senseValues , '-r*');
        %
        figure(2);
        plot(result.timestamps, result.sourceValues, '-b*');
        %
        return
        %mySMU.restartTrigger;
    case 2
        % single measurement value
        result = mySMU.runMeasurement;
    case 3
        % slower measurements
        mySMU.SenseParameters.NPLCycles    = 10; % def: 1
        mySMU.SenseParameters.AverageCount =  5; % def: 0
        %
        result = mySMU.runMeasurement( ...
            timeout   = 10           , ...
            mode      = 'simple'     , ...
            count     = 30           );
    case 4
        % user defined sweep
        mySMU.outputDisable;
        mySMU.OperationMode                      = 'SVMI';
        %
        mySMU.SourceParameters.OVProtectionValue = 3;
        mySMU.SourceParameters.LimitValue        = 20e-3;
        %
        result = mySMU.runMeasurement( ...
            timeout   = 100          , ...
            mode      = 'list'       , ...
            count     = 1            , ...
            list      = (2.5 - 1)*rand(1, 100) + 1, ...
            delay     = -1           , ...
            failabort = false        );
        %
        figure(1);
        plot(result.timestamps  , result.senseValues , '-r*');
        %
        figure(2);
        plot(result.timestamps  , result.sourceValues, '-b*');
        %
        figure(3);
        plot(result.sourceValues, result.senseValues, 'g*');
        %
        return
    case 5
        % linear sweep
        mySMU.outputDisable;
        mySMU.OperationMode                      = 'SVMI';
        %
        mySMU.SourceParameters.OVProtectionValue = 3;
        mySMU.SourceParameters.LimitValue        = 20e-3;
        %
        result = mySMU.runMeasurement( ...
            timeout   = 100          , ...
            mode      = 'lin'        , ...
            count     = 1            , ...
            points    = 50           , ...
            start     = 0            , ...
            stop      = 2.5          , ...
            dual      = 1            , ...
            delay     = -1           , ...
            rangetype = 'best'       , ...
            failabort = false        );
        %
        figure(1);
        plot(result.timestamps  , result.senseValues , '-r*');
        %
        figure(2);
        plot(result.timestamps  , result.sourceValues, '-b*');
        %
        figure(3);
        plot(result.sourceValues, result.senseValues, '-g*');
        %
        return
    case 6
        % logarithmic sweep
        mySMU.outputDisable;
        mySMU.OperationMode                      = 'SVMI';
        %
        mySMU.SourceParameters.OVProtectionValue = 5;
        mySMU.SourceParameters.LimitValue        = 25e-3;
        %
        result = mySMU.runMeasurement( ...
            timeout   = 200          , ...
            mode      = 'log'        , ...
            count     = 10           , ...
            points    = 60           , ...
            start     =  0.5         , ...
            stop      =  2.5         , ...
            asymptote =  0           , ...
            dual      = true         , ...
            delay     = -1           , ...
            rangetype = 'best'       , ...
            failabort = false        );
        %
        figure(1);
        plot(result.timestamps  , result.senseValues , '-r*');
        %
        figure(2);
        plot(result.timestamps  , result.sourceValues, '-b*');
        %
        figure(3);
        plot(result.sourceValues, result.senseValues , '-g*');
        %
        return
    case 7
        % logarithmic sweep
        mySMU.outputDisable;
        mySMU.OperationMode                      = 'SVMI';
        %
        mySMU.SourceParameters.OVProtectionValue = 5;
        mySMU.SourceParameters.LimitValue        = 25e-3;
        mySMU.SourceParameters.Readback          = 'on'; % def: on
        mySMU.SenseParameters.NPLCycles          = 5; % def: 1
        mySMU.SenseParameters.AverageCount       = 0; % def: 0
        mySMU.SenseParameters.RemoteSensing      = 'off'; % def: 'off'
        %
        result = mySMU.runMeasurement( ...
            timeout   = 100          , ...
            mode      = 'log'        , ...
            count     = 1            , ...
            points    = 50           , ...
            start     =  0           , ...
            stop      =  2.5         , ...
            asymptote =  10          , ...
            dual      = true         , ...
            delay     = -1           , ...
            rangetype = 'best'       , ...
            failabort = false        );
        %
        figure(1);
        plot(result.timestamps  , result.senseValues , '-r*');
        %
        figure(2);
        plot(result.timestamps  , result.sourceValues, '-b*');
        %plot((1:length(result.sourceValues)), result.sourceValues, '-b*');
        %
        figure(3);
        plot(result.sourceValues, result.senseValues, '-g*');
        %
        %return
    case 14
        % display test
        %mySMU.configureDisplay(screen= 'X');
        %mySMU.configureDisplay(screen= 'hElp');
        %mySMU.configureDisplay(screen= 'home');
        %mySMU.configureDisplay(screen= 'clear');
        %mySMU.configureDisplay(screen= 'hist');
        mySMU.configureDisplay(brightness= 25);
        mySMU.configureDisplay(digits= '6');
        %mySMU.configureDisplay(buffer= 'defbuffer2');
        %mySMU.configureDisplay(text= 'Running first tests;work in progress ...');
    case 15
        mySMU.outputTone;
        %mySMU.outputTone(freq= 2500, duration= '1.5');
    case 16
        eventLog = mySMU.ErrorMessages;
        disp('SMU error (event) messages: ');
        disp(eventLog);
    case 20
        % -------------------------------------------------------------------------
        % low level commands
        mySMU.write(':Trace:Clear');
    case 21
        disp('further test cases ...');
        %
    case 22
        disp('Content of property "SupportedInstrumentClasses"');
        disp(mySMU.SupportedInstrumentClasses);
        disp(' ');
    otherwise
        % exit (return): SMU object is still available
        return;
end

%return
mySMU.delete;

% -------------------------------------------------------------------------
% regexp: full line that does not contain a certain word
% '^((?!meas).)*$' ==> must not contain 'meas'
% '^(?!meas).'     ==> simplier, but not whole line for sure

if visaLogging
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
    myLog.saveHistoryTable('test_SMU2450.csv');

    myLog.delete;
end

if false
    myLog = VisaIFLogger;
    myLog.readHistoryTable('test_SMU2450.csv');
    myLog.Filter = false;
    myLog.listCommandHistory(inf);
    myLog.delete;
end

% -------------------------------------------------------------------------
% EOF