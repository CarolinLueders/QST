function makeDelayPlots(type,varargin)
%MAKEDELAYPLOTS Creates plots from a 3-Channel Series

%% Validate and parse input arguments
p = inputParser;
defaultFigurepath = 'figures-fig/';
addParameter(p,'Figurepath',defaultFigurepath,@isstr);
defaultSelectionParameters = struct('Type','fullcircle', ...
    'Position',[2.5 0.5]);
addParameter(p,'SelectionParameters',defaultSelectionParameters,@isstruct);
defaultRecomputeTheta = false;
addParameter(p,'RecomputeTheta',defaultRecomputeTheta,@islogical);
defaultSavePostselection = false;
addParameter(p,'SavePostselection',defaultSavePostselection,@islogical);
defaultSaveTheta = false;
addParameter(p,'SaveTheta',defaultSaveTheta,@islogical);
defaultGetDelay = false;
addParameter(p,'GetDelay',defaultGetDelay,@islogical);
defaultRemoveModulation = false;
addParameter(p,'RemoveModulation',defaultRemoveModulation,@islogical);
defaultRange = 0.3;
addParameter(p,'Range',defaultRange,@isnumeric);
defaultXUnit = 'fs';
addParameter(p,'XUnit',defaultXUnit,@isstr);
parse(p,varargin{:});
c = struct2cell(p.Results);
[figurepath,getDelay,range,recomputeTheta,remMod,saveps, ...
    savetheta,selParams,xUnit] = c{:};

% Constants
pdfpath = 'figures-pdf/';

% make all if nothing is specified
if nargin == 0
    type = 'all';
end

%% Find out what needs to be done
[delayMeanVarX,delayDiscAmpl,movieWigner2D,movieWigner3D, ...
    cleanDelayMeanVarX,cleanDelayDiscAmpl,cleanMovieWigner2D, ...
    cleanMovieWigner3D,pdfs,cleanpdfs] = deal(false);
% User request
switch type
    case 'all'
        delayMeanVarX = true;
        delayDiscAmpl = true;
        delayG2 = true;
        delayN = true;
        movieWigner2D = true;
        movieWigner3D = true;
        pdfs = true;
    case 'plots'
        delayMeanVarX = true;
        delayDiscAmpl = true;
        delayG2 = true;
        delayN = true;
        pdfs = true;
    case 'pdfs'
        pdfs = true;
    case 'cleanall'
        cleanDelayMeanVarX = true;
        cleanDelayDiscAmpl = true;
        cleanMovieWigner2D = true;
        cleanMovieWigner3D = true;
        cleanpdfs = true;
    case 'cleanplots'
        cleanDelayMeanVarX = true;
        cleanDelayDiscAmpl = true;
        cleanpdfs = true;
    case 'cleanpdfs'
        cleanpdfs = true;
end

% Look what is already there
selStr = selParamsToStr(selParams);
if ~isempty(dir([figurepath,'*-DelayMeanVarX-',selStr,'*']))
    delayMeanVarX = false;
end
if ~isempty(dir([figurepath,'*-DelayDiscAmpl-',selStr,'*']))
    delayDiscAmpl = false;
end
if ~isempty(dir([figurepath,'*-WignerMovie3D-',selStr,'*']))
    movieWigner3D = false;
end
if ~isempty(dir([figurepath,'*-WignerMovie2D-',selStr,'*']))
    movieWigner2D = false;
end

% Find dependencies that need to be created
[makeTable] = deal(false);
if isempty(seriesRead3ChTable(selParams))
    makeTable = true;
end

%% Make
dispstat('','init','timestamp','keepthis',0);
datestring = datestr(date,'yyyy-mm-dd');
if makeTable
    dispstat('Making 3-channel table ...','timestamp','keepthis');
    T = series3Ch('SelectionParameters',selParams,'RecomputeTheta',recomputeTheta,'Range',range,...
        'SavePostselection',saveps,'SaveTheta',savetheta,'GetDelay',getDelay,'RemoveModulation',remMod);    
