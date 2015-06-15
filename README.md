## Short description

*rshell-mat* is bash script based project that helps to ease heavy data processing in Matlab. Its main idea is to send the split big data to several remote servers and run the most heavy computations simultaneously using those remotes. When the processing is done, the split result files are copied back to the local machine, merged by using the user-provided function; so the data can be used further in matlab. The processing is done by two main bash scripts and a matlab class:  
* *dhead.sh* - a local head script that performs the distribution among the remote servers and also copying all the files forward and back  
* *dserver.sh* - a remote server script that launches matlab function on the remote server  
* *Distrubutor.m* - is a handle Matlab interface, that coordinates data initialization, splitting, script launching and merging. Note, the split, kernel and merge functions must be provided by a user, as well as initialized structures for each method.  

## Platforms  

The scripts are able to distribute the data processing among Linux servers, Windows (Cygwin SSHD) servers and the mixture of both.  

## Quick start

A usage example is provided - calculation of the Mandelbrot set. To run the example, you can use **test_rshell_mat.m** with the following steps:   
* **IMPORTANT**: it is necessary to set up the login process through the SSH public-key, otherwise the password prompts will not allow for the programm to continue (see [Notes](https://github.com/vicrucann/rshell-mat#notes) for tutorial examples).  
* Before launching the Matlab, set up the SSH connection to the remotes by using *ssh-agent*. For example, run the folloing commands in your command line:  
```
eval `ssh-agent`
ssh-add
```  
and provide the pass-phrase.  
* Now launch the Matlab from the **same terminal command line, not in the background**:  
```  
matlab
```   
* Open the example script *test_rshell_mat.m*.   
* Inside the example Matlab script, insert your own settings for the remote servers (such as IP addresses, login, paths, etc). Your Matlab script is now ready to be run, since the split, kernel and merge functions are provided for the example.  
* When all the calculation are finished and you no longer wish to use the SSH connection and Matlab, exit Matlab, and do not forget to remove the added key (run in command line):  
```
kill $SSH_AGENT_PID
```  
## Customizing and running your own *Distributor*

Use the following steps to run your `Distributor`:  
[1] *Distributor* variable declaration by running a constructor (see what are the input parameters in [parameter list]())  
```
d = Distributor(login, ppath, ipaddrs, pathout, varmat, ...
    pathcurr, sleeptime, resfold, printout);
```  
[2] Obtain function handles on your `split`, `kernel` and `merge` functions, as well as initialize the input structures for each of these functions:  
```
in_split = struct('field1', val1, 'field2', val2, ...);
in_merge = struct('field1', val1, 'field2', val2, ...);
h_split = @split;
h_kernel = @kernel;
h_merge = @merge; 
```  
[3] Launch the *Distributor*:  
```
out_merge = d.launch(h_split, in_split, h_kernel, h_merge, in_merge);
```
[4] Use the output variable \ structure further in your Matlab code:  
```
val1 = out_merge.field1;
val2 = out_merge.field2;
...
```

## List of parameters  

`login` is a login id for the remotes (assumed the same for all the remotes), in a string format, e.g.: `login = 'remote_user';`.   

`path` is a workspace path on **remote** servers (if the folder does not exist, it will be created), e.g.: `path = '/home/remoteu/tmp'`.   

`ipaddrs` is a list of IP addresses, in a string format; it has a form of `['ipaddrs1' ' ' 'ipaddrs2' ' ' ...]` - each IP address must be separated by **one** space character from its neighbors.  

`pathout` is a folder path where all the `varmat` data (Matlab worspace variables) is stored and loaded from  

`varmat` is a root name of temporal files where the work variables are saved to, in a string format.   

`pathcurr` is a folder path where the .sh scripts are located, for the Mandelbrot example case it is a full path to the current folder.  

`sleeptime` is a pause interval in seconds, integer, it is used inside *dhead.sh* to wait until the tasks are finished execution on remotes; you may want to increase it for heavy data computations.    

`resfold` is a name of a temporal folder on *local* machine where the result files will be copied to, in a string format.  

`printout` is a boolean (`0` or `1`) variable that allows (`1`) or suppresses (`0`) any `printf` output to the Matlab command line. Note that for big repetitive data computations it is adviced to turn it off for faster processing time.  

## Tester bash script  
`dtest.sh` - is run from *Distributor* constructor automatically and it tests the accesibility of the provided IP addresses.  

## Providing your custom functions for split, merge and wrapping (kernel)  
These are the signatures of three functions that user must provide for their *Distributor*:  
* `function out = split(input)`  
* `function out = kernel(input1, inout2, ...)`  
* `function out = merge(input)`  
The `split` and `merge` functions have their own `input` and `out` variables which are a Matlab structures that contain the necessary variables as a fields. The `kernel` function may have different variables as input (for clarity refer to the provided Mandelbrot example).  

## Notes  

**It is the responsibility of user to split and merge the data as a pre- and after- data processing**. The main task of the distribution bash is to tranfer the split data to the servers, run the necessary computations and bring all the results data back to the local machine for further usage withing matlab.   

The distribution scripts assume all the remote machines have the same login id and are accessed using public key authorization (pass phrase), a tutorial on [How do I set up SSH public-key authentication to connect to a remote system](https://kb.iu.edu/d/aews).  

When using a Windows maching as a SSHD server, it is necessary to install and configure cygwin: [Cygwin - SSHD Configuration](techtorials.me/cygwin/sshd-configuration/).  

The distributed scrip clears all the data in the provided work folder, so make sure it is either new folder or you do not have any valuable data in the work directories on each of the remotes.  

The bash distributor package was created as a part of [cryo3d](https://github.com/vicrucann/cryo3d) matlab-based software which reconstructs the 3D model of a particle based on its cryogenic images. *rshell-mat* was made to deal with the heaviest computational part of the pipeline - calculations of SSDs to find the best projection direction and transfomation parameters.  

###### For questions and inqueries 

Victoria Rudakova, vicrucann(at)gmail(dot)com
