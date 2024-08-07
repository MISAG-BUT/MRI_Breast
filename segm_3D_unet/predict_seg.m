%% predickce celych prsou

clear all
close all
clc

% read model
trainedNet = load('segm_3D_unet\model_2_0.mat','net').net;

%% dataset public MR

% load('pat_list.mat')
% 
% i = 44; % od 42 je to validacni
% niftiFilePath = fullfile(imageFiles(i).folder, imageFiles(i).name);
% 
% %% loading for nifti public
% nii_info = niftiinfo(niftiFilePath);
% niftiData = niftiread(niftiFilePath);
% 
% T = nii_info.Transform.T;
% current_voxel_size = nii_info.PixelDimensions;


%% dataset FNUSA
% dicomFiles = 'S:\MRI_Breast\Data\Export\DICOM\S44930\S4010';
% dicomFiles = 'S:\MRI_Breast\Data\Export\DICOM\S44961\S5010';
% dicomFiles = 'S:\MRI_Breast\Data\Export\DICOM\S64400\S6010';
% dicomFiles = 'D:\Breast_MR\Export\DICOM\S41610\S6010';
% dicomFiles = 'D:\Breast_MR\Export\DICOM\S41910\S6010';
% dicomFiles = 'D:\Breast_MR\Export\DICOM\S42640\S6010';

path_to_dicom = 'D:\Breast_MR\Export\DICOM\';

%%
pat_dir = dir([path_to_dicom 'S*']);

for pat = 1%length(pat_dir)
    
    %% loading for dicom FNUSA

    dicomFiles = dir([pat_dir(pat).folder filesep pat_dir(pat).name filesep 'S*']);

    [collection,vel] = dicoms_info([dicomFiles(1).folder filesep dicomFiles(1).name], 'I*');
    
    col = collection(collection.Dyn==1,:);    
    [niftiData, InfoR] = dicomreadVolume(col.FileName);
    niftiData = squeeze(niftiData);
    
    [T,~,current_voxel_size] = TransMatrix(col.Info{1});
    T = T';
    % T([1,2],:)=T([2,1],:);
    
    current_voxel_size = current_voxel_size';
    
    %% data preprocessing
    
    target_size = [96,96,32];
    desired_voxel_size = [2.0, 2.0, 2.0]; % 2mm x 2mm x 2mm
    
    [img, T_new] = transfToUnit(niftiData, T, current_voxel_size, desired_voxel_size);
    
    p = single(prctile(img(img>0),95,"all"));
    img = uint16((double(img)/p)*500);

    img = imrotate3(img,90,[0,0,1]);
    
    
    %% splitting and prediction
    
    prct = 0.95;
    numsIm = [ceil(size(img,1) / (target_size(1)*prct)),ceil(size(img,2) / (target_size(2)*prct)),ceil(size(img,3) / (target_size(3)*prct))];
    
    x = linspace(1, size(img,1)-target_size(1), numsIm(1));
    y = linspace(1, size(img,2)-target_size(2), numsIm(2));
    z = linspace(1, size(img,3)-target_size(3), numsIm(3));
    
    x(x<1)=[];
    y(y<1)=[];
    z(z<1)=[];
    
    pred_mask = zeros(size(img,[1,2,3]));
    
    for ra = 1:length(x)
        for sl = 1:length(y)
            for Z = 1:length(z)
                indX = round(x(ra):x(ra)+target_size(1)-1);
                indY = round(y(sl):y(sl)+target_size(2)-1);
                indZ = round(z(Z):z(Z)+target_size(3)-1);
                sIm = img(indX, indY, indZ);

                prediction = predict(trainedNet, single(sIm));

                % sIm = imrotate3(sIm,90,[0,0,1]);
                % prediction2 = predict(trainedNet, single(sIm));
                % prediction2 = imrotate3(prediction2(:,:,:,2),-90,[0,0,1]);
                % prediction = (prediction1(:,:,:,2) + prediction2)./2;

                pred_mask(indX, indY, indZ) =  ( pred_mask(indX, indY, indZ) + prediction(:,:,:,2) )./2;
                
            end
        end
    end

    pred_mask = imrotate3(pred_mask,-90,[0,0,1],"nearest");

    % prevzorkovani
    % [pred_mask_orig, T_mask] = transfToUnit(single(pred_mask>0.5), T_new, desired_voxel_size, current_voxel_size);
    
    % % nechat s podvzorkovanim?
    pred_mask_orig = int16(pred_mask>0.5);
    current_voxel_size = desired_voxel_size;
    T_mask = T_new;
    img = imrotate3(img,-90,[0,0,1]);

    SE = create_sphere(1);
    SE = SE(:,:,3);
    pred_mask_orig = imclose(pred_mask_orig,SE);
    pred_mask_orig = imfill(pred_mask_orig,8,"holes");
    pred_mask_orig = permute(pred_mask_orig,[1,3,2]);
    pred_mask_orig = imfill(pred_mask_orig,8,"holes");
    pred_mask_orig = permute(pred_mask_orig,[1,3,2]);

    path_save = ['S:\MRI_Breast\Data\predicted_2_0' filesep   ];
    file_save = [pat_dir(pat).name];
    mkdir(path_save)

    load('nii_info.mat')
    nii_info.ImageSize = size(pred_mask_orig);
    nii_info.PixelDimensions = current_voxel_size;
    nii_info.Transform.T = T_mask;
    nii_info.Datatype = 'int16';
    nii_info.Description = 'resaved data';

    % nii_info = niftiinfo([path_save file_save '_orig']);

    niftiwrite(int16(img),[path_save file_save '_orig'],nii_info,"Compressed",true)
    niftiwrite(pred_mask_orig,[path_save file_save '_mask'],nii_info,"Compressed",true)

end

% %% 
% 
% mask = pred_mask>0.5;
% imfuse5(img,mask)
% 
% %%
% % imshow5(img)
% imshow5(int16(pred_mask>0.5)*500)
% 
% imfuse5(niftiData,pred_mask_orig)