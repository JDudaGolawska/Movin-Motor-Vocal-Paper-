function [] = create_tables_mediana(c, Vocal_Set)
% create long tables for statistical analysis
find_limbs = {{'infantleftarm','infantrightarm'};{'infantleftleg','infantrightleg'}} ;
Limbs = {'arm','leg'};
% find all files
Files = dir(c.directoy_DataMat);
Files = Files(contains({Files.name}, sprintf('.mat')));
Files = Files(contains({Files.name}, sprintf('Wsensors_all')));
c.time_windows = c.time_windows*1000;
for vc = Vocal_Set
    % create table
    files = Files(contains({Files.name}, [vc{:}{:} '.mat']));
    clear Table
    Table.median = [];
    i_tab = 1;
    
    for i_File = 1:size(files,1)
        disp([string(i_File) '_' c.task])
        load([files(i_File).folder '/' files(i_File).name], 'Wsensors_all')
 
        for i_limbs = 1:size(Wsensors_all.data, 1)
            for i_trial = 1:size(Wsensors_all.data, 3)
                  %% baseline 
                [top, bot] = envelope(Wsensors_all.data(i_limbs,:,i_trial),12,'analytic');
                Wsensors_all.data(i_limbs,:,i_trial) = Wsensors_all.data(i_limbs,:,i_trial) - mean(top+ bot)/2;
                  %% envelope on baselined signal
                [Wsensors_all.data(i_limbs,:,i_trial), ~] = envelope(Wsensors_all.data(i_limbs,:,i_trial),12,'analytic');
            end
        end
        task = strcat(upper(c.task(1)),lower(c.task(2:end)));
        time_window = extractAfter(extractBetween(extractAfter(extractAfter(files(i_File).name, '_'), '_'), '_','.mat'), '_');
        epoched = extractBefore(extractBetween(extractAfter(extractAfter(files(i_File).name, '_'), '_'), '_','.mat'), '_');
        for i_epoch = 1:size(Wsensors_all.data, 3)
            % sprawdzamy czy któryś ma pusty sensor
            signal_test = squeeze(mean(mean(Wsensors_all.data(:, :, i_epoch),3),2));
            if ~any(signal_test == 0)
                for i_l = 1:size(Limbs, 2)
                    limb = find(contains({Wsensors_all.chanlocs.labels}, find_limbs{i_l}));
                    for i_time = 1:size(c.time_windows_names,2)%'{'base', 'pre' ,'onset','post'}%'{ 'pre' ,'onset','post'}%
                        %% time windows idx
                        idx_window = c.time_windows(i_time)<Wsensors_all.times & Wsensors_all.times<c.time_windows(i_time+1);
                        tmp =  mean(squeeze(median(Wsensors_all.data(limb, idx_window, i_epoch),2)));
                        Table(i_tab).median = tmp;
                        Table(i_tab).limb = Limbs{i_l};
                        Table(i_tab).time_window = c.time_windows_names{i_time};
                        Table(i_tab).task = [task  upper(time_window{:})];
                        if isempty(Wsensors_all.epoch)
                            Wsensors_all.epoch.event = [1];
                            Wsensors_all.epoch.eventname = {Wsensors_all.event.name};
                            Wsensors_all.epoch.eventtype = {Wsensors_all.event.type};
                            Wsensors_all.epoch.eventlatency = {0};
                            Wsensors_all.epoch.eventduration = {Wsensors_all.event.duration};
                            Wsensors_all.epoch.eventbaby = {Wsensors_all.event.baby};
                        end
                        if iscell(Wsensors_all.epoch(i_epoch).eventlatency)
                             idx_cell =  knnsearch([Wsensors_all.epoch(i_epoch).eventlatency{:}]',0); % find index nearest to zero
                        else
                            idx_cell = find([Wsensors_all.epoch(i_epoch).eventlatency] == 0);
                        end
                       
                        if iscell(Wsensors_all.epoch(i_epoch).eventbaby)
                            Table(i_tab).baby = Wsensors_all.epoch(i_epoch).eventbaby{idx_cell};
                        else
                            Table(i_tab).baby = Wsensors_all.epoch(i_epoch).eventbaby;
                        end
                        Table(i_tab).age = sprintf("mo%d",c.age(str2double( extractAfter(Table(i_tab).baby, '_'))));
                        Table(i_tab).age_nb =  c.age(str2double( extractAfter(Table(i_tab).baby, '_')))-3;
                        i_tab = i_tab + 1;
                    end
                end
                
            end
        end
    end
    
    T = struct2table(Table);
    % calculate median
    age = unique(T.age);
    clear Table
    Table.median = [];
    i_tab = 1;
    for i_limb = 1:2
        idx_limb = strcmp(T.limb,Limbs(i_limb));
        for i_age = 1:size(age, 1)
            for i_window = 1:size(c.time_windows, 2)
                idx_time = T.age==age(i_age);
                idx_window = strcmp(T.time_window,c.time_windows(i_window));
                baby = unique(T.baby(idx_time&idx_window&idx_limb));
                for i_baby = 1:size(baby, 1)
                    idx_baby = (T.baby==baby(i_baby));
                    Table(i_tab).median  =  median(T.median(idx_time&idx_window&idx_baby&idx_limb));
                    Table(i_tab).limb = Limbs(i_limb);
                    Table(i_tab).time_window = i_time{1};
                    Table(i_tab).task = [task  upper(time_window{:})];
                    Table(i_tab).baby =  baby(i_baby);
                    Table(i_tab).age = sprintf("mo%d",c.age(i_age));
                    Table(i_tab).age_nb =  i_age;
                    i_tab = i_tab + 1;
                end
            end
        end
    end
    Tmedian = struct2table(Table);
    writetable(T,sprintf('%sTable_%s_%s_%s_median.txt',c.directoy_DataMat,task,[vc{:}{:}] ,epoched{:}),'Delimiter',' ')
    writetable(Tmedian,sprintf('%sTable_%s_%s_%s_median_median.txt',c.directoy_DataMat,task,[vc{:}{:}] ,epoched{:}),'Delimiter',' ')
    
end
if 0
    fig_handle=figure(1);
    d=4;
    ax1= subplot(d,1,1);histogram(Mean.mean_var);title(mean(Mean.mean_var));title(['mean var ' str2double(mean(Mean.mean_var))]);
    ax2 = subplot(d,1,2);histogram(Mean.mean_all);title(mean(Mean.mean_all));title(['mean all' str2double(mean(Mean.mean_var))]);
    ax3 = subplot(d,1,3);histogram(Mean.mean_base);title(mean(Mean.mean_base));title(['mean base' str2double(mean(Mean.mean_var))]);
    ax4 = subplot(d,1,4);histogram([Mean.idx_mean_var.idx]/60-1);title('var index');xlabel('s')
    xlim([-1 1])
    linkaxes([ax1, ax2, ax3])
    
    set(fig_handle, 'PaperUnits', 'centimeters');
    
    set(fig_handle,'PaperUnits','centimeters','PaperPosition',[0 0 30 15])
    set(fig_handle, 'PaperPositionMode', 'manual');
    set(findall(fig_handle,'-property', 'FontSize'), 'FontSize', 8)
    directory =  replace(sprintf('%sFigures/Hist/', c.directoryResults ),' ','_') ;
    
    if ~exist(directory,'dir')
        mkdir(directory) % make dir if doesnt exists
    end
    print(fig_handle, '-dpng', '-r150', replace(sprintf('%s/hist_%s_mean_var.png', directory,c.task),' ','_') );
end
end
