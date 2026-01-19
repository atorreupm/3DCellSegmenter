function varargout = demoCS3DGUI(varargin)
% DEMOCS3DGUI MATLAB code for demoCS3DGUI.fig
%      DEMOCS3DGUI, by itself, creates a new DEMOCS3DGUI or raises the existing
%      singleton*.
%
%      H = DEMOCS3DGUI returns the handle to a new DEMOCS3DGUI or the handle to
%      the existing singleton*.
%
%      DEMOCS3DGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DEMOCS3DGUI.M with the given input arguments.
%
%      DEMOCS3DGUI('Property','Value',...) creates a new DEMOCS3DGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before demoCS3DGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to demoCS3DGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help demoCS3DGUI

% Last Modified by GUIDE v2.5 16-Jan-2015 17:46:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @demoCS3DGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @demoCS3DGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before demoCS3DGUI is made visible.
function demoCS3DGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to demoCS3DGUI (see VARARGIN)

% Choose default command line output for demoCS3DGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes demoCS3DGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

javaaddpath('./libs/MIJ.jar')
javaaddpath('./libs/ij.jar')

global lastDir_;
lastDir_ = '/Volumes/Data/Work/tmp/lidia.input/';

global cfg;
cfg=Config();

global testPState;
testPState = 'off';

set(handles.blueThres,          'string', cfg.blueThreshold_          );
set(handles.greenThres,         'string', cfg.greenThreshold_         );
set(handles.redThres,           'string', cfg.redThreshold_           );
set(handles.blueFact,           'string', cfg.blueFactor_             );
set(handles.greenFact,          'string', cfg.greenFactor_            );
set(handles.redFact,            'string', cfg.redFactor_              );
set(handles.bboxGap,            'string', cfg.frameSize_              );
set(handles.dnOver,             'string', cfg.minOverNeuNDAPI_        );
set(handles.dsOver,             'string', cfg.minOverNeuNSulfor_      );
set(handles.segmentNonNeuronal, 'Value' , cfg.segmentNonNeuronalCells_);
set(handles.useSulfor,          'Value' , cfg.useSulforChannel_       );
set(handles.useGAD,             'Value' , cfg.useGADChannel_          );
set(handles.eightbit_vs_rgb,    'Value' , cfg.use8bitImages_          );

% --- Outputs from this function are returned to the command line.
function varargout = demoCS3DGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global lastDir_;

[FileName, PathName, ~] = uigetfile({'*.tiff;*.tif', 'TIFF images (*.tif, *.tiff)'}, ...
                                     'Select the blue channel image', lastDir_);

if FileName ~= 0,
  filename = strcat(PathName, FileName);
  lastDir_ = PathName;
  set(handles.edit1, 'String', filename);
end

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global lastDir_;

[FileName, PathName, ~] = uigetfile({'*.tiff;*.tif', 'TIFF images (*.tif, *.tiff)'}, ...
                                     'Select the green channel image', lastDir_);

if FileName ~= 0,
  filename = strcat(PathName, FileName);
  lastDir_ = PathName;
  set(handles.edit2, 'String', filename);
end

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global lastDir_;

folder_name = uigetdir(lastDir_, 'Select the output directory');

if folder_name ~= 0,
  folder_name = strcat(folder_name, '/');
  lastDir_    = folder_name;
  set(handles.edit3, 'String', folder_name);
end

% --- Executes on button press in segmentBtn.
function segmentBtn_Callback(hObject, eventdata, handles)
% hObject    handle to segmentBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global cfg;

finBlue   = get(handles.edit1 , 'String');
finGreen  = get(handles.edit2 , 'String');
finRed    = get(handles.edit19, 'String');
finGAD    = get(handles.edit25, 'String');
finLayers = get(handles.edit24, 'String');
dout      = get(handles.edit3 , 'String');

if exist(finBlue,'file')~=2 || exist(finGreen,'file')~=2 || exist(dout,'dir')~=7,
  h = msgbox('Some of the files could not be opened. Please, select the correct files.', 'Error', 'error', 'modal');
  uiwait(h);
  return;
