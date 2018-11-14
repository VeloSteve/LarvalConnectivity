% Test the speed of loading two variables one at a time with simple syntax
% vs both at once but requiring a complicated renaming syntax.
%
% Result: for small files separate loading is around 40% slower, but for
%   big files it hardly matters.  Not what I would have guessed.  It seems
%   likely (after profiling) that the location data is at the top of the file
%   and 1000x smaller than temperatures, so that doing it separately makes
%   little difference.
climate = 'RCP6.0';
temps = strcat('sst3_', num2str(str2double(extractAfter(climate, 3))*10, 2));

tic
for j = 1:100
    posSST = load('../data/reefData.mat', "latLon3", temps);
    for i = 1:length(latLon3)
        dummy = fake_function(posSST.latLon3(i, :), posSST.(temps)(i, :), 1860);
    end
end
fprintf("Loading both together takes %f seconds.\n", toc);


tic
for j = 1:100
    pos = load('../data/reefData.mat', "latLon3");
    pos = pos.("latLon3");
    ttt = load('../data/reefData.mat', temps);
    ttt = ttt.(temps);
    for i = 1:length(latLon3)
        dummy = fake_function(pos(i, :), ttt(i, :), 1860);
    end
end
fprintf("Loading separately takes %f seconds.\n", toc);


%% repeat for the full-size input file.
tic
temps = "SSTR_2M45_JD";
for j = 1:100
    posSST = load('../../Coral-Model-V12/ClimateData/ESM2M_SSTR_JD.mat', "ESM2M_reefs_JD", temps);
    for i = 1:length(latLon3)
        dummy = fake_function(posSST.ESM2M_reefs_JD(i, :), posSST.(temps)(i, :), 1860);
    end
end
fprintf("Loading both together takes %f seconds.\n", toc);


tic
for j = 1:100
    pos = load('../../Coral-Model-V12/ClimateData/ESM2M_SSTR_JD.mat', "ESM2M_reefs_JD");
    pos = pos.("ESM2M_reefs_JD");
    ttt = load('../../Coral-Model-V12/ClimateData/ESM2M_SSTR_JD.mat', temps);
    ttt = ttt.(temps);
    for i = 1:length(latLon3)
        dummy = fake_function(pos(i, :), ttt(i, :), 1860);
    end
end
fprintf("Loading separately takes %f seconds.\n", toc);


function x = fake_function(a, b, c) 
    x = a(1) + b(1) + c;
end
