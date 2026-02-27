%% Howto: Laser Startup Procedure with TEC Control and Safety Checks
% This script demonstrates a complete laser startup procedure including:
%   - TEC temperature stabilization
%   - Safety enclosure check
%   - Gradual laser current ramping
%   - Safe shutdown sequence
%
% HTW Dresden - Faculty of Electrical Engineering
% Date: 2026-02-27
% Author: Florian Römer
%
% IMPORTANT SAFETY NOTES:
%   - The enclosure MUST be closed before enabling the laser
%   - The enclosure has limit switches that will prevent laser operation
%   - Never look directly into the laser beam
%   - Always wear appropriate laser safety goggles
%
% Device: Arroyo Instruments ComboSource 6301 Laser Controller
% Requires: ComboSource6301 class, VisaIF framework

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

% Create ComboSource6301 object
% Use 'none' for clean output (recommended), 'few' for status, 'all' for debug
myLaser = ComboSource6301('Arroyo-6301', 'visa-serial', 'none');

fprintf('Connected to Arroyo ComboSource 6301\n\n');

% Get device identification
idString = myLaser.getID();
fprintf('Device ID: %s\n', idString);

% Clear any previous errors
errorCode = myLaser.getError();
if errorCode ~= 0
    errorMsg = myLaser.getErrorString();
    fprintf('Clearing previous error: E-%d: %s\n', errorCode, errorMsg);
    myLaser.clear();
end
fprintf('\n');

%% 3. Configure and Enable TEC (Temperature Control)
fprintf('=== STEP 1: TEC TEMPERATURE CONTROL ===\n');

% Set temperature limits (safety)
TEC_TEMP_MIN = 15.0;  % °C
TEC_TEMP_MAX = 35.0;  % °C
TEC_TARGET_TEMP = 20.0;  % °C

fprintf('Setting TEC temperature limits...\n');
myLaser.setTECTempLimitLow(TEC_TEMP_MIN);
myLaser.setTECTempLimitHigh(TEC_TEMP_MAX);

% Check for errors after setting limits
errorCode = myLaser.getError();
if errorCode ~= 0
    errorMsg = myLaser.getErrorString();
    fprintf('ERROR setting TEC limits: E-%d: %s\n', errorCode, errorMsg);
    myLaser.delete;
    error('Failed to configure TEC temperature limits.');
end

fprintf('  Temperature limits: %.1f°C to %.1f°C\n', TEC_TEMP_MIN, TEC_TEMP_MAX);

% Set TEC to temperature control mode
fprintf('Setting TEC to temperature control mode...\n');
myLaser.setTECModeTemperature();

% Set target temperature
fprintf('Setting target temperature to %.1f°C...\n', TEC_TARGET_TEMP);
myLaser.setTemperature(TEC_TARGET_TEMP);

% Check for errors after setting temperature
errorCode = myLaser.getError();
if errorCode ~= 0
    errorMsg = myLaser.getErrorString();
    fprintf('ERROR setting TEC temperature: E-%d: %s\n', errorCode, errorMsg);
    myLaser.delete;
    error('Failed to set TEC target temperature. Check if value is within limits.');
end

% Verify setpoint
setpointTemp = myLaser.getTempSetpoint();
fprintf('  TEC setpoint confirmed: %.2f°C\n', setpointTemp);

% Read current temperature before enabling TEC
initialTemp = myLaser.getTemperature();
fprintf('  Current temperature (TEC OFF): %.2f°C\n', initialTemp);

% Enable TEC
fprintf('Enabling TEC...\n');
myLaser.enableTEC();

% Check for errors after enabling TEC
errorCode = myLaser.getError();
if errorCode ~= 0
    errorMsg = myLaser.getErrorString();
    fprintf('ERROR enabling TEC: E-%d: %s\n', errorCode, errorMsg);
    if errorCode == 508
        fprintf('Error E-508: Parameter out of range.\n');
        fprintf('  Possible issue: Temperature setpoint (%.1f°C) may be outside allowed range.\n', TEC_TARGET_TEMP);
        fprintf('  Or temperature limits (%.1f°C to %.1f°C) may be invalid.\n', TEC_TEMP_MIN, TEC_TEMP_MAX);
    end
    myLaser.delete;
    error('Failed to enable TEC.');
end

% Verify TEC is enabled
if myLaser.isTECEnabled()
    fprintf('TEC is now ENABLED\n\n');
