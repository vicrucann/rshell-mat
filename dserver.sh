#!/bin/bash
#
# Perform heavy data processing by splitting the task to different servers:
#   Transfer the data and "kernel" function to the servers. 
#   Wait for servers to complete.
#   Collect and merge the results.

printf "The n input arguments for dserver.sh script are: \n"
printf "[1] LOGIN : login id to the remote servers (assumed it's the same login for every server) \n)"
printf "[2]- PPATH : working directory (will be created if does not exist) on the remote servers; assumed to be the same for each server \n"
printf "[3..n-3]- IPADDRS : range of ip-addresses of all the servers, assumed they have the same login/psw account \n"
printf "[n-2]- REMMAT : name of the matlab function that will be copied and launched on remote servers \n"
printf "[n-1]- VARMAT : name of the workspace varialbes file, in *.mat format; these are the variables to copy and load to matlab memory on the remote servers \n"
printf "[n]- SLEEPTIME : integer that indicates number of seconds to pause when waiting for each remote server to complete their computations \n"


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
PPATH=${args[1]}
i=2
while true; do
	IPADDRS[$((i-2))]=${args[$i]}
	i=$((i+1))
	nservs=$((nservs-1))
	if (( nservs <= 0 )); then
		printf "\nIP addresses extracted:\n"
		echo ${IPADDRS[@]} 
		break
	fi
done

REMMAT=${args[$i]}
VARMAT=${args[$(($i+1))]}
SLEEPTIME=${args[$(($i+2))]}
printf "Finished reading the input arguments\n"
sleep 3

i=0
for IPA in ${IPADDRS[@]}; do
	FDONE[$i]=0
	e=".mat"
	j=$((i+1))
	IFILES[$i]="$VARMAT$j$e"
	i=$((i+1))
done
printf "\nVariables-to-load extracted:\n"
echo ${IFILES[@]}

eval `ssh-agent`
ssh-add
for IPA in ${IPADDRS[@]}; do
	printf "\nFile transfer using scp\n"
	ssh $LOGIN@$IPA "mkdir -p $PPATH"
	scp $REMSCRIPT $LOGIN@$IPA:$PPATH
	scp $REMMAT $LOGIN@$IPA:$PPATH
	for IFA in ${IFILES[@]}; do
		scp $IFA $LOGIN@$IPA:$PPATH
	done
	ssh -n -f $LOGIN@$IPA "sh -c 'cd $PPATH; chmod u+x $REMSCRIPT; nohup ./$REMSCRIPT > tester.out 2> tester.err < /dev/null &'"
	printf "Launched the shell on remote\n"
done

printf "\nWaiting for Matlab scripts to terminate\n"
TLIMIT=50
count=0
tot=0
while [[ $tot -eq 0 ]]; do
	i=0
	for IPA in ${IPADDRS[@]}; do
		printf "Connecting to a server and checking for files...\n"
		if [ ${FDONE[$i]} -eq 0 ]; then
			ssh $LOGIN@${IPADDRS[$i]} "test -e $PPATH/tester.dn"
			if [ $? -eq 0 ]; then
				FDONE[$i]=1
				printf "Server %d obtained results\n" $i
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
done

printf "\nCopying the result files\n"
for IPA in ${IPADDRS[@]}; do
	printf "\nCreating folder for results from server %s\n" $IPA
	mkdir -p $IPA
	printf "File transfer using scp\n"
	scp $LOGIN@$IPA:$PPATH/result.mat $IPA
	scp $LOGIN@$IPA:$PPATH/$REMSCRIPT.out $IPA
	scp $LOGIN@$IPA:$PPATH/$REMSCRIPT.err $IPA
done

kill $SSH_AGENT_PID
