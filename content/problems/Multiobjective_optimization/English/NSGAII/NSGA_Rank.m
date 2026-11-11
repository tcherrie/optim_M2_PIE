% Ranks the individuals according to their degree of constraint violation
% (1st sort key), the number of their Pareto-optimal front (2nd sort key)
% and the degree to which they are `crowded' by other individuals
% (3rd sort key).
%
% ARGUMENTS
%
% Indivs - individuals to be ranked
%   MxN array where M = number of decision variables and N = number of
%   individuals
% ObjVals - objective function values for each individuals.
%   MxN array where M = number of objectives and N = number of
%   individuals
% ConstrVals - constraints values for each individuals in the form :
% g_i(x) <= 0
%   MxN array where M = number of constraints and N = number of
%   individuals
%
% RETURN VALUES
%
% Ranking - the rank for each individual
% SumOfViols - sum of constraint violations for each individual (line
% vector)
% NmbOfFront - number of pareto-optimal front for each individual
% CrowdDist - crowding distance for each individuals
%
% all of the above return values are 1D arrays of length = number of
% individuals
%
% Modified by G. Robin - 28/09/2004
%   - Suppressed Bounds and Cons from prototype
%   - Replaced ranges (or Cons) violation, which shouldn't occur due to the
%   coding of crossover and mutation operators, by computed constraints
%   violations measure. Each constraint violation is normalized to the
%   greater violation for the same constraint.
%   - Modified CrowDist calculation to match Deb et al. algorithm : the
%   crowding distance is now computed within each front.
%   - Performance optimization :
%       Replaced cells elements by perallocated arrays (less elegant but
%       more efficient)
%       Changed sorting algorithm to avoid comparing twice every pair of
%       individuals for instance : (1,2) and (2,1)
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

function [Ranking, SumOfViols, NmbOfFront, CrowdDist] = ...
    NSGA_Rank( Indivs, ObjVals, ConstrVals);

[nmbOfVars nmbOfIndivs] = size( Indivs);
[nmbOfObjs foo] = size( ObjVals);

% sum of absolute constraint violations for each individual; highest priority sorting key
%First compute the maximum constraints violation for each constraint in
%order to normalize
ConstrMax=max(ConstrVals,[],2);
%Identify rows corresponding to violated constraints by at least one
%individual
Idx_ViolCstr = find(ConstrMax > 0);
%Set non violated constraints to zero and normalize each violated
%constraints row with respect to its maximum value before summing the lines
%Normalization is obtained by creating a diagonal matrix which diagonal
%holds the inverse of the maximum constraints violations and performing
%matrix product with the rows holding violations amount
SumOfViols = sum( diag(1./ConstrMax(Idx_ViolCstr),0) * max( ConstrVals(Idx_ViolCstr,:) , 0 ),1)';

% Pareto-optimal fronts
Front = zeros(nmbOfIndivs);
FrontSize = zeros( nmbOfIndivs, 1);
% number of Pareto-optimal front for each individual; 2nd highest priority sorting key
NmbOfFront = zeros( nmbOfIndivs, 1);
% set of individuals a particular individual dominates
Dominated = zeros( nmbOfIndivs,nmbOfIndivs-1);
DominatedSize = zeros( nmbOfIndivs, 1);
% number of individuals by which a particular individual is dominated
NmbOfDominating = zeros( nmbOfIndivs, 1);
%Compare all individuals
for p = 1:(nmbOfIndivs-1)
    %Only compare individuals that haven't been already compared (indexes
    %greater than p
    for q = (p+1):nmbOfIndivs

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if SumOfViols(p) < SumOfViols(q)
            Dominated( p , DominatedSize(p)+1 ) = q;
            DominatedSize(p) = DominatedSize(p) + 1;
            NmbOfDominating( q) = NmbOfDominating( q) + 1;
        elseif SumOfViols(p) > SumOfViols(q)
            Dominated( q , DominatedSize(q)+1 ) = p;
            DominatedSize(q) = DominatedSize(q) + 1;
            NmbOfDominating( p) = NmbOfDominating( p) + 1;
        elseif (sum( ObjVals( :, p) <= ObjVals( :, q)) == nmbOfObjs) && ...
                (sum( ObjVals( :, p) < ObjVals( :, q)) > 0)
            Dominated( p , DominatedSize(p)+1 ) = q;
            DominatedSize(p) = DominatedSize(p) + 1;
            NmbOfDominating( q) = NmbOfDominating( q) + 1;
        elseif (sum( ObjVals( :, q) <= ObjVals( :, p)) == nmbOfObjs) && ...
                (sum( ObjVals( :, q) < ObjVals( :, p)) > 0)
            Dominated( q , DominatedSize(q)+1 ) = p;
            DominatedSize(q) = DominatedSize(q) + 1;
            NmbOfDominating( p) = NmbOfDominating( p) + 1;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
    if NmbOfDominating( p) == 0
        NmbOfFront( p) = 1;
        Front(1,FrontSize(1)+1) = p;
        FrontSize(1) = FrontSize(1) +1;
    end
end

%Test last individual Pareto's front's membership
if NmbOfDominating( nmbOfIndivs) == 0
    NmbOfFront( nmbOfIndivs) = 1;
    Front(1,FrontSize(1)+1) = nmbOfIndivs;
    FrontSize(1) = FrontSize(1) +1;
end

i = 1;
%Loop on all individuals belonging to each front to determine the next
%front. Termination conditions are : 1) all the fronts are used (1
%individual per front) - 2) Next front is empty
while (i~=nmbOfIndivs) && (FrontSize(i)~=0)
    for j = 1:FrontSize(i)
        p = Front(i, j);
        for k = 1:DominatedSize(p)
            q = Dominated(p , k);
            NmbOfDominating( q) = NmbOfDominating( q) - 1;
            if NmbOfDominating( q) == 0
                NmbOfFront( q) = i + 1;
                Front(i+1,FrontSize(i+1)+1) = q;
                FrontSize(i+1)=FrontSize(i+1)+1;
            end
        end
    end
    i = i + 1;
end

% crowding distance for each individual; 3rd highest priority sorting key
CrowdDist = zeros( nmbOfIndivs, 1);

i = 1;
%Compute Crowding distance of the individuals belonging to the same front
%Loop on each front until the last is reached (empty front or as many
%fronts as there are individuals)
while (i~=nmbOfIndivs) && FrontSize(i)~=0
    %Index of the front members
    MembersIdx = Front(i,1:FrontSize(i));
    %Test if front contains more than two members
    if FrontSize(i) > 2
        %Compute the Crowding distance by affecting -Inf distance to the
        %extremities
        %For each objective
        for k = 1:nmbOfObjs
            %Sort members of the front along the considered objective
            [ObjValsSorted SortMembersIdx] = sort( ObjVals( k, MembersIdx));
            %SortMembersIdx is an index within MembersIdx -> recover the true members indexes
            SortIdx = MembersIdx(SortMembersIdx);
            ObjMax = ObjValsSorted(end);
            ObjMin = ObjValsSorted(1);
            if ObjMax ~= ObjMin
                CrowdDist( SortIdx(1) ) = -Inf;
                CrowdDist( SortIdx(end) ) = -Inf;
                for j = 2:(length(MembersIdx) - 1)
                    CrowdDist( SortIdx( j) ) = CrowdDist( SortIdx( j)) - ...
                        (ObjValsSorted( j + 1) - ObjValsSorted( j - 1)) / ...
                        (ObjMax - ObjMin);
                end
                %             else
                %                 CrowdDist(MembersIdx)=0; %Already done when preallocating
                %                 array using "zeros"
            end
        end

        % Delete twins at extremities(-Inf. CrowdDist) of the front i.
        Twins = zeros(1,FrontSize(i));
        CrowdInfIdx = find(CrowdDist == -Inf);
        for d=1:length(CrowdInfIdx)
            for e=(d+1):length(CrowdInfIdx)
                if (sum( ( ObjVals( :,CrowdInfIdx(d)) ~= ObjVals(:,CrowdInfIdx(e)) ) ) == 0)
                    CrowdDist(CrowdInfIdx(d))=0;
                end
            end
        end

    end
    i = i + 1;
end

% rank of each individual
[foo SortIdx] = sortrows( [NmbOfFront CrowdDist]);
Ranking = zeros( nmbOfIndivs, 1);
for i = 1:nmbOfIndivs
    Ranking( i) = find( SortIdx == i);
end
