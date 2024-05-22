%% breasst segmentation

function [s, mask1,maskA] = segmentation_breast(dataR,pixelSize)

level = graythresh(dataR/max(dataR(:))) * max(dataR(:));
maskA =  uint8(dataR>(level));

maskA = imclose(logical(maskA),strel("cube",1));


% poz2 = find( sum( squeeze(maskA(:, round(size(maskA,2)/2), 3*round(size(maskA,3)/4):end )) ,2)>1,1,"first" );
poz2 = find( sum( squeeze(maskA(:, round(size(maskA,2)/2), 2*round(size(maskA,3)/4):end )) ,2)>0,1,"first" );

mask1 = maskA;
mask1(poz2,:,:) = true;
mask1(poz2+1:end,:,:) = false;

mask1 = imdilate(mask1, strel("cube",3));
mask1 = imfill(mask1,4,"holes");
mask1 = permute(imfill(permute(mask1,[1,3,2]),4,"holes"),[1,3,2]);
mask1 = permute(imfill(permute(mask1,[3,2,1]),4,"holes"),[3,2,1]);
mask1 = imerode(mask1, strel("cube",3));

mask1(poz2,:,:) = false;

s=[];
s(1) = sum(mask1(:,1:round(size(mask1,2)/2),:),'all') .* prod(pixelSize) / (10^3);
s(2) = sum(mask1(:,round(size(mask1,2)/2)+1:end,:),'all') .* prod(pixelSize) / (10^3);


%% local

mask1 = maskA;
maskP = logical(zeros(size(mask1)));

for i = 1:size(maskA,3)
    poz3 = find( squeeze(maskA(:, round(size(maskA,2)/2), i) ) >0,1,"first" );   
    maskP(poz3,:,i) = true;
    mask1(poz3+1:end,:,i) = false;
end

mask1(logical(maskP)) = true;

mask1 = imdilate(mask1, strel("cube",3));
mask1 = imfill(mask1,4,"holes");
mask1 = permute(imfill(permute(mask1,[1,3,2]),4,"holes"),[1,3,2]);
mask1 = permute(imfill(permute(mask1,[3,2,1]),4,"holes"),[3,2,1]);
mask1 = imerode(mask1, strel("cube",3));

mask1(maskP) = false;


%% visualization
figure
imshowpair( squeeze(dataR(:,:,round(size(dataR,3)/2))) , squeeze(mask1(:,:,round(size(mask1,3)/2),:,:)) )
     

   


