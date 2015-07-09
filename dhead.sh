#!/bin/bash
#
# Perform heavy data processing by splitting the task to different servers:
#   Transfer the data and "kernel" function to the servers.
#   Wait for servers to complete.
#   Collect and merge the results.
#   dhead.sh - "distributed head server shell".
#   2015 Victoria Rudakova, vicrucann@gmail.com

# HEADER INSTRUCTIONS#{{{
# ================

#printf "The n input arguments for dhead.sh script are: \n"
#printf "[0] LOGIN : login id to the remote servers (assumed it's the same login for every server)\n"
#printf "[1]- PATH_REM : temporal working directory (will be created if does not exist) on the remote servers; assumed to be the same for each server \n"
#printf "[2..n-8]- IPADDRS : range of ip-addresses of all the servers, assumed they have the same login/psw account \n"
#printf "[n-7]- PATH_FUN : path name where REM_FUN function is located \n"
#printf "[n-6]- REM_FUN : name of the matlab function (e.g. 'myfunc') that will be copied and launched on remote servers by dserver.sh \n"
#printf "[n-5]- PATH_VARS : path name where VARS data will be saved to and loaded from \n"
#printf "[n-4]- VARS : name of the workspace varialbes file (without numeration and .mat); these are the variables to copy and load to matlab memory on the remote servers \n"
#printf "[n-3]- PATH_CURR : path name where .sh scripts are located, literally, it is a full path to the current folder \n"
#printf "[n-2]- SLEEPTIME : integer that indicates number of seconds to pause when waiting for each remote server to complete their computations \n"
#printf "[n-1] - PATH_RES : name of the local folder where the results will be copied to from the servers \n"
#printf "[n-2] - CVARS : rootname of the cached (kept on disk, .dat files) variable file that was copied in advance to the remotes \n"
#printf "[n-1] - NCVARS : number of cached files copied to each remote \n"
#}}}

# ARGUMENTS PARSING#{{{
# ================

args=("$@")
printf "\nNumber of arguments passed: %d\n" $#
nargs=$#
if [ $nargs -lt 12 ]; then
	echo "ERROR: Number of passed arguments is smaller than required minimum (12)"
	exit 1
fi
nservs=$((nargs-11))
printf "Number of servers: %d\n" $nservs

LOGIN=${args[0]}
printf "The login parameter: %s\n" $LOGIN
PATH_REM=${args[1]}
printf "The remote working directory: %s\n" $PATH_REM
i=2
while true; do
	IPADDRS[$((i-2))]=${args[$i]}
	i=$((i+1))
	nservs=$((nservs-1))
	if (( nservs <= 0 )); then
		break
	fi
done
printf "\nIP addresses extracted:\n"
echo ${IPADDRS[@]}

PATH_FUN=${args[$nargs-9]}

REM_FUN=${args[$nargs-8]} # check file existance
test -e $PATH_FUN$REM_FUN.m
if [ $? -ne 0 ]; then
	printf "ERROR: no such file: %s\n" $PATH_FUN$REM_FUN.m
	exit 1
fi
printf "Matlab script file for remote: %s\n" $PATH_FUN$REM_FUN.m

PATH_VARS=${args[$(($nargs-7))]}
VARS=${args[$(($nargs-6))]} # check file existance
j=1
i=0
for IPA in ${IPADDRS[@]}; do
	test -e $PATH_VARS$VARS$j.mat
	if [ $? -ne 0 ]; then
		printf "ERROR: no such file: %s\n" $PATH_VARS$VARS$j.mat
		exit 1
	fi
	FDONE[$i]=0
	IFILES[$i]="$VARS$j.mat"
	j=$((j+1))
	i=$((i+1))
done
printf "\nVariables-to-load extracted:\n"
echo $PATH_VARS${IFILES[@]}

PATH_CURR=${args[$(($nargs-5))]}
REM_BASH="dserver.sh" # check file existance
test -e $PATH_CURR$REM_BASH
if [ $? -ne 0 ]; then
	printf "ERROR: no such file: %s\n" $PATH_CURR$REM_BASH
	exit 1
fi
printf "Remote bash script: %s\n" $PATH_CURR$REM_BASH

