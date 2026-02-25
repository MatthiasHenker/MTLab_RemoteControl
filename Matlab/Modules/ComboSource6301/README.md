# ComboSource6301 - Arroyo Instruments Laser Controller Driver

## Overview
The **ComboSource6301** class provides complete control of the **Arroyo Instruments ComboSource 6301** laser controller via RS-232/USB interface. This MATLAB class inherits from VisaIF and implements the Arroyo Computer Interfacing Manual command set.

### Features
- **Laser diode current control** (constant current mode)
- **TEC (Thermoelectric Cooler) temperature control** with PID tuning
- **Temperature monitoring and safety limits**
- **Laser enable/disable control with interlock checking**
- **Comprehensive status monitoring** (condition registers)
- **Error handling and diagnostics**
- **Safety features** (over-temperature detection, interlock status)

⚠️ **IMPORTANT:** The Arroyo 6301 uses **custom Arroyo commands**, NOT standard SCPI!

### ✅ Fully Validated
This driver has been **line-by-line validated** against the Arroyo Computer Interfacing Manual and is production-ready for lab use.

## Quick Start

```matlab
% Connect to device (COM1, 9600 baud, CR terminator)
myLaser = ComboSource6301('Arroyo-6301');

% Get device info
fprintf('Device: %s\n', myLaser.getID());
fprintf('Version: %s\n', myLaser.getVersion());

% Configure and enable TEC
myLaser.setTECModeTemperature();    % Set temperature control mode
myLaser.setTemperature(25);         % 25°C target
myLaser.enableTEC();                % Enable TEC

% Wait for temperature stabilization
pause(30);

% Configure laser current
myLaser.setLaserCurrentLimit(150);  % Set safety limit to 150 mA
myLaser.setLaserCurrent(100);       % Set current to 100 mA
myLaser.enableLaser();              % Enable laser output

% Monitor status
fprintf('Temperature: %.2f °C\n', myLaser.getTemperature());
fprintf('TEC Current: %.3f A\n', myLaser.getTECCurrent());
fprintf('Laser Current: %.2f mA\n', myLaser.getLaserCurrent());

% Check safety
if myLaser.isInterlockClosed()
    fprintf('Interlock: SAFE (closed)\n');
else
    warning('Interlock is OPEN!');
end

if myLaser.isOverTemp()
    warning('Over-temperature detected!');
end

% Safe shutdown
myLaser.disableLaser();
myLaser.disableTEC();
myLaser.delete;
```

## Files

```
ComboSource6301/
├── @ComboSource6301/
│   ├── ComboSource6301.m              - Main class file (v2.0.0)
│   └── ComboSource6301.html           - HTML documentation
├── ComboSource6301_History.txt        - Version history
├── Configuration_Guide.txt            - Arroyo command reference
└── README.md                          - This file
```

## Installation

1. **Install Prerequisites:**
   - MATLAB R2019b or newer (for `serialport` support)
   - Instrument Control Toolbox
   - VisaIF class version 3.0.0+

2. **Add to MATLAB Path:**
   ```matlab
   addpath('Y:\MTLab_RemoteControl\Matlab\Modules\ComboSource6301');
   addpath('Y:\MTLab_RemoteControl\Matlab\Modules\VisaIF');
   savepath;
   ```

3. **Configure Device:**
   Add device entry to `VisaIF_HTW_Labs.csv`:
   ```
   Arroyo-6301 ;; ArroyoInstruments;; ComboSource6301;; Other ;; visa-serial;; ASRL1::9600.8.1.none.none.CR.CR;; 1e4 ;; 1e4
   ```
   
   **Key Settings:**
   - COM Port: COM1 (ASRL1)
   - Baud Rate: 9600
   - Terminator: **CR only** (0x0D, not CR/LF!)
   - Data: 8 bits, No parity, 1 stop bit

4. **Verify Installation:**
   ```matlab
   myLaser = ComboSource6301('Arroyo-6301');
   disp(myLaser.getID());
   myLaser.delete;
   ```

## Documentation

