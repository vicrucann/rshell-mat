function [x, y, count] = mandelbrodt( xlim, ylim, gridSize, maxIterations )
%MANDELBRODT Mndelbrodt set calculation for given parameters
%   To use as a part of rshell-mat - bash script that helps to parallelize
%   matlab big data processing
%   2015 vicrucann@gmail.com

assert(xlim(1)>=-2 && xlim(2)<=1, 'real part should stay within range [-2;1]');
assert(ylim(1)>=-1.5 && ylim(2)<=1.5, 'imaginary part should stay within range [-1.5;1.5]');
assert(gridSize>=100, 'Grid size should be at least 100 pixels');
assert(maxIterations>=10, 'maxIterations should be at least 10 times');

x = linspace( xlim(1), xlim(2), gridSize );
y = linspace( ylim(1), ylim(2), gridSize );
[xGrid,yGrid] = meshgrid( x, y );
z0 = xGrid + 1i*yGrid;
count = ones( size(z0) );

z = z0;
for n = 0:maxIterations
    z = z.*z + z0;
    inside = abs( z )<=2;
    count = count + inside;
end
count = log( count );

end

