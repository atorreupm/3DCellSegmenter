function [CC, stats, subImages, auxs, Is, Js, shifts, areas] = breakBinaryImage(slice, debug_level)
    global cfg;

    debug_printf(debug_level, '-> Searching for connected components and measuring properties...');

    CC    = bwconncomp(slice, cfg.conn3D_); 
    stats = regionprops(CC, 'Area', 'Centroid', 'PixelList', 'BoundingBox', 'ConvexImage');

    debug_printf(debug_level, ' done\n\n');
    debug_printf(debug_level, sprintf('Number of connected components: %d.\n\n', CC.NumObjects));
    debug_printf(debug_level, '-> Processing individual connected components in 1st pass...');

    areas = [];

    for i=1:CC.NumObjects,
        area  = stats(i).Area;
        areas = [areas area];
    end

    maxArea = max(areas);

    subImages = {};
    auxs      = {};
    Is        = {};
    Js        = {};
    shifts    = {};


    for i=1:CC.NumObjects,

        bbox = stats(i).BoundingBox;

        x0 = round(bbox(1,1));
        y0 = round(bbox(1,2));

        xinc = round(bbox(1,3));
        yinc = round(bbox(1,4));

        subImage = slice(y0:y0+yinc-1, x0:x0+xinc-1);
        subImages{i} = subImage;

        pixels = stats(i).PixelList;
        pixels(:,1) = pixels(:,1) - x0 + 1;
        pixels(:,2) = pixels(:,2) - y0 + 1;
        auxs{i} = subImage .* 0;

        for j=1:size(pixels,1),
            auxs{i}(pixels(j,2), pixels(j,1)) = 1;
        end

        [I, J] = ind2sub(size(auxs{i}), find(auxs{i}(:, :)));
        Is{i} = I;
        Js{i} = J;
        
        shifts{i}{1} = x0;
        shifts{i}{2} = y0;
    end

    debug_printf(debug_level, ' done\n');
end
