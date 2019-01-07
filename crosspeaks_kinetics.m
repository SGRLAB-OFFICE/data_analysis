%% Other Assorted Calculations
dE = 667;%cm^1
%assumption: kT in wavenumbers at 298K = 207cm^-1
Keq = 2*exp(-dE/207);

%% Values
ts = 0:0.1:10;
kk1 = .01;
kk2 = 0.1;
kk3 = kk2/Keq;

%% A->B1
syms k1 k2 k3 t
V1_0 = [1; 0];


K1 = [-k1 0;
    k1 0];

[V1, D1] = eig(K1);
%V is eigen vectors
%D is eigenvalues

p1 = V1*expm(D1*t)*V1^(-1);
V1_t = p1*V1_0;
%also works
%V_t = expm(K*t)*V_0;

A_t = symfun((V1_t(1)),[k1,k2,k3,t])
B1_t = symfun((V1_t(2)),[k1,k2,k3,t])

%figure(1);clf
%plot(ts, A_t(kk1,kk2,kk3,ts),ts,B1_t(kk1,kk2,kk3,ts),'--')

%% C <-> B2

syms k1 k2 k3 t

V2_0 = [1; 0];

V2_1 = [0; 1];

K2 = [-k2 k3;
    k2 -k3];

[V2, D2] = eig(K2);
ev2 = diag(D2);

p2 = V2*expm(D2*t)*V2^(-1);
V2_t = p2*V2_0;
V2_1_t = p2*V2_1;

C_t = symfun((V2_t(1)),[k1 k2,k3,t]); %(B/R1)
B2_t = symfun((V2_t(2)),[k1 k2,k3,t]);%(B/R3)

D_t = symfun((V2_1_t(1)),[k1 k2,k3,t]);%(B/R2)
E_t = symfun((V2_1_t(2)),[k1 k2,k3,t]);%(B/R4)

% figure(2);clf
% hold on
% plot(ts, C_t(kk1,kk2,kk3,ts),ts,B2_t(kk1,kk2,kk3,ts),'--')
% plot(ts, D_t(kk1,kk2,kk3,ts),'k',ts,E_t(kk1,kk2,kk3,ts),'g--')

%%
Btotal = symfun(B1_t - B2_t, [k1,k2,k3,t]);

figure(3);clf
plot(ts, Btotal(kk1,kk2,kk3,ts),'--')


%%
amp1 = symfun(V2(1,1),[k2,k3]) %B/R1, B/R3
amp2 = symfun(V2(2,1),[k2,k3]) %B/R2, B/R4

kin = {amp1,amp2,C_t,B2_t,D_t,E_t,B1_t,A_t}
%%


