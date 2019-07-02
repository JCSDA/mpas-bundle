#!/bin/csh -f
#------------------------------------
# Purpose: Build mpas-bundle for JEDI
#------------------------------------
# Authors: 
#   Gael Descombes  MMM/NCAR
#   BJ Jung         MMM/NCAR
#   JJ Guerrette    MMM/NCAR
#------------------------------------
# Instructions:
# - choose REL_DIR, where
#   REL_DIR = /home/vagrant/ for vagrant virtual box
#   OR 
#   REL_DIR = <USER-OWNED-DIRECTORY>/ for HPC applications
# - mpas-bundle github clone:
#   + mkdir -p ${REL_DIR}/code
#   + cd ${REL_DIR}/code
#   + git clone https://github.com/JCSDA/mpas-bundle
# - select appropriate environment using ENV variables in
#   this automated script
# - run script as described below
#
# Generated Directory Structure:
#   ${REL_DIR}/build/
#                   └─${BNDL_BLD_NAME}
#   ${REL_DIR}/libs/
#                  ├─code/
#                  │     ├─${PIO_GITREPO}
#                  │     └─${MPAS_GITREPO}
#                  └─build/
#                         ├─PIO_${COMP}-${MPICOMP}_${ENV_PRVDR}
#                         └─MPAS_${COMP}-${MPICOMP}_debug=${DEBUG_BUILD}_${ENV_PRVDR}
#   ${REL_DIR}/data/
#
#  Note:
#  All ENV variables are set internally in this build
#  script. BNDL_BLD_NAME can be used to contain
#  multiple builds of a single bundle within a common
#  directory structure. The libs directory naming 
#  convention enables similar behavior when switching
#  between COMP-MPICOMP pairs.
#
#-------------------------------------------------------------------------------
# Select components to build
#---------------------------
# (J) - Required, but already done in JCSDA jedi containers and modules
# (R) - Required: always needs to be done at least once
# (O) - Optional
# (U) - Unsupported
# (lib) - library
# (app) - application
# + each component depends on those preceding it
# + users may execute build_mpas.csh with one or multiple selected at a time
#-------------------------------------------------------------------------------
set build_pio2=0    # (J, lib): Get and build PIO_GITBRANCH of PIO2 library
set build_mpas=1    # (R, lib): Get and build MPAS_GITBRANCH of MPAS-model
set libr_mpas=1     # (R, lib): Make a shared MPAS library to be used in mpas-bundle build
#set build_odb=0     # (U, lib): Build ODB1+ODB2
#set enable_odb=0    # (U, lib): Enable ODB when building mpas-bundle
set build_bundle=1  # (R, lib): Clone and build all components of mpas-bundle (see CMakeLists.txt)
set get_data=1      # (R, app): Download and place test dataset, link UFO data
set test_mpas=0     # (O, app): Launch a ctest
set plot=0          # (O, app): Plot the results 

#-------------------------------------------------------------------------------
# Select top-level build settings
#--------------------------------
#Select COMP for HPC platforms [ gnu (D); intel ]
set COMP="gnu"

#Select MPICOMP for HPC platforms [ openmpi (D); mpt ]
set MPICOMP="openmpi"

#Set to 1 to turn on debug flags for MPAS-Model and mpas-bundle
set DEBUG_BUILD=0

#Select ENV_PRVDR for HPC platforms [ JCSDA (D); MMM ]
set ENV_PRVDR="JCSDA"

#Set BNDLNAME (mpas, unless used to build another jedi bundle)
set BNDLNAME="mpas"

#Set REPONAME (Name of Github repo for MPAS/JEDI)
set REPONAME="mpas-jedi"

# Additional Notes:
#   (1) Not all combinations of COMP/MPICOMP are supported
#
#   (2) users must build all desired lib components when changing COMP, MPICOMP, or ENV_PRVDR
#
#   (3) when rebuilding, only components with code changes or with dependencies need to be selected
#
#   (4) remove build/${BNDL_BLD_NAME}/CMakeCache.txt before building when any CMakeLists.txt 
#       of any repository has changed (e.g., ufo/test/CMakeLists.txt)

#---------------------
# Set up environment
#---------------------
set platform=`uname -n`
echo "Setting up environment for platform: $platform"

