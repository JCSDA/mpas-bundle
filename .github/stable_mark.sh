#!/bin/bash
#================================================================================
# (C) Copyright 2019 UCAR
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# This script is designed to be sourced from the mpas-bundle directory:
# e.g. source .github/stable_mark.sh
#
# It will modify the CMakeLists.txt file to reference the specific git hash
# of each project instead of a tag or branch (i.e. 'develop').
#
# Note that every project must already be cloned to the bundle directory
# and the hash of the HEAD of each project will be put into CMakeLists.txt.
#
# This script is a modification of the script with the same filename in the 
# JCSDA/soca repository, created by Travis Sluka.
#================================================================================
set -e

cwd=$(pwd)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# figure out what git hash is associated with each repo in the bundle.
# Note that there are several places where this repo could exist.
bundle_dir=$cwd
bundle_repos=$(grep "ecbuild_bundle(" $bundle_dir/CMakeLists.txt | awk '{print $3}')
for r in $bundle_repos; do

    echo ""
    echo "Finding hash tag for $r..."
    hash="none"

    # check the repo source ( for uncached repos, i.e. the main test repo)
    if [[ "$hash" == "none" ]]; then
        echo -n "searching uncached src.. "
        src_dir=$bundle_dir/$r
        [[ -d $src_dir ]] \
            && cd $src_dir \
            && hash=$(git rev-parse HEAD || echo "none")
        [[ "$hash" == "none" ]] && echo "NOT found" || echo "FOUND"
    fi

    # use ecbuild to find the repo (i.e. check if in the container)
    if [[ "$hash" == "none" ]]; then
        echo -n "searching cmake paths... "
        rm -rf $cwd/repo_hash
        mkdir -p $cwd/repo_hash/build
        cp $SCRIPT_DIR/get_repo_hash.cmake  $cwd/repo_hash/CMakeLists.txt
        cd $cwd/repo_hash/build
        hash=$(ecbuild -DREPO_NAME=${r^^} ../ 2> /dev/null | grep "git_hash" || echo "none")
        [[ "$hash" != "none" ]] && hash=$(echo "$hash" | awk '{print $3}')
        [[ "$hash" == "none" ]] && echo "NOT found" || echo "FOUND"
    fi

    # otherwise, we couldn't find the repo, either the repo in the bundle wasn't used for
    # the ctests, or something bad happened. Oh well.

    # if a git hash was found, update the bundle with a tagged version
    echo "git_hash: $hash"
    if [[ $hash != "none" ]]; then
        hash=${hash:0:7}
        echo "changing $r to $hash"
        sed -i "s/\(.* PROJECT $r .*\) \(BRANCH\|TAG\) .*/\1 TAG $hash \)/" $bundle_dir/CMakeLists.txt
    fi
done
cd $bundle_dir

