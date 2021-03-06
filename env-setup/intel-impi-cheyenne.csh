source /etc/profile.d/modules.csh
setenv OPT /glade/work/jedipara/cheyenne/opt/modules
module purge
module use $OPT/modulefiles/core
module load jedi/intel-impi
unalias ecbuild
set ecb = `which ecbuild`
alias ecbuild "$ecb  --toolchain=/glade/work/miesch/jedi/jedi-cmake/cmake/Toolchains/jcsda-Cheyenne-Intel.cmake"
#setenv LOCAL_PATH_JEDI_TESTFILES /glade/u/home/maryamao/JEDI_test_files
git lfs install
limit stacksize unlimited
setenv OOPS_TRACE 0  # Note: Some ctests fail when OOPS_TRACE=1
module list
#setenv F_UFMTENDIAN 'big:101-200'
