%% registrace MRI prs
clear all
close all
clc

path_data = 'D:\pro_mr_prsa\Export\DICOM';
D = dir([path_data '\S*']);

D = D([D.isdir]);

for pat = 1:5


path_1 = fullfile(D(pat).folder, D(pat).name);
DD = dir([path_1,'\S*']);

path_save = fullfile( D(pat).folder, D(pat).name,  'Results');
mkdir(path_save)

lenDD=[];
for ii = 1:length(DD)
    path_2 = fullfile(DD(ii).folder, DD(ii).name);
    lenDD(ii) = length(dir([path_2 '\I*']));
end

[~,m] = max(lenDD);
path_3 = fullfile(DD(m).folder, DD(m).name);


%%

[collection,vel] = dicoms_info(path_3);
% save('collection.mat','collection','vel')

% load('collection.mat')


%%

%% saving Orig dicom

    col = collection(collection.Dyn==1,:);    
    [dataR,InfoR]=dicomreadVolume(col.FileName);
    dataR = squeeze(dataR);    

    maskA =  uint8(dataR>10);
%     maskA = bwareaopen(maskA,100);

%     path_save_1 = [path_save filesep 'orig_dyn_'  num2str(1)];
    path_save_1 = [path_save filesep 'orig_dyn'];
    mkdir(path_save_1)

    UID_orig = dicomuid;
    UID_reg = dicomuid;
    UID_sub_reg = dicomuid;
    UID_sub_orig = dicomuid;

    for i = 1:size(dataR,3)
        [~,name] = fileparts(col.FileName(i));
        metadata = col.Info{i};
        metadata.SeriesDescription = [ 'NOT DIAG - ' 'Orig ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID_orig;
        metadata.WindowWidth = 600;
        metadata.WindowCenter = 300;
        dicomwrite( dataR(:,:,i), [path_save_1 filesep char(name)] , metadata);
    end

    % save first orig as first reg dyn
    path_save_1 = [path_save filesep 'reg_dyn'];
    mkdir(path_save_1)

    for i = 1:size(dataR,3)
        [~,name] = fileparts(col.FileName(i));
        metadata = col.Info{i};
        metadata.SeriesDescription = [ 'NOT DIAG - ' 'Reg ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID_reg;
        metadata.WindowWidth = 600;
        metadata.WindowCenter = 300;
        dicomwrite( dataR(:,:,i), [path_save_1 filesep char(name)] , metadata);
    end

%% registrace dynamik

for dyn = 2:vel(2)

    try
        rmdir([pwd '\TempFile\'],'s');
    end

    tempFile = [pwd '\TempFile\'];
    mkdir(tempFile);

%     col = collection(collection.Dyn==1,:);    
%     [dataR,InfoR]=dicomreadVolume(col.FileName);

    col = collection(collection.Dyn==dyn,:);
    [dataM,InfoM]=dicomreadVolume(col.FileName);
    
%     dataR = squeeze(dataR);
    dataM = squeeze(dataM);

    maskB = uint8(dataM>10);
    
    
    %%
    
    PF_name = ['parametric_file\' 'BSpline_custom.txt' ];
    
    mat2raw_3D(dataR,tempFile,'imgA',[InfoR.PixelSpacings(1,:), InfoR.PatientPositions(2,3)-InfoR.PatientPositions(1,3)] )
    mat2raw_3D(dataM,tempFile,'imgB',[InfoM.PixelSpacings(1,:), InfoM.PatientPositions(2,3)-InfoM.PatientPositions(1,3)] )

    mat2raw_3D(maskA,tempFile,'maskA',[InfoR.PixelSpacings(1,:), InfoR.PatientPositions(2,3)-InfoR.PatientPositions(1,3)] )
    mat2raw_3D(maskB,tempFile,'maskB',[InfoM.PixelSpacings(1,:), InfoM.PatientPositions(2,3)-InfoM.PatientPositions(1,3)] )
    
    
    CMD = ['elastix\elastix.exe -f ' [tempFile 'imgA.mhd']  ' -m ' [tempFile 'imgB.mhd'] ' -out ' [tempFile ] ' -p ' [PF_name] ' -fMask ' [tempFile 'maskA.mhd'] ' -mMask ' [tempFile 'maskB.mhd']];
%     CMD = ['elastix\elastix.exe -f ' [tempFile 'imgA.mhd']  ' -m ' [tempFile 'imgB.mhd'] ' -out ' [tempFile ] ' -p ' [PF_name] ];
    system(CMD)
    
    
    %%
    
    [registered, ~] = load_raw_reg([tempFile,'result.0.mhd']);
    
    % registered = uint16(registered);
    registered(registered>(64000))=0;
    % registered(registered>(250))=0;
    % dataM(dataM>(250))=0;
    
    
    % imshow5(registered)
    
    slice = floor(vel(1)/2);
    figure
    subplot 121
    imshowpair(dataR(:,:,slice),dataM(:,:,slice))
    subplot 122
    imshowpair(dataR(:,:,slice),registered(:,:,slice))

    print([path_save filesep 'img_dyn_' num2str(dyn) '.png'],'-dpng')
    close all

    % figure(6)
    % subplot 131
    % imshow(dataR(:,:,100),[])
    % subplot 132
    % imshow(dataM(:,:,100),[])
    % subplot 133
    % imshow(registered(:,:,100),[])
    % 
    % figure(7)
    % imshowpair(dataM(:,:,50),registered(:,:,50))
    
    %% saving REG
    
%     info = dicomCollection([ mD.folder filesep mD.name filesep ]);
    
%     path_save_1 = [path_save filesep 'reg_dyn_'  num2str(dyn)];
    path_save_1 = [path_save filesep 'reg_dyn'];
    mkdir(path_save_1)


%     UID_reg = dicomuid;
    for i = 1:size(registered,3)
        [~,name] = fileparts(col.FileName(i));
        metadata = col.Info{i};
        metadata.SeriesDescription = [ 'NOT DIAG - ' 'Reg ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID_reg;
        metadata.WindowWidth = 600;
        metadata.WindowCenter = 300;
        dicomwrite( registered(:,:,i), [path_save_1 filesep char(name)] , metadata);
    end

    %% saving SUBSTRAKCE
        
%     path_save_1 = [path_save filesep 'sub_reg_dyn_'  num2str(dyn)];
    path_save_1 = [path_save filesep 'sub_reg_dyn'];
    mkdir(path_save_1)


    subtr = int16(registered) - int16(dataR);
%     subtr = int16(dataM) - int16(dataR);
%     range = max(subtr(:,:,100),[],'all') - min(subtr(:,:,100),[],'all')
%     range = max(registered(:,:,100),[],'all') - min(registered(:,:,100),[],'all')
%     range = max(dataM(:,:,100),[],'all') - min(dataM(:,:,100),[],'all')


%     UID_sub_reg = dicomuid;
    for i = 1:size(registered,3)
        [~,name] = fileparts(col.FileName(i));
        metadata = col.Info{i};
        metadata.SeriesDescription = ['NOT DIAG - ' 'Sub Reg ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID_sub_reg;
        metadata.WindowWidth = 300;
        metadata.WindowCenter = 100;
        dicomwrite( subtr(:,:,i), [path_save_1 filesep char(name)] , metadata);
    end


%     path_save_1 = [path_save filesep 'sub_orig_dyn_'  num2str(dyn)];
    path_save_1 = [path_save filesep 'sub_orig_dyn'];
    mkdir(path_save_1)

%     subtr = int16(registered) - int16(dataR);
    subtr = int16(dataM) - int16(dataR);

%     UID_sub_orig = dicomuid;
    for i = 1:size(dataM,3)
        [~,name] = fileparts(col.FileName(i));
        metadata = col.Info{i};
        metadata.SeriesDescription = ['NOT DIAG - ' 'Sub Orig ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID_sub_orig;
        metadata.WindowWidth = 300;
        metadata.WindowCenter = 100;
        dicomwrite( subtr(:,:,i), [path_save_1 filesep char(name)] , metadata);
    end


    %% saving Orig dicom
        
%     col = collection(collection.Dyn==dyn,:);
%     path_save_1 = [path_save filesep 'orig_dyn_'  num2str(dyn)];
%     mkdir(path_save_1)
    path_save_1 = [path_save filesep 'orig_dyn'];

%     UID = dicomuid;
    for i = 1:size(dataM,3)
        [~,name] = fileparts(col.FileName(i));
        metadata = col.Info{i};
        metadata.SeriesDescription = [ 'NOT DIAG - ' 'Orig ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID_orig;
        metadata.WindowWidth = 600;
        metadata.WindowCenter = 300;
        dicomwrite( dataM(:,:,i), [path_save_1 filesep char(name)] , metadata);
    end

end

end
