# MR breast co-registration and Segmentation
Automatic tool for co-registration of MR dynamic contrast enhanced MR data and breast segmetantion as preprocessing af breast lession analysis tool.

## Introduction
Data preparation for preprocessing is a prerequisite for subsequent analysis, as it enables comparative studies and helps to identify clinically significant relationships between the attributes of the extracted MR-based images and clinical outcomes or parameters.

## Description
General information about the tool steps:
* folders containing dicom files (mroe patients) are split into dynamics
* all dynamics are registered to the native scan
* breast segmentation of the native scans

Program runs under Matlab license (2024a) or matlab RunTime

## Running the Program - one of three possibilities
* install CoRegBreastMRI_web.exe to your PC as program 
    * internet connection
    * no additional requirements needed
* run the file CoRegBreastMRI.exe
    * download the fodler with the codes
    * the elastix folder must be in the current program folder
    * trained model for segmentation in the current program folder
* use of source code - script CoRegBreastMRI.m
    * you need the same as in the previous example

## Important links
* instalation Matlab 2024a or RunTime ( [downlowd here](https://www.mathworks.com/products/compiler/matlab-runtime.html))
* Elastix ( [dowload here](https://elastix.dev/download.php) )
* trained model ( [download here](https://drive.google.com/file/d/1cU1XA0Zj4nbSxnJg43WyU3u7xs6G05Eq/view?usp=drive_link) )

## Data preprocessing
All data needs to be **dicom** files and needs to be in an single folder (all dynamics, data export by ISP)

## Licence
The tool is possible to use for academic and reseach purposes. 
The proposed approach was submitted to the BVM 2025 Germany conference.