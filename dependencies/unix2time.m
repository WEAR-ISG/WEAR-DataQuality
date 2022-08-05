function outTime = unix2time(time, varargin)
% function returns converts unix time to a numeric input vector:
% timeAsArray = [year month day hour minute second ms]

tzone = getNamedArg(varargin,'timezone|tz','local');
format = getNamedArg(varargin,'format','vector');
strformat = getNamedArg(varargin,'strfmt','yyyy-mm-dd HH:MM:SS');
numelem = getNamedArg(varargin,'numelem',7);

outTime = datetime(time, 'ConvertFrom', 'posixtime', 'TimeZone', 'Etc/UTC');
outTime = datetime(outTime, 'TimeZone', tzone);

if nargin == 2
    if isnumeric(varargin{1})
        numelem = varargin{1};
    elseif ischar(varargin{1})
        if strcmpi(varargin{1}, 'dt'); format = 'datetime';
        elseif strcmpi(varargin{1}, 's'); format = 'string'; end
    end
end

if strcmp(format, 'string')
    outTime = datestr(outTime, strformat);
elseif strcmp(format, 'vector')
    s = datevec(outTime);
    v = rem(round(time*1000),1000)';
    outTime = [s v];
    outTime = outTime(1:numelem);
end



