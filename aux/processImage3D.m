function [slice, Is, Js, Ks, auxs, shifts, areas] = processImage3D (fname, indir, outdir, channel, subRegion, doublePass, overrideLevel, dry)
    global cfg;

    if nargin == 7,
        dryRun = false;
    else
        dryRun = dry;
    end

    inputFile = sprintf('%s/%s',           indir,  fname);
    cacheFile = sprintf('%s/%s.comps.tif', outdir, fname);
    dataFile  = sprintf('%s/%s.mat',       outdir, fname);

    % Initialize subRegion with values to select the whole image if it is not given
    infoFile = imfinfo(inputFile);
    if isempty(subRegion),
        subRegion.minX=1;
        subRegion.minY=1;
        subRegion.minZ=1;
        subRegion.maxX=infoFile(1).Height;
        subRegion.maxY=infoFile(1).Width;
        subRegion.maxZ=numel(infoFile);
    end

    debug_printf(cfg.debug_level_, sprintf('==> Binarizing original image: %s\n', inputFile));

    if exist(dataFile, 'file') == 0,
        if exist(cacheFile, 'file') == 0,
            infoFile = imfinfo(inputFile);
            num_images = numel(infoFile);

            % parfor i=1:1:num_images,
            for i=subRegion.minZ:1:subRegion.maxZ,
                debug_printf(cfg.debug_level_, sprintf('-> Processing slice %d/%d:\n', i, num_images));
                [~, slice(:,:,i-subRegion.minZ+1), ~, ~] = binarizeImage(inputFile, i, channel, subRegion, doublePass, true, overrideLevel);
                debug_printf(cfg.debug_level_, sprintf('-> Processing slice %d/%d -> Done!!!\n', i, num_images));
            end

            for i=1:1:size(slice, 3),
                if ~dryRun, imwrite(slice(:,:,i), cacheFile, 'writemode', 'append', 'Compression', 'none'); end
            end
        elseif exist(cacheFile, 'file') == 2,
            debug_printf(cfg.debug_level_, '-> Opening cache file...');

            infoFile = imfinfo(cacheFile);
            num_images = numel(infoFile);

            for i=1:num_images, [slice(:,:,i)] = imread(cacheFile, i, 'Info', infoFile); end

            debug_printf(cfg.debug_level_, ' done\n');
        else
            fprintf('Error: opening cache file "%s".\n', cacheFile);
            return;
        end

        [CC, stats, subImages, auxs, Is, Js, Ks, shifts, areas] = breakBinaryImage3D(slice);

        if ~dryRun,
            debug_printf(cfg.debug_level_, '-> Saving data file...');
            save(dataFile, 'slice', 'CC', 'stats', 'subImages', 'auxs', 'Is', 'Js', 'Ks', 'shifts', 'areas', '-v7.3');
            debug_printf(cfg.debug_level_, ' done\n');
        end
    elseif exist(dataFile, 'file') == 2,
        debug_printf(cfg.debug_level_, '-> Opening data file...');
        load(dataFile, 'slice', 'CC', 'stats', 'subImages', 'auxs', 'Is', 'Js', 'Ks', 'shifts', 'areas');
        debug_printf(cfg.debug_level_, ' done\n');
    else
        fprintf('Error: opening data file "%s".\n', dataFile);
        return;
    end

    debug_printf(cfg.debug_level_, sprintf('==> Binarizing original image: %s -> Done!!!\n\n', inputFile));
end
