%% F_LaunchNSGAII.m
%% ============================================
%% OPTIMISATION MULTI-OBJECTIF - ALGORITHME GÉNÉTIQUE NSGA-II
%% ============================================
% Ce script exécute le NSGA-II (Non-dominated Sorting Genetic Algorithm II)
% pour trouver directement le front de Pareto, sans scalarisation ni contraintes epsilon.
%
% CARACTÉRISTIQUES DU NSGA-II :
%   - Maintient une population de 500 solutions candidates
%   - Utilise le tri par non-domination pour classer les solutions par numéro de front de Pareto
%   - Utilise la distance de crowding pour maintenir la diversité
%   - Élitisme : les meilleures solutions des générations parentale et enfant survivent
%
% PARAMÈTRES PAR DÉFAUT :
%   Population : 500 individus
%   Générations : 100
%   Croisement SBX : prob=0.5, eta=0.5
%   Mutation polynomiale : prob=0.1, eta=0.5
%
% Le script exécute également gamultiobj intégré de MATLAB pour comparaison.

clear; close all; path=pwd();
[s,e]=regexp(path,'.+(?=[\\/]{1,2}MainScripts)');
path=path(s:e); addpath(genpath(path)); clear s e path

%% ============================================
%% PARAMÈTRES NSGA-II
%% ============================================

% Population et générations
nmbOfIndivs = 500;  % Nombre d'individus par génération
nmbOfGens = 100;    % Nombre de générations avant arrêt

% Référence de fonction objective
Fct = @(x) ObjContr(x);

%% Bornes des variables et paramètres d'initialisation aléatoire
lb = [ 3e-3 ; 14e-3 ; 6e-3 ; 10e-3 ; 200 ; 0.15e-6 ; 0.15e-6 ];
ub = [ 30e-3 ; 95e-3 ; 40e-3 ; 80e-3 ; 1200 ; 19e-6 ; 19e-6 ];
Ranges = [lb, ub];  % [inf; sup] pour chaque variable

% Init aléatoire : distribution uniforme (type=1) dans [lb, ub]
RandParams = [ones(7,1), lb, ub];

%% Paramètres de croisement (Croisement Binaire Simulé - SBX)
% pX = 0.5 : 50% de probabilité qu'une variable subisse un croisement
% etaX = 0.5 : eta faible signifie que les enfants peuvent être loin des parents (exploration)
%   eta élevé (ex: 20) rendrait les enfants proches des parents (exploitation)
pX = 0.5;
etaX = 0.5;

%% Paramètres de mutation (Mutation Polynomiale)
% pM = 0.1 : 10% des gènes (variables) sont mutés à chaque génération
% etaM = 0.5 : eta faible signifie de grandes mutations (exploration)
pM = 0.1;
etaM = 0.5;

%% ============================================
%% EXÉCUTION DE NSGA-II de Deb et al.
%% ============================================
fprintf('Exécution de NSGA-II (%d individus, %d générations)...\\n', nmbOfIndivs, nmbOfGens);
tic
[ParGen, ObjVals, ConstrVals, Ranking, SumOfViols, NmbOfFront] = ...
    NSGA_II(nmbOfIndivs, nmbOfGens, Fct, RandParams, Ranges, pX, etaX, pM, etaM);
tNSGA = toc;
fprintf('Terminé (%.2f s)\\n', tNSGA);

%% ============================================
%% EXÉCUTION DE NSGA-II MATLAB INTÉGRÉ
%% ============================================

% voir https://fr.mathworks.com/help/gads/gamultiobj-algorithm.html

options = optimoptions('gamultiobj', ...
    'PlotFcn', 'gaplotpareto', ...
    'PopulationSize', nmbOfIndivs, ...
    'MaxGenerations', nmbOfGens, ...
    'CrossoverFraction', pX,...
    'UseParallel', true, ...
    'ConstraintTolerance', 1e-3, ...
    'FunctionTolerance', 1e-3, ...
    'InitialPopulationRange', [lb, ub].', ...
    'ParetoFraction', 0.3,...
    'Display','iter');

[xopt_gamultiobj, fopt_gamultiobj, exitflag, output] = ...
    gamultiobj(@myfun, 7, [], [], [], [], lb, ub, @mycon, options);


%% ============================================
%% TRACÉ DES RÉSULTATS
%% ============================================


figure;
objParetoNSGAII = ObjVals(:, NmbOfFront == 1);
scatter(objParetoNSGAII(2,:), objParetoNSGAII(1,:)*100, 'ko', 'filled');
hold on;
scatter(fopt_gamultiobj(:,2), fopt_gamultiobj(:,1)*100, 'ro', 'filled');
grid on;
legend('Deb et al. NSGA-II', 'MATLAB gamultiobj');
xlabel('Masse (kg)'); ylabel('Pertes (%)');
title('Front de Pareto : NSGA-II vs gamultiobj');

%% ============================================
%% ANNEXE : FONCTIONS WRAPPER
%% ============================================


function f = myfun(x)
% Fonction objective wrapper : extraire un objectif de ObjContr.
% index : 1=pertes, 2=masse
[f,~,~] = ObjContr(x);
% [f,~,~] = ObjContr_linesearch(x);
end

function [g,h] = mycon(x)
% Wrapper de contraintes : transmettre les contraintes d'inégalité et d'égalité.
% fmincon requiert g(x) <= 0 et h(x) = 0.
 [~,g,h] = ObjContr(x);
 % [~,g,h] = ObjContr_linesearch(x);
end