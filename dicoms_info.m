function [collection] = dicoms_info(path, name_find)

D = dir([path '\' name_find ]);
k=1;

collection=table('Size',[size(D,1),1],'VariableNames',{'Filenames'},'VariableTypes',{'string'});
% collection=table("",'VariableNames',{'FileName'});

multiWaitbar('Loading dicom info', 'Increment', 1/length(D));


for i = 1:length(D)
    p = dicominfo( fullfile(D(i).folder,D(i).name) );
    if isfield(p,'SliceLocation')     
        % collection{k,'Filenames'} =  string( fullfile(D(i).folder,D(i).name));
        collection{k,'Filenames'} =  {fullfile(D(i).folder,D(i).name)};
        collection{k,'SliceLocation'} =  p.SliceLocation;
        AcquisitionTime = p.AcquisitionTime; 
        AcquisitionTime = AcquisitionTime(1:findstr(AcquisitionTime,'.')+2);
        if isempty(AcquisitionTime)
            AcquisitionTime = p.AcquisitionTime;
        end
        collection{k,'AcquisitionTime'} = AcquisitionTime;
        collection{k,'Info'} =  {p};
        k=k+1;
    end
    multiWaitbar('Loading dicom info', 'Value', i/length(D));
end

collection = collection(1:k-1,:);

TotalSlices = length(unique(collection.SliceLocation));
% TotalDyn = height(collection)/TotalSlices;
TotalDyn = length(unique(str2num(collection.AcquisitionTime)));
StatDyn = countlabels(str2num(collection.AcquisitionTime));
IDSlices = [];
IDDyn = [];

collection = sortrows(collection,{'AcquisitionTime','SliceLocation'});

for d = 1:TotalDyn
    NumSlices = StatDyn.Count(d);

    IDSlices = [IDSlices, 1:NumSlices];
    % collection = sortrows(collection,{'AcquisitionTime','SliceLocation'});
    % collection{1:NumSlices,'Slice'} = [1:NumSlices]';
    
    % collection = sortrows(collection,{'SliceLocation','AcquisitionTime'});
    % collection{:,'Dyn'} = repmat([1:TotalDyn],1,TotalSlices)';
    IDDyn = [IDDyn,ones(1,NumSlices)*d];
    % vel = [TotalSlices,TotalDyn];
end

collection{:,'Slice'} = IDSlices';
collection{:,'Dyn'} = IDDyn';

multiWaitbar('Loading dicom info', 'Close');


