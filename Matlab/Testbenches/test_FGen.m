% test_FGen.m

clear variables;
close all;
clc;

%FGenName = 'Agi';        % Agilent  generator
FGenName = 'SDG';        % Siglent  generator
%FGenName = 'Key';        % Keysight generator
%FGenID   = '';           % don't care ==> connect to first found generator
%FGenID   = 'MY44022964'; % a specific generator (Agilent/Keysight)


% demo mode or with real hardware?
%interface = 'demo';
%interface = 'visa-usb';
%interface = 'visa-tcpip';
interface = '';

showmsg   = 'all';
%showmsg   = 'few';
%showmsg   = 'none';

% -------------------------------------------------------------------------
% display versions
disp(['Version of FGen              : ' FGen.FGenVersion ...
    ' (' FGen.FGenDate ')']);
disp(['Version of VisaIF            : ' FGen.VisaIFVersion ...
    ' (' FGen.VisaIFDate ')']);
disp(['Version of VisaIFLogEventData: ' ...
    VisaIFLogEventData.VisaIFLogEventVersion ...
    ' (' VisaIFLogEventData.VisaIFLogEventDate ')']);
disp(['Version of VisaIFLogger      : ' ...
    VisaIFLogger.VisaIFLoggerVersion ...
    ' (' VisaIFLogger.VisaIFLoggerDate ')']);
disp(' ');

% -------------------------------------------------------------------------
% print out some information
%FGen.listAvailableConfigFiles;
%FGen.listContentOfConfigFiles;
FGen.listAvailableVisaUsbDevices;
%FGen.listAvailablePackages;

%myFGen = FGen({FGenName, FGenID}, interface);
myFGen = FGen(FGenName, interface, showmsg);
%myFGen.EnableCommandLog = true;
%myFGen.ShowMessages     = 'few';

%myLog = VisaIFLogger();
%myLog.ShowMessages = 0;

% display details (properties) of FGen object
%myFGen

%myFGen.open;
%myFGen.clear;
%myFGen.reset;

%myFGen.unlock;
%myFGen.lock;


%myFGen.configureOutput(     ...
%    'waveform'    , 'sin' , ...
%    'phase'       , 90    , ...
%    'outputImp'   , 50    );

%myFGen.configureOutput(     ...
%    'waveform'    , 'sin' , ...
%    'outputImp'   , inf    );

myFGen.configureOutput(     ...
    'waveform'    , 'arb' , ...
    'channel'     , 1:2   , ...
    'samplerate'  , 300e6 , ...
    'amplitude'   , 2     , ...
    'unit'        , 'Vpp' );

myFGen.configureOutput(     ...
    'frequency'   , 1.2e3 , ...
    'amplitude'   , 2     , ...
    'unit'        , 'Vpp' );

myFGen.configureOutput(       ...
    'channel'    , 1        , ...
    'waveform'   , 'square' , ...
    'amplitude'  , 1        , ...
    'dutycycle'  , 20.47     );

%myFGen.configureOutput(       ...
%    'channel'    , 1        , ...
%    'waveform'   , 'ramp'   , ...
%    'amplitude'  , 1        , ...
%    'symmetry'   , 99.45    );

%myFGen.configureOutput(       ...
%    'channel'    , 1        , ...
%    'waveform'   , 'pulse'  , ...
%    'amplitude'  , 1        , ...
%    'transition' , 600e-9   , ...
%    'dutycycle'  , 49.45    );

myFGen.configureOutput(     ...
    'offset'      , -0.5  );

%myFGen.configureOutput(       ...
%    'waveform'    , 'noise' , ...
%    'stdev'       , 1       , ...
%    'bandwidth'   , 12.3456789e3 );
%myFGen.configureOutput(       ...
%    'waveform'    , 'noise' , ...
%    'stdev'       , 1       );


myFGen.enableOutput;
%myFGen.enableOutput('channel', 1:2);

