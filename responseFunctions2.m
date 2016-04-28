function out = responseFunctions2(pmodes,options)
global wavenumbersToInvPs

out = [];
order = options.order;

%canonical results
Rh.n = 2;
Rh.w = [1889.184 1947.621];
Rh.mu = [sqrt(0.908) 0 0 ; 0 sqrt(0.671) 0];
Rh.w_off = 1915;
Rh.w = Rh.w - Rh.w_off;
Rh.n2 = 3;
Rh.w2 = [3767.517 3883.911 3813.698];
Rh.w2 = Rh.w2 - 2*Rh.w_off;
Rh.mu2 = zeros(Rh.n2,3,Rh.n);
Rh.mu2(:,:,1) = [sqrt(2).*Rh.mu(1,:) ; 0,0,0 ; Rh.mu(2,:)];
Rh.mu2(:,:,2) = [ 0,0,0 ; sqrt(2).*Rh.mu(2,:) ; Rh.mu(1,:)];

% default values
flag_plot = false;
w0 = 0;
n_excitons = 2;
n_exciton_sig_figs = 1;

if isfield(options,'w0')
    if isempty(options.w0)
        w0=0;
    else
        w0 = options.w0;
    end
end
if isfield(options,'flag_plot')
    flag_plot = options.flag_plot;
end

% simulation parameters
n_t = options.n_t;
n_zp = options.n_zp;
dt = options.dt; %time step
t2 = options.t2; %population time (ps)
pol = options.polarizations;
e_1 = pol{1};
e_2 = pol{2};
e_3 = pol{3};
e_4 = pol{4};
w_laser = options.w_laser;
BW = options.BW;

% set up time and response functions
J = zeros(1,n_t);
R_r = zeros(n_t,n_t);
R_nr = zeros(n_t,n_t);
t=0:dt:(n_t-1)*dt;
[T1,T3] = meshgrid(t,t);


%upack the results
f=fieldnames(pmodes);
for ii=1:length(f)
    eval(strcat(f{ii},'=pmodes.',f{ii},';'))
end

% calculate the eigenvectors of the coupled system 
[V,E]=eig(H_,'vector');
[E,ordering] = sort(E);
V = V(:,ordering); %eigenvectors in input basis
VV = eye(size(V)); %eigenvectors in eigenstate basis

%
% set up operators
%

  
    A0 = V'*A*V;
    C0 = V'*C*V;

% could add a loop over possible initial states here. The idea would be to
% look at the thermal density matrix elements relative to some cutoff. then
% loop through the response function calculation for each state with the
% appropriate thermal weight.

% density matrix
PSIi = VV(:,1); %take first eigenstate for the time being
rho = PSIi*PSIi'; % could do thermal density here!

%one way to go would be to define mui muj etc from inputs and then add
%invariants function (see thoughts below)
%tests:
%reproduce Rhcomplex 
%make sure in strong mixing dipoles are orthogonal
% check amplitudes of parallel and perp polarizations

% calc mus and omegas from inputs (ultimately want to refactor this)
% calculate the one and two exciton manifolds. Might need to be modified if
% thermal states are allowed. not sure. 

%find all one and two exciton states
[ind_1ex ind_2ex] =  findNExcitonStates(PSIi,C0,n_exciton_sig_figs);

%keep only the ones in the laser bandwidth
[ind_1ex ind_2ex] = filterExcitons(w_laser,BW,E,ind_1ex,ind_2ex);

% ind_1ex = find(abs(round(C0*PSIi,1))>0);
% ind_2ex = find(abs(round(C0*C0*PSIi,1))>0);
n = length(ind_1ex)
n2 = length(ind_2ex)

% energies -- subtract zero point energy
w = E(ind_1ex) - E(1);
w2 = E(ind_2ex) - E(1);

% subtract rotating frame frequency and convert to rad/ps
w = (w - w0)*2*pi*wavenumbersToInvPs;
w2 = (w2 - 2*w0)*2*pi*wavenumbersToInvPs;

% rotate dipole operators to the eigenstate basis
MUX = V'*MUX*V;
MUY = V'*MUY*V;
MUZ = V'*MUZ*V;

