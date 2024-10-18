function [info, Delay] = load_sensors(c,ageCode)
% This function loads data from IMU sensors, extracts acceleration,
% gyroscope, and magnetometer data, and creates various plots to
% visualise synchronisation between annotated 'claps' and movement in the accelerometer.

%% Load all vocalisation events for the infant and parent
[Events, folderNames_vocal, uniqueLabels] = get_vocal(c, c.vocal_directory);
[Events_parent, folderNames_vocal_parent, ~] = get_vocal(c, c.vocal_directory_Parent);

%% Load sampling frequency and delay table
load(sprintf('%s/Configs/sampling_rate_%s.mat', c.main_path, c.task), 'sampling_frequency');
load(sprintf('/Users/joanna/Analysis/Vocalisations/Delay_cameras_mp3/Table/Table_%s.mat', c.task), 'Table_delay');

%% Temporary table extension for delay
idx_empty = size(Table_delay,2)+1;
Table_delay(idx_empty).cam1_ms = 0;
Table_delay(idx_empty).cam2_ms = 0;
Table_delay(idx_empty).cam3_ms = 0;

%% Load and filter data by the specified infant age
parent_directory = c.parent_directory;
files = dir(parent_directory);
dirFlags = [files.isdir];
subFolders = files(dirFlags);
folderNames = {subFolders.name};
subFolders = subFolders(~ismember(folderNames ,{'.','..','.DS_Store'}));
folderNames = folderNames(~ismember(folderNames ,{'.','..','.DS_Store'}));
babyAge = cellfun(@(y) y, cellfun(@(x) str2double(extractAfter(x, '_')), folderNames, 'UniformOutput', false))';
subFolders = subFolders(babyAge==ageCode,:);
folderNames = {subFolders.name};
folderNames = folderNames(~ismember(folderNames ,{'.','..','.DS_Store'}));

%% Initialize output structure for delay information
Delay = struct;

