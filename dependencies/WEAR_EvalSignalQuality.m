function quality = WEAR_EvalSignalQuality(data, varargin)

args = getNamedArg(varargin,'args',WEAR_getDefaultArgs());
blocks = getNamedArg(varargin, 'blocks', []);

for d = fieldnames(data)'
    for m = fieldnames(data.(d{:}))'
        if ~strcmpi(m,'tags')
            disp(append('[', datestr(datetime), '] [', d{:}, '] Assess data quality: ', char(m)));
        end
        
        if strcmpi(m,'ACC')
            % metric:
            quality.(d{:}).(m{:}).metric = data.(d{:}).(m{:})(:,2:end);
            quality.(d{:}).(m{:}).values = (quality.(d{:}).(m{:}).metric >= args.(d{:}).range.(m{:})(1)) & (quality.(d{:}).(m{:}).metric <= args.(d{:}).range.(m{:})(2));
            
            % scoring
            %quality.(d{:}).(m{:}).score = mean( mean(quality.(d{:}).(m{:}).values) );
            quality.(d{:}).(m{:}).score_window = args.quality.(m{:}).window;
            quality.(d{:}).(m{:}).score_windowed = getWindowedMMScore(quality.(d{:}).(m{:}).values, data.(d{:}).(m{:})(:,1), args.quality.(m{:}).window, args.(d{:}).fs.(m{:}));
            quality.(d{:}).(m{:}).score = mean(mean(quality.(d{:}).(m{:}).score_windowed(:,2:end)));
            %quality.(d{:}).(m{:}).score = 1;
        elseif strcmpi(m,'EDA')
            % metric 1: zero-line
            quality.(d{:}).(m{:}).metric1 = data.(d{:}).(m{:})(:,2);
            quality.(d{:}).(m{:}).values1 = quality.(d{:}).(m{:}).metric1 > args.quality.(m{:}).threshold;
            
            % metric 2: rate of amplitude change
            quality.(d{:}).(m{:}).metric2 = getRAC(data.(d{:}).(m{:})(:,2), args.quality.(m{:}).RACwindow, args.(d{:}).fs.(m{:}));
            quality.(d{:}).(m{:}).values2 = abs(quality.(d{:}).(m{:}).metric2) < args.quality.(m{:}).RACthreshold;
            
            % scoring
            quality.(d{:}).(m{:}).values = quality.(d{:}).(m{:}).values1 & quality.(d{:}).(m{:}).values2;
            quality.(d{:}).(m{:}).score_window = args.quality.(m{:}).window;
            quality.(d{:}).(m{:}).score_windowed = getWindowedMMScore(quality.(d{:}).(m{:}).values, data.(d{:}).(m{:})(:,1), args.quality.(m{:}).window, args.(d{:}).fs.(m{:}));
            quality.(d{:}).(m{:}).score = mean(quality.(d{:}).(m{:}).score_windowed(:,2:end));
        elseif strcmpi(m,'BVP')
            % metric:
            if isempty(blocks)
                metric = PPGMetric(data.(d{:}).(m{:})(:,2));
            else
                metric = [];
                for bix = 1:size(blocks.(d{:}), 1)
                    dataix = getIxByNearestUnix(blocks.(d{:})(bix,1), blocks.(d{:})(bix,2), data.(d{:}).(m{:})(:,1));
                    metricb = PPGMetric(data.(d{:}).(m{:})(dataix,2));
                    metric = horzcat(metric, metricb);
                end
            end
            quality.(d{:}).(m{:}).metric = metric;
            quality.(d{:}).(m{:}).values = quality.(d{:}).(m{:}).metric < args.quality.(m{:}).threshold;
            
            % scoring
            quality.(d{:}).(m{:}).score_window = args.quality.(m{:}).window;
            quality.(d{:}).(m{:}).score_windowed = getWindowedMMScore(quality.(d{:}).(m{:}).values, data.(d{:}).(m{:})(:,1), args.quality.(m{:}).window, args.(d{:}).fs.(m{:}));
            quality.(d{:}).(m{:}).score = mean(quality.(d{:}).(m{:}).score_windowed(:,2:end));
        elseif strcmpi(m,'TEMP')
            % metric 1: sensible body temperature values
            quality.(d{:}).(m{:}).metric1 = data.(d{:}).(m{:})(:,2);
            quality.(d{:}).(m{:}).values1 = (quality.(d{:}).(m{:}).metric1 > args.quality.TEMP.threshold(1)) & (quality.(d{:}).(m{:}).metric1 < args.quality.TEMP.threshold(2));
            
            % metric 2: rate of amplitude change
            quality.(d{:}).(m{:}).metric2 = getRAC(data.(d{:}).(m{:})(:,2), args.quality.(m{:}).RACwindow, args.(d{:}).fs.(m{:}));
            quality.(d{:}).(m{:}).values2 = abs(quality.(d{:}).(m{:}).metric2) < args.quality.(m{:}).RACthreshold;
            
            % scoring
            quality.(d{:}).(m{:}).values = quality.(d{:}).(m{:}).values1 & quality.(d{:}).(m{:}).values2;
            quality.(d{:}).(m{:}).score_window = args.quality.(m{:}).window;
            quality.(d{:}).(m{:}).score_windowed = getWindowedMMScore(quality.(d{:}).(m{:}).values, data.(d{:}).(m{:})(:,1), args.quality.(m{:}).window, args.(d{:}).fs.(m{:}));
            quality.(d{:}).(m{:}).score = mean(quality.(d{:}).(m{:}).score_windowed(:,2:end));
        end
    end
end

end


% windowed moving mean score with [T] seconds window length
function score_windowed = getWindowedMMScore(score, stamps, T, fs)
    [~,dim] = max(size(score));
    if dim > 1; score=score'; end
    scoremm = movmean(score, [0 (T*fs)-1]);
    sample_ix = 1:T*fs:min([size(scoremm,1) numel(stamps)]);
    score_windowed = [stamps(sample_ix) scoremm(sample_ix,:)];
end


% rate of amplitude change with [T] seconds window length
function rac = getRAC(signal, T, fs)
    intervals = 1:T*fs:numel(signal);
    rac = nan(numel(signal),1);
    for ix = intervals
        if ix+T*fs-1 >= numel(signal); continue; end
        windowdata = signal(ix:ix+T*fs-1);
        [vmin,imin] = min(windowdata);
        [vmax,imax] = max(windowdata);
        if imin < imax
            rac(ix) = (vmax-vmin)/abs(vmin);
        elseif imin > imax
            rac(ix) = (vmin-vmax)/abs(vmax);
        end
    end
    rac = fillmissing(rac,'previous');
end



