%% Prediction

clear all
close all
clc

path_data = 'C:\Data\MRI_prsa\Validation\manifest-1654812109500\Nifti';

% Load images 
imageFiles = dir(fullfile(path_data, '**', '*.nii.gz'));

% Filter files that contain "dyn" and either "1st" or "Ph1" in their name
filteredFiles = [];
for i = 1:length(imageFiles)
    fileName = imageFiles(i).name;
    if ( ~contains(fileName, 't1') )
            filteredFiles = [filteredFiles; imageFiles(i)];
    end
end

imageFiles = filteredFiles;


%% load net
load('model_2.mat','net')

%% datastore

imageFilePaths = arrayfun(@(x) fullfile(x.folder, x.name), imageFiles, 'UniformOutput', false);

input_size = [128,128,64];
desired_voxel_size = [2,2,2];

niftiFilePath = imageFilePaths{3};

niftiInfo = niftiinfo(niftiFilePath);
niftiData = niftiread(niftiFilePath);

current_voxel_size = niftiInfo.PixelDimensions;

T = niftiInfo.Transform.T;
[niftiData, T_new] = transfToUnit(niftiData, T, current_voxel_size, desired_voxel_size);

vel = size(niftiData);

inputData = single( imresize3(niftiData, input_size,"nearest"));
    % img2 = (img2 - mean(img2,"all")) / std(img2,[],"all");
inputData = (rescale(inputData)*5000);

% Perform prediction
pred = predict(net, inputData);

%% resampling and postprocessing

prediction2 = imresize3(pred(:,:,:,2)>0.5, vel,"nearest");

prediction2 = imopen(prediction2,create_sphere(1));
prediction2 = imopen(prediction2,create_sphere(2));
prediction2 = imclose(prediction2,create_sphere(1));
prediction2 = imclose(prediction2,create_sphere(2));

% display
imfuse5(niftiData, prediction2)

%% display

% imfuse5(niftiData, prediction2)

%% volume calculation

V_left = sum(prediction2(vel(1)/2 : end, :,:),"all")*(2^3) / (100^3)
V_right = sum(prediction2(1:vel(2)/2, :,:),"all")*(2^3) / (100^3)

