# rshell-mat  
Bash scripts that help to parallelize big data analysis by sending the data to process from local to remote machines. The bash script splits data into parts, send a part to a remote server, then waits until processing is done, colleclts and merges the result data.   

sumvar.m - matlab script to be be run on the remote (assume computationally expensive);
sv - shell script to launch on local;
tester - shell script that is launched by sv on remote (launched in background).  

Run "chmod u+x sv" before testing.