- **Class Documentation:** Type `ComboSource6301.doc` in MATLAB to open full HTML documentation
- **Configuration Guide:** See `Configuration_Guide.txt` for Arroyo command syntax reference
- **Version History:** See `ComboSource6301_History.txt`
- **Example Scripts:** See `Howtos/Sonstiges/ComboSource/` folder

## Main Features

### Device Information (IEEE-488.2 & Arroyo Commands)
- `getID()` - Get device identification (*IDN?)
- `getVersion()` - Get firmware version (VER?)
- `getSerialNumber()` - Get serial number (SN?)
- `getError()` - Get error code (ERR?)
- `getErrorString()` - Get error description (ERRSTR?)
- `clear()` - Clear device status (*CLS)
- `setLocalMode()` - Return to local front panel control (LOCAL)

### Laser Current Control
- `setLaserCurrent(mA)` - Set laser drive current (LAS:LDI)
- `getLaserCurrent()` - Get current setpoint (LAS:LDI?)
- `setLaserCurrentLimit(mA)` - Set current limit (LAS:LIM:LDI)
- `getLaserCurrentLimit()` - Get current limit (LAS:LIM:LDI?)

### Laser Output Control (Arroyo LAS: Tree)
- `enableLaser()` - Enable laser output (LAS:OUT 1)
- `disableLaser()` - Disable laser output (LAS:OUT 0)
- `isLaserEnabled()` - Check laser status (LAS:OUT?)
- `getLaserCondition()` - Get laser condition register (LAS:COND?)

### TEC Temperature Control (Arroyo TEC: Tree)
- `setTemperature(°C)` - Set TEC temperature setpoint (TEC:T)
- `getTemperature()` - Get measured temperature (TEC:T?)
- `getTempSetpoint()` - Get temperature setpoint (TEC:SET:T?)
- `getTECCurrent()` - Get TEC current in amperes (TEC:ITE?)
- `setTECCurrentLimit(A)` - Set TEC current limit (TEC:LIM:ITE)
- `getTECCurrentLimit()` - Get TEC current limit (TEC:LIM:ITE?)

### TEC Output Control
- `enableTEC()` - Enable TEC (TEC:OUT 1)
- `disableTEC()` - Disable TEC (TEC:OUT 0)
- `isTECEnabled()` - Check TEC status (TEC:OUT?)

### TEC Mode Control
- `setTECModeTemperature()` - Set temperature control mode (TEC:MODE:T)
- `setTECModeCurrent()` - Set current control mode (TEC:MODE:ITE)
- `getTECMode()` - Get current TEC mode (TEC:MODE?)

### TEC PID Control
- `setTECPID(p, i, d)` - Set PID parameters (TEC:PID)
- `getTECPID()` - Get PID parameters (TEC:PID?)

### Temperature Limits (Arroyo Commands)
- `setTECTempLimitHigh(°C)` - Set TEC high temp limit (TEC:LIM:THI)
- `setTECTempLimitLow(°C)` - Set TEC low temp limit (TEC:LIM:TLO)
- `setLaserTempLimitHigh(°C)` - Set laser high temp limit (LAS:LIM:THI)

### Status and Safety (Arroyo Commands)
- `getStatus()` - Get device status byte (*STB?)
- `getLaserCondition()` - Get laser condition register (LAS:COND?)
- `getTECCondition()` - Get TEC condition register (TEC:COND?)
- `getInterlockState()` - Get interlock digital input state (DIO:IN? 0)
- `isInterlockClosed()` - Check if interlock is safe (DIO:IN? 0)
- `isOverTemp()` - Check over-temperature from TEC:COND? (bits 3 & 12)

## Complete Method Summary

**Total Implemented:** 35+ methods

| Category | Methods |
|----------|---------|
| **Device Info** | getID, getVersion, getSerialNumber, getError, getErrorString, clear, setLocalMode |
| **Laser Current** | setLaserCurrent, getLaserCurrent, setLaserCurrentLimit, getLaserCurrentLimit |
| **Laser Output** | enableLaser, disableLaser, isLaserEnabled, getLaserCondition |
| **TEC Temperature** | setTemperature, getTemperature, getTempSetpoint, getTECCurrent, setTECCurrentLimit, getTECCurrentLimit |
| **TEC Output** | enableTEC, disableTEC, isTECEnabled |
| **TEC Mode** | setTECModeTemperature, setTECModeCurrent, getTECMode |
| **TEC PID** | setTECPID, getTECPID |
| **Temperature Limits** | setTECTempLimitHigh, setTECTempLimitLow, setLaserTempLimitHigh |
| **Status & Safety** | getStatus, getTECCondition, getInterlockState, isInterlockClosed, isOverTemp |