% arb waveform commands
myFGen.arbWaveform(          ...
    'mode'    , 'list'     , ...
    'submode' , 'user'     );
myFGen.arbWaveform(          ...
    'mode'    , 'list'     , ...
    'submode' , 'builtin' );
myFGen.arbWaveform(          ...
    'mode'    , 'list'     , ...
    'submode' , 'volatile' );
myFGen.arbWaveform(          ...
    'mode'    , 'list'     , ...
    'submode' , 'all'      );

%myFGen.arbWaveform(          ...
%    'mode'    , 'delete'   , ...
%    'submode' , 'volatile' , ...
%    'wavename', 'dummy3'   );

%myFGen.arbWaveform(          ...
%    'mode'    , 'delete'   , ...
%    'submode' , 'user'     , ...
%    'wavename', 'exp_rise' );

myFGen.arbWaveform(          ...
    'mode'    , 'upload'   , ...
    'waveData', abs(sin(2*pi*(0:999999)/1000000)+0.5)-0.75, ...
    'waveName', 'dummy2' );

%myFGen.arbWaveform(          ...
%    'mode'    , 'upload'   , ...
%    'submode' , 'override' , ...
%    'waveData', (-1:1/157:1), ...
%    'waveName', 'exp_rise' );

tic
myFGen.arbWaveform(          ...
    'mode'    , 'upload'   , ...
    'submode' , 'volatile' , ...
    'waveData', cos(2*pi*(0:1e6-1)/1e6), ...
    'waveName', 'dummy3' );
toc

myFGen.arbWaveform(          ...
    'mode'    , 'select'   , ...
    'submode' , 'builtin'  , ...
    'waveName', 'cauchy'   );

myFGen.arbWaveform(          ...
    'mode'    , 'select'   , ...
    'submode' , 'volatile' , ...
    'waveName', 'dummy2'    );

myFGen.arbWaveform(          ...
    channel    = 1:2        , ...
    mode       = 'select'   , ...
    submode    = 'user'     , ...
    waveName   = 'DualSine_8192');

%myFGen.arbWaveform(          ...
%    'mode'    , 'select'   , ...
%    'submode' , 'volatile' , ...
%    'waveName', 'exp_rise'    );

% [status, wavedata] = myFGen.arbWaveform( ...
%     'mode'    , 'download' , ...
%     'wavename', 'dummy'    );

myFGen.configureOutput(      ...
    'waveform', 'arb'      , ...
    'samplerate', 2*65536e3     );

%myFGen.configureOutput(      ...
%    'waveform', 'arb'      , ...
%    'frequency', 1e6     );


%myFGen.disableOutput;
%myFGen.disableOutput('channel', 1);

errMsgs = myFGen.ErrorMessages;
disp(['FGen error messages: ' errMsgs]);

