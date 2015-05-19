* Fair distribution - check for most powerful severs and gime them more load, less to the less powerful ones.  
* ssh-add should be a separate bash script; as well as killing the pid. This will allow not to enter passphrase if we need to run the distributer for several iterations. Another option: leave passphrase as an empty line.  
* Help file on how to setup the distributer, including ssh-keygen procedures + help links.  
* Boolean variable that makes an option to suppres the bash script output texts.  
* Check if given ip address is reachable; if not - either exit with error or continue without this server.   

