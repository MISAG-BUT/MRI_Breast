%% Training 3D unet

clear all
close all
clc

%%
% Define paths
path_data = 'S:\MRI_Breast\data_train\NIfTI_Files_resaved_2';
path_mask = 'S:\MRI_Breast\data_train\NIfTI_Files_resaved_2';


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

imds = imageDatastore(imageFilePaths(1:1575), 'FileExtensions', [".gz"],'ReadFcn', @(filename) niftiread(filename));

classNames = ["background", "breast"];

maskFilesPaths = arrayfun(@(x) fullfile(x.folder, x.name), maskFiles, 'UniformOutput', false);
labelIDs = [0, 1]; 
% pxds = pixelLabelDatastore(fullfile({maskFiles.folder}, {maskFiles.name}), classNames, labelIDs, 'FileExtensions', [".gz"],'ReadFcn', @(filename) niftiread(filename));
pxds = pixelLabelDatastore(maskFilesPaths(1:1575), classNames, labelIDs, 'FileExtensions', [".gz"],'ReadFcn', @(filename) niftiread(filename));

% Combine into a single datastore
trainingData = combine(imds, pxds);

imds2 = imageDatastore(imageFilePaths(1576:end), 'FileExtensions', [".gz"],'ReadFcn', @(filename) niftiread(filename));
pxds2 = pixelLabelDatastore(maskFilesPaths(1576:end), classNames, labelIDs, 'FileExtensions', [".gz"],'ReadFcn', @(filename) niftiread(filename));
ValidData = combine(imds2, pxds2);


%%
% % clear all
% % Define the target input size and number of classes
% InputSize = [96,96,32]; % The size that the network expects
% numClasses = 2; % Background and breast
% 
% % Create 3D U-Net layers using unet3d function with a resizing layer
% encoderDepth = 3; % You can adjust this based on your requirement
% numFirstEncoderFilters = 2; % Number of output channels for first convolution layer
% 
% 
% % Add U-Net layers
% lgraph = unet3d(InputSize, numClasses,'NumFirstEncoderFilters', numFirstEncoderFilters,'EncoderDepth',encoderDepth, 'ConvolutionPadding', 'same', 'FilterSize', 3);
% 
% % % Remove the input layer of unet3d and connect to resizing layer
% % unet3dNetwork = removeLayers(unet3dNetwork, 'encoderImageInputLayer');
% % lgraph = addLayers(lgraph, unet3dNetwork.Layers);
% % lgraph = connectLayers(lgraph, 'inputLayer', 'encoderImageInputLayer');
% 
% % Display the network
% % figure;
% % plot(lgraph);
% 
% save('Unet3d.mat',"lgraph")


%%
% % dataDir = 'S:\MRI_Breast\data_train\NIfTI_Files_resaved_2';
% % trainedBrainCANDINetwork_url = "https://www.mathworks.com/supportfiles/"+ ...
% %     "image/data/trainedSynthSegModel.zip";
% % downloadTrainedNetwork(trainedBrainCANDINetwork_url,dataDir)
% addpath('C:\Users\Administrator\Documents\MATLAB\Examples\R2024a\images_deeplearning\BrainMRISegmentationUsingTrained3DUNetExample')
% lgraph = importNetworkFromTensorFlow(fullfile(dataDir,"trainedSynthSegModel"));
% 
% figure;
% plot(lgraph);
% 
% % % Display the layers of the pre-trained network
% % analyzeNetwork(lgraph);
% 
% InputSize = [96,96,32];
% % Create a new input layer
% newInputLayer = image3dInputLayer([InputSize,1], 'Name', 'unet_input','Normalization','none');
% 
% % Extract the layers from the pre-trained network
% % layers = layerGraph(lgraph);
% 
% % inputLayerIdx = find(arrayfun(@(l) isa(l, 'nnet.cnn.layer.Image3DInputLayer'), layers.Layers));
% % layers = replaceLayer(layers, layers.Layers(inputLayerIdx).Name, newInputLayer);
% 
% lgraph = replaceLayer(lgraph, lgraph.Layers(1).Name, newInputLayer);
% 
% lgraph = removeLayers(lgraph,lgraph.Layers(60).Name);
% lgraph = removeLayers(lgraph,lgraph.Layers(59).Name);
% 
% layers = [
%     convolution3dLayer(3,2,Name="conv_1x1x1",Padding="same")
%     batchNormalizationLayer('Name','last_BNL')
%     softmaxLayer('Name','Softmax')
%     ];
% lgraph = addLayers(lgraph,layers);
% lgraph = connectLayers(lgraph,"unet_bn_up_3","conv_1x1x1");
% 
% concat = concatenationLayer(4,2,'Name','concat1');
% lgraph = replaceLayer(lgraph, lgraph.Layers(32).Name, concat);
% concat = concatenationLayer(4,2,'Name','concat2');
% lgraph = replaceLayer(lgraph, lgraph.Layers(39).Name, concat);
% concat = concatenationLayer(4,2,'Name','concat3');
% lgraph = replaceLayer(lgraph, lgraph.Layers(46).Name, concat);
% concat = concatenationLayer(4,2,'Name','concat4');
% lgraph = replaceLayer(lgraph, lgraph.Layers(53).Name, concat);
% 
% % lgraph = disconnectLayers(lgraph,"unet_conv_uparm_8_1_elu","unet_bn_up_3");
% % concat = concatenationLayer(4,2,'Name','concat5');
% % lgraph = addLayers(lgraph,concat);
% % lgraph = connectLayers(lgraph,"unet_conv_uparm_8_1","concat5/in1");
% % lgraph = connectLayers(lgraph,"unet_input","concat5/in2");
% 
% save('Unet3dBrain.mat',"lgraph")

