%% F_LaunchNSGAII.m
%% ============================================
%% MULTI-OBJECTIVE OPTIMIZATION - NSGA-II EVOLUTIONARY ALGORITHM
%% ============================================
% This script runs the NSGA-II (Non-dominated Sorting Genetic Algorithm II)
% to find the Pareto front directly, without scalarization or epsilon constraints.
%
% NSGA-II KEY FEATURES:
%   - Maintains a population of 500 candidate solutions
%   - Uses non-dominated sorting to rank solutions by Pareto front number
%   - Uses crowding distance to maintain diversity
%   - Elitism: better solutions from both parent and child generations survive
%
% DEFAULT PARAMETERS:
%   Population: 500 individuals
%   Generations: 100
%   SBX Crossover: prob=0.5, eta=0.5
%   Polynomial Mutation: prob=0.1, eta=0.5
%
% The script also runs MATLAB's built-in gamultiobj for comparison.

clear; close all; path=pwd();
[s,e]=regexp(path,'.+(?=[\\/]{1,2}MainScripts)');
path=path(s:e); addpath(genpath(path)); clear s e path

%% ============================================
%% NSGA-II PARAMETERS
%% ============================================

% Population and generations
nmbOfIndivs = 500;  % Number of individuals per generation
nmbOfGens = 100;    % Number of generations before stopping

% Objective function handle
Fct = @(x) ObjContr(x);

%% Variable bounds and random initialization parameters
lb = [ 3e-3 ; 14e-3 ; 6e-3 ; 10e-3 ; 200 ; 0.15e-6 ; 0.15e-6 ];
ub = [ 30e-3 ; 95e-3 ; 40e-3 ; 80e-3 ; 1200 ; 19e-6 ; 19e-6 ];
Ranges = [lb, ub];  % [lower; upper] for each variable

% Random init: uniform distribution (type=1) within [lb, ub]
RandParams = [ones(7,1), lb, ub];

%% Crossover parameters (SBX - Simulated Binary Crossover)
% pX = 0.5: 50% probability that a variable undergoes crossover
% etaX = 0.5: low eta means children can be far from parents (exploration)
%   Higher eta (e.g., 20) would make children close to parents (exploitation)
pX = 0.5;
etaX = 0.5;

%% Mutation parameters (Polynomial Mutation)
% pM = 0.1: 10% of genes (variables) are mutated each generation
% etaM = 0.5: low eta means large mutations (exploration)
pM = 0.1;
etaM = 0.5;

%% ============================================
%% RUN NSGA-II from Deb et. al.
%% ============================================
fprintf('Running NSGA-II (%d individuals, %d generations)...\\n', nmbOfIndivs, nmbOfGens);
tic
[ParGen, ObjVals, ConstrVals, Ranking, SumOfViols, NmbOfFront] = ...
    NSGA_II(nmbOfIndivs, nmbOfGens, Fct, RandParams, Ranges, pX, etaX, pM, etaM);
tNSGA = toc;
fprintf('Done (%.2f s)\\n', tNSGA);

%% ============================================
%% RUN NSGA-II from Matlab builtin
%% ============================================

% see https://fr.mathworks.com/help/gads/gamultiobj-algorithm.html

options = optimoptions('gamultiobj', ...
    'PlotFcn', 'gaplotpareto', ...
    'PopulationSize', nmbOfIndivs, ...
    'MaxGenerations', nmbOfGens, ...
    'CrossoverFraction', pX,...
    'UseParallel', true, ...
    'ConstraintTolerance', 1e-3, ...
    'FunctionTolerance', 1e-3, ...
    'InitialPopulationRange', [lb, ub].', ...
    'ParetoFraction', 0.3,...
    'Display','iter');

[xopt_gamultiobj, fopt_gamultiobj, exitflag, output] = ...
    gamultiobj(@myfun, 7, [], [], [], [], lb, ub, @mycon, options);


%% ============================================
%% PLOT RESULTS
%% ============================================


figure;
objParetoNSGAII = ObjVals(:, NmbOfFront == 1);
scatter(objParetoNSGAII(2,:), objParetoNSGAII(1,:)*100, 'ko', 'filled');
hold on;
scatter(fopt_gamultiobj(:,2), fopt_gamultiobj(:,1)*100, 'ro', 'filled');
grid on;
legend('Deb et. al. NSGA-II', 'MATLAB gamultiobj');
xlabel('Mass (kg)'); ylabel('Losses (%)');
title('Pareto Front: NSGA-II vs gamultiobj');

%% ============================================
%% APPENDIX: WRAPPER FUNCTIONS
%% ============================================


function f = myfun(x)
% Objective function wrapper: extract one objective from ObjContr.
% index: 1=losses, 2=mass
[f,~,~] = ObjContr(x);
% [f,~,~] = ObjContr_linesearch(x);
end

function [g,h] = mycon(x)
% Constraints wrapper: pass through inequality and equality constraints.
% fmincon requires g(x) <= 0 and h(x) = 0.
 [~,g,h] = ObjContr(x);
 % [~,g,h] = ObjContr_linesearch(x);
end