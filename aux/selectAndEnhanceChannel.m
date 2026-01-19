function [Acolor, Agray] = selectAndEnhanceChannel(Acolor, channel)
    global cfg;

    if strcmpi(channel, 'blue') == 1,
        % Increase intensity of blue colors
        B = Acolor(:,:,3) > cfg.blueThreshold_;
        C = double(B);
        Acolor(:, :, 3) = Acolor(:, :, 3) .* C;
        Acolor(:, :, 3) = Acolor(:, :, 3) .* cfg.blueFactor_;

        % Take only blue channel
        Agray = Acolor(:,:,3);
    elseif strcmpi(channel, 'green') == 1,
        % Increase intensity of green colors
        B = Acolor(:,:,2) > cfg.greenThreshold_;
        C = double(B);
        Acolor(:, :, 2) = Acolor(:, :, 2) .* C;
        Acolor(:, :, 2) = Acolor(:, :, 2) .* cfg.greenFactor_;

        % Take only blue channel
        Agray = Acolor(:,:,2);
    elseif strcmpi(channel, 'red') == 1,
        % Increase intensity of green colors
        B = Acolor(:,:,1) > cfg.redThreshold_;
        C = double(B);
        Acolor(:, :, 1) = Acolor(:, :, 1) .* C;
        Acolor(:, :, 1) = Acolor(:, :, 1) .* cfg.redFactor_;

        % Take only blue channel
        Agray = Acolor(:,:,1);
    elseif strcmpi(channel, 'gray') == 1,
        % Increase intensity of gray colors
        B = Acolor > cfg.grayThreshold_;
        C = uint8(B);
        Acolor = Acolor .* C;
        Acolor = Acolor .* cfg.grayFactor_;

        % Nothing to do here...
        Agray = Acolor;
    else
        error('select between blue, green or gray channels');
    end
end
