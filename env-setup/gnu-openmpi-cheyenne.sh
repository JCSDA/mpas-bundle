source /etc/profile.d/modules.sh
export OPT=/glade/work/miesch/modules
module use $OPT/modulefiles/core
module purge
module load jedi/gnu-openmpi
export LOCAL_PATH_TESTFILES_IODA=/glade/u/home/maryamao/s3_ioda_test_files/test_data/ioda
git lfs install
ulimit -s unlimited
export OOPS_TRACE=1
module list
