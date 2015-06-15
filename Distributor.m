classdef Distributor < handle
    %DISTRIBUTOR handle class to manage split, distribution and merging of data
    %   User must provide their custom functions to perform splitting, 
    %   merging and wrapping (kernel), each in a separate file.
    
    properties (GetAccess = 'public', SetAccess = 'private')
        bashscript;
        printout;
        parameters;
        ncluster;
        login;
        ppath;
        ipaddrs;
        pathout;
        varmat;
        pathcurr;
        sleeptime;
        resfold;
    end
    
    methods
        % ctor
        function obj = Distributor(login, ppath, ipaddrs, ...
                pathout, varmat, pathcurr, sleeptime, resfold, printout)
            ppath = correctpath(ppath);
            pathout = correctpath(pathout);
            pathcurr = correctpath(pathcurr);
            resfold = correctpath(resfold);
            obj.login=login;
            obj.ppath=ppath;
            obj.ipaddrs=ipaddrs;
            obj.pathout=pathout;
            obj.varmat=varmat;
            obj.pathcurr=pathcurr;
            obj.sleeptime=sleeptime;
            obj.resfold=resfold;
            %obj.parameters = struct('login', login, 'ppath', ppath, 'ipaddrs', ipaddrs, 'pathsrc', ...
            %    pathsrc, 'remmat', remmat, 'pathout', pathout, 'varmat', varmat,...
            %    'pathcurr', pathcurr, 'sleeptime', sleeptime, 'resfold', resfold);
            obj.bashscript = fullfile(pwd,'dhead.sh');
            obj.printout = printout;
            [obj.ncluster, ~] = find(ipaddrs==' '); % to break data into n clusters (as many as given servers)
            obj.ncluster = size(obj.ncluster,2)+1;
            % check if servers are reacheable
            
            fprintf('Distributor initialized successfully\n');
        end
        
        % launching framework: split, distribute, merge
        function out_merge = launch(obj, h_split, in_split, h_kernel, h_merge, in_merge)   
            % split data
            fprintf('Splitting the data...');
            out_split = h_split(in_split);
            fprintf('done\n');
            
            % remmat initialization
            filestruct = functions(h_kernel);
            [pathsrc, remmat, ~] = fileparts(filestruct.file);
            pathsrc = correctpath(pathsrc);
            
            system(['chmod u+x ' obj.bashscript])
            if obj.printout
                cmdStr = [obj.bashscript ' ' obj.login ' ' obj.ppath ' ' obj.ipaddrs ' '...
                    pathsrc ' ' remmat ' ' obj.pathout ' ' obj.varmat ' ' obj.pathcurr ' ' ...
                    int2str(obj.sleeptime) ' ' obj.resfold];
            else
                cmdStr = [obj.bashscript ' ' obj.login ' ' obj.ppath ' ' obj.ipaddrs ' '...
                    pathsrc ' ' remmat ' ' obj.pathout ' ' obj.varmat ' ' obj.pathcurr ' ' ...
                    int2str(obj.sleeptime) ' ' obj.resfold '>' obj.remmat '.log 2>&1'];
            end
            % perform the command
            fprintf('Launching the bash scripts\n');
            system(cmdStr)
            
            % merge data
            fprintf('Merging data...');
            out_merge = h_merge(in_merge);
            fprintf('done\n');
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