### Command Tree Compliance

✅ **IEEE-488.2:** `*IDN?`, `*CLS`, `*STB?`, `VER?`, `SN?`  
✅ **LAS: Tree:** `LAS:LDI`, `LAS:LIM:LDI`, `LAS:OUT`, `LAS:COND`, `LAS:LIM:THI`  
✅ **TEC: Tree:** `TEC:T`, `TEC:SET:T`, `TEC:ITE`, `TEC:LIM:ITE`, `TEC:OUT`, `TEC:MODE`, `TEC:PID`, `TEC:LIM:THI/TLO`, `TEC:COND`  
✅ **DIO: Tree:** `DIO:IN? 0` (interlock)  
✅ **Error Handling:** `ERR?`, `ERRSTR?`, `LOCAL`

## Usage Examples

### Basic TEC Temperature Control
```matlab
% Connect
myLaser = ComboSource6301('Arroyo-6301');

% Set temperature limits (safety)
myLaser.setTECTempLimitLow(15);   % Min 15°C
myLaser.setTECTempLimitHigh(35);  % Max 35°C

% Set target temperature
myLaser.setTemperature(20);       % 20°C target

% Enable TEC
myLaser.enableTEC();

% Wait for stabilization
pause(30);

% Monitor
fprintf('Temp: %.2f °C\n', myLaser.getTemperature());
fprintf('TEC Current: %.3f A\n', myLaser.getTECCurrent());

% Disable
myLaser.disableTEC();
myLaser.delete;
```

### Basic Laser Current Control
```matlab
% Connect
myLaser = ComboSource6301('Arroyo-6301');

% Set current limit (safety)
myLaser.setLaserCurrentLimit(150);  % 150 mA max

% Set operating current
myLaser.setLaserCurrent(27.5);      % 27.5 mA

% Enable laser
myLaser.enableLaser();

% Check status
if myLaser.isLaserEnabled()
    fprintf('Laser ON at %.2f mA\n', myLaser.getLaserCurrent());
end

% Disable
myLaser.disableLaser();
myLaser.delete;
```

### Complete Startup with Safety Checks
```matlab
% Connect
myLaser = ComboSource6301('Arroyo-6301');

% Check interlock BEFORE any operations
if ~myLaser.isInterlockClosed()
    error('Interlock is OPEN! Close enclosure before continuing.');
end

% 1. Configure TEC with safety limits
myLaser.setTECTempLimitLow(15);      % Min 15°C
myLaser.setTECTempLimitHigh(35);     % Max 35°C
myLaser.setTECModeTemperature();     % Temperature control mode
myLaser.setTemperature(25);          % 25°C target
myLaser.enableTEC();

% 2. Wait for temperature stabilization
fprintf('Waiting for temperature stabilization...\n');
for t = 1:60
    temp = myLaser.getTemperature();
    tecCurrent = myLaser.getTECCurrent();
    fprintf('  t=%d s: %.2f °C (TEC: %.3f A)\n', t, temp, tecCurrent);
    
    % Check for over-temp
    if myLaser.isOverTemp()
        error('Over-temperature detected!');
    end
    
    pause(1);
    
    % Check if stable (change < 0.1°C)
    if t > 30 && abs(temp - 25) < 0.1
        fprintf('Temperature stable.\n');
        break;
    end
end

% 3. Configure laser with safety limits
myLaser.setLaserCurrentLimit(150);   % 150 mA max
myLaser.setLaserTempLimitHigh(40);   % Laser diode max temp
myLaser.setLaserCurrent(0);          % Start at 0

% 4. Enable laser (final interlock check)
if ~myLaser.isInterlockClosed()
    error('Interlock opened during setup!');
end
myLaser.enableLaser();

% 5. Ramp current gradually
fprintf('Ramping laser current...\n');
for current = 0:1:100
    myLaser.setLaserCurrent(current);
    fprintf('  Current: %d mA\n', current);
    pause(0.1);
end

% 6. Monitor operation
fprintf('Monitoring...\n');
for i = 1:10
    temp = myLaser.getTemperature();
    current = myLaser.getLaserCurrent();
    tecCurr = myLaser.getTECCurrent();
    
    fprintf('Temp: %.2f °C | Laser: %.2f mA | TEC: %.3f A\n', ...
            temp, current, tecCurr);
    
    % Safety checks
    if myLaser.isOverTemp()
        warning('Over-temperature detected!');
        break;
    end
    if ~myLaser.isInterlockClosed()
        warning('Interlock opened!');
        break;
    end
    
    pause(1);
end

% 7. Safe shutdown
fprintf('Shutting down...\n');
myLaser.setLaserCurrent(0);
pause(1);
myLaser.disableLaser();
myLaser.disableTEC();
myLaser.delete;
```

