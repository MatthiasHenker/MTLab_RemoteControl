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
% edited:  2022-02-02
% version: 2.3
%
% -------------------------------------------------------------------------
% This is a simple sample script from the series of howto-files
% based on the >> openExample('daq/demo_compactdaq_intro').
% from Help Center "Acquire Data Using NI Devices"
% >> web('https://de.mathworks.com/help/daq/acquire-data-using-ni-devices.html')
%
% ATTENTION: The 'Data Acquisition Toolbox', a connected 'NI-USB' device
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
% Index of the device that should be used for DAQ
devIdx = 1; % only of interest when more than one device is connected

% Read some seconds of data (on all channels).
readDuration = seconds(5); % in s
% Number of samples per second (in Sa/s or Hz)
samplerate = 200;   % for NI-USB-6001: maximum is 20e3 / numOfChannels
% Total number of values to read ( = time to record [s] * samplerate)
numValues = seconds(readDuration) * samplerate;

%% 2. Discover Available Devices
% 2.1) Use 'daqlist("ni")' to list all available National Instruments™ devices
DeviceList = daqlist("ni");
disp(DeviceList)
% ! use 'daqreset;' if not all devices are listed and try again

% 2.2) check if an compatible device is connected
if (isempty(DeviceList))
    error(' \n>> No DAQ-Device connected!');
else
    % 2.3) display more details of the connected device
    deviceInfo = DeviceList.DeviceInfo(devIdx);
    disp(deviceInfo);
end

%% 3. Prepare data aquisition
% 3.1) create NI daq interface object
DAQBox=daq("ni"); % input is the vendor

% Set samplerate (DataAcquisition scan rate)
DAQBox.Rate = samplerate;

% 3.2) Add channels (to the daq-interface 'd')
% channelhandle = d.addinput(deviceID, channelID, measurementType)
ch0 = DAQBox.addinput(deviceInfo.ID, 'ai1', 'Voltage');
ch1 = DAQBox.addinput(deviceInfo.ID, 'ai2', 'Voltage');

% Set the channel terminal configuration as 'SingleEnded'
% (referenced to GND)
ch0.TerminalConfig = 'SingleEnded';
ch1.TerminalConfig = 'SingleEnded';

% Show the channel config
disp(DAQBox.Channels);

% 3.3)  Prepare figure
startdatetime = datetime('now');

fig1 = figure(1); clf(fig1); % activate and clear figure 1
ax1 = axes(fig1); hold off; % create axes in figure 1
set(ax1,'NextPlot','replacechildren') ; % to keep existing axes properties
%plot(ax1, TimeTable.Time, TimeTable{:,1},TimeTable.Time, TimeTable{:,2});
title(ax1, {'Data from DAQ - Option 1' ; ...
    datestr(startdatetime, 'yyyy-mm-dd HH:MM:SS')});
xlabel(ax1, 'Time  t / s');
ylabel(ax1, 'Voltage  U / V');
grid(ax1, 'on');

fig2 = figure(2); clf(fig2); % activate and clear figure 2
ax2 = axes(fig2); hold on; % keep data in axes in figure 2

%% 4. Run aquisition
% flush:  Clear all queued and acquired data
flush(DAQBox); % (alternative: >> DAQBox.flush)

% -read('all') returns all values read while measuring in background
% -start also starts outputting data when preloaded (see Howto DAC)

%update a plot every 0.5sec (for illustration purposes)
DAQBox.ScansAvailableFcnCount = 100; %activate callback every 100/200 = 0.5 seconds

disp('Option 1');
figure(1); % activate figure 1
%Option 1: acquires data continously and
%          callback call plot-function directly
DAQBox.ScansAvailableFcn = @(src,evt)(plot(ax1, src.read('all',...
    'OutputFormat', 'Matrix')));
% Read in background continously
DAQBox.start('Continuous');
%... do something else
pause(seconds(readDuration));
% stop acqusition is very important here !
DAQBox.stop();

disp('Option 2');
%Option 2: acquires data for a fix duration and
%          use the callback function 'plotMyData' to update the plot
DAQBox.ScansAvailableFcn = @plotMyData;
% acquire data for a predefined duration
start(DAQBox, 'Duration', readDuration)
% ... do something else or script ends here. not stop() needed

% pause before save
pause(seconds(readDuration));


%% 5. Save data and figure
save('DAQ_in_Background.mat', 'DAQBox', 'startdatetime');
savefig(fig1, 'DAQ_in_Background.fig');

disp('finished.')
%--------------------------------------------------------------------------
%% functions
function plotMyData(daqobj, ~)
% obj is the DataAcquisition object passed in. evt is not used.
% scanData = read(daqobj,daqobj.ScansAvailableFcnCount,...
%    "OutputFormat","Matrix");
% plot(scanData)
TimeTable = daqobj.read('all');
figure(2); %activate figure 2
plot(TimeTable.Time, TimeTable{:,1},TimeTable.Time, TimeTable{:,2});
title("Data from DAQ - Option 2");
xlabel('time / s');
ylabel('Voltage  U / V');
grid('on');
end

%--------------------------------------------------------------------------
%% More Informationen
%This summarizes the use of the NI-DAQ-Box to capture component characterstics
% >> web(fullfile(docroot, 'daq/transition-your-code-from-session-to-dataacquisition-interface.html'))

% Getting Started with NI Devices
% >> web('https://de.mathworks.com/help/daq/getting-started-with-session-based-interface-using-ni-devices.html')

% Read data acquired by hardware
% >> web('https://de.mathworks.com/help/daq/daq.interfaces.dataacquisition.read.html')

% Start DataAcquisition background operation
% >> web(fullfile(docroot, 'daq/daq.interfaces.dataacquisition.start.html?s_tid=doc_srchtitle'))


