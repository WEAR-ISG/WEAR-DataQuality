function arg = getNamedArg(args, name, default)
% get named argument value from provided varargin
    arg = default;
    for i = 1:length(args)
        if any(strcmpi(strsplit(name,'|'), args{i})) %strcmp(args{i}, name)
            arg = args{i+1}; break;
        end
    end
    try
        if ischar(default) && ~iscell(arg); arg = char(arg); end
        if isstring(default) && ~iscell(arg); arg = string(arg); end
    catch ME
        %warning(ME.message)
    end
end