SLEEPTIME=${args[$(($nargs-4))]}
printf "Pause time is set to %i\n" $SLEEPTIME

PATH_RES=${args[$(($nargs-3))]}
mkdir -p $PATH_RES
printf "The folder to collect result files: %s\n" $PATH_RES
printf "\nFinished reading the input arguments\n"

CVARS=${args[$(($nargs-2))]}
NCVARS=${args[$(($nargs-1))]} #}}}

# CONNECT TO REMOTES, SCP FILES, LAUNCH REMOTE BASH#{{{
# ================

#eval `ssh-agent`
#ssh-add
i=0
printf "\nFile transfer and script launching\n"
for IPA in ${IPADDRS[@]}; do
	ssh $LOGIN@$IPA "mkdir -p $PATH_REM" # create working directory, if necessary
	ssh $LOGIN@$IPA "rm -f $PATH_REM/*.mat" # clear the working directory from any previous data
	ssh $LOGIN@$IPA "rm -f $PATH_REM/*.out" # clear the working directory from any previous data
	ssh $LOGIN@$IPA "rm -f $PATH_REM/*.err" # clear the working directory from any previous data
	ssh $LOGIN@$IPA "rm -f $PATH_REM/*.dn" # clear the working directory from any previous data
	scp $PATH_CURR$REM_BASH $LOGIN@$IPA:$PATH_REM
	scp $PATH_FUN$REM_FUN.m $LOGIN@$IPA:$PATH_REM
	scp -c arcfour $PATH_VARS${IFILES[$i]} $LOGIN@$IPA:$PATH_REM

	ssh -n -f $LOGIN@$IPA "sh -c 'cd $PATH_REM; chmod u+x $REM_BASH; nohup ./$REM_BASH $REM_FUN ${IFILES[$i]} $CVARS $NCVARS  > $VARS.out 2> $VARS.err < /dev/null &'"
	i=$((i+1))
done #}}}

# WAIT LOOP FOR MATLAB FUNCTION ON REMOTE TO TERMINATE#{{{
# ================

printf "\nWaiting for Matlab scripts to terminate\n"
TLIMIT=5000 # max wait time = TLIMIT * SLEEPTIME
count=0
tot=0
while [[ $tot -eq 0 ]]; do
	i=0
	for IPA in ${IPADDRS[@]}; do
		if [ ${FDONE[$i]} -eq 0 ]; then
			printf "Connecting to a server %s and checking for files...\n" $IPA
			ssh $LOGIN@${IPADDRS[$i]} "test -e $PATH_REM/dserver.dn" # check if *.dn file was generated
			if [ $? -eq 0 ]; then
				FDONE[$i]=1
				printf "Server %d (%s) obtained results\n" $i $IPA
				#printf "\nCopying the result files\n"
				#nohup scp $LOGIN@$IPA:$PATH_REM/result_${IFILES[$i]} $PATH_RES &
			else
				printf " not ready, pause.\n"
				sleep $SLEEPTIME
			fi
		fi
		i=$(($i+1))
	done

	count=$(($count+1))
	if [ $count -eq $TLIMIT ]; then
		printf "Time out - check if requested files exist on remotes\n"
		exit 0
	fi

	tot=1
	i=0
	for IPA in ${IPADDRS[@]} ; do
		if [ ${FDONE[$i]} -eq 0 ]; then
			tot=0
		fi
		i=$(($i+1))
	done
done #}}}

# SCP FROM REMOTES TO LOCAL THE RESULT DATA #{{{
# ================

printf "\nCopying the result files\n"
i=0
for IPA in ${IPADDRS[@]}; do
	#printf "\nCreating folder for results from server %s\n" $IPA
	#mkdir -p $IPA
	#mkdir -p $PATH_RES
	printf "File transfer using scp\n"
	scp -c arcfour $LOGIN@$IPA:$PATH_REM/result_${IFILES[$i]} $PATH_RES  # $IPA
	#scp $LOGIN@$IPA:$PATH_REM/$VARS.out $IPA
	#scp $LOGIN@$IPA:$PATH_REM/$VARS.err $IPA
	i=$(($i+1))
done

#kill $SSH_AGENT_PID #}}}

printf "\nBash script terminated\n"
