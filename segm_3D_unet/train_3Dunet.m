%% Training 3D unet

clear all
close all
clc

%%
% Define paths
path_data = 'C:\Data\MRI_prsa\manifest-1654812109500\NIfTI_Files_resaved';
path_mask = 'C:\Data\MRI_prsa\manifest-1654812109500\NIfTI_Files_resaved';


%% Load masks 
maskFiles = dir(fullfile(path_mask, '**', '*_mask.nii.gz'));
imageFiles = dir(fullfile(path_mask, '**', '*.nii.gz'));
imageFiles = imageFiles(~contains({imageFiles.name}, '_mask'));


%% datastore

imageFilePaths = arrayfun(@(x) fullfile(x.folder, x.name), imageFiles, 'UniformOutput', false);
% imageFilePaths = [imageFiles(1).folder filesep imageFiles(1).name];

% formatStruct = struct('ext','nii.gz','isa','',...
%     'info',@niftiinfo,'read',@niftiread,'write','niftiwrite',...
%     'alpha',0,'description','nifti');
% registry = imformats('add',formatStruct);
% registry = imformats('remove','nii.gz')
% registry = imformats

imds = imageDatastore(imageFilePaths(1:42), 'FileExtensions', [".gz"],'ReadFcn', @(filename) niftiread(filename));

classNames = ["background", "breast"];

maskFilesPaths = arrayfun(@(x) fullfile(x.folder, x.name), maskFiles, 'UniformOutput', false);
labelIDs = [0, 1]; 
% pxds = pixelLabelDatastore(fullfile({maskFiles.folder}, {maskFiles.name}), classNames, labelIDs, 'FileExtensions', [".gz"],'ReadFcn', @(filename) niftiread(filename));
pxds = pixelLabelDatastore(maskFilesPaths(1:42), classNames, labelIDs, 'FileExtensions', [".gz"],'ReadFcn', @(filename) niftiread(filename));

% Combine into a single datastore
trainingData = combine(imds, pxds);

imds2 = imageDatastore(imageFilePaths(43:47), 'FileExtensions', [".gz"],'ReadFcn', @(filename) niftiread(filename));
pxds2 = pixelLabelDatastore(maskFilesPaths(43:47), classNames, labelIDs, 'FileExtensions', [".gz"],'ReadFcn', @(filename) niftiread(filename));
ValidData = combine(imds2, pxds2);


%%
% clear all
% Define the target input size and number of classes
InputSize = [128 128 64 1]; % The size that the network expects
numClasses = 2; % Background and breast

% Create 3D U-Net layers using unet3d function with a resizing layer
encoderDepth = 2; % You can adjust this based on your requirement
numFirstEncoderFilters = 16; % Number of output channels for first convolution layer

% Define the network
% lgraph = layerGraph();
% 
% % % Add input layer with resizing
% inputLayer = image3dInputLayer(targetInputSize, 'Normalization', 'zerocenter', 'Name', 'inputLayer'); % example size, use the maximum possible size of your data
% lgraph = addLayers(lgraph, inputLayer);

% Add U-Net layers
lgraph = unet3d(InputSize, numClasses, 'ConvolutionPadding', 'same','FilterSize', 3);

% % Remove the input layer of unet3d and connect to resizing layer
% unet3dNetwork = removeLayers(unet3dNetwork, 'encoderImageInputLayer');
% lgraph = addLayers(lgraph, unet3dNetwork.Layers);
% lgraph = connectLayers(lgraph, 'inputLayer', 'encoderImageInputLayer');

% Display the network
figure;
plot(lgraph);


%% Data Augmentation

% Define custom data augmentation function
function dataOut = augmentData(data)
    dataOut = data;
    % Apply random reflection
    if rand > 0.5
        dataOut{1} = flip(dataOut{1}, 1); % Flip image
        dataOut{2} = flip(dataOut{2}, 1); % Flip label
    end
    if rand > 0.5
        dataOut{1} = flip(dataOut{1}, 2); % Flip image
        dataOut{2} = flip(dataOut{2}, 2); % Flip label
    end
    if rand > 0.5
        dataOut{1} = flip(dataOut{1}, 3); % Flip image
        dataOut{2} = flip(dataOut{2}, 3); % Flip label
    end

    % Apply random scaling
    % rot = (randi(4)-1)*90;
    % dataOut{1} = imrotate3(dataOut{1}, rot, [0,0,1]); % Scale image
    % dataOut{2} = imresize3(dataOut{2}, rot, [0,0,1]); % Scale label

    dataOut{1} = uint16( single(dataOut{1}).^(randn(1)*0.05+1));
    % dataOut{2} = flip(dataOut{2}, 1);

end

trainingData = transform(trainingData, @(data) augmentData(data));



%% traning

% Define training options
options = trainingOptions('adam', ...
    'MaxEpochs', 20, ...
    'Metrics','fscore',...
    'ResetInputNormalization',true,...
    'InitialLearnRate', 1e-3, ...
    'MiniBatchSize', 1, ...
    'Plots', 'training-progress', ...
    'ValidationData',ValidData, ...
    'Verbose', true, ...
    'Shuffle', 'every-epoch');

% Train the network
[net, info] = trainnet(trainingData, lgraph, 'binary-crossentropy', options);

save('model_2.mat',"net","info")


%% Prediction

% niftiFilePath = imageFilePaths{40};
% 
% niftiInfo = niftiinfo(niftiFilePath);
% niftiData = niftiread(niftiFilePath);
% 
% % Resize the input data to match the network's input size
% inputData = imresize3(niftiData, InputSize(1:3));
% inputData = single(inputData); % Ensure the data is single precision
% % inputData = rescale(inputData); % Normalize the input data
% 
% % Perform prediction
% prediction = predict(net, inputData);


%% Custom function for data augmentation
% function dataOut = augmentData(dataIn, augmenter)
%     % Extract images and labels
%     images = dataIn{1};
%     labels = dataIn{2};
% 
%     % Augment images and labels
%     augImages = augment(augmenter, images);
%     augLabels = augment(augmenter, labels);
% 
%     % Randomly rotate images and labels by multiples of 90 degrees
%     numRotations = randi([0, 3]); % Randomly choose 0, 1, 2, or 3 rotations
%     augImages = rot90(augImages, numRotations);
%     augLabels = rot90(augLabels, numRotations);
% 
%     % Return augmented data
%     dataOut = {augImages, augLabels};
% end