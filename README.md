*rshell-mat* consists of two main bash scripts:  
* *dhead.sh* - a local head script that performs the distribution among the remote servers
* *dserver.sh* - a remote server script that launches matlab function on the remote server  

A usage example is provided - calculation of the Mandelbrot set. To run the example, open and run **test_rshell_mat.m**:  
* Insert your own settings for the remote servers (such as IP addresses, login, path, etc).  
* **IMPORTANT**: it is absolutely necessary to set up the login through ssh key.  

For general usage, the bash script can be run from matlab by using the next two lines:  
```  
cmdstr = ['dhead.sh' ' ' login ' ' path ' ' ipaddrs ' '...
	 remmat ' ' varmat ' ' int2str(sleeptime) ' ' resfold];  
system(cmdstr); % will perform the command above
```  
Where  
`login` is a login id, in a string format   
`path` is a workspace path on remote servers (if the folder does not exist, it will be created)   
`ipaddrs` is a list of IP addresses, in a string format; it has a form of `['ipsddrs1' ' ' 'ipsddrs2' ' ' ...]` - each IP address must be separated by **one** space character from its neighbors  
`remmat` is a matlab function name that will be run on remotes, in a string format, withought *.m* resolution; for example, if you intend to run function *fft-custom.m*, you have to set `remmat='fft-custom';`   
`varmat` is a temporal file name where the work variables will be saved to, in a string format   
`sleeptime` is a pause interval in seconds, integer; you may want to increase it for heavy data computations    
`resfold` is a name of a folder on local machine where the essential result files will be kept, in a string format  

Besides the forementioned folders and files, the program will also produce a range of folders in the current directory under each server.s name where the *.err* and *.out* files will be kept.

**It is the responsibility of user to split and merge the data as a pre- and after- data processing**. The main task of the distribution bash is to tranfer the split data to the servers, run the necessary computations and bring all the result data back to the local machine for further usage withing matlab. 

