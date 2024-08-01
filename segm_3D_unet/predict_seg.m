%% predickce celych prsou

clear all
close all
clc

% read model
trainedNet = load('model_2.mat','net').net;

%% dataset public MR

% load('pat_list.mat')
% 
% i = 42; % od 42 je to validacni
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
dicomFiles = 'D:\Breast_MR\Export\DICOM\S41910\S6010';
% dicomFiles = 'D:\Breast_MR\Export\DICOM\S42640\S6010';

[collection,vel] = dicoms_info(dicomFiles, 'I*');


%% loading for dicom FNUSA
col = collection(collection.Dyn==1,:);    
[niftiData, InfoR] = dicomreadVolume(col.FileName);
niftiData = squeeze(niftiData);

[T,~,current_voxel_size] = TransMatrix(col.Info{1});
T = T';
T([1,2],:)=T([2,1],:);

current_voxel_size = current_voxel_size';

%% data preprocessing

target_size = [96,96,32];
desired_voxel_size = [2.0, 2.0, 2.0]; % 2mm x 2mm x 2mm

[img, T_new] = transfToUnit(niftiData, T, current_voxel_size, desired_voxel_size);

p = single(prctile(img(img>0),95,"all"));
img = uint16((double(img)/p)*500);


%% splitting and prediction

prct = 0.75;
numsIm = [ceil(size(img,1) / (target_size(1)*prct)),ceil(size(img,2) / (target_size(2)*prct)),ceil(size(img,3) / (target_size(3)*prct))];

x = linspace(1, size(img,1)-target_size(1), numsIm(1));
y = linspace(1, size(img,2)-target_size(2), numsIm(2));
z = linspace(1, size(img,3)-target_size(3), numsIm(3));

x(x<1)=[];
y(y<1)=[];
z(z<1)=[];

pred_mask = zeros(size(img));

for ra = 1:length(x)
    for sl = 1:length(y)
        for Z = 1:length(z)
            indX = round(x(ra):x(ra)+target_size(1)-1);
            indY = round(y(sl):y(sl)+target_size(2)-1);
            indZ = round(z(Z):z(Z)+target_size(3)-1);
            sIm = img(indX, indY, indZ);

            prediction = predict(trainedNet, single(sIm));

            pred_mask(indX, indY, indZ) =  ( pred_mask(indX, indY, indZ) + prediction(:,:,:,2) )./2;
            
        end
    end
end

%% 

mask = pred_mask>0.5;
imfuse5(img,mask)


