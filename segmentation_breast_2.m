%% breasst segmentation

function [s] = segmentation_breast_2(dataR,pixelSize)


input_size = [128,128,64];
desired_voxel_size = [2,2,2];



%% visualization
figure
imshowpair( squeeze(dataR(:,:,round(size(dataR,3)/2))) , squeeze(mask1(:,:,round(size(mask1,3)/2),:,:)) )
     

   


