%% predickce celych prsou

clear all
close all
clc


%% dataset public MR

% path_to_dicom = 'S:\MRI_Breast\data_train\NIfTI_Files_resaved_3\';
% 
% pat_dir = dir([path_to_dicom 'Breast*_mask.nii.gz']);


%% dataset FNUSA
% % dicomFiles = 'S:\MRI_Breast\Data\Export\DICOM\S44930\S4010';
% % dicomFiles = 'S:\MRI_Breast\Data\Export\DICOM\S44961\S5010';
% % dicomFiles = 'S:\MRI_Breast\Data\Export\DICOM\S64400\S6010';
% % dicomFiles = 'D:\Breast_MR\Export\DICOM\S41610\S6010';
% % dicomFiles = 'D:\Breast_MR\Export\DICOM\S41910\S6010';
% % dicomFiles = 'D:\Breast_MR\Export\DICOM\S42640\S6010';

for d = 1:2

    if d==1
        path_to_dicom = 'D:\Breast_MR_I\Export\DICOM\';
    elseif d==2
        path_to_dicom = 'D:\Breast_MR_II\Export\DICOM\';
    end

pat_dir = dir([path_to_dicom 'S*']);


%%

for pat = 1:length(pat_dir)
    
    %% loading for dicom FNUSA

    dicomFiles = dir([pat_dir(pat).folder filesep pat_dir(pat).name filesep 'S*']);

    [fPath, fName, fExt] = fileparts(dicomFiles(1).folder);

    % if exist(['S:\MRI_Breast\Data_predicted\BestNet\MR_Breast_II\predicted_4_0\' fName '_orig.nii.gz' ])
    % else

    [collection] = dicoms_info([dicomFiles(1).folder filesep dicomFiles(1).name], 'I*');

    DC = dicomCollection([dicomFiles(1).folder filesep dicomFiles(1).name]);

    col = collection(collection.Dyn==1,:);

    % colNew = table('Size',[1,1],'VariableNames',{'Filenames'},'VariableTypes',{'string'});
    colNew = string(col{:,"Filenames"});

    % [niftiData, InfoR] = dicomreadVolume(col.FileName);
    % niftiData = squeeze(niftiData);
    % 
    % [T,~,current_voxel_size] = TransMatrix(col.Info{1});
    % T = T';
    % % T([1,2],:)=T([2,1],:);
    % 
    % current_voxel_size = current_voxel_size';
    
    %% data preprocessing
    
    medVol = medicalVolume(colNew);

    desired_voxel_size = [1 1 1];
    [data, newMapping] = resample_tform(medVol, desired_voxel_size);
    
    p = single(prctile(data(data>0),95,"all"));
    data = uint16((double(data)/p)*500);

    data = imrotate3(data,-90,[0,0,1]);
    
    %% splitting and prediction

    % for verse = [0,1,2,3]
    for verse = [8]

        % read model
        % net = load(['segm_3D_unet\trainedUNet_4_' num2str(verse) '.mat'],'net').net;
        net = load(['segm_3D_unet\trainedUNet_4_' num2str(verse) '.mat'],'netBest').netBest;

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

        % maskThr = imrotate3(maskThr,90,[0,0,1]);
        % maskFinal = imrotate3(maskFinal,90,[0,0,1]);

        maskThr = flip(maskThr,2);
        maskFinal = flip(maskFinal,2);

        % newMapping = invert(newMapping);
        % maskFinal = imwarp(maskFinal,(newMapping));
        % maskThr = imwarp(maskThr,(newMapping));
        
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

            if d==1
                path_save = ['S:\MRI_Breast\Data_predicted\BestNet\MR_Breast_I\predicted_4_' num2str(verse) filesep ];
            elseif d==2
                path_save = ['S:\MRI_Breast\Data_predicted\BestNet\MR_Breast_II\predicted_4_' num2str(verse) filesep ];
            end
        
        file_save = [pat_dir(pat).name];
        mkdir(path_save)
        
        load('nii_info.mat')
        nii_info.ImageSize = size(maskThr);
        nii_info.PixelDimensions = desired_voxel_size;
        nii_info.Transform.T = eye(4);
        nii_info.Datatype = 'int16';
        nii_info.Description = 'resaved data';
        
        % % nii_info = niftiinfo([path_save file_save '_orig']);
        
        if verse==0
            niftiwrite(int16(data),[path_save file_save '_orig'],nii_info,"Compressed",true)
        end

        niftiwrite(int16(maskFinal),[path_save file_save '_mask_pp'],nii_info,"Compressed",true)
        niftiwrite(int16(maskThr),[path_save file_save '_mask'],nii_info,"Compressed",true)
    
    end
    end

end
