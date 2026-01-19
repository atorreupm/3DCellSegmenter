function orthoSlices(img, varargin)
%ORTHOSLICES Display three orthogonal slices in the same figure
%
%   orthoSlices(IMG)
%   Show three orthogonal slices of the 3D image IMG in the same figure.
%   Each slice is displayed to occupy the maximum amount of space within
%   the figure, keeping same proportion between slices.
%
%   orthoSlices(IMG, POS)
%   Specify the initial position of the intersection point between slices.
%   POS is given as [XPOS YPOS ZPOS].
%
%   orthoSlices(IMG, POS, SPACING)
%   Also specify the spacing between voxels, in [SP_X SP_Y SP_Z] order.
%
%   Example
%   % Display MRI head using three orthogonal planar slices
%     img = analyze75read(analyze75info('brainMRI.hdr'));
%     figure(1); clf; hold on;
%     orthoSlices(img, [60 80 13], [1 1 2.5]);
%
%   See also
%   orthoSlices3d
%
%
% ------
% Author: David Legland
% e-mail: david.legland@grignon.inra.fr
% Created: 2011-04-26,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2011 INRA - Cepia Software Platform.

%% Extract input arguments

% get stack size (in x, y, z order)
siz = stackSize(img);

% if no position is specified, use the center of image
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

% flag for displaying 3D orthodlices in lower right corner
% (set to false for the moment, requires further debugging)
display3d = false;


%% Extract data

% extract each slice
sliceXY = squeeze(stackSlice(img, 3, pos(3)));
sliceZY = squeeze(permute(stackSlice(img, 1, pos(1)), [2 1 3]));
sliceXZ = squeeze(permute(stackSlice(img, 2, pos(2)), [2 1 3]));

% in case of double image, rescale and convert to uint8
if ~isa(img, 'uint8') && size(sliceXY, 3) == 1
    sliceXY = formatSlice(sliceXY);
    sliceZY = formatSlice(sliceZY);
    sliceXZ = formatSlice(sliceXZ);
end

% get spatial calibration
xdata = (0:siz(1)-1) * spacing(1) + origin(1);
ydata = (0:siz(2)-1) * spacing(2) + origin(2);
zdata = (0:siz(3)-1) * spacing(3) + origin(3);

% coordinate of reference point
xPos = xdata(pos(1));
yPos = ydata(pos(2));
zPos = zdata(pos(3));

% physical extent of image in each dimension
wx = xdata([1 end]);
wy = ydata([1 end]);
wz = zdata([1 end]);

% amount of space used by each axis
width1  = wx / (wx + wz);
width2  = wz / (wx + wz);
height1 = wy / (wy + wz);
height2 = wz / (wy + wz);

% refresh figure
hf = gcf; clf;


%% Display XY Slice

% create XY axis
axes('parent', hf, 'units', 'normalized', 'visible', 'off', ...
    'position', [0 height2 width1 height1]);
hSliceXY = imshow(sliceXY, 'xdata', xdata, 'ydata', ydata);

hLineXYx = line([xdata(1) xdata(end)], [yPos yPos], 'color', 'r');
hLineXYy = line([xPos xPos], [ydata(1) ydata(end)], 'color', 'r');

% set up slice data
data.handle = hSliceXY;
data.fig    = hf;
data.dir    = 3;
data.dir1   = 1;
data.dir2   = 2;
data.index  = pos(3);
data.xdata  = xdata;
data.ydata  = ydata;
set(hSliceXY, 'UserData', data);

% set up mouse listener
set(hSliceXY, 'ButtonDownFcn', @startDragCrossLine);


%% Display ZY Slice

% create ZY axis
axes('parent', hf, 'units', 'normalized', 'visible', 'off', ...
    'position', [width1 height2 width2 height1]);
hSliceZY = imshow(sliceZY, 'xdata', zdata, 'ydata', ydata);

hLineZYz = line([zdata(1) zdata(end)], [yPos yPos], 'color', 'r');
hLineZYy = line([zPos zPos], [ydata(1) ydata(end)], 'color', 'r');

% set up slice data
data.handle = hSliceZY;
data.fig    = hf;
data.dir    = 1;
data.dir1   = 3;
data.dir2   = 2;
data.index  = pos(1);
data.xdata  = zdata;
data.ydata  = ydata;
set(hSliceZY, 'UserData', data);

