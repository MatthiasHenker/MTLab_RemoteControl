% test_VisaIF

clear all;
close all;
clc;

%ScopeName = 'TDS';      % Tektronix Scope
%ScopeName = 'DSO';      % Keysight scope
ScopeName = 'RTB';      % R&S Scope
ScopeID   = '';         % don't care ==> connect to first found scope
%ScopeID   = 'C011107';  % a specific scope
%ScopeID   = 'C011127';  % (when more than one scope is connected)


% demo mode or with real hardware?
%interface = 'demo';
interface = 'visa-usb';

showmsg   = 'all';
%showmsg   = 'few';
%showmsg   = 'none';

% -------------------------------------------------------------------------
% display versions
disp(['Version of Scope             : ' Scope.ScopeVersion]);
disp(['Version of VisaIF            : ' Scope.VisaIFVersion]);
disp(['Version of VisaIFLogEventData: ' VisaIFLogEventData.VisaIFLogEventVersion]);
disp(['Version of VisaIFLogger      : ' VisaIFLogger.VisaIFLoggerVersion]);
disp(' ');

% -------------------------------------------------------------------------
% print out some information
%Scope.listAvailableConfigFiles;
%Scope.listContentOfConfigFiles;
Scope.listAvailableVisaUsbDevices;
Scope.listAvailablePackages;

%myScope = Scope({ScopeName, ScopeID}, interface);
myScope = Scope(ScopeName, interface, showmsg);
%myScope.EnableCommandLog = true;

%myLog = VisaIFLogger();
%myLog.ShowMessages = 0;

% optionally extend timeout period
%myScope.Timeout = 20; % for Keysight scope

% display details (properties) of Scope object
myScope;

myScope.open;

% R&S RTB2004: dedicated low-level commands
myScope.write('wgenerator:function sin');
myScope.write('wgenerator:voltage 0.1');
myScope.write('wgenerator:frequency 100e3');
myScope.write('wgenerator:output:load highz');
myScope.write('wgenerator:output:enable on');


myScope.ErrorMessages;
myScope.clear;

return

% -------------------------------------------------------------------------
% R&S RTB2004: dedicated low-level commands

myScope.write('format:border LSBF');  % Set little endian byte order
myScope.query('format:border?');
myScope.write('format:data uint,16]');
myScope.query('format:data?');
myScope.query('CHANnel3:DATA:HEADer?');
myScope.write('CHAN3:TYPE HRES');  % Set high resolution mode (16 bit data)
myScope.write('TIM:SCAL 10E-7');   % Set time base
myScope.write('FORM REAL');        % Set REAL data format
myScope.write('CHAN3:DATA:POIN MAX'); % Set sample range to memory da
myScope.query('chan3:data:points?');
myScope.query('chan3:data?');
 
myScope.write('channel1:scale 0.5');
% ADC is clipped? RTB manual (10vxx, page 573)
myScope.query('STATus:QUEStionable:ADCState:CONDition?');
% tests for waitfortrigger feature (TriggerState-method)
myScope.query('STATus:OPERation:CONDition?');
myScope.query('STATus:OPERation:NTRansition?');
myScope.write('STATus:OPERation:NTRansition 8');  % 8
myScope.query('STATus:OPERation:PTRansition?');
myScope.write('STATus:OPERation:PTRansition 0');
myScope.query('STATus:OPERation:EVENt?');
myScope.query('STATus:OPERation:ENABle?');  % default is 8 (WTrigger)
%
myScope.query('*STB?');
myScope.query('*SRE?');
myScope.query('*ESR?');
myScope.query('*ESE?');
myScope.write('*ESE 0');

myScope.query('ACQuire:SEGMented:STATe?');
myScope.write('ACQuire:SEGMented:STATe 1');
myScope.query('ACQuire:AVAilable?');
myScope.query('CHANnel1:HISTory:REPLay?');
myScope.write('CHANnel1:HISTory:REPLay 1');

tic
myScope.write('MEASurement3:ENABle 1');
myScope.write('MEASurement3:MAIN Lpeakvalue');
myScope.write('MEASurement3:SOURce CH1');
myScope.query('MEASurement3:RESult:ACTual?');
%myScope.write('MEASurement3:ENABle 0');
toc

tic
myScope.write('MEASurement2:ENABle 1');
myScope.write('MEASurement2:MAIN DELay');
myScope.write('MEASurement2:SOURce CH1, CH3');
myScope.query('MEASurement2:RESult:ACTual?');
%myScope.write('MEASurement:ENABle 0');
toc



myScope.AutoscaleHorizontalSignalPeriods = 5;
myScope.AutoscaleVerticalScalingFactor   = 0.9;
myScope.autoscale('mode', 'both');

myScope.configureInput( ...
    'channel'  , 1        , ...
    'inputdiv' , 1       , ...
    'vDiv'     , 0.012      , ...
    'vOffset'  , 0.0      );

return