if false
    % temp test to read in arb data
    filename = 'SDG6000_PN7_100Sym_QPSK_r05.arb';
    
    %fid = fopen(filename, 'wb+');  % open as binary
    %fwrite(fid, bitMapData(11:end), 'uint8'); %leave out number
    
    headerFull = [ ...
        'FileType,'           'IQ,'           ... %%
        'Version,'            '2.0,'          ... %%
        'FileName,'           'wavename.ARB,' ... %%
        'DataSourceType,'     'PN7,'          ... 
        'SymbolLength,'       '100,'          ... %% disp only
        'SymbolRate,'         '250,'          ... %% ==> setting
        'ModulationType,'     'QPSK,'         ... % disp only
        'FilterType,'         'RootCosine,'   ... % disp only
        'FilterBandwidth,'    '0,'            ...
        'FilterAlpha,'        '0.5,'          ... % disp only
        'FilterLength,'       '32,'           ...
        'OverSampling,'       '8,'            ... %% disp & convert Fs - Fsymb
        'ActualSampleLength,' '100,'          ... 
        'SampleRate,'         '2000,'         ...
        'RMS,'                '1.4,'          ...
        'DataLength,'         '800,'          ... %%
        'IQData,'             ];                  %%
    
    headerMand = [ ...
        'FileType,'           'IQ,'                  ...
        'Version,'            '2.0,'                 ...
        'FileName,'           wavename '.ARB,'       ...
        'SymbolLength,'       num2str(100, '%d') ',' ...
        'SymbolRate,'         '250,'           ... %% ==> setting
        'ModulationType,'     'QPSK,'          ... % disp only
        'FilterType,'         'RootCosine,'    ... % disp only
        'FilterAlpha,'        '0.5,'           ... % disp only
        'OverSampling,'       '8,'             ... %% disp & convert Fs - Fsymb
        'SampleRate,'         '2000,'          ... %? instead of SymbolRate
        'DataLength,'         '800,'           ... %%
        'IQData,'             ];                  %%
    
    
    fid  = fopen(filename, 'rb');  % open as binary for reading
    %[fdata, fcnt] = fread(fid, inf, 'uint8');
    [fdata, fcnt] = fread(fid);
    fclose(fid);
    
    header = char(fdata(1:306)')
    wdata  = uint8(fdata(307:end))';
    wdata2 = typecast(wdata, 'int16');
    wdata3 = double(wdata2)/(2^(16-1)-1);
    
    wd_I = wdata3(1:2:end);
    wd_Q = wdata3(2:2:end);
    time = 1:length(wd_I);
    figure(1);
    plot(time, wd_I, '-r*');
    hold on;
    plot(time, wd_Q, '-b*');
    hold off;
    zoom on;
end

if false

% -------------------------------------------------------------------------
% low level 33511B

% not working this way (header of arb/barb file missing)
% myFGen.write('MMEMORY:DOWNLOAD:FNAME "INT:\dummy1.barb"');
% WaveData    = 1 * sin(2*pi*(0:15)/16);
% WaveData    = max(min(real(WaveData) *2^(16-1), 2^(16-1)-1), -2^(16-1)+1);
% RawWaveData = typecast(int16(WaveData), 'uint8');
% myFGen.write([uint8('MMEMORY:DOWNLOAD:DATA #800000032') RawWaveData]);

% write waveform data from host pc to FGen
% check before: enough memspace, wavename available? otherwise clear mem
%myFGen.write('DATA:VOLATILE:CLEAR');
%NumSamples  = 2e1;
%WaveData    = 0.99 * sin(2*pi*(0:NumSamples-1)/NumSamples);
%WaveData    = (-1 : 0.01 : 1);
%WaveData    = max(min(real(WaveData) *2^(16-1), 2^(16-1)-1), -2^(16-1)+1);
% requires setting 'FORMAT:BORDER SWAPPED' (see 'runAfterOpen' macro)
%RawWaveData = typecast(int16(WaveData), 'uint8');
%NumBytes    = length(RawWaveData);
%myFGen.write([ ...
%    uint8(['DATA:ARB:DAC dummy1,#8' num2str(NumBytes, '%08d')]) ...
%    RawWaveData]);
%myFGen.write('FUNCTION:ARB dummy1');
%myFGen.query('*OPC?');
%
%myFGen.write('MMEMORY:STORE:DATA "INT:\dummy1.barb"');

% list available wave files in non volatile memory
% user
response = myFGen.query('MMEM:CATALOG:DATA:ARBITRARY? "INT:\"');
% builtin
response = myFGen.query('MMEM:CATALOG:DATA:ARBITRARY? "INT:\BuiltIn"');





% -------------------------------------------------------------------------
% low level 33220A

myFGen.ShowMessages = 'all';
% freq
%myFGen.write('freq 1234.5');
%myFGen.query('freq?');
myFGen.ShowMessages = 'none';

%myFGen.query('FUNC:PULS:DCYC?');
end

%myFGen.close;
return
myFGen.delete;


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
