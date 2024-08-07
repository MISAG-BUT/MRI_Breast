%% prepare traning dataset
clear all
close all
clc

% addpath('dicm2nii');
% 
% path_data = 'C:\Data\MRI_prsa\manifest-1654812109500\Duke-Breast-Cancer-MRI';
% output_path = 'C:\Data\MRI_prsa\manifest-1654812109500\NIfTI_Files';
% 
% % path_data = 'C:\Data\MRI_prsa\Validation\manifest-1654812109500\Duke-Breast-Cancer-MRI';
% % output_path = 'C:\Data\MRI_prsa\Validation\manifest-1654812109500\Nifti';
% 
% 
% if ~exist(output_path, 'dir')
%     mkdir(output_path);
% end
% 
% D = dir([path_data '\*MRI*']);
% 
% for i = 1:length(D)
%     dicm2nii([path_data filesep D(i).name], [output_path filesep D(i).name], '.nii.gz');
% end


%% resaving and resizing
clear all
close all
clc

% % Define paths
path_data = 'S:\MRI_Breast\data_train\NIfTI_Files';
path_mask = 'S:\MRI_Breast\data_train\Segmentation_Masks_NRRD';

% Load images 
imageFiles = dir(fullfile(path_data, '**', '*.nii.gz'));

% Filter files that contain "dyn" and either "1st" or "Ph1" in their name
filteredFiles = [];
for i = 1:length(imageFiles)
    fileName = imageFiles(i).name;
    if ( contains(fileName, 'dyn') || contains(fileName, 'pre') || contains(fileName, 'Vibrant') ) && ~( contains(fileName, 'Ph' ) || contains(fileName, 't1') ...
            || contains(fileName, '1st') || contains(fileName, '2nd') || contains(fileName, '3rd') || contains(fileName, '4th') ...
            || contains(fileName, 'resized'))
        % if contains(fileName, 'Ph' )
            filteredFiles = [filteredFiles; imageFiles(i)];
        % end
    elseif contains(fileName, 'MultiPhase' ) && ~( contains(fileName(1:5), 'Ph' ))
        filteredFiles = [filteredFiles; imageFiles(i)];
    end
end

imageFiles = filteredFiles;

maskFiles = dir(fullfile(path_mask, '**', '*Breast.seg.nrrd'));
maskFiles = maskFiles(1:length(imageFiles));


%%
output_folder = 'S:\MRI_Breast\data_train\NIfTI_Files_resaved_3';
mkdir(output_folder)

desired_voxel_size = [1 1 1]; % 2mm x 2mm x 2mm

% i = 10;
for i = 10 %1:length(imageFiles)
% for i = 1:2

    % Load NIfTI file
    nii_path = fullfile(imageFiles(i).folder, imageFiles(i).name);
    nii_path_mask = fullfile(maskFiles(i).folder, maskFiles(i).name);

    medVol = medicalVolume(nii_path);
    % info = niftiinfo(nii_path);
    [img, ~] = resample_tform(medVol, desired_voxel_size);

    medVol = medicalVolume(nii_path_mask);
    [mask, ~] = resample_tform(medVol, desired_voxel_size);

    [~, name, ] = fileparts(imageFiles(i).folder);

    if sum(size(img) == size(mask))<3
        mask = imresize3(mask,size(img),'nearest');
    end

    % write(newVol.Voxels, [output_folder filesep name '.nii.gz'])
    niftiwrite(img,[output_folder filesep name '.nii.gz'])
    niftiwrite(mask,[output_folder filesep name '_mask.nii.gz'])

end