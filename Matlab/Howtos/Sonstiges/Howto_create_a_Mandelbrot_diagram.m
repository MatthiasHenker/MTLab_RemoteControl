% Howto create a Mandelbrot-Diagram
%
% goals: show diagram type 'image' and howto operate efficiently on
% matrices

% measure compute time (start)
tic

% ---- config ------------------------------------------------------------------
% Parameter for Mandelbrot-Set
maxIter        = 100;         % # of iterations (50 .. 150)
selectPlotArea = 1;           % adapt to your needs

switch selectPlotArea
    case 1    % smaller window (right hand side)
        xRange  = linspace(-0.8, 0.6, 2000); % X - plot range (real)
        yRange  = linspace(-1.1, 0.0, 2000); % Y - plot range (imaginay)
    case 2    % smaller window (left hand side
        xRange  = linspace(-1.5, -1.2, 2000); % X - plot range (real)
        yRange  = linspace(0, -0.3, 2000); % Y - plot range (imaginay)
    otherwise % default (full plot)
        xRange  = linspace(-2.2, 1.6, 2000); % X - plot range (real)
        yRange  = linspace(-1.5, 1.5, 2000); % Y - plot range (imaginay)
end

% ---- actual code -------------------------------------------------------------

% create mesh grid for complex plane
[X, Y] = meshgrid(xRange, yRange);
% constant complex offset
C = X + 1i*Y;

% initialize matrices (size of X, Y, C, and Z are identical)
Z = zeros(size(X));
k = zeros(size(X));

% Mandelbrot-loop
for cnt = 1 : maxIter
    % compute next iteration values (for whole complex plane)
    Z = Z.^2 + C;
    % check if it is divergent and save iteration depth
    k(abs(Z) > 2 & k == 0) = cnt;
    % stop further computation for divergent values in complex plane
    Z(abs(Z) > 2) = NaN;
end

% show Mandelbrot-Diagram
figure(1);
imagesc(xRange, yRange, log(k));   % log scaling looks more beautiful
colormap(jet);
axis equal;
title('Mandelbrot-Diagram');
xlabel('Re(c)');
ylabel('Im(c)');
colorbar;

% stop and show timing
toc

% EOF