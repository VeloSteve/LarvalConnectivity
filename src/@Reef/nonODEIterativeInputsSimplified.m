% Calculate values used in the ODE iterations, but not dependent on them.
function [ri] = nonODEIterativeInputsSimplified(sst, gi0, SelV, con)
    rmVec = con.a*exp(con.b*sst);

    ri = (1- (con.EnvV + (min(0, gi0 - sst)).^2) ./ ...
        (2*SelV)) .* exp(con.b*min(0, sst - gi0)) .* rmVec;
    
end
