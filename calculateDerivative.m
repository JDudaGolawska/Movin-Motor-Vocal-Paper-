function [Events, delay, flag] = calculateDerivative(c, iSub, Events, filename, Babyhand, Parenthand, filter_info, task)
% Function to calculate delay between signal-based and video-based annotations
% Inputs:
% - c: Configuration structure
% - iSub: Subject index
% - Events: Struct containing event data
% - filename: Name of the current data file
% - Babyhand: Data matrix for baby's hand movement
% - Parenthand: Data matrix for parent's hand movement
% - filter_info: Information about filtering
% - task: Task being processed (e.g., 'rattles', 'books', etc.)
% Outputs:
% - Events: Updated event data with latency adjusted
% - delay: Calculated delay between signal and annotations
% - flag: Indicator if the delay was successfully calculated

ParenthandL = sqrt(Parenthand(:,1).^2 + Parenthand(:,2).^2 + Parenthand(:,3).^2);
ParenthandR = sqrt(Parenthand(:,4).^2 + Parenthand(:,5).^2 + Parenthand(:,6).^2);
dependentVariable = ParenthandL  + ParenthandR;
dependentVariable = dependentVariable';
%% minimal distance between peaks
clap = [Events(contains({Events.name}, 'clap')).latency];
events = zeros(size(dependentVariable));
events(floor(clap)) = 1;
if length(clap)==1
    dist = 40;
