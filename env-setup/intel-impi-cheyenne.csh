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

module use /glade/work/jedipara/cheyenne/spack-stack/spack-stack-v1/envs/skylab-3.0.0-intel-19.1.1.217/install/modulefiles/Core
module load stack-intel/19.1.1.217
module load stack-intel-mpi/2019.7.217
module load stack-python/3.9.12
module load jedi-base-env/1.0.0 # this should be jedi-mpas-env/1.0.0, but module does not exist
module list
