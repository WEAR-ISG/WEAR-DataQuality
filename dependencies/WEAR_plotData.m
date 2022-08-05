function [fig, ax] = WEAR_plotData(data, varargin)

args = getNamedArg(varargin,'args',WEAR_getDefaultArgs());

tz = getNamedArg(varargin,'tz','local');
title = getNamedArg(varargin,'title','plot');
visible = getNamedArg(varargin,'Visible','on');

device = getNamedArg(varargin,'device','E4');
markmissing = getNamedArg(varargin,'markmissing',1);
markoffbody = getNamedArg(varargin,'markoffbody',1);
plotonbody = getNamedArg(varargin,'plotonbody',1);
marktags = getNamedArg(varargin,'marktags',1);
onbody = getNamedArg(varargin,'onbody',[]);
quality = getNamedArg(varargin,'quality',[]);

plotlinewidth = getNamedArg(varargin,'plotlinewidth',0.5);

disp(append('[', datestr(datetime), '] plotting data'));

subplot_names = fieldnames(data);
subplot_names = setdiff(subplot_names,'tags');
% prepare onbody data for plotting if available
if ~isempty(onbody)
    if plotonbody; subplot_names = [subplot_names; 'onbody']; end
    data.onbody = [data.TEMP(:,1) interp1(onbody(:,1), onbody(:,2), data.TEMP(:,1), 'previous')];
    offbodyblocks = getOffbodyBlocks(data.onbody(:,1), data.onbody(:,2), args.quality.onbody.threshold);
end
num_subplots = numel(subplot_names);



fig = figure('Name', title, 'Visible', visible, 'NumberTitle', 'off');
if ~verLessThan('matlab','9.2')
    set(fig,'defaultLegendAutoUpdate','off')
end



for i = 1:num_subplots
    % plot
    plot_data = data.(subplot_names{i})(:,2:end);
    plot_stamps = data.(subplot_names{i})(:,1);
    %ax(i) = subaxis(num_subplots, 1, i, 'sv', 0.02, 'mt', 0.01);
    ax(i) = subaxis(num_subplots, 1, i, 'sv', 0.04, 'mt', 0.01);
    p = plot(ax(i), plot_stamps, plot_data,'LineWidth',plotlinewidth);

    ylabel(subplot_names{i}, 'Interpreter', 'none');

    % handle ticks and cursor
    if i ~= num_subplots
        set(ax(i), 'XTickLabel', [])
    else
        % date ticks
        xlabel(['datetime (' tz ')']);
        %simpledatetickzoom('x','yyyy-mm-dd HH:MM:SS', 'keeplimits', 'keepticks', 'tz', tz);
        %set(ax(i),'XTickLabelRotation',20);
        simpledatetickzoom('x','HH:MM:SS', 'keeplimits', 'keepticks', 'tz', tz);

        % date cursor
        dcm = datacursormode(fig);
        set(dcm,'updatefcn',@datetime_cursor_x);
    end

    % post
    ylim auto;
    axis(ax(i), 'tight');
    if i == num_subplots
        tmp.Axes = ax(i);
        simpledatetickzoom(fig, tmp);
    end
    
    % data-specific edits
    if strcmpi(subplot_names{i},'ACC')
        ylim(args.(device).range.ACC);
    elseif strcmpi(subplot_names{i},'TEMP')
        yline(args.quality.TEMP.threshold, 'r--', 'LineWidth', 1);
        ylim([20 50]);
    elseif strcmpi(subplot_names{i},'BVP')
        set(ax(i),'YTickLabel',[]);
    elseif strcmpi(subplot_names{i},'onbody')
        ylim([0 1]);
    end


    % mark missing data
    if markmissing
        ph = [];
        missingblocks = getMissingBlocks(plot_stamps, 1);
        for b = 1:size(missingblocks,1)
            x1 = missingblocks(b,1);
            x2 = missingblocks(b,2);
            yl = ylim;
            ph(b) = patch(ax(i), [x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], [204 204 204]/255, 'FaceAlpha', 1, 'LineStyle', 'none');
        end
        uistack(ph,"bottom");
    end    

    % mark offbody data
    if markoffbody && ~isempty(onbody)
        ph = [];
        for b = 1:size(offbodyblocks,1)
            x1 = offbodyblocks(b,1);
            x2 = offbodyblocks(b,2);
            yl = ylim;
            ph(b) = patch(ax(i), [x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], [0.75 0.75 0.75], 'FaceAlpha', 1, 'LineStyle', 'none');
        end
        uistack(ph,"bottom");
    end

    % mark data quality
    if ~isempty(quality) && any(contains(fieldnames(quality), subplot_names{i}))
        ph = [];
        for scoreix = 1:size(quality.(subplot_names{i}).score_windowed,1)
            x1 = quality.(subplot_names{i}).score_windowed(scoreix,1);
            x2 = x1 + quality.(subplot_names{i}).score_window;
            yl = ylim;
            q = quality.(subplot_names{i}).score_windowed(scoreix,2);
            ph(scoreix) = patch(ax(i), [x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], [1 0 0], 'FaceAlpha', 0.5*(1-q), 'LineStyle', 'none');
        end
        uistack(ph,"bottom");
    end

    % mark tags
    if marktags && isfield(data, 'tags') && ~isempty(data.tags)
        for t = data.tags'
            lh = xline(ax(i), t, '--k', 'LineWidth', 2);
        end
    end

    set(ax(i), 'Layer', 'top')
end

linkaxes(ax,'x');
pan on;

end


function blocks = getMissingBlocks(stamps, th)
    blocks = [];
    blocks_ix = find(diff(stamps) > th);
    for b = blocks_ix'
        blocks(end+1,1) = stamps(b);
        blocks(end,2) = stamps(b+1);
    end
end

function blocks = getOffbodyBlocks(stamps, onbody, th)
    blocks = [];

    offbody_ix = find(onbody<th);
    if isempty(offbody_ix); return; end
    offbody_ix_blocks = [1; find(diff(offbody_ix)>1)+1 ];
    offbody_ix_blocks = [offbody_ix_blocks [offbody_ix_blocks(2:end)-1 ; numel(offbody_ix)]];

    blocks = arrayfun(@(b) stamps(offbody_ix(b)), offbody_ix_blocks);

%     for b = 1:size(offbody_ix_blocks,1)
%         blocks(end+1,1) = stamps(offbody_ix_blocks(b,1));
%         blocks(end,2) = stamps(offbody_ix_blocks(b,2));
%     end
end
