function [inter_clean] = processInterneurons(fname, overrideLevel)
	global cfg;
	
	infoFile=imfinfo(fname);
	reps=length(infoFile)

    subRegion.minX=1;
    subRegion.minY=1;
    subRegion.minZ=1;
    subRegion.maxX=infoFile(1).Height;
    subRegion.maxY=infoFile(1).Width;
    subRegion.maxZ=numel(infoFile);

	inter_large=logical(zeros(infoFile(1).Height, infoFile(1).Width, reps));
	inter_small=logical(zeros(infoFile(1).Height, infoFile(1).Width, reps));

	for i=1:reps,
		i
		inter_large(:,:,i)=processSlice(fname, i, subRegion, true , overrideLevel);
		inter_small(:,:,i)=processSlice(fname, i, subRegion, false, overrideLevel);
	end

	inter_clean = filterLargeBlobs(inter_large, inter_small);
end

function [slice] = processSlice(fname, i, subRegion, runAdaptive, overrideLevel)
	global cfg;

	[~, slice, ~, ~]=binarizeImage(fname, i, 'gray', subRegion, true, runAdaptive, overrideLevel);
	slice=bwareaopen(slice, cfg.minInterSize_, cfg.nNeighbors_);
	slice=erodeAndDilate(slice, cfg.dilationMask_, cfg.interNIters_);
	slice=bwareaopen(slice, cfg.minInterSize_, cfg.nNeighbors_);
end
