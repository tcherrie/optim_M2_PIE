% The polynomial mutation operator.
% Assuming an individual is a feasible solution (all decision variables are
% within their respective permissible range), the mutated individual will be
% feasible also. This is achieved by calculating the range of values for the
% random parameter u that guarantees the feasibility of the mutated individual,
% based on the decision variable values of the original individual in relation
% to the constraints for those variables.
%
% ARGUMENTS
%
% Indivs - individuals to be mutated
%   MxN array where M = number of decision variables and N = number of 
%   individuals
% Ranges - permissible range for each decision variable
%   MxN array where M = number of decision variables and N = 2 (1st column =
%   lower bound, 2nd column = upper bound).
%   something like [-inf inf] is allowed and means that there are no 
%   constraints on the respective decision variable
% pM - mutation probability (fraction of `genes', i.e., decision variable 
%   values that will be mutated where the pool of genes is made up of all
%   the individuals)
% etaM - distribution parameter for polynomial mutation (the larger, the 
%   closer will the mutated individual be, on average, to the original 
%   individual)
%
% RETURN VALUES
%
% MIndivs - the mutated individuals
%   MxN array where M = number of decision variables and N = number of 
%   individuals
%
% Modified by G. Robin - 28/09/2004
%   - Renamed Cons as Ranges
%   - Modified algorithm to match Deb's definition
%
% Copyright (C) 2004 Reiner Schulz (rschulz@cs.umd.edu)
% This file is part of the author's Matlab implementation of the NSGA-II
% multi-objective genetic algorithm with simulated binary crossover (SBX)
% and polynomial mutation operators.
%
% The algorithm was developed by Kalyanmoy Deb et al. 
% For details, refer to the following article:
% Deb, K., Pratap, A., Agarwal, S., and Meyarivan, T. 
% A fast and elitist multiobjective genetic algorithm: NSGA-II.
% in IEEE TRANSACTIONS ON EVOLUTIONARY COMPUTATION, vol. 8, pp. 182-197, 2002
%
% This implementation is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This implementation is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with This implementation; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
    
function MIndivs = NSGA_Mutate( Indivs, Ranges, pM, etaM);

[nmbOfVars nmbOfIndivs] = size( Indivs);

% Compute distance to the bounds - used to restrict random parameter range
% to keep mutated individual within the allowed range
UpMinusIndiv = repmat( Ranges( :, 2), 1, nmbOfIndivs) - Indivs;
IndivMinusLow = Indivs - repmat( Ranges( :, 1), 1, nmbOfIndivs);

% randomly chose variables and individuals that undergo mutation
MutVarsIdx = find( rand(size( Indivs)) <= pM);

U = rand( size( Indivs));

FullRange = repmat((Ranges( :, 2) - Ranges( :, 1)),1,nmbOfIndivs);
DeltaLow = IndivMinusLow ./ FullRange ;
DeltaUp = UpMinusIndiv ./ FullRange ;

Delta = zeros(size( Indivs));

Dir = (U >= 0.5);
Delta(Dir) = 1 - [2*(1-U(Dir)) + 2*(U(Dir)-0.5).*(1-DeltaUp(Dir)).^(etaM+1)].^(1/(etaM+1));
Delta(~Dir) = [2*U(~Dir) + (1-2*U(~Dir)).*(1-DeltaLow(~Dir)).^(etaM+1)].^(1/(etaM+1)) - 1;

MIndivs = Indivs;

MIndivs(MutVarsIdx) = Indivs(MutVarsIdx) + Delta(MutVarsIdx).* FullRange(MutVarsIdx);

%Force generated individuals to the allowed ranges - this should not be
%necessary since we have calculated u values to remain within the allowed
%range but it will clear very small rounding errors that could cause
%the objective function to fail
MIndivs = min( repmat( Ranges( :, 2), 1, nmbOfIndivs), MIndivs);
MIndivs = max( repmat( Ranges( :, 1), 1, nmbOfIndivs), MIndivs);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % randomly chose mutation direction; D == 0 (1) => negative (positive)
% Dir = rand( size( Indivs)) > .5;
% % for negative mutations, compute lower bounds for random parameter u
% % zero is the lowest lower bound; .5 is the upper bound
% U_low = max( 0, -bar ./ maxM + 1).^(etaM + 1) / 2;
% % for positive mutations, compute upper bounds for random parameter u
% % one is the maximum upper bound; .5 is the lower bound
% U_up = 1 - max( 0, 1 - foo ./ maxM).^(etaM + 1) / 2;
% % determine values for random parameter u
% U = rand( size( Indivs));
% U( ~Dir) = U_low( ~Dir) + (.5 - U_low( ~Dir)) .* U( ~Dir);
% U( Dir) = .5 + (U_up( Dir) - .5) .* U( Dir);
% % compute perturbance factor delta for negative mutations
% DeltaNeg = (2 * U).^(1/(etaM + 1)) - 1;
% % compute perturbance factor delta for positive mutations
% DeltaPos = 1 - (2 * (1 - U)).^(1/(etaM + 1));
% % combine cases
% Delta = zeros( size( U));
% Delta( ~Dir) = DeltaNeg( ~Dir);
% Delta( Dir) = DeltaPos( Dir);
% % mark `genes' (variables across all individuals) for mutation
% % pM is the (fixed) fraction of genes that are mutated
% M = randperm( prod( size( Indivs)));
% M = M( 1:ceil( pM * length( M)));
% % add perturbance factor times max. allowed mutation size to variables marked for mutation
% MIndivs = Indivs;
% MIndivs( M) = Indivs( M) + maxM * Delta( M);
% 
% %Force generated individuals to the allowed ranges - this should not be
% %necessary since we have calculated u values to remain within the allowed
% %range but it will clear very small rounding errors that could cause
% %the objective function to fail
% MIndivs = min( repmat( Ranges( :, 2), 1, nmbOfIndivs), MIndivs);
% MIndivs = max( repmat( Ranges( :, 1), 1, nmbOfIndivs), MIndivs);
% 
