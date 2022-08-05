function [args] = WEAR_getDefaultArgs(varargin)


%% general
args.sites = ["BCH", "UKF", "KCL", "MCR"];
args.devices = ["E4"];

args.blocks.minlengthsec = 130; % recommend 2x quality basewindow + 10

%% quality/onbody assessement
args.quality.basewindow = getNamedArg(varargin,'basewindow',60);
args.quality.ACC.window = args.quality.basewindow;
args.quality.EDA.window = args.quality.basewindow;
args.quality.EDA.RACwindow = 2;
args.quality.BVP.window = args.quality.basewindow;
args.quality.TEMP.window = args.quality.basewindow;
args.quality.TEMP.RACwindow = 2;

args.quality.onbody.window = args.quality.basewindow;
args.quality.onbody.winperc = 0.01;
args.quality.onbody.ACC.movstd_window_sec = 10;
args.quality.onbody.ACC.movstd_th = 0.2;
args.quality.onbody.threshold = 0.3;

args.quality.EDA.threshold = 0.05;
args.quality.EDA.RACthreshold = 0.2;
args.quality.BVP.threshold = 0.8;
args.quality.TEMP.threshold = [25, 40];
args.quality.TEMP.RACthreshold = 0.2;



%% Empatica E4
args.E4.fs.ACC = 32;
args.E4.fs.EDA = 4;
args.E4.fs.BVP = 64;
args.E4.fs.TEMP = 4;

args.E4.range.ACC = [-2,2];

args.E4.dataformat.UKF = "RADAR";
args.E4.dataformat.KCL = "RADAR";
args.E4.dataformat.BCH = "EMPA";
args.E4.dataformat.MCR = "EMPA";
args.E4.modalities.EMPA = ["ACC", "EDA", "BVP", "TEMP"];
args.E4.modalities.RADAR = [
    "android_empatica_e4_acceleration"
    "android_empatica_e4_electrodermal_activity"
    "android_empatica_e4_blood_volume_pulse"
    "android_empatica_e4_temperature"
    ];
args.E4.modalities.RADARmap = containers.Map(args.E4.modalities.RADAR, args.E4.modalities.EMPA);


end

