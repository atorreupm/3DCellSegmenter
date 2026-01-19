function [newLabels, cnt] = splitBigCells(labels, labShift)
	global cfg;

	newLabels=uint16(zeros(size(labels)));

	[~, ~, ~, auxs, ~, ~, ~, shifts, areas] = breakBinaryImage3D(labels, false);

    % Aux var to trace progress
    times = 0;

    cnt=labShift+1;

    cellsProcessed=0;

    for i=1:length(auxs),
        % Trace progress
    	[times] = tracePercentage(i, length(auxs), times);

        % Compute bounding box of the 3D structure
    	y0=shifts{i}{2};
        yinc=size(auxs{i}, 1);
        x0=shifts{i}{1};
        xinc=size(auxs{i}, 2);
        z0=shifts{i}{3};
        zinc=size(auxs{i}, 3);

        oldLab=max(unique(labels(y0:y0+yinc-1, x0:x0+xinc-1, z0)));

        if size(auxs{i}, 3) <= 25 && areas(i) < cfg.bigThreshold_,
            newLabels=addToFinalImage(newLabels, auxs{i}.*cnt, y0, x0, z0);
            cnt=cnt+1;
            imgT=auxs{i}.*cnt;
            labs=unique(imgT(:));
            labs(labs==0)=[];

            continue;
        end

        if size(auxs{i}, 1)<10 || size(auxs{i}, 2) < 10,
            continue;
        else
            cellsProcessed=cellsProcessed+1;

            % This is to remove division lines (watershed should correctly
            % identify multiple regions if they exist)
            auxs{i}=imdilate(auxs{i}, cfg.dilationMask_);
            auxs{i}=imdilate(auxs{i}, cfg.dilationMask_);
            auxs{i}=imerode(auxs{i}, cfg.dilationMask_);
            auxs{i}=imerode(auxs{i}, cfg.dilationMask_);

            [subNewLabels, newCNT] = splitBigCellsMethod1(auxs{i}, cnt);

            if newCNT==cnt+2,
                vals1=subNewLabels==newCNT-2;
                sz1=sum(vals1(:));
                vals2=subNewLabels==newCNT-1;
                sz2=sum(vals2(:));

                if     (sz2>sz1) && ((sz1/sz2)<=0.1),
                    subNewLabels(subNewLabels==(newCNT-2))=0;
                    subNewLabels(subNewLabels==(newCNT-1))=1;
                    newCNT=cnt+1;
                    auxs{i}=subNewLabels;
                elseif (sz1>sz2) && ((sz2/sz1)<=0.1),
                    subNewLabels(subNewLabels==(newCNT-1))=0;
                    subNewLabels(subNewLabels==(newCNT-2))=1;
                    newCNT=cnt+1;
                    auxs{i}=subNewLabels;
                end
            end

            if newCNT==cnt+1,
                midSlice=auxs{i}(:,:,round(size(auxs{i}, 3)/2));
                avgOver=0;

                avgOver=avgOver+overlapping(find(auxs{i}(:,:,1  )~=0), find(midSlice~=0), 'max');
                avgOver=avgOver+overlapping(find(auxs{i}(:,:,end)~=0), find(midSlice~=0), 'max');
                avgOver=avgOver/2;

                if avgOver>0.80,
                    subNewLabels=uint16(zeros(size(auxs{i})));
                    subNewLabels(auxs{i}~=0)=cnt;
                    newCNT=cnt+1;
                else
                    [subNewLabels, newCNT] = splitBigCellsMethod2(auxs{i}, cnt);
                end
            end

            labs=unique(subNewLabels(:));
            labs(labs==0)=[];

            cnt=newCNT;

            newLabels=addToFinalImage(newLabels, subNewLabels, y0, x0, z0);
        end
    end
end

