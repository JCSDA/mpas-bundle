(C) Copyright 2017-2021 UCAR

This software is licensed under the terms of the Apache Licence Version 2.0
which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

# Installation Instructions 

---
### Note about using git

It is recommended that you create a .gitconfig file in your home directory (inside the container
if working from a container)
```bash
vim ${HOME}/.gitconfig
```

with the following content:

```bash
[user]
name = Your Name
email = yourname@somewhere.something

[credential]
helper = cache --timeout=3600
```
Since the bundle acceses many repositories, it can be tedious to enter your username and
password for every operation. With the last line the system will remember your password for
a given time (defined in seconds by the timeout parameter).

---

1.  Clone the mpas-bundle repository and create an environment variable equal to the repository root directory
    ```bash
    git clone https://github.com/JCSDA-internal/mpas-bundle.git
    ```
    and navigate into the repository root directory.
    ```bash
    cd mpas-bundle
    ```
1. Create an environment variable equal to the repository root directory
    ```bash
    MPAS_BUNDLE_DIR=$(pwd)
    ```
1. Create a build directory and enter it.
    ```bash
    mkdir build
    cd build
    ```
## If building on Derecho 

1. Create an environment variable equal to the compiler you want to use.
    ```bash
    MPAS_BUNDLE_COMPILER=<intel or gnu>
    ```
1. Source the environment mpas-bundle environment script.
    ```bash
    source ${MPAS_BUNDLE_DIR}/env-setup/${MPAS_BUNDLE_COMPILER}-derecho.sh
    ```
1. Configure the cmake build.
    ```bash
    cmake ..
    ```
1. Due to resource limitations on derecho it is recommended to build and run ctest on a compute node. To run
the build on a compute node, create a batch script using the run_make.bundle.sh script in the env-setup directory. If you want to log the build and ctest
progress to the terminal, pass ```-l``` to the ```run_make.bundle.sh``` script.
    ```bash    
    bash ${MPAS_BUNDLE_DIR}/env-setup/run_make.bundle.sh -A <account> -e ${MPAS_BUNDLE_DIR}/env-setup -c ${MPAS_BUNDLE_COMPILER} -f <make job file name> -l -n
    ```
1. This will create a batch job submission script with the name specified above. After checking the batch script, submit it via
    ```bash
    qsub <make job file name>
    ```
1. Once the build has finished, create a batch job script for running ctest
    ```bash    
    bash ${MPAS_BUNDLE_DIR}/env-setup/run_make.bundle.sh -A <account> -e ${MPAS_BUNDLE_DIR}/env-setup -c ${MPAS_BUNDLE_COMPILER} -f <job file name> -x ctest -l -n
    ```
1. and submit it.
    ```bash
    qsub <ctest job file name>
    ```

The cmake command above will clone all the source code for the projects defined in the
CMakeLists.txt in the bundle and the make command will build them all.

The default build-type is 'release'. For a debug build, add '-DCMAKE_BUILD_TYPE=Debug' to the cmake
command line.

To work with a different branch than the default for a given project, the branch must be
modified in the CMakeLists.txt for the bundle.


--- Working with the code ---
# Working with the code

The CMakeLists.txt file in this directory contains the list of the repositories included
in the bundle and the branch to be used. The branch specified in the CMakeLists.txt is
the one that will be compiled. When working with you own branch, the should be changed in
the CMakeLists.txt file, but it is not necessary to re-run cmake, make is enough.

After the first build, changes in the code can be tested by re-running only
(from build directory in an interactive session on a compute node):

    make -j4
    cd mpas-jedi
    ctest

By default, make will not update your local repository from the remote. To update all repositories
in the bundle, run (from build directory):

    make update

The update will fail for repositories that contain uncommited code. This is a safety mechanism to
avoid losing your work.
