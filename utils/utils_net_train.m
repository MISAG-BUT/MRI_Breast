%% my functions

classdef utils_net_train
    methods (Static)

    function [loss, lossBatch] = DiceLoss( Y, targets)    
        TP = targets .* Y;
        TP = TP.sum([1,2]);
        FP = (1-targets) .* Y;
        FP = FP.sum([1,2]);
        FN = targets .* (1-Y);
        FN = FN.sum([1,2]);
        loss = (  (2.*(TP) + eps) ./ (2*(TP) + FP + FN + eps) );
        lossBatch = 1 - loss;
        loss = 1 - loss.mean("all");
        % loss = 1 - (  (2*(TP)) / (2*(TP) + FP + FN) );
    end


    function [loss] = BinEntropLoss( Y, targets) 
        w1 = targets(:,:,1,:).mean([1,2]);
        w2 = 1-w1;
        loss = -sum(  w1.*targets(:,:,1,:).*log(Y(:,:,1,:)) + w2.*(1-targets).*log(1-Y) ,'all');
    end

    function [loss] = generalizedDiceLoss( Y, targets) 
        targets(isnan(targets)) = 0;
        Y(isnan(Y)) = 0;
        GD = generalizedDice(Y, targets);
        % GD = dice(targets, Y);
        loss = 1 - GD.mean('all');
    end
    
    function [loss,gradients,Acc] = modelLoss(net,X,T)
        % % Forward data through network.
        [Y] = forward(net,X);
        % % Calculate cross-entropy loss.
        loss = utils_net_train.generalizedDiceLoss(Y,T);
        Y = Y(:,:,2:end,:);
        T = T(:,:,2:end,:);
        [acc,~] = utils_net_train.DiceLoss(single(Y>0.5),T);
        Acc = 1 - acc;
        % if Acc==0
        %     Acc
        % end
        % Calculate gradients of loss with respect to learnable parameters.
        gradients = dlgradient(loss,net.Learnables);
    end

    function [loss, gradients, acc, acc_batch] = modelLossDM(net,X,T)
        % % Forward data through network.
        [Y] = forward(net,X);
        % % Calculate cross-entropy loss.
        loss = utils_net_train.generalizedDiceLoss(Y,T);
        Y = Y(:,:,2:end,:);
        T = T(:,:,2:end,:);
        [acc, acc_batch] = utils_net_train.DiceLoss(single(Y>0.5),T);
        % Acc = 1 - acc;
        acc_batch = 1 - acc_batch;

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
    
    function [img, mask] = augment_transf(img, mask, state)
        if state(1) > 0.5
            img = flip(img, 2);
            mask = flip(mask, 2);
        end
        if state(2) < 0.8
            % img = uint16( ((single(img)/500).^(state(3)*0.1+1))*500);
            img = uint16( ((single(img)/500).^(state(3)*0.2+1))*500);
        end
    end
    
    function [imgs, masks] = readSlices(imgds, masksds, inputSize, bathSize)
        imgs = zeros([inputSize(1:3),bathSize]);
        masks = zeros([inputSize(1:2),1,bathSize]);
        k = 1;
        for i = 1:length(imgds)
            medVolData = medicalVolume([imgds(i).folder filesep imgds(i).name]);
            medVolMask = medicalVolume([masksds(i).folder filesep masksds(i).name]);
            num_slices = bathSize/length(imgds);
            idx = randi([3,medVolData.NumTransverseSlices-2],num_slices,1);
            for sl = 1 : num_slices
                transl = [-2,0,2];
                rect = utils_net_train.genRect(medVolData.VolumeGeometry.VolumeSize([1,2]),inputSize);
                state = [rand(1,2),randn(1)];
                for ii = 1:3
                    slice = idx(sl) + transl(ii);
                    img = extractSlice(medVolData,slice,"transverse");
                    img = rot90(img,1);
                    p = single(prctile(img(img>0),95,"all"));
                    img = uint16((double(img)/p)*500);
                    mask = extractSlice(medVolMask,slice,"transverse");
                    mask = rot90(mask,1);
                    [img, mask] = utils_net_train.augment_transf(img, mask, state);
                    imgs(:,:,ii,k) = imcrop(img,rect);
                    if ii==2
                        masks(:,:,1,k) = imcrop(mask,rect);
                    end
                end
                k = k+1;
            end
            % delete medVolData
            % delete medVolMask
        end

    end

    function [imgs, masks] = readSlicesDM(imgds, masksds, slices, inputSize)

        imgs = zeros([inputSize(1:3),length(slices)]);
        masks = zeros([inputSize(1:2),1,length(slices)]);
        k = 1;
        while ~isempty(slices)
            medVolData = medicalVolume([imgds(slices(1,1)).folder filesep imgds(slices(1,1)).name]);
            medVolMask = medicalVolume([masksds(slices(1,1)).folder filesep masksds(slices(1,1)).name]);
            % num_slices = bathSize/length(imgds);
            % idx = randi([3,medVolData.NumTransverseSlices-2],num_slices,1);
            idx = slices(slices(:,1)==slices(1,1),2);
            num_slices = length(idx);
            slices(slices(:,1)==slices(1,1),:) = [];

            for sl = 1 : num_slices
                transl = [-2,0,2];
                rect = utils_net_train.genRect(medVolData.VolumeGeometry.VolumeSize([1,2]),inputSize);
                state = [rand(1,2),randn(1)];
                for ii = 1:3
                    slice = idx(sl) + transl(ii);
                    img = extractSlice(medVolData,slice,"transverse");
                    img = rot90(img,1);
                    p = single(prctile(img(img>0),95,"all"));
                    img = uint16((double(img)/p)*500);
                    mask = extractSlice(medVolMask,slice,"transverse");
                    mask = rot90(mask,1);
                    [img, mask] = utils_net_train.augment_transf(img, mask, state);
                    imgs(:,:,ii,k) = imcrop(img,rect);
                    if ii==2
                        masks(:,:,1,k) = imcrop(mask,rect);
                    end
                end
                k = k+1;
            end
            % delete medVolData
            % delete medVolMask
        end

    end
    
    function [imgs, masks] = readSlicesVal(imgds, maskds, inputSize, bathSize)
        medVoldata = medicalVolume([imgds(1).folder filesep imgds(1).name]);
        medVolMask = medicalVolume([maskds(1).folder filesep maskds(1).name]);
        k = 1;
        idx = randi([3,medVoldata.NumTransverseSlices-2],bathSize,1);

        imgs = zeros([inputSize(1:3),bathSize]);
        masks = zeros([inputSize(1:2),1,bathSize]);
        rect = utils_net_train.genRect(medVoldata.VolumeGeometry.VolumeSize([1,2]),inputSize);

        for sl = 1:size(idx,1)
            transl = [-2,0,2];
            for ii = 1:3
                slice = idx(sl) + transl(ii);
                img = extractSlice(medVoldata,slice,"transverse");
                img = rot90(img,1);
                p = single(prctile(img(img>0),95,"all"));
                img = uint16((double(img)/p)*500);
                mask = extractSlice(medVolMask,slice,"transverse");
                mask = rot90(mask,1);
                imgs(:,:,ii,k) = imcrop(img,rect);
                if ii==2
                    masks(:,:,1,k) = imcrop(mask,rect);
                end
            end
            k = k+1;
        end
        % delete medVolData
        % delete medVolMask
    end
    
    function [mask] = seg_image(data, inputSize)
        mask = zeros(size(data));
        for slice = 1:size(data,3)
            img = data(:,:,slice);    
            [rects] = utils_net_train.split_image(img, inputSize, 0.85);    
            mask_pred = zeros([size(img,1),size(img,2)]);
            rect_mask = zeros(size(img,1),size(img,2));
            for i = 1:size(rects,1)
                rect = rects(i,:);
                X = zeros([inputSize([1,2]),1,1]);
                X(:,:,1,1) = imcrop(img,rect);
                p = single(prctile(X(X>0),95,"all"));
                X = uint16((double(X)/p)*500);
                X = dlarray(single(X),"SSCB");
                if canUseGPU
                    X = gpuArray(X);
                end
                [pred] = predict(net,X);
                pred = extractdata(pred);
                mask_pred(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) = mask_pred(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) + pred(:,:,1,1);
                rect_mask(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) = rect_mask(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) + 1;
            end
            mask(:,:,slice) = mask_pred ./ rect_mask;
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

    function fcn = rand_norm_distrb(N, mu, std, n_range)
        pd = makedist('Normal', 'mu', mu, 'sigma', std);
        rmin = cdf(pd, n_range(1));
        rmax = cdf(pd, n_range(2));
        rUnif = (rmax - rmin) * rand(N, 1) + rmin;
        fcn = icdf(pd, rUnif);
    end

    end
end