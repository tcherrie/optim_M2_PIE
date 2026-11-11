% Creates offspring generation of size equal to the parent generation.
%
% ARGUMENTS
%
% ParGen - parent generation
%   MxN array where M = number of decision variables and N = number of 
%   individuals
% Ranking - the rank for each parent individual
% Ranges - permissible range for each decision variable
%   MxN array where M = number of decision variables and N = 2 (1st column =
%   lower bound, 2nd column = upper bound).
%   something like [-inf inf] is allowed and means that there are no 
%   constraints on the respective decision variable
% pX - crossover probability/fraction (see NSGA_SBX.m)
% etaX - distribution parameter for simulated binary crossover 
%   (SBX; see NSGA_SBX.m)
% pM - mutation probability/fraction (see NSGA_Mutate.m)
% etaM - distribution parameter for polynomial mutation (see NSGA_Mutate.m)
%
% RETURN VALUES
%
% ChildGen - offspring generation
%   MxN array where M = number of decision variables and N = number of 
%   individuals
% Pars - the pair of parents for each child individual (see NSGA_Tournament.m)
%
% Modified by G. Robin - 28/09/2004
%   - Renamed Cons as Ranges
%   - Suppressed maxM argument to match Deb's definition of the mutation
%   algorithm
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
    
function [ChildGen, Pars] = ...
  NSGA_ChildGen( ParGen, Ranking, Ranges, pX, etaX, pM, etaM)

[nmbOfVars nmbOfIndivs] = size( ParGen);
if rem( nmbOfIndivs, 2) ~= 0
  error( 'Number of individuals needs to be even.');
end

% select parent pairs
Pars = NSGA_Tournament( Ranking, floor( nmbOfIndivs / 2));
% create offspring from parents via simulated binary crossover
ChildGen = NSGA_SBX( ParGen, Ranges, Pars, pX, etaX);
ChildGen = NSGA_Mutate( ChildGen, Ranges, pM, etaM);
