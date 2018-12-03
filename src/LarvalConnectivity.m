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
climate = "RCP6.0";
scaleConnectivity = 0.001;

w = World(startYear, endYear, historyYear, climate, scaleConnectivity);
w.start();

% Plot some results
coralLines = {"-k", "-b", "-g", "-c"};
symLines = {":k", ":b", ":g", ":c"};
reefs = w.reefs;

for k = 1:length(reefs)
    figure(k)
    r = reefs(k);
    clf
    yyaxis left
    labels = {};
    for i = 1:length(r.corals)
        plot(1860 + r.corals(i).history(:, 1)/12, ...
                    r.corals(i).history(:, 2), coralLines{i}) 
        labels{i} = char(r.corals(i).ageClass);
        hold on;
    end
    axis auto

    ylabel('Coral') 

    hold on
    yyaxis right   
    for i = 1:length(r.corals)
        plot(1860+r.corals(i).sym.history(:, 1)/12, ...
                  r.corals(i).sym.history(:, 2), symLines{i})
    end
    ylabel('Symbionts') 
    title(strcat('Reef ', num2str(k), ", ", reefs(k).name));
    legend(labels);
end