source /etc/profile.d/modules.sh
export OPT=/glade/work/jedipara/cheyenne/opt/modules
module purge
module use $OPT/modulefiles/core
module load jedi/gnu-openmpi
unalias ecbuild
#export LOCAL_PATH_JEDI_TESTFILES=/glade/u/home/maryamao/JEDI_test_files
git lfs install
ulimit -s unlimited
export OOPS_TRACE=0  # Note: Some ctests fail when OOPS_TRACE=1
module list
export GFORTRAN_CONVERT_UNIT='big_endian:101-200'
