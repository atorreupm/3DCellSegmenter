function [img] = loadImage (fname, which, channel)
    % Read the image (this works with stacks; if the image is not a stack
    % it should be loaded differently)
    info = imfinfo(fname);

    % Load an RGB indexed image
    if strcmpi(channel, 'blue') == 1 || strcmpi(channel, 'green') == 1 || strcmpi(channel, 'red') == 1,
        [A, map] = imread(fname, which, 'Info', info);
        if ~isempty(map),
            img = ind2rgb(A, map);
        else
            img = im2double(A);
        end

        % Remove alpha channel, if present
        if size(img, 3) > 3,
          img=img(:,:,1:3);
        end
    % Load a gray image
    else
        img = imread(fname, which, 'Info', info);
    end
end
