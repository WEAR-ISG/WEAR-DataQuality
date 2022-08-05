function [ps,frq,ts,x_cutted]=TR_PSD(x,T,Tstep,Fs,W,detr,nfft,whitening,whiteningopt,whiteningorder,postcoloring)

% Time-resolved Power Spectral Density Estimation
%
% parameter:
% X - signal; first dimension: time; second dimension: trials
% T - length of time window
% Tstep - time steps in which time window is moved
% Fs - sampling frequency
% W - window function
% whitening - prewhiten time series for bias reduction
% whiteningopt - 'ar','FirstDif'; estimate ar coefficients form time series
%                 or take first difference (equals  [1, -1] as AR coefficients)
% postcoloring - multiply by the transfer function do undo prewhitening
%
% return values:
% ps - Time-resolved Power Spectral Density Estimation, first dimension: frequency; second dimension: time; third dim: trials
% frq - Fourier Frequencies
% ts - center of moving window function

if nargin<5
    W=rectwin(T);
end

if nargin<6
    detr=0;
end

if nargin<7
    nfft=T;
end

if nargin<8
    whitening=0;
end

if nargin<9
    whiteningopt='arburg';
end

if nargin<10
    whiteningorder=1;
end

if nargin<11
    postcoloring=0;
end

W=W./norm(W);
ts=T:Tstep:size(x,1);

% if mod(T,2)==0
%     ps=zeros(T/2+1,length(ts),size(x,2));
% else
%     ps=zeros(ceil(T/2),length(ts),size(x,2));
% end
x_cutted=zeros(T,length(ts),size(x,2));

for trial=1:size(x,2)
    x1=zeros(T,length(ts));
    count=0;
    for t=ts
        count=count+1;
        x1(:,count)=x(t-T+1:t,trial);
    end
    
    if detr
        %x1=detrend(x1);
        %x1=detrend(x1,3);
        x1=x1-mean(x1);
    end
    
    if whitening
        switch whiteningopt
            case 'arburg'
                [x1,a]=prewhitening(x1,whiteningorder,'Burg');
            case 'aryule'
                [x1,a]=prewhitening(x1,whiteningorder,'Yule');
            case 'FirstDif'
                a=[1,-.999];  % take value close to -1 to avoid dividing by zero
                a=repmat(a,1,size(x1,2));
                x1(2:end,:)=a(1,1)*x1(2:end,:)+a(2,1)*x1(1:end-1,:);
        end
    end
    q=repmat(W,1,length(ts)).*x1;
    f=fft(q,nfft);
    
    if mod(size(f,1),2)==0
        f=f(1:end/2+1,:);
    else
        m=ceil(size(f,1)/2);
        f=f(1:m,:);
    end
    ps(:,:,trial)=abs(f).^2/Fs;
    ps(2:end-1,:,trial)=2*ps(2:end-1,:,trial);
    
    if postcoloring
        freq=linspace(0,Fs/2,size(ps,1));
        for n=1:size(ps,2)
            h(:,n) = freqz(1,a(:,n),freq,Fs);
        end
        h=abs(h).^2;
        ps(:,:,trial)=ps(:,:,trial).*h;
    end
    
    x_cutted(:,:,trial)=x1;
end

ts=ts-floor(T/2);
frq=([1:size(f,1)]'-1)./nfft*Fs;

