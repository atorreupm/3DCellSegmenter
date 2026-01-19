% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    reassignPixels                                             %
% Description: Reassign pixels in a layer incorrectly divided so that it  %
%              is divided similarly to a contiguous layer correctly       %
%              splitted                                                   %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [newLabels, blobs] = reassignPixels (slice, centroids)
    % Initialize some aux variables...
    nObj  = length(centroids);
    blobs = cell(1, nObj);
    dists = [];

    [r, c]     = find(slice);
    pxToAssign = find(slice);

    for k=1:nObj,
        blobs{k} = zeros(size(slice));

        distsAux = arrayfun(@(i,j) euclideanDistance(centroids{k}(1), centroids{k}(2), j, i), r, c);

        distsAux2 = repmat(Inf, size(slice, 1) * size(slice, 2), 1);
        distsAux2(pxToAssign) = distsAux;

        dists = [dists, distsAux2];
    end

    [~, minIdx] = min(dists, [], 2);

    for k=1:length(pxToAssign),
        which = minIdx(pxToAssign(k));
        blobs{which}(pxToAssign(k)) = 1;
    end

    newLabels = zeros(size(slice));

    for k=1:size(blobs, 2),
        newLabels=newLabels+blobs{k}*k;
    end
end
