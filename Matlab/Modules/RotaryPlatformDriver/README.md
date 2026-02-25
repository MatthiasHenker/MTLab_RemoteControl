# RotaryPlatformDriver - MATLAB Control Interface

Control interface for HTWD-DT-2025 rotary platform via **VisaIF** serial communication.

## Overview

The **RotaryPlatformDriver** class provides a comprehensive MATLAB interface for controlling a custom rotary platform. It uses the **VisaIF** class for serial communication and implements all 19 SCPI commands from Firmware v1.1.0 specification for position control, safety limits, and motor diagnostics.

**✓ 100% SCPI Compliant** with HTWD-DT-2025 Firmware v1.1.0

## Quick Start

```matlab
% Connect to platform (uses default COM7 from config)
platform = RotaryPlatformDriver();

% Or specify COM port
platform = RotaryPlatformDriver('COM13');

% Enable motor (green button must be physically pressed!)
platform.setMotorEnableRemote(true);

% Move to 90 degrees
platform.setAngle(90);

% Wait for movement to complete
while ~platform.isReached()
    pause(0.5);
end
disp('Position reached!');

% Get current position
pos = platform.getPosition();
fprintf('Current position: %.1f degrees\n', pos);

% Close connection
platform.delete();
```

## Requirements

- **MATLAB R2019b** or later
- **Instrument Control Toolbox**
- **VisaIF class** (HTW Dresden internal)
- Device must be configured in `VisaIF_HTW_Labs.csv`
- HTWD-DT-2025 hardware with Firmware v1.1.0 or compatible

## File Structure

```
RotaryPlatformDriver/
├── @RotaryPlatformDriver/
│   ├── RotaryPlatformDriver.m        # Main class file
│   ├── RotaryPlatformDriver.html     # HTML documentation
│   ├── checkParams.m                 # Parameter validation
│   └── listAvailablePackages.m      # Package information
├── RotaryPlatformDriver_History.txt  # Version history and changelog
├── MIGRATION_TO_VISAIF.md           # Migration guide from v2.0 to v2.1
└── README.md                         # This file
```

## Installation

1. **Add to MATLAB Path**
   ```matlab
   addpath('C:\Path\To\MTLab_RemoteControl\Matlab\Modules\RotaryPlatformDriver');
   addpath('C:\Path\To\MTLab_RemoteControl\Matlab\Modules\VisaIF');
   savepath;
   ```

2. **Connect Hardware**
   - Connect rotary platform via USB or RS-232
   - Note the COM port (e.g., COM13)
   - Verify in Device Manager or MATLAB:
     ```matlab
     serialportlist("available")
     ```

3. **Test Connection**
   ```matlab
   platform = RotaryPlatformDriver('COM13');
   id = platform.getID();
   disp(id);
   platform.delete();
   ```

## Documentation

### Open Full Documentation
```matlab
RotaryPlatformDriver.doc
```

### Main Features

#### **Position Control**
- `setAngle(angle)` - Set target angle (-360 to 360 degrees)
- `getTargetAngle()` - Query commanded target angle
- `getPosition()` - Query actual current position
- `isReached()` - Check if target position is reached and held

#### **Safety Limits**
- `setUpperLimit(angle)` - Set upper angle safety limit
- `getUpperLimit()` - Query upper angle limit
- `setLowerLimit(angle)` - Set lower angle safety limit  
- `getLowerLimit()` - Query lower angle limit

#### **Local Control**
- `lockLocal()` - Disable physical buttons on device
- `unlockLocal()` - Enable physical buttons on device
- `isLocked()` - Query if local control is locked

#### **Motor Status & Diagnostics**
- `isMotorEnabled()` - Check if motor is currently active (AND combination of all conditions)
- `isMotorEnableLocal()` - Check if green enable button is pressed
- `isMotorEnableRemote()` - Query remote motor enable status
- `setMotorEnableRemote(enable)` - Set remote motor enable (locks motor when false)
- `isMotorVoltLockout()` - Check if under-voltage lockout is active

