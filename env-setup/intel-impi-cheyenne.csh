source /etc/profile.d/modules.csh
setenv OPT /glade/work/miesch/modules
module use $OPT/modulefiles/core
module purge
module load jedi/intel-impi
setenv LOCAL_PATH_JEDI_TESTFILES /glade/u/home/maryamao/JEDI_test_files
git lfs install
limit stacksize unlimited
setenv OOPS_TRACE 0  # Note: Some ctests fail when OOPS_TRACE=1
module list
