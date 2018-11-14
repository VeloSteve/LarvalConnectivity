classdef Symbiont < Population
    %SYMBIONT A coral population
    %   A single population of coral in one location.  It competes against
    %   itself, and possibly against other corals sharing the same substrate
    %   area.
    
    properties
        gi      % genotype = optimial temperature in C
        selV    % selectional variance (of genotype)
        gHistory % history of the genotype
    end
    
    methods
        function obj = Symbiont(t0, startPop, growthParams)
            %SYMBIONT Construct an instance of Symbiont
            %   Detailed explanation goes here
            obj@Population(t0, startPop, growthParams.KC*growthParams.KS, ...
                growthParams);
        end
        
        function setGenotype(obj, t, gi, selV)
            obj.gi = gi;
            obj.selV = selV;
            obj.gHistory(end+1, :)  = [t, gi, selV];            
        end
        
        function sym = copySubset(obj, t, fraction)
            %COPYSUBSET Copy the specified fraction of this Symbiont.
            
            % Something like this should allow the superclass method to do
            % most of the work, but this isn't quite right because you get
            % a Population object and not a Symbiont.  Just do a complete
            % override.
            % sym = copySubset@Population(obj, t, fraction);  % Superclass method
            sym = Symbiont(t, fraction, obj.con);
            % The population is wrong - base it on the current symbiont.
            sym.history = [];
            sym.setPop(t, obj.pop * fraction);
            sym.gi = obj.gi;
            sym.selV = obj.selV;
        end
    end
end

