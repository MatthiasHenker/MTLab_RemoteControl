%% Howto control the rotary platform using RotaryPlatformDriver class
% 2026-01-18
% HTW Dresden - Prof. Florian Römer
%
% Requirements: RotaryPlatformDriver, VisaIF, HTWD-DT-2025 connected to COM13

%% Clean workspace

clear;
close all;
clc;

%% Connect and get device ID

% Create object and connect to COM13 (115200 baud, 8N1, CR/LF)
% Change 'COM13' to 'COM7' if needed
myPlatform = RotaryPlatformDriver('COM7');

% Get and display device ID
deviceID = myPlatform.getID();
disp(['Connected to device: ' deviceID]);

%% Enable motor for remote control

% Enable local motor (unlocks stepper motor for movement)
% This can be done remotely instead of pressing the green button
myPlatform.setMotorEnableLocal(true);
disp('Motor unlocked (local enable set remotely)');

% Enable remote motor control (required for motor to work)
myPlatform.setMotorEnableRemote(true);
disp('Motor enabled for remote control');

% Check motor status
motorEnabled = myPlatform.isMotorEnabled();
localEnabled = myPlatform.isMotorEnableLocal();
remoteEnabled = myPlatform.isMotorEnableRemote();
voltageLockout = myPlatform.isMotorVoltLockout();

fprintf('Motor status:\n');
fprintf('  Motor enabled (overall): %d\n', motorEnabled);
fprintf('  Local enable (unlocked): %d\n', localEnabled);
fprintf('  Remote enable:           %d\n', remoteEnabled);
fprintf('  Voltage lockout:         %d\n', voltageLockout);

if ~motorEnabled
    myPlatform.delete();
    error('Motor is not enabled! Check voltage supply or device status.');
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

%% Disable motor (lock and disable)

% Disable remote motor control
myPlatform.setMotorEnableRemote(false);
disp('Motor disabled (remote control locked)');

% Lock motor (prevents manual movement)
myPlatform.setMotorEnableLocal(false);
disp('Motor locked (manual movement prevented)');

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
