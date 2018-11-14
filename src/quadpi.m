function y = quadpi(x)
    %QUADPI Return the derivative of 4*atan(x)

    %   Copyright 2008 The MathWorks, Inc.  [abridged from their code]
    y = 4./(1 + x.^2);
end

