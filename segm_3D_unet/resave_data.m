%% prepare traning dataset
clear all
close all
clc

addpath('dicm2nii');

path_data = 'C:\Data\MRI_prsa\manifest-1654812109500\Duke-Breast-Cancer-MRI';
output_path = 'C:\Data\MRI_prsa\manifest-1654812109500\NIfTI_Files';

% path_data = 'C:\Data\MRI_prsa\Validation\manifest-1654812109500\Duke-Breast-Cancer-MRI';
% output_path = 'C:\Data\MRI_prsa\Validation\manifest-1654812109500\Nifti';


if ~exist(output_path, 'dir')
    mkdir(output_path);
end

D = dir([path_data '\*MRI*']);

for i = 1:length(D)
    dicm2nii([path_data filesep D(i).name], [output_path filesep D(i).name], '.nii.gz');
end

%% resaving and resizing
clear all
close all
clc

% % Define paths
path_data = 'C:\Data\MRI_prsa\manifest-1654812109500\NIfTI_Files';
path_mask = 'C:\Data\MRI_prsa\Segmentation_Masks_NRRD';

% path_data = 'C:\Data\MRI_prsa\Validation\manifest-1654812109500\Nifti';

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
output_folder = 'C:\Data\MRI_prsa\manifest-1654812109500\NIfTI_Files_resaved';
mkdir(output_folder)

% Set target size for resizing (e.g., [128, 128, 128])
target_size = [128, 128, 64];

desired_voxel_size = [2.0, 2.0, 2.0]; % 2mm x 2mm x 2mm

% i = 10;
for i =  1:length(imageFiles)

    %
    % Load NIfTI file
    nii_path = fullfile(imageFiles(i).folder, imageFiles(i).name);
    nii_path_mask = fullfile(maskFiles(i).folder, maskFiles(i).name);

    img = niftiread(nii_path);
    mask = nrrdread(nii_path_mask);
    nii_info = niftiinfo(nii_path);
    nii_info2 = nrrdinfo(nii_path_mask);

    current_voxel_size = nii_info.PixelDimensions;
    current_voxel_size_mask = nii_info2.PixelDimensions;

    T = nii_info.Transform.T;
    % T(:,[1,2]) = T(:,[2,1]);
    [img2, T_new] = transfToUnit(img, T, current_voxel_size, desired_voxel_size);

    A = nii_info2.SpatialMapping.A';
    A(:,[1,2]) = A(:,[2,1]);
    [mask2, T_new_mask] = transfToUnit(mask, A, current_voxel_size_mask, desired_voxel_size);

    % disp(size(mask2))
    % disp(size(img2))
    % disp('-------------------------')
    % if sum(size(mask2) - size(img2))>0
    %     disp(num2str(i))
    % end

    img2 = double( imresize3(img2, target_size,"nearest"));

    % img2 = (img2 - mean(img2,"all")) / std(img2,[],"all");
    img2 = uint16(rescale(img2)*5000);

    mask2 = imresize3(mask2, target_size, "nearest");

    % imfuse5(img2, mask2)

    nii_info.ImageSize = size(img2);
    nii_info.PixelDimensions = desired_voxel_size;
    nii_info.Transform.T = T_new;
    nii_info.Datatype = 'uint16';

    % nii_info2.ImageSize = size(mask2);
    % nii_info2.PixelDimensions = desired_voxel_size;
    % nii_info2.Transform.T = T_new_mask;

    nii_info2 = nii_info;
    nii_info2.Datatype = 'uint8';

    % Save the resized and converted image
    [~, ~, ext] = fileparts(nii_path);
    [~, name, ] = fileparts(imageFiles(i).folder);

    output_file = fullfile(output_folder, ['resized_', name]);
    niftiwrite(img2, output_file, nii_info, 'Compressed', true);
    output_file = fullfile(output_folder, ['resized_', name, '_mask']);
    niftiwrite(uint8(mask2), output_file, nii_info2 , 'Compressed', true);

end