elseif exist(finRed,'file')~=2,
  h = msgbox('No sulfor. channel image was selected. The use of this channel will be deactivated (if it was activated).', 'Error', 'warn', 'modal');
  uiwait(h);
  if cfg.useSulforChannel_,
    cfg.useSulforChannel_ = false;
    set(handles.useSulfor, 'Value', false);
  end
elseif exist(finGAD,'file')~=2,
  h = msgbox('No GAD channel image was selected. The use of this channel will be deactivated (if it was activated).', 'Error', 'warn', 'modal');
  uiwait(h);
  if cfg.useGADChannel_,
    cfg.useGADChannel_ = false;
    set(handles.useGAD, 'Value', false);
  end
end

tglobal=tic;
if cfg.nWorkers_ > 1,
  s = matlabpool('size');
  if s==0, matlabpool('open', 'local', cfg.nWorkers_); end
  demoCS3D(finBlue, finGreen, finRed, finGAD, finLayers, dout, []);
  if s>0, matlabpool('close'                        ); end
else
  demoCS3D(finBlue, finGreen, finRed, finGAD, finLayers, dout, []);
end
toc(tglobal);

% --- Executes on button press in exitBtn.
function exitBtn_Callback(hObject, eventdata, handles)
% hObject    handle to exitBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close;

