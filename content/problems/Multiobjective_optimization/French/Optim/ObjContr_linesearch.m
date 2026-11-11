function [obj, g, h] = ObjContr_linesearch(conceptionVariables)
%% ObjContr.m
%% ============================================
%% OBJECTIVE FUNCTION AND CONSTRAINTS
%% ============================================
% Evaluates the two objectives and seven constraints for a given transformer
% design. This function is called by every optimization method.
%
% OBJECTIVES (to minimize):
%   obj(1) = 1 - efficiency       Losses as a fraction of output power
%   obj(2) = total mass (kg)      Core mass + copper winding mass
%
% CONSTRAINTS (all must satisfy g(i) <= 0):
%   g(1): Copper temperature <= 120 degC
%   g(2): Iron temperature <= 100 degC
%   g(3): Voltage drop DV2/V2 <= 0.1 (10%)
%   g(4): Magnetizing current ratio I10/I1 <= 0.1
%   g(5): Primary fill factor f1 <= 1.0 (window not overfull)
%   g(6): Secondary fill factor f2 <= 1.0 (window not overfull)
%   g(7): Newton-Raphson residual <= 1e-6 (model converged)
%
% DESIGN VARIABLES:
%   x = [a; b; c; d; n1; S1fil; S2fil]
%   a,d : core dimensions, b,c : window dimensions
%   n1 : primary turns, S1fil/S2fil : conductor cross-sections

%% Unpack the 7 design variables
conceptionVariables_unpack = num2cell(conceptionVariables);
[a,b,c,d,n1,S1fil,S2fil] = conceptionVariables_unpack{:};

%% ============================================
%% FIXED PARAMETERS (same values as in A_LaunchModel.m)
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

% Pack parameters into a column vector for ConceptionModel
parameters = [V2;V1;f;fp2;I2;Text;q;kr;h;lambda;e_iso;mvfer;mvcuivre;rhocuivre;alphacuivre]';

%% Run the transformer physics model
% The model solves the coupled electromagnetic and thermal equations
% and returns: [M_tot; Tcuivre; Tfer; DV2_V2; I10_I1; rendement; f1; f2; Pj; Pfer ; crit]
output = ConceptionModelLineSearch(conceptionVariables,parameters);

%% Unpack model outputs
output_unpack = num2cell(output);
[M_tot,Tcuivre,Tfer,DV2_V2,I10_I1,rendement,f1,f2,Pj,Pfer,residu] = output_unpack{:};

%% ============================================
%% OBJECTIVE FUNCTION (to minimize)
%% ============================================
obj = ... % 1) losses, 2) mass

%% ============================================
%% INEQUALITY CONSTRAINTS (must satisfy g(i) <= 0)
%% Each constraint is normalized by its limit for better numerical scaling.
%% ============================================
g = ...

%% Equality constraints (none)
h = 0;
end