classdef ScopeMacros < handle
    % template
    %
    % device specific documentation

    properties(Constant = true)
        MacrosVersion = '0.1.0';      % release version
        MacrosDate    = '2020-06-05'; % release date
    end

    properties(Dependent, SetAccess = private, GetAccess = public)
        ShowMessages                      logical
        AutoscaleHorizontalSignalPeriods  double
        AutoscaleVerticalScalingFactor    double
        AcquisitionState                  char
        TriggerState                      char
        ErrorMessages                     char
    end

    properties(SetAccess = private, GetAccess = private)
        VisaIFobj         % VisaIF object
    end

    % ------- basic methods -----------------------------------------------
    methods

        function obj = ScopeMacros(VisaIFobj)
            % constructor

            obj.VisaIFobj = VisaIFobj;
        end

        function delete(obj)
            % destructor

            if obj.ShowMessages
                disp(['Object destructor called for class ''' ...
                    class(obj) '''.']);
            end
        end

        function status = runAfterOpen(obj)

            % init output
            status = NaN;

            disp('ToDo ...');
            % add some device specific commands:
            % XXX
            %if obj.VisaIFobj.write('XXX')
            %    status = -1;
            %end
            % set XXX
            %if obj.VisaIFobj.write('XXX')
            %    status = -1;
            %end
            % ...

            % wait for operation complete
            obj.VisaIFobj.opc;
            % ...

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = runBeforeClose(obj)

            % init output
            status = NaN;

            disp('ToDo ...');
            % add some device specific commands:
            % XXX
            %if obj.VisaIFobj.write('XXX')
            %    status = -1;
            %end

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

        function status = reset(obj)

            % init output
            status = NaN;

            disp('ToDo ...');
            % add some device commands:
            %
            % XXX
            %if obj.VisaIFobj.write('XXX')
            %    status = -1;
            %end
            % XXX
            %if obj.VisaIFobj.write('XXX')
            %    status = -1;
            %end
            % wait for operation complete
            obj.VisaIFobj.opc;

            % set final status
            if isnan(status)
                % no error so far ==> set to 0 (fine)
                status = 0;
            end
        end

    end

    % ------- main scope macros -------------------------------------------
    methods

        function status = clear(obj)
            % clear status at scope
            status = obj.VisaIFobj.write('*CLS');
        end

        function status = lock(obj)
            % lock all buttons at scope

            disp('ToDo ...');
            status = 0;
        end

        function status = unlock(obj)
            % unlock all buttons at scope

            disp('ToDo ...');
            status = 0;
        end

        function status = acqRun(obj)
            % start data acquisitions at scope

            disp('ToDo ...');
            status = 0;
        end

        function status = acqStop(obj)
            % stop data acquisitions at scope

            disp('ToDo ...');
            status = 0;
        end

        function status = autoset(obj)
            % causes the oscilloscope to adjust its vertical, horizontal,
            % and trigger controls to display a stable waveform

            disp('ToDo ...');
            status = 0;
        end

        % -----------------------------------------------------------------

        function status = configureInput(obj, varargin)
            % configure input channels

            disp('ToDo ...');
            status = 0;
        end

        function status = configureAcquisition(obj, varargin)
            % configure acquisition parameters

            disp('ToDo ...');
            status = 0;
        end

        function status = configureTrigger(obj, varargin)
            % configure trigger parameters

            disp('ToDo ...');
            status = 0;
        end

        function status = configureZoom(obj, varargin)
            % configure zoom window

            disp('ToDo ...');
            status = 0;
        end

        function status = autoscale(obj, varargin)
            % adjust its vertical and/or horizontal scaling

            disp('ToDo ...');
            status = 0;
        end

        function status = makeScreenShot(obj, varargin)
            % make a screenshot of scope display

            disp('ToDo ...');
            status = 0;
        end

        function status = takeMeasurement(obj, varargin)
            % request measurement value

            disp('ToDo ...');
            status = 0;
        end

        function status = captureWaveForm(obj, varargin)
            % download waveform data

            disp('ToDo ...');
            status = 0;
        end

        % -----------------------------------------------------------------
        % actual scope methods: get methods (dependent)
        % -----------------------------------------------------------------

        function acqState = get.AcquisitionState(obj)
            % get acquisition state (run or stop)

            disp('ToDo ...');
            acqState = '<undefined>';
        end

        function trigState = get.TriggerState(obj)
            % get trigger state (ready, auto, triggered)

            disp('ToDo ...');
            trigState = '<undefined>';
        end

        function errMsg = get.ErrorMessages(obj)
            % read error list from the scope’s error buffer

            disp('ToDo ...');
            errMsg = '<undefined>';
        end

    end

    % ---------------------------------------------------------------------
    methods           % get/set methods

        function showmsg = get.ShowMessages(obj)

            switch lower(obj.VisaIFobj.ShowMessages)
                case 'none'
                    showmsg = false;
                case {'few', 'all'}
                    showmsg = true;
                otherwise
                    disp('ScopeMacros: invalid state in get.ShowMessages');
            end
        end

        function period = get.AutoscaleHorizontalSignalPeriods(obj)

            period = obj.VisaIFobj.AutoscaleHorizontalSignalPeriods;
        end

        function factor = get.AutoscaleVerticalScalingFactor(obj)

            factor = obj.VisaIFobj.AutoscaleVerticalScalingFactor;
        end

    end

end