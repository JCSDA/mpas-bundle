#!/bin/csh
#---------------------------------------------------------
# Author: Gael DESCOMBES, MMM/NCAR, 01/2018
# Build mpas-bundle for OOPS-MPAS
#
# Prerequies:
# - mpas-bundle github done: 'git clone https://github.com/JCSDA/mpas-bundle'
# - place modified MPAS code in SRCMPAS / --> need to use mpas github
#
# Directory structure assumed...
#   REL_DIR = /home/vagrant/ OR /some/where/to/store/soure/code
#   ${REL_DIR}/code/
#                  └─mpas-bundle
#   ${REL_DIR}/build/
#                   └─mpas-bundle
#   ${REL_DIR}/libs/
#                  ├─build
#                  ├─ParallelIO
#                  └─MPAS-Release
#   ${REL_DIR}/data/
#
#---------------------------------------------------------
setenv MODEL    mpas

#CHEYENNE
if ( `uname -n` =~ cheyenne* ) then
#   setenv COMP intel
   setenv COMP gnu

   module purge
   module use /glade/u/home/xinzhang/modules/default
   module load jedi/$COMP

   #Enables lfs for large file retrieval
   git lfs install

   #This package requires the "code/mpas-bundle" and "build/mpas-bundle" directories to be two levels deep
   setenv CODE_DIR `pwd`
   cd ../../
   setenv REL_DIR `pwd`
   cd $CODE_DIR
endif

if ( `uname -n` =~ vagrant* ) then
   #VAGRANT
   setenv REL_DIR  "/home/vagrant"
else
   #OTHERWISE
   setenv CXX  mpic++
   setenv FC   mpif90
endif

set comp_pio2=0     # Get and build a PIO2 library
set comp_mpas=0     # Get and build MPAS model
set libr_mpas=0     # Make a MPAS library to be used in MPAS/OOPS
set build_odb=0     # Whether build ODB1+ODB2
set enable_odb=0    # Whether enable ODB when builing mpas-bundle
set oops_mpas=1     # clone and build a mpas-bundle
set get_data=0      # Download and place test dataset, link UFO data
set test_mpas=1     # launch a ctest

#---------------------------------------------------------
setenv SRC_DIR  ${REL_DIR}/code
setenv BLD_DIR  ${REL_DIR}/build
setenv EXT_DIR  ${REL_DIR}/libs
setenv ODB_DIR  ${REL_DIR}/odb/install

setenv BUNDLE_MODEL ${SRC_DIR}/mpas-bundle
setenv BUILD_MODEL  ${BLD_DIR}/mpas-bundle

setenv SRCPIO   ${EXT_DIR}/ParallelIO 
setenv BUILDPIO ${EXT_DIR}/build
setenv LIBPIO   ${BUILDPIO}/writable/pio2
setenv SRCMPAS  ${EXT_DIR}/MPAS-Release
setenv LIBMPAS  ${SRCMPAS}/link_libs
#setenv NETCDF /somewhere/already set
#setenv PNETCDF /somewhere/already set 

#===========================================================

mkdir -p ${REL_DIR}
mkdir -p ${SRC_DIR}
mkdir -p ${BLD_DIR}
mkdir -p ${EXT_DIR}

if ( $comp_pio2 ) then
   echo ""
   echo "======================================================"
   echo " Git clone PIO2"
   echo "======================================================"
   cd $EXT_DIR
   git clone https://github.com/NCAR/ParallelIO.git

   echo ""
   echo "======================================================"
   echo " Compiling PIO2"
   echo "======================================================"
   setenv FFLAGS "-fPIC"
   setenv CFLAGS "-fPIC"
   setenv FCFLAGS "-fPIC"
   setenv LDFLAGS "-fPIC"

   rm -rf $BUILDPIO
   mkdir -p $LIBPIO
   cd $BUILDPIO
   setenv CC mpicc
   cmake -DNetCDF_C_PATH=$NETCDF -DNetCDF_Fortran_PATH=$NETCDF -DPnetCDF_PATH=$PNETCDF -DCMAKE_INSTALL_PREFIX=${LIBPIO} -DPIO_ENABLE_TIMING=OFF $SRCPIO -DPIO_ENABLE_TIMING=OFF
   make
   make install

endif

if ( $comp_mpas ) then
   echo ""
   echo "======================================================"
   echo " GET modified MPAS_Realise source code  <-- should use git, soon "
   echo "======================================================"
   cd ${EXT_DIR}
   #git clone https://github.com/SOME_REPOSITORY
   wget -c http://www2.mmm.ucar.edu/people/bjung/files/MPAS-Release_modified_20180730.tgz
   tar zxvf MPAS-Release_modified_20180730.tgz

   # adding -fPIC in the MPAS makefile
   echo ""
   echo "======================================================"
   echo " Compiling MPAS"
   echo "======================================================"
   cd ${SRCMPAS}
   setenv PIO ${LIBPIO} 
   echo "PIO $PIO"
   pwd
   echo "make clean CORE=atmosphere"
   make clean CORE=atmosphere
   echo "make gfortran CORE=atmosphere USE_PIO2=true"
   #make gfortran CORE=atmosphere USE_PIO2=true DEBUG=true
   make gfortran CORE=atmosphere USE_PIO2=true
