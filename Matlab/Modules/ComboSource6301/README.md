# ComboSource6301 - Arroyo Instruments Laser Controller

## Overview
The **ComboSource6301** class provides control of the **Arroyo Instruments ComboSource 6301** laser controller via RS-232 serial interface. This MATLAB class inherits from VisaIF and offers control functions for:

- **Laser diode current control** (constant current mode)
- **TEC (Thermoelectric Cooler) temperature control**
- **Temperature monitoring and limits**
- **Laser enable/disable control**
- **Error handling and diagnostics**

⚠️ **IMPORTANT:** The Arroyo 6301 uses **custom Arroyo commands**, NOT standard SCPI!

## Quick Start

```matlab
% Connect to device (COM1, 9600 baud, CR terminator)
myLaser = ComboSource6301('Arroyo-6301');

% Get device info
fprintf('Device: %s\n', myLaser.getID());
fprintf('Version: %s\n', myLaser.getVersion());

% Set TEC temperature
myLaser.setTemperature(20);    % 20°C target
myLaser.enableTEC();            % Enable TEC

% Set laser current
myLaser.setLaserCurrent(27.5);  % 27.5 mA
myLaser.enableLaser();          % Enable laser

% Monitor
fprintf('Temp: %.2f °C\n', myLaser.getTemperature());
fprintf('Current: %.2f mA\n', myLaser.getLaserCurrent());

% Disable and disconnect
myLaser.disableLaser();
myLaser.disableTEC();
myLaser.delete;
```

## Files

```
ComboSource6301/
├── @ComboSource6301/
│   ├── ComboSource6301.m              - Main class file
│   └── ComboSource6301.html           - HTML documentation
├── ComboSource6301_History.txt        - Version history
├── Configuration_Guide.txt            - Arroyo command reference
├── ARROYO_IMPLEMENTATION_GUIDE.md     - Complete method implementations
├── VERIFIED_CONFIGURATION.md          - Verified working commands
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

- **Implementation Guide:** See `ARROYO_IMPLEMENTATION_GUIDE.md` for complete method reference
- **Verified Commands:** See `VERIFIED_CONFIGURATION.md` for tested working commands
- **Configuration:** See `Configuration_Guide.txt` for Arroyo command syntax
- **Example Scripts:** 
  - `Howtos/Sonstiges/ComboSource/Howto_control_ComboSource6301.m`
  - `Howtos/Sonstiges/ComboSource/Howto_laser_startup_with_TEC_and_safety.m`

## Main Features

### Device Information
- `getID()` - Get device identification (*IDN?)
- `getVersion()` - Get firmware version (VER?)
- `getSerialNumber()` - Get serial number (SN?)
- `getError()` - Get error code (ERR?)
- `getErrorString()` - Get error message (ERRSTR?)
- `clear()` - Clear error queue
- `setLocalMode()` - Exit remote mode (SYST:LOC)

### Laser Current Control
- `setLaserCurrent(mA)` - Set laser drive current (LAS:LDI)
- `getLaserCurrent()` - Get current setpoint (LAS:LDI?)
- `setLaserCurrentLimit(mA)` - Set current limit (LAS:LIM:LDI)
- `getLaserCurrentLimit()` - Get current limit (LAS:LIM:LDI?)

### Laser Output Control
- `enableLaser()` - Enable laser output (LAS:OUT 1)
- `disableLaser()` - Disable laser output (LAS:OUT 0)
- `isLaserEnabled()` - Check laser status (LAS:OUT?)

### TEC Temperature Control
- `setTemperature(°C)` - Set TEC temperature target (TEC:T)
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

### Temperature Limits
- `setTECTempLimitHigh(°C)` - Set TEC high temp limit (TEC:LIM:THI)
- `getTECTempLimitHigh()` - Get TEC high temp limit (TEC:LIM:THI?)
- `setTECTempLimitLow(°C)` - Set TEC low temp limit (TEC:LIM:TLO)
- `getTECTempLimitLow()` - Get TEC low temp limit (TEC:LIM:TLO?)
- `setLaserTempLimitHigh(°C)` - Set laser high temp limit (LAS:LIM:THI)
- `getLaserTempLimitHigh()` - Get laser high temp limit (LAS:LIM:THI?)

## Method Summary

**Currently Implemented:** ~20 methods (partial implementation)

| Category | Methods |
|----------|---------|
| **Device Info** | getID, getVersion, getSerialNumber, getError, getErrorString, clear, setLocalMode |
| **Laser Current** | setLaserCurrent, getLaserCurrent, setLaserCurrentLimit, getLaserCurrentLimit |
| **Laser Output** | enableLaser, disableLaser, isLaserEnabled |
| **TEC Temperature** | setTemperature, getTemperature, getTempSetpoint, getTECCurrent, setTECCurrentLimit, getTECCurrentLimit |
| **TEC Output** | enableTEC, disableTEC, isTECEnabled |
| **TEC Mode** | setTECModeTemperature, setTECModeCurrent, getTECMode |
| **TEC PID** | setTECPID, getTECPID |
| **Temperature Limits** | setTECTempLimitHigh/Low, getTECTempLimitHigh/Low, setLaserTempLimitHigh, getLaserTempLimitHigh |

**Note:** Complete method implementations are documented in `ARROYO_IMPLEMENTATION_GUIDE.md`

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

### Complete Startup Procedure
```matlab
% Connect
myLaser = ComboSource6301('Arroyo-6301');

