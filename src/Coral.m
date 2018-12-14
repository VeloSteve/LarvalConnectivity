classdef Coral < Population
    %CORAL A coral population
    %   A single population of coral in one location.  It competes against
    %   itself, and possibly against other corals sharing the same substrate
    %   area.
    
    properties
        sym
        ageClass
        ecotype
    end

    methods
        function obj = Coral(t0, startPopFraction, growthParams)
            %CORAL Construct a Coral
            %   This defines a particular coral type on a reef.
            obj@Population(t0, startPopFraction, growthParams.KC, growthParams);
            obj.sym = Symbiont(t0, 0.5, growthParams);
            % Reefs are initialized with adult coral.
            obj.ageClass = AgeClass.Adult;
            obj.ecotype = growthParams.name;
            %fprintf("Instantiating Coral %8s\n", obj.ageClass);
        end
        
        function coral = copySubset(obj, t, fraction)
            %COPYSUBSET Copy the specified fraction of this Coral.
            
            % As with Symbiont, I'm not sure how to use the superclass
            % method directly, so just set everything.
            coral = Coral(t, fraction, obj.con);
            coral.setPop(t, fraction * obj.pop);
            coral.ageClass = obj.ageClass;
            %fprintf("  class immediately changed to %8s in copySubset\n", obj.ageClass);
            coral.sym = obj.sym.copySubset(t, fraction);
        end
            
        function setGenotype(obj, t, gi, selV)
            %SETGENOTYPE Set the optimal temperature and variance for this
            %Coral's Symbionts.
            obj.sym.setGenotype(t, gi, selV);
        end
        
        function scalePopulation(obj, frac)
        % SCALEPOPULATION Scale the population by frac, as when only part of a
        % population recruits.  Assumes that symbionts scale by the same
        % fraction.
            obj.pop = obj.pop * frac;
            obj.sym.pop = obj.sym.pop * frac;
        end
        
        function nextAgeClass(obj)
            obj.ageClass = AgeClass.next(obj.ageClass);
        end
        
        function print(obj, verbose, levels)
        %PRINT Print information about this Coral.
        %
        % If verbose is false, just the population and carrying capacity.
        % If true, also the growth-related constants.  Note that this is
        % partially redundant with the output Matlab gives by just typing the
        % variable name.
        % levels > 0 tells the coral method to recursively print constained
        % symbionts.
            fprintf("%8s %s %s population %7.2e of K = %7.2e (%6.2f pct)\n", ...
                obj.ageClass, obj.ecotype, class(obj), obj.pop, obj.K, ...
                100*obj.pop/obj.K);
            if verbose
                disp(obj.con);
            end
            if levels
                obj.sym.print(verbose, levels-1);
            end
        end
        
    end
end

