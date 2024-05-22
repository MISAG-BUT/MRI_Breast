%% import unet
clear all
close all
clc

modelfile = 'test.pt';

net = importNetworkFromPyTorch(modelfile)

