%% C_LaunchOptimisationMultiStart.m
%% ============================================
%% SINGLE-OBJECTIVE OPTIMIZATION WITH MULTISTART
%% ============================================
% Extends B_LaunchOptimisation by running fmincon from MULTIPLE random
% starting points. This helps avoid local minima and increases the chance
% of finding the global optimum.
%
% APPROACH:
%   1. Generate 100 random starting points within the bounds.
%   2. Run fmincon from each starting point independently.
%   3. Keep only converged results and select the best one.
%
% COMPARISON:
%   - B_LaunchOptimisation: 1 starting point -> 1 solution
%   - This script: 100 starting points -> potentially 100 local minima explored
%   - D/E/F scripts: explore the FULL Pareto front (multi-objective)

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
%% 2) MULTISTART CONFIGURATION
%% ============================================
nStarts = 100;                  % Number of random starting points
nVariables = length(lb);        % 7 design variables

%% Preallocate storage for all results
xopt = zeros(nStarts,nVariables);   % Best variables from each run
fopt = zeros(nStarts,1);            % Best objective from each run
exitflag = zeros(nStarts,1);        % Convergence status
nEval = zeros(nStarts,1);           % Function evaluation count

%% fmincon options: SQP with tight tolerance
options = optimoptions('fmincon',...
                        'Algorithm','sqp',...
                        'Display','final-detailed',...
                        'ConstraintTolerance', 1e-11);

%% Objective: minimize losses (index=1) for losses
myfun = @(x) ...;

%% ============================================
%% 3) MULTISTART LOOP
%% ============================================
% Use 'parfor' instead of 'for' to run in parallel 
% (requires Parallel Computing Toolbox)
tic
for i=1:nStarts
    rng(i);                                   % Different seed to avoid computing the same with parfor
    x0 = ...          % Random starting point
    [xopt(i,:),fopt(i),exitflag(i),output] = ...
        fmincon(myfun,x0,[],[],[],[],lb,ub,@mycon,options);
    nEval(i) = output.funcCount;
end
toc

%% ============================================
%% 4) POST-PROCESSING: SELECT THE BEST SOLUTION
%% ============================================
% Filter only converged solutions (exitflag >= 1 means successful convergence)
[fBest, indexmin] = min(fopt(exitflag>=1));
xopt = xopt(exitflag>=1,:);
xBest = xopt(indexmin,:);

%% Plot the distribution of objective values from all starting points
plot(100*(1:sum(exitflag>=1))/nStarts, sort(fopt(exitflag>=1)), 'o'); grid on;
ylabel("Objective function (1 - efficiency)"); xlabel("Cumulative percentage (%)")
title("Repartition of results from multistart optimization")

% Show the best result
disp(strcat("Best result: 1-efficiency = ", num2str(obj(xBest,1)), ...
    " | Mass = ", num2str(obj(xBest,2)), " kg"))

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
% Pass through constraints from ObjContr. g(x) <= 0, h(x) = 0.
    [~,g,h] = ObjContr(x);
    % [~,g,h] = ObjContr_linesearch(x);
end
