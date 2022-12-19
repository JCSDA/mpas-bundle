source /etc/profile.d/modules.csh
setenv OPT /glade/work/jedipara/cheyenne/opt/modules
module purge
module use $OPT/modulefiles/core
module load jedi/gnu-openmpi/10.1.0
module load json
module load json-schema-validator
module load atlas/ecmwf-0.29.0 # temp. patch until JEDI stack recovers
unalias ecbuild
#setenv LOCAL_PATH_JEDI_TESTFILES /glade/u/home/maryamao/JEDI_test_files
git lfs install
limit stacksize unlimited
setenv OOPS_TRACE 0  # Note: Some ctests fail when OOPS_TRACE=1
module list
setenv GFORTRAN_CONVERT_UNIT 'big_endian:101-200'
