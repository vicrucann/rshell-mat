#!/bin/bash
#
# Perform heavy data processing by splitting the task to different servers:
#   Transfer the data and "kernel" function to the servers. 
#   Wait for servers to complete.
#   Collect and merge the results.


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


