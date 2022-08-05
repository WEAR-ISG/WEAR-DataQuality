function filesRanked = getFilesSorted( inputFolder, regexWildcard , varargin )
%GETFILESSORTED Return a list of files of a certain type, sorted by the
%   date in the filenames.
%
%   inputFolder = Absolute path to the folder containing the files to be processed.
%   regexWildcard = RegEx filter for files to be returned.
%       E.g. '*.csv' to get only CSV files, or '*' to get all files.
%
%   Options:
%       getFilesSorted(___, 'start', S, 'end', E): <0, 0>
%           Only get the files relevant to read the data between S and E,
%           as unix timestamps.
%


% get start and end times as unix stamps
start_time = getNamedArg(varargin,'start',0);
end_time = getNamedArg(varargin,'end',0);

dInputInfo = dir(fullfile(inputFolder,'*.*'));
ind = 1;
for K = 1:length(dInputInfo)
    if regexp(dInputInfo(K).name, [regexptranslate('wildcard', regexWildcard) '$'])
        thisfile = dInputInfo(K).name;
        year = str2num(thisfile(1:4));
        month = str2num(thisfile(5:6));
        day = str2num(thisfile(7:8));
        hour = str2num(thisfile(10:11));

        if start_time > 0 && end_time > start_time
            hstart = time2unix([year,month,day,hour,0,0,0]);
            hend = hstart + 3600; %time2unix([year,month,day,hour+1,0,0,0]);
            if hend < start_time || hstart > end_time
                continue;
            end
        end

        file{ind} = thisfile;
        fileInd(ind) = hour + day*24 + month*24*31 + year*24*31*12;
        ind = ind + 1;
    end
end

if ~exist('file','var') || isempty(file)
    filesRanked = [];
else
    [~, ind_sorted] = sort(fileInd);
    filesRanked = file(ind_sorted);
end

end

