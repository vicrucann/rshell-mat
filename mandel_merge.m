function [ out ] = mandel_merge( input )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
isize = input.isize;
ncluster = input.ncluster;
szx = input.szx;
out = zeros(isize, isize);
for i=1:ncluster
    load([input.resfold '/' 'result_' input.varmat int2str(i) '.mat']);
    % [count] variable is loaded
    if (i ~= ncluster)
        out(:,szx*(i-1)+1:szx*i) = count;
    else
        out(:,szx*(i-1)+1:end) = count;
    end
end
end

