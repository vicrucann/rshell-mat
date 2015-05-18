%% Example of matlab scrips that launches bash script to control data parallelization among servers
% Two examples are considered: calculation of madelbrodt set and two
% matricies summation

%% Setting up
login = 'cryo';
ppath = '/home/cryo/tester';
ipaddrs = ['172.23.2.105' ' ' '172.23.5.77'];
remmat = ''; % definition given below for each example case
varmat = ''; % definition given below for each example case
sleeptime = 10;
bashscript = fullfile(pwd,'dhead.sh'); % main bash script that organizes data processing

[ncluster ~] = find(ipaddrs==' '); % to break data into n clusters (as many as given servers)
ncluster = ncluster+1;

%% Two matrices summation
% Given two large matrices, find its sum
remmat = 'sumvar.m';

%% Mandelbrot set
% Given resolution and iteration number, find corresponding Mandelbrodt set

% name of matlab function to be run on remote server
remmat = 'mandelbrodt'; % name of matlab function that will be launched on remote server
varmat = 'mandelbrodt'; % when splitting data, they will be saved under varmat.mat name on disk

% input parameters
iter = 500;
isize = 1000;
xlim = [-2, 1]; % to split
ylim = [-1.5, 1.5]; % to split
x = linspace( xlim(1), xlim(2), isize );
y = linspace( ylim(1), ylim(2), isize );
[xGrid,yGrid] = meshgrid( x, y );
szx = ceil(size(xGrid,2)/ncluster);

% perform the split (assume we break along "X" dimension)
for i=1:ncluster
    if (i ~= ncluster)
        xi=xGrid(:, szx*(i-1)+1:szx*i);
        yi=yGrid(:, szx*(i-1)+1:szx*i);
    else
        xi=xGrid(:, szx*(i-1)+1:end);
        yi=yGrid(:, szx*(i-1)+1:end);
    end
    save([varmat int2str(i) '.mat'], 'xi', 'yi', 'iter');
end
% assert the mentioned files exist(in bash file)
if (~exist(bashscript))
    error('No file found: check the bash script file name');
end
system(['chmod u+x ' bashscript])
cmdStr = [bashscript ' ' login ' ' ppath ' ' ipaddrs ' ' remmat ' ' varmat ' ' int2str(sleeptime)];
% perform the command
system(cmdStr)
