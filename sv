#!/bin/bash

printf "Script to launch different matlab scripts on remote servers in background\n"

LOGIN=cryo
PPATH=/home/cryo/tester
IPADDRS=(172.23.2.105 172.23.5.77)
IFILES=(v1.mat v2.mat)
REMSCRIPT=tester
REMMAT=sumvar.m
FDONE1=0
FDONE2=0

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
	ssh -n -f $LOGIN@$IPA "sh -c 'cd $PPATH; nohup ./$REMSCRIPT > tester.out 2> tester.err < /dev/null &'"
done

printf "\nWaiting for Matlab scripts to terminate\n"
TLIMIT=50
count=0
while [[ $FDONE1 -eq 0 || $FDONE2 -eq 0 ]]; do
	if [ $FDONE1 -eq 0 ]; then
		ssh $LOGIN@${IPADDRS[0]} "test -e $PPATH/tester.dn"
		if [ $? -eq 0 ]; then
			FDONE1=1
			printf "FDONE1 is positive\n"
		else
			sleep 10
		fi
	fi
	if [ $FDONE2 -eq 0 ]; then
		ssh $LOGIN@${IPADDRS[1]} "test -e $PPATH/tester.dn"
		if [ $? -eq 0 ]; then
			FDONE2=1
			printf "FDONE2 is positive\n"
		else
			sleep 10
		fi
	fi
	count=$(($count+1))
	if [ $count -eq $TLIMIT ]; then
		printf "Time out - check if requested files exist on remotes\n"
		exit 0
	fi	
done

printf "\nTrying to obtain the result files\n"
for IPA in ${IPADDRS[@]}; do
	printf "\nCreating folder for results from server %s\n" $IPA
	mkdir -p $IPA
	printf "File transfer using scp\n"
	scp $LOGIN@$IPA:$PPATH/result.mat $IPA
done

kill $SSH_AGENT_PID
printf "\nScript terminated\n"
