classdef HandheldDMMMacros < handle
    % include device specific documentation when needed
    %
    %
    % Uni-T, UT61E series macros
    
    properties(Constant = true)
        MacrosVersion = '1.1.0';      % release version
        MacrosDate    = '2022-08-10'; % release date
        MacrosName    = 'UT61E';      % DMM type
        %
        NumBytes      = 14;  % number of bytes to read (for one DMM value)
        SamplePeriod  = 0.5; % in s
        %
        Timeout       = 0.7; % slightly larger than SamplePeriod
        BaudRate      = 19200;
        DataBits      = 7;
        StopBits      = 1;
        Parity        = "odd";
        FlowControl   = "none";
        ByteOrder     = "little-endian"; % default, not of interest
        %
        % DMM sends ASCII (7-bit) with CR/LF at the end
        Terminator       = "CR/LF";
        BinaryTerminator = {}; % has to be empty when Terminator is set
        RequestPacket    = {}; % uni-directional connection
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
                % DC-V mode with 0.0000 .. 2.2000 V range
                DCoffset  = 1.3;   % in V
                DCsigma   = 0.4; % in V
                measValue = DCoffset + DCsigma*randn(1);
                % clip to max display value
                measValue = min(measValue,  2.199);
                measValue = max(measValue, -2.199);
                % limit to four decimal places
                measValue = round(measValue * 1e4) / 1e4;
                
                % respond a random value and return
                value  = measValue;
                mode   = 'DC-V';
                status = 0;
                return
            end
            
            % a check that 14 Bytes (property NumBytes) were received
            % is already implemented in the public read function
            
            % first we check bytes order: the bytes are numbers
            % Attention: 7 Databits only ==> MSB (8-bit) is always '0'
            % num byte:   upper nibble     lower nibble
            %  1st byte:     0x3             measurement range
            %  2nd byte:     0x3             digit 1 (BCD)
            %  3rd byte:     0x3             digit 2 (BCD)
            %  4th byte:     0x3             digit 3 (BCD)
            %  5th byte:     0x3             digit 4 (BCD)
            %  6th byte:     0x3             digit 5 (BCD)
            %  7th byte:     0x3             measurement range
            %  8th byte:     0x3             percent, Vz, lowBatt, OL
            %  9th byte:     0x3             max, min, delta, RMR
            % 10th byte:     0x3             UL, peakMax, peakMin, '0'
            % 11th byte:     0x3             DC, AC, auto, freq
            % 12th byte:     0x3             '0', vbar, hold, LPF
            % last two bytes are carriage return, line feed
            % CR, LF = \r, \n = 0x0D, 0x0A = 13, 10
            % 13th byte:             0x0D
            % 14th byte:             0x0A
            rawBin = dec2bin(rawData(1:12), 8);
            
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
            
            % check upper nibble of first bytes (1 .. 12)
            % always 0x3 = '0011' expected
            if ~all(rawBin(:,1:4) == dec2bin(zeros(12, 1)+3, 4), 'all')
                % incorrect order of bytes
                if obj.ShowMessages
                    disp('WARNING: Incorrect order of bytes.');
                end
                status = -1;
                return
            end
            
            % now we can convert the actual data (lower nibble)
            lowNib = rawBin(:,5:8);
            
            % conversion can start
            %
            % bytes  2:6 are the actual digits
            value = [1e4 1e3 1e2 1e1 1e0] * bin2dec(lowNib(2:6, :));
            
            % bytes 1 & 7 define measurement range and mode
            % Attention: percent mode is not implemented here
            switch lowNib(7, :)         % mode
                case '1011'
                    mode   = 'V';
                    switch lowNib(1, :) % range (mode 'V')
                        case '0000', multiplier = 1e-4;
                        case '0001', multiplier = 1e-3;
                        case '0010', multiplier = 1e-2;
                        case '0011', multiplier = 1e-1;
                        case '0100', multiplier = 1e-5;
                        otherwise  , multiplier = NaN;
                            status     = -1;
                    end
                case '0011'
                    mode   = 'Ohm';
                    switch lowNib(1, :) % range (mode 'Ohm')
                        case '0000', multiplier = 1e-2;
                        case '0001', multiplier = 1e-1;
                        case '0010', multiplier = 1e0;
                        case '0011', multiplier = 1e1;
                        case '0100', multiplier = 1e2;
                        case '0101', multiplier = 1e3;
                        case '0110', multiplier = 1e4;
                        otherwise  , multiplier = NaN;
                            status     = -1;
                    end
                case '0110'
                    mode   = 'F';
                    switch lowNib(1, :) % range (mode 'F')
                        case '0000', multiplier = 1e-12;
                        case '0001', multiplier = 1e-11;
                        case '0010', multiplier = 1e-10;
                        case '0011', multiplier = 1e-9;
                        case '0100', multiplier = 1e-8;
                        case '0101', multiplier = 1e-7;
                        case '0110', multiplier = 1e-6;
                        case '0111', multiplier = 1e-5;
                        otherwise  , multiplier = NaN;
                            status     = -1;
                    end
                case '0010'
                    mode   = 'Hz';
                    switch lowNib(1, :) % range (mode 'Hz')
                        case '0000', multiplier = 1e-2;
                        case '0001', multiplier = 1e-1;
                            %    '0010'
                        case '0011', multiplier = 1e0;
                        case '0100', multiplier = 1e1;
                        case '0101', multiplier = 1e2;
                        case '0110', multiplier = 1e3;
                        case '0111', multiplier = 1e4;
                        otherwise  , multiplier = NaN;
                            status     = -1;
                    end
                case '1101'
                    mode   = 'A';
                    switch lowNib(1, :) % range (mode 'microA')
                        case '0000', multiplier = 1e-8;
                        case '0001', multiplier = 1e-7;
                        otherwise  , multiplier = NaN;
                            status     = -1;
                    end
                case '1111'
                    mode   = 'A';
                    switch lowNib(1, :) % range (mode 'mA')
                        case '0000', multiplier = 1e-6;
                        case '0001', multiplier = 1e-5;
                        otherwise  , multiplier = NaN;
                            status     = -1;
                    end
                case '0000'
                    mode   = 'A';
                    switch lowNib(1, :) % range (mode '10A')
                        case '0000', multiplier = 1e-3;
                        otherwise  , multiplier = NaN;
                            status     = -1;
                    end
                otherwise
                    mode       = '?';
                    multiplier = NaN;
                    status     = -1;
            end
            
            % scale value according to measurement mode and range
            value = value * multiplier;
            
            % bytes 8..12 define sign, AC/DC mode, and overload
            % Byte  8
            %percent = lowNib( 8, 1); % unused here
            Vz      = lowNib( 8, 2);
            %batt    = lowNib( 8, 3); % unused here
            OL      = lowNib( 8, 4);
            % Byte  9
            %max     = lowNib( 9, 1); % unused here
            %min     = lowNib( 9, 2); % unused here
            %delta   = lowNib( 9, 3); % unused here
            %RMR     = lowNib( 9, 4); % unused here
            % Byte 10
            %UL      = lowNib(10, 1); % unused here
            %peakMax = lowNib(10, 2); % unused here
            %peakMin = lowNib(10, 3); % unused here
            %unknown = lowNib(10, 4); % unused here
            % Byte 11
            DC      = lowNib(11, 1);
            AC      = lowNib(11, 2);
            %auto    = lowNib(11, 3); % unused here
            %freq    = lowNib(11, 4); % unused here
            % Byte 12
            %unknown = lowNib(12, 1); % unused here
            %vbar    = lowNib(12, 2); % unused here
            %hold    = lowNib(12, 3); % unused here
            %LPF     = lowNib(12, 4); % unused here
            
            % add sign to value
            % sign
            if Vz == '1'
                value = (-1)* value;
            end
            
            % overload
            if OL == '1'
                value = inf;
            end
            
            % finally: AC or DC? (byte 11)
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