if ( "$platform" =~ vagrant* ) then
   ## VAGRANT

   #Override COMP/MPICOMP for vagrant
   set COMP="gnu"
   set MPICOMP="openmpi"

   set ENV_PRVDR="JCSDA"
   set MODELFC="gfortran"
   set DOCKER_PATH="none"
   set jedi_module="none"

   set REL_DIR="/home/vagrant"
else
   ## HPC

   #Set additional compiler-specific ENV variables
   switch ( "${COMP}" )
   case gnu:
      set MODELFC="gfortran"
      breaksw
   case intel:
      set MODELFC="ifort"
      breaksw
   default:
      echo "ERROR: COMP=${COMP} is not currently supported"
      exit 10
   endsw

   switch ( "$platform" )
   case cheyenne*:
      #CHEYENNE - `uname -n` only works on login node

      switch ( "${ENV_PRVDR}" )
      case MMM:
         #MMM - maintained by BJ Jung
         if ( "$COMP" == gnu && "$MPICOMP" == openmpi ) then
            echo ""; echo "Using MMM docker"; echo ""
            set DOCKER_PATH="/glade/work/bjung/panda-c/module/default"
            set jedi_module="gnu"
            breaksw
         endif
         set ENV_PRVDR="JCSDA"
      default:
         #JCSDA - maintained by Mark Miesch
         echo ""; echo "Using JCSDA docker"; echo ""
         set DOCKER_PATH="/glade/work/miesch/modules/modulefiles/core"
         if ( "$COMP" == gnu && "$MPICOMP" == openmpi ) then
            set jedi_module="gnu-openmpi"
         else if ( "$COMP" == gnu && "$MPICOMP" == mpt ) then
            set jedi_module="gnu-mpt"
         else if ( "$COMP" == intel && "$MPICOMP" == mpt ) then
            set jedi_module="intel-mpt"
         else
            echo "ERROR: COMP=${COMP}-MPICOMP=${MPICOMP} is not currently supported"
            exit 11
         endif
         breaksw
      endsw

      source /etc/profile.d/modules.csh
      module purge
      module use $DOCKER_PATH
      module load jedi/$jedi_module
      module list

      breaksw
   default:
      echo "ERROR: platform=${platform} is not currently supported"
      exit 12
   endsw

#   #TODO: extend to other platforms, possibly using similar module interface
#   if ( `which module` =~ ??? ) then
#      module purge
#      module use $DOCKER_PATH
#      module load jedi/$jedi_module
#   else
#      echo "ERROR: module statements not supported by this platform"
#      exit 13
#   #endif

   #Enables lfs for large file retrieval
   git lfs install

   #TODO: add write-protected test for ../../
   cd ../../
   set REL_DIR=`pwd`
   cd -
endif

#Set compiler environment variables
#Beginning May 2019, the JCSDA containers & modules should have compiler environment variables defined.
if ( (! $?MPI_CC) || (! $?MPI_CXX) || (! $?MPI_FC) ) then
   switch ( "${MPICOMP}" )
   case openmpi:
      setenv CC     mpicc
      setenv CXX    mpicxx
      setenv FC     mpifort
      breaksw
   case mpt:
      setenv CC     mpicc
      setenv CXX    mpicxx
      setenv FC     mpif90
      breaksw
   case mpich:
      setenv CC     mpicc
      setenv CXX    mpicxx
      setenv FC     mpifort
      breaksw
   default:
      echo "ERROR: MPICOMP=${MPICOMP} is not currently supported"
      exit 10
   endsw
else
   echo "Setting compiler environment variables using module/container environment variables"
   setenv CC     $MPI_CC
   setenv CXX    $MPI_CXX
   setenv FC     $MPI_FC
endif
echo "CC            = ${CC}"
echo "CXX           = ${CXX}"
echo "FC            = ${FC}"

#Set build directory name with BNDL_BLD_NAME 
set BNDL_BLD_NAME="${BNDLNAME}-bundle"
#Add a suffix for managinge multiple builds
# (e.g., unique sets of compiler, ENV_PRVDR, or git branch)
#set BNDL_BLD_NAME="${BNDL_BLD_NAME}_${COMP}-${MPICOMP}_debug=${DEBUG_BUILD}_${ENV_PRVDR}"

echo "ENV_PRVDR     = ${ENV_PRVDR}"
echo "MODELFC       = ${MODELFC}"
echo "DOCKER_PATH   = ${DOCKER_PATH}"
echo "jedi_module   = ${jedi_module}"
echo "BNDL_BLD_NAME = ${BNDL_BLD_NAME}"

