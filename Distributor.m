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
        time_stats=0;
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
                mkdir(obj.path_res, 'result_distr');
                obj.test_connection();
            end
            obj.time_stats = struct('transfer_mat', 0, 'transfer_dat', 0, 'transfer_m', 0, ...
                'split', 0, 'merge', 0, 'launch', 0);
        end
        
        function test_connection(obj)
            if (obj.printout);
                tic;
            end
            tester = [obj.path_curr 'dtest.sh']; 
            system(['chmod u+x ' tester]);
            cmdStr=[tester ' ' obj.login ' ' obj.ipaddrs];
            if ~obj.printout
               cmdStr = [cmdStr ' >' obj.path_res 'tester.log 2>&1']; 
            end
            status = system(cmdStr);
            if (status==0)
                fprintf('Distributor initialized successfully\n');
            else
                error('Could not initialize distributor - check SSH connection/settings');
            end
            if (obj.printout);
                toc;
            end
        end
        
        % launching framework: split, distribute, merge
        function out_merge = launch(obj, h_split, in_split, h_kernel, h_merge, in_merge)   
            % split data
            t_split = tic;
            if (obj.printout); 
                fprintf('Splitting the data...'); 
            end
            h_split(in_split);
            if obj.printout; 
                fprintf('done\n'); 
                toc(t_split);
            end
            obj.time_stats.split = toc(t_split);
            
            t_launch = tic;
            if obj.printout; 
                fprintf('Launching the bash scripts\n'); 
            end
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
                cmdStr = [cmdStr ' >' obj.path_res remmat '.log 2>&1'];
            end
            % perform the command
            status = system(cmdStr);
            if obj.printout; 
                toc(t_launch);
            end
            obj.time_stats.launch = toc(t_launch);
            
            % merge data
            t_merge = tic;
            if obj.printout; 
                fprintf('Merging data...'); 
            end
            out_merge = h_merge(in_merge);
            if obj.printout; 
                fprintf('done\n'); 
                toc(t_merge);
            end
            obj.time_stats.merge = toc(t_merge);
        end
        
        function status = scp_cached_data(obj, cnda) % where cnda is CachedNDArray data structure
            t_scp_dat=tic;
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
                cmdStr = [cmdStr ' >' obj.path_res 'transfer.log 2>&1'];
            end
            if (obj.printout)
                t_dtransfer = tic;
                fprintf('Launching .dat transfer script\n');
            end
            status = system(cmdStr);
            if (obj.printout)
                toc(t_dtransfer);
            end
            obj.time_stats.transfer_dat = toc(t_scp_dat);
        end
        
        % h_func is a handle to a function or a class file, in a form 
        % "@func_name" or "@class_name"
        function status = scp_function(obj, h_func)
            t_scp_func = tic;
            func_str = char(h_func);
            filename = which(func_str);
            %filestruct = functions(h_func);
            [path_func, func_name, file_ext] = fileparts(filename);
            path_func = correctpath(path_func);
            func_name = [func_name file_ext];
            
            dscp = [obj.path_curr 'dscp.sh'];
            system(['chmod u+x ' dscp]);
            
            cmdStr = [dscp ' ' obj.login ' ' obj.path_rem ' ' ...
                path_func ' ' func_name ' ' obj.ipaddrs];
            if ~obj.printout
                cmdStr = [cmdStr ' >' obj.path_res 'transfer.log 2>&1'];
            end
            if (obj.printout)
                t_dscp = tic;
                fprintf('Launching .m transfer script\n');
            end
            status = system(cmdStr);
            if (obj.printout)
                toc(t_dscp);
            end
            obj.time_stats.transfer_m = toc(t_scp_func);
        end
        
        function print_timestats(obj)
            totT = obj.time_stats.transfer_m + obj.time_stats.transfer_dat + ...
                obj.time_stats.merge + obj.time_stats.launch + obj.time_stats.split;
            fprintf('Transfer tot .m files:  %.1f sec, %.2f perc\n', obj.time_stats.transfer_m, round(obj.time_stats.transfer_m/totT)*100);
            fprintf('Transfer tot dat files: %.1f sec, %.2f perc\n', obj.time_stats.transfer_dat, round(obj.time_stats.transfer_dat/totT)*100);
            fprintf('Splitting data:         %.1f sec, %.2f perc\n', obj.time_stats.split, round(obj.time_stats.split/totT)*100);
            fprintf('Bash launcher:          %.1f sec, %.2f perc\n', obj.time_stats.launch, round(obj.time_stats.launch/totT)*100);
            fprintf('Merging data:           %.1f sec, %.2f perc\n', obj.time_stats.merge, round(obj.time_stats.merge/totT)*100);
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

