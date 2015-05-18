#!/bin/bash
#
# Perform heavy data processing by splitting the task to different servers:
#   Transfer the data and "kernel" function to the servers. 
#   Wait for servers to complete.
#   Collect and merge the results.

printf "The n input arguments for dserver.sh script are: \n"
printf "[1] LOGIN : login id to the remote servers (assumed it's the same login for every server \n)"
printf "[2]- PPATH : working directory (will be created if does not exist) on the remote servers; assumed to be the same for each server \n"
printf "[3..n-3]- IPADDRS : range of ip-addresses of all the servers, assumed they have the same login/psw account \n"
printf "[n-2]- REMMAT : name of the matlab function that will be copied and launched on remote servers \n"
printf "[n-1]- VARMAT : name of the workspace varialbes file, in *.mat format; these are the variables to copy and load to matlab memory on the remote servers \n"
printf "[n]- SLEEPTIME : integer that indicates number of seconds to pause when waiting for each remote server to complete their computations \n"


args=("$@")
printf "Number of arguments passed: %d\n" $#
nargs=$#
if [ $nargs -lt 6 ]; then
  echo "ERROR: Number of passed arguments is smaller than required minimum (6)"
  exit 1
fi
nservs=$((nargs-5))
printf "Number of servers: %d\n" $nservs

LOGIN=${args[0]}
PPATH=${args[1]}
i=2
while true; do
  IPADDRS[$((i-2))]=${args[$i]}
  i=$((i+1))
  nservs=$((nservs-1))
  if (( nservs <= 0 )); then
    printf "IP addresses extracted:\n"
    echo ${IPADDRS[@]} 
    break
  fi
done

REMMAT=${args[$i]}
VARMAT=${args[$(($i+1))]}
SLEEPTIME=${args[$(($i+2))]}
printf "Finished reading the input arguments\n"

i=0
for IPA in ${IPADDRS[@]}; do
  FDONE[$i]=0
  i=$((i+1))
done


