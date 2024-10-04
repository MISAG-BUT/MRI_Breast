function mask = refinement_mask(mask)    

slice = find(max(mask(:,round(size(mask,2)/2),:),[],3),1,"first")-2;

SE = create_sphere(2);
SE = SE(:,:,3);
mask = imclose(mask, SE);
mask = imfill(mask,8,"holes");

% mask = imerode(mask,SE);
% CC = bwconncomp(mask);
% numPixels = cellfun(@numel, CC.PixelIdxList);
% [~, idx] = max(numPixels);
% mask2 = false(size(mask));
% mask2(CC.PixelIdxList{idx}) = true;
% mask = imdilate(mask2,SE);

mask = permute(mask,[3,2,1]);
mask = imclose(mask, SE);
mask(:,:,1:slice) = imfill(mask(:,:,1:slice),8,"holes");
mask = permute(mask,[3,2,1]);

mask = permute(mask,[1,3,2]);
mask = imclose(mask, SE);
mask = imfill(mask,8,"holes");
mask = permute(mask,[1,3,2]);