#### **Device Information**
- `getID()` - Get device identification string
- `getError()` - Get error from error queue

## Method Summary

| Method | Description |
|--------|-------------|
| `RotaryPlatformDriver(comPort)` | Create connection to platform on specified COM port |
| `setAngle(angle)` | Set target angle in degrees (-360 to 360) |
| `getPosition()` | Query actual current position in degrees |
| `isReached()` | Check if target position is reached and held |
| `setUpperLimit(angle)` | Set upper angle safety limit in degrees |
| `getUpperLimit()` | Query upper angle safety limit |
| `setLowerLimit(angle)` | Set lower angle safety limit in degrees |
| `getLowerLimit()` | Query lower angle safety limit |
| `lockLocal()` | Disable physical buttons on device |
| `unlockLocal()` | Enable physical buttons on device |
| `isLocked()` | Query if local control is locked |
| `isMotorEnabled()` | Query if motor is currently active |
| `isMotorEnableLocal()` | Query if green enable button is pressed |
| `isMotorEnableRemote()` | Query remote motor enable status |
| `setMotorEnableRemote(enable)` | Set remote motor enable (true/false) |
| `isMotorVoltLockout()` | Query if under-voltage lockout is active |
| `getID()` | Get device identification string |
| `getError()` | Get error from error queue |

## Usage Examples

### Basic Movement
```matlab
platform = RotaryPlatformDriver('COM13');

% Move to specific angles
platform.setAngle(0);
pause(2);
platform.setAngle(45);
pause(2);
platform.setAngle(90);
pause(2);

% Check position
pos = platform.getPosition();
fprintf('Final position: %.1f°\n', pos);

platform.delete();
```

### Configure Safety Limits
```matlab
platform = RotaryPlatformDriver('COM7');

% Query current limits
upper = platform.getUpperLimit();
lower = platform.getLowerLimit();
fprintf('Current limits: %.1f to %.1f degrees\n', lower, upper);

% Set new limits
platform.setUpperLimit(180);
platform.setLowerLimit(-180);

platform.delete();
```

### Lock Local Control During Automation
```matlab
platform = RotaryPlatformDriver('COM13');

% Disable physical buttons during automated measurement
platform.lockLocal();

% Perform measurements at different angles
for angle = 0:45:180
    platform.setAngle(angle);
    pause(1);
    while ~platform.isReached()
        pause(0.1);
    end
    % ... perform measurement ...
    fprintf('Measured at %.1f degrees\n', angle);
end

% Re-enable physical buttons
platform.unlockLocal();
platform.delete();
```

### Check Motor Status and Diagnose Issues
```matlab
platform = RotaryPlatformDriver('COM13');

% Check overall motor status
if platform.isMotorEnabled()
    disp('Motor is powered and active');
else
    % Diagnose why motor is not active
    fprintf('Motor is NOT active. Checking conditions:\n');
    
    localBtn = platform.isMotorEnableLocal();
    fprintf('  Local button pressed: %d\n', localBtn);
    
    remoteEnable = platform.isMotorEnableRemote();
    fprintf('  Remote enable: %d\n', remoteEnable);
    
    voltLockout = platform.isMotorVoltLockout();
    fprintf('  Voltage lockout: %d\n', voltLockout);
    
    if voltLockout
        warning('Under-voltage detected! Check power supply.');
    end
    if ~localBtn
        warning('Green enable button must be pressed!');
    end
    if ~remoteEnable
        warning('Remote lockout active! Use setMotorEnableRemote(true)');
    end
end

platform.delete();
```

### Remote Motor Lockout (Safety Feature)
```matlab
platform = RotaryPlatformDriver('COM13');

% Disable motor from remote (safety feature)
% LCD shows lockout message, green button LED turns off
platform.setMotorEnableRemote(false);
fprintf('Motor locked from remote\n');

% Try to move (will not work while locked)
platform.setAngle(90);
pause(1);

% Check status
if ~platform.isMotorEnabled()
    disp('Motor did not move (as expected - locked)');
end

% Re-enable motor
platform.setMotorEnableRemote(true);
fprintf('Motor unlocked\n');

platform.delete();
```

