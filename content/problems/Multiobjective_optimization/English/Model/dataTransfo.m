function [data, param] = dataTransfo()
%% dataTransfo.m
%% ============================================
%% TRANSFORMER MODEL DATA DICTIONARY
%% ============================================
% This function creates a lookup table of all quantities used in the
% transformer design optimization model, with values, units, and descriptions.
% Organized into: Fixed Parameters, Design Variables, Intermediate Quantities,
% Objectives, and Constraints.

%% Initialize output structure
data = struct('valeur',[],'unite',[""],'description',[""]);
RowNames = string.empty();

%% ============================================
%% CATEGORY 1: FIXED PARAMETERS
%% Determined by application requirements and material choices.
%% ============================================
param = struct();
param.V1 = {230, "V", "Primary rated voltage"};
param.f = {50, "Hz", "Supply frequency"};
param.fp2 = {0.8, "-", "Secondary load power factor (cos phi)"};
param.I2 = {8, "A", "Secondary rated current"};
param.Text = {40, "K", "Ambient (outside) temperature"};
param.q = {1, "W/kg", "Specific iron loss at 1T, 50Hz"};
param.kr = {0.5, "-", "Window packing factor (copper/window area ratio)"};
param.h = {10, "W/m2/K", "Air convection heat transfer coefficient"};
param.lambda_iso = {0.15, "W/m/K", "Thermal conductivity of insulation"};
param.e_iso = {1e-3, "m", "Insulation thickness between windings"};
param.mvfer = {7800, "kg/m3", "Density of electrical steel core"};
param.mvcuivre = {8800, "kg/m3", "Density of copper"};
param.rho_cu = {1.72e-8, "ohm.m", "Copper resistivity at 0 degC"};
param.alpha_cu = {3.8e-3, "1/K", "Temperature coefficient of copper resistivity"};
param.mu0 = {4e-7*pi, "H/m", "Permeability of free space"};

%% ============================================
%% CATEGORY 2: DESIGN / OPTIMIZATION VARIABLES
%% 7 variables: a,b,c,d (geometry), n1 (turns), S1fil,S2fil (wire sizes)
%% ============================================
param.a = {0.0214, "m", "Lateral core leg width"};
param.b = {0.0180, "m", "Winding window height"};
param.c = {0.0350, "m", "Winding window width"};
param.d = {0.0800, "m", "Core leg thickness"};
param.n1 = {295.04, "-", "Number of primary turns"};
param.S1fil = {1.53e-07, "m2", "Primary conductor cross-section area"};
param.S2fil = {4.21e-06, "m2", "Secondary conductor cross-section area"};

%% ============================================
%% CATEGORY 3: INTERMEDIATE QUANTITIES (computed during simulation)
%% ============================================
param.PJ = {50, "W", "Joule (copper) losses"};
param.X2 = {1, "ohm", "Secondary winding leakage reactance"};
param.n2 = {1, "-", "Number of secondary turns"};
param.Pfer = {30, "W", "Core (iron) losses"};
param.r1 = {0.5, "ohm", "Primary winding resistance"};
param.r2 = {0.2, "ohm", "Secondary winding resistance"};
param.R2 = {0.25, "ohm", "Total equivalent resistance referred to secondary"};
param.Bm = {1, "T", "Magnetic flux density in the core"};
param.l1spire = {0.3, "m", "Primary mean turn length"};
param.l2spire = {0.4, "m", "Secondary mean turn length"};
param.Mfer = {5, "kg", "Core iron mass"};
param.Mcuivre = {5, "kg", "Copper winding mass"};
param.Vfer = {1e-3, "m^3", "Core volume"};
param.Rfercuivre = {1, "m^2.K/W", "Thermal resistance: iron to copper (through insulation)"};
param.Sferair = {1e-4, "m^2", "Surface area: iron to air (convection)"};
param.Rferair = {1, "m^2.K/W", "Thermal resistance: iron to air"};
param.Scuivreair = {1e-4, "m^2", "Surface area: copper to air (convection)"};
param.Rcuivreair = {1, "m^2.K/W", "Thermal resistance: copper to air"};
param.Lmu = {100, "H", "Magnetizing inductance"};
param.P1 = {1000, "W", "Active power absorbed at primary"};
param.Q1 = {100, "VAR", "Reactive power supplied at primary"};
param.I1 = {80, "A", "Primary current (full load)"};
param.I10 = {0.5, "A", "No-load (magnetizing) current"};
param.DV2 = {1, "V", "Secondary voltage drop at full load"};
param.V2 = {24, "V", "Secondary rated voltage"};
param.rend = {0.95, "-", "Transformer efficiency"};

%% ============================================
%% CATEGORY 4: OPTIMIZATION OBJECTIVES
%% ============================================
param.Mtotale = {20, "kg", "Total mass (core + copper)"};
param.loss = {0.05, "-", "Losses = 1 - efficiency"};

%% ============================================
%% CATEGORY 5: CONSTRAINTS
%% ============================================
param.Tcuivre = {1, "degC", "Copper temperature (limit: 120 degC)"};
param.Tfer = {40, "degC", "Iron core temperature (limit: 100 degC)"};
param.DV2_V2 = {0, "-", "Normalized voltage drop DV2/V2 (limit: 0.1)"};
param.I10_I1 = {0, "-", "Normalized magnetizing current I10/I1 (limit: 0.1)"};
param.f2 = {0.45, "-", "Secondary fill factor f2 (limit: 1.0)"};
param.f1 = {0.5, "-", "Primary fill factor f1 (limit: 1.0)"};
param.residu = {0, "-", "Newton-Raphson residual norm (limit: 1e-6)"};

%% ============================================
%% BUILD TABLE FROM STRUCTURE
%% ============================================
fields = fieldnames(param);
for i = 1:length(fields)
    RowNames(i,1) = fields{i};
    data.valeur(i,1) = param.(fields{i}){1};
    data.unite(i,1) = param.(fields{i}){2};
    data.description(i,1) = param.(fields{i}){3};
end
data = struct2table(data);
data.Properties.RowNames = RowNames;
data = sortrows(data,"RowNames");
end