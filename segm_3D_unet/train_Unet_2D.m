%% segmentation by network
clear all
close all
clc
reset(gpuDevice)

%% datat public
% Set paths to the image and mask folders
imageFolder = 'S:\MRI_Breast\data_train\NIfTI_Files_resaved_3';
% maskFolder = 'data\forTraining\training\binary_images';

imgds = dir([imageFolder filesep '*.nii.gz']);
maskds = imgds(contains({imgds.name}, '_mask.'));
imgds = imgds(~contains({imgds.name}, '_mask.'));

rng(77)
idx = randperm(numel(imgds) );
imgds = imgds(idx);
maskds = maskds(idx);

imgds = imgds(1:10);
maskds = maskds(1:10);

splitnum = round(numel(imgds)*0.88);
imgdsVal = imgds(splitnum:end);
maskdsVal = maskds(splitnum:end);
imgds = imgds(1:splitnum-1);
maskds = maskds(1:splitnum-1);



%% datat FNUSA I
% Set paths to the image and mask folders
% imageFolder = 'S:\MRI_Breast\data_train\NIfTI_Files_resaved_4';
imageFolder = 'S:\MRI_Breast\data_train\NIfTI_Files_resaved_6';  % instance segmentation

imgds2 = dir([imageFolder filesep '*orig.nii.gz']);
maskds2 = dir([imageFolder filesep '*labels.nii.gz']);

% rng(10)
% idx = randperm(numel(imgds2) );
% imgds2 = imgds2(idx);
% maskds2 = maskds2(idx);

%% datat FNUSA II
% Set paths to the image and mask folders
% imageFolder = 'S:\MRI_Breast\data_train\NIfTI_Files_resaved_5';
imageFolder = 'S:\MRI_Breast\data_train\NIfTI_Files_resaved_7';     % instance segmentation

imgds3 = dir([imageFolder filesep '*orig.nii.gz']);
maskds3 = dir([imageFolder filesep '*labels.nii.gz']);

% imgds3 = imgds3([1:11,13,14,15]);

% join FNUSA i a FNUSA II
imgds2 = [imgds2; imgds3];
maskds2 = [maskds2; maskds3];


%% shufle
rng(777)
idx = randperm(numel(imgds2) );
imgds2 = imgds2(idx);
maskds2 = maskds2(idx);

%%
splitnum = round(numel(imgds2)*0.88);

imgdsVal = [imgdsVal; imgds2(splitnum:end)];
maskdsVal = [maskdsVal; maskds2(splitnum:end)];
% 
% imgds = [imgds; imgds2(1:splitnum-1)];
% maskds = [maskds; maskds2(1:splitnum-1)];

imgds = [ imgds2(1:splitnum-1)];
maskds = [ maskds2(1:splitnum-1)];

% imgds = [imgds; imgds2];
% maskds = [maskds; maskds2];

% imgds = [imgds2];
% maskds = [maskds2];

% idxImplants = [3,11,17,20,22,23,28];% implants
% idxImplants = [idxImplants, 1, 2, 34,35,15,16,18,25];
% imgds = imgds(idxImplants);
% maskds = maskds(idxImplants);

IDX = [];
poz = 1;
for i = 1:length(imgds)
    medVolData = medicalVolume([imgds(i).folder filesep imgds(i).name]);
    num_slice = medVolData.NumTransverseSlices - 4;
    IDX(poz:poz+num_slice-1,1) = i;
    IDX(poz:poz+num_slice-1,2) = [3:medVolData.NumTransverseSlices-2];
    poz = poz+num_slice;
end
IDX(1:end,4) = [1:size(IDX,1)];

IDX(1:end,3) = 1;
for i = [3,11,17,20,22,23,28]
    IDX(IDX(:,1)==i,3) = 0;
end

% IDX = load('trainedUNet_6_8.mat','IDX').IDX;


%% training 

% net = buildNet(inputSize, 2, [8,16,32]);
% analyzeNetwork(net)

% plot(net)

name_version = 'trainedUNet_7_0';

