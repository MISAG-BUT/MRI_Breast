%% prepare data

% function [col]

% clear all
% close all
% clc

path_data = 'D:\pro_mr_prsa\Export\DICOM';
D = dir([path_data '\S*']);

D = D([D.isdir]);

i = 1;
path_1 = fullfile(D(i).folder, D(i).name);
DD = dir([path_1,'\S*']);

lenDD=[];
for ii = 1:length(DD)
    path_2 = fullfile(DD(ii).folder, DD(ii).name);
    lenDD(ii) = length(dir([path_2 '\I*']));
end

[~,m] = max(lenDD);

path_3 = fullfile(DD(m).folder, DD(m).name);

[collection,vel] = dicoms_info(path_3);
col = collection(collection.Dyn==3,"FileName");


% data = dicomreadVolume(col.FileName);


                    