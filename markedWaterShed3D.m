function [finalImg] = markedWaterShed3D(labels, neunBin, outdir)
	addpath('./aux');

	global cfg;
	cfg=Config();

	[neunBinImg, num_images] = loadBinaryImage(neunBin);
	labelsImg                = loadLabels(labels);

	finalImg=zeros(size(labelsImg));

	for i=1:num_images,
		img=neunBinImg(:,:,i);

		stats=regionprops(labelsImg(:,:,i), 'Centroid');

		minima=logical(zeros(size(img)));

		for j=1:length(stats),
			minima(uint32(stats(j).Centroid(2)), uint32(stats(j).Centroid(1)))=1;
		end

		imgDist=-bwdist(~img, 'cityblock');
		imgDist=imimposemin(imgDist, minima);
		imgDist(~img)=-inf;

		imgLabel=watershed(imgDist);
		imgLabel(imgLabel==1)=0;

		BW = imregionalmin(imgDist);

		% figure; imshow(minima);
		% figure; imshow(BW);
		% figure; imshow(label2rgb(imgLabel));
		% figure; imshow(label2rgb(labelsImg(:,:,i)));

		finalImg(:,:,i)=imgLabel;

		% imwrite(minima(:,:), 'centroids.tif', 'writemode', 'append', 'Compression', 'none');
	end

	[pathNeuN, baseFNameNeuN, extNeuN] = fileparts(neunBin);
	writeMHDFile(finalImg, outdir, sprintf('%s.%s', baseFNameNeuN, extNeuN));
end

function [CC, stats, subImages, shifts] = breakBinaryImage2(slice, debug_level)
    global cfg;

    CC    = bwconncomp(slice, cfg.conn3D_); 
    stats = regionprops(CC, 'Centroid', 'PixelIdxList', 'BoundingBox');

    for i=1:CC.NumObjects,
        bbox = stats(i).BoundingBox;

        x0 = round(bbox(1,1));
        y0 = round(bbox(1,2));

        xinc = round(bbox(1,3));
        yinc = round(bbox(1,4));

        subImg = zeros(size(slice));
        subImg(stats(i).PixelIdxList) = 1;
        subImages{i}=subImg(y0:y0+yinc-1, x0:x0+xinc-1);
        
        shifts{i}{1} = x0;
        shifts{i}{2} = y0;
    end
end
