%% predickce prsou v nifti = DUKE dataset
clear all
close all
clc


%% dataset Lambert
path_to_data = 'S:\MRI_Breast\data_train\NIfTI_Files_resaved_3\';
pat_dir = dir([path_to_data 'Breast*_mask.nii.gz']);


%%
for pat = 5 %1:length(pat_dir)
    
    %% loading for dicom FNUSA

    % pat = 2;

    file_name = replace(fullfile(pat_dir(pat).folder,pat_dir(pat).name),'_mask.nii','.nii');
    nifti_data = medicalVolume( file_name );

    % figure
    % imshow(nifti_data.Voxels(:,:,90),[])

    if length(size(nifti_data.Voxels))==4
        nifti_data.Voxels = nifti_data.Voxels(:,:,:,1);
    end

    vel = size(nifti_data.Voxels);
    
    % data preprocessing
    
    desired_voxel_size = [1 1 1];
    [data, newMapping] = resample_tform(nifti_data, desired_voxel_size);

    % figure
    % imshow(data(:,:,90),[])

    newMapping = invert(newMapping);

    % figure
    % imshow(new(:,:,90),[])

    % data = imrotate3(data,90,[0,0,1]);

    p = single(prctile(data(data>0),95,"all"));
    data = uint16((double(data)/p)*500);

    figure
    imshow(data(:,:,90),[])
    
    %% splitting and prediction

    % for verse = [0,1,2,3]
    for verse = [0]

        % read model
        net = load(['trainedUNet_4_' num2str(verse) '.mat'],'netBest').netBest;

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
        
        %%
        
        maskThr = mask>0.5;
        
        maskFinal = refinement_mask(maskThr);
        
        % SE = create_sphere(1);
        % SE = SE(:,:,3);
        % maskThr = imclose(maskThr,SE);
        % maskThr = imfill(maskThr,8,"holes");
        % maskThr = permute(maskThr,[1,3,2]);
        % maskThr = imclose(maskThr,SE);
        % maskThr = imfill(maskThr,8,"holes");
        % maskThr = permute(maskThr,[1,3,2]);
        % 
        % stats = regionprops(maskThr,'Area');
        % [~, ind] = sort([stats.Area],'descend');
        % lbl = bwlabeln(maskThr);
        % maskFinal = lbl==ind(1);
        
        % imfuse5(data, maskFinal)
        % imshow5(lbl)

        % path_save = ['S:\MRI_Breast\Data_predicted\BestNet\MR_Breast_I\predicted_4_' num2str(verse) filesep ];
        path_save = [path_to_data filesep ];
        
        file_save = [pat_dir(pat).name];
        mkdir(path_save)
        
        % load('nii_info.mat')
        % nii_info.ImageSize = size(maskThr);
        % nii_info.PixelDimensions = desired_voxel_size;
        % nii_info.Transform.T = eye(4);
        % nii_info.Datatype = 'int16';
        % nii_info.Description = 'resaved data';
        
        nii_info = niftiinfo(fullfile(pat_dir(pat).folder,pat_dir(pat).name));

        nii_info.ImageSize = nii_info.ImageSize([1:3]);
        nii_info.PixelDimensions = nii_info.PixelDimensions([1:3]);

        % maskFinal = imrotate3(maskFinal,-90,[0,0,1]);
        % maskThr = imrotate3(maskThr,-90,[0,0,1]);

        maskFinal = imwarp(maskFinal,(newMapping));
        maskThr = imwarp(maskThr,(newMapping));

        maskFinal = imresize3(maskFinal,[vel]);
        maskThr = imresize3(maskThr,[vel]);

        niftiwrite(uint8(maskFinal),[path_save replace(file_save, 'mask','mask_pred')],nii_info,"Compressed",true)
        % niftiwrite(int16(maskThr),[path_save replace(file_save, 'orig','mask')],nii_info,"Compressed",true)
    
    end
    % end

end
