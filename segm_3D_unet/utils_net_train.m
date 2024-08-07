%% my functions

classdef utils_net_train
    methods (Static)

    function [loss] = DiceLoss( Y, targets)    
        TP = targets(:,:,1,:) .* Y(:,:,1,:);
        TP = TP.sum('all');
        FP = (1-targets(:,:,1,:)) .* Y(:,:,1,:);
        FP = FP.sum('all');
        FN = targets(:,:,1,:) .* (Y(:,:,2,:));
        FN = FN.sum('all');
        loss = 1 - (  (2*(TP)) / (2*(TP) + FP + FN) );
    end

    function [loss] = BinEntropLoss( Y, targets) 
        w1 = targets(:,:,1,:).mean([1,2]);
        w2 = 1-w1;
        loss = -sum(  w1.*targets(:,:,1,:).*log(Y(:,:,1,:)) + w2.*(1-targets).*log(1-Y) ,'all');
    end

    function [loss] = generalizedDiceLoss( Y, targets) 
        targets(isnan(targets)) = 0;
        Y(isnan(Y)) = 0;
        targets(:,:,2,:) = 1-targets(:,:,1,:);
        GD = generalizedDice(targets, Y);
        loss = 1 - GD.mean('all');
    end
    
    function [loss,gradients,Acc] = modelLoss(net,X,T)
        % % Forward data through network.
        [Y] = forward(net,X);
        % % Calculate cross-entropy loss.
        % loss = utils_net_train.DiceLoss(Y,T);
        % Acc = 1 - utils_net_train.generalizedDiceLoss(Y,T);
        loss = utils_net_train.generalizedDiceLoss(Y,T);
        Acc = 1 - utils_net_train.DiceLoss(Y,T);
        % % Calculate gradients of loss with respect to learnable parameters.
        gradients = dlgradient(loss,net.Learnables);
    end
    
    function [rect] = genRect(vel,inputSize)
        ra = vel(1)-inputSize(1); ra(ra<1)=1;
        sl = vel(2)-inputSize(2); sl(sl<1)=1;
        rect = [ randi(sl,1) , randi(ra,1), inputSize([2,1])-1 ];
        % posun na spodni polovinu obrazu
        % fct = 2/3;
        %     rectY = floor( rect(2)*fct + vel(1)*fct );
        %     rectY(rectY>(vel(1)-inputSize(1))) = vel(1)-inputSize(1);
        %     rect(2) = rectY;
    end
    
    function [img, mask] = augment_transf(img, mask)
        if rand > 0.5
            img = flip(img, 2);
            mask = flip(mask, 2);
        end
        if rand < 0.8
            img = uint16( ((single(img)/500).^(randn(1)*0.05+1))*500);
        end
    end
    
    function [imgs, masks] = readSlices(imgds, masksds, inputSize, bathSize)
        imgs = zeros([inputSize(1:2),1,bathSize]);
        masks = zeros([inputSize(1:2),1,bathSize]);
        k = 1;
        for i = 1:length(imgds)
            medVolData = medicalVolume([imgds(i).folder filesep imgds(i).name]);
            medVolMask = medicalVolume([masksds(i).folder filesep masksds(i).name]);
            num_slices = bathSize/length(imgds);
            idx = randi([1,medVolData.NumTransverseSlices],num_slices,1);
            for sl = 1 : num_slices
                slice = idx(sl);
                img = extractSlice(medVolData,slice,"transverse");
                img = rot90(img,1);
                p = single(prctile(img(img>0),95,"all"));
                img = uint16((double(img)/p)*500);
                mask = extractSlice(medVolMask,slice,"transverse");
                mask = rot90(mask,1);
                [img, mask] = utils_net_train.augment_transf(img, mask);
                rect = utils_net_train.genRect(size(img),inputSize);
                imgs(:,:,1,k) = imcrop(img,rect);
                masks(:,:,1,k) = imcrop(mask,rect);
                k = k+1;
            end
            % delete medVolData
            % delete medVolMask
        end

    end
    
    function [imgs, masks] = readSlicesVal(imgds, maskds, inputSize, bathSize)
        medVoldata = medicalVolume([imgds(1).folder filesep imgds(1).name]);
        medVolMask = medicalVolume([maskds(1).folder filesep maskds(1).name]);

        idx = randi([1,medVoldata.NumTransverseSlices],bathSize,1);

        imgs = zeros([inputSize(1:2),1,bathSize]);
        masks = zeros([inputSize(1:2),1,bathSize]);
        rect = utils_net_train.genRect(medVoldata.VolumeGeometry.VolumeSize,inputSize);

        for i = 1:size(idx,1)
            slice = idx(i);
            img = extractSlice(medVoldata,slice,"transverse");
            img = rot90(img,1);
            p = single(prctile(img(img>0),95,"all"));
            img = uint16((double(img)/p)*500);

            mask = extractSlice(medVolMask,slice,"transverse");
            mask = rot90(mask,1);

            imgs(:,:,1,i) = imcrop(img,rect);
            masks(:,:,1,i) = imcrop(mask,rect);
        end
        % delete medVolData
        % delete medVolMask
    end
    
    function [masks] = seg_image(imgds, inputSize)
        img = imread([imgds(1).folder filesep imgds(1).name]);
        [rects] = split_image(img, inputSize, 0.75);
        masks = zeros([size(img,1),size(img,2)]);
        imgs = zeros(inputSize([2,1],7,1));
        for i = 1:size(rects,1)
            rect = rects(i,:);
            imgs(:,:,1:3,1) = imcrop(img,rect);
            imgs(:,:,4:6,1) = imresize(img, inputSize([1,2]));
            rect_mask = zeros(size(img,1),size(img,2));
            rect_mask(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) = 1;
            imgs(:,:,7,1) = imresize(rect_mask, inputSize(1:2));
            imgs = dlarray(single(imgs),"SSCB");
            if canUseGPU
                imgs = gpuArray(imgs);
            end
            [pred] = predict(net,XVal);
            masks(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) = pred(:,:,1,1);
        end
    end
    
    function [rects] = split_image(img, target_size, prct)
        numsIm = [ceil(size(img,1) / (target_size(1)*prct)),ceil(size(img,2) / (target_size(2)*prct)),ceil(size(img,3) / (target_size(3)*prct))];
        x = linspace(1, size(img,1)-target_size(1), numsIm(1));
        y = linspace(1, size(img,2)-target_size(2), numsIm(2));
        
        x(x<1)=[];
        y(y<1)=[];
        i=1;rects=[];
        for ra = 1:length(x)
            for sl = 1:length(y)
                rects(i,:) = round( [y(sl),x(ra),target_size([2,1])-1] );
                i = i+1;
            end
        end
    
    end
    end
end