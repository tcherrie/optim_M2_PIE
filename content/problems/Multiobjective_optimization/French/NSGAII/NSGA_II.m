% The NSGA-II multi-objective genetic algorithm w/
% simulated binary crossover (SBX) and polynomial mutation.
%
% ARGUMENTS
%
% nmbOfIndivs - number of individuals in each generation
% nmbOfGens - number of generations for the algorithm to run
% Fct - objective function handle (i.e. @FunctionName)
%    Input :
%      Indivs - Population to evaluate
%         MxN array where M = number of decision variables and N = number
%         of individuals
%    Outputs :
%       ObjVals - Objectives values for each individual
%         MxN array where M = number of objectives and N = number of
%         individuals
%       ConstrVals - constraints values for each individuals in the form :
%       g_i(x) <= 0
%         MxN array where M = number of constraints and N = number of
%         individuals
% RandParams - parameters for the random initialization of the initial
%   (zero-th) generation (see NSGA_ParentGen0.m)
% Ranges - permissible range for each decision variable
% pX - crossover probability/fraction (see NSGA_SBX.m)
% etaX - distribution parameter for simulated binary crossover
%   (SBX; see NSGA_SBX.m)
% pM - mutation probability/fraction (see NSGA_Mutate.m)
% etaM - distribution parameter for polynomial mutation (see NSGA_Mutate.m)
% Options - structure containing the following fields :
%           SaveDir : save directory (each generation is saved)
%           ParGen  : initial generation, if not set, the initial
%           generation is created using RandParams.
%         This argument is optional (default is no save and random initial
%         generation). Each field is also optional : if the field is not
%         present the default behaviour is obtained.
%
% RETURN VALUES
%
% ParGen - final (parent) generation
% ObjVals - objective function values for each individual of the final
%   generation
% Ranking - ranks of the individuals of the final generation
% SumOfViols - sum of constraint violations for each individual of the
%   final generation
% NmbOfFront - number of pareto-optimal front for each individual of the
%   final generation
%
% Modified by G. Robin - 28/09/2004
%   - Renamed Cons as Ranges
%   - Added calculated constraints handling : user function now returns a
%   constraints matrix ConstrVals (Nc by N matrix where Nc is the number of
%   constraints and N the number of individuals) along with the objectives
%   matrix ObjVals.
%   - Bounds is suppressed : upper and lower bound are dynamically computed
%   within each Front during the Crowdist calculation
%   - User defined objective function is passed via a handle
%   - Added possibility to supply initial generation instead of randomly
%   generating it
%   - Mutation is made conform to the Non-Uniform mutation algorithm
%   described by Deb (maxM input is suppressed).
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

function [ParGen, ObjVals,ConstrVals,Ranking, SumOfViols, NmbOfFront] = ...
    NSGA_II( nmbOfIndivs, nmbOfGens, Fct, RandParams, Ranges, ...
    pX, etaX, pM, etaM, Options)

%Check the number of arguments
error(nargchk(9, 10, nargin));

%Default value for Inital population random generation
RandomInitGen = true;
Save = false;

if nargin == 10
    %Options provided
    %Test for the presence of a SaveDir field
    if isfield(Options, 'SaveDir')
        %The field is present - Set the Save lag to true
        Save = true;
        %Create directory (even if it already exists)
        success = mkdir(Options.SaveDir);
    end
    %Test for the presence of a ParGen field
    if isfield(Options, 'ParGen')
        %Initial population supplied - Set RandomInitGen flag to false
        RandomInitGen = false;
    end
end

%Intialize random number generator to an arbitrary state using clock
%rand('state',sum(100*clock));
[nombreDeGenes,~]=size(Ranges);
if RandomInitGen
    % create initial (parent) generation
    ParGen = NSGA_ParentGen0( nmbOfIndivs, RandParams, Ranges);
else
    %Check suppled initial generation for coherency with the parameters
    ParGen = Options.ParGen;
    [foo,bar] = size(ParGen);
    [NmbOfVars,dump]=size(Ranges);
    if (foo~=NmbOfVars) || (bar~=nmbOfIndivs)
        error('Initial generation not coherent with either nmbOfIndivs or Ranges')
    end
