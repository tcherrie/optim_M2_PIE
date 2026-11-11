% Selection via binary tournaments of pairs of parent individuals 
% that can be used to create offspring via, e.g., the SBX crossover operator.
%
% ARGUMENTS
%
% Ranking - the rank for each individual (see NSGA_Rank.m)
% nmbOfPairs - desired number of pairs of parents
%
% RETURN VALUES
%
% Pars - the pair of parents for each prospective child individual
%   Mx2 array where M = number of individuals; contains indices into 'Ranking' 
%   and thus, indices into the underlying generation
% Tourn - the actual pairing of individuals during the tournaments
%   2xN array where N = 2 * nmbOfPairs
%
% This file is part of the modified version by G. Robin - 28/09/2004
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
    
function [Pars, Tourn] = NSGA_Tournament( Ranking, nmbOfPairs)

nmbOfIndivs = length( Ranking);
% indices of all pairs of identical individuals
DiagIdx = 1:(nmbOfIndivs + 1):nmbOfIndivs^2;
% indices of all pairs of distinct individuals
OffDiagIdx = setdiff( 1:nmbOfIndivs^2, DiagIdx);
% random permutation of all pairs of distinct individuals
RandPerm = randperm( length( OffDiagIdx));
% initialization of competing pairs
Tourn = zeros( 2, 2 * nmbOfPairs);
% randomly select 2 * nmbOfPairs competing pairs of distinct individuals from pool
[Tourn( 1, :) Tourn( 2, :)] = ind2sub( ...
  [nmbOfIndivs nmbOfIndivs], OffDiagIdx( RandPerm( 1:(2 * nmbOfPairs))));
% let paired individuals compete; individual w/ lower rank wins
FirstRowWins = Ranking( Tourn( 1, :)) < Ranking( Tourn( 2, :));
% pair winners, creating pairs of parent individuals
Pars = reshape( ...
  [Tourn( 1, FirstRowWins) Tourn( 2, ~FirstRowWins)], nmbOfPairs, 2);
