%% registrace MRI prs
clear all
close all
clc

% path_data = 'D:\pro_mr_prsa\Export\DICOM';
% D = dir([path_data '\S*']);

% [path_data] = uigetdir(['C:\Data\MRI_prsa\test\Breast_MRI_020']);
% [path_data] = uigetdir();
% path_data = 'C:\Data\MRI_prsa\test\Breast_MRI_018';
path_data = 'C:\Data\MRI_prsa\test';


name_find = '1-*';

if path_data==0
    return
end

% h = waitbar(0,'Folder selection...');

% Conditions for exist results ######################
% R = dir([path_data '\**\Results']);

% if ~isempty(R)
%     answ = questdlg(['There have been found some exported results. Do you want to remove ones and export new results? '],"Existed results",'Yes','Cancel','Yes');
%     switch answ
%         case 'Yes' 
%             R = R([contains({R.name},'..')]);
%             for k = 1:length(R)
%                 rmdir(R(k).folder,'s');
%             end
%         case 'Cancel'
%             return
%     end
%     if isempty(answ)
%         return
%     end
% end

% D = dir([path_data '\**\I*']);
% D = dir([path_data '\**\' name_find]);
% D = unique({D.folder});

% P = split(D{1},'\');
% P = fullfile(P{1:end-2});

D =  dir(path_data);
D(1:2)=[];
D = D([D.isdir]);

% waitbar(1,h);
% close(h)

% uiwait(msgbox(['There were found ' num2str(length(D)) ' patient folders'],"Number of patients","warn"));

answ = questdlg(['There were found ' num2str(length(D)) ' patient folders. Would you like to run the program?'],"Number of patients",'Yes','Cancel','Yes');
if isempty(answ)
    return
else
    switch answ
        case 'Cancel'
            return
    end
end

% h = waitbar(0,['Patient 1 from ' num2str(length(D))]);
% multiWaitbar( 'CloseAll' );
% multiWaitbar(['Patient: 0 from ' num2str(length(D))], 'Increment', 1/length(D));

%%
for pat = 1:length(D)

% multiWaitbar(['Patient: ' num2str(pat-1) ' from ' num2str(length(D))], 'Relabel', ['Patient: ' num2str(pat) ' from ' num2str(length(D))]);
% multiWaitbar(['Patient: ' num2str(pat) ' from ' num2str(length(D))], 'Value', (pat-1)/length(D));

% path_1 = fullfile(D(pat).folder, D(pat).name);
path_1 = fullfile(D(pat).folder, D(pat).name);
DD = dir([path_1,'\**\*dyn*']);

% path_save = fullfile( D(pat).folder, D(pat).name,  'Results');
% mkdir(path_save)

lenDD=[];
for ii = 1:length(DD)
    path_2 = fullfile(DD(ii).folder, DD(ii).name);
    lenDD(ii) = length(dir([path_2 '\' name_find]));
end

for dyn = 1 %1:length(DD)
    path_3 = fullfile(DD(dyn).folder, DD(dyn).name);

%%
    [collection,vel] = dicoms_info(path_3, name_find);

    col = collection(collection.Dyn==1,:);    
    [dataR,InfoR]=dicomreadVolume(col.FileName);
    dataR = single(squeeze(dataR));

    if sign(collection.Info{1}.ImageOrientationPatient(1))==-1
        dataR = flip(dataR,1);
    end

    %%
     [s, mask] = segmentation_breast(dataR,[collection.Info{1}.PixelSpacing(1),collection.Info{1}.PixelSpacing(1),collection.Info{1}.PixelSpacing(1)]);
     s

    end
    
    
    try
       rmdir([path_save filesep '\TempFile\'],'s');
    end

end


