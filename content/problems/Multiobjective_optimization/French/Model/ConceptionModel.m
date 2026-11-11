function output = ConceptionModel(conceptionVariables,parameters,drawConvergence)
%% ConceptionModel.m
%% ============================================
%% TRANSFORMER DESIGN MODEL - Complete Physics-Based Simulator
%% ============================================
% Solves the coupled electromagnetic and thermal model of a shell-type
% single-phase transformer to predict its performance for a given set of
% design variables.
%
% MODEL STRUCTURE:
%   Phase 1 (Explicit) : Directly compute geometric and material quantities
%   Phase 2 (Implicit) : Solve 8 coupled nonlinear equations via Newton-Raphson
%                        for: [r2, X2, n2, DV2, Pj, Tcuivre, r1, R2]
%   Phase 3 (Explicit) : Compute performance metrics (efficiency, mass, fill factors)
%
% PHYSICAL COUPLING:
%   Electromagnetics (flux density -> losses -> temperatures)
%   Thermal network (losses -> temperature rise -> resistance changes)
%   Electrical impedance (temperature -> resistance -> voltage drop -> losses)
%
% OUTPUT: [M_tot; Tcuivre; Tfer; DV2/V2; I10/I1; ren; f1; f2; Pj; Pfer ; crit]
%   M_tot : Total mass (kg), Tcuivre : Copper temp (degC), Tfer : Iron temp (degC)
%   DV2/V2 : Normalized voltage drop, I10/I1 : Magnetizing current ratio
%   ren : Efficiency, f1/f2 : Fill factors, Pj/Pfer : Copper/Iron losses (W)
%   crit : Residual norm (1e6 if not converged)

% Solve the transformer model
% Inputs :  - conceptionVariables, vector [a; b; c; d; n1; S1fil; S2fil]
%           - parameters, vector [V2; V1; f; fp2; I2; Text; q; kr; h; ...
%             ... lambda; e_iso; mvfer; mvcuivre; rhocuivre; alphacuivre]
%           - drawConvergence, bool : flag to draw the Newton-Raphson residual evolution

%% Optional convergence plotting
if nargin ==2
    drawConvergence = false;
end

% Ensure all inputs are column vectors
conceptionVariables = conceptionVariables(:);
parameters = parameters(:);

%% ============================================
%% PHASE 1: EXPLICIT PRE-PROCESSING
%% ============================================

%% Constants
muo = 4*pi*1e-7;  % Permeability of free space (H/m)

%% Unpack the 7 design variables: a,d = core dimensions, b,c = window dimensions
% n1 = primary turns, S1fil/S2fil = conductor cross-sections
conceptionVariables_unpack = num2cell(conceptionVariables);
[a, b, c, d, n1, S1fil, S2fil] = conceptionVariables_unpack{:};

%% Unpack the 15 fixed parameters (V2,V1,f,fp2,I2,Text,q,kr,h,lambda,e_iso,
% mvfer,mvcuivre,rhocuivre,alphacuivre)
parameters_unpack = num2cell(parameters);
[V2, V1, f, fp2, I2, Text, q, kr, h, lambda, e_iso, mvfer, mvcuivre, rhocuivre, alphacuivre] = parameters_unpack{:};

%% 1a) Magnetic flux density and mean turn lengths
Bm = 1/4*V1*sqrt(2)/(n1*a*d*pi*f);  % From Faraday's law; factor 4 for 4-leg core
l1spire = 2*(d+2*a)+pi*c/2;          % Primary mean turn length
l2spire = 2*(d+2*a)+pi*3*c/2;        % Secondary (wound outside primary)

%% 1b) Core mass and iron losses
Mfer = 4*a*d*(2*a+b+c)*mvfer;  % Core volume * density
Pfer = q*Mfer*f/50*(Bm/1)^2;   % Iron losses (Steinmetz approximation)

%% 1c) Thermal resistance network
Rfercuivre = e_iso/(lambda*b*(4*a+2*d));  % Through insulation layer
Sferair = 4*a*(4*a+b+2*c)+2*d*(6*a+b+2*c);
Rferair = 1/(h*Sferair);                  % Core-to-air convection
Scuivreair = b*(4*a+2*pi*c);
Rcuivreair = 1/(h*Scuivreair);            % Winding-to-air convection

%% ============================================
%% PHASE 2: IMPLICIT SYSTEM - INITIAL GUESS
%% ============================================
% 8 implicit variables [r2, X2, n2, DV2, Pj, Tcuivre, r1, R2] are coupled
% via circular dependencies requiring iterative Newton-Raphson solution.

Tcuivre_0  = 0;  % Initial copper temp = ambient
DV2_0 = 0;       % Initial voltage drop = 0
Tcuivre = Tcuivre_0;
DV2 = DV2_0;

