#!/bin/bash
#
# A script to test accessibility to spicified IP addresses
# Also tests if the private key is added (ssh-add)

args=("$@")
nargs=$#
if [ $nargs -lt 2  ]; then
  printf "ERROR: There must be at least two passed parameters (login and IP address)\n"
  exit 1
fi

LOGIN=${args[0]}

nservs=$((nargs-1))
i=1
while true; do
  IPADDRS[$((i-1))]=${args[$i]}
  i=$((i+1))
  nservs=$((nservs-1))
  if (( nservs <= 0 )); then
    break
  fi
done

for IPA in ${IPADDRS[@]}; do
  ssh -q $LOGIN@$IPA exit
  status=$?
  if [ $status -eq 255 ]; then
    printf "ERROR: server %s is not accessible, check connectivity and private key setup\n"
    exit 1
  fi
done


