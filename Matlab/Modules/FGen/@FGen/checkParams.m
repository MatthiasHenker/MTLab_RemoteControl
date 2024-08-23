function outVars = checkParams(inVars, command, showmsg)
% check input parameters ==> always dupels
% 'parameterName', 'parameterValue'
% outVars = cell array with all set parameters
% all unset parameter names are ignored
% parameter values are coerced, converted or (silently) ignored
% report warnings when
%   - odd number of input variables
%   - unknown parameter names
%   - invalid types of parameter values
%
% accepted inputs are: (for all parameters)
% text is not case sensitive    ==> changed to upper case
% 'text', "text", {'text'}      ==> 'TEXT'    (without spaces)
% number, [number], true/false  ==> 'number'
% additionally for 'channels'
% 1, [1 2 3], '1,2,3' '1;2;3' ["1", "2", "3"]  ==> '1, 2, 3'
% 'ch1, ch2',  {'ch1', 'ch2'}, ["ch1", "ch2"]  ==> '1, 2'
% any channel number in range 0 .. 99 is allowed
% channel ids will be sorted in ascending order, duplicates will be removed
%

narginchk(1,3);
% -------------------------------------------------------------------------
% check type of input
if isempty(inVars)
    inVars = {};
elseif ~iscell(inVars) || ~isvector(inVars)
    error('FGen: invalid state.');
elseif mod(length(inVars), 2) ~= 0
    disp(['FGen: Warning - Odd number of parameters. ' ...
        'Ignore last input.']);
end

if nargin < 3
    showmsg = false;
end

if nargin < 2 || isempty(command)
    command = '';
end

% -------------------------------------------------------------------------
% initialize all parameter values (empty)
channel      = '';   % configureOutput, arbWaveform, enableOutput,
%                      disableOutput
waveform     = '';   % configureOutput
amplitude    = '';   % configureOutput
unit         = '';   % configureOutput
offset       = '';   % configureOutput
frequency    = '';   % configureOutput
phase        = '';   % configureOutput
dutycycle    = '';   % configureOutput
symmetry     = '';   % configureOutput
transition   = '';   % configureOutput
stdev        = '';   % configureOutput
bandwidth    = '';   % configureOutput
outputimp    = '';   % configureOutput
samplerate   = '';   % configureOutput
mode         = '';   % arbWaveform
submode      = '';   % arbWaveform
wavename     = '';   % arbWaveform
wavedata     = '';   % arbWaveform  ==> exception: run no data conversion
%filename     = '';   % arbWaveform    (for future use???)

