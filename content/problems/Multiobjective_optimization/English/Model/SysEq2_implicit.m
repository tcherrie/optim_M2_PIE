%% SysEq2_implicit.m
%% ============================================
%% IMPLICIT EQUATIONS - Coupled Electrical/Thermal System
%% ============================================
% This file contains the 8 implicit equations that must be solved
% simultaneously using an iterative method (Newton-Raphson).
% The equations are "implicit" because the variables depend on each other
% in a circular manner, forming a closed system.
%
% The 8 unknown inner state variables are:
%   [r2, X2, n2, DV2, Pj, Tcuivre, r1, R2]
%
% The coupling structure:
%   - n2 (secondary turns) depends on DV2 (voltage drop)
%   - DV2 depends on R2 and X2 (equivalent resistance and reactance)
%   - R2 depends on r1 and r2 (primary and secondary resistances)
%   - r1, r2 depend on Tcuivre (temperature-dependent resistivity)
%   - Tcuivre depends on Pj and Pfer (Joule and iron losses via thermal network)
%   - Pj depends on R2 and I2
%   - X2 depends on n2
%
% This circular dependency chain requires iterative solution.

%% 1) Secondary turns - depends on voltage drop DV2
% The effective secondary turns count changes with the voltage drop across
% the primary winding impedance. From transformer voltage equation:
%   V1 + DV2_effective = n1/n2 * V2,  hence  n2 = n1 * (V2 + DV2) / V1
n2 = n1*(V2+DV2)/V1;

%% 2) Secondary winding resistance - temperature dependent
% Copper resistivity increases with temperature: rho(T) = rho0 * (1 + alpha * T)
% Resistance = resistivity * (number of turns * mean turn length) / cross-section
r2 = rhocuivre*(1+alphacuivre*Tcuivre)*n2*l2spire/S2fil;

%% 3) Secondary leakage reactance - depends on secondary turns n2
% Empirical formula for leakage inductance of a shell-type transformer winding,
% converted to reactance at frequency f: X = 2*pi*f*L
% The factor 1/3 is an empirical geometrical coefficient for the shell-type core.
X2 = 1/3*muo*n2^2*c*(4*a+2*d+pi*c)/b*2*pi*f;

%% 4) Primary winding resistance - temperature dependent
% Same physics as r2, but for the primary winding.
r1 = rhocuivre*(1+alphacuivre*Tcuivre)*n1*l1spire/S1fil;

%% 5) Equivalent resistance referred to secondary side
% The total series resistance seen from the secondary side includes:
%   - Direct secondary resistance r2
%   - Primary resistance r1 reflected through the turns ratio squared
R2 = r2+(n2/n1)^2*r1;

%% 6) Voltage drop at full load - depends on R2, X2, and power factor
% The voltage drop across the equivalent series impedance at rated current:
%   DV2 = I2 * (R2 * cos(phi) + X2 * sin(phi))
% where cos(phi) = fp2 (secondary power factor).
DV2 = (R2*fp2+X2*sin(acos(fp2)))*I2;

%% 7) Joule (copper) losses at full load
% Power dissipated as heat in the windings: P = I^2 * R
% These losses occur in both primary and secondary windings.
Pj = R2*I2^2;

%% 8) Copper temperature - thermal equilibrium equation
% The copper temperature results from a steady-state thermal network:
%   Heat generated (Pj + Pfer) flows through thermal resistances to ambient.
% The formula solves the thermal circuit with:
%   - Rcuivreair: copper-to-air convection path
%   - Rferair: iron-to-air convection path
%   - Rfercuivre: iron-to-copper conduction path through insulation
Tcuivre = Text+Rcuivreair*(Rferair*Pfer+(Rferair+Rfercuivre)*Pj)/(Rcuivreair+Rferair+Rfercuivre);