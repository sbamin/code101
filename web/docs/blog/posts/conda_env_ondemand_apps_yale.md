---
date: 2023-11-28
categories:
  - HowTo
tags:
  - onboarding
  - hpc
  - howto
  - ondemand
authors:
  - sba
---

# Run OnDemand App with a custom conda env

Setup to run OnDemand apps on mccleary. As always, this is an overview and not an error-proof guide. Always, refer to [McCleary Docs from Yale HPC Team](https://docs.ycrc.yale.edu/clusters/mccleary/) and [Contact HPC support](https://docs.ycrc.yale.edu/) for questions.

<!-- more -->

## Command Line setup

* Login to mccleary using terminal. [Guide](https://docs.ycrc.yale.edu/clusters-at-yale/access/ssh/)
* Start an interactive job, so conda setup will not get be killed in the middle, corrupting your setup

```sh
## request 6 hours on devel partition with 4 cpus and 12G memory
srun --job-name=myinteractive --chdir=${HOME} --partition=devel --time=06:00:00 --mem=1G --nodes=1 --cpus-per-task=4 --mail-type=FAIL --export=all --pty bash --login
```

*	Once interactive job starts, you will notice a terminal prompt changing from `netid@login1or2.mccleary` to `netid@giberrish_compute_node_id.mccleary`, e.g., `netid@r209u08n02.mccleary`. Now, you are set to run conda set up as following!

*	load miniconda module with a stable version, 23.5.2 from yale hpc module library. Modules are pre-configured softwares from Yale HPC, so that you do not need to do setup/compile softwares. [Guide for Modules](https://docs.ycrc.yale.edu/clusters-at-yale/applications/modules/)

```sh
module load miniconda/23.5.2
```

*	Create a conda env with the desired name at `-n` flag in the following command, e.g., renv

>Here, we are creating a conda env using speedier `mamba` instead of `conda` command. While creating a new conda env, we ask conda to install latest R software as well as several commonly used R packages or libraries (one that starts with `r-`). We also install several other softwares to setup python language and kernels which can be useful at the later date to run OnDemand apps like Jupyter and Code Server.

```sh
mamba create -n renv r-base r-essentials r-tidyverse r-tidymodels r-devtools r-biocmanager r-pak gcc_linux-64 cmake autoconf python numpy scipy pandas matplotlib scikit-learn ipython jupyter r-irkernel
```

*	Once installation is complete, activate a new conda env. Replace `renv` below with a name of conda env you used above.

```sh
mamba activate renv
```

*	You should notice terminal prompt change from `netid@XXXXX.mccleary` to `(renv)etid@XXXXX.mccleary`, meaning now you are within conda env named, renv.
*	Once you are within a specific conda env, e.g., renv in this case, you can run R or other softwares you installed while creating conda env above. You can also install additional conda packages using `mamba install` and **NOT `mamba create`** command. The latter command is used only to create a new conda env. To find additional softwares available for conda env, go to https://anaconda.org/ and search for your R package or other softwares of interest, e.g., R packages like tidymodels, maftools, etc. or non-R softwares like bedtools, etc.
*	Make sure to use `mamba` instead of `conda` command to install packages as `mamba install` is much faster and reliable than using `conda install`.

!!! warning "Avoid installing conda packages from third-parties"
	While searching https://anaconda.org/, always rely on packages stemming from either `conda-forge` or `bioconda` as those two are reliable software repositories and well-maintained. Never install conda packages from third-party developers.

	To avoid breaking your conda env, worth reading [a detailed conda setup guide](https://code.sbamin.com/hpc/cpu/sumner_2/). Do not copy and paste commands but rather read and understand rationale behind maintaining a stable, error-free, conda env.


*	Finally, create a file called `~/.condarc` on HPC and copy-paste following contents in it. You can use Files section from [OnDemand dashboard](https://ood-mccleary.ycrc.yale.edu/pun/sys/dashboard) and navigate to Home directory and create a file, `/.condarc`. Alternately, on command-line terminal, you can run `nano ~/.condarc` to create and edit file. [See nano guide](https://linuxize.com/post/how-to-use-nano-text-editor/)

```
#### YCRC suggested condarc config ####
env_prompt: '({name})'
auto_activate_base: false
channels:
  - conda-forge
  - bioconda
  - defaults
#### Additional config ####
auto_update_conda: False
always_yes: False
add_pip_as_python_dependency: True
ssl_verify: True
allow_softlinks: True
use_only_tar_bz2: False
anaconda_upload: False

repodata_threads: 4
verify_threads: 4
execute_threads: 4
```

## Using OnDemand Apps

For loading your custom conda env in OnDemand apps like RStudio Server and Code Server, you need to set a custom user module, such that OnDemand can recognize this module and load it **prior** to starting OnDemand Apps.

*	Create a directory where you can install/manage your modules. These modules are on top of modules managed by Yale HPC. [Guide for Modules](https://docs.ycrc.yale.edu/clusters-at-yale/applications/modules/)

```sh
mkdir -p /gpfs/gibbs/pi/labid/"${USER}"/hpcenv/opt/modules
```

*	Edit your `~/.bash_profile` file on HPC and add following.

```sh
module use --prepend /gpfs/gibbs/pi/labid/"${USER}"/hpcenv/opt/modules
```

*	Now, create a modulefile directory, named `renv` or the name of conda env you like to use in OnDemand App.

```
mkdir -p /gpfs/gibbs/pi/labid/"${USER}"/hpcenv/opt/modules/renv
```

*	Under `renv/` directory, create a modulefile named `1.0.lua` (our first version of this module) and add following contents to it.


!!! tip "module directory name, `renv` must match conda env"
	Ensure that module file, `1.0.lua` is under a directory that is named exactly as the name of conda env you are trying to load, e.g., `renv/1.0.lua` will assume that you are trying to load conda env, *renv*.

```lua title="<path_to_user_modules>/renv/1.0.lua"
help([==[

Description
===========
Preload config for OnDemand Apps: Code Server and RStudio server.

Note that this module, if loaded at the start of OnDemand VSCode or RStudio server, will be loaded
silently prior to initializing code-server.

module list command may not show this module as being loaded but the module configs should have
already be applied to user env, e.g., PATH, LIBRARY_PATH, etc. should show directives set as per this module.

Much of config for this file rely on upstream config from Yale HPC module for miniconda:
/vast/palmer/apps/avx2/modules/tools/miniconda/

More information
================
	+ Yale HPC Guide: https://docs.ycrc.yale.edu/
	+ Module file: https://lmod.readthedocs.io/en/latest/
	+ Working with HPC: https://code.sbamin.com/hpc/

]==])

whatis([==[Description: Preload config for OnDemand Apps: RStudio Server and Code Server.]==])
whatis([==[URL: https://docs.ycrc.yale.edu/]==])
whatis([==[URL: https://code.sbamin.com/hpc/]==])

-- Module Name and Version are parsed by Lmod from dir/version string in module path
-- REVIEW: ensure that this module file is under a directory that is named
-- exactly as the name of conda env you are trying to load, e.g.,
-- renv/1.0.lua will assume that you are trying to load conda env, renv
local pkgName = myModuleName()
local version = myModuleVersion()
local pkgNameVer = myModuleFullName()

--other modules
-- load("module_name/version_id")

-- following bash variable will be visible once you start rstudio server or
-- code server. Run command:
-- echo ${my_vscode} from rstudio or code server to ensure you have loaded
-- this module.
pushenv("my_vscode", "1.0")

-- NOTE: Preferably should use depends_on and/or prereq for module loads
-- and not concatenate using bash && directive.
execute{cmd="module load miniconda && conda activate "..pkgName, modeA={"load"}}
execute{cmd="conda deactivate && module unload miniconda", modeA={"unload"}}

-- end --
```

## Test run

* Exit all of sessions from terminal by `exit` and closing ondemand sessions, if any.
* Login again to McCleary using ssh or [OnDemand terminal interface](https://ood-mccleary.ycrc.yale.edu/pun/sys/dashboard) under Clusters > McCleary Shell Access.

*	Start an interactive session as above.
*	Activate your new conda env via module you just created.

```sh
module load renv/1.0
```

*	Check if module is loaded or not with `module list` command which will show, both, `miniconda` and `renv` modules loaded!
*	Run `R` or `python` and you should see those running.
*	Also check `R --version` and note that version.
*	Once done, unload module using `module unload renv/1.0` and then check with `module list`. Both, `miniconda` and `renv` should disappear now!

### OnDemand Apps

Once module test run is working ok, open [OnDemand terminal interface](https://ood-mccleary.ycrc.yale.edu/pun/sys/dashboard) and under [Interactive Apps menu](https://ood-mccleary.ycrc.yale.edu/pun/sys/dashboard/apps/index), click **RStudio Server** and NOT Rstudio Desktop.

*	Pick R version that is closest to one you noted above in the test run. Ideally, it should not deviate too much, e.g., if test run R version is 4.4 but available R versions in OnDemand Apps have only R 4.2 or R 4.3, ask HPC to install a new R for OnDemand Apps. If R version is 4.3.2 for your test run but OnDemand App has R 4.3.0, that's ok.
*	Select number of hours, cpus, memory, and [choose partition accordingly](https://docs.ycrc.yale.edu/clusters/mccleary/#partitions-and-hardware).
*	Under **Additional modules (optional)** option, type `renv/1.0` or whichever module you just created above. If additional modules option is not visible, check `Check the box to view more options` option.
*	Launch OnDemand App.

Once OnDemand apps launches, open terminal from RStudio or code server, and ensure that your module is loaded by checking output of `module list`.
