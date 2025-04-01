#!/bin/bash -l

#--------------------------------------------------------------
# Script to build mpas-bundle and run mpas-jedi ctests.
# mpas-bundle may be built with both the gnu and intel tool chains.
# After running mpas-jedi ctests the results will be put into an html document,
# which will be copied to the web pages directory on whitedwarf.mmm.ucar.edu
#
# This script assumes the mpas-bundle repository has been cloned into
#  <some_dir>/<mpas-bundle_dir>    # directory mpas-bundle has been cloned to
# This script will make the following directory layout if it doesn't exist:
#  <some_dir>/build-gnu-2p   # directory to build the bundle with the gnu tool chain, double precision
#  <some_dir>/build-gnu-1p   # directory to build the bundle with the gnu tool chain, single precision
#  <some_dir>/build-intel-2p # directory to build the bundle with the intel tool chain, double preecision
#  <some_dir>/build-intel-1p # directory to build the bundle with the intel tool chain, single preecision
#  Note the build directories are adjacent to the bundle source directory.
#
# This script is expected to be run via cron, but can be run manually as well.
# See usage() for invocation

declare -r timestamp="$(date +%F-%H-%M)"
declare -r lock_file_name="mpas_bundle_cron.lock"
LOCK_FILE=""
LOGFILE=""

init_logs()
{
  local cron_logdir="$1"
  mkdir -p ${cron_logdir} || exit 1
  LOGFILE="${cron_logdir}/mpas-bundle-cron.log.${timestamp}"
  touch $LOGFILE
  HTML_BODY_FILE="${cron_logdir}/body.html"
}

# where to copy html output files on whitedwarf.mmm.ucar.edu
html_dir="/web/htdocs/projects/mpas-jedi/weekly-ctests"
# available queues to use
# normal cpu hours are charged
MAIN_Q="main@desched1"
# charged @ .3 * regular rate, job may not run to completion
PREEMPT_Q="preempt@desched1"
# shared nodes, charged only for the no. of cpu's used
DEV_Q="develop@desched1"

usage()
{
  args="-d <bundle_dir> -c <compiler> [-x <suffix>] [-q <queue>] [-a <account>] [ -p <precision>] [-l <lock_file>] [-o <out_dir>] [-f] [-h] [-n]"
  log "usage:"
  log "  mpas-bundle-cron.sh ${args}"
  log "    -d <bundle_dir> is where the mpas-bundle repo has been cloned to"
  log "    -c <compiler> is one of gnu, intel or both"
  log "    -x <suffix> is a suffix to add to the build directory"
  log "    -q <queue> is ${MAIN_Q}, ${DEV_Q} or ${PREEMPT_Q}, defaults to ${MAIN_Q}"
  log "    -a <account> is the account to use when submitting PBS jbs (e.g. 'nmmm0015')"
  log "    -p <precision> is 1 or 2, defaults to 2 (double)"
  log "    -l <lock_file> is absolute path to the lock file which indicates the build is running,"
  log "        default is <bundle_dir>/$lock_file_name"
  log "    -o <out_dir> is where the html files will be copied to, default is $html_dir"
  log "    -f means force-build, always build even if no source changed since last build"
  log "    -h prints help and exits"
  log "    -n means don't run cmake"
  exit 1
}

log()
{
  if [ -f "${LOGFILE}" ]; then
    echo -e "$1" | tee -a ${LOGFILE}
  else
    echo -e "$1"
  fi
}

remove_lock()
{
    rm -f "${LOCK_FILE}"
}

another_instance()
{
    log "Cannot acquire lock on ${LOCK_FILE}"
    log "There is another instance running, exiting"
    exit 1
}

# check the return code of a pbs job, return 0 if it succeeded, else return non-zero
check_pbs_return()
{
  local jobno=$1
  local pbs_status=$(qstat -x -f $jobno | grep 'Exit_status')

  if [ ! -z "${pbs_status}" ]; then
    retcode=$(echo $pbs_status|awk '{print $3}')
    return $retcode
  else
    return 1
  fi
}

# wait for the provided job to either show in the queue ($2 is 1)
# or for the job to leave the queue ($2 is 0)
queue_wait()
{
  local job=$1
  local pcode=$2
  local secs=$3

  qstat ${job} &> /dev/null
  local rc=$?
  while [ ${rc} == "${pcode}" ]; do
    sleep ${secs}
    qstat ${job} &> /dev/null
    rc=$?
  done
}

