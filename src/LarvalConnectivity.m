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
endYear = 2100;
historyYear = 2001;
climate = "RCP6.0";
scaleConnectivity = 0.1;

w = World(startYear, endYear, historyYear, climate, scaleConnectivity);
w.start();

% Plot some results
reefs = w.reefs;
for r = 1:length(reefs)
    figure(r)
    clf
    yyaxis left
    plot(1860 + reefs(r).corals(1).history(:, 1)/12, ...
                reefs(r).corals(1).history(:, 2), "-k")
    ylabel('Coral') 

    hold on
    yyaxis right
    plot(1860+reefs(r).corals(1).sym.history(:, 1)/12, ...
              reefs(r).corals(1).sym.history(:, 2), "-b")
    ylabel('Symbionts') 
    title(strcat('Reef ', num2str(r), ", ", reefs(r).name));
end