classdef VisaDemo < handle

    properties(Constant = true)
        % matches to VisaIF class version min. 3.x.x
        % emulates 'visadev'
        VisaDemoVersion = '3.0.1';      % current version
        VisaDemoDate    = '2025-07-12'; % release date
    end

    properties(SetAccess = private, GetAccess = public)
        Name              char   = '<empty>';
        RsrcName          char   = '<empty>';
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
        CurrentCmd       char     % to store current write command
        %
        % device AGILENT-33220A   : internal state variables
        FgenMode         logical  % true for AGILENT-33220A
        FgenFreq         double   % actual frequency at generator
        % add more here ...
        %
        % device TEK-TDS1001C-EDU : internal state variables
        ScopeMode        logical  % true for TEK-TDS1001C-EDU
        % add more here ...
    end

    properties (Constant = true, GetAccess = private)
        % device AGILENT-33220A
        FgenRsrcName   = 'USB0::0x0957::0x0407::demo';
        FgenIdn        = 'Agilent Technologies,33220A,Serial-ID,FW-ID';
        %
        % device TEK-TDS1001C-EDU
        ScopeRsrcName  = 'USB0::0x0699::0x03AA::demo';
        ScopeIdn       = 'TEKTRONIX,TDS 1001C-EDU,Serial-ID,FW-ID';
    end

    methods

        function obj = VisaDemo(RsrcName)
            narginchk(0, 1);
            if nargin < 1 || ~ischar(RsrcName)
                RsrcName = 'demo';
            end
            obj.RsrcName = RsrcName;
            obj.Status   = 'open';

            % -------------------------------------------------------------
            % here starts the actual emulation

            switch lower(obj.RsrcName)
                case lower(obj.FgenRsrcName)
                    obj.FgenMode  = true;    % emulate AGILENT-33220A
                    obj.ScopeMode = false;
                case lower(obj.ScopeRsrcName)
                    obj.FgenMode  = false;
                    obj.ScopeMode = true;    % emulate TEK-TDS1001C-EDU
                otherwise
                    obj.FgenMode  = false;
                    obj.ScopeMode = false;
            end

            if obj.FgenMode
                % initialze internal state variables
                obj.FgenFreq = 1e3;  % 1kHz as default
                % add more here ...
            end

            if obj.ScopeMode
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

            % end of emulation
            % -------------------------------------------------------------

            % convert to double (like in visa) and attach 'LF' at the end
            response = [double(response) 10];
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