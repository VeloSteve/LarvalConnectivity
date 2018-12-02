function [dydt] = multiCoralODE(obj, t, startVals, tMonths, ...
        temp, sharedCon, coralCon, ri)
    % MULTICORALODE The differential equations for coral and symbiont growth and
    % competition.
    % 
    % This function conforms to the rules for functions which are arguments to
    % ode45.  The first argument is a scalar time value, and the second is a
    % column vector of the starting values for the odes.  The return value is a
    % column vector of the first derivatives of those values at the given time.

    % For readability, the input vector will be broken into familiar variable
    % names inside the function.  A good compiler will be able to remove the
    % associated overhead, or if the result is slow the code can be rewritten
    % after it is trusted.
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
    if (nargin == 1)
        clear interpTemp;
        clear interpRI;
        return;
    end

    % Symbiont-related
    G     = coralCon.G;   % coral growth rates
    KS    = coralCon.KS;  % symbiont carrying capacity
    KC    = coralCon.KC;  % coral carrying capacity
    Mu    = coralCon.Mu;  % coral basal mortality
    um    = coralCon.um;  % symbiont influence on mortality
    a     = sharedCon.a;   % symbiont linear growth rate factor
    b     = sharedCon.b;   % symbiont growth rate exponent

    % Sn = Cn for the MS 274 project
    Cn = length(startVals)/2;
    Sn = Cn;
    Sold = startVals(1:Sn)';
    Cold = startVals(Sn+1:end)';

    % In the full model, seeds are calculated outside the loops and 
    % passed in, but this is easy for now:
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
        for i = 1:Cn
            interpRI{i} = griddedInterpolant(t:t+length(ri(i, :))-1, ri(i, :), 'pchip');
        end
    end
    for i = 1:Cn
        riNow(i) = interpRI{i}(i)';
    end

    % Baskett 2009 equations 4 and 5.
    dSdT = Sold ./ (KS .* Cold) .* (riNow .* KS .* Cold - rm .* symSum ) ;
    %              
    
    dCdT = Cold .* (G .* Sold./ (KS .* Cold) .* (KC - Cold) ./KC - Mu ./(1+um .* Sold./(KS .* Cold)));
    %              [    growth                 space comp        mortality, less symbiont effect ]   
    
    % We can't set a seed value rigidly in the output, since it's a
    % derivative, but we can refuse to drop if below the seed.
    % Set negative derivatives to zero if old value is below seed.
    flag = dSdT > 0 | Sold-S_seed > 0;
    dSdT = dSdT .* flag; 
    flag = dCdT > 0 | Cold(1:Cn)-C_seed > 0;
    dCdT = dCdT .* flag;

    dydt = [dSdT dCdT]';

end
