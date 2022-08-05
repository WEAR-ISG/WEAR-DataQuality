function metadata = WEAR_assessData(metadata, varargin)
    device = getNamedArg(varargin, 'device', '');
    strip_scores = getNamedArg(varargin, 'strip', 0);

    processingErrors = struct();
    for site = fieldnames(metadata)'
        maxIndex = numel(fieldnames(metadata.(site{:})));
        currentIndex = 0;
        for rec = fieldnames(metadata.(site{:}))'
            currentIndex = currentIndex + 1;

            % process assessment
            if isfield(metadata.(site{:}).(rec{:}), 'path')
                tmp = metadata.(site{:}).(rec{:});
                disp("##########")
                if isfield(tmp, 'processed') && tmp.processed
                    disp(append('[', datestr(datetime), '] Skipped assessments due to already existing results for recording at ''', tmp.path, ''''));
                    datachanged = 0;
                else
                    disp(append('[', datestr(datetime), '] ', progress2str(currentIndex, maxIndex), ' Processing assessments for ''', rec{:}, ''', recording at ''', tmp.path, ''''));
                    try
                        [tmp.completeness, tmp.onbody, tmp.quality, datachanged] = assessment( tmp.path );
                    catch ME
                        processingErrors.(rec{:}).exception = ME;
                        processingErrors.(rec{:}).path = tmp.path;
                        warning(append('[', datestr(datetime), '] ERROR while processing assessments for ''', rec{:}, ''', recording at ''', tmp.path, ''''))
                        warning(getReport( ME, 'extended', 'hyperlinks', 'on' ))
                        datachanged = 0;
                    end
                    if datachanged; tmp.processed = true; end
                    metadata.(site{:}).(rec{:}) = tmp;
                end
                clear tmp;
            end

            % save result data
            if exist('datachanged','var') && datachanged
                % save results to disc
                tmpsav.(site{:}).(rec{:}) = metadata.(site{:}).(rec{:});
                WEAR_saveResults(tmpsav, 'outdir',['WEAR_results_' site{:}], 'suffix',rec{:}, 'strip',strip_scores);
                % remove results from memory after saving to disc
                clear tmpsav;
                datafields = {'completeness','onbody','quality'};
                metadata.(site{:}).(rec{:}) = rmfield(metadata.(site{:}).(rec{:}), datafields(isfield(metadata.(site{:}).(rec{:}), datafields)));
            end
            %if currentIndex == 1; return; end
        end
    end
    disp("##########")

    if ~isempty(fieldnames(processingErrors))
        disp(' ');
        disp(strjoin(strings(50,1)+'-',''));
        disp("SOME ERRORS OCCURRED DURING PROCESSING:")
        for rec = fieldnames(processingErrors)'
            disp(append(rec{:}, ": ", processingErrors.(rec{:}).exception.message))
        end
        disp(strjoin(strings(50,1)+'-',''));
        disp(' ');
    end

    disp(append('[', datestr(datetime), '] Done processing.'));
end


function [completeness, onbody, quality, datachanged] = assessment(datapath)
    args = WEAR_getDefaultArgs();
    [data, blocks] = WEAR_readDataFromPath(datapath);

    if isempty(data)
        [completeness, onbody, quality] = deal([]);
        datachanged = 0;
        return;
    end
    datachanged = 1;

    if isempty(blocks.E4)
        blocks = WEAR_getDataBlocks(data, 'minlengthsec', args.blocks.minlengthsec);
    else
        blocks.E4 = sort(blocks.E4,1);
    end

    % assess data completeness per modality
    completeness = WEAR_EvalCompleteness(data);

    % assess wearable on body
    onbody = WEAR_EvalOnBody(data, 'window_sec', args.quality.onbody.window, 'blocks', blocks);

    % assess signal quality per modality
    quality = WEAR_EvalSignalQuality(data, 'blocks', blocks); % TODO: only get for periods of onbody=1

end
