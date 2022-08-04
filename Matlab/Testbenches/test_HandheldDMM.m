% test_HandheldDMM.m

clear variables;
close all;
clc;

if isempty(which('HandheldDMM'))
    addpath('..\Modules\HandheldDMM');
end

% -------------------------------------------------------------------------
% display versions
disp(['Version of HandheldDMM       : ' ...
    HandheldDMM.Version ' (' HandheldDMM.Date ')']);
disp(' ');

% -------------------------------------------------------------------------
HandheldDMMName = 'VC820';       % Voltcraft
%HandheldDMMName = 'VC830';       % Voltcraft
%HandheldDMMName = 'UT61E';        % Uni-T

% demo mode or with real hardware?
%port = 'demo';
port = 'COM5';
%port = 'COM7';
%port = '';

showmsg   = true;
%showmsg   = 0;

% -------------------------------------------------------------------------
% print out some information
HandheldDMM.listSerialPorts(showmsg);
HandheldDMM.listSupportedPackages(showmsg);

myDMM   = HandheldDMM(HandheldDMMName, port, showmsg);

myDMM.connect;
myDMM.read;
% ...             % possibly change measurement setup
myDMM.flush;      % empty queue
myDMM.read;       % read new data (old data were removed by flush)

% define range
numValues = 30;
time      = (0:numValues-1) * myDMM.SamplePeriod;
values    = zeros(size(time));

for cnt = 1:length(time)
    [values(cnt), mode, status] = myDMM.read;
    if status
        break
    end
end

figure(1);
plot(time, values, '*b-');
title(['DMM mode: ' mode]);
grid on;

% ...
myDMM.disconnect;
myDMM.delete;
% end of file