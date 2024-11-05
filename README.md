# MR breast co-registration and Segmentation
Automatic tool for co-registration of MR dynamic contrast enhanced MR data and breast segmetantion as preprocessing af breast lession analysis tool.

## Introduction
Data preparation for preprocessing is a prerequisite for subsequent analysis, as it enables comparative studies and helps to identify clinically significant relationships between the attributes of the extracted MR-based images and clinical outcomes or parameters.

## Description
General information about this tool:
* folder contating dicom files are divide to dynamics (as export from ISP)
* all dynamics are registered to native scan
* breast segmentation in native scan
* It runs under Matlab licence (2024a) or matlab RunTime

## Requirements
* instalation Matlab 2024a or RunTime ( [downlowd here](https://www.mathworks.com/products/compiler/matlab-runtime.html))
* Elastix ( [dowload here](https://elastix.dev/download.php) )
* trained model ( [download here](https://drive.google.com/file/d/1cU1XA0Zj4nbSxnJg43WyU3u7xs6G05Eq/view?usp=drive_link) )

## Prerequisities and Running the Program 
* elastix folder in current folder with program
* trained model for segmentation
* modify and use script CoRegBreastMRI.m
* or run CoRegBreastMRI.exe file

## Data preprocessing
All data needs to be **dicom** files and needs to be in an single folder (all dynamics)

## Licence
The tool is possible to use for academic and reseach purposes. 
The pipeline has been submited to BVM 2025 Germany.