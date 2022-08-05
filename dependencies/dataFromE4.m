function data = dataFromE4(indir, varargin)

modalities = getNamedArg(varargin, 'modalities', ["ACC", "EDA", "BVP", "TEMP"]);
remove_extracted = getNamedArg(varargin, 'clean', 1);

% extract data if necessary
if isfolder(indir)
    remove_extracted = 0; % never remove already extracted data
elseif isfile(append(indir, '.zip'))
    unzip(append(indir, '.zip'), indir);
else
    warning(['[' datestr(datetime) '] No E4 data could be read from path ''' indir '''!'])
    data = [];
    return;
end


for m = modalities
    %disp(append('[', datestr(datetime), '] ', 'Read E4-EMPA data: ', m));
    inpath = append(indir, filesep, m, '.csv');
    if ~isfile(inpath)
        warning(['[' datestr(datetime) '] E4 ' char(m) ' data is missing from path ''' indir '''!'])
        continue;
    end

    % read header
    header = readmatrix(inpath,'Range','1:2');
    stamp = unique(header(1,:));
    fs = unique(header(2,:));
    if numel(stamp) > 1 || numel(fs) > 1; error(append("Error while reading E4 data: unexpected header data (",m,")")); end

    % read data
    mdata = readmatrix(inpath,'NumHeaderLines',2);

    % data conversion
    if strcmp(m,'ACC')
        mdata = mdata/64;
    end

    % create unix timestamps and save data
    stamps = linspace(stamp,stamp+size(mdata,1)/fs,size(mdata,1));
    data.(m) = [stamps' mdata];
end

% read tags
inpath = append(indir, filesep, 'tags.csv');
mdata = readmatrix(inpath);
data.tags = mdata;


% clean up extracted data
if remove_extracted
    rmdir(indir, 's');
end

end

