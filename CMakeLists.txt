# (C) Copyright 2017 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

#
# MPAS/JEDI bundle
#

project( mpas-bundle C CXX Fortran )

cmake_minimum_required( VERSION 3.3.2 FATAL_ERROR )

set( CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake;${CMAKE_CURRENT_SOURCE_DIR}/ecbuild/cmake;${CMAKE_MODULE_PATH}")
include( ecbuild_bundle )

set( ENABLE_MPI ON CACHE BOOL "Compile with MPI" )

ecbuild_bundle_initialize()

ecbuild_requires_macro_version( 2.7 )

#ecbuild_bundle( PROJECT eckit  GIT "https://github.com/ECMWF/eckit.git"        TAG 0.23.0 )
ecbuild_bundle( PROJECT fckit GIT "https://github.com/JCSDA/fckit.git"         BRANCH develop        UPDATE )
ecbuild_bundle( PROJECT ropp-ufo  GIT "https://github.com/JCSDA/ropp-test.git" BRANCH develop        UPDATE )
ecbuild_bundle( PROJECT oops   GIT "https://github.com/JCSDA/oops.git"         BRANCH develop        UPDATE )
#ecbuild_bundle( PROJECT gsw    GIT "https://github.com/JCSDA/GSW-Fortran.git"  BRANCH develop        UPDATE )
ecbuild_bundle( PROJECT crtm   GIT "https://github.com/JCSDA/crtm.git"         BRANCH develop        UPDATE )
ecbuild_bundle( PROJECT ioda   GIT "https://github.com/JCSDA/ioda.git"         BRANCH develop        UPDATE )
ecbuild_bundle( PROJECT ufo    GIT "https://github.com/JCSDA/ufo.git"          BRANCH develop        UPDATE )
ecbuild_bundle( PROJECT mpas   GIT "https://github.com/JCSDA/mpas.git"         BRANCH develop        UPDATE )

ecbuild_bundle_finalize()
