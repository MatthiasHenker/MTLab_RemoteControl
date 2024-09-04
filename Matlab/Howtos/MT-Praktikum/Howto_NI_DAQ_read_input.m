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

% Read some seconds of data on all channels.
readDuration = seconds(10);   % in s
% Number of samples per second, in Sa/s (or Hz)
samplerate = 100;   % for NI-USB-6001: maximum is 20e3 / numOfChannels
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

%% 3. Configure DAQ-Device and Acquire Data
% 3.1) create NI DAQ interface object
DAQBox = daq('ni');

% 3.2) Add and configure channels (to the 'DAQBox')
% channelhandle = DAQBox.addinput(deviceID, channelID, measurementType)
% returns optionally a channel-handle or its index in channellist
ch0         = DAQBox.addinput(deviceInfo.ID, 'ai0', 'Voltage');
[ch1, idx1] = DAQBox.addinput(deviceInfo.ID, 'ai7', 'Voltage');

% Set the channel terminal configuration as 'SingleEnded' (measure to GND)
ch0.TerminalConfig = 'SingleEnded';
ch1.TerminalConfig = 'SingleEnded';
% alternatively configure the channel settings using its index.
%DAQBox.Channels(idx1).TerminalConfig = 'SingleEnded';

% Show the channel config
disp('Display configuration of selected channels:');
disp(DAQBox.Channels);

% 3.3) Start data acquisition
% Set samplerate (DataAcquisition scan rate)
DAQBox.Rate = samplerate;

% flush: clear all queued and acquired data (= delete all old date before)
DAQBox.flush; % (alternative: >> flush(DAQBox)

% a) read a defined number of values into a matrix
%>> startdatetime = datetime('now');
%>> scanData      = DAQBox.read(numValues, OutputFormat = 'Matrix');

% b) read data for a duration into a timetable [ Time | ValCh1 | ValCh2 ]
disp('Start data acquisition. Please wait ...');
[TimeTable,  datetime_start] = DAQBox.read(readDuration);
disp('  done.');

formattedTimeStamp = char(datetime(datetime_start, ...
    Format= 'yyyy-MM-dd  HH:mm:ss'));

%% 4. Display data
figure(1);
plot(TimeTable.Time, TimeTable{:,1}, '--rx', DisplayName= 'ch0: ai0');
hold on;
plot(TimeTable.Time, TimeTable{:,2}, '-.gx', DisplayName= 'ch1: ai7');
hold off;
grid on;

title(['Data from DAQBox (' formattedTimeStamp ')']);
xlabel('Time  t / s');
ylabel('Voltage  U_{ch0, ch1} / V');
legend(Location='best');

%% 5. Save data
% optionally save data to hard disk
saveData = true; % true or false

if saveData
    % save actual acqired data and timestamp of start
    save('myDAQ_Data.mat', 'TimeTable', 'datetime_start');
end

%--------------------------------------------------------------------------
%% More Informationen

% Getting Started with NI Devices
% >> web('https://de.mathworks.com/help/daq/getting-started-with-session-based-interface-using-ni-devices.html')
% Read data acquired by hardware
% >> web('https://de.mathworks.com/help/daq/daq.interfaces.dataacquisition.read.html')
% This summarizes the use of the NI-DAQ-Box to capture component characterstics
% >> web(fullfile(docroot, 'daq/transition-your-code-from-session-to-dataacquisition-interface.html'))
