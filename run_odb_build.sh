#!/usr/bin/env bash
#
# This script will run the build and install the following packages:
#   metkit
#   eccodes
#   odb (which includes ODB1 and ODB2)
#
# It is assumed that you have run setup_odb_build.sh prior to running this script,
# and that you are cd'd to the directory where setup_odb_build.sh was run.

OdbName="odb_api_bundle-0.18.0-Source"
EccodesName="eccodes-2.8.0-Source"

ODB_PATH="$(pwd)/odb"
ODB_INSTALL_DIR="${ODB_PATH}/install"

########################################################################
# METKIT
########################################################################
echo "Building/installing metkit:"
cd $ODB_PATH/build_metkit
ecbuild -DCMAKE_INSTALL_PREFIX=${ODB_INSTALL_DIR} ../src/${OdbName}/metkit
make -j4
#ctest
make install

########################################################################
# ECCODES
########################################################################
echo "Building/installing eccodes:"
cd $ODB_PATH/build_eccodes
ecbuild -DCMAKE_INSTALL_PREFIX=${ODB_INSTALL_DIR} ../src/${EccodesName}
make -j4
#ctest
make install

########################################################################
# ODB1 + ODB2
########################################################################
echo "Building/installing odb:"
cd $ODB_PATH/build_odb
ecbuild -DCMAKE_INSTALL_PREFIX=${ODB_INSTALL_DIR} \
        -DENABLE_ODB=1 \
        -DENABLE_FORTRAN=1 \
        -DENABLE_MIGRATOR=1 \
        ../src/${OdbName}
make -j4
#ctest
make install