## Safety Warnings

⚠️ **LASER SAFETY:**
- **Class 3B/4 LASER - Avoid direct or scattered exposure to beam**
- **NEVER look directly into the laser beam or its reflections**
- **Always wear appropriate laser safety goggles (wavelength-specific)**
- **Ensure enclosure is closed before enabling laser**
- **Always disable laser before opening enclosure**
- **Monitor temperature to prevent thermal damage**
- **Use appropriate current limits for your laser diode**

⚠️ **DEVICE-SPECIFIC NOTES:**
- The Arroyo 6301 uses **custom Arroyo commands**, NOT standard SCPI
- Commands like `OUTP ON`, `SOUR:CURR`, `MEAS:CURR?` **DO NOT WORK**
- Use Arroyo commands: `LAS:OUT 1`, `LAS:LDI`, `TEC:T` instead
- Serial settings: **COM1, 9600 baud, CR terminator only** (not CR/LF!)
- The device has a hardware interlock (check with `isInterlockClosed()`)

⚠️ **TEC:COND REGISTER BIT DEFINITIONS:**
- Bit 0 (1): Current limit
- Bit 1 (2): Voltage limit  
- Bit 2 (4): Sensor limit
- **Bit 3 (8): Temperature high limit** ← checked by `isOverTemp()`
- Bit 4 (16): Temperature low limit
- Bit 5 (32): Sensor shorted
- Bit 6 (64): Sensor open
- Bit 7 (128): TEC open circuit
- **Bit 12 (4096): Thermal run-away** ← checked by `isOverTemp()`

## Common Errors

### E-202: Laser output cannot be enabled
- **Cause:** Enclosure interlock open, limit switches not engaged
- **Solution:** Close enclosure completely, check limit switches

### E-508: Parameter out of range
- **Cause:** Value exceeds hardware limits (current, temperature, etc.)
- **Solution:** Check limits before setting values:
  ```matlab
  % Check current limit first
  limit = myLaser.getLaserCurrentLimit();
  % Set current within limit
  myLaser.setLaserCurrent(min(27.5, limit));
  ```

### E-123: Path not found (Command Error)
- **Cause:** Invalid command syntax or using SCPI instead of Arroyo commands
- **Solution:** Use correct Arroyo command syntax from this guide

## Properties

- `ComboSourceVersion` - Class version: '2.0.0' (read-only)
- `ComboSourceDate` - Release date: '2026-02-24' (read-only)
- `ErrorMessages` - Device error queue (read-only)

## Inherited from VisaIF

All VisaIF methods are available:
- `write(command)` - Send Arroyo command
- `query(command)` - Send query and read response
- `read()` - Read from device
- Plus many more (see `VisaIF.doc`)

## Troubleshooting

**Cannot connect to device:**
1. Check COM port (should be COM1)
2. Verify baud rate is 9600
3. Check terminator is CR only (not CR/LF)
4. Verify device power and cable
5. Test with: `serialportlist("available")`

**Laser won't enable (E-202 error):**
1. Check enclosure is completely closed
2. Verify limit switches are engaged
3. Check device display for error messages
4. Verify TEC is enabled and stable