%% 
% load('Unet3dBrain.mat',"lgraph")
% load('Unet3d.mat',"lgraph")

lgraph = load('model_2_0.mat','net').net;

%% Data Augmentation

% Define custom data augmentation function
function dataOut = augmentData(data)
    dataOut = data;
    % Apply random reflection
    if rand > 0.3
        dataOut{1} = flip(dataOut{1}, 1); % Flip image
        dataOut{2} = flip(dataOut{2}, 1); % Flip label
    end
    if rand > 0.3
        dataOut{1} = flip(dataOut{1}, 2); % Flip image
        dataOut{2} = flip(dataOut{2}, 2); % Flip label
    end
    if rand > 0.3
        dataOut{1} = flip(dataOut{1}, 3); % Flip image
        dataOut{2} = flip(dataOut{2}, 3); % Flip label
    end

    angles = [180, 90, -90, -180];
    if rand > 0.75
        direction = randperm(3)==3;
        angle = angles(randi(2));
        dataOut{1} = imrotate3(dataOut{1},angle,direction); % Flip image
        dataOut{2} =  imrotate3(dataOut{2},angle,direction); % Flip label
    end

    if rand < 0.4
        dataOut{1} = uint16( ((single(dataOut{1})/500).^(randn(1)*0.2+1))*500);
    elseif rand > 0.7
        dataOut{1} = uint16( single(dataOut{1})*(randn(1)*0.2+1));
    end

    % Apply random scaling
    % rot = (randi(4)-1)*90;
    % dataOut{1} = imrotate3(dataOut{1}, rot, [0,0,1]); % Scale image
    % dataOut{2} = imresize3(dataOut{2}, rot, [0,0,1]); % Scale label

    % dataOut{1} = uint16( single(dataOut{1})*(randn(1)*0.05+1));
    % dataOut{2} = flip(dataOut{2}, 1);
    % dataOut{1} = imresize3(dataOut{1}, [64,64,32], 'nearest'); % Scale label
    % dataOut{2} = imresize3(dataOut{2}, [64,64,32], 'nearest'); % Scale label

end

trainingData = transform(trainingData, @(data) augmentData(data));

%% traning

% Define training options
options = trainingOptions('adam', ...
    'MaxEpochs', 5, ...
    'Metrics','fscore',...
    'ResetInputNormalization',true,...
    'InitialLearnRate', 1e-4, ...
    'MiniBatchSize', 4, ...
    'LearnRateSchedule','piecewise', ...
    'Plots', 'training-progress', ...
    'ValidationData', ValidData, ...
    'Verbose', true, ...
    'ValidationFrequency',100, ...
    'Shuffle', 'every-epoch');

function [loss] = MyLoss( Y, targets) 
% lossFcn = @(Y1,Y2,T1,T2) crossentropy(Y1,T1) + mse(Y2,T2);

    sAB = targets(:,:,1,:) .* Y(:,:,1,:);
    mAB = targets(:,:,1,:).sum('all') + Y(:,:,1,:).sum('all');
    loss = 1 - ((2*(sAB.sum('all'))) / mAB);
    % w1 = mean(targets(:,:,1,:),[1,2]);
    % w2 = mean(targets(:,:,2,:),[1,2]);
    % loss = -sum(  w1.*targets(:,:,1,:).*log(Y(:,:,1,:)) + w2.*(1-targets).*log(1-Y) ,'all');
end

% Train the network
[net, info] = trainnet(trainingData, lgraph, @MyLoss, options);

description = 'pokus o nove douceni pro vsechny rotace, z model2_0, a take nove na loss Dice';

save('segm_3D_unet\model_2_2.mat',"net","info","description")


%% Prediction
% 
% niftiFilePath = imageFilePaths{100};
% 
% niftiInfo = niftiinfo(niftiFilePath);
% niftiData = niftiread(niftiFilePath);
% 
% % Resize the input data to match the network's input size
% % inputData = imresize3(niftiData, InputSize(1:3));
% niftiData = single(niftiData); % Ensure the data is single precision
% % inputData = rescale(inputData); % Normalize the input data
% 
% % Perform prediction
% prediction = predict(net, niftiData);
% 
% imfuse5(niftiData, prediction(:,:,:,2)>0.5)