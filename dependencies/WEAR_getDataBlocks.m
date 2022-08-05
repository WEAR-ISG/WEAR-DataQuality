function blocks = WEAR_getDataBlocks(data, varargin)

args = WEAR_getDefaultArgs();
downfs_hz = getNamedArg(varargin, 'downfs', 1); % downsample data to this rate
minlength_sec = getNamedArg(varargin, 'minlengthsec', 10); % minimum length of a consecutive data block
maxdist_sec = getNamedArg(varargin, 'maxdistsec', 2); % maximum distance allowed between nearest samples of modalities

if 1/downfs_hz >= maxdist_sec || maxdist_sec > minlength_sec
    error("Conflicting arguments for getting consecutive data blocks!")
end

for d = fieldnames(data)'
    fprintf(['[' datestr(datetime) '] [' d{:} '] Getting data blocks. Processing... %03d%%'], 0);
    perclast = 0;

    downsampled_stamps = struct();
    for m = args.E4.modalities.EMPA
        downsampled_stamps.(m) = downsample(data.(d{:}).(m)(:,1), round(args.E4.fs.(m)/downfs_hz));
    end

    dblocks = [];
    block_ix = 1;
    state = 1;
    for ix = 1:numel(downsampled_stamps.ACC)
        ACCs = downsampled_stamps.ACC(ix);
        EDAs = downsampled_stamps.EDA(getIxByNearestUnix(ACCs, ACCs, downsampled_stamps.EDA,'inner','bs'));
        BVPs = downsampled_stamps.BVP(getIxByNearestUnix(ACCs, ACCs, downsampled_stamps.BVP,'inner','bs'));
        TEMPs = downsampled_stamps.TEMP(getIxByNearestUnix(ACCs, ACCs, downsampled_stamps.TEMP,'inner','bs'));

        if state == 1 && abs(ACCs-EDAs) < maxdist_sec && abs(ACCs-BVPs) < maxdist_sec && abs(ACCs-TEMPs) < maxdist_sec
            dblocks(block_ix,state) = ACCs;
            state = 2;
        end

        if state == 2
            if ix == numel(downsampled_stamps.ACC) ...
                    || (ix < numel(downsampled_stamps.ACC) && abs(ACCs - downsampled_stamps.ACC(ix+1)) >= maxdist_sec) ...
                    || (abs(ACCs-EDAs) >= maxdist_sec || abs(ACCs-BVPs) >= maxdist_sec || abs(ACCs-TEMPs) >= maxdist_sec)
                dblocks(block_ix,state) = ACCs;
                state = 1;
                if dblocks(block_ix,2)-dblocks(block_ix,1) >= minlength_sec; block_ix = block_ix + 1; end
            end
        end

        perclast = print_perc(ix, numel(downsampled_stamps.ACC), perclast);
    end
    if dblocks(end,2)-dblocks(end,1) < minlength_sec
        dblocks(end,:) = [];
    end
    blocks.(d{:}) = dblocks;
    fprintf('\n');
end
end

function perclast = print_perc(cur,tot,perclast)
    perc = round(cur*100/tot);
    if perc ~= perclast
        fprintf('\b\b\b\b');
        fprintf('%03d%%', perc);
    end
    perclast = perc;
end
