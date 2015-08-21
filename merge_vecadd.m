function out = merge_vecadd(input)

C = [];
for i=1:input.ncluster
    load([input.path_res '/' 'result_' input.vars int2str(i) '.mat']);
    C = [C; c];
end

out = struct('C', C);

end