classdef Config
    properties
        % %%%%%%%%%%%%%%%%%%%%% %
        % System related config %
        % %%%%%%%%%%%%%%%%%%%%% %

        pathToLibs_     = './libs/';
        pathToSaveData_ = './output/';

        use8bitImages_  = false; % Original images come in RGB format or 8 bit

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
        % Constants used in the parallelization %
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

        nWorkers_ = 1;

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
        % Constants used in several places %
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

        SHOW_DEBUG_LEVEL = 2;
        debug_level_ = 3;
        debug_detailed_level_ = 1;

        out_width_ = 15;

        nNeighbors_   = 4;
        dilationMask_ = [0 1 0; 1 1 1; 0 1 0];

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
        % Constants used in 3D binarization %
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

        conn3D_ = 6;                      % Connectivity for the 3D blobs
        segmentNonNeuronalCells_ = true;  % Should we segment non neuronal cells?

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
        % Constants used in binarization %
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

        blueThreshold_    = 0.01;      % Over this threshold, pixels will see increased
                                       % their blue intensity

        greenThreshold_   = 0.01;      % Over this threshold, pixels will see increased
                                       % their green intensity

        redThreshold_     = 0.01;      % Over this threshold, pixels will see increased
                                       % their red intensity

        grayThreshold_    = 3;         % Over this threshold, pixels will see increased
                                       % their gray intensity
  
        blueFactor_       = 5;         % Multiplication factor for selected blue pixels

        greenFactor_      = 5;         % Multiplication factor for selected green pixels

        redFactor_        = 5;         % Multiplication factor for selected red pixels

        grayFactor_       = 1;         % Multiplication factor for selected gray pixels

        frameSize_        = 3;         % Amount of excess pixels to consider around the
                                       % for the second step of the binarization

        % For 0.42 xyz resolution
        % minBlobSize_      = 100;       % Minimum blob size to use 'bwareaopen' filter

        % For 0.21 xyz resolution
        minBlobSize_      = 300;       % Minimum blob size to use 'bwareaopen' filter

        erodeDilateIters_ = 4;         % Number of iterations of the erode/dilation process

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
        % Constants used in merging blue, green and red channels %
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

        minOverNeuNDAPI_   = 0.7;    % Minimum overlapping required for a structure in
                                     % the blue channel to be kept regarding the green one

        minOverNeuNSulfor_ = 0.2;    % Minimum overlapping required for a structure in
                                     % the blue channel to be kept regarding the red one

        useSulforChannel_  = true;  % Should we use the info from the Sulfor. Channel?

        useGADChannel_     = false; % Should we use the info from the GAD Channel?

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
        % Constants used with interneurons %
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

        minInterSize_=400;
        interNIters_ =10;

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
        % Constants used in clump splitting 3D %
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

        minOverlapping_       = 0.2;

        sizeRatio_            = 1.5;

        intersectionInterval_ = 0.2;

        minOverlappingToJoin_ = 0.6;

        minCellSizeForSplitting_ = 200;

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
        % Constants used in filtering out small cells %
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

        minCellSize_ = 100;

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
        % Constants used in fixing marking errors %
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

        minOverlappingFixMarking = 0.7;

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
        % Constants used in pre-processing small pieces %
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

        minSmallOverLeft =0.60;
        minSmallOverRight=0.85;

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
        % Constants used when dividing cells by size %
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

        % For 0.42 xyz resolution
        % verySmallThreshold_ =  1000;
        % smallThreshold_     = 15000;
        % bigThreshold_       = 70000;

        % For 0.21 xyz resolution
        verySmallThreshold_ =  2000;
        smallThreshold_     = 30000;
        bigThreshold_       = 140000;

        bigCellMinDivideRatio_ = 0.30; % Should we divide a slice of a cell in two parts?
    end
end
