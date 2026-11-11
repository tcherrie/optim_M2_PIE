%% SysEq3_explicit.m
%% ============================================
%% POST-PROCESSING - Performance and Output Quantities
%% ============================================
% These equations are computed AFTER solving the implicit system.
% They depend on all previously computed variables (explicit + implicit).
% These represent the final performance metrics of the transformer design.

%% 1) Iron (core) temperature - thermal network solution
% Using the same thermal resistance network as the copper temperature,
% but solving for the iron core temperature instead.
% Heat flow: Pfer flows from core to ambient through Rferair.
% Pj (copper losses) also contributes via the coupled thermal path Rfercuivre.
Tfer = Text+Rferair*(Rcuivreair*Pj+(Rcuivreair+Rfercuivre)*Pfer)/(Rcuivreair+Rferair+Rfercuivre);

%% 2) Magnetizing inductance - with saturation correction
% The magnetizing inductance depends on the core permeability, which varies
% with flux density Bm due to magnetic saturation.
% The formula uses an empirical saturation curve:
%   mu(Bm) = mu0 / (2.12e-4 + ((1-2.12e-4) * (Bm/1)^(2*7.358)) / ((Bm/1)^(2*7.358) + 1.18e6))
% This is a fitted curve for electrical steel that captures the nonlinear
% B-H relationship. At low Bm, permeability is high; at high Bm, it drops.
% L = mu(Bm) * N^2 * A_core / l_core
Lmu=muo*(1/(2.12E-4+((1-2.12E-4)*(Bm/1)^(2*7.358))/((Bm/1)^(2*7.358)+1.18E+6)))*n1^2*a*d/(2*a+b+c);

%% 3) Copper (winding) mass
% Mass = density * volume, where volume = total wire length * cross-section.
% Total wire length = primary (n1 turns * l1spire) + secondary (n2 turns * l2spire).
Mcuivre = mvcuivre*(n1*S1fil*l1spire+n2*S2fil*l2spire);

%% 4) Transformer efficiency
% Efficiency = useful output power / total input power
%   Output: V2 * I2 * power_factor
%   Input: Output + losses (iron + copper)
ren = V2*I2*fp2/(V2*I2*fp2+Pfer+Pj);

%% 5) Active power absorbed at primary
% Total input active power = output power + all losses.
P1 = Pfer+Pj+V2*I2*fp2;

%% 6) Reactive power absorbed at primary
% Reactive power has three sources:
%   - Magnetizing current: V1^2 / (Lmu * 2*pi*f)
%   - Leakage reactance: X2 * I2^2
%   - Reactive component of load current: V2 * I2 * sin(phi)
Q1 = V1^2/(Lmu*2*pi*f)+X2*I2^2+V2*I2*sin(acos(fp2));

%% 7) Primary current (full load)
% From apparent power S = sqrt(P^2 + Q^2), and I = S / V.
I1 = sqrt(P1^2+Q1^2)/V1;

%% 8) No-load (magnetizing) current
% Current required to establish the magnetic flux in the core with no load.
% Components: iron loss current (real) + magnetizing current (reactive).
I10 = sqrt((Pfer/V1)^2+(V1/(Lmu*2*pi*f))^2);

%% 9) Primary winding fill factor
% The fill factor f1 represents how much of the window area is occupied
% by copper conductors (not including insulation, ventilation, etc.).
%   f1 = 2 * n1 * S1fil / (k_r * b * c)
% where k_r (kr) is a known packing factor for the winding process.
% The factor 2 accounts for both LV and HV windings in the same window.
f1=2*n1*S1fil/(kr*b*c);

%% 10) Secondary winding fill factor
% Same definition as f1, but for the secondary winding.
f2=2*n2*S2fil/(kr*b*c);

%% 11) Total transformer mass
% Sum of core mass and winding (copper) mass.
% This is one of the two main optimization objectives (minimize mass).
M_tot = Mcuivre+Mfer;