classdef HandheldDMMMacros < handle
    % include device specific documentation when needed
    %
    %
    % Uni-T, UT61E series macros
    
    properties(Constant = true)
        MacrosVersion = '1.0.0';      % release version
        MacrosDate    = '2022-08-09'; % release date
        MacrosName    = 'VC830';      % DMM type
        %
        NumBytes      = 14;  % number of bytes to read (for one DMM value)
        SamplePeriod  = 0.6; % in s
        %
        Timeout       = 0.7; % slightly larger than SamplePeriod
        BaudRate      = 2400;
        DataBits      = 8;
        StopBits      = 1;
        Parity        = "none";
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
                % DC-V mode with 0.000 .. 5.999 V range
                DCoffset  = 4.4;   % in V
                DCsigma   = 0.9; % in V
                measValue = DCoffset + DCsigma*randn(1);
                % clip to max display value
                measValue = min(measValue,  5.999);
                measValue = max(measValue, -5.999);
                % limit to four decimal places
                measValue = round(measValue * 1e3) / 1e3;
                
                % respond a random value and return
                value  = measValue;
                mode   = 'DC-V';
                status = 0;
                return
            end
            
            % a check that 14 Bytes (property NumBytes) were received
            % is already implemented in the public read function
            
            % first we check bytes order: the bytes are numbers
            % Attention: 8 Databits
            % num byte:   upper nibble     lower nibble
            %  1st byte:     0x2             sign
            %  2nd byte:     0x3             digit 1 (BCD)
            %  3rd byte:     0x3             digit 2 (BCD)
            %  4th byte:     0x3             digit 3 (BCD)
            %  5th byte:     0x3             digit 4 (BCD)
            %  6th byte:     0x2             0x0
            %  7th byte:     0x3             point
            %  8th byte:     0x?             SB1
            %  9th byte:     0x?             SB2
            % 10th byte:     0x?             SB3
            % 11th byte:     0x?             SB4
            % 12th byte:     0x?             BAR
            % last two bytes are carriage return, line feed
            % CR, LF = \r, \n = 0x0D, 0x0A = 13, 10
            % 13th byte:             0x0D
            % 14th byte:             0x0A
            
            % check last two bytes
            if ~all(rawData(13:14) == [13; 10])
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
            value = str2double(char(rawData(1:5)'));
            
            % decimal point (byte 7)
            switch dec2hex(rawData(7))
                case '30', multiplier = 1e0;
                case '31', multiplier = 1e-3;
                case '32', multiplier = 1e-2;
                case '34', multiplier = 1e-1;
                otherwise, multiplier = NaN;
                    status     = -1;
            end
            
            % scale value properly
            value = value * multiplier;
            
            % bytes 8 .. 11 defines mode and so on
            SBbin = dec2bin(rawData(8:11), 8);
            
            %auto    = SBbin(1, 3);
            DC      = SBbin(1, 4);
            AC      = SBbin(1, 5);
            
            % prefix
            nano    = SBbin(2, 7);
            mu      = SBbin(3, 1);
            milli   = SBbin(3, 2);
            kilo    = SBbin(3, 3);
            Mega    = SBbin(3, 4);
            
            switch [nano mu milli kilo Mega]
                case '10000', multiplier = 1e-9;
                case '01000', multiplier = 1e-6;
                case '00100', multiplier = 1e-3;
                case '00000', multiplier = 1e0;
                case '00010', multiplier = 1e3;
                case '00001', multiplier = 1e6;
                otherwise,    multiplier = NaN;
                    status     = -1;
            end
            
            % scale value properly
            value = value * multiplier;
            
            switch SBbin(4, :)
                case '10000000', mode   = 'V';
                case '01000000', mode   = 'A';
                case '00100000', mode   = 'Ohm';
                    %
                case '00001000', mode   = 'Hz';
                    %
                case '00000100', mode   = 'F';
                otherwise,       mode   = '?';
                    status = -1;
            end
            
            % bar graph (byte 12) ==> not of interest here
            %barBin  = dec2bin(rawData(12), 7)
            %if barBin(1) == '1'
            %    barValue = - bin2dec(barBin(2:7))
            %else
            %    barValue = + bin2dec(barBin(2:7))
            %end
            
            % finally: add AC or DC
            switch [AC DC]
                case '10',   mode   = ['AC-' mode];
                case '01',   mode   = ['DC-' mode];
                case '00'    % nothing to do
                otherwise,   status = -1;
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