% set up mouse listener
set(hSliceZY, 'ButtonDownFcn', @startDragCrossLine);


%% Display XZ Slice

% create XZ axis
axes('parent', hf, 'units', 'normalized', 'visible', 'off', ...
    'position', [0 0 width1 height2]);
hSliceXZ = imshow(sliceXZ, 'xdata', xdata, 'ydata', zdata);

hLineXZx = line([xdata(1) xdata(end)], [zPos zPos], 'color', 'r');
hLineXZz = line([xPos xPos], [zdata(1) zdata(end)], 'color', 'r');

% set up slice data
data.handle = hSliceXZ;
data.fig    = hf;
data.dir    = 2;
data.dir1   = 1;
data.dir2   = 3;
data.index  = pos(2);
data.xdata  = xdata;
data.ydata  = zdata;
set(hSliceXZ, 'UserData', data);

% set up mouse listener
set(hSliceXZ, 'ButtonDownFcn', @startDragCrossLine);



%% Display Orthoslices

if display3d
    axes('parent', hf, 'units', 'normalized', 'visible', 'off', ...
        'position', [width1 0 width2 height2], ...
        'ydir', 'reverse', 'zdir', 'reverse'); %#ok<UNRCH>
    [hSlice3dXY hSlice3dYZ hSlice3dXZ] = orthoSlices3d(img, pos);

    % show orthogonal lines
    hLine3dX = line([xdata(1) xdata(end)], [yPos yPos], [zPos zPos], 'color', 'r');
    hLine3dY = line([xPos xPos], [ydata(1) ydata(end)], [zPos zPos], 'color', 'r');
    hLine3dZ = line([xPos xPos], [yPos yPos], [zdata(1) zdata(end)], 'color', 'r');

    view([-20 30]);

    axis equal;
end


%% Create GUI for figure

% clear struct
data = struct;

% general data common to all displays
data.img = img;
data.pos = pos;

% spatial basis
data.bases  = {xdata, ydata, zdata};

data.display3d = display3d;

% handles to image displays
data.hSliceXY = hSliceXY;
data.hSliceZY = hSliceZY;
data.hSliceXZ = hSliceXZ;

% handles to ortho lines 
data.hLineXYx = hLineXYx;
data.hLineXYy = hLineXYy;
data.hLineZYz = hLineZYz;
data.hLineZYy = hLineZYy;
data.hLineXZx = hLineXZx;
data.hLineXZz = hLineXZz;

if display3d
    % handles to 3D slice displays
    data.hSlice3dXY = hSlice3dXY; %#ok<UNRCH>
    data.hSlice3dYZ = hSlice3dYZ;
    data.hSlice3dXZ = hSlice3dXZ;

    % handles to 3D line separators
    data.hLine3dX = hLine3dX;
    data.hLine3dY = hLine3dY;
    data.hLine3dZ = hLine3dZ;
end

% will contain current callback object
data.src = [];


set(hf, 'UserData', data);



function startDragCrossLine(src, event) %#ok<INUSD>
%STARTDRAGGING  One-line description here, please.
%
%   output = startDragging(input)
%
%   Example
%   startDragging
%
%   See also
%


data = get(src, 'UserData');

% direction of slicing (normal to the slice)
dir1 = data.dir1;
dir2 = data.dir2;
%disp(['Click on orthoslice - ' num2str(dir1) num2str(dir2)]);


hFig = gcbf();
dataFig = get(hFig, 'UserData');
pos = dataFig.pos;

point = get(gca, 'CurrentPoint');
point = point(1, 1:2);

% convert indices to physical coordinates
xdata = dataFig.bases{dir1};
ydata = dataFig.bases{dir2};
[mini pos(dir1)] = min((xdata - point(1)).^2); %#ok<ASGLU>
[mini pos(dir2)] = min((ydata - point(2)).^2); %#ok<ASGLU>


dataFig.pos = pos;
dataFig.src = src;

set(hFig, 'UserData', dataFig);


updateDisplay(hFig);

% set up listeners for figure object
set(hFig, 'WindowButtonMotionFcn', @dragCrossLine);
set(hFig, 'WindowButtonUpFcn', @stopDragCrossLine);


