classdef(ConstructOnLoad) VisaIFLogEventData < event.EventData
    % documentation for class 'VisaIFLogEventData'
    % ---------------------------------------------------------------------
    % Intention: This class adds additional properties to the event object
    % which is passed from the notifier (VisaIF) to the listener
    % (VisaIFLogger).
    % ---------------------------------------------------------------------
    % Methods:
    %
    % VisaIFLogEventData(CmdNumber, Device, Mode, SCPIcommand, CmdLength)
    % Constructor of this class
    %   -Input variables:
    %      CmdNumber   : SCPI command number             (double)
    %      Device      : device name                     (char)
    %      Mode        : read or write                   (char)
    %      SCPIcommand : head of SCPI command            (char)
    %      CmdLength   : length of SCPI command in bytes (double)
    %
    % Properties: constant, read-only
    %      VisaIFLogEventVersion : version      (char)
    %      VisaIFLogEventDate    : release date (char)
    %
    % Usage:
    %      class will be internally used by VisaIF and VisaIFLogger;
    %      VisaIFLogEventData.VisaIFLogEventVersion to get version
    %      VisaIFLogEventData.VisaIFLogEventDate    to get date
    % ---------------------------------------------------------------------
    % HTW Dresden, faculty of electrical engineering
    %   for version and release date see properties 'VisaIFLogEventVersion'
    %   and 'VisaIFLogEventDate'
    %
    % tested with
    %   - VisaIF v2.3.0  (2020-05-25)
    %   - for further requirements see VisaIF
    %
    % ---------------------------------------------------------------------
    % development, support and contact:
    %   - Constantin Wimmer (student, automation)
    %   - Matthias Henker   (professor)
    %----------------------------------------------------------------------
    
    properties(Constant = true)
        VisaIFLogEventVersion = '2.0.0';      % current version
        VisaIFLogEventDate    = '2020-05-25'; % release date
    end
    
    properties (GetAccess = public, SetAccess = private)
        CmdNumber      double
        Device         char
        Mode           char
        SCPIcommand    char
        CmdLength      double
    end
    
    methods
        
        function eventData = VisaIFLogEventData(...
                CmdNumber   , ...
                Device      , ...
                Mode        , ...
                SCPIcommand , ...
                CmdLength   )
            
            narginchk(5, 5);
            
            % -------------------------------------------------------------
            % set defaults for missing inputs
            
            if isempty(CmdNumber)
                CmdNumber   = NaN;
            end
            
            if isempty(Device)
                Device      = '<missing>';
            end
            
            if isempty(Mode)
                Mode        = '<missing>';
            end
            
            if isempty(SCPIcommand)
                SCPIcommand = '<missing>';
            end
            
            
            if isempty(CmdLength)
                CmdLength   = NaN;
            end
            
            % -------------------------------------------------------------
            % no type check of inputs required (single types declared)
            
            
            % -------------------------------------------------------------
            % actual code: copy data to object
            % (no conversions needed, only single type allowed)
            
            eventData.CmdNumber   = CmdNumber;   % double
            eventData.Device      = Device;      % char
            eventData.Mode        = Mode;        % char
            eventData.SCPIcommand = SCPIcommand; % char
            eventData.CmdLength   = CmdLength;   % double
            
        end
        
    end
end