else
    fprintf('TEC failed to enable! Aborting...\n');
    myLaser.delete;
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
    currentTemp = myLaser.getTemperature();
    
    % Read TEC current
    tecCurrent = myLaser.getTECCurrent();
    
    % Calculate temperature error
    tempError = abs(setpointTemp - currentTemp);
    
    % Status indicator
    if tempError < 0.5
        statusStr = 'Stable';
    elseif tempError < 1.0
        statusStr = 'Near';
    else
        statusStr = 'Heating';
    end
    
    fprintf('%4d     %7.2f       %7.2f     %6.3f    %+6.2f     %s\n', ...
        t, currentTemp, setpointTemp, tecCurrent, setpointTemp - currentTemp, statusStr);
    
    pause(1);
end

% Final temperature check
finalTemp = myLaser.getTemperature();
tempError = abs(setpointTemp - finalTemp);

fprintf('\n');
fprintf('Temperature stabilization complete:\n');
fprintf('  Initial:  %.2f°C\n', initialTemp);
fprintf('  Final:    %.2f°C\n', finalTemp);
fprintf('  Target:   %.2f°C\n', setpointTemp);
fprintf('  Error:    %.2f°C\n', tempError);

if tempError < 1.0
    fprintf('Temperature within acceptable range\n\n');
else
    fprintf('Temperature error is %.2f°C (may need more time)\n\n', tempError);
end

%% 5. Safety Check: Enclosure Closed?
fprintf('=== STEP 3: SAFETY ENCLOSURE CHECK ===\n');
fprintf('IMPORTANT SAFETY CHECK\n\n');
fprintf('The laser enclosure MUST be closed before enabling the laser.\n');
fprintf('The enclosure has limit switches that prevent laser operation\n');
fprintf('when the enclosure is open (for safety).\n\n');

% Check interlock status
if myLaser.isInterlockClosed()
    fprintf('Interlock status: CLOSED (safe to proceed)\n\n');
else
    fprintf('WARNING: Interlock is OPEN!\n');
    fprintf('Close the enclosure completely before continuing.\n\n');
    myLaser.disableTEC();
    myLaser.delete;
    error('Cannot enable laser - interlock is open.');
end

fprintf('Please verify:\n');
fprintf('  [ ] Enclosure is completely closed\n');
fprintf('  [ ] All safety covers are in place\n');

% Wait for user confirmation
input('Press ENTER to confirm enclosure is closed and continue... ', 's');
fprintf('\nUser confirmed enclosure safety\n\n');

%% 6. Configure Laser Parameters
fprintf('=== STEP 4: LASER CONFIGURATION ===\n');

% Set laser parameters
LASER_CURRENT_LIMIT = 150.0;  % mA (maximum allowed)
LASER_START_CURRENT = 0.0;    % mA (starting current)
LASER_TARGET_CURRENT = 28.0;  % mA (target operating current)
CURRENT_RAMP_STEP = 0.5;      % mA (current increase per step)
RAMP_STEP_DELAY = 0.5;        % seconds (delay between steps)

% Read current limits
fprintf('Reading current laser limits...\n');
currentLimitRead = myLaser.getLaserCurrentLimit();
fprintf('  Current limit (hardware): %.1f mA\n', currentLimitRead);

% Set laser current limit
fprintf('Setting laser current limit to %.1f mA...\n', LASER_CURRENT_LIMIT);
myLaser.setLaserCurrentLimit(LASER_CURRENT_LIMIT);

% Verify limit was set
currentLimit = myLaser.getLaserCurrentLimit();
fprintf('  Current limit confirmed: %.1f mA\n', currentLimit);

% Set initial laser current to 0
fprintf('Setting initial laser current to %.1f mA...\n', LASER_START_CURRENT);
myLaser.setLaserCurrent(LASER_START_CURRENT);

% Verify initial current
currentSetpoint = myLaser.getLaserCurrent();
fprintf('  Initial current confirmed: %.1f mA\n\n', currentSetpoint);

%% 7. Enable Laser Output
fprintf('=== STEP 5: LASER ENABLE ===\n');
fprintf('Attempting to enable laser output...\n');

% Clear any previous errors before attempting enable
preErrorCode = myLaser.getError();
if preErrorCode ~= 0
    fprintf('Clearing previous error E-%d before laser enable...\n', preErrorCode);
    myLaser.clear();
end

myLaser.enableLaser();

% Verify laser is enabled
laserEnabled = myLaser.isLaserEnabled();

% Check for errors after enable attempt
errorCode = myLaser.getError();

if errorCode ~= 0
    errorMsg = myLaser.getErrorString();
    fprintf('\nERROR: Laser failed to enable!\n');
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
    myLaser.disableTEC();
    myLaser.delete;
    error('Laser startup aborted due to safety error.');
end

if laserEnabled
    fprintf('Laser output is now ENABLED\n\n');
