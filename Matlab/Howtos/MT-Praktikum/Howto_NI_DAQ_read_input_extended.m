% Howto create a daq-object and acquire data from multiple channels
%
% This script uses a NI-DAQ device for measuring two voltages
% simultaniously in foreground and visualise them.
% Voltage 1:  A0 (Single Ended)
% Voltage 2:  A7 (Single Ended)
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
% ATTENTION: The 'Data Acquisition Toolbox™', a connected 'NI-USB' device
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

%--------------------------------------------------------------------------
%% --- Define Variables / Some preparations ---
% Set the Index of the Device that should be used for DAQ
devIdx = 1;   % only of interest when more than one device is connected

% Read some seconds of data on all channels.
readDuration = seconds(10); % in s
% Number of samples per second (in Sa/s or Hz)
samplerate = 10;  % for NI-USB-6001: maximum is 20e3 / numOfChannels
% Total number of values to read ( = time to record [s] * samplerate)
numValues = seconds(readDuration) * samplerate;

%% --- Discover Available Devices ---
% 1: Use the |daqlist()| command to display a list of devices available
% to your machine and MATLAB(R).
% Use 'daqlist("ni")' to list all available National Instruments™ devices
DeviceList = daqlist("ni");

% check daqlist if a specific device is connected and selected
% 2: check number of connected devices
if (isempty(DeviceList))
    error(' \n>> No DAQ-Device connected!');
    % OR: Use 'daqreset' if not all devices are listed correctly
    % daqreset;  % resets Data Acquisition Toolbox™/ deletes all daq objects
end
% ID/Name of the selected DAQ
devID = DeviceList.DeviceID(devIdx);

% 3: Display the device selected by devIdx
disp(strcat(">> Your device """, devID, """ ", ...
    "(", DeviceList.Model(devIdx), ") is connected properly."));

% 4: Display Device Details
% To learn more about an individual device, access the device in
% the array returned by |daqlist()| command.
%>> disp(DeviceList.DeviceInfo(devIdx));
disp(DeviceList{devIdx, "DeviceInfo"})

%--------------------------------------------------------------------------

%% --- Acquire Data ---
% Procedure to acquire data:
%   1. Create a vendor specific daq object
%   2. Add input channels
%   3. Configure input channels
%   4. Start the acquisition

% 1. create NI daq object interface
DAQBox = daq("ni"); % input is the vendor

%set samplerate (DataAcquisition scan rate)
DAQBox.Rate = samplerate;

% 2. Add channels
% addinput(d,deviceID,channelID,measurementType)
% use 'channelID' from device 'deviceID' to the specified DataAcquisition
% daq-interface 'd', configured for the specified 'measurementType'
% returns a channel-handle or its index in channellist
ch0         = DAQBox.addinput(devID, 'ai0', 'Voltage');
[ch1, idx1] = DAQBox.addinput(devID, 'ai7', 'Voltage');

% 3. Set the channel terminal configuration as 'SingleEnded' (measure to GND),
%    'SingleEndedNonReferenced', 'Differential' or 'PseudoDifferential'
ch0.TerminalConfig = 'SingleEnded';
%ch1.TerminalConfig = 'SingleEnded';
% Access one of the channel settings using its index.
DAQBox.Channels(idx1).TerminalConfig = 'SingleEnded';

% Show the channel config
disp(DAQBox.Channels);

% 4. Start data acquisition

% flush:  Clear all queued and previously acquired data
DAQBox.flush;   % or flush(DAQBox)

% now begin actual measurement:

% a) read a defined number of values into a matrix
%startdatetime = datetime('now');
%scanData=read(DAQBox,numValues,'OutputFormat','Matrix');

% b) read data for a defined duration into a timetable
%    [(Time)| ValuesCh1 | ValuesCh2 ...]
[TimeTable,  startdatetime] = DAQBox.read(readDuration);

%--------------------------------------------------------------------------

%% Display data
% plot data over time
% (just for illustration purposes)

figure(1);
plot(TimeTable.Time, TimeTable{:,1}, '-r*', 'DisplayName', 'ch0: ai0');
hold on;
plot(TimeTable.Time, TimeTable{:,2}, '-g*', 'DisplayName', 'ch1: ai7');
hold off;
title({'Data from DAQ' ; ...
    datestr(startdatetime, 'yyyy-mm-dd HH:MM:SS')});
xlabel('Time  t / s');
ylabel('Voltage  U / V');
grid on;
legend;

%--------------------------------------------------------------------------
%% Save data

% optionally save data to hard disk
%save('DAQ_Data.mat', 'startdatetime', 'TimeTable');

%--------------------------------------------------------------------------
%% More Informationen
%This summarizes the use of the NI-DAQ-Box to capture component characterstics
% >> web(fullfile(docroot, 'daq/transition-your-code-from-session-to-dataacquisition-interface.html'))
% Getting Started with NI Devices
% >> web('https://de.mathworks.com/help/daq/getting-started-with-session-based-interface-using-ni-devices.html')
% Read data acquired by hardware
% >> web('https://de.mathworks.com/help/daq/daq.interfaces.dataacquisition.read.html')

