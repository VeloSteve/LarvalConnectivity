classdef AgeClass
    %AGECLASS A coral age class
    
    properties
        minYear = 1
        maxYear = 1
        span    = 1
        spawns  = false
    end
    methods
        function c = AgeClass(minY, maxY, years, spawns)
            c.minYear = minY;
            c.maxYear = maxY;
            c.span = years;
            c.spawns = spawns;
        end
    end
    methods (Static)
        function c = next(oldClass)
            switch oldClass
                case 'Adult'
                    c = 'Adult';
                case 'Juvenile'
                    c = 'Adult';
                case 'Second'
                    c = 'Juvenile';
                case 'First'
                    c = 'Second';
                otherwise
                    error("No way to promote unknown age class %s\n", oldClass);
            end
            c = AgeClass(c);
        end
        function t = isTerminal(ac)
            t = ac == 'Adult';
        end
    end
    enumeration
        First    ( 1,    1, 1, false)
        Second   ( 2,    3, 2, false)
        Juvenile ( 4,   10, 7, true)
        Adult    (11, 1000, nan, true)
    end
        

end



