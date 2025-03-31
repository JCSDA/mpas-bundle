(C) Copyright 2017-2021 UCAR

This software is licensed under the terms of the Apache Licence Version 2.0
which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

# Table of Contents

* [Installation](#installation)
    * [Git Configuration](#git-configuration)
    * [Installation Steps](#installation-steps)
    * [Building on a Compute Node](#building-on-a-compute-node)
    * [Building in an Interactive Session](#building-in-an-interactive-session)
    * [Useful CMake Flags](#useful-cmake-flags)
    * [Useful CTest Flags](#useful-ctest-flags)

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

_**For performance and memory reasons, it is recommended to compile ```mpas-bundle``` using the gnu platform.**_

* **Clone the Repository:**
  Clone the `mpas-bundle` repository and navigate into the repository's root directory.

    ```bash
    git clone https://github.com/JCSDA/mpas-bundle.git
    cd mpas-bundle
    ```

<a id="env_script"></a>

* To set up your environment for building ```mpas-bundle```, run the appropriate environment setup script for your
  computing and compiler platform.
  The compiler/shell specific environment configuration commands are listed in the below table.

  |              | GNU | Intel |
  |:------------:|:--------------:|:----------------:|
  | __zsh/bash__ | `source <mpas_bundle_dir>/env-setup/gnu-derecho.sh` | `source <mpas_bundle_dir>/env-setup/intel-derecho.sh` |
  | __csh/tcsh__ | `source <mpas_bundle_dir>/env-setup/gnu-derecho.csh` | `source <mpas_bundle_dir>/env-setup/intel-derecho.csh` |
* Create and navigate into the build directory.

    mkdir -p <mpas-bundle_build_dir> 
    cd <mpas-bundle_build_dir> 
* To configure the build using CMake, set the `MPAS_DOUBLE_PRECISION` flag according to your usage needs: 
  enable it (`-DMPAS_DOUBLE_PRECISION=ON`) for running the `mpas-jedi` test suite, or 
  disable it for `MPAS-Workflow` calculations when using the `mpas-bundle` build. 
  The default setting for `MPAS_DOUBLE_PRECISION` is `ON`.
  
  ```bash
  cmake <mpas_bundle_dir> -DMPAS_DOUBLE_PRECISION=<ON|OFF> <cmake_flags>
  ```

  Though not required, you can pass flags to cmake that define the build type, makefile
  verbosity, build engine, and compiler flags. A table of useful CMake flags can be found [here](#useful-cmake-flags).

### Building on a Compute Node

_**Due to resource limitations, it's recommended to build and run tests on a compute node.**_

* Use the `run_make.bundle.sh` script to generate a batch job for building.

  ```bash
  bash <mpas_bundle_dir>/env-setup/run_make.bundle.sh -A <derecho_account> -c <compiler> -n
  ```
* Submit the job with ```qsub```.
  ```bash
  qsub make.pbs.sh 
  ```

* When the above job finishes, generate a batch job for running mpas-jedi's test suite and submit it using ```qsub```
  ```bash
  <mpas_bundle_dir>/env-setup/run_make.bundle.sh -A <derecho_account> -c <compiler> -x ctest -n
  ```
  ```bash
  qsub ctest.pbs.sh
  ```

### Building in an Interactive Session

* Start an interactive session.
  ```bash
  qsub -A <derecho_account> -N cc-mpas-bundle -q main -l walltime=03:00:00 -l select=1:ncpus=32 -I
  ```
* Once the session starts, source the environment configuration script as you did in this [step](#env_script).
* Enter the ```mpas-bundle``` build directory
   ```bash
   cd <mpas_bundle_build_dir>
   ```
  and start the build. Make sure to specify the number of cores ```GNU Make``` should use with the ```-j``` flag.
  In the below command, ```mpas-bundle``` is compiled using 32 cores.
   ```bash
   make -j32
   ```
  When ```mpas-bundle``` is finished building, enter the ```mpas-jedi``` build directory 
  ```bash
  cd <mpas_bundle_build_dir>/mpas-jedi
  ```
  and run ctest. 
  ```bash
  ctest <ctest_flags>
  ```
  You can execute ctest without any flags to run all available tests with default settings.
  However, ctest supports numerous flags that allow you to customize the test execution. For a table of
  useful ```ctest```
  flags, click [here](#useful-ctest-flags).

### Useful CMake Flags

| Flag                       | Description                                                           | Acceptable Values                                | Default              |
|----------------------------|-----------------------------------------------------------------------|--------------------------------------------------|----------------------|
| `-G`                       | Specifies the generator to use for the build system.                  | ```Unix Makefiles```, ```Ninja```, ```Meson```.  | ```Unix Makefiles``` |
| `-DCMAKE_BUILD_TYPE`       | Defines the type of build.                                            | ```Debug```, ```Release```, ```RelWithDebInfo``` | ```Release```        |
| `-DCMAKE_VERBOSE_MAKEFILE` | Enables verbose output from the makefile, useful for debugging.       | ```ON```, ```OFF```                              | ```OFF```            |
| `-DMPAS_DOUBLE_PRECISION`  | __MPAS-MODEL__: Use double precision for floating point calculations. | ```ON```, ```OFF```                              | ```ON```             | 

### Useful CTest Flags

| Flag                      | Description                                                                                                        | Acceptable Values                                                   |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------|
| `--build-and-test`        | Build and test a project.                                                                                          | Path to project and build tree, additional arguments                |
| `--test-action`           | Specifies the action to perform (e.g., test, start, update, configure, build).                                     | ```test```, ```start```, ```update```, ```configure```, ```build``` |
| `--output-on-failure`     | Output anything from the test program if it fails.                                                                 | N/A                                                                 |
| `--parallel`              | Run the tests in parallel using the given number of jobs.                                                          | Number of jobs (e.g., `32`)                                         |
| `--schedule-random`       | Schedule tests in random order.                                                                                    | N/A                                                                 |
| `--stop-on-failure`       | Stop running tests after the first test fails.                                                                     | N/A                                                                 |
| `--timeout`               | Set a global timeout for all tests, after which CTest will kill the test.                                          | Timeout in seconds (e.g., `120`)                                    |
| `--verbose`               | Enable verbose output from tests.                                                                                  | N/A                                                                 |
| `--repeat`                | Repeat the tests according to a specified mode (e.g., until fail, until pass, after timeout).                      | ```until-fail```, ```until-pass```, ```after-timeout```             |
| `--extra-submit`          | Specify files to submit to a dashboard. Files are submitted to the first dashboard mentioned in CTestConfig.cmake. | File paths                                                          |
| `--label-summary`         | Print a summary of test results grouped by label.                                                                  | N/A                                                                 |
| `--subproject-summary`    | Print a summary of test results grouped by subproject.                                                             | N/A                                                                 |
| `-C` or `--build-config`  | Specify the configuration type to build/test when using a multi-configuration generator.                           | ```Debug```, ```Release```, ```RelWithDebInfo```                    |
| `-R` or `--tests-regex`   | Run only the tests whose names match the given regular expression.                                                 | Regular expression (e.g., `MyTest*`)                                |
| `-E` or `--exclude-regex` | Exclude tests whose names match the given regular expression.                                                      | Regular expression (e.g., `LongRunningTest*`)                       |
| `-L` or `--label-regex`   | Run only the tests with labels matching the given regular expression.                                              | Regular expression (e.g., `Nightly*`)                               |
| `-j` or `--parallel`      | Run the tests in parallel using the given number of jobs.                                                          | Number of jobs (same as `--parallel`)                               |
