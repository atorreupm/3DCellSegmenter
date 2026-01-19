function [img, num_images] = loadLabels(inputImage)
    info = imfinfo(inputImage);
    num_images = numel(info);

    for i=1:num_images,
        [A] = imread(inputImage, i, 'Info', info);
        A(A==255)=0;
        [labels, ~] = rgb2ind(A, 65536);

        img(:,:,i) = labels;
    end
end
