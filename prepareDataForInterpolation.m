function [changedArray, missingValues] = prepareDataForInterpolation(originalArray)
%function changedArray = prepareDataForInterpolation(originalArray,orderedPackets)

%This function is going to take an input array and return the data ready
%for interpolation with the missing values exactly in the place that it
%should be.

%V1.0 Creation of the document by David López Pérez 23.04.2020
%V1.1 Performance improvement and number of missing samples now is returned 
%by the algorithm by David López Pérez 09.09.2020
%V1,2 Now the function allows to send an empty array. In this case the
%data wont be process and an empty array will be returned  by David Lopez
%Perez 10.08.2021
%JD zeroed counter 12 July

%Validation of the input parameters
if nargin <1
    error('The array and the packet numbers have not been provided');
end

%JD check if counter was zeroed in any moments
shiftedArray = circshift(squeeze(originalArray(:,1)),1); %JD shift one element to the left
if any(originalArray(2:end,1)-(shiftedArray(2:end))<0)
    idx = find(originalArray(2:end,1)-(shiftedArray(2:end))<0)+1;
    originalArray(idx:end,1)= originalArray(idx:end,1) + originalArray(idx-1,1)+1;
end

if ~isempty(originalArray)
    %Prepare the data for interpolation
    missingValues  = 0;
    changedArray(1,:) = originalArray(1,:);

    %Calculate the differences in the packages
    diffArray = diff(originalArray(:,1));
    for i = 1:size(diffArray,1)
        %Copy the value of that position
        if diffArray(i,1) == 1
            changedArray(end+1,:) = originalArray(i+1,:);
        elseif diffArray(i,1) < 1
            %We need to acount for a possible change in the numeration of the
            %packages
            if (abs(diffArray(i,1)) - 65535) == 0
                changedArray(end+1,:) = originalArray(i+1,:);
            else
                missingValues = missingValues + 65535 - abs(diffArray(i,1));
                changedArray(end+1:end+65535 - abs(diffArray(i,1)),:) = NaN;
                changedArray(end+1,:) = originalArray(i+1,:);
            end
        else
            %Adjust for the missing values and copy the value at that position
            changedArray(end+1:end+diffArray(i,1)-1,:) = NaN;
            missingValues = diffArray(i,1) -1 + missingValues;
            changedArray(end+1,:) = originalArray(i+1,:);
        end
    end

    %Fill the interpolation codes to remove NaNs
    changedArray(:,1) = fillmissing(changedArray(:,1),'linear');
else
    changedArray = [];
    missingValues = NaN;
end