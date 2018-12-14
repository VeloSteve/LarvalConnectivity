classdef Reporter
    %REPORTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        world;
    end
    
    methods
        function obj = Reporter(w)
            %REPORTER Construct an instance of this class
            %   Detailed explanation goes here
            obj.world = w;
        end
        
        function populationPlots(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            % Plot some results
            w = obj.world;
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
                ylim([100 1E8]);

                %axis auto

                ylabel('Coral') 

                hold on
                yyaxis right   
                for i = 1:length(r.corals)
                    plot(1860+r.corals(i).sym.history(:, 1)/12, ...
                              r.corals(i).sym.history(:, 2), symLines{i})
                end
                xlabel('Year') 
                ylabel('Symbionts (dotted lines)') 
                set(gca, 'YScale', 'log')
                ylim([100 1E14]);

                title(strcat('Reef ', num2str(k), ", ", reefs(k).name));
                legend(labels, 'Location', 'best');
            end
        end
        
        function populationSumPlots(obj)
            coralLines = {"-k", "-b", "-g", "-c"};
            reefs = obj.world.reefs;
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



                figure(200+k);

                idx = find(pops > 0);
                plot(1860+months(idx)/12, pops(idx), coralLines{1})
                set(gca, 'YScale', 'log')
                ylim([100 1E8]);
                xlabel('Year') 
                ylabel('Coral population') 

                title(strcat('Reef ', num2str(k), ", ", reefs(k).name));

            end
        end
        
        function genotypePlots(obj, showVariance)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            % Plot some results
            symLines = {"-k", "-b", "-g", "-c"};
            selVLines = {":k", ":b", ":g", ":c"};
            reefs = obj.world.reefs;

            maxM = 0;
            for k = 1:length(reefs)
                figure(300+k)
                r = reefs(k);
                clf
                %yyaxis left
                labels = {};
                for i = 1:length(r.corals)
                    h = r.corals(i).sym.gHistory;

                    % There are repeated points.  Average them.
                    uMonths = unique(h(:, 1));
                    gi = 0 * uMonths;
                    selV = gi;
                    for j = 1:length(uMonths)
                        idx = find(h(:,1) == uMonths(j));
                        if ~isempty(idx)
                            gi(j) = sum(h(idx, 2))/length(idx);
                            selV(j) = sum(h(idx, 3))/length(idx);
                        end
                    end
                    maxM = max(maxM, uMonths(end));
                    % Special case for reefs with one coral and no set endpoint.
                    % Make a horizontal line rather than an invisible point.
                    %if length(r.corals) == 1 && length(uMonths) == 1
                    if length(uMonths) == 1
                        uMonths(2) = maxM;
                        selV(2) = selV(1);
                        gi(2) = gi(1);
                    end
                    if showVariance
                        plot(uMonths/12 + 1860, selV, selVLines{i});
                        labels{i*2} = "";
                        hold on;
                        plot(uMonths/12 + 1860, gi, symLines{i});
                        labels{i*2-1} = char(r.corals(i).ageClass);
                    else
                        plot(uMonths/12 + 1860, gi, symLines{i});
                        labels{i} = char(r.corals(i).ageClass);
                        hold on;
                    end

                end
                %set(gca, 'YScale', 'log')
                if ~showVariance
                    ylim([24 30]);
                end

                %axis auto
                xlabel('Year') 
                ylabel('Symbiont Genotype, °C') 

                title(strcat('Reef ', num2str(k), ", ", reefs(k).name));
                lh = legend(labels); %, 'Location', 'southeast');
                lh.Position = [0.2, 0.3, 0.2, 0.2];
            end
        end
        
    end
end

