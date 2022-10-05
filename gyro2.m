%%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%%
%%                                       Gyroscope Tower Simulation                                        %%
%%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%%

clear all
% clearvars
% clear global
close all

g = 9.8;														% Gravitational acceleration (m/s^2)
omega = 10;														% Initial angular velocity (rad/s)
r = 1;															% Radius of wheel (m)
a = 0.5;														% Length of axle (m)
n = 20;															% Number of points on the rim
M_rim = 1;														% Total mass of the rim (kg)
M_axle = 1;														% Total mass of the axle (kg)
S_rim = 2000 * (M_rim / n) * omega ^ 2;							% StifWfness of each rim link (kg/s^2)
D_rim = 0 * (M_rim / n) * omega;								% Damping constant of each rim link (kg/s)
S_spoke = S_rim;												% Stiffnes of each spoke (kg/s^2)
D_spoke = D_rim;												% Damping constant of each spoke (kg/s)
S_axle =  S_rim;												% Stiffness of the axle (kg/s^2)
D_axle =  D_rim;												% Damping constant of the axle (kg/s)

figure(1)														% Setup for animation
nskip = 5;														% Clock skip
ngyro = 3;														% Number of gyroscopes
lr = zeros(1, ngyro * n);										% Rim links
ls = zeros(1, ngyro * 2 * n);									% Spoke links
la = zeros(1, ngyro);											% Axle link
X = zeros((n + 2) * ngyro, 3);									% Coordinates of points
jj = zeros((3 * n + 1) * ngyro, 1);								% Indices of points on one end of the links
kk = zeros((3 * n + 1) * ngyro, 1);								% Indices of points on the other end of the links
S = zeros((3 * n + 1) * ngyro, 1);								% Stiffness of links
D = zeros((3 * n + 1) * ngyro, 1);								% Damping constant of links
Rzero = zeros((3 * n + 1) * ngyro, 1);							% Rest length of links
M = zeros((n + 2) * ngyro, 1);									% Mass of points
for gyro = 1 : ngyro											% Update information for each gyroscope
	lr((gyro - 1) * n + 1 : gyro * n) = (gyro - 1) * (3 * n + 1) + 1 : (gyro - 1) * (3 * n + 1) + n;
	ls((gyro - 1) * 2 * n + 1 : gyro * 2 * n) = (gyro - 1) * (3 * n + 1) + n + 1 : (gyro - 1) * (3 * n + 1) + 3 * n;
	la(gyro) = (gyro - 1) * (3 * n + 1) + 3 * n + 1;
	[kmax, lmax, X((gyro - 1) * (n + 2) + 1 : gyro * (n + 2), :), ...
		jj((gyro - 1) * (3 * n + 1) + 1 : gyro * (3 * n + 1)), ...
		kk((gyro - 1) * (3 * n + 1) + 1 : gyro * (3 * n + 1)), ...
		S((gyro - 1) * (3 * n + 1) + 1 : gyro * (3 * n + 1)), ...
		D((gyro - 1) * (3 * n + 1) + 1 : gyro * (3 * n + 1)), ...
		Rzero((gyro - 1) * (3 * n + 1) + 1 : gyro * (3 * n + 1)), ...
		M((gyro - 1) * (n + 2) + 1 : gyro * (n + 2))] = ...
		wheel(r, a, (gyro - 1) * a, n, M_rim, M_axle, S_rim, D_rim, S_spoke, D_spoke, S_axle, D_axle, (gyro - 1) * (n + 2));
end

hr = plot3([X(jj(lr), 1), X(kk(lr), 1)]', [X(jj(lr), 2), X(kk(lr), 2)]', ...
	[X(jj(lr), 3), X(kk(lr), 3)]', "r", "linewidth", 3);
axis([-1.2 * r, 1.2 * r, -1.2 * r, 1.2 * r, -1.2 * a, 1.2 * a]);
hold on
hs = plot3([X(jj(ls), 1), X(kk(ls), 1)]', [X(jj(ls), 2), X(kk(ls), 2)]', ...
	[X(jj(ls), 3), X(kk(ls), 3)]', "b");
ha = plot3([X(jj(la), 1), X(kk(la), 1)]', [X(jj(la), 2), X(kk(la), 2)]', ...
	[X(jj(la), 3), X(kk(la), 3)]', "k", "linewidth", 3);
hold off
axis equal
axis manual
axis([-1.2 * r, 1.2 * r, -1.2 * r, 1.2 * r, -0.2, 5])
drawnow

tmax = 20;														% Duration of simulation (s)
clockmax = 10000;												% Number of time steps
dt = tmax / clockmax;											% Time step (s)

t_ext_start = 2;												% Time that external force starts (s)
t_ext_stop = 3;													% Time that external force stops (s)
F_ext = 0.5 * [1, 0, 0] * M_rim * g;							% External force (kg·m/s^2)
U = omega * [-X(:, 2), X(:, 1), zeros(ngyro * kmax, 1)];		% Initial velocity

for clock = 1 : clockmax

	t = clock * dt;
	DX = X(jj, :) - X(kk, :);									% Link vectors
	DU = U(jj, :) - U(kk, :);									% Link velocity difference vectors
	R = sqrt(sum(DX .^ 2, 2));									% Link lengths
  	T = S .* (R - Rzero) + (D ./ R) .* sum(DX .* DU, 2);		% Link tensions
	TR = T ./ R;												% Link tensions divided by link lengths
	FF = [TR, TR, TR] .* DX;									% Link force vectors

	F = zeros(ngyro * kmax, 3);									% Initialize force array for mass points 
	F(:, 3) = -M * g;											% Apply gravitational force to each link point

	for link = 1 : lmax
		F(kk(link), :) = F(kk(link), :) + FF(link, :);			% Add force of the link to one end
		F(jj(link), :) = F(jj(link), :) - FF(link, :);			% Add force of the link to the other end
	end

	if (t > t_ext_start) && (t < t_ext_stop)
		F(ngyro * (n + 2), :) = F(ngyro * (n + 2), :) + F_ext;	% Apply external force during specified time interval
	end

	U = U + dt * F ./ [M, M, M];								% Update velocities of all points
	U(n + 1, :) = 0; 											% The fixed point must have velocity zero
	for gyro = 2 : ngyro
		U(gyro * (n + 2) - 1, :) = U((gyro - 1) * (n + 2));		% The bottom of upper gyroscope is attached to the top of its lower
	end
	X = X + dt * U;												% Update positions of all points
  
	%%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%%
	%%                                                Animation                                                %%
	%%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%% %%%%%%%%%%
	if mod(clock, nskip) == 0
		c = 0;
		for l = lr
			c = c + 1;
			hr(c).XData = [X(jj(l), 1), X(kk(l), 1)];
			hr(c).YData = [X(jj(l), 2), X(kk(l), 2)];
			hr(c).ZData = [X(jj(l), 3), X(kk(l), 3)];
		end
		c = 0;
		for l = ls
			c = c + 1;
			hs(c).XData = [X(jj(l), 1), X(kk(l), 1)];
			hs(c).YData = [X(jj(l), 2), X(kk(l), 2)];
			hs(c).ZData = [X(jj(l), 3), X(kk(l), 3)];
		end
		c = 0;
		for l = la
			c = c + 1;
			ha(c).XData = [X(jj(l), 1), X(kk(l), 1)];
			ha(c).YData = [X(jj(l), 2), X(kk(l), 2)];
			ha(c).ZData = [X(jj(l), 3), X(kk(l), 3)];
		end
		drawnow
    end

end