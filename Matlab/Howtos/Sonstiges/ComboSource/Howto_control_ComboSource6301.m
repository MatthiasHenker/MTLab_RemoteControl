%% Howto: Control Arroyo ComboSource 6301 Laser Controller
% This script demonstrates how to control the Arroyo ComboSource 6301 laser
% controller using the ComboSource6301 class
%
% HTW Dresden - Faculty of Electrical Engineering
% Date: 2026-02-27
%
% NOTE: The Arroyo 6301 uses custom Arroyo commands, NOT standard SCPI!
% Verified Configuration: COM1, 9600 baud, CR terminator

%% 1. Connect to Device
% Create ComboSource6301 object (automatically connects)
% Use 'none' for silent mode, 'few' for minimal messages, 'all' for debug
myLaser = ComboSource6301('Arroyo-6301', 'visa-serial', 'none');

fprintf('\nConnected to Arroyo ComboSource 6301\n');

%% 2. Get Device Identification
idString = myLaser.getID();
fprintf('Device ID: %s\n', idString);

version = myLaser.getVersion();
fprintf('Firmware Version: %s\n', version);

serialNum = myLaser.getSerialNumber();
fprintf('Serial Number: %s\n\n', serialNum);

%% 3. Clear any previous errors
myLaser.clear();

errorCode = myLaser.getError();
if errorCode ~= 0
    errorMsg = myLaser.getErrorString();
    fprintf('Previous error cleared: E-%d: %s\n\n', errorCode, errorMsg);
end

%% 4. Configure TEC Temperature Limits (Safety)
disp('--- Configuring TEC Temperature Limits ---');
myLaser.setTECTempLimitLow(15);   % Minimum temperature 15°C
myLaser.setTECTempLimitHigh(35);  % Maximum temperature 35°C

fprintf('Temperature limits set: 15.0°C to 35.0°C\n\n');

%% 5. Set TEC to Temperature Control Mode
disp('--- Setting TEC Mode ---');
myLaser.setTECModeTemperature();  % Set to temperature control mode
pause(0.1);

tecMode = myLaser.getTECMode();
fprintf('TEC Mode: %s\n\n', tecMode);

%% 6. Set Temperature Setpoint
disp('--- Setting Temperature Setpoint ---');
targetTemp = 25.0;  % Target temperature in °C
myLaser.setTemperature(targetTemp);
pause(0.1);

% Read back the setpoint
setpointTemp = myLaser.getTempSetpoint();
fprintf('TEC Temperature Setpoint: %.2f°C\n\n', setpointTemp);

%% 7. Read Current Temperature (Before Enabling TEC)
currentTemp = myLaser.getTemperature();
fprintf('Current Temperature (TEC OFF): %.2f°C\n\n', currentTemp);

%% 8. Enable TEC
disp('--- Enabling TEC ---');
myLaser.enableTEC();
pause(0.1);

% Verify TEC is enabled
tecStatus = myLaser.isTECEnabled();
if tecStatus
    fprintf('✓ TEC is now ENABLED\n\n');
else
    warning('✗ TEC failed to enable\n\n');
end

%% 9. Monitor Temperature for Several Seconds
disp('Monitoring temperature as TEC stabilizes...');
disp('Time(s)  Temp(°C)  Setpoint(°C)  TEC Current(A)  Error(°C)');
disp('-------  --------  ------------  --------------  ---------');

monitorTime = 10;  % Monitor for 10 seconds
for t = 1:monitorTime
    % Read current temperature
    temp = myLaser.getTemperature();
    
    % Read TEC current
    tecCurrent = myLaser.getTECCurrent();
    
    % Calculate temperature error
    tempError = setpointTemp - temp;
    
    fprintf('%4d     %7.2f       %7.2f         %7.4f      %+6.2f\n', ...
        t, temp, setpointTemp, tecCurrent, tempError);
    
    pause(1);
end

%% 10. Final Temperature Reading
disp(' ');
finalTemp = myLaser.getTemperature();
fprintf('Final Temperature (after %d seconds): %.2f°C\n', monitorTime, finalTemp);
fprintf('Temperature change: %.2f°C → %.2f°C (Δ = %.2f°C)\n', ...
    currentTemp, finalTemp, finalTemp - currentTemp);

%% 11. Disable TEC
disp(' ');
disp('--- Disabling TEC ---');
myLaser.disableTEC();
pause(0.1);

% Verify TEC is disabled
tecStatus = myLaser.isTECEnabled();
if ~tecStatus
    fprintf('✓ TEC is now DISABLED\n');
else
    warning('✗ TEC failed to disable\n');
end

%% 12. Check for Device Errors
errorCode = myLaser.getError();
if errorCode == 0
    fprintf('✓ No device errors\n');
else
    errorMsg = myLaser.getErrorString();
    fprintf('Device error: E-%d: %s\n', errorCode, errorMsg);
end

%% 13. Close Connection
delete(myLaser);
disp(' ');
disp('Connection closed');

%% Additional Examples and Notes

%% Example: Laser Control Commands
% % Enable laser output (CAUTION: Ensure enclosure is closed!)
% myLaser.enableLaser();
% 
% % Set laser current (in milliamps)
% myLaser.setLaserCurrent(100.0);
% 
% % Read laser current setpoint
% laserCurrent = myLaser.getLaserCurrent();
% fprintf('Laser Current: %.3f mA\n', laserCurrent);
% 
% % Set laser current limit (safety)
% myLaser.setLaserCurrentLimit(150.0);
% 
% % Check if interlock is closed
% interlockClosed = myLaser.isInterlockClosed();
% if interlockClosed
%     fprintf('✓ Enclosure closed (safe)\n');
% else
%     warning('✗ Enclosure open - laser cannot be enabled!');
% end
% 
% % Disable laser
% myLaser.disableLaser();

%% Example: TEC Current Control Mode
% % Switch to TEC current control mode
% myLaser.setTECModeCurrent();
% 
% % Set TEC current limit (in amperes)
% myLaser.setTECCurrentLimit(1.5);
% 
% % Enable TEC
% myLaser.enableTEC();

%% Example: Reading TEC PID Parameters
% [status, p, i, d] = myLaser.getTECPID();
% fprintf('TEC PID: P=%.4f, I=%.4f, D=%.4f\n', p, i, d);

%% Example: Error Handling with Try-Catch
% try
%     myLaser = ComboSource6301('Arroyo-6301', 'visa-serial', 'none');
%     
%     % Your code here
%     myLaser.enableTEC();
%     
%     % Always disable TEC when done
%     myLaser.disableTEC();
%     delete(myLaser);
% catch ME
%     fprintf('Error: %s\n', ME.message);
%     if exist('myLaser', 'var')
%         try
%             myLaser.disableTEC();
%             delete(myLaser);
%         catch
%         end
%     end
% end

%% Important Notes:
% 1. The Arroyo 6301 does NOT use standard SCPI commands
% 2. Use ComboSource6301 class methods for easy control
% 3. Always set temperature limits before enabling TEC
% 4. Check interlock status before enabling laser
% 5. TEC current is measured in Amperes, temperature in Celsius
% 6. See ComboSource6301.html for complete method reference