#---------------------
# Set up directories
#---------------------
#===ECBUILD BUNDLE===
set SRC_DIR=${REL_DIR}/code
set BLD_DIR=${REL_DIR}/build
set BNDL_SRC=${SRC_DIR}/${BNDLNAME}-bundle
set BNDL_BLD=${BLD_DIR}/${BNDL_BLD_NAME}

#===External Libraries===
set EXT_SRC_DIR=${REL_DIR}/libs/code
set EXT_BLD_DIR=${REL_DIR}/libs/build

#PIO
set PIO_GITREPO="ParallelIO"
set SRCPIO=${EXT_SRC_DIR}/${PIO_GITREPO}
set BLDPIO=${EXT_BLD_DIR}/PIO_${COMP}-${MPICOMP}_${ENV_PRVDR}
if (! $?PIO  ) then
   set LIBPIO=${BLDPIO}/writable/pio2
else
   set LIBPIO=$PIO
endif
echo "LIBPIO        = $LIBPIO"

#MPAS-Model
set MPAS_GITREPO="MPAS-Model"
#TODO: get changes merged into MPAS-Dev/${MPAS_GITREPO}::develop
#Use this when MPAS-Dev develop is updated for ${BNDLNAME}-bundle
#set MPAS_GITTREE="MPAS-Dev"
#set MPAS_GITBRANCH=develop
#Use this fork/branch until MPAS-Dev is compatible with JEDI (temporary)
set MPAS_GITTREE="jjguerrette"
set MPAS_GITBRANCH=develop-for-jedi

set SRCMPAS=${EXT_SRC_DIR}/${MPAS_GITREPO}
set BLDMPAS=${EXT_BLD_DIR}/MPAS_${COMP}-${MPICOMP}_debug=${DEBUG_BUILD}_${ENV_PRVDR}
set LIBMPAS=${BLDMPAS}/link_libs

#ODB
#set ODB_DIR=${REL_DIR}/odb/install

#NETCDF
#setenv NETCDF /somewhere/already set
#setenv PNETCDF /somewhere/already set 

#===========================================================

mkdir -p ${REL_DIR}
mkdir -p ${SRC_DIR}
mkdir -p ${BLD_DIR}
mkdir -p ${EXT_SRC_DIR}

if ( ${build_pio2} ) then
   echo ""
   echo "======================================================"
   echo " Git clone PIO2"
   echo "======================================================"
   cd ${EXT_SRC_DIR}
   rm -rf $SRCPIO
   git clone https://github.com/NCAR/${PIO_GITREPO}.git

### MARKED FOR REMOVAL, 19 APR 2019: NOT NEEDED FOR gnu-openmpi_JCSDA
#   # 21 DEC 2018: PIO2 master branch causes a substantial increase
#   # in wall-time for ${BNDLNAME}-bundle.  Temporarily use old hash
#   # until this bug is fixed.
#   #cd $SRCPIO
#   #git checkout -b OLD_SHA 96e562f7c8bd55b9ad50144c332516bf571a94c6

   echo ""
   echo "======================================================"
   echo " Compiling PIO2"
   echo "======================================================"
   setenv FFLAGS "-fPIC"
   setenv CFLAGS "-fPIC"
   setenv FCFLAGS "-fPIC"
   setenv LDFLAGS "-fPIC"

   rm -rf $BLDPIO
   mkdir -p $LIBPIO
   cd $BLDPIO
   setenv CC mpicc
   cmake -DNetCDF_C_PATH=$NETCDF -DNetCDF_Fortran_PATH=$NETCDF -DPnetCDF_PATH=$PNETCDF -DCMAKE_INSTALL_PREFIX=${LIBPIO} -DPIO_ENABLE_TIMING=OFF $SRCPIO -DPIO_ENABLE_TIMING=OFF
   make |& tee make.log

   echo ""
   echo "NOTE: the preceding output from make is archived in ${BLDPIO}/make.log"
   echo ""

   make install |& tee make_install.log

   echo ""
   echo "NOTE: the preceding output from make is archived in ${BLDPIO}/make_install.log"
   echo ""
endif

