function result = runMeasurement(obj, varargin)
% run measurement function using trigger model
% supported modes are: linear sweep, logarithmic sweep,
% user defined list and periodical single measurement

% start stopwatch timer to report elapsed time for method
tMeasStart = tic;

% init output
result.status       = NaN; %
result.length       = NaN; % number of meas. values   (double)
result.senseValues  = NaN; % actual measurement value (double)
result.senseUnit    = '';  % corresponding unit       (char)
result.sourceValues = NaN; % source (readback) value  (double)
result.sourceUnit   = '';  % corresponding unit       (char)
result.timestamps   = NaT; % time stamp               (datetime)
result.elapsedTime  = NaN; % total time (in s)        (double)

if ~strcmpi(obj.ShowMessages, 'none')
    disp([obj.DeviceName ':']);
    disp('  request measurement value(s)');
    params = obj.checkParams(varargin, 'runMeasurement', true);
else
    params = obj.checkParams(varargin, 'runMeasurement');
end

% initialize all supported (input) parameters
timeout   = []; % double : for all modes
mode      = ''; % char   : main selector
count     = []; % double (integer): number meas. or sweep runs
list      = []; % vector of double
points    = []; % double (integer)
start     = []; % double
stop      = []; % double
dual      = []; % logical: for lin/logSweep
delay     = []; % double : -1 = auto, 0 = off, 0..1 = delay
rangetype = ''; % char   : for lin/logSweep
failabort = []; % logical: for lin/log/listSweep
asymptote = []; % double: for logSweep through zero
%
timeoutDefault   = 10;  % 80 s for NPLC = 10 & Averaging = 100
modeDefault      = 'simple';
countDefault     = 1;   % single run
%listDefault      = [];
pointsDefault    = 31;
%startDefault     = [];
%stopDefault      = [];
dualDefault      = 1;   % yes
delayDefault     = -1;  % auto delay
rangetypeDefault = 'best';
failabortDefault = 0;   % off: continue if source limit is exceeded
asymptoteDefault = 0;   % for log sweep when not sweeping through zero

senseMode  = obj.SenseMode;
sourceMode = obj.SourceMode;
switch sourceMode
    case 'current'
        minValue = -1.05;
        maxValue =  1.05;
    case 'voltage'
        minValue = -210;
        maxValue =  210;
    otherwise
        minValue = 0;
        maxValue = 0;
end

