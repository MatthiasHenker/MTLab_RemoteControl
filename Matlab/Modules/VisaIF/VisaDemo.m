classdef VisaDemo < handle
    
    properties(Constant = true)
        VisaDemoVersion = '1.0.2';      % current version
        VisaDemoDate    = '2021-01-09'; % release date
    end
    
    properties(SetAccess = private, GetAccess = public)
        Name             char   = '<empty>';
        RsrcName         char   = '<empty>';
        Alias            char   = '';
        Type             char   = 'demo';
        RemoteHost       char   = '<empty>';
        ManufacturerID   char   = '<empty>';
        ModelCode        char   = '<empty>';
        SerialNumber     char   = '<empty>';
        Status           char   = '';
    end
    
    properties
        Timeout          double = 0;
        InputBufferSize  double = 0;
        OutputBufferSize double = 0;
        ByteOrder        char   = '';
        EOIMode          char   = '';
        EOSCharCode      char   = '';
        EOSMode          char   = '';
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
            obj.Status   = 'closed';
            
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
        
        function delete(obj)
            % do nothing
            %disp(['Object destructor called for class ' class(obj)]);
        end
        
        function fopen(obj)
            obj.Status = 'open';
        end
        
        function fclose(obj)
            obj.Status = 'closed';
        end
        
        function fwrite(obj, cmd, type)
            narginchk(3, 3);
            % input 'type' will be ignored
            if ~isa(cmd, 'uint8')
                error('VisaDemo (fwrite): invalid input (cmd).');
            end
            if ~strcmpi(obj.Status, 'open')
                error('OBJ must be connected to the hardware with OPEN.');
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
        
        function [response, cnt, msg] = fread(obj, bufsize, type)
            narginchk(3, 3);
            % inputs bufsize and 'type' will be ignored
            if ~strcmpi(obj.Status, 'open')
                error('OBJ must be connected to the hardware with OPEN.');
            end
            cnt      = 0;
            msg      = '';
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
        
        function clrdevice(obj)
            if ~strcmpi(obj.Status, 'open')
                error('OBJ must be connected to the hardware with OPEN.');
            end
            % do nothing else
        end
        
    end
    
end