%% Howto: Get Current Values from Siglent SDS2304X Oscilloscope
% This script demonstrates how to read current settings and measurements
% from a Siglent SDS2304X oscilloscope using the Scope class
%
% HTW Dresden - Faculty of Electrical Engineering
% Date: 2026-02-24
%
% Requirements:
%   - Scope class (version 3.0.0 or higher)
%   - VisaIF class (version 3.0.1 or higher)
%   - Siglent SDS2304X oscilloscope connected via USB or LAN

%% 1. Preparation
CleanMatlab = true;  % true or false

if CleanMatlab
    clear;      % clear all variables from the workspace
    close all;  % close all figures
    clc;        % clear command window
end

%% 2. Connect to Oscilloscope
% Check available devices
USBDeviceList = Scope.listAvailableVisaUsbDevices(true);

% Select interface
runDemoMode = false; % Set to true for demo mode (limited functionality)
if runDemoMode || isempty(USBDeviceList)
    interface = 'demo';
else
    interface = 'visa-usb';  % or 'visa-tcpip' for LAN connection
end

% Specify scope type for Siglent SDS2304X
ScopeType = 'SDS2304X';  % or just 'SDS' for short

% Create Scope object and open connection
myScope = Scope(ScopeType, interface);

fprintf('Connected to: %s\n\n', myScope.Vendor);

%% 3. Get Device Identification
fprintf('=== DEVICE IDENTIFICATION ===\n');
idInfo = myScope.identify();
fprintf('Vendor:   %s\n', idInfo.Vendor);
fprintf('Product:  %s\n', idInfo.Product);
fprintf('Serial:   %s\n', idInfo.SerialNumber);
fprintf('Firmware: %s\n\n', idInfo.FirmwareVersion);

%% 4. Get Acquisition State and Trigger Status
fprintf('=== ACQUISITION STATUS ===\n');
acqState = myScope.AcquisitionState;
fprintf('Acquisition State: %s\n', acqState);

trigState = myScope.TriggerState;
fprintf('Trigger State:     %s\n\n', trigState);

%% 5. Get Horizontal (Time Base) Settings
fprintf('=== HORIZONTAL (TIME BASE) SETTINGS ===\n');

% Get time division (horizontal scale)
tDiv = str2double(char(myScope.query('TIME_DIV?')));
fprintf('Time/Division:     %s (%.2e s/div)\n', ...
    formatEngineering(tDiv, 's'), tDiv);

% Get sample rate
response = myScope.query('SAMPLE_RATE?');
[value, unit] = regexpi(char(response), '^\d+\.?\d*', 'match', 'split');
sampleRate = str2double(value{1});
switch lower(unit{end})
    case 'gsa/s'
        sampleRate = sampleRate * 1e9;
    case 'msa/s'
        sampleRate = sampleRate * 1e6;
    case 'ksa/s'
        sampleRate = sampleRate * 1e3;
end
fprintf('Sample Rate:       %s (%.2e Sa/s)\n', ...
    formatEngineering(sampleRate, 'Sa/s'), sampleRate);

% Get memory depth (number of samples)
response = myScope.query('SAMPLE_NUM? C1');
[value, ~] = regexpi(char(response), '^\d+\.?\d*', 'match', 'split');
memDepth = str2double(value{1});
fprintf('Memory Depth:      %s samples\n', formatSamples(memDepth));

% Get trigger delay
response = myScope.query('TRIG_DELAY?');
[value, ~] = regexpi(char(response), '^-?\d+\.?\d*', 'match', 'split');
trigDelay = str2double(value{1});
fprintf('Trigger Delay:     %s (%.2e s)\n\n', ...
    formatEngineering(trigDelay, 's'), trigDelay);

%% 6. Get Vertical (Channel) Settings for All Channels
fprintf('=== VERTICAL (CHANNEL) SETTINGS ===\n');

channels = 1:4;  % SDS2304X has 4 channels

for ch = channels
    fprintf('--- Channel %d ---\n', ch);
    
    % Check if channel is enabled
    trace = char(myScope.query(sprintf('C%d:TRACE?', ch)));
    fprintf('  Trace:           %s\n', trace);
    
    if strcmpi(trace, 'ON')
        % Get voltage division
        vDiv = str2double(char(myScope.query(sprintf('C%d:VDIV?', ch))));
        fprintf('  Volt/Division:   %s (%.2e V/div)\n', ...
            formatEngineering(vDiv, 'V'), vDiv);
        
        % Get voltage offset
        vOffset = str2double(char(myScope.query(sprintf('C%d:OFFSET?', ch))));
        fprintf('  Voltage Offset:  %s (%.2e V)\n', ...
            formatEngineering(-vOffset, 'V'), -vOffset);
        
        % Get coupling
        coupling = char(myScope.query(sprintf('C%d:COUPLING?', ch)));
        fprintf('  Coupling:        %s\n', coupling);
        
        % Get attenuation (probe)
        atten = str2double(char(myScope.query(sprintf('C%d:ATTENUATION?', ch))));
        fprintf('  Probe:           %gX\n', atten);
        
        % Get bandwidth limit
        bwLimit = char(myScope.query(sprintf('C%d:BANDWIDTH_LIMIT?', ch)));
        fprintf('  BW Limit:        %s\n', bwLimit);
        
        % Get unit
        unit = char(myScope.query(sprintf('C%d:UNIT?', ch)));
        fprintf('  Unit:            %s\n', unit);
        
        % Get invert status
        invert = char(myScope.query(sprintf('C%d:INVS?', ch)));
        fprintf('  Inverted:        %s\n', invert);
    end
    fprintf('\n');
