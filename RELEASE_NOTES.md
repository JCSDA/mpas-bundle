# JEDI-MPAS 1.0.0 RELEASE NOTES

The Joint Center for Satellite Data Assimilation (JCSDA) and National Center for Atmospheric Research (NCAR) are pleased to announce the public release of JEDI-MPAS 1.0.0 on September 24, 2021. JEDI-MPAS is a multi-component software package that provides everything that is needed to run data assimilation applications for the atmospheric core of the [Model for Prediction Across Scales](https://mpas-dev.github.io/) (MPAS).

The Joint Effort for Data assimilation Integration (JEDI) is a development project led by JCSDA. The purpose of JEDI is to provide a comprehensive generic data assimilation framework that will accelerate data assimilation developments and the uptake of new observation platforms for the community.
MPAS is a collaborative project for developing atmosphere, ocean and other earth-system simulation components for use in climate, regional climate and weather studies, whose primary development partners are Los Alamos National Laboratory and NCAR.
 
JEDI-MPAS works with MPAS’s native unstructured Voronoi meshes, including regional and variable-resolution meshes, and performs I/O with native MPAS-A files.

## SOURCE CODE

JEDI-MPAS 1.0.0 is modular software and the required source code spans several repositories in various categories. All this software is available open source from https://github.com/JCSDA

* The generic data assimilation components **OOPS**, **UFO**, **SABER** and **IODA** provide the central data assimilation capabilities. **OOPS** is the heart of JEDI, defining interfaces and data assimilation applications. **UFO** provides generic observation operators. **IODA** provides the in-memory data access and management and IO for observations. **SABER** provides generic interfaces for covariance matrix operations.
* **MPAS-JEDI** implements the JEDI applications for MPAS, and provides all the configuration files and executables for running applications. 
* **MPAS-Model** contains the MPAS modeling infrastructure, including code for the atmospheric core used by JEDI-MPAS. The repository is forked from MPAS-Dev, the main repository for MPAS development, and includes enhancements for use with JEDI, which are merged back into MPAS-Dev/MPAS-Model when feasible.


Descriptions of the various components of JEDI are available [here](https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/inside/jedi-components/index.html).

## BUILD SYSTEM

Several modes of building and running JEDI-MPAS are supported with this release:
* Using a [development container](https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/learning/tutorials/level2/index.html). 
* Using [Amazon Web Services](https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/using/jedi_environment/cloud/index.html).
* Using pre-prepared modules maintained on several [HPC platforms](https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/using/jedi_environment/modules.html?highlight=modules). JEDI-MPAS is most commonly used on NCAR’s Cheyenne machine but it should build and run on [other HPC systems](https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/using/jedi_environment/modules.html) that have the proper dependencies installed.
* By self installing all of the dependencies using [JEDI-STACK](https://github.com/JCSDA/jedi-stack). This repository includes everything required to build the system, beginning with installation of the source code compilers.

Users clone only the MPAS-BUNDLE to get started. MPAS-BUNDLE is essentially a convenience package that will clone and build all the required JEDI-MPAS dependencies. Users can obtain this software with:

`git clone -b 1.0.0 https://github.com/jcsda/mpas-bundle`

## DOCUMENTATION AND SUPPORT

Documentation for JEDI-MPAS can be found at [jedi-docs](http://jedi-docs.jcsda.org). Users are encouraged to explore the documentation for detailed descriptions of the source code, development practices and build systems. Note that users are also encouraged to contribute to the documentation, which can be done by submitting pull requests to the JEDI-DOCS repository at https://github.com/JCSDA/jedi-docs. JEDI source code includes DOXYGEN comments and the DOXYGEN generated pages can be found under the documentation for [each component](https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/inside/jedi-components/index.html). These pages are useful for learning more about the way the software is structured. Users can also access the [JEDI Forum](https://forums.jcsda.org/c/jedi/) for questions and limited support from JEDI-MPAS developers.

## APPLICATIONS


JEDI-MPAS can run several useful applications, basic examples of which are illustrated in [tutorials](https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/learning/tutorials/index.html).  
All the applications can be configured to use any MPAS mesh, including variable-resolution and regional meshes.
The HofX application applies the forward operators from UFO, given an MPAS background forecast and a set of observations in one or more IODA files.
The Variational application performs an analysis, again given an MPAS background forecast and a set of observations in one or more IODA files. It can be configured to perform 3DVar, 3DEnVar and 4DEnVar, and to use meshes of different resolutions for the background and increment.
The EDA application conducts an ensemble of simultaneous instances of the Variational application, each taking a different background state as input, and with options for perturbing observations.
SABER’s EstimateParams application, often simply called “Parameters”, can be used to generate localization operators and static background error covariance matrix operators.


## POST PROCESSING AND VISUALIZATION

### Analysis fields

JEDI-MPAS reads and writes native MPAS files in NetCDF format.  These contain data on the [MPAS unstructured mesh](https://mpas-dev.github.io/atmosphere/atmosphere_meshes.html), which is based on centroidal Voronoi tessellations.  JEDI-MPAS produces analysis fields on this unstructured mesh for temperature, specific humidity, zonal and meridional components of velocity, and surface pressure. Optionally, mixing ratios of five hydrometeors (cloud liquid water, cloud ice, rain, snow, and graupel) can also be analyzed when assimilating cloud- or precipitation-affected observations.  The tutorial for the JEDI-MPAS [Variational application](https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/learning/tutorials/level2/envar-mpas.html) gives basic, python-based visualization examples for fields on an MPAS mesh.  The same tools also support verification against operational analyses interpolated to an MPAS mesh.


### Observations

Utilities are provided for plotting observation statistics from the data output by IODA. Use of these tools can be explored through the tutorial for the JEDI-MPAS [HofX application](https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/learning/tutorials/level2/hofx-mpas.html).

