%% Matlab distributor example - calcualtion of Mandelbrot set using Distributor class
%   to split, distribute and merge the data.
% 2015 Victoria Rudakova, vicrucann@gmail.com

%% Input parameters for Distributor constructor
clc; clear; close all;
login = 'cryo';
path_rem = '/home/cryo/dop'; % distributed operations, destination on remote
cpath = pwd;
ipaddrs = ['172.21.9.92' ' ' '172.23.2.105' ' ' '172.23.5.77']; % list of ip addresses
path_vars = cpath;
vars = 'mnd'; % when splitting data, they will be saved under varmat.mat name on disk
path_curr = cpath;
path_cache = 0;
cache = 0;
sleeptime = 5;
path_res = 'dres'; % name of the result folder
printout = 1; % print the bash output (1) or not (0)

% ctor
distr = Distributor(login, path_rem, ipaddrs, path_vars, vars, path_cache, cache, ...
    path_curr, sleeptime, path_res, printout);

%% Mandelbrot pre-calcualtion and input data
iter = 2000;
isize = 4000;
xlim = [-2, 1]; % to split
ylim = [-1.5, 1.5]; % to split
figpos = [100 100 1000 1000];

% pre-calcualtion
x = linspace( xlim(1), xlim(2), isize );
y = linspace( ylim(1), ylim(2), isize );
[xGrid,yGrid] = meshgrid( x, y );
szx = ceil(size(xGrid,2)/distr.ncluster);

%% Distributor launch input parameters
h_split = @mandel_split;
in_split = struct('ncluster', distr.ncluster, 'xGrid', xGrid, 'yGrid', yGrid,...
    'szx', szx, 'varmat', vars, 'iter', iter);
h_kernel = @mandel_kernel;
h_merge = @mandel_merge;
in_merge = struct('isize', isize, 'ncluster', distr.ncluster, 'szx', szx, ...
    'resfold', path_res, 'varmat', vars);

out_merge = distr.launch(h_split, in_split, h_kernel, h_merge, in_merge);

%% Usage of obtained result - plot
figure;
fig = gcf;
fig.Position = figpos;
imagesc( x, y, out_merge );
axis image
colormap( [jet();flipud( jet() );0 0 0] );

% % perform the full calculation of mandelbrot on local
% fprintf('Calculation on local...\n');
% tic();
% z0 = xGrid + 1i*yGrid;
% count0 = ones( size(z0) );
% z = z0;
% for n = 0:iter
%     z = z.*z + z0;
%     inside = abs( z )<=2;
%     count0 = count0 + inside;
%     if (mod(n, iter*0.25) == 0)
%         fprintf('%i', ceil(n/iter*100));
%     elseif (mod(n,iter*0.05) == 0)
%         fprintf('.');
%     end
% end
% count0 = log( count0 );
% tlocal=toc();
% fprintf( ' -> done\n');
% 
% fprintf('\n\nLocal time vs distributed time: \n    %1.2fsecs vs %1.2fsecs \n', tlocal, tcluster);
% 
% % display local result
% figure;
% fig = gcf;
% fig.Position = figpos;
% imagesc( x, y, count0 );
% axis image
% colormap( [jet();flipud( jet() );0 0 0] );


