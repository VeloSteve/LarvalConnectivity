% Larval Connectivity
% This is a model of connectivity between coral reefs.  It will be a highly
% simplified version of something which may be added to the model described in
% Ryan and Logan "A Mechanistic Model of Global Coral Growth and Decay"
% [tentative author list snd title].
%
% Pseudocode:
% set up populations
% set up SST
% step all reefs forward by some time (e.g. 1 year) using ode45
% exchange larvae according to transport matrix
% recruit based on a the mix of local and remote larvae, affected by current SST
% update population genotype to reflect this mix

startYear = 1860;
endYear = 2100;  % XXX normally 2100
historyYear = 2001;
climate = "RCP6.0";  % RCP followed by one of 2.6, 4.5, 6.0, or 8.5
scaleConnectivity = 1.0;

w = World(startYear, endYear, historyYear, climate, scaleConnectivity);
w.start();

reporter = Reporter(w);
reporter.populationPlots();
reporter.populationSumPlots();
reporter.genotypePlots(false);


