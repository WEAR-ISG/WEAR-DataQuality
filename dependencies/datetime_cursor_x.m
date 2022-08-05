function output_txt = datetime_cursor_x(obj,event_obj)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).

pos = get(event_obj,'Position');
%tmp = pos(1);
%pos(1) = pos(1)/86400 + 719529;
%output_txt = {['X: ',num2str(tmp)],['Y: ',num2str(pos(2))],['Stamp: ',datestr(pos(1))]};

output_txt = {['X: ', num2str(pos(1))],['Y: ', num2str(pos(2))],['Stamp: ', unix2time(pos(1), 'format', 'string')]};

% If there is a Z-coordinate in the position, display it as well
if length(pos) > 2
    output_txt{end+1} = ['Z: ',num2str(pos(3),4)];
end
