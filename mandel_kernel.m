function count = mandel_kernel( fname, resfname, ~ )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
fprintf('The data file provided: %s\n', fname);

load(fname);
xGrid=xi;
yGrid=yi;
maxIterations=iter;
%------------------------

z0 = xGrid + 1i*yGrid;
count = ones( size(z0) );

z = z0;
for n = 0:maxIterations
    z = z.*z + z0;
    inside = abs( z )<=2;
    count = count + inside;
end
count = log( count );
save(resfname, 'count');

end

