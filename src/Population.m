classdef Population < handle
    %POPULATION A population of some organism
    %   A single population in one location.
    
    properties
        con
        K
        pop
        history
    end
    
    methods
        function obj = Population(t0, startPopFraction, K, growthParams)
            %POPULATION Construct a Population
            %   A population has some size and a copy of the model's
            %   biological parameters, but does not represent a particular
            %   type of organism until subclassed.  It includes a population
            %   history.
            if nargin == 0
                % Required for subclassing
                return;
            end
            obj.K = K;
            obj.pop = startPopFraction * K;
            obj.con = growthParams;
            obj.history = [t0, obj.pop];
        end
        
        function setPop(obj, t, pop)
            obj.pop = pop;
            obj.history(end+1, :) = [t, pop];
        end
        
        function pop = copySubset(obj, t, fraction)
            %COPYSUBSET Make a copy of this population, but at a fraction of the
            % current size.
            % MATLAB does not provide a deep copy operation for handle objects,
            % so just create a new population with the required changes.
            newSize = fraction * obj.pop / obj.K;
            pop = Population(t, newSize, obj.K, obj.con);
        end
        
        function print(obj, verbose, ~)
        %PRINT Print information about this Population.
        %
        % If verbose is false, just the population and carrying capacity.
        % If true, also the growth-related constants.  Note that this is
        % partially redundant with the output Matlab gives by just typing the
        % variable name.
            fprintf("Population %7.2e of K = %7.2e\n", obj.pop, obj.K);
            if verbose
                disp(obj.con);
            end
        end
    end
end

