%% B_LaunchOptimisation.m
%% ============================================
%% OPTIMISATION À UN SEUL OBJECTIF (SQP fmincon)
%% ============================================
% Ce script démontre l'optimisation mono-objectif utilisant le solveur fmincon de MATLAB
% avec l'algorithme de Programmation Quadrille Sequential (SQP).
%
% OBJECTIF :
%   Un seul objectif est choisi : soit minimiser les pertes (index=1) soit
%   minimiser la masse (index=2). L'autre objectif n'est pas considéré.
%   Cela produit UN seul point sur le front de Pareto.
%
% Pour explorer le front de Pareto complet, utiliser :
%   - D_LaunchOptimisationPonderation.m (somme pondérée / scalarisation)
%   - E_LaunchOptimisationEpsConstr.m (contrainte epsilon)
%   - F_LaunchNSGAII.m (algorithme évolutionnaire)

%% Effacer l'espace de travail et configurer le chemin
clc; clear; close all; path=pwd(); format short;
[s,e]=regexp(path,'.+(?=[\\/]{1,2}MainScripts)');
path=path(s:e); addpath(genpath(path)); clear s e path

%% ============================================
%% 1) BORNES DES VARIABLES D'OPTIMISATION
%% ============================================
% Ordre : [a ; b ; c ; d ; n1 ; S1 ; S2]
lb = [ 3e-3 ; 14e-3 ; 6e-3 ; 10e-3 ; 200 ; 0.15e-6 ; 0.15e-6 ]; % Bornes inférieures
ub = [ 30e-3 ; 95e-3 ; 40e-3 ; 80e-3 ; 1200 ; 19e-6 ; 19e-6 ];  % Bornes supérieures

%% ============================================
%% 2) EXÉCUTION DE fmincon (ALGORITHME SQP)
%% ============================================

%% 2a) Estimation initiale : point aléatoire dans les bornes
x0 = ...

%% 2b) Configurer et exécuter fmincon
% SQP approxime la Hessienne du Lagrangien par des mises à jour BFGS.
% Adapté pour les problèmes d'optimisation contraintes lisses.
options = optimoptions('fmincon',...
                        'Algorithm','sqp',...
                        'Display','iter-detailed');

% Choisir l'objectif : index=1 pour les pertes, index=2 pour la masse
% voir annexe à la fin du fichier.
myfunfmincon = @(x) ... ;

% fmincon résout : min f(x) s.t. lb <= x <= ub, g(x) <= 0, h(x) = 0
% voir documentation fmincon pour la signature de fonction et détails.
[xopt, fopt, exitflag] = fmincon(... , options);

% Afficher les résultats complets (les deux objectifs)
obj = ObjContr(xopt);
disp(strcat("pertes = ", num2str(obj(1) * 100), " % | masse = ", num2str(obj(2)),' kg'))

%% Référence du exitflag :
%  1 : Convergence (optimalité du premier ordre satisfaite)
% >1 : Convergence (autres critères de convergence satisfaits)
%  0 : Itérations maximales atteintes (peut ne pas avoir convergé)
% <=-1 : Aucune solution réalisable trouvée

%% ============================================
%% ANNEXE : FONCTIONS WRAPPER
%% ============================================

function f = myfun(x, index)
% Fonction objective wrapper : extraire un objectif de ObjContr.
% index : 1=pertes, 2=masse
[f,~,~] = ObjContr(x);
% [f,~,~] = ObjContr_linesearch(x);
f = f(index);
end

function [g,h] = mycon(x)
% Wrapper de contraintes : transmettre les contraintes d'inégalité et d'égalité.
% fmincon requiert g(x) <= 0 et h(x) = 0.
 [~,g,h] = ObjContr(x);
 % [~,g,h] = ObjContr_linesearch(x);
end