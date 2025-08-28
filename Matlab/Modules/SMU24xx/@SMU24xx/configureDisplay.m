function status = configureDisplay(obj, varargin)
% configureDisplay : configure display of SMU24xx

if ~strcmpi(obj.ShowMessages, 'none')
    disp([obj.DeviceName ':']);
    disp('  configure SMU display');
    params = obj.checkParams(varargin, 'configureDisplay', true);
else
    params = obj.checkParams(varargin, 'configureDisplay');
end

% init output
status = NaN;

% initialize all supported parameters
screen     = '';
digits     = [];
brightness = [];
buffer     = '';
text       = {};

% init misc
screenClear = false;
screenHelp  = false;

for idx = 1:2:length(params)
    paramName  = params{idx};
    paramValue = params{idx+1};
    switch paramName
        case 'screen'
            switch lower(paramValue)
                case ''
                    screen = '';
                case 'help'
                    screenHelp  = true;
                case 'clear'
                    screenClear = true;
                case 'home'
                    screen = 'home';
                case {'home_larg', 'home_large_reading'}
                    screen = 'home_large_reading';
                case {'read', 'reading_table'}
                    screen = 'reading_table';
                case {'grap', 'graph'}
                    screen = 'graph';
                case {'hist', 'histogram'}
                    screen = 'histogram';
                case {'swipe_grap', 'swipe_graph'}
                    screen = 'swipe_graph';
                case {'swipe_sett', 'swipe_settings'}
                    screen = 'swipe_settings';
                case {'sour', 'source'}
                    screen = 'source';
                case {'swipe_stat', 'swipe_statistics'}
                    screen = 'swipe_statistics';
                case 'swipe_user'
                    screen = 'swipe_user';
                case {'proc', 'processing'}
                    screen = 'processing';
                otherwise
                    disp(['SMU24xx Warning - ' ...
                        '''configureDisplay(screen)'' ' ...
                        'invalid parameter value ' ...
                        '--> ignore and continue']);
            end
        case 'digits'
            if ~isempty(paramValue)
                digits = str2double(paramValue);
                if isnan(digits)
                    digits = '';
                else
                    digits = round(digits);
                    digits = min(digits, 6);
                    digits = max(digits, 3);
                    digits = num2str(digits, '%d');
                end
            end
        case 'brightness'
            if ~isempty(paramValue)
                brightness = str2double(paramValue);
                if isnan(brightness)
                    brightness = [];
                else
                    brightness = round(brightness);
                    brightness = min(brightness, 100);
                    brightness = max(brightness, -1);
                end
                % convert to command string (char)
                if brightness < 0
                    brightness = 'blackout';
                elseif brightness < 5
                    brightness = 'off';
                elseif brightness < 30
                    brightness = 'on25';
                elseif brightness < 55
                    brightness = 'on50';
                elseif brightness < 80
                    brightness = 'on75';
                else
                    brightness = 'on100';
                end
            end
        case 'buffer'
            if ~isempty(paramValue)
                if obj.isBuffer(paramValue)
                    buffer = paramValue;
                end
            end
        case 'text'
            % split and copy to cell array of char
            if ~isempty(paramValue)
                text = split(paramValue, ';');
            end
            % check and limit number of lines
            % check and limit also length of lines
            maxNumOfLines = 2;
            maxLenLine    = [20 32];
            if length(text) > maxNumOfLines
                text = text(1:maxNumOfLines);
            end
            for cnt = 1 : length(text)
                if length(text{cnt}) > maxLenLine(cnt)
                    text{cnt} = text{cnt}(1 : ...
                        maxLenLine(cnt)); %#ok<AGROW>
                end
            end
        otherwise
            if ~isempty(paramValue)
                disp(['SMU24xx Warning - ''configureDisplay'' ' ...
                    'parameter ''' paramName ''' is ' ...
                    'unknown --> ignore and continue']);
            end
    end
end

% -------------------------------------------------------------
% actual code
% -------------------------------------------------------------
% 'screen'           : char
if screenHelp
    disp('Help for ''configureDisplay(screen= OPTIONS)''');
    disp('  available OPTIONS are:');
    disp('  ''HOME''              - Home screen');
    disp('  ''HOME_LARGe_reading''- ... with large readings');
    disp('  ''READing_table''     - Reading table');
    disp('  ''GRAPh''             - Graph screen');
    disp('  ''HISTogram''         - Histogram screen');
    disp('  ''SWIPE_GRAPh''       - GRAPH      swipe screen');
    disp('  ''SWIPE_SETTings''    - SETTINGS   swipe screen');
    disp('  ''SOURce''            - SOURCE     swipe screen');
    disp('  ''SWIPE_STATistics''  - STATISTICS swipe screen');
    disp('  ''SWIPE_USER''        - USER       swipe screen');
    disp('  ''PROCessing''        - screen reducing CPU power');
elseif screenClear
    obj.write(':Display:Clear');
elseif ~isempty(screen)
    obj.write([':Display:Screen ' screen]);
    % read and verify (not applicable)
end

% 'digits'           : char
if ~isempty(digits)
    % set for all modes: curr, res, volt
    obj.write([':Display:Digits ' digits]);
    % readback and verify
    response = obj.query(':Display:Volt:Digits?');
    response = char(response);
    if ~strcmpi(response, digits)
        % set command failed
        disp(['SMU24xx Warning - ''configureDisplay'' ' ...
            'digits parameter could not be set correctly.']);
        status = -1;
    end
end

% 'brightness'       : char
if ~isempty(brightness)
    obj.write([':Display:Light:State ' brightness]);
    % readback and verify
    response = obj.query(':Display:Light:State?');
    response = char(response);
    if ~strcmpi(response, brightness)
        % set command failed
        disp(['SMU24xx Warning - ''configureDisplay'' ' ...
            'brightness parameter could not be set correctly.']);
        status = -1;
    end
end

% 'buffer'           : char
if ~isempty(buffer)
    obj.write([':Display:Buffer:Active "' buffer '"']);
    % readback and verify
    response = obj.query(':Display:Buffer:Active?');
    response = char(response);
    if ~strcmpi(response, buffer)
        % set command failed
        disp(['SMU24xx Warning - ''configureDisplay'' ' ...
            'buffer parameter could not be set correctly.']);
        status = -1;
    end
end

% 'text'             : cell array of char
if ~isempty(text)
    % select user swipe screen
    obj.write(':Display:Screen swipe_user');
    % show text on screen
    for cnt = 1 : length(text)
        if ~isempty(text{cnt})
            cmd = sprintf(':Display:User%d:Text "%s"', ...
                cnt, text{cnt});
            obj.write(cmd);
        end
    end
    % read and verify (not applicable)
end

% wait for operation complete
obj.opc;

% set final status
if isnan(status)
    % no error so far ==> set to 0 (fine)
    status = 0;
end

if ~strcmpi(obj.ShowMessages, 'none') && status ~= 0
    disp('  configureDisplay failed');
end

end
