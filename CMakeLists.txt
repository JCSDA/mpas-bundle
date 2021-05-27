# (C) Copyright 2017-2020 UCAR
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

#
# MPAS/JEDI bundle
#

cmake_minimum_required( VERSION 3.12 )
project( mpas-bundle LANGUAGES C CXX Fortran )

## ECBuild integration
include(GNUInstallDirs)
set( INSTALL_LIB_DIR ${CMAKE_INSTALL_LIBDIR} CACHE STRING "Library installation directory" FORCE ) #Force ecbuild to use the default platform lib install location
set( ECBUILD_DEFAULT_BUILD_TYPE Release CACHE STRING "ECBuild default build type" FORCE)
set( CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin )
set( CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib )
set( CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib )
find_package(ecbuild)
include( ecbuild_bundle )
ecbuild_bundle_initialize()

ecbuild_bundle( PROJECT jedicmake GIT "https://github.com/jcsda-internal/jedi-cmake.git" BRANCH develop UPDATE )
include( jedicmake/cmake/Functions/git_functions.cmake )

option(BUNDLE_SKIP_ECKIT "Don't build eckit" "ON" ) # Skip eckit build unless user passes -DBUNDLE_SKIP_ECKIT=OFF
ecbuild_bundle( PROJECT eckit     GIT "https://github.com/jcsda-internal/eckit.git"  BRANCH release-stable UPDATE )
ecbuild_bundle( PROJECT fckit     GIT "https://github.com/jcsda-internal/fckit.git"  BRANCH release-stable UPDATE )
ecbuild_bundle( PROJECT atlas     GIT "https://github.com/jcsda-internal/atlas.git"  BRANCH release-stable UPDATE )

#TODO: When mpas-bundle becomes a public repo, consider changing the default value of BUNDLE_SKIP_ROPP-UFO to "ON"
option(BUNDLE_SKIP_ROPP-UFO "Don't build ROPP-UFO"  "OFF") # Skip ropp-ufo build unless user passes -DBUNDLE_SKIP_ROPP-UFO=OFF
ecbuild_bundle( PROJECT ropp-ufo  GIT "https://github.com/jcsda-internal/ropp-test.git"   BRANCH develop   UPDATE )
option(BUNDLE_SKIP_GSW "Don't build GSW"       "ON") # Skip gsw build unless user passes -DBUNDLE_SKIP_GSW=OFF
ecbuild_bundle( PROJECT gsw       GIT "https://github.com/jcsda-internal/GSW-Fortran.git" BRANCH develop   UPDATE )
ecbuild_bundle( PROJECT crtm      GIT "https://github.com/jcsda-internal/crtm.git"        TAG    v2.3-jedi UPDATE )
option(BUNDLE_SKIP_RTTOV "Don't build rttov"  "ON") # Skip rttov build unless user passes -DBUNDLE_SKIP_RTTOV=OFF
ecbuild_bundle( PROJECT rttov     GIT "https://github.com/JCSDA-internal/rttov.git"       BRANCH develop   UPDATE )

ecbuild_bundle( PROJECT oops      GIT "https://github.com/jcsda-internal/oops.git"        BRANCH develop UPDATE )
ecbuild_bundle( PROJECT saber     GIT "https://github.com/jcsda-internal/saber.git"       BRANCH develop UPDATE )
ecbuild_bundle( PROJECT ioda      GIT "https://github.com/jcsda-internal/ioda.git"        BRANCH develop UPDATE )
ecbuild_bundle( PROJECT ufo       GIT "https://github.com/jcsda-internal/ufo.git"         BRANCH develop UPDATE )

# ioda and ufo test data
#---------------------------------

# If IODA branch is being built set GIT_BRANCH_FUNC to IODA's current branch.
# If a tagged version of IODA is being built set GIT_TAG_FUNC to ioda's current tag. In this case,
# IODA test files will be download from UCAR DASH and ioda-data repo will not be cloned.
# When LOCAL_PATH_JEDI_TESTFILES is set to the directory of IODA test files stored
# in a local directory, ioda-data repo will not be cloned

find_branch_name(REPO_DIR_NAME ioda)
# When LOCAL_PATH_JEDI_TESTFILES is set to the directory of IODA test files stored
# in a local directory, ioda-data repo will not be cloned
if( NOT DEFINED ENV{LOCAL_PATH_JEDI_TESTFILES} AND NOT DEFINED ${GIT_TAG_FUNC} )
  ecbuild_bundle( PROJECT ioda-data GIT "https://github.com/JCSDA-internal/ioda-data.git" BRANCH develop UPDATE )
endif()

# same procedure for ufo-data
find_branch_name(REPO_DIR_NAME ufo)
if( NOT DEFINED ENV{LOCAL_PATH_JEDI_TESTFILES} AND NOT DEFINED ${GIT_TAG_FUNC} )
  ecbuild_bundle( PROJECT ufo-data GIT "https://github.com/JCSDA-internal/ufo-data.git" BRANCH develop UPDATE )
endif()


set(MPAS_DOUBLE_PRECISION "ON" CACHE STRING "MPAS-Model: Use double precision 64-bit Floating point.")
set(MPAS_CORES init_atmosphere atmosphere CACHE STRING "MPAS-Model: cores to build.")
ecbuild_bundle( PROJECT MPAS GIT "https://github.com/jcsda-internal/MPAS-Model.git" BRANCH release-stable UPDATE)
ecbuild_bundle( PROJECT mpasjedi GIT "https://github.com/jcsda-internal/mpas-jedi"  BRANCH develop UPDATE)



ecbuild_bundle_finalize()
