function allMetadata = WEAR_printResults(allMetadata,varargin)

plotting = getNamedArg(varargin, 'plot', 0);
printperc = getNamedArg(varargin, 'printperc', []);
minhours = getNamedArg(varargin, 'minhours', 0);

score_tab = getNamedArg(varargin, 'scoreTab', []);

qbo = getNamedArg(varargin, 'qualityByOnbody', 0);

TZ = getNamedArg(varargin, 'tz', 'local');

if ischar(allMetadata) || isStringScalar(allMetadata)
    allMetadata = WEAR_loadResults(allMetadata, 'strip', getNamedArg(varargin, 'strip', 1));
end

for site = fieldnames(allMetadata)'
    if isempty(score_tab)
        score_tab = WEAR_aggregateResults(allMetadata.(site{:}), 'plot', plotting, 'minhours',minhours, 'qualityByOnbody',qbo, 'tz',TZ.(site{:}));
    end
    disp(' ')
    disp(['Results for site ''' site{:} '''']);
    disp('Individual results:');
    disp(cols2perc(score_tab,printperc));
    for d = unique(score_tab.device(:))'
        overall_d = score_tab(strcmpi(score_tab.device,d),:);
        overall_n = size(overall_d,1);
        overall_mean = varfun(@mean, overall_d, 'InputVariables', @(x) ~isstring(x) && ~ischar(x));
        overall_median = varfun(@median, overall_d, 'InputVariables', @(x) ~isstring(x) && ~ischar(x));
        overall_std = varfun(@std, overall_d, 'InputVariables', @(x) ~isstring(x) && ~ischar(x));
        overall_min = varfun(@min, overall_d, 'InputVariables', @(x) ~isstring(x) && ~ischar(x));
        overall_max = varfun(@max, overall_d, 'InputVariables', @(x) ~isstring(x) && ~ischar(x));
        disp(' ')
        disp(append('Overall results for device ', d, ' (N=', num2str(overall_n), '):'));
        disp(cols2perc(tableAggConcat(overall_mean, overall_median, overall_std, overall_min, overall_max),printperc-2));
        disp(append('Total hours recorded:'));
        disp(sum(overall_d.duration_hms));
    end
    score_tab = [];
end

end

function outtab = cols2perc(intab,colix)
    if nargin < 2; colix = 1:size(intab,2); end
    outtab = intab;
    for ix = colix
        outtab.(ix) = arrayfun(@(x) string(sprintf('%.1f%%',x*100)), intab.(ix));
    end
end

