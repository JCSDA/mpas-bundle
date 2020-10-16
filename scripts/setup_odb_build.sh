#!/usr/bin/env bash
#
# This script will:
#   Create a directory structure for building odb
#   Download the ODB_API and ECCODES tar files and unpack them
#   Make a few necessary modifications in the odb source code
#

OdbName="odb_api_bundle-0.18.0-Source"
EccodesName="eccodes-2.8.0-Source"

OdbTarFile="${OdbName}.tar.gz"
EccodesTarFile="${EccodesName}.tar.gz"

OdbTarUrl="https://confluence.ecmwf.int/download/attachments/61117379/${OdbTarFile}"
EccodesTarUrl="https://confluence.ecmwf.int/download/attachments/45757960/${EccodesTarFile}"


########################################################################
# Create the directory structure for building odb
########################################################################
#
#    ./odb/
#          build_eccodes/                 for compile, test, install processes
#          build_metkit/                               ''
#          build_odb/                                  ''
#          install/                       location of eccodes, metkit, odb packages
#          src/
#             <odb_source_code>
#             <eccodes_source_code>
#          tar/                           odb, eccodes tar files

# Create path to odb build directory based on the current working directory
ODB_PATH="$(pwd)/odb"

# Check with the user if okay
echo "About to set up odb build in current directory: $ODB_PATH"
#echo "Continue? y for yes, n for no"
#read Response
#if [ "$Response" != "y" ]
#then
#   echo "Aborting"
#fi

# Okay, ready to go

########################################################################
# Download and upack the ODB and ECCODES tar files
########################################################################
echo "Creating directories:"
if [ -d $ODB_PATH ]
then
  echo "  Directory structure already built"
  echo
else
  set -x
  mkdir -p $ODB_PATH/build_eccodes
  mkdir -p $ODB_PATH/build_metkit
  mkdir -p $ODB_PATH/build_odb
  mkdir -p $ODB_PATH/install
  mkdir -p $ODB_PATH/src
  mkdir -p $ODB_PATH/tar
  set +x
  echo
fi

# Get the tar balls
cd $ODB_PATH/tar
echo "Retrieving tar files:"
echo
if [ -f $OdbTarFile ]
then
  echo "  $OdbTarFile is already downloaded"
else
  echo "  Retrieving $OdbTarFile"
  echo
  wget $OdbTarUrl
fi
if [ -f $EccodesTarFile ]
then
  echo "  $EccodesTarFile is already downloaded"
else
  echo "  Retrieving $EccodesTarFile"
  echo
  wget $EccodesTarUrl
fi
echo

# Unpack the tar balls
cd $ODB_PATH/src
echo "Unpacking tar files:"
echo
if [ -d $OdbName ]
then
  echo "  $OdbTarFile already unpacked"
  echo
else 
  echo "  Unpacking $OdbTarFile"
  tar -xzvf $ODB_PATH/tar/$OdbTarFile
fi
if [ -d $EccodesName ]
then
  echo "  $EccodesTarFile already unpacked"
  echo
else 
  echo "  Unpacking $EccodesTarFile"
  tar -xzvf $ODB_PATH/tar/$EccodesTarFile
fi
echo

########################################################################
# Do the modifications
########################################################################
#
# Edit the CMakeLists.txt file:
#   Comment out the ecbuild, eckit and metkit so that we use
#   the install ecbuild and eckit, and can build and install
#   metkit as a separate package.
#
#   Change the STASH specs for odb_api, odb and odb-tools to SOURCE
#   specs since this isn't really a git repository.
#

cd $ODB_PATH/src/$OdbName
if [ ! -f CMakeLists.txt.orig ]
then
  echo "Saving original ODB CMakeLists.txt file"
  set -x
  mv CMakeLists.txt CMakeLists.txt.orig
  set +x
fi

echo "Modifiying ODB CMakeLists.txt file"
sed -e '/^ecbuild_bundle.* ecbuild /s/^/#/' \
    -e '/^ecbuild_bundle.* eckit /s/^/#/' \
    -e '/^ecbuild_bundle.* metkit /s/^/#/' \
    -e "/^ecbuild_bundle.* odb_api /s@STASH .*@SOURCE \"$ODB_PATH/src/$OdbName/odb_api\" )@" \
    -e "/^ecbuild_bundle.* odb /s@STASH .*@SOURCE \"$ODB_PATH/src/$OdbName/odb\" )@" \
    -e "/^ecbuild_bundle.* odb-tools /s@STASH .*@SOURCE \"$ODB_PATH/src/$OdbName/odb-tools\" )@" \
    CMakeLists.txt.orig > CMakeLists.txt
echo

