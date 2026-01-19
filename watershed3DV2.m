function [newLabels] = watershed3DV2(data)
    global cfg;

    % Load aux functions...
    addpath('./aux/');

    %% Initialization of aux variables
    nSlices       = size(data, 3);
    labels        = cell(1, nSlices);
    allStats      = cell(1, nSlices);
    nPerSlice     = zeros(1, nSlices);

    beg_=1;
    end_=nSlices;

    %% Process each slide separately
    for i=beg_:end_,
        img = logical(data(:,:,i));

        %% %%%%%%%%% %%
        %% WATERSHED %%
        %% %%%%%%%%% %%
        imgInv = ~img;
        imgInv = uint8(imgInv.*255);
        imgJ = MIJ.createImage('', imgInv, false);
        edm = ij.plugin.filter.EDM();
        edm.setup('watershed', imgJ);
        edm.run(imgJ.getProcessor());
        splittedImg=MIJ.get(imgJ);

        splittedImg=~splittedImg;
        splittedImg=logical(splittedImg./255);

        components = bwconncomp (splittedImg, cfg.nNeighbors_);
        
        if components.NumObjects == 0,
            comps2       = bwconncomp (img, cfg.nNeighbors_);
            allStats{i}  = regionprops(comps2, 'Centroid');
            labels{i}    = labelmatrix(comps2);
            nPerSlice(i) = 1;
        else
            allStats{i}  = regionprops(components, 'Centroid');
            labels{i}    = labelmatrix(components);
            nPerSlice(i) = components.NumObjects;
        end
    end

    [allStats, labels, nPerSlice] = preprocessSmallPieces(data, allStats, labels, nPerSlice);

    %% Divide the slices into blocks and join some of these blocks if needed

    % Divide the 3D blob into pieces that will be studied independently for
    % repairment
    [blocks, depths, nObjects] = divideBlobIntoBlocks(nPerSlice, data, labels, allStats);

    % Fix the different blocks so that they are internally homogeneous with
    % regards the number of cells
    [fixedBlocks, fixedDepths] = fixAllBlocks(blocks, depths, nObjects);

    mustRepeat = 1;
    while mustRepeat,
        % Try to join the beginning and end of a block with another block given
        % that the overlapping between their touching blobs is enough
        [canJoin_i, canJoin_j, canJoin_pos_i, canJoin_pos_j, joinSpecial] = tryToJoinBlocks(fixedBlocks, fixedDepths);

        % Once selected the candidate blocks to be joined, we actually join
        % them if the overlapping between the representative slices is over a
        % threshold
        [fixedBlocks, fixedDepths, mustRepeat] = doJoinBlocks(canJoin_i, canJoin_j, canJoin_pos_i, canJoin_pos_j, joinSpecial, fixedBlocks, fixedDepths);
    end

    % Recompute number of objects per cell after block joining for a second
    % round of fixing blocks
    newNObjects=cell(1, length(fixedBlocks));

    deleteBlocks={};
    deleteSubBlocks=cell(1, length(fixedBlocks));

    for i=1:length(fixedBlocks),
        newNObjects{i}=zeros(1, length(fixedBlocks{i}));

        for j=1:length(fixedBlocks{i}),
            cmps = bwconncomp (fixedBlocks{i}{j} > 0, cfg.nNeighbors_);
            newNObjects{i}(j)=cmps.NumObjects;
            if cmps.NumObjects == 0,
                if isempty(deleteSubBlocks{i}),
                    deleteSubBlocks{i}={};
                end
                deleteSubBlocks{i}{end+1}=j;
            end
        end
    end

    for i=length(deleteSubBlocks):-1:1,
        if ~isempty(deleteSubBlocks{i}),
            for j=length(deleteSubBlocks{i}):-1:1,
                fixedBlocks{i}(deleteSubBlocks{i}{j})=[];
                fixedDepths{i}(deleteSubBlocks{i}{j})=[];
                newNObjects{i}(deleteSubBlocks{i}{j})=[];
            end
            if isempty(fixedBlocks{i}),
                deleteBlocks{end+1}=i;
            end
        end
    end

    if ~isempty(deleteBlocks),
        for i=1:length(deleteBlocks),
            fixedBlocks(deleteBlocks{i})=[];
            fixedDepths(deleteBlocks{i})=[];
            newNObjects(deleteBlocks{i})=[];
        end
    end

    [fixedBlocks, fixedDepths] = fixAllBlocks(fixedBlocks, fixedDepths, newNObjects);

    % Finally, assign independent labels to each of the fixed blocks
    newLabels = assignLabels(size(data), fixedBlocks, fixedDepths);

    % plotLabels(newLabels, '');
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% MAIN FUNCTIONS (Directly called from the main program) %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SMALL (UTILITY) FUNCTIONS %%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    assignJoinLineToLabel                                      %
% Description: Assign the point of a join line to a randomly chosen       %
%              adjacent component                                         %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [slice2, IDend] = assignJoinLineToLabel(joinLines, shift, slice, IDstart)
    y0 = shift{1};
    x0 = shift{2};

    slice2 = slice;

    for i=1:length(joinLines),
        line = joinLines{i};

        for r=1:size(line, 1),
            for s=1:size(line, 2),
                if line(r, s) == 1,
                    (100) + (IDstart + i - 1);
                    slice2(x0+r-1, y0+s-1) = (100) + (IDstart + i - 1);
                end
            end
        end
    end

    IDend = (IDstart + length(joinLines) - 1);
