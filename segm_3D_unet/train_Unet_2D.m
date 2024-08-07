%% segmentation by network
clear all
close all
clc
reset(gpuDevice)

% Set paths to the image and mask folders
imageFolder = 'S:\MRI_Breast\data_train\NIfTI_Files_resaved_3';
% maskFolder = 'data\forTraining\training\binary_images';

imgds = dir([imageFolder filesep '*.nii.gz']);
maskds = imgds(contains({imgds.name}, '_mask'));
imgds = imgds(~contains({imgds.name}, '_mask'));

rng(77)
idx = randperm(numel(imgds) );
imgds = imgds(idx);
maskds = maskds(idx);

splitnum = round(numel(imgds)*0.85);
imgdsVal = imgds(splitnum:end);
maskdsVal = maskds(splitnum:end);
imgds = imgds(1:splitnum-1);
maskds = maskds(1:splitnum-1);


%% training 

% net = buildNet(inputSize, 2, [8,16,32]);
% analyzeNetwork(net)

% plot(net)

inputSize = [256, 256, 3];

net = unet(inputSize, 2, EncoderDepth=3, NumFirstEncoderFilters=16);
% net = load('trainedUNet_3_0.mat','net').net;

%% Traininig parameters

SlicesBatchSize = 16;
PatBatchSize = 2;

miniBatchSize = PatBatchSize * SlicesBatchSize;
numEpochs = 300;
numSlicesVal = 32;

initialLearnRate = 0.01;
decayLearnRate = 0.003;

numObservations = numel(imgds);
numIterationsPerEpoch = floor(numObservations./PatBatchSize);
averageGrad = [];
averageSqGrad = [];
numIterations = numEpochs * numIterationsPerEpoch;

figure
plot(initialLearnRate./(1 + decayLearnRate * [1:numIterations]))

Val_iter = round(numIterationsPerEpoch * (2));

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
    idx = randperm(numel(imgds));
    imgds = imgds(idx);
    maskds = maskds(idx);

    i = 0;
    while i < numIterationsPerEpoch && ~monitor.Stop
        i = i + 1;
        iteration = iteration + 1;

        % Determine learning rate for time-based decay learning rate schedule.
        learnRate = initialLearnRate/(1 + decayLearnRate * iteration);

        % Read mini-batch of data and convert the labels to dummy
        % variables.
        idx = (i-1)*PatBatchSize+1:i*PatBatchSize;
        
        [X, T] = utils_net_train.readSlices(imgds(idx), maskds(idx), inputSize, miniBatchSize);

        % Convert mini-batch of data to a dlarray.
        X = dlarray(single(X),"SSCB");
        T = dlarray(single(T),"SSCB");

        % If training on a GPU, then convert data to a gpuArray.
        if canUseGPU
            X = gpuArray(X);
        end

        % Evaluate the model loss and gradients using dlfeval and the
        % modelLoss function.
        [loss,gradients, GDice] = dlfeval(@utils_net_train.modelLoss,net,X,T);

        % Update the network parameters using the Adam optimizer.
        [net,averageGrad,averageSqGrad] = adamupdate(net,gradients,averageGrad,averageSqGrad,iteration,learnRate);

        % Validation every 20th iteration
        % numSlicesVal = 8;
        if mod(iteration, Val_iter) == 1
            valDice = 0; valLoss = 0;
            for idxVal = 1:numel(imgdsVal)
                [XVal, TVal] = utils_net_train.readSlicesVal(imgdsVal(idxVal), maskdsVal(idxVal), inputSize, numSlicesVal);
                XVal = dlarray(single(XVal),"SSCB");
                TVal = dlarray(single(TVal),"SSCB");
                if canUseGPU
                    XVal = gpuArray(XVal);
                end
                [vloss,~,vGDice] = dlfeval(@utils_net_train.modelLoss,net,XVal,TVal);
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
            end
        else
            % Update the training progress monitor.
            recordMetrics(monitor,iteration, ...
                TrainingLoss = loss, ...
                TrainingDice = GDice);
        end

        updateInfo(monitor,Epoch = epoch + " of " + numEpochs);
        updateInfo(monitor,LearningRate = learnRate, Iteration=iteration + " ( " + numIterationsPerEpoch + " ) ");
        monitor.Progress = 100 * iteration/numIterations;
    end
end

description = ['stejne jako v3 ale se 3 kanalama tri rezu'];
% Save the trained network
save('segm_3D_unet\trainedUNet_4_0.mat', 'net','netBest','monitor', 'description');