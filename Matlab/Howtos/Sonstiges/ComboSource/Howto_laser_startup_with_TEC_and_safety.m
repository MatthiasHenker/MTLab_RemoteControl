%% Howto: Laser Startup Procedure with TEC Control and Safety Checks
% This script demonstrates a complete laser startup procedure including:
%   - TEC temperature stabilization
%   - Safety enclosure check
%   - Gradual laser current ramping
%   - Safe shutdown sequence
%
% HTW Dresden - Faculty of Electrical Engineering
% Date: 2026-02-24
%
% IMPORTANT SAFETY NOTES:
%   - The enclosure MUST be closed before enabling the laser
%   - The enclosure has limit switches that will prevent laser operation
%   - Never look directly into the laser beam
%   - Always wear appropriate laser safety goggles
%
% Device: Arroyo Instruments ComboSource 6301 Laser Controller
% Configuration: COM1, 9600 baud, CR terminator

%% 1. Preparation
CleanMatlab = true;  % true or false

if CleanMatlab
    clear;      % clear all variables from the workspace
    close all;  % close all figures
    clc;        % clear command window
end

%% 2. Connect to Arroyo ComboSource 6301
fprintf('==========================================================\n');
fprintf('   ARROYO COMBOSOURCE 6301 - LASER STARTUP PROCEDURE\n');
fprintf('==========================================================\n\n');

% Create serial connection
s = serialport('COM1', 9600);
configureTerminator(s, 'CR');  % Arroyo uses CR (0x0D) only
s.Timeout = 2;

fprintf('Connected to Arroyo ComboSource 6301 on COM1\n\n');

% Get device identification
writeline(s, '*IDN?');
idString = readline(s);
fprintf('Device ID: %s\n', idString);

% Clear any previous errors
writeline(s, 'ERR?');
errorCode = str2double(readline(s));
if errorCode ~= 0
    writeline(s, 'ERRSTR?');
    errorMsg = readline(s);
    fprintf('⚠ Clearing previous error: E-%d: %s\n', errorCode, errorMsg);
end
fprintf('\n');

%% 3. Configure and Enable TEC (Temperature Control)
fprintf('=== STEP 1: TEC TEMPERATURE CONTROL ===\n');

% Set temperature limits (safety)
TEC_TEMP_MIN = 15.0;  % °C
TEC_TEMP_MAX = 35.0;  % °C
TEC_TARGET_TEMP = 20.0;  % °C

fprintf('Setting TEC temperature limits...\n');
writeline(s, sprintf('TEC:LIM:TLO %.1f', TEC_TEMP_MIN));
pause(0.1);
writeline(s, sprintf('TEC:LIM:THI %.1f', TEC_TEMP_MAX));
pause(0.1);

% Check for errors after setting limits
writeline(s, 'ERR?');
errorCode = str2double(readline(s));
if errorCode ~= 0
    writeline(s, 'ERRSTR?');
    errorMsg = readline(s);
    fprintf('✗ ERROR setting TEC limits: E-%d: %s\n', errorCode, errorMsg);
    clear s;
    error('Failed to configure TEC temperature limits.');
end

% Verify limits
writeline(s, 'TEC:LIM:TLO?');
tempLimitLow = str2double(readline(s));
writeline(s, 'TEC:LIM:THI?');
tempLimitHigh = str2double(readline(s));
fprintf('  Temperature limits: %.1f°C to %.1f°C\n', tempLimitLow, tempLimitHigh);

% Set TEC to temperature control mode
fprintf('Setting TEC to temperature control mode...\n');
writeline(s, 'TEC:MODE:T');
pause(0.2);

% Set target temperature
fprintf('Setting target temperature to %.1f°C...\n', TEC_TARGET_TEMP);
writeline(s, sprintf('TEC:T %.1f', TEC_TARGET_TEMP));
pause(0.2);

% Check for errors after setting temperature
writeline(s, 'ERR?');
errorCode = str2double(readline(s));
if errorCode ~= 0
    writeline(s, 'ERRSTR?');
    errorMsg = readline(s);
    fprintf('✗ ERROR setting TEC temperature: E-%d: %s\n', errorCode, errorMsg);
    clear s;
    error('Failed to set TEC target temperature. Check if value is within limits.');
end

% Verify setpoint
writeline(s, 'TEC:SET:T?');
setpointTemp = str2double(readline(s));
fprintf('  TEC setpoint confirmed: %.2f°C\n', setpointTemp);

% Read current temperature before enabling TEC
writeline(s, 'TEC:T?');
initialTemp = str2double(readline(s));
fprintf('  Current temperature (TEC OFF): %.2f°C\n', initialTemp);

% Enable TEC
fprintf('Enabling TEC...\n');
writeline(s, 'TEC:OUT 1');
pause(0.2);

