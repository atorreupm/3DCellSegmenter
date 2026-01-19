function [CC, stats, subImages, auxs, Is, Js, Ks, shifts, areas] = breakBinaryImage3D(slice, useConnComp)
    global cfg;

    if nargin == 1,
        useConnComp = true;
    end

    debug_printf(cfg.debug_level_, '-> Searching for connected components and measuring properties...');

    areas = [];
    stats = [];

    if useConnComp,
        CC    = bwconncomp(slice, cfg.conn3D_); 
        stats = regionprops(CC   , 'Area', 'Centroid', 'PixelList', 'BoundingBox');

        numObjects = CC.NumObjects;

        % Proceed as usual: just copy areas
        for i=1:numObjects,
            area  = stats(i).Area;
            areas = [areas area];
        end
    else
        CC     = 0;
        stats1 = regionprops(slice, 'Area', 'Centroid', 'PixelList', 'BoundingBox');

        % We take here of the empty labels that regionprops will
        % include in the statistics
        for i=1:length(stats1),
            area  = stats1(i).Area;
            if area > 0,
                areas = [areas area];
                stats = [stats stats1(i)];
            end
        end

        numObjects = length(stats);
    end

    debug_printf(cfg.debug_level_, ' done\n\n');
    debug_printf(cfg.debug_level_, sprintf('Number of connected components: %d.\n\n', numObjects));
    debug_printf(cfg.debug_level_, '-> Processing each component...\n');

    times   = 0;

    % parfor i=1:numObjects,
    for i=1:numObjects,
        [times] = tracePercentage(i, numObjects, times);

        bbox = stats(i).BoundingBox;

        x0 = round(bbox(1,1));
        y0 = round(bbox(1,2));
        z0 = round(bbox(1,3));

        xinc = round(bbox(1,4));
        yinc = round(bbox(1,5));
        zinc = round(bbox(1,6));

        subImage = slice(y0:y0+yinc-1, x0:x0+xinc-1, z0:z0+zinc-1);
        subImages{i} = subImage;

        pixels = stats(i).PixelList;
        pixels(:,1) = pixels(:,1) - x0 + 1;
        pixels(:,2) = pixels(:,2) - y0 + 1;
        pixels(:,3) = pixels(:,3) - z0 + 1;
        auxs{i} = subImage .* 0;

        for j=1:size(pixels,1),
            auxs{i}(pixels(j,2), pixels(j,1), pixels(j,3)) = 1;
        end

        [I, J, K] = ind2sub(size(auxs{i}), find(auxs{i}(:, :, :)));
        Is{i} = I;
        Js{i} = J;
        Ks{i} = K;
        
        shifts{i}{1} = x0;
        shifts{i}{2} = y0;
        shifts{i}{3} = z0;
    end

    debug_printf(cfg.debug_level_, '\n-> Done\n\n');
end
