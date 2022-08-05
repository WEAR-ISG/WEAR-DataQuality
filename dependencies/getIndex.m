function [ index ] = getIndex( cellarray, string, pos )
%GETINDEX ( cellarray, string ) search for STRING in CELLARRAY and return
%corresponding index.

    if isempty(string)
        index = 0;
    else
        indexC = strfind(cellarray,string);
        index = find(not(cellfun('isempty', indexC)));
        if nargin == 3
            index = index(pos);
        end
    end
end

