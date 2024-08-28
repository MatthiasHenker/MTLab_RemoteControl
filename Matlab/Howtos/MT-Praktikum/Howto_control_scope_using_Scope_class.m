%% Howto create a Scope object and control a scope remotely
% 2024-08-28
%
% HTW Dresden, faculty of electrical engineering
% measurement engineering
% Prof. Matthias Henker
% ---------------------------------------------------------------------
% This is a simple sample script within a series of howto-files.
%
% ATTENTION: 'Scope' (version 3.0.0 or higher) and 'VisaIF' (version 3.0.1
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
%   - For full functionality an e.g. Textronix TDS1001/2001 scope has to be
%     connected to the computer. Normally, you won't have such a scope
%     at home. Thus, a demo mode is provided for first tests at home.
%   - Thus, we provide a demo mode for first tests at home.
%   - ATTENTION: the demo mode supports very few macros only
%       * methods: reset, identify, opc
%       * you will get no errors but warnings for all unsupported methods
%         and parameters in demo-mode --> read messages in command window

% you can check if there is a scope connected via USB and turned on
USBDeviceList = Scope.listAvailableVisaUsbDevices(true); % show results

% SELECT: true (demo) or false (control actually connected scope)
runDemoMode = false; % true or false
if runDemoMode || isempty(USBDeviceList)
    interface = 'demo';
else
    interface = 'visa-usb';
end

% which scope is used? available scopes in the lab (room S 110)
ScopeType = 'TDS';   % Tektronix TDS 1000X
%ScopeType = 'SDS';   % Siglent SDS1202X-E
%ScopeType = 'DSO';   % Keysight DSOX1102A

% -------------------------------------------------------------------------
% create object (constructor) and open interface
myScope = Scope(ScopeType, interface);

% optionally perform a reset to set the generator to default state
myScope.reset;   % reset can be helpful get scope to a known state

% -------------------------------------------------------------------------
% some initial configuration first

% it is often sensible to use the autoset functionality of the scope as
% good starting point for further more detailed configurations
% ATTENTION: - always use 'autoset' before ALL OTHER configurations,
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
myScope.configureInput(      ...
    channel  = channels    , ...  % select channel(s) to configure
    trace    = 'on'        , ...  % turn on selected channel(s)
    coupling = 'DC'        , ...  % DC-coupling of input signal
    inputdiv = 1           , ...  % cable does 1:1 (default is 10)
    bwlimit  = true        );     % 20MHz low pass filter reduces noise
myScope.configureTrigger(    ...
    type     = 'risingedge', ...  % or 'fallingedge'
    source   = 'ch1'       , ...  % or 'ch2' (alternatively just 1 or 2)
    coupling = 'DC'        , ...  % or 'AC'
    level    = 0.5         );     % depends on offset of input signal

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

% make a screenshot and save as BMP-, PNG- or TIFF-file
% (supported file formats/extensions depend on scope)
myScope.makeScreenShot(filename = 'myScreenShot'); % use default file extension

% -------------------------------------------------------------------------
% some helpful methods: download wave data

% save waveform data to host (same as on scope screen)
myScope.acqStop;                                        % stop
wavedata = myScope.captureWaveForm(channel = channels); % download data
myScope.acqRun;                                         % run again
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
% some more helpful methods: request measurement value(s)

% most scopes support measurements like mean value, max- and min-value ...
myMeas_1 = myScope.runMeasurement( ...
    channel   =  1       , ...
    parameter = 'maximum');
% the result is a struct (see 'help struct') containing several fields
% ==> in most cases only the actual measurement value is of interest
maxValue = myMeas_1.value;

% alternatively you can directly access the 'value' field only
phaseValue = myScope.runMeasurement( ...
    channel   = [1 2]  , ...
    parameter = 'phase').value;

% -------------------------------------------------------------------------
% finally close interface and delete object again
myScope.delete;

disp('Scope Test Done.');

return % end of file