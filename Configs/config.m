function [c] = config()
% configuration file

c = struct();
c.main_path = '/Users/joanna/Analysis/Script_Vocalisations/';
c.codes_directory = [c.main_path 'Files/Codes.txt'];

c.vocal_directory = {'/Users/joanna/Analysis/Vocalisations/Infant/4mo books/',...
    '/Users/joanna/Analysis/Vocalisations/Infant/12mo books/',...
    '/Users/joanna/Analysis/Vocalisations/Infant/4mo manipulative/',...
    '/Users/joanna/Analysis/Vocalisations/Infant/12mo manipulative/'};

c.parent_directory = {'/Users/joanna/Analysis/Lab/books/',...
    '/Users/joanna/Analysis/Lab/books/',...
    '/Users/joanna/Analysis/Lab/manipulative/',...
    '/Users/joanna/Analysis/Lab/manipulative/'};

c.directoy_DataSet = {'/Users/joanna/Analysis/Vocalisations/DataSet/Infant_4mo_books/',...
    '/Users/joanna/Analysis/Vocalisations/DataSet/Infant_12mo_books/',...
    '/Users/joanna/Analysis/Vocalisations/DataSet/Infant_4mo_manipulative/',...
    '/Users/joanna/Analysis/Vocalisations/DataSet/Infant_12mo_manipulative/'};

c.ageCode = {1, 4, 1, 4};

% c.eb = {'_b', '_b', '_m', '_m'};

c.directoryFigures = {'/Users/joanna/Analysis/Vocalisations/Figures_books/',...
    '/Users/joanna/Analysis/Vocalisations/Figures_books/',...
    '/Users/joanna/Analysis/Vocalisations/Figures_manipulative/',...
    '/Users/joanna/Analysis/Vocalisations/Figures_manipulative/'};

c.directoy_DataSet_Infant = '/Users/joanna/Analysis/Vocalisations/DataSet/';

c.fs = 60; % Hz
c.selected_body_parts = {
    'infantleftarm';
    'infantleftleg';
    'infantrightarm';
    'infantrightleg';
    'infanttrunkmid';
    'infanthead'; 
    'infanttrunkleft';
    'parentlefthand';
    'parentrighthand'}';

c.selected_body_parts_short = {
    'infantleftarm';
    'infantleftleg';
    'infantrightarm';
    'infantrightleg';
    'infanttrunkmid';
    'infanthead'; 
    'infanttrunkleft';
    'parentlefthand';};
% 'infanttrunkmid''infanthead'; 'infanttrunkleft';
%  'parenthead';
%  'parentlefthand';
%  'parentrighthand';
%  'parenttrunkleft';
%  'parenttrunkmid'}

c.from_to = [-1, 1];
end
