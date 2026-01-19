function [BW, BW_clean, Aorig, Acolor] = binarizeImage (fname, whichImg, channel, subRegion, doublePass, runAdaptive, overrideLevel)
    global cfg;

    % Load aux functions...
    addpath('./aux/');

    % Load image stack
    Acolor = loadImage(fname, whichImg, channel);
    Acolor = Acolor(subRegion.minX:subRegion.maxX, subRegion.minY:subRegion.maxY, :);

    % Store a copy of the original image
    Aorig = Acolor;

    % Select appropriate channel (as requested)
    [Acolor, Agray] = selectAndEnhanceChannel(Acolor, channel);

    % Apply a median filter to reduce noise while trying to preserve edges
    Agray = medfilt2(Agray);

    % Enhance contrast of the image: "Contrast Limited Adaptive Histograph
    % Equalization"
    if runAdaptive, Agray = adapthisteq(Agray); end

    % Convert image to B/W (with an overall threshold)
    if overrideLevel ~= 0,
    	level = overrideLevel;
    else
    	level = graythresh(Agray);
    end

    BW = im2bw(Agray, level);

    % Fill in holes within cells
    BW = imfill(BW, 'holes');

    % Remove small blobs, erode, dilate and remove small objects again
    BW = bwareaopen(BW, cfg.minBlobSize_, cfg.nNeighbors_);
    BW = erodeAndDilate(BW, cfg.dilationMask_, cfg.erodeDilateIters_);
    BW = bwareaopen(BW, cfg.minBlobSize_, cfg.nNeighbors_);

    % Fill holes of cells touching borders to avoid bad divisions and
    % vanishing of cells after imopem

    % Start with top-left corner
    BW = padarray(BW, [1 1], 1, 'pre');
    BW = imfill(BW, 'holes');
    BW = BW(2:end, 2:end);

    % Continue with top-right corner
    BW = padarray(padarray(BW, [1 0], 1, 'pre'), [0 1], 1, 'post');
    BW = imfill(BW, 'holes');
    BW = BW(2:end, 1:end-1);

	% Continue with bottom-right corner
	BW = padarray(BW, [1 1], 1, 'post');
    BW = imfill(BW, 'holes');
    BW = BW(1:end-1, 1:end-1);

	% End with bottom-left corner
	BW = padarray(padarray(BW, [1 0], 1, 'post'), [0 1], 1, 'pre');
    BW = imfill(BW, 'holes');
    BW = BW(1:end-1, 2:end);

    if doublePass,
        % Divide original slice into 2-D connected components for further process
        [~, ~, ~, auxs, ~, ~, shifts, ~] = breakBinaryImage(BW, cfg.debug_level_);

        BW_clean = zeros(size(Agray));

        debug_printf(cfg.debug_level_, '-> Processing individual connected components in 2nd pass...\n');

        times=0;

        for i=1:length(auxs),
            [times] = tracePercentage(i, length(auxs), times);

            [xinit, xend, yinit, yend, BWorig] = computeFrameWindow(auxs{i}, shifts{i}, Agray, cfg.frameSize_);

            subImgOrig = Agray(yinit:yend, xinit:xend);

            H = fspecial('gaussian');
            subImgOrig = imfilter(subImgOrig, H,'replicate');

            BW2 = niblack_new(subImgOrig);
            BW2 = imfill(BW2, 'holes');
            BW2 = erodeAndDilate(BW2, cfg.dilationMask_, cfg.erodeDilateIters_);

            % Check that this pre-processing did not remove all the image traces.
            % If so, abort and continue with the next image.
            if any(BW(:)) == 0, continue; end

            BW2 = removeArtifactsNew(BW2, BWorig, xinit, xend, yinit, yend);

            % Try to avoid second passes that lead to square cells
            if auxs{i}(1,1)~=BW2(1,1) || auxs{i}(1,end)~=BW2(1,end) || auxs{i}(end,end)~=BW2(end,end) || auxs{i}(end,1)~=BW2(end,1),
                imgClean=BWorig;
            else,
                imgClean=BW2;
            end

            % Refine cells borders but avoid removing cells by accident
			imgClean_tmp = imopen(imgClean, strel('disk', 10));

			if any(imgClean_tmp(:)) == 0,
				imgClean_tmp = imopen(imgClean, strel('disk', 5));
				filter_size = bwareaopen(imgClean_tmp, cfg.minBlobSize_, cfg.nNeighbors_);

				if any(imgClean_tmp(:)) == 0 || any(filter_size(:)) == 0,
					imgClean_tmp=imgClean;
				end
			end

			imgClean=imgClean_tmp;

            % Copy only white pixels to the clean image
            BW_clean = addToFinalImage(BW_clean, imgClean, yinit, xinit, 1);
        end
        debug_printf(cfg.debug_level_, '\n-> Done\n');
    else
        BW_clean = BW;
    end

    BW_clean = bwareaopen(BW_clean, cfg.minBlobSize_, cfg.nNeighbors_);
