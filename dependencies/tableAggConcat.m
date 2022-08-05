function out = tableAggConcat(varargin)

if nargin == 1
    out = varargin{1};
    return;
end

out = table();
agg_names = {};

for t = varargin
    if ~istable(t{:})
        error('One of the provided arguments is not a table!')
    end

    agg_name = {};
    agg_vars = {};
    for vn = t{:}.Properties.VariableNames
        vn_split = strsplit(vn{:}, '_');
        agg_name = {agg_name{:}, vn_split{1}};
        agg_vars = {agg_vars{:}, strjoin(vn_split(2:end), '_')};
    end
    agg_name = unique(agg_name);
    if numel(agg_name) > 1
        error('Each table must only contain one aggregator prefix!')
    end

    %newT = renamevars(t{:}, t{:}.Properties.VariableNames, agg_vars);
    t{:}.Properties.VariableNames = agg_vars;

    out = [out; t{:}];
    agg_names = [agg_names, agg_name];
end

out.Properties.RowNames = agg_names;

end