function [subNewLabels, cnt] = splitBigCellsMethod1(img, cnt)
    cents =cell (1, size(img, 3));
    nCents=zeros(1, size(img, 3));

    % Hack needed to fix the appropriate type for keys
    maxNObjectsList=containers.Map({0}, [0]);

    beginSplit=-1;
    endSplit  =-1;

    beginSplitLargest=-1;
    endSplitLargest  =-1;
    largestSplitSize = 0;

    % Safe values. Will not do anything
    maxNObjects=1;
    maxPos=1;
    maxNObjectsCount=0;

    for j=1:size(img, 3),
        % Compute centroids for each slice
        if size(img(:,:,j), 1)==1 && size(img(:,:,j), 2)==1,
            cents{j}=regionprops(img(:,:,j), 'Centroid', 'Area');    
        else
            cents{j}=computeWatershed(img(:,:,j));
        end

        % Store the number of centroids per slice
        nCents(j)=length(cents{j});

        % We will also count how many times each number of centroids
        % appears. This is to avoid over-segmentation
        % (example: 1 time 4 centroids vs. 3 times 2 centroids)
        nCurCents=nCents(j);
         curCents= cents{j};

        maxArea=0;

        for k=1:nCents(j),
            if curCents(k).Area > maxArea,
                maxArea=curCents(k).Area;
            end
        end

        % In some degenerated cases, regionprops may report many centroids
        % of areas of just one pixel (this happens in rasterized lines,
        % each part of the line is a different area). We just ignore them.
        for k=1:nCents(j),
            if curCents(k).Area < 10 || curCents(k).Area < (maxArea * 0.20),
                nCurCents=nCurCents-1;
            end
        end

        % Increment the number of occurrences for each number of centroids
        if isKey(maxNObjectsList, nCurCents),
            maxNObjectsList(nCurCents)=maxNObjectsList(nCurCents)+1;
        else,
            maxNObjectsList(nCurCents)=1;
        end
    end

    % Remove the artificial '0' used to initialize and the '1', which would
    % be majority in most of the cases
    remove(maxNObjectsList, 0);
    remove(maxNObjectsList, 1);

    % Retrieve the keys of the map (i.e., the different numbers of possible
    % splitting - centroids)
    ks=keys(maxNObjectsList);

    % Which number of centroids, apart from one, is more frequent?
    for j=1:length(ks),
        if maxNObjectsList(ks{j})>maxNObjectsCount,
            maxNObjectsCount=maxNObjectsList(ks{j});
            maxNObjects=ks{j};
        end
    end

    [c1, c2, p1, p2] = selectReferenceSlicesAndCentroids(img);

    % If the previous heuristic decides that we must split, compute reference
    % slices and position to start the splitting
    if maxNObjects>1,

        finished=false;

        while maxPos==1 && maxNObjects>1,
            candidatePositions=find(nCents==maxNObjects);

            if length(candidatePositions)>0,
                [~, poscand]=min(arrayfun(@(x) abs(x-size(img, 3)/2), candidatePositions));
                maxPos=candidatePositions(poscand);

                if maxPos<0.20*size(img, 3) || maxPos>0.80*size(img, 3),
                    maxPos=1;
                    maxNObjects=maxNObjects-1;
                end
            else,
                maxNObjects=maxNObjects-1;
            end
        end

        badDividingPos=false;

        if maxPos<p1 || maxPos>p2,
            badDividingPos=true;
        end

        inter1=sum(ismember(find(img(:,:,p1)~=0), find(img(:,:,maxPos)~=0)));
        over1 =inter1/length(find(img(:,:,maxPos)~=0));

        inter2=sum(ismember(find(img(:,:,p2)~=0), find(img(:,:,maxPos)~=0)));
        over2 =inter2/length(find(img(:,:,maxPos)~=0));

        completelyContained=false;

        if over1>0.90 || over2>0.90,
            completelyContained=true;
        end
    end

    if maxNObjects>1 && ~completelyContained && ~badDividingPos,
        subNewLabels=uint16(zeros(size(img)));

        for j=1:size(img, 3),
            over=overlapping(find(img(:,:,j)~=0), find(img(:,:,maxPos)~=0), 'min');

            pos=findClosestCentroid(nCents, maxNObjects, j);
            [subNewLabels(:,:,j), ~]=reassignPixels(img(:,:,j), convertCentroids(cents{pos}));

            lb=unique(subNewLabels(:,:,j));
            lb(1)=[];

            % The only easy way to fix this is when we have just two labels
            if length(lb)==2,
                vals1=subNewLabels(:,:,j)==lb(1);
                vals2=subNewLabels(:,:,j)==lb(2);
                area1=sum(vals1(:));
                area2=sum(vals2(:));

                if over<0.80 && area2>area1,
                    tmpSlice=subNewLabels(:,:,j);
                    tmpSlice(vals1)=lb(2);
                    subNewLabels(:,:,j)=tmpSlice;
                elseif over<0.80 && area1>area2,
                    tmpSlice=subNewLabels(:,:,j);
                    tmpSlice(vals2)=lb(1);
                    subNewLabels(:,:,j)=tmpSlice;
                elseif beginSplit==-1,
                    beginSplit=j;
                end
            end

            % Repeat the computing, as labels may have changed
            lb=unique(subNewLabels(:,:,j));
            lb(1)=[];

            if length(lb)==1 && beginSplit~=-1 && endSplit==-1,
                endSplit=j-1;

                if endSplit-beginSplit+1 > largestSplitSize,
                    largestSplitSize =endSplit-beginSplit+1;

                    beginSplitLargest=beginSplit;
                      endSplitLargest=  endSplit;

                    beginSplit=-1;
                      endSplit=-1;
                end
            end
        end

        % This is to ensure that there are no jumps between labels due
        % to the assignment to the majority label at the splitting borders
        if beginSplitLargest>2 && endSplitLargest~=-1,
            tmpImg1=subNewLabels(:,:,1:beginSplitLargest-1);
            tmpImg2=subNewLabels(:,:,endSplitLargest+1:end);

            lb1=unique(tmpImg1);
            lb1(1)=[];

            lb2=unique(tmpImg2);
            lb2(1)=[];

            splitCents1=regionprops(subNewLabels(:,:,beginSplitLargest), 'Centroid');
            splitCents2=regionprops(subNewLabels(:,:,  endSplitLargest), 'Centroid');

            dist11=norm([round(c1.Centroid(2)), round(c1.Centroid(1))] - [round(splitCents1(1).Centroid(2)), round(splitCents1(1).Centroid(1))]);
            dist12=norm([round(c1.Centroid(2)), round(c1.Centroid(1))] - [round(splitCents1(2).Centroid(2)), round(splitCents1(2).Centroid(1))]);

            dist21=norm([round(c2.Centroid(2)), round(c2.Centroid(1))] - [round(splitCents2(1).Centroid(2)), round(splitCents2(1).Centroid(1))]);
            dist22=norm([round(c2.Centroid(2)), round(c2.Centroid(1))] - [round(splitCents2(2).Centroid(2)), round(splitCents2(2).Centroid(1))]);

            if dist11<dist12,
                relab1=subNewLabels(round(splitCents1(1).Centroid(2)), round(splitCents1(1).Centroid(1)), beginSplitLargest);
            else
                relab1=subNewLabels(round(splitCents1(2).Centroid(2)), round(splitCents1(2).Centroid(1)), beginSplitLargest);
            end

            if dist21<dist22,
                relab2=subNewLabels(round(splitCents2(1).Centroid(2)), round(splitCents2(1).Centroid(1)), beginSplitLargest);
            else
                relab2=subNewLabels(round(splitCents2(2).Centroid(2)), round(splitCents2(2).Centroid(1)), beginSplitLargest);
            end

            if relab1==0 || relab2==0,
                subNewLabels = img.*cnt;
                cnt=cnt+1;
                return;
            end

            tmpImg1(tmpImg1~=0)=relab1;
            subNewLabels(:,:,1:beginSplitLargest-1)=tmpImg1;

            tmpImg2(tmpImg2~=0)=relab2;
            subNewLabels(:,:,endSplitLargest+1:end)=tmpImg2;
        end

        % Ensure that labels in reassignPixels were assigned correctly in consecutive
        % slices and they were not inverted
        oldNSlices=length(unique(subNewLabels(:,:,1)));

        for j=2:size(subNewLabels, 3),
            newNSlices=length(unique(subNewLabels(:,:,j)));

            if oldNSlices==3 && newNSlices==3,
                centsOld=regionprops(subNewLabels(:,:,j-1), 'Centroid');
                centsNew=regionprops(subNewLabels(:,:,j  ), 'Centroid');

                dist1=norm([round(centsOld(1).Centroid(2)), round(centsOld(1).Centroid(1))] - [round(centsNew(1).Centroid(2)), round(centsNew(1).Centroid(1))]);
                dist2=norm([round(centsOld(1).Centroid(2)), round(centsOld(1).Centroid(1))] - [round(centsNew(2).Centroid(2)), round(centsNew(2).Centroid(1))]);

                if dist1<dist2,
                    if (subNewLabels(round(centsOld(1).Centroid(2)), round(centsOld(1).Centroid(1)), j-1) == subNewLabels(round(centsNew(2).Centroid(2)), round(centsNew(2).Centroid(1)), j)) && (subNewLabels(round(centsOld(2).Centroid(2)), round(centsOld(2).Centroid(1)), j-1) == subNewLabels(round(centsNew(1).Centroid(2)), round(centsNew(1).Centroid(1)), j)),
                        tmpImg=subNewLabels(:,:,j);
                        tmpImg(tmpImg==subNewLabels(round(centsNew(1).Centroid(2)), round(centsNew(1).Centroid(1)), j))=100;
                        tmpImg(tmpImg==subNewLabels(round(centsNew(2).Centroid(2)), round(centsNew(2).Centroid(1)), j))=subNewLabels(round(centsOld(2).Centroid(2)), round(centsOld(2).Centroid(1)), j-1);
                        tmpImg(tmpImg==100                                                                            )=subNewLabels(round(centsOld(1).Centroid(2)), round(centsOld(1).Centroid(1)), j-1);
                        subNewLabels(:,:,j)=tmpImg;
                   end
                else
                    if (subNewLabels(round(centsOld(1).Centroid(2)), round(centsOld(1).Centroid(1)), j-1) == subNewLabels(round(centsNew(1).Centroid(2)), round(centsNew(1).Centroid(1)), j)) && (subNewLabels(round(centsOld(2).Centroid(2)), round(centsOld(2).Centroid(1)), j-1) == subNewLabels(round(centsNew(2).Centroid(2)), round(centsNew(2).Centroid(1)), j)),
                        tmpImg=subNewLabels(:,:,j);
                        tmpImg(tmpImg==subNewLabels(round(centsNew(1).Centroid(2)), round(centsNew(1).Centroid(1)), j))=100;
                        tmpImg(tmpImg==subNewLabels(round(centsNew(2).Centroid(2)), round(centsNew(2).Centroid(1)), j))=subNewLabels(round(centsOld(1).Centroid(2)), round(centsOld(1).Centroid(1)), j-1);
                        tmpImg(tmpImg==100                                                                            )=subNewLabels(round(centsOld(2).Centroid(2)), round(centsOld(2).Centroid(1)), j-1);
                        subNewLabels(:,:,j)=tmpImg;
                   end
                end
            end

            oldNSlices=newNSlices;
        end

        % Renumber labels
        lb=unique(subNewLabels);
        lb(1)=[];

        for j=1:length(lb),
            subNewLabels(subNewLabels==lb(j))=cnt;
            cnt=cnt+1;
        end
    else
        subNewLabels = img.*cnt;
        cnt=cnt+1;
    end
