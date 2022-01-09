---
title: "Setting up CPU env - Part 2"
description: "Sumner HPC Setup 2021: Part 2"
keywords: "sumner,hpc,conda,bash,jupyter,programming"
---

Following up from [Part 1: Initial HPC setup](../sumner_1/), we now start installing essential softwares or (in conda dictionary) packages, e.g., R, Jupyter, etc.

```sh
## login back to HPC
ssh userid@login.sumner.jax.org

## start screen
screen

## start interactive session
srun -p compute -q batch -N 1 -n 4 --mem 10G -t 08:00:00 --pty bash

## unload gcc if loaded
module unload gcc
```

!!! danger "☠️ Keep a note of walltime ☠️"
    Make sure you do not run over alloted walltime while configuring conda env, especially when you are in the middle of installing via `mamba install` or `mamba update` command, and walltime dies out! (speaking from an experience) and that may break an ongoing conda setup.

    conda is good in a way that it locks process files for package(s) it is trying to install or update. If you are lucky, you should be able to save your ongoing setup else start again! Just read errors you may encounter during such issue and it should resolve such issue.

## Configuring conda env

Typically, we use `conda` command to manage all of conda env, e.g., `conda install package`, `conda update package`, `conda list`, etc. However, we will now use `mamba` instead of `conda`. [Mamba](https://github.com/mamba-org/mamba) is a faster drop-in replacement for `conda` to manage packages.

!!! tip "Use `mamba` instead of `conda`"
    Moving forward, do not forget to use `mamba` instead of `conda` for all of available commands. See `mamba --help` to list available commands. At present, following commands from `conda` are supported by `mamba`: install, create, list, search, run, info and clean. For rest of commands, e.g, config, activate, deactivate, etc., use `conda` command.

    Turns out `mamba activate <env_name>` or `mamba deactivate` also works following one-time command: `mamba init` which will ensure sourcing mamba shell variable at the bash startup by writing a few lines towards the end of _~/.bashrc_ file. **Please note** to execute `mamba init` after `conda init` as in [Part 1: Initialize conda](../sumner_1/#install-conda). This will ensure at the bash startup sequence to load conda setup prior to mamba setup. If you end up running `mamba init` now (I ended up running it late in the setup), prefer activating or deactivating conda env using `mamba` and not `conda` command.

It is important to install packages only from a single channel and not do mix-and-match install. Read more at [conda-forge page](https://conda-forge.org/docs/user/tipsandtricks.html) on `channel_priority: strict` which is enabled as default for conda v4.6 or higher. We are using conda v4.10.3 and anaconda v2021-11. We can check that using `conda --version` and `conda list anaconda` respectively.

*   Add Bioconda and conda-forge channels to get updated and compbio related packages. **Do not** change the order of following commands and a command with `--add channels conda-forge` must be the last one else other channels may take a priority over default `conda-forge` channel.

```sh
conda config --add channels bioconda
conda config --add channels conda-forge
```

Above command will generate `~/.condarc` file and sets priority for channels, i.e., when same package is available from more than one channels, we prioritize installation per ordered channel list in `~/.condarc` file as below. This file should be present after above commands and no need to edit unless changing priority of channels.

!!! tip "precedence of _condarc_ file"
    Since we are using Mambaforge and not anaconda3, it already ships with conda-forge as a default channel, as specified in `cat "${CONDA_PREFIX}"/.condarc`. Note that _~/.condarc_ will [take precedence over default](https://docs.conda.io/projects/conda/en/latest/user-guide/configuration/use-condarc.html) _"${CONDA_PREFIX}"/.condarc_ file, so ensure that `conda-forge` is the most preferred channel (first channel) in both files.

*   Besides channel priority, I have added a few other custom settings to my _~/.condarc_ file. For more on these settings, please [refer to condarc documentation](https://docs.conda.io/projects/conda/en/latest/user-guide/configuration/use-condarc.html) before applying to your own HPC env.

>_~/.condarc_ is a yml format file, so take care of preceding spaces (and not tabs) before and after `-` while editing this file.

```yaml
channels:
  - conda-forge
  - bioconda
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


!!! danger "Do not exceed requested resources for an interactive job"
    If you increase number of threads for conda operations, make sure that you request required threads for an interactive HPC job else you may consume more resources than requested threads, and HPC workload manager may kill your interactive job - conda env can potentially break if interrupted during install or update command.

*   You can verify custom set _~/.condarc_ configurations using `conda config --get` command. If some of key:value pairs are showing warnings saying _unknown key_, you should remove those entries from _~/.condarc_.

>If channel priority has been set as above, you will notice `--add channels 'conda-forge'   # highest priority` from the output of `conda config --get` command.

## Update conda package

*   Since we used Mambaforge, anaconda3 variant from a third-pary [conda-forge](https://conda-forge.org) open-source community, let's make sure that the base `conda` package is the most up-to-date or not.

```sh
conda --version
```

>conda 4.10.3

*   To check if this is the current version, we will update `conda` package. 

```sh
mamba update conda
```

>You may notice that conda update is available else no further action needed. Notice source of updated conda package from _conda-forge/linux-64_. That is because we set _conda-forge_ with the highest channel priority in _~/.condarc_. 

```
  - conda       4.10.3  py39hf3d152e_2  installed                      
  + conda       4.11.0  py39hf3d152e_0  conda-forge/linux-64      17 MB
```

*   Confirm that conda package is now updated with an updated version, if any.

```sh
conda --version
```

>conda 4.11.0

## JupyterLab

For most packages, e.g., R, snakemake workflow, etc., we will use dedicated conda env and avoid installing into base env. That is to keep base env clean and without much of dependencies. Unlike base env, additional env can be recreated without a risk of breaking conda setup. However, we will require a few packages, e.g., JupyterLab and Notebook, that typically ships with regular (and not miniconda or mambaforge) anaconda3 installation.

??? tip "Install JupyterLab in its own conda env"
    If you prefer, you can skip installing JupyterLab in _base_ env and instead use its own dedicated env. This is perhaps a preferred way to keep _base_ env minimal and also allows you to update JupyterLab from time to time without worrying about breaking _base_ env. However, when you start jupyterlab session, you need to switch (activate) to the respective conda env from _base_ or other envs.

    To install jupyterlab in its dedicated env, do following:

    ```sh
    mamba create -c conda-forge -n jlab jupyterlab nodejs jupyterthemes jupytext dos2unix jupyter_http_over_ws jupyterlab-link-share
    
    mamba activate jlab

    ## check installed extensions, if any
    jupyter lab extension list
    jupyter server extension list
    ```
    
    Read install guide for extensions, if any, e.g. some extensions like jupyter_http_over_ws are not enabled by default for good (saftey) reasons.

*   [JupyterLab](https://jupyter.org) is similar to RStudio IDE and provides richer interface to several programming languages, including python, R, julia, and many more. To install jupyterlab, [please read installation guide](https://jupyterlab.readthedocs.io/en/stable/getting_started/installation.html).

```sh
## core package
mamba install -c conda-forge jupyterlab
```

>Even though conda-forge is set as the highest priority channel in _~/.condarc_, I am explicitly specifying to use the same channel while running install or update command.

>This will install jupyterlab and series of its dependencies. You can check version of related packages using `mamba list | grep -E "jupyter"` although versions may differ as they get updated over time.

```
# packages in environment at /projects/verhaak-lab/amins/hpcenv/mambaforge:
#
# Name                    Version                   Build  Channel
jupyter_client            7.1.0              pyhd8ed1ab_0    conda-forge
jupyter_core              4.9.1            py39hf3d152e_1    conda-forge
jupyter_server            1.12.1             pyhd8ed1ab_0    conda-forge
jupyterlab                3.2.4              pyhd8ed1ab_0    conda-forge
jupyterlab_pygments       0.1.2              pyh9f0ad1d_0    conda-forge
jupyterlab_server         2.8.2              pyhd8ed1ab_0    conda-forge
```

*   **Optional:** I have also installed following set of packages in the base env for my own needs or convenience for not switching to other conda environments. If you do so, try to limit installing packages in base env to bare minimum, and avoid installing packages that require multiple dependencies, e.g., R, tensorflow, node, julia, GO library, etc.

```sh
mamba install -c conda-forge git rsync vim globus-cli tmux screen
```

We will setup rest of jupyterlab settings and initialize it later after we install R in a separate conda env.

## Installing R

We will install R and other routinely used tools in a separate conda env for reasons explained above. You should [read official documentation on installing R](https://docs.anaconda.com/anaconda/user-guide/tasks/using-r-language/) to familiarize with steps that I am going to follow below.

### Create a new env

I am going to name a new env as ***yoda***. Ideally, naming should be such that you should not have difficulty finding which env to switch to for the type of packages and analysis you may end up running at the later date, e.g., in my case, while far from ideal, I have used nomenclature based on :fontawesome-solid-jedi: [the Jedi members](https://en.wikipedia.org/wiki/Jedi) for conda env:

| env id | intended use |
| -- | -- |
| yoda | hosts all packages, including R and others that I use on daily basis |
| luke | serves as an env for background processes using databases |
| leia | a standalone env for [running snakemake](https://snakemake.readthedocs.io) workflows |
| obiwan | fallback to _yoda_ when I require to use another mature version of R or other packages |
| windu | conda env using legacy Python 2 over Python 3 |
| anakin | dev or beta env for testing: Optimized for CPU-based HPC |
| rey | Similar to yoda but optimized for GPU-based HPC |
| ben |  dev or beta env for testing: Optimized for GPU-based HPC |
| grogu | toy env for everything else: for experimental purpose |

>_rey_ and _ben_ env are optimized for GPU-based, *Winter* HPC at JAX and should not be used while working in the CPU-based, *Sumner* HPC at JAX. However, all of CPU-based envs, e.g., _yoda, luke, leia_, etc. will work on both, Sumner and Winter HPCs.

*   Let's create the first env, _yoda_ and install base R package and a several essential R packages for routine analysis.

```sh
mamba create -c conda-forge -n yoda r-base r-essentials
```

>Note that most up-to-date R version may be available in the _conda-forge_ or sometimes in the other conda channels, like _r_ or _bioconda_. However, **it is preferable to install R from the first priority channel**, i.e., _conda-forge_ in our case.

*   Activate a new env. Note that we use `conda` instead of `mamba` command as the latter (at least for now) only accepts following sub commands: install, create, list, search, run, info and clean.

```sh
conda activate yoda
```

>You will notice bash prompt changing from `(base) [userid@sumner50]` to `(yoda) [userid@sumner50]`.

### Pin R and conda auto-updates

*   Before moving further, let's [pin R version](https://stackoverflow.com/a/48733093/1243763 "how to fix software versions in conda environment - stackoverflow") to 4.1.1 (at the time of this writing) and also disallow conda auto-updates. That way, we have lesser chances of breaking conda env when we do `mamba install <pkg>` in future, and carefully install/update packages without breaking existing setup. For more on pinning packages, [read official documentation](https://conda.io/projects/conda/en/latest/user-guide/tasks/manage-pkgs.html#preventing-packages-from-updating-pinning).

!!! note "Technical note"
    Typically, I avoid installing or updating package if `mamba install` throws a message or warning about **removing or downgrading existing packages**. In such cases, I fall back to [compiling package using available devtools in conda](https://docs.conda.io/projects/conda-build/en/latest/resources/compiler-tools.html). Also, I load compiled package using *Modulefile* when needed, and not integrate it in my default bash environment as this may give errors while running some random program due to conflicts in shared library versions.

```sh
## we already set auto update to False above
## under ~/.condarc settings
# conda config --set auto_update_conda False

# Find package version using
mamba list | grep -Ei 'r-base'
```

*   We can notice that R version is 4.1.1 (or higher). You can also check R version by `R --version`. Remember this version and add it to following newly created file:

```sh
nano "${CONDA_PREFIX}"/conda-meta/pinned
```

>Note that `echo ${CONDA_PREFIX}` points to _conda-meta/_ directory under _yoda_ and not the _base_ env because we are within _yoda_ env. In other words, pinned packages env specific and you can update R package in other environment(s), if present.

*  Add following as a new line entry:

```
r-base ==4.1.1
```

??? info "Check a valid line break"
    Since we are creating a new file and only adding a single line of text, when we save this text file, we should confirm that it is the [end of the line](https://en.wikipedia.org/wiki/Newline). This is usually recognized by pressing the ++enter++. Unix systems recognizes such line break using an invisible `$` sign which you can confirm by running `cat -e "${CONDA_PREFIX}"/conda-meta/pinned`

    ```
    r-base ==4.1.1$
    $
    ```

    With each line break, you will notice `$` sign, e.g., two lines in my case. You may remove a second line by editing file again but make sure to run `cat -e "${CONDA_PREFIX}"/conda-meta/pinned` to check a valid line break.

You may [pin](https://conda.io/projects/conda/en/latest/user-guide/tasks/manage-pkgs.html#preventing-packages-from-updating-pinning) only part of [the major and minor version](https://en.wikipedia.org/wiki/Software_versioning), i.e., to allow updates from 4.1.1 to 4.1.2 or 4.1.3 but not from 4.1.1 to 4.2.*. However, I rather freeze the specific version and update to builds at the later date, if need arises. To do so, remove the pinned entry from `"${CONDA_PREFIX}"/conda-meta/pinned` and do `mamba update r-base=4.1.2` or other version. Since [R developer team](https://cran.r-project.org/doc/manuals/r-release/NEWS.html) updates [major.minor version](https://en.wikipedia.org/wiki/Software_versioning) of R every quarter or so, I try to keep those R versions in a separate env rather updating as certain R packages may throw an error with such major updates.

### Install R libraries

You may now install additional R libraries (or packages - it's alias!) or any other packages, e.g., git, bedtools, samtools, etc. in the new env using `mamba install` command. Just make sure that you are in the new env by `conda activate yoda`. You can check which env you are in by `echo "$(basename ${CONDA_PREFIX})"`

>Some of packages, e.g., git, rsync, etc. are already installed in the base env. However, they may not be recognized in the new env: _yoda_. Ideally, you should install the same package in the new env. Conda will usually link package files (which takes much of space) from the central package directory, so installing the same package in different env should not take significant additional space.

To search for packages, prefer using [anaconda website](https://anaconda.org/) and look for packages that are under _conda-forge/_ or _bioconda_ channels, i.e., the first and second preference, respectively in our _~/.condarc_ file.

!!! warning "Avoid installing packages from non-standard channels"
    For a stable and error-free conda env, avoid installing conda packages from non-standard channels, i.e., a channel other than conda-forge and bioconda or ones specified in _~/.condarc_ file. Installing packages from non-standard channels will unnecessarily increase complexity of package dependencies in conda env and will increase likelihood of slowing or breaking down one or more conda env. Note that we have yet to create additional conda env besides a default base env.

*   Install R packages: You can tie up all of your packages in a single command or break it down to smaller chunks. The former appraoch may take longer and difficult to debug if package installation fails due to conflicting dependencies with one or more packages.

```sh
mamba install -c conda-forge r-tidyverse r-tidymodels r-devtools r-biocmanager
mamba install -c conda-forge gnupg git rsync vim openjdk r-rjava
mamba install -c conda-forge bedtools pybedtools bedops
mamba install -c conda-forge matplotlib scikit-learn
```

*   Reticulate and rpy2 packages will allow us to use R and python interchangeably in the same R script or python notebook, respectively! [Read details about reticulate on RStudio website](https://rstudio.github.io/reticulate/) and [rpy2 here](https://rpy2.github.io/).

#### reticulate R package

```sh
mamba install -c conda-forge r-reticulate
```

#### rpy2 python package

```sh
mamba install -c conda-forge rpy2
```

If above command works without forcing you to downgrade python, R, or other major packages, good for you! If not, it is due to [strict requirements](https://github.com/rpy2/rpy2/blob/master/setup.py) of rpy2 package which can conflict with other core packages in _yoda_ env. So, `mamba install -c conda-forge rpy2` may not work.

!!! danger "☠️ Beware of using `pip install` in conda env ☠️"
    You should be comfortable compiling and installing packages using `pip install` and knowing how to manually install python package requirements. If not, it is safer to skip installing rpy2 (or any other) package by steps detailed below. Wait until _conda-forge_ developers make rpy2 package available. _conda-forge_ developer community is pretty good and active, so patience should pay off then risking to break an otherwise functioning _yoda_ env!

*   From [rpy2 setup.py and requirements.txt](https://github.com/rpy2/rpy2) file, list number of packages required as dependencies for rpy2.

>If we do `pip install rpy2`, pip will automatically install these requirements. However, I prefer to let conda manage all package versions because **pip may not necessarily evaluate if certain package versions are compatible with other conda-installed packages**. That's why I prefer installing requirements by myself using `mamba install` and then do `pip install`, so only minimal set of requirements will be installed by pip command. That way, I can minimize chances of breaking conda env due to conflicting package dependencies.

```sh
## required packages by rpy2
## see how many of these are already installed
conda list | grep -E "cffi|pytest|pandas|numpy|jinja2|pytz|tzlocal"
```

*   Install missing packages using `mamba`.

```sh
## ok to write packages which are already installed
## conda will take care of version conflict, if any.
mamba install -c conda-forge cffi pytest pandas numpy jinja2 pytz tzlocal
```

*   Now try (fingers crossed!) installing rpy2 using pip. Make sure that [rpy2 pip website](https://pypi.org/project/rpy2/) is showing same version (3.4.5 in my case) as on [rpy2 github website](https://github.com/rpy2/rpy2) else you need to download source file from pip website, and check respective _setup.py_ and _requirements.txt_ file to ensure dependencies are identical and satisfied or installed via `mamba install` command.

```sh
## in yoda env
mkdir - ~/logs && \
pip install rpy2 |& tee -a logs/pip_install_rpy2.log
```

??? info "Success installing rpy2"
    Great! `pip install` did not end up installing any dependencies (as we already installed those using `mamba install`), and rpy2 is now successfully installed.

    ```
    Collecting rpy2
      Downloading rpy2-3.4.5.tar.gz (194 kB)
      Preparing metadata (setup.py): started
      Preparing metadata (setup.py): finished with status 'done'
    Requirement already satisfied: cffi>=1.10.0 in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/python3.10/site-packages (from rpy2) (1.15.0)
    Requirement already satisfied: jinja2 in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/python3.10/site-packages (from rpy2) (3.0.3)
    Requirement already satisfied: pytz in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/python3.10/site-packages (from rpy2) (2021.3)
    Requirement already satisfied: tzlocal in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/python3.10/site-packages (from rpy2) (4.1)
    Requirement already satisfied: pycparser in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/python3.10/site-packages (from cffi>=1.10.0->rpy2) (2.21)
    Requirement already satisfied: MarkupSafe>=2.0 in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/python3.10/site-packages (from jinja2->rpy2) (2.0.1)
    Requirement already satisfied: pytz-deprecation-shim in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/python3.10/site-packages (from tzlocal->rpy2) (0.1.0.post0)
    Requirement already satisfied: tzdata in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/python3.10/site-packages (from pytz-deprecation-shim->tzlocal->rpy2) (2021.5)
    Building wheels for collected packages: rpy2
      Building wheel for rpy2 (setup.py): started
      Building wheel for rpy2 (setup.py): finished with status 'done'
      Created wheel for rpy2: filename=rpy2-3.4.5-cp310-cp310-linux_x86_64.whl size=300939 sha256=136144e165e2b0f156fdb7f525547ae073dda06346a893de398aa6836e625af1
      Stored in directory: /home/amins/.cache/pip/wheels/ba/d8/8b/68fc240578a71188d0ca04b6fe8a58053fbcbcfbe2a3cbad12
    Successfully built rpy2
    Installing collected packages: rpy2
    Successfully installed rpy2-3.4.5
    ```

*   Since we just installed JAVA (openjdk) and rJava R library, for sanity check, run `R CMD javareconf` (to print and update java configuration for R) and `echo $JAVA_HOME` (to confirm that bash variable is correctly set).
*   If you also have installed git, you can copy boilerplate :octicons-file-code-16: [~/.gitconfig]({{ repo.url }}{{ repo.blob }}/confs/hpc/user_env/.gitconfig), and make changes under line starting with name, email, and excludesfile. Make sure to [read about gitconfig](https://git-scm.com/docs/git-config) too.

!!! tip "Best practices using `mamba install` or `mamba update`"
    Keep a habit of checking following when using `mamba install` command:

    - [ ]   Prefer _conda-forge_ channel, followed by _bioconda_, and avoid installing packages from other channels. You can do so in dev or beta env, e.g., env _grogu_ in my case to see how it pans out.
    - [ ]   Before hitting `Y/Yes` to install packages, ensure that installing or updating packages does not force **downgrading** of one or more major packages, like python, R, and any other packages that you deem it as major package in your routine analysis and downgrading it may break reproducibility of your analysis. You can always use dev env, like _grogu_ to play packages showing such downgrade warnings.

While doing `mamba install -c conda-forge samtools bcftools htslib`, I noticed `openssl` dependency being downgraded from v3.0.0 to v1.1.1. I find it a major downgrade to one of the core package and so I skipped installing samtools and  related packages using `mamba`. I would rather install these packages by compiling from their respective source tar balls. You can [read installation details for samtools family packages at author's website](http://www.htslib.org/download/).

Similarly for `mamba install -c conda-forge bedtools pybedtools bedops`, I got following error as _yoda_ env is using python 3.10 and it is pinned by default. So, it can not be downgraded! Similar to samtools, I will compile pybedtools or use a separate env, like _grogu_ for such packages with *unique* requirements! For `bedops`, it was asking me to install older version of samtools which I was not ok with. I will rather compile those tools from the current version. So, finally I ended up installing only bedtools with clean requirements! `mamba install -c conda-forge bedtools`.

```
package pybedtools-0.8.2-py39h39abbe0_1 requires python >=3.9,<3.10.0a0, but none of the providers can be installed
```

### Setup Rprofile and Renviron

Rprofile and Renviron files provide additional configuration option for R, similar to _~/.condarc_ file to manage several conda-related configurations. You can read more about these files at [R developer website](https://cran.r-project.org/web/packages/startup/vignettes/startup-intro.html) and [RStudio website](https://support.rstudio.com/hc/en-us/articles/360047157094-Managing-R-with-Rprofile-Renviron-Rprofile-site-Renviron-site-rsession-conf-and-repos-conf). For detailed notes, Jennifer Bryan and Jim Hester has written an excellent resources, titled [_What they forgot to teach you about R_](https://rstats.wtf/) with a chapter on [R Startup](https://rstats.wtf/r-startup.html).

*   Setup R library directory path for R 3.6

Before setting up R startup, I will make a dedicated package directory that will store R libraries or packages. By default, R will store all libraries at conda env specific path, i.e., for my case, it is at *"${CONDA_PREFIX}"/lib/R/library/*. You can check this path using `Rscript -e '.libPaths()'`. This default path is ideally intended for R libraries managed via `mamba install` or `mamba update` command. However, I also compile R libraries using `install.packages()` R command when I find conflicting dependencies in installing R libraries using `mamba install` command. In such cases, I prefer to use a separate R library directory than a default R library path.

>I am making an empty library directory for installing libraries or R packages that I may compile using R `install.packages()` command. R usually defaults to making such user-package directory in the user's home path but I will use tier 1 space again to avoid filling up my home directory with a limited quota.

```sh
mkdir -p /projects/verhaak-lab/amins/hpcenv/opt/R/pkgs/4.1
```

*   Create _~/.Renviron_ file

```sh
nano ~/.Renviron
```

>Add following to _~/.Renviron_. Notice the order in which R will store newly compiled packages. It will use an empty directory we just created to store new packages. If for some reasons, this directory is not accessible (file permission errors), R will fallback to the second path, and so on. The second path is an expanded path of a default R package directory, i.e., output of `echo _"${CONDA_PREFIX}"/lib/R/library/_` command.

```sh
R_LIBS="/projects/verhaak-lab/amins/hpcenv/opt/R/pkgs/4.1:/projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/R/library"
```

>You can confirm precedence of R library paths in R using `.libPaths()` R command or from bash using `Rscript -e '.libPaths()'`.

*   Create _~/.Rprofile_ file

```sh
nano ~/.Rprofile
```

>Add following contents. Please read more about configuring R startup from links shared earlier in this section. Comment out lines using `#` if you do not require one or more of following options.

```r
## set user specific env variables, e.g., GITHUB_PAT here
Sys.setenv("GITHUB_PAT"="my_github_secret_token")

## Default source to download packages
local({
  r <- getOption("repos")
  r["CRAN"] <- "https://cran.rstudio.com"
  options(repos = r)
})
```


??? tip "Protect secret tokens, passwords, etc."
    If your _~/.Rprofile_ file contains any secret tokens, it's a best practice to make it read/write only by file owner (you) using `chmod 600 ~/.Rprofile`. Same goes for similar files in your home directory, e.g., _.gitconfig_, _.netrc_, etc. Equivalent command for directory, e.g., for _.ssh/_ is `chmod 700 ~/.ssh`. [Read more about linux file permissions](https://www.linux.com/training-tutorials/understanding-linux-file-permissions/).

### Compiling R libraries

Since we already have setup _yoda_ env for R, you can now install additional R libraries using `mamba install r-PackageName` ([see above](#install-r-libraries)) as long as it is available in [anaconda repository](https://anaconda.org/), preferably in _conda-forge_ or _bioconda_ sources AND it does not significantly downgrades essential packages like python, R, and other core libraries, e.g., zlib, openssl, etc. The latter is subjective and depends on what you will consider as an essential. In any case where I have doubts of breaking conda env, I fall back to compiling R library using native R command: `install.packages()`. However, I am going to wait using this command until I have finished my HPC setup, specifically, **bash startup** using _~/.profile.d_ configuration. We are not there yet but not far from it too!

## Install essentials

This can again vary per user's need and optional. If you find errors compiling packages, you may end up installing respective dev libraries, e.g., libiconv, zlib, etc. if they are not already installed in the current (_yoda_ in this case) conda env.

```sh
mamba install -c conda-forge wget curl rsync libiconv parallel ipyparallel
```

## Setup JupyterLab

We have installed JupyterLab [earlier](#jupyterlab) but did not finish complete setup. Let's do that!

In this section, I will setup jupyter notebook and kernels to launch python, R, and bash based notebooks. I will also harden notebook server with several security settings.

Remember that we will be using JupyterLab installation from the conda _base_ env even though JupyterLab could have been installed in _yoda_ and other conda env. Managing jupyterlab server from _base_ env is convenient and allows us to interact with all other env. Also, if we end up resetting or deleting other env, jupyter configuration in _base_ env will remain intact. 

First, we install language-specific kernels. By default, jupyterlab ships with python kernel, named ipykernel which is backend when we interact with jupyter python notebook. Jupyter can allow us to use other language-specific kernels to interact with R, Julia, bash, and [many more languages](https://jupyter.org/try). Accordingly, I will install kernels for R and bash in specific envs, e.g., _yoda_ and then switch back to _base_ env to configure jupyterlab, such that we can connect to kernels in _yoda_ env from conda _base_ env.

*   Make sure you are in _yoda_ env. We will switch to _base_ env after we configure all kernels in _yoda_ env.

```sh
conda activate yoda
```

*   Install kernels

```sh
mamba install -c conda-forge ipykernel r-irkernel bash_kernel
```

>Note that I have also installed python kernel, ipykernel in _yoda_ env as we may not have jupyterlab installed in _yoda_ as we only need to install jupyterlab in the _base_ env.

>Also, some of kernels may already have been downloaded as part of dependency for other packages we installed earlier. You can check `conda list | grep kernel` output to confirm which kernels are already installed.

Now we can link each of these kernels to jupyterlab in _base_ env. 

### python kernel

```sh
python -m ipykernel install --user --name yoda_py310 --display-name "yoda_py310"
# confirm that installation exited without any error
echo $?
# this should return 0 for successful installation
```

>--name and --display-name will show up as kernel file location at _~/.local/share/jupyter/kernels/_ and icon name in the jupyterlab launcher page, respectively. You can name as you like but without any spaces or special characters. I am following naming format that uses env followed by language and its major and minor version.

### R kernel

*    Start R session

```sh
R
```

*   Install kernel while in _yoda_ env

>[Read available options](https://irkernel.github.io/installation/) for IRkernel installation. Also, consider installing [jupytertext-text-shortcuts](https://github.com/techrah/jupyterext-text-shortcuts) but **not now** and we can install this along with other extensions towards the end of configuring jupyterlab.

```r
library(IRkernel)
installspec(name = "yoda_r41", displayname = "yoda_r41", user = TRUE)

## quit R session
q(save = "no")
```

>Similar to python kernel, r kernel should now be at _~/.local/share/jupyter/kernels/_.

### bash kernel

Stay in _yoda_ env.

```sh
python -m bash_kernel.install
```

*   Unlike python and R kernels, I could not find overriding default name and display_name for bash kernel. So, I will rename bash kernel manually else if I end up installing similar kernel from other env, it will override kernel with the same default name: _bash_. Typically, you do not need to install _bash_ kernels in all conda env as jupyterlab ships with a powerful terminal that allows switching from one to other env using same `conda activate` command. So, I hardly use bash kernel.

```sh
## go to kernel base dir
cd ~/.local/share/jupyter/kernels/

## rename bash dir to yoda_bash
mv bash yoda_bash

## edit bash kernel.json to rename display name
cd yoda_bash
nano kernel.json
```

>Rename `"display_name": "Bash"` to `"display_name": "yoda_bash"`

### kernel loading

Following completion of the entire setup, we are going to run JupyterLab from the _base_ env. However, on daily basis, we like to access Python and R from _yoda_ and not _base_[^noRinbase]. Default kernel setup above should let jupyterlab handle conda env specific python but not so for other kernels.

However, I have noticed issues running Python and R from a non _base_ conda env as sometimes packages requiring shared libraries may throw an error as such shared libraries are either missing in _base_ env or have a different version than one in the current env, i.e., _yoda_ env where package was originally installed or compiled.

I mitigate such issues by **loading a valid bash env prior to initializing kernel**, e.g., I will wrap a default jupyter kernel settings into a bash script (wrapper) and will activate a valid conda env, e.g., _yoda_ in this case prior to initializing _yoda_ specific Python or R kernel. That way, kernel will consistently inherit a valid login (bash) env for the respective conda env.

[^noRinbase]: Notice that there is no R in the _base_ env. So, hitting R will not start R session unless you do `mamba activate yoda`!

#### yoda python

*   Create a new kernel wrapper matching name of kernel we like to edit, e.g., _/projects/verhaak-lab/amins/hpcenv/opt/kernels/wrap_yoda_py310_

```sh
mkdir -p /projects/verhaak-lab/amins/hpcenv/opt/kernels
touch /projects/verhaak-lab/amins/hpcenv/opt/kernels/wrap_yoda_py310

# make file executable
chmod 700 /projects/verhaak-lab/amins/hpcenv/opt/kernels/wrap_yoda_py310
```

*   Add following to _wrap_yoda_py310_ file. Change user paths where applicable.

```
#!/bin/bash

## Load env before loading jupyter kernel
## @sbamin

## https://github.com/jupyterhub/jupyterhub/issues/847#issuecomment-260152425

#### Activate CONDA in subshell ####
## Read https://github.com/conda/conda/issues/7980
# I am using conda instead of mamba to activate env
# as somehow I notices warnings/errors sourcing
# mamba.sh in sub-shells.
CONDA_BASE=$(conda info --base) && \
source "${CONDA_BASE}"/etc/profile.d/conda.sh && \
conda activate yoda
#### END CONDA SETUP ####

# this is the critical part, and should be at the end of your script:
exec /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/bin/python -m ipykernel_launcher "$@"

## Make sure to update corresponding kernel.json under ~/.local/share/jupyter/kernels/<kernel_name>/kernel.json

#_end_
```

*   Now, adjust kernel settings.

```sh
## go to kernel base dir
cd ~/.local/share/jupyter/kernels/

## there should be yoda_py310 directory or
## one matching --name yoda_py310 argument
## we used above when installing python kernel
cd yoda_py310

## edit kernel.json
nano kernel.json
```

*   Replace contents of _kernel.json_ with following:

```json
{
 "argv": [
  "/projects/verhaak-lab/amins/hpcenv/opt/kernels/wrap_yoda_py310",
  "-f",
  "{connection_file}"
 ],
 "display_name": "yoda_py310",
 "language": "python",
 "metadata": {
  "debugger": true
 }
}
```

#### yoda R

Now, we can reconfigure R kernel for _yoda_ same as above but with a few changes in the wrapper script.

*   Create a new kernel wrapper for R, e.g., _/projects/verhaak-lab/amins/hpcenv/opt/kernels/wrap_yoda_r41_

```sh
mkdir -p /projects/verhaak-lab/amins/hpcenv/opt/kernels
touch /projects/verhaak-lab/amins/hpcenv/opt/kernels/wrap_yoda_r41

# make file executable
chmod 700 /projects/verhaak-lab/amins/hpcenv/opt/kernels/wrap_yoda_r41
```

*   Add following to _wrap_yoda_r41_ file. Change user paths where applicable.

```
#!/bin/bash

## Load env before loading jupyter kernel @sbamin https://github.com/jupyterhub/jupyterhub/issues/847#issuecomment-260152425

#### Activate CONDA in subshell ####
## Read https://github.com/conda/conda/issues/7980
CONDA_BASE=$(conda info --base) && \
source "${CONDA_BASE}"/etc/profile.d/conda.sh && \
conda activate yoda
#### END CONDA SETUP ####

## this is the critical part, and should be at the end of your script:
## path to R and arguments come from original kernel.json under
## ~/.local/share/jupyter/kernels/yoda_r41/ directory.

## In some cases, path to R may differ and may originate from
## .../envs/yoda/lib64/R/bin/R instead of .../envs/rey/lib64/R/bin/R

## If so, adjust path to R here accordingly.
exec /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/R/bin/R --slave -e "IRkernel::main()" --args "$@"

## Make sure to update corresponding kernel.json under ~/.local/share/jupyter/kernels/<kernel_name>/kernel.json

#_end_
```

*   Now, adjust kernel settings.

```sh
## go to kernel base dir
cd ~/.local/share/jupyter/kernels/

## there should be yoda_py310 directory or
## one matching --name yoda_py310 argument
## we used above when installing python kernel
cd yoda_r41

## edit kernel.json
nano kernel.json
```

*   Replace contents of _kernel.json_ with following:

```json
{
 "argv": [
  "/projects/verhaak-lab/amins/hpcenv/opt/kernels/wrap_yoda_r41",
  "{connection_file}"
 ],
 "display_name": "yoda_r41",
 "language": "R"
}
```

Done! Next time you run jupyter, you should have a new julia kernel in JupyterLab.

### Configure JupyterLab

Once we have installed env specific kernels as in _yoda_ (and other envs, if a ny), now it's a time configure JupyterLab in the _base_ env.

```sh
## deactivate yoda env
conda deactivate
```

!!! warning "You should be in conda _base_ env"
    If you were jumping across more than one conda envs, then each instance of `conda deactivate` command will bring you back to previously active env. So, make sure to return to _base_ env which you can confirm using `echo $CONDA_PREFIX` output. That should point to base path of conda (mambaforge in my case) installation: _/projects/verhaak-lab/amins/hpcenv/mambaforge/_. Also, notice change in bash prompt to `(base) userid@sumner50`.

*   Once in the _base_ env, generate skeleton for default jupyter configuration.

```sh
## return to home dir
cd "${HOME}" && \
jupyter server --generate-config
```

>Writing default config to: /home/userid/.jupyter/jupyter_notebook_config.py

!!! danger "Secure Jupyter Server"
    It is critical that you harden security of jupyterlab server. Default configuration is not good enough (in my view) for launching notebook server over HPC, especially without SSL (or _https_) support. Setting up individual security steps is beyond scope of this documentation. However, I strongly recommend reading official documentation on [running a public Jupyter Server](https://jupyter-server.readthedocs.io/en/latest/operators/public-server.html) and [security in the jupyter server](https://jupyter-server.readthedocs.io/en/latest/operators/security.html).

*   Example config for _/home/userid/.jupyter/jupyter_server_config.py_. **Please do not copy and paste these options** without knowing [underlying details](https://jupyter-notebook.readthedocs.io/en/stable/config.html).

```py
## leave commented out portion of default config as it is.
## then you can add your custom config
## Do not copy these configurations without knowing what they do!

#### NOTEBOOK CONFIGS ####
## SSL settings
## read documentation for details
c.ServerApp.certfile = u'/home/foo/xyz/jp.crt'
c.ServerApp.keyfile = u'/home/foo/xyz/jp.pem'

## openssl rand -hex 32 > /home/foo/xyz/dummy_file
c.JupyterHub.cookie_secret_file = '/home/foo/xyz/dummy_file'
c.ServerApp.open_browser = False

## token used to programmatically login to jupyter,
## e.g., via Atom Hydrogen package
## alphanumeric secret string - longer the better.
c.ServerApp.token = 'dummy_login_token_replace_with_a_secret_token'
c.ServerApp.allow_password_change = False

## should be set to False
## unsafe to set True from https security point of view
c.ServerApp.disable_check_xsrf = False

## use one of available options: See documentation
c.Application.log_level = 'INFO'

## use login shell
c.ServerApp.terminado_settings={'shell_command':['bash', '-l']}
## END ##
```

*   Once you customize _/home/userid/.jupyter/jupyter_notebook_config.py_ file, **make sure to generate a secret and strong password using** `jupyter server password` command. Your password then will be written in encrypted format in _/home/userid/.jupyter/jupyter_server_config.json_ file.
*   Make both files read/write-only by you.

```sh
## for directory, we use permission 700
chmod 700 ~/.jupyter
## location where cookie secret is stored
## prefer a secure and stable path
mkdir -p ~/xyz 
chmod 700 ~/xyz

# For files, we use permission 600
chmod 600 ~/.jupyter/jupyter_server_config.py
chmod 600 ~/.jupyter/jupyter_server_config.json
## location of cookie secret file
chmod 600 ~/xyz/dummy_file
```

### Customizing user interface

Before installing themes or customizing jupyterlab further, I will install [node js](https://nodejs.org/en/) package to _base_ env.

>Ideally, _base_ env should not be cluttered with packages except bare mininmum that comes with original conda installation (mambaforge in my case). However, node js is required to setup and manage jupyterlab extensions and how jupyterhub can interact with a few kernels, e.g., `jupyterlab-sql` extension to interact with sql databases that I will end up installing in the future.

```sh
mamba install -c conda-forge nodejs
npm --version
```

>using v8.1.2

####  Themes

Optional: Themes provide custom user interface and is optional for setup. See example themes at https://github.com/dunovank/jupyter-themes

```sh
mamba install -c conda-forge jupyterthemes
```

>Note: This may downgrade node js. Since I do not use node js in _base_ and it is installed in _base_ to manage jupyter extensions, I was ok downgrading it as it changed only [a build and not major or minor version](https://en.wikipedia.org/wiki/Software_versioning).

*   setup theme, see [details here](https://github.com/dunovank/jupyter-themes)

```sh
jt -t solarizedl -T -N -f firacode -fs 12 -tf ptserif -tfs 11 -nf ptsans -nfs 12 -dfs 11 -ofs 10 -cellw 90% -lineh 170
```

#### keyboard shortcuts

If you are familiar with RStudio shortcuts for R pipe `%>%` and assignment `<-` operator, you can enable those in JupyterLab too[^ref_kbr] by first starting a jupyterlab session. You can then go to `Advanced Settings Editor` either by pressing ++cmd+comma++ on a mac or go to `Settings` from a top menubar, and then clicking `Keyboard Shortcuts` option. There, under `User Preferences` pane, you can paste following to enable keyboard shortcuts, i.e., ++alt+minus++ for `<-` and ++shift+cmd+m++ for `%>%` operator.

[^ref_kbr]: Based on a reply from @krassowski at [JupyterLab forums](https://github.com/jupyterlab/jupyterlab/issues/10114#issuecomment-821993321)

```
{
    "shortcuts": [
        {
            "command": "apputils:run-first-enabled",
            "selector": "body",
            "keys": ["Alt -"],
            "args": {
                "commands": [
                    "console:replace-selection",
                    "fileeditor:replace-selection",
                    "notebook:replace-selection",
                ],
                "args": {"text": " <- "}
            }
        },
        {
            "command": "apputils:run-first-enabled",
            "selector": "body",
            "keys": ["Accel Shift M"],
            "args": {
                "commands": [
                    "console:replace-selection",
                    "fileeditor:replace-selection",
                    "notebook:replace-selection",
                ],
                "args": {"text": " %>% "}
            }
        }
    ]
}
```

#### gpg signatures

Optional: Import gpg keys, if any for [code signing](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits). More at https://unix.stackexchange.com/a/392355/28675

Earlier I installed required gpg packages, _gpg_ and _python-gnupg_ but they ended up conflicting with `gpg-agent` that is running by the system gpg at `/usr/bin/gpg`. So, I have to remove both conda packages in order to use system gpg at `/usr/bin/`.

```sh
mamba remove -c conda-forge gnupg python-gnupg
```

!!! warning "Removing packages using `mamba remove`"
    This also removed several other packages which were required by gpg packages but not by other packages still present in _conda_ env. However, over time, you may end up compiling softwares outside of conda env but still using certain dependencies installed via conda. If so, be careful running `mamba remove` command as it **can not check dependencies for softwares installed outside conda env**, and removing packages like below may break your compiled tools.

```
  - gnupg           2.3.3  h7853c96_0     installed         
  - libassuan       2.5.5  h9c3ff4c_0     installed         
  - libgcrypt       1.9.4  h7f98852_0     installed         
  - libgpg-error     1.42  h9c3ff4c_0     installed         
  - libksba         1.3.5  hf484d3e_1000  installed         
  - npth              1.6  hf484d3e_1000  installed         
  - ntbtls          0.1.2  hdbcaa40_1000  installed         
  - python-gnupg    0.4.8  pyhd8ed1ab_0   installed 
```


!!! danger "Careful with gpg command"
    For code signing, you do not need private keys and public keys works ok. **Make sure to check gpg documentation before running these commands.** Incorrect use may expose your private keys (worst if you push incorrect keys to a public gpg server!) and defeats the purpose of encryption.

```sh
## list public keys, if any
## This will setup ~/.gnupg dir if running command for the first time
## Do chmod 700 ~/.gnupg in case dir perm are not correctly set
gpg --list-keys

gpg --allow-secret-key-import --import private_public.key

## list public keys
gpg --list-keys

## set trust level
## set a valid trust level after reading documentation
gpg --edit-key {KEY} trust quit

## list secret keys
gpg --list-secret-keys
```

#### rmate

Optional: I user `rmate` command to open remote files on HPC in the text editor like Atom or SublimeText on my macbook.

*   Prefer installing [standalone binary](https://github.com/textmate/rmate) over ruby-based (`gem install rmate`) command. If you prefer ruby based installation, better to add ruby installation in a separate conda env, e.g., in _luke_ or other backend env.

```sh
# in base env

## download standalone binary and save as rmate in ~/bin/
mkdir -p ~/bin
curl -Lo ~/bin/rmate https://raw.githubusercontent.com/textmate/rmate/master/bin/rmate
chmod 700 ~/bin/rmate

```

>[Read usage instructions](https://github.com/textmate/rmate) for more on using `rmate` command.

## Backup conda env

Let's backup conda setup we have done so far. I will backup configurations for each of conda env we created above. I have created a small wrapper, :octicons-file-code-16: [conda_bkup.sh]({{ repo.url }}{{ repo.blob }}/confs/hpc/user_env/bin/conda_bkup.sh) - using [`conda env export` and `conda list` commands](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html) - to backup conda env. 

*   Base or root env

>~/conda_env_bkup/sumner/base/<timestamp>/

```sh
conda_bkup.sh
```

*   dev env

>~/conda_env_bkup/sumner/yoda/<timestamp>/

```sh
conda activate yoda && \
conda_bkup.sh

## return to base env
conda deactivate
```

## Start JupyterLab

*   **Optional:** Install several tools in _base_ env.

```sh
# I use dos2unix often to fix line endings for
# files created from windows (dos2unix) or mac (mac2unix)

## A few other packages for jupyterlab extensions
mamba install -c conda-forge jupyter_http_over_ws jupyterlab-link-share dos2unix

## check for successful install
echo $?

# Run only if you have installed jupyter_http_over_ws AND
# you are familiar with managing jupyter server backend.
# jupyter server extension enable --py jupyter_http_over_ws
```

*   Test jupyterlab run: Please [read documentation](https://jupyter-notebook.readthedocs.io/en/stable/public_server.html) carefully on using SSL option and defining port and IP.


!!! warning "☠️ Use SSL and password protection ☠️"
    Avoid running notebook server without SSL and proper password and token configuration as [detailed above](#configure-jupyterlab)) else you may encounter a significant data security risk.

```sh
mkdir -p ~/tmp/jupyter/sumner

## capture LAN IP for a login or compute node
## https://stackoverflow.com/a/3232433
REMOTEIP="$(hostname -I | head -n1 | xargs)"

## test run from a login or compute node
jupyter lab --no-browser --certfile="${MYPEM}" --keyfile "${MYKEY}" --ip="${REMOTEIP}" --port="$MYPORT" >> ~/tmp/jupyter/sumner/runtime.log 2>&1
```

*   Once a jupyter session begins and assuming you are on a secure local area network, you can open URL: `https://<REMOTEIP>:<PORT>/lab` to launch jupyter lab.

!!! warning "Run jupyterlab from a compute and not login node"
    **Avoid running JupyterLab server on a login node.** It will most likely be killed by HPC admins. For longer running and compute-intensive jupyterlab sessions, it is preferable to run jupyterlab from a compute and not a login node. This requires series of secure port forwarding which is beyond the scope of current documentation. However, your HPC may already have support for running JupyterLab on a compute node, e.g, similar to this one at [Univ. of Bern](https://hpc-unibe-ch.github.io/software/JupyterLab.html) or [Princeton Univ.](https://researchcomputing.princeton.edu/support/knowledge-base/jupyter). Talk to your HPC staff for policies on running JupyterLab server.

Before continuing setup (not over yet!), let's logout and login first from interactive job and exit HPC.

```sh
exit # from interactive session
exit # from sumner

ssh sumner
```

[In Part 3](../sumner_3/), I will finalize setting up Sumner (or CPU-based) HPC and also install a dedicated conda env for Winter (GPU-based) HPC.