# write html header, including the table directive
print_header()
{
  outfile=$1
  local html_header=("<!DOCTYPE html> <html> <head> <style>" \
  "table { font-family: arial, sans-serif; border-collapse: collapse; width: 100%; }" \
  "td, th { border: 1px solid #dddddd; text-align: left; padding: 8px; }" \
  "tr:nth-child(even) { background-color: #dddddd; } </style> </head>" \
  "<body> <h2>mpas-bundle mpas-jedi ctest results</h2>" \
  "<table> <tr> <th>Date</th> <th>Results</th> <th>Spack</th> <th>Compiler</th> <th>Tools</th> <th>Stats</th></tr>")

  for line in ${!html_header[@]}; do
    echo -n ${html_header[$line]} >> ${outfile}
    echo >> ${outfile}
  done
}

# write html to end the page
print_footer()
{
  outfile=$1
  echo "</table> </body> </html>" >> ${outfile}
}

# create a script which will execute cmake and run it on derecho
run_cmake()
{
  cmake_script="${LOG_DIR}/run_cmake.sh"

cat > $cmake_script << CMAKE_EOF
#!/bin/bash
#
cd $1 && source ../mpas-bundle/env-setup/$2-derecho.sh && if [ -f Makefile ]; then echo "make update" && make update |& tee make.update.log; fi && cmake -DCMAKE_VERBOSE_MAKEFILE=ON -DBUNDLE_SKIP_RTTOV=ON -DMPAS_DOUBLE_PRECISION=$3 ctest_update  ../mpas-bundle;
CMAKE_EOF

  chmod 755 ${cmake_script}
  ssh derecho.hpc.ucar.edu ${cmake_script} |& tee ${cmake_script}.log
}

# create a script which will check for changes in git repositories, and run it on derecho
check_git_changes()
{
  check_changes_log=$2

  check_script="${LOG_DIR}/check_changes.sh"
  update_file="${LOG_DIR}/files_changed.lock"
  rm ${update_file}

cat > $check_script << EOF
#!/bin/bash -l
#
# check to see if any source files changed in git.
# this is meant to be called from automated scripts.

# touch $update_file if sources changed
check_for_changes() {
  # traverse subdirectories
  dirs=\$(ls -d */)
  for subdir in \$dirs;
  do

    # skip directories which don't have a git repo
    if [ ! -d "\${subdir}/.git" ]; then
      continue
    fi

    echo \$subdir
    cd "\$subdir"

    # get latest code and see if it has changed
    git fetch >& /dev/null
    local branch=\$(git rev-parse --abbrev-ref HEAD)
    local remote=\$(git remote get-url origin)
    local local_commit=\$(git rev-parse --short HEAD)
    local remote_commit=\$(git rev-parse --short origin/\${branch})
    if [ "\$local_commit" != "\$remote_commit" ]; then
      echo "updating \${remote} in branch \${branch} to sha \$remote_commit." &>> $check_changes_log
      git pull &>> $check_changes_log
      echo "\${remote} in branch \${branch} has been updated to sha \$remote_commit."
      touch $update_file
    else
      echo "No updates found for \${remote} in branch \${branch}, sha \$local_commit."
    fi

    cd ..
  done
}

echo "work_dir $1"
echo "sync_file $update_file"
cd $1
check_for_changes
EOF

  # run a script on derecho, it needs git which is not on the cron server
  chmod 755 ${check_script}
  log "ssh derecho.hpc.ucar.edu ${check_script} ${BUNDLE_DIR} ${update_file} |& tee ${check_changes_log}"
  ssh derecho.hpc.ucar.edu "${check_script} |& tee ${check_changes_log}"
  local ret_code=0
  if [ -f ${update_file} ]; then
    log "update file $update_file exists"
    ret_code=1
  fi
  rm $update_file
  return $ret_code
}

