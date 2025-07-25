classdef VisaDemo < handle

    properties(Constant = true)
        % matches to VisaIF class version min. 3.x.x
        % emulates 'visadev'
        VisaDemoVersion = '3.0.2';      % current version
        VisaDemoDate    = '2025-07-25'; % release date
    end

    properties(SetAccess = private, GetAccess = public)
        Name              char   = '<empty>';
        RsrcName          char   = '<empty>'; % defined by config.csv
        ResourceName      char   = '<empty>'; % defined by emulated visadev
        Alias             char   = '';
        Type              char   = 'demo';
        PreferredVisa     char   = '<empty>';
        InstrumentAddress char   = '<empty>';
        VendorID          char   = '<empty>';
        ProductID         char   = '<empty>';
        SerialNumber      char   = '<empty>';
        VendorIdentified  char   = '<empty>';
        ProductIdentified char   = '<empty>';
        Status            char   = '';
    end

    properties
        Timeout          double = 0;
        Tag              char   = '';
        InputBufferSize  double = 0;
        OutputBufferSize double = 0;
        ByteOrder        char   = '';
        EOIMode          char   = '';
        %EOSMode          char   = '';
    end

    properties(SetAccess = private, GetAccess = private)
        % internal state variables
        CurrentCmd       char            % to store current write command
        %
        % device AGILENT-33220A   : internal state variables
        FgenMode         logical = false % true for AGILENT-33220A
        FgenFreq         double  = 1e3   % actual frequency at generator
        % add more here ...
        %
        % device TEK-TDS1001C-EDU : internal state variables
        ScopeMode        logical = false % true for TEK-TDS1001C-EDU
        %
        SMU24xxMode      logical = false % true for Keithley-2450
        % add more here ...
    end

    properties (Constant = true, GetAccess = private)
        % device AGILENT-33220A
        FgenRsrcName    = 'USB0::0x0957::0x0407::demo';
        FgenIdn         = 'Agilent Technologies,33220A,Serial-ID,FW-ID';
        %
        % device TEK-TDS1001C-EDU
        ScopeRsrcName   = 'USB0::0x0699::0x03AA::demo';
        ScopeIdn        = 'TEKTRONIX,TDS 1001C-EDU,Serial-ID,FW-ID';
        %
        % device
        SMU24xxRsrcName = 'USB0::0x05E6::0x2450::demo';
        SMU24xxIdn      = 'KEITHLEY,2450,Serial-ID,FW-ID';
    end

    methods

        function obj = VisaDemo(RsrcName)
            narginchk(0, 1);
            if nargin < 1 || ~ischar(RsrcName)
                RsrcName = 'demo';
            end
            obj.RsrcName     = RsrcName;
            obj.ResourceName = RsrcName;
            obj.Status       = 'open';

            % -------------------------------------------------------------
            % here starts the actual emulation

            switch lower(obj.RsrcName)
                case lower(obj.FgenRsrcName)
                    obj.FgenMode    = true;   % emulate AGILENT-33220A
                case lower(obj.ScopeRsrcName)
                    obj.ScopeMode   = true;   % emulate TEK-TDS1001C-EDU
                case lower(obj.SMU24xxRsrcName)
                    obj.SMU24xxMode = true;   % emulate Keithley 2450
                otherwise
                    % all '*Mode' = false
            end

            if obj.FgenMode
                % initialze internal state variables
                obj.FgenFreq = 1e3;  % 1 kHz as default
                % add more here ...
            end

            if obj.ScopeMode
                % add more here ...
            end

            if obj.SMU24xxMode
                % add more here ...
            end

            % end of emulation
            % -------------------------------------------------------------
        end

        function delete(obj) %#ok<INUSD>
            % do nothing
            %disp(['Object destructor called for class ' class(obj)]);
        end

        function write(obj, cmd, type) %#ok<INUSD>
            narginchk(3, 3);
            % input 'type' will be ignored
            if ~isa(cmd, 'uint8')
                error('VisaDemo (write): invalid input (cmd).');
            end
            % convert to characters
            cmd = char(cmd);

            % -------------------------------------------------------------
            % here starts the actual emulation

            % split command into command header and parameter
            cmdCell = split(cmd, ' ');
            cmdHeader    = cmdCell{1};
            if length(cmdCell) >= 2
                cmdParam = cmdCell{2};
            else
                cmdParam = '';
            end

            % store cmd
            obj.CurrentCmd = cmdHeader;

            % emulate AGILENT-33220A
            if obj.FgenMode
                % list of supported SCPI commands (set commands only!)
                switch upper(cmdHeader)
                    case '*RST'
                        obj.FgenFreq = 1e3; % set to default again
                    case {'FREQ', 'FREQUENCY'}
                        frequency = str2double(cmdParam);
                        if ~isnan(frequency) && isreal(frequency) && ...
                                isscalar(frequency) && frequency > 0
                            % okay, format and save frequency value
                            obj.FgenFreq  = str2double( ...
                                num2str(frequency, '%.6f'));
                        end
                        % add more here ...
                    otherwise
                        % do nothing
                end
            end

            % emulate TEK-TDS1001C-EDU
            if obj.ScopeMode
                % ToDo
                %
                %
                % add more here ...
                %
            end

            % emulate Keithey-2450
            if obj.SMU24xxMode
                % list of supported SCPI commands (set commands only!)
                switch upper(cmdHeader)
                    case '*RST'
                        % set to default again
                        % add more here ...
                    otherwise
                        % do nothing
                end
            end

            % end of emulation
            % -------------------------------------------------------------
        end

        function response = read(obj, bufsize, type) %#ok<INUSD>
            narginchk(3, 3);
            % inputs bufsize and 'type' will be ignored
            response = '';
            % -------------------------------------------------------------
            % here starts the actual emulation

            % emulate AGILENT-33220A
            if obj.FgenMode
                % create response according to last get command
                switch upper(obj.CurrentCmd)
                    case '*IDN?'
                        response = obj.FgenIdn;
                    case '*OPC?'
                        response = '1';
                    case {'FREQ?', 'FREQUENCY?'}
                        response = num2str(obj.FgenFreq, '%.6f');
                        % add more here ...
                    otherwise
                        % unknown command
                        response = '<cmd not implemented>';
                end
            end

            % emulate TEK-TDS1001C-EDU
            if obj.ScopeMode
                % create response according to last get command
                switch upper(obj.CurrentCmd)
                    case '*IDN?'
                        response = obj.ScopeIdn;
                    case '*OPC?'
                        response = '1';
                        % add more here ...
                    otherwise
                        % unknown command
                        response = '<cmd not implemented>';
                end
            end

            % emulate Keithey-2450
            if obj.SMU24xxMode
                % create response according to last get command
                switch upper(obj.CurrentCmd)
                    case '*IDN?'
                        response = obj.SMU24xxIdn;
                    case '*OPC?'
                        response = '1';
                    case ':SENSE:FUNCTION?'
                        response = '"curr:dc"'; % or '"volt:dc"'
                    case ':SOURCE:FUNCTION?'
                        response = 'volt';      % or 'curr'
                    case ':SOURCE:VOLTAGE:ILIMIT?'
                        response = '0.815';     % numerical
                    case ':SOURCE:VOLTAGE:ILIMIT:TRIPPED?'
                        response = '1';         % yes
                        % add more here ...
                    otherwise
                        % unknown command
                        response = '<cmd not implemented>';
                end
            end

            % end of emulation
            % -------------------------------------------------------------

            % convert to double (like in visa) and attach 'LF' at the end
            %response = [double(response) 10];
            % do not attach 'LF' anymore because readline and writeline is
            % used now
            response = double(response);
        end

        function writeline(obj, cmd)
            obj.write(uint8(cmd), 'uint8')
        end

        function response = readline(obj)
            response = obj.read(inf, 'uint8');
        end

        function clrdevice(obj) %#ok<MANU>
            % do nothing else
        end

        function flush(obj, buffer) %#ok<INUSD>
            narginchk(1, 2);
            if nargin < 2
                buffer = ''; %#ok<NASGU>
            end
            % do nothing else
        end

        function configureTerminator(obj, RxTerminator, TxTerminator) %#ok<INUSD>
            % do nothing
        end

    end

end