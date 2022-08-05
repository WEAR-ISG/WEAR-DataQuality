function input_paths = WEAR_prepareData(data_input, site, varargin)
    force = getNamedArg(varargin, 'force', 0);
    existingdataset = getNamedArg(varargin, 'existingdataset', '');
    strip_scores = getNamedArg(varargin, 'strip', 0);

    % prepare metadata
    if strcmpi(site, 'UKF') || strcmpi(site, 'KCL')
        input_paths.(site) = prepare_RADAR(data_input);
    elseif strcmpi(site, 'BCH')
        input_paths.(site) = prepare_BCH(data_input);
    elseif strcmpi(site, 'MCR')
        input_paths.(site) = prepare_MCR(data_input);
    else
        error(['Site ' site ' unknown!']);
    end

    % check if metadata already exists
    if ~isempty(existingdataset) && isfile(existingdataset) && strcmpi(existingdataset(end-3:end),'.mat')
        input_paths = WEAR_loadResults(existingdataset);
    else
        for site = fieldnames(input_paths)'
            for rec = fieldnames(input_paths.(site{:}))'
                if isempty(existingdataset)
                    if strip_scores
                        resultsfilepath = ['WEAR_results_' site{:} filesep 'WEAR_results_' site{:} '_' rec{:} '.mat'];
                    else
                        resultsfilepath = ['WEAR_results_full_' site{:} filesep 'WEAR_results_' site{:} '_' rec{:} '.mat'];
                    end
                elseif isfolder(existingdataset) && ~strcmpi(existingdataset(end-3:end),'.mat')
                    [filepath,filename,~] = fileparts(existingdataset);
                    if isempty(filepath)
                        resultsfilepath = [filename filesep filename '_' rec{:} '.mat'];
                    else
                        resultsfilepath = [filepath filesep filename filesep filename '_' rec{:} '.mat'];
                    end
                end
                if ~force && exist('resultsfilepath', 'var') && isfile(resultsfilepath)
                    input_paths.(site{:}).(rec{:}).processed = true;
                end
            end
        end
    end

end



