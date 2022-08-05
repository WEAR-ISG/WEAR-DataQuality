function [metric,sc,scs,ps,frq,tc,tcs] = TR_SpecEnt(signal,fs,L,Lstep,T,Tstep,W,detr,fband_lower,fband_upper)

tc=L:Lstep:length(signal);
sc=zeros(L,length(tc));
if ~isempty(tc)
    count=0;
    for t=tc
        count=count+1;
        sc(:,count)=signal(t-L+1:t);
    end
    tc=tc-tc(1)+1;
    
    %[ps,frq,tcs,scs]=TR_PSD(sc,T,Tstep,fs,W,detr,1024);
    [ps,frq,tcs,scs]=TR_PSD(sc,T,Tstep,fs,W,detr,10*T);
    tcs=tcs-tcs(1)+1;
    
    [~,I1]=min(abs(frq-fband_lower));
    [~,I2]=min(abs(frq-fband_upper));
    
    metric=pentropy(squeeze(median(ps(I1:I2,:,:),2)),...
        frq(I1:I2),1:size(ps,3));
else
    metric=[];
    sc=[];
    scs=[];
    ps=[];
    frq=[];
    tc=[];
    tcs=[];
end
end
