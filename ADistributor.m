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
        output = split(obj, input);
        output = merge(obj, input);
        %wrap(obj); % wrapper must be provided as a separate function
    end
    
    methods
        % ctor
        function obj = ADistributor(login, ppath, ipaddrs, pathsrc, remmat, ...
                pathout, varmat, pathcurr, sleeptime, resfold, printout)
            ppath = correctpath(ppath);
            pathsrc = correctpath(pathsrc);
            pathout = correctpath(pathout);
            pathcurr = correctpath(pathcurr);
            resfold = correctpath(resfold);
            obj.parameters = struct('login', login, 'ppath', ppath, 'ipaddrs', ipaddrs, 'pathsrc', ...
                pathsrc, 'remmat', remmat, 'pathout', pathout, 'varmat', varmat,...
                'pathcurr', pathcurr, 'sleeptime', sleeptime, 'resfold', resfold);
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
                cmdStr = [obj.parameters.bashscript ' ' obj.parameters.login ' ' obj.parameters.ppath ' ' obj.parameters.ipaddrs ' '...
                    obj.parameters.pathsrc ' ' obj.parameters.remmat ' ' obj.parameters.pathout ' ' obj.parameters.varmat ' ' obj.parameters.pathcurr ' ' ...
                    int2str(obj.parameters.sleeptime) ' ' obj.parameters.resfold];
            else
                cmdStr = [obj.parameters.bashscript ' ' obj.parameters.login ' ' obj.parameters.ppath ' ' obj.parameters.ipaddrs ' '...
                    obj.parameters.pathsrc ' ' obj.parameters.remmat ' ' obj.parameters.pathout ' ' obj.parameters.varmat ' ' obj.parameters.pathcurr ' ' ...
                    int2str(obj.parameters.sleeptime) ' ' obj.parameters.resfold '>' obj.parameters.remmat '.log 2>&1'];
            end
            % perform the command
            system(cmdStr)
            
            % merge data
            obj.merge();
            status = 1;
        end
    end

end

function os = getOS()
archstr = computer('arch');
if (isequal(archstr(1:3), 'win')) % Windows
    os = 1;
elseif (isequal(archstr(1:5),'glnxa')) % Linux
    os = 0;
else % other, not supported
    error('Unrecognized or unsupported architecture');
end
end

function path_platform = correctpath(path)
os = getOS();
if (strcmp(path(end), '\') || strcmp(path(end), '/'))
    path = path(1:end-1);
end
path_platform = path;
if os % Windows
    path_platform = [path_platform '\'];
else % Linux
    path_platform = [path_platform '/'];
end
end

