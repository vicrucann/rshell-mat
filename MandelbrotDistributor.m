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
        function out = split(obj, input)
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
                save([obj.parameters.varmat int2str(i) '.mat'], 'xi', 'yi', 'iter'); % [xi, yi, iter] are saved
            end
            out = 1;
        end
        
        % redefined merge method
        function out = merge(obj, input)
            isize = input.isize;
            ncluster = input.ncluster;
            szx = input.szx;
            out = zeros(isize, isize);
            for i=1:ncluster
                load([obj.parameters.resfold '/' 'result_' obj.parameters.varmat int2str(i) '.mat']); 
                % [count] variable is loaded
                if (i ~= ncluster)
                    out(:,szx*(i-1)+1:szx*i) = count;
                else
                    out(:,szx*(i-1)+1:end) = count;
                end
            end
        end
        
    end
    
end