# run the ctests
run_ctests()
{
  # input params
  local scripts=$1
  local cc=$2
  local make_job=$3
  local timestamp=$4

  # output params
  local lsummary="" # 5th param
  local lctest_time=""  # 6th param
  local lhref="href=\"./ctest.results.log.${timestamp}\"" # 7th param

  # create script to run ctest and run it, holding it until the make job finishes
  mv ./${CTEST_LOGFILE} ./${CTEST_LOGFILE}.old
  log "${scripts}/run_make.bundle.sh -A ${ACCOUNT} -q ${QUEUE} -p economy -x ctest -c ${cc} -N cron-${cc}-ctest-mpas -m -n"
  ${scripts}/run_make.bundle.sh -A ${ACCOUNT} -q ${QUEUE} -p economy -x ctest -c ${cc} -N "cron-${cc}-ctest-mpas" -m -n
  local ctest_job=$(qsub -W depend=afterok:${make_job} ./ctest.pbs.sh) || \
    { log "cannot connect to Derecho PBS" ; exit 1; }
  log "${cc} ctest: ${ctest_job}"

  # wait for the ctest job to show up in the queue, check every 5 seconds
  queue_wait ${ctest_job} 1 5

  # wait for the ctest job to finish, check every 60 seconds
  queue_wait ${ctest_job} 0 60

  # get the runtimes for the PBS ctest job
  lctest_time=$(qstat -xf ${ctest_job} | grep used.walltime | awk '{print $3}')

  # if there's no log file, the make was probably aborted, so ctest didn't run
  if [ ! -f ${CTEST_LOGFILE} ]; then
    # check the make job for success
    check_pbs_return $make_job
    local make_rc=$?
    if [ "$make_rc" -ne 0 ]; then
      lsummary="make job failed return code $make_rc"
      lctest_time="NA"
      lhref=""
    else
      check_pbs_return $ctest_job
      local ctest_rc=$?
      if [ "$ctest_rc" -ne 0 ]; then
        lsummary="ctest job failed return code $ctest_rc"
        lctest_time="NA"
        lhref=""
      else
        lsummary="ctests didn't run, unknown failure"
        lctest_time="NA"
        lhref=""
      fi
    fi
  else
    lsummary=`grep 'tests .*passed' ${CTEST_LOGFILE}`
    if [ -z "$lsummary" ]; then
      lsummary="ctest run didn't complete"
    fi
  fi
  log "run_ctests() summary:$lsummary href:$lhref ctest_time:$lctest_time"
  eval "$5=\"$lsummary\""
  eval "$6=\"$lctest_time\""
  eval "$7=\"$lhref\""
}

# build the html file and copy it to the web server
make_html()
{
  local dest_dir=$1
  local make_job=$2
  local cc=$3
  local timestamp=$4
  local ctest_time=$5
  local summary=$6
  local href=$7
  local sha_file=$8
  #local dest_dir="/web/htdocs/projects/mpas-jedi/weekly-ctests"

  log "make_html() dest_dir: $dest_dir make_job=$make_job ctest_time=$ctest_time"
  log "            cc=$cc timestamp=$timestamp href=$href summary=$summary"
  log "            chref=$href sha_file=$sha_file sha_file:t=${sha_file##*/}"

  # get tool versions to put into summary table
  local spack_stack=$(grep spack-stack- ../mpas-bundle/env-setup/${cc}-derecho.sh | awk -F/ '{print $8}')
  log "spack-stack: ${spack_stack}"
  if [ ${cc} == "gnu" ]; then
    local comp="gcc"
  else
    local comp="intel"
  fi
  local compiler=$(grep "load *stack-${comp}" ../mpas-bundle/env-setup/${cc}-derecho.sh | awk '{print $3}')
  log "compiler: ${compiler}"
  local mpich=$(grep "load *stack-cray" ../mpas-bundle/env-setup/${cc}-derecho.sh | awk '{print $3}')
  log "mpich: ${mpich}"


  # get the runtime for the PBS make job
  local make_time=$(qstat -xf ${make_job} | grep used.walltime | awk '{print $3}')

  # prepend current results to the table, then add the old entries
  local stats="<a href=./${sha_file##*/}> Q:${QUEUE%"@desched1"} make:${make_time} ctest:${ctest_time}</a>"
  echo "<tr><td>${timestamp}</td> <td><a ${href}>${summary}</a></td> <td>${spack_stack}</td> <td>${cc}</td> <td>${compiler} ${mpich}</td> <td>${stats}</td> " > body.html
  if [ -f ${HTML_BODY_FILE} ]; then
    cat ${HTML_BODY_FILE} >> body.html
  fi
  cp body.html ${HTML_BODY_FILE}

  rm -f index.html
  print_header  index.html
  cat body.html >> index.html
  print_footer index.html
  rm body.html

  local host="whitedwarf.mmm.ucar.edu"
  local dest="${host}:${dest_dir}"
  local index_tarfile="index.tar"

  if [ -f ${CTEST_LOGFILE} ]; then
    local resultsfile="ctest.results.tmp"
    echo ${timestamp} > ${resultsfile}
    echo >> ${resultsfile}
    egrep -A 20 'Test|Start' ${CTEST_LOGFILE} >> ./${resultsfile}
    mv ${resultsfile} ctest.results.log.${timestamp}
    log "scp ./ctest.results.log.${timestamp} ${dest}"
    scp ./ctest.results.log.${timestamp} ${dest} || { log "scp ctest_results failed"; }
    log "scp ${sha_file} ${dest}"
    scp ${sha_file} ${dest} || { log "scp $sha_file failed"; }
    mv ctest.results.log.${timestamp} ctest.results.log.old
  else
    log "${CTEST_LOGFILE} doesn't exist"
    log "scp ${sha_file} ${dest}"
    scp ${sha_file} ${dest} || { log "scp $sha_file failed"; }
  fi
  # clean up old index files by putting them in a tar file
  log "ssh ${host} cd ${dest_dir} && tar --remove-files -rf ${index_tarfile} index.2"
  ssh ${host} "cd ${dest_dir} && tar --remove-files -rf ${index_tarfile} index.2*"
  mv index.html index.${timestamp}.html
  log "scp ./index.${timestamp}.html ${dest}"
  scp ./index.${timestamp}.html ${dest} ||{ log "scp index failed"; }
  rm index.${timestamp}.html
  log "ssh ${host} cd ${dest_dir} && rm -f index.html && ln -s index.${timestamp}.html index.html"
  ssh ${host} "cd ${dest_dir} && rm -f index.html && ln -s index.${timestamp}.html index.html"
}

