%% Howto control the rotary platform using RotaryPlatformDriver class
% 2026-02-25 - Updated to use VisaIF
% HTW Dresden - Florian Römer
%
% Requirements: 
%   - RotaryPlatformDriver class
%   - VisaIF class
%   - HTWD-DT-2025 device configured in VisaIF_HTW_Labs.csv
%   - Device connected to COM port (default: COM7)

%% Clean workspace

clear;
close all;
clc;

%% Connect and get device ID

% Create object using VisaIF
% Options:
%   myPlatform = RotaryPlatformDriver();        % Use default COM7 from config
%   myPlatform = RotaryPlatformDriver('COM13'); % Override to COM13
%   myPlatform = RotaryPlatformDriver('COM5');  % Override to COM5

myPlatform = RotaryPlatformDriver();  % Uses COM7 by default

% Get and display device ID
deviceID = myPlatform.getID();
disp(['Connected to device: ' deviceID]);

%% Enable motor for remote control

% NOTE: The green button MUST be physically pressed on the device
% There is no remote command to simulate the button press
% MOTOR:ENABLELOCal? is query-only (reads button state)

% Enable remote motor control (required for motor to work)
myPlatform.setMotorEnableRemote(true);
disp('Motor enabled for remote control');
disp('IMPORTANT: Press the green button on the device to enable motor!');

% Check motor status
motorEnabled = myPlatform.isMotorEnabled();
localEnabled = myPlatform.isMotorEnableLocal();
remoteEnabled = myPlatform.isMotorEnableRemote();
voltageLockout = myPlatform.isMotorVoltLockout();

fprintf('Motor status:\n');
fprintf('  Motor enabled (overall): %d\n', motorEnabled);
fprintf('  Local enable (button):   %d\n', localEnabled);
fprintf('  Remote enable:           %d\n', remoteEnabled);
fprintf('  Voltage lockout:         %d\n', voltageLockout);

if ~motorEnabled
    myPlatform.delete();
    error('Motor is not enabled! Press the green button and check voltage supply.');
end

%% Move to specific angle

targetAngle = 20; % degrees
disp(['Moving to angle: ' num2str(targetAngle) ' degrees...']);
myPlatform.setAngle(targetAngle);

% Wait for movement to complete
pause(5);
while ~myPlatform.isReached()
    pause(0.5);
end

targetAngle = 0; % degrees
disp(['Moving to angle: ' num2str(targetAngle) ' degrees...']);
myPlatform.setAngle(targetAngle);

% Wait for movement to complete
pause(5);
while ~myPlatform.isReached()
    pause(0.5);
end

% Get and display current angle
currentAngle = myPlatform.getPosition();
disp(['Current angle: ' num2str(currentAngle) ' degrees']);

%% Disable motor (remote lockout)

% Disable remote motor control
myPlatform.setMotorEnableRemote(false);
disp('Motor disabled (remote control locked)');

% Verify motor is disabled
motorEnabled = myPlatform.isMotorEnabled();
remoteEnabled = myPlatform.isMotorEnableRemote();
fprintf('Motor enabled: %d, Remote enabled: %d\n', motorEnabled, remoteEnabled);

%% Check error status

error = myPlatform.getError();
disp(['Error status: ' error]);


%% End
myPlatform.delete();
disp('Done.');