%% Initial estimates for all 8 implicit variables
n2 = n1*(V2+DV2)/V1;
r2 = rhocuivre*(1+alphacuivre*Tcuivre)*n2*l2spire/S2fil;
X2 = 1/3*muo*n2^2*c*(4*a+2*d+pi*c)/b*2*pi*f;
r1 = rhocuivre*(1+alphacuivre*Tcuivre)*n1*l1spire/S1fil;
R2 = r2+(n2/n1)^2*r1;
DV2 = (R2*fp2+X2*sin(acos(fp2)))*I2;
Pj = R2*I2^2;
Tcuivre = Text+Rcuivreair*(Rferair*Pfer+(Rferair+Rfercuivre)*Pj)/(Rcuivreair+Rferair+Rfercuivre);

%% ============================================
%% PHASE 2: NEWTON-RAPHSON SOLVER
%% Solve 8x8 nonlinear system: F(innerState) = innerState
%% ============================================
% Convergence parameters
N_max = 100;  % Maximum number of iterations
rtol = 1e-6;  % Relative tolerance

% X stores the solution trajectory: rows = state vars, cols = iterations
% State variable order: [r2; X2; n2; DV2; Pj; Tcuivre; r1; R2]
Xn = [r2; X2; n2; DV2; Pj; Tcuivre; r1; R2];
crit = 1;
iterCount = 1;
X(:,iterCount) = Xn;
critHist(:,iterCount) = crit;

%% Newton-Raphson iteration
while ...
    % Evaluate residual and Jacobian at current iterate
    [FN, JN] = sysEquation(conceptionVariables,parameters,X(:,iterCount));
    % Solve for Newton descent direction
    DeltaX = ... ;
    % Update solution
    Xn = ... ;
    % Check relative change norm as convergence criterion
    crit = ...;
    % Store in trajectory
    iterCount = iterCount + 1;
    X(:,iterCount) = Xn;
    critHist(:,iterCount) = crit;
end

%% Plot convergence history if requested
if drawConvergence
    figure(1)
    title("Newton-Raphson convergence")
    semilogy(critHist);
    xlabel('Iteration'); ylabel('Euclidean Error');
end

%% Final validation: check convergence and physical feasibility
innerState = num2cell(X(:,iterCount));
[r2,X2,n2,DV2,Pj,Tcuivre,r1,R2] =  innerState{:};
% Flag as infeasible if not converged or if temperature/voltage drop are non-physical
if (crit<rtol && Tcuivre>0 && DV2 >0)
    crit = norm(sysEquation(conceptionVariables,parameters,X(:,iterCount)));
else
    crit = 1e6;
end

%% ============================================
%% PHASE 3: POST-PROCESSING - PERFORMANCE METRICS
%% ============================================

%% 3a) Thermal: iron temperature from thermal network
Tfer = Text+Rferair*(Rcuivreair*Pj+(Rcuivreair+Rfercuivre)*Pfer)/(Rcuivreair+Rferair+Rfercuivre);

%% 3b) Magnetizing inductance with saturation correction
% Empirical B-H curve fit for electrical steel captures nonlinear permeability
Lmu=muo*(1/(2.12E-4+((1-2.12E-4)*(Bm/1)^(2*7.358))/((Bm/1)^(2*7.358)+1.18E+6)))*n1^2*a*d/(2*a+b+c);

%% 3c) Copper mass
Mcuivre = mvcuivre*(n1*S1fil*l1spire+n2*S2fil*l2spire);

%% 3d) Efficiency and power calculations
ren = V2*I2*fp2/(V2*I2*fp2+Pfer+Pj);       % Efficiency
P1 = Pfer+Pj+V2*I2*fp2;                     % Total active input power
Q1 = V1^2/(Lmu*2*pi*f)+X2*I2^2+V2*I2*sin(acos(fp2));  % Total reactive input power
I1 = sqrt(P1^2+Q1^2)/V1;                   % Full-load primary current
I10 = sqrt((Pfer/V1)^2+(V1/(Lmu*2*pi*f))^2); % No-load magnetizing current

%% 3e) Winding fill factors (copper area / available window area)
f1=2*n1*S1fil/(kr*b*c);
f2=2*n2*S2fil/(kr*b*c);

%% 3f) Total mass
M_tot = Mcuivre+Mfer;

%% OUTPUT
% [M_tot; Tcuivre; Tfer; DV2/V2; I10/I1; ren; f1; f2; Pj; Pfer ; crit]
output =  [M_tot; Tcuivre; Tfer; DV2/V2; I10/I1; ren; f1; f2; Pj; Pfer ; crit] ;
end

