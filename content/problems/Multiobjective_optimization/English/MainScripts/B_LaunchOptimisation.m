%% B_LaunchOptimisation.m
%% ============================================
%% SINGLE-OBJECTIVE OPTIMIZATION (fmincon SQP)
%% ============================================
% This script demonstrates mono-objective optimization using MATLAB's
% fmincon solver with the Sequential Quadratic Programming (SQP) algorithm.
%
% PURPOSE:
%   A single objective is chosen: either minimize losses (index=1) or
%   minimize mass (index=2). The other objective is not considered.
%   This produces ONE point on the Pareto front.
%
% To explore the full Pareto front, use:
%   - D_LaunchOptimisationPonderation.m (weighted sum / scalarization)
%   - E_LaunchOptimisationEpsConstr.m (epsilon-constraint)
%   - F_LaunchNSGAII.m (evolutionary algorithm)

%% Clear workspace and set up path
clc; clear; close all; path=pwd(); format short;
[s,e]=regexp(path,'.+(?=[\\/]{1,2}MainScripts)');
path=path(s:e); addpath(genpath(path)); clear s e path

%% ============================================
%% 1) OPTIMIZATION VARIABLE BOUNDS
%% ============================================
% Order: [a ; b ; c ; d ; n1 ; S1 ; S2]
lb = [ 3e-3 ; 14e-3 ; 6e-3 ; 10e-3 ; 200 ; 0.15e-6 ; 0.15e-6 ]; % Lower bounds
ub = [ 30e-3 ; 95e-3 ; 40e-3 ; 80e-3 ; 1200 ; 19e-6 ; 19e-6 ];  % Upper bounds

%% ============================================
%% 2) RUN fmincon (SQP ALGORITHM)
%% ============================================

%% 2a) Initial guess: random point within bounds
x0 = ...

%% 2b) Configure and run fmincon
% SQP approximates the Hessian of the Lagrangian using BFGS updates.
% Suitable for smooth constrained optimization problems.
options = optimoptions('fmincon',...
                        'Algorithm','sqp',...
                        'Display','iter-detailed');

% Choose the objective: index=1 for losses, index=2 for mass
% see appendix at the end of the file.
myfunfmincon = @(x)...

% fmincon solves: min f(x) s.t. lb <= x <= ub, g(x) <= 0, h(x) = 0
% see fmincon documentation for function signature and details.
[xopt, fopt, exitflag] = fmincon(...,options);

% Display full results (both objectives)
obj = ObjContr(xopt);
disp(strcat("loss = ", num2str(obj(1) * 100), " % | mass = ", num2str(obj(2)),' kg'))

%% Exitflag reference:
%  1 : Converged (first-order optimality satisfied)
% >1 : Converged (other convergence criteria met)
%  0 : Maximum iterations reached (may not have converged)
% <=-1 : No feasible solution found

%% ============================================
%% APPENDIX: WRAPPER FUNCTIONS
%% ============================================

function f = myfun(x, index)
% Objective function wrapper: extract one objective from ObjContr.
% index: 1=losses, 2=mass
[f,~,~] = ObjContr(x);
% [f,~,~] = ObjContr_linesearch(x);
f = f(index);
end

function [g,h] = mycon(x)
% Constraints wrapper: pass through inequality and equality constraints.
% fmincon requires g(x) <= 0 and h(x) = 0.
 [~,g,h] = ObjContr(x);
 % [~,g,h] = ObjContr_linesearch(x);
end