% check input: loop over all input parameters
for idx = 1:2:length(params)
    paramName  = params{idx};
    paramValue = params{idx+1};
    switch paramName
        case 'timeout'
            coerced = false;
            if ~isempty(paramValue)
                timeout = str2double(paramValue);
                if isnan(timeout)
                    coerced = true;
                    timeout = timeoutDefault;
                else
                    timeoutNew = min(timeout, 1e3); % max 1000 s
                    timeoutNew = max(timeoutNew, 1);% min 1 s
                    if timeoutNew ~= timeout
                        coerced = true;
                    end
                    timeout = timeoutNew;
                end
            else
                timeout = timeoutDefault;
                coerced = true;
            end
            if ~strcmpi(obj.ShowMessages, 'none') && coerced
                disp(['  - timeout      : ' ...
                    num2str(timeout, '%g') ' (coerced)']);
            end
        case 'mode'
            coerced = false;
            if ~isempty(paramValue)
                mode    = lower(paramValue);
                switch mode
                    case {'linsweep', 'lin'}
                        mode    = 'lin';
                    case {'logsweep', 'log'}
                        mode    = 'log';
                    case {'listsweep', 'list'}
                        mode    = 'list';
                    case {'simple'}
                        mode    = 'simple';
                    otherwise
                        mode    = modeDefault;
                        coerced = true;
                end
            else
                mode    = modeDefault;
                coerced = true;
            end
            if ~strcmpi(obj.ShowMessages, 'none') && coerced
                disp(['  - mode         : ' mode ...
                    ' (coerced)']);
            end
        case 'count'
            coerced = false;
            if ~isempty(paramValue)
                count   = str2double(paramValue);
                if isnan(count)
                    coerced = true;
                    count   = countDefault;
                else
                    % limit due to max timeout setting
                    countNew = round(count);
                    countNew = min(countNew, 1e3); % more ?
                    countNew = max(countNew, 1);
                    if countNew ~= count
                        coerced = true;
                    end
                    count = countNew;
                end
            else
                count   = countDefault;
                coerced = true;
            end
            if ~strcmpi(obj.ShowMessages, 'none') && coerced
                disp(['  - count        : ' ...
                    num2str(count, '%g') ' (coerced)']);
            end
        case 'list'
            if ~isempty(paramValue)
                coerced = false;
                list    = str2double(split(paramValue, ','))';
                listNew = real(list); % remove imaginary part
                if isnan(list)
                    coerced = true;
                    list    = [];
                else
                    % limit due to max timeout setting
                    listNew = min(listNew, maxValue);
                    listNew = max(listNew, minValue);
                    if any(listNew ~= list)
                        coerced = true;
                    end
                    list = listNew;
                end
                if ~strcmpi(obj.ShowMessages, 'none') && coerced
                    if isempty(list)
                        disp('  - list         : [] (coerced)');
                    else
                        disp(['  - list         : [' ...
                            num2str(list(1), '%g') ' ... ' ...
                            num2str(list(end), '%g') ...
                            '] (coerced)']);
                    end
                end
            end
        case 'points'
            if ~isempty(paramValue)
                coerced = false;
                points  = str2double(paramValue);
                if isnan(points)
                    coerced = true;
                    points  = pointsDefault;
                else
                    % limit due to max timeout setting
                    pointsNew = round(points);
                    pointsNew = min(pointsNew, 1e4); % more ?
                    pointsNew = max(pointsNew, 2);
                    if pointsNew ~= points
                        coerced = true;
                    end
                    points = pointsNew;
                end
                if ~strcmpi(obj.ShowMessages, 'none') ...
                        && coerced && (strcmpi(mode, 'lin') ...
                        || strcmpi(mode, 'log'))
                    disp(['  - points       : ' ...
                        num2str(points, '%g') ' (coerced)']);
                end
            else
                points = pointsDefault;
            end
        case 'start'
            if ~isempty(paramValue)
                coerced = false;
                start   = str2double(paramValue);
                if isnan(start)
                    coerced = true;
                    start   = [];
                else
                    % limit to max range
                    startNew = min(start   , maxValue);
                    startNew = max(startNew, minValue);
                    if startNew ~= start
                        coerced = true;
                    end
                    start = startNew;
                end
                if ~strcmpi(obj.ShowMessages, 'none') ...
                        && coerced && (strcmpi(mode, 'lin') ...
                        || strcmpi(mode, 'log'))
                    disp(['  - start        : ' ...
                        num2str(start, '%g') ' (coerced)']);
                end
            end
        case 'stop'
            if ~isempty(paramValue)
                coerced = false;
                stop    = str2double(paramValue);
                if isnan(stop)
                    coerced = true;
                    stop    = [];
                else
                    % limit to max range
                    stopNew = min(stop   , maxValue);
                    stopNew = max(stopNew, minValue);
                    if stopNew ~= stop
                        coerced = true;
                    end
                    stop = stopNew;
                end
                if ~strcmpi(obj.ShowMessages, 'none') ...
                        && coerced && (strcmpi(mode, 'lin') ...
                        || strcmpi(mode, 'log'))
                    disp(['  - stop         : ' ...
                        num2str(stop, '%g') ' (coerced)']);
                end
            end
        case 'dual'
            coerced = false;
            if ~isempty(paramValue)
                % check input argument
                dual = str2double(paramValue);
                if isnan(dual)
                    if strcmpi('yes', paramValue) || ...
                            strcmpi('on', paramValue)
                        dual = 1;
                    elseif strcmpi('no', paramValue) || ...
                            strcmpi('off', paramValue)
                        dual = 0;
                    else
                        dual    = dualDefault;
                        coerced = true;
                    end
                else
                    dualNew = double(logical(dual));
                    if dualNew ~= dual
                        coerced = true;
                    end
                    dual = dualNew;
                end
            else
                dual    = dualDefault;
                coerced = true;
            end
            if ~strcmpi(obj.ShowMessages, 'none') ...
                    && coerced && (strcmpi(mode, 'lin') ...
                    || strcmpi(mode, 'log'))
                disp(['  - dual         : ' ...
                    num2str(dual, '%g') ' (coerced)']);
            end
        case 'delay'
            coerced = false;
            if ~isempty(paramValue)
                delay  = str2double(paramValue);
                if isnan(delay)
                    delay   = delayDefault;
                    coerced = true;
                else
                    % limit to sensible values
                    delayNew = min(delay,  1); % more than 1s?
                    if delayNew < 0
                        delayNew = -1; % auto delay
                    elseif delayNew == 0
                        % ok: no delay
                    else
                        if strcmpi(mode, 'simple')
                            minDelay = 167e-9; % 167 ns
                        else
                            minDelay = 50e-6; % 50 us
                        end
                        delayNew = max(delayNew,  minDelay);
                    end
                    if delayNew ~= delay
                        coerced = true;
                    end
                    delay = delayNew;
                end
            else
                delay   = delayDefault;
                coerced = true;
            end
            if (strcmpi(mode, 'simple') || strcmpi(mode, 'list')) ...
                    && delay < 0
                delay   = 0; % no auto delay
                coerced = true;
            end
            if ~strcmpi(obj.ShowMessages, 'none') && coerced
                disp(['  - delay        : ' ...
                    num2str(delay, '%g') ' (coerced)']);
            end
        case 'rangetype'
            if ~isempty(paramValue)
                coerced   = false;
                rangetype = lower(paramValue);
                switch rangetype
                    case 'auto'
                        rangetype = 'auto';
                    case 'best'
                        rangetype = 'best';
                    case {'fixed', 'fix'}
                        rangetype = 'fixed';
                    otherwise
                        rangetype = rangetypeDefault;
                        coerced   = true;
                end
                if ~strcmpi(obj.ShowMessages, 'none') ...
                        && coerced && (strcmpi(mode, 'lin') ...
                        || strcmpi(mode, 'log'))
                    disp(['  - rangetype    : ' rangetype ...
                        ' (coerced)']);
                end
            else
                rangetype = rangetypeDefault;
            end
        case 'failabort'
            coerced = false;
            if ~isempty(paramValue)
                % check input argument
                failabort = str2double(paramValue);
                if isnan(failabort)
                    if strcmpi('yes', paramValue) || ...
                            strcmpi('on', paramValue)
                        failabort = 1;
                    elseif strcmpi('no', paramValue) || ...
                            strcmpi('off', paramValue)
                        failabort = 0;
                    else
                        failabort = failabortDefault;
                        coerced   = true;
                    end
                else
                    failabortNew = double(logical(failabort));
                    if failabortNew ~= failabort
                        coerced = true;
                    end
                    failabort = failabortNew;
                end
            else
                failabort = failabortDefault;
                coerced   = true;
            end
            if ~strcmpi(obj.ShowMessages, 'none') ...
                    && coerced && ~strcmpi(mode, 'simple')
                disp(['  - failabort    : ' ...
                    num2str(failabort, '%g') ' (coerced)']);
            end
        case 'asymptote'
            coerced = false;
            if ~isempty(paramValue)
                asymptote = str2double(paramValue);
                if isnan(asymptote)
                    asymptote = asymptoteDefault;
                    coerced   = true;
                else
                    % it is any number
                    %
                end
            else
                asymptote = asymptoteDefault;
                coerced   = true;
            end
            if ~strcmpi(obj.ShowMessages, 'none') ...
                    && coerced && strcmpi(mode, 'log')
                disp(['  - asymptote    : ' ...
                    num2str(asymptote, '%g') ' (coerced)']);
            end
        otherwise
            if ~isempty(paramValue)
                disp(['SMU24xx Warning - ''runMeasurement'' ' ...
                    'parameter ''' paramName ''' is ' ...
                    'unknown --> ignore and continue']);
            end
    end
end

% mandatory parameters missing?
allFine = true;
if isempty(list) && strcmpi(mode, 'list')
    allFine = false;
    if ~strcmpi(obj.ShowMessages, 'none')
        disp('  parameter ''list'' is missing ==> exit');
    end
end
if isempty(start) && (strcmpi(mode, 'lin') || strcmpi(mode, 'log'))
    allFine = false;
    if ~strcmpi(obj.ShowMessages, 'none')
        disp('  parameter ''start'' is missing ==> exit');
    end
end
if isempty(stop) && (strcmpi(mode, 'lin') || strcmpi(mode, 'log'))
    allFine = false;
    if ~strcmpi(obj.ShowMessages, 'none')
        disp('  parameter ''stop'' is missing ==> exit');
    end
end

% invalid parameters?
if allFine && strcmpi(mode, 'log')
    % start and stop are not empty
    if (min(start, stop) <= asymptote) && (asymptote <= max(start, stop))
        allFine = false;
        if ~strcmpi(obj.ShowMessages, 'none')
            disp(['  parameter ''asymptote'' has to be outside the ' ...
                'log sweep range ==> exit']);
        end
    end
end

% exit when mandatory parameters are missing
if ~allFine
    result.status = 1;
    if ~strcmpi(obj.ShowMessages, 'none')
        disp(['  .status     : Error with code = ' ...
            num2str(result.status) ]);
    end
    return
end

% -------------------------------------------------------------
% actual code
% -------------------------------------------------------------
activeBuffer = obj.ActiveBuffer;

% 1st step: setup trigger model (lin, log, list, simple)
switch mode
    case 'simple'
        if obj.write([':Trigger:Load "SimpleLoop", ' ...
                num2str(count)     ', ' ...
                num2str(delay)     ', ' ...
                '"' activeBuffer   '"'])
            result.status = -5;
            return
        end
    case 'lin'
        if obj.write([':Source:Sweep:' sourceMode ':' mode ' ' ...
                num2str(start)     ', ' ...
                num2str(stop)      ', ' ...
                num2str(points)    ', ' ...
                num2str(delay)     ', ' ...
                num2str(count)     ', ' ...
                rangetype          ', ' ...
                num2str(failabort) ', ' ...
                num2str(dual)      ', ' ...
                '"' activeBuffer   '"'])
            result.status = -5;
            return
        end
    case 'log'
        if obj.write([':Source:Sweep:' sourceMode ':' mode ' ' ...
                num2str(start)     ', ' ...
                num2str(stop)      ', ' ...
                num2str(points)    ', ' ...
                num2str(delay)     ', ' ...
                num2str(count)     ', ' ...
                rangetype          ', ' ...
                num2str(failabort) ', ' ...
                num2str(dual)      ', ' ...
                '"' activeBuffer  '", ' ...
                num2str(asymptote) ])
            result.status = -5;
            return
        end
    case 'list'
        % upload source list before defining trigger model
        % theoretically data chunks of size 100 are possible
        % input buffer overrun can happen ==> slow down
        lengthTarget = length(list);
        chunkLength  = 50;
        firstLoopRun = true;

        while ~isempty(list)
            % extract chunk of data
            if length(list) <= chunkLength
                listChunk = list(1:end);
                list      = [];
            else
                listChunk = list(1 : chunkLength);
                list      = list(chunkLength+1 : end);
            end
            % upload chunk of data
            if firstLoopRun
                cmdMode      = ' ';
                firstLoopRun = false;
            else
                cmdMode      = ':Append ';
            end
            if obj.write([':Source:List:' sourceMode cmdMode ...
                    regexprep(num2str(listChunk, 10), '\s+', ', ')])
                result.status = -2;
            end
            % slow down
            pause(0.1);
        end

        % check length of uploaded data
        response = obj.query([':Source:List:' sourceMode ...
            ':Points?']);
        lengthActual = str2double(char(response));
        if lengthTarget ~= lengthActual
            result.status = -3;
            return
        end

        % finally define trigger model
        if obj.write([':Source:Sweep:' sourceMode ':List ' ...
                num2str(1)         ', ' ...
                num2str(delay)     ', ' ...
                num2str(count)     ', ' ...
                num2str(failabort) ', ' ...
                '"' activeBuffer   '"'])
            result.status = -5;
            return
        end
    otherwise
        % impossible state ==> exit method
        return
end

% check trigger state
obj.opc;
if ~strcmpi(obj.TriggerState, 'building')
    result.status = -7;
    return
end

% save output state, enable output and start trigger model
if obj.OutputState ~= 1
    obj.OutputState         = 'on';
    disableOutputAtEndAgain = true;
else
    disableOutputAtEndAgain = false;
end
if obj.write(':Initiate')
    result.status = -8;
end

% check trigger state: running or idle (ready)
for cnt = 1 : ceil(timeout)
    % assumption: one loop takes about one second
    if ~strcmpi(obj.ShowMessages, 'none')
        disp(['Measurement started. Check trigger State: ' ...
            pad(num2str(cnt), 3, 'left') ...
            ' / ' num2str(ceil(timeout))]);
    end
    switch obj.TriggerState
        case 'idle'
            break;
        case 'running'
            pause(0.99);
        otherwise
            result.status = -10;
            return
    end
end

% abort trigger when not ready (timeout)
if ~strcmpi(obj.TriggerState, 'idle')
    obj.abortTrigger;
end

% optionally disable output again
if disableOutputAtEndAgain
    obj.OutputState         = 'off';
end

% data available?
traceStart = str2double(char(obj.query(':Trace:Actual:Start?')));
traceEnd   = str2double(char(obj.query(':Trace:Actual:End?')));
dataLength = traceEnd - traceStart + 1;

if traceStart >= 1 && traceEnd >= 1
    % fine
    if ~strcmpi(obj.ShowMessages, 'none')
        disp(['  Data available: download ' ...
            num2str(dataLength) ...
            ' measurement values']);
    end
else
    result.status = 5;
    if ~strcmpi(obj.ShowMessages, 'none')
        disp(['  No data available. Exit runMeasurement ' ...
            'method']);
    end
    return
end

if isnan(result.status)
    % all fine: download data
    response     = obj.query([':Trace:Data? ' ...
        num2str(traceStart) ', ' num2str(traceEnd) ', "' ...
        activeBuffer '", reading, unit, source, sourunit, tstamp']);
    tmpResult    = split(char(response), ',');
    % check right number of received values
    if size(tmpResult, 1) == 5*dataLength && ...
            size(tmpResult, 2) == 1
        tmpResult = reshape(tmpResult, 5, dataLength);
        result.length = dataLength;
        % convert numerical values
        result.senseValues  = str2double(tmpResult(1, :));
        result.sourceValues = str2double(tmpResult(3, :));
        % check units (are identical?)
        if all(strcmpi(tmpResult{2, 1}, tmpResult(2, :)))
            result.senseUnit   = tmpResult{2, 1};
        else
            result.status = -7;
        end
        if all(strcmpi(tmpResult{4, 1}, tmpResult(4, :)))
            result.sourceUnit   = tmpResult{4, 1};
        else
            result.status = -8;
        end
        % remap units
        switch lower(result.senseUnit)
            case 'amp dc' , result.senseUnit  = 'A';
            case 'volt dc', result.senseUnit  = 'V';
            case 'ohm'    , result.senseUnit  = 'Ohm';
            case 'watt dc', result.senseUnit  = 'W';
        end
        switch lower(result.sourceUnit)
            case 'amp dc' , result.sourceUnit = 'A';
            case 'volt dc', result.sourceUnit = 'V';
        end
        % conversion of response to type datetime can fail
        try
            result.timestamps = datetime(tmpResult(5, :));
        catch
            warning(['SMU24xx (runMeasurement): Could not ' ...
                'recognize the format of the timestamps.']);
            result.timestamps = NaT;
            result.status     = -9;
        end
    else
        result.status = -6;
    end
end

% detect overflow values
result.senseValues(result.senseValues >  1e10)   = NaN;
result.senseValues(result.senseValues < -1e10)   = NaN;
result.sourceValues(result.sourceValues >  1e10) = NaN;
result.sourceValues(result.sourceValues < -1e10) = NaN;

% set final status
if isnan(result.status)
    % no error so far ==> set to 0 (fine)
    result.status = 0;
end

% stop timer
result.elapsedTime = toc(tMeasStart);

% optionally display results
if ~strcmpi(obj.ShowMessages, 'none')
    if result.status ~= 0
        disp(['  .status     : Error with code = ' ...
            num2str(result.status) ]);
    else
        disp(['  Number of values : ' num2str(result.length)]);
        disp(['  Sense  (' senseMode ') : ' ...
            num2str(result.senseValues(end)) ' ' ...
            result.senseUnit]);
        disp(['  Source (' sourceMode ') : ' ...
            num2str(result.sourceValues(end)) ' ' ...
            result.sourceUnit]);
        disp(['  Timestamp        : ' ...
            char(result.timestamps(end))]);
        disp(['  Elapsed time     : ' ...
            num2str(result.elapsedTime) ' s']);
    end
end

end
