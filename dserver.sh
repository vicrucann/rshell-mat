#!/bin/bash
#
# Launches predefined matlab script that loads and processes predefined matlab data
#	Clears all the previous temporal data
#	Launches predefined matlab script in silent mode
#	Generates output data
#	2015 Victoria Rudakova, vicrucann@gmail.com

#{{{# ARGUMENT PARSING
# ================

args=("$@")
nargs=$#
if [ $nargs -ne 4 ]; then
	printf "ERROR: Number of passed parameters must be equal 4\n"
	exit 1
fi

REMMAT=${args[0]}
IFILE=${args[1]}
RESFILE="result_$IFILE"
CACHE=${args[2]}
NCACHE=${args[3]}

test -e $REMMAT.m # check file exists
if [ $? -ne 0 ]; then
	printf "Error on remote: no such file - %s\n" $REMMAT.m
	exit 1
fi

test -e $IFILE # check file exists
if [ $? -ne 0 ]; then
	printf "Error on remote: no such file - %s\n" $IFILE
	exit 1
fi

printf "\nRemote matlab script name: %s\n" $REMMAT
printf "Input file name: %s\n" $IFILE
printf "Result save name: %s\n\n" $RESFILE #}}}

#{{{# LAUNCH THE MATLAB FUNCTION
# ================

printf "\nRunning matlab script\n"
matlab -nodisplay -nojvm -nosplash -nodesktop -wait -r "$REMMAT('$IFILE','$RESFILE','$CACHE','$NCACHE');quit();"
printf "\nMatlab work done\n" #}}}

#{{{# INDICATE MATLAB HAD FINISHED CALCULATIONS
# ================

> dserver.dn
printf "\nresult.dn file generated\n" #}}}

