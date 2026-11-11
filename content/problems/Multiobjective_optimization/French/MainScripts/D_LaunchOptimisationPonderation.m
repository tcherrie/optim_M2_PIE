%% D_LaunchOptimisationPonderation.m
%% ============================================
%% OPTIMISATION MULTI-OBJECTIF - SCALARISATION PAR SOMME PONDÉRÉE
%% ============================================
% Ce script trace le front de Pareto en optimisant la SOMME PONDÉRÉE des
% deux objectifs. En faisant varier le paramètre de poids omega de 0 à 1, nous
% balayons différents compromis entre pertes et masse.
%
% MÉTHODE : Scalarisation (somme pondérée)
%   Minimiser : omega * (obj_pertes / norm_pertes) + (1-omega) * (obj_masse / norm_masse)
%
% Cette méthode fonctionne bien pour tracer les fronts de Pareto convexes.
% Les facteurs de normalisation mettent les deux objectifs
% à des ordres de grandeur similaires afin qu'aucun ne domine la somme pondérée.
%
% ALGORITHME :
%   1. Balayer omega à travers nOmega valeurs dans [0, 1].
%   2. Pour chaque omega, exécuter nStarts optimisations multistart (parallelisées).
%   3. Enregistrer la meilleure solution pour chaque omega.
%
% SORTIE : Un graphique en nuage de points du front de Pareto colorié par la valeur de omega.

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
%% 2) PARAMÈTRES DE SCALARISATION
%% ============================================
nStarts = 20;               % Points multistart par valeur de omega
nOmega = 20;                % Nombre de valeurs de poids différentes
nVariables = length(lb);    % 7 variables de conception

norm_mass = ...;           % Coefficient de normalisation - masse
norm_loss = ...;           % Coefficient de normalisation - pertes

%% Allocation mémoire
xopt = zeros(nStarts,nVariables);
fopt = zeros(nStarts,1);
exitflag = zeros(nStarts,1);
nEval = 0;

%% Options fmincon : SQP, discret, tolérance serrée
options = optimoptions('fmincon',...
                        'Algorithm','sqp',...
                        'Display','off',...
                        'ConstraintTolerance',1e-9);

% Valeurs de poids balayant de 0 (masse uniquement) à 1 (pertes uniquement)
OmegaList = linspace(0,1,nOmega);

%% ============================================
%% 3) BOUCLE SOMME PONDÉRÉE + MULTISTART
%% ============================================
for i = 1:nOmega
    disp(strcat(num2str(i),"/",num2str(nOmega)))
    omega = OmegaList(i);

    % Fonction objective somme pondérée normalisée avec valeurs maximales typiques de pertes et masse
    % La normalisation garantit que les deux objectifs contribuent également quelle que soit l'échelle.
    myfun = @(x) ...

    nEvals = zeros(nStarts,1);

    % Boucle parallèle : chaque point de départ s'exécute indépendamment
    parfor j=1:nStarts
        rng(i*10 + j*100);                % Seed unique par exécution
        x0 = ...;  % Estimation initiale aléatoire
        [xopt(j,:),fopt(j),exitflag(j),output] = fmincon(myfun,x0,[],[],[],[],lb,ub,@mycon,options);
        nEvals(j) = output.funcCount;
    end

    nEval = nEval + sum(nEvals);

    % Sélectionner le meilleur résultat de cette valeur de omega
    [fBest(i), indexmin] = min(fopt(exitflag>=1));
    xopt = xopt(exitflag>=1,:);
    xBest(i,:) = xopt(indexmin,:);
    loss(i) = obj(xBest(i,:), 1);
    mass(i) = obj(xBest(i,:), 2);
end

%% ============================================
%% 4) POST-TRAITEMENT : TRACÉ DU FRONT DE PARETO
%% ============================================
scatter(mass, loss*100, 10, OmegaList, 'o', 'filled', ...
    'DisplayName', sprintf('SQP multistart - %d évaluations de fonction', nEval));
grid on;
ylabel("Pertes (%)"); xlabel("Masse (kg)"); colormap("jet")
title("Front de Pareto via Scalarisation par Somme Pondérée");
col = colorbar; ylabel(col, 'Omega (poids sur les pertes)');

% Enregistrer les résultats
save("Pareto_ponderation", "mass", "loss", "OmegaList", "nEval")

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
% Transmettre les contraintes de ObjContr.
    [~,g,h] = ObjContr(x);
    % [~,g,h] = ObjContr_linesearch(x);
end