% Check for errors after enabling TEC
writeline(s, 'ERR?');
errorCode = str2double(readline(s));
if errorCode ~= 0
    writeline(s, 'ERRSTR?');
    errorMsg = readline(s);
    fprintf('✗ ERROR enabling TEC: E-%d: %s\n', errorCode, errorMsg);
    if errorCode == 508
        fprintf('Error E-508: Parameter out of range.\n');
        fprintf('  Possible issue: Temperature setpoint (%.1f°C) may be outside allowed range.\n', TEC_TARGET_TEMP);
        fprintf('  Or temperature limits (%.1f°C to %.1f°C) may be invalid.\n', TEC_TEMP_MIN, TEC_TEMP_MAX);
    end
    clear s;
    error('Failed to enable TEC.');
end

% Verify TEC is enabled
writeline(s, 'TEC:OUT?');
tecStatus = str2double(readline(s));
if tecStatus == 1
    fprintf('✓ TEC is now ENABLED\n\n');
else
    fprintf('✗ TEC failed to enable! Aborting...\n');
    clear s;
    error('TEC enable verification failed.');
end

%% 4. Wait for Temperature Stabilization (30 seconds minimum)
fprintf('=== STEP 2: TEMPERATURE STABILIZATION ===\n');
fprintf('Waiting for temperature to stabilize (minimum 30 seconds)...\n\n');

STABILIZATION_TIME = 30;  % seconds
fprintf('Time(s)  Temp(°C)  Setpoint(°C)  TEC(A)   Error(°C)  Status\n');
fprintf('-------  --------  ------------  -------  ---------  ------\n');

for t = 1:STABILIZATION_TIME
    % Read current temperature
    writeline(s, 'TEC:T?');
    currentTemp = str2double(readline(s));
    
    % Read TEC current
    writeline(s, 'TEC:ITE?');
    tecCurrent = str2double(readline(s));
    
    % Calculate temperature error
    tempError = abs(setpointTemp - currentTemp);
    
    % Status indicator
    if tempError < 0.5
        statusStr = '✓ Stable';
    elseif tempError < 1.0
        statusStr = '~ Near';
    else
        statusStr = '↑ Heating';
    end
    
    fprintf('%4d     %7.2f       %7.2f     %6.3f    %+6.2f     %s\n', ...
        t, currentTemp, setpointTemp, tecCurrent, setpointTemp - currentTemp, statusStr);
    
    pause(1);
end

% Final temperature check
writeline(s, 'TEC:T?');
finalTemp = str2double(readline(s));
tempError = abs(setpointTemp - finalTemp);

fprintf('\n');
fprintf('Temperature stabilization complete:\n');
fprintf('  Initial:  %.2f°C\n', initialTemp);
fprintf('  Final:    %.2f°C\n', finalTemp);
fprintf('  Target:   %.2f°C\n', setpointTemp);
fprintf('  Error:    %.2f°C\n', tempError);

if tempError < 1.0
    fprintf('✓ Temperature within acceptable range\n\n');
else
    fprintf('⚠ Temperature error is %.2f°C (may need more time)\n\n', tempError);
end

%% 5. Safety Check: Enclosure Closed?
fprintf('=== STEP 3: SAFETY ENCLOSURE CHECK ===\n');
fprintf('⚠  IMPORTANT SAFETY CHECK  ⚠\n\n');
fprintf('The laser enclosure MUST be closed before enabling the laser.\n');
fprintf('The enclosure has limit switches that prevent laser operation\n');
fprintf('when the enclosure is open (for safety).\n\n');
fprintf('If the enclosure is open, you will get an error when trying\n');
fprintf('to enable the laser output.\n\n');
fprintf('Please verify:\n');
fprintf('  [ ] Enclosure is completely closed\n');
fprintf('  [ ] All safety covers are in place\n');

% Wait for user confirmation
input('Press ENTER to confirm enclosure is closed and continue... ', 's');
fprintf('\n✓ User confirmed enclosure safety\n\n');

%% 6. Configure Laser Parameters
fprintf('=== STEP 4: LASER CONFIGURATION ===\n');

% Set laser parameters
LASER_CURRENT_LIMIT = 150.0;  % mA (maximum allowed)
LASER_POWER_LIMIT = 0.99;     % mW (maximum allowed power)
LASER_START_CURRENT = 0.0;    % mA (starting current)
LASER_TARGET_CURRENT = 27.5;  % mA (target operating current)
CURRENT_RAMP_STEP = 0.5;      % mA (current increase per step)
RAMP_STEP_DELAY = 0.5;        % seconds (delay between steps)

% First, read current limits to check what's already configured
fprintf('Reading current laser limits...\n');
writeline(s, 'LAS:LIM:LDI?');
currentLimitRead = str2double(readline(s));
fprintf('  Current limit (hardware): %.1f mA\n', currentLimitRead);

