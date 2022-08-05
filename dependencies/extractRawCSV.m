function extractRawCSV( indir, varargin )
%EXTRACTRAWCSV extracts gzipped (*.csv.gz) files from the RADAR platform

outdir = getNamedArg(varargin,'outdir','');
start_time = getNamedArg(varargin,'start',0);
end_time = getNamedArg(varargin,'end',0);
force = getNamedArg(varargin,'force',0);

if ~isempty(outdir) && ~strcmp(outdir(1), '/')
    outdir = [indir filesep outdir];
end

% compare zipped and unzipped files, get set difference to only extract
% files that do not exist yet
filesRankedZipped = getFilesSorted(indir, '*.csv.gz', 'start', start_time, 'end', end_time);
filesRankedRaw = getFilesSorted(outdir, '*.csv', 'start', start_time, 'end', end_time);

if isempty(filesRankedZipped)
    return;
end

% remove relevant extracted files if force flag is set
if force
    disp(['Extraction forced, deleting ' num2str(length(filesRankedRaw)) ' files already extracted...']);
    for fix = 1:length(filesRankedRaw)
        thisfile = [ outdir filesep filesRankedRaw{fix} ];
        if isfile(thisfile)
            delete(thisfile);
        end
    end
    filesRankedRaw = getFilesSorted(outdir, '*.csv', 'start', start_time, 'end', end_time);
end

% get set diff
[~,filesRankedCompare,~] = cellfun(@fileparts, filesRankedZipped, 'UniformOutput', 0);
filesRanked = setdiff(filesRankedCompare, filesRankedRaw);

% nothing to do
if isempty(filesRanked)
    return;
end



% extract
if ~isempty(filesRanked)
    %disp(['Extracting ' num2str(length(filesRanked)) ' gzipped files...']);
    fprintf(['[' datestr(datetime) '] Extracting ' num2str(length(filesRanked)) ' gzipped files... %03d%%'], 0);
    perclast = 0;
    for fix = 1:length(filesRanked)
        filename = [indir filesep filesRanked{fix} '.gz'];
        %disp(['Extracting (' num2str(fix) '/' num2str(length(filesRanked)) '): ' filename]);
        perclast = print_perc(fix, length(filesRanked), perclast);
        gunzip(filename, outdir);
    end
    fprintf('\n');
end


end


function perclast = print_perc(cur,tot,perclast)
    perc = round(cur*100/tot);
    if perc ~= perclast
        fprintf('\b\b\b\b');
        fprintf('%03d%%', perc);
    end
    perclast = perc;
end

