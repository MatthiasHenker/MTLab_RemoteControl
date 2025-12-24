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
% any channel number in range 0 .. 99 is allowed, duplicates will be removed
%

narginchk(1,3);
% -------------------------------------------------------------------------
% check type of input
if isempty(inVars)
    inVars = {};
elseif ~iscell(inVars) || ~isvector(inVars)
    error('Scope: invalid state.');
elseif mod(length(inVars), 2) ~= 0
    disp(['Scope: Warning - Odd number of parameters. ' ...
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
channel      = ''; % configureInput, runMeasurement, captureWaveForm, autoscale
trace        = ''; % configureInput
impedance    = ''; % configureInput
vDiv         = ''; % configureInput
vOffset      = ''; % configureInput
coupling     = ''; % configureInput, configureTrigger
inputDiv     = ''; % configureInput
bwLimit      = ''; % configureInput
invert       = ''; % configureInput
skew         = ''; % configureInput
unit         = ''; % configureInput
tDiv         = ''; % configureAcquisition
sampleRate   = ''; % configureAcquisition
maxLength    = ''; % configureAcquisition
mode         = ''; % configureAcquisition, configureTrigger, autoscale
numAverage   = ''; % configureAcquisition
type         = ''; % configureTrigger
source       = ''; % configureTrigger
level        = ''; % configureTrigger
delay        = ''; % configureTrigger
parameter    = ''; % runMeasurement
fileName     = ''; % makeScreenShot
darkMode     = ''; % makeScreenShot
zoomFactor   = ''; % configureZoom
zoomPosition = ''; % configureZoom

% -------------------------------------------------------------------------
% assign parameter values
for nArgsIn = 2:2:length(inVars)
    paramName  = inVars{nArgsIn-1};
    paramValue = inVars{nArgsIn};
    % convert even cell arrays or strings to char: {'m' 'ode'} is also okay
    if iscellstr(paramName) || isstring(paramName)
        paramName = char(strjoin(paramName, ''));
    end
    if ischar(paramName) || isStringScalar(paramName)
        % coerce parameter value (array) to comma separated char array
        % '1', {'1'}, "1", 1, true                           ==> '1'
        % {'0', '1'} ["0", "1"], '0, 1', [0 1] [false true ] ==> '0, 1'
        if ~isvector(paramValue)
            paramValue = '';
            disp(['Scope: Invalid type of ''' paramName '''. ' ...
                'Ignore input.']);
        elseif ischar(paramValue)
            paramValue = upper(paramValue);
        elseif iscellstr(paramValue) || isstring(paramValue)
            paramValue = upper(char(strjoin(paramValue, ', ')));
        elseif isa(paramValue, 'double') || islogical(paramValue)
            paramValue = upper(regexprep( ...
                num2str(paramValue, 10), '\s+', ', '));
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
                % duplicates will be removed
                %
                % check format and accept valid input only
                if ~isempty(regexp(paramValue, ...
                        '^\s*(CH|)\d{1,2}\s*((,|;)\s*(CH|)\d{1,2}\s*)*$', ...
                        'once'))
                    % remove optional 'CH':  'CH1, CH3' ==> '1, 3'
                    channel = replace(paramValue, {'CH', ';'}, {'', ','});
                    % split char array into a (column) vector of integer numbers
                    channel = str2double(split(channel, ','));
                    % remove duplicates without changing order
                    channel = unique(channel, 'stable');
                    % convert to char array back again
                    channel = char(join(string(channel), ', '));
                end
            case {'trace'}
                % trace: accept all scalar values [+-a-zA-Z0-9.] no spaces
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    trace        = paramValue;
                end
            case {'impedance', 'imp'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    impedance    = paramValue;
                end
            case {'vdiv'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    vDiv         = paramValue;
                end
            case {'voffset', 'voff', 'voffs'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    vOffset      = paramValue;
                end
            case {'coupling', 'coupl', 'coup'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    coupling     = paramValue;
                end
            case {'inputdiv', 'probe'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    inputDiv     = paramValue;
                end
            case {'bwlimit'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    bwLimit      = paramValue;
                end
            case {'invert', 'inv'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    invert       = paramValue;
                end
            case {'skew'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    skew         = paramValue;
                end
            case {'unit'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    unit         = paramValue;
                end
            case {'tdiv'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    tDiv         = paramValue;
                end
            case {'samplerate', 'srate'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    sampleRate   = paramValue;
                end
            case {'maxlength', 'maxlen'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    maxLength    = paramValue;
                end
            case {'mode'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    mode         = paramValue;
                end
            case {'numaverage', 'numavg'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    numAverage   = paramValue;
                end
            case {'type'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    type         = paramValue;
                end
            case {'source', 'src', 'sourc'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    source       = paramValue;
                end
            case {'level', 'lev', 'lvl'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    level        = paramValue;
                end
            case {'delay', 'dly'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    delay        = paramValue;
                end
            case {'parameter', 'param'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    parameter    = paramValue;
                end
            case {'filename', 'fname'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-\\/:]+$', 'once'))
                    try
                        fileName = char(java.io.File(paramValue).toPath);
                    catch
                        fileName = '';
                    end
                end
            case {'darkmode', 'dark'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    darkMode     = paramValue;
                end
            case {'zoomfactor', 'zoomfact'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    zoomFactor   = paramValue;
                end
            case {'zoomposition', 'zoompos'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    zoomPosition = paramValue;
                end
            otherwise
                disp(['Scope: Warning - Parameter name ''' ...
                    paramName ''' is unknown. ' ...
                    'Ignore parameter.']);
        end
    else
        disp(['Scope: Parameter names have to be ' ...
            'character arrays. Ignore input.']);
    end
end

% -------------------------------------------------------------------------
% copy only command relevant parameters
switch command
    case 'configureInput'
        outVars = { ...
            'channel'     , channel      , ...
            'trace'       , trace        , ...
            'impedance'   , impedance    , ...
            'vDiv'        , vDiv         , ...
            'vOffset'     , vOffset      , ...
            'coupling'    , coupling     , ...
            'inputDiv'    , inputDiv     , ...
            'bwLimit'     , bwLimit      , ...
            'invert'      , invert       , ...
            'skew'        , skew         , ...
            'unit'        , unit         };
    case 'configureAcquisition'
        outVars = { ...
            'tDiv'        , tDiv         , ...
            'sampleRate'  , sampleRate   , ...
            'maxLength'   , maxLength    , ...
            'mode'        , mode         , ...
            'numAverage'  , numAverage   };
    case 'configureTrigger'
        outVars = { ...
            'mode'        , mode         , ...
            'type'        , type         , ...
            'source'      , source       , ...
            'coupling'    , coupling     , ...
            'level'       , level        , ...
            'delay'       , delay        };
    case 'configureZoom'
        outVars = { ...
            'zoomFactor'  , zoomFactor   , ...
            'zoomPosition', zoomPosition };
    case 'autoscale'
        outVars = { ...
            'channel'     , channel      , ...
            'mode'        , mode         };
    case 'makeScreenShot'
        outVars = { ...
            'fileName'    , fileName     , ...
            'darkMode'    , darkMode     };
    case 'runMeasurement'
        outVars = { ...
            'channel'     , channel      , ...
            'parameter'   , parameter    };
    case 'captureWaveForm'
        outVars = { ...
            'channel'     , channel      };
    otherwise
        % create full list of parameter name+value pairs
        allVars = { ...
            'channel'     , channel      , ...
            'trace'       , trace        , ...
            'impedance'   , impedance    , ...
            'vDiv'        , vDiv         , ...
            'vOffset'     , vOffset      , ...
            'coupling'    , coupling     , ...
            'inputDiv'    , inputDiv     , ...
            'bwLimit'     , bwLimit      , ...
            'invert'      , invert       , ...
            'skew'        , skew         , ...
            'unit'        , unit         , ...
            'tDiv'        , tDiv         , ...
            'sampleRate'  , sampleRate   , ...
            'maxLength'   , maxLength    , ...
            'mode'        , mode         , ...
            'numAverage'  , numAverage   , ...
            'type'        , type         , ...
            'source'      , source       , ...
            'level'       , level        , ...
            'delay'       , delay        , ...
            'parameter'   , parameter    , ...
            'fileName'    , fileName     , ...
            'darkMode'    , darkMode     , ...
            'zoomFactor'  , zoomFactor   , ...
            'zoomPosition', zoomPosition };
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
            disp(['  - ' pad(outVars{cnt}, 13) ': ' ...
                outVars{cnt+1}]);
        end
    end
end
end