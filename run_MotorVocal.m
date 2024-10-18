% Process wearables data with vocalisations
clear all;

% Add paths to config and files folder with configs and description of sensors
addpath('./Configs');
addpath('./cbrewer2');
addpath('./Files');  % Holds Codes.txt
addpath('./eeglab2023/');

%% Define vocal sets to analyse
Vocal_Set = {{'s', 'p', 'w'}};  % Example vocal set: silence (s), parent (p), word (w)

%% Loop through task types (1 = rattles, 2 = books, 3 = manipulative)
for type = 1:3
    if type == 1
        c = config_rattles();  % Load rattles configuration
    elseif type == 2
        c = config_books();  % Load books configuration
    else
        c = config_manipulative();  % Load manipulative tasks configuration
    end
    
    %% Process each age group within the task
    for i = 1:size(c.age, 2)
        % Define directories for infant vocalisations and parent speech
        c.vocal_directory = sprintf('/Users/joanna/Analysis/Vocalisations/Infant/%dmo %s/', c.age(i), c.task);
        c.vocal_directory_Parent = sprintf('/Users/joanna/Analysis/Vocalisations/Parent_speech/%dmo %s/', c.age(i), c.task);
        
        % Load sensor data with events and calculate delay
        [info, Delay] = load_sensors(c, c.ageCode(i));
        
        % Save delays to a file
        save(sprintf('/Users/joanna/Analysis/Vocalisations/Delay_kam1_sensors/Delay_%d_%s.mat', c.ageCode(i), c.task), 'Delay');
        
        % Load sounds and sounds_event data
        load_sounds_and_events(c, c.ageCode(i));
        
        % Close all open figures
        close all;
    end
    
    %% Preprocess data
    preprocessing(c);
    
    %% Analyse task-specific vocalisation sets
    for vocal_set = Vocal_Set
        Averages_extract_and_merge_epochs(c, 'onset', vocal_set);  % Compute continuous averages for each vocal set
    end
    
    %% Create median-based tables for the vocalisation sets
    create_tables_mediana(c, Vocal_Set);

end

%% Generate a figure with averages and raindrop plots for the vocalisation sets- loop through task types
Averages_task_one_figure(Vocal_Set);