% 1. Configure TEC
myLaser.setTECTempLimitLow(15);
myLaser.setTECTempLimitHigh(35);
myLaser.setTECModeTemperature();    % Temperature control mode
myLaser.setTemperature(20);
myLaser.enableTEC();

% 2. Wait for temperature stabilization
fprintf('Waiting for temperature stabilization...\n');
for t = 1:30
    temp = myLaser.getTemperature();
    fprintf('  t=%d s: %.2f °C\n', t, temp);
    pause(1);
end

% 3. Configure laser
myLaser.setLaserCurrentLimit(150);
myLaser.setLaserCurrent(0);  % Start at 0

% 4. Enable laser (check for enclosure interlock!)
myLaser.enableLaser();

% 5. Ramp current gradually
for current = 0:0.5:27.5
    myLaser.setLaserCurrent(current);
    pause(0.5);
end

% 6. Monitor briefly
pause(5);

% 7. Safe shutdown
myLaser.setLaserCurrent(0);
myLaser.disableLaser();
myLaser.disableTEC();
myLaser.delete;
```

For complete working examples, see:
- `Howtos/Sonstiges/ComboSource/Howto_control_ComboSource6301.m`
- `Howtos/Sonstiges/ComboSource/Howto_laser_startup_with_TEC_and_safety.m`

## Safety Warnings

⚠️ **LASER SAFETY:**
- **NEVER look directly into the laser beam or its reflections**
- **Always wear appropriate laser safety goggles**
- **Ensure enclosure is closed before enabling laser**
- The device has limit switches that prevent laser operation when enclosure is open
- **Always disable laser before opening enclosure**
- Monitor temperature to prevent overheating
- Use appropriate current limits

⚠️ **IMPORTANT NOTES:**
- The Arroyo 6301 uses **custom Arroyo commands**, NOT standard SCPI
- Commands like `OUTP ON`, `SOUR:CURR`, `MEAS:CURR?` **DO NOT WORK**
- Use Arroyo commands: `LAS:OUT 1`, `LAS:LDI`, `LAS:LDI?` instead
- Serial settings: **COM1, 9600 baud, CR terminator only**
- Device echoes commands in TERMINAL mode (use `TERMINAL 0` to disable)

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
2. Check command syntax in ARROYO_IMPLEMENTATION_GUIDE.md
3. Ensure proper formatting (e.g., `LAS:LDI 27.5` not `SOUR:CURR 27.5`)

**Communication errors:**
1. Check TERMINAL mode: `write('TERMINAL?')` then `read()`
2. If echo is on, disable with: `write('TERMINAL 0')`
3. Clear buffers: `flush(serialObject, 'input')`
4. Verify CR terminator (not CR/LF)

## Version History

**Version 2.0.0 (2026-02-24)**
- **MAJOR UPDATE:** Complete rewrite for Arroyo commands
- Fixed constructor to use 'Other' instrument type
- Implemented device information methods (getID, getVersion, getSerialNumber)
- Implemented laser current control with Arroyo commands (LAS:LDI)
- Implemented laser output control (LAS:OUT)
- Added TEC temperature control methods (TEC:T, TEC:OUT)
- Added TEC mode and PID control
- Removed all non-working SCPI methods
- Updated documentation with correct Arroyo command syntax

**Version 1.0.0 (2026-01-19)**
- Initial release (SCPI-based, non-functional on Arroyo hardware)

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
- HTW Dresden, Faculty of Electrical Engineering
- Prof. Florian Römer

## Related Classes

- `VisaIF` - Base class for instrument communication
- `FGen` - Function generator control
- `Scope` - Oscilloscope control (Siglent SDS2304X)
- `SMU24xx` - Source measure unit control (Keithley)
- `RotaryPlatformDriver` - Rotary platform control (HTWD-DT-2025)

## References

- **Arroyo Command Reference:** See `ARROYO_IMPLEMENTATION_GUIDE.md`
- **Verified Commands:** See `VERIFIED_CONFIGURATION.md`
- **Arroyo 6301 Manual:** Contact manufacturer for command reference
- **Device Name:** Arroyo Instruments ComboSource 6301

## License

Part of MTLab_RemoteControl toolbox
HTW Dresden - Faculty of Electrical Engineering

---

**CRITICAL REMINDER:**
- This device uses **Arroyo custom commands**, NOT SCPI
- Serial: COM1, 9600 baud, CR terminator only
- Always check for errors (E-202, E-508, E-123)
- See working examples in `Howtos/Sonstiges/ComboSource/`

*Documentation updated: 2026-02-24*
