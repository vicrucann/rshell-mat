% test distributor

clc; clear;

login = 'cryo';
path_rem = '/home/cryo/test_distributor';
ipaddrs = ['172.23.2.105' ' ' '172.21.9.92'];
path_vars = pwd; % input vars
vars = 'vecadd';
path_curr = pwd; % script path
sleeptime = 1;
path_res = pwd; % output from remotes
printout = 1;

d = Distributor(login, path_rem, ipaddrs, path_vars, vars, ...
    path_curr, sleeptime, path_res, printout);

A = zeros(1, 1000);
B = ones(1, 1000);

in_split = struct('A', A, 'B', B, 'ncluster', d.ncluster, 'vars', d.vars, 'path_vars', d.path_vars);
in_merge = struct('ncluster', d.ncluster, 'path_res', d.path_res, 'vars', d.vars);

out_merge = d.launch(@split_vecadd, in_split, @kernel_vecadd, @merge_vecadd, in_merge);

C = out_merge.C;