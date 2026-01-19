function varargout = orthoSlices3d(img, varargin)
%ORTHOSLICES3D Show three orthogonal slices of a 3D image
%
%   orthoSlices3d(IMG)
%   Show three orthogonal slices of the 3D image IMG in the same axis.
%
%   orthoSlices3d(IMG, POS)
%   Specifies the position of the intersection point of the three slices.
%   POS is 1-by-3 row vector containing the position of slices intersection
%   point, in image index coordinate between 1 and image size, in order 
%   [XPOS YPOS ZPOS].
%
%   orthoSlices3d(IMG, POS, SPACING)
%   Also specify the spacing between voxels, as a 1-by-3 row vector with
%   values: [SP_X SP_Y SP_Z].
%
%   Example
%   % Display MRI head using three 3D orthogonal slices
%     img = analyze75read(analyze75info('brainMRI.hdr'));
%     figure(1); clf; hold on;
%     orthoSlices3d(img, [60 80 13], [1 1 2.5]);
%     axis equal;                          % to have equal sizes
%
%   See also
%   stackSlice, orthoSlices, showXSlice, showYSlice, showZSlice
%
% ------
% Author: David Legland
% e-mail: david.legland@grignon.inra.fr
% Created: 2010-06-30,    using Matlab 7.9.0.529 (R2009b)
% http://www.pfl-cepia.inra.fr/index.php?page=slicer
% Copyright 2010 INRA - Cepia Software Platform.


%% Parse input arguments

% get stack size (in x, y, z order)
siz = stackSize(img);

% use a default position if not specified
if isempty(varargin)
    pos = ceil(siz / 2);
else
    pos = varargin{1};
    varargin(1) = [];
end

% extract spacing
spacing = [1 1 1];
if ~isempty(varargin)
    spacing = varargin{1};
    if numel(spacing) == 1
        % in case of scalar spacing, convert to row vector
        spacing = [1 1 1] * spacing;
    end
end

% origin
origin = [0 0 0];


%% Display slices

% display three orthogonal slices
hold on;
hyz = slice3d(img, 1, pos(1), spacing);
hxz = slice3d(img, 2, pos(2), spacing);
hxy = slice3d(img, 3, pos(3), spacing);

% compute display extent (add a 0.5 limit around each voxel)
corner000 = (zeros(1, 3) + .5) .* spacing + origin;
corner111 = (siz + .5) .* spacing + origin;
extent = [corner000 ; corner111];
extent = extent(:)';

% setup display
axis equal;
axis(extent);

if nargout > 2
    varargout = {hxy, hyz, hxz};
end