endif

if ( $libr_mpas ) then
   echo ""
   echo "======================================================"
   echo " Building MPAS Library libmpas.a for OOPS"
   echo "======================================================"
   mkdir -p ${LIBMPAS}
   cd ${LIBMPAS}
   cd ${LIBMPAS}
   rm -rf include
   mkdir include
   rm -f libmpas.a

   set list_dirlib = "${SRCMPAS}/src/driver ${SRCMPAS}/src/external/esmf_time_f90/ ${SRCMPAS}/src/framework ${SRCMPAS}/src/core_atmosphere ${SRCMPAS}/src/operators"

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
   set dirlib="${SRCMPAS}/src/driver"
   cp -v ${SRCMPAS}/src/driver/*o .

   # build libmpas.a
   mv *.a *.o *.mod *.h ./include
   ar -ru libmpas.a ./include/*.o

endif

# Warning: building ODB can be slow in singularity, just do it once
#--------------------------
if ( $build_odb ) then
   cd ${REL_DIR}
   ./code/mpas-bundle/setup_odb_build.sh
   ./code/mpas-bundle/run_odb_build.sh
endif

if ( $oops_mpas ) then
   echo ""
   echo "======================================================"
   echo " Compiling OOPS-MPAS"
   echo "======================================================" 
if ( `uname -n` =~ vagrant* ) then
   setenv MPAS_LIBRARIES "${LIBPIO}/lib/libpiof.a;${LIBPIO}/lib/libpioc.a;${LIBMPAS}/libmpas.a;/usr/local/lib/libnetcdf.so;/usr/local/lib/libmpi.so;/usr/local/lib/libpnetcdf.so;/usr/local/lib/libmpi_mpifh.so"
endif
if ( `uname -n` =~ cheyenne* ) then
   setenv MPAS_LIBRARIES "${LIBPIO}/lib/libpiof.a;${LIBPIO}/lib/libpioc.a;${LIBMPAS}/libmpas.a;${NETCDF}/lib/libnetcdf.so;${MPI_ROOT}/lib/libmpi.so;${PNETCDF}/lib/libpnetcdf.a;${MPI_ROOT}/lib/libmpi.so" 
endif
   #setenv MPAS_LIBRARIES "${LIBPIO}/lib/libpiof.a;${LIBPIO}/lib/libpioc.a;${LIBMPAS}/libmpas.a;/usr/local/lib/libnetcdf.so;/usr/local/lib/libmpi.so;/usr/local/lib/libpnetcdf.so"
   setenv MPAS_INCLUDES "${LIBMPAS}/include;${LIBPIO}/include"
   echo "MPAS_LIBRARIES: ${MPAS_LIBRARIES}"
   echo "MPAS_INCLUDES:  ${MPAS_INCLUDES}"
   echo "BUILD $BUILD_MODEL"
   echo "BUNDLE CODE $BUNDLE_MODEL"

   mkdir -p ${BUILD_MODEL}
   cd ${BUILD_MODEL}

   if ( $enable_odb ) then
     ecbuild -DODB_PATH=${ODB_DIR} -DENABLE_ODB=1 -DODB_API_PATH=${ODB_DIR} -DENABLE_ODB_API=1 ${BUNDLE_MODEL}
   else
     ecbuild ${BUNDLE_MODEL}
   endif
   make -j4

   #Substitute the correct REL_DIR into relevant testinput json files
   sed -i -e "s#REL_DIR#$REL_DIR#" $BUILD_MODEL/mpas/test/testinput/*.json
endif


if ( $get_data ) then
   echo ""
   echo "======================================================"
   echo " Download and place test dataset, link UFO data "
   echo "======================================================"
   cd ${REL_DIR}
   wget -c http://www2.mmm.ucar.edu/people/bjung/files/data_20180914.tgz
   tar zxvf data_20180914.tgz
   cd ./data
   cp *.DBL *.TBL namelist.atmosphere stream_list.* streams.atmosphere x1.2562.graph.* restart.*.nc ${BUILD_MODEL}/${MODEL}/test
   ln -fs ${BUILD_MODEL}/ufo/test/Data/* ${BUILD_MODEL}/mpas/test/Data
endif

if ( $test_mpas ) then
   echo ""
   echo "======================================================"
   echo " Testing OOPS-MPAS"
   echo "======================================================"

   cd $BUILD_MODEL
   limit stacksize unlimited
   setenv OOPS_TRACE 1
   ctest -VV -R test_mpas_geometry
   #ctest -VV -R test_mpas_state
   #ctest -VV -R test_mpas_increment
   #ctest -VV -R test_mpas_model
   #ctest -VV -R test_mpas_forecast
   #ctest -VV -R test_mpas_hofx
   #ctest -VV -R test_mpas_dirac_nicas
   #ctest -VV -R test_mpas_3dvar
   #ctest -VV -R test_mpas_3denvar
endif


