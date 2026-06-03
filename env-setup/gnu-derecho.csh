#!/bin/csh
#
source /etc/profile.d/z00_modules.csh
setenv LMOD_TMOD_FIND_FIRST yes

# Check if conda is installed. If it is, deactivate it.
if ( `which conda >& /dev/null` ) then
    conda deactivate
endif

module purge
# ignore that the sticky module ncarenv/... is not unloaded
module load ncarenv/24.12
module use /glade/work/epicufsrt/contrib/spack-stack/derecho/modulefiles
module load ecflow/5.8.4
module load mysql/8.0.33

module use /glade/work/epicufsrt/contrib/spack-stack/derecho/spack-stack-1.9.3/envs/ue-gcc-12.4.0/install/modulefiles/Core

module load stack-gcc/12.4.0
module load stack-cray-mpich/8.1.29
module load stack-python/3.11.7
module load py-pycodestyle/2.11.0
# module load jedi-mpas-env is commented out because it loads many modules not needed for
# building and running mpas-bundle on derecho.
# To load all of the modules which were loaded prior to 01/15/2026,
# uncomment out "module load jedi-mpas-env"
# module load jedi-mpas-env
module load atlas/0.40.0
module load ecbuild/3.7.2
module load netcdf-cxx4/4.3.1
module load parallelio/2.6.2
module load gsl-lite/0.37.0
module load nccmp/1.9.0.1
module load udunits/2.2.28
# Following modules are required for ioda-converters build
module load bufr/12.1.0
module load py-pybind11/2.13.5
module list

limit stacksize unlimited
setenv F_UFMTENDIAN 'big_endian:101-200'
setenv LD_LIBRARY_PATH `pwd`/lib:$LD_LIBRARY_PATH