end

%% 7. Get Trigger Settings
fprintf('=== TRIGGER SETTINGS ===\n');

% Get trigger type
trigType = char(myScope.query('TRIG_SELECT?'));
fprintf('Trigger Type:      %s\n', trigType);

% For edge trigger, get additional parameters
if contains(lower(trigType), 'edge')
    % Get trigger source
    response = char(myScope.query('TRIG_SELECT?'));
    % Parse response to extract source (format: EDGE,SR,C1,HT,OFF)
    parts = strsplit(response, ',');
    if length(parts) >= 3
        trigSource = parts{3};
        fprintf('Trigger Source:    %s\n', trigSource);
        
        % Get trigger level
        trigLevel = str2double(char(myScope.query(sprintf('%s:TRIG_LEVEL?', trigSource))));
        fprintf('Trigger Level:     %s (%.2e V)\n', ...
            formatEngineering(trigLevel, 'V'), trigLevel);
    end
    
    % Get trigger slope
    if length(parts) >= 4
        trigSlope = parts{4};
        fprintf('Trigger Slope:     %s\n', trigSlope);
    end
    
    % Get trigger coupling
    if length(parts) >= 5
        trigCoupling = parts{5};
        fprintf('Trigger Coupling:  %s\n', trigCoupling);
    end
end
fprintf('\n');

%% 8. Get Acquisition Mode Settings
fprintf('=== ACQUISITION MODE ===\n');

% Get acquisition type
acqType = char(myScope.query('ACQUIRE_WAY?'));
fprintf('Acquisition Mode:  %s\n', acqType);

% If in average mode, get number of averages
if contains(lower(acqType), 'average')
    numAvg = str2double(char(myScope.query('AVERAGE_ACQUIRE?')));
    fprintf('Number of Averages: %g\n', numAvg);
end
fprintf('\n');

%% 9. Get Measurements from Enabled Channels
fprintf('=== AUTOMATIC MEASUREMENTS ===\n');

for ch = channels
    % Check if channel is enabled
    trace = char(myScope.query(sprintf('C%d:TRACE?', ch)));
    
    if strcmpi(trace, 'ON')
        fprintf('--- Channel %d Measurements ---\n', ch);
        
        % Frequency
        meas = myScope.runMeasurement('channel', ch, 'parameter', 'freq');
        if meas.status == 0 && ~isnan(meas.value)
            fprintf('  Frequency:       %s\n', formatMeasurement(meas));
        end
        
        % Peak-to-Peak
        meas = myScope.runMeasurement('channel', ch, 'parameter', 'pk-pk');
        if meas.status == 0 && ~isnan(meas.value)
            fprintf('  Peak-to-Peak:    %s\n', formatMeasurement(meas));
        end
        
        % RMS
        meas = myScope.runMeasurement('channel', ch, 'parameter', 'rms');
        if meas.status == 0 && ~isnan(meas.value)
            fprintf('  RMS:             %s\n', formatMeasurement(meas));
        end
        
        % Mean
        meas = myScope.runMeasurement('channel', ch, 'parameter', 'mean');
        if meas.status == 0 && ~isnan(meas.value)
            fprintf('  Mean:            %s\n', formatMeasurement(meas));
        end
        
        % Period
        meas = myScope.runMeasurement('channel', ch, 'parameter', 'per');
        if meas.status == 0 && ~isnan(meas.value)
            fprintf('  Period:          %s\n', formatMeasurement(meas));
        end
        
        fprintf('\n');
    end
end

%% 10. Display Intensity Settings
fprintf('=== DISPLAY SETTINGS ===\n');
dispSettings = char(myScope.query('INTENSITY?'));
fprintf('Intensity Settings: %s\n\n', dispSettings);

%% 11. Check for Errors
fprintf('=== ERROR STATUS ===\n');
errors = myScope.ErrorMessages;
fprintf('Error Messages: %s\n', errors);

%% 12. Close Connection
myScope.close;
myScope.delete;
fprintf('\nConnection closed.\n');

%% Helper Functions

function str = formatEngineering(value, unit)
    % Format a value in engineering notation
    if abs(value) >= 1e9
        str = sprintf('%.2f G%s', value/1e9, unit);
    elseif abs(value) >= 1e6
        str = sprintf('%.2f M%s', value/1e6, unit);
    elseif abs(value) >= 1e3
        str = sprintf('%.2f k%s', value/1e3, unit);
    elseif abs(value) >= 1
        str = sprintf('%.2f %s', value, unit);
    elseif abs(value) >= 1e-3
        str = sprintf('%.2f m%s', value*1e3, unit);
    elseif abs(value) >= 1e-6
        str = sprintf('%.2f µ%s', value*1e6, unit);
    elseif abs(value) >= 1e-9
        str = sprintf('%.2f n%s', value*1e9, unit);
    else
        str = sprintf('%.2e %s', value, unit);
    end
end

function str = formatSamples(value)
    % Format sample count in engineering notation
    if value >= 1e6
        str = sprintf('%.0f MSa', value/1e6);
    elseif value >= 1e3
        str = sprintf('%.0f kSa', value/1e3);
    else
        str = sprintf('%.0f Sa', value);
    end
end

function str = formatMeasurement(meas)
    % Format measurement result with value and unit
    str = sprintf('%s %s', formatEngineering(meas.value, ''), meas.unit);
end
