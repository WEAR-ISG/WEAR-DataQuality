function [metric] = PPGMetric(signal, varargin)

fs = getNamedArg(varargin,'fs',64);

L=4*fs;
Lstep=L/16;
T=4*fs;
Tstep=T;
W=tukeywin(T,.25);
fband_lower=.1;
fband_upper=5;
detr=1;

[metric,~,~,~,~,~,~] = TR_SpecEnt(-signal,fs,L,Lstep,T,Tstep,W,detr,fband_lower,fband_upper);

metric = interp1(metric, linspace(1,length(metric),length(signal)));

end

