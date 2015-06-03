## Short description

*rshell-mat* is bash script based project that helps to ease heavy data processing in matlab. Its main idea is to send the split big data to several remote servers and run the heavy computations simultaneously using those remotes. When the processing is done, the split result files are copied back to the local machine and can be used further in matlab. The processing is done by two main bash scripts:  
* *dhead.sh* - a local head script that performs the distribution among the remote servers and also copying all the files forward and back  
* *dserver.sh* - a remote server script that launches matlab function on the remote server  

## Platforms  

The scripts are able to distribute the data processing among Linux servers, Windows (Cygwin SSHD) servers and the mixture of both.  

## Quick start

A usage example is provided - calculation of the Mandelbrot set. To run the example, you can use **test_rshell_mat.m** with the following steps:   
* **IMPORTANT**: it is absolutely necessary to set up the login process through the SSH public-key, otherwise the password prompts will not allow for the programm to continue (see [Notes](https://github.com/vicrucann/rshell-mat#notes) for tutorial examples).  
* Before launching the Matlab, set up the SSH connection to the remotes by using *ssh-agent*. For example, run the folloing commands in your command line:  
```
eval \`ssh-agent\`
ssh-add
```  
and provide the pass-phrase.  
* Now launch the Matlab from the **same terminal command line, not in the background**.  
* Open the example script *test_rshell_mat.m*.   
* Inside the example Matlab script, insert your own settings for the remote servers (such as IP addresses, login, paths, etc). Your Matlab script is now ready to be run.  
* When all the calculation are finished and you no longer wish to use the SSH connection and Matlab, exit Matlab, and do not forget to remove the added key (run in command line):  
```
kill $SSH_AGENT_PID
```  

## List of parameters  

For general usage, the bash script can be run from matlab by using the next two lines:  
```  
cmdstr = ['dhead.sh' ' ' login ' ' path ' ' ipaddrs ' '...
	 pathsrc ' ' remmat ' ' pathout ' ' varmat ' ' pathcurr ' ' int2str(sleeptime) ' ' resfold];  
system(cmdstr); % will perform the command above
```  
or, in case if you want to suppress any script output and forward it to a *.log* file (which also improves the computation time):  
```
cmdstr_noOutput = [bashscript ' ' login ' ' ppath ' ' ipaddrs ' '...
        pathsrc ' ' remmat ' ' pathout ' ' varmat ' ' pathcurr ' ' int2str(sleeptime) ' ' resfold ...
	'>' remmat '.log 2>&1'];
system(cmdstr_noOutput)
```
Where  
`login` is a login id, in a string format, e.g.: `login = 'localu';`.   

`path` is a workspace path on remote servers (if the folder does not exist, it will be created), e.g.: `path = '/home/remoteu/tmp'`.   

`ipaddrs` is a list of IP addresses, in a string format; it has a form of `['ipaddrs1' ' ' 'ipaddrs2' ' ' ...]` - each IP address must be separated by **one** space character from its neighbors.  

`pathsrc` is a folder path from where `remmat` will be read from   
 
`remmat` is a matlab function name that will be run on remotes, in a string format, withought *.m* resolution; for example, if you intend to run function *fft-custom.m*, you have to set `remmat='fft-custom';`.   

`pathout` is a folder path where all the `varmat` data is stored and loaded from  

`varmat` is a temporal file name where the work variables will be saved to, in a string format.   

`pathcurr` is a folder path where the .sh scripts are located, basically it is a full path to the current folder.  

`sleeptime` is a pause interval in seconds, integer; you may want to increase it for heavy data computations.    

`resfold` is a name of a folder on local machine where the essential result files will be kept, in a string format.  

## Notes  

**It is the responsibility of user to split and merge the data as a pre- and after- data processing**. The main task of the distribution bash is to tranfer the split data to the servers, run the necessary computations and bring all the results data back to the local machine for further usage withing matlab.   

The distribution scripts assume all the remote machines have the same login id and are accessed using public key authorization (pass phrase), a tutorial on [How do I set up SSH public-key authentication to connect to a remote system](https://kb.iu.edu/d/aews).  

When using a Windows maching as a SSHD server, it is necessary to install and configure cygwin: [Cygwin - SSHD Configuration](techtorials.me/cygwin/sshd-configuration/).  

The distributed scrip clears all the data in the provided work folder, so make sure it is either new folder or you do not have any valuable data in the work directories on each of the remotes.  

The bash distributor package was created as a part of [cryo3d](https://github.com/vicrucann/cryo3d) matlab-based software which reconstructs the 3D model of a particle based on its cryogenic images. *rshell-mat* was made to deal with the heaviest computational part of the pipeline - calculations of SSDs to find the best projection direction and transfomation parameters.  

###### For questions and inqueries 

Victoria Rudakova, vicrucann(at)gmail(dot)com
