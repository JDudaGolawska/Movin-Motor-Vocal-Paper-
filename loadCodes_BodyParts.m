function [codes,bodyParts] =  loadCodes_BodyParts(device,pathCodeFiles)

%This snipplet is going to load the codes and bodyparts from the
%codingFile

%Input: device -> the information about the device data 

%V1.0 Creation of the document by David Lopez Perez 23.11.2020
%V1.1 This function has been rewritten to accept the path to the files
%containing the codes to convert the sensor names to body parts 10.07.2021


%Validation of the input parameters
if nargin < 1
    error('The device information has not been provided');
end

if nargin < 2
    %Convert the sensor codes
    display('Load the files with the sensor codes conversion');
    [codesFile,codesPath] = uigetfile('.txt','Multstrcat(codesPath,codesFile)iSelect','OFF');   
    codes = importdata(strcat(codesPath,codesFile),'\t');
else
    codes = importdata(pathCodeFiles,'\t');
end


%Split the cell in two columns
for iCode = 1:size(codes,1)
    positionSpace = strfind(codes{iCode,1},' ');
    bodyParts{iCode} = lower(codes{iCode,1}(1,positionSpace(1)+1:(positionSpace(2)-1)));
    clear positionSpace
end

% Order codes and bodyParts according to the loaded files 
counter = 1;
for iFile=1:size(device,2)
    for iCode = 1:size(codes,1)
        if ~isempty(strfind(codes{iCode},device{iFile}))
            bodyPartsAux{counter} = bodyParts{iCode};
            CodesAux{counter} = codes{iCode};
            counter = counter + 1;
            break;
        end
    end
end
bodyParts = bodyPartsAux;
codes = CodesAux;