# run cmake, make, and ctest for the provided build chain
build_and_test()
{
  local cc=$1
  local dbl_p=$2
  local html_dir=$3
  local run_cmake=$4
  local sha_file=$5
  local suffix=$6

  local build_dir_suffix=""
  if [ $dbl_p == "ON" ]; then
    build_dir_suffix="2p"
  else
    build_dir_suffix="1p"
  fi
  local scripts=${BUNDLE_DIR}/env-setup/

  #--------------------------------------------------------------
  # go to build directory, exit on failure:
  BUILD_DIR="${BUNDLE_DIR}/../build-${cc}-${build_dir_suffix}"
  if [ "$suffix" != "" ]; then
    BUILD_DIR="${BUILD_DIR}_${suffix}"
  fi

  mkdir -p ${BUILD_DIR}
  log "BUNDLE_DIR ${BUNDLE_DIR}"
  log "BUILD_DIR ${BUILD_DIR}"
  cd ${BUILD_DIR} || { log "cannot cd ${BUILD_DIR}"; exit 1; }
  log "building in: ${PWD}"

  # run cmake on a login node (compute nodes have poor internet transmission)
  # block until cmake finishes
  if [[ "$run_cmake" == "yes" ]]; then
    run_cmake ${BUILD_DIR} ${cc} $dbl_p
  fi

  # create script to run gnu make and run it
  mv make.pbs.sh.log make.pbs.sh.log.old
  log "${scripts}/run_make.bundle.sh -A ${ACCOUNT} -q ${QUEUE} -p economy -x make -c ${cc} -N cron-${cc}-make-mpas -m -n"
  ${scripts}/run_make.bundle.sh -A ${ACCOUNT} -q ${QUEUE} -p economy -x make -c ${cc} -N "cron-${cc}-make-mpas" -m -n
  local make_job=$(qsub make.pbs.sh) || { log "cannot connect to Derecho PBS"; exit 1; }
  log "${cc} make: ${make_job}"
  local ctest_time=""
  local summary=""
  local href=""

  # only run ctest for double precision builds
  if [ "${dbl_p}" == "ON" ]; then
    run_ctests $scripts $cc $make_job $timestamp summary ctest_time href  
    log "build_and_test() summary:$summary href:$href ctest_time:$ctest_time"
  else
    # wait for the make job
    # wait for the make job to show up in the queue, check every 5 seconds
    queue_wait ${make_job} 1 5

    # wait for the make job to finish, check every 60 seconds
    queue_wait ${make_job} 0 60
    summary="Single precision build - no ctests run"
    ctest_time="NA"
  fi

  #
  # create and copy the docs to the web page directory
  #
  log "calling make_html() dir: $html_dir make_job $make_job ctest_time $ctest_time cc $cc timestamp $timestamp href $href summary $summary"
  make_html $html_dir $make_job $cc $timestamp $ctest_time "$summary" $href  $sha_file
}