end

function [xinit, xend, yinit, yend, imgOut] = computeFrameWindow(img, shift, Agray, fsize)
    xinc = size(img, 2);
    yinc = size(img, 1);
    x0   = shift{1};
    y0   = shift{2};

    xinit = x0            - fsize;
    xend  = x0 + xinc - 1 + fsize;
    yinit = y0            - fsize;
    yend  = y0 + yinc - 1 + fsize;

    if xinit < 1,              xinit = 1;              end
    if xend  > size(Agray, 2), xend  = size(Agray, 2); end
    if yinit < 1,              yinit = 1;              end
    if yend  > size(Agray, 1), yend  = size(Agray, 1); end

    imgOut=[zeros(y0-yinit, size(img, 2)); img];
    imgOut=[imgOut; zeros(yend-(y0+yinc-1), size(imgOut, 2))];
    imgOut=[zeros(size(imgOut, 1), x0-xinit), imgOut];
    imgOut=[imgOut, zeros(size(imgOut, 1), xend-(x0+xinc-1))];
end

function [BW2new] = removeArtifactsNew(BW2, BWorig, xinit, xend, yinit, yend)
    global cfg;

    % This code removes small artifacts that appear due to using a frame
    % window. They could be pixels that were not selected with the global
    % threshold or pixels coming from an adjacent cell
    [~, ~, ~, auxs2, Is2, Js2, shifts2, ~] = breakBinaryImage(BW2, cfg.debug_detailed_level_);

    BW2new=zeros(size(BW2));
    found=false;

    if length(auxs2) > 1,
        for j = 1:length(auxs2),
            xcenter = floor(size(auxs2{j}, 2) / 2) + shifts2{j}{1};
            ycenter = floor(size(auxs2{j}, 1) / 2) + shifts2{j}{2};
            if BWorig(ycenter, xcenter)==1,
                BW2new = BW2new+assignSubImage(size(BW2), auxs2{j}, shifts2{j}, auxs2{j});
                found=true;
            end
        end
    end

    % If function reaches this point, it means that the function did
    % not find the cell by using the centroid. We will return the one
    % with the biggest overlapping with the original cell...
    if ~found,
        for j=1:length(auxs2),
            sub=assignSubImage(size(BW2), auxs2{j}, shifts2{j}, auxs2{j});
            inter=and(sub, BWorig);
            over1=sum(inter(:))/sum(sub(:));
            over2=sum(inter(:))/sum(BWorig(:));
            over=max(over1, over2);
            if over>0.8,
                BW2new = or(BW2new, assignSubImage(size(BW2), auxs2{j}, shifts2{j}, auxs2{j}));
            end
        end
    end
end

function [BW2new] = removeArtifacts(BW2, BWorig, xinit, xend, yinit, yend)
    global cfg;

    % This code removes small artifacts that appear due to using a frame
    % window. They could be pixels that were not selected with the global
    % threshold or pixels coming from an adjacent cell
    [~, ~, ~, auxs2, Is2, Js2, shifts2, ~] = breakBinaryImage(BW2, cfg.debug_detailed_level_);

    if length(auxs2) > 1,
        xcenter = floor((xend - xinit) / 2);
        ycenter = floor((yend - yinit) / 2);

        for j = 1:length(auxs2),
            lastXs  = find((Js2{j} + shifts2{j}{1} - 1) == xcenter);
            lastYs  = find((Is2{j} + shifts2{j}{2} - 1) == ycenter);
            lastPos = lastXs(ismember(lastXs, lastYs));

            if ~isempty(lastPos),
                BW2new = assignSubImage(size(BW2), auxs2{j}, shifts2{j}, auxs2{j});
                return;
            end
        end
    else
        BW2new=BW2;
        return;
    end

    % If function reaches this point, it means that the function did
    % not find the cell by using the centroid. We will return the one
    % with the biggest overlapping with the original cell...
    BW2new=zeros(size(BW2));

    for j=1:length(auxs2),
        sub=assignSubImage(size(BW2), auxs2{j}, shifts2{j}, auxs2{j});
        inter=and(sub, BWorig);
        over1=sum(inter(:))/sum(sub(:));
        over2=sum(inter(:))/sum(BWorig(:));
        over=max(over1, over2);
        if over>0.8,
            BW2new = or(BW2new, assignSubImage(size(BW2), auxs2{j}, shifts2{j}, auxs2{j}));
        end
    end
end

function [img] = assignSubImage(sz, aux, shifts, subImg)
    img = zeros(sz);

    xinc2 = size(subImg, 2);
    yinc2 = size(subImg, 1);
    x02   = shifts{1};
    y02   = shifts{2};

    img(y02:y02+yinc2-1, x02:x02+xinc2-1) = aux;
end
