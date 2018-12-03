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
scaleConnectivity = 0.0001;

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
        h = r.corals(i).history;

        % There are repeated points.  Average them.
        uMonths = unique(h(:, 1));
        pops = 0 * uMonths;
        for j = 1:length(uMonths)
            idx = find(h(:,1) == uMonths(j));
            if ~isempty(idx)
                pops(j) = sum(h(idx, 2))/length(idx);
            end
        end
        plot(1860 + uMonths/12, ...
                    pops, coralLines{i}) 
        labels{i} = char(r.corals(i).ageClass);
        hold on;
    end
    set(gca, 'YScale', 'log')
    ylim([10 1E8]);

    %axis auto

    ylabel('Coral') 

    hold on
    yyaxis right   
    for i = 1:length(r.corals)
        plot(1860+r.corals(i).sym.history(:, 1)/12, ...
                  r.corals(i).sym.history(:, 2), symLines{i})
    end
    ylabel('Symbionts') 
    set(gca, 'YScale', 'log')
    ylim([10 1E14]);

    title(strcat('Reef ', num2str(k), ", ", reefs(k).name));
    legend(labels);
end

% A separate set of plots, using sums.
% We have histories, but they may not start at the same time.

for k = 1:length(reefs)
    maxMonth = 0;
    minMonth = 1000*12;
    c = reefs(k).corals;
    for i = 1:length(c)
        h = c(i).history;
        maxMonth = max(maxMonth, h(end, 1));
        minMonth = min(minMonth, h(1, 1));
    end
    months = [minMonth:maxMonth];
    pops = months * 0;
    for i = 1:length(c)
        h = c(i).history;

        % There are repeated points.  Average them.
        for j = 1:length(months)
            idx = find(h(:,1) == months(j));
            if ~isempty(idx)
                pops(j) = pops(j) + sum(h(idx, 2))/length(idx);
            end
        end

    end
    
    
    
    figure(100+k);

    ylabel('Coral population') 
    idx = find(pops > 0);
    plot(1860+months(idx)/12, pops(idx), coralLines{1})
    set(gca, 'YScale', 'log')
    ylim([10 1E8]);

    title(strcat('Reef ', num2str(k), ", ", reefs(k).name));

end
%}
