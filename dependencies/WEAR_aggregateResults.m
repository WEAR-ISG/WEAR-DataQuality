function score_tab = WEAR_aggregateResults(indata, varargin)

    args = WEAR_getDefaultArgs();
    plotting = getNamedArg(varargin, 'plot', 0);

    minhours = getNamedArg(varargin, 'minhours', 0);
    minhours_dur = duration(minhours,0,0);

    qbo = getNamedArg(varargin, 'qualityByOnbody', 0);

    filterByTimeHours = getNamedArg(varargin, 'filterByTime', []);
    TZ = getNamedArg(varargin, 'tz', 'local');

    % init table
    varTypes = ["string","string","double","double","double","double","double","double","duration","duration"];
    varNames = ["ID","device","completeness","onbody","ACC","EDA","BVP","TEMP","duration_hms","span_hms"];
    score_tab_def = table('Size', [0 numel(varNames)], 'VariableTypes', varTypes, 'VariableNames', varNames);
    score_tab = getNamedArg(varargin, 'score_tab', score_tab_def);

    disp(append('[', datestr(datetime), '] Aggregating results for ', num2str(numel(fieldnames(indata))), ' recordings...'));

    for d = fieldnames(indata)'
        if any(contains(fieldnames(indata.(d{:})),'path'))
            if ~isempty(filterByTimeHours)
                indata.(d{:}) = filterByTime(indata.(d{:}), filterByTimeHours(1), filterByTimeHours(2), TZ);
            end

            % check all data present
            if any(cellfun(@isempty, {indata.(d{:}).completeness, indata.(d{:}).onbody, indata.(d{:}).quality}))
                continue;
            end

            % init new table row
            devices = union(fieldnames(indata.(d{:}).completeness), fieldnames(indata.(d{:}).onbody));
            devices = union(devices, fieldnames(indata.(d{:}).quality));
            score_tab_new = table('Size', [numel(devices) numel(varNames)], 'VariableTypes', varTypes, 'VariableNames', varNames);
            for dev = 1:numel(devices)
                score_tab_new.ID(dev) = d{:};
                score_tab_new.device(dev) = devices{dev};
            end

            % aggregate completeness score
            for dev = fieldnames(indata.(d{:}).completeness)'
                all_completeness = structfun(@(x) x.score, indata.(d{:}).completeness.(dev{:}));
                score_tab_new(strcmpi(score_tab_new.device,dev{:}),:).completeness(end) = mean(all_completeness);
            end

            % aggregate onbody score
            for dev = fieldnames(indata.(d{:}).onbody)'
                onbody_perc = sum(indata.(d{:}).onbody.(dev{:})(:,2) > args.quality.onbody.threshold) / size(indata.(d{:}).onbody.(dev{:}),1);
                score_tab_new(strcmpi(score_tab_new.device,dev{:}),:).onbody(end) = onbody_perc;
            end

            % aggregate quality scores
            for dev = fieldnames(indata.(d{:}).quality)'
                for m = args.E4.modalities.EMPA
                    if ~qbo
                        score_tab_new(strcmpi(score_tab_new.device,dev{:}),:).(m)(end) = indata.(d{:}).quality.(dev{:}).(m).score;
                    else
                        onbody_ix = indata.(d{:}).onbody.(dev{:})(:,2) > args.quality.onbody.threshold;
                        onbody_stamps = indata.(d{:}).onbody.(dev{:})(onbody_ix,1);
                        quality_stamps = indata.(d{:}).quality.(dev{:}).(m).score_windowed(:,1);

                        if isempty(onbody_stamps)
                            score_tab_new(strcmpi(score_tab_new.device,dev{:}),:).(m)(end) = nan;
                            continue;
                        end

                        % arrayfun
%                         diffs = arrayfun(@(x) min(abs(onbody_stamps-x)), quality_stamps);

                        % simple loop
                        diffs = nan(1,numel(quality_stamps));
                        for stix = 1:numel(quality_stamps)
                           diffs(stix) = min(abs(onbody_stamps-quality_stamps(stix)));
                        end

                        % binary search loop
