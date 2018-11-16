clear pax paxRight figHandles P fh figHandles ymax
i = 0;
for treat = ["0", "0.1", "1", "10"]
    for r = [3 1 2]
        i = i + 1;
        names{i} = strcat("R", num2str(r), "C", treat);
    end
end

titles = { ...
    'Ulithi', ...
    'Philippines', ...
    'Ryukyu'
    };
rowLabels = {'None', 'x 0.1', 'x 1', 'x 10'};
for i = 1:length(names)
    n = names{i};
    p1 = open(strcat(n,'.fig'));
    gca
    yyaxis right;
    pax(i) = gca;
    figHandles(i) = p1;
end

fh = figure('color', 'w');
mainax = gca;
%set(gcf,...
%    'OuterPosition',[11 1 1920 1440]);
set(gcf, 'Units', 'inches', 'Position', [15, 0.1, 17, 14]);

% Subplot arguments are rows, columns, counter by rows first
for i = 1:length(names)
    P = subplot(4,3,i);
    pSave(i) = P;
    axes(P);
    gca
    yyaxis right
    copyobj(get(pax(i),'children'), P);
    xlim([1850 2100]);
    ylim([0 2*10^14]);


    %n = strrep(names{i}, '_', ' ');
    if i <= 3
        title(titles{i});
    end
    if ~mod(i-1, 3)
        %ylabel('Coral cm^2');
        idx = 1+(i-1)/3;
        ylabel('dummy');
        ylabel(rowLabels{idx});
    end
    %if i <= 9
    %    set(gca, 'XTick', []);
    %end
    set(P,'FontSize',22);
    %close(figHandles(i));
end

for i = 1:length(names)
    close(figHandles(i));
end

% Open again to get the left side.
for i = 1:length(names)
    n = names{i};
    p1 = open(strcat(n,'.fig'));
    gca
    yyaxis left;
    pax(i) = gca;
    figHandles(i) = p1;
end

for i = 1:length(names)
    P = pSave(i);
    axes(P);
    gca
    yyaxis left;
    copyobj(get(pax(i),'children'), P);

    xlim([1850 2100]);
    ylim([0 8*10^7]);
    %n = strrep(names{i}, '_', ' ');
    if i <= 3
        title(titles{i});
    end
    if ~mod(i-1, 3)
        ylabel('Coral cm^2');
        idx = 1+(i-1)/3;
        %ylabel(rowLabels{idx});
        th = text(1770, 0, rowLabels{idx});
        set(th,'Rotation',90)
        set(th,'FontSize',18)
    end
    %if i <= 9
    %    set(gca, 'XTick', []);
    %end
    set(gca,'FontSize',22);
end

for i = 1:length(names)
    close(figHandles(i));
end

%{
leg = legend('show');
set(leg,...
    'Position',[0.858 0.489 0.140 0.162],...
    'FontSize',18);
%}

% Side label
axes(pSave(7));
gca
th = text(1750, 6*10^7, 'Connectivity Factor');
set(th,'Rotation',90)
set(th,'FontSize',20)
