function [finalImg] = reconstruct3DCells(img)
    global cfg;

    % Break image into 3D pieces
    [~, ~, ~, data, ~, ~, ~, shifts, ~] = breakBinaryImage3D(img);

    cnt     =10001;
    finalImg=uint16(zeros(size(img)));
    times   =0;

    debug_printf(cfg.debug_level_, '-> Reconstructing each Individual 3D Cell from 2D Patches...\n');

    for i=1:size(data, 2),
        [times] = tracePercentage(i, size(data, 2), times);

        if size(data{i}, 1)*size(data{i}, 2)*size(data{i}, 3)<=10, continue; end

        lab = watershed3DV2(data{i});

        % Only process unique labels present in the label map (filtering out zero).
        % Using 'max' here is not a good idea, as there could be gaps in the labels.
        vals = unique(lab);
        vals(vals == 0) = [];

        for j=1:length(vals),
            lab(lab==vals(j)) = cnt;
            cnt = cnt + 1;
        end

        finalImg = addToFinalImage(finalImg, lab, shifts{i}{2}, shifts{i}{1}, shifts{i}{3});
    end

    debug_printf(cfg.debug_level_, '\n-> Done\n\n');

    % Trick to avoid overwritting labels
    finalImg = finalImg - 10000;
    cnt      = cnt      - 10000;
end
