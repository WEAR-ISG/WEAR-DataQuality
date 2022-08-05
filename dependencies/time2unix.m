function time = time2unix(date, varargin)
%   returns the unix timestamp for a given time
%
%   date = The time to convert, either as a datetime vector or as a
%   datetime string
%
%   Options:
%       dataFromCSV(___, 'strformat', S): <'yyyy-MM-dd HH:mm:ss'>
%           String, the format that the input time is specified in.
%
%       dataFromCSV(___, 'timezone', S): <'local'>
%           String, the timezone that the input time is set in.
%


strformat = getNamedArg(varargin,'strformat','yyyy-MM-dd HH:mm:ss');
tzone = getNamedArg(varargin,'timezone|tz','local');

if ischar(date)
    date = datetime(date, 'InputFormat', strformat, 'TimeZone', tzone);
    date = datetime(date, 'TimeZone', 'Etc/UTC');
    date = datevec(date);
elseif isdatetime(date)
    date = datetime(date, 'TimeZone', tzone);
    date = datetime(date, 'TimeZone', 'Etc/UTC');
    date = datevec(date);
end

if length(date) < 6 || length(date) > 7
    error('wrong input format/size');
elseif length(date) == 6
    date = [date 0];
end

time = (datenum(date(1:end-1)) - 719529)*86400 + date(end)*0.001;