description = ['instanci segm, all FNUSA data, dataMining batch KCL, maskovani rezu s GT maskou breast'];
% description = ['dalsi douceni, vic data bez implants, input (4 channels) i s maskou breast - maska GT, segmentace jen implantatu'];
% description = ['from scratch instancni ucene jen na pac s implants = bez implants z train odstranena, instancni segm bez input masky prsu'];

% inputSize = [256, 256, 4];
inputSize = [256, 256, 3];

% net = unet(inputSize, 2, EncoderDepth=3, NumFirstEncoderFilters=16);
net = unet(inputSize, 3, EncoderDepth=3, NumFirstEncoderFilters=16);

% net = load('trainedUNet_6_8.mat','net').net;

%% Traininig parameters

% SlicesBatchSize = 16;
% PatBatchSize = 2;
% miniBatchSize = PatBatchSize * SlicesBatchSize;

miniBatchSize = 32;
sigma = 0.2;

numEpochs = 300;
numSlicesVal = 32;

initialLearnRate = 0.001;
num_cyclic = 3;
decreasing = 50;

% decayLearnRate = 0.0005;
% num_step = 5 ;
% decreasingLR = 100;

numObservations = numel(imgds);
% numIterationsPerEpoch = floor(numObservations ./ PatBatchSize);
numIterationsPerEpoch = round( 10 /100 * size(IDX,1) / miniBatchSize);    % 10% dat na jednu epochu

averageGrad = [];
averageSqGrad = [];
numIterations = numEpochs * numIterationsPerEpoch;

fct_nonlinear = 2;
learnRates = ((((linspace(1, 0.0, numIterations)).^fct_nonlinear) ./(1+1/decreasing))  + 1/decreasing ); 
C = (cos(2*pi*num_cyclic*linspace(0,1,numIterations)) +1.5 )/2.5;
% C = (cos(2*pi*num_cyclic*linspace(0,1,numIterations)) );

learnRates = initialLearnRate .* C .* learnRates;
% learnRates = C;
figure
plot(learnRates)

% figure
% plot(initialLearnRate./(1 + decayLearnRate * [1:numIterations]))

Val_iter = round(numIterationsPerEpoch * (1));

%% Train the U-Net network

monitor = trainingProgressMonitor(XLabel="Iteration");
monitor.Info = ["LearningRate","Epoch","Iteration"];
monitor.Metrics = ["TrainingLoss","ValidationLoss","TrainingDice","ValidationDice"];
groupSubPlot(monitor,"Loss",["TrainingLoss","ValidationLoss"]);
groupSubPlot(monitor,"Dice",["TrainingDice","ValidationDice"]);

net = initialize(net);

