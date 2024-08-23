classdef HandheldDMMMacros < handle
    % include device specific documentation when needed
    %
    %
    % Uni-T, UT161E series macros

    properties(Constant = true)
        MacrosVersion = '0.5.0';      % release version
        MacrosDate    = '2022-08-10'; % release date
        MacrosName    = 'UT161E';     % DMM type
        %
        NumBytes      = 19;  % number of bytes to read (for one DMM value)
        SamplePeriod  = 0.5; % tbd. in s
        %
        Timeout       = 0.2; % typical respond time is 100 ms
        BaudRate      = 9600;
        DataBits      = 8;
        StopBits      = 1;
        Parity        = "none";
        FlowControl   = "none";
        ByteOrder     = "little-endian"; % default, not of interest
        %
        % DMM sends ASCII (8-bit) with CRC at the end
        Terminator       = 0;  % useless, can be any value
        BinaryTerminator = {}; % has to be empty when Terminator is set
        RequestPacket    = {'AB', 'CD', '03', '5e', '01', 'd9'};
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

            % a check that 19 Bytes (property NumBytes) were received
            % is already implemented in the public read function

            % first we check bytes order:
            % Attention: 8 Databits
            % num byte :  data
            %  1st byte:  0xAB       magic header 1/2
            %  2nd byte:  0xCD       magic header 2/2
            %  3rd byte:             unknown
            %  4th byte:             unknown
            %  5th byte:             unknown
            %  6th byte:  char 1     7-character display
            %  7th byte:  char 2     (5 digits + decimal point
            %  8th byte:  char 3     and sign)
            %  9th byte:  char 4     ASCII
            % 10th byte:  char 5
            % 11th byte:  char 6
            % 12th byte:  char 7
            % 13th byte:             unknown
            % 14th byte:             unknown
            % 15th byte:             unknown
            % 16th byte:             unknown
            % 17th byte:             unknown
            %      last two bytes are a CRC
            % 18th byte:             0x0D
            % 19th byte:             0x0A

            % check header
            header = dec2hex(rawData(1:2), 2);
            if ~all(header == ['AB'; 'CD'])
                if obj.ShowMessages
                    disp('WARNING (read): Incorrect data header');
                end
                status = -1;
                return
            end

            % check CRC    (sum(1:17) == (18:19)
            CRCfield = dec2hex(rawData(18 : 19), 2);
            CRCfield = reshape(CRCfield', 1, 4);
            CRCdata  = dec2hex(sum(rawData( 1 : 17)), 4);
            if ~all(CRCfield == CRCdata)
                if obj.ShowMessages
                    disp('WARNING (read): Incorrect CRC');
                end
                status = -1;
                return
            end

            % convert display data
            data = str2double(char(rawData(6:12)'));
            if ~isnan(data)
                value = data;
            else
                if obj.ShowMessages
                    disp('WARNING (read): Incorrect display data');
                end
                status = -1;
                return
            end

            % remaining bytes
            unknown1 = dec2hex(rawData( 3 :  5), 2);
            unknown2 = dec2hex(rawData(13 : 17), 2);
            if obj.ShowMessages
                disp(['unknown_1: ' char(strjoin(string(unknown1))) ...
                    '  _2: ' char(strjoin(string(unknown2)))]);
            end
            %mode   = 'AC-V';



            %             % now we can convert the actual data (lower nibble)
            %             lowNib = rawBin(:,5:8);
            %
            %             % conversion can start
            %             %
            %             % bytes  2:6 are the actual digits
            %             value = [1e4 1e3 1e2 1e1 1e0] * bin2dec(lowNib(2:6, :));
            %
            %             % bytes 1 & 7 define measurement range and mode
            %             % Attention: percent mode is not implemented here
            %             switch lowNib(7, :)         % mode
            %                 case '1011'
            %                     mode   = 'V';
            %                     switch lowNib(1, :) % range (mode 'V')
            %                         case '0000', multiplier = 1e-4;
            %                         case '0001', multiplier = 1e-3;
            %                         case '0010', multiplier = 1e-2;
            %                         case '0011', multiplier = 1e-1;
            %                         case '0100', multiplier = 1e-5;
            %                         otherwise  , multiplier = NaN;
            %                             status     = -1;
            %                     end
            %                 case '0011'
            %                     mode   = 'Ohm';
            %                     switch lowNib(1, :) % range (mode 'Ohm')
            %                         case '0000', multiplier = 1e-2;
            %                         case '0001', multiplier = 1e-1;
            %                         case '0010', multiplier = 1e0;
            %                         case '0011', multiplier = 1e1;
            %                         case '0100', multiplier = 1e2;
            %                         case '0101', multiplier = 1e3;
            %                         case '0110', multiplier = 1e4;
            %                         otherwise  , multiplier = NaN;
            %                             status     = -1;
            %                     end
            %                 case '0110'
            %                     mode   = 'F';
            %                     switch lowNib(1, :) % range (mode 'F')
            %                         case '0000', multiplier = 1e-12;
            %                         case '0001', multiplier = 1e-11;
            %                         case '0010', multiplier = 1e-10;
            %                         case '0011', multiplier = 1e-9;
            %                         case '0100', multiplier = 1e-8;
            %                         case '0101', multiplier = 1e-7;
            %                         case '0110', multiplier = 1e-6;
            %                         case '0111', multiplier = 1e-5;
            %                         otherwise  , multiplier = NaN;
            %                             status     = -1;
            %                     end
            %                 case '0010'
            %                     mode   = 'Hz';
            %                     switch lowNib(1, :) % range (mode 'Hz')
            %                         case '0000', multiplier = 1e-2;
            %                         case '0001', multiplier = 1e-1;
            %                             %    '0010'
            %                         case '0011', multiplier = 1e0;
            %                         case '0100', multiplier = 1e1;
            %                         case '0101', multiplier = 1e2;
            %                         case '0110', multiplier = 1e3;
            %                         case '0111', multiplier = 1e4;
            %                         otherwise  , multiplier = NaN;
            %                             status     = -1;
            %                     end
            %                 case '1101'
            %                     mode   = 'A';
            %                     switch lowNib(1, :) % range (mode 'microA')
            %                         case '0000', multiplier = 1e-8;
            %                         case '0001', multiplier = 1e-7;
            %                         otherwise  , multiplier = NaN;
            %                             status     = -1;
            %                     end
            %                 case '1111'
            %                     mode   = 'A';
            %                     switch lowNib(1, :) % range (mode 'mA')
            %                         case '0000', multiplier = 1e-6;
            %                         case '0001', multiplier = 1e-5;
            %                         otherwise  , multiplier = NaN;
            %                             status     = -1;
            %                     end
            %                 case '0000'
            %                     mode   = 'A';
            %                     switch lowNib(1, :) % range (mode '10A')
            %                         case '0000', multiplier = 1e-3;
            %                         otherwise  , multiplier = NaN;
            %                             status     = -1;
            %                     end
            %                 otherwise
            %                     mode       = '?';
            %                     multiplier = NaN;
            %                     status     = -1;
            %             end
            %
            %             % scale value according to measurement mode and range
            %             value = value * multiplier;
            %
            %             % bytes 8..12 define sign, AC/DC mode, and overload
            %             % Byte  8
            %             %percent = lowNib( 8, 1); % unused here
            %             Vz      = lowNib( 8, 2);
            %             %batt    = lowNib( 8, 3); % unused here
            %             OL      = lowNib( 8, 4);
            %             % Byte  9
            %             %max     = lowNib( 9, 1); % unused here
            %             %min     = lowNib( 9, 2); % unused here
            %             %delta   = lowNib( 9, 3); % unused here
            %             %RMR     = lowNib( 9, 4); % unused here
            %             % Byte 10
            %             %UL      = lowNib(10, 1); % unused here
            %             %peakMax = lowNib(10, 2); % unused here
            %             %peakMin = lowNib(10, 3); % unused here
            %             %unknown = lowNib(10, 4); % unused here
            %             % Byte 11
            %             DC      = lowNib(11, 1);
            %             AC      = lowNib(11, 2);
            %             %auto    = lowNib(11, 3); % unused here
            %             %freq    = lowNib(11, 4); % unused here
            %             % Byte 12
            %             %unknown = lowNib(12, 1); % unused here
            %             %vbar    = lowNib(12, 2); % unused here
            %             %hold    = lowNib(12, 3); % unused here
            %             %LPF     = lowNib(12, 4); % unused here
            %
            %
            %             % overload
            %             if OL == '1'
            %                 value = inf;
            %             end
            %
            %             % finally: AC or DC? (byte 11)
            %             switch [AC DC]
            %                 case '10',   mode   = ['AC-' mode];
            %                 case '01',   mode   = ['DC-' mode];
            %                 case '00'    % nothing to do
            %                 otherwise,   status = -1;
            %             end






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