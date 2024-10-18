function [files, fileNames_str] = check_dir(directory, ageCode)
files = dir(directory);
fileNames = {files.name};

% files = files(~ismember(fileNames ,{'.','..','.DS_Store','.Rhistory'}));
files = files(contains(fileNames, sprintf('%d.set', ageCode)));
fileNames = {files.name};
fileNames = cellfun(@(x) extractBefore(x, sprintf('_%d', ageCode)), fileNames, 'UniformOutput', false);

fileNames_str = fileNames;
% fileNames = cell2mat(fileNames);
end