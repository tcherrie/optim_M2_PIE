function output = ConceptionModelLineSearch(conceptionVariables,parameters,drawConvergence)
%% ConceptionModelLineSearch.m
%% ============================================
%% TRANSFORMER MODEL WITH LINE SEARCH ENHANCEMENT
%% ============================================
% This is an enhanced version of ConceptionModel that adds a backtracking
% line search to the Newton-Raphson solver for improved robustness.
%
% The standard Newton-Raphson uses a full step (alpha=1):
%   X_new = X + DeltaX
%
% The line search version computes a step size alpha in (0,1] satisfying
% the Armijo condition (sufficient decrease):
%   ||F(X + alpha*DeltaX)||^2 <= (1 - 2*relax*alpha) * ||F(X)||^2
%
% This prevents overshooting when far from the solution, at the cost of
% extra function evaluations per Newton step. Near convergence, alpha=1.
%
% Usage: replace ConceptionModel with this function in A_LaunchModel.m
% by uncommenting the second "output = ConceptionModelLineSearch..." line.
% Inputs :  - conceptionVariables, vector [a; b; c; d; n1; S1fil; S2fil]
%           - parameters, vector [V2; V1; f; fp2; I2; Text; q; kr; h; ...
%             ... lambda; e_iso; mvfer; mvcuivre; rhocuivre; alphacuivre]
%           - drawConvergence, bool : flag to draw the residual evolution
% Outputs : - output, vector : [M_tot; Tcuivre; Tfer; DV2/V2; I10/I1; ren; f1; f2; Pj; Pfer ; EuclideanError]

if nargin ==2
    drawConvergence = false;
end

% Make sure the vectors are column-vectors
conceptionVariables = conceptionVariables(:);
parameters = parameters(:);

%% Constants
muo = 4*pi*1e-7;

%% Unpack conception variables, parameters (Order is important !!)
conceptionVariables_unpack = num2cell(conceptionVariables);
[a, b, c, d, n1, S1fil, S2fil] = conceptionVariables_unpack{:};
parameters_unpack = num2cell(parameters);
[V2, V1, f, fp2, I2, Text, q, kr, h, lambda, e_iso, mvfer, mvcuivre, rhocuivre, alphacuivre] = parameters_unpack{:};

%% Pre-processing, system of equations 1 (explicit, to complete)
Bm = 1/4*V1*sqrt(2)/(n1*a*d*pi*f);
l1spire = 2*(d+2*a)+pi*c/2;
Mfer = 4*a*d*(2*a+b+c)*mvfer;
Pfer = q*Mfer*f/50*(Bm/1)^2;
Rfercuivre = e_iso/(lambda*b*(4*a+2*d));
Sferair = 4*a*(4*a+b+2*c)+2*d*(6*a+b+2*c);
Rferair = 1/(h*Sferair);
Scuivreair = b*(4*a+2*pi*c);
Rcuivreair = 1/(h*Scuivreair);
l2spire = 2*(d+2*a)+pi*3*c/2;

%% System of equations 2 (implicit, to complete)
% Need iterative method, such as Newton-Raphson
%% Init inner state (to complete)

Tcuivre_0  = 0;
DV2_0 = 0 ;
Tcuivre = Tcuivre_0;
DV2 = DV2_0 ;

% With inner model equation
n2 = n1*(V2+DV2)/V1;
r2 = rhocuivre*(1+alphacuivre*Tcuivre)*n2*l2spire/S2fil;
X2 = 1/3*muo*n2^2*c*(4*a+2*d+pi*c)/b*2*pi*f;
r1 = rhocuivre*(1+alphacuivre*Tcuivre)*n1*l1spire/S1fil;
R2 = r2+(n2/n1)^2*r1;
DV2 = (R2*fp2+X2*sin(acos(fp2)))*I2;
Pj = R2*I2^2;
Tcuivre = Text+Rcuivreair*(Rferair*Pfer+(Rferair+Rfercuivre)*Pj)/(Rcuivreair+Rferair+Rfercuivre);

%%  Solving the inner state (to complete)
% Convergence criteria
N_max = 20 ;
rtol = 1e-6;

% Initialize vector, error, iteration count...
Xn = [r2; X2; n2; DV2; Pj; Tcuivre; r1; R2] ;
crit = 1 ;
iterCount = 1 ;
X(:,iterCount) = Xn ;
critHist(:,iterCount) = crit;

