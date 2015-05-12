#!/bin/bash

printf "Script to launch different matlab scripts on remote servers in background\n"

LOGIN=cryo
PPATH=/home/cryo/tester
IPADDRS=(172.23.2.105 172.23.5.77)
NADDRS=${#IPARRDS[@]}
IFILES=(v1.mat v2.mat)
REMSCRIPT=tester
REMMAT=sumvar.m
i=0
for IPA in ${IPADDRS[@]}; do
	FDONE[$i]=0
	i=$(($i+1))
done

SLEEPTIME=10

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
done

printf "\nWaiting for Matlab scripts to terminate\n"
TLIMIT=50
count=0
tot=0
while [[ $tot -eq 0 ]]; do
	printf "inside while loop\n"
	i=0
	for IPA in ${IPADDRS[@]}; do
		printf "Connecting to a server...\n"
		if [ ${FDONE[$i]} -eq 0 ]; then
			ssh $LOGIN@${IPADDRS[$i]} "test -e $PPATH/tester.dn"
			if [ $? -eq 0 ]; then
				FDONE[$i]=1
				printf "Server %d obtained result\n" $i
			else
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

printf "\nTrying to obtain the result files\n"
for IPA in ${IPADDRS[@]}; do
	printf "\nCreating folder for results from server %s\n" $IPA
	mkdir -p $IPA
	printf "File transfer using scp\n"
	scp $LOGIN@$IPA:$PPATH/result.mat $IPA
	scp $LOGIN@$IPA:$PPATH/$REMSCRIPT.out $IPA
	scp $LOGIN@$IPA:$PPATH/$REMSCRIPT.err $IPA
done

kill $SSH_AGENT_PID
printf "\nScript terminated\n"
