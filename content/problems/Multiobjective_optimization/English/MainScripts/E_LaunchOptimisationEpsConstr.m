%% E_LaunchOptimisationEpsConstr.m
%% ============================================
%% MULTI-OBJECTIVE OPTIMIZATION - EPSILON-CONSTRAINT METHOD
%% ============================================
% This script traces the Pareto front using the epsilon-constraint method.
% Instead of weighting objectives, it minimizes ONE objective while
% constraining the OTHER to be below a specified threshold (epsilon).
%
% METHOD: Epsilon-Constraint (bidirectional, controlled by mass_or_loss_constr)
%   mass_or_loss_constr = 1:
%     Minimize: obj_losses
%     Subject to: obj_mass <= epsilon_target
%   mass_or_loss_constr = 2:
%     Minimize: obj_mass
%     Subject to: obj_losses <= epsilon_target
%
% By sweeping epsilon_target, we trace the entire Pareto front.
% Each epsilon value gives a different point.
%
% ADVANTAGES over scalarization:
%   - Guarantees feasible points (constraints are hard limits)
%   - Can find non-convex parts of the Pareto front
%   - No need to normalize objectives or tune weights
%
% ALGORITHM:
%   1. Sweep target through nEps values between constMin and constMax.
%   2. For each target, run nStarts multistart optimizations.
%   3. Each optimization minimizes one objective subject to the other.

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
%% 2) EPSILON-CONSTRAINT PARAMETERS
%% ============================================
mass_or_loss_constr = ...; % 1 = mass constraint; 2 = loss constraints
constMin = ...; 
constMax = ...;

nStarts = 20;               % Multistart points per epsilon value
nEps = 20;                  % Number of epsilon values
nVariables = length(lb);

% Preallocate
xopt = zeros(nStarts,nVariables);
fopt = zeros(nStarts,1);
exitflag = zeros(nStarts,1);

% fmincon options
options = optimoptions('fmincon',...
                        'Algorithm','sqp',...
                        'Display','off',...
                        'ConstraintTolerance',1e-9);


targetList = linspace(constMin, constMax, nEps);
nEval = 0;

%% ============================================
%% 3) EPSILON-CONSTRAINT + MULTISTART LOOP
%% ============================================
for i = 1:nEps
    disp(strcat(num2str(i),"/",num2str(nEps)))
    massTarget = targetList(i);

    % Create constraint function that includes the mass or loss limit
    
    myconstr = @(x) ...
    myfunfmincon = @(x) ...

    nEvals = zeros(nStarts,1);

    % Parallel loop
    parfor j=1:nStarts
        rng(i*10 + j*100);
        x0 = ...
        [xopt(j,:),fopt(j),exitflag(j),output] = fmincon(myfunfmincon,x0,[],[],[],[],lb,ub,myconstr,options);
        nEvals(j) = output.funcCount;
    end

    nEval = nEval + sum(nEvals);

    % Select best result
    [fBest(i), indexmin] = min(fopt(exitflag>=1));
    xopt = xopt(exitflag>=1,:);
    xBest(i,:) = xopt(indexmin,:);
    obj = ObjContr(xBest(i,:));
    loss(i) = obj(1); mass(i) = obj(2);
end

%% ============================================
%% 4) POST-PROCESSING: PLOT PARETO FRONT
%% ============================================

scatter(mass, loss*100, 50, targetList, '*');
grid on;
ylabel("Losses (%)"); xlabel("Mass (kg)"); colormap("jet")
title("Pareto Front - Epsilon-Constraint Method");
col = colorbar; ylabel(col, 'Target Mass (kg)');

% Save results
if mass_or_loss_constr == 1
    save("Pareto_eps_mass_constraint", "mass", "loss", "targetList", "nEval")
elseif mass_or_loss_constr == 2
    save("Pareto_eps_loss_constraint", "mass", "loss", "targetList", "nEval")
end
%% ============================================
%% APPENDIX: WRAPPER FUNCTIONS
%% ============================================

function f = myfun(x, index)
% Objective function wrapper: extract one objective from ObjContr.
% index: 1=losses, 2=mass
%[f,~,~] = ObjContr(x);
[f,~,~] = ObjContr_linesearch(x);
f = f(index);
end

function [g,h] = constr(x, target, index)
% Constraints: standard + mass <= massTarget
    %[~,g,h] = ObjContr_epsilon(x, target, index);
    [~,g,h] = ObjContr_epsilon_linesearch(x, target, index);
end
