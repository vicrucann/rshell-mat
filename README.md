#RSHELL-MAT - Shell-based distributor for Matlab

## Content
* [Short description](https://github.com/vicrucann/rshell-mat#short-description)
* [Platforms and other requirements](https://github.com/vicrucann/rshell-mat#platforms)
* [Quick Start](https://github.com/vicrucann/rshell-mat#quick-start)
* [Main workflow description](https://github.com/vicrucann/rshell-mat#main-workflow-of-the-distributor-processes)
* [Customizing and running your own Distributor](https://github.com/vicrucann/rshell-mat#customizing-and-running-your-own-distributor)
    * [List of parameters](https://github.com/vicrucann/rshell-mat#list-of-parameters)
    * [Providing your custom functions for split, merge and kernel](https://github.com/vicrucann/rshell-mat#providing-your-custom-functions-for-split-merge-and-wrapping-kernel)
    * [LOG files](https://github.com/vicrucann/rshell-mat#log-files)
* [Notes and tutorials](https://github.com/vicrucann/rshell-mat#notes)
    * [Setting up SSH pubkey authentication](https://github.com/vicrucann/rshell-mat#setting-up-ssh-public-key-authentication)
    * [Setting up SSHD server using Cygwin on Windows](https://github.com/vicrucann/rshell-mat#setting-up-sshd-server-using-cygwin-on-windows)
    * [Enabling arcfour cipher (for Windows SSHD)](https://github.com/vicrucann/rshell-mat#enabling-arcfour-cipher-for-windows)
    * [Specifics](https://github.com/vicrucann/rshell-mat#specifics)
    * [Other info](https://github.com/vicrucann/rshell-mat#other)
    * [Performace examples](https://github.com/vicrucann/rshell-mat#performance-examples)
* [Contact](https://github.com/vicrucann/rshell-mat#for-questions-and-inqueries)

## Short description

*rshell-mat* is bash script based project that helps to ease heavy data processing in Matlab. Its main idea is to send the split data to several remote servers and run the most heavy computations simultaneously using those remotes. When the processing is done, the split result files are copied back to the local machine, merged by using the user-provided function; so the data can be used further in Matlab. The processing is done by the bash scripts and a Matlab class:  
* *dhead.sh* - a local head script that performs the distribution among the remote servers and also copying all the files forward and back  
* *dserver.sh* - a remote server script that launches Matlab function on the remote server  
* *dtest.sh* - a tester script that checks connectivity to the remotes and clears all the previous data inside the remote working directory  
* *dscp.h* - a script to copy any additional *.m* files such as Matlab functions and classes that are necessesary for computaions on remotes  
* *dtransfer.sh* - a script that copies any additional heavy data, in *.dat* format; the script is optionally used and works only and directly with [CachedNDArray](https://github.com/vicrucann/cacharr) matlab class  
* *Distrubutor.m* - is a handle Matlab interface, that coordinates data initialization, splitting, script launching and merging. Note: the split, kernel and merge functions must be provided by user, as well as the initialized structures for each method.  

## Platforms  

The scripts are able to distribute the data processing among Linux servers, Windows (Cygwin SSHD) servers and the mixture of both. SSH connection is used for all the processing. As for the head (local) machine, it must be Linux, since we could not find a way to make it work within Cygwin due to impossibility to tie up the ssh-agent, ssh-add and a Matlab process. 

## Quick start

The Matlab interface class called `Distributor.m` manages the usage of all the Bash scripts. A Matlab example is provided - two vector summation. To run the example, you can use **test_distributor.m** with the following steps:   
* **IMPORTANT**: it is necessary to set up the login process through the SSH public-key, otherwise, the password prompts will not allow for the programm to continue (see [Notes](https://github.com/vicrucann/rshell-mat#notes) for tutorial examples).  
* Before launching the Matlab, set up the SSH connection to the remotes by using *ssh-agent*. For example, run the following commands in your command line (it **must** be Linux environment):  
```
eval `ssh-agent`
ssh-add
```  
and provide the pass-phrase.  
* Now launch the Matlab from the **same terminal command line, not in the background**:  
```  
matlab
```   
* Open the example script *test_distributor.m*.   
* Inside the example Matlab script, insert your own settings for the remote servers (such as IP addresses, login, paths, etc). Your Matlab script is now ready to be run, since the split, kernel and merge functions are provided for the example.  
* When all the calculation are finished and you no longer wish to use the SSH connection and Matlab, exit Matlab, and do not forget to remove the added key (run in a command line):  
```
kill $SSH_AGENT_PID
```  

## Main workflow of the Distributor processes 
 
These are the main steps that happen inside when the Distributor is run:  
* Initialization: 
    * Connectivity tests for each of the remotes   
    * Creating / clearing the remote workfolder for each of the remotes (all files are deleted)  
    * Creating / clearing the local workfolder (`*.log` and `result*.mat` files are deleted)  
    * Internal variable initialization  
* Copying any additional files to the remotes (optional step):  
    * Copying of the additional Matlab functions or classes that will be used during remote computations (note: the wrapper function file is not included in this step)  
    * Copying of any additional `.dat` files that are tied to [CachedNDArray](https://github.com/vicrucann/cacharr) Matlab data class   
* Running the distributor:  
    * Splitting the data - is done based on the user-provided function and input  
    * Distribution - which automatically copies saved by user `.mat` files to the corresponding remotes, launching the Matlab wrappers on the remotes, waiting for the results and then copying back the generated result `.mat` files to the local workfolder  
    * Merging the obtained data in order to use it further in Matlab local session   

## Customizing and running your own *Distributor*

#### Main interface

Use the following steps to run your `Distributor`:  
*Distributor* variable declaration by running a constructor (see what are the input parameters in [parameter list](https://github.com/vicrucann/rshell-mat/tree/auto#list-of-parameters))  
```
d = Distributor(login, path_rem, ipaddrs, path_vars, vars, ...
    path_curr, sleeptime, path_res, printout);
```   
Obtain function handles on your `split`, `kernel` and `merge` functions, as well as initialize the input structures for each of these functions (see [functions signatures](https://github.com/vicrucann/rshell-mat/tree/auto#providing-your-custom-functions-for-split-merge-and-wrapping-kernel)):  
```
in_split = struct('field1', val1, 'field2', val2, ...);
in_merge = struct('field1', val1, 'field2', val2, ...);
h_split = @split;
h_kernel = @kernel;
h_merge = @merge; 
```  
Launch the *Distributor*:  
```
out_merge = d.launch(h_split, in_split, h_kernel, h_merge, in_merge);
```
Use the output variable\structure further in your Matlab code:  
```
val1 = out_merge.field1;
val2 = out_merge.field2;
...
```

#### List of parameters  

`login` is a login id for the remotes (assumed the same for all the remotes), in a string format, e.g.: `login = 'remote_user';`.   

`path_rem` is a workdirectory path on **remote** servers (note: if the folder does not exist, it will be created during the initialization; if the folder exists all the containing data will be cleared); `path = '/home/remote_user/tmp'`.   

`ipaddrs` is a list of IP addresses, in a string format; it has a form of `['ipaddrs1' ' ' 'ipaddrs2' ' ' ...]` - each IP address must be separated by **one** space character, like this: `' '`, from its neighbors.  

`path_vars` is a folder path where all the `vars` data (Matlab worspace variables, normally in format `*.mat`) is stored and loaded from.  

`vars` is a root name of temporal files where the work variables are saved to, in a string format. An example of the saved file with a `vars` rootname will be `{vars1.dat, vars2.dat, ...}`; each of these files will be kept on `server1, server2, ...`.   

`path_curr` is a folder path where the .sh scripts are located, for the Mandelbrot example case it is a full path to the current folder.  

`sleeptime` is a pause interval in seconds, integer, it is used inside *dhead.sh* to wait until the tasks are finished on remotes; you may want to increase it for heavier computations. This variable insures the processes are not stuck in an infinite loop on the remotes.    

`path_res` is a name of a temporal folder on **local** machine where the result files will be copied to, in a string format.  

`printout` is a boolean (`0` or `1`) variable that allows (`1`) or suppresses (`0`) any `printf` and `echo` bash outputs to the Matlab command line (in case of suppresion the outout is forwarded to a `*.log` file). Note that for big repetitive data computations, once the code is debugged, it is advised to turn the direct output off for faster processing time.  

#### Providing your custom functions for split, merge and wrapping (kernel)  

These are the signatures of three functions that user must provide for their *Distributor*:  
* `function output = split(input)`  
* `function output = kernel(file_mat, res_fname, cache_vname, ncache)`, note: cache parameters could be omitted, e.g: `kernel(file_mat, res_fname, ~, ~)` if you do not use any supplemental `.dat` files in computations  
* `function output = merge(input)`  

The `split` and `merge` functions have their own `input` and `output` variables which are the Matlab `struct` data types that contain the necessary variables as fields.  

Certain `input` fields must be passed and used correctly for any split or merge functions. The necessary parameters for any split function:  
```
% to be called from main script before we launch the distributor
in_split = struct('ncluster', d.ncluster, 'path_vars', d.path_vars, ...);
```  
where `d` is out distributor. With these passed parameters, the skeletone of the split function has the next form:  
```
% user provided function which is called automatically inside launch()
function out = split(input)
    ...
    % for each cluster
    for i = 1 : input.ncluster
        % split each variable into chunks
        ...
        % save each chunk and any other variables
        % for the corresponding remote 'i'
        save([input.path_vars, input.vars int2str(i) '.mat'], ...);
    end
% indicate the operation is done
out = 1;
end
```
The merge mandatory parameters are:  
```
% to be called from main script before we launch the distributor
in_merge = struct('ncluster', d.ncluster, 'path_res', d.path_res, 'vars', d.vars, ...);
```
where `d` is our distributor.  With these passed parameters, the skeletone of the merge function has the next form:  
```
% user provided function which is called automatically inside launch()
function out = merge(input)
...
% for each cluster file
for i = 1 : input.ncluster 
    % load the corresponding result file
    load([input.path_res 'result_' input.vars int2str(i) '.mat']);
    % save it to the result variable
    ...
end
% save the result variable to the output structure
out = struct(...);
```

The `kernel` function have two or four variables as input: `file_mat` is a `.mat` filename where Matlab workspace variables are kept; `res_fname` is a filename where the result will be written to for the current remote (string format); and `cache_vname` together with `ncache` are for indication a rootname of `.dat` file where Matlab cache variable is stored and the number of such files (the last two parameters might be ommited). 

The necessity to have `.dat` files might not be obvious, but we use **rshell-mat** in conjunction with [CachedNDArray](https://github.com/vicrucann/cacharr) data structure for our [cryo3D](https://github.com/vicrucann/cryo3d) project (see [Notes](https://github.com/vicrucann/rshell-mat/tree/auto#notes) for more details), for that reason we figured out that not all the data can be stored and transferred as `.mat` file, but in case if there is any other disk data, it could be transferred and used as a `.dat` file.  

The example of the basic `merge` function:  
```
function out = kernel(file_mat, res_fname, ~, ~)
% load the corresponding variables into Matlab workspace
load(file_mat);
% operate the variables
...
% save the result variable to the provided name
save(res_fname, ...);
% indicate the operation is done
out = 1;
end
```
Note, you can always perform an output when debugging your kernel function by doing `fprintf()`. The output will be printed into a corresponding log (`.err` or `.out`) file **on the remote workfolder**. An example:  
```
function out = kernel(file_mat, res_fname, ~,~)
load(file_mat);
if (size(var)>x)
    fprintf('The size of var is %i\n', size(var));
    fprintf('x is %f\n', x);
    ...
end
...
end
```
In the sample code above, if the `if` condition met, two messages will be print into `.out` log file. Further on, if an error occurs, the error message will be printed to the `.err` log file. Both of the log files are kept on the corresponding remote workspace directory. 

#### LOG files  

For each Matlab and Bash process, there is a corresponding `*.log` file that allows to check the running status and/or for any errors that can occur - whether on local or remote machines. The list of `.log` files is as follows:  
* Local log files  
    * `tester.log` - generated on local machine when user choses to suppress any distributor output; it contains the information on `ssh` connectivity and accessibility to remotes  
* `transfer.log` - generated on local machine when user choses to suppress any distributor output; it containds the information on performance of `.dat` and `.m` files transfers  
    * `remmat.log` - with `remmat` being defined by user (see [Parameter List](https://github.com/vicrucann/rshell-mat#list-of-parameters) for details) - generated on a local machine when user choses to suppress any distributor output; it contains the progress steps of the `dhead.sh` Bash launcher, i.e. `.mat` data transfer, Matlab remote launching, output data transfer, etc.  
* Remote log files
    * `*.out` - generated on each of the remote machines, it contains information on the `dserver.sh` steps, as well as Matlab wrapper output (if any was provided by a user)  
    * `*.err` - generated on each of the remote machines, it only contains error messages that caused `dserver.sh` or Matlab wrapper to stop  

## Notes  

#### Setting up SSH public-key authentication

The distribution scripts assume all the remote machines have the same login id and are accessed by using public key authorization (pass phrase); for full step-by-step refer to a tutorial on [How do I set up SSH public-key authentication to connect to a remote system](https://kb.iu.edu/d/aews). Here we list a brief description of the procedure:  
* On the **local** maching (what is intended to be a head), generate public and private keys by running the command:  
`$ ssh-keygen -t rsa`  
    * Provide a filename (press <Enter> to save it as default - `id_rsa.pub`, recommended) and a passphrase (press <Enter> to not use any pass phrase, not recommended)
* Copy `id_rsa.pub` to each of the remotes, e.g. by sftp - this is your public key
* For each of the remotes do following:
    * Login to the remote, e.g. by using ssh connection: `ssh remote_user@remote_ip`    
    * Copy your public key to the authorized keys `cat id_rsa.pub >> ~/.ssh/authorized_keys`
    * Set the correct priveleges:  
```
chmod 600 ~/.ssh/authorized_keys  
chmod 700 ~/.ssh  
```
* Logout of the remote and go back to the local machine: `exit`  
* Now you can test the ssh connection by a simple `ssh` command or by using `ssh-agent` (you are supposed to use `ssh-agent` for distributor anyway):  
```
eval `ssh-agent`
ssh-add  
```
* Make sure there is no password prompt, but a pass-phrase prompt instead  
* Remove the `ssh-agent` after exiting  
```
kill $SSH_AGENT_PID
```

#### Setting up SSHD server using Cygwin on Windows

When using a Windows machine as a SSHD server, it is necessary to install and configure Cygwin: [Cygwin - SSHD Configuration](http://techtorials.me/cygwin/sshd-configuration/)(it is a step-by-step tutorial with other additional information). Here, the main steps are described briefly (the steps will require administration rights and will ask to reboot the system at the end):  
* Install Cygwin on Windows; when installing make sure to include the following packages: `cygrunsrv`, `openssh` (you can find them by using search).  
* Edit Path variable on Windows, append the following string: ";c:\cygwin\bin" (the path where Cygwin is installed) and click OK.  
* Chose a username for the server (new user will be created on your Windows machine); for the distributor chose the same username as for all of your other remote machines.  
* Create a new user with the chosen username on Windows.  
* Run Cygwin as administrator.  
* Type the following commands / answers:   
    * `ssh-host-config`  
    * `yes` to privilege separation   
    * `yes` to install sshd as a service   
    * `[]` empty for value of CYGWIN for the daemon   
    * `yes` to use a different name  
    * `username` for the new username, e.g. `cryo`  
    * `username` to reenter  
    * `password` enter the password for the username (must be the same on all machines that distributor will use); reenter  
* Setup Local Security Authority (LSA) by running:  
    * `cyglsa-config`  
    * Answer `yes` to all of the questions  
* The last operation will automatically reboot the system  
* Sometimes it is necessary to edit ``etc/sshd_config`` file and set to `yes` the following attributes:  
    * `X11Forwarding`  
    * `RSA Authentication`  
    * `Publickey Authentication` 
    * Append to the end of the file: `Allow users` and the username you are planning to login from, e.g. `cryo` 
* Before restarting the `sshd` server, you may need to include the *arcfour* cipher to the configuration file (see the next section) 
* The changes will take place after restarting the sshd service: 
    * `net stop sshd` 
    * `net start sshd` 
* The last important step is to configure your Windows 7 firewall options, so that it allows for incoming connections. The full tutorial can be found: [Configure Windows Firewall](http://techtorials.me/cygwin/configure-windows-firewall/). The brief steps are listed below:
    * open Windows Firewall
    * "Inbound Rules" -> "Actions" -> "New Rule"; press "Next"  
    * chose "Port"; press "Next"
    * chose "TCP" and "Specific local ports" and enter the port number (if during sshd installation you chose a specific number, enter it; otherwise, enter "22" as a default); press "Next"
    * chose "Allow the connection"; press "Next"
    * check all the boxes "Domain", "Private", "Public"; press "Next"
    * give it a name and description, e.g. "sshd" and "open port 22"; press "Next"
    * press "Finish"

#### Enabling arcfour cipher (for Windows)

The distributor uses an *arcfour* cipher to compress the transferred data. You can always remove its usage by editing the `dhead.sh` file. Otherwise, Cygwin does not allow this cipher by default, therefore, we need to include it manually (normally, you do not have to do anything for Linux). Enabling is done by followind the steps:  
* First make sure the cipher is available on the current machine, type in Cygwin:   
```ssh -Q cipher localhost | paste -d , -s```  
It will list all the available ciphers of the system. Make sure `arcfour` is in the list.  
* Edit the config file `vim etc/sshd_config` (or `etc/ssh/sshd_config`) to include the cipher by adding the line:   
```Ciphers arcfour```  
* Restart the sshd server:   
```
net sshd stop  
net sshd start  
```

#### Specifics

The Distributor **clears all the data in the provided work folder** on each of the remotes, so make sure it is either new folder or you do not have any valuable data in the work directories on each of the remotes. The working folder will be created directly inside the `$HOME` directory of the user on each of the remotes. 

#### Other

The bash distributor package was created as a part of [cryo3d](https://github.com/vicrucann/cryo3d) Matlab-based software developed at [Yale IPAG](https://medicine.yale.edu/bioimaging/ipa/) which reconstructs a 3D protein model from cryogenic particle images. *rshell-mat* was developed to deal with the heaviest computational part of the pipeline - calculations of SSDs to find the best projection direction and transfomation parameters. 

#### Performance examples  

Two examples will be considered. The first is the provided Mandelbrot calculation; the second is the usage within the [cryo3d](https://github.com/vicrucann/cryo3d) software package for SSDs calculations.  

[Cryo3d](https://github.com/vicrucann/cryo3d)-whole-pipeline performance when using single head server vs. the same head and two remotes (the most expensive operations will be distributed between those two remotes) vs the same head and four\* remotes. Different database sizes provided (the larger the more computationally expesive it is) and a sampling angle `theta` (the smaller the more computationally expensive it is).  
```
---------------------------------------------------------------------------------   
Test params / Configuration   |  Single machine   |  Cluster of two / four * 
---------------------------------------------------------------------------------   
15K database, theta = 12      |      1.3  hrs     |     0.94  hrs  /  1.1   hrs   
15K database, theta = 6       |      5.0  hrs     |     3.45  hrs  / --
15K database, theta = 3       |      29   hrs     |     21    hrs  / --
---------------------------------------------------------------------------------   
67K database, theta = 12      |      2.8  hrs     |     2.1   hrs  /  1.65  hrs  
67K database, theta = 6       |      12   hrs     |     7.8   hrs  /  6.2   hrs  
67K database, theta = 3       |     ~150  hrs     |     -.-   hrs  / ~50    hrs  
--------------------------------------------------------------------------------   
```
\* All of the four remotes had different memory and GPU characteristics, therefore, some performed slower than others which means the performance numbers could be even better than displayed.

## For questions and inqueries 

Victoria Rudakova, vicrucann(at)gmail(dot)com
