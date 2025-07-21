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
% text is case sensitive       ==> text remains unchanged
% 'Text', "Text", {'Text'}     ==> 'Text'
% number, [number], true/false ==> 'number' (with num2str, false = 0, true = 1)
% additionally for ParameterName 'text'
% 'ABC;abc', {'ABC', 'abc'}, ["ABC", "abc"]  ==> 'ABC;abc'
% ==> ';' is used as delimiter to separate char arrays (lines of text)
% text starts with [a-zA-Z_0-9] or any white space followed by characters
% like +-*/\:.,;=%& ==> ';' is used as delimiter ==> cannot be used in text

narginchk(1,3);
% -------------------------------------------------------------------------
% check type of input
if isempty(inVars)
    inVars = {};
elseif ~iscell(inVars) || ~isvector(inVars)
    error('SMU: invalid state.');
elseif mod(length(inVars), 2) ~= 0
    disp(['SMU: Warning - Odd number of parameters. ' ...
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
func         = ''; % configureSource, configureMeasure
level        = ''; % configureSource
limit        = ''; % configureSource
range        = ''; % configureSource, configureMeasure
nplc         = ''; % configureMeasure
fileName     = ''; % tbd.
frequency    = ''; % outputTone
duration     = ''; % outputTone
screen       = ''; % configureDisplay
digits       = ''; % configureDisplay
brightness   = ''; % configureDisplay
buffer       = ''; % configureDisplay
text         = ''; % configureDisplay

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
        % '1', {'1'}, "1", 1, true                          ==> '1'
        % {'0', '1'} ["0", "1"], '0;1', [0 1] [false true ] ==> '0;1'
        if ~isvector(paramValue)
            paramValue = '';
            disp(['SMU: Invalid type of ''' paramName '''. ' ...
                'Ignore input.']);
        elseif ischar(paramValue)
            paramValue = paramValue; %#ok<ASGSL> % do nothing
        elseif iscellstr(paramValue) || isstring(paramValue)
            paramValue = char(strjoin(paramValue, ';')); % no final upper()
        elseif isa(paramValue, 'double') || islogical(paramValue)
            paramValue = regexprep( ...
                num2str(paramValue, 10), '\s+', ';');    % no final upper()
        else
            paramValue = '';
        end

        % copy coerced parameter value to the right variable
        switch lower(char(paramName))
            % list of supported parameters
            case {'funct', 'func', 'fun'}
                % accept all scalar values [+-a-zA-Z0-9.] no spaces
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    func = paramValue;
                end
            case {'level', 'lvl'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    level = paramValue;
                end
            case {'limit', 'lim'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    limit = paramValue;
                end
            case {'range', 'rng'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    range = paramValue;
                end
            case {'nplc'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    nplc = paramValue;
                end
            case {'filename', 'fname'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-\\/:]+$', 'once'))
                    try
                        fileName = char(java.io.File(paramValue).toPath);
                    catch
                        fileName = '';
                    end
                end
            case {'frequeny', 'freq'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    frequency = paramValue;
                end
            case {'duration', 'length'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    duration = paramValue;
                end
            case {'screen'}
                if ~isempty(regexp(paramValue, '^\w+$', 'once'))
                    screen= paramValue;
                end
            case {'digits', 'digit'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    digits= paramValue;
                end
            case {'brightness', 'bright'}
                if ~isempty(regexp(paramValue, '^[\w\.\+\-]+$', 'once'))
                    brightness= paramValue;
                end
            case {'buffer', 'buf'}
                if ~isempty(regexp(paramValue, '^\w+$', 'once'))
                    buffer= paramValue;
                end
            case {'text'}
                % text: equivalent settings are (case sensitive)
                % 'ABC', {'ABC'}, "ABC"                      ==> 'ABC'
                % 'ABC;abc', {'ABC', 'abc'}, ["ABC", "abc"]  ==> 'ABC;abc'
                %
                % check format and accept valid input only
                if ~isempty(regexp(paramValue, ...
                        '^(\w|\s)*((;|,|\.|%|&|/|\\|:|=|+|-|\*|\w|\s)*)*$', ...
                        'once'))
                    % text starts with [a-zA-Z_0-9] or any white space
                    % followed by characters like +-*/\:.,;%&
                    % ';' is used as delimiter ==> cannot be used in text
                    text = paramValue;
                end
            otherwise
                disp(['SMU: Warning - Parameter name ''' ...
                    paramName ''' is unknown. ' ...
                    'Ignore parameter.']);
        end
    else
        disp(['SMU: Parameter names have to be ' ...
            'character arrays. Ignore input.']);
    end
end

% -------------------------------------------------------------------------
% copy command-relevant parameters
switch command
    case 'configureSource'
        outVars = { ...
            'function'  , func       , ...
            'level'     , level      , ...
            'limit'     , limit      , ...
            'range'     , range      };
    case 'configureMeasure'
        outVars = { ...
            'function'  , func       , ...
            'range'     , range      , ...
            'nplc'      , nplc       };
    case 'outputTone'
        outVars = { ...
            'frequency' , frequency  , ...
            'duration'  , duration   };
    case 'configureDisplay'
        outVars = { ...
            'screen'    , screen     , ...
            'digits'    , digits     , ...
            'brightness', brightness , ...
            'buffer'    , buffer     , ...
            'text'      , text       };
    otherwise
        % create full list of parameter name+value pairs
        allVars = { ...
            'function'  , func       , ...
            'level'     , level      , ...
            'limit'     , limit      , ...
            'range'     , range      , ...
            'nplc'      , nplc       , ...
            'filename'  , fileName   , ...
            'frequency' , frequency  , ...
            'duration'  , duration   , ...
            'screen'    , screen     , ...
            'digits'    , digits     , ...
            'brightness', brightness , ...
            'buffer'    , buffer     , ...
            'text'      , text       };
        outVars = cell(0);
        idx = 1;
        for cnt = 1:2:length(allVars)
            if ~isempty(allVars{cnt+1})
                outVars{idx}   = allVars{cnt};
                outVars{idx+1} = allVars{cnt+1};
                idx = idx + 2;
            end
        end
end

if showmsg
    for cnt = 1 : 2 : length(outVars)
        if ~isempty(outVars{cnt+1})
            disp(['  - ' pad(outVars{cnt}, 13) ': ' ...
                lower(outVars{cnt+1})]);
        end
    end
end
end