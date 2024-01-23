function [collection,vel] = dicoms_info(path)

D = dir([path '\I*']);
k=1;

collection=table('Size',[size(D,1),1],'VariableNames',{'FileName'},'VariableTypes',{'string'});
% collection=table("",'VariableNames',{'FileName'});

multiWaitbar('Loading dicom info', 'Increment', 1/length(D));


for i = 1:length(D)
    p = dicominfo( fullfile(D(i).folder,D(i).name) );
    if isfield(p,'ImageOrientationPatient')     
        collection{k,'FileName'} =  string( fullfile(D(i).folder,D(i).name));
        collection{k,'SliceLocation'} =  p.SliceLocation;
        AcquisitionTime = p.AcquisitionTime; 
        AcquisitionTime = AcquisitionTime(1:findstr(AcquisitionTime,'.')+2);
        collection{k,'AcquisitionTime'} =  AcquisitionTime;
        collection{k,'Info'} =  {p};
        k=k+1;
    end
    multiWaitbar('Loading dicom info', 'Value', i/length(D));
end

collection = collection(1:k-1,:);

TotalSlices = length(unique(collection.SliceLocation));
TotalDyn = height(collection)/TotalSlices;

collection = sortrows(collection,{'AcquisitionTime','SliceLocation'});
collection{:,'Slice'} = repmat([1:TotalSlices],1,TotalDyn)';

collection = sortrows(collection,{'SliceLocation','AcquisitionTime'});
collection{:,'Dyn'} = repmat([1:TotalDyn],1,TotalSlices)';

vel = [TotalSlices,TotalDyn];

multiWaitbar('Loading dicom info', 'Close');