if ( $build_mpas ) then
   echo ""
   echo "======================================================"
   echo " Retrieving ${MPAS_GITREPO} source code using git"
   echo "======================================================"
   cd ${EXT_SRC_DIR}

   #TODO: solve the following:
   # + can only rm ${SRCMPAS} if no local working branches exist
   # + can only clone successfully when local clone/branch does not exist
   # Q: possible to move MPAS-Model clone/pull/build to EC build system?
   #rm -rf ${SRCMPAS}
   git clone -b ${MPAS_GITBRANCH} https://github.com/${MPAS_GITTREE}/${MPAS_GITREPO}

   #Copy index to ${BLDMPAS}
   cd ${SRCMPAS}
   rm -rf ${BLDMPAS}
   mkdir -p ${BLDMPAS}
   git checkout-index -f -a --prefix=${BLDMPAS}/

   echo ""
   echo "======================================================"
   echo " Compiling MPAS"
   echo "======================================================"
   cd ${BLDMPAS}
   setenv PIO ${LIBPIO}
   echo "PIO $PIO"
   pwd
   echo "make clean CORE=atmosphere"
   make clean CORE=atmosphere
   setenv MPASDEBUG ""
   if ( $DEBUG_BUILD ) then
      setenv MPASDEBUG "DEBUG=true"
   endif
   echo "make ${MODELFC} CORE=atmosphere USE_PIO2=true SHARELIB=true ${MPASDEBUG} |& tee make.log"
   make ${MODELFC} CORE=atmosphere USE_PIO2=true SHARELIB=true ${MPASDEBUG} |& tee make.log

   echo ""
   echo "NOTE: the preceding output from make is archived in ${BLDMPAS}/make.log"
   echo ""
endif

