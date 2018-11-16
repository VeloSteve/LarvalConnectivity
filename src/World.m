classdef World < handle
    %WORLD Everything in the world we will model
    %   This is a container for all the reefs, and a place for functions which
    %   require information from all or many of them.
    
    properties
        reefs = Reef.empty
        startYear;
        endYear;
        nowYear;
        climate;
       
        connectivity =  ...
            [0.80 0.01 0.00; ...
             0.00 0.80 0.00; ...
             0.01 0.00 0.80];
        %{
            [0.80 0.01 0.00; ...
             0.00 0.80 0.01; ...
             0.00 0.00 0.80];  
        %}
    end
    
    methods
        function obj = World(startYear, endYear, historyYear, climate, scale)
            %WORLD Construct an instance of World
            %   All the reefs in the world.
            % startYear and endYear are years, as integers
            % climate is one of RCP2.6, RCP4.5, RCP6.0, RCP8.5
            % indicating a climate scenario from the IPCC AR5 report.
            % scale multiplies the connectivity matrix.
            obj.startYear = startYear;
            obj.endYear = endYear;
            obj.nowYear = startYear;
            obj.climate = climate;
            obj.adjustConnectivity(scale);
            obj.buildReefs(historyYear);
        end
                
        function start(obj)
            %START Begins the passage of time, after setup is complete.
            while obj.nowYear < obj.endYear
                if mod(obj.nowYear, 20) == 0
                    fprintf("Stepping from year %d\n", obj.nowYear);
                end
                startMonth = 1 + 12 * (obj.nowYear - obj.startYear);

                %tic
                for r = obj.reefs
                    r.stepOneYear(startMonth);
                end

                %toc
                obj.nowYear = obj.nowYear + 1;
                % I expected the line below to call spawn() on each reef,
                % but instead it passed the reefs array to the spawn function.
                %obj.reefs.spawn();
                % This works as expected.
                for r = obj.reefs
                    r.spawn(1 + 12 * (obj.nowYear - obj.startYear));
                end

            end
        end
    end
    
    methods (Access=private)
        function adjustConnectivity(obj, mult)
            %ADJUSTCONNECTIVITY Scale all between-reef connectivity values.
            
            if ~isempty(obj.reefs)
                error("Calling adjustConnectivity after reefs are build will not have the intended effect.");
            end
            if mult == 1.0; return; end
            % Save diagonal, scale everything, restore diagonal values.
            diagonal = diag(obj.connectivity);  
            obj.connectivity = obj.connectivity * mult;
            obj.connectivity(1:size(obj.connectivity,1)+1:end) = diagonal;
            disp(obj.connectivity);
        end
        
        function buildReefs(obj, historyYear)
            %BUILDREEFS Instantiate a reef for each location.
            % historyYear is the last year for which we include temperatures
            %   when computing an historical average.
            % convert climate name to a variable name
            temps = strcat('sst3_', num2str(str2double(extractAfter(obj.climate, 3))*10, 2));
            % load to a structure so we can avoid renaming variables.
            posSST = load('../data/reefData.mat', "latLon3", temps);
            reefNames = load('../data/reefData.mat', "names");
            reefNames = reefNames.("names");
            % Get coral biology parameters
            con = load('../data/Coral_Sym_constants.mat', "coralSymConstants");
            con = con.("coralSymConstants");
            for i = 1:length(posSST.latLon3)
                fprintf("Build reef %d\n", i);
                obj.reefs(end+1) = Reef(obj, i, reefNames(i), posSST.latLon3(i, :), ...
                    posSST.(temps)(i, :), obj.connectivity(i, :), con);
            end
            
            % Number of temperature values in the monthly SST array to use
            % for computing historical averages:
            historyMonths = 12 * (1 + historyYear - obj.startYear);
            % Go back to each reef and add a coral population
            % For now, assume that each coral has a single built-in Symbiont
            % population.
            for r = obj.reefs
                r.addCoral(Coral(1.0, 0.8, con), historyMonths);
            end
        end
    end

end

