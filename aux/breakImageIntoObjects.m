function [objects, shifts] = breakImageIntoObjects(slice)
    global cfg;

    debug_printf(cfg.debug_level_, '-> Searching for 2D connected components and measuring properties...');

    CC    = bwconncomp (slice, cfg.nNeighbors_);
    stats = regionprops(CC, 'BoundingBox', 'PixelIdxList');

    debug_printf(cfg.debug_level_, ' done\n\n');
    debug_printf(cfg.debug_level_, sprintf('Number of connected components: %d.\n\n', CC.NumObjects));
    debug_printf(cfg.debug_level_, '-> Processing each component to break it into multiple cells...\n');

    objects = cell(0);
    shifts  = cell(0);
    oldNObjects=0;

    times=0;

    for i=1:CC.NumObjects,
        [times] = tracePercentage(i, CC.NumObjects, times);

        bbox = stats(i).BoundingBox;

        x0 = round(bbox(1,1));
        y0 = round(bbox(1,2));

        xinc = round(bbox(1,3));
        yinc = round(bbox(1,4));

        % Is it faster to compute the sub image before or after?
        subImg = zeros(size(slice));
        subImg(stats(i).PixelIdxList) = 1;
        subImg=subImg(y0:y0+yinc-1, x0:x0+xinc-1);

        imgInv = ~logical(subImg);
        imgInv = uint8(imgInv.*255);
        imgJ = MIJ.createImage('', imgInv, false);

        % If the subimage is too small, the MIJ plug-in will fail to create an image
        if isequal(imgJ, []), continue; end

        edm = ij.plugin.filter.EDM();
        edm.setup('watershed', imgJ);
        edm.run(imgJ.getProcessor());

        splittedImg=MIJ.get(imgJ);
        splittedImg=~splittedImg;
        comps=logical(splittedImg./255);

        CC2    = bwconncomp (comps, cfg.nNeighbors_);
        stats2 = regionprops(CC2, 'PixelIdxList');

        for j=1:CC2.NumObjects,
            pieces = zeros(size(subImg));
            pieces(stats2(j).PixelIdxList) = 1;
            objects{end+1}  = pieces;
            shifts {end+1}  = cell(0);
            shifts {end}{1} = x0;
            shifts {end}{2} = y0;
        end

        oldNObjects=length(objects);
    end

    debug_printf(cfg.debug_level_, '\n-> Done\n\n');
end
