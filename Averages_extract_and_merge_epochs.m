function [] = Averages_extract_and_merge_epochs(c, info_events, vocal_set)
% Function processes continuous EEG and sound data for different age groups.
% It extracts relevant epochs based on specified vocalisation events,
% identifies and rejects trials with invalid data, and optionally generates
% plots of the processed data. The function merges data across subjects
% within the same age group and saves the combined datasets for later analysis.

% Loop through each age group defined in the input structure
for ageCode = 1:size(c.ageCode,2)
    clear Wsensors_all Wsounds_all  % Clear variables for storing combined datasets
    
    [files, fileNames] = check_dir(c.directory_DataSetPrePro, ageCode);
    
    files = files(~contains(fileNames, 'norm'));
    
    for i_sub =1:size(files, 1)
        clear Wsensors Wsound trials_to_reject Event_sound Event_sensor
        
        fprintf('---------------------- %s ----------------------\n', files(i_sub).name);
        
        % load continous data
        Wsensors = pop_loadset('filename', files(i_sub).name, 'filepath', files(i_sub).folder);
        Wsensors = eeg_checkset( Wsensors);
        
        % extract channels just hand and legs
        Wsensors = pop_select( Wsensors, 'channel', {Wsensors.chanlocs(1:4).labels});
        Wsensors = eeg_checkset( Wsensors);
        
        %% extract epochs
        if isempty(Wsensors.event)
            continue
        end
        try
            Wsensors = pop_epoch(Wsensors, vocal_set{:}, [c.from, c.to], 'newname', Wsensors.filename, 'epochinfo', 'yes');
            Wsensors = eeg_checkset(Wsensors);
        catch ME
            if strcmp(ME.message, 'pop_epoch(): empty epoch range (no epochs were found).')
                disp('No epoch to extract');
                continue
            else
                rethrow(ME)
            end
        end
        
        % correct single epoch mistake
        if Wsensors.times(1) ~= c.from*1000 % when one epoch is generetaed time vector is not correct
            Wsensors.times = linspace(c.from, c.to,  size(Wsensors.times,2)) * 1000;
            Wsensors.xmin = Wsensors.times(1)/1000;
            Wsensors.xmax = Wsensors.times(end)/1000;
            if isempty(Wsensors.epoch)
                Wsensors.epoch.event = [1];
                Wsensors.epoch.eventname = {Wsensors.event.name};
                Wsensors.epoch.eventtype = {Wsensors.event.type};
                Wsensors.epoch.eventlatency = {Wsensors.event.latency};
                Wsensors.epoch.eventduration = {Wsensors.event.duration};
                Wsensors.epoch.eventbaby = {Wsensors.event.baby};
            end
        end
        
        trials_to_reject = [];
        for i_limb = 1:Wsensors.nbchan
            for i_trial = 1:Wsensors.trials
                if any(isnan(squeeze(Wsensors.data(i_limb,:,i_trial))))
                    trials_to_reject = [trials_to_reject i_trial];
                end
            end
        end
        
        for i_limb = 1:Wsensors.nbchan
            for i_trial = 1:Wsensors.trials
                if sum(squeeze(Wsensors.data(i_limb,:,i_trial)))==0
                    trials_to_reject = [trials_to_reject i_trial];
                end
            end
        end
        
        
        if ~isempty(trials_to_reject)
            trials_to_reject = unique(trials_to_reject);
            if size(trials_to_reject, 2) == Wsensors.trials  % all trials removed
                continue
            end
            Wsensors = pop_rejepoch( Wsensors, trials_to_reject ,0);
        end
        
        
        %% load sounds
        try
            Wsound = pop_loadset('filename',files(i_sub).name ,'filepath',['/Users/joanna/Analysis/Vocalisations/DataSetSound/' upper(c.task(1)) c.task(2:end)]);
            Wsound = eeg_checkset( Wsound);
        catch
            continue
        end
        if strcmp(vocal_set{:}, 'silence')
            Wsound.event = Event_sound;
        end
        try
            Wsound = pop_epoch(Wsound, vocal_set{:}, [c.from, c.to], 'newname', Wsound.filename, 'epochinfo', 'yes');
            Wsound = eeg_checkset(Wsound);
        catch ME
            if strcmp(ME.message, 'pop_epoch(): empty epoch range (no epochs were found).')
                disp('No epoch to extract');
                continue
            else
                rethrow(ME)
            end
        end
        
        if Wsound.times(1) ~= c.from*1000 % when one epoch is generetaed time vector is not correct
            Wsound.times = linspace(c.from, c.to,  size(Wsound.times,2)) * 1000;
            Wsound.xmin = Wsound.times(1)/1000;
            Wsound.xmax = Wsound.times(end)/1000;
            if isempty(Wsound.epoch)
                Wsound.epoch.event = [1];
                Wsound.epoch.eventname = {Wsound.event.name};
                Wsound.epoch.eventtype = {Wsound.event.type};
                Wsound.epoch.eventlatency = {Wsound.event.latency};
                Wsound.epoch.eventduration = {Wsound.event.duration};
                Wsound.epoch.eventbaby = {Wsound.event.baby};
            end
        end
        if strcmp(vocal_set{:}, 'silence')
            [sound_present] = check_is_sound(Wsound.data, Wsound.srate);
            trials_to_reject = [trials_to_reject find(sound_present)];
        end
        
        %% reject all not needed epochs
        if length(trials_to_reject)>0
            trials_to_reject = unique(trials_to_reject);
            if size(trials_to_reject, 2) == Wsound.trials  % all trials removed
                continue
            end
            Wsound = pop_rejepoch( Wsound, trials_to_reject ,0);
            if isempty(Wsound.epoch)
                continue
            end
        end
        
        %% reject all not needed epochs just in silence, cose we are intresed only in epoch with no sound
        if strcmp(vocal_set{:}, 'silence') && sum(sound_present)>0
            EpochIn = {Wsound.epoch.eventname};
            EpochSensor = {Wsensors.epoch.eventname};
            found = cellfun(@(x) any(strcmp(x, EpochIn)), EpochSensor);
            Wsensors = pop_rejepoch( Wsensors, ~found ,0);
        end
        
        %% Merge sets
        if isempty(Wsensors.epoch)
            continue
        end
        
        if ~exist('Wsensors_all', 'var')
            
            Wsensors_all = Wsensors;
            Wsensors_all.setname =  sprintf("%s_%d", c.task, ageCode);
        else
            Wsensors_all = pop_mergeset2(Wsensors, Wsensors_all);
        end
        
        if ~exist('Wsounds_all', 'var')
            Wsounds_all = Wsound;
            Wsounds_all.setname =  sprintf("%s_%d", c.task, ageCode);
        else
            if ~isempty(Wsound.data)
                Wsounds_all = pop_mergeset2(Wsounds_all, Wsound);
            end
        end
        
    end
    if ~exist(c.directoy_DataMat,'dir')
        mkdir(c.directoy_DataMat) % make dir if doesnt exists
    end
    if exist('Wsensors_all', 'var')
        if ~isempty(Wsensors_all.data)
            
            Wsensors_all.setname = sprintf('all sets %s %s', [vocal_set{:}{:}], info_events);
            Wsensors_all.filename = sprintf('all sets %s %s', [vocal_set{:}{:}], info_events);
            Wsensors_all.filepath = sprintf('%sWsensors_all_%d_%s_%s.mat', c.directoy_DataMat, ageCode, info_events,[vocal_set{:}{:}]);
            save(sprintf('%sWsensors_all_%d_%s_%s.mat', c.directoy_DataMat, ageCode, info_events,[vocal_set{:}{:}]), 'Wsensors_all');
            
            
            if ~exist(c.directoy_DataMatSound,'dir')
                mkdir(c.directoy_DataMatSound) % make dir if doesnt exists
            end
            Wsounds_all.setname = sprintf('all sets %s %s', [vocal_set{:}{:}], info_events);
            Wsounds_all.filename = sprintf('all sets %s %s', [vocal_set{:}{:}], info_events);
            Wsounds_all.filepath = sprintf('%sWsounds_all_%d_%s_%s.mat', c.directoy_DataMatSound, ageCode, info_events,[vocal_set{:}{:}]);
            Wsounds_all = eeg_checkset(Wsounds_all);
            save(sprintf('%sWsounds_all_%d_%s_%s.mat', c.directoy_DataMatSound, ageCode, info_events,[vocal_set{:}{:}]), 'Wsounds_all', '-v7.3');
        end
    end
end
end
