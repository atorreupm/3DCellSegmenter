function [neurons, others, merged] = mergeDAPIandNeuN3D(dapi, neun)
	global cfg;

    [~, ~, ~, auxs, ~, ~, ~, shifts, ~] = breakBinaryImage3D(dapi);

    neurons=logical(zeros(size(dapi)));
    others =logical(zeros(size(neun)));
    merged =logical(zeros(size(dapi)));

    % Aux var to trace progress
    times = 0;

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
	    subDAPI=dapi(y0:y0+yinc-1, x0:x0+xinc-1, z0:z0+zinc-1);
	    subNeuN=neun(y0:y0+yinc-1, x0:x0+xinc-1, z0:z0+zinc-1);

	    % Remove labels not belonging to this 3D structure (as we extract cubes,
	    % other close cells can be partly included in the bounding box)
	    subDAPI(auxs{i}==0)=0;

	    overs=zeros(1, zinc);

	    for j=1:zinc,
	    	sliceDAPI=zeros(size(subDAPI(:,:,j)));
	    	sliceNeuN=subNeuN(:,:,j);

	    	oldLevel=cfg.debug_level_;
	    	cfg.debug_level_=0;
			[pieces_, shifts_] = breakImageIntoObjects(subDAPI(:,:,j));
			cfg.debug_level_=oldLevel;

		    volNeuN=sum(sliceNeuN(:));

			for ii=1:length(pieces_),
	            y0_=shifts_{ii}{2};
	            yinc_=size(pieces_{ii}, 1);
	            x0_=shifts_{ii}{1};
	            xinc_=size(pieces_{ii}, 2);

				tmpSlice=zeros(size(subDAPI(:,:,j)));
	            tmpSlice(y0_:y0_+yinc_-1, x0_:x0_+xinc_-1)=pieces_{ii};

	            sz=sum(tmpSlice(:));

			    eqvals=and(tmpSlice, sliceNeuN);
			    inter=sum(eqvals(:));

		    	volDAPI=sum(tmpSlice(:));

				over=getOverlapping(inter, volDAPI, volNeuN);

			    if over < 0.40,
				    	others(y0:y0+yinc-1, x0:x0+xinc-1, z0+j-1)=or(others(y0:y0+yinc-1, x0:x0+xinc-1, z0+j-1), tmpSlice);
			    elseif sz>=cfg.minBlobSize_,
			    	sliceDAPI=sliceDAPI+tmpSlice;
			    end
	        end

	        % Update after changes are made
			subDAPI(:,:,j)=sliceDAPI;

		    eqvals=and(sliceDAPI, sliceNeuN);
		    inter=sum(eqvals(:));

	    	volDAPI=sum(sliceDAPI(:));

		    overs(j)=getOverlapping(inter, volDAPI, volNeuN);
		end

		% Should we split the array before computing statistics?
		splitOvers=splitVector(overs);

		pos=0;

		for ii=1:length(splitOvers),
			n=length(splitOvers{ii});
			m=mean(splitOvers{ii});
			s=std(splitOvers{ii});

			if m>cfg.minOverNeuNDAPI_ && s<0.20,
				neurons    (y0:y0+yinc-1, x0:x0+xinc-1, z0+pos:z0+pos+n-1)=or(neurons    (y0:y0+yinc-1, x0:x0+xinc-1, z0+pos:z0+pos+n-1), subDAPI(:,:,pos+1:pos+n));
			elseif m < 0.40,
				others     (y0:y0+yinc-1, x0:x0+xinc-1, z0+pos:z0+pos+n-1)=or(others     (y0:y0+yinc-1, x0:x0+xinc-1, z0+pos:z0+pos+n-1), subDAPI(:,:,pos+1:pos+n));
			else,
				merged     (y0:y0+yinc-1, x0:x0+xinc-1, z0+pos:z0+pos+n-1)=or(merged     (y0:y0+yinc-1, x0:x0+xinc-1, z0+pos:z0+pos+n-1), subDAPI(:,:,pos+1:pos+n));
			end
			pos=pos+n;
		end
	end
end

function [v] = splitVector(t)
	idx = find([NaN diff([t>0 NaN])]~=0);
	for ii = 1:numel(idx)-1
	    v{ii} = t(idx(ii):idx(ii+1)-1);
	end
end


function [over] = getOverlapping(inter, volDAPI, volNeuN)
	if inter==0,
		over=0;
	elseif volDAPI==0 && volNeuN~=0,
    	over=inter/volNeuN;
    elseif volDAPI~=0 && volNeuN==0,
    	over=inter/volDAPI;
    else,
    	over=max(inter/volDAPI, inter/volNeuN);
    end
end
