function [Events, babyCodes_vocal, UniqueLabels] = get_vocal(c, vocal_directory)
%This script is gonna read the data from the coded vocalisations and it is
%going to return the descriptives

%V1.0 Creation of the document by David Lopez Perez 05.01.2022
%V1.1 Adaption to Moving vocalisations data by David Lopez Perez 02.03.2022
%V1.2 Bug Fix. 'auto' has been include in the TgRead called to avoid
%problems with different encodings 14.04.2022
%V1.4 Event structure added Joanna Duda-Goławska 30.06.2023

%Load the coded files
files = dir(vocal_directory);
fileNames = {files.name};
fileNames = fileNames(~ismember(fileNames ,{'.','..','.DS_Store','.Rhistory'}));
babyCodes_vocal =  cellfun(@(x) extractBefore(x,c.eb), fileNames, 'UniformOutput', false);
UniqueLabels = [];
Events = struct();
%Loop through them and call the
arrayOfErrorsOfClap = {'cap'};
arrayOFErrorsToRemove = {char(9), char(10)};% Tab and return key
for i=length(fileNames):-1:1
    tg = tgRead(strcat(vocal_directory,'/',fileNames{i}),'auto');
    % get info about camera
    kamera = string(extractBetween(lower(fileNames{i}), 'kam', '_'));
    if isempty(kamera) || strcmp(kamera,"")
        kamera = string(extractBetween(lower(fileNames{i}), 'kma', '_'));
    end
    if isempty(kamera) || strcmp(kamera,"")
        kamera = string(extractBetween(lower(fileNames{i}), 'kam_', '_'));
    end
    if isempty(kamera) || strcmp(kamera,"")
        kamera = string(extractBetween(lower(fileNames{i}), 'kam_', '.'));
    end
    if isempty(kamera) || strcmp(kamera,"")
        kamera = string(extractBetween(lower(fileNames{i}), 'kam', '.'));
    end
    
    if contains(vocal_directory,'Parent') && ( isempty(kamera)|| strcmp(kamera,""))
        kamera = '1';
    end
    %Get the tier Index
    tierInd = tgI(tg, 1);
    %Get the unique labels
    %It is not seeing all the labels here (it misses rl and rc)
    uniqueLabels = unique(tg.tier{tierInd}.Label);
    
    %Remove the empty tiers which normally means the empty spaces between
    %vocalisations and calculate the descriptives for each type vocalisation
    for iError = 1:length(arrayOFErrorsToRemove)
        condition = find(ismember(tg.tier{tierInd}.Label,arrayOFErrorsToRemove{iError}));
        if ~isempty(condition)
            for iCond = 1:length(condition)
                tg = tgSetLabel(tg,1, condition(iCond), '');
            end
            %Clean those labels
            for iLabel = length(uniqueLabels):-1:1
                if strcmp(uniqueLabels{iLabel},arrayOFErrorsToRemove{iError})
                    uniqueLabels(iLabel) = [];
                end
            end
        end
    end
    for iError = 1:length(arrayOfErrorsOfClap)
        condition = find(ismember(tg.tier{tierInd}.Label,arrayOfErrorsOfClap{iError}));
        if ~isempty(condition)
            for iCond = 1:length(condition)
                tg = tgSetLabel(tg, 1, condition(iCond), 'clap');
            end
            %Clean those labels
            for iLabel = length(uniqueLabels):-1:1
                if strcmp(uniqueLabels{iLabel},arrayOfErrorsOfClap{iError})
                    uniqueLabels(iLabel) = [];
                end
            end
        end
    end
    for iLabel = length(uniqueLabels):-1:1
        if isempty(uniqueLabels{iLabel})
            uniqueLabels(iLabel) = [];
        end
    end
    
    % Extract the durations of each type of vocalisation
    stimuli.type = [];
    stimuli.duration = [];
    stimuli.latency = [];
    stimuli.baby = [];
    for iLabel = 1:length(uniqueLabels)
        condition = ismember(tg.tier{tierInd}.Label, uniqueLabels{iLabel});
        stimuli.type = [stimuli.type tg.tier{tierInd}.Label(condition)];
        % probes
        stimuli.duration = [stimuli.duration (tg.tier{tierInd}.T2(condition) - tg.tier{tierInd}.T1(condition))*c.fs];
        % probes
        stimuli.latency = [stimuli.latency tg.tier{tierInd}.T1(condition)*c.fs];
    end
    stimuli.baby = repmat({babyCodes_vocal{i}}, size(stimuli.type ,1), size(stimuli.type ,2));
    % Create Events structure for eeglab
    
    if ~contains(vocal_directory,'Parent')
        [kamera_clap, stimuli] = importfiles_clap(c, stimuli,kamera);
    else
        kamera_clap = [];
        % delete clpas, it was syncronised to other clap
        idx_del = contains(stimuli.type(:), 'clap');
        stimuli.type(idx_del) = [];
        stimuli.duration(idx_del)  = [];
        stimuli.latency(idx_del)  = [];
        stimuli.baby(idx_del)  = [];
        % add cargiver to events
        stimuli.type = cellfun(@(c)[c '_cg'], stimuli.type,'uni',false);
    end
    Events(i).data = makeEvent(stimuli);
    Events(i).baby = babyCodes_vocal{i};
    Events(i).kamera = kamera;
    Events(i).kamera_clap = kamera_clap;
    UniqueLabels = [UniqueLabels uniqueLabels];
end
UniqueLabels = unique(UniqueLabels);

end
