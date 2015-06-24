classdef Distributor < handle
    %DISTRIBUTOR handle class to manage split, distribution and merging of data
    %   User must provide their custom functions to perform splitting, 
    %   merging and wrapping (kernel), each in a separate file.
    
    properties (GetAccess = 'public', SetAccess = 'private')
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
        cached=0; % flag if there are any cached variables that were copied
        ncache=0; % number of those vars
        cvars='empty'; % vector of strings that contain names of cached vars, currently supports only 1 var max
    end
    
    methods
        % ctor
        function obj = Distributor(login, path_rem, ipaddrs, path_vars, vars, path_curr, sleeptime, path_res, printout)
            path_rem = correctpath(path_rem);
            path_vars = correctpath(path_vars);
            path_res = correctpath(path_res);
            path_curr = correctpath(path_curr);
            obj.login=login;
            obj.path_rem=path_rem;
            obj.ipaddrs=ipaddrs;
            obj.path_vars=path_vars;
            obj.vars=vars;
            obj.path_curr=path_curr;
            obj.sleeptime=sleeptime;
            obj.path_res=path_res;
            obj.printout = printout;
            [obj.ncluster, ~] = find(ipaddrs==' '); % to break data into n clusters (as many as given servers)
            obj.ncluster = size(obj.ncluster,2)+1;
            if (obj.ncluster > 1)
                obj.test_connection();
            end
        end
        
        function test_connection(obj)
            tester = [obj.path_curr 'dtest.sh']; 
            system(['chmod u+x ' tester]);
            cmdStr=[tester ' ' obj.login ' ' obj.ipaddrs];
            status = system(cmdStr);
            if (status==0)
                fprintf('Distributor initialized successfully\n');
            else
                error('Could not initialize distributor - check SSH connection/settings');
            end
        end
        
        % launching framework: split, distribute, merge
        function out_merge = launch(obj, h_split, in_split, h_kernel, h_merge, in_merge)   
            % split data
            if (obj.printout); fprintf('Splitting the data...'); end
            h_split(in_split);
            if obj.printout; fprintf('done\n'); end
            
            % remmat initialization
            filestruct = functions(h_kernel);
            [pathsrc, remmat, ~] = fileparts(filestruct.file);
            pathsrc = correctpath(pathsrc);
            
            bashscript = [obj.path_curr 'dhead.sh'];
            system(['chmod u+x ' bashscript]);
            cmdStr = [bashscript ' ' obj.login ' ' obj.path_rem ' ' obj.ipaddrs ' '...
                pathsrc ' ' remmat ' ' obj.path_vars ' ' obj.vars ' ' obj.path_curr ' '...
                int2str(obj.sleeptime) ' ' obj.path_res];
            cmdStr = [cmdStr ' ' obj.cvars ' ' int2str(obj.ncache)]; % add cache params
            if ~obj.printout
                cmdStr = [cmdStr '>' obj.path_res remmat '.log 2>&1'];
            end
            % perform the command
            if obj.printout; fprintf('Launching the bash scripts\n'); end
            status = system(cmdStr);
            
            if (status~=0)
                error('Distributor return status : check output files .out and .err for status');
            end
            
            % merge data
            if obj.printout; fprintf('Merging data...'); end
            out_merge = h_merge(in_merge);
            if obj.printout; fprintf('done\n'); end
        end
        
        function status = scp_cached_data(obj, cnda) % where cnda is CachedNDArray data structure
            assert(obj.cached == 0, 'Current version supports only 1 cached varaible data transfer');
            
            cache = cnda.window.vname; % variable name
            path_cache = cnda.window.cpath; % its path
            
            nc = cnda.nchunks / obj.ncluster;
            
            obj.cached = 1; % indicate cached object was already copied
            obj.ncache = nc; 
            obj.cvars = cache;
             
            transfer = [obj.path_curr 'dtransfer.sh'];
            system(['chmod u+x ' transfer]);
            
            cmdStr = [transfer ' ' obj.login ' ' obj.path_rem ' ' ...
                    int2str(obj.ncache) ' ' path_cache ' ' cache ' ' obj.ipaddrs];
            if ~obj.printout
                cmdStr = [cmdStr '>' obj.path_res 'transfer.log 2>&1'];
            end
            if (obj.printout)
                fprintf('Lauching .dat transfer script\n');
            end
            status = system(cmdStr);
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

