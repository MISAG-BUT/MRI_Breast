%% breasst segmentation

function [s] = segmentation_breast_2(dataR,info, net)


input_size = [128,128,64];
desired_voxel_size = [2,2,2];

[T,R,S] = getTransMatrix(info)

current_voxel_size = diag( S(1:3,1:3) )';

T = T';
T(:,[1,2]) = T(:,[2,1]);

[dataR2, T_new] = transfToUnit(dataR, T, current_voxel_size, desired_voxel_size);

vel = size(dataR2);

dataR2 = single( imresize3(dataR2, input_size,"nearest"));
dataR2 = ( rescale(dataR2,"InputMin",0,"InputMax",quantile(dataR(:),0.98)) *2500);

% Perform prediction
pred = predict(net, dataR2);

% mask = imresize3(pred(:,:,:,2)>0.5, vel,"nearest");

mask = pred(:,:,:,2)>0.5;
% mask = imopen(mask,create_sphere(1));
% mask = imopen(mask,create_sphere(2));
mask = imclose(mask,create_sphere(1));
% mask = imclose(mask,create_sphere(2));
mask = imopen(mask,create_sphere(1));

mask(:,62:end,:)=0;
niftiwrite(uint8(mask),'S:\MRI_Breast\data_train\NIFTI_Files_own\resized_Brest_MRI2_001_mask','Compressed', true)


%% visualization
figure
imshowpair( squeeze(dataR2(:,:,round(size(dataR,3)/2))) , squeeze(mask(:,:,round(size(mask1,3)/2),:,:)) )
     

   


