% Howto output analog signals with a daq-interface
%
% This script uses a NI-DAQ device to convert digital data to analog
% voltages.
% Voltage 1:  ao0 (Single Ended)
%
% HTW Dresden, faculty of electrical engineering
% - Measurement Engineering -
% @Robert Stoll, @Matthias Henker
% created: 2020-09-04
% edited:  2022-02-01
% version: 1.1
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
CleanMatlab = false; % true or false

% optionally clean Matlab
if CleanMatlab       % set to true/false to enable/disable cleaning
    daqreset;        %#ok<UNRCH> % resets DAQ Toolbox and deletes all daq objects
    clear variables; % clear all variables
    close all;       % close all figures
    clc;             % clear command window
end

%% 1. Define Variables / Some preparations
% Index of the Device that should be used for DAQ
devIdx = 1; % only of interest when more than one device is connected

% create a signal for output generation
sampleRate = 2000; % in Sa/s (or Hz) for NI-USB-6001: maximum is 5e3
numSamples = 1500;

time       = (0:numSamples-1) / sampleRate;
amplitude  = 5; % in Volt
% sine wave (samples as row vector)
numPeriods = 10;
signalData = amplitude *sin(numPeriods *2*pi* (0:numSamples-1)/numSamples);

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

%% 3. Upload Data and Control Generation
% 3.1) create NI daq interface object
DAQBox = daq("ni"); % input is the vendor

% 3.2) Add output channel ('ao0' and 'ao1' are available)
ch0    = DAQBox.addoutput(deviceInfo.ID, 'ao0', 'Voltage');
disp(DAQBox.Channels); % Show the channel config

% 3.3) Start data output
% configure sample rate
DAQBox.Rate = sampleRate;

% select option (demonstrates different commands and options)
option = 2;  % 1, 2 or 3

% Option 1: write only a single value ==> constant output signal
if option == 1
    voltageOut = 5; % in Volt
    write(DAQBox, voltageOut);
end

% Option 2: Generate a periodic signal in the background
if option == 2
    % load waveform to daq interface
    % !!! data vector has to be a column vector !!! => transpose vector
    DAQBox.preload(signalData');
    % start to output data periodically
    start(DAQBox, "RepeatOutput");
end

% Option 3: similar to option 2, but update signal in between
if option == 3
    DAQBox.preload(signalData');
    DAQBox.start("RepeatOutput");
    
    % update signal
    for i = 1:5
        disp(['...' num2str(i)]);
        pause(1);
        DAQBox.write(abs(signalData)'); % change preloaded data
        pause(1);
        DAQBox.write(signalData');      % change preloaded data
    end
end

% 3.4) Stop signal generation
%     When signal generation at NI-USB-device is stopped then last output
%     valueis hold at output (constant output voltage as long as a new
%     value is defined).

% Thus, is recommended to set output to zero to avoid unwanted output
stopGen = 0;  % true or false (0 or 1 as shorthand alternative)
if stopGen
    DAQBox.stop; %#ok<UNRCH>
    DAQBox.write(0);
end

%% Display data

figure(1);
plot(time, signalData, '-r');
title("Output on channel ao0");
xlabel('Time t / s');
ylabel('Voltage  U / V');
grid on;

%--------------------------------------------------------------------------
%% More Informationen
%This summarizes the use of the NI-DAQ-Box to capture component characterstics
% >> web(fullfile(docroot, 'daq/transition-your-code-from-session-to-dataacquisition-interface.html'))

% Getting Started with NI Devices
% >> web('https://de.mathworks.com/help/daq/getting-started-with-session-based-interface-using-ni-devices.html')

% Write output scans to hardware channels
% >> web('https://de.mathworks.com/help/daq/daq.interfaces.dataacquisition.write.html')
