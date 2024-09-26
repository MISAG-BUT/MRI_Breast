%% breasst segmentation

function [maskFinal, volumes, h] = segmentation_breast_2(dataR,info, net)


[T,R,S] = getTransMatrix(info);

% T = T';
% T(:,[1,2]) = T(:,[2,1]);

Mapping = affinetform3d(T);

data = imwarp(dataR,(Mapping));
invMapping = invert(Mapping);

vel = size(dataR);

p = single(prctile(data(data>0),95,"all"));
data = uint16((double(data)/p)*500);

inputSize = [256, 256, 3];
mask = zeros(size(data));

for slice = 1+2:size(data,3)-2
    img = data(:,:,slice);
    img1 = data(:,:,slice-2);
    img3 = data(:,:,slice+2);
    [rects] = utils_net_train.split_image(img, inputSize, 0.85);
    mask_pred = zeros([size(img,1),size(img,2)]);
    rect_mask = zeros(size(img,1),size(img,2));
    
    C = centerCropWindow2d(size(img3,[1,2]),inputSize(1:2));
    rects(end+1,:) = [C.XLimits(1), C.YLimits(1), inputSize(1:2)-1];

    for i = 1:size(rects,1)
        rect = rects(i,:);
        X = zeros([inputSize,1]);
        X(:,:,1,1) = imcrop(img1,rect);
        X(:,:,2,1) = imcrop(img,rect);
        X(:,:,3,1) = imcrop(img3,rect);
        % p = single(prctile(X(X>0),95,"all"));
        % X = uint16((double(X)/p)*500);
        X = dlarray(single(X),"SSCB");
        if canUseGPU
            X = gpuArray(X);
        end
        [pred] = predict(net,X);
        pred = extractdata(pred);
        % mask_pred(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) = mask_pred(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) + pred(:,:,1,1);
        % rect_mask(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) = rect_mask(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) + 1;
        mask_pred(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) = max( mask_pred(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) , pred(:,:,1,1) );
    end
    % mask(:,:,slice) = mask_pred ./ rect_mask;
    mask(:,:,slice) = mask_pred;
end

maskThr = mask>0.5;       
maskThr = refinement_mask(maskThr);

% volumes=[]; pixelSize = [1,1,1]
% volumes(1) = sum(maskThr(:,1:round(size(maskThr,2)/2),:),'all') .* prod(pixelSize) / (10^3);
% volumes(2) = sum(maskThr(:,round(size(maskThr,2)/2)+1:end,:),'all') .* prod(pixelSize) / (10^3)
% 
% h = figure;
% imshowpair( squeeze(data(:,:,round(size(data,3)/2))) , squeeze(maskThr(:,:,round(size(maskThr,3)/2),:,:)) )

maskFinal = imwarp(maskThr,(invMapping));
maskFinal = single( imresize3(maskFinal, vel,"nearest"));

volumes=[]; pixelSize = diag(S)';
volumes(1) = sum(maskFinal(:,1:round(size(maskFinal,2)/2),:),'all') .* prod(pixelSize) / (10^3);
volumes(2) = sum(maskFinal(:,round(size(maskFinal,2)/2)+1:end,:),'all') .* prod(pixelSize) / (10^3);

% % niftiwrite(uint8(mask),'S:\MRI_Breast\data_train\NIFTI_Files_own\resized_Brest_MRI2_001_mask','Compressed', true)

% %% visualization
h = figure;
subplot(2,3,1)
imshow(squeeze(dataR(:,:,round(size(dataR,3)*(1/3)))),[])
subplot(2,3,2)
imshow(squeeze(dataR(:,:,round(size(dataR,3)*(1/2)))),[])
subplot(2,3,3)
imshow(squeeze(dataR(:,:,round(size(dataR,3)*(2/3)))),[])
subplot(2,3,4)
imshowpair( squeeze(dataR(:,:,round(size(dataR,3)*(1/3) ))) , squeeze(maskFinal(:,:,round(size(maskFinal,3)*(1/3)),:,:)) )
subplot(2,3,5)
imshowpair( squeeze(dataR(:,:,round(size(dataR,3)*(1/2)))) , squeeze(maskFinal(:,:,round(size(maskFinal,3)*(1/2)),:,:)) )
subplot(2,3,6)
imshowpair( squeeze(dataR(:,:,round(size(dataR,3)*(2/3)))) , squeeze(maskFinal(:,:,round(size(maskFinal,3)*(2/3)),:,:)) )
     

   