iteration = 0;
epoch = 0;
ValBest = 0;
while epoch < numEpochs && ~monitor.Stop
    epoch = epoch + 1;

    % Shuffle data.
    % idx = randperm(numel(imgds));
    % imgds = imgds(idx);
    % maskds = maskds(idx);

    mu1 = size(IDX,1) / 100;
    sigma1 = sigma * size(IDX,1);


    i = 0;
    while i < numIterationsPerEpoch && ~monitor.Stop
        i = i + 1;
        iteration = iteration + 1;

        % Determine learning rate for time-based decay learning rate schedule.
        % learnRate = initialLearnRate/(1 + decayLearnRate * iteration);
        learnRate = learnRates(iteration);

        % Read mini-batch of data 
        % idx = (i-1)*PatBatchSize+1:i*PatBatchSize;
        
        idx_Rand = round( utils_net_train.rand_norm_distrb(miniBatchSize, mu1, sigma1, [0, size(IDX,1)]));
        idx_Rand(idx_Rand<=0)=1;
        idx_Rand(idx_Rand>size(IDX,1)) = size(IDX,1);
        idx_orig = IDX(idx_Rand, 4);
        
        % [X, T] = utils_net_train.readSlices(imgds(idx), maskds(idx), inputSize, miniBatchSize);
        [X, T] = utils_net_train.readSlicesDM(imgds, maskds, IDX(idx_orig,[1:2]), inputSize);


        % onehotcoding
        Toh = T(:,:,1,:)==0;  % for both
        Toh(:,:,2,:) = T(:,:,1,:)==1;
        Toh(:,:,3,:) = T(:,:,1,:)==2;

        % Toh = T(:,:,1,:)<2;    % for implants only
        % Toh(:,:,2,:) = T(:,:,1,:)==2;
        % Toh = single(Toh);

        X(:,:,2,:) = X(:,:,2,:) .* single(T(:,:,1,:)>0);

        % Convert mini-batch of data to a dlarray.
        X = dlarray(single(X),"SSCB");
        Toh = dlarray(single(Toh),"SSCB");

        % If training on a GPU, then convert data to a gpuArray.
        if canUseGPU
            X = gpuArray(X);
        end

        % Evaluate the model loss and gradients using dlfeval and the
        % modelLoss function.
        [loss,gradients, GDice, Dice_batch] = dlfeval(@utils_net_train.modelLossDM,net,X,Toh);

        IDX(idx_Rand,3) = squeeze(extractdata(Dice_batch));
        [IDX] = sortrows(IDX,3,"ascend");

        pd = makedist('Normal', 'mu', mu1, 'sigma', sigma1);
        figure(7);
        plot(IDX(:, 3));
        x = linspace(0, size(IDX, 1), size(IDX, 1));
        y = pdf(pd, x);
        hold on;
        plot(y / max(y)); % Normalize the y values
        ylim([0.0, 1.1]);
        hold off;

        % Update the network parameters using the Adam optimizer.
        [net,averageGrad,averageSqGrad] = adamupdate(net,gradients,averageGrad,averageSqGrad,iteration,learnRate);

        % Validation every 20th iteration
        % numSlicesVal = 8;
        if mod(iteration, Val_iter) == 1

            ind100 = find(IDX(:,3)==1);
            IDX( ind100 ,:) =  IDX( ind100(randperm(length(ind100)) ) , :);

            valDice = 0; valLoss = 0;
            for idxVal = 1:numel(imgdsVal)
                [XVal, TVal] = utils_net_train.readSlicesVal(imgdsVal(idxVal), maskdsVal(idxVal), inputSize, numSlicesVal);

                % onehotcoding
                TVoh = TVal(:,:,1,:)==0;    % for breast + implants
                TVoh(:,:,2,:) = TTVal(:,:,1,:)==1; 
                TVoh(:,:,3,:) = TTVal(:,:,1,:)==2;

                % TVoh = TVal(:,:,1,:)<2;    % for implants only
                % TVoh(:,:,2,:) = TVal(:,:,1,:)==2;   
                % TVoh = single(TVoh);

                XVal(:,:,2,:) = XVal(:,:,2,:) .* single(TVal(:,:,1,:)>0);

                XVal = dlarray(single(XVal),"SSCB");
                TVoh = dlarray(single(TVoh),"SSCB");
                if canUseGPU
                    XVal = gpuArray(XVal);
                end
                [vloss,~,vGDice] = dlfeval(@utils_net_train.modelLoss,net,XVal,TVoh);
                valDice = valDice + (vGDice) /numel(imgdsVal);
                valLoss = valLoss + (vloss) /numel(imgdsVal);
            end
            recordMetrics(monitor,iteration, ...
                TrainingLoss = loss, ...
                TrainingDice = GDice, ...
                ValidationLoss = valLoss, ...
                ValidationDice = valDice)
            if valDice>ValBest
                netBest = net;
                ValBest = valDice;
                save(['segm_3D_unet\' name_version '.mat'], 'net','netBest','monitor', 'description','imgdsVal', 'imgds');
            end
        else
            % Update the training progress monitor.
            recordMetrics(monitor,iteration, ...
                TrainingLoss = loss, ...
                TrainingDice = GDice);
        end

        updateInfo(monitor,Epoch = epoch + " of " + numEpochs);
        updateInfo(monitor,LearningRate = learnRate, Iteration=iteration + " ( " + numIterationsPerEpoch + " ) / " + numIterations);
        monitor.Progress = 100 * iteration/numIterations;
    end
end

% Save the trained network
save(['segm_3D_unet\' name_version '.mat'], 'net','netBest','monitor', 'description','imgdsVal', 'imgds', 'IDX');