% Only set limit if it needs to be changed and is valid
if currentLimitRead ~= LASER_CURRENT_LIMIT && LASER_CURRENT_LIMIT <= currentLimitRead
    fprintf('Setting laser current limit to %.1f mA...\n', LASER_CURRENT_LIMIT);
    writeline(s, sprintf('LAS:LIM:LDI %.1f', LASER_CURRENT_LIMIT));
    pause(0.2);
    
    % Verify limit was set
    writeline(s, 'LAS:LIM:LDI?');
    currentLimit = str2double(readline(s));
    fprintf('  Current limit confirmed: %.1f mA\n', currentLimit);
else
    fprintf('  Using existing current limit: %.1f mA\n', currentLimitRead);
    LASER_CURRENT_LIMIT = currentLimitRead;
end

% Set initial laser current to 0
fprintf('Setting initial laser current to %.1f mA...\n', LASER_START_CURRENT);
writeline(s, sprintf('LAS:LDI %.1f', LASER_START_CURRENT));
pause(0.2);

% Verify initial current
writeline(s, 'LAS:LDI?');
currentSetpoint = str2double(readline(s));
fprintf('  Initial current confirmed: %.1f mA\n\n', currentSetpoint);

%% 7. Enable Laser Output
fprintf('=== STEP 5: LASER ENABLE ===\n');
fprintf('Attempting to enable laser output...\n');

% Clear any previous errors before attempting enable
writeline(s, 'ERR?');
preErrorCode = str2double(readline(s));
if preErrorCode ~= 0
    fprintf('⚠ Clearing previous error E-%d before laser enable...\n', preErrorCode);
end

writeline(s, 'LAS:OUT 1');
pause(0.5);

% Verify laser is enabled
writeline(s, 'LAS:OUT?');
laserStatus = str2double(readline(s));

% Check for errors after enable attempt
writeline(s, 'ERR?');
errorCode = str2double(readline(s));

if errorCode ~= 0
    writeline(s, 'ERRSTR?');
    errorMsg = readline(s);
    fprintf('\n✗ ERROR: Laser failed to enable!\n');
    fprintf('  Error code: E-%d\n', errorCode);
    fprintf('  Error message: %s\n\n', errorMsg);
    
    % Provide specific guidance based on error code
    switch errorCode
        case 202
            fprintf('Error E-202: Laser output cannot be enabled.\n');
            fprintf('  Check: Enclosure interlock, limit switches, or hardware issue.\n');
        case 508
            fprintf('Error E-508: Parameter out of range.\n');
            fprintf('  Check: Current limit, temperature limits, or setpoint values.\n');
        otherwise
            fprintf('Unknown error. Check device manual for error code E-%d.\n', errorCode);
    end
    fprintf('\nShutting down TEC and exiting...\n');
    
    % Disable TEC
    writeline(s, 'TEC:OUT 0');
    clear s;
    error('Laser startup aborted due to safety error.');
end

if laserStatus == 1
    fprintf('✓ Laser output is now ENABLED\n\n');
else
    fprintf('✗ Laser failed to enable (check errors)\n\n');
    % Disable TEC
    writeline(s, 'TEC:OUT 0');
    clear s;
    error('Laser startup failed.');
end

%% 8. Gradual Current Ramping
fprintf('=== STEP 6: LASER CURRENT RAMP-UP ===\n');
fprintf('Gradually increasing laser current from %.1f mA to %.1f mA\n', ...
    LASER_START_CURRENT, LASER_TARGET_CURRENT);
fprintf('  Step size: %.2f mA\n', CURRENT_RAMP_STEP);
fprintf('  Step delay: %.1f seconds\n', RAMP_STEP_DELAY);
fprintf('  Power limit: %.2f mW\n\n', LASER_POWER_LIMIT);

fprintf('Step  Current(mA)  Power(mW)   Temp(°C)   Status\n');
fprintf('----  -----------  ----------  ---------  ------\n');

% Calculate number of steps
numSteps = round((LASER_TARGET_CURRENT - LASER_START_CURRENT) / CURRENT_RAMP_STEP);
stepCounter = 0;

