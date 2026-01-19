function writeMHDFile(finalImg, outdir, fname)
    global cfg;

    addpath('./libs/slicer_2011.08.18/stacks/');

    debug_printf(cfg.debug_level_, '==> Writing TIFF and SEGMHA files...\n');

    outFile = sprintf('%s/labels_%s', outdir, fname);

    % Create a label map with different random colors for each cell
    maxCells = max (finalImg(:));

    debug_printf(cfg.debug_level_, '-> Writing TIFF file...');

    % Convert the label image into a RGB image
    map = zeros(maxCells, 3);

    for i=1:maxCells,
        map(i, 1) = rand(1);
        map(i, 2) = rand(1);
        map(i, 3) = rand(1);
    end

    for i=1:size(finalImg, 3),
        imwrite(label2rgb(finalImg(:,:,i), map), outFile, 'writemode', 'append', 'Compression', 'none');
    end

    debug_printf(cfg.debug_level_, ' done\n');

    debug_printf(cfg.debug_level_, '-> Writing SEGMHA file...');

    % Write the image in 'Meta Image' format (to open it in Espina)
    [~, baseFName, ~] = fileparts(fname);
    outFile  = sprintf('%s/%s.mhd',    outdir, baseFName);
    outFile2 = sprintf('%s/%s.segmha', outdir, baseFName);

    finalImg = finalImg(end:-1:1,:,end:-1:1);

    % Important: outFile should not have any dot as 'metaImageWrite' removes
    % all the extensions and this could make the append of the extra information
    % to fail and create a different file
    metaImageWrite(finalImg, outFile);

    % Append Espina specific attributes
    fID = fopen(outFile, 'a');

    fprintf(fID, '\nElementSpacing = 1 1 1\n\n');

    % ToDo: Review how labels are printed here. Maybe first label is missing???
    % labs=unique(finalImg);

    uni=[];
    for i=1:size(finalImg, 3),
        uniTmp=unique(finalImg(:,:,i));
        uni=[uni, uniTmp'];
    end
    labs=unique(uni);

    labs(labs==0)=[];
    for i=1:length(labs),
        fprintf(fID, 'Object: label=%d segment=1 selected=1\n', labs(i));
    end

    fprintf(fID, '\nCounting Brick: inclusive=[0, 0, 0] exclusive=[0, 0, 0]\n\n');
    fprintf(fID, 'Segment: name="Cell" value=1 color= 255, 0, 0\n');

    fclose(fID);

    movefile(outFile, outFile2);

    debug_printf(cfg.debug_level_, ' done\n');

    fprintf('\n ==> Overall regions: %d <==\n', length(labs));

    debug_printf(cfg.debug_level_, '\n==> Done\n');
end
