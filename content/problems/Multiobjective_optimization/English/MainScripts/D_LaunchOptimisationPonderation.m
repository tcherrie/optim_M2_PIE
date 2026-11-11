%% D_LaunchOptimisationPonderation.m
%% ============================================
%% MULTI-OBJECTIVE OPTIMIZATION - LINEAR SCALARIZATION
%% ============================================
% This script traces the Pareto front by optimizing a WEIGHTED SUM of the
% two objectives. By varying the weight parameter omega from 0 to 1, we
% sweep across different trade-offs between losses and mass.
%
% METHOD: Scalarization (weighted sum)
%   Minimize: omega * (obj_losses / norm_losses) + (1-omega) * (obj_mass / norm_mass)
%
% This method works well to trace convex Pareto fronts.
% The normalization factors scale both objectives to
% similar magnitudes so neither dominates the weighted sum.
%
% ALGORITHM:
%   1. Sweep omega through nOmega values in [0, 1].
%   2. For each omega, run nStarts multistart optimizations (parallelized).
%   3. Record the best solution for each omega.
%
% OUTPUT: A scatter plot of the Pareto front colored by omega value.

%% Clear workspace and set up path
clc; clear; close all; path=pwd(); format short;
[s,e]=regexp(path,'.+(?=[\\/]{1,2}MainScripts)');
path=path(s:e); addpath(genpath(path)); clear s e path

%% ============================================
%% 1) OPTIMIZATION VARIABLE BOUNDS
%% ============================================
lb = [ 3e-3 ; 14e-3 ; 6e-3 ; 10e-3 ; 200 ; 0.15e-6 ; 0.15e-6 ];
ub = [ 30e-3 ; 95e-3 ; 40e-3 ; 80e-3 ; 1200 ; 19e-6 ; 19e-6 ];

%% ============================================
%% 2) SCALARIZATION PARAMETERS
%% ============================================
nStarts = 20;               % Multistart points per omega value
nOmega = 20;                % Number of different weight values
nVariables = length(lb);    % 7 design variables

norm_mass = ...;           % Normalization coefficient - mass
norm_loss =...;           % Normalization coefficient - loss

%% Preallocate storage
xopt = zeros(nStarts,nVariables);
fopt = zeros(nStarts,1);
exitflag = zeros(nStarts,1);
nEval = 0;

%% fmincon options: SQP, quiet, tight tolerance
options = optimoptions('fmincon',...
                        'Algorithm','sqp',...
                        'Display','off',...
                        'ConstraintTolerance',1e-9);

% Weight values sweeping from 0 (mass only) to 1 (losses only)
OmegaList = linspace(0,1,nOmega);

%% ============================================
%% 3) WEIGHTED SUM + MULTISTART LOOP
%% ============================================
for i = 1:nOmega
    disp(strcat(num2str(i),"/",num2str(nOmega)))
    omega = OmegaList(i);

    % Normalized weighted sum objective with typical max loss and mass values
    % Normalization ensures both objectives contribute equally regardless of scale.
    myfun = @(x) ...;

    nEvals = zeros(nStarts,1);

    % Parallel loop: each starting point runs independently
    parfor j=1:nStarts
        rng(i*10 + j*100);                % Unique seed per run
        x0 = ...  % Random initial guess
        [xopt(j,:),fopt(j),exitflag(j),output] = fmincon(myfun,x0,[],[],[],[],lb,ub,@mycon,options);
        nEvals(j) = output.funcCount;
    end

    nEval = nEval + sum(nEvals);

    % Select best result from this omega value's multistart runs
    [fBest(i), indexmin] = min(fopt(exitflag>=1));
    xopt = xopt(exitflag>=1,:);
    xBest(i,:) = xopt(indexmin,:);
    loss(i) = obj(xBest(i,:), 1);
    mass(i) = obj(xBest(i,:), 2);
end

%% ============================================
%% 4) POST-PROCESSING: PLOT PARETO FRONT
%% ============================================
scatter(mass, loss*100, 10, OmegaList, 'o', 'filled', ...
    'DisplayName', sprintf('SQP multistart - %d function evals', nEval));
grid on;
ylabel("Losses (%)"); xlabel("Mass (kg)"); colormap("jet")
title("Pareto Front via Weighted Sum Scalarization");
col = colorbar; ylabel(col, 'Omega (weight on losses)');

% Save results
save("Pareto_ponderation", "mass", "loss", "OmegaList", "nEval")

%% ============================================
%% APPENDIX: WRAPPER FUNCTIONS
%% ============================================

function f = obj(x, index)
% Extract one objective from ObjContr. index: 1=losses, 2=mass
    [f,~,~] = ObjContr(x);
    % [f,~,~] = ObjContr_linesearch(x);
    f = f(index);
end

function [g,h] = mycon(x)
% Pass through constraints from ObjContr.
    [~,g,h] = ObjContr(x);
    % [~,g,h] = ObjContr_linesearch(x);
end
