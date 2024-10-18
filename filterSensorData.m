function [frequency, dataFiltered, missing_data] = filterSensorData(data, path_sensor, sampling_frequency)

%This function is going to load the data and return the interpolated data.

%Input: data -> input loaded data
%       path -> path for a one sensor file example

%Output: frequency -> the frequency of the sensor
%         dataFiltered -> the filtered data

%V1.0 Creation of the document by David López Pérez 23.11.2020
%V1.1 Bug Fix. The function was always try catching a code error all the
%time and therefore assuming 60Hz by David López Pérez 26.11.2020

%Validation of the input data

if nargin<1
    error('The input data has not been provided');
end

%% Start the process

disp('Filtering and Interpolating data');
try
    %Get the first file of the list, and load it
    frequencyFile = importdata(path_sensor);
    for iRow = 1:size(frequencyFile.textdata,1)
        for iColumn = 1:size(frequencyFile.textdata,2)
            if ~isempty(strfind(frequencyFile.textdata{iRow,iColumn},'Hz'))
                freqPosition = strfind(frequencyFile.textdata{iRow,iColumn},'Hz');
                frequency = str2num(frequencyFile.textdata{iRow,iColumn}(freqPosition-5:freqPosition-1));
                disp(['Frequency value of ' num2str(frequency) ' Hz found in the sensor files']);
                break;
                
            end
        end
    end
    if isempty(frequency)
        frequency = str2num(cell2mat(inputdlg('Write the sensor frequency')));
    end
catch
    warning('There was an error in the frequency value. Getting frequency from table.');
    pos_sl =  strfind(path_sensor,'/');
    filename = path_sensor(pos_sl(end-1)+1:pos_sl(end)-1);
% 	index = find(contains(sampling_frequency.name,filename));
    frequency = double(sampling_frequency(contains({sampling_frequency.name},filename)).frequency);
end


if contains(path_sensor, 'books/77040_2/')
    frequency = 80;
end
%We need to interpolate missing packages so the time series are comparable.
%Prepare the data for interpolation
% parfor iFile = 1:size(data,2)
for iFile = 1:size(data,2)
    [data{iFile},missingValues(iFile)] = prepareDataForInterpolation(data{iFile});
end

%Calculate the min and max packet number
fileLengths = cell2mat(cellfun(@length,data,'UniformOutput',false));
if ~all(fileLengths == fileLengths(1))
    %Show a warning if after preparing the data something is still wrong
    warning('The length of the time series is not the same. Padding the beginning or the end with NaNs, double check that the problem is due to files being shorter at the end or the beginning');
    minPackageNumber = 10000000000;
    maxPackageNumber = 0;
    for iData = 1:size(data,2)
        if ~isempty(data{iData})
            if data{iData}(1,1) < minPackageNumber
                minPackageNumber = data{iData}(1,1);
            end
            if data{iData}(end,1) > maxPackageNumber
                maxPackageNumber = data{iData}(end,1);
            end
        end
    end
    for iFile = 1:size(data,2)
        if ~isempty(data{iFile})
            if data{iFile}(1,1) ~= minPackageNumber
                auxBegin = nan([(data{iFile}(1,1)-minPackageNumber) size(data{iFile},2)]);
                data{iFile} = [auxBegin;data{iFile}];
            end
            if data{iFile}(end,1) ~= maxPackageNumber
                data{iFile}(end+1:end+(maxPackageNumber - data{iFile}(end,1)),:) = NaN;
            end
            data{iFile}(:,1) = fillmissing(data{iFile}(:,1),'linear');
            clear auxBegin
        end
    end
end
%Display the mean values of missing data
missing_data = num2str(100*nanmean([missingValues])/length(data{1}));
display(['Missing data values estimated: average of ', missing_data, '% missing data']);
%Interpolate possible missing values and filter the time series
for iData = 1:size(data,2)
    dataFiltered{iData} = interpolateSensorData(data{iData},frequency);
end
end