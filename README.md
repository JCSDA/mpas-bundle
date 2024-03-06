(C) Copyright 2017-2021 UCAR

This software is licensed under the terms of the Apache Licence Version 2.0
which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

# Table of Contents
* [Installation](#installation)
  * [Git Configuration](#git-configuration)
  * [Installation Steps](#installation-steps)
  * [Building on a Compute Node](#building-on-a-compute-node)
  * [Building in an Interactive Session](#building-in-an-interactive-session)
# Installation

### Git Configuration
* It's recommended to configure Git using command line to simplify repository access. You can set your 
name and email, which helps avoid repeatedly entering your credentials. 
Run the following commands in your terminal:
    ```bash
    # Set your name
  git config --global user.name "Your Name"

  # Set your email
  git config --global user.email "yourname@somewhere.something"

  # Set credential helper with timeout
  git config --global credential.helper 'cache --timeout=3600'
    ```
* Ensure Git LFS is installed and configured prior to building ```mpas-bundle```.

     ```bash
     git lfs install
     ```

### Installation Steps

* **Clone the Repository:**
   Clone the `mpas-bundle` repository and navigate into the repository's root directory.

    ```bash
    git clone https://github.com/JCSDA-internal/mpas-bundle.git
    cd mpas-bundle
    ```
<a id="env_script"></a>
* To set up your environment for building ```mpas-bundle```, run the appropriate environment setup script for your computing and compiler platform. 
The compiler/shell specific environment configuration commands are listed in the below table.
 
  |              | GNU | Intel |
  |:------------:|:--------------:|:----------------:|
  | __zsh/bash__ | `source env-setup/gnu-derecho.sh` | `source env-setup/intel-derecho.sh` |
  | __csh/tcsh__ | `source env-setup/gnu-derecho.csh` | `source env-setup/intel-derecho.csh` |
* Create and navigate into the build directory.

  ```bash
    mkdir <mpas-bundle_build_dir> 
  ```
  ```bash
    cd <mpas-bundle_build_dir> 
    ```
* Run CMake to configure the build. 

    ```bash
    cmake <mpas-bundle_build_dir> 
    ```

### Building on a Compute Node

_**Due to resource limitations, it's recommended to build and run tests on a compute node.**_

* Use the `run_make.bundle.sh` script to generate a batch job for building.

  ```bash
  bash <mpas_bundle_dir>/env-setup/run_make.bundle.sh -A <derecho_account> -e <mpas-bundle_dir>/env-setup -c <compiler> -n
  ```
* Submit the job with ```qsub```.
  ```bash
  qsub make.pbs.sh 
  ```

* When the above job finishes, generate a batch job for running mpas-jedi's test suite and submit it using ```qsub``` 
  ```bash
  bash <mpas_bundle_dir>/env-setup/run_make.bundle.sh -A <derecho_account> -e <mpas-bundle_dir>/env-setup -c <compiler> -x ctest -n
  ```
  ```bash
  qsub ctest.pbs.sh
  ```

### Building in an Interactive Session

* Start an interactive session. 
  ```bash
  qsub -A <derecho_account> -N cc-mpas-bundle -q main -l walltime=03:00:00 -l select=1:ncpus=8 -I
  ```
* Once the session starts, source the environment configuration script as you did in this [step](#env_script).
* Enter the ```mpas-bundle``` build directory
   ```bash
   cd <mpas_bundle_build_dir>
   ```
  and start the build. Make sure to specify the number of cores ```GNU Make``` should use with the ```-j``` flag.
In the below command, ```mpas-bundle``` is compiled using 8 cores.
   ```bash
   make -j8
   ```
* When the build has finished, enter the ```mpas-jedi``` directory
  ```bash
  cd mpas-jedi
  ```
  and run ctest.
  ```bash
  ctest
  ```
