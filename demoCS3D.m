function demoCS3D(fnameBlue, fnameGreen, fnameRed, fnameGAD, fnameLayers, outdir, subRegion, writeOutput)
    global cfg;

    if nargin==7,
        writeOutputFile=true;
    else
        writeOutputFile=writeOutput;
    end

    % Load aux functions...
    addpath('./aux/');

    % Identify all the needed paths and file names
    [pathBlue,  baseFNameBlue,  extBlue ] = fileparts(fnameBlue );
    [pathGreen, baseFNameGreen, extGreen] = fileparts(fnameGreen);
    [pathRed,   baseFNameRed,   extRed  ] = fileparts(fnameRed  );

    blueFile  = sprintf('%s%s', baseFNameBlue,  extBlue );
    greenFile = sprintf('%s%s', baseFNameGreen, extGreen);
    redFile   = sprintf('%s%s', baseFNameRed,   extRed  );
    dataFile  = 'alldata.mat';

    myDate = strrep(strrep(datestr(now), ':', '-'), ' ', '_');

    outdirFinal = sprintf('%s/resultsMatlab_%s/'      , outdir, myDate);
    outdirCache = sprintf('%s/resultsMatlab_%s/cache/', outdir, myDate);

    if exist(outdirCache, 'dir') ~= 7, mkdir(outdirCache); end

    printParameters(outdirCache, subRegion);

    debug_printf(cfg.debug_level_, '********************************************************\n');
    debug_printf(cfg.debug_level_, '*** Running Step 1/6: Binarization of three channels ***\n');
    debug_printf(cfg.debug_level_, '********************************************************\n');

    ts1=tic;

    % Process the whole stack of blue, green and red channels
    if cfg.use8bitImages_,
	                             processImage3D(blueFile,  pathBlue,  outdirCache, 'gray' , subRegion, true , 0);
	                             processImage3D(greenFile, pathGreen, outdirCache, 'gray' , subRegion, false, 0);
	    if cfg.useSulforChannel_ processImage3D(redFile,   pathRed,   outdirCache, 'gray' , subRegion, false, 0); end
	else,
	                             processImage3D(blueFile,  pathBlue,  outdirCache, 'blue' , subRegion, true , 0);
	                             processImage3D(greenFile, pathGreen, outdirCache, 'green', subRegion, false, 0);
	    if cfg.useSulforChannel_ processImage3D(redFile,   pathRed,   outdirCache, 'red'  , subRegion, false, 0); end
	end

    % Process interneurons (always in gray channel)
    if cfg.useGADChannel_ interneurons=processInterneurons(fnameGAD, 0); end

    toc(ts1);

    debug_printf(cfg.debug_level_, '*********************************************\n');
    debug_printf(cfg.debug_level_, '*** Running Step 2/6: Merging of channels ***\n');
    debug_printf(cfg.debug_level_, '*********************************************\n');

    ts2=tic;

    % Merge the information of four channels
    blueFileBin  = sprintf('%s/%s.comps.tif', outdirCache, blueFile );
    greenFileBin = sprintf('%s/%s.comps.tif', outdirCache, greenFile);
    redFileBin   = sprintf('%s/%s.comps.tif', outdirCache, redFile  );

    if cfg.useGADChannel_
        [interNeuN, ~      , ~]=mergeDAPIandNeuN3D(loadBinaryImage(greenFileBin), interneurons);
        [interDAPI, newDAPI, ~]=mergeDAPIandNeuN3D(loadBinaryImage( blueFileBin), interNeuN   );

        newNeuN=loadBinaryImage(greenFileBin)-interNeuN;

        save(sprintf('%s/%s', outdirCache, dataFile), 'interneurons', 'interNeuN', 'interDAPI', '-v7.3');
        clear interneurons interNeuN interDAPI;
    else,
        newDAPI=loadBinaryImage( blueFileBin);
        newNeuN=loadBinaryImage(greenFileBin);
    end

    [neurons, notNeurons, inDoubt]=mergeDAPIandNeuN3D(newDAPI, newNeuN);

    clear newDAPI newNeuN;

    notNeurons=or(notNeurons, inDoubt);

    if cfg.useSulforChannel_,
        vessels=loadBinaryImage(redFileBin);
        [notNeurons, merged] = merge3Dnew(notNeurons, vessels);

        writeMHDFile(merged , outdirFinal, 'vessels_merged.tif');
    

        % Save vars for further processing
        if cfg.useGADChannel_
            save(sprintf('%s/%s', outdirCache, dataFile), 'vessels', 'merged', '-append', '-v7.3');
        else,
            save(sprintf('%s/%s', outdirCache, dataFile), 'vessels', 'merged', '-v7.3');
        end

        % Clear variables that are no longer needed
        clear vessels merged;
    end

    % Clear variables that are no longer needed
    clear inDoubt;

    toc(ts2);

    debug_printf(cfg.debug_level_, '*************************************************\n');
    debug_printf(cfg.debug_level_, '*** Running Step 3/6: Reconstructing 3D Cells ***\n');
    debug_printf(cfg.debug_level_, '*************************************************\n');

    ts3=tic;

                                     finalImg      = reconstruct3DCells(neurons   );
    if cfg.segmentNonNeuronalCells_, notNeuronsImg = reconstruct3DCells(notNeurons); end

    % Save vars for further processing
    if cfg.useSulforChannel_,
        save(sprintf('%s/%s', outdirCache, dataFile), 'neurons', 'notNeurons', '-append', '-v7.3');
    else,
        save(sprintf('%s/%s', outdirCache, dataFile), 'neurons', 'notNeurons', '-v7.3');
    end

    % Clear variables that are no longer needed
    clear neurons notNeurons;

    toc(ts3);

    % Apply second splitting algorithm: divide a cell in Z if size is decreasing and,
    % suddenly, it starts to increase again (two cells perfectly overlapping in z)
    % finalImg = splitCellsBySize(finalImg, splittedByCentroids);

    debug_printf(cfg.debug_level_, '**********************************************\n');
    debug_printf(cfg.debug_level_, '*** Running Step 4/6: Removing Small Cells ***\n');
    debug_printf(cfg.debug_level_, '**********************************************\n');

    ts4=tic;

    % Final filtering: we remove all cells that are smaller than a number
    % of pixels (counting all the pixels in all the slices)
                                     finalImg      = filterSmallCells(finalImg     );
    if cfg.segmentNonNeuronalCells_, notNeuronsImg = filterSmallCells(notNeuronsImg); end

    toc(ts4);

    debug_printf(cfg.debug_level_, '*******************************************************************************************************\n');
    debug_printf(cfg.debug_level_, '*** Running Step 5/6: Fix small/big cells reassigning them to their neurons/notNeurons counterparts ***\n');
    debug_printf(cfg.debug_level_, '*******************************************************************************************************\n');

    ts5=tic;

    [finalImg, notNeuronsImg] = fixBySize(finalImg, notNeuronsImg);

    finalImg     =removeOversegmentedCells(finalImg     );
    notNeuronsImg=removeOversegmentedCells(notNeuronsImg);

    toc(ts5);

    debug_printf(cfg.debug_level_, '*************************************************************\n');
    debug_printf(cfg.debug_level_, '*** Running Step 6/6: Writing Output Files (if requested) ***\n');
    debug_printf(cfg.debug_level_, '*************************************************************\n');

    ts6=tic;

    % Write the final segmentation as a MHD file to open it in Espina
    if writeOutputFile,
        % Save vars for further processing
        save(sprintf('%s/%s', outdirCache, dataFile), 'finalImg', 'notNeuronsImg', '-append', '-v7.3');

        if ~isempty(subRegion),
            finalImgRel=relocateImage(fnameBlue, finalImg, subRegion);
        else
            finalImgRel=finalImg;
        end

        % Should we split cells by layers or not?
        if isempty(fnameLayers),
            writeMHDFile(finalImgRel, outdirFinal, 'neurons.tif');
        else
            splitLabelsPerLayer(fnameLayers, finalImgRel, outdirFinal, 'neurons');
        end

        if cfg.segmentNonNeuronalCells_,
            if ~isempty(subRegion),
                notNeuronsImgRel=relocateImage(fnameBlue, notNeuronsImg, subRegion);
            else
                notNeuronsImgRel=notNeuronsImg;
            end

            % Should we split cells by layers or not?
            if isempty(fnameLayers),
                writeMHDFile(notNeuronsImgRel, outdirFinal, 'non_neurons.tif');
            else
                splitLabelsPerLayer(fnameLayers, notNeuronsImgRel, outdirFinal, 'not_neurons');
            end
        end
    end

    clear finalImg notNeuronsImg;

    toc(ts6);
