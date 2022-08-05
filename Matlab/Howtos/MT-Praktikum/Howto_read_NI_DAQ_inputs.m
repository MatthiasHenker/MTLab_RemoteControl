% Howto create a daq-object and acquire data from multiple channels
%
% This script runs a measurement of two voltages simultaniously in fore-
% ground and visualise them. A NI-DAQ device like NI-USB-6001 is required
% Voltage 1:  A0 (Single Ended)
% Voltage 2:  A7 (Single Ended)
%
% HTW Dresden, faculty of electrical engineering
% - Measurement Engineering -
% @Robert Stoll, @Matthias Henker
% created: 2020-09-04
% edited:  2022-02-01
% version: 2.4
%
% -------------------------------------------------------------------------
% This is a simple sample script from the series of howto-files
% This script is based on the >> openExample('daq/demo_compactdaq_intro').
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

%% 1. Define Variables / Some preparations
% Index of the device that should be used for DAQ
devIdx = 1; % only of interest when more than one device is connected

% Read some seconds of data on all channels.
readDuration = seconds(10); % [s]
% Number of samples per second (in Sa/s or Hz)
samplerate = 100;   % for NI-USB-6001: maximum is 20e3 / numOfChannels
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

%% 3. Acquire Data
% 3.1) create NI daq interface object
DAQBox = daq("ni"); % input is the vendor

% 3.2) Add channels (to the daq-interface 'd')
% channelhandle = d.addinput(deviceID, channelID, measurementType)
ch0  = DAQBox.addinput(deviceInfo.ID, 'ai0', 'Voltage');
ch1  = DAQBox.addinput(deviceInfo.ID, 'ai7', 'Voltage');

% Set the channel terminal configuration as 'SingleEnded' (measure to GND)
ch0.TerminalConfig = 'SingleEnded';
ch1.TerminalConfig = 'SingleEnded';

% Show the channel config
disp(DAQBox.Channels);

% 3.3) Start data acquisition
% Set samplerate (DataAcquisition scan rate)
DAQBox.Rate = samplerate;

% flush:  Clear all queued and acquired data
DAQBox.flush; % (alternative: >> flush(DAQBox)

% a) read a defined number of values into a matrix
%>> startdatetime = datetime('now');
%>> scanData      = d.read(numValues, 'OutputFormat', 'Matrix');

% b) read data for a duration into a timetable [ Time | ValCh1 | ValCh2 ]
[TimeTable,  startdatetime] = DAQBox.read(readDuration);

%% 4. Display data
figure(1);
plot(TimeTable.Time, TimeTable{:,1}, '--rx', 'DisplayName', 'ch0: ai0');
hold on;
plot(TimeTable.Time, TimeTable{:,2}, '-.gx', 'DisplayName', 'ch1: ai7');
hold off;
title({'Data from DAQ' ; ...
    datestr(startdatetime, 'yyyy-mm-dd HH:MM:SS')});
xlabel('Time  t / s');
ylabel('Voltage  U / V');
grid on;
legend;

%% 5. Save data
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


