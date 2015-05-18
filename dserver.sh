#!/bin/bash
#
# Launches predefined matlab script that loads and processes predefined matlab data
#	Clears all the previous temporal data
#	Launches predefined matlab script in silent mode
#	Generates output data

args=("$@")
nargs=$#
if [ $nargs -ne 2 ]; then
	printf "ERROR: Number of passed parameters must be equal 2\n"
	exit 1
fi

REMMAT=${args[0]}
IFILE=${args[1]}

printf "\nRemote matlab script name: %s\n" $REMMAT
printf "Input file name: %s\n\n" $IFILE

printf "Cleaning up the old data..."
rm -f dserver.dn
rm -f result.mat
printf "done\n"

printf "\nRunning matlab script\n"
matlab -nodisplay -nojvm -nosplash -nodesktop -r "$REMMAT('$IFILE'),quit()"
printf "\nMatlab work done\n"

> dserver.dn
printf "\nresult.dn file generated\n"

