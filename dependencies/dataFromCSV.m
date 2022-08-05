function [key, data, header] = dataFromCSV( inputFolder, varargin )
%DATAFROMCSV read data from raw CSV files
%
%   inputFolder = Absolute path to the folder containing the files to be processed.
%
%   Options:
%       dataFromCSV(___, 'infiles', F): <[]>
%           Cellarray with filenames of all the files to be read. Default
%           is to read all files with the .csv fileext in the input folder.
%           If a real number is specified, the first F files in the
%           directory are read.
%
%       dataFromCSV(___, 'parallel', P): <1>
%           Boolean, default is to read files using parfor if possible.
%
%       dataFromCSV(___, 'process', P): <1>
%           Boolean, default is to sort and deduplicate data by device timestamps.
%
%       dataFromCSV(___, 'method', M): <'datastore'>
%           String, specify the read method, one of [readtable, textscan, datastore].
%

infiles = getNamedArg(varargin,'infiles',[]);
extract = getNamedArg(varargin,'extract',0);
parallel = getNamedArg(varargin,'parallel',1);
process = getNamedArg(varargin,'process',1);
method = getNamedArg(varargin,'method','datastore');
q = getNamedArg(varargin,'q',0);

data = [];
key = [];
header = [];

if isstring(inputFolder); inputFolder = strjoin(inputFolder,''); end
if ~ischar(inputFolder); inputFolder = char(inputFolder); end

% extract
if extract
    extractRawCSV(inputFolder, 'outdir', 'extracted');
    inputFolder = [inputFolder filesep 'extracted'];
end

filesRankedIn = getFilesSorted(inputFolder, '*.csv');
if isnumeric(infiles) && length(infiles) == 1
    filesRankedIn = filesRankedIn(1:infiles);
elseif isnumeric(infiles) && length(infiles) > 1
    filesRankedIn = filesRankedIn(infiles);
elseif ~isempty(infiles)
    filesRankedIn = infiles;
end

filesRanked = {};
% filter nonexisting files
for i = 1:length(filesRankedIn)
    if exist([inputFolder filesep filesRankedIn{i}], 'file') == 2
        filesRanked{end+1} = filesRankedIn{i};
    end
end

nFiles = length(filesRanked);

if nFiles < 1
    return;
end

iFile = 1;
paths = {};
while iFile <= nFiles
    file = filesRanked{iFile};

    if strcmp(method, 'readtable')
        [key_new, data_new, header] = read_readtable([inputFolder filesep file], q);
    elseif strcmp(method, 'textscan')
        [key_new, data_new, header] = read_textscan([inputFolder filesep file], parallel, q);
    elseif strcmp(method, 'datastore')
        paths{end+1} = [inputFolder filesep file];
        iFile = iFile + 1;
        continue;
    else
        error('method argument must be one of [readtable, textscan, datastore]');
    end

    data = [data; data_new];
    key = vertcat(key, key_new);

    iFile = iFile + 1;
end

if strcmp(method, 'datastore')
    [key, data, header] = read_datastore(paths', q);
end

if process
    % sort data by device timestamp
    time = data(:,1);
    [~,r] = sort(time);
    data = data(r,:);
    key = key(r,:);

    % deduplicate by device timestamps
    time = data(:,1)';
    steps = [1 diff(time)];
    data = data(steps ~= 0,:);
    key = key(steps ~= 0,:);
end

% remove extracted data
if extract && endsWith(inputFolder, 'extracted')
    rmdir(inputFolder, 's');
end

end



%% read with textscan()

function [key_new, data_new, header] = read_textscan(filename, parallel, q)
    if ~q; disp(['[' datestr(datetime) '] ' 'CSV (textscan): reading file ' filename]); end

    % open and read csv file
    fileID = fopen(filename, 'r');
    markerFields = textscan(fileID, '%s', 'Delimiter', '\n');
    fclose(fileID);

    % get header
    header = markerFields{1}{1};
    header = regexp(header, ',', 'split');

    % make new Data object
    fieldSize = length(markerFields{1}) - 1;
    dataSize = length(header) - getIndex(header,'value.time',1) + 1;
    data_new = zeros(fieldSize, dataSize);
    key_new = {};

    % fill in data
    if parallel
        parfor fieldIndex = 1 : fieldSize
            stringMarker = markerFields{1}{fieldIndex + 1};
            stringMarker = regexp(stringMarker, ',', 'split');
            data_new(fieldIndex, :) = str2double(stringMarker(getIndex(header,'value.time'):end));
            key_new = vertcat(key_new, stringMarker(1:getIndex(header,'value.time')-1));
        end
    else
        for fieldIndex = 1 : fieldSize
            stringMarker = markerFields{1}{fieldIndex + 1};
            stringMarker = regexp(stringMarker, ',', 'split');
            data_new(fieldIndex, :) = str2double(stringMarker(getIndex(header,'value.time'):end));
            key_new = vertcat(key_new, stringMarker(1:getIndex(header,'value.time')-1));
        end
    end
end


%% read with readtable()

function [key_new, data_new, header] = read_readtable(filename, q)
    if ~q; disp(['[' datestr(datetime) '] ' 'CSV (readtable): reading file ' filename]); end

    warning ('off','MATLAB:table:ModifiedVarnames');
    T = readtable(filename,'Delimiter',',');
    header = T.Properties.VariableNames;
    warning ('on','MATLAB:table:ModifiedVarnames');

    idx_time = 4;
    % backwards compatibility with older data which does not have projectId
    if strcmp(header{1},'key_userId')
        idx_time = 3;
    end

    data_new = table2array(T(:,idx_time:end));
    key_new = table2cell(T(:,1:idx_time-1));
end


%% read with datastore()

function [key_new, data_new, header] = read_datastore(files, q)
    if ~q; disp(['[' datestr(datetime) '] ' 'CSV (datastore): reading ' num2str(length(files)) ' files']); end

    warning ('off','MATLAB:table:ModifiedVarnames');
    ds = datastore(files, 'Type', 'tabulartext', 'FileExtensions', '.csv');
    ds.ReadSize = 'file';
    ds.Delimiter = ',';
    T = readall(ds);
    header = T.Properties.VariableNames;
    warning ('on','MATLAB:table:ModifiedVarnames');

    idx_time = 4;
    % backwards compatibility with older data which does not have projectId
    if ~strcmp(header{1},'key_projectId')
        idx_time = 3;
    end

    % remove non-numeric table variables, TODO: make this work without removing them (split off as categoricals?)
    nonnumeric = {};
    for col = T(:,idx_time:end).Properties.VariableNames
        if iscell(T.(col{:}))
            nonnumeric{end+1} = col{:};
        end
    end
    T = removevars(T, nonnumeric);

    data_new = table2array(T(:,idx_time:end));
    key_new = table2cell(T(:,1:idx_time-1));
end


