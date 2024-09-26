function [data, T_new] = transfToUnit(data, T, current_voxel_size, desired_voxel_size) 

vel = size(data);

T = inv(diag([desired_voxel_size 1])) * T;
T(4,1:3)=0;

% T(4,1:3) = T(4,1:3) - center;
% T_center = eye(4);
% T_center(4, 1:3) = center;
% T_combined = T_center * T * inv(T_center);

tform = affine3d(T);
% R = imref3d(size(data));
% data = imwarp(data, tform, 'OutputView', R);
data = imwarp(data, tform);

scale_factors = current_voxel_size ./ desired_voxel_size;
new_size = round(vel .* scale_factors);

data = int16(insertMatrix(zeros(new_size,'int16'),data));

% data = imresize3(data, new_size);

% Update the transformation matrices (qform and sform)
% scaling_matrix = diag([1./scale_factors 1]);
T_new = eye(4);
T_new(1:3,1:3) = diag(desired_voxel_size);
% T_new(4, 1:3) = T(4, 1:3) .* scale_factors ;  % Adjust translations