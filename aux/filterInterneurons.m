function [finalImgOut] = filterInterneurons(finalImg)
    global cfg;

    debug_printf(cfg.debug_level_, '-> Filtering out Small Cells...\n');

    vals_unique=sort(unique(finalImg(:)));
    vals_unique(1)=[];

    fprintf(1, 'Total number of cells: %d\n', length(vals_unique));

    begin_=1;
    end_=1000;

    vals_notSmall=[];

    while begin_<length(vals_unique),
        if end_>length(vals_unique), end_=length(vals_unique); end

        fprintf(1, 'Processing interval [%d, %d]...', begin_, end_);
        subvals=vals_unique(begin_:end_);

        dist=uint32(histc(finalImg, subvals));
        dist=sum(dist, 2);
        dist=sum(dist, 3);

        vals_notSmall=[vals_notSmall; subvals(dist>=10000)];

        begin_=end_+1;
        end_=end_+1000;
        fprintf(1, ' end.\n');
    end

    finalImgOut=uint16(ismember(finalImg, vals_notSmall)).*finalImg;

    debug_printf(cfg.debug_level_, '-> Done\n\n');
end
