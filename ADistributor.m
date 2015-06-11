classdef ADistributor
    %ADISTRIBUTOR abstract class to manage split, distribution and merging of data
    %   User must derive their custom class and redefine all the abstract
    %   methods: splitting, merging and wrapping.
    
    properties (GetAccess = 'public', SetAccess = 'private')
        bashscript;
        printout;
        parameters;
        ncluster;
    end
    
    methods (Abstract) % these methods must be redefined in derived class
        split(obj);
        merge(obj);
        %wrap(obj); % wrapper must be provided as a separate function
    end
    
    methods
        % ctor
        function obj = ADistributor(login, ppath, ipaddrs, pathsrc, remmat, ...
                pathout, varmat, pathcurr, sleeptime, resfold, printout)
            obj.parameters = struct('login', login, 'ppath', correct_path(ppath), 'ipaddrs', ipaddrs, 'pathsrc', ...
                correct_path(pathsrc), 'remmat', remmat, 'pathout', correct_path(pathout), 'varmat', varmat,...
                'pathcurr', correct_path(pathcurr), 'sleeptime', sleeptime, 'resfold', correct_path(resfold));
            obj.bashscript = fullfile(pwd,'dhead.sh');
            obj.printout = printout;
            [obj.ncluster, ~] = find(ipaddrs==' '); % to break data into n clusters (as many as given servers)
            obj.ncluster = size(obj.ncluster,2)+1;
        end
        
        % launching framework: split, distribute, merge
        function status = launch(obj)
            % split data
            obj.split();
            
            system(['chmod u+x ' obj.bashscript])
            if obj.printout
                cmdStr = [obj.bashscript ' ' obj.login ' ' obj.ppath ' ' obj.ipaddrs ' '...
                    obj.pathsrc ' ' obj.remmat ' ' obj.pathout ' ' obj.varmat ' ' obj.pathcurr ' ' ...
                    int2str(obj.sleeptime) ' ' obj.resfold];
            else
                cmdStr = [obj.bashscript ' ' obj.login ' ' obj.ppath ' ' obj.ipaddrs ' '...
                    obj.pathsrc ' ' obj.remmat ' ' obj.pathout ' ' obj.varmat ' ' obj.pathcurr ' ' ...
                    int2str(obj.sleeptime) ' ' obj.resfold '>' obj.remmat '.log 2>&1'];
            end
            % perform the command
            system(cmdStr)
            
            % merge data
            obj.merge();
            status = 1;
        end
    end

end

function cpath = correct_path(cpath)
slash = cpath(end);
if (~isequal(slash, '\') && ~isequal(slash, '/'))
    archstr = computer('arch');
    if (isequal(archstr(1:3), 'win')) % Windows
        cpath = [cpath '\'];
    else % Linux
        cpath = [cpath '/'];
    end
end
end

