function [finalImgOut] = addToFinalImage(finalImg, img, x0, y0, z0)
    finalImgOut = finalImg;

    % ToDo: Think of a better implementation of this loop.
    % This loop replaces commented line below to avoid overlapping
    % of bounding boxes that leads to "zeroing" some parts of overlapping
    % cells
    for r=1:size(img, 1),
        for s=1:size(img, 2),
            for t=1:size(img, 3),
                if img(r, s, t) ~= 0,
                    finalImgOut(x0+r-1, y0+s-1, z0+t-1) = img(r, s, t);
                end
            end
        end
    end
end