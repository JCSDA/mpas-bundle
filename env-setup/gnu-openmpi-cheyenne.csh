# contains atlas/0.31.1
#
source /etc/profile.d/modules.csh  # note: needed on non-computing nodes, MPAS-Workflow
module purge
module unuse /glade/u/apps/ch/modulefiles/default/compilers
setenv MODULEPATH_ROOT /glade/work/jedipara/cheyenne/spack-stack/modulefiles
module use /glade/work/jedipara/cheyenne/spack-stack/modulefiles/compilers
module use /glade/work/jedipara/cheyenne/spack-stack/modulefiles/misc
module load miniconda/3.9.12
module load ecflow/5.8.4

limit stacksize unlimited
setenv GFORTRAN_CONVERT_UNIT 'big_endian:101-200'
module use /glade/work/jedipara/cheyenne/spack-stack/spack-stack-v1/envs/skylab-3.0.0-gnu-10.1.0/install/modulefiles/Core

module load stack-gcc/10.1.0
module load stack-openmpi/4.1.1
module load stack-python/3.9.12
module load jedi-mpas-env/1.0.0
module list
