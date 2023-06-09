#
echo "Loading Spack-Stack 1.3.1"
#
source /etc/profile.d/modules.csh  # note: needed on non-computing nodes, MPAS-Workflow
module purge
setenv LMOD_TMOD_FIND_FIRST yes
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

limit stacksize unlimited
setenv GFORTRAN_CONVERT_UNIT 'big_endian:101-200'
