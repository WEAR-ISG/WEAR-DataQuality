function [] = WEAR_saveResults(metadata,varargin)

suffix = getNamedArg(varargin, 'suffix', '');
outdir = getNamedArg(varargin, 'outdir', '');
strip_scores = getNamedArg(varargin, 'strip', 0);
basefilename = getNamedArg(varargin, 'basefilename', 'WEAR_results');
if ~strip_scores; basefilename = [basefilename '_full']; end

if strip_scores
    metadata = stripScores(metadata);
end

for site = fieldnames(metadata)'
    if isempty(suffix) || ~ischar(suffix)
        outfilename = [ basefilename '_' site{:} ];
    else
        outfilename = [ basefilename '_' site{:} '_' suffix ];
    end
    if ~isempty(outdir)
        if ~exist(outdir,'dir'); mkdir(outdir); end
        outfilename = [outdir filesep outfilename];
    end
    disp(append('[', datestr(datetime), '] Saving results to file ''', outfilename, ''''));
    metadatasite.(site{:}) = metadata.(site{:});
    save(outfilename, 'metadatasite', '-v7.3')
    clear metadatasite
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
