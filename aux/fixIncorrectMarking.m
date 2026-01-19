function [img1, img2] = fixIncorrectMarking(img1, img2, isdapi)
    rerun  =true;

    while rerun,
        [img1, img2, rerun] = doFixIncorrectMarking(img1, img2, isdapi);
    end
end

function [img1, img2, rerun] = doFixIncorrectMarking(img1, img2, isdapi)
	global cfg;

    % Safe default value
    rerun=false;

    % Compute a join image combining structures in both channels and break it into 3D
    imgJoin = or(img1 > 0, img2 > 0);
    [~, ~, ~, auxs, ~, ~, ~, shifts, ~] = breakBinaryImage3D(imgJoin);

    % Aux var to trace progress
    times = 0;

    % Main loop: for each 3D structure (probably made up of multiple cells subparts
    % with different labels)
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

        % Extract the corresponding bounding boxes from both channels
        sub1=img1(y0:y0+yinc-1, x0:x0+xinc-1, z0:z0+zinc-1);
        sub2=img2(y0:y0+yinc-1, x0:x0+xinc-1, z0:z0+zinc-1);

        if length(unique(sub1))==1 || length(unique(sub2))==1,
            continue;
        end

        % Remove labels not belonging to this 3D structure (as we extract cubes,
        % other close cells can be partly included in the bounding box)
        sub1(auxs{i}==0)=0;
        sub2(auxs{i}==0)=0;

        % Extract unique IDs from each labeled channel
        IDs1=unique(sub1(:));
        IDs2=unique(sub2(:));

        % Remove background from the list of labels
        IDs1(IDs1==0)=[];
        IDs2(IDs2==0)=[];

        % Compute number of unique labels per channels and initialize structures to
        % store all their information
        n1=length(IDs1);
        n2=length(IDs2);

        slicesSub1={};
        slicesSub2={};

        % For each label in the first channel, compute all its characteristics
        for j=1:n1,
            % Safe initialization
            slicesSub1{j}.begin=0;
            slicesSub1{j}.end  =zinc;
            slicesSub1{j}.id   =IDs1(j);
            slicesSub1{j}.neu  =true;

            % Guess the beginning and the end of this labeled subcell
            for k=1:zinc,
                vals=unique(sub1(:,:,k));
                if     ~isempty(find(vals==slicesSub1{j}.id)) && slicesSub1{j}.begin==0,
                    slicesSub1{j}.begin=k;
                elseif  isempty(find(vals==slicesSub1{j}.id)) && slicesSub1{j}.begin~=0,
                    slicesSub1{j}.end=k-1;
                    break;
                end
            end
        end

        % For each label in the second channel, compute all its characteristics
        for j=1:n2,
            % Safe initialization
            slicesSub2{j}.begin=0;
            slicesSub2{j}.end  =zinc;
            slicesSub2{j}.id   =IDs2(j);
            slicesSub2{j}.neu  =false;

            % Guess the beginning and the end of this labeled subcell
            for k=1:zinc,
                vals=unique(sub2(:,:,k));
                if     ~isempty(find(vals==slicesSub2{j}.id)) && slicesSub2{j}.begin==0,
                    slicesSub2{j}.begin=k;
                elseif  isempty(find(vals==slicesSub2{j}.id)) && slicesSub2{j}.begin~=0,
                    slicesSub2{j}.end=k-1;
                    break;
                end
            end
        end

        % Combine the information of the slices of both channels into a single list and
        % initialize another list to store the same list sorted by its beginning slice
        allSlices=[slicesSub1, slicesSub2];
        sortedSlices={};

        % Avoid process if just one labeled cell
        if length(allSlices) < 2, continue; end

        % Remove the extracted labels from the resulting images (we will insert them
        % once the repairing has been carried out)
        img1(y0:y0+yinc-1, x0:x0+xinc-1, z0:z0+zinc-1) = img1(y0:y0+yinc-1, x0:x0+xinc-1, z0:z0+zinc-1) - sub1;
        img2(y0:y0+yinc-1, x0:x0+xinc-1, z0:z0+zinc-1) = img2(y0:y0+yinc-1, x0:x0+xinc-1, z0:z0+zinc-1) - sub2;

        % Sort all the labeled structures
        while length(allSlices)>0,
            posmin=1;
            for j=1:length(allSlices),
                if allSlices{j}.begin < allSlices{posmin}.begin, posmin=j; end
            end
            sortedSlices{end+1}=allSlices{posmin};
            allSlices(posmin)=[];
        end

        % Process all labeled structures trying to merge adjacent highly overlapping parts
        j=2;
        while j<=length(sortedSlices),
            pos1=j-1;
            pos2=j;

            % First option: both cells are directly adjacent
            if sortedSlices{pos1}.end+1==sortedSlices{pos2}.begin,
                slice1=sortedSlices{pos1}.end;
                slice2=sortedSlices{pos2}.begin;
                over=0;

                % Compute overlapping between the last slice of one cell and the first one
                % of the other. We iterate just in case there are multiple sets of slices
                % with the same beginning slice, which may hide a correct overlapping
                while over < cfg.minOverlappingFixMarking && pos2<=length(sortedSlices) && sortedSlices{pos1}.end+1==sortedSlices{pos2}.begin,
                    over=computeOverlapping(sortedSlices, pos1, pos2, slice1, slice2, sub1, sub2, 'max');
                    pos2=pos2+1;
                end

                % If the two cells highly overlap, then join them
                if over > cfg.minOverlappingFixMarking,
                    % if sum(sub1(:))>0, plotLabels(sub1, ''); end
                    % if sum(sub2(:))>0, plotLabels(sub2, ''); end
                    % fprintf('adjacent\n');

                    pos2=pos2-1;

                    if      sortedSlices{pos2}.neu &&  sortedSlices{pos1}.neu,
                        sub1(sub1==sortedSlices{pos2}.id)=sortedSlices{pos1}.id;
                    elseif  sortedSlices{pos2}.neu && ~sortedSlices{pos1}.neu,
                        if isdapi && (size(sub1, 3) > size(img1, 3) / 3),
                            j=j+1;
                            continue;
                        end
                        sub1(sub2==sortedSlices{pos1}.id)=sortedSlices{pos2}.id;
                        sub2(sub2==sortedSlices{pos1}.id)=0;
                    elseif ~sortedSlices{pos2}.neu &&  sortedSlices{pos1}.neu,
                        if isdapi && (size(sub1, 3) > size(img1, 3) / 3),
                            j=j+1;
                            continue;
                        end
                        sub1(sub2==sortedSlices{pos2}.id)=sortedSlices{pos1}.id;
                        sub2(sub2==sortedSlices{pos2}.id)=0;
                    elseif ~sortedSlices{pos2}.neu && ~sortedSlices{pos1}.neu,
                        sub2(sub2==sortedSlices{pos2}.id)=sortedSlices{pos1}.id;
                    end

                    % Update labels info to store new beginning, type flag and id of the label
                    sortedSlices{pos2}.begin=sortedSlices{pos1}.begin;
                    sortedSlices{pos2}.id   =sortedSlices{pos1}.id;
                    sortedSlices{pos2}.neu  =sortedSlices{pos1}.neu;

                    % Remove the set of slices that has been incorporated into another set
                    sortedSlices(pos1)=[];

                    % Some slices have been moved, we must re-run the process
                    rerun=true;
                end
            elseif sortedSlices{pos2}.begin >= sortedSlices{pos1}.begin && sortedSlices{pos2}.end <= sortedSlices{pos1}.end,
                % Is the overlapping of labeled structures to the left?
                if sortedSlices{pos2}.begin > sortedSlices{pos1}.begin,
                    slice1=sortedSlices{pos2}.begin-1;
                    slice2=sortedSlices{pos2}.begin;
    
                    over=computeOverlapping(sortedSlices, pos1, pos2, slice1, slice2, sub1, sub2, 'max');

                    % If slices highly overlap, reassign pixels
                        if over > cfg.minOverlappingFixMarking,
                            % if sum(sub1(:))>0, plotLabels(sub1, ''); end
                            % if sum(sub2(:))>0, plotLabels(sub2, ''); end
                            % fprintf('left\n');

                            if      sortedSlices{pos2}.neu &&  sortedSlices{pos1}.neu,
                                sub1(sub1==sortedSlices{pos2}.id)=sortedSlices{pos1}.id;

                                % Remove the set of slices that has been incorporated into another set
                                sortedSlices(pos2)=[];
                            elseif  sortedSlices{pos2}.neu && ~sortedSlices{pos1}.neu,
                                if isdapi && (size(sub1, 3) > size(img1, 3) / 3),
                                    j=j+1;
                                    continue;
                                end

                                sub1(sub2==sortedSlices{pos1}.id)=sortedSlices{pos2}.id;
                                sub2(sub2==sortedSlices{pos1}.id)=0;

                                % Update labels info to store new beginning, type flag and id of the label
                                sortedSlices{pos2}.begin=min(sortedSlices{pos1}.begin, sortedSlices{pos2}.begin);
                                sortedSlices{pos2}.end  =max(sortedSlices{pos1}.end  , sortedSlices{pos2}.end  );

                                % Remove the set of slices that has been incorporated into another set
                                sortedSlices(pos1)=[];
                            elseif ~sortedSlices{pos2}.neu &&  sortedSlices{pos1}.neu,
                                if isdapi && (size(sub1, 3) > size(img1, 3) / 3),
                                    j=j+1;
                                    continue;
                                end

                                sub1(sub2==sortedSlices{pos2}.id)=sortedSlices{pos1}.id;
                                sub2(sub2==sortedSlices{pos2}.id)=0;

                                % Update labels info to store new beginning, type flag and id of the label
                                sortedSlices{pos1}.begin=min(sortedSlices{pos1}.begin, sortedSlices{pos2}.begin);
                                sortedSlices{pos1}.end  =max(sortedSlices{pos1}.end  , sortedSlices{pos2}.end  );

                                % Remove the set of slices that has been incorporated into another set
                                sortedSlices(pos2)=[];
                            elseif ~sortedSlices{pos2}.neu && ~sortedSlices{pos1}.neu,
                                sub2(sub2==sortedSlices{pos2}.id)=sortedSlices{pos1}.id;

                                % Remove the set of slices that has been incorporated into another set
                                sortedSlices(pos2)=[];
                            end

                            % Some slices have been moved, we must re-run the process
                            rerun=true;

                            % We must not increase j as we have removed one element
                            continue;
                    end
                end

                % Or to the right?
                if sortedSlices{pos1}.end > sortedSlices{pos2}.end,
                    slice1=sortedSlices{pos2}.end;
                    slice2=sortedSlices{pos2}.end+1;
    
                    over=computeOverlapping(sortedSlices, pos1, pos2, slice2, slice1, sub1, sub2, 'max');

                    % If slices highly overlap, reassign pixels
                    if over > cfg.minOverlappingFixMarking,
                        % if sum(sub1(:))>0, plotLabels(sub1, ''); end
                        % if sum(sub2(:))>0, plotLabels(sub2, ''); end
                        % fprintf('right\n');

                        if      sortedSlices{pos2}.neu &&  sortedSlices{pos1}.neu,
                            sub1(sub1==sortedSlices{pos2}.id)=sortedSlices{pos1}.id;

                            % Remove the set of slices that has been incorporated into another set
                            sortedSlices(pos2)=[];
                        elseif  sortedSlices{pos2}.neu && ~sortedSlices{pos1}.neu,
                            if isdapi && (size(sub1, 3) > size(img1, 3) / 3),
                                j=j+1;
                                continue;
                            end

                            sub1(sub2==sortedSlices{pos1}.id)=sortedSlices{pos2}.id;
                            sub2(sub2==sortedSlices{pos1}.id)=0;

                            % Update labels info to store new beginning, type flag and id of the label
                            sortedSlices{pos2}.begin=min(sortedSlices{pos1}.begin, sortedSlices{pos2}.begin);
                            sortedSlices{pos2}.end  =max(sortedSlices{pos1}.end  , sortedSlices{pos2}.end  );

                            % Remove the set of slices that has been incorporated into another set
                            sortedSlices(pos1)=[];
                        elseif ~sortedSlices{pos2}.neu &&  sortedSlices{pos1}.neu,
                            if isdapi && (size(sub1, 3) > size(img1, 3) / 3),
                                j=j+1;
                                continue;
                            end

                            sub1(sub2==sortedSlices{pos2}.id)=sortedSlices{pos1}.id;
                            sub2(sub2==sortedSlices{pos2}.id)=0;

                            % Update labels info to store new beginning, type flag and id of the label
                            sortedSlices{pos1}.begin=min(sortedSlices{pos1}.begin, sortedSlices{pos2}.begin);
                            sortedSlices{pos1}.end  =max(sortedSlices{pos1}.end  , sortedSlices{pos2}.end  );

                            % Remove the set of slices that has been incorporated into another set
                            sortedSlices(pos2)=[];
                        elseif ~sortedSlices{pos2}.neu && ~sortedSlices{pos1}.neu,
                            sub2(sub2==sortedSlices{pos2}.id)=sortedSlices{pos1}.id;

                            % Remove the set of slices that has been incorporated into another set
                            sortedSlices(pos2)=[];
                        end

                        % Some slices have been moved, we must re-run the process
                        rerun=true;

                        % We must not increase j as we have removed one element
                        continue;
                    end
                end
            else
                j=j+1;
                continue;
            end

            j=j+1;
        end

        % Re-include both subimages into the final images with the corrections carried out
        img1=addToFinalImage(img1, sub1, y0, x0, z0);
        img2=addToFinalImage(img2, sub2, y0, x0, z0);
    end

    fprintf('\n');
