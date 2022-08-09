classdef HandheldDMMMacros < handle
    % include device specific documentation when needed
    %
    %
    % Uni-T, UT61E series macros
    
    properties(Constant = true)
        MacrosVersion = '1.0.0';      % release version
        MacrosDate    = '2022-08-09'; % release date
        MacrosName    = 'VC920';      % DMM type
        %
        NumBytes      = 11;  % number of bytes to read (for one DMM value)
        SamplePeriod  = 0.65; % in s
        %
        Timeout       = 0.7; % slightly larger than SamplePeriod
        BaudRate      = 2400;
        DataBits      = 7;
        StopBits      = 1;
        Parity        = "odd";
        FlowControl   = "none";
        ByteOrder     = "little-endian"; % default, not of interest
        %
        % DMM sends ASCII (7-bit) with CR/LF at the end
        Terminator       = "CR/LF";
        BinaryTerminator = {}; % has to be empty when Terminator is set
    end
    
    properties(Dependent, SetAccess = private, GetAccess = public)
        ShowMessages logical
    end
    
    properties(SetAccess = private, GetAccess = private)
        HandheldDMMobj                % HandheldDMMobj object
    end
    
    
    % ------- basic methods -----------------------------------------------
    methods
        
        function obj = HandheldDMMMacros(HandheldDMMobj)
            % constructor
            
            obj.HandheldDMMobj = HandheldDMMobj;
        end
        
        function delete(obj)
            % destructor
            
            if obj.ShowMessages
                disp(['Object destructor called for class ' class(obj)]);
            end
        end
        
        function [value, mode, status] = convertData(obj, rawData)
            % convert block of bytes (rawData) to actual numeric value
            
            % init output variables
            value  = NaN;
            mode   = '';
            status = NaN;
            
            if obj.HandheldDMMobj.DemoMode
                % DC-V mode with 0.000 .. 3.9999 V range
                DCoffset  = 2.4;   % in V
                DCsigma   = 0.7; % in V
                measValue = DCoffset + DCsigma*randn(1);
                % clip to max display value
                measValue = min(measValue,  3.9999);
                measValue = max(measValue, -3.9999);
                % limit to four decimal places
                measValue = round(measValue * 1e4) / 1e4;
                
                % respond a random value and return
                value  = measValue;
                mode   = 'DC-V';
                status = 0;
                return
            end
            
            % a check that 11 Bytes (property NumBytes) were received
            % is already implemented in the public read function
            
            % first we check bytes order: the bytes are numbers
            % Attention: 7 Databits
            % num byte:   upper nibble     lower nibble
            %  1st byte:     0x3             digit 1 (ASCII)
            %  2nd byte:     0x3             digit 2 (ASCII)
            %  3rd byte:     0x3             digit 3 (ASCII)
            %  4th byte:     0x3             digit 4 (ASCII)
            %  5th byte:     0x3             digit 5 (ASCII)
            %  6th byte:     0x3             range
            %  7th byte:     0x3             mode (unit)
            %  8th byte:     0x3             AC / DC
            %  9th byte:     0x3             info
            % last two bytes are carriage return, line feed
            % CR, LF = \r, \n = 0x0D, 0x0A = 13, 10
            % 10th byte:             0x0D
            % 11th byte:             0x0A
            
            % check last two bytes
            if ~all(rawData(10:11) == [13; 10])
                % incorrect order of bytes
                if obj.ShowMessages
                    disp(['WARNING: Incorrect order of bytes. ' ...
                        '(CR, LF missing)']);
                end
                status = -1;
                return
            end
            
            % now we can convert the actual data
            
            % first 5 bytes are ASCII-chars for sign and numbers
            if all(dec2hex(rawData(5)) == '3A')
                % last digit is ' ' (empty)
                value = str2double(char(rawData(1:4)'));
            else
                value = str2double(char(rawData(1:5)'));
            end
            
            % range (byte 6)
            Byte6_bin = dec2bin(rawData(6), 8);
            range     = Byte6_bin(1, 6:8);
            range     = bin2dec(range);
            
            % mode (unit) (byte 7)
            Byte7_bin = dec2bin(rawData(7), 8);
            unit      = Byte7_bin(1, 5:8);
            unit      = bin2dec(unit);
            
            % AC / DC (byte 8)
            Byte8_bin = dec2bin(rawData(8), 8);
            DC        = Byte8_bin(1, 7);
            AC        = Byte8_bin(1, 8);
            
            % info (byte 9)
            Byte9_bin = dec2bin(rawData(9), 8);
            NegFlag   = Byte9_bin(1, 6);
            %ManRange  = Byte9_bin(1, 7);
            %AutoRange = Byte9_bin(1, 8);
            
            % -------------------------------------------------------------
            
            switch unit
                case 0,    mode   = 'V';   % AC-mV
                    multiplier = 10^(range-5);
                case 1,    mode   = 'V';   % DC-V
                    multiplier = 10^(range-5);
                case 2,    mode   = 'V';   % AC-V
                    multiplier = 10^(range-5);
                case 3,    mode   = 'V';   % DC-mV
                    multiplier = 10^(range-5);
                case 4,    mode   = 'Ohm';
                    multiplier = 10^(range-2);
                case 5,    mode   = 'F';
                    multiplier = 10^(range-13);
                case 6,    mode   = '°C';
                    multiplier = 10^(range-1);
                case 7,    mode   = 'A';  % muA
                    multiplier = 10^(range-8);
                case 8,    mode   = 'A';  % mA
                    multiplier = 10^(range-6);
                case 9,    mode   = 'A';  % A
                    multiplier = 10^(range-4);
                case 10,   mode   = 'Pieps'; % Durchgangsprüfung
                    multiplier = 1;
                case 11,   mode   = 'V';   % Diodenmessung
                    multiplier = 1;
                case 12,   mode   = 'Hz';  % bzw. duty cycle when NegFlag
                    multiplier = 1;
                case 13,   mode   = '°F';
                    multiplier = 10^(range-1);
                case 14,   mode   = 'W';
                    multiplier = 1;
                case 15,   mode   = '%';  % 4-20 mA Tester
                    multiplier = 1;
                otherwise, mode   = '?';
                    status = -1;
            end
            
            % finally: add AC or DC
            switch [AC DC]
                case '11',   mode   = ['AC+DC-' mode];
                case '10',   mode   = ['AC-'    mode];
                case '01',   mode   = ['DC-'    mode]; % unused
                case '00'
                    switch mode
                        case {'V', 'A'}
                            mode   = ['DC-'    mode];
                    end
                otherwise,   status = -1;
            end
            
            % scale value properly
            value = value * multiplier;
            if NegFlag == '1'
                value = (-1) * value;
            end
            
            % all others bits were ignored up to now
            %
            % ==> code can be extended later
            
            % set status
            if isnan(status)
                status = 0;
            end
            
        end
        
    end
    
    % ---------------------------------------------------------------------
    methods           % get/set methods
        
        function showmsg = get.ShowMessages(obj)
            
            % logical (boolean)
            showmsg = obj.HandheldDMMobj.ShowMessages;
        end
        
    end
    
end