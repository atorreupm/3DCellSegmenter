function [img, num_images] = loadBinaryImage(inputImage)
    info = imfinfo(inputImage);
    num_images = numel(info);

    for i=1:num_images,
        [A] = imread(inputImage, i, 'Info', info);

        % Hack: needed to be able to read B/W images encoded in color
        if max(A(:)) ~= 1,
            level = graythresh(A);
            A = im2bw(A, level);
        end

        img(:,:,i) = A;
    end
end
