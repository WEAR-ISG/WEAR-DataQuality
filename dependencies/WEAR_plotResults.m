function allMetadata = WEAR_plotResults(allMetadata,varargin)

colormap = [
    [0 0.4470 0.7410];
    [0.8500 0.3250 0.0980];
    [0.9290 0.6940 0.1250];
    [0.4940 0.1840 0.5560];
    [0.4660 0.6740 0.1880];
    [0 0 0]; % legend marker color
    ];

markers = getNamedArg(varargin, 'markers', {'o','+','*','^'});

printperc = getNamedArg(varargin, 'printperc', []);
minhours = getNamedArg(varargin, 'minhours', 0);

plotSeparate = getNamedArg(varargin, 'plotSeparate', 0);
score_tab = getNamedArg(varargin, 'scoreTab', []);

qbo = getNamedArg(varargin, 'qualityByOnbody', 0);

TZ = getNamedArg(varargin, 'tz', 'local');

suffix = getNamedArg(varargin, 'suffix', '');
if ~isempty(suffix); suffix = ['-' suffix]; end

if ischar(allMetadata) || isStringScalar(allMetadata)
    allMetadata = WEAR_loadResults(allMetadata, 'strip', getNamedArg(varargin, 'strip', 1));
end

legendnames = getNamedArg(varargin, 'legendnames', fieldnames(allMetadata));

outdir = getNamedArg(varargin, 'outdir', '');
if ~isempty(outdir) && ~strcmp(outdir(end),filesep); outdir = [outdir filesep]; end



fig = figure; hold all;
ax = gca;

six = 1; % swarmplot index
mix = 1; % marker index
for site = fieldnames(allMetadata)'
    disp(append('[', datestr(datetime), '] Plotting for site ', site{:}));

    if isempty(score_tab)
        score_tab = WEAR_aggregateResults(allMetadata.(site{:}), 'plot', 0, 'minhours',minhours, 'qualityByOnbody',qbo, 'tz',TZ.(site{:}));
        %score_tab = score_tab(contains(score_tab.ID,"ankle"),:);
    end

    tempMetadata = struct();
    tempMetadata.(site{:}) = allMetadata.(site{:});
    if plotSeparate
        WEAR_plotResults(tempMetadata, 'scoreTab',score_tab , 'suffix',[suffix(2:end) '-' erase(legendnames{six},' ')], 'legendnames',legendnames(six), 'outdir',outdir, 'markers',markers(mix), 'printperc',printperc, 'minhours',minhours, 'plotSeparate',0, 'qualityByOnbody',qbo);
    else
        WEAR_printResults(tempMetadata, 'scoreTab',score_tab, 'printperc',printperc, 'minhours',minhours, 'qualityByOnbody',qbo);
    end

    plotdata = score_tab{:,[3:7]};
    plotdata(:,6) = nan; % legend workaround
    plotcats = categorical(strings(size(plotdata))+["completeness","onbody","EDA","BVP","TEMP","legend"]);
    plotcats = reordercats(plotcats,["completeness","onbody","EDA","BVP","TEMP","legend"]);

    if contains('+*.x_|', markers{mix})
        s(six,:) = swarmchart(ax, plotcats, plotdata, 50, colormap, markers{mix});
    else
        s(six,:) = swarmchart(ax, plotcats, plotdata, 50, colormap, markers{mix}, 'filled');
    end

    [s(six,:).XJitterWidth] = deal(0.5);
    ylabel(ax, 'quality score (better \rightarrow)')
    ylim(ax, [0,1])

    if mix >= numel(markers); mix = 1; else; mix = mix + 1; end
    six = six + 1;
    score_tab = [];
end

l = legend(s(:,6), legendnames, 'Location','southeast');
xlim(ax, {'completeness','TEMP'})

outpath = [outdir 'WEAR2-results' suffix '.png'];
disp(append('[', datestr(datetime), '] Saving plot to ''', outpath, ''''));
exportgraphics(fig,outpath,'Resolution',300)

end

