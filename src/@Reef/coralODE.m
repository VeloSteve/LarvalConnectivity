function [dydt] = coralODE(obj, t, startVals, tMonths, ...
        temp, con, ri)
    % CORALODE The differential equations for coral and symbiont growth.
    % 
    % This function conforms to the rules for functions which are
    % arguments to ode45.  The first argument is a scalar time value,
    % and the second is a column vector of the starting values for the
    % odes.  The return value is a column vector of the first
    % derivatives of those values at the given time.

    % For readability, the input vector will be broken into familiar
    % variable names inside the function.  A good compiler will be
    % able to remove the associated overhead, or if the result is slow
    % the code can be rewritten after it is trusted.
    %
    % The docs recommend interpolating any time-dependent input values in the
    % function.  tMonths is a zero-based array of months for finding values in
    % any required array.
    %
    % Other inputs:
    % temp - the temperature history for this reef
    % con    - constants
    % ri     - symbiont growth rate, a function of temperature
    % 
    % Simplifications to be reversed for the full model:
    % 1) growth vector with Omega effect (Gvec) is now just the constant G.
    % 2) code assumes there is one seed value per coral or symbiont
    % 3) coral-coral competition is ignored

    % Piecewise polynomials which can be re-used across function calls:
    persistent interpTemp;
    persistent interpRI;
    Sn    = con.Sn; % number of symbionts per coral
    Cn    = con.Cn; % number of coral populations
    % Symbiont-related
    G     = con.G;   % coral growth rates
    KS    = con.KS;  % symbiont carrying capacity
    KC    = con.KC;  % coral carrying capacity
    Mu    = con.Mu;  % coral basal mortality
    um    = con.um;  % symbiont influence on mortality
    a     = con.a;   % symbiont linear growth rate factor
    b     = con.b;   % symbiont growth rate exponent

    % Sn = Cn = 1 for the MS 274 project
    cols = Sn*Cn;
    Sold = startVals(1);
    Cold = startVals(2);

    % In the full model, seeds are calculated outside the loops and 
    % passed in, but this is easy:
    C_seed = KC * 0.001;  % minimum population for each coral
    S_seed = KS * 0.0001; % minimum population for each symbiont

    % This can make the result function discontinuous, but if the last
    % iteration set C negative, it must be set back to the seed level.
    Cold = max(Cold, C_seed);
    Sold = max(Sold, S_seed);

    % When there are multiple symbionts per coral, this will have to
    % change to produce the correct vector of sums.
    symSum = Sold;  % Sum symbionts in massives

    % Start getting interpolated values not needed in the original RK
    % approach.
    if isempty(interpTemp)
        %disp('a');
        interpTemp = griddedInterpolant(t:t+length(temp)-1, temp, 'pchip');
    end
    T = interpTemp(t);
    rm  = a*exp(b*T);  % Faster than interpolating already-made values!
    if isempty(interpRI)
        interpRI = griddedInterpolant(t:t+length(ri)-1, ri, 'pchip');
    end
    riNow = interpRI(t)';

    % Baskett 2009 equations 4 and 5.
    dSdT = Sold ./ (KS .* Cold) .* (riNow .* KS .* Cold - rm .* symSum ) ;
    dCdT = Cold .* (G .* Sold./ (KS .* Cold) * (KC - Cold)/KC - Mu ./(1+um .* Sold./(KS .* Cold)));
    
    % We can't set a seed value rigidly in the output, since it's a
    % derivative, but we can refuse to drop if below the seed.
    % Set negative derivatives to zero if old value is below seed.
    flag = dSdT > 0 | Sold-S_seed > 0;
    dSdT = dSdT .* flag; 
    flag = dCdT > 0 | Cold(1:Cn)-C_seed > 0;
    dCdT = dCdT .* flag;
    dCdT = repmat(dCdT, 1, Sn);

    dydt = [dSdT dCdT]';

end
