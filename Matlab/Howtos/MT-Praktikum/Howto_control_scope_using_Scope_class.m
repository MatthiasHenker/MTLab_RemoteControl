%% Howto create a Scope object and control a scope remotely
% 2022-08-05
%
% HTW Dresden, faculty of electrical engineering
% measurement engineering
% Prof. Matthias Henker
% ---------------------------------------------------------------------
% This is a simple sample script within a series of howto-files.
%
% ATTENTION: 'Scope' (version 1.2.1 or higher) and 'VisaIF' (version 2.4.3
%            or higher) class files are required
%
% This sample script is dealing with the creation of a Scope object and
% how to control a connected scope (a Tektronix TDS1000 scope as example)
%
%   - for further reading type 'Scope.doc'
%   - the scope is assumed to be connected to your computer and is
%     turned on
%   - a (very restricted) demo mode is available for first tests at home
%     without a scope
%
% just start this script (short cut 'F5') and get inspired

%% here we start

CleanMatlab = true;  % true or false

% optionally clean Matlab
if CleanMatlab  % set to true/false to enable/disable cleaning
    clear;      % clear all variables from the workspace (see 'help clear')
    close all;  % close all figures
    clc;        % clear command window
end

% -------------------------------------------------------------------------
%% here we go

% NOTES:
%   - the Scope class provides some high-level SPCI-command macros for
%     typical actions like selecting voltage divider, time base,
%     download waveform, making a screenshot and so on
%   - this enables you to create powerful scripts for full automated tests
%   - For full functionality a Textronix TDS1001/2001 scope has to connected
%     to your computer. Normally, you won't have such a scope at home.
%   - Thus, we provide a demo mode for first tests at home.
%   - ATTENTION: the demo mode supports very few macros only
%       * methods: reset, identify, opc
%       * you will get no errors but warnings for all unsupported methods
%         and parameters in demo-mode --> read messages in command window

% you can check if there is a scope connected via USB and turned on
Scope.listAvailableVisaUsbDevices; % take a look on your command window

% is a scope connected to PC or do want to use the Demo-mode?
runDemoMode = true;  % true (demo) or false (with connected scope)
if runDemoMode
    interface = 'demo';
else
    interface = 'visa-usb'; %#ok<UNRCH>
end

% which scope is used?
ScopeType = 'Tek-TDS';   % used in the lab (room S110)

% create object (constructor) --> same as for VisaIF class
myScope = Scope(ScopeType, interface);

myScope.open;     % open the interface
%myScope.reset;   % optionally reset the scope (set to default state)

% -------------------------------------------------------------------------
% some initial configuration first

% it is often sensible to use the autoset functionality of the scope as
% good starting point for further more detailed configurations
% ATTENTION: - always use 'autoset' before all other configurations,
%              because autoset configures (overwrites) lots of settings
%            - fur further adjustments use 'autoscale' instead of 'autoset'
%              to avoid unwanted changes in configuration (e.g. trigger)
%            - 'autoset' and 'autoscale' will only produce sensible results
%              when a signal is present at scope input(s)
%
myScope.autoset;   % same as pressing autoset button at scope

% configure and use both channels
channels = [1 2];   % or channels = {'ch1', 'ch2'};

% general settings of input and trigger parameters (fine tuning)
myScope.configureInput(          ...
    'channel'    , channels    , ...  % select channel(s) to configure
    'trace'      , 'on'        , ...  % turn on selected channel(s)
    'coupling'   , 'DC'        , ...  % DC-coupling of input signal
    'inputdiv'   , 1           , ...  % cable does 1:1 (default is 10)
    'bwlimit'    , true        );     % 20MHz low pass filter reduces noise
myScope.configureTrigger( ...
    'type'       , 'risingedge', ...  % default (after reset)
    'source'     , 'ch1'       , ...  % or ch2
    'coupling'   , 'DC'        , ...  % or AC
    'level'      , 0           );     % depends on input signal

% now adjust vertical (voltage) and horizontal (time) scaling as fine
% tuning ==> very helpful when signal at scope input has changed
%myScope.AutoscaleHorizontalSignalPeriods = 4;   % default is 5
%myScope.AutoscaleVerticalScalingFactor   = 0.9; % default is 0.95
myScope.autoscale;                    % configurable macro

% without autoscaling you would need to set the parameters manually
%myScope.configureInput(  ...
%    'channel', channels, ...
%    'vDiv'   , 2,        ...
%    'vOffset', 0         ); % e.g. vDiv = 2 (in V/div), vOffset = 0 (in V)
%myScope.configureAcquisition('tDiv', 50e-3); % tDiv = 0.05 (in s/div)

% -------------------------------------------------------------------------
% some helpful methods: screenshot

% make a screenshot and save as BMP- or TIFF-file
% (supported file formats/extensions depend on scope)
myScope.makeScreenShot('filename', 'myScreenShot.tiff');

% -------------------------------------------------------------------------
% some helpful methods: download wave data

% save waveform data to host (same as on scope screen)
myScope.acqStop;                                         % stop
wavedata = myScope.captureWaveForm('channel', channels); % save
myScope.acqRun;                                          % run again
%
% plot acquired scope data
if wavedata.status == 0   % download was successful
    u_1  = wavedata.volt(1,:); % in V
    u_2  = wavedata.volt(2,:); % in V
    time = wavedata.time;      % in s
    figure(1);
    plot(time, u_1, '-b', ...
        time, u_2, '-r');
    grid on;
end

% -------------------------------------------------------------------------
% some helpful methods: request measurement value(s)

% most scopes support measurements like mean value, max- and min-value ...
myMeas_1 = myScope.runMeasurement( ...
    'channel'  , 1          , ...
    'parameter', 'maximum'  );
% the result is a struct (see 'help struct') containing several fields
% ==> in most cases only the actual measurement value is of interest
maxValue = myMeas_1.value;

% alternatively you can directly access the 'value' field only
phaseValue = myScope.runMeasurement( ...
    'channel'  , [1 2]      , ...
    'parameter', 'phase'    ).value;

% -------------------------------------------------------------------------
% finally close interface and delete object again
myScope.close;
myScope.delete;

disp('Scope Test Done.');

return % end of file