end

%% DIVIDE BLOB INTO BLOCKS %%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    divideBlobIntoBlocks                                       %
% Description: Divides a 3D blob into blocks with the same number of 2D   %
%              blobs                                                      %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [blocks, depths, nObjects] = divideBlobIntoBlocks(nPerSlice, data, labels, stats)
    global cfg;

    %% %%%%%% %%
    %% PART 1 %%
    %% %%%%%% %%

    % In 'blobs' we store the different blobs identified in each slice (coming
    % from the clump splitting or splitted in this function). In 'centroids' we
    % cache the centroids of each blob. For those coming from the clump
    % splitting they are already stored in 'stats', but we have also to re-compute
    % them for blobs splitted in this function
    blobs     = cell(0);
    centroids = cell(0);

    % Initialize first set of blobs (for first slice)
    for i=1:nPerSlice(1),
        blobs{1}{i} = labels{1} == i;
        centroids{1}{i} = round(stats{1}(i).Centroid);
    end

    % For the remaining slices, try to guess if those slices must be splitted,
    % according to their overlapping with blobs in the previous slice
    for i=2:length(labels),
        % Matrix to store overlapping between each blob in slice i-1 and each
        % blob in current slice according to the provided info in nPerSlice(i)
        overs = zeros(length(blobs{i-1}), nPerSlice(i));

        for j=1:length(blobs{i-1}),
            for k=1:nPerSlice(i),
                % ToDo: decide which sense to use here...
                overs(j, k) = overlapping(find(blobs{i-1}{j}), find(labels{i} == k), 'min');
            end
        end

        % Check if for some blob of the current slice it overlaps similarly with
        % more than one blob in the previous slice. In such a case, we divide
        % that blob into N-parts and reassign pixels to the new labels.
        divided = false;

        % Do not forget to initialize the cell-arrays for this slice
        blobs    {i} = {};
        centroids{i} = {};

        if length(blobs{i-1}) > 1,
            for j=1:nPerSlice(i),
                % Take the maximum overlapping of this slice (or a part of it,
                % as it could be already splitted in several parts) as a
                % reference and search for overlapping values with other slices
                % within an interval
                % ToDo: Try to impose a minimum value here so that we do not
                % take values such as 0.35 and 0.05 in consideration (or use
                % smaller intervals)
                v = max(overs(:, j));

                % Avoid weird behavior when all the overlapping values are
                % zero. Without this, we will end with empty blobs that
                % complicate things.
                if v==0, continue; end

                inter = intersect(find(overs(:, j) >= v - cfg.intersectionInterval_), find(overs(:, j) <= v + cfg.intersectionInterval_));

                % If two or more overlappings are of similar size, try to split
                % the current slice into parts according to their overlapping
                % with blobs in the current slice
                if length(inter) > 1,
                    % Create the data structures needed to call 'reassignPixels'
                    cent = cell(1, length(inter));

                    for k=1:length(inter),
                        cent{k} = centroids{i-1}{inter(k)};
                    end

                    [newLabels, ~] = reassignPixels(labels{i} == j, cent);

                    % Store the new blobs and their corresponding centroids
                    for k=1:nPerSlice(i),
                        if k ~= j,
                            blobs    {i}{end+1} = labels{i} == k;
                            centroids{i}{end+1} = round(stats{i}(k).Centroid);
                        else
                            interStats = regionprops(newLabels, 'Centroid');

                            for l=1:length(inter),
                                % Again, avoid weird behavior when the
                                % overlappings are low and some of them are
                                % zero (this would add empty blobs)
                                if overs(inter(l), j)==0, continue; end
                                blobs    {i}{end+1} = (newLabels == l);
                                % centroids{i}{end+1} = round(interStats(l).Centroid);
                                centroids{i}{end+1} = centroids{i-1}{inter(l)};
                            end
                        end
                    end

                    divided = true;
                    break;
                end
            end
        end

        % If the number of blobs equals one or the current blob has not been
        % divided, copy the original info passed in 'labels'
        if ~divided,
            for j=1:nPerSlice(i),
                blobs    {i}{j} = labels{i} == j;
                centroids{i}{j} = stats{i}(j).Centroid;
            end
        end
    end

    %% %%%%%% %%
    %% PART 2 %%
    %% %%%%%% %%

    % Now divide the structure into connected components with maximum
    % overlapping

    % Initialize 'blocks' with the info of the first slice in 'blobs'
    blocks   = cell(0);
    depths   = cell(0);
    nObjects = cell(0);

    for i=1:length(blobs{1}), blocks{end+1} = {blobs{1}{i}}; end

    for i=1:length(blocks),
        depths  {end+1} = {1};
        nObjects{end+1} = ones(1);
    end

    % For the remaining blobs, assign maximizing the overlapping
    for i=2:length(blobs)
        addTo = zeros(1, length(blobs{i}));
        overs = zeros(size(blobs{i}, 2), size(blocks, 2));

        % Compute the overlapping of each blob of the current slice with each
        % block (actually with the last blob of that block)
        for j=1:size(blobs{i}, 2),
            for k=1:size(blocks, 2),
                % ToDo: decide which sense to use here...
                overs(j, k) = overlapping(find(blobs{i}{j}), find(blocks{k}{end}), 'min');

                % Avoid assigning an overlapping to slices not touching themselves
                if depths{k}{end} < i - 1, overs(j, k) = 0; end
            end
        end

        % For each blob of the current slice, compute the block it should be
        % added to
        for j=1:size(blobs{i}, 2),
            s = sum(overs, 2);

            % ToDo: this was changed from max to min... Test!!!
            % [~, p1] = min(s);
            [~, p1] = max(s);

            done = false;
            while ~done,
                [v, p2] = max(overs(p1, :));
                done = isempty(find(addTo == p2, 1));
                if ~done, overs(p1, p2) = -1; end

                % If we find a '-1' as max value for this row this only
                % could mean that we are in the first steps adding cells to
                % blocks and we still have only one block and a new cell
                % arrives. If this is not the case, abort with an error.
                if v == -1,
                    break;
                    if size(blocks, 2) == 1,
                        break;
                    else
                        error('Error: This should not happen. Number of blocks: %d. Number of new cells: %d', size(blocks, 2), size(blobs{i}, 2));
                    end
                end
            end

            if v<=0, overs(p1, :) = -100; continue; end

            % If we only enforce minimum overlapping in first slice of the
            % block, we might have problems...
            if v <= cfg.minOverlapping_,
                addTo(p1) = 0;
            else
                addTo(p1) = p2;
            end

            % overs(:, p2) = -1;
            overs(p1, :) = -100;
        end

        newBlocks   = cell(0);
        newDepths   = cell(0);
        newNObjects = cell(0);

        mx = max(addTo);

        % Check if there is any overlapping between layers. If there is,
        % process the slice to guess to which block to add blobs. If there
        % is not, just add the blobs as new blocks.
        if mx > 0,
            for j=1:mx,
                if ~isempty(find(addTo == j, 1)),
                    res = zeros(size(data(:,:,1)));
                    cntObjects = 0;
                    for k=1:length(addTo),
                        if addTo(k) == j,
                            res = or(res, blobs{i}{k});
                            cntObjects = cntObjects + 1;
                            if depths{j}{end} ~= i - 1, warning('This should not happen: assigning a blob to a block with depth not in accordance.'); end
                        elseif addTo(k) == 0,
                            newBlocks  {end+1} = blobs{i}{k};
                            newDepths  {end+1} = i;
                            newNObjects{end+1} = ones(1);
                            addTo(k) = -1; % Avoid repeating this blob again
                        end
                    end
                    
                    if cntObjects > 0,
                        blocks  {j}{end+1} = res;
                        depths  {j}{end+1} = i;
                        nObjects{j}(end+1) = cntObjects;
                    end
                end
            end

            for j=1:length(newBlocks),
                blocks  {end+1}{1} = newBlocks  {j};
                depths  {end+1}{1} = newDepths  {j};
                nObjects{end+1}    = newNObjects{j};
            end
        else
            for k=1:length(addTo),
                blocks{end+1}{1} = blobs{i}{k};
                depths{end+1}{1} = i;
                nObjects{end+1}  = ones(1);
            end
        end
    end