### Angular Sweep Measurement
```matlab
platform = RotaryPlatformDriver('COM13');

% Configure limits
platform.setLowerLimit(-180);
platform.setUpperLimit(180);

% Perform angular sweep
angles = -180:10:180;
results = zeros(size(angles));

platform.lockLocal();  % Prevent manual interference

for i = 1:length(angles)
    platform.setAngle(angles(i));
    
    % Wait for position reached
    timeout = 10;  % seconds
    tic;
    while ~platform.isReached() && toc < timeout
        pause(0.1);
    end
    
    if platform.isReached()
        % Perform measurement
        results(i) = rand();  % Replace with actual measurement
        fprintf('Angle: %6.1f° | Measurement: %.3f\n', angles(i), results(i));
    else
        warning('Timeout at angle %.1f°', angles(i));
    end
end

platform.unlockLocal();

% Plot results
figure;
plot(angles, results, '-o');
xlabel('Angle (degrees)');
ylabel('Measurement');
title('Angular Sweep Results');
grid on;

platform.delete();
```

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `RotaryPlatformDriverVersion` | String (constant) | Version number (e.g., '2.0.0') |
| `RotaryPlatformDriverDate` | String (constant) | Release date (e.g., '2026-01-19') |

## Motor Activation Logic

The motor is active when **ALL** of the following conditions are true:
- `isMotorEnableLocal() == true` - Green button is pressed
- `isMotorEnableRemote() == true` - No remote lockout active
- `isMotorVoltLockout() == false` - Power supply is OK

The method `isMotorEnabled()` returns the AND combination of all three conditions.

## Communication Settings

- **Baud Rate:** 115200
- **Data Bits:** 8
- **Parity:** None
- **Stop Bits:** 1
- **Flow Control:** None
- **Terminator:** CR/LF
- **Note:** Device echoes every command sent to it

## Troubleshooting

### Cannot connect to device
```matlab
% List available COM ports
serialportlist("available")

% Try different COM port
platform = RotaryPlatformDriver('COM7');
```

### Motor not moving
```matlab
% Check motor status
if ~platform.isMotorEnabled()
    % Check individual conditions
    if ~platform.isMotorEnableLocal()
        disp('Press green enable button on device');
    end
    if ~platform.isMotorEnableRemote()
        platform.setMotorEnableRemote(true);
    end
    if platform.isMotorVoltLockout()
        disp('Check power supply voltage');
    end
end
```

### Position not reached
```matlab
% Check safety limits
upper = platform.getUpperLimit();
lower = platform.getLowerLimit();
fprintf('Limits: %.1f to %.1f degrees\n', lower, upper);

% Verify target is within limits
target = platform.getTargetAngle();
if target > upper || target < lower
    warning('Target outside safety limits!');
end
```

## Version History

See [RotaryPlatformDriver_History.txt](RotaryPlatformDriver_History.txt) for detailed version history and changelog.

**Current Version:** 2.0.0 (2026-01-19)
- Added motor diagnostic methods
- Enhanced status checking
- Improved remote lockout control

## System Requirements

- MATLAB R2019b or later (for `serialport` support)
- HTWD-DT-2025 rotary platform hardware
- Serial connection (USB-to-Serial or direct COM port)

## Support

For issues, questions, or contributions:
- HTW Dresden - Faculty of Electrical Engineering
- Repository: MTLab_RemoteControl

## Related Classes

- **FGen** - Function generator control
- **Scope** - Oscilloscope control
- **ComboSource6301** - Laser controller interface
- **VisaIF** - Base class for VISA instrument control

## License

Copyright © 2026 HTW Dresden

---

**Always call `platform.delete()` or `clear platform` to properly close the serial connection when finished.**