%% Define residual function handle for line search
resFun = @(x) sysEquation(conceptionVariables,parameters,x);
F0 = resFun(Xn);

%% Newton-Raphson with backtracking line search
% Unlike the standard version, this computes an adaptive step size alpha
% that ensures the residual norm decreases sufficiently at each iteration.
while ...

    % Evaluate residual and Jacobian at current iterate
    [FN, JN] = resFun(X(:,iterCount));

    % Newton descent direction
    descent = ...

    % Backtracking line search: find smallest alpha = 1, 1/2, 1/4, ...
    % that satisfies the Armijo sufficient decrease condition
    alpha = lineSearch(X(:,iterCount), descent, 0.1, resFun);

    % Update with line search step size
    Xn = ...

    % Convergence criterion: relative residual norm
    crit = ...
    critHist(:,iterCount) = crit;

    iterCount = iterCount + 1;
    X(:,iterCount) = ...

end

%% Plot convergence history if requested
if drawConvergence
    figure(1)
    title("Newton-Raphson with line search convergence")
    semilogy(critHist);
    xlabel('Iteration'); ylabel('Euclidean Error');
end

% Unpack inner state (Order is important !!)
innerState = num2cell(X(:,iterCount));
[r2,X2,n2,DV2,Pj,Tcuivre,r1,R2] =  innerState{:};
if (crit<rtol && Tcuivre>0 && DV2 >0)
    crit = norm(sysEquation(conceptionVariables,parameters,X(:,iterCount)));
else
    crit = 1e6 ;
end

%% Post-processing (to complete)
Tfer = Text+Rferair*(Rcuivreair*Pj+(Rcuivreair+Rfercuivre)*Pfer)/(Rcuivreair+Rferair+Rfercuivre);
Lmu=muo*(1/(2.12E-4+((1-2.12E-4)*(Bm/1)^(2*7.358))/((Bm/1)^(2*7.358)+1.18E+6)))*n1^2*a*d/(2*a+b+c);
Mcuivre = mvcuivre*(n1*S1fil*l1spire+n2*S2fil*l2spire);
ren = V2*I2*fp2/(V2*I2*fp2+Pfer+Pj);
P1 = Pfer+Pj+V2*I2*fp2;
Q1 = V1^2/(Lmu*2*pi*f)+X2*I2^2+V2*I2*sin(acos(fp2));
I1 = sqrt(P1^2+Q1^2)/V1;
I10 = sqrt((Pfer/V1)^2+(V1/(Lmu*2*pi*f))^2);
f1=2*n1*S1fil/(kr*b*c);
f2=2*n2*S2fil/(kr*b*c);
M_tot = Mcuivre+Mfer;

%% Ouput
output =  [M_tot; Tcuivre; Tfer; DV2/V2; I10/I1; ren; f1; f2; Pj; Pfer ; crit] ;
end


function alpha = lineSearch(innerState, descent, relax, resFun)
    %% lineSearch - Backtracking line search with Armijo condition
    %%
    %% PURPOSE:
    %%   Find a step size alpha in (0,1] that ensures sufficient decrease
    %%   in the residual norm along the descent direction.
    %%
    %%   Armijo condition: ||F(X + alpha*d)||^2 <= (1 - 2*relax*alpha) * ||F(X)||^2
    %%
    %%   Parameters:
    %%     innerState : Current solution vector (8,1)
    %%     descent    : Newton descent direction (8,1), typically negative
    %%     relax      : Relaxation parameter (default 0.1), controls sufficient decrease
    %%                  Higher values require more decrease but are harder to satisfy.
    %%     resFun     : Function handle returning the residual vector
    %%
    %% Returns:
    %%     alpha : Step size (starts at 1, halves until Armijo condition is met,
    %%             or returns 2^(-maxit) if no step satisfies the condition)

    maxit = 20;              % Maximum number of backtracking attempts
    res2 = @(x) norm(resFun(x))^2;  % Squared residual norm function
    alpha = 1;                % Start with full Newton step
    for i = 1:maxit
        % Armijo sufficient decrease condition
        if ...
            break             % Condition satisfied, use this alpha
        end
        alpha = ...;   % Halve step size and try again
    end
    if i==maxit
        disp("Line search has failed: could not find step satisfying Armijo condition");
    end
end