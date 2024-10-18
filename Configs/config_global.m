function [c] = config_global()
c = struct();
c.time_windows = [-2.5 -0.9 0 0.9];
c.time_windows_names = {'base','pre','post'};
c.age_names = {'4mo', '6mo', '9mo', '12mo'};
c.from = -3.5;
c.to = 5;

c.from_to = [c.from, c.to];

c.age = [4, 6, 9, 12];
c.ageCode = [1, 2, 3, 4];
c.fs = 60; % Hz

c.selected_body_parts = {
    'infantleftarm';
    'infantleftleg';
    'infantrightarm';
    'infantrightleg';
    'infanttrunkmid';
    'infanttrunkleft';
    'parentlefthand';
    'parentrighthand'}';

c.selected_body_parts_short = {
    'infantleftarm';
    'infantleftleg';
    'infantrightarm';
    'infantrightleg';
    'infanttrunkmid';
    'infanttrunkleft';
    'parentlefthand';
    'parentrighthand'}';
% ';'infanthead';
%  'parenthead';
%  'parentlefthand';
%  'parentrighthand';
%  'parenttrunkleft';
%  'parenttrunkmid'}

c.main_path = '/Users/joanna/Analysis/Script_Vocalisations/';
c.codes_directory = [c.main_path 'Files/Codes.txt'];
c.directoryResults = '/Users/joanna/Analysis/Vocalisations/';
c.directoryInSound = '/Users/joanna/Analysis/Vocalisations/Delay_cameras_mp3/';
c.directoryBABYLAB = '/Volumes/BABYLAB-1/MOVIN_Data/';
c.directoy_DataSet_Infant = '/Users/joanna/Analysis/Vocalisations/DataSet/';

c.pantone_l = [
    [232 129 166];
    [255 190 152];
    [95 200 179];
    [110 161 212]
    ]/256;

c.pantone_d = [
    [206 51 117];
    [255 167 79];
    [38 157 159];
    [27 80 145]
   ]/256;
c.aaublue1 = [34,44,77]/256;
c.tealme=[45 ,123 ,186]/256;
end

