classdef Distributor < handle
    %DISTRIBUTOR handle class to manage split, distribution and merging of data
    %   User must provide their custom functions to perform splitting, 
    %   merging and wrapping (kernel), each in a separate file.
    
    properties (GetAccess = 'public', SetAccess = 'private')
        bashscript;
        printout;
        ncluster;
        login;
        path_rem;
        ipaddrs;
        path_vars;
        vars;
        path_curr;
        sleeptime;
        path_res;
        path_cache;
        cache;
    end
    
    methods
        % ctor
        function obj = Distributor(login, path_rem, ipaddrs, path_vars, vars, ...
                path_cache, cache, path_curr, sleeptime, path_res, printout)
            if (sum(path_cache == 0) || sum(cache == 0))
                path_cache = '0';
                cache = '0';
            end
            path_rem = correctpath(path_rem);
            path_vars = correctpath(path_vars);
            path_curr = correctpath(path_curr);
            path_res = correctpath(path_res);
            obj.login=login;
            obj.path_rem=path_rem;
            obj.ipaddrs=ipaddrs;
            obj.path_vars=path_vars;
            obj.vars=vars;
            obj.path_cache=path_cache;
            obj.cache=cache;
            obj.path_curr=path_curr;
            obj.sleeptime=sleeptime;
            obj.path_res=path_res;
            obj.bashscript = [path_curr 'dhead.sh']; % can be initialized from launch() to avoid passing path_curr
            obj.printout = printout;
            [obj.ncluster, ~] = find(ipaddrs==' '); % to break data into n clusters (as many as given servers)
            obj.ncluster = size(obj.ncluster,2)+1;
            % check if servers are reacheable
            tester = [path_curr 'dtest.sh']; % can be moved to separate func which is called from launch()
            system(['chmod u+x ' tester]);
            cmdStr=[tester ' ' login ' ' ipaddrs];
            system(cmdStr);
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
                cmdStr = [obj.bashscript ' ' obj.login ' ' obj.path_rem ' ' obj.ipaddrs ' '...
                    pathsrc ' ' remmat ' ' obj.path_vars ' ' obj.vars ' ' obj.path_cache ' ' obj.cache ' ' ...
                    obj.path_curr ' ' int2str(obj.sleeptime) ' ' obj.path_res];
            else
                cmdStr = [obj.bashscript ' ' obj.login ' ' obj.path_rem ' ' obj.ipaddrs ' '...
                    pathsrc ' ' remmat ' ' obj.path_vars ' ' obj.vars ' ' obj.path_cache ' ' obj.cache ' ' ...
                    obj.path_curr ' ' int2str(obj.sleeptime) ' ' obj.path_res '>' obj.remmat '.log 2>&1'];
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

