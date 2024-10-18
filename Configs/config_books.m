function [c] = config_books()
% configuration file

c = config_global();
c.task = 'books';
c.parent_directory = '/Users/joanna/Analysis/Lab/books/';
c.directoy_DataSet ='/Users/joanna/Analysis/Vocalisations/DataSet/Books/';
c.directoy_DataMat ='/Users/joanna/Analysis/Vocalisations/DataMat/Books/';
c.directory_DataSetPrePro ='/Users/joanna/Analysis/Vocalisations/DataSetPrePro/Books/';
c.directoy_DataMat_CG ='/Users/joanna/Analysis/Vocalisations/DataMat_CG/Books/';
 c.directoy_DataMatSound_CG ='/Users/joanna/Analysis/Vocalisations/DataMatSound_CG/Books/';
 c.directoy_DataMatSound ='/Users/joanna/Analysis/Vocalisations/DataMatSound/Books/';
c.eb = '_b';
c.directoryFigures = '/Users/joanna/Analysis/Vocalisations/Figures/Books/';


end