end


%% FIX BLOCKS %%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    fixAllBlocks                                               %
% Description: Iteratively calls function 'fixBlock' trying to guess the  %
%              correct number of cells per block and the new assignment   %
%              of labels to pixels. With those new labels, the new list   %
%              of blocks is constructed, as well as the list of depths.   %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [fixedBlocks, fixedDepths] = fixAllBlocks(blocks, depths, nObjects)
    global cfg;

    fixedBlocks = cell(0);
    fixedDepths = cell(0);

    for i=1:length(blocks),
        blockComponents = cell(1, length(blocks{i}));
        blockLabels     = cell(1, length(blocks{i}));
        blockPixels     = cell(1, length(blocks{i}));
        blockAllStats   = cell(1, length(blocks{i}));
        
        for j=1:length(blocks{i}),
            blockComponents{j} = bwconncomp (blocks{i}{j}, cfg.nNeighbors_);
            blockAllStats{j}   = regionprops(blockComponents{j}, 'Centroid');
            blockLabels{j}     = labelmatrix(blockComponents{j});
            blockPixels{j}     = {};
            
            for k=1:blockComponents{j}.NumObjects,
                blockPixels{j}{k} = find(blockLabels{j} == k);
            end
        end
        
        [newBlockLabels, goodNCells] = fixBlock(blocks{i}, depths{i}, nObjects{i}, blockComponents, blockAllStats, blockLabels, blockPixels);

        lastBlock = length(fixedBlocks);

        % ToDo: we should make sure in here that labels correspond among them
        % in different blocks (i.e.: pixels belonging to label 1 in block 1
        % overlap with those with label 1 in block 2 and not with those with
        % label 2). We do not have any guarantee about this.
        if goodNCells > 1,
            for j=1:goodNCells,
                blocksTmp = cell(0);
                depthsTmp = cell(0);
                pos = 1;

                for k=1:length(newBlockLabels),
                    bl = (newBlockLabels{k} == j);
                    if sum(bl(:)) > 0,
                        blocksTmp{pos} = bl;
                        depthsTmp{pos} = depths{i}{k};
                            
                        pos = pos + 1;
                    else
                        % We have not still found any blob with this label, so
                        % we must keep searching
                        if isempty(blocksTmp),
                            continue;
                        % We already have found some blobs with that label, so
                        % we must stop (there will be no more)
                        else
                            break;
                        end
                    end
                end

                if ~isempty(blocksTmp),
                    fixedBlocks{lastBlock + j} = blocksTmp;
                    fixedDepths{lastBlock + j} = depthsTmp;
                end
            end
        else
            fixedBlocks{lastBlock + 1} = blocks{i};
            fixedDepths{lastBlock + 1} = depths{i};
        end
    end
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    fixAllBlocks                                               %
% Description: Iteratively calls function 'fixBlock' trying to guess the  %
%              correct number of cells per block and the new assignment   %
%              of labels to pixels. With those new labels, the new list   %
%              of blocks is constructed, as well as the list of depths.   %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [newBlockLabels, goodNCells] = fixBlock(block, depths, nObjects, blockComponents, blockAllStats, blockLabels, blockPixels)
    global cfg;

    % Compute the approximate number of correct objects
    goodNCellsV = guessGoodNCells(nObjects, block);

    nSlices        = length(block);
    newBlockLabels = blockLabels;
    newBlockPixels = cell(size(blockPixels));
    newBlockStats  = cell(size(blockAllStats));

    % Repeat the whole process in those cases in which we do not have enough
    % information for some slices (to a maximum of 10 times)
    nTries    = 0;
    allOk     = false;
    fixed     = zeros(1, nSlices);
    unChanged = zeros(1, nSlices);

    while ~allOk && nTries < 10,
        nTries = nTries + 1;
        allOk  = true;

        % Process each slice individually
        for i=1:nSlices,        
            if fixed(i) || unChanged(i), continue; end

            which = haveInfoForCell(i, nSlices, blockComponents, goodNCellsV, fixed);

            if blockComponents{i}.NumObjects ~= goodNCellsV(i),
                if which < 0,
                    allOk = false;
                    continue;
                end
            end

            if blockComponents{i}.NumObjects < goodNCellsV(i),
                if goodNCellsV(i) - blockComponents{i}.NumObjects == 1,
                    if goodNCellsV(i) == 2,
                        if fixed(which) == 1,
                            newBlockStats{i} = newBlockStats{which};
                        else
                            newBlockStats{i} = cell(1, 2);
                            newBlockStats{i}{1} = round(blockAllStats{which}(1).Centroid);
                            newBlockStats{i}{2} = round(blockAllStats{which}(2).Centroid);
                        end

                        [newBlockLabels{i}, newBlockPixels{i}] = reassignPixels(block{i}, newBlockStats{i});
                        fixed(i) = 1;
                    else
                        newBlockLabels{i} = blockLabels{i};
                        % warning('Repairment of blobs with more than two cells not yet implemented');
                    end
                else
                    newBlockLabels{i} = blockLabels{i};
                    % warning('Repairment of blobs with size difference greater than two not yet implemented');
                end
            elseif blockComponents{i}.NumObjects > goodNCellsV(i),
                currentNcells = blockComponents{i}.NumObjects;

                while currentNcells > goodNCellsV(i),
                    % ToDo: creo que no va a funcionar cuando hay que mezclar
                    % mas de una vez: blockLabels y newBlockLabels
                    if fixed(which) == 1,
                        [~, pos11, pos12, ~] = bestOverlappingNToN(blockLabels{i}, newBlockLabels{which}, currentNcells);
                    else
                        [~, pos11, pos12, ~] = bestOverlappingNToN(blockLabels{i},    blockLabels{which}, currentNcells);
                    end

                    if pos11 ~= -1,
                        newBlockLabels{i} = mergeCells(pos11, pos12, blockLabels{i}, currentNcells);
                    else
                        break;
                    end

                    currentNcells = currentNcells - 1;
                end

                % Do not forget to update centroid positions just in case
                % this block is further processed
                newBlockStats{i} = cell(1, currentNcells);
                for j=1:currentNcells,
                    props = regionprops(newBlockLabels{i} == j, 'Centroid');
                    newBlockStats{i}{j} = round(props(1).Centroid);
                end

                fixed(i) = 1;
            else
                newBlockLabels{i} = blockLabels{i};
                unChanged(i) = 1;
            end
        end
    end

    if nTries > 1,
        ;
       % debug_printf(cfg.debug_detailed_level_, sprintf('Warning: More than one try used in \"fixBlock\": %d\n', nTries));
    end

    goodNCells = max(goodNCellsV);

    for i=1:nSlices-1,
        for j=1:max(newBlockLabels{i}(:)),
            labJ = find(newBlockLabels{i} == j);
            if ~isempty(labJ),
                [~, which] = bestOverlapping1ToN(labJ, newBlockLabels{i+1});
                if j ~= which,
                    newBlockLabels{i+1}(newBlockLabels{i+1} == j    ) = 100;
                    newBlockLabels{i+1}(newBlockLabels{i+1} == which) = j;
                    newBlockLabels{i+1}(newBlockLabels{i+1} == 100  ) = which;
                end
            end
        end
    end
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    guessGoodNCells                                            %
% Description: Compute the approximate number of correct objects          %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [goodNCells] = guessGoodNCells(nObjects, block)
    global cfg;

    countOptions = accumarray(nObjects(:), 1);

    % maxCO        = max(countOptions);
    % occurrences  = sum(countOptions == maxCO);
    % 
    % if occurrences > 1 && maxCO > 3,
    %     goodNCells = max(find(countOptions == maxCO));
    %     warning('It is not clear which is the proper number of cells. Using the largest possible...');
    % else
    %     goodNCells = min(find(countOptions == maxCO));
    % 
    %     if occurrences > 1,
    %         warning('It is not clear which is the proper number of cells. Using the smallest possible...');
    %     end
    % end

    goodMaxNCells = 1;
    goodNCells    = ones(1, length(block));

    % If there is more than one 'opinion' on the number of blobs
    if sum(countOptions > 0) > 1,
        maxNObjects  = max(nObjects(:));
        overallSize  = zeros(1, maxNObjects);
        overallElems = zeros(1, maxNObjects);
        overallMean  = zeros(1, maxNObjects);
        
        for i=1:length(block),
            overallSize (nObjects(i)) = overallSize (nObjects(i)) + size(find(block{i} == 1), 1);
            overallElems(nObjects(i)) = overallElems(nObjects(i)) + 1;
        end

        overallMean(1) = overallSize(1) / overallElems(1);

        for i=2:length(overallSize),
            overallMean(i) = overallSize(i) / overallElems(i);
            if overallMean(i) > cfg.sizeRatio_ * overallMean(i-1), goodMaxNCells = i; end
        end

        if goodMaxNCells > 1,
            for i=1:length(block),
                sz = size(find(block{i} == 1), 1);
                [~, p] = min(abs(overallMean - sz));
                goodNCells(i) = p;
                % Sometimes, a division line makes the difference in the
                % number of pixels necessary to change from 1 to 2 cells
                if goodNCells(i) == 1 && nObjects(i) == 2,
                    sz2 = size(find(imerode(imdilate(block{i}, cfg.dilationMask_), cfg.dilationMask_) == 1), 1);
                    [~, p] = min(abs(overallMean - sz2));
                    goodNCells(i) = p;
                end
            end
        end
    end
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    haveInfoForCell                                            %
% Description: Check if we have information either in the upper slice or  %
%              in the lower slice to split this blob. If we do have, we   %
%              return which slice to use. If not, we return -1.           %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [isGood] = haveInfoForCell(which, nSlices, blockComponents, goodNCellsV, fixed)
    isGood = -1;

    if which > 1       && goodNCellsV(which) == goodNCellsV(which-1) && (blockComponents{which-1}.NumObjects == goodNCellsV(which-1) || fixed(which-1) == 1), isGood = which-1; return; end
    if which < nSlices && goodNCellsV(which) == goodNCellsV(which+1) && (blockComponents{which+1}.NumObjects == goodNCellsV(which+1) || fixed(which+1) == 1), isGood = which+1; return; end
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    bestOverlappingNToN                                        %
% Description: Finds the best overlapping between two blobs of one set    %
%              and one blob of another set in order to merge the first    %
%              two blobs and match them with the best overlapping one in  %
%              the other set                                              %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [val, pos11, pos12, pos2] = bestOverlappingNToN(labels1, labels2, nCells)
    val   =  0;
    pos11 = -1;
    pos12 = -1;
    pos2  = -1;

    for i=1:nCells,
        [v, p] = bestOverlapping1ToN(find(labels1 == i), labels2);
        
        for j=1:nCells,
            if i==j, continue; end

            over = overlapping(union(find(labels1 == i), find(labels1 == j)), find(labels2 == p), 'min');
            inc  = over - v;
            
            if inc > val,
                val = inc;
                pos11 = i;
                pos12 = j;
                pos2 = p;
            end
        end
    end
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    bestOverlapping1ToN                                        %
% Description: Finds the best overlapping between one blob and a set of   %
%              other blobs, and returns the position of the best matching %
%              blob and the overlapping value                             %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [val, which] = bestOverlapping1ToN(target, candidates)
    overs=zeros(1,max(candidates(:)));

    for i=1:max(candidates(:)),
        overs(i) = overlapping(target, find(candidates == i), 'min');
    end

    [val, which] = max(overs(:));
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    mergeCells                                                 %
% Description: Merges two cells into one with the same label              %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [newImg] = mergeCells(v1, v2, origImg, nCells)
    newImg = origImg;
    newImg(newImg == v2    ) = v1;
    newImg(newImg == nCells) = v2;