function stopDragCrossLine(src, event) %#ok<INUSD>
%stopDragCrossLine  One-line description here, please.
%
%   output = stopDragCrossLine(input)
%
%   Example
%   stopDragCrossLine
%
%   See also
%


% remove figure listeners
hFig = src;
set(hFig, 'WindowButtonUpFcn', '');
set(hFig, 'WindowButtonMotionFcn', '');


function dragCrossLine(src, event) %#ok<INUSD>
%DRAGSLICE  One-line description here, please.
%
%   output = dragSlice(input)
%
%   Example
%   dragSlice
%
%   See also
%


% extract handle to image object
data = get(src, 'UserData');
hImg = data.src;
pos = data.pos;

% position of last click
point = get(gca, 'CurrentPoint');
point = point(1, 1:2);

% main directions of current slice
imgData = get(hImg, 'UserData');
dir1 = imgData.dir1;
dir2 = imgData.dir2;

% convert indices to physical coordinates
xdata = data.bases{dir1};
ydata = data.bases{dir2};
[mini pos(dir1)] = min((xdata - point(1)) .^ 2); %#ok<ASGLU>
[mini pos(dir2)] = min((ydata - point(2)) .^ 2); %#ok<ASGLU>

% update data for current figure
data.pos = pos;
set(src, 'UserData', data);

% redraw
updateDisplay(src);


function updateDisplay(hFig)

% get dat of current image
data = get(hFig, 'UserData');
img = data.img;
pos = data.pos;

% extract each slice
sliceXY = formatSlice(squeeze(stackSlice(img, 3, pos(3))));
sliceZY = formatSlice(squeeze(stackSlice(img, 1, pos(1))));
sliceXZ = formatSlice(squeeze(stackSlice(img, 2, pos(2))));

% get spatial calibration
xdata = data.bases{1};
ydata = data.bases{2};
zdata = data.bases{3};

% coordinate of reference point
xpos = xdata(pos(1));
ypos = ydata(pos(2));
zpos = zdata(pos(3));


% update planar image displays
buf = sliceXY;
set(data.hSliceXY, 'CData', buf);
if data.display3d
    set(data.hSlice3dXY, 'CData', buf);
end

buf = sliceZY;
set(data.hSliceZY, 'CData', permute(buf, [2 1 3]));
if data.display3d
    set(data.hSlice3dYZ, 'CData', buf);
end

buf = sliceXZ;
set(data.hSliceXZ, 'CData', permute(buf, [2 1 3]));
if data.display3d
    set(data.hSlice3dXZ, 'CData', buf);
end

% update position of orthogonal lines
set(data.hLineXYx, 'YData', [ypos ypos]);
set(data.hLineXYy, 'XData', [xpos xpos]);
set(data.hLineZYz, 'YData', [ypos ypos]);
set(data.hLineZYy, 'XData', [zpos zpos]);
set(data.hLineXZx, 'YData', [zpos zpos]);
set(data.hLineXZz, 'XData', [xpos xpos]);

if data.display3d
    % update position of 3D orthogonal lines
    set(data.hLine3dX, 'YData', [ypos ypos]);
    set(data.hLine3dX, 'ZData', [zpos zpos]);
    set(data.hLine3dY, 'XData', [xpos xpos]);
    set(data.hLine3dY, 'ZData', [zpos zpos]);
    set(data.hLine3dZ, 'XData', [xpos xpos]);
    set(data.hLine3dZ, 'YData', [ypos ypos]);
    
    % update position of 3D slices
    coords = get(data.hSlice3dXY, 'ZData');
    coords(:) = zpos;
    set(data.hSlice3dXY, 'ZData', coords);
    
    coords = get(data.hSlice3dYZ, 'XData');
    coords(:) = xpos;
    set(data.hSlice3dYZ, 'XData', coords);
    
    coords = get(data.hSlice3dXZ, 'YData');
    coords(:) = ypos;
    set(data.hSlice3dXZ, 'YData', coords);
    
end



function slice = formatSlice(slice)
% converts slice to uint8, rescaling data between 0 and max value
if ~strcmp(class(slice), 'uint8') && size(slice, 3) == 1
    slice = double(slice);
    slice = uint8(slice * 255 / max(slice(:)));
end
