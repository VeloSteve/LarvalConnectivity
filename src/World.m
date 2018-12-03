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
       
        % 1 = Philippines, 2 = Ryukyu, 3 = Ulithi
        connectivity =  ...
            [0.80 0.01 0.00; ...
             0.00 0.80 0.00; ...
             0.00 0.00 0.80];
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
            obj.startSerial();
            % obj.startParallel();
        end
        function startSerial(obj)
            %START Begins the passage of time, after setup is complete.
            while obj.nowYear < obj.endYear
                if mod(obj.nowYear, 20) == 0
                    fprintf("Stepping from year %d\n", obj.nowYear);
                end
                startMonth = 1 + 12 * (obj.nowYear - obj.startYear);

                tic
                    % No index needed in serial form:
                    for r = obj.reefs
                        r.stepOneYear(startMonth);
                    end

                toc
                obj.nowYear = obj.nowYear + 1;
                % I expected the line below to call spawn() on each reef,
                % but instead it passed the reefs array to the spawn function.
                %obj.reefs.spawn();
                % This works as expected.
                    fprintf("\nYear %d\n", obj.nowYear);
                    for r = obj.reefs
                        r.spawn(1 + 12 * (obj.nowYear - obj.startYear));
                        %fprintf("Reef %d has %d corals at World level in %d.\n", ...
                        %    r.id, length(r.corals), obj.nowYear);
                        %r.print(0, 1);
                    end

            end % End while
        end
        
        %{
        function startParallel(obj)
            %START Begins the passage of time, after setup is complete.
            while obj.nowYear < obj.endYear
                if mod(obj.nowYear, 20) == 0
                    fprintf("Stepping from year %d\n", obj.nowYear);
                end
                startMonth = 1 + 12 * (obj.nowYear - obj.startYear);

                tic

                    % At least for 3 reefs, this is much slower than
                    % serial. It's probably because of copying the reef
                    % back to the main program each time - can they
                    % stay on the workers until the end?
                    rrr = obj.reefs;
                    parfor i = 1:length(rrr)
                        r = rrr(i);
                        r.stepOneYear(startMonth);

                    end
                
                toc
                obj.nowYear = obj.nowYear + 1;
                % I expected the line below to call spawn() on each reef,
                % but instead it passed the reefs array to the spawn function.
                %obj.reefs.spawn();
                % This works as expected.

                    nY = obj.nowYear;
                    sY = obj.startYear;
                    parfor i = 1:length(rrr)
                        % This is a new copy of the reef being sent,
                        % not the existing one.  WRONG.
                        r = rrr(i);
                        r.spawn(1 + 12 * (nY - sY));
                    end
                
            end % End while
        end
        %}
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
            
            % XXX
            % consider creating a copy of "con" for each coral type, and then
            % pass just that copy to the Coral constructor.  It will contain
            % only relevant values for that coral, so no further indexing is
            % required.
            
            coralType = "Massive";
            conShared = obj.sharedCoralConstants(con);
            % XXX Reef uses some "con" or "conMassive" constants in the ODE, but
            % it's redundant to have them in the corals as well.  What's the
            % best way?
            for i = 1:length(posSST.latLon3)
                fprintf("Build reef %d\n", i);
                obj.reefs(end+1) = Reef(obj, i, reefNames(i), posSST.latLon3(i, :), ...
                    posSST.(temps)(i, :), obj.connectivity(i, :), conShared);
            end
            
            % Number of temperature values in the monthly SST array to use
            % for computing historical averages:
            historyMonths = 12 * (1 + historyYear - obj.startYear);
            % Go back to each reef and add a coral population. For now, assume
            % that each coral has a single built-in Symbiont population.
            conMassive = obj.oneCoralConstants(con, coralType);
            for r = obj.reefs
                r.addCoral(Coral(1.0, 0.8, conMassive), historyMonths);
            end
        end
        
        function c = oneCoralConstants(~, con, ecoType)
            %ONECORALCONSTANTS Gets just the constants applicable for a
            %particular coral type.  Single-valued constants are omitted, and
            %will be a property of the reef rather than the coral.
            
            % Identify the index within constant arrays.
            idx = strfind(con.name, ecoType);  % cell array of indexes, some possibly empty
            idx = find(not(cellfun('isempty',idx))); % just the non-empty values

            if isempty(idx)
                error("Searched for an undefined coral ecotype.");
            elseif length(idx) > 1
                error("Coral ecotype was found more than once.  Bad constant definitions.");
            end
            fields = fieldnames(con);
            for i = 1:length(fields)
                fieldName = fields{i};
                item = con.(fieldName);
                if length(item) == 1
                    % omit c.(fieldName) = item;
                else
                    c.(fieldName) = item(idx);
                end
            end
        end
        
       function c = sharedCoralConstants(~, con)
            %ONECORALCONSTANTS Gets constants which are not specific to coral
            %type.  This assumes that single values may be shared, while those
            %in vector form are coral-specific and should be omitted.
            
            fields = fieldnames(con);
            for i = 1:length(fields)
                fieldName = fields{i};
                item = con.(fieldName);
                if length(item) == 1
                    c.(fieldName) = item;
                end
            end
        end        
    end

end

