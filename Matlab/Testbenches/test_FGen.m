% test_FGen.m

clear variables;
close all;
clc;

%FGenName = 'Agi';        % Agilent  generator
%FGenName = 'SDG';        % Siglent  generator
FGenName = 'Key';        % Keysight generator
FGenID   = '';           % don't care ==> connect to first found generator
%FGenID   = 'MY44022964'; % a specific generator (Agilent/Keysight)


% demo mode or with real hardware?
%interface = 'demo';
interface = 'visa-usb';
%interface = 'visa-tcpip';

showmsg   = 'all';
%showmsg   = 'few';
%showmsg   = 'none';

% -------------------------------------------------------------------------
% display versions
disp(['Version of FGen              : ' FGen.FGenVersion]);
disp(['Version of VisaIF            : ' FGen.VisaIFVersion]);
disp(['Version of VisaIFLogEventData: ' VisaIFLogEventData.VisaIFLogEventVersion]);
disp(['Version of VisaIFLogger      : ' VisaIFLogger.VisaIFLoggerVersion]);
disp(' ');

% -------------------------------------------------------------------------
% print out some information
FGen.listAvailableConfigFiles;
FGen.listContentOfConfigFiles;
FGen.listAvailableVisaUsbDevices;
FGen.listAvailablePackages;

%myFGen = FGen({FGenName, FGenID}, interface);
myFGen = FGen(FGenName, interface, showmsg);
%myFGen.EnableCommandLog = true;
%myFGen.ShowMessages     = 'few';

%myLog = VisaIFLogger();
%myLog.ShowMessages = 0;

% display details (properties) of FGen object
%myFGen

myFGen.open;
%myFGen.clear;
%myFGen.reset;

%myFGen.unlock;
%myFGen.lock;

return

myFGen.configureOutput(     ...
    'waveform'    , 'sin' , ...
    'phase'       , 90    , ...
    'outputImp'   , 50    );
myFGen.configureOutput(     ...
    'waveform'    , 'sin' , ...
    'outputImp'   , inf    );

myFGen.configureOutput(     ...
    'frequency'   , 1.2e3 , ...
    'amplitude'   , 2     , ...
    'unit'        , 'Vpp' );

myFGen.configureOutput(       ...
    'channel'    , 1        , ...
    'waveform'   , 'square' , ...
    'amplitude'  , 1        , ...
    'dutycycle'  , 20.47     );

myFGen.configureOutput(       ...
    'channel'    , 1        , ...
    'waveform'   , 'ramp'   , ...
    'amplitude'  , 1        , ...
    'symmetry'   , 99.45    );

myFGen.configureOutput(       ...
    'channel'    , 1        , ...
    'waveform'   , 'pulse'  , ...
    'amplitude'  , 1        , ...
    'transition' , 600e-9   , ...
    'dutycycle'  , 49.45    );

myFGen.configureOutput(     ...
    'offset'      , -0.5  );

myFGen.configureOutput(       ...
    'waveform'    , 'noise' , ...
    'stdev'       , 1       , ...
    'bandwidth'   , 12.3456789e3 );
%myFGen.configureOutput(       ...
%    'waveform'    , 'noise' , ...
%    'stdev'       , 1       );


myFGen.enableOutput;
%myFGen.enableOutput('channel', 1);

% arb waveform commands
myFGen.arbWaveform(          ...
    'mode'    , 'list'     , ...
    'submode' , 'user'     );

myFGen.arbWaveform(          ...
    'mode'    , 'list'     , ...
    'submode' , 'all'      );

myFGen.arbWaveform(          ...
    'mode'    , 'delete'     , ...
    'wavename', 'dummy3'    );

myFGen.arbWaveform(          ...
    'mode'    , 'upload'   , ...
    'submode' , 'override' , ...
    'waveData', (-1:1/17:1.4), ...
    'waveName', 'dummy4' );

tic
myFGen.arbWaveform(          ...
    'mode'    , 'upload'   , ...
    'waveData', sin((0:1e5-1)/1e5*2*pi*3), ...
    'waveName', 'dummy3' );
toc

myFGen.arbWaveform(          ...
    'mode'    , 'select'   , ...
    'waveName', 'dummy2'    );

% [status, wavedata] = myFGen.arbWaveform( ...
%     'mode'    , 'download' , ...
%     'wavename', 'dummy'    );

myFGen.configureOutput(      ...
    'waveform', 'arb'      , ...
    'samplerate', 2*65536e3     );

myFGen.configureOutput(      ...
    'waveform', 'arb'      , ...
    'frequency', 1e6     );


%myFGen.disableOutput;
myFGen.disableOutput('channel', 1);

errMsgs = myFGen.ErrorMessages;
disp(['FGen error messages: ' errMsgs]);

% -------------------------------------------------------------------------
% low level 33220A

myFGen.ShowMessages = 'all';
% freq
%myFGen.write('freq 1234.5');
%myFGen.query('freq?');
myFGen.ShowMessages = 'none';

%myFGen.query('FUNC:PULS:DCYC?');


myFGen.close;
return
myFGen.delete;


% -------------------------------------------------------------------------
% regexp: full line that does not contain a certain word
% '^((?!meas).)*$' ==> must not contain 'meas'
% '^(?!meas).'     ==> simplier, but not whole line for sure

myLog.Filter            = false;
myLog.FilterLine        = [-1000 0];
myLog.FilterCmdID       = [-inf 0];
myLog.FilterDevice      = 'agi'; %'^a';
myLog.FilterMode        = '.'; %'^w';
%myLog.FilterSCPIcommand = '^(?!meas).'; % must not contain 'meas'
myLog.FilterSCPIcommand = 'freq';
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