end

%% JOIN BLOCKS %%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    tryToJoinBlocks                                            %
% Description: Analyzes the fixed blocks creating a structure of pairs of %
%              blocks that could be joined (they are adjacent or overlap).%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [canJoin_i, canJoin_j, canJoin_pos_i, canJoin_pos_j, joinSpecial] = tryToJoinBlocks(fixedBlocks, fixedDepths)
    canJoin_i     = cell(0);
    canJoin_j     = cell(0);
    canJoin_pos_i = cell(0);
    canJoin_pos_j = cell(0);
    joinSpecial   = cell(0);

    for i=1:length(fixedBlocks),
        for j=1:length(fixedBlocks),
            if i==j, continue; end

            begin_i = fixedDepths{i}{1};
            end_i   = fixedDepths{i}{length(fixedBlocks{i})};
            begin_j = fixedDepths{j}{1};
            end_j   = fixedDepths{j}{length(fixedBlocks{j})};
            
            if (begin_i <= begin_j) && (begin_j <= end_i + 1) && (end_i < end_j),
                canJoin_i    {end+1} = i;
                canJoin_j    {end+1} = j;
                canJoin_pos_i{end+1} = length(fixedBlocks{i});
                canJoin_pos_j{end+1} = (end_i - begin_j + 1) + 1;
                joinSpecial  {end+1} = false;
            elseif (begin_i < begin_j) && (begin_j <= end_i + 1) && (end_i >= end_j),
                canJoin_i    {end+1} = i;
                canJoin_j    {end+1} = j;
                canJoin_pos_i{end+1} = begin_j - begin_i + 1;
                canJoin_pos_j{end+1} = 1;
                joinSpecial  {end+1} = true;
            end
        end
    end
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    doJoinBlocks                                               %
% Description: Takes the list of pairs of blocks thar could be            %
%              potentially joined and test if they are actually 'joinable'%
%              (basically, if they overlap enough and depths match). If   %
%              this happens to be true, information of both blocks is     %
%              combined. Both blocks are marked as touched in order to    %
%              avoid problems with indices. If more joins are needed, the %
%              function returns mustRepeat=true to force that it is       %
%              called again.                                              %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [fixedBlocks2, fixedDepths2, mustRepeat] = doJoinBlocks(canJoin_i, canJoin_j, canJoin_pos_i, canJoin_pos_j, joinSpecial, fixedBlocks, fixedDepths)
    global cfg;

    touched = zeros(1, length(fixedBlocks));

    fixedBlocks2 = fixedBlocks;
    fixedDepths2 = fixedDepths;

    for i=1:length(canJoin_i),
        pos_i = canJoin_i{i};
        pos_j = canJoin_j{i};

        % If we are trying to merge again a block already merged, we abort for
        % safety reasons (some of the indices may not be at the correct
        % position)
        if touched(pos_i) ~= 0 || touched(pos_j) ~= 0, continue; end

        if ~isempty(fixedBlocks2{pos_i}) && ~isempty(fixedBlocks2{pos_j}),
            if ~joinSpecial{i}
                over = overlapping(find(fixedBlocks2{pos_i}{canJoin_pos_i{i}} == 1), find(fixedBlocks2{pos_j}{canJoin_pos_j{i}} == 1), 'max');

                % ToDo: This is a test to fix some particular situations. Test
                % with care!!!!
                p1 = canJoin_pos_i{i} - (canJoin_pos_j{i} - 1);
                p2 = 1;

                if p1 > 0,
                    overAux = overlapping(find(fixedBlocks2{pos_i}{p1} == 1), find(fixedBlocks2{pos_j}{p2} == 1), 'max');
                    if overAux > over, over = overAux; end
                end
            else
                if canJoin_pos_i{i} - 1 > 0,
                    over1 = overlapping(find(fixedBlocks2{pos_i}{canJoin_pos_i{i} - 1} == 1), find(fixedBlocks2{pos_j}{canJoin_pos_j{i}} == 1), 'max');
                else
                    over1 = overlapping(find(fixedBlocks2{pos_i}{canJoin_pos_i{i} + 1} == 1), find(fixedBlocks2{pos_j}{canJoin_pos_j{i}} == 1), 'max');
                end
                
                if canJoin_pos_i{i} + 1 <= length(fixedBlocks2{pos_i}),
                    over2 = overlapping(find(fixedBlocks2{pos_i}{canJoin_pos_i{i} + 1} == 1), find(fixedBlocks2{pos_j}{canJoin_pos_j{i}} == 1), 'max');
                else
                    over2 = overlapping(find(fixedBlocks2{pos_i}{canJoin_pos_i{i} - 1} == 1), find(fixedBlocks2{pos_j}{canJoin_pos_j{i}} == 1), 'max');
                end
                
                over  = max(over1, over2);
            end
            
            if over > cfg.minOverlappingToJoin_,
                mixedBlocks = cell(0);
                mixedDepths = cell(0);
                    
                if ~joinSpecial{i},
                    mx = fixedDepths2{pos_j}{end} - fixedDepths2{pos_i}{1} + 1;
                    start_join = length(fixedBlocks2{pos_i}) - canJoin_pos_j{i} + 2;
                    end_join = start_join + canJoin_pos_j{i} - 1;

                    for j=1:mx,
                        if j < start_join,
                            mixedBlocks{j} =    fixedBlocks2{pos_i}{j};
                            mixedDepths{j} =    fixedDepths2{pos_i}{j};
                        elseif j >= start_join && j < end_join,
                            mixedBlocks{j} = or(fixedBlocks2{pos_i}{j}, fixedBlocks2{pos_j}{j - start_join + 1});
                            mixedDepths{j} =    fixedDepths2{pos_i}{j};
                        else
                            mixedBlocks{j} =    fixedBlocks2{pos_j}{j - start_join + 1};
                            mixedDepths{j} =    fixedDepths2{pos_j}{j - start_join + 1};
                        end
                    end
                else
                    mx = length(fixedBlocks2{pos_i});
                    start_join = canJoin_pos_i{i};
                    end_join = start_join + length(fixedBlocks2{pos_j});

                    for j=1:mx,
                        if j < start_join,
                            mixedBlocks{j} =    fixedBlocks2{pos_i}{j};
                            mixedDepths{j} =    fixedDepths2{pos_i}{j};
                        elseif j >= start_join && j < end_join,
                            mixedBlocks{j} = or(fixedBlocks2{pos_i}{j}, fixedBlocks2{pos_j}{j - start_join + 1});
                            mixedDepths{j} =    fixedDepths2{pos_i}{j};
                        else
                            mixedBlocks{j} =    fixedBlocks2{pos_i}{j};
                            mixedDepths{j} =    fixedDepths2{pos_i}{j};
                        end
                    end
                end

                fixedBlocks2{pos_i} = {};
                fixedDepths2{pos_i} = {};
                fixedBlocks2{pos_j} = mixedBlocks;
                fixedDepths2{pos_j} = mixedDepths;
                
                touched(pos_i) = 1;
                touched(pos_j) = 1;
            end
        end
    end

    % Remove empty blocks once moved (if any)
    fixedBlocks2 = fixedBlocks2(~cellfun('isempty', fixedBlocks2));
    fixedDepths2 = fixedDepths2(~cellfun('isempty', fixedDepths2));

    mustRepeat = ~isempty(find(touched ~= 0, 1));
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% AUX FUNCTIONS (Called from many places in the program) %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% AUX FUNCTIONS %%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    assignLabels                                               %
% Description: assign independent labels to each of the fixed blocks      %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [labels] = assignLabels(sz, blocks, depths)
    labels = zeros(sz);

    if ~iscell(blocks), error('assignLabels: cell array expected.'); end

    if ~iscell(blocks{1}),
        blocksAux    = cell(1);
        blocksAux{1} = blocks;
        depthsAux    = cell(1);
        depthsAux{1} = depths;
    else
        blocksAux = blocks;
        depthsAux = depths;
    end

    for i=1:size(blocksAux, 2),
        for j=1:size(blocksAux{i}, 2),
            labels(:,:,depthsAux{i}{j}) = labels(:,:,depthsAux{i}{j}) + blocksAux{i}{j} * i;
        end
    end
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    plotBlock                                                  %
% Description: Plots a block of overlapping slices of a cell              %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function plotBlock(block)
    figure;
    nrows = fix(size(block, 2) / 5) + 1;
    for j=1:size(block, 2),
        subplot(nrows,5,j);
        imshow(block{j});
    end
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    mustIgnoreSlice                                            %
% Description: Checks if this slice is made up of small pieces that must  %
%              not be divided                                             %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [smallPieces] = mustIgnoreSlice(comps)
    global cfg;
    smallPieces=false;

    if comps.NumObjects>1,
        for ii=1:comps.NumObjects,
            smallPieces=smallPieces || (length(comps.PixelIdxList{ii}) < cfg.minCellSizeForSplitting_);
        end
    end
