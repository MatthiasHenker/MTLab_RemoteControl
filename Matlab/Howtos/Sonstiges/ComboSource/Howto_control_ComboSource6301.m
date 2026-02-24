%% Howto: Control Arroyo ComboSource 6301 Laser Controller
% This script demonstrates how to control the Arroyo ComboSource 6301 laser
% controller using direct serial communication with Arroyo commands
%
% HTW Dresden - Faculty of Electrical Engineering
% Date: 2026-02-24
%
% NOTE: The Arroyo 6301 uses custom Arroyo commands, NOT standard SCPI!
% Verified Configuration: COM1, 9600 baud, CR terminator

%% 1. Connect to Device
% Create serial connection to Arroyo 6301
s = serialport('COM1', 9600);
configureTerminator(s, 'CR');  % Arroyo uses CR (0x0D) only
s.Timeout = 2;

fprintf('Connected to Arroyo ComboSource 6301 on COM1\n');

%% 2. Get Device Identification
writeline(s, '*IDN?');
idString = readline(s);
fprintf('Device ID: %s\n', idString);

writeline(s, 'VER?');
version = readline(s);
fprintf('Firmware Version: %s\n', version);

writeline(s, 'SN?');
serialNum = readline(s);
fprintf('Serial Number: %s\n\n', serialNum);

%% 3. Clear any previous errors
writeline(s, 'ERR?');
errorCode = str2double(readline(s));
if errorCode ~= 0
    writeline(s, 'ERRSTR?');
    errorMsg = readline(s);
    fprintf('Clearing previous error: E-%d: %s\n', errorCode, errorMsg);
end

%% 4. Configure TEC Temperature Limits (Safety)
disp('--- Configuring TEC Temperature Limits ---');
writeline(s, 'TEC:LIM:TLO 15');   % Minimum temperature 15°C
writeline(s, 'TEC:LIM:THI 35');   % Maximum temperature 35°C

writeline(s, 'TEC:LIM:TLO?');
tempLimitLow = str2double(readline(s));
writeline(s, 'TEC:LIM:THI?');
tempLimitHigh = str2double(readline(s));
fprintf('Temperature limits set: %.1f°C to %.1f°C\n\n', tempLimitLow, tempLimitHigh);

%% 5. Set TEC to Temperature Control Mode
disp('--- Setting TEC Mode ---');
writeline(s, 'TEC:MODE:T');  % Set to temperature control mode
pause(0.1);

writeline(s, 'TEC:MODE?');
tecMode = readline(s);
fprintf('TEC Mode: %s\n\n', tecMode);

%% 6. Set Temperature Setpoint
disp('--- Setting Temperature Setpoint ---');
targetTemp = 25.0;  % Target temperature in °C
writeline(s, sprintf('TEC:T %.2f', targetTemp));
pause(0.1);

% Read back the setpoint
writeline(s, 'TEC:SET:T?');
setpointTemp = str2double(readline(s));
fprintf('TEC Temperature Setpoint: %.2f°C\n\n', setpointTemp);

%% 7. Read Current Temperature (Before Enabling TEC)
writeline(s, 'TEC:T?');
currentTemp = str2double(readline(s));
fprintf('Current Temperature (TEC OFF): %.2f°C\n\n', currentTemp);

%% 8. Enable TEC
disp('--- Enabling TEC ---');
writeline(s, 'TEC:OUT 1');
pause(0.1);

% Verify TEC is enabled
writeline(s, 'TEC:OUT?');
tecStatus = str2double(readline(s));
if tecStatus == 1
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
    writeline(s, 'TEC:T?');
    temp = str2double(readline(s));
    
    % Read TEC current
    writeline(s, 'TEC:ITE?');
    tecCurrent = str2double(readline(s));
    
    % Calculate temperature error
    tempError = setpointTemp - temp;
    
    fprintf('%4d     %7.2f       %7.2f         %7.4f      %+6.2f\n', ...
        t, temp, setpointTemp, tecCurrent, tempError);
    
    pause(1);
end

%% 10. Final Temperature Reading
disp(' ');
writeline(s, 'TEC:T?');
finalTemp = str2double(readline(s));
fprintf('Final Temperature (after %d seconds): %.2f°C\n', monitorTime, finalTemp);
fprintf('Temperature change: %.2f°C → %.2f°C (Δ = %.2f°C)\n', ...
    currentTemp, finalTemp, finalTemp - currentTemp);

%% 11. Disable TEC
disp(' ');
disp('--- Disabling TEC ---');
writeline(s, 'TEC:OUT 0');
pause(0.1);

% Verify TEC is disabled
writeline(s, 'TEC:OUT?');
tecStatus = str2double(readline(s));
if tecStatus == 0
    fprintf('✓ TEC is now DISABLED\n');
else
    warning('✗ TEC failed to disable\n');
end

%% 12. Check for Device Errors
writeline(s, 'ERR?');
errorCode = str2double(readline(s));
if errorCode == 0
    fprintf('✓ No device errors\n');
else
    writeline(s, 'ERRSTR?');
    errorMsg = readline(s);
    fprintf('Device error: E-%d: %s\n', errorCode, errorMsg);
end

%% 13. Close Connection
clear s;
disp(' ');
disp('Connection closed');

%% Additional Examples and Notes

%% Example: Laser Control Commands
% % Enable laser output
% writeline(s, 'LAS:OUT 1');
% 
% % Set laser current (in milliamps)
% writeline(s, 'LAS:LDI 100.0');
% 
% % Read laser current
% writeline(s, 'LAS:LDI?');
% laserCurrent = str2double(readline(s));
% 
% % Set laser current limit
% writeline(s, 'LAS:LIM:LDI 150.0');
% 
% % Disable laser
% writeline(s, 'LAS:OUT 0');

%% Example: TEC Current Control Mode
% % Switch to TEC current control mode
% writeline(s, 'TEC:MODE:ITE');
% 
% % Set TEC current setpoint (in amperes)
% writeline(s, 'TEC:ITE 0.5');
% 
% % Enable TEC
% writeline(s, 'TEC:OUT 1');

%% Example: Reading TEC PID Parameters
% writeline(s, 'TEC:PID?');
% pidValues = readline(s);
% fprintf('TEC PID: %s\n', pidValues);

%% Example: Error Handling with Try-Catch
% try
%     s = serialport('COM1', 9600);
%     configureTerminator(s, 'CR');
%     
%     % Your code here
%     writeline(s, 'TEC:OUT 1');
%     
%     % Always disable TEC when done
%     writeline(s, 'TEC:OUT 0');
%     clear s;
% catch ME
%     fprintf('Error: %s\n', ME.message);
%     if exist('s', 'var')
%         try
%             writeline(s, 'TEC:OUT 0');
%             clear s;
%         catch
%         end
%     end
% end

%% Important Notes:
% 1. The Arroyo 6301 does NOT use standard SCPI commands
% 2. Use Arroyo-specific commands: TEC:OUT, LAS:LDI, etc.
% 3. Always set temperature limits before enabling TEC
% 4. TEC current is measured in Amperes, temperature in Celsius
% 5. See ARROYO_IMPLEMENTATION_GUIDE.md for complete command reference
