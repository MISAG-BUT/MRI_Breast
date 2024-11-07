% ===================================================================
% Description: Loading dicom files
% Input:    path  - folder path with Dicom files
% 
% Output:   im_load - loaded original data
%           info - structure of parameters
% 
% Authors:  Roman Jakubicek
%           Jiri Chmelik
% ===================================================================

function [im_load,Info] = load_dicom(path)

Files  = dir(path);
StructureIndexes = arrayfun(@(x) x.isdir,Files);
Files(StructureIndexes)=[];
StructureIndexes = arrayfun(@(x) strcmp(x.name,'DIRFILE'),Files);
Files(StructureIndexes)=[];
SlicesTotal = length(Files);

info = dicominfo([path '\' Files(10).name]);
Info.size_im = [info.Height, info.Width];
Info.resolution = [info.PixelSpacing; info.SliceThickness];
Info.SlicesTotal = SlicesTotal;
Info.dcm_info = info;

im_load=single(false(Info.size_im(1),Info.size_im(2),Info.SlicesTotal));

for i = 1:SlicesTotal
    info = dicominfo([path '\' Files(i).name]);
    number = info.InstanceNumber;
    im_load(:,:,number)=single(dicomread([path '\' Files(i).name]));
    
    P = [info.ImageOrientationPatient(1)*info.PixelSpacing(1),info.ImageOrientationPatient(4)*info.PixelSpacing(2),0,info.ImagePositionPatient(1);...
         info.ImageOrientationPatient(2)*info.PixelSpacing(1),info.ImageOrientationPatient(5)*info.PixelSpacing(2),0,info.ImagePositionPatient(2);...
         info.ImageOrientationPatient(3)*info.PixelSpacing(1),info.ImageOrientationPatient(6)*info.PixelSpacing(2),0,info.ImagePositionPatient(3)]...
         *[1;1;0;1]; % compute voxel coordinates of each slice
    P_z(number) = P(3); % z coordinates of each slice
end

SpacingBetweenSlices = diff(P_z); % compute SpacingBetweenSlices for each slice
SpacingBetweenSlices = mode(abs(SpacingBetweenSlices)); % modus value of SpacingBetweenSlices
if info.SliceThickness == SpacingBetweenSlices % conditions for correct physical voxel size determination
%     Info.resolution(3) = double(info.SliceThickness);
elseif info.SliceThickness > SpacingBetweenSlices
    Info.resolution(3) = double(SpacingBetweenSlices);
else
    Info.resolution(3) = double(SpacingBetweenSlices); % not correct resolution!!! program is not adapted for work with GAP between slices
end


 Info.resolution =  Info.resolution';
 SpacingBetweenSlices = diff(P_z); % compute SpacingBetweenSlices for each slice
 SpacingBetweenSlices = mode((SpacingBetweenSlices));
 Info.SpacingBetweenSlices = SpacingBetweenSlices;
 Info.SlicePositions = P_z;
 
if Info.SpacingBetweenSlices>0
    im_load = flip(im_load,3);
end

contrast = info.RescaleIntercept;
im_load = uint16( im_load+(contrast) );