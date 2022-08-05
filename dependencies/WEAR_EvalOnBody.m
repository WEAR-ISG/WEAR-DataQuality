function onbody = WEAR_EvalOnBody(data, varargin)

args = getNamedArg(varargin,'args',WEAR_getDefaultArgs());
window_sec = getNamedArg(varargin, 'window_sec', args.quality.onbody.window);
min_interval_samples = getNamedArg(varargin, 'min_interval_samples', 2);
onbody_th_perc = getNamedArg(varargin, 'onbody_th_perc', args.quality.onbody.winperc);
blocks = getNamedArg(varargin, 'blocks', []);

onbody = struct();

for d = fieldnames(data)'
    if isempty(blocks); blocksd = [-Inf Inf]; else; blocksd = blocks.(d{:}); end
    fprintf(['[' datestr(datetime) '] [' d{:} '] Assess wearable on body. Processing... %03d%% %03d%%'], 0, 0);
    perclast = 0;

    for bix = 1:size(blocksd,1)
        if any(isinf(blocksd(bix,:)))
            minstamp = min([data.(d{:}).ACC(:,1); data.(d{:}).EDA(:,1); data.(d{:}).TEMP(:,1)]);
            maxstamp = max([data.(d{:}).ACC(:,1); data.(d{:}).EDA(:,1); data.(d{:}).TEMP(:,1)]);
        else
            minstamp = blocksd(bix,1);
            maxstamp = blocksd(bix,2);
        end

        intervals = minstamp:window_sec:maxstamp;
        onbodyb.(d{:}) =  [intervals', zeros(numel(intervals),1)];

        for i = numel(intervals):-1:1
            ACC_ix = getIxByNearestUnix(intervals(i), intervals(i)+window_sec, data.(d{:}).ACC(:,1), 'any', 'bs');
            EDA_ix = getIxByNearestUnix(intervals(i), intervals(i)+window_sec, data.(d{:}).EDA(:,1), 'any', 'bs');
            TEMP_ix = getIxByNearestUnix(intervals(i), intervals(i)+window_sec, data.(d{:}).TEMP(:,1), 'any', 'bs');
            
            if any(cellfun(@numel,{ACC_ix EDA_ix TEMP_ix}) < min_interval_samples)
                onbodyb.(d{:})(i,:) = [];
                continue;
            end
            
            ACC_onbody = sum(movstd(sum(data.(d{:}).ACC(ACC_ix,2:end),2),args.(d{:}).fs.ACC*args.quality.onbody.ACC.movstd_window_sec) > args.quality.onbody.ACC.movstd_th) > (window_sec*args.(d{:}).fs.ACC) * onbody_th_perc;
            EDA_onbody = sum(data.(d{:}).EDA(EDA_ix,2:end) > args.quality.EDA.threshold) > (window_sec*args.(d{:}).fs.EDA) * onbody_th_perc;
            TEMP_onbody = sum((data.(d{:}).TEMP(TEMP_ix,2:end) > args.quality.TEMP.threshold(1)) & (data.(d{:}).TEMP(TEMP_ix,2:end) < args.quality.TEMP.threshold(2))) > (window_sec*args.(d{:}).fs.TEMP) * onbody_th_perc;
            
            onbodyb.(d{:})(i,2) = sum([ACC_onbody EDA_onbody TEMP_onbody])/3;
            onbodyb.(d{:})(i,3:5) = [ACC_onbody EDA_onbody TEMP_onbody];
            
            perclast = print_perc(bix, size(blocksd,1), numel(intervals)-i+1, numel(intervals), perclast);
        end

        if ~isfield(onbody,d{:})
            onbody.(d{:}) = onbodyb.(d{:});
        else
            onbody.(d{:}) = vertcat(onbody.(d{:}), onbodyb.(d{:}));
        end
    end

    fprintf('\n');
end

end



function perclast = print_perc(cur1,tot1,cur2,tot2,perclast)
    perc1 = round(cur1*100/tot1);
    perc2 = round(cur2*100/tot2);
    if perc2 ~= perclast
        fprintf('\b\b\b\b\b\b\b\b\b');
        fprintf('%03d%% %03d%%', perc1, perc2);
    end
    perclast = perc2;
end
