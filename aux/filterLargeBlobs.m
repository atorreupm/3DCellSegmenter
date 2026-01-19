function [inter_clean] = filterLargeBlobs(inter_large, inter_small)
	global cfg;

	inter_clean=logical(zeros(size(inter_large)));

	zsize=size(inter_large, 3);

	for i=1:zsize,
    	CC    = bwconncomp (inter_large(:,:,i), cfg.nNeighbors_);
    	stats = regionprops(CC, 'BoundingBox', 'Image');

    	for j=1:length(stats),
	        subImg_large = stats(j).Image;

        	bbox = stats(j).BoundingBox;

	        x0 = round(bbox(1,1));
	        y0 = round(bbox(1,2));

	        xinc = round(bbox(1,3));
	        yinc = round(bbox(1,4));

	        subImg_small=inter_small(y0:y0+yinc-1, x0:x0+xinc-1);

		    eqvals=and(subImg_large, subImg_small);
		    inter=sum(eqvals(:));

	    	volLarge=sum(subImg_large(:));
	    	volSmall=sum(subImg_small(:));

		    over=getOverlapping(inter, volLarge, volSmall);

		    if over>0.10,
		    	inter_clean(y0:y0+yinc-1, x0:x0+xinc-1, i)=subImg_small;
		    else
		    	inter_clean(y0:y0+yinc-1, x0:x0+xinc-1, i)=subImg_large;
		    end
    	end
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
