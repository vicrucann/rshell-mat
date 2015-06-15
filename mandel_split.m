function out = mandel_split( input)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
ncluster = input.ncluster;
xGrid = input.xGrid;
yGrid = input.yGrid;
szx = input.szx;
iter = input.iter;

for i=1:ncluster
    if (i ~= ncluster)
        xi=xGrid(:, szx*(i-1)+1:szx*i);
        yi=yGrid(:, szx*(i-1)+1:szx*i);
    else
        xi=xGrid(:, szx*(i-1)+1:end);
        yi=yGrid(:, szx*(i-1)+1:end);
    end
    save([input.varmat int2str(i) '.mat'], 'xi', 'yi', 'iter'); % [xi, yi, iter] are saved
end
out = 1;

end

