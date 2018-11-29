% Calculate values used in the ODE iterations, but not dependent on them.
function [ri] = nonODEIterativeInputsSimplified(sst, gi0, SelV, con, nc)
    rmVec = con.a*exp(con.b*sst);

    ri(nc, length(sst)) = 0.0;
    for i = 1:nc
        ri(i, :) = (1- (con.EnvV + (min(0, gi0(i) - sst)).^2) ./ ...
            (2*SelV(i))) .* exp(con.b*min(0, sst - gi0(i))) .* rmVec;
    end
end
