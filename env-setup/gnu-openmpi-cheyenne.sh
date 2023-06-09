#
echo "Loading Spack-Stack 1.3.1"
#
source /etc/profile.d/modules.sh  # note: needed on non-computing nodes
module purge
export LMOD_TMOD_FIND_FIRST=yes
module use /glade/work/jedipara/cheyenne/spack-stack/modulefiles/misc
module load miniconda/3.9.12
module load ecflow/5.8.4
module load mysql/8.0.31

module use /glade/work/epicufsrt/contrib/spack-stack/spack-stack-1.3.1/envs/unified-env/install/modulefiles/Core
module load stack-gcc/10.1.0
module load stack-openmpi/4.1.1
module load stack-python/3.9.12
module load jedi-mpas-env/unified-dev
module list

ulimit -s unlimited
export GFORTRAN_CONVERT_UNIT='big_endian:101-200'

