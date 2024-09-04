% Howto acquire data of multiple channels in background
%
% This script uses a NI-DAQ device for measuring two voltages
% simultaniously in background and continuously plot them.
% Voltage 1:  A1 (Single Ended)
% Voltage 2:  A2 (Single Ended)
%
% HTW Dresden, faculty of electrical engineering
% - Measurement Engineering -
% @Robert Stoll, @Matthias Henker
% created: 2020-09-04
% edited:  2024-09-04
% version: file is under git control
%
% -------------------------------------------------------------------------
% This is a simple sample script from the series of howto-files
%
% This script is based on the script (copy and run the listed commands below)
% >> openExample('daq/demo_compactdaq_intro')
% from Help Center "Acquire Data Using NI Devices"
% >> web('https://de.mathworks.com/help/daq/acquire-data-using-ni-devices.html')
%
% ATTENTION: The 'Data Acquisition Toolbox', a connected NI-USB device
%            and its hardware support package is required.
%--------------------------------------------------------------------------

%% Clean Matlab
CleanMatlab = true; % true or false

% optionally clean Matlab
if CleanMatlab       % set to true/false to enable/disable cleaning
    daqreset;        % resets DAQ Toolbox and deletes all daq objects
    clear variables; % clear all variables
    close all;       % close all figures
    clc;             % clear command window
end

%% 1. Define Variables / Some preparations

% Read some seconds of data (on all channels).
readDuration = seconds(5);   % in s
% Number of samples per second in Sa/s (or Hz)
samplerate = 200;   % for NI-USB-6001: maximum is 20e3 / numOfChannels
% Total number of values to read ( = time to record * samplerate)
numValues  = seconds(readDuration) * samplerate;

%% 2. Discover Available Devices
% 2.1) list all available DAQ devices of National Instruments™
DeviceList = daqlist('ni');

disp('Display all available DAQ-devices:');
disp(DeviceList);
% ! use 'daqreset' if not all devices are listed correctly and try again

% exit when no compatible device is connected to your computer
if (isempty(DeviceList))
    error('No DAQ-Device connected! This demo-script requires a DAQ-device.');
end

% 2.2) display more details of the connected device
devIdx     = 1;         % adapt when more than one device is connected
deviceInfo = DeviceList.DeviceInfo(devIdx);

disp('Display detailed information about selected DAQ-device:');
disp(deviceInfo);

%% 3. Prepare data aquisition
% 3.1) create NI DAQ interface object
DAQBox = daq('ni');

% 3.2) Add channels (to the daq-interface 'd')
% channelhandle = d.addinput(deviceID, channelID, measurementType)
ch0 = DAQBox.addinput(deviceInfo.ID, 'ai1', 'Voltage');
ch1 = DAQBox.addinput(deviceInfo.ID, 'ai2', 'Voltage');

% Set the channel terminal configuration as 'SingleEnded'
% (referenced to GND)
ch0.TerminalConfig = 'SingleEnded';
ch1.TerminalConfig = 'SingleEnded';

% Show the channel config
disp('Display configuration of selected channels:');
disp(DAQBox.Channels);

% Set samplerate (DataAcquisition scan rate)
DAQBox.Rate = samplerate;

% 3.3)  Prepare figure
datetime_start = datetime('now');
formattedTimeStamp = char(datetime(datetime_start, ...
    Format= 'yyyy-MM-dd  HH:mm:ss'));

fig1 = figure(1); clf(fig1); % activate and clear figure 1
ax1  = axes(fig1); hold off; % create axes in figure 1
set(ax1, NextPlot= 'replacechildren'); % to keep existing axes properties
%plot(ax1, TimeTable.Time, TimeTable{:,1}, TimeTable.Time, TimeTable{:,2});
title(ax1, ['Data from DAQ - Option 1 (' formattedTimeStamp ')']);
xlabel(ax1, 'Samples');
ylabel(ax1, 'Voltage  U / V');
grid(ax1, 'on');

fig2 = figure(2); clf(fig2); % activate and clear figure 2
ax2  = axes(fig2); hold on; % keep data in axes in figure 2

%% 4. Run aquisition
% Clear all queued and previously acquired data
DAQBox.flush;

% read('all') returns all values read while measuring in background
% start also starts outputting data when preloaded (see Howto_NI_DAQ_write*)

% update a plot every 0.5 sec (for illustration purposes)
DAQBox.ScansAvailableFcnCount = round(samplerate *0.5);

disp('Option 1');
figure(1); % activate figure 1
% Option 1: acquires data continously and
%           callback function plots data directly
DAQBox.ScansAvailableFcn = @(src,evt)(plot(ax1, src.read('all', ...
    OutputFormat= 'Matrix')));

% Read data in background continously
DAQBox.start('Continuous');

%... do something else
pause(seconds(readDuration));

% stop acqusition is very important here !
DAQBox.stop();

disp('Option 2');
% Option 2: acquires data for a fix duration and
%           use the callback function 'plotMyData' to update the plot
DAQBox.ScansAvailableFcn = @plotMyData;
% acquire data for a predefined duration
DAQBox.start(Duration= readDuration);
% ... do something else or script ends here. no stop() needed

% pause before save
pause(seconds(readDuration));


%% 5. Save data and figure

% captured background data has to be stored in avariable before saving it

save('myDAQ_in_Background.mat', 'datetime_start');
savefig(fig1, 'myDAQ_in_Background.fig');

disp('finished.')
%--------------------------------------------------------------------------

%% definition of local functions

function plotMyData(daqobj, ~)
% daqobj is the DataAcquisition object passed in.
%
% alternative solution
% scanData = daqobj.read(daqobj.ScansAvailableFcnCount, ...
%    OutputFormat= 'Matrix');
% plot(scanData)

TimeTable = daqobj.read('all');

figure(2);
plot(TimeTable.Time, TimeTable{:,1}, ...
    TimeTable.Time, TimeTable{:,2});
grid on;

title('Data from DAQ - Option 2');
xlabel('Time / s');
ylabel('Voltage  U / V');
end

%% More Informationen

% Getting Started with NI Devices
% >> web('https://de.mathworks.com/help/daq/getting-started-with-session-based-interface-using-ni-devices.html')

% Read data acquired by hardware
% >> web('https://de.mathworks.com/help/daq/daq.interfaces.dataacquisition.read.html')

% Start DataAcquisition background operation
% >> web(fullfile(docroot, 'daq/daq.interfaces.dataacquisition.start.html?s_tid=doc_srchtitle'))

% This summarizes the use of the NI-DAQ-Box to capture component characterstics
% >> web(fullfile(docroot, 'daq/transition-your-code-from-session-to-dataacquisition-interface.html'))