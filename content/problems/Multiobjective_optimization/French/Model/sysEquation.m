function [residual,Jacobian] = sysEquation(conceptionVariables,parameters,innerState)
%% sysEquation.m
%% ============================================
%% RESIDUAL AND JACOBIAN OF THE IMPLICIT SYSTEM
%% ============================================
% Computes the residual vector F(x) = F(innerState) - innerState and its
% Jacobian matrix J = dF/d(innerState) for the 8 implicit equations.
%
% This function is called by the Newton-Raphson solver inside ConceptionModel
% at each iteration to compute the descent direction: DeltaX = -J^(-1) * F(X)
%
% INPUTS:
%   conceptionVariables : [a; b; c; d; n1; S1fil; S2fil] - 7 design variables
%   parameters          : [V2; V1; f; fp2; I2; Text; q; kr; h; ...
%                         lambda; e_iso; mvfer; mvcuivre; rhocuivre; alphacuivre]
%   innerState          : [r2; X2; n2; DV2; Pj; Tcuivre; r1; R2] - 8 unknowns
%
% OUTPUTS:
%   residual    : 8x1 vector, where residual(i) = equation_i - variable_i
%   Jacobian    : 8x8 matrix, where J(i,j) = d(residual_i)/d(innerState_j)

%% Helper function
% Returns the residual (8,1) and the jacobian of the system (8,8)
% All inputs must be column vectors (m,1) not row vectors (1,m)

% Ensure that the vectors are column vectors
conceptionVariables = conceptionVariables(:);
parameters = parameters(:);
innerState = innerState(:);

%% Constants
muo = 4*pi*1e-7;

%% Unpack inner state variables (Order: [r2, X2, n2, DV2, Pj, Tcuivre, r1, R2])
innerState = num2cell(innerState);
[r2,X2,n2,DV2,Pj,Tcuivre,r1,R2] =  innerState{:};

%% Unpack conception variables (Order: [a, b, c, d, n1, S1fil, S2fil])
conceptionVariables = num2cell(conceptionVariables);
[a,b,c,d,n1,S1fil,S2fil] = conceptionVariables{:};

%% Unpack fixed parameters (Order: [V2, V1, f, fp2, I2, Text, q, kr, h, lambda, e_iso, mvfer, mvcuivre, rhocuivre, alphacuivre])
parameters = num2cell(parameters);
[V2,V1,f,fp2,I2,Text,q,~,h,lambda,e_iso,mvfer,~,rhocuivre,alphacuivre] = parameters{:};

%% Pre-compute compound quantities needed for residual and Jacobian
l2spire = 2*(d+2*a)+pi*3*c/2;
Bm = 1/4*V1*sqrt(2)/(n1*a*d*pi*f);
l1spire = 2*(d+2*a)+pi*c/2;
Mfer = 4*a*d*(2*a+b+c)*mvfer;
Pfer = q*Mfer*f/50*(Bm/1)^2;
Rfercuivre = e_iso/(lambda*b*(4*a+2*d));
Sferair = 4*a*(4*a+b+2*c)+2*d*(6*a+b+2*c);
Rferair = 1/(h*Sferair);
Scuivreair = b*(4*a+2*pi*c);
Rcuivreair = 1/(h*Scuivreair);

%% ================================================================
%% RESIDUAL VECTOR (8 equations)
%% Each equation represents: residual(i) = variable_i - equation_i
%% The Newton-Raphson method seeks to find the root: F(x) = 0
%% ================================================================

% Eq(1): r2 = rho * (1 + alpha*T) * n2 * l2spire / S2fil
% Defines the secondary resistance as a function of temperature, turns, length, and cross-section.
residual(1) = r2 - rhocuivre*(1+alphacuivre*Tcuivre)*n2*l2spire/S2fil;

% Eq(2): X2 = (1/3) * mu0 * n2^2 * c * (4a+2d+pi*c) / b * 2*pi*f
% Defines the secondary leakage reactance from the empirical shell-type core geometry.
residual(2) = X2 - 1/3*muo*n2^2*c*(4*a+2*d+pi*c)/b*2*pi*f;

% Eq(3): n2 = n1 * (V2 + DV2) / V1
% Relates secondary turns to the voltage transformation ratio including voltage drop.
residual(3) = n2 - n1*(V2+DV2)/V1;

% Eq(4): DV2 = (R2*cos(phi) + X2*sin(phi)) * I2
% Voltage drop at full load: impedance drop projected onto the power factor angle.
residual(4) = DV2 - (R2*fp2+X2*sin(acos(fp2)))*I2;

% Eq(5): Pj = R2 * I2^2
% Total Joule (copper) losses referred to the secondary side.
residual(5) = Pj - R2*I2^2;

% Eq(6): Tcuivre = Text + thermal_network(Pfer, Pj)
% Copper temperature from steady-state thermal equilibrium:
%   Heat generated (iron + copper losses) flows through thermal resistances to ambient.
residual(6) = Tcuivre - Text-Rcuivreair*(Rferair*Pfer+(Rferair+Rfercuivre)*Pj)/(Rcuivreair+Rferair+Rfercuivre);

% Eq(7): r1 = rho * (1 + alpha*T) * n1 * l1spire / S1fil
% Defines the primary resistance, same physics as Eq(1) but for primary winding.
residual(7) = r1 - rhocuivre*(1+alphacuivre*Tcuivre)*n1*l1spire/S1fil;

% Eq(8): R2 = r2 + (n2/n1)^2 * r1
% Equivalent resistance referred to secondary: direct r2 plus reflected r1.
residual(8) = R2 - r2-(n2/n1)^2*r1;

residual = residual(:);

%% ================================================================
%% JACOBIAN MATRIX (8x8)
%% J(i,j) = d(residual_i) / d(innerState_j)
%% Columns correspond to: [r2, X2, n2, DV2, Pj, Tcuivre, r1, R2]
%% ================================================================
% The Jacobian is computed analytically (not numerically) for accuracy
% and efficiency. Each row i contains the partial derivatives of
% residual_i with respect to each of the 8 state variables.

if nargout >1
Jacobian = [1, 0, -rhocuivre*(1+alphacuivre*Tcuivre)*l2spire/S2fil, 0, 0, -rhocuivre*alphacuivre*n2*l2spire/S2fil, 0, 0;
    0, 1, -4/3*muo*n2*c*(4*a+2*d+pi*c)*pi*f/b, 0, 0, 0, 0, 0;
    0, 0, 1, -n1/V1, 0, 0, 0, 0;
    0, -sin(acos(fp2))*I2, 0, 1, 0, 0, 0, -fp2*I2;
    0, 0, 0, 0, 1, 0, 0, -I2^2;
    0, 0, 0, 0, -Rcuivreair*(Rferair+Rfercuivre)/(Rcuivreair+Rferair+Rfercuivre), 1, 0, 0;
    0, 0, 0, 0, 0, -rhocuivre*alphacuivre*n1*l1spire/S1fil, 1, 0;
    -1, 0, -2*n2/n1^2*r1, 0, 0, 0, -n2^2/n1^2, 1];
end

end