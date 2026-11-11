%% C_LaunchOptimisationMultiStart.m
%% ============================================
%% OPTIMISATION À UN SEUL OBJECTIF AVEC MULTISTART
%% ============================================
% Prolongement de B_LaunchOptimisation en exécutant fmincon à PARTIR DE PLUSIEURS
% points de départ aléatoires. Cela aide à éviter les minima locaux et augmente
% la chance de trouver l'optimum global.
%
% APPROCHE :
%   1. Générer 100 points de départ aléatoires dans les bornes.
%   2. Exécuter fmincon à partir de chaque point de départ indépendamment.
%   3. Conserver uniquement les résultats convergés et sélectionner le meilleur.
%
% COMPARAISON :
%   - B_LaunchOptimisation : 1 point de départ -> 1 solution
%   - Ce script : 100 points de départ -> potentiellement 100 minima locaux explorés
%   - Scripts D/E/F : explorer le front de Pareto COMPLET (multi-objectif)

%% Effacer l'espace de travail et configurer le chemin
clc; clear; close all; path=pwd(); format short;
[s,e]=regexp(path,'.+(?=[\\/]{1,2}MainScripts)');
path=path(s:e); addpath(genpath(path)); clear s e path

%% ============================================
%% 1) BORNES DES VARIABLES D'OPTIMISATION
%% ============================================
lb = [ 3e-3 ; 14e-3 ; 6e-3 ; 10e-3 ; 200 ; 0.15e-6 ; 0.15e-6 ];
ub = [ 30e-3 ; 95e-3 ; 40e-3 ; 80e-3 ; 1200 ; 19e-6 ; 19e-6 ];

%% ============================================
%% 2) CONFIGURATION MULTISTART
%% ============================================
nStarts = 100;                  % Nombre de points de départ aléatoires
nVariables = length(lb);        % 7 variables de conception

%% Allocation mémoire pour tous les résultats
xopt = zeros(nStarts,nVariables);   % Meilleures variables de chaque exécution
fopt = zeros(nStarts,1);            % Meilleur objectif de chaque exécution
exitflag = zeros(nStarts,1);        % Statut de convergence
nEval = zeros(nStarts,1);           % Nombre d'évaluations de fonction

%% Options fmincon : SQP avec tolérance serrée
options = optimoptions('fmincon',...
                        'Algorithm','sqp',...
                        'Display','final-detailed',...
                        'ConstraintTolerance', 1e-11);

%% Objectif : minimiser les pertes (index=1) pour les pertes
myfun = @(x) ...

%% ============================================
%% 3) BOUCLE MULTISTART
%% ============================================
% Utiliser 'parfor' au lieu de 'for' pour exécuter en parallèle
% (nécessite le Parallel Computing Toolbox)
tic
for i=1:nStarts
    rng(i);                                   % Seed différent pour éviter de calculer le même avec parfor
    x0 = ...          % Point de départ aléatoire
    [xopt(i,:),fopt(i),exitflag(i),output] = ...
        fmincon(myfun,x0,[],[],[],[],lb,ub,@mycon,options);
    nEval(i) = output.funcCount;
end
toc

%% ============================================
%% 4) POST-TRAITEMENT : SÉLECTION DE LA MEILLEURE SOLUTION
%% ============================================
% Filtrer uniquement les solutions convergées (exitflag >= 1 signifie convergence réussie)
[fBest, indexmin] = min(fopt(exitflag>=1));
xopt = xopt(exitflag>=1,:);
xBest = xopt(indexmin,:);

%% Tracer la distribution des valeurs objectives à partir de tous les points de départ
plot(100*(1:sum(exitflag>=1))/nStarts, sort(fopt(exitflag>=1)), 'o'); grid on;
ylabel("Fonction objective (1 - rendement)"); xlabel("Pourcentage cumulé (%)")
title("Répartition des résultats de l'optimisation multistart")

% Afficher le meilleur résultat
disp(strcat("Meilleur résultat : 1-rendement = ", num2str(obj(xBest,1)), ...
    " | Masse = ", num2str(obj(xBest,2)), " kg"))

%% ============================================
%% ANNEXE : FONCTIONS WRAPPER
%% ============================================

function f = obj(x, index)
% Extraire un objectif de ObjContr. index : 1=pertes, 2=masse
    [f,~,~] = ObjContr(x);
    % [f,~,~] = ObjContr_linesearch(x);
    f = f(index);
end

function [g,h] = mycon(x)
% Transmettre les contraintes de ObjContr. g(x) <= 0, h(x) = 0.
    [~,g,h] = ObjContr(x);
    % [~,g,h] = ObjContr_linesearch(x);
end