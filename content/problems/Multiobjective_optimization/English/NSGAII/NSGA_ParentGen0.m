% Creates an initial random (parent) generation.
%
% ARGUMENTS
%
% nmbOfIndivs - number of individuals composing the generation
% RandParams - parameters for the random initialization of the individuals.
%   MxN array where M = number of decision variables and N = 3 or 4.
%   Value in 1st column determines the type of random initialization for the
%   respective decision variable: 1 => uniform distribution within the
%   given range (2nd & 3rd columns); 2 => normal distribution with given mean
%   and standard deviation (2nd & 3rd columns); 3 => polynomial distribution
%   (the same used for mutation) with given mean, spread and maximum magnitude
%   (2nd, 3rd & 4th columns)
% Ranges - permissible range for each decision variable
%   MxN array where M = number of decision variables and N = 2 (1st column =
%   lower bound, 2nd column = upper bound).
%   something like [-inf inf] is allowed and means that there are no
%   constraints on the respective decision variable
%
% RETURN VALUES
%
% ParGen0 - the (random) initial (parent) generation.
%   MxN array where M = number of decision variables and N = nmbOfIndivs
%
% Modified by G. Robin - 28/09/2004
%   - Renamed Cons as Ranges
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

function ParGen0 = NSGA_ParentGen0( nmbOfIndivs, RandParams, Ranges)

if rem( nmbOfIndivs, 2) ~= 0
    warning( 'Number of individuals is ODD ?!');
end

[nmbOfVars foo] = size( RandParams);
ParGen0 = zeros( nmbOfVars, nmbOfIndivs);
for i = 1:nmbOfVars
    switch RandParams( i, 1)
        case 1
            fprintf( 'NSGA_ParentGen0: variable %d; uniform distribution in [%g, %g]\n', i, RandParams( i, 2), RandParams( i, 3));
            % uniformly distributed in the interval [RandParams(i,1) RandParams(i,2)]
            ParGen0( i, :) = RandParams( i, 2) + ...
                (RandParams( i, 3) - RandParams( i, 2)) * rand( 1, nmbOfIndivs);
        case 2
            fprintf( 'NSGA_ParentGen0: variable %d; normal distribution: mean %g, std dev %g\n', i, RandParams( i, 2), RandParams( i, 3));
            % normally distributed w/ mean RandParams(i,1) & standard deviation RandParams(i,2)
            ParGen0( i, :) = ...
                RandParams( i, 2) + RandParams( i, 3) * randn( 1, nmbOfIndivs);
            ParGen0( i, :) = min( Ranges( i, 2), ParGen0( i, :)); %Patch Gael
            ParGen0( i, :) = max( Ranges( i, 1), ParGen0( i, :)); %Patch Gael
        case 3
            fprintf( 'NSGA_ParentGen0: variable %d; polynomial mutation: mean %g, spread %d, max size %g\n', i, RandParams( i, 2), RandParams( i, 4), RandParams( i, 3));
            % polynomial mutation of RandParams(i,1) w/ max. magnitude RandParams(i,2) and
            % spread RandParams(i,3)
            Temp = NSGA_Mutate( repmat( RandParams( :, 2), 1, nmbOfIndivs), ...
                Ranges, 1, RandParams( i, 4), RandParams( i, 3));
            ParGen0( i, :) = Temp( i, :);
    end
end
