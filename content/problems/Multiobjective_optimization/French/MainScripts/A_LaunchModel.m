%% A_LaunchModel.m
%% ============================================
%% TEST DU MODÈLE DE TRANSFORMATEUR
%% ============================================
% Ce script teste le modèle physique du transformateur (ConceptionModel.m)
% avec un jeu donné de variables de conception et affiche les résultats.
%
% OBJECTIF :
%   Avant de lancer l'optimisation, valider que le modèle produit
%   des résultats raisonnables pour une conception connue. Ce script exécute
%   le modèle avec un cas de test et trace la convergence de Newton-Raphson.
%
% UTILISATION :
%   1. Modifier conceptionVariables pour tester différentes conceptions
%   2. Décommenter la ligne 98 pour tester avec le solveur LineSearch
%   3. Exécuter dataTransfo() pour afficher toutes les quantités du modèle

%% Effacer l'espace de travail et configurer le chemin
% Nettoyer la session précédente
clc; clear; close all; path=pwd(); format short;
[s,e]=regexp(path,'.+(?=[\\/]{1,2}MainScripts)');
path=path(s:e); addpath(genpath(path)); clear s e path

%% ============================================
%% 1) DÉFINITION DES QUANTITÉS DU MODÈLE
%% ============================================

%% 1a) Variables de conception d'optimisation (7 au total)
% Ces variables définissent la géométrie du transformateur et les spécifications
% des enroulements :
%   a    : Largeur du joug latéral du noyau (m)
%   b    : Hauteur de l'ouverture de fenêtre de l'enroulement (m)
%   c    : Largeur de l'ouverture de fenêtre de l'enroulement (m)
%   d    : Épaisseur de la colonne du noyau (m)
%   n1   : Nombre de spires primaire
%   S1fil: Section du conducteur primaire (m^2)
%   S2fil: Section du conducteur secondaire (m^2)

% Plusieurs cas de test prédéfinis sont fournis à titre de référence.
% Chaque cas de test a des dimensions caractéristiques différentes.
xTest_0 = [0.0248;0.0802;0.0125;0.0187;1021;1.22e-05;4.54e-07];
xTest_1 = [0.0248;0.0802;0.0125;0.0187;1021;1.22e-05;4.54e-07];
xTest_2 = [0.0030;0.0140;0.0228;0.0800;200.0000;0.0000;0.0000;0.0000];
xTest_3 = [18e-3; 54e-3; 18e-3; 33e-3; 722; 0.32e-6; 2.8e-6];
xTest_4 = [0.0176579; 0.0184541; 0.0253506; 0.0191353; 483.817; 0.0000102611; 2.18774*10^-6];

%% ============================================
% Sélectionner le cas de test à utiliser
conceptionVariables = xTest_4;
%% ============================================


% Dépacker pour référence
a = conceptionVariables(1);  % Largeur du joug latéral
b = conceptionVariables(2);  % Hauteur de l'ouverture de l'enroulement
c = conceptionVariables(3);  % Largeur de l'ouverture de l'enroulement
d = conceptionVariables(4);  % Épaisseur de la colonne du noyau
n1 = conceptionVariables(5); % Nombre de spires primaire
S1fil = conceptionVariables(6); % Section du conducteur primaire
S2fil = conceptionVariables(7); % Section du conducteur secondaire

%% 1b) Paramètres fixes du modèle (15 au total)
% Ces paramètres sont déterminés par l'application et les choix de matériaux.
V2 = 24;                % Tension secondaire (V)
V1 = 230;               % Tension primaire (V)
f = 50;                 % Fréquence d'alimentation (Hz)
fp2 = 0.8;              % Facteur de puissance de charge secondaire (cos phi)
I2 = 8;                 % Courant secondaire (A)
Text = 40;              % Température ambiante (degC)
q = 1;                  % Coefficient de perte fer spécifique (W/kg)
kr = 0.5;               % Facteur de remplissage de la fenêtre
h = 10;                 % Coefficient de convection (W/m2/K)
lambda = 0.15;          % Conductivité thermique de l'isolation (W/m/K)
e_iso = 1e-3;           % Épaisseur de l'isolation (m)
mvfer = 7800;           % Masse volumique de l'acier (kg/m3)
mvcuivre = 8800;        % Masse volumique du cuivre (kg/m3)
rhocuivre = 1.72e-8;    % Résistivité du cuivre à 0 degC (ohm.m)
alphacuivre = 3.8e-3;   % Coefficient de température de résistivité (1/K)

% Empaqueter en vecteur colonne pour ConceptionModel
parameters = [V2; V1; f; fp2; I2; Text; q; kr; h; lambda; e_iso; mvfer; mvcuivre; rhocuivre; alphacuivre];

%% 1c) Afficher toutes les quantités du modèle dans un tableau formaté
% Ceci appelle dataTransfo() qui organise toutes les variables dans un tableau.
display = true;
if display
    disp(dataTransfo())
end

%% ============================================
%% 2) EXÉCUTION DU MODÈLE DU TRANSFORMATEUR
%% ============================================
% Exécuter le modèle physique avec tracé de convergence activé (drawConvergence=1)
% Sortie : [M_tot; Tcuivre; Tfer; DV2/V2; I10/I1; ren; f1; f2; Pj; Pfer ; crit]
drawConvergence = true;
output = ConceptionModel(conceptionVariables,parameters,drawConvergence);

% Alternative : utiliser le solveur LineSearch pour une convergence
% potentiellement meilleure sur les conceptions difficiles. Décommenter la ligne.
% output = ConceptionModelLineSearch(conceptionVariables,parameters,drawConvergence);

disp('Évaluation du modèle terminée')