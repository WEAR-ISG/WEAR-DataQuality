function [ ix, varargout ] = getIxByNearestUnix( start_unix, end_unix, all_unix , mode, nearix, nearix_margin)
%GETIXBYNEARESTUNIX get the indices of the nearest start and end unix timestamps
% this assumes that the stamps in all_unix are already sorted
%
%   start_unix  = The first timestamp of the interval to look for.
%   end_unix    = The second timestamp of the interval to look for. Can be the
%               same as start_unix, if you only want to look for one stamp and not an
%               interval.
%   all_unix    = The timestamps in which to search the corresponding nearest
%               stamps.
%
%   Options:
%       dataFromCSV(___, 'mode', S): <'any'>
%           String, the mode for searching the nearest timestamps. Possible
%           values are 'inner', 'outer', 'any'.
%

    %mode = getNamedArg(varargin,'mode','any');
    if nargin < 4
        mode = 'any';
    end
    if nargin < 5
        nearix = [];
    end
    if nargin < 6
        nearix_margin = 10;
    end

    if end_unix < start_unix
        end_unix = start_unix;
    end

    if start_unix == end_unix
        if ~isempty(nearix)
            [ix, val] = searchNearIX(all_unix, start_unix, nearix, nearix_margin);
        else
            [val, ix] = min(abs(all_unix - start_unix));
        end

        if nargout > 1
            varargout{1} = unix2time(val);
        end
        return;
    end

    if ~isempty(nearix)
        [start_ix, ~] = searchNearIX(all_unix, start_unix, nearix, nearix_margin);
        [end_ix, ~] = searchNearIX(all_unix, end_unix, nearix, nearix_margin);
    else
        [start_ix, end_ix] = getExactIX(all_unix, start_unix, end_unix, mode);
    end

    ix = start_ix:end_ix;

    if nargout > 1
        start_unix = all_unix(start_ix,1);
        varargout{1} = unix2time(start_unix);
        end_unix = all_unix(end_ix,1);
        varargout{2} = unix2time(end_unix);
    end
end



function [start_ix, end_ix] = getExactIX(all_unix, start_unix, end_unix, mode)
    all_start = all_unix - start_unix;
    all_end = all_unix - end_unix;
    if strcmp(mode,'inner')
        start_ix = find(all_start>=0,1,'first');
        start_ix = max([ start_ix 1 ]);
        end_ix = find(all_end<=0,1,'last');
        end_ix = max([ end_ix 1 ]);
    elseif strcmp(mode,'outer')
        start_ix = find(all_start<=0,1,'last');
        start_ix = max([ start_ix 1 ]);
        end_ix = find(all_end>=0,1,'first');
        end_ix = max([ end_ix 1 ]);
    elseif strcmp(mode,'any')
        [~, start_ix] = min(abs(all_start));
        [~, end_ix] = min(abs(all_end));
    else
        error(['Unknown mode: ' mode]);
    end
end


function [ix, val] = searchNearIX(all_unix, target_unix, nearix, nearix_margin)
    if ischar(nearix) && strcmpi(nearix,'bs')
        [nearix_start,nearix_end] = binarySearch(all_unix, target_unix, nearix_margin);
    else
        nearix_start = max([ 1, nearix - nearix_margin ]);
        nearix_end = min([ nearix + nearix_margin, numel(all_unix) ]);
    end
    all_unix_near = all_unix(nearix_start:nearix_end);
    if nearix_start > numel(all_unix) || isempty(all_unix_near)
        ix = numel(all_unix);
        val = all_unix(end);
    else
        [val,ix] = min(abs(all_unix_near - target_unix));
        ix = ix + nearix_start - 1;
    end
end


function [ix_start,ix_end] = binarySearch(values, target, margin)
    ix_start = 1;
    ix_end = numel(values);
    while values(ix_end) - values(ix_start) > margin
        m = ceil((ix_start+ix_end)/2);
        if values(m) > target
            ix_end = m-1;
        else
            ix_start = m;
        end
    end
end

