#!/bin/csh
#---------------------------------------------------------
# Author: Gael DESCOMBES, MMM/NCAR, 01/2018
# Build PIO and MPAS libraries for OOPS-MPAS
#
# Prerequies:
# - mpas-bundle github done
# - place modified MPAS code in SRCMPAS / --> need to use mpas github
#
# Directory structure assumed...
# /home/vagrant/code/
#                   ├─mpas-bundle
#                   └─MPAS-Release
# /home/vagrant/build/
#                    └─mpas-bundle
# /home/vagrant/libs/
#                   ├─build
#                   └─ParallelIO
#---------------------------------------------------------
setenv MODEL mpas
setenv BUNDLE_MODEL "/home/vagrant/code/mpas-bundle/"
setenv BUILD_MODEL "/home/vagrant/build/mpas-bundle/"

setenv SRCMPAS /home/vagrant/code/MPAS-Release
setenv LIBMPAS ${SRCMPAS}/link_libs
setenv PIODIR /home/vagrant/libs
setenv SRCPIO ${PIODIR}/ParallelIO 
setenv BUILDPIO ${PIODIR}/build
setenv LIBPIO ${BUILDPIO}/writable/pio2
#setenv NETCDF /somewhere/already set
#setenv PNETCDF /somewhere/already set 

set comp_pio2=0
set comp_mpas=0
set libr_mpas=0
set oops_mpas=1
set test_mpas=0

#===========================================================

if ( $comp_pio2 ) then
   echo ""
   echo "======================================================"
   echo " Git clone PIO2"
   echo "======================================================"
   mkdir -p $PIODIR
   cd $PIODIR
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
   setenv FC mpif90
   cmake -DNetCDF_C_PATH=$NETCDF -DNetCDF_Fortran_PATH=$NETCDF -DPnetCDF_PATH=$PNETCDF -DCMAKE_INSTALL_PREFIX=${LIBPIO} -DPIO_ENABLE_TIMING=OFF $SRCPIO -DPIO_ENABLE_TIMING=OFF
   make
   make install

endif

if ( $comp_mpas ) then
   # adding -fPIC in the MPAS makefile
   echo ""
   echo "======================================================"
   echo " Compiling MPAS"
   echo "======================================================"
   cd ${SRCMPAS}
   setenv PIO ${LIBPIO} 
   echo "PIO $PIO"
   pwd
   echo "make gfortran CORE=atmosphere USE_PIO2=true"
   #make gfortran CORE=atmosphere USE_PIO2=true DEBUG=true
   make gfortran CORE=atmosphere USE_PIO2=true
endif

if ( $libr_mpas ) then
   echo ""
   echo "======================================================"
   echo " Building MPAS Library libmpas.a for OOPS"
   echo "======================================================"
   mkdir ${LIBMPAS}
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

if ( $oops_mpas ) then
   echo ""
   echo "======================================================"
   echo " Compiling OOPS-MPAS"
   echo "======================================================" 

   setenv MPAS_LIBRARIES "${LIBPIO}/lib/libpiof.a;${LIBPIO}/lib/libpioc.a;${LIBMPAS}/libmpas.a;/usr/local/lib/libnetcdf.so;/usr/local/lib/libmpi.so;/usr/local/lib/libpnetcdf.so;/usr/local/lib/libmpi_mpifh.so"
   #setenv MPAS_LIBRARIES "${LIBPIO}/lib/libpiof.a;${LIBPIO}/lib/libpioc.a;${LIBMPAS}/libmpas.a;/usr/local/lib/libnetcdf.so;/usr/local/lib/libmpi.so;/usr/local/lib/libpnetcdf.so"
   setenv MPAS_INCLUDES "${LIBMPAS}/include;${LIBPIO}/include"
   echo "MPAS_LIBRARIES: ${MPAS_LIBRARIES}"
   echo "MPAS_INCLUDES:  ${MPAS_INCLUDES}"
   echo "BUILD $BUILD_MODEL"
   echo "BUNDLE CODE $BUNDLE_MODEL"

   mkdir -p $BUILD_MODEL/${MODEL}
   cd $BUILD_MODEL
   ecbuild  /home/vagrant/code/mpas-bundle
   make -j4

   #cp -v $BUNDLE_MODEL/statics/* $BUILD_MODEL/${MODEL}/test
   #cp -v ~/jedi/data/mpas2/* $BUILD_MODEL/${MODEL}/test

endif


if ( $test_mpas ) then
   echo ""
   echo "======================================================"
   echo " Testing OOPS-MPAS"
   echo "======================================================"

   cd $BUILD_MODEL
   export OOPS_TRACE=1
   #ctest -VV -R test_mpas_geometry
   #ctest -VV -R test_mpas_state
   ctest -VV -R test_mpas_increment
   #ctest -VV -R test_mpas_geometry
endif