end

function printParameters(outdirCache, subRegion)
    global cfg;

    outFile = sprintf('%s/parameters.txt', outdirCache);
    fID     = fopen(outFile, 'w');

    fields = fieldnames(Config);

    for i=1:length(fields),
        if strcmp(class(cfg.(fields{i})), 'char'),
            fprintf(fID, '%s: %s\n', fields{i}, cfg.(fields{i}));
        end
        if strcmp(class(cfg.(fields{i})), 'double'),
            vals = cfg.(fields{i});
            fprintf(fID, '%s: ', fields{i});
            fprintf(fID, '%f ', cfg.(fields{i}));
            fprintf(fID, '\n');
        end
        if strcmp(class(cfg.(fields{i})), 'logical'),
            if cfg.(fields{i}),
                val = 'true';
            else,
                val = 'false';
            end
            fprintf(fID, '%s: %s\n', fields{i}, val);
        end
    end

    if ~isempty(subRegion),
        fprintf(fID, '\n');

        fields = fieldnames(subRegion);

        for i=1:length(fields),
            fprintf(fID, '%s: %d\n', fields{i}, subRegion.(fields{i}));
        end
    end

    fclose(fID);
end

function [newImg] = relocateImage(img, labels, shift)
    data=imfinfo(img);

    h=data.Height;
    w=data.Width;
    z=numel(data);

    newImg=zeros(h,w,z);
    newImg(shift.minX:shift.maxX, shift.minY:shift.maxY, shift.minZ:shift.maxZ)=labels;
end
