%#codegen
% This function conforms to the rules for functions which are arguments to
% ode45.  The first argument is a scalar time value, and the second is a
% column vector of the starting values for the odes.  The return value is a
% column vector of the first derivatives of those values at the given time.
% 
% In order to keep things readable, the input vector will be broken into
% familiar variable names inside the function.  A good compiler will be
% able to remove the associated overhead, or if the result is slow the code
% can be rewritten after it is trusted.
%
% The docs recommend interpolating any time-dependent input values in the
% function.  tMonths is a zero-based array of months for finding values in
% any required array.
function [dydt] = odeFunction(t, startVals, tMonths, ...
                            temp, C_seed, S_seed, con, ri, gVec)
                       
    persistent polyT;
    persistent polyRI;  
    persistent polyG;
    Sn    = con.Sn;
    Cn    = con.Cn;
    KSx   = con.KSx;
    G     = con.G;
    KS    = con.KS;
    KC    = con.KC;
    A     = con.A;
    Mu    = con.Mu;
    um    = con.um;
    a     = con.a;
    b     = con.b;
    %%
    cols = Sn*Cn;
    Sold = startVals(1:cols)';
    Cold = startVals(cols+1:cols*2)';
    
    % This an make the result function discontinuous, but if the last iterationsent C negative, it
    % must be set back to the seed level.
    Cold = max(Cold, repmat(C_seed, 1, 2));

    assert(length(Sold) == Sn*Cn, 'There should be one symbiont entry for each coral type * each symbiont type.');
    assert(length(Cold) == Sn*Cn, 'There should be one coral entry for each coral type * each symbiont type.');
    
    %%
    Sm = sum(Sold(1:2:end));  % Sum symbionts in massives
    Sb = sum(Sold(2:2:end));  % Sum symbionts in branching
    SA = [Sm Sb];
    % SAx = Sold(1, :);  % replaced 1/30/2017 with line below
    SAx = repmat(SA, 1, 2);
    
    C1 = [Cold(2) Cold(1)];   % [branch mass]
    C2 = [Cold(1) Cold(2)];   % [mass branch]
    
    % Start getting interpolated values not needed in the original RK
    % approach.
    if isempty(polyT)
        disp('a');
        polyT = interp1(tMonths, temp, 'pchip', 'pp');
    end
    %T = interp1(tMonths, temp, t, 'pchip');
    T = ppval(polyT, t);
    rm  = a*exp(b*T);  % Faster than interpolating already-made values!
    %rm = interp1q(tMonths, rmVec, t);
    % G is a pair of values for massive and branching.
    if isempty(polyG)
        polyG = interp1(tMonths, gVec, 'pchip', 'pp');
    end
    G = ppval(polyG, t)';
    % ri is four values
    if isempty(polyRI)
        polyRI = interp1(tMonths, ri, 'pchip', 'pp');
    end
    %riNow = interp1(tMonths, ri, t, 'pchip');
    riNow = ppval(polyRI, t)';

    % Baskett 2009 equations 4 and 5.  k1 indicates the derivative at t sub i
    dSdT = Sold ./ (KSx .* Cold) .* (riNow .* KSx .* Cold - rm .* SAx ) ;  %Change in symbiont pops %OK
    dCdT = (C2 .* (G .* SA./ (KS .* C2).* (KC-A .* C1-C2)./KC - Mu ./(1+um .* SA./(KS .* C2))) ); %Change in coral pops %OK
    
    % We can't set a seed value rigidly, but we can refuse to drop if below
    % the seed.
    % Treat dS as zero when less than zero and old value is below seed.
    flag = dSdT > 0 | Sold-S_seed > 0;
    dSdT = dSdT .* flag; % .* max(0, sign(Sold-S_seed)); % max part is one when above seed, zero otherwise
    flag = dCdT > 0 | Cold(1:Cn)-C_seed > 0;
    dCdT = dCdT .* flag; % repmat(dCdT, 1, Sn) .* max(0, sign(Cold-repmat(C_seed, 1, Sn))); % max part is one when above seed, zero otherwise
    dCdT = repmat(dCdT, 1, Sn);
    
    dydt = [dSdT dCdT]';

end