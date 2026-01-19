function [vals_verySmall, vals_small, vals_normal, vals_big, dist_verysmall, dist_small, dist_normal, dist_big] = splitLabelsSetsBySize(labels, computeDists)
	global cfg;

	% Idea taken from: http://stackoverflow.com/questions/2880933/how-can-i-count-the-number-of-elements-of-a-given-value-in-a-matrix
	vals_unique=sort(unique(labels(:)));
	vals_unique(1)=[];

	% Original implementation (it hangs due to large vector passed to histc)
	% dist=uint32(histc(labels, vals_unique));
	% dist=sum(dist, 2);
	% dist=sum(dist, 3);

    begin_=1;
    end_=1000;

    dist=[];

	while begin_<length(vals_unique),
        if end_>length(vals_unique), end_=length(vals_unique); end

        fprintf(1, 'Processing interval [%d, %d]...', begin_, end_);

		dist_tmp=uint32(histc(labels, vals_unique(begin_:end_)));
		dist_tmp=sum(dist_tmp, 2);
		dist_tmp=sum(dist_tmp, 3);

		dist=[dist; dist_tmp];

        begin_=end_+1;
        end_=end_+1000;
        fprintf(1, ' end.\n');
	end

	vals_verySmall=vals_unique(dist< cfg.verySmallThreshold_                           );
	vals_small    =vals_unique(dist>=cfg.verySmallThreshold_ & dist<cfg.smallThreshold_);
	vals_normal   =vals_unique(dist>=cfg.smallThreshold_     & dist<cfg.bigThreshold_  );
	vals_big      =vals_unique(dist>=cfg.bigThreshold_                                 );

	if computeDists,
		dist_verysmall=dist(dist< cfg.verySmallThreshold_                           );
		dist_small    =dist(dist>=cfg.verySmallThreshold_ & dist<cfg.smallThreshold_);
		dist_normal   =dist(dist>=cfg.smallThreshold_     & dist<cfg.bigThreshold_  );
		dist_big      =dist(dist>=cfg.bigThreshold_                                 );
	else,
		dist_verysmall=false;
		dist_small    =false;
		dist_normal   =false;
		dist_big      =false;
	end

	% writeMHDFile(verySmall     , outdir,       'very_small.tif');
	% writeMHDFile(small         , outdir,            'small.tif');
	% writeMHDFile(normal        , outdir,           'normal.tif');
	% writeMHDFile(big           , outdir,              'big.tif');

	% save(sprintf('%s/alldata_divided.mat', outdir), 'verySmall', 'small', 'normal', 'big', 'dist_verysmall', 'dist_small', 'dist_normal', 'dist_big', '-v7.3');
end

function [mask] = getBorderMask(labels)
	mask=zeros(size(labels));

	mask(1:end, 1    , :)=1;
	mask(1:end,   end, :)=1;
	mask(1    , 1:end, :)=1;
	mask(  end, 1:end, :)=1;
end
