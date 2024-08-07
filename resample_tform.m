%% resample object Volume

function [new, new_tform] = resample_tform(medVol, targetVoxelSize)

ratios = targetVoxelSize ./ medVol.VoxelSpacing;
% ratios = medVol.VoxelSpacing ./ targetVoxelSize;


origSize = size(medVol.Voxels);
newSize = round(origSize ./ ratios);

origRef = medVol.VolumeGeometry;
origMapping = intrinsicToWorldMapping(origRef);
% tform = origMapping.A;
tform = origMapping.A;

newMapping4by4 = tform * diag([1./medVol.VoxelSpacing 1]);
newMapping4by4 = newMapping4by4 * diag([ratios 1]);
newMapping = affinetform3d(newMapping4by4);
newMapping = invert(newMapping);

new = imwarp(medVol.Voxels,(newMapping));
new_tform = diag([targetVoxelSize 1]);

% new = flip(new,1);

% newRef = medicalref3d(newSize,newMapping);

% newRef = orient(newRef,origRef.PatientCoordinateSystem);

% newVol = resample(medVol,newRef);

