% Written by Mahmoud Afifi -- mafifi@eecs.yorku.ca | m.3afifi@gmail.com
% MIT License
% Requires Matlab 2019b or higher
function net = build2DUNet(imageSize,numClasses,depths)


input = imageInputLayer(imageSize,'Name','InputLayer',...
    'Normalization','zerocenter');
% depths = [8, 16, 32]; %conv depth for each block

%stream-1st
layers = [input
    split_1st];
for i = 1 : length(depths)
    if i == 1
        layers = [layers
            addBlock(depths(i), i, sprintf('Block_%d_1st',i),3); % 3 color channels
            ];
    else
        layers = [layers
            addBlock(depths(i), i, sprintf('Block_%d_1st',i));
            ];
    end
end

% cat convs
numInputs = 2;
cat_dim = 3; %third dimension
cat_Layer = concatenationLayer(cat_dim,numInputs,'Name','Cat-Layer');


Btl_block = [convolution2dLayer(1,depths(end)*2,'Stride',1,'Padding','same','Name',sprintf('%s_Conv_%d','Btl',1))
             reluLayer('Name',sprintf('%s_ReLU_%d','Btl',1))
             convolution2dLayer(1,depths(end),'Stride',1,'Padding','same','Name',sprintf('%s_Conv_%d','Btl',2))
             reluLayer('Name',sprintf('%s_ReLU_%d','Btl',2))
             % dropoutLayer('Name','dropOut-Btl-1')
             convolution2dLayer(1,depths(end)*2,'Stride',1,'Padding','same','Name',sprintf('%s_Conv_%d','Btl',3))
             reluLayer('Name',sprintf('%s_ReLU_%d','Btl',3))
             concatenationLayer(3,2,'Name','Btl-Cat-Layer')
        ];

layers = [layers
    cat_Layer
    Btl_block
    ];


% fc1 = fullyConnectedLayer(1024,'Name', 'FC-1');
% relu1 = reluLayer('Name','ReLu-FC-1');

depths = depths*2;

for i = 1 : length(depths)-1
        layers = [layers
            addBlockDeconv(depths(end-i), i, sprintf('Block_%d_Decodec',i), depths(end-i+1)*2);
            concatenationLayer(3,2,'Name', sprintf('Cat_%d_Decodec',i))
            ];
end

layers = [layers
            addBlockDeconv(depths(1), i, sprintf('Block_%d_Decodec',length(depths)), depths(1)*2)
            concatenationLayer(3,2,'Name', sprintf('Cat_%d_Decodec',i+1))
            convolution2dLayer(3, depths(1),'Stride',1,'Padding',1,'Name', sprintf('Final_conv1_1x1'),'NumChannels',depths(1)+depths(1)/2)
            convolution2dLayer(1, numClasses,'Stride',1,'Padding',0,'Name', sprintf('Final_conv2_1x1'),'NumChannels',depths(1) )
            softmaxLayer('Name','Softmaxx')
            ];

net = dlnetwork;
net = addLayers(net,layers);
net = addLayers(net,layers_2nd);
net = connectLayers(net,'InputLayer','Splitting-2nd');
net = connectLayers(net,sprintf('Block_%d_2nd_Pooling_%d',...
    length(depths),length(depths)),'Cat-Layer/in2');
net = connectLayers(net,'Btl_Conv_1','Btl-Cat-Layer/in2');

for i = 1 : length(depths)
    net = connectLayers(net,sprintf('Block_%d_1st_ReLU_%d',length(depths)-i+1,length(depths)-i+1),sprintf('Cat_%d_Decodec/in2',i));
end

end

function block = addBlock(depth, number, prefix, channels)
        if number > 1
            conv = convolution2dLayer(3,depth,'Stride',1,'Padding',1,'Name',...
                sprintf('%s_Conv_%d',prefix,number));
        else
            conv = convolution2dLayer(3,depth,'Stride',1,'Padding',1,'Name',...
                sprintf('%s_Conv_%d',prefix,number),'NumChannels',channels);
        end
    relu = reluLayer('Name',sprintf('%s_ReLU_%d',prefix,number));
    pool = maxPooling2dLayer(2,'Stride',2,'Padding',0, 'Name',...
        sprintf('%s_Pooling_%d',prefix,number));
    block = [conv
        relu
        pool
        ];
end

function block = addBlockDeconv(depth, number, prefix, channels)
    conv = convolution2dLayer(3,depth,'Stride',1,'Padding',1,'Name',...
        sprintf('%s_Conv_%d',prefix,number),'NumChannels',channels);
    relu = reluLayer('Name',sprintf('%s_ReLU_%d',prefix,number));
    trans = transposedConv2dLayer(2,depth,"Stride",2,'Name',...
            sprintf('%s_TransvConv_%d',prefix,number));
    block = [conv
        relu
        trans
        ];
end