end

% evaluate initial generation
% [ObjVals, ConstrVals] = feval(Fct, ParGen);

for k=1:nmbOfIndivs
  [ObjVals(:,k), ConstrVals(:,k)] = feval(Fct, ParGen(1:nombreDeGenes,k));
end
% rank individuals of initial generation
[Ranking, SumOfViols, NmbOfFront, foo] = ...
    NSGA_Rank( ParGen, ObjVals, ConstrVals);

% repeat for given number of generations ...
for i = 1:nmbOfGens
    fprintf( 'generation %d\n', i);
    % create child generation
    [ChildGen foo] = NSGA_ChildGen( ...
        ParGen, Ranking, Ranges, pX, etaX, pM, etaM);
    % append children to parents
    Par_ChildGen = [ParGen ChildGen];
    % append objective function and constraints values of the children to
    % those of the parents
    for k=1:nmbOfIndivs                                                  %% parfor
        [ChildObjVals(:,k), ChildConstrVals(:,k)]= feval(Fct, ChildGen(1:nombreDeGenes,k));
    end
%     [ChildObjVals, ChildConstrVals]= feval(Fct, ChildGen);
    ObjVals = [ObjVals, ChildObjVals];
    ConstrVals = [ConstrVals, ChildConstrVals];
    % rank children and parents together
    [Ranking, SumOfViols, NmbOfFront, foo] = ...
        NSGA_Rank( Par_ChildGen, ObjVals, ConstrVals);
    % ranks of the parents
    ParRanking = Ranking( 1:nmbOfIndivs);
    % elite parents that will not be replaced by children
    ElitePars = find( ParRanking <= nmbOfIndivs);
    % non-elite parents that will be replaced by children
    NonElitePars = find( ParRanking > nmbOfIndivs);
    % ranks of the children
    ChildRanking = Ranking( (nmbOfIndivs + 1):end);
    % children that will replace worse parents
    BetterChildren = find( ChildRanking <= nmbOfIndivs);

    % replace non-elite parents with better children
    ParGen( :, NonElitePars) = ChildGen( :, BetterChildren);
    % use the same type of `filling-in-the-gaps-between-elite-parents' for obj. val.s etc.
    % to keep indices in sync w/ run numbers
    %ChildObjVals = ObjVals( :, (nmbOfIndivs + 1):end); % children
    % Patch G.Robin -> not needed anymore
    ObjVals = ObjVals( :, 1:nmbOfIndivs); % parents
    ObjVals( :, NonElitePars) = ChildObjVals( :, BetterChildren); % replace non-elite parents
    % Patch G.Robin -> Added selecting the constraints values
    %ChildConstrVals = ConstrVals( :, (nmbOfIndivs + 1):end); % children
    % Patch G.Robin -> not needed here
    ConstrVals = ConstrVals( :, 1:nmbOfIndivs); % parents
    ConstrVals( :, NonElitePars) = ChildConstrVals( :, BetterChildren); % replace non-elite parents

    ChildSumOfViols = SumOfViols( (nmbOfIndivs + 1):end); % children
    SumOfViols = SumOfViols( 1:nmbOfIndivs); % parents
    SumOfViols( NonElitePars) = ChildSumOfViols( BetterChildren); % replace non-elite parents
    ChildNmbOfFront = NmbOfFront( (nmbOfIndivs + 1):end); % children
    NmbOfFront = NmbOfFront( 1:nmbOfIndivs); % parents
    NmbOfFront( NonElitePars) = ChildNmbOfFront( BetterChildren); % replace non-elite parents
    % have ChildRanking already
    Ranking = ParRanking; % parents
    Ranking( NonElitePars) = ChildRanking( BetterChildren); % replace non-elite parents


    %Sauvegarde des résultats et des paramètres
    if Save
        filename = strcat(Options.SaveDir,'\Result_',sprintf('%d',i));
        save(filename, 'ParGen', 'ObjVals', 'ConstrVals', 'Ranking', 'SumOfViols', 'NmbOfFront');
    end
end
end
