classdef Reef < handle
    %Reef One coral reef cell.
    %   Everything which defines a reef in the model, from its location and 
    %   climate to living objects.
    
    properties
        id;                 % Integer id for sending larval data between reefs.
        name;               % For convenient reference and plotting.
        SST;                % Monthly sea surface temperature,°C 
        corals = Coral.empty  % Coral objects, one per population
        lat;                % This reefs latitude
        lon;                % This reef's longitude
        connect;            % Connectivity values from this reef to all others
        con;                % Biological parameters
        world;              % The world this reef lives in
    end
    
    methods (Static)
        [ri] = nonODEIterativeInputsSimplified(sst, gi0, SelVx, con);
    end
    
    methods
        function obj = Reef(world, id, name, location, sst, connectivity, con)
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
            obj.con = con;         
        end
        
        %% Method signatures for those found in separate files
        [dydt] = coralODE(obj, t, startVals, tMonths, temp, con, ri)
        
        %%  Methods defined here
                
        function addCoral(obj, coral, initMonths)
            %ADDCORAL Add one coral object to this reef
            %  The coral should arrive already defined with
            % its population size, associated symbionts, etc.
            obj.corals(end+1) = coral;
            
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

            % XXX assume just one coral with one symbiont.
            coral = obj.corals(1);
            sym = coral.sym;
            inVar = [sym.pop coral.pop]';
            
            % Work with just the SST subset for this year.
            subSST = obj.SST(startMonth:min(startMonth+12, end));
            % Time dependent arguments which are not dependent on the ODEs
            % within this year, but note that it does change when the genotype
            % changes.
            gi = sym.gi;
            selV = sym.selV;
            ri = obj.nonODEIterativeInputsSimplified(subSST, gi, selV, obj.con);
    
            % The ODE function has persistent variables containing some
            % interpolation information.  It must start fresh for each ode45
            % call, because the input to the interpolation changes.
            % This may cause a slight delay as the function is re-parsed, but
            % it's easier than having a special flag for clearing those
            % variables.
            obj.coralODE();
            
            % Note that obj.SST and ri must be arrays of values spaced 1 month
            % apart, and must start with a value matching t=startMonth at the
            % first index.  They need to span the time of this ode45 call.
            opts = odeset('RelTol',1e-3);  % 1e-3 is the default error target
            [t, yOut] = ode45(@(t, y) ...
                obj.coralODE(t, y, 12, subSST, ...
                obj.con, ri), ...
                [startMonth startMonth+12], inVar, opts);
            sym.setPop(t(end), yOut(end, 1));
            coral.setPop(t(end), yOut(end, 2));
            % TODO: be sure the object is updated here, not a copy!
        end
        
        function spawn(obj, monthTime)
            %SPAWN All corals spawn and send larvae to connected reefs.
            %  A possibly useful function:
            %  findobj(w.reefs, "id", 2)
            %  for example, returns the reef with id 2
            % Note that "i" is the ID of the reef to which the new larvae
            % will be sent.
            for i = 1:length(obj.connect)
                weight = obj.connect(i);
                if weight > 0 && weight < 0.5
                    for c = obj.corals
                        % Spawn on this reef
                        sp = c.copySubset(monthTime, weight);
                        % Find the target reef and start recruitment there.
                        targetReef = findobj(obj.world.reefs, "id", i);
                        targetReef.recruit(monthTime, sp);
                    end     
                end
            end
        end

        function recruit(obj, monthTime, arrivals)
            %RECRUIT Take an arriving larval group and allow them to recruit.
            % This assumes that only incoming larvae which land on unoccupied
            % substrate (based on K and the existing population) can recruit.  
            % Further, it assumes that the populations can be treated as one
            % with combined properties.  In the future this should be replaced
            % with some sort of age class system.
            
            % For now we have exactly one coral per reef:
            coral = obj.corals(1);
            substrate = 1.0 - coral.pop / coral.K;
            % Population is a sum
            newPop = substrate * arrivals.pop;
            oldPop = coral.pop;
            coral.setPop(monthTime, oldPop + newPop);
            % Genotype (thermal tolerance is a weighted average.  Don't assign
            % it yet because old values are used in the variance calculation.
            % newGi is the value for the incoming population, gi for the new
            % combined population.
            oldGi = coral.sym.gi;
            newGi = arrivals.sym.gi;
            gi = (oldGi * oldPop + newGi * newPop) / (oldPop + newPop);
            % Variance is a more complicated combination which increases
            % when the two gi values are farther apart.
            % https://www.emathzone.com/tutorials/basic-statistics/combined-variance.html
            oldVar = coral.sym.selV;
            newVar = arrivals.sym.selV;
            v = (oldPop*(oldVar + (oldGi - gi)^2) ...
               + newPop*(newVar + (newGi - gi)^2)) ...
                / (oldPop + newPop);
            coral.setGenotype(monthTime, gi, v);
%            coral.sym.gi = gi;
%            coral.sym.selV = v;
        end

    end
end

