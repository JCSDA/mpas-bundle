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


1. Clone the mpas-bundle repository and create an environment variable equal to the repository root directory
    ```bash
    git clone https://github.com/JCSDA-internal/mpas-bundle.git
    ```
    and navigate into the repository root directory.
    ```bash
    cd mpas-bundle
    ```
1. Source the configure script in the env-setup directory, which will set several envirnoment variables referenced in the subsequent installation steps. A list of
   configure arguments is provided below.
   - ```mpas_bundle_dir```: The absolute path to the mpas-bundle repository root directory.
   - ```mpas_bundle_buidl_dir```: The absolute path to the mpas-bundle build directory.
   - ```mpas_bundle_compiler```: The compiler platform that mpas-bundle is built for.
   - ```mpas_bundle_cmake_flags```: The flags pass to CMake during the configuration step. This is an optional argument. 
    ```bash
    source env-setup/configure.sh <mpas_bundle_dir> <mpas_bundle_build_dir> <mpas_bundle_compiler> <mpas_bundle_account> [<mpas_bundle_cmake_flags>]" 
    ```
    
1. Create the build directory 
    ```bash
    mkdir ${MPAS_BUNDLE_BUILD_DIR} 
    ```
1. and enter it.
   ```bash
   cd ${MPAS_BUNDLE_BUILD_DIR} 
   ```
## If building on Derecho 

1. Configure the cmake build.
    ```bash
    cmake ${MPAS_BUNDLE_DIR} ${MPAS_BUNDLE_CMAKE_FLAGS}
    ```
1. Due to resource limitations on derecho it is recommended to build and run ctest on a compute node. To run
the build on a compute node, create a batch script using the run_make.bundle.sh script in the env-setup directory. If you want to log the build and ctest
progress to the terminal, pass ```-l``` to the ```run_make.bundle.sh``` script.
    ```bash    
    bash ${MPAS_BUNDLE_DIR}/env-setup/run_make.bundle.sh -A ${MPAS_BUNDLE_ACCOUNT} -e ${MPAS_BUNDLE_DIR}/env-setup -c ${MPAS_BUNDLE_COMPILER} -n
    ```
1. This will create a batch job submission script with the name specified above. After checking the batch script, submit it via
    ```bash
    qsub make.pbs.sh 
    ```
1. Once the build has finished, create a batch job script for running ctest
    ```bash    
    bash ${MPAS_BUNDLE_DIR}/env-setup/run_make.bundle.sh -A ${MPAS_BUNDLE_ACCOUNT} -e ${MPAS_BUNDLE_DIR}/env-setup -c ${MPAS_BUNDLE_COMPILER} -x ctest -n
    ```
1. and submit it.
    ```bash
   qsub ctest.pbs.sh
    ```

[//]: # (The cmake command above will clone all the source code for the projects defined in the)

[//]: # (CMakeLists.txt in the bundle and the make command will build them all.)

[//]: # ()
[//]: # (The default build-type is 'release'. For a debug build, add '-DCMAKE_BUILD_TYPE=Debug' to the cmake)

[//]: # (command line.)

[//]: # ()
[//]: # (To work with a different branch than the default for a given project, the branch must be)

[//]: # (modified in the CMakeLists.txt for the bundle.)


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
