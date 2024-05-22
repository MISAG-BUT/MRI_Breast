%% DeepSeA
clear all
close all
clc

MR_startup

%%

path_dcm = 'C:\Data\MRI_prsa\test\Breast_MRI_001\01-01-1990-NA-MRI BREAST BILATERAL WWO-97538\3.000000-ax dyn pre-93877\';
path_resave = 'C:\Data\MRI_prsa\test\Breast_MRI_001\01-01-1990-NA-MRI BREAST BILATERAL WWO-97538\3.000000-ax dyn pre-93877_sub\';
mkdir(path_resave)

D = dir([path_dcm '**\*.dcm']);

for i = 1:length(D)
    img = dicomread( fullfile( D(i).folder , D(i).name ) );
    info = dicominfo( fullfile( D(i).folder , D(i).name ) );
    img = medfilt2(img);
    img = imgaussfilt(img,1);
    img = imresize(img, 0.5);
    info.PixelSpacing(1:2) = info.PixelSpacing(1:2)*2;
    dicomwrite(img,[path_resave '\' D(i).name], info)
end

%%

segdata = wholeBreastSegment(path_resave, 'Results\', 'LateralBounds', true);

% segdata = wholeBreastSegment('DeepSeA-master\demoData\AX_T1_BILAT\', 'Results\', 'LateralBounds', true);