else
    fprintf('Laser failed to enable (check errors)\n\n');
    % Disable TEC
    myLaser.disableTEC();
    myLaser.delete;
    error('Laser startup failed.');
end

%% 8. Gradual Current Ramping
fprintf('=== STEP 6: LASER CURRENT RAMP-UP ===\n');
fprintf('Gradually increasing laser current from %.1f mA to %.1f mA\n', ...
    LASER_START_CURRENT, LASER_TARGET_CURRENT);
fprintf('  Step size: %.2f mA\n', CURRENT_RAMP_STEP);
fprintf('  Step delay: %.1f seconds\n\n', RAMP_STEP_DELAY);

fprintf('Step  Current(mA)  Temp(°C)   Status\n');
fprintf('----  -----------  ---------  ------\n');

% Calculate number of steps
numSteps = round((LASER_TARGET_CURRENT - LASER_START_CURRENT) / CURRENT_RAMP_STEP);
stepCounter = 0;

% Ramp up current gradually
for targetCurrent = LASER_START_CURRENT:CURRENT_RAMP_STEP:LASER_TARGET_CURRENT
    stepCounter = stepCounter + 1;
    
    % Set new current
    myLaser.setLaserCurrent(targetCurrent);
    pause(RAMP_STEP_DELAY);
    
    % Read actual current
    actualCurrent = myLaser.getLaserCurrent();
    
    % Read temperature
    currentTemp = myLaser.getTemperature();
    
    % Status check
    statusStr = 'OK';
    fprintf('%3d     %8.2f     %7.2f    %s\n', ...
        stepCounter, actualCurrent, currentTemp, statusStr);
end

fprintf('\nCurrent ramp completed\n');
fprintf('  Final current: %.2f mA\n\n', targetCurrent);

%% 9. Brief Operation Period
fprintf('=== STEP 7: LASER OPERATION ===\n');
fprintf('Laser is now operating at target parameters.\n');
fprintf('Monitoring for 5 seconds...\n\n');

fprintf('Time(s)  Current(mA)  Temp(°C)\n');
fprintf('-------  -----------  --------\n');

for t = 1:5
    % Read laser current
    laserCurrent = myLaser.getLaserCurrent();
    
    % Read temperature
    currentTemp = myLaser.getTemperature();
    
    fprintf('%4d     %8.2f     %7.2f\n', ...
        t, laserCurrent, currentTemp);
    
    pause(1);
end

fprintf('\n');

%% 10. Safe Shutdown Sequence
fprintf('=== STEP 8: SAFE SHUTDOWN ===\n');
fprintf('Beginning safe shutdown sequence...\n\n');

% Step 1: Ramp down laser current
fprintf('1. Ramping down laser current...\n');
myLaser.setLaserCurrent(0);

currentSetpoint = myLaser.getLaserCurrent();
fprintf('   Current set to %.2f mA\n', currentSetpoint);

% Step 2: Disable laser output
fprintf('2. Disabling laser output...\n');
myLaser.disableLaser();

% Verify laser is disabled
if ~myLaser.isLaserEnabled()
    fprintf('   Laser output DISABLED\n');
else
    fprintf('   Warning: Laser may still be enabled\n');
end

% Step 3: Disable TEC
fprintf('3. Disabling TEC...\n');
myLaser.disableTEC();

% Verify TEC is disabled
if ~myLaser.isTECEnabled()
    fprintf('   TEC DISABLED\n');
else
    fprintf('   Warning: TEC may still be enabled\n');
end

% Step 4: Final temperature reading
finalTemp = myLaser.getTemperature();
fprintf('4. Final temperature: %.2f°C\n\n', finalTemp);

%% 11. Final Error Check
fprintf('=== FINAL ERROR CHECK ===\n');
errorCode = myLaser.getError();
if errorCode == 0
    fprintf('No device errors\n');
else
    errorMsg = myLaser.getErrorString();
    fprintf('Device error: E-%d: %s\n', errorCode, errorMsg);
end

%% 12. Close Connection
myLaser.delete;
fprintf('\n==========================================================\n');
fprintf('   LASER STARTUP PROCEDURE COMPLETED SUCCESSFULLY\n');
fprintf('==========================================================\n');
fprintf('Connection closed.\n\n');

fprintf('Summary:\n');
fprintf('  - TEC stabilized at %.2f°C (target: %.2f°C)\n', finalTemp, TEC_TARGET_TEMP);
fprintf('  - Laser ramped to %.2f mA (target: %.2f mA)\n', targetCurrent, LASER_TARGET_CURRENT);
fprintf('  - All systems safely shut down\n');
fprintf('\n');
