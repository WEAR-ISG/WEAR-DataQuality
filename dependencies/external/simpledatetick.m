function simpledatetick(varargin)
%DATETICK Date formatted tick labels.
%   DATETICK(TICKAXIS,DATEFORM) annotates the specified tick axis with
%   date formatted tick labels. TICKAXIS must be one of the strings
%   'x','y', or 'z'. The default is 'x'.  The labels are formatted
%   according to the format number or string DATEFORM (see tables
%   below).  If no DATEFORM argument is entered, DATETICK makes a
%   guess based on the data for the objects within the specified axis.
%   To produce correct results, the data for the specified axis must
%   be serial date numbers (as produced by DATENUM).
%
%	Table 1: Standard MATLAB Date format definitions
%
%   DATEFORM number   DATEFORM string         Example
%   ===========================================================================
%      0             'dd-mmm-yyyy HH:MM:SS'   01-Mar-2000 15:45:17
%      1             'dd-mmm-yyyy'            01-Mar-2000
%      2             'mm/dd/yy'               03/01/00
%      3             'mmm'                    Mar
%      4             'm'                      M
%      5             'mm'                     03
%      6             'mm/dd'                  03/01
%      7             'dd'                     01
%      8             'ddd'                    Wed
%      9             'd'                      W
%     10             'yyyy'                   2000
%     11             'yy'                     00
%     12             'mmmyy'                  Mar00
%     13             'HH:MM:SS'               15:45:17
%     14             'HH:MM:SS PM'             3:45:17 PM
%     15             'HH:MM'                  15:45
%     16             'HH:MM PM'                3:45 PM
%     17             'QQ-YY'                  Q1-96
%     18             'QQ'                     Q1
%     19             'dd/mm'                  01/03
%     20             'dd/mm/yy'               01/03/00
%     21             'mmm.dd,yyyy HH:MM:SS'   Mar.01,2000 15:45:17
%     22             'mmm.dd,yyyy'            Mar.01,2000
%     23             'mm/dd/yyyy'             03/01/2000
%     24             'dd/mm/yyyy'             01/03/2000
%     25             'yy/mm/dd'               00/03/01
%     26             'yyyy/mm/dd'             2000/03/01
%     27             'QQ-YYYY'                Q1-1996
%     28             'mmmyyyy'                Mar2000
%     29 (ISO 8601)  'yyyy-mm-dd'             2000-03-01
%     30 (ISO 8601)  'yyyymmddTHHMMSS'        20000301T154517
%     31             'yyyy-mm-dd HH:MM:SS'    2000-03-01 15:45:17
%
%   Table 2: Free-form date format symbols
%
%   Symbol  Interpretation of format symbol
%   ===========================================================================
%   yyyy    full year, e.g. 1990, 2000, 2002
%   yy      partial year, e.g. 90, 00, 02
%   mmmm    full name of the month, according to the calendar locale, e.g.
%           "March", "April" in the UK and USA English locales.
%   mmm     first three letters of the month, according to the calendar
%           locale, e.g. "Mar", "Apr" in the UK and USA English locales.
%   mm      numeric month of year, padded with leading zeros, e.g. ../03/..
%           or ../12/..
%   m       capitalized first letter of the month, according to the
%           calendar locale; for backwards compatibility.
%   dddd    full name of the weekday, according to the calendar locale,
%           e.g. "Monday", "Tuesday", for the UK and USA calendar locales.
%   ddd     first three letters of the weekday, according to the calendar
%           locale, e.g. "Mon", "Tue", for the UK and USA calendar locales.
%   dd      numeric day of the month, padded with leading zeros, e.g.
%           05/../.. or 20/../..
%   d       capitalized first letter of the weekday; for backwards
%           compatibility
%   HH      hour of the day, according to the time format. In case the time
%           format AM | PM is set, HH does not pad with leading zeros. In
%           case AM | PM is not set, display the hour of the day, padded
%           with leading zeros. e.g 10:20 PM, which is equivalent to 22:20;
%           9:00 AM, which is equivalent to 09:00.
%   MM      minutes of the hour, padded with leading zeros, e.g. 10:15,
%           10:05, 10:05 AM.
%   SS      second of the minute, padded with leading zeros, e.g. 10:15:30,
%           10:05:30, 10:05:30 AM.
%   FFF     milliseconds field, padded with leading zeros, e.g.
%           10:15:30.015.
%   PM      set the time format as time of morning or time of afternoon. AM
%           or PM is appended to the date string, as appropriate.
%
%   DATETICK(...,'keeplimits') changes the tick labels into date-based
%   labels while preserving the axis limits.
%
%   DATETICK(....'keepticks') changes the tick labels into date-based labels
%   without changing their locations. Both 'keepticks' and 'keeplimits' can
%   be used at the same time.
%
%   DATETICK(AX,...) uses the specified axes, rather than the current axes.
%
%   DATETICK relies on DATESTR to convert date numbers to date strings.
%
%   Example (based on the 1990 U.S. census):
%      t = (1900:10:1990)'; % Time interval
%      p = [75.995 91.972 105.711 123.203 131.669 ...
%          150.697 179.323 203.212 226.505 249.633]';  % Population
%      plot(datenum(t,1,1),p) % Convert years to date numbers and plot
%      datetick('x','yyyy') % Replace x-axis ticks with 4 digit year labels.
%
%   See also DATESTR, DATENUM.

