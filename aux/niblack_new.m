function imagBW = niblack_new(imag)

filt_radius = 39; % filter radius [pixels]
k_threshold = -0.2; % std threshold parameter

X = double(imag);
X = X / max(X(:)); % normalyze to [0, 1] range

%% build filter
fgrid = -filt_radius : filt_radius;
[x, y] = meshgrid(fgrid);
filt = sqrt(x .^ 2 + y .^ 2) <= filt_radius;
filt = filt / sum(filt(:));

%% calculate mean, and std
local_mean = imfilter(X, filt, 'symmetric');
local_std = sqrt(imfilter(X .^ 2, filt, 'symmetric'));

%% calculate binary image
imagBW = X >= (local_mean + k_threshold * local_std);
