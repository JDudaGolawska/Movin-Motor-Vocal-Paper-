function [] = load_sounds_and_events(c, ageCode)
% This function loads data from IMU sensors, extracts relevant epochs,
% and imports the corresponding sound track for synchronisation.

% Get list of files for the specified age group
[files, ~] = check_dir(c.directoy_DataSet, ageCode);

% Iterate through all subject files
for i_sub = 1: size(files, 1)
    clear Wsensors
    subjectName = files(i_sub).name(1:end-4);
    
    %% Load IMU sensor data
    Wsensors = pop_loadset('filename', files(i_sub).name, 'filepath', files(i_sub).folder);
    Wsensors = eeg_checkset( Wsensors);
    fprintf("Processing subject %d: %s\n", i_sub, subjectName);
    
    %% Load and sync sound data
    try
        % Get the camera used for synchronisation
        kamera_used_to_synch = Wsensors.delay_camera;
        sync_audio(c, subjectName, Wsensors,  kamera_used_to_synch);
        
        % Construct file path for sound track (MP3)
        f1_mp3 = replace(sprintf('%s%s_%s_kam%d.mp3', c.directoryInSound, subjectName, c.task, kamera_used_to_synch), ' ', '\ '); % direcotry to MP3
        
        % Load the sound file
        [signal_sound, Fs_sound] = audioread(f1_mp3);
        
        % Assign sound data to Wsensors structure
        Wsound = Wsensors;
        Wsound.data = signal_sound(1:end)';
        Wsound.pnts = size( Wsound.data, 2);
        Wsound.chanlocs = Wsensors.chanlocs(1);
        Wsound.chanlocs(1).labels = 'sound';
        Wsound.srate = Fs_sound;
        Wsound.nbchan = 1;
        
        % Synchronise sound events with camera delay
        cam_del = Wsensors.(sprintf('sync_to_cam%d_ms', Wsensors.delay_camera))/1000;
        
        % Adjust event latencies to match the sound sampling rate
        for i_event = 1: size(Wsound.event,2)
            Wsound.event(i_event).latency = (Wsound.event(i_event).latency/Wsensors.srate + cam_del)*Fs_sound;
        end
        % Check and save the updated sound structure
        Wsound = eeg_checkset( Wsound);
        Wsound = pop_saveset(Wsound, 'filename',subjectName ,'filepath',['/Users/joanna/Analysis/Vocalisations/DataSetSound/' upper(c.task(1)) c.task(2:end)]);
    catch
        % If an error occurs, exclude this subject and clear sound data
        disp('Excluded from the dataset');
        clear Wsound
    end
    
end
end