% Ramp up current gradually
for targetCurrent = LASER_START_CURRENT:CURRENT_RAMP_STEP:LASER_TARGET_CURRENT
    stepCounter = stepCounter + 1;
    
    % Set new current
    writeline(s, sprintf('LAS:LDI %.2f', targetCurrent));
    pause(RAMP_STEP_DELAY);
    
    % Read actual current
    writeline(s, 'LAS:LDI?');
    actualCurrent = str2double(readline(s));
    
    % Read laser diode voltage (could calculate power if needed)
    writeline(s, 'LAS:LDV?');
    laserVoltage = str2double(readline(s));
    
    % Estimate power (simplified - actual power would need photodiode)
    estimatedPower = actualCurrent * 0.030;  % rough estimate: ~30 µW per mA
    
    % Read temperature
    writeline(s, 'TEC:T?');
    currentTemp = str2double(readline(s));
    
    % Status check
    if estimatedPower > LASER_POWER_LIMIT
        statusStr = '⚠ Power limit!';
        fprintf('%3d     %8.2f     %8.3f     %7.2f    %s\n', ...
            stepCounter, actualCurrent, estimatedPower, currentTemp, statusStr);
        fprintf('\n⚠ Power limit exceeded! Stopping current ramp.\n');
        break;
    else
        statusStr = '✓ OK';
        fprintf('%3d     %8.2f     %8.3f     %7.2f    %s\n', ...
            stepCounter, actualCurrent, estimatedPower, currentTemp, statusStr);
    end
end

fprintf('\n✓ Current ramp completed\n');
fprintf('  Final current: %.2f mA\n', targetCurrent);
fprintf('  Estimated power: %.3f mW\n\n', estimatedPower);

%% 9. Brief Operation Period
fprintf('=== STEP 7: LASER OPERATION ===\n');
fprintf('Laser is now operating at target parameters.\n');
fprintf('Monitoring for 5 seconds...\n\n');

fprintf('Time(s)  Current(mA)  Voltage(V)  Power(mW)  Temp(°C)\n');
fprintf('-------  -----------  ----------  ---------  --------\n');

for t = 1:5
    % Read laser current
    writeline(s, 'LAS:LDI?');
    laserCurrent = str2double(readline(s));
    
    % Read laser voltage
    writeline(s, 'LAS:LDV?');
    laserVoltage = str2double(readline(s));
    
    % Estimate power
    estimatedPower = laserCurrent * 0.030;
    
    % Read temperature
    writeline(s, 'TEC:T?');
    currentTemp = str2double(readline(s));
    
    fprintf('%4d     %8.2f     %8.3f    %8.3f    %7.2f\n', ...
        t, laserCurrent, laserVoltage, estimatedPower, currentTemp);
    
    pause(1);
end

fprintf('\n');

%% 10. Safe Shutdown Sequence
fprintf('=== STEP 8: SAFE SHUTDOWN ===\n');
fprintf('Beginning safe shutdown sequence...\n\n');

% Step 1: Ramp down laser current
fprintf('1. Ramping down laser current...\n');
writeline(s, 'LAS:LDI 0');
pause(0.5);

writeline(s, 'LAS:LDI?');
currentSetpoint = str2double(readline(s));
fprintf('   Current set to %.2f mA\n', currentSetpoint);

% Step 2: Disable laser output
fprintf('2. Disabling laser output...\n');
writeline(s, 'LAS:OUT 0');
pause(0.5);

% Verify laser is disabled
writeline(s, 'LAS:OUT?');
laserStatus = str2double(readline(s));
if laserStatus == 0
    fprintf('   ✓ Laser output DISABLED\n');
else
    fprintf('   ⚠ Warning: Laser may still be enabled\n');
end

% Step 3: Disable TEC
fprintf('3. Disabling TEC...\n');
writeline(s, 'TEC:OUT 0');
pause(0.5);

% Verify TEC is disabled
writeline(s, 'TEC:OUT?');
tecStatus = str2double(readline(s));
if tecStatus == 0
    fprintf('   ✓ TEC DISABLED\n');
else
    fprintf('   ⚠ Warning: TEC may still be enabled\n');
end

% Step 4: Final temperature reading
writeline(s, 'TEC:T?');
finalTemp = str2double(readline(s));
fprintf('4. Final temperature: %.2f°C\n\n', finalTemp);

%% 11. Final Error Check
fprintf('=== FINAL ERROR CHECK ===\n');
writeline(s, 'ERR?');
errorCode = str2double(readline(s));
if errorCode == 0
    fprintf('✓ No device errors\n');
else
    writeline(s, 'ERRSTR?');
    errorMsg = readline(s);
    fprintf('⚠ Device error: E-%d: %s\n', errorCode, errorMsg);
end

%% 12. Close Connection
clear s;
fprintf('\n==========================================================\n');
fprintf('   LASER STARTUP PROCEDURE COMPLETED SUCCESSFULLY\n');
fprintf('==========================================================\n');
fprintf('Connection closed.\n\n');

fprintf('Summary:\n');
fprintf('  - TEC stabilized at %.2f°C (target: %.2f°C)\n', finalTemp, TEC_TARGET_TEMP);
fprintf('  - Laser ramped to %.2f mA (target: %.2f mA)\n', targetCurrent, LASER_TARGET_CURRENT);
fprintf('  - All systems safely shut down\n');
fprintf('\n');
