function [resImg] = erodeAndDilate(img, mask, times)
    resImg = img;

    resImg = imdilate(resImg, mask);

    for i=1:times,   resImg = imerode (resImg, mask); end
    for i=1:times-1, resImg = imdilate(resImg, mask); end
end