%% RADAR data structure TODO
function input_paths = prepare_RADAR(data_input)
    args = WEAR_getDefaultArgs();
    input_paths = struct();

    [~,~,ext] = fileparts(data_input);

    % can't handle files
    if ext ~= ""
        warning(append("Bad input path: ", data_input))
        return
    end

    patInputInfo = dir(fullfile(data_input,'*.*'));

    if any(contains({patInputInfo.name}, 'android_')) % handle path to single subject
        patStr = extract(data_input, regexpPattern('KCL[0-9]{2}|UKLFR[0-9]{3}'));
        if isempty(patStr)
            patStr = extract(data_input, regexpPattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'));
            patStrUUIDParts = split(patStr,'-');
            patStr = ['UUID_' patStrUUIDParts(1)];
        end
        if ~isempty(patStr)
            input_paths.(patStr).path = data_input;
            input_paths.(patStr).processed = false;
        end
    else % iterate subjects
        for ixPat = 3:length(patInputInfo)
            patPath = [patInputInfo(ixPat).folder filesep patInputInfo(ixPat).name];
            patStr = patInputInfo(ixPat).name;
            if ~isempty(regexp(patStr, '^UKLFR[0-9]{3}$', 'once')) && isfolder(patPath)
                input_paths.(patStr).path = patPath;
                input_paths.(patStr).processed = false;
            elseif ~isempty(regexp(patStr, '^KCL[0-9]{2}$', 'once')) && isfolder(patPath)
                input_paths.(patStr).path = [patPath filesep 'RADAR'];
                input_paths.(patStr).processed = false;
            elseif ~isempty(regexp(patStr, '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', 'once')) && isfolder(patPath)
                patStrUUIDParts = split(patStr,'-');
                patStr = ['UUID_' patStrUUIDParts{1}];
                input_paths.(patStr).path = patPath;
                input_paths.(patStr).processed = false;
            end
        end
    end

end


%% BCH data structure
function input_paths = prepare_BCH(data_input)
    args = WEAR_getDefaultArgs();
    input_paths = struct();
    
    [filepath,name,ext] = fileparts(data_input);
    
    % can't handle files
    if ext ~= ""
        warning(append("Bad input path: ", data_input))
        return
    end
    
    % handle path to single subject
    patID_filter = "";
    if name ~= "" && ~isempty(regexp(name, '^C[0-9]{3}$', 'once'))
        data_input = filepath;
        patID_filter = name;
    end

    % handle direct path to data directory
    if all(arrayfun(@(x) isfile(append(data_input, filesep, x, '.csv')), args.E4.modalities.EMPA))
        input_paths.(append('rec_', name)).path = data_input;
        return;
    end
    
    % iterate subjects
    patInputInfo = dir(fullfile(data_input,'*.*'));
    for ixPat = 3:length(patInputInfo)
        if ~isempty(regexp(patInputInfo(ixPat).name, '^C[0-9]{3}$', 'once')) && (patID_filter=="" || patInputInfo(ixPat).name==patID_filter)
            patPath = [patInputInfo(ixPat).folder filesep patInputInfo(ixPat).name];
            patStr = patInputInfo(ixPat).name;
    
            % iterate dates
            dateInputInfo = dir(fullfile(patPath,'*.*'));
            for ixDate = 3:length(dateInputInfo)
                if regexp(dateInputInfo(ixDate).name, '^..\...\.....$')
                    datePath = [dateInputInfo(ixDate).folder filesep dateInputInfo(ixDate).name];
                    %dateStr = ['D' datestr(datetime(dateInputInfo(ixDate).name,'InputFormat','MM.dd.yyyy'), 'yyyymmdd')];
    
                    % iterate devices
                    devInputInfo = dir(fullfile(datePath,'*.*'));
                    for ixDev = 3:length(devInputInfo)
                        devPath = [devInputInfo(ixDev).folder filesep devInputInfo(ixDev).name];
                        devStr = strsplit(devInputInfo(ixDev).name,'_');
                        devStr = replace(devStr{1},' ','_');
    
                        % iterate data
                        dataInputInfo = dir(fullfile(devPath,'*.*'));
                        for ixData = 3:length(dataInputInfo)
                            if regexp(dataInputInfo(ixData).name, '.*\.zip')
                                dataZipPath = [dataInputInfo(ixData).folder filesep dataInputInfo(ixData).name];
                                dataPath = dataZipPath(1:end-4);
                                fldnm = [patStr '_' devStr];
                                if isfield(input_paths, fldnm)
                                    input_paths.(fldnm).path = [input_paths.(fldnm).path ';' dataPath];
                                else
                                    input_paths.(fldnm).path = dataPath;
                                    input_paths.(fldnm).processed = false;
                                end
                            end
                        end
                        % / iterate data
    
                    end
                    % / iterate devices
    
                end
            end
            % / iterate dates
    
        end
    end
    % / iterate patients

end



%% MCR data structure
function input_paths = prepare_MCR(data_input)
    args = WEAR_getDefaultArgs();
    input_paths = struct();
    
    [filepath,name,ext] = fileparts(data_input);
    
    % can't handle files
    if ext ~= ""
        warning(append("Bad input path: ", data_input))
        return
    end
    
    % handle path to single subject
    patID_filter = "";
    if name ~= "" && ~isempty(regexp(name, '^[a-zA-Z]{4}_[0-9]{5}$', 'once'))
        data_input = filepath;
        patID_filter = name;
    end

    % handle direct path to data directory
    if all(arrayfun(@(x) isfile(append(data_input, filesep, x, '.csv')), args.E4.modalities.EMPA))
        input_paths.(append('rec_', name)).path = data_input;
        return;
    end
    
    % iterate subjects
    patInputInfo = dir(fullfile(data_input,'*.*'));
    for ixPat = 3:length(patInputInfo)
        if ~isempty(regexp(patInputInfo(ixPat).name, '^[a-zA-Z]{4}_[0-9]{5}$', 'once')) && (patID_filter=="" || patInputInfo(ixPat).name==patID_filter)
            patPath = [patInputInfo(ixPat).folder filesep patInputInfo(ixPat).name];
            patStr = patInputInfo(ixPat).name;
    
            % iterate empatica data
            dateInputInfo = dir(fullfile(patPath,'*.*'));
            for ixDate = 3:length(dateInputInfo)
                if regexp(dateInputInfo(ixDate).name, '^Empatica$')
                    e4Path = [dateInputInfo(ixDate).folder filesep dateInputInfo(ixDate).name];
    
                    % iterate data
                    dataInputInfo = dir(fullfile(e4Path,'*.*'));
                    for ixData = 3:length(dataInputInfo)
                        if regexp(dataInputInfo(ixData).name, '^[0-9]{10}_[A-Z0-9]{6}$')
                            dataPath = [dataInputInfo(ixData).folder filesep dataInputInfo(ixData).name];
                            if isfield(input_paths, patStr)
                                input_paths.(patStr).path = [input_paths.(patStr).path ';' dataPath];
                            else
                                input_paths.(patStr).path = dataPath;
                                input_paths.(patStr).processed = false;
                            end
                        end
                    end
                    % / iterate data
    
                end
            end
            % / iterate empatica data
    
        end
    end
    % / iterate patients

end


