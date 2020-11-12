source /etc/profile.d/modules.sh
export OPT=/glade/work/miesch/modules
module use $OPT/modulefiles/core
module purge
module load jedi/intel-impi
export LOCAL_PATH_JEDI_TESTFILES=/glade/u/home/maryamao/JEDI_test_files
git lfs install
ulimit -s unlimited
export OOPS_TRACE=1
module list
