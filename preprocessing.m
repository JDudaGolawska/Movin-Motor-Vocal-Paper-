function preprocessing(c)
% This function performs preprocessing of sensor data by removing artefacts
% and saving the cleaned data.

% Loop through all age codes
for ageCode =1:size(c.ageCode,2)
    clear Wsensors_all
    
    % Get list of files for the current age code
    [files, ~] = check_dir(c.directoy_DataSet, ageCode);
    
    % Iterate through all subjects
    for i_sub = 1: size(files, 1)
        
        clear Wsensors
        subjectName = files(i_sub).name;
        
        %% Load sensor data
        Wsensors = pop_loadset('filename', files(i_sub).name, 'filepath', files(i_sub).folder);
        Wsensors = eeg_checkset( Wsensors);
        
        fprintf("Processing subject %d: %s\n", i_sub, subjectName);
        
        %% Artefact removal process
        
        for limb = 1:size(Wsensors.data,1) % we do not check parents hand
            sensor = squeeze(Wsensors.data(limb,:,:));
            vector_tmp = 1:size(sensor,2);
            
            % Check if the sensor data is valid (i.e., not all NaNs)
            if ~all(isnan(sensor))
                % Identify peaks greater than 200 (possible artefacts)
                TF = sensor > 200;
                if any(TF==1)
                    [~, local_p]  = findpeaks(sensor, 'MINPEAKHEIGHT', 200);
                    
                    % For each detected peak, mark a surrounding window as NaN
                    for idx_peak = 1:size(local_p,2)
                        idx = (vector_tmp > (local_p(idx_peak)-40)) & (vector_tmp < (local_p(idx_peak)+40));
                        sensor(idx) = nan;
                    end
                    % Update the sensor data in Wsensors after artefact removal
                    Wsensors.data(limb,:,:) = sensor;
                end
            end
        end
        
        %% Save preprocessed data
        % Create the output directory if it doesn't exist
        if ~exist(c.directory_DataSetPrePro, 'dir')
            mkdir(c.directory_DataSetPrePro);
        end
        
        % Save the cleaned sensor data
        pop_saveset(Wsensors, 'filename',subjectName ,'filepath', c.directory_DataSetPrePro);
    end
    
end
end



