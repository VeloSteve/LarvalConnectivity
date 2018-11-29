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
endYear = 1880;  % XXX normally 2100
historyYear = 2001;
climate = "RCP6.0";
scaleConnectivity = 1.0;

w = World(startYear, endYear, historyYear, climate, scaleConnectivity);
w.start();

% Plot some results
coralLines = {"-k", "-b", "-g", "-c"};
reefs = w.reefs;
for r = 1:length(reefs)
    figure(r)
    clf
    yyaxis left
    for i = 1:length(reefs(r).corals)
        plot(1860 + reefs(r).corals(i).history(:, 1)/12, ...
                    reefs(r).corals(i).history(:, 2), coralLines{i}) 
        hold on;
    end
    axis auto

    ylabel('Coral') 

    hold on
    yyaxis right
    plot(1860+reefs(r).corals(1).sym.history(:, 1)/12, ...
              reefs(r).corals(1).sym.history(:, 2), ":k")
    ylabel('Symbionts') 
    title(strcat('Reef ', num2str(r), ", ", reefs(r).name));
end