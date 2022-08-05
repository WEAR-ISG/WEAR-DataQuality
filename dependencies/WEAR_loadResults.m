function metadata = WEAR_loadResults(inpath, varargin)
    metadata = struct();

    strip_scores = getNamedArg(varargin, 'strip', 0);

    if isfolder(inpath)
        disp(append('[', datestr(datetime), '] Loading existing metadata from ''', inpath, ''''));

        resultfiles = dir(fullfile(inpath, ['*.mat']));
        maxIndex = size(resultfiles,1);
        currentIndex = 0;
        for fix = 1:size(resultfiles,1)
            filepath = [resultfiles(fix).folder filesep resultfiles(fix).name];
            currentIndex = currentIndex + 1;
            disp(append('[', datestr(datetime), '] ', progress2str(currentIndex, maxIndex), ' Loading metadata from ''', filepath, ''''));
            loadedData = load(filepath);
            if isfield(loadedData, 'metadata')
                for site = fieldnames(loadedData.metadata)'
                    for rec = fieldnames(loadedData.metadata.(site{:}))'
                        metadata.(site{:}).(rec{:}) = loadedData.metadata.(site{:}).(rec{:});
                    end
                end
            elseif isfield(loadedData, 'metadatasite')
                for site = fieldnames(loadedData.metadatasite)'
                    for rec = fieldnames(loadedData.metadatasite.(site{:}))'
                        metadata.(site{:}).(rec{:}) = loadedData.metadatasite.(site{:}).(rec{:});
                    end
                end
            end
            clear loadedData;
            if strip_scores
                metadata = stripScores(metadata);
            end
        end
    elseif isfile(inpath) && strcmpi(inpath(end-3:end),'.mat')
        disp(append('[', datestr(datetime), '] Loading existing metadata from ''', inpath, ''''));
        loadedData = load(inpath);
        if isfield(loadedData, 'metadata')
            metadata = loadedData.metadata;
        elseif isfield(loadedData, 'metadatasite')
            metadata = loadedData.metadatasite;
        end
        clear loadedData;
        if strip_scores
            metadata = stripScores(metadata);
        end
    end
end

function metadata = stripScores(metadata)
    for site = fieldnames(metadata)'
        for subj = fieldnames(metadata.(site{:}))'
            for dev = fieldnames(metadata.(site{:}).(subj{:}).quality)'
                for mod = fieldnames(metadata.(site{:}).(subj{:}).quality.(dev{:}))'
                    for field = fieldnames(metadata.(site{:}).(subj{:}).quality.(dev{:}).(mod{:}))'
                        if ~startsWith(field{:},'score')
                            metadata.(site{:}).(subj{:}).quality.(dev{:}).(mod{:}) = rmfield(metadata.(site{:}).(subj{:}).quality.(dev{:}).(mod{:}), field{:});
                        end
                    end
                end
            end
        end
    end
end
