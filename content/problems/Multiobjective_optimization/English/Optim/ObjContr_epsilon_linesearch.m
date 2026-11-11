function [obj, g, h] = ObjContr_epsilon_linesearch(conceptionVariables, target, index)
%% ObjContr_epsilon_linesearch.m
%% ============================================
%% EPSILON-CONSTRAINT OBJECTIVE AND CONSTRAINTS
%% ============================================
% This is the epsilon-constraint variant of ObjContr with line search. Instead
% of optimizing both objectives simultaneously, it minimizes ONE objective and 
% converts the OTHER into a constraint. The direction is controlled by 'index'.
%
% Usage: Called from E_LaunchOptimisationEpsConstr.m where the target value
% is swept to trace the Pareto front.
%
% INPUTS:
%   conceptionVariables : [a; b; c; d; n1; S1fil; S2fil] - 7 design variables
%   target              : Threshold value for the constrained objective
%   index               : Direction of the epsilon-constraint
%                         1 = minimize losses, constrain mass  (mass <= target)
%                         2 = minimize mass, constrain losses  (losses <= target)
%
% OBJECTIVE (to minimize):
%   index=1: obj = 1 - efficiency       Losses as fraction of output power
%   index=2: obj = total mass (kg)      Core mass + copper winding mass
%
% CONSTRAINTS (all must satisfy g(i) <= 0):
%   g(1): Copper temp <= 120 degC
%   g(2): Iron temp <= 100 degC
%   g(3): Voltage drop DV2/V2 <= 0.1
%   g(4): Magnetizing current ratio <= 0.1
%   g(5): Primary fill factor <= 1.0
%   g(6): Secondary fill factor <= 1.0
%   g(7): Residual <= 1e-6
%   g(8): Epsilon constraint
%         index=1: Total mass <= target
%         index=2: Losses (1-efficiency) <= target
%
% DESIGN VARIABLES:
%   x = [a; b; c; d; n1; S1fil; S2fil]

%% Unpack the 7 design variables
conceptionVariables_unpack = num2cell(conceptionVariables);
[a,b,c,d,n1,S1fil,S2fil] = conceptionVariables_unpack{:};

%% ============================================
%% FIXED PARAMETERS (same as ObjContr.m)
%% ============================================
V2 = 24;                % Secondary voltage (V)
V1 = 230;               % Primary voltage (V)
f = 50;                 % Supply frequency (Hz)
fp2 = 0.8;              % Secondary load power factor
I2 = 8;                 % Secondary current (A)
Text = 40;              % Ambient temperature (degC)
q = 1;                  % Specific iron loss coefficient (W/kg)
kr = 0.5;               % Window packing factor
h = 10;                 % Convection coefficient (W/m2/K)
lambda = 0.15;          % Insulation thermal conductivity (W/m/K)
e_iso = 1e-3;           % Insulation thickness (m)
mvfer = 7800;           % Steel density (kg/m3)
mvcuivre = 8800;        % Copper density (kg/m3)
rhocuivre = 1.72e-8;    % Copper resistivity at 0 degC (ohm.m)
alphacuivre = 3.8e-3;   % Resistivity temperature coefficient (1/K)

parameters = [V2;V1;f;fp2;I2;Text;q;kr;h;lambda;e_iso;mvfer;mvcuivre;rhocuivre;alphacuivre]';

%% Run the transformer physics model
output = ConceptionModelLineSearch(conceptionVariables,parameters);

%% Unpack model outputs
output_unpack = num2cell(output);
[M_tot,Tcuivre,Tfer,DV2_V2,I10_I1,efficiency,f1,f2,Pj,Pfer,residu] = output_unpack{:};

g = ...

if index == 1
%% ============================================
%% OBJECTIVE: Minimize losses only
%% ============================================
obj = ...;

%% ============================================
%% CONSTRAINTS: Standard + mass limit
%% ============================================

g(8) = ...; % Total mass <= target mass (epsilon constraint)

elseif index == 2
%% ============================================
%% OBJECTIVE: Minimize mass only
%% ============================================

    obj = ...;

g(8) = ...;  % Total loss <= target loss (epsilon constraint)

end

h = 0;
end