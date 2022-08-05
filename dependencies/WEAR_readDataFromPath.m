function [data, blocks] = WEAR_readDataFromPath(inpaths)
    args = WEAR_getDefaultArgs();
    blocks.E4 = [];
    %data = []; return;

    for p = split(inpaths,';')'
        inpath = p{:};

        % determine which data format is available
        E4_EMPA_unzip = all(arrayfun(@(x) isfile(append(inpath, filesep, x, '.csv')), args.E4.modalities.EMPA));
        E4_EMPA_zip = isfile(append(inpath, '.zip'));
        E4_EMPA = E4_EMPA_unzip | E4_EMPA_zip;
        E4_RADAR = all(arrayfun(@(x) isfolder(append(inpath, filesep, x)), args.E4.modalities.RADAR));

        if E4_EMPA && E4_RADAR; error(['[' datestr(datetime) '] ' 'Error: Reading Empatica and RADAR E4 data from the same directory is currently not supported!']); end

        % read E4 data
        disp(append('[', datestr(datetime), '] ', 'Read E4 data from: ', inpath));
        if E4_EMPA
            newdata = dataFromE4(inpath);
            startstamp = max([newdata.ACC(1,1), newdata.EDA(1,1), newdata.BVP(1,1), newdata.TEMP(1,1)]);
            endstamp = min([newdata.ACC(end,1), newdata.EDA(end,1), newdata.BVP(end,1), newdata.TEMP(end,1)]);
            blocks.E4 = vertcat(blocks.E4,[startstamp, endstamp]);
        elseif E4_RADAR
            newdata = dataFromE4RADAR(inpath);
        else
            warning(['[' datestr(datetime) '] ' 'No E4 data could be read!'])
            continue;
        end

        % concatenate if some data already exists
        if exist('data','var') && isstruct(data) && isfield(data,'E4') && ~isempty(fieldnames(data.E4))
            for m = fieldnames(newdata)'
                if isfield(data.E4, m{:}) && ~isempty(data.E4.(m{:}))
                    data.E4.(m{:}) = vertcat(data.E4.(m{:}), newdata.(m{:}));
                    data.E4.(m{:}) = sortrows(data.E4.(m{:}), 1);
                else
                    data.E4.(m{:}) = newdata.(m{:});
                end
            end
        else
            data.E4 = newdata;
        end
        clear newdata;
    end

    if ~exist('data','var') || ~checkDataIntegrity(data)
        data = [];
    end
end


function data = dataFromE4RADAR(inpath)
    data = [];
    args = WEAR_getDefaultArgs();
    for m = args.E4.modalities.RADAR'
        [~, mdata, ~] = dataFromCSV([inpath filesep m], 'q', 1, 'extract', 1, 'infiles', []);
        if ~isempty(mdata)
            disp(append('[', datestr(datetime), '] ', 'RADAR E4 timestamp correction...'));
            mdata = [mdata(:,1:2) mdata(:,1) mdata(:,3:end)];
            %mdata = timestampCorrection(mdata, 1, 1, 500);
            data.(args.E4.modalities.RADARmap(m)) = mdata(:,3:end);
        else
            warning(['[' datestr(datetime) '] ' 'No E4 data could be read! (' char(m) ')'])
        end
    end
    clear mdata;
end


function res = checkDataIntegrity(data)
    if isempty(data)
        res = 0;
        return;
    end
    res = 1;
    args = WEAR_getDefaultArgs();
    for d = fieldnames(data)'
        if isempty(data.(d{:}))
            res = 0;
        else
            mods = fieldnames(data.(d{:}));
            if ~all(arrayfun(@(x) any(strcmpi(mods,x)), args.(d{:}).modalities.EMPA))
                warning(append('[', datestr(datetime), '] ', 'Some data is missing for device', d{:}, ', skipping recording!'));
                res = 0;
            end
        end
    end
end