else
    T = seriesRead3ChTable(selParams);
end
if ~exist('figures-fig','dir')
    mkdir('figures-fig');
end
if ~exist('figures-pdf','dir')
    mkdir('figures-pdf')
end
if delayMeanVarX
    dispstat('Making DelayMeanVarX plot ...','timestamp','keepthis');
    filenameFig = [figurepath,datestring,'-DelayMeanVarX-',selStr,'.fig'];
    plotSeries3Ch(T,'Type','DelayMeanVarX','Filename',filenameFig,'XUnit',xUnit);
end
if delayDiscAmpl
    dispstat('Making DelayDiscAmpl plot ...','timestamp','keepthis');
    plotSeries3Ch(T,'Type','DelayDiscAmpl','Filename', ...
        [figurepath,datestring,'-DelayDiscAmpl-',selStr,'.fig'],'XUnit',xUnit);
end
if delayG2
    dispstat('Making DelayG2 plot ...','timestamp','keepthis');
    plotSeries3Ch(T,'Type','g2','Filename', ...
        [figurepath,datestring,'-DelayG2-',selStr,'.fig'],'XUnit',xUnit);
end
if delayN
    dispstat('Making DelayN plot ...','timestamp','keepthis');
    plotSeries3Ch(T,'Type','meanN','Filename', ...
        [figurepath,datestring,'-DelayN-',selStr,'.fig'],'XUnit',xUnit);    
end
if movieWigner2D || movieWigner3D
    dispstat('Making Wigner functions ...','timestamp','keepthis');
    series3Ch('SaveWigner',true,'SelectionParameters',selParams);
end
if movieWigner2D && movieWigner3D
    dispstat('Making 2D & 3D Wigner movies ...','timestamp','keepthis');
    seriesWignerMovie('Narrow',true);
elseif movieWigner2D
    dispstat('Making 2D Wigner movie ...','timestamp','keepthis');
    seriesWignerMovie('Dimensions','2D','Narrow',true);
elseif movieWigner3D
    dispstat('Making 3D Wigner movie ...','timestamp','keepthis');
    seriesWignerMovie('Dimensions','3D','Narrow',true);
end
if pdfs
    listOfFigures = dir([figurepath,'*',selStr,'.fig']);
    [~,figNames] = cellfun(@fileparts,{listOfFigures.name}, ...
        'UniformOutput',false);
    listOfPdfs = dir([pdfpath,'*',selStr,'.pdf']);
    [~,pdfNames] = cellfun(@fileparts,{listOfPdfs.name}, ...
        'UniformOutput',false);
    cellfun(@(x) makePdf([figurepath,x,'.fig'],pdfpath), ...
        setdiff(figNames,pdfNames));
end

%% Make clean
if cleanDelayMeanVarX
    listMeanVarX = dir([figurepath,'*-DelayMeanVarX-',selStr,'*']);
    cellfun(@(x) delete([figurepath,x]),{listMeanVarX.name});
end
if cleanDelayDiscAmpl
    listDelayDiscAmpl = dir([figurepath,'*-DelayDiscAmpl-',selStr,'*']);
    cellfun(@(x) delete([figurepath,x]),{listDelayDiscAmpl.name});
end
if cleanMovieWigner2D
    listWignerMovie2D = dir(['*-WignerMovie2D-',selStr,'*']);
    cellfun(@delete,{listWignerMovie2D.name});
end
if cleanMovieWigner3D
    listWignerMovie3D = dir(['*-WignerMovie3D-',selStr,'*']);
    cellfun(@delete,{listWignerMovie3D.name});
end
if cleanpdfs
    listOfPdfs = dir([pdfpath,'*',selStr,'.pdf']);
    cellfun(@(x) delete([pdfpath,x]),{listOfPdfs.name});
end

end

