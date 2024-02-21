#!/bin/bash
#
source /etc/profile.d/z00_modules.sh

export LMOD_TMOD_FIND_FIRST=yes

module purge
module use /lustre/desc1/scratch/epicufsrt/contrib/modulefiles
module use /lustre/desc1/scratch/epicufsrt/contrib/modulefiles_extra
module load ecflow/5.8.4
module load mysql/8.0.33

module use /glade/work/epicufsrt/contrib/spack-stack/derecho/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core

module load stack-intel/2021.10.0
module load stack-cray-mpich/8.1.25
module load stack-python/3.10.13
module load jedi-mpas-env
module list

ulimit -s unlimited
export F_UFMTENDIAN='big_endian:101-200'
export LD_LIBRARY_PATH=`pwd`/lib:$LD_LIBRARY_PATH
