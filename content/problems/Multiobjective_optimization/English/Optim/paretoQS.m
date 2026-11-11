
function indPar=paretoQS(sln)
%% paretoQS.m
%% ============================================
%% PARETO FRONT EXTRACTION USING MODIFIED QUICKSORT
%% ============================================
% Finds the Pareto-optimal subset of designs from a set of evaluated points.
% A design x_i is "Pareto optimal" if no other design x_j performs better
% in ALL objectives simultaneously. In other words, improving one objective
% requires sacrificing another.
%
% ALGORITHM:
%   1. Start with all points assumed Pareto-optimal.
%   2. Repeatedly pick a random pivot point and remove all points it dominates.
%      Point A dominates point B if A is better or equal in ALL objectives
%      and strictly better in at least one.
%   3. If no points are removed in two consecutive rounds, perform a final
%      deterministic sweep to clean up any remaining dominated points.
%
% IMPORTANT: All objectives are treated as minimization. To maximize an
% objective, negate it first: y_min = -y_max.
%
% INPUTS:
%   sln : Matrix of size (nPoints x nObjectives)
%
% OUTPUTS:
%   indPar : Row indices of the Pareto-optimal points

% Verify correct input shape
assert(ismatrix(sln),'Input must be an nPt x nOF matrix');

% Find size of solution space
[nPt,nOF]=size(sln);

%% Special cases

% Empty input: return empty of same shape
if isempty(sln)
    indPar=sln;
    return

% Single point: always Pareto optimal
elseif nPt==1
    indPar=1;
    return

% Single objective: only the minimum point is Pareto optimal
elseif nOF==1
    [~,indPar]=min(sln);
    return
end

%% Main iterative dominance removal (quickssort-inspired)
% Start assuming all points are Pareto-optimal
indPar=1:nPt;
nPar=nPt;

% Allow at most 2 consecutive rounds with no removal before stopping
% This gives expected O(n log n) performance
nnImp=0;
exitThresh=2;

while true
    % Pick a random pivot point and remove all points it dominates.
    % A point A dominates B if A <= B in ALL objectives and A < B in at least one.
    % We keep points that are NOT dominated by the pivot:
    indPar(all(sln(indPar,:) > sln(indPar(randi([1 nPar],1)),:),2))=[];

    % Track improvement for early stopping
    nParPrev=nPar;
    nPar=length(indPar);

    if (nPar==nParPrev)
        % No improvement this round
        nnImp=nnImp+1;
    else
        % Points were removed
        nnImp=0;
    end

    % Stop if no improvement for too many rounds
    if nnImp>=exitThresh
        break
    end
end

%% Final deterministic sweep to remove any remaining dominated points
% Go backwards through the list so removal doesn't affect remaining indices
for i=nPar:-1:1
    if any(all(sln(indPar,:) < sln(indPar(i),:),2))
        indPar(i)=[];
    end
end
end
