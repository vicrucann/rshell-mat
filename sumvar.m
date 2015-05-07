function sumvar()
% script to sum two vectors and save the result to file

load('v1.mat');
load('v2.mat');

v12 = v1+v2;

save('result.mat', 'v12');