end

function [cents] = computeWatershed(img)
	global cfg;

    imgInv = ~img;
    imgInv = uint8(imgInv.*255);
    imgJ = MIJ.createImage('', imgInv, false);

    % If the subimage is too small, the MIJ plug-in will fail to create an image
    if isequal(imgJ, []),
        splittedImg=imgInv;
    else,
        edm = ij.plugin.filter.EDM();
        edm.setup('watershed', imgJ);
        edm.run(imgJ.getProcessor());

        splittedImg=MIJ.get(imgJ);

        splittedImg=~splittedImg;
        splittedImg=logical(splittedImg./255);
    end

    components = bwconncomp (splittedImg, cfg.nNeighbors_);
    cents=regionprops(components, 'Centroid', 'Area');
end

function [centroids] = convertCentroids(cents)
	centroids={};
	for i=1:length(cents),
		centroids{end+1}=cents(i).Centroid;
	end
end

function [pos] = findClosestCentroid(nCents, maxNObjects, j)
	allPos=find(nCents==maxNObjects);
	[~, p]=min(abs(allPos-j));
	pos=allPos(p);
end

function [c1, c2, p1, p2] = selectReferenceSlicesAndCentroids(img)
    global cfg;

    bottomVals=[1:round(size(img, 3)*0.20)             ];
       topVals=[  round(size(img, 3)*0.80):size(img, 3)];

    if isempty(bottomVals) || isempty(topVals),
        p1=1;
        c1=regionprops(img(:,:,p1), 'Centroid');
        p2=1;
        c2=regionprops(img(:,:,p2), 'Centroid');
        return;
    end

    bottomKeys=arrayfun(@(x) sum(sum(img(:,:,x)>0, 2), 1), bottomVals);

    if length(bottomKeys)>1,
        [p1, c1]=selectKey(bottomVals, bottomKeys, img, round(length(bottomKeys)/2), length(bottomKeys));

        if p1==0,
            [p1, c1]=selectKey(bottomVals, bottomKeys, img, round(length(bottomKeys)/2), 1);

            if p1==0,
                p1=bottomVals(round(length(bottomVals)/2));
                c1=regionprops(img(:,:,p1), 'Centroid');
            end
        end
    else
        p1=bottomVals(1);
        c1=regionprops(img(:,:,p1), 'Centroid');
    end

    topKeys=arrayfun(@(x) sum(sum(img(:,:,x)>0, 2), 1), topVals);

    if length(topKeys)>1,
        [p2, c2]=selectKey(topVals, topKeys, img, round(length(topKeys)/2), length(topKeys));

        if p2==0,
            [p2, c2]=selectKey(topVals, topKeys, img, round(length(topKeys)/2), 1);

            if p2==0,
                p2=topVals(round(length(topVals)/2));
                c2=regionprops(img(:,:,p2), 'Centroid');
            end
        end
    else
        p2=topVals(1);
        c2=regionprops(img(:,:,p2), 'Centroid');
    end
