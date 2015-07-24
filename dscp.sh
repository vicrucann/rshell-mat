#!/bin/bash
#
# Distributor shell script to transfer any additional functions or classes
#   Given .m filename and remote destinations
#   Copy the file to each of the destinations
#   dscp.sh - distributed scp
#   2015 Victoria Rudakova, vicrucann@gmail.com

# ARGUMENTS PARSING#{{{
# ================
# input arguments form (must be at least 5 args):
#   login, remote_destination, path_func, func_name, {ipaddrs}
#   The .m file has the format: `path_func/func_name`

args=("$@")
printf "\nNumber of arguments passed: %d\n" $#
nargs=$#
if [ $nargs -lt 5 ]; then
	echo "ERROR: Number of passed arguments is smaller than required minimum (5)"
	exit 1
fi
nservs=$((nargs-4))
printf "Number of servers: %d\n" $nservs

LOGIN=${args[0]}
printf "The login parameter: %s\n" $LOGIN
PATH_REM=${args[1]}
printf "The remote working directory: %s\n" $PATH_REM

PATH_FUNC=${args[2]}
FUNC_NAME=${args[3]}
test -e $PATH_FUNC$FUNC_NAME
if [ $? -ne 0 ]; then
  printf "ERROR: no such file: %s\n" $PATH_FUNC$FUNC_NAME
  exit 1
fi
printf "The function file to copy is %s\n" "$PATH_FUNC$FUNC_NAME"

i=4
while true; do
	IPADDRS[$((i-4))]=${args[$i]}
	i=$((i+1))
	nservs=$(($nservs-1))
	if (( nservs <= 0 )); then
		break
	fi
done
printf "\nIP addresses extracted:\n"
echo ${IPADDRS[@]} #}}}

# CONNECT TO REMOTES, SCP FILE#{{{
# ================

i=0
printf "\nFile transfer\n"
for IPA in ${IPADDRS[@]}; do
	ssh $LOGIN@$IPA "mkdir -p $PATH_REM" # create working directory, if necessary
  scp $PATH_FUNC$FUNC_NAME $LOGIN@$IPA:$PATH_REM
	i=$((i+1))
done #}}}

