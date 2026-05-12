
# run scripts to build mpas-bundle and run ctest
# to use this, 
# 1. log on to cron.hpc.ucar.edu
# 2. run: crontab crontab.sh

# set this to the directory the mpas-bundle repository has been cloned to
# don't put it on scratch or it will get corrupted due to scratch retention policy
bundle_dir=/glade/work/jwittig/repos1/mpas-bundle-cron-src/mpas-bundle
# set this to where the builds are - we want them on scratch so they get cleaned up
builds_dir=/glade/derecho/scratch/jwittig/repos-s/mpas-bundle-cron/
# the directory where the single precision bundle build is
bundle_build_dir="'/glade/derecho/scratch/jwittig/repos-s/mpas-bundle-cron/build-gnu-1p_[01]'"
# this is the build script to execute, relative to the mpas-bundle source directory
build_script=env-setup/mpas-bundle-cron.sh

# the workflow directory with the develop branch, used when running the cylc workflow
workflow_dev_dir=/glade/derecho/scratch/jwittig/repos-s/MPAS-Workflow-develop
# the workflow directory with the script to run a workflow and make graphs
workflow_dir=/glade/derecho/scratch/jwittig/repos-s/MPAS-Workflow-cron
# the script to run a cylc job and to create graphs, relative to the workflow directory
workflow_script=env-setup/run_cylc.sh
# the workflow scenario to run, relative to the workflow directory
workflow_scenario=scenarios/3denvar_OIE120km_WarmStart_VarBC_cron.yaml
workflow_scenario2=scenarios/3dhybrid_OIE120km_WarmStart_cron.yaml

# the directory with the graphics scripts
graphs_dir=/glade/derecho/scratch/jwittig/repos-s/mpas-jedi-cron/graphics
# the directory where the workflow results graphs shold be placed
graphs_out_dir=/glade/derecho/scratch/jwittig/graphs/data/

# derecho hpc
derecho=derecho.hpc.ucar.edu
# mmm web server
webserver=eris.mmm.ucar.edu
# destination for graphs
web_graphs_dir=/web/htdocs/projects/mpas-jedi/weekly-cycling/cylc_graphs

# start at 11:05 PM and clean up log files
05 23 * * 7 ssh $derecho "cd ~/my_cron_logs && (gunzip mpas-bundle-cron.log.tar.gz ; tar --remove-files -uf mpas-bundle-cron.log.tar mpas-bundle-cron.log.2* ; tar --remove-files -uf mpas-bundle-cron.log.tar git_shas* ; gzip mpas-bundle-cron.log.tar)"

# at 7:30 AM on 7th day of the month clean up last months cylc log files
lastmon=$(date --date='-1 month' +%Y-%m)
30 7 7 * * ssh $derecho "cd ~/my_cron_logs/cylc/logs && tar --remove-files -czf run_cylc.cron.$lastmon.tgz *.$lastmon*.log"

bld_suffix=date +%0m_%0d_%y

# start at 12:05 AM on Mon-Fri
# make a double precision build of mpas-bundle and run ctest
# the build script won't do anything if there have been no changes to the
# modules used to create mpas-bundle (unless the '-f' parameter is provided).
05 00 * * 1-5 ssh $derecho "echo ${bld_suffix} ${bundle_dir} 'make 2p'  >> ~/my_cron_logs/cron.log && cd $bundle_dir && git fetch -p >> ~/my_cron_logs/cron.log ; git status >> ~/my_cron_logs/cron.log ; git pull >> ~/my_cron_logs/cron.log" ;$bundle_dir/$build_script -d $bundle_dir -b $builds_dir -q develop@desched1 -c gnu -p 2 -a nmmm0015

# start at 12:05 AM on Sat 
# always build, even if no source change from previous run (-f)
05 00 * * 6 $bundle_dir/$build_script -d $bundle_dir -b $builds_dir -q develop@desched1 -c gnu -p 2 -f -a nmmm0015

# start at 1:05 AM on Sat 
# always build, even if no source change from previous run (-f)
# single precision (-p 1), to be used for cylc experiment.
# use the date as part of the build directory name, so each week's build is unique.
05 01 * * 6 $bundle_dir/$build_script -d $bundle_dir -b $builds_dir -q develop@desched1 -c gnu -p 1 -f -l $bundle_dir/$build_script.lock -x $(${bld_suffix}) -a nmmm0015
# build gpu enabled MPAS-Model
#20 12 * * 1 $bundle_dir/$build_script -d $bundle_dir -b $builds_dir -q develop@desched1 -c nvhpc -p 1 -f -l $bundle_dir/$build_script.lock -x $(${bld_suffix}) -a nmmm0015

# at 12:05 am on Sun update the develop branch of  MPAS-Workflow repo and run the workflow
suffix=$(date +%F)
05 00 * * 7 ssh $derecho "echo $suffix 'run workflow in ' $workflow_dir >> ~/my_cron_logs/cron.log && cd $workflow_dir && git fetch -p >> ~/my_cron_logs/cron.log 2>&1 && git co develop >> ~/my_cron_logs/cron.log 2>&1 && git pull >> ~/my_cron_logs/cron.log 2>&1 && $workflow_dir/$workflow_script -w $workflow_dir -d $bundle_build_dir -k $bundle_dir/$build_script.lock -s $workflow_scenario -x $suffix"
# at 1:05 am on Sun run the 3dhybrid workflow
05 01 * * 7 ssh $derecho "echo $suffix 'run workflow in ' $workflow_dir >> ~/my_cron_logs/cron.log && cd $workflow_dir && $workflow_dir/$workflow_script -w $workflow_dir -d $bundle_build_dir -k $bundle_dir/$build_script.lock -s $workflow_scenario2 -x $suffix"

# run the weekly cylc scenario using a gpu build of MPAS-Model
suffix_gpu=2025-05-30_new
workflow_scenario_gpu=scenarios/3denvar_OIE120km_WarmStart_VarBC_gpu_cron.yaml
#55 15 * * * ssh $derecho "echo $suffix >> ~/my_cron_logs/cron.log 2>&1 && cd $workflow_dev_dir && git fetch -p >> ~/my_cron_logs/cron.log 2>&1 && git co develop >> ~/my_cron_logs/cron.log 2>&1 && git pull >> ~/my_cron_logs/cron.log && $workflow_dir/$workflow_script -w $workflow_dir -d $bundle_build_dir -k $bundle_dir/$build_script.lock -s $workflow_scenario_gpu -x ${suffix}_gpu"

# at 2:05 am Mon-Fri try to graph results from the completed workflow runs
casper=casper.hpc.ucar.edu
05 02 * * 1-5 ssh $casper "$workflow_dir/$workflow_script -w $workflow_dir -g $graphs_dir -o $graphs_out_dir -m $webserver -c $web_graphs_dir/"