else
    dist = abs(clap.'-clap);
    dist = min(dist(dist>0))*0.7;
    if dist > 40
        dist = 40;
    end
end

%% parameters
max_k_m = 20; % number of maximal fit-points
flag = 0;
delay = '';
probes = (max(clap)/1000+50)* c.fs; % number of probes when testing - (x[ms]/1000 + 20[s]) * fs

%% Exceptions in files
if strcmp(task,'rattles')
    files_to_check = {'77083_1'};
    if any(strcmp(files_to_check,filename))
        probes = (max(clap)/1000 +100)* c.fs; % number of probes when testing - (x[ms]/1000 + 20[s]) * fs
    end
    files_to_check = {'77040_2', '77024_2'};
    if any(strcmp(files_to_check,filename))
        return
    end
end
if strcmp(task,'books')
    files_to_check = {'77099_2','77071_4','77067_2'};
    if any(strcmp(files_to_check,filename))
        probes = (max(clap)/1000 +100)* c.fs; % number of probes when testing - (x[ms]/1000 + 20[s]) * fs
    end
    files_to_check = {'77017_3','77046_2'};
    if any(strcmp(files_to_check,filename))
        probes = (max(clap)/1000 +250)* c.fs; % number of probes when testing - (x[ms]/1000 + 20[s]) * fs
    end
end

if strcmp(task,'manipulative')
    files_to_check = {'77036_1'}; 
    if any(strcmp(files_to_check,filename))
        probes = (max(clap)/1000 + 100)* c.fs; % number of probes when testing - (x[ms]/1000 + 20[s]) * fs
    end
end

%% caluclating peaks
independentVariable = 1:size(dependentVariable, 2); % points vector
derivative = diff(dependentVariable) ./ diff(independentVariable); % derivative of parents hands(Acc) and points
derivative(probes:end) = derivative(probes:end)*0; % fill with zero further part of signal, claps are only at the beginig of signal
derivative = [derivative 0];

[up,lo] = envelope(derivative, 4, 'rms'); % envelope of signal to smooth it out
%  clf; t = (1:size(derivative,2))/c.fs; hold on; plot(t,derivative); plot(t,up+lo*(-1),'-',t,lo,'--'); xlim([0 probes]); hold off
env_derivative = up + lo*(-1);
[up,lo] = envelope(env_derivative, 2, 'rms'); % envelope of signal to smooth it out
env_derivative = up;


env_derivative(probes:end) = [];
dependentVariable(probes:end) = [];
derivative(probes:end) = [];
Parenthand(probes:end,:) = [];
Babyhand(probes:end,:) = [];
for  tresh = [50, 30,  10, 5, 1.5] % treshold when finding peaks
    [peaks, to]  = findpeaks(env_derivative, 'MINPEAKHEIGHT', tresh, 'MINPEAKDISTANCE' , dist);
     peak = zeros(size(dependentVariable));
    peak(to) = 1;
    if length(to)<length(clap)
        continue
    end
    if length(clap) == 1
        [~,delay] = max(env_derivative);
        delay =  -delay+clap ;
        
        for i = 1:size(Events,2)
            Events(i).latency = Events(i).latency  - delay;
        end
        clap = [Events(contains({Events.name}, 'clap')).latency];
        
        events = zeros(size(dependentVariable));
        events(ceil(clap(clap>0))) = 1;
        [fig_handle] = fitted_peaks(c, env_derivative, derivative,to, events, probes, Parenthand, Babyhand);
        check_and_print(fig_handle,  sprintf('%s%s_one.png', c.directoryFigures,filename), iSub, filter_info);
        return
    else
        for clap_dist = [5:2:15] %   distance between clap and annotation
            clap = [Events(contains({Events.name}, 'clap')).latency];  % probes
            events = zeros(size(dependentVariable)); % zeros vector - length of nb. of points of sensor signal
            events(floor(clap)) = 1;
            delta=length(events)-length(peak);
            [cor,lags]=xcorr([zeros(1,delta) peak(1,:)],events(1,:),'coeff');
            [b, idx_delay] = maxk(cor,length(clap)*max_k_m,2);
            delay = 0;
            flag = 0;
            for j =  1:length(idx_delay)
                ix = idx_delay(j);
                delay = delta-lags(ix);
                Events_tmp = Events;
                for i = 1:size(Events_tmp,2)
                    Events_tmp(i).latency = Events_tmp(i).latency  - delay;
                end
                clap = [Events_tmp(contains({Events_tmp.name}, 'clap')).latency];
                if any(clap< 0) || any(clap> size(dependentVariable,2))
                    continue
                end
                events = zeros(size(dependentVariable));
                events(ceil(clap(clap>0))) = 1;
                
                [col,row] = find(abs(to-clap(:)) < clap_dist);
                [fig_handle] = fitted_peaks(c, env_derivative, derivative,to, events, probes, Parenthand, Babyhand);
                if  isequal(col', 1:length(clap)) &&  isequal(row'- min(row), 0:length(clap)-1)
                    % move events
                    for i = 1:size(Events,2)
                        Events(i).latency = Events(i).latency  - delay;
                    end
                    clap = [Events(contains({Events.name}, 'clap')).latency];
                    
                    events = zeros(size(dependentVariable));
                    events(ceil(clap(clap>0))) = 1;
                    flag = 1;
                    return
                end
            end
        end
    end
end
if ~flag
    [fig_handle] = fitted_peaks(c, env_derivative, derivative,to, events, probes, Parenthand, Babyhand);
    check_and_print(fig_handle, sprintf('%s%s_Bad.png', c.directoryFigures,filename), iSub, filter_info);
end
end

function [] = check_and_print(fig_handle, name, iSub, filter_info)
idx = strfind(name, '/');
title(sprintf("%d / %s %s", iSub, replace(name(idx(end)+1:end-4), '_', ' '), filter_info));
if ~exist(name(1:idx(end)-1), 'dir')
    mkdir(name(1:idx(end)-1)) % make dir if doesnt exists
end
set(fig_handle,'PaperUnits','centimeters','PaperPosition',[0 0 30 25])
print(fig_handle, '-dpng', '-r200', name);
end


function [fig_handle] = fitted_peaks(c, env_derivative, derivative,to, events, probes, Parenthand, Babyhand)
fig_handle = figure(1);
clf;
t = (0:size(env_derivative, 2)-1)/c.fs;
row = 7;
top = find(events==1, 1, 'first')-240;
if top < 0
    top = 0;
end
limits = [top find(events==1, 1, 'last')+240]/60;
%% parent's hands
ax1 = subplot(row,1,4);
hold on;
title('parent: left hand');
plot(t, Parenthand(:,1));
plot(t, Parenthand(:,2));
plot(t, Parenthand(:,3));
xlim(limits)
hold off

ax2 = subplot(row,1,5);
hold on;
title('parent: right hand');
plot(t, Parenthand(:,4), 'color', c.pantone_d(1,:));
plot(t, Parenthand(:,5), 'color', c.pantone_d(2,:));
plot(t, Parenthand(:,6), 'color', c.pantone_d(3,:));
xlim(limits)
hold off

xlabel('time [s]')

%% peak signal
ax5 = subplot(row,1,1:3);
v_marker = max(env_derivative)*1.1;
blue  =[0 0.447 0.741];

plot(t, env_derivative , 'Color',[blue 0.6]); hold on;grid on
plot(t(to), env_derivative(to) , "v",'MarkerSize',6,  'MarkerFaceColor',blue, 'Color',blue);
ev = find(events(1,:)==1);
plot(t(ev), env_derivative(ev)*0+v_marker, "v",'MarkerSize',4, 'MarkerFaceColor','r', 'Color','r');
plot(t, events(1,:)*v_marker,'Color', 'r', 'HandleVisibility','off')
plot(t, derivative, 'k');
legend({'envelope', 'peaks', 'clap', 'signal'}, 'Location','southeast')
hold off;
axis tight;
xlim(limits)

linkaxes([ax1 ax2 ax5],'x');
end
