classdef Reef < handle
    %Reef One coral reef cell.
    %   Everything which defines a reef in the model, from its location and 
    %   climate to living objects.
    
    properties
        id;                 % Integer id for sending larval data between reefs.
        name;               % For convenient reference and plotting.
        SST;                % Monthly sea surface temperature,°C 
        corals = Coral.empty  % Coral objects, one per population
        lat;                % This reef's latitude
        lon;                % This reef's longitude
        connect;            % Connectivity values from this reef to all others
        sharedConstants;    % Biological parameters
        coralConstants;     % List of constants for each coral in order
        world;              % The world this reef lives in
    end

    
    methods (Static)
        [ri] = nonODEIterativeInputsSimplified(sst, gi0, SelVx, sharedConstants, nc);
    end
    
    methods
        function obj = Reef(world, id, name, location, sst, connectivity, ...
                con)
            %Reef Construct an instance of this class
            %   world is the containing World object, so we can call back to its
            %       other reefs
            %   id is a label, and corresponds to this reef's location
            %       in the connectivity vector
            %   location is the longitude and latitude (in that order) for
            %       this reef.
            %   sst defines the SST over time, one value per month
            %   connectivity lists a connectivity weight from this reef to all
            %       reefs
            %   startYear is the year the model starts, to initialize the time
            %       variable
            obj.world = world;
            obj.id = id;
            obj.name = name;
            obj.lat = location(2);
            obj.lon = location(1);
            obj.SST = sst;
            obj.connect = connectivity;
            obj.sharedConstants = con;   
        end
        
        %% Method signatures for those found in separate files
        [dydt] = coralODE(obj, t, startVals, tMonths, temp, con, ri)
        
        %%  Methods defined here
                
        function addCoral(obj, coral, initMonths)
            %ADDCORAL Add one coral object to this reef
            %  The coral should arrive already defined with
            % its population size, associated symbionts, etc.
            obj.corals(end+1) = coral;
            if length(obj.corals) == 1
                obj.coralConstants = coral.con;
            else
                % XXX Be sure this is correct each time there is a change due
                % to new ecotypes or age promotion.  There is just one distinct
                % set of values per ecotype, but the solver needs one copy per
                % population.
                obj.appendConstants();
            end
            
            % HUGE simplification: in the full model psw2 is a function of
            % historical temperature at each reef.  Parameters of that function
            % are chosen to tune the model to each climate scenario.  Here, all
            % of that is replaced by a constant.  Typical values range from 0.35
            % to 1.35.
            %psw2 = 0.85;
            % But the curves match the big model pretty loosely. Try with
            % matching values for RCP 6.0, E=0.  This is column 25 in the 
            % psw2_new matrix.
            psw2_E0_60 = [0.802, 0.464, 1.189];
            psw2 = psw2_E0_60(obj.id);

            % Selectional variance reflects the expected genetic variation
            selV = 1.25*psw2*var(obj.SST(1:initMonths));
            % gi is the initial optimal temperature for this reef
            gi = mean(obj.SST(1:initMonths));
            % Second HUGE simplification.  In the full model this would be
            % a good place to estimate historical genetic variance and pass
            % that to each coral symbiont.  I'll assume here that the only
            % genetic variation is that due to larval transport.
            coral.setGenotype(0, gi, selV);
        end
              
        function stepOneYear(obj, startMonth)
            %STEPONEYEAR Moves the reef one year forward in time.
            %  This has two main parts.  First, the differential equations
            %  are integrated for one year.  Second, packets of larvae are
            %  exchanged between reefs according to the connectivity array.
            %  Note that this does not take into account spawning seasonality
            %  and how that might change north and south of the equator.  It
            %  simply assumes that larvae are produced and transported at some
            %  time during each year.

            % The number of corals is variable.  Combine their various growth
            % constants into one structure.
              
                
            % XXX assume just one coral with one symbiont.
            %{
            coral = obj.corals(1);
            sym = coral.sym;
            inVar = [sym.pop coral.pop]';
            %}
            nc = length(obj.corals);
            symList = zeros(1, nc);
            corList = zeros(1, nc);
            giList = zeros(1, nc);
            selVList = zeros(1, nc);
            for i = 1:nc
                c = obj.corals(i);
                s = c.sym;
                corList(i) = c.pop;
                symList(i) = s.pop;
                giList(i) = s.gi;
                selVList(i) = s.selV;
            end
            inVar = [symList corList];
            
            % Work with just the SST subset for this year.
            subSST = obj.SST(startMonth:min(startMonth+12, end));
            % Time dependent arguments which are not dependent on the ODEs
            % within this year, but note that it does change when the genotype
            % changes.
            ri = obj.nonODEIterativeInputsSimplified(subSST, giList, selVList, ...
                obj.sharedConstants, nc);
    
            % The ODE function has persistent variables containing some
            % interpolation information.  It must start fresh for each ode45
            % call, because the input to the interpolation changes.
            % This may cause a slight delay as the function is re-parsed, but
            % it's easier than having a special flag for clearing those
            % variables.
            obj.multiCoralODE();
            
            % Stack growth-related constants for the current set of corals.
            obj.appendConstants();
            
            % Note that obj.SST and ri must be arrays of values spaced 1 month
            % apart, and must start with a value matching t=startMonth at the
            % first index.  They need to span the time of this ode45 call.
            opts = odeset('RelTol',1e-3);  % 1e-3 is the default error target
            [t, yOut] = ode45(@(t, y) ...
                obj.multiCoralODE(t, y, 12, subSST, ...
                obj.sharedConstants, obj.coralConstants, ri), ...
                [startMonth startMonth+12], inVar, opts);
            
            % Unpack the populations from yOut
            for i = 1:nc
                c = obj.corals(i);
                c.setPop(t(end), yOut(end, nc + i));
                c.sym.setPop(t(end), yOut(end, i ));
            end
            % TODO: be sure the object is updated here, not a copy!
        end
        
        function spawn(obj, monthTime)
            %SPAWN All corals spawn and send larvae to connected reefs.
            %  A possibly useful function:
            %  findobj(w.reefs, "id", 2)
            %  for example, returns the reef with id 2
            % Note that "i" is the ID of the reef to which the new larvae
            % will be sent.
            %fprintf("Reef %d is spawning. Coral P = %f\n", obj.id, ...
            %    obj.corals(1).pop);
            for i = 1:length(obj.connect)
                weight = obj.connect(i);
                if weight > 0 && obj.id ~= i
                    for j = 1:length(obj.corals)
                        c = obj.corals(j);
                        % Spawn on this reef
                        %fprintf("Spawning from (copySubset)");
                        %c.print(0, 0);
                        if c.ageClass.spawns
                            sp = c.copySubset(monthTime, weight);
                            % Find the target reef and start recruitment there.
                            targetReef = findobj(obj.world.reefs, "id", i);
                            targetReef.recruit(monthTime, sp);
                        end
                    end     
                end
            end
        end

        function recruit(obj, monthTime, arrivals)
            %RECRUIT Take an arriving larval group and allow them to recruit.
            % This assumes that only incoming larvae which land on unoccupied
            % substrate (based on K and the existing population) can recruit.  
            % The recruits become a new population of coral.

            % Reduce arrivals by fractional recruitment.
            coverage = 0;
            for i = 1:length(obj.corals)
                c = obj.corals(i);
                coverage = coverage + c.pop/c.K;
            end
            coverage = min(1.0, coverage);
            substrate = 1.0 - coverage;
            % Population is a sum
            arrivals.scalePopulation(substrate);
            
            
            % Move older corals to their new age classes.
            obj.promoteAgeClasses(monthTime);

            % The arrivals become the new 1st-year class.
            arrivals.ageClass = AgeClass.First;
            obj.corals(end+1) = arrivals;

            %fprintf("Reef %d now has %d corals.\n", obj.id, length(obj.corals));
        end
        
        function print(obj, verbose, levels)
        %PRINT Print information about this Reef.
        %
        % If verbose is false, just the population and carrying capacity.
        % If true, also the growth-related constants.  Note that this is
        % partially redundant with the output Matlab gives by just typing the
        % variable name.
        % levels > 0 tells the method to recursively print constained
        % objects to that depth.       
            fprintf("%s %s %d at %6.2f, %6.2f has %d corals.\n", ...
                obj.name, class(obj), obj.id, obj.lat, obj.lon, ...
                length(obj.corals));
            if verbose
                disp(obj.sharedConstants);
                fprintf("Connectivity: ");
                fprintf("%f ", obj.connect);
                fprintf("\n");
            end
            if levels
                for c = 1:length(obj.corals)
                    obj.corals(c).print(verbose, levels-1);
                end
            end
        end
    end
    methods (Access=private)
        function appendConstants(obj)
        %APPENDCONSTANTS Append all coral constants into a single structure for
        %use in the ODE solution.
            obj.coralConstants = obj.corals(1).con;
            if length(obj.corals) > 1
                for i = 2:length(obj.corals)
                    c = obj.corals(i).con;
                    fields = fieldnames(obj.coralConstants);
                    for j = 1:length(fields)
                        fieldName = fields{j};
                        obj.coralConstants.(fieldName)(end+1) = ...
                                         c.(fieldName);
                    end
                end
            end
        end
        
        function promoteAgeClasses(obj, monthTime)
        % PROMOTEAGECLASSES Combine the population and genotypes of some age
        % classes.
        
        % Assumptions: 
        % 1) There may be more than one ecotype, each treated separately.
        % 2) Within an ecotype, age classes are listed oldest first.
        % 3) Existing age classes cover 1 to infinite (indicated by NaN) ages
        % without gaps.
        % 4) Not all classes are in the list at all times.
        
            % Start by separating out the ecotypes and sending them to 
            % a separate function.
            workingSet = obj.corals;
            obj.corals = [];
            while ~isempty(workingSet)
                eType = workingSet(1).ecotype;
                typeSet = findobj(workingSet, 'ecotype', eType);
                workingSet = findobj(workingSet, '-not', 'ecotype', eType);
                % fprintf("Reef %d promoting %d corals, %d saved for next pass.\n", ...
                %    obj.id, length(typeSet), length(workingSet));
                obj.corals = [obj.corals obj.promoteSet(monthTime, typeSet)];
            end
        end
        
        function set = promoteSet(obj, monthTime, set)
        %PROMOTESET Promotes corals of a single ecotype among age classes.
            
            % There are several types of promotion.
            % 1) Two sets are adjacent.
            %    a) All of the younger set moves into the elder.
            %    b) Some of the younger set moves.
            % 2) There is a missing age class between sets.
            %    a) All of the younger set becomes the missing class.
            %    b) Part of the younger set becomes the missing class.
            
            if isempty(set); return; end
            % Work from the top of the set when done return it as "corals"
            workOn = 1;
            while workOn <= length(set)
                c = set(workOn);
                if workOn == 1 
                    if ~AgeClass.isTerminal(c.ageClass)
                        % This is the top of the list, but not a terminal
                        % population, so a new one will be prepended.
                        [y, e] = obj.promoteOne(monthTime, c, NaN);
                        set = [e, y, set(2:end)];
                        workOn = 3;
                    else
                        workOn = 2;
                    end
                else
                    elder = set(workOn-1);
                    % Look back to see whether our promotions will merge into an
                    % older class or form a new one.
                    if AgeClass.next(c.ageClass) == elder.ageClass
                        % There is an immediately older class.
                        [y, e] = obj.promoteOne(monthTime, c, elder);
                        % But the young class may or may not persist.
                        if isempty(y)
                            set(workOn-1) = e;
                            if workOn < length(set)
                                set = [set(1:workOn-1), set(workOn+1:end)];
                            else
                                set = set(1:workOn-1);
                            end
                        else
                            set(workOn) = y;
                            set(workOn-1) = e;
                        end
                        workOn = workOn + 1;
                    else
                        % There is a gap.  Create a new elder rather than
                        % modifying the one above.                        
                        [y, e] = obj.promoteOne(monthTime, c, NaN);
                        if isempty(y)
                            % Younger class had just one year so it no longer
                            % exists and can be replaced.

                            set(workOn) = e;
                        else
                            % Younger and (new) older class both exist.
                            if length(set) > workOn
                                set = [set(1:workOn-1), e, y, set(workOn+1:end)];
                            else
                                set = [set(1:workOn-1), e, y];
                            end
                        end
                        workOn = workOn + 1;
                    end
                end
            end

        end
        
        function [younger, elder] = promoteOne(~, monthTime, younger, elder)
            %PROMOTEONE Promote one age class to another
            %
            % If the younger class spans more than one year, promote only a
            % fraction to the older class.  Otherwise move everything up and
            % delete the younger age class.
            frac = 1/younger.ageClass.span;

            % If there's no older population, create a new one.
            if ~isa(elder, "Coral")

                elder = younger.copySubset(monthTime, frac);
                fprintf("No elder, copied age is %s\n", elder.ageClass);
                elder.nextAgeClass();
                fprintf("No elder, promoted age is %s\n", elder.ageClass);

            else
                % Add from the young population to the elder.
                oldPop = elder.pop;
                frac = 1/younger.ageClass.span;
                youngPop = younger.pop * frac;
                elder.setPop(monthTime, oldPop + youngPop);
                % Genotype (thermal tolerance is a weighted average.  Don't assign
                % it yet because old values are used in the variance calculation.
                % newGi is the value for the incoming population, gi for the new
                % combined population.
                % Change "pop" values to use symbionts, which are not exactly
                % proportional to coral hosts.
                oldPop = elder.sym.pop;
                youngPop = younger.sym.pop * frac;
                elder.sym.setPop(monthTime, oldPop + youngPop);
                oldGi = elder.sym.gi;
                youngGi = younger.sym.gi;
                %fprintf("merging gi values at year %d.\n", monthTime/12);
                gi = (oldGi * oldPop + youngGi * youngPop) / (oldPop + youngPop);                
                %fprintf("merging gi values %f and %f to %f at year %d.\n", youngGi, oldGi, gi, monthTime/12);

                % Variance is a more complicated combination which increases
                % when the two gi values are farther apart.
                % https://www.emathzone.com/tutorials/basic-statistics/combined-variance.html
                oldVar = elder.sym.selV;
                youngVar = younger.sym.selV;
                v = (oldPop*(oldVar + (oldGi - gi)^2) ...
                    + youngPop*(youngVar + (youngGi - gi)^2)) ...
                    / (oldPop + youngPop);
                elder.setGenotype(monthTime, gi, v);
            end
            if younger.ageClass.span > 1
                younger.scalePopulation(1.0 - frac);
            else
                younger = [];
            end
        end
    end
end