%                         diffs = nan(1,numel(quality_stamps));
%                         for stix = 1:numel(quality_stamps)
%                           nearestOnbodyIx = getIxByNearestUnix(quality_stamps(stix), quality_stamps(stix), onbody_stamps,'inner','bs');
%                           diffs(stix) = abs(quality_stamps(stix) - onbody_stamps(nearestOnbodyIx));
%                         end

                        onbody_quality = indata.(d{:}).quality.(dev{:}).(m).score_windowed(diffs<=args.quality.(m).window,:);
                        score_tab_new(strcmpi(score_tab_new.device,dev{:}),:).(m)(end) = mean(onbody_quality(:,2:end),'all');
                    end
                end
            end

            % aggregate durations
            for dev = fieldnames(indata.(d{:}).completeness)'
                all_span = structfun(@(x) x.duration_sec, indata.(d{:}).completeness.(dev{:}));
                score_tab_new(strcmpi(score_tab_new.device,dev{:}),:).span_hms(end) = duration(seconds(max(all_span)),'Format','hh:mm:ss');

                all_duration = [];
                for m = fieldnames(indata.(d{:}).completeness.(dev{:}))'
                    all_duration = [ all_duration, indata.(d{:}).completeness.(dev{:}).(m{:}).rec_samples / args.(dev{:}).fs.(m{:}) ];
                end
                score_tab_new(strcmpi(score_tab_new.device,dev{:}),:).duration_hms(end) = duration(seconds(max(all_duration)),'Format','hh:mm:ss');
            end

            % filter by minimum duration
            if score_tab_new.duration_hms < minhours_dur
                continue;
            end

            % plotting
            if plotting
                plotdata = WEAR_readDataFromPath(indata.(d{:}).path);
                for dev = fieldnames(plotdata)'
                    disp(['[' datestr(datetime) '] [' dev{:} '] Plotting data...']);

                    fig = WEAR_plotData(plotdata.(dev{:}), 'onbody', indata.(d{:}).onbody.(dev{:}), 'quality', indata.(d{:}).quality.(dev{:}));
                    fig.WindowState = 'maximized';
                end
            end

            % fix values >1
            score_tab_new(:,3:8) = varfun(@(x) min(1,x), score_tab_new(:,3:8));

            % append row
            score_tab = [score_tab; score_tab_new];
        end
    end

    % remove ACC column since unused
    score_tab.ACC = [];
end



function outdata = filterByTime(indata, hstart, hend, tz)
    outdata = indata;
    timespan = duration([hstart,hend],0,0);
    if timespan(1)<timespan(2)
        factor = abs(diff(timespan))/duration(24,0,0);
    else
        factor = abs(timespan(1)-timespan(2)-duration(24,0,0))/duration(24,0,0);
    end

    % onbody
    onbody_ix = getTimeBinaryIx(indata.onbody.E4(:,1), timespan, tz);
    outdata.onbody.E4 = indata.onbody.E4(onbody_ix,:);

    args = WEAR_getDefaultArgs();
    for m = args.E4.modalities.EMPA
        % quality
        stamps = indata.quality.E4.(m).score_windowed(:,1);
        quality_ix = getTimeBinaryIx(stamps, timespan, tz);
        outdata.quality.E4.(m).score_windowed = indata.quality.E4.(m).score_windowed(quality_ix,:);
        outdata.quality.E4.(m).score = mean(outdata.quality.E4.(m).score_windowed(:,2:end), 'all');

        % completeness
        winsec = indata.quality.E4.(m).score_window;
        startst = indata.quality.E4.(m).score_windowed(1,1);
        endst = indata.quality.E4.(m).score_windowed(end,1) + winsec;
        diff_sec = (endst-startst)*factor;
        outdata.completeness.E4.(m).duration_sec = int32(diff_sec);
        outdata.completeness.E4.(m).exp_samples = int32((diff_sec) * args.E4.fs.(m));
        outdata.completeness.E4.(m).rec_samples = int32(size(outdata.quality.E4.(m).score_windowed,1)*winsec*args.E4.fs.(m));
        outdata.completeness.E4.(m).score = size(outdata.quality.E4.(m).score_windowed,1) * winsec / (diff_sec);
    end
end

function ix = getTimeBinaryIx(stamps, timespan, tz)
    mode = timespan(1)<timespan(2);
    tods = timeofday(datetime(stamps,'ConvertFrom','posix','TimeZone',tz));
    if mode
        ix = tods>=timespan(1) & tods<timespan(2);
    else
        ix = tods>=timespan(1) | tods<timespan(2);
    end
end