end

function [newAllStats, newLabels, newNPerSlice] = preprocessSmallPieces(data, allStats, labels, nPerSlice)
    global cfg;

    newAllStats =allStats;
    newLabels   =labels;
    newNPerSlice=nPerSlice;

    nSlices=size(data, 3);

    % Convert data from a matrix into a cell array to allow its use with guessGoodNCells()
    dataAsBlock={};
    for i=1:nSlices,
        dataAsBlock{i}=data(:,:,i);
    end

    % With the current status, estimate the correct number of cells per slice
    goodNCells=guessGoodNCells(nPerSlice, dataAsBlock);

    % Initialize a cell array to store the slices that must be re-labeled
    mustBeReassigned={};

    % Find those slices that should be re-labeled (those bigger than previous ones,
    % smaller than the next one and highly overlapping with the latter, being that
    % one a single cell and the previous one multiple cells)
    for i=1:nSlices,
        % Only if there are discrepancies
        if goodNCells(i)==1 && nPerSlice(i)>1,

            % Find the next slice with one single cell (to avoid comparison with other
            % problematic slices with more than one cells)
            next=i;
            while next<nSlices,
                next=next+1;
                if nPerSlice(next)==1,
                    break;
                end
            end

            % Check if the conditions hold (split for better readability)
             leftCondition = (i==1)        || (i> 1 && overlapping(find(data(:,:,i)==1), find(data(:,:,i-1 )==1), 'min')<cfg.minSmallOverLeft  && sum(sum(data(:,:,i)))>sum(sum(data(:,:,i-1 ))));
            rightCondition = (next<nSlices          && overlapping(find(data(:,:,i)==1), find(data(:,:,next)==1), 'max')>cfg.minSmallOverRight && sum(sum(data(:,:,i)))<sum(sum(data(:,:,next))));

            if leftCondition && rightCondition,
                mustBeReassigned{end+1}=[i:next-1];
            end
        end
    end

    % Reassign those labels marked in the previous step. We check which side we should
    % consider as reference by computing the overlapping to the left and to the right
    % and reassigning labels accordingly.
    for i=1:length(mustBeReassigned),
        over1=0;
        over2=0;

        p1=mustBeReassigned{i}(1);
        p2=mustBeReassigned{i}(end);

        if p1>1,       over1=overlapping(find(data(:,:,p1)==1), find(data(:,:,p1-1)==1), 'max'); end
        if p2<nSlices, over2=overlapping(find(data(:,:,p2)==1), find(data(:,:,p2+1)==1), 'max'); end

        if over1>over2,
            for j=p1:p2,
                [newAllStats{j}, newLabels{j}, newNPerSlice(j)] = reassignLabelsToSmallPieces(data(:,:,j), newAllStats{j-1}, newLabels{j-1}, newNPerSlice(j-1));
            end
        else
            for j=p2:-1:p1,
                [newAllStats{j}, newLabels{j}, newNPerSlice(j)] = reassignLabelsToSmallPieces(data(:,:,j), newAllStats{j+1}, newLabels{j+1}, newNPerSlice(j+1));
            end
        end
    end
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    reassignLabelsToSmallPieces                                %
% Description: Reassign labels to small pieces ignored in the splitting   %
%              phase                                                      %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function [newStats, newLabels, newNPerSlice] = reassignLabelsToSmallPieces(slice, nextStats, nextLabels, nextNPerSlice)
    newStats=nextStats;
    newLabels=zeros(size(nextLabels));
    newLabels(slice~=0)=nextLabels(slice~=0);
    newNPerSlice=nextNPerSlice;
end
