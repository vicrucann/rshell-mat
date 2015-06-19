#!/bin/bash
#
# Distributor shell script to transfer any additional cached data
#   Given number of .dat files and remote destinations
#   Copy each file to each of the destinations
#   dtransfer.sh - "distributed transfer shell".
#   2015 Victoria Rudakova, vicrucann@gmail.com

# ARGUMENTS PARSING
# ================
# input arguments form (must be at least 6 args):
#   login, remote_destination, n_cachef, path_cache, cache_var, {ipaddrs}
#   The .dat files have the format: `path_cache/cache_var{i}.dat` for i=[1..n_cachef*n_ipaddrs]
#   `n_cachef` stands for number of files to transfer per one remote

args=("$@")
printf "\nNumber of arguments passed: %d\n" $#
nargs=$#
if [ $nargs -lt 6 ]; then
	echo "ERROR: Number of passed arguments is smaller than required minimum (6)"
	exit 1
fi
nservs=$((nargs-5))
printf "Number of servers: %d\n" $nservs

LOGIN=${args[0]}
printf "The login parameter: %s\n" $LOGIN
PATH_REM=${args[1]}
printf "The remote working directory: %s\n" $PATH_REM

ncache=${args[2]}
printf "Number of .dat file to copy for EACH remote: %d\n" $ncache
nfiles=$(($nservs*$ncache))
printf "Total number of .dat files: %d\n" $nfiles
rem_check=$(($nservs%$ncache)) # make sure the remainder is 0
if [ $rem_check -ne 0 ]; then
  printf "ERROR: number of files to transfer must be the same for all the remotes\n"
  exit 1
fi
PATH_CACHE=${args[3]}
CACHE=${args[5]}

i=6
while true; do
	IPADDRS[$((i-6))]=${args[$i]}
	i=$((i+1))
	nservs=$(($nservs-1))
	if (( nservs <= 0 )); then
		break
	fi
done
printf "\nIP addresses extracted:\n"
echo ${IPADDRS[@]}

j=1
i=0
while true; do
  test -e $PATH_CACHE$CACHE$j.dat
  if [ $? -ne 0 ]; then
    printf "ERROR: no such file: %s\n" $PATH_CACHE$CACHE$j.dat
    exit 1
  fi
  CFILES[$i]="$CACHE$j.dat"
  i=$((i+1))
  j=$((j+1))
  nfiles=$(($nfiles-1))
  if (( nfiles <= 0 )); then
    break
  fi
done
printf "\nVariables-to-load extracted:\n"
echo $PATH_CACHE${CFILES[@]}

# CONNECT TO REMOTES, SCP FILES
# ================

i=0
printf "\nFile transfer and script launching\n"
for IPA in ${IPADDRS[@]}; do
	ssh $LOGIN@$IPA "mkdir -p $PATH_REM" # create working directory, if necessary
	ssh $LOGIN@$IPA "rm -f $PATH_REM/*" # clear the working directory from any previous data
  for (( j = 0; j < $ncache ; j++ )); do
    idx=$(($j*$ncache+$i+1))
    scp -c arcfour $PATH_CACHE${CFILES[$idx]} $LOGIN@$IPA:$PATH_REM
  done
	i=$((i+1))
done

echo "Distributed transfer of .dat files done"
