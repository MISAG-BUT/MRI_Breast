%% export vysl;edku - poster
clear all
close all
clc


% path = 'D:\pro_mr_prsa\Export\DICOM\S41610\Results';
path = 'D:\pro_mr_prsa\Export\DICOM\S44540\Results_1';

path_save = 'S:\registrace_MRI_prs\Exported_images_1';

% i = 1;
% col = dicomCollection(fullfile(path, ['orig_dyn_' num2str(i) ] ));
% data = dicomreadVolume(col(1,14));
% imshow5(data)

%%
k=1;
img7=[];
for i = 1:6
    col = dicomCollection(fullfile(path, ['orig_dyn_' num2str(i) ] ));
    data = dicomreadVolume(col(1,14));
%     img7(:,:,k) = data(:,:,:,91);
    img7(:,:,:,k) = squeeze(data);
    k=k+1;
end

for i = 1:6
    col = dicomCollection(fullfile(path, ['reg_dyn_' num2str(i) ] ));
    data = dicomreadVolume(col(1,14));
%     img7(:,:,k) = data(:,:,:,91);
    img7(:,:,:,k) = squeeze(data);
    k=k+1;
end

%%
% img = mat2gray(img7);
% img = imadjustn(img,[0,0.35]);

% figure
% montage(img,'Size',[2,3])

%%
img = img7(60:180,100:215,103,:);    % for axial 
% img = imrotate3(img7,270,[0,0,1]);
% img = img7(60:220,20:200,:);    % for sagital 

img = squeeze(img);
img = mat2gray(img);
img = imadjustn(img,[0.1,0.5]);

figure
montage(img,'Size',[2,6])

figure
imshow(img(:,:,1))

%% gif - subtr

img3 = img(:,:,1:6);
img3 = permute(img3,[1,2,4,3]);
save_gif(img3, 'DataAX_before', path_save, 3)


img3 = img(:,:,7:12);
img3 = permute(img3,[1,2,4,3]);
save_gif(img3, 'DataAX_after', path_save, 3)


%%

k=1;
img1=[];
for i = 2:6
    col = dicomCollection(fullfile(path, ['sub_orig_dyn_' num2str(i) ] ));
    data = dicomreadVolume(col(1,14));
%     img7(:,:,k) = data(:,:,:,91);
    img1(:,:,:,k) = squeeze(data);
    k=k+1;
end

for i = 2:6
    col = dicomCollection(fullfile(path, ['sub_reg_dyn_' num2str(i) ] ));
    data = dicomreadVolume(col(1,14));
%     img7(:,:,k) = data(:,:,:,91);
    img1(:,:,:,k) = squeeze(data);
    k=k+1;
end

%% Axial
% img = img1(60:180,100:215,103,:);    % for axial - jedno prso
img = img1(60:200,100:355,103,:);    % for axial  - dve prsa

img = squeeze(img);
img = mat2gray(img);
img = imadjustn(img,[0.1,0.6]);

figure
montage(img,'Size',[2,5])

figure
imshow(img(:,:,1))

%% gif - subtr AX

img3 = img(:,:,1:5);
img3 = permute(img3,[1,2,4,3]);
save_gif(img3, 'SubtrAX_before', path_save, 2)

img3 = img(:,:,6:10);
img3 = permute(img3,[1,2,4,3]);
save_gif(img3, 'SubtrAX_after', path_save, 2)


%% SAgital

img = squeeze(img1(:,137,:,:));    % for axial 
img = imrotate3(img,90,[0,0,1]);
img = img(1:180,60:210,:);    % for sagital 

img = squeeze(img);
img = mat2gray(img);
img = imadjustn(img,[0.1,0.6]);

figure
montage(img,'Size',[2,5])

figure
imshow(img(:,:,1))

%% gif - subtr

img3 = img(:,:,1:5);
img3 = permute(img3,[1,2,4,3]);
save_gif(img3, 'SubtrSAG_before', path_save, 2)


img3 = img(:,:,6:10);
img3 = permute(img3,[1,2,4,3]);
save_gif(img3, 'SubtrSAG_after', path_save, 2)


%%
for i = 1:size(img,3)
    figure
    imshow(img(:,:,i),[0,600])
end

%%

