source /etc/profile.d/modules.sh
export OPT=/glade/work/miesch/modules
module use $OPT/modulefiles/core
module purge
module load jedi/intel-impi
unalias ecbuild
ecb=`which ecbuild`
alias ecbuild="$ecb  --toolchain=/glade/work/miesch/jedi/jedi-cmake/cmake/Toolchains/jcsda-Cheyenne-Intel.cmake"
#export LOCAL_PATH_JEDI_TESTFILES=/glade/u/home/maryamao/JEDI_test_files
git lfs install
ulimit -s unlimited
export OOPS_TRACE=0  # Note: Some ctests fail when OOPS_TRACE=1
module list
#export F_UFMTENDIAN='big:101-200'
