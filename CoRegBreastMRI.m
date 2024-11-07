%% registrace MRI prs
clear all
close all
clc

% addpath(fullfile(ctfroot, 'utils\'))
addpath(fullfile(pwd, 'utils\'))

% path to dicoms file
[path_data] = uigetdir();

if path_data==0
    return
end

% Conditions for exist results ######################
R = dir([path_data '\**\Results']);

if ~isempty(R)
    answ = questdlg(['There have been found some exported results. Do you want to remove ones and export new results? '],"Existed results",'Yes','Cancel','Yes');
    switch answ
        case 'Yes' 
            R = R([contains({R.name},'..')]);
            for k = 1:length(R)
                rmdir(R(k).folder,'s');
            end
        case 'Cancel'
            return
    end
    if isempty(answ)
        return
    end
end

% finding patients
D = dir([path_data '\**\I*']);
D = unique({D.folder});
P = split(D{1},'\');
P = fullfile(P{1:end-2});

D =  dir(P);
D(1:2)=[];
D = D([D.isdir]);


answ = questdlg(['There were found ' num2str(length(D)) ' patient folders. Would you like to run the program?'],"Number of patients",'Yes','Cancel','Yes');
if isempty(answ)
    return
else
    switch answ
        case 'Cancel'
            return
    end
end

multiWaitbar('Segmentation model loading...', 'Value', 0.3);
net = load('trainedUNet_4_7.mat','netBest').netBest;
multiWaitbar( 'CloseAll' );

multiWaitbar(['Patient: 0 from ' num2str(length(D))], 'Increment', 1/length(D));

%% for cycle over cases
for pat = 1:length(D)

    multiWaitbar(['Patient: ' num2str(pat-1) ' from ' num2str(length(D))], 'Relabel', ['Patient: ' num2str(pat) ' from ' num2str(length(D))]);
    multiWaitbar(['Patient: ' num2str(pat) ' from ' num2str(length(D))], 'Value', (pat-1)/length(D));
    
    % selection of subfolder with dynamics
    path_1 = fullfile(D(pat).folder, D(pat).name);
    DD = dir([path_1,'\S*']);
    
    path_save = fullfile( D(pat).folder, D(pat).name,  'Results');
    mkdir(path_save)
    
    lenDD=[]; descriptions={};
    for ii = 1:length(DD)
        path_2 = fullfile(DD(ii).folder, DD(ii).name);
        dcmDD = dir([path_2 '\I*']);
        lenDD(ii) = length(dcmDD);
        descriptions{ii} = dicominfo(fullfile(dcmDD(1).folder, dcmDD(1).name)).SeriesDescription;
    end
    
    [~,m] = max(lenDD);
    path_3 = fullfile(DD(m).folder, DD(m).name);
    descriptions{m}

    % podminky pro nalezeni spravne dynamiky
    % napr. hledani textu "dyn", pak najit druhy nejosahlejsi slozku a
    % hledat slovo dyn

    % answ = questdlg(['There was found ' descriptions{m} ' series. Would you like to run the program?'],"Selected series",'Yes','Cancel','Yes');
    % if isempty(answ)
    %     return
    % else
    %     switch answ
    %         case 'Cancel'
    %             return
    %     end
    % end

%% division of dynamics in all dicoms files
    
    [collection] = dicoms_info(path_3, ['I*']);

    num_dyn = max(collection{:,'Dyn'});

    % save('collection.mat','collection','vel')
    % load('collection.mat')

%% saving Orig dicom

    multiWaitbar('Resaving dynamic data', 'Value', 0);

    col = collection(collection.Dyn==1,:); 

    [dataR,InfoR]=dicomreadVolume(col.Filenames);
    dataR = squeeze(dataR);
    dataR = flip(dataR,3);

    T = multithresh( single(dataR(dataR>0)) ./ single(max(dataR(:))) , 3) .* single(max(dataR(:)));
    T = T-10; T(T<0)=0;
    maskA =  uint8( dataR>T(1) );

    path_save_1 = [path_save filesep 'orig_dyn'];
    mkdir(path_save_1)

    path_save_2 = [path_save filesep 'reg_dyn'];
    mkdir(path_save_2)

    UID_orig = dicomuid;
    UID_reg = dicomuid;
    UID_sub_reg = dicomuid;
    UID_sub_orig = dicomuid;

    for i = 1:size(dataR,3)
        [~,name] = fileparts(col.Filenames(i));
        metadata = col.Info{i};
        metadata.SeriesDescription = [ 'NOT DIAG - ' 'Orig ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID_orig;
        metadata.WindowWidth = 600;
        metadata.WindowCenter = 300;
        dicomwrite( dataR(:,:,i), [path_save_1 filesep char(name)] , metadata);

        [~,name] = fileparts(col.Filenames(i));
        metadata = col.Info{i};
        metadata.SeriesDescription = [ 'NOT DIAG - ' 'Reg ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID_reg;
        metadata.WindowWidth = 600;
        metadata.WindowCenter = 300;
        dicomwrite( dataR(:,:,i), [path_save_2 filesep char(name)] , metadata);
        multiWaitbar('Resaving dynamic data', 'Value', i/size(dataR,3));
    end

    multiWaitbar('Resaving dynamic data', 'Close');

%% breast segmentation    

multiWaitbar('Breast segmentation','Value',0.3);

[mask, volumes, hFig] = segmentation_breast_2(dataR, col.Info{1,1}, net);

multiWaitbar('Breast segmentation','Value', 0.9);
pause(0.5)

filenameTxt = [ path_save filesep 'Breast_sizes.txt'];
appendNumbersToTxt(volumes(1), volumes(2), filenameTxt, 'Dyn_0 -')
% saveas(hFig,replace(filenameTxt,'Breast_sizes.txt', 'Breast_segmentation.png'))
saveas(hFig,replace(filenameTxt,'Breast_sizes.txt', 'Breast_segmentation.png'))
close(hFig)

niftiwrite(mask, replace(filenameTxt,'Breast_sizes.txt','Breast_mask.nii.gz'))
niftiwrite(dataR, replace(filenameTxt,'Breast_sizes.txt','Breast_native.nii.gz'))

multiWaitbar('Breast segmentation','Close');

%% registrace dynamik
    multiWaitbar('Registration of 1 dynamics','Increment',1/(num_dyn-1) );

for dyn = 2:num_dyn
    
    multiWaitbar(['Registration of ' num2str(dyn-1) ' dynamics'], 'Relabel', ['Registration of ' num2str(dyn) ' dynamics']);
    multiWaitbar(['Registration of ' num2str(dyn) ' dynamics'], 'Value', (dyn-2)/(num_dyn-1) );

    try
        rmdir([path_save filesep '\TempFile\'],'s');
    end

    tempFile = [path_save filesep '\TempFile\'];
    mkdir(tempFile);

    multiWaitbar('Read data','Increment',1/5);
    multiWaitbar('Read data','Value',1/5);

    col = collection(collection.Dyn==dyn,:);
    [dataM,InfoM]=dicomreadVolume(col.Filenames);
    
    dataM = squeeze(dataM);
    dataM = flip(dataM,3);

    T = multithresh( single(dataR(dataR>0)) ./ single(max(dataR(:))) , 3) .* single(max(dataR(:)));
    T = T-10; T(T<0)=0;
    maskB = uint8( dataM > T(1) );
    
    %%
    multiWaitbar('Read data','Relabel','Registration');
    multiWaitbar('Registration','Value',2/5);

    % PF_name = [ctfroot '\CoRegBreastM\BSpline_custom.txt' ];
    PF_name = ['BSpline_custom.txt' ];

%     disp(ctfroot)
%     disp(matlabroot)
%     disp(pwd)
    
    mat2raw_3D(dataR,tempFile,'imgA',[InfoR.PixelSpacings(1,:), InfoR.PatientPositions(2,3)-InfoR.PatientPositions(1,3)] )
    mat2raw_3D(dataM,tempFile,'imgB',[InfoM.PixelSpacings(1,:), InfoM.PatientPositions(2,3)-InfoM.PatientPositions(1,3)] )

    mat2raw_3D(maskA,tempFile,'maskA',[InfoR.PixelSpacings(1,:), InfoR.PatientPositions(2,3)-InfoR.PatientPositions(1,3)] )
    mat2raw_3D(maskB,tempFile,'maskB',[InfoM.PixelSpacings(1,:), InfoM.PatientPositions(2,3)-InfoM.PatientPositions(1,3)] )
    
    
    % CMD = [ ctfroot '\CoRegBreastM' '\elastix\elastix.exe -f ' [tempFile 'imgA.mhd']  ' -m ' [tempFile 'imgB.mhd'] ' -out ' [tempFile ] ' -p ' [PF_name] ' -fMask ' [tempFile 'maskA.mhd'] ' -mMask ' [tempFile 'maskB.mhd']];
    CMD = ['elastix\elastix.exe -f ' [tempFile 'imgA.mhd']  ' -m ' [tempFile 'imgB.mhd'] ' -out ' [tempFile ] ' -p ' [PF_name] ' -fMask ' [tempFile 'maskA.mhd'] ' -mMask ' [tempFile 'maskB.mhd']];

    system(CMD)
    
    
    %% loading of registered volume
    
    [registered, ~] = load_raw_reg([tempFile,'result.0.mhd']);
    registered(registered>(64000))=0;

    
    %% saving REGistered data

    multiWaitbar('Registration','Relabel','Saving data');
    multiWaitbar('Saving data','Value',3/5);
    multiWaitbar('Progress','Increment',1/size(registered,3));

    path_save_1 = [path_save filesep 'reg_dyn'];
    mkdir(path_save_1)

    for i = 1:size(registered,3)
        [~,name] = fileparts(col.Filenames(i));
        metadata = col.Info{i};
        metadata.SeriesDescription = [ 'NOT DIAG - ' 'Reg ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID_reg;
        metadata.WindowWidth = 600;
        metadata.WindowCenter = 300;
        dicomwrite( registered(:,:,i), [path_save_1 filesep char(name)] , metadata);
        multiWaitbar('Progress','Value',i/size(registered,3));
    end

    %% saving SUBSTRAKCE
        
    path_save_1 = [path_save filesep 'sub_reg_dyn'];
    mkdir(path_save_1)

    subtr = int16(registered) - int16(dataR);

    for i = 1:size(registered,3)
        [~,name] = fileparts(col.Filenames(i));
        metadata = col.Info{i};
        metadata.SeriesDescription = ['NOT DIAG - ' 'Sub Reg ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID_sub_reg;
        metadata.WindowWidth = 300;
        metadata.WindowCenter = 100;
        dicomwrite( subtr(:,:,i), [path_save_1 filesep char(name)] , metadata);
        multiWaitbar('Progress','Value',i/size(registered,3));
    end

    multiWaitbar('Saving data','Value',4/5);

    path_save_1 = [path_save filesep 'sub_orig_dyn'];
    mkdir(path_save_1)

    subtr = int16(dataM) - int16(dataR);

    for i = 1:size(dataM,3)
        [~,name] = fileparts(col.Filenames(i));
        metadata = col.Info{i};
        metadata.SeriesDescription = ['NOT DIAG - ' 'Sub Orig ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID_sub_orig;
        metadata.WindowWidth = 300;
        metadata.WindowCenter = 100;
        dicomwrite( subtr(:,:,i), [path_save_1 filesep char(name)] , metadata);
        multiWaitbar('Progress','Value',i/size(registered,3));
    end


    %% saving Orig dicom
        
    multiWaitbar('Saving data','Value',5/5);

    path_save_1 = [path_save filesep 'orig_dyn'];

    for i = 1:size(dataM,3)
        [~,name] = fileparts(col.Filenames(i));
        metadata = col.Info{i};
        metadata.SeriesDescription = [ 'NOT DIAG - ' 'Orig ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID_orig;
        metadata.WindowWidth = 600;
        metadata.WindowCenter = 300;
        dicomwrite( dataM(:,:,i), [path_save_1 filesep char(name)] , metadata);
        multiWaitbar('Progress','Value',i/size(registered,3));
    end

    multiWaitbar('Saving data','Close');
    multiWaitbar('Progress','Close');
    multiWaitbar(['Registration of ' num2str(dyn) ' dynamics'], 'Close' );

end

try
   rmdir([path_save filesep '\TempFile\'],'s');
end

end

multiWaitbar( 'CloseAll' );
uiwait(msgbox(['The registration of ' num2str(length(D)) ' patients have been succefully done'],"Finalized","warn"));

