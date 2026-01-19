function [newLabs] = removeOversegmentedCells(labelsOrig)
	global cfg;

  % Load aux functions...
  addpath('./aux/');

  newLabs=labelsOrig;
	maxZ=size(labelsOrig, 3);

	[~, ~, ~, data, ~, ~, ~, shifts, ~] = breakBinaryImage3D(labelsOrig, false);

  times=0;
  debug_printf(cfg.debug_level_, '-> Finding oversegmented cells...\n');

  for i=1:size(data, 2),
    [times] = tracePercentage(i, size(data, 2), times);

    x0=shifts{i}{2};
    y0=shifts{i}{1};
    z0=shifts{i}{3};

    xsize=size(data{i}, 1);
    ysize=size(data{i}, 2);
    zsize=size(data{i}, 3);

    if (z0~=1 && (z0+zsize-1)~=maxZ) && zsize<=3,
		  dataOrig=labelsOrig(x0:x0+xsize-1, y0:y0+ysize-1, z0:z0+zsize-1);
      dataOrig(data{i}==0)=0;

      newLabs(x0:x0+xsize-1, y0:y0+ysize-1, z0:z0+zsize-1) = newLabs(x0:x0+xsize-1, y0:y0+ysize-1, z0:z0+zsize-1) - dataOrig;
    end
  end

	debug_printf(cfg.debug_level_, ' done\n\n');
end
