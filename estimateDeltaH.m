function Delta_H = estimateDeltaH(T2_star,tau_H)
% estimateDeltaH instantaneous frequency standard deviation for homogeneous
% motions
%
% Delta_H = estimateDeltaH(T2_star,tau_H) provides an estimate of the
% standard deviation of the instantaneous frequency distribution that is in
% the homogeneous linewidth for an ensemble of oscillators.
%
% T2_star and tau_H should be in reciprocal units of ps (i.e. ps^-1 and
% ps).
%
% Using a dephasing time (T2) rather than a pure dephasing time (T2*) will
% result in an overestimate of the standard deviation (\Delta_H).
%
% This calculation also accounts for the conversion from angular frequency
% to frequency.

c = 2.9979e10;
wavenumbersToInvPs=c*1e-12;
invPsToWavenumbers=1/wavenumbersToInvPs;
Delta_H = sqrt(1/(T2_star*tau_H))*invPsToWavenumbers/(2*pi);


% \Delta_H = (T2* \tau_H)^{-1/2}  / (2 pi c)