%   Author(s): C.F. Garvin, 4-03-95, Clay M. Thompson 1-29-96
%   Copyright 1984-2015 MathWorks, Inc.

numorigargs = find(strcmp('tz',varargin)) - 1;
if isempty(numorigargs)
    origargs = varargin;
else
    origargs = varargin(1:numorigargs);
end
[axh,nin,ax,dateform,keep_ticks,keep_limits] = parseinputs(origargs);
tzone = getNamedArg(varargin,'tz','local');


% Check to see if the date form is valid:
if nin==2
    try
        datestr(0,dateform);
    catch E
        error(message('MATLAB:datetick:UnknownDateFormat', dateform));
    end
end

% Compute data limits.
if keep_limits || isempty(get(axh,'children'))
    lim = get(axh,[ax 'lim']);
    vmin = lim(1);
    vmax = lim(2);
else
    error('MATLAB:simpledatetick:NotImplemented', 'Function not implemented in simpledatetick');
end

if ~keep_ticks
    error('MATLAB:simpledatetick:NotImplemented', 'Function not implemented in simpledatetick');
else
    %ticks = get(axh,[ax,'tick']);

    %xtl = get(axh,'XTickLabel');
    %xtlm = str2mat(xtl);
    %xtln = str2num(xtlm);
    %xe = axh.XAxis.Exponent;
    %ticks = xtln.*double(10^xe);
    ticks = get(axh,'XTick');
    ticks_dn = arrayfun(@(a)(a/86400 + 719529), ticks, 'UniformOutput', false);
    ticks_dn = cell2mat(ticks_dn);
    ticks_dn = datevec(ticks_dn);
    ticks_dn = datetime(ticks_dn, 'TimeZone', 'Etc/UTC');
    ticks_dn = datetime(ticks_dn, 'TimeZone', tzone);
    ticks_dn = datenum(ticks_dn)';

    if nin~=2
        error('MATLAB:simpledatetick:NotImplemented', 'Function not implemented in simpledatetick');
    end
end

% Set axis tick labels
labels = datestr(ticks_dn,dateform);
if keep_limits
    %set(axh,[ax,'tick'],ticks,[ax,'ticklabel'],labels)
    set(axh,'XTickLabel',labels)
else
    error('MATLAB:simpledatetick:NotImplemented', 'Function not implemented in simpledatetick');
end

end

%--------------------------------------------------
function [labels,format] = bestscale(axh,ax,xmin,xmax,dateform,dateChoice)
    error('MATLAB:simpledatetick:NotImplemented', 'Function not implemented in simpledatetick');
end

%-------------------------------------------------
function [axh,nin,ax,dateform,keep_ticks,keep_limits] = parseinputs(v)
%Parse Inputs

% Defaults;
dateform = [];
keep_ticks = 0;
keep_limits = 0;
nin = length(v);

% check to see if an axes was specified
if nin > 0 & ishandle(v{1}) & ...
  (isequal(get(v{1},'type'),'axes') | isequal(get(v{1},'type'),'colorbar')) %#ok<AND2> ishandle return is not scalar
    % use the axes passed in
    axh = v{1};
    v(1)=[];
    nin=nin-1;
else
    % use gca
    axh = gca;
end

% check for too many input arguments
if nin < 0
    error(message('MATLAB:narginchk:notEnoughInputs'));
elseif nin > 4
    error(message('MATLAB:narginchk:tooManyInputs'));
end

% check for incorrect arguments
% if the input args is more than two - it should be either
% 'keeplimits' or 'keepticks' or both.
if nin > 2
    for i = nin:-1:3
        if ~(strcmpi(v{i},'keeplimits') || strcmpi(v{i},'keepticks'))
            error(message('MATLAB:datetick:IncorrectArgs'));
        end
    end
end


% Look for 'keeplimits'
for i=nin:-1:max(1,nin-2)
    if strcmpi(v{i},'keeplimits')
        keep_limits = 1;
        v(i) = [];
        nin = nin-1;
    end
end

% Look for 'keepticks'
for i=nin:-1:max(1,nin-1)
    if strcmpi(v{i},'keepticks')
        keep_ticks = 1;
        v(i) = [];
        nin = nin-1;
    end
end

if nin==0
    ax = 'x';
else
    switch v{1}
        case {'x','y','z'}
            ax = v{1};
        otherwise
            error(message('MATLAB:datetick:InvalidAxis'));
    end
end


if nin > 1
    % The dateform (Date Format) value should be a scalar or string constant
    % check this out
    dateform = v{2};
    if (isnumeric(dateform) && length(dateform) ~= 1) && ~ischar(dateform)
        error(message('MATLAB:datetick:InvalidInput'));
    end
end

end

%---------------------------------------------------------------%
function dateChoice = localParseCustomDateForm(dateform)
    error('MATLAB:simpledatetick:NotImplemented', 'Function not implemented in simpledatetick');
end
