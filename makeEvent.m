function [Event] = makeEvent(stimuli)
%% wzorzec struktury
Event = fillEvent('delete', '', 0, 0, '');

%% Fill event
for i = 1:size(stimuli.type, 2)
    name = [stimuli.type{i} num2str(i)];
    type = stimuli.type{i};
    latency  = stimuli.latency(i);
    duration = stimuli.duration(i);
     baby = stimuli.baby{i};
    Event = [Event, fillEvent(name, type, latency, duration, baby)];
end
%% delete wzorzec struktury
Event(strcmp({Event.name}, 'delete') == 1) = [];
end

function event = fillEvent(name,type, latency, duration, baby)
event.name = name;
event.type = type;
event.latency = latency;
event.duration  = duration;
event.baby  = baby;
end