% calculate dipole matrix elements
mu = zeros(n,3);
mu2 = zeros(n2,3,n);
for ii = 1:n
    PSIf = VV(:,ind_1ex(ii));
    mu(ii,:) = [PSIf'*MUX*PSIi PSIf'*MUY*PSIi PSIf'*MUZ*PSIi];
    for jj =  1:n2
        PSIf2 = VV(:,ind_2ex(jj));
        mu2(jj,:,ii) = [PSIf2'*MUX*PSIf PSIf2'*MUY*PSIf PSIf2'*MUZ*PSIf];
    end
end

g = @(t) options.g(t,options.c2params);

%linear spectroscopy
for j = 1:n
    [~,muj] = unit_vector(mu(j,:));
    J = J + muj^2.*exp(-1i*w(j).*t);
end
%add lineshape (same for all peaks for now)
J = J.*exp(-g(t));

% first calculate all rephasing diagrams
for j = 1:n
  for i  = 1:n
    
    [aa,mui] = unit_vector(mu(i,:));
    [bb,muj] = unit_vector(mu(j,:));
    dipole = mui^2*muj^2;
    angle = polarizationInvariant(e_1,e_2,e_3,e_4,...
        aa,bb,aa,bb);
    
    % rephasing diagram R1
    R_r = R_r - dipole*angle*exp(+ 1i*w(j).*T1 ...
				 - 1i*w(i).*T3 ...
				 + 1i*(w(j)-w(i))*t2);
    % rephasing diagram R2
    R_r = R_r - dipole*angle*exp(+ 1i*w(j).*T1 ...
				 - 1i*w(i).*T3);
    
    for k = 1:n2      
      %molecular dipoles?
      [cc,muik_] = unit_vector(mu2(k,:,i));
      [dd,mujk_] = unit_vector(mu2(k,:,j));
      dipole = mui*muj*muik_*mujk_;
      angle = polarizationInvariant(e_1,e_2,e_3,e_4,...
         aa,bb,cc,dd);

     %rephasing diagram R3
      R_r = R_r + dipole*angle*exp(+ 1i*w(j).*T1 ...
				   - 1i*(w2(k)-w(j)).*T3 ...
				   + 1i*(w(j)-w(i)).*t2);
    end
  end
end
% add lineshape (same for all peaks for now)
R_r = exp(-g(T1)+g(t2)-g(T3)-g(T1+t2)-g(t2+T3)+g(T1+t2+T3)).*R_r;

% now non-rephasing diagrams
for j = 1:n
  for i  = 1:n      
    [aa,mui] = unit_vector(mu(i,:));
    [bb,muj] = unit_vector(mu(j,:));
    dipole = mui^2*muj^2;
    angle = polarizationInvariant(e_1,e_2,e_3,e_4,...
         aa,bb,aa,bb);
    
    % non-rephasing diagram R4
    R_nr = R_nr - dipole*angle*exp(- 1i*w(j).*T1 ...
				   - 1i*w(j).*T3 ... %?
				   - 1i*(w(j)-w(i))*t2);
    % non-rephasing diagram R5
    R_nr = R_nr - dipole*angle*exp(- 1i*w(j).*T1 ...
				   - 1i*w(i).*T3);
    
    for k = 1:n2      
      %molecular dipoles
      [cc,muik_] = unit_vector(mu2(k,:,i));
      [dd,mujk_] = unit_vector(mu2(k,:,j));
      dipole = mui*muj*muik_*mujk_;
      angle = polarizationInvariant(e_1,e_2,e_3,e_4,...
         aa,bb,cc,dd);
     
      %non-rephasing diagram R6
      R_nr = R_nr + dipole*angle*exp(- 1i*w(j).*T1 ...
				     - 1i*(w2(k)-w(i)).*T3 ...
				     - 1i*(w(j)-w(i)).*t2);
    end
  end
end
% add lineshape (same for all peaks for now)
R_nr = exp(-g(T1)-g(t2)-g(T3)+g(T1+t2)+g(t2+T3)-g(T1+t2+T3)).*R_nr;

% calculate 1D spectrum (freq domain)
J = real(fftshift(sgrsifft(J,n_zp)));

% divide first points (by row and column) by 2
R_r(:,1) = R_r(:,1)./2;
R_r(1,:) = R_r(1,:)./2;
R_nr(:,1) = R_nr(:,1)./2;
R_nr(1,:) = R_nr(1,:)./2;

if flag_plot
%what we have so far in the time domain
figure(1),clf
subplot(1,2,1)
contourf(real(R_r'),10); 
axis equal tight
subplot(1,2,2)
contourf(real(R_nr'),10);
axis equal tight
end

% do the fft
R_r = ifft2(R_r,n_zp,n_zp); %given the frequency definitions used
                            %above, use the ifft to get the
                            %frequencies right (Mathematica has the
                            %opposite definition of the fft by default)
R_nr = ifft2(R_nr,n_zp,n_zp);

%this is the frequency not the energy of the transitions
freq  = fftFreqAxis(t,'time_units','ps','zeropad',n_zp);
freq = freq+w0;

if flag_plot
%now frequency domain
figure(2),clf
subplot(1,2,1)
contourf(freq,freq,fftshift(real(R_r')),20); %pump-probe axis convention
%contourf(fftshift(real(R_r)),20; % the (omega_1, omega_3) axis convention
axis equal tight
subplot(1,2,2)
contourf(freq,freq,fftshift(real(R_nr')),20)
%contourf(fftshift(real(R_nr)),20)
axis equal tight
end

% flip R_r (being careful to keep zero frequency as the first time
% point), add the response functions, take the real part, and
% finally reorganize so that the 0 frequency is in the center
R = fftshift(real(fliplr(circshift(R_r,[0 -1]))+R_nr));
    

if flag_plot
figure(3),clf
n_contours = 40;
MAX = max(abs(R(:)));
level_list = linspace(-MAX,MAX,n_contours+2);
dl = level_list(2)-level_list(1);
cmin =level_list(1)-dl/2;
cmax =level_list(end);

%contourf(freq,freq,R',level_list) %use R' to display the pump-probe axis convention
contourf(freq,freq,R,level_list) %use R to display the (omega_1, omega_3) axis convention
caxis([cmin cmax]);			
axis equal tight
end

%package output
out.w1 = freq;
out.w3 = freq;
out.J = J;
out.R_r = R_r;
out.R_nr = R_nr;
out.R = R;
out.E = E;
out.V = V;
out.ind_1ex = ind_1ex;
out.ind_2ex = ind_2ex;
out.energy_gap1 = w./(2*pi*wavenumbersToInvPs)+w0;
out.energy_gap2 = w2./(2*pi*wavenumbersToInvPs)+2*w0;
out.mu1 = mu;
out.mu2 = mu2;

end

function [out,n] = unit_vector(in)
n  = norm(in,2);
if n>1e-6
out = in./n;
else
    n=0;
    out = 0*in;
end
out = out(:); %convert to a column matrix
end
