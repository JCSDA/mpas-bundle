#!/usr/bin/env bash

# 
# create a batch script to run on an HPC compute node, and (optionally) submit it
# can be used to build mpas-bundle or run mpas-bundle ctest
#
# For more information on submitting jobs to Derecho, see:
# https://arc.ucar.edu/knowledge_base/131596447
#

# name of script to create and submit to compute node
JOB_FILE=""

# vars for PBS directives
QUEUE=""
QUEUE_OPTS=""
ACCOUNT=""
ENV_DIR=""
NAME=""

# vars for setting the environment
HPC="unknown"
COMPILER=""

# vars for creating the batch script
EXEC=""
DEFAULT_EXEC="make"
NTHREADS=8

# vars for controlling this script
RUN=""
HELP=""
LOG=""
VERBOSE=""

# derecho params
DERECHO_CC="gnu intel"
DERECHO_CC_INTEL="intel"
DERECHO_Q=("main" "develop" )
QUEUE_OPTS=${DERECHO_Q[@]}

export F_UFMTENDIAN='big_endian:101-200'
export GFORTRAN_CONVERT_UNIT='big_endian:101-200'


usage()
{
	echo "usage: $0 -A account -c gnu|intel [-x make|ctest|echo] [-c compiler] [-l] "
	echo "  [-q queue] [-t threads] [-N name] [-f job-file] [-n] [-e env-dir] [-h] "
	echo
	echo "  account is the HPC account number"
	echo "  -c compiler is one of [ $DERECHO_CC ]"
	echo "  -x to specify what to run, default is -x $DEFAULT_EXEC"
	echo "      use echo to submit a job which only sets the environment (for testing)"
	echo "  -l: wait for job to start and log progress"
	echo "  -q queue is one of [ ${QUEUE_OPTS[@]} ], default is $QUEUE"
	echo "  -t threads is the number of threads to run, default is $NTHREADS"
	echo "  -N name is a name for the job, default is mpas-${DEFAULT_EXEC}"
	echo "  -f job file is the file to be created and submitted to a compute node, default is ${DEFAULT_EXEC}.pbs.sh"
	echo "  -n: don't submit the job to a compute node, only create the batch file"
	echo "  -e env-dir is the directory with the module scripts"
	echo "  -h: print help and exit"
	exit
}

#
# set up host specific elements
#
echo $HOST | grep -q derecho
if [ $? == 0 ]; then
  HPC="derecho"
fi

if [ "$HPC" = "derecho" ]; then
	QUEUE="-q ${DERECHO_Q[0]}"
	QUEUE_OPTS=${DERECHO_Q[@]}
else
	echo "unsupported HPC, must run on HPC login node"
	exit
fi

if [ $# == 0 ]; then
	usage
fi

# get comamnd line args
while getopts A:e:x:q:c:N:f:t:nhlv flag
do
	case "${flag}" in
		A) ACCOUNT=${OPTARG};;
		e) ENV_DIR=${OPTARG};;
		q) QUEUE="-q ${OPTARG}";;
		c) COMPILER=${OPTARG};;
		N) NAME=${OPTARG};;
		f) JOB_FILE=${OPTARG};;
		x) DEFAULT_EXEC=${OPTARG};;
		t) NTHREADS=${OPTARG};;
		n) RUN="echo";;
		h) HELP="help";;
    l) LOG="monitor";;
    v) VERBOSE="v1"
	esac
done

if [ "$ACCOUNT" = "" ]; then
	echo "account (-A) is required"
	echo "   something like nmmm0004"
	echo
	usage
fi

if [ "$COMPILER" = "" ]; then
	echo "compiler (-c) is required"
	echo "gnu or intel"
	echo
	usage
fi

if [ "$ENV_DIR" = "" ]; then
  # if there's a '/' in the command name use the directory to find the module file
  SCRIPT=$0
  if [[ "$SCRIPT" =~ .*/+ ]]; then
    ENV_DIR=${SCRIPT%/*}
    if [ "$VERBOSE" != "" ]; then
      echo env_dir:$ENV_DIR
    fi
  else
    echo "environment dir (-e) is required"
    echo "   something like ../mpas-bundle/env-setup/"
    echo
    usage
  fi
fi

if [ "$NAME" = "" ]; then
  NAME="mpas-${DEFAULT_EXEC}"
fi

if [ "$JOB_FILE" = "" ]; then
  JOB_FILE=${DEFAULT_EXEC}".pbs.sh"
fi

if [ "$HELP" != "" ];then
	usage
fi

# check for alternate compiler
if [ "$HPC" == "derecho" ]; then
	if [ "$COMPILER" == "gnu" ]; then
    MODFILE="${ENV_DIR}/gnu-derecho.sh"
	elif [ "$COMPILER" == "intel" ]; then
    MODFILE="${ENV_DIR}/intel-derecho.sh"
	else
		echo unknown compiler: $COMPILER, must be either "gnu" or "intel"
		echo
		usage
	fi
fi
if [ "$VERBOSE" != "" ]; then
  echo modfile:$MODFILE
fi

if [ "$DEFAULT_EXEC" == "make" ]; then
	EXEC="$DEFAULT_EXEC -j$NTHREADS"
elif [ "$DEFAULT_EXEC" == "ctest" ]; then
	EXEC="cd mpas-jedi && ctest"
elif [ "$DEFAULT_EXEC" == "echo" ]; then
	EXEC="echo finished"
else
	echo "unknown exec: $DEFAULT_EXEC"
	EXEC=""
fi

# create the bash script to run on a compute node
cat > $JOB_FILE << EOF
#!/usr/bin/env bash

#PBS -l walltime=01:00:00
#PBS -j oe
#PBS -k eod
#--- get 1 cpu per thread
#PBS -l select=1:ncpus=$NTHREADS
#--- 
#PBS -N $NAME
#PBS -A $ACCOUNT
#PBS $QUEUE

date
EOF

cat $MODFILE >> $JOB_FILE
echo $EXEC >> $JOB_FILE

# submit the job to a compute node
if [ "$RUN" = "" ]; then
	echo Running qsub  $JOB_FILE
	jobno=`qsub  $JOB_FILE`
  # remove the trailing ".desched"
  jobno="${jobno%\.*}"
  logfile=${NAME}.o${jobno}
  if [ "$VERBOSE" != "" ]; then
    echo log will be in ${logfile}
  fi
  if [ "$LOG" != "" ];then
    if [ ! -f ${logfile} ]; then
      echo  -n "Waiting for job to start "
    fi
    while [ ! -f ${logfile} ]
    do
      echo -n ". "
      sleep 60
    done
    tail -f ${logfile}
  else
    echo "after job starts run"
    echo "   tail -f ${logfile}"
    echo " to see progress"
  fi
else
	echo created script $JOB_FILE
	echo To run it: qsub  $JOB_FILE
fi

