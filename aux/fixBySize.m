function [finalImg, notNeuronsImg] = fixBySize(finalImg, notNeuronsImg)
    % Divide labels of neurons per size
    [vals_verySmall, vals_small, vals_normal, vals_big, ~, ~, ~, ~] = splitLabelsSetsBySize(finalImg, false);

    verySmall=uint16(ismember(finalImg, vals_verySmall)).*finalImg;
    small    =uint16(ismember(finalImg, vals_small    )).*finalImg;
    normal   =uint16(ismember(finalImg, vals_normal   )).*finalImg;
    big      =uint16(ismember(finalImg, vals_big      )).*finalImg;

    finalImg=normal;
    clear vals_verySmall vals_small vals_normal vals_big normal;

    % Reassemble small cells by merging those labels with their corresponding neuronal or non-neuronal counterparts
    if any(small(:)) || any(notNeuronsImg(:)), [small, notNeuronsImg]=fixIncorrectMarking(small, notNeuronsImg, true ); end
    if any(small(:)) || any(finalImg     (:)), [small, finalImg     ]=fixIncorrectMarking(small, finalImg     , false); end

    finalImg=finalImg+small;

    % Clear variables that are no longer needed
    clear small;

    if any(verySmall(:)) || any(notNeuronsImg(:)), [verySmall, notNeuronsImg]=fixIncorrectMarking(verySmall, notNeuronsImg, true ); end
    if any(verySmall(:)) || any(finalImg     (:)), [verySmall, finalImg     ]=fixIncorrectMarking(verySmall, finalImg     , false); end

    [~, vals_small2, vals_normal2, vals_big2, ~, ~, ~, ~] = splitLabelsSetsBySize(verySmall, false);

    small2    =uint16(ismember(verySmall, vals_small2    )).*verySmall;
    normal2   =uint16(ismember(verySmall, vals_normal2   )).*verySmall;
    big2      =uint16(ismember(verySmall, vals_big2      )).*verySmall;

    clear vals_small2 vals_normal2 vals_big2;

    % Clear variables that are no longer needed
    clear verySmall;

    % Note: small2 could be probably safely discarded as it involves mostly
    % cells touching one of the borders (XY)
    finalImg=finalImg+small2+normal2;

    % Clear variables that are no longer needed
    clear small2 normal2;

    % Divide labels of non-neuronal cells per size
    [vals_verySmallNotNeu, ~, ~, ~, ~, ~, ~, ~] = splitLabelsSetsBySize(notNeuronsImg, false);
    verySmallNotNeu    =uint16(ismember(notNeuronsImg, vals_verySmallNotNeu    )).*notNeuronsImg;
    clear vals_verySmallNotNeu;

    % Remove very small not neurons as they will be mixed with neurons or removed;
    notNeuronsImg=notNeuronsImg-verySmallNotNeu;

    % Reassemble small cells by merging those labels with their corresponding neuronal counterparts
    if any(finalImg(:)) || any(verySmallNotNeu(:)), [finalImg, ~]=fixIncorrectMarking(finalImg, verySmallNotNeu, false); end

    % Clear variables that are no longer needed
    clear verySmallNotNeu;

    % Join the original big cells and those that potentially may arise after fixing small
    % and very small cells in the previous step
    big=big+big2;

    % Clear variables that are no longer needed
    clear big2;

    % Put big cells back to the neurons stack
    finalImg=finalImg+big;

    % Clear variables that are no longer needed
    clear big;

    finalImg=splitBigCells(finalImg, max(finalImg(:)));

    % Remove pixels adjacent to neurons present in non neuronal cells to avoid false positives of not neurons
    [~, notNeuronsImg]=fixIncorrectMarkingClean(finalImg, notNeuronsImg, false, true);
end
