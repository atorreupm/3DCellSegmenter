% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    euclideanDistance                                          %
% Description: Given two points, computes the euclidean distance.         %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [dist] = euclideanDistance(x0, y0, x1, y1)
    dist = sqrt((x0 - x1)^2 + (y0 - y1)^2);
end
