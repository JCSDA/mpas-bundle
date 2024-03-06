#!/bin/csh
#
source /etc/profile.d/z00_modules.csh
setenv LMOD_TMOD_FIND_FIRST yes

module purge
# ignore that the sticky module ncarenv/... is not unloaded
module load ncarenv/23.09
module use /glade/work/epicufsrt/contrib/spack-stack/derecho/modulefiles
module load ecflow/5.8.4
module load mysql/8.0.33

module use /glade/work/epicufsrt/contrib/spack-stack/derecho/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core
module load stack-gcc/12.2.0
module load stack-cray-mpich/8.1.25
module load stack-python/3.10.13
module load jedi-mpas-env

limit stacksize unlimited
setenv F_UFMTENDIAN 'big_endian:101-200'
setenv LD_LIBRARY_PATH `pwd`/lib:$LD_LIBRARY_PATH