end

function [p, c] = selectKey(vals, keys, img, beginP, endP)
    p=0;
    c=-1;

    [keysSorted, sortIndex] = sort(keys);
     valsSorted = vals(sortIndex);

    if beginP>endP,
        step=-1;
    else
        step=1;
    end

    for i=beginP:step:endP,
        pTmp=valsSorted(i);

        % If there are multiple blobs in reference slices, this fix will not work
        CC=bwconncomp(img(:,:,pTmp));

        if length(CC.PixelIdxList)==1,
            p=pTmp;
            c=regionprops(img(:,:,p), 'Centroid');
            break;
        end
    end
end

function [subNewLabels, cnt] = splitBigCellsMethod2(img, cnt)
    [c1, c2, p1, p2] = selectReferenceSlicesAndCentroids(img);
    
    if ~isstruct(c1) || ~isstruct(c2),
        subNewLabels = img.*cnt;
        cnt=cnt+1;
        return;
    end

    % Extract pixels values from swapped centroids
    l12=img(round(c2.Centroid(2)), round(c2.Centroid(1)), p1);
    l21=img(round(c1.Centroid(2)), round(c1.Centroid(1)), p2);

    if l12==0 || l21==0,
        % Store label assigned to each slice
        labs=uint16(zeros(size(img, 3)));

        subNewLabels=uint16(zeros(size(img)));

        for j=1:size(img, 3),
            tmpSlice=uint16(zeros(size(img(:,:,j))));

            % First, second, before last and last slices have fixed labels
            if     j==p1 || j==1,
                tmpSlice(img(:,:,j)~=0)=cnt;
                labs(j)=cnt;
            elseif j==p2 || j==size(img, 3),
                tmpSlice(img(:,:,j)~=0)=cnt+1;
                labs(j)=cnt+1;
            else,
                stats=regionprops(img(:,:,j), 'Centroid', 'PixelIdxList');

                % Assign each slice to the label its centroid is closest
                for k=1:length(stats),
                    dist1=norm([round(c1.Centroid(2)), round(c1.Centroid(1))] - [round(stats(k).Centroid(2)), round(stats(k).Centroid(1))]);
                    dist2=norm([round(c2.Centroid(2)), round(c2.Centroid(1))] - [round(stats(k).Centroid(2)), round(stats(k).Centroid(1))]);

                    if dist1<dist2,
                        tmpSlice(stats(k).PixelIdxList)=cnt;
                    else,
                        tmpSlice(stats(k).PixelIdxList)=cnt+1;
                    end
                end

                labs(j)=max(tmpSlice(:));
            end

            subNewLabels(:,:,j)=tmpSlice;
        end

        % Ensure there are no "islands" (each slice must have the same label than,
        % at least, its left or right counterpart)

        % Find when labels changes
        changes=find(diff(labs));

        % If there is more than one label change, there are islands. Find the point
        % minimizing the distance to the mid-slice and reassign labels
        if length(changes>1),
            [~, pos]=min(arrayfun(@(x) abs(x-length(labs)/2), changes));

            subNewLabels2=subNewLabels(:,:,1:changes(pos));
            subNewLabels2(subNewLabels2>0)=cnt;
            subNewLabels(:,:,1:changes(pos))=subNewLabels2;

            subNewLabels2=subNewLabels(:,:,changes(pos)+1:end);
            subNewLabels2(subNewLabels2>0)=cnt+1;
            subNewLabels(:,:,changes(pos)+1:end)=subNewLabels2;
        end

        % Finally, check that division was not due to malformed reference cells
        % by computing overlapping of first and last slices with division ones
        changes=find(diff(labs));

        if overlapping(find(img(:,:,changes(1))~=0), find(img(:,:,end)~=0), 'max') > 0.90 || overlapping(find(img(:,:,changes(1)+1)~=0), find(img(:,:,1)~=0), 'max') > 0.90,
            subNewLabels2=subNewLabels(:,:,changes(pos)+1:end);
            subNewLabels2(subNewLabels2>0)=cnt;
            subNewLabels(:,:,changes(pos)+1:end)=subNewLabels2;
            cnt=cnt+1;
        else
            cnt=cnt+2;
        end
    else
        subNewLabels = img.*cnt;
        cnt=cnt+1;
    end
end
