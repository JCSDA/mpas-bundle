
# run scripts to build mpas-bundle and run ctest
# to use this, 
# 1. log on to cron.hpc.ucar.edu
# 2. run: crontab bundle-crontab

# set this to the directory the mpas-bundle repository has been cloned to
bundle_dir=/glade/work/jwittig/repos1/mpas-bundle-cron/mpas-bundle/
# the directory where the single precision bundle build is
bundle_build_dir=/glade/work/jwittig/repos1/mpas-bundle-cron/build-gnu-1p/
# this is the build script to execute, relative to the mpas-bundle source directory
build_script=env-setup/mpas-bundle-cron.sh

# the workflow directory with the script to run a workflow and make graphs
workflow_dir=/glade/derecho/scratch/jwittig/repos-s/MPAS-Workflow-cron
# the script to run a cylc job and to create graphs, relative to the workflow directory
workflow_script=env-setup/run_cylc.sh
# the workflow scenario to run, relative to the workflow directory
workflow_scenario=scenarios/3denvar_OIE120km_WarmStart_VarBC_cron.yaml

# the directory with the graphics scripts
graphs_dir=/glade/derecho/scratch/jwittig/repos-s/mpas-jedi-cron/graphics
# the directory where the workflow results graphs shold be placed
graphs_out_dir=/glade/derecho/scratch/jwittig/graphs/data/

# derecho hpc
derecho=derecho.hpc.ucar.edu
# mmm web server
webserver=whitedwarf.mmm.ucar.edu
# destination for graphs
web_graphs_dir=/web/htdocs/projects/mpas-jedi/weekly-cycling/cylc_graphs

# start at 11:05 PM and clean up log files
05 23 * * * ssh $derecho "cd ~/my_cron_logs && (gunzip mpas-bundle-cron.log.tar.gz ; tar --remove-files -uf mpas-bundle-cron.log.tar mpas-bundle-cron.log.2* ; tar --remove-files -uf mpas-bundle-cron.log.tar git_shas* ; gzip mpas-bundle-cron.log.tar)"

# start at 12:05 AM Sun through Fri 
# change 'gnu' to 'intel' to use the intel build toolchain, or 'both' to build both
# double precision (-p 2), to be used for ctests.
# don't do anything if no source code changed from previous run (don't provide -f)
#05 00 * * 0-5 $bundle_dir/$build_script -d $bundle_dir -q main@desched1 -c gnu  -p 2
#05 00 * * 0-5 $bundle_dir/$build_script -d $bundle_dir -q develop@desched1 -c gnu  -p 2 -l $bundle_dir/$build_script.lock

# start at 12:05 AM on Sat 
# always build, even if no source change from previous run (-f)
05 00 * * 6 $bundle_dir/$build_script -d $bundle_dir -q develop@desched1 -c gnu -p 2 -f

# start at 1:05 AM on Sat 
# always build, even if no source change from previous run (-f)
# single precision (-p 1), to be used for cylc experiment.
05 01 * * 6 $bundle_dir/$build_script -d $bundle_dir -q develop@desched1 -c gnu -p 1 -f -l $bundle_dir/$build_script.lock

# at 12:05 am on Sun run the workflow
suffix=$(date +%F)
05 00 * * 7 ssh $derecho $workflow_dir/$workflow_script -w $workflow_dir -d $bundle_build_dir -k $bundle_dir/$build_script.lock -s $workflow_scenario -x $suffix

# at 12:05 am Mon-Fri try to graph results from the completed workflow runs
05 00 * * 1-5 ssh $derecho $workflow_dir/$workflow_script -w $workflow_dir -g $graphs_dir -o $graphs_out_dir

# at 6:05 am weekdays tar any graphics files and copy them to an mmm web server
05 06 * * 1-5 echo "`date` checking $graphs_out_dir" >> ~/my_cron_logs/cp_graphs.log && for dir in $(/bin/ls $graphs_out_dir); do echo "`date` dir to copy:$dir" >> ~/my_cron_logs/cp_graphs.log; echo "ssh $derecho cd $graphs_out_dir && tar --remove-files -czf $dir.tgz $dir" >> ~/my_cron_logs/cp_graphs.log; ssh $derecho "cd $graphs_out_dir && tar --remove-files -czf $dir.tgz $dir"; echo "scp $graphs_out_dir/$dir.tgz $webserver:$web_graphs_dir/" >> ~/my_cron_logs/cp_graphs.log; scp $graphs_out_dir/$dir.tgz $webserver:$web_graphs_dir/; echo "ssh $webserver cd $web_graphs_dir/ && tar -xzf $dir.tgz" >> ~/my_cron_logs/cp_graphs.log; ssh $webserver "cd $web_graphs_dir/ && tar -xzf $dir.tgz"; mv $graphs_out_dir/$dir.tgz $graphs_out_dir/../copied; echo "finished $dir" >> ~/my_cron_logs/cp_graphs.log; done

