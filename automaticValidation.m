function [manualLabs, autoLabs, autoStats] = automaticValidation(labelsOrig, labelsNew, validationLabels)
	global cfg;

	valLabels=loadValidationLabels(validationLabels);

	manualLabs=uint16(zeros(size(labelsOrig)));
	  autoLabs=uint16(zeros(size(labelsOrig)));

    % Load aux functions...
    addpath('./aux/');

	[~, ~, ~, data, ~, ~, ~, shifts, ~] = breakBinaryImage3D(labelsNew, false);

    times=0;
    debug_printf(cfg.debug_level_, '-> Validating cells automatically...\n');

	size(data, 2)

    for i=1:size(data, 2),
        [times] = tracePercentage(i, size(data, 2), times);
        i

        x0=shifts{i}{2};
        y0=shifts{i}{1};
        z0=shifts{i}{3};

        xsize=size(data{i}, 1);
        ysize=size(data{i}, 2);
        zsize=size(data{i}, 3);

		dataOrig=labelsOrig(x0:x0+xsize-1, y0:y0+ysize-1, z0:z0+zsize-1);
		valsOrig=unique(dataOrig);
		valsOrig(1)=[];

		foundOver=false;

		% Extract labeled pixels from new labels' bounding box
		dataNew=labelsNew(x0:x0+xsize-1, y0:y0+ysize-1, z0:z0+zsize-1);
		dataNew(data{i}~=1)=0;
		newVals=unique(dataNew);
		newVals(1)=[];

		if length(newVals)>1,
			error('Error: unexpected number of cells when validating automatically...')
		end

		% Compare new labels with old labels
		for j=1:length(valsOrig),
			over=overlapping(find(data{i}>0), find(dataOrig==valsOrig(j)), 'min');

			if over>0.95,
				autoLabs=addToFinalImage(autoLabs, dataNew, x0, y0, z0);
				autoStats{newVals(1)}=valLabels{valsOrig(j)};

				foundOver=true;
			end
		end

		% If the new label did not overlap sufficiently with any old lab,
		% add it for manual validation
		if ~foundOver,
			manualLabs=addToFinalImage(manualLabs, dataNew, x0, y0, z0);
		end

		% plotLabels(data{i}, '');
		% plotLabels(dataOrig, '');
		% plotLabels(labelsNew(x0:x0+xsize-1, y0:y0+ysize-1, z0:z0+zsize-1),'');
    end
end

function [valLabels] = loadValidationLabels(validationLabels)
	fid=fopen(validationLabels);
	data = textscan(fid, '%f %s', 'HeaderLines', 1, 'Delimiter', ',', 'CollectOutput', 0);
	fclose(fid);

	valLabels=cell(1, 5000);

	for i=1:length(data{1}),
		valLabels(data{1}(i))=data{2}(i);
	end
end
