source /etc/profile.d/modules.csh
setenv OPT /glade/work/miesch/modules
module use $OPT/modulefiles/core
module purge
module load jedi/gnu-openmpi
setenv LOCAL_PATH_TESTFILES_IODA /glade/u/home/maryamao/s3_ioda_test_files/test_data/ioda
git lfs install
limit stacksize unlimited
setenv OOPS_TRACE 1
module list
