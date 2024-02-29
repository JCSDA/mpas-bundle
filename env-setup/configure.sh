#!/bin/bash

# Check for minimum number of arguments
if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <mpas_bundle_dir> <mpas_bundle_build_dir> <mpas_bundle_compiler> <mpas_bundle_account> [<mpas_bundle_cmake_flags>]"
    echo "compiler options: intel or gnu"
    exit 1
fi

# Assign mandatory arguments to variables
MPAS_BUNDLE_DIR=$1
MPAS_BUNDLE_BUILD_DIR=$2
MPAS_BUNDLE_COMPILER=$3
MPAS_BUNDLE_ACCOUNT=$4

# Assign optional MPAS_BUNDLE_CMAKE_FLAGS argument if provided
if [ "$#" -eq 5 ]; then
    MPAS_BUNDLE_CMAKE_FLAGS=$5
else
    MPAS_BUNDLE_CMAKE_FLAGS=""  # Set to empty if not provided
fi

# Validate compiler choice
if [ "$MPAS_BUNDLE_COMPILER" != "intel" ] && [ "$MPAS_BUNDLE_COMPILER" != "gnu" ]; then
    echo "Invalid compiler specified. Use 'intel' or 'gnu'."
    exit 2
fi

# Export environment variables
export MPAS_BUNDLE_DIR
export MPAS_BUNDLE_BUILD_DIR
export MPAS_BUNDLE_COMPILER
export MPAS_BUNDLE_ACCOUNT
export MPAS_BUNDLE_CMAKE_FLAGS

# Output the set environment variables for user verification
echo "MPAS_BUNDLE_DIR is set to $MPAS_BUNDLE_DIR"
echo "MPAS_BUNDLE_BUILD_DIR is set to $MPAS_BUNDLE_BUILD_DIR"
echo "MPAS_BUNDLE_COMPILER is set to $MPAS_BUNDLE_COMPILER"
echo "MPAS_BUNDLE_ACCOUNT is set to $MPAS_BUNDLE_ACCOUNT"
if [ -n "$MPAS_BUNDLE_CMAKE_FLAGS" ]; then
    echo "MPAS_BUNDLE_CMAKE_FLAGS is set to '$MPAS_BUNDLE_CMAKE_FLAGS'"
else
    echo "MPAS_BUNDLE_CMAKE_FLAGS is not set"
fi

env_script="${MPAS_BUNDLE_DIR}/env-setup/${MPAS_BUNDLE_COMPILER}-derecho.sh"
source ${env_script}
