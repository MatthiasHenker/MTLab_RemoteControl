classdef HandheldDMMMacros < handle
    % include device specific documentation when needed
    %
    %
    % Voltcraft, VC820 series macros

    properties(Constant = true)
        MacrosVersion = '1.1.0';      % release version
        MacrosDate    = '2022-08-10'; % release date
        MacrosName    = 'VC820';      % DMM type
        %
        NumBytes      = 14;  % number of bytes to read (for one DMM value)
        SamplePeriod  = 0.35;% in s
        %
        Timeout       = 0.5; % slightly larger than SamplePeriod
        BaudRate      = 2400;
        DataBits      = 8;
        StopBits      = 1;
        Parity        = "none";
        FlowControl   = "none";
        ByteOrder     = "little-endian"; % default, not of interest
        %
        % DMM sends ASCII (7-bit) with CR/LF at the end
        Terminator       = ''; % Terminator is ignored when read is used
        % ==> create dedicated list (check protocol of DMM)
        % ==> for VC820 last byte is always 0xE? where upper
        %     nibble 'E' is unique in each data packet
        BinaryTerminator = hex2dec({'E0', 'E1', 'E2', 'E3', 'E4', 'E5', ...
            'E6', 'E7', 'E8', 'E9', 'EA', 'EB', 'EC', 'ED', 'EE', 'EF'});
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
                % DC-V mode with 0.000 .. 3.999 V range
                DCoffset  = 2.5;   % in V
                DCsigma   = 0.6; % in V
                measValue = DCoffset + DCsigma*randn(1);
                % clip to max display value
                measValue = min(measValue,  3.999);
                measValue = max(measValue, -3.999);
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
            % num byte:   upper nibble       lower nibble
            %  1st byte:     0x1              AC,DC,Auto,RS232
            %  2nd byte:     0x2              Vz,A5,A6,A1
            %  3rd byte:     0x3              A4,A3,A7,A2
            %  4th byte:     0x4              P1,B5,B6,B1
            %  5th byte:     0x5              B4,B3,B7,B2
            %  6th byte:     0x6              P2,C5,C6,C1
            %  7th byte:     0x7              C4,C3,C7,C2
            %  8th byte:     0x8              P3,D5,D6,D1
            %  9th byte:     0x9              D4,D3,D7,D2
            % 10th byte:     0xA              mu,n,k,Diode
            % 11th byte:     0xB              m,%,M,Beep
            % 12th byte:     0xC              F,Ohm,Delta,Hold
            % 13th byte:     0xD              A,V,Hz,Battery
            % 14th byte:     0xE              '','','',°C
            rawBin = dec2bin(rawData, 8);

            % check upper nibble
            if ~all(rawBin(:,1:4) == dec2bin(transpose(1:14), 4), 'all')
                % incorrect order of bytes
                if obj.ShowMessages
                    disp('WARNING: Incorrect order of bytes.');
                end
                status = -1;
                return
            end

            % now we can convert the actual data (lower nibble)
            lowNib = rawBin(:,5:8);

            % we have to extract all bits first
            % Byte  1
            AC      = lowNib( 1, 1);
            DC      = lowNib( 1, 2);
            %Auto    = lowNib( 1, 3); % unused here
            %RS232   = lowNib( 1, 4); % unused here
            % Byte  2
            Vz      = lowNib( 2, 1);
            A5      = lowNib( 2, 2);
            A6      = lowNib( 2, 3);
            A1      = lowNib( 2, 4);
            % Byte  3
            A4      = lowNib( 3, 1);
            A3      = lowNib( 3, 2);
            A7      = lowNib( 3, 3);
            A2      = lowNib( 3, 4);
            % Byte  4
            P1      = lowNib( 4, 1);
            B5      = lowNib( 4, 2);
            B6      = lowNib( 4, 3);
            B1      = lowNib( 4, 4);
            % Byte  5
            B4      = lowNib( 5, 1);
            B3      = lowNib( 5, 2);
            B7      = lowNib( 5, 3);
            B2      = lowNib( 5, 4);
            % Byte  6
            P2      = lowNib( 6, 1);
            C5      = lowNib( 6, 2);
            C6      = lowNib( 6, 3);
            C1      = lowNib( 6, 4);
            % Byte  7
            C4      = lowNib( 7, 1);
            C3      = lowNib( 7, 2);
            C7      = lowNib( 7, 3);
            C2      = lowNib( 7, 4);
            % Byte  8
            P3      = lowNib( 8, 1);
            D5      = lowNib( 8, 2);
            D6      = lowNib( 8, 3);
            D1      = lowNib( 8, 4);
            % Byte  9
            D4      = lowNib( 9, 1);
            D3      = lowNib( 9, 2);
            D7      = lowNib( 9, 3);
            D2      = lowNib( 9, 4);
            % Byte 10
            mu      = lowNib(10, 1);
            n       = lowNib(10, 2);
            k       = lowNib(10, 3);
            %diode   = lowNib(10, 4); % unused here
            % Byte 11
            m       = lowNib(11, 1);
            %percent = lowNib(11, 2); % unused here
            M       = lowNib(11, 3);
            %beep    = lowNib(11, 4); % unused here
            % Byte 12
            F       = lowNib(12, 1);
            Ohm     = lowNib(12, 2);
            %delta   = lowNib(12, 3); % unused here
            %hold    = lowNib(12, 4); % unused here
            % Byte 13
            A       = lowNib(13, 1);
            V       = lowNib(13, 2);
            Hz      = lowNib(13, 3);
            %battery = lowNib(13, 4); % unused here
            % Byte 14
            %unknown = lowNib(14, 1);
            %unknown = lowNib(14, 2);
            %unknown = lowNib(14, 3);
            %degrees = lowNib(14, 4); % unused here

            % pooh, create numbers and modes out of all these bits
            %
            % we start with the digits (bytes 2 ... 9)
            segments        = char(zeros(4,7));
            segments(1, : ) = [A1, A2, A3, A4, A5, A6, A7];
            segments(2, : ) = [B1, B2, B3, B4, B5, B6, B7];
            segments(3, : ) = [C1, C2, C3, C4, C5, C6, C7];
            segments(4, : ) = [D1, D2, D3, D4, D5, D6, D7];
            %
            digits          = char(zeros(1,4));
            for idx = 1:length(digits)
                switch segments(idx, :)
                    case '0110000'
                        digits(idx) = '1';
                    case '1101101'
                        digits(idx) = '2';
                    case '1111001'
                        digits(idx) = '3';
                    case '0110011'
                        digits(idx) = '4';
                    case '1011011'
                        digits(idx) = '5';
                    case '1011111'
                        digits(idx) = '6';
                    case '1110000'
                        digits(idx) = '7';
                    case '1111111'
                        digits(idx) = '8';
                    case '1111011'
                        digits(idx) = '9';
                    case '1111110'
                        digits(idx) = '0';
                    otherwise
                        % error
                        status      = -1;
                        digits(idx) = 'x';
                end

            end

            % where is the decimal point? (still bytes 2 ... 9)
            switch [P1 P2 P3]
                case '001', multiplier = 0.1;
                case '010', multiplier = 0.01;
                case '100', multiplier = 0.001;
                otherwise,  multiplier = NaN;
                    status     = -1;
            end

            % merge all digits and convert
            value = str2double(digits) * multiplier;
            % sign
            if Vz == '1'
                value = (-1)* value;
            end

            % now we add the exponent (bytes 10 ... 11)
            switch [M k m mu n]
                case '10000', mult2  = 1e6;
                case '01000', mult2  = 1e3;
                case '00000', mult2  = 1;
                case '00100', mult2  = 1e-3;
                case '00010', mult2  = 1e-6;
                case '00001', mult2  = 1e-9;
                otherwise,    mult2  = NaN;
                    status = -1;
            end
            % final numeric value
            value = value * mult2;
            if isnan(value)
                status = -1;
            end

            % now detect mode (bytes 12 ... 13)
            switch [V A Hz F Ohm]
                case '10000', mode   = 'V';
                case '01000', mode   = 'A';
                case '00100', mode   = 'Hz';
                case '00010', mode   = 'F';
                case '00001', mode   = 'Ohm';
                otherwise,    mode   = '?';
                    status = -1;
            end
            % finally: AC or DC? (byte 1)
            switch [AC DC]
                case '10',   mode   = ['AC-' mode];
                case '01',   mode   = ['DC-' mode];
                case '00'    % nothing to do
                otherwise,   status = -1;
            end

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