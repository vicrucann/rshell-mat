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
if [ $nargs -ne 3 ]; then
	printf "ERROR: Number of passed parameters must be equal 3\n"
	exit 1
fi

REMMAT=${args[0]}
IFILE=${args[1]}
CFILE=${args[2]}
RESFILE="result_$IFILE"

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

if [ $CFILE -ne 0 ]; then
  # check file exists
  test -e $CFILE
  if [ $? -ne 0 ]; then
    printf "Error on remote: no such file - %s\n" $CFILE
    exit 1
  fi
fi

printf "\nRemote matlab script name: %s\n" $REMMAT
printf "Input file name: %s\n" $IFILE
printf "Cache file (0 if nonoe): %s\n" $CFILE
printf "Result save name: %s\n\n" $RESFILE#}}}

#{{{# LAUNCH THE MATLAB FUNCTION
# ================

#printf "\nRunning matlab script\n"
matlab -nodisplay -nojvm -nosplash -nodesktop -wait -r "$REMMAT('$IFILE','$RESFILE','$CFILE');quit();"
#printf "\nMatlab work done\n"#}}}

#{{{# INDICATE MATLAB HAD FINISHED CALCULATIONS
# ================

> dserver.dn
#printf "\nresult.dn file generated\n"#}}}