**Parameter errors (E-508):**
1. Read current limits before setting values
2. Ensure temperature is within TEC limits (15-35°C typical)
3. Check current limit before setting laser current
4. Verify values are within hardware capabilities

**Command errors (E-123):**
1. Use Arroyo commands, NOT SCPI
2. Check command syntax in class documentation (`ComboSource6301.doc`)
3. Ensure proper formatting (e.g., `LAS:LDI 100` not `SOUR:CURR 0.1`)
4. Remember: No `SOUR:`, `MEAS:`, or `SYST:` commands exist

**Communication errors:**
1. Verify CR terminator (0x0D only, not CR/LF)
2. Check baud rate is 9600
3. Ensure COM port is correct (usually COM1)
4. Test with: `serialportlist("available")`

## TEC:COND Register Interpretation

The `getTECCondition()` method returns a bitfield. Decode it as:

```matlab
cond = myLaser.getTECCondition();

if bitget(cond, 1), disp('Current limit reached'); end
if bitget(cond, 2), disp('Voltage limit reached'); end
if bitget(cond, 3), disp('Sensor limit'); end
if bitget(cond, 4), disp('Temperature HIGH limit!'); end
if bitget(cond, 5), disp('Temperature LOW limit'); end
if bitget(cond, 6), disp('Sensor shorted'); end
if bitget(cond, 7), disp('Sensor open'); end
if bitget(cond, 8), disp('TEC open circuit'); end
if bitget(cond, 13), disp('THERMAL RUN-AWAY!'); end

% Or use the built-in method:
if myLaser.isOverTemp()
    disp('Over-temperature detected (bits 3 or 12)');
end
```

## Version History

**Version 2.0.0 (2026-02-24)**
- **MAJOR UPDATE:** Complete rewrite for Arroyo manual compliance
- Removed all invalid SCPI commands (SOUR:*, MEAS:*, SYST:* trees)
- Implemented complete IEEE-488.2 command set (*IDN?, *CLS, *STB?, VER?, SN?)
- Implemented complete LAS: command tree (LDI, LIM:LDI, OUT, COND, LIM:THI)
- Implemented complete TEC: command tree (T, SET:T, ITE, LIM:ITE, OUT, MODE, PID, LIM:THI/TLO, COND)
- Added interlock checking via DIO:IN? 0
- Added over-temperature detection (TEC:COND bits 3 & 12)
- Fixed error handling (ERR?, ERRSTR?)
- Added comprehensive safety features
- Line-by-line validated against Arroyo Computer Interfacing Manual
- Production-ready for lab use

**Version 1.0.0 (2026-01-19)**
- Initial release (SCPI-based, non-functional on Arroyo hardware)
- Deprecated: Do not use

## System Requirements

- **Software:**
  - MATLAB R2019b or newer (for `serialport` support)
  - Instrument Control Toolbox
  - VisaIF class version 3.0.0+

- **Hardware:**
  - Arroyo Instruments ComboSource 6301 laser controller
  - RS-232 serial connection (COM1, 9600 baud)
  - Properly configured power supply (check voltage to avoid E-508 errors)

## Support

For questions, bug reports, or feature requests:
- **HTW Dresden**, Faculty of Electrical Engineering
- **Prof. Matthias Henker** (VisaIF framework support)
- **Florian Römer** (ComboSource6301 driver development)

## References

- **Arroyo Computer Interfacing Manual** - Official command reference
- **Class Documentation:** `ComboSource6301.doc` in MATLAB
- **Configuration Guide:** `Configuration_Guide.txt` in this folder
- **Device Manual:** Arroyo Instruments ComboSource 6301 User Manual

## Validation Status

**Implementation Verified**
- All commands validated against official Arroyo Computer Interfacing Manual
- Uses Arroyo custom command set (not SCPI)
- Correct bit indexing for condition registers
- Ready for laboratory use

---

**CRITICAL REMINDER:**
- This device uses **Arroyo custom commands**, NOT SCPI
- Serial: **COM1, 9600 baud, CR terminator only**
- Always check `isInterlockClosed()` before enabling laser
- Always monitor `isOverTemp()` during operation
- See working examples in `Howtos/Sonstiges/ComboSource/`

*Documentation updated: 2026-02-24 | Driver version: 2.0.0*
