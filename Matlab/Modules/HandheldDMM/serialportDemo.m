classdef serialportDemo < handle

    properties(Constant = true)
        SerialportDemoVersion = '1.1.0';      % current version
        SerialportDemoDate    = '2022-08-10'; % release date
        %
        NumBytesAvailable     = 0;            % empty buffer
    end

    methods

        function obj = serialportDemo()
            % do nothing

        end

        function delete(obj)                     %#ok<INUSD>
            % do nothing

            %disp(['Object destructor called for class ' class(obj)]);
        end

        function flush(obj, mode)                %#ok<INUSD>
            % do nothing

        end

        function data = readline(obj)            %#ok<MANU>
            % do nothing, but respond a string with no content
            % Note: isempty("") will get false

            data = "";
        end

        function data = read(obj, count, type)   %#ok<INUSL>
            % do nothing, but respond zero data of requested size and
            % format
            %
            % count has to be a scalar positive integer
            % type has to be a valid datatype ("uint8" | "int8" | ...)

            typeHandle = str2func(type);
            data       = typeHandle(zeros(1, count));
        end

        function data = write(obj, data, type)   %#ok<INUSL,INUSD>
            % do nothing
        end

    end

end