if ( $libr_mpas ) then
   echo ""
   echo "======================================================"
   echo " Building MPAS Library libmpas.a for ${BNDLNAME}-bundle"
   echo "======================================================"
   mkdir -p ${LIBMPAS}
   cd ${LIBMPAS}
   rm -rf include
   mkdir include
   rm -f libmpas.a

   set list_dirlib = "${BLDMPAS}/src/driver ${BLDMPAS}/src/external/esmf_time_f90/ ${BLDMPAS}/src/framework ${BLDMPAS}/src/core_atmosphere ${BLDMPAS}/src/core_atmosphere/physics ${BLDMPAS}/src/operators"

   foreach dirlib ( $list_dirlib )
      echo "-------------------------------------------------------------------"
      echo " dirlib $dirlib"
      echo "-------------------------------------------------------------------"
      set lib="$dirlib/*.a"
      set mod="$dirlib/*.mod"
      set hhh="$dirlib/*.h"
      cp -v $lib .
      cp -v $mod .
      cp -v $hhh .
      ar -x $lib
   end

   # link river
   set dirlib="${BLDMPAS}/src/driver"
   cp -v ${BLDMPAS}/src/driver/*o .

   # build libmpas.a
   mv *.a *.o *.mod *.h ./include
   ar -ru libmpas.a ./include/*.o
endif

## Warning: building ODB can be slow in singularity, just do it once
##--------------------------
#if ( $build_odb ) then
#   cd ${REL_DIR}
#   ./code/${BNDLNAME}-bundle/setup_odb_build.sh
#   ./code/${BNDLNAME}-bundle/run_odb_build.sh
#endif

if ( $build_bundle ) then
   echo ""
   echo "=============================================================="
   echo " Compiling ${BNDLNAME}-bundle using ecbuild/cmake"
   echo "=============================================================="
   if ( "${BNDLNAME}" == mpas ) then
      setenv MPAS_LIBRARIES "${LIBPIO}/lib/libpiof.a;${LIBPIO}/lib/libpioc.a;${LIBMPAS}/libmpas.a"

      switch ( "$platform" )
      case vagrant*:
         setenv MPAS_LIBRARIES "${MPAS_LIBRARIES};/usr/local/lib/libnetcdf.so;/usr/local/lib/libmpi.so;/usr/local/lib/libpnetcdf.a;/usr/local/lib/libmpi_mpifh.so"
         breaksw
      default:
         setenv MPAS_LIBRARIES "${MPAS_LIBRARIES};${NETCDF}/lib/libnetcdf.so;${MPI_ROOT}/lib/libmpi.so;${PNETCDF}/lib/libpnetcdf.a;${MPI_ROOT}/lib/libmpi.so"
         breaksw
      endsw

      setenv MPAS_INCLUDES "${LIBMPAS}/include;${LIBPIO}/include"
      echo "MPAS_LIBRARIES: ${MPAS_LIBRARIES}"
      echo "MPAS_INCLUDES:  ${MPAS_INCLUDES}"
   endif

   echo "BUNDLE BUILD:   ${BNDL_BLD}"
   echo "BUNDLE CODE:    ${BNDL_SRC}"

   if ( "${COMP}" == intel ) then
      # Extra flags needed for intel-mpt determined by MMiesch
      #TODO: investigate further and check if these are needed 
      #      in MPAS-Model and ParallelIO compilation as well
      setenv LDFLAGS "-L$INTEL_BASE_PATH/lib/intel64 -L/usr/lib -lifport -lifcoremt -lipgo -lintlc"
      echo "LDFLAGS = ${LDFLAGS}"
   endif

   if ( $DEBUG_BUILD ) then
     set BLDTYPE=debug
   else
     set BLDTYPE=release
   endif

#   set ODBFLAGS=""
#   if ( $enable_odb ) then
#      set ODBFLAGS="-DODB_PATH=${ODB_DIR} -DENABLE_ODB=1 -DODB_API_PATH=${ODB_DIR} -DENABLE_ODB_API=1"
#   endif
#   ecbuild ${ODBFLAGS} --build=${BLDTYPE} ${BNDL_SRC}

   mkdir -p ${BNDL_BLD}
   cd ${BNDL_BLD}
   ecbuild --build=${BLDTYPE} ${BNDL_SRC} |& tee ecbuild.log0

   echo ""
   echo "NOTE: the preceding output from ecbuild is archived in ${BNDL_BLD}/ecbuild.log0"
   echo ""

   echo ""
   echo "Building ${BNDLNAME}-bundle using make files from ecbuild..."
   echo ""

   #make VERBOSE=1 -j4 |& tee make.log
   make -j4 |& tee make.log

   echo ""
   echo "NOTE: the preceding output from make is archived in ${BNDL_BLD}/make.log"
   echo ""

   #Substitute the correct REL_DIR into relevant testinput yaml files
   sed -i -e "s#REL_DIR#${REL_DIR}#" ${BNDL_BLD}/${REPONAME}/test/testinput/*.yaml
endif

if ( $get_data ) then
   echo ""
   echo "======================================================"
   echo " Download and place test dataset, link UFO data "
   echo "======================================================"
   cd ${REL_DIR}
   wget -c http://www2.mmm.ucar.edu/people/bjung/files/data_20190226_small.tgz
   tar zxvf data_20190226_small.tgz
   cd ./data
   cp *.DBL *.TBL namelist.atmosphere* stream_list.* streams.atmosphere x1.2562.graph.* restart.*.nc ${BNDL_BLD}/${REPONAME}/test
endif

if ( $test_mpas ) then
   echo ""
   echo "======================================================"
   echo " Testing OOPS-MPAS"
   echo "======================================================"

   #TODO: (1) put all of these commands in an executable script
   #      (2) automatically generate a wrapper script for HPC
   #          applications including module loads, etc.

   cd $BNDL_BLD
   limit stacksize unlimited
   setenv OOPS_TRACE 1

   #Compiler-specific environment variables for unformatted binary file units
   #Units 101-200 are used for reading big-endian RRTMG LW/SW data files in 
   #MPAS.  All other units use the native byte order. More variables may need 
   #to be added as other compilers are used (e.g., XL, Cray, PGI, FTN).
   # GNU:
   setenv GFORTRAN_CONVERT_UNIT 'native;big_endian:101-200'
   # INTEL:
   setenv F_UFMTENDIAN 'big:101-200'

   #ctest -VV -R test_mpas_geometry
   #ctest -VV -R test_mpas_state
   #ctest -VV -R test_mpas_increment
   #ctest -VV -R test_mpas_model
   #ctest -VV -R test_mpas_forecast
   #ctest -VV -R test_mpas_hofx
   #ctest -VV -R test_mpas_dirac_nicas
   ctest -VV -R test_mpas_3dvar
   ctest -VV -R test_mpas_3denvar
endif

if ( $plot ) then
   echo ""
   echo "======================================================"
   echo " Plotting"
   echo "======================================================"

   cd $BNDL_BLD/mpas/test/graphics
   if ( "$platform" =~ cheyenne* ) then
      module purge
      module load python/2.7.13
      module load numpy/1.12.0
      module load matplotlib/2.0.0
      module load netcdf4-python
   endif
   python plot_cost_grad.py
#  python plot_obs_nc_loc.py
#  python plot_diag_omaomb.py
#  python plot_BUMP_diag.py
endif

