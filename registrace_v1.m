%% registrace MRI prs
clear all
close all
clc

% for clinic data
path_data = 'D:\pro_mr_prsa\Export\DICOM\S44540\';
D = dir([path_data '\S*']);

% % for public data
% path_data = 'D:\pro_mr_prsa\Public_test\Breast_MRI_001\Pat001\';
% D = dir([path_data '*ax*']);


reg_ind = cellfun(@(x) contains(x,'_reg'), {D.name});
D = D(~reg_ind);

rD = D(2);
% rD = D(3);

%%

for i = [3,4,5,6,1]
% for i = [4,5,1,2]

    try
        rmdir([pwd '\TempFile\'],'s');
    end
    tempFile = [pwd '\TempFile\'];
    mkdir(tempFile);

    mD = D(i);
    
    % [dataR,InfoR]=load_dicom([ rD.folder filesep rD.name filesep ]);
    % [dataM,InfoM]=load_dicom([ mD.folder filesep mD.name filesep ]);
    
    [dataR,InfoR]=dicomreadVolume([ rD.folder filesep rD.name filesep ]);
    [dataM,InfoM]=dicomreadVolume([ mD.folder filesep mD.name filesep ]);
    
    dataR = squeeze(dataR);
    dataM = squeeze(dataM);
    
    % dataR = uint16(mat2gray(dataR).*(2^16));
    % dataM = uint16(mat2gray(dataM).*(2^16));
    
    % dataR = uint8(mat2gray(dataR).*255);
    % dataM = uint8(mat2gray(dataM).*255);
    
    % maskR = ones(size(dataR), class(dataR)).*255;
    % maskM = ones(size(dataM), class(dataM)).*255;
    
    %%
    
    PF_name = ['parametric_file\' 'BSpline_custom.txt' ];
    
    mat2raw_3D(dataR,tempFile,'imgA',[InfoR.PixelSpacings(1,:), InfoR.PatientPositions(2,3)-InfoR.PatientPositions(1,3)] )
    mat2raw_3D(dataM,tempFile,'imgB',[InfoM.PixelSpacings(1,:), InfoM.PatientPositions(2,3)-InfoM.PatientPositions(1,3)] )
    
    % mat2raw_3D(maskR,tempFile,'maskA',InfoR)
    % mat2raw_3D(maskM,tempFile,'maskB',InfoM)
    
    
    % CMD = ['elastix\elastix.exe -f ' [tempFile 'imgA.mhd']  ' -m ' [tempFile 'imgB.mhd'] ' -out ' [tempFile ] ' -p ' [PF_name] ' -fMask ' [tempFile 'maskA.mhd'] ' -mMask ' [tempFile 'maskB.mhd']];
    CMD = ['elastix\elastix.exe -f ' [tempFile 'imgA.mhd']  ' -m ' [tempFile 'imgB.mhd'] ' -out ' [tempFile ] ' -p ' [PF_name] ];
    system(CMD)
    
    
    %%
    
    [registered, ~] = load_raw_reg([tempFile,'result.0.mhd']);
    
    % registered = uint16(registered);
    registered(registered>(64000))=0;
    % registered(registered>(250))=0;
    % dataM(dataM>(250))=0;
    
    
    % imshow5(registered)
    
    slice = 70;
    figure
    subplot 121
    imshowpair(dataR(:,:,slice),dataM(:,:,slice))
    subplot 122
    imshowpair(dataR(:,:,slice),registered(:,:,slice))

    path_save = [mD.folder filesep];
    print([mD.folder filesep 'img_' char(mD.name) '.png'],'-dpng')
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
    
    info = dicomCollection([ mD.folder filesep mD.name filesep ]);
    
    path_save = [mD.folder filesep mD.name '_reg'];
    mkdir(path_save)

    UID = dicomuid;
    for i = 1:size(registered,3)
        [~,name] = fileparts(info.Filenames{1}(i));
        metadata = dicominfo(info.Filenames{1}(i));
        metadata.SeriesDescription = [ 'NOT FOR DIAGNOSIS - ' 'reg ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID;
        dicomwrite( registered(:,:,i), [path_save filesep char(name)] , metadata);
    end

    %% saving SUBSTRAKCE
        
    path_save = [mD.folder filesep mD.name '_sub'];
    mkdir(path_save)

    subtr = int16(registered) - int16(dataR);
%     subtr = int16(dataM) - int16(dataR);

    UID = dicomuid;
    for i = 1:size(registered,3)
        [~,name] = fileparts(info.Filenames{1}(i));
        metadata = dicominfo(info.Filenames{1}(i));
        metadata.SeriesDescription = ['NOT FOR DIAGNOSIS - ' 'sub ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID;
        dicomwrite( subtr(:,:,i), [path_save filesep char(name)] , metadata);
    end


    path_save = [mD.folder filesep mD.name '_subOrig'];
    mkdir(path_save)

%     subtr = int16(registered) - int16(dataR);
    subtr = int16(dataM) - int16(dataR);

    UID = dicomuid;
    for i = 1:size(registered,3)
        [~,name] = fileparts(info.Filenames{1}(i));
        metadata = dicominfo(info.Filenames{1}(i));
        metadata.SeriesDescription = ['NOT FOR DIAGNOSIS - ' 'sub orig ' metadata.SeriesDescription ];
        metadata.SeriesInstanceUID =  UID;
        dicomwrite( subtr(:,:,i), [path_save filesep char(name)] , metadata);
    end

end


