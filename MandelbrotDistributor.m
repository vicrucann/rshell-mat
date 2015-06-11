classdef MandelbrotDistributor < ADistributor
    %MANDELBROTDISTRIBUTOR User-provided class that inherits from abstract
    %distributor ADistributor class
    %   In this class user must define the functions split and merge
    
    properties
        %i_split; % input split struct
        %i_merge; % input merge struct
    end
    
    methods
        % ctor
        function obj = MandelbrotDistributor(login, ppath, ipaddrs, pathsrc, remmat, ...
                pathout, varmat, pathcurr, sleeptime, resfold, printout)
            obj = obj@ADistributor(login, ppath, ipaddrs, pathsrc, remmat, ...
                pathout, varmat, pathcurr, sleeptime, resfold, printout);
        end
        
        % redefined split method
        function split(~, input)
            ncluster = input.ncluster;
            xGrid = input.xGrid;
            yGrid = input.yGrid;
            szx = input.szx;
            varmat = input.varmat;
            iter = input.iter;
            
            for i=1:ncluster
                if (i ~= ncluster)
                    xi=xGrid(:, szx*(i-1)+1:szx*i);
                    yi=yGrid(:, szx*(i-1)+1:szx*i);
                else
                    xi=xGrid(:, szx*(i-1)+1:end);
                    yi=yGrid(:, szx*(i-1)+1:end);
                end
                save([varmat int2str(i) '.mat'], 'xi', 'yi', 'iter'); % [xi, yi, iter] are saved
            end
        end
        
        % redefined merge method
        function res = merge(obj, isize, ncluster, szx)
            res = zeros(isize, isize);
            for i=1:ncluster
                load([obj.resfold '/' 'result_' obj.varmat int2str(i) '.mat']); % [count] variable is loaded
                if (i ~= ncluster)
                    res(:,szx*(i-1)+1:szx*i) = count;
                else
                    res(:,szx*(i-1)+1:end) = count;
                end
            end
        end
        
    end
    
end

