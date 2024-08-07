%% segmentation by network
clear all
close all
clc
reset(gpuDevice)

% Set paths to the image and mask folders
imageFolder = 'S:\MRI_Breast\data_train\NIfTI_Files_resaved_3';
% maskFolder = 'data\forTraining\training\binary_images';

imgds = dir([imageFolder filesep '*.nii.gz']);
maskds = imgds(contains({imgds.name}, '_mask'));
imgds = imgds(~contains({imgds.name}, '_mask'));

rng(77)
idx = randperm(numel(imgds) );
imgds = imgds(idx);
maskds = maskds(idx);

splitnum = round(numel(imgds)*0.85);
imgdsVal = imgds(splitnum:end);
maskdsVal = maskds(splitnum:end);
imgds = imgds(1:splitnum-1);
maskds = maskds(1:splitnum-1);

inputSize = [256, 256, 1];

net = load('trainedUNet_3_0.mat','net').netBest;
% net = load('trainedUNet_3_0.mat','net').net;


%%
numImg = 1;

data = niftiread([imgds(numImg).folder filesep imgds(numImg).name]);
mask = zeros(size(data));
for slice = 1:size(data,3)
    img = data(:,:,slice);    
    [rects] = utils_net_train.split_image(img, inputSize, 0.85);    
    mask_pred = zeros([size(img,1),size(img,2)]);
    rect_mask = zeros(size(img,1),size(img,2));

    for i = 1:size(rects,1)
        rect = rects(i,:);
        X = zeros([inputSize([1,2]),1,1]);
        X(:,:,1,1) = imcrop(img,rect);
        p = single(prctile(X(X>0),95,"all"));
        X = uint16((double(X)/p)*500);
        X = dlarray(single(X),"SSCB");
        if canUseGPU
            X = gpuArray(X);
        end
        [pred] = predict(net,X);
        pred = extractdata(pred);
        mask_pred(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) = mask_pred(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) + pred(:,:,1,1);
        rect_mask(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) = rect_mask(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) + 1;
    end
    mask(:,:,slice) = mask_pred ./ rect_mask;
end

maskThr = mask>0.5;

imfuse5(data,maskThr)
imshow5(maskThr)