%% Loop through each infant folder
for i_sub = 1:size(folderNames_vocal, 2)
    subjectName = folderNames_vocal{i_sub};
    fprintf("Start processing subject %d: %s\n", i_sub, subjectName);
    info = [];
    data = [];
    device = [];
    dataAux = [];
    header = [];
    device = [];
    Wsensors = [];
    if sum(contains(folderNames, subjectName)) && any(contains({Events(strcmp({Events.baby}, subjectName)).data.name},'clap'))
        % Load sensor data from folder
        filesInFolder = dir(strcat(parent_directory,'/',subjectName));
        fileNames = {filesInFolder.name};
        filesInFolder = filesInFolder(contains(fileNames ,'.txt'));
        if isempty(filesInFolder)
            continue
        end
        for iFile=1:length(filesInFolder)
            data{iFile} = importdata(strcat(filesInFolder(iFile,1).folder,'/',filesInFolder(iFile,1).name));
            positions_bar = strfind(filesInFolder(iFile,1).name,'_');
            device{iFile} = filesInFolder(iFile,1).name(positions_bar(end)+1:positions_bar(end)+8);
        end
        
        % Load conversion codes for slected body parts
        [codes,bodyParts] = loadCodes_BodyParts(device, c.codes_directory);
        listOfSelectedParts = c.selected_body_parts;
        
        % Match selected parts with loaded body parts
        for iSelected = 1:size(listOfSelectedParts,2)
            for iPart = 1:size(bodyParts,2)
                if strcmp(listOfSelectedParts{1,iSelected},bodyParts{1,iPart})
                    bodyPartsNumber(iSelected) = iPart;
                    break;
                end
            end
        end
        
        
        try
            header = data{1,1}.colheaders;
            % Remove the unnecesary data for further processing
            device = device(:,bodyPartsNumber);
            data = data(:,bodyPartsNumber);
        catch
            fprintf('missing sensors_data');
            continue;
        end
        
        %% Pre-process all the data and generate the average movement signals
        % The data is sorted alfabetically -> Firstcolumn Infant Left Arm; Second
        % Column Infant Right Arm, Third column is the ParentLeftHand and the last
        % column is the ParentRightHand
        positions = {};
        %For each infant we calculate the position of this data to avoid
        %differences in the way the data was exported.
        for iColumn=1:size(data{1}.textdata,2)
            switch data{1}.textdata{end,iColumn}
                case 'Acc_X'
                    [positions.acceleration] = iColumn:1:iColumn+2;
                case 'Gyr_X'
                    [positions.gyroscope] = iColumn:1:iColumn+2;
                case 'Mag_X'
                    [positions.magneticField] = iColumn:1:iColumn+2;
            end
        end
        %Remove the structure so can perform the interpolation easier
        for iFile=1:size(data,2)
            try
                dataAux{iFile} = data{iFile}.data( :,[1, 2, positions.acceleration] );
            catch
                if iFile==5 ||  iFile==6
                    dataAux{iFile} =  nan(size(dataAux{iFile-1}));
                    dataAux{iFile}(:,1) =  dataAux{iFile-1}(:,1);
                else
                    continue;
                end
            end
        end
        data = dataAux;
        if any(cellfun(@isempty,data))
            continue
        end
        %% Filter and Interpolate the data %%
        [frequency(i_sub), data_Interpolated, missing_data] = filterSensorData(data,strcat(parent_directory,subjectName,'/',filesInFolder(1,1).name), sampling_frequency);
        
        %% we choose acceleration
        positions = positions.acceleration-2;
        chan_type = header(positions+2);
        
        %% prepare Wsensors Set
        load('./Wsensors.mat', 'Wsensors');
        load('./channels.mat', 'channels');
        
        Wsensors.setname = ['acceleration_' subjectName]; % baby type - acceleration
        Data_tmp = [];
        Parenthand = [];
        Parenthand3 = [];
        Babyhand3 = [];
        chan = 1;
        Acc = [];
        Acc1 = [];
        for body_parts = 1:size(data_Interpolated,2)
            Acc1 = data_Interpolated{1, body_parts}(:, positions);
            if  contains(listOfSelectedParts{body_parts}, 'parent')
                Parenthand3 = [Parenthand3 Acc1];
            else
                
                clf; ax1=subplot(2,1,1);plot(Acc1(:,1), 'color',c.pantone_d(1,:));hold on; plot(Acc1(:,2), 'color',c.pantone_d(2,:)); plot(Acc1(:,3), 'color',c.pantone_d(3,:)); hold off
                axis tight
                yline(0)
                Acc = sqrt(Acc1(:,1).^2 + Acc1(:,2).^2 + Acc1(:,3).^2);
                
                ax2 =subplot(2,1,2);plot(Acc(:), 'color',c.aaublue1);    axis tight
                yline(0)
                ax1.XTick = [];    ax1.YTick = []; ax2.XTick = [];    ax2.YTick = [];
                linkaxes([ax1, ax2], 'x');
                if  contains(listOfSelectedParts{body_parts}, 'arm')
                    Babyhand3 = [Babyhand3 Acc1]; % just to visualise
                end
                %% Fitration - with filtering
                [Acc] = filter_data(c, Acc);
                Data_tmp = [Data_tmp, Acc];
                channels(chan).labels = sprintf('%s', listOfSelectedParts{body_parts});
            end
            chan = chan + 1;
        end
        ParenthandL = sqrt(Parenthand3(:,1).^2 + Parenthand3(:,2).^2 + Parenthand3(:,3).^2);
        ParenthandR = sqrt(Parenthand3(:,4).^2 + Parenthand3(:,5).^2 + Parenthand3(:,6).^2);
        Parenthand = ParenthandL  + ParenthandR;
        
        Data_tmp = [Data_tmp, Parenthand, filter_data(c, ParenthandR),   filter_data(c, ParenthandL)];
        
        
        channels(size(channels,2)+1).labels = 'parenthands_Acc';
        channels(size(channels,2)+1).labels = listOfSelectedParts{7};
        channels(size(channels,2)+1).labels = listOfSelectedParts{8};
        
        % Fill Wsensor struct
        Wsensors.data = Data_tmp';
        Wsensors.nbchan = size(Data_tmp,2); % 4 body parts child + one summed parent
        Wsensors.srate = 60;
        Wsensors.chanlocs = channels;
        Wsensors.pnts = size( Wsensors.data ,2);
        Wsensors.missing_data = missing_data;
        Wsensors.event = Events(strcmp({Events.baby}, subjectName)).data;
        Wsensors.event = [Wsensors.event Events_parent(strcmp({Events_parent.baby}, subjectName)).data];
        Wsensors.camera =   Events(strcmp({Events.baby}, subjectName)).kamera;
        Wsensors.ref = 'none';
        Wsensors.filter = sprintf('high pass butter, 1 order, 0.001 Hz');
        Wsensors.comments = info;
        Wsensors = eeg_checkset( Wsensors);
        
        fprintf("cal %d %s\n",i_sub, subjectName);
        
        %% correction based on 'clap' events
        
        [Wevent, delay, flag] = calculateDerivative(c,i_sub, Wsensors.event, subjectName, Babyhand3, Parenthand3, Wsensors.filter, c.task);
        if flag
            %% Apply correction based on 'clap' events and calculate delays
            Delay(i_sub).baby = subjectName;
            Delay(i_sub).task = c.task;
            Delay(i_sub).delay_probes = delay; % if it have positive value it means that events where
            Delay(i_sub).delay_camera = double(Wsensors.camera);
            Delay(i_sub).delay_ms = (delay/c.fs)*1000;
            idx_sub = find(contains([Table_delay.task], c.task) & contains([Table_delay.name], subjectName));
            if isempty(idx_sub)
                idx_sub  = idx_empty;
            end
            
            Delay(i_sub).delay_cam1_ms = Table_delay(idx_sub).cam1_ms;
            Delay(i_sub).delay_cam2_ms = Table_delay(idx_sub).cam2_ms;
            Delay(i_sub).delay_cam3_ms = Table_delay(idx_sub).cam3_ms;
            sync_delay = sync_cam(Table_delay(idx_sub), Delay(i_sub).delay_camera, Delay(i_sub).delay_ms);
            Delay(i_sub).sync_to_cam1_ms =  sync_delay(1);
            Delay(i_sub).sync_to_cam2_ms =  sync_delay(2);
            Delay(i_sub).sync_to_cam3_ms =  sync_delay(3);
            
            
            Wsensors.delay_probes = delay; % if it have positive value it means that events where
            Wsensors.delay_camera = double(Wsensors.camera);
            Wsensors.delay_ms = (delay/c.fs)*1000;
            Wsensors.delay_cam1_ms = Table_delay(idx_sub).cam1_ms;
            Wsensors.delay_cam2_ms = Table_delay(idx_sub).cam2_ms;
            Wsensors.delay_cam3_ms = Table_delay(idx_sub).cam3_ms;
            Wsensors.sync_to_cam1_ms =  sync_delay(1);
            Wsensors.sync_to_cam2_ms =  sync_delay(2);
            Wsensors.sync_to_cam3_ms =  sync_delay(3);
            
            Wsensors.event = Wevent;
            Wsensors.delay = delay;
            
            %% Save the processed sensor data
            pop_saveset(Wsensors, 'filename', subjectName,'filepath', c.directoy_DataSet);
        end
    end
end
end


