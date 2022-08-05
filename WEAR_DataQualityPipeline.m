clear variables;
close all;

tStart = tic;

% add dependencies
addpath(genpath('dependencies'));


%% init | vvv EDIT HERE vvv

% input for the assessment, path to a set of subjects or a single subject
data_input = "/path/to/data/directory";

% one of ["BCH", "UKF", "KCL", "MCR"]
site = '';

% empty for all available or one of ["E4"]
device = 'E4';

% path to a mat file or folder of mat files, which contain results of
% already processed data (empty to use predefined values)
% optionally ignore existing data, forcing (re-)processing for all
existing_dataset = '';
ignore_existing = 0;

% remove detailed quality score data from results output (significant increase in memory/storage usage if off)
stripscores = 1;


%% prepare data --> IMPLEMENT YOUR DATA STRUCTURE HERE
allMetadata = WEAR_prepareData(data_input, site, 'force', ignore_existing, 'existingdataset', existing_dataset, 'strip', stripscores);

%% assess data
allMetadata = WEAR_assessData(allMetadata, 'device', device, 'strip', stripscores);


%% report results

disp(append('[', datestr(datetime), '] Consolidating results into single file.'));
allMetadata = WEAR_loadResults(['WEAR_results_' site], 'strip', stripscores);
if isempty(fieldnames(allMetadata))
    allMetadata = WEAR_loadResults(existing_dataset, 'strip', stripscores);
end
WEAR_saveResults(allMetadata, 'suffix', datestr(now,29), 'strip', stripscores);

disp(' ');
disp(strjoin(strings(50,1)+'-',''));
disp('FINAL RESULTS');
disp(strjoin(strings(50,1)+'-',''));
disp(' ');

WEAR_printResults(allMetadata, 'plot', 0);

tEnd = toc(tStart);
disp(append("Finished in ", sprintf('%.2f', tEnd/3600), " hours (", sprintf('%.0f', tEnd), "s)."));
