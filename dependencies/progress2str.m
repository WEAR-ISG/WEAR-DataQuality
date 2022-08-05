function progstr = progress2str(currentIndex,maxIndex,pad,escape)
%PROGRESS2STR get formatted progress string
%
% progress2str(currentIndex, maxIndex) returns formatted progress string as "[currentIndex]/[maxIndex] ([currentIndex/maxIndex*100])"
% progress2str(___, 0) returns formatted progress string, but with '0' as the padding character instead of ' '
%

if nargin > 2 && isnumeric(pad) && ~isempty(pad) && (pad == 0 || strcmp(pad,'0'))
    progstr = sprintf('%0*d/%d (%03.0f%%)', numel(num2str(maxIndex)), currentIndex, maxIndex, floor(currentIndex/maxIndex*100));
else
    progstr = sprintf('%*d/%d (%3.0f%%)', numel(num2str(maxIndex)), currentIndex, maxIndex, floor(currentIndex/maxIndex*100));
end

if nargin > 3 && escape
    progstr = strrep(progstr,'%','%%');
else

end

