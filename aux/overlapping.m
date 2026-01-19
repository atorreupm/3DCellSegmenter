% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    overlapping                                                %
% Description: Measures the overlapping of two blobs, either the maximum  %
%              or the minimum one                                         %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [over] = overlapping (data1, data2, sense)
    inter = sum(ismember(data1, data2));
    over1 = inter / length(data1);
    over2 = inter / length(data2);

    if     sense == 'min', over = min(over1, over2);
    elseif sense == 'max', over = max(over1, over2);
    else   error ('sense should be either min or max');
    end
end
