%% E_LaunchOptimisationEpsConstr.m
%% ============================================
%% OPTIMISATION MULTI-OBJECTIF - MÉTHODE PAR CONTRAINTE EPSILON
%% ============================================
% Ce script trace le front de Pareto en utilisant la méthode par contrainte epsilon.
% Au lieu de pondérer les objectifs, on minimise UN objectif tandis que
% L'AUTRE est contraint d'être en dessous d'un seuil spécifié (epsilon).
%
% MÉTHODE : Contrainte epsilon (bidirectionnel, contrôlé par mass_or_loss_constr)
%   mass_or_loss_constr = 1 :
%     Minimiser : obj_pertes
%     Sous contrainte : obj_masse <= epsilon_target
%   mass_or_loss_constr = 2 :
%     Minimiser : obj_masse
%     Sous contrainte : obj_pertes <= epsilon_target
%
% En balayant epsilon_target, nous traçons l'intégralité du front de Pareto.
% Chaque valeur epsilon donne un point différent.
%
% AVANTAGES par rapport à la scalarisation :
%   - Garantit des points réalisables (les contraintes sont des limites dures)
%   - Peut trouver des parties non convexes du front de Pareto
%   - Pas besoin de normaliser les objectifs ou d'ajuster les poids
%
% ALGORITHME :
%   1. Balayer la cible à travers nEps valeurs entre constMin et constMax.
%   2. Pour chaque cible, exécuter nStarts optimisations multistart.
%   3. Chaque optimisation minimise un objectif sous contrainte sur l'autre.

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
%% 2) PARAMÈTRES CONTRAINTE EPSILON
%% ============================================
mass_or_loss_constr = ...; % 1 = contrainte sur masse ; 2 = contrainte sur pertes
constMin = ...;
constMax = ...;

nStarts = 20;               % Points multistart par valeur epsilon
nEps = 20;                  % Nombre de valeurs epsilon
nVariables = length(lb);

% Allocation mémoire
xopt = zeros(nStarts,nVariables);
fopt = zeros(nStarts,1);
exitflag = zeros(nStarts,1);

% Options fmincon
options = optimoptions('fmincon',...
                        'Algorithm','sqp',...
                        'Display','off',...
                        'ConstraintTolerance',1e-9);


targetList = linspace(constMin, constMax, nEps);
nEval = 0;

%% ============================================
%% 3) CONTRAINTE EPSILON + BOUCLE MULTISTART
%% ============================================
for i = 1:nEps
    disp(strcat(num2str(i),"/",num2str(nEps)))
    massTarget = targetList(i);

    % Créer la fonction de contrainte incluant la limite masse ou pertes
    
    myconstr = @(x)  ...
    myfunfmincon = @(x) ...

    nEvals = zeros(nStarts,1);

    % Boucle parallèle
    parfor j=1:nStarts
        rng(i*10 + j*100);
        x0 = ...
        [xopt(j,:),fopt(j),exitflag(j),output] = fmincon(myfunfmincon,x0,[],[],[],[],lb,ub,myconstr,options);
        nEvals(j) = output.funcCount;
    end

    nEval = nEval + sum(nEvals);

    % Sélectionner le meilleur résultat
    [fBest(i), indexmin] = min(fopt(exitflag>=1));
    xopt = xopt(exitflag>=1,:);
    xBest(i,:) = xopt(indexmin,:);
    obj = ObjContr(xBest(i,:));
    loss(i) = obj(1); mass(i) = obj(2);
end

%% ============================================
%% 4) POST-TRAITEMENT : TRACÉ DU FRONT DE PARETO
%% ============================================

scatter(mass, loss*100, 50, targetList, '*');
grid on;
ylabel("Pertes (%)"); xlabel("Masse (kg)"); colormap("jet")
title("Front de Pareto - Méthode par Contrainte Epsilon");
col = colorbar; ylabel(col, 'Masse cible (kg)');

% Enregistrer les résultats
if mass_or_loss_constr == 1
    save("Pareto_eps_mass_constraint", "mass", "loss", "targetList", "nEval")
elseif mass_or_loss_constr == 2
    save("Pareto_eps_loss_constraint", "mass", "loss", "targetList", "nEval")
end
%% ============================================
%% ANNEXE : FONCTIONS WRAPPER
%% ============================================

function f = myfun(x, index)
% Fonction objective wrapper : extraire un objectif de ObjContr.
% index : 1=pertes, 2=masse
%[f,~,~] = ObjContr(x);
[f,~,~] = ObjContr_linesearch(x);
f = f(index);
end

function [g,h] = constr(x, target, index)
% Contraintes : standard + masse <= masseTarget
    %[~,g,h] = ObjContr_epsilon(x, target, index);
    [~,g,h] = ObjContr_epsilon_linesearch(x, target, index);
end