end

% This function computes the overlapping of two cells at the corresponding slices depending
% on the channels they belong to. The parameter 'sense' decides if the overlapping must be
% 'maximum' or 'minimum'
function [over] = computeOverlapping(sortedSlices, pos1, pos2, slice1, slice2, sub1, sub2, sense)
    if      sortedSlices{pos1}.neu &&  sortedSlices{pos2}.neu,
        over=overlapping(find(sub1(:,:,slice1)==sortedSlices{pos1}.id), find(sub1(:,:,slice2)==sortedSlices{pos2}.id), sense);
    elseif  sortedSlices{pos1}.neu && ~sortedSlices{pos2}.neu,
        over=overlapping(find(sub1(:,:,slice1)==sortedSlices{pos1}.id), find(sub2(:,:,slice2)==sortedSlices{pos2}.id), sense);
    elseif ~sortedSlices{pos1}.neu &&  sortedSlices{pos2}.neu,
        over=overlapping(find(sub2(:,:,slice1)==sortedSlices{pos1}.id), find(sub1(:,:,slice2)==sortedSlices{pos2}.id), sense);
    elseif ~sortedSlices{pos1}.neu && ~sortedSlices{pos2}.neu,
        over=overlapping(find(sub2(:,:,slice1)==sortedSlices{pos1}.id), find(sub2(:,:,slice2)==sortedSlices{pos2}.id), sense);
    end
end
