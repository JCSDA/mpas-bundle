#!/bin/csh
#

source /etc/profile.d/z00_modules.csh

module --force purge
module load ncarenv/24.12

module use /glade/work/epicufsrt/contrib/spack-stack/derecho/spack-stack-1.9.3/envs/ue-gcc-12.4.0/install/modulefiles/Core
module load stack-gcc/12.4.0
module load ecbuild/3.7.2
module load cmake/3.27.9

module load craype/2.7.31
module load nvhpc/24.11 
module load ncarcompilers/1.0.0
module load cray-mpich/8.1.29
module load cuda/12.3.2
module load parallel-netcdf/1.14.0
module list

