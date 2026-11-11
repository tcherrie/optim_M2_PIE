%% A_LaunchModel.m
%% ============================================
%% TRANSFORMER MODEL TESTING
%% ============================================
% This script tests the transformer physics model (ConceptionModel.m)
% with a given set of design variables and displays the results.
%
% PURPOSE:
%   Before running optimization, validate that the model produces
%   reasonable results for a known design. This script runs the model
%   with a test case and plots the Newton-Raphson convergence.
%
% USAGE:
%   1. Modify conceptionVariables to test different designs
%   2. Uncomment line 98 to test with the LineSearch-enhanced solver
%   3. Run dataTransfo() to see all model quantities in a table

%% Clear workspace and set up path
% Clean previous session
clc; clear; close all; path=pwd(); format short;
[s,e]=regexp(path,'.+(?=[\\/]{1,2}MainScripts)');
path=path(s:e); addpath(genpath(path)); clear s e path

%% ============================================
%% 1) DEFINITION OF MODEL QUANTITIES
%% ============================================

%% 1a) Optimization design variables (7 total)
% These define the transformer geometry and winding specifications:
%   a    : Lateral core leg width (m)
%   b    : Winding window height (m)
%   c    : Winding window width (m)
%   d    : Core leg thickness (m)
%   n1   : Number of primary turns
%   S1fil: Primary conductor cross-section (m^2)
%   S2fil: Secondary conductor cross-section (m^2)

% Several pre-defined test cases are provided for reference.
% Each test case has different characteristic dimensions.
xTest_0 = [0.0248;0.0802;0.0125;0.0187;1021;1.22e-05;4.54e-07];
xTest_1 = [0.0248;0.0802;0.0125;0.0187;1021;1.22e-05;4.54e-07];
xTest_2 = [0.0030;0.0140;0.0228;0.0800;200.0000;0.0000;0.0000;0.0000];
xTest_3 = [18e-3; 54e-3; 18e-3; 33e-3; 722; 0.32e-6; 2.8e-6];
xTest_4 = [0.0176579; 0.0184541; 0.0253506; 0.0191353; 483.817; 0.0000102611; 2.18774*10^-6];

%% ============================================
% Select which test case to use
conceptionVariables = xTest_4;
%% ============================================


% Unpack for reference
a = conceptionVariables(1);  % Lateral core leg width
b = conceptionVariables(2);  % Winding window height
c = conceptionVariables(3);  % Winding window width
d = conceptionVariables(4);  % Core leg thickness
n1 = conceptionVariables(5); % Primary turns
S1fil = conceptionVariables(6); % Primary conductor cross-section
S2fil = conceptionVariables(7); % Secondary conductor cross-section

%% 1b) Fixed model parameters (15 total)
% These are determined by the application and material choices.
V2 = 24;                % Secondary voltage (V)
V1 = 230;               % Primary voltage (V)
f = 50;                 % Supply frequency (Hz)
fp2 = 0.8;              % Secondary load power factor (cos phi)
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

% Pack into column vector for ConceptionModel
parameters = [V2; V1; f; fp2; I2; Text; q; kr; h; lambda; e_iso; mvfer; mvcuivre; rhocuivre; alphacuivre];

%% 1c) Display all model quantities in a formatted table
% This calls dataTransfo() which organizes all variables into a table.
display = true;
if display
    disp(dataTransfo())
end

%% ============================================
%% 2) RUN THE TRANSFORMER MODEL
%% ============================================
% Run the physics model with convergence plotting enabled (drawConvergence=1)
% Output: [M_tot; Tcuivre; Tfer; DV2/V2; I10/I1; ren; f1; f2; Pj; Pfer ; crit]
drawConvergence = true;
output = ConceptionModel(conceptionVariables,parameters,drawConvergence);

% Alternative: use the LineSearch-enhanced solver for potentially better
% convergence on difficult designs. Uncomment the line below to try it.
% output = ConceptionModelLineSearch(conceptionVariables,parameters,drawConvergence);

disp('Done evaluating the model')