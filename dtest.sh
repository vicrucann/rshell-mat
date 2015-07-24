#!/bin/bash
#
# A script to test accessibility to spicified IP addresses
# Tests if the private key is added (ssh-add), if not, throws connectivity error
# Creates a workfolder on each of the remotes
# If the workfolder already exists, it clears all the previous data stored in there

printf "Testing if SSH connection can be set up successfully\n"
args=("$@")
nargs=$#
printf "Number of input args is %i\n" $nargs
if [ $nargs -lt 3  ]; then
  printf "ERROR: There must be at least two passed parameters (login, path_rem and IP address)\n"
  exit 1
fi

LOGIN=${args[0]}
printf "Login is %s\n" $LOGIN

PATH_REM=${args[1]}
printf "Remote directory path is %s\n" $PATH_REM

nservs=$((nargs-2))
printf "Number of servers is %i\n" $nservs
i=2
while true; do
  IPADDRS[$((i-2))]=${args[$i]}
  i=$((i+1))
  nservs=$((nservs-1))
  if (( nservs <= 0 )); then
    break
  fi
done
printf "Done reading the IP addresses\n"

for IPA in ${IPADDRS[@]}; do
  printf "Trying to SSH to server %s\n" $IPA
  ssh -q $LOGIN@$IPA exit
  status=$?
  if [ $status -eq 255 ]; then
    printf "ERROR: server %s is not accessible, check connectivity and private key setup\n" $IPA
    exit 1
  fi
  printf " - success\n"
	ssh $LOGIN@$IPA "mkdir -p $PATH_REM" # create working directory, if necessary
  status=$?
  if [ $status -eq 255 ]; then
    printf "ERROR: server %s - the working directory could not be created, check the rights to run mkdir\n" $IPA
  fi
	ssh $LOGIN@$IPA "rm -f $PATH_REM/*" # clear the working directory from any previous data
  printf "Working directory had been created / cleared\n"
done
printf "Done checking connectivity\n"