function blueThres_Callback(hObject, eventdata, handles)
% hObject    handle to blueThres (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of blueThres as text
%        str2double(get(hObject,'String')) returns contents of blueThres as a double
val=str2double(get(hObject,'String'));
nocommas=isempty(strfind(get(hObject,'String'), ','));

global cfg;

if ~isnan(val) && nocommas,
    cfg.blueThreshold_=val;
else
    h = msgbox('Wrong number entered. Please, correct.', 'Error', 'error', 'modal');
    uiwait(h);
end


% --- Executes during object creation, after setting all properties.
function blueThres_CreateFcn(hObject, eventdata, handles)
% hObject    handle to blueThres (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function blueFact_Callback(hObject, eventdata, handles)
% hObject    handle to blueFact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of blueFact as text
%        str2double(get(hObject,'String')) returns contents of blueFact as a double
val=str2double(get(hObject,'String'));
nocommas=isempty(strfind(get(hObject,'String'), ','));

global cfg;

if ~isnan(val) && nocommas,
    cfg.blueFactor_=val;
else
    h = msgbox('Wrong number entered. Please, correct.', 'Error', 'error', 'modal');
    uiwait(h);
end

% --- Executes during object creation, after setting all properties.
function blueFact_CreateFcn(hObject, eventdata, handles)
% hObject    handle to blueFact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function greenFact_Callback(hObject, eventdata, handles)
% hObject    handle to greenFact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of greenFact as text
%        str2double(get(hObject,'String')) returns contents of greenFact as a double
val=str2double(get(hObject,'String'));
nocommas=isempty(strfind(get(hObject,'String'), ','));

global cfg;

if ~isnan(val) && nocommas,
    cfg.greenFactor_=val;
else
    h = msgbox('Wrong number entered. Please, correct.', 'Error', 'error', 'modal');
    uiwait(h);
end

% --- Executes during object creation, after setting all properties.
function greenFact_CreateFcn(hObject, eventdata, handles)
% hObject    handle to greenFact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function greenThres_Callback(hObject, eventdata, handles)
% hObject    handle to greenThres (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of greenThres as text
%        str2double(get(hObject,'String')) returns contents of greenThres as a double
val=str2double(get(hObject,'String'));
nocommas=isempty(strfind(get(hObject,'String'), ','));

global cfg;

if ~isnan(val) && nocommas,
    cfg.greenThreshold_=val;
else
    h = msgbox('Wrong number entered. Please, correct.', 'Error', 'error', 'modal');
    uiwait(h);
end

% --- Executes during object creation, after setting all properties.
function greenThres_CreateFcn(hObject, eventdata, handles)
% hObject    handle to greenThres (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bboxGap_Callback(hObject, eventdata, handles)
% hObject    handle to bboxGap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bboxGap as text
%        str2double(get(hObject,'String')) returns contents of bboxGap as a double
val=str2double(get(hObject,'String'));
nocommas=isempty(strfind(get(hObject,'String'), ','));

global cfg;

if ~isnan(val) && nocommas,
    cfg.frameSize_=val;
else
    h = msgbox('Wrong number entered. Please, correct.', 'Error', 'error', 'modal');
    uiwait(h);
end

% --- Executes during object creation, after setting all properties.
function bboxGap_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bboxGap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function minX_Callback(hObject, eventdata, handles)
% hObject    handle to text10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text10 as text
%        str2double(get(hObject,'String')) returns contents of text10 as a double


% --- Executes during object creation, after setting all properties.
function text10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minY_Callback(hObject, eventdata, handles)
% hObject    handle to text11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text11 as text
%        str2double(get(hObject,'String')) returns contents of text11 as a double


% --- Executes during object creation, after setting all properties.
function text11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minZ_Callback(hObject, eventdata, handles)
% hObject    handle to minZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minZ as text
%        str2double(get(hObject,'String')) returns contents of minZ as a double


% --- Executes during object creation, after setting all properties.
function minZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxX_Callback(hObject, eventdata, handles)
% hObject    handle to maxX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxX as text
%        str2double(get(hObject,'String')) returns contents of maxX as a double


% --- Executes during object creation, after setting all properties.
function maxX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxY_Callback(hObject, eventdata, handles)
% hObject    handle to maxY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxY as text
%        str2double(get(hObject,'String')) returns contents of maxY as a double


% --- Executes during object creation, after setting all properties.
function maxY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxZ_Callback(hObject, eventdata, handles)
% hObject    handle to maxZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxZ as text
%        str2double(get(hObject,'String')) returns contents of maxZ as a double


% --- Executes during object creation, after setting all properties.
function maxZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in preview.
function preview_Callback(hObject, eventdata, handles)
% hObject    handle to preview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global cfg;

% Load aux functions...
addpath('./aux/');

vals=checkSubImageParams(handles);

if isempty(vals), return; end

finBlue  = get(handles.edit1 , 'String');
finGreen = get(handles.edit2 , 'String');

imgGreen=loadImage(finGreen, uint16(double(vals.minZ+vals.maxZ)/2.0), 'green');
imgBlue =loadImage(finBlue , uint16(double(vals.minZ+vals.maxZ)/2.0), 'blue' );

figure; imshow(imgGreen(vals.minX:vals.maxX, vals.minY:vals.maxY, :));
figure; imshow(imgBlue (vals.minX:vals.maxX, vals.minY:vals.maxY, :));

if cfg.useSulforChannel_,
  finRed = get(handles.edit19, 'String');
  imgRed = loadImage(finRed  , uint16(double(vals.minZ+vals.maxZ)/2.0), 'red'  );
  figure; imshow(imgRed  (vals.minX:vals.maxX, vals.minY:vals.maxY, :));
end

if cfg.useGADChannel_,
  finGAD = get(handles.edit25, 'String');
  imgGAD = loadImage(finGAD  , uint16(double(vals.minZ+vals.maxZ)/2.0), 'gray'  );
  figure; imshow(imgGAD  (vals.minX:vals.maxX, vals.minY:vals.maxY, :));
end

function [vals] = checkSubImageParams(handles)
finGreen = get(handles.edit2 , 'String');

infoGreen=imfinfo(finGreen);

wGreen=infoGreen(1).Width;
hGreen=infoGreen(1).Height;
zGreen=length(infoGreen);

minX=str2double(get(handles.minX,'String'));
minY=str2double(get(handles.minY,'String'));
minZ=str2double(get(handles.minZ,'String'));
maxX=str2double(get(handles.maxX,'String'));
maxY=str2double(get(handles.maxY,'String'));
maxZ=str2double(get(handles.maxZ,'String'));

if minX < 1 || minY < 1 || minZ < 1 || maxX > hGreen || maxY > wGreen || maxZ > zGreen || minX > maxX || minY > maxY || minZ > maxZ,
  h = msgbox('Some of the values exceed image dimension or max is smaller than min for some dimensions. Please, review your input.', 'Error', 'error', 'modal');
  uiwait(h);
  vals=[];
  return;
end

if maxZ - minZ < 1,
  h = msgbox('You must select at least two slices from the original slice to conduct the 3D reconstruction. Please, review your input.', 'Error', 'error', 'modal');
  uiwait(h);
  vals=[];
  return;
end

vals=struct('minX', minX, 'minY', minY, 'minZ', minZ, 'maxX', maxX, 'maxY', maxY, 'maxZ', maxZ);

% --- Executes on button press in testparams.
function testparams_Callback(hObject, eventdata, handles)
% hObject    handle to testparams (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global cfg;

finBlue  = get(handles.edit1 , 'String');
finGreen = get(handles.edit2 , 'String');
finRed   = get(handles.edit19, 'String');
finGAD   = get(handles.edit25, 'String');
dout     = get(handles.edit3 , 'String');

if exist(finBlue,'file')~=2 || exist(finGreen,'file')~=2 || exist(dout,'dir')~=7,
  h = msgbox('You need to specify the files in order to test the params on a subset of the image.', 'Error', 'error', 'modal');
  uiwait(h);
  return;
elseif exist(finRed,'file')~=2,
  h = msgbox('No sulfor. channel image was selected. The use of this channel will be deactivated (if it was activated).', 'Error', 'warn', 'modal');
  uiwait(h);
  if cfg.useSulforChannel_,
    cfg.useSulforChannel_ = false;
    set(handles.useSulfor, 'Value', false);
  end
elseif exist(finGAD,'file')~=2,
  h = msgbox('No GAD channel image was selected. The use of this channel will be deactivated (if it was activated).', 'Error', 'warn', 'modal');
  uiwait(h);
  if cfg.useGADChannel_,
    cfg.useGADChannel_ = false;
    set(handles.useGAD, 'Value', false);
  end
end

                          infoGreen=imfinfo(finGreen);
                          infoBlue =imfinfo(finBlue );
if cfg.useSulforChannel_, infoRed  =imfinfo(finRed  ); end
if cfg.useGADChannel_   , infoGAD  =imfinfo(finGAD  ); end

                          wGreen=infoGreen(1).Width;
                          wBlue =infoBlue (1).Width;
if cfg.useSulforChannel_, wRed  =infoRed  (1).Width;   end
if cfg.useGADChannel_   , wGAD  =infoGAD  (1).Width;   end
                          hGreen=infoGreen(1).Height;
                          hBlue =infoBlue (1).Height;
if cfg.useSulforChannel_, hRed  =infoRed  (1).Height;  end
if cfg.useGADChannel_   , hGAD  =infoGAD  (1).Height;  end
                          zGreen=length(infoGreen);
                          zBlue =length(infoBlue );
if cfg.useSulforChannel_, zRed  =length(infoRed );     end
if cfg.useGADChannel_   , zGAD  =length(infoGAD );     end

if cfg.useSulforChannel_,
  if cfg.useGADChannel_,
    if ~(wGreen==wBlue && hGreen==hBlue && zGreen==zBlue && wGreen==wRed && hGreen==hRed && zGreen==zRed && wGreen==wGAD && hGreen==hGAD && zGreen==zGAD),
      h = msgbox('The height, width or number of slices of the three images do not agree. This will result in the algorithm to fail. Please, select the correct images or resolve the problem.', 'Error', 'error', 'modal');
      uiwait(h);
      return;
    end
  else
    if ~(wGreen==wBlue && hGreen==hBlue && zGreen==zBlue && wGreen==wRed && hGreen==hRed && zGreen==zRed),
      h = msgbox('The height, width or number of slices of the three images do not agree. This will result in the algorithm to fail. Please, select the correct images or resolve the problem.', 'Error', 'error', 'modal');
      uiwait(h);
      return;
    end
  end
else
  if wGreen~=wBlue || hGreen~=hBlue || zGreen~=zBlue,
    h = msgbox('The height, width or number of slices of both images does not agree. This will result in the algorithm to fail. Please, select the correct images or resolve the problem.', 'Error', 'error', 'modal');
    uiwait(h);
    return;
  end
end
  
global testPState;
if strcmp(testPState, 'off'), testPState = 'on'; else testPState = 'off'; end
  
set(handles.text10    , 'Visible', testPState);
set(handles.text11    , 'Visible', testPState);
set(handles.text12    , 'Visible', testPState);
set(handles.text13    , 'Visible', testPState);
set(handles.text14    , 'Visible', testPState);
set(handles.text15    , 'Visible', testPState);
set(handles.minX      , 'Visible', testPState);
set(handles.minY      , 'Visible', testPState);
set(handles.minZ      , 'Visible', testPState);
set(handles.maxX      , 'Visible', testPState);
set(handles.maxY      , 'Visible', testPState);
set(handles.maxZ      , 'Visible', testPState);
set(handles.preview   , 'Visible', testPState);
set(handles.runtestBtn, 'Visible', testPState);

set(handles.minX, 'string', 1     );
set(handles.minY, 'string', 1     );
set(handles.minZ, 'string', 1     );
set(handles.maxX, 'string', hGreen);
set(handles.maxY, 'string', wGreen);
set(handles.maxZ, 'string', zGreen);

% --- Executes during object creation, after setting all properties.
function minX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function minY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in runtestBtn.
function runtestBtn_Callback(hObject, eventdata, handles)
% hObject    handle to runtestBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global cfg;

vals=checkSubImageParams(handles);

if isempty(vals), return; end

finBlue   = get(handles.edit1 , 'String');
finGreen  = get(handles.edit2 , 'String');
finRed    = get(handles.edit19, 'String');
finGAD    = get(handles.edit25, 'String');
finLayers = get(handles.edit24, 'String');
dout      = get(handles.edit3 , 'String');

if exist(finBlue,'file')~=2 || exist(finGreen,'file')~=2 || exist(dout,'dir')~=7,
  h = msgbox('Some of the files could not be opened. Please, select the correct files.', 'Error', 'error', 'modal');
  uiwait(h);
  return;
elseif exist(finRed,'file')~=2,
  h = msgbox('No sulfor. channel image was selected. The use of this channel will be deactivated (if it was activated).', 'Error', 'error', 'modal');
  uiwait(h);
  if cfg.useSulforChannel_,
    cfg.useSulforChannel_ = false;
    set(handles.useSulfor, 'Value', false);
  end
elseif exist(finGAD,'file')~=2,
  h = msgbox('No GAD channel image was selected. The use of this channel will be deactivated (if it was activated).', 'Error', 'error', 'modal');
  uiwait(h);
  if cfg.useGADChannel_,
    cfg.useGADChannel_ = false;
    set(handles.useGAD, 'Value', false);
  end
end

global cfg;

tglobal=tic;
if cfg.nWorkers_ > 1,
  s = matlabpool('size');
  if s==0, matlabpool('open', 'local', cfg.nWorkers_); end
  demoCS3D(finBlue, finGreen, finRed, finGAD, finLayers, dout, vals);
  if s>0, matlabpool('close'                        ); end
else
  demoCS3D(finBlue, finGreen, finRed, finGAD, finLayers, dout, vals);
end
toc(tglobal);


% --- Executes on button press in segmentNonNeuronal.
function segmentNonNeuronal_Callback(hObject, eventdata, handles)
% hObject    handle to segmentNonNeuronal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of segmentNonNeuronal
global cfg;

cfg.segmentNonNeuronalCells_=get(hObject,'Value');

if ~cfg.segmentNonNeuronalCells_,
  set(handles.useSulfor, 'Value', false);
  set(handles.useGAD   , 'Value', false);
end


function edit19_Callback(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit19 as text
%        str2double(get(hObject,'String')) returns contents of edit19 as a double


% --- Executes during object creation, after setting all properties.
function edit19_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global lastDir_;

[FileName, PathName, ~] = uigetfile({'*.tiff;*.tif', 'TIFF images (*.tif, *.tiff)'}, ...
                                     'Select the red channel image', lastDir_);

if FileName ~= 0,
  filename = strcat(PathName, FileName);
  lastDir_ = PathName;
  set(handles.edit19, 'String', filename);
end



function redThres_Callback(hObject, eventdata, handles)
% hObject    handle to redThres (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of redThres as text
%        str2double(get(hObject,'String')) returns contents of redThres as a double
val=str2double(get(hObject,'String'));
nocommas=isempty(strfind(get(hObject,'String'), ','));

global cfg;

if ~isnan(val) && nocommas,
    cfg.redThreshold_=val;
else
    h = msgbox('Wrong number entered. Please, correct.', 'Error', 'error', 'modal');
    uiwait(h);
end

% --- Executes during object creation, after setting all properties.
function redThres_CreateFcn(hObject, eventdata, handles)
% hObject    handle to redThres (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function redFact_Callback(hObject, eventdata, handles)
% hObject    handle to redFact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of redFact as text
%        str2double(get(hObject,'String')) returns contents of redFact as a double
val=str2double(get(hObject,'String'));
nocommas=isempty(strfind(get(hObject,'String'), ','));

global cfg;

if ~isnan(val) && nocommas,
    cfg.redFactor_=val;
else
    h = msgbox('Wrong number entered. Please, correct.', 'Error', 'error', 'modal');
    uiwait(h);
end

% --- Executes during object creation, after setting all properties.
function redFact_CreateFcn(hObject, eventdata, handles)
% hObject    handle to redFact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dnOver_Callback(hObject, eventdata, handles)
% hObject    handle to dnOver (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dnOver as text
%        str2double(get(hObject,'String')) returns contents of dnOver as a double
val=str2double(get(hObject,'String'));
nocommas=isempty(strfind(get(hObject,'String'), ','));

global cfg;

if ~isnan(val) && nocommas,
    cfg.minOverNeuNDAPI_=val;
else
    h = msgbox('Wrong number entered. Please, correct.', 'Error', 'error', 'modal');
    uiwait(h);
end

% --- Executes during object creation, after setting all properties.
function dnOver_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dnOver (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dsOver_Callback(hObject, eventdata, handles)
% hObject    handle to dsOver (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dsOver as text
%        str2double(get(hObject,'String')) returns contents of dsOver as a double
val=str2double(get(hObject,'String'));
nocommas=isempty(strfind(get(hObject,'String'), ','));

global cfg;

if ~isnan(val) && nocommas,
    cfg.minOverNeuNSulfor_=val;
else
    h = msgbox('Wrong number entered. Please, correct.', 'Error', 'error', 'modal');
    uiwait(h);
end

% --- Executes during object creation, after setting all properties.
function dsOver_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dsOver (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in useSulfor.
function useSulfor_Callback(hObject, eventdata, handles)
% hObject    handle to useSulfor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useSulfor
global cfg;

cfg.useSulforChannel_=get(hObject,'Value');

if cfg.useSulforChannel_,
  set(handles.segmentNonNeuronal, 'Value', true);
end



function edit24_Callback(hObject, eventdata, handles)
% hObject    handle to edit24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit24 as text
%        str2double(get(hObject,'String')) returns contents of edit24 as a double


% --- Executes during object creation, after setting all properties.
function edit24_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global lastDir_;

[FileName, PathName, ~] = uigetfile({'*.tiff;*.tif', 'TIFF images (*.tif, *.tiff)'}, ...
                                     'Select the layers division image', lastDir_);

if FileName ~= 0,
  filename = strcat(PathName, FileName);
  lastDir_ = PathName;
  set(handles.edit24, 'String', filename);
end


% --- Executes on button press in eightbit_vs_rgb.
function eightbit_vs_rgb_Callback(hObject, eventdata, handles)
% hObject    handle to eightbit_vs_rgb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of eightbit_vs_rgb
global cfg;

cfg.use8bitImages_=get(hObject,'Value');



function edit25_Callback(hObject, eventdata, handles)
% hObject    handle to edit25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit25 as text
%        str2double(get(hObject,'String')) returns contents of edit25 as a double


% --- Executes during object creation, after setting all properties.
function edit25_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton12.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global lastDir_;

[FileName, PathName, ~] = uigetfile({'*.tiff;*.tif', 'TIFF images (*.tif, *.tiff)'}, ...
                                     'Select the green channel image', lastDir_);

if FileName ~= 0,
  filename = strcat(PathName, FileName);
  lastDir_ = PathName;
  set(handles.edit25, 'String', filename);
end


% --- Executes on button press in useGAD.
function useGAD_Callback(hObject, eventdata, handles)
% hObject    handle to useGAD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useGAD
global cfg;

cfg.useGADChannel_=get(hObject,'Value');

if cfg.useGADChannel_,
  set(handles.segmentNonNeuronal, 'Value', true);
end
