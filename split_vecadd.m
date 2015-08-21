function out = split_vecadd(input)

A = input.A;
B = input.B;

for i=1:input.ncluster
    a = A(1, (i-1)*numel(A)/input.ncluster+1 : i*numel(A)/input.ncluster);
    b = B(1, (i-1)*numel(B)/input.ncluster+1 : i*numel(B)/input.ncluster);
    save([input.path_vars input.vars int2str(i) '.mat'], 'a', 'b');
end

out = 1;

end