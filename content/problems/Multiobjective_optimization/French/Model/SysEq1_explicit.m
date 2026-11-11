%% SysEq1_explicit.m
%% ============================================
%% EXPLICIT EQUATIONS - Pre-processing Physical Quantities
%% ============================================
% This file computes the "explicit" (directly calculable) quantities used
% in the transformer design model. These variables depend only on the
% design variables [a, b, c, d, n1, S1fil, S2fil] and fixed parameters,
% without any circular dependencies.
%
% Quantities computed:
%   1. Magnetic flux density in the core (Bm)
%   2. Mean turn lengths for primary (l1spire) and secondary (l2spire) windings
%   3. Core mass (Mfer) from core volume and material density
%   4. Core (iron) losses (Pfer) using Steinmetz-like approximation
%   5. Thermal resistances for the heat transfer network:
%      - Rfercuivre: iron-to-copper (through insulation)
%      - Rferair: iron-to-air (convection from core surface)
%      - Rcuivreair: copper-to-air (convection from winding surface)
%   6. Heat transfer surface areas (Sferair, Scuivreair)

%% 1) Magnetic flux density in the core limb
% From Faraday's law: V_rms = 4.44 * f * N * Bm * A_core
% Solving for peak flux density: Bm = V1 * sqrt(2) / (4 * n1 * a * d * pi * f)
% The factor 4 arises from the shell-type core geometry (4 core legs).
% The factor sqrt(2) converts RMS primary voltage to peak value.
% Design implication: Bm must be kept below ~1.6-1.8 T to avoid core saturation.
muo = 4*pi*1e-7;
Bm = 1/4*V1*sqrt(2)/(n1*a*d*pi*f);

%% 2) Primary winding mean turn length
% The mean length per turn around the core cross-section plus window width:
%   - Two straight segments along core depth d and lateral width a: 2*(d + 2*a)
%   - Half circular arc around the core window: pi*c/2
l1spire = 2*(d+2*a)+pi*c/2;

%% 3) Core mass calculation
% Core volume for a shell-type transformer:
%   V_core = 4 * a * d * (2*a + b + c)
% This accounts for 4 legs (cross-section a x d) plus yokes.
% Mass = volume * material density (mvfer = 7800 kg/m^3 for electrical steel).
Mfer = 4*a*d*(2*a+b+c)*mvfer;

%% 4) Core (iron) losses - Steinmetz approximation
% Iron losses scale with: material quality factor (q), core mass (Mfer),
% frequency (f), and magnetic flux density squared (Bm^2).
% The reference is 50 Hz and 1 Tesla.
% Pfer = q * Mfer * (f/50) * (Bm/1)^2
% Physical origin: hysteresis losses (proportional to f) + eddy current losses (proportional to f^2).
Pfer = q*Mfer*f/50*(Bm/1)^2;

%% 5) Thermal resistance: iron to copper (through insulation layer)
% R_th = thickness / (thermal_conductivity * heat_transfer_area)
% Heat flows radially from copper windings through the insulation to the core.
Rfercuivre = e_isol/(lambda*b*(4*a+2*d));

%% 6) Heat transfer surface area: iron core exposed to ambient air
% This is the outer surface area of the shell-type core through which
% natural convection occurs. Composed of top/bottom faces and side faces.
Sferair = 4*a*(4*a+b+2*c)+2*d*(6*a+b+2*c);

%% 7) Thermal resistance: iron core to ambient air (convection)
% R_th = 1 / (convection_coefficient * surface_area)
Rferair = 1/(h*Sferair);

%% 8) Heat transfer surface area: copper windings exposed to ambient air
% The outer perimeter of the winding pack times the window height.
Scuivreair = b*(4*a+2*pi*c);

%% 9) Thermal resistance: copper windings to ambient air (convection)
Rcuivreair = 1/(h*Scuivreair);

%% 10) Secondary winding mean turn length
% The secondary winding is wound outside the primary, so its mean turn
% length is longer than the primary. The factor 3*c/2 (instead of c/2)
% accounts for the extra radial thickness of the primary winding.
l2spire = 2*(d+2*a)+pi*3*c/2;