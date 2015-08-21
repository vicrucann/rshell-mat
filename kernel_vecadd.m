function out = kernel_vecadd(file_mat, res_fname, ~, ~)

load(file_mat);
c = a+b;
save(res_fname,'c');
out = 1;
end