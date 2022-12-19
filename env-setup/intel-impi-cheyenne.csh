source /etc/profile.d/modules.csh
setenv OPT /glade/work/jedipara/cheyenne/opt/modules
module purge
module use $OPT/modulefiles/core
module load jedi/intel-impi/19.1.1
module load json
module load json-schema-validator
module load atlas/ecmwf-0.29.0
unalias ecbuild
set ecb = `which ecbuild`
#alias ecbuild "$ecb  --toolchain=/glade/work/miesch/jedi/jedi-cmake/cmake/Toolchains/jcsda-Cheyenne-Intel.cmake"
alias ecbuild "$ecb -DCMAKE_CXX_FLAGS='-gxx-name=/glade/u/apps/ch/opt/gnu/9.1.0/bin/g++' -DCMAKE_EXE_LINKER_FLAGS='-gxx-name=/glade/u/apps/ch/opt/gnu/9.1.0/bin/g++ -Wl,-rpath,/glade/u/apps/ch/opt/gnu/9.1.0/lib64' -DCMAKE_SHARED_LINKER_FLAGS='-gxx-name=/glade/u/apps/ch/opt/gnu/9.1.0/bin/g++ -Wl,-rpath,/glade/u/apps/ch/opt/gnu/9.1.0/lib64' -DENABLE_AEC=OFF -DFYPP_NO_LINE_NUMBERING=ON"
#setenv LOCAL_PATH_JEDI_TESTFILES /glade/u/home/maryamao/JEDI_test_files
git lfs install
limit stacksize unlimited
setenv OOPS_TRACE 0  # Note: Some ctests fail when OOPS_TRACE=1
module list
#setenv F_UFMTENDIAN 'big:101-200'