CTEST_LOGFILE="ctest.pbs.sh.log"
QUEUE=$MAIN_Q
BUNDLE_DIR=""
tools=""
precision="2"
force_build=0
LOG_DIR="${HOME}/my_cron_logs/"
help=""
run_cmake="yes"
suffix=""
ACCOUNT="nmmm0015"

# get comamnd line args
while getopts d:q:a:p:c:l:o:x:fhn flag
do
  case "${flag}" in
    d) BUNDLE_DIR="${OPTARG}";;
    q) QUEUE="${OPTARG}";;
    a) ACCOUNT="${OPTARG}";;
    p) precision=${OPTARG};;
    c) tools=${OPTARG};;
    l) LOCK_FILE=${OPTARG};;
    o) html_dir=${OPTARG};;
    x) suffix=${OPTARG};;
    f) force_build=1;;
    h) help="help";;
    n) run_cmake="no";;
  esac
done

init_logs $LOG_DIR
log "commandline: $0 $*"

if [ "$help" != "" ]; then
  usage
fi

# location of the mpas-bundle source dir
if [ "$BUNDLE_DIR" = "" ]; then
  log "source dir <-d source_dir> is required"
  usage
fi
if [ ! -d ${BUNDLE_DIR} ]; then
  log "source dir ${BUNDLE_DIR} does not exist"
  usage
fi

if [[ "$QUEUE" != "$MAIN_Q" && "$QUEUE" != "$PREEMPT_Q" && "$QUEUE" != "$DEV_Q" ]]; then
  log "queue \"${QUEUE}\" is invalid"
  usage
fi

if [ "$tools" = "" ]; then
  log "compiler <-c compiler> is required"
  usage
fi

if [ "$precision" = "2" ]; then
  dbl_precision="ON"
else
  dbl_precision="OFF"
fi

log "q:$QUEUE precision: $precision $dbl_precision force: $force_build"

# acquire an exclusive lock on our ${LOCK_FILE} file to make sure
# only one copy of this script is running at a time.
# wait 10 seconds between attempts to get the lockfile,
# retry 360 times ( 1 hr) , delete lockfile which is over 20 hours old.
# Also, the compiles can get stuck in PBS queues for lengthy periods, so we want to queue up
# single and double precision builds simultaneously.
if [ "$LOCK_FILE" = "" ]; then
  LOCK_FILE="${BUNDLE_DIR}/$lock_file_name"
fi
lockfile -10 -r 360 -l 72000 "${LOCK_FILE}" || another_instance
trap remove_lock EXIT
log "lockfile: ${LOCK_FILE}"

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
log "[${timestamp}]: Running ${0} on $(hostname)\n\tfrom $(pwd)\n\tscriptdir=${scriptdir}" 
log "using job queue ${QUEUE}"

#  check for any changed source, store all current git sha's in a file
declare -r sha_file="${LOG_DIR}/git_shas.$timestamp"
check_git_changes ${BUNDLE_DIR} $sha_file
declare -r git_changes=$?
log "check_git_changes returned $git_changes"

# check to see if any source files changed, do nothing if no changes
if [ "$force_build" -eq 0 ]; then
  if [ "$git_changes" -eq 1 ]; then
    force_build=1
    log "forcing build, check_git_changes returned 1"
  fi
fi

if [ "$force_build" -eq 0 ]; then
  log "no source changes, not running"
else
  log "building with tools ${tools}"
  # build gnu version and run ctest
  if [[ "$tools" == "gnu" || "$tools" == "both" ]]; then
    log "build_and_test gnu $dbl_precision $html_dir $run_cmake $sha_file $suffix"
    build_and_test "gnu" $dbl_precision $html_dir $run_cmake $sha_file $suffix
  fi

  # build intel version and run ctest
  if [[ "$tools" == "intel" || "$tools" == "both" ]]; then
    build_and_test "intel" $dbl_precision $html_dir $run_cmake $sha_file $suffix
  fi
fi

