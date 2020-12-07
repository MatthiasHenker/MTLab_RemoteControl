function varargout = listAvailablePackages
% displays information about available support packages
%
% no outputs defined yet
%   - all information are displayed in command window only
%   - extend later when needed

% get name of class (where this method belongs to)
className   = mfilename('class');

% init output variables
if nargout > 0
    error([className ': Too many output arguments.']);
else
    varargout  = cell(1, nargout);
end

% run actual method to list support packages
VisaIF.listSupportedPackages(className);

end