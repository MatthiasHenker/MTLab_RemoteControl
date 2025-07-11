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
            disp(['SMU: Invalid type of ''' paramName '''. ' ...
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
            'function' , func, ...
            'level'    , level, ...
            'limit'    , limit, ...
            'range'    , range };
    case 'configureMeasure'
        outVars = { ...
            'function' , func, ...
            'range'    , range, ...
            'nplc'     , nplc };
    otherwise
        % create full list of parameter name+value pairs
        allVars = { ...
            'function' , func, ...
            'level'    , level, ...
            'limit'    , limit, ...
            'range'    , range, ...
            'nplc'     , nplc , ...
            'filename' , fileName};
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
                outVars{cnt+1}]);
        end
    end
end
end