% -------------------------------------------------------------------------
% assign parameter values
for nArgsIn = 2:2:length(inVars)
    paramName  = inVars{nArgsIn-1};
    paramValue = inVars{nArgsIn};
    % convert even cell arrays or strings to char: {'m' 'ode'} is okay
    if iscellstr(paramName) || isstring(paramName)
        paramName = char(strjoin(paramName, ''));
    end
    if ischar(paramName) || isStringScalar(paramName)
        % coerce parameter value (array) to comma separated char array
        % '1', {'1'}, "1", 1, true                           ==> '1'
        % {'0', '1'} ["0", "1"], '0, 1', [0 1] [false true ] ==> '0, 1'
        if ~isvector(paramValue)
            paramValue = '';
            disp(['FGen: Invalid type of ''' paramName '''. ' ...
                'Ignore input.']);
        elseif ischar(paramValue)
            paramValue = upper(paramValue);
        elseif iscellstr(paramValue) || isstring(paramValue)
            paramValue = upper(char(strjoin(paramValue, ', ')));
        elseif islogical(paramValue)
            paramValue = regexprep(num2str(paramValue), '\s+', ', ');
        elseif isa(paramValue, 'double')
            % introduce an exception for wavedata to avoid time consuming
            % conversions of waveform data vectors from double to char
            if strcmpi(paramName, 'wavedata')
                % ATTENTION: paramValue is still of type double now
            else
                paramValue = upper(regexprep( ...
                    num2str(paramValue, 10), '\s+', ', '));
            end
        else
            paramValue = '';
        end
        % copy coerced parameter value to the right variable
        switch lower(char(paramName))
            % list of supported parameters
            case {'channel', 'channels', 'chan'}
                % channel: equivalent settings are (not case sensitive)
                % 'CH1', {'CH1'}, "CH1", '1', "1", 1, true  ==> '1'
                % 'CH1, CH2', '1, 2', [1 2]                 ==> '1, 2'
                % any channel number in range 0 .. 99 is allowed
                % channel ids will be sorted in ascending order
                % duplicates will be removed
                %
                % check format and accept valid input only
                if ~isempty(regexp(paramValue, ...
                        '^\s*(CH|)\d{1,2}\s*((,|;)\s*(CH|)\d{1,2}\s*)*$', ...
                        'once'))
                    % remove optional 'CH':  'CH1, CH3' ==> '1, 3'
                    channel = replace(paramValue, {'CH', ';'}, {'', ','});
                    % sort in ascending order and remove duplicates
                    channel = regexprep(num2str(unique( ...
                        str2num(channel)), '%d '), '\s+', ', ');
                end
            case {'waveform'}
                if ~isempty(regexp(paramValue, '^\w+$', 'once'))
                    waveform   = paramValue;
                end
            case {'amplitude', 'amp'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    amplitude  = paramValue;
                end
            case {'unit'}
                if ~isempty(regexp(paramValue, '^\w+$', 'once'))
                    unit       = paramValue;
                end
            case {'offset', 'off', 'offs'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    offset     = paramValue;
                end
            case {'frequency', 'freq'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    frequency  = paramValue;
                end
            case {'phase'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    phase      = paramValue;
                end
            case {'dutycycle', 'dutycyc'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    dutycycle  = paramValue;
                end
            case {'symmetry', 'sym', 'symm'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    symmetry   = paramValue;
                end
            case {'transition', 'trans'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    transition = paramValue;
                end
            case {'stdev'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    stdev      = paramValue;
                end
            case {'bandwidth'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    bandwidth  = paramValue;
                end
            case {'outputimp', 'impedance', 'outputimpedance', 'load'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    outputimp  = paramValue;
                end
            case {'samplerate', 'srate'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    samplerate = paramValue;
                end
            case {'mode'}
                if ~isempty(regexp(paramValue, '^\w+$', 'once'))
                    mode       = paramValue;
                end
            case {'submode'}
                if ~isempty(regexp(paramValue, '^\w+$', 'once'))
                    submode    = paramValue;
                end
            case {'wavename'}
                if ~isempty(regexp(paramValue, '^[a-zA-Z]\w+$', 'once'))
                    % wavename starts with a letter and contain word
                    % characters only
                    wavename   = paramValue;
                else
                    % use heading part of wavename only (till first invalid
                    % character)
                    heading = regexp(paramValue, '^[a-zA-Z]\w+', 'match');
                    if ~isempty(heading)
                        wavename   = heading{1};
                    end
                end
            case {'wavedata'}
                % exception allowed: can be either char or double
                if ~ischar(paramValue)
                    wavedata   = double(paramValue); % exception: double
                elseif ~isempty(regexp(paramValue, '^[\w\.\+\-\s]+$', 'once'))
                    wavedata   = paramValue;
                end
                % check format of vector
                if iscolumn(wavedata)
                    wavedata = transpose(wavedata);
                end
                % case {'filename', 'fname'}
                %     if ~isempty(regexp(paramValue, '^[\w\.\+\-\\/:]+$', 'once'))
                %         try
                %             filename = char(java.io.File(paramValue).toPath);
                %         catch
                %             filename = '';
                %         end
                %     end
            otherwise
                disp(['FGen: Warning - Parameter name ''' ...
                    paramName ''' is unknown. ' ...
                    'Ignore parameter.']);
        end
    else
        disp(['FGen: Parameter names have to be ' ...
            'character arrays. Ignore input.']);
    end
end

% -------------------------------------------------------------------------
% copy only command relevant parameters
switch command
    case 'configureOutput'
        outVars = { ...
            'channel'   , channel    , ...
            'waveform'  , waveform   , ...
            'amplitude' , amplitude  , ...
            'unit'      , unit       , ...
            'offset'    , offset     , ...
            'frequency' , frequency  , ...
            'phase'     , phase      , ...
            'dutycycle' , dutycycle  , ...
            'symmetry'  , symmetry   , ...
            'transition', transition , ...
            'stdev'     , stdev      , ...
            'bandwidth' , bandwidth  , ...
            'outputimp' , outputimp  , ...
            'samplerate', samplerate };
    case 'arbWaveform'
        outVars = { ...
            'channel'   , channel    , ...
            'mode'      , mode       , ...
            'submode'   , submode    , ...
            'wavename'  , wavename   , ...
            'wavedata'  , wavedata   }; %, ...
        %'filename'  , filename   };
    case 'enableOutput'
        outVars = {                    ...
            'channel'   , channel    };
    case 'disableOutput'
        outVars = {                    ...
            'channel'   , channel    };
    otherwise
        % create full list of parameter name+value pairs
        allVars = { ...
            'channel'   , channel    , ...
            'waveform'  , waveform   , ...
            'amplitude' , amplitude  , ...
            'unit'      , unit       , ...
            'offset'    , offset     , ...
            'frequency' , frequency  , ...
            'phase'     , phase      , ...
            'dutycycle' , dutycycle  , ...
            'symmetry'  , symmetry   , ...
            'transition', transition , ...
            'stdev'     , stdev      , ...
            'bandwidth' , bandwidth  , ...
            'outputimp' , outputimp  , ...
            'samplerate', samplerate , ...
            'mode'      , mode       , ...
            'submode'   , submode    , ...
            'wavename'  , wavename   , ...
            'wavedata'  , wavedata   }; %, ...
        %'filename'  , filename   };
        % copy only non-empty parameter name+value pairs to output
        outVars = cell(0);
        idx     = 1;
        for cnt = 1 : 2 : length(allVars)
            if ~isempty(allVars{cnt+1})
                outVars{idx}   = allVars{cnt};
                outVars{idx+1} = allVars{cnt+1};
                idx            = idx+2;
            end
        end
end

if showmsg
    for cnt = 1 : 2 : length(outVars)
        if ~isempty(outVars{cnt+1})
            % preprocess parameterValue
            paramValueText = outVars{cnt+1};
            % convert non character arrays (see exception for wavedata)
            if ~ischar(paramValueText)
                paramValueText = num2str(paramValueText);
            end
            % limit length of text
            if length(paramValueText) > 44
                paramValueText = [paramValueText(1:40) ' ...'];
            end
            disp(['  - ' pad(outVars{cnt}, 13) ': ' ...
                paramValueText]);
        end
    end
end
end