myScope.configureInput( ...
    'channel'  , [1, 2, 3, 4]    , ...
    'trace'    , 'on'     , ...
    'impedance', '1e6'    , ...
    'vDiv'     , 0.1        , ...
    'vOffset'  , '0'      , ...
    'coupling' , 'DC'     , ...
    'inputdiv' ,  1       , ...
    'bwlimit'  ,  false   , ...
    'invert'   ,  false   , ...
    'skew'     ,  0       , ...
    'unit'     , 'V'      );
            
myScope.configureTrigger( ...
    'mode'    , 'auto'        , ...
    'type'    , 'fallingEdge'  , ...
    'source'  , 'ch1'         , ...
    'coupling', 'DC'          , ...
    'level'   , 1             , ...
    'delay'   , 0             );

myScope.configureAcquisition( ...
    'tdiv'  , 1.2345e-4     , ...
    'mode'  , 'sample');
myScope.configureAcquisition( ...
    'tDiv'      , 2.3456e-5,  ...
    'maxLength' , 27e6,        ...
    'mode'      , 'sample'    );
myScope.configureAcquisition( ...
    'tDiv'      , 2e-3,       ...
    'samplerate', 1e12,       ...
    'maxLength' , 800,        ...
    'mode'      , 'average',  ...
    'numAverage', 46          );

meas = myScope.runMeasurement( ...
    'channel'   , [1 2]   , ...
    'parameter' , 'phase' );
meas

%return

myScope.configureZoom('zoomFactor', 16, 'zoomPos', 0);

myScope.makeScreenShot('fileName', './tmp5.png');

data = myScope.captureWaveForm('channel', [1, 2, 3, 4]);

if true
    figure(1);
    plot(data.time, data.volt); % plot all available waveforms
    %plot(data.time, data.volt(1, :), '-r');
    %hold on;
    %plot(data.time, data.volt(2, :), '-b');
    %hold off;
end

%return

myScope.acqStop;
myScope.acqRun;


myScope.AcquisitionState
myScope.TriggerState
myScope.ErrorMessages

%return

% __________
% todo: Keysight scope

%acqStop
myScope.acqStop();
myScope.AcquisitionState

%acqRun
myScope.acqRun();
myScope.AcquisitionState

%autoset
myScope.autoset();

%configureInput
myScope.configureInput('Channel', [1,2], 'skew', 0E-9);
myScope.configureInput('Channel', 1, 'vOffset', 10E-3, 'vDiv', 10E-3);
myScope.configureInput('Channel', [1,2], 'trace', 'off');
pause(2);
myScope.configureInput('Channel', [1,2], 'trace', 'on', ...
    'inputDiv', 1);
myScope.configureInput('Channel', 1, 'coupling', 'AC');
myScope.configureInput('Channel', 2, 'coupling', 'DC', 'unit', 'A',...
    'invert', 'on', 'bwlimit', 'on');

%configureAcquisition
myScope.configureAcquisition('tDiv', 2e-3, 'samplerate', 1e12,...
    'maxLength', 800, 'mode', 'average', 'numAverage', 4);

%configureTrigger
myScope.configureTrigger('mode', 'normal', 'type', 'risingedge', ...
    'source', 'ch1', 'coupling', 'HFReject', 'level', NaN, 'delay', 0);

%configureZoom
myScope.configureZoom('zoomFactor', 2, 'zoomPosition', 0);

%autoscale
%ToDo: test with function generator in lab
myScope.AutoscaleHorizontalSignalPeriods = 2;
myScope.AutoscaleVerticalScalingFactor = 1;
myScope.autoscale('mode', 'both');

%makeScreenShot
myScope.makeScreenShot('filename', 'KeysightTestScreenshot.png');

%runMeasurement
Measurement = myScope.runMeasurement('channel', 1, ...
    'parameter', 'pk-pk');
disp(Measurement);

%captureWaveform
myScope.acqStop();
WaveData = myScope.captureWaveForm('channel', 1);
myScope.acqRun();
plot(WaveData.time, WaveData.volt(1,:));
grid on

%get methods
myScope.ErrorMessages
myScope.AcquisitionState
myScope.TriggerState
% __________


myScope.close;
myScope.delete;
%myLog.delete;

return

myScope.query('MEASU:IMM:TYP?');
myScope.query('MEASU:IMM:VAL?');
myScope.write('MEASU:IMM:TYP FREQ');
myScope.query('MEASU:IMM:TYP?');
myScope.query('MEASU:IMM:VAL?');

% -------------------------------------------------------------------------
% regexp: full line that does not contain a certain word
% '^((?!meas).)*$' ==> must not contain 'meas'
% '^(?!meas).'     ==> simplier, but not whole line for sure

myLog.Filter            = false;
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

myScope.delete;
%myLog.delete;

return

myLog = VisaIFLogger;
myLog.readHistoryTable;
myLog.Filter = false;
myLog.listCommandHistory(inf);
myLog.delete;

% -------------------------------------------------------------------------
