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
        end
        
        function coral = copySubset(obj, t, fraction)
            %COPYSUBSET Copy the specified fraction of this Coral.
            
            % As with Symbiont, I'm not sure how to use the superclass
            % method directly, so just set everything.
            coral = Coral(t, fraction, obj.con);
            coral.setPop(t, fraction * obj.pop);
            coral.ageClass = obj.ageClass;
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
        
        
    end
end

