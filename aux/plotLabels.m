% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Function:    plotLabels                                                 %
% Description: Assign each label a different (random) color preserving    %
%              colors in 3D                                               %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

function plotLabels(labels, fname)
    % Load aux functions...
    addpath('../libs/export_fig');

    if iscell(labels),
        newLabels = zeros(size(labels{1}, 1), size(labels{1}, 2), size(labels{1}, 3));
        for i=1:length(labels),
            newLabels(:,:,i) = labels{i};
        end
    else,
        newLabels = labels;
    end

    nCells = max (newLabels(:));
    map    = zeros(nCells, 3);

    for i=1:nCells,
        map(i, 1) = rand(1);
        map(i, 2) = rand(1);
        map(i, 3) = rand(1);
    end

    fig=figure;

    if ~isempty(fname),
        set(fig, 'Position', [0 0 1800 1800])
        set(fig, 'visible', 'off');
    end

    nrows = fix(size(newLabels, 3)/5) + 1;

    for i=1:size(newLabels, 3),
        subplot(nrows,5,i);
        imshow(label2rgb(newLabels(:,:,i), map));
        title(strcat('\fontsize{16}\bf{(', num2str(i), ')}'));
    end

    if ~isempty(fname),
        export_fig(fname, '-png');
        close(fig);
    end
end
