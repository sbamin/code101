---
title: "Setting up CPU env - Part 3"
description: "Sumner HPC Setup 2021: Part 3"
keywords: "sumner,hpc,conda,bash,jupyter,programming"
comments: true
---

Continuing the setup from the [Part 2](../sumner_2/), now we will finalize setup for Sumner or CPU-optimized HPC with following key configurations:

- [x] Install additional tools and conda envs for Sumner (CPU-based) HPC:
    - [x] Julia in _yoda_ env
    - [x] a new env, _luke_ for installing sql related backend tools, and
    - [x] a new env, _leia_ for running [snakemake](https://snakemake.readthedocs.io) workflows.
- [x] Configure [Modules](https://modules.readthedocs.io) to load tools that either I use infrequently or require multiple dependencies that may break my stable env, _yoda_
- [x] Finalize **bash startup env** using _~/.profile.d/_ configuration.

Let's start with a fresh :octicons-terminal-16: terminal session:

```sh
exit # from prior interactive session, if any
exit # from sumner

ssh sumner

screen
## start interactive session
srun -p compute -q batch -N 1 -n 4 --mem 10G -t 08:00:00 --pty bash

## activate env
conda activate yoda

## unload gcc if loaded
module unload gcc
```

>Confirm that `echo $PATH` output should now have paths related to conda env **prefixed** but nothing else related to modules, LD_LIBRARY_PATH, etc.

Also, make sure that module: `gcc` is unloaded and should not show up in `module list` output. We do not want system gcc (or any other devtools), and instead rely on conda-installed devtools when compiling R libraries or any other softwares, e.g., samtools, bcftools, etc.

```sh
## example PATH variable
/projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/bin:/projects/verhaak-lab/amins/hpcenv/mambaforge/condabin:/cm/shared/apps/slurm/18.08.8/sbin:/cm/shared/apps/slurm/18.08.8/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/amins/.local/bin:/home/amins/bin

## example LD_LIBRARY_PATH variable
/cm/shared/apps/slurm/18.08.8/lib64/slurm:/cm/shared/apps/slurm/18.08.8/lib64
```

??? info "Duplicate entries in PATH and LD_LIBRARY_PATH"
    If you are using `screen`, you may notice duplicate entries for one or more paths, typically for those which are loaded by the system defaults, e.g., modules and `/usr/local/...`. We will take care of this later when setting up our **bash startup** using _~/.profile.d/_ configurations.


## Julia

Since I use Julia alongside R and Python, I will install it under a primary env, _yoda_. I will prefer using a long-term support (LTS) version over the latest version. You can install julia via conda-forge channel. However, I'd trouble running conda installed julia in jupyter notebooks with kernel unable to start and connect to console[^julia1].  Hence, I ended up installing pre-compiled version from [julia downloads page](https://julialang.org/downloads/) and then adjusting PATH variable to setup `julia` command using _~/.bashrc_ or preferably _~/.profile.d/_ configuration (explained later).

[^julia1]: Related discussions on [julia forums](https://discourse.julialang.org/t/ijulia-kernel-not-starting-unless-ijulia-is-installed-in-the-global-environment-ie-v1-1/21172) and [troubleshooting guide](https://julialang.github.io/IJulia.jl/dev/manual/troubleshooting/).

??? tip "Removing conda installed version of julia"
    If you have previously installed julia in conda env, _yoda_ and now like to remove it, you can run `mamba remove -n yoda julia` to remove julia and all of dependencies which are NOT shared by other conda installed packages. Before removing dependencies, it's good to check if any of removed packages (shared libraries in particular) are requirements or not for other packages by [listing package dependencies](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-pkgs.html).

    After ensuring no other conda packages require julia-related dependencies, I used `mamba remove -n yoda julia libunwind` to remove conda-installed julia and its dependencies.

*   Create an empty path to store compiled packages. Later in the setup (Modules section), I will end up loading most of these packages as `module load package` as I use them less often. For julia, I will rather use bash startup to assign it to PATH variable and load it as a routine package.

```sh
mkdir -p /projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia
```

*   Install LTS version of julia: Go to [julia downloads](https://julialang.org/downloads/) page and download _64-bit_ LTS version (and not one with _musl_ which is [statically linked](https://en.wikipedia.org/wiki/Static_library) libraries).

```sh
cd /projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia
wget https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.4-linux-x86_64.tar.gz

tar xvzf julia-1.6.4-linux-x86_64.tar.gz

# This is to standardize package naming for module definitions, if any.
mv julia-1.6.4 1.6.4
```

### Reconfigure julia base directory

By default, julia will store packages (which takes much of space) into _~/.julia_. Since my home directory is capped at 50 GB, I will reconfigure julia to use non-home path (on tier 1 space) for storing packages. Before reconfiguring, **please read [Environment Variable](https://docs.julialang.org/en/v1/manual/environment-variables/)** section in julia documentation and [following post on stackoverflow](https://stackoverflow.com/questions/36398629/change-package-directory-in-julia).

??? info "Why not to simply move _~/.julia/_ to a new place?"
    Perhaps the easiest solution would be to move _~/.julia/_ to a new path and symlink it from there. While it looks easy, I usually avoid such hack as several softwares, including conda and some of commands of python and R rely on [hardlinks over symnlinks](https://stackoverflow.com/questions/185899/what-is-the-difference-between-a-symbolic-link-and-a-hard-link) and can throw errors. Besides, it is always good to understand how softwares set default configurations.

*   Since pre-compiled julia is not in bash PATH, for now, we will just run following command to manually make julia available in PATH for **the current terminal session**. Once setup is complete, we will set julia path in PATH permanently using bash startup, so julia can load anytime we login to HPC.

```sh
export PATH="/projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia/1.6.4/bin:${PATH}"
echo "$PATH"
```

*   Start julia prompt.

```sh
# show location of julia
command -v julia

# start julia prompt
julia
```

??? bug "segmentation fault running julia"
    If you have _libunwind_ library for some other conda package(s) and if it is a version higher than 1.5.0, running `julia` command may throw an error saying segmentation fault. More at https://github.com/conda-forge/julia-feedstock/issues/135. In that case, you may need to tweak PATH and LD_LIBRARY_PATH such that conda installed _libunwind_ does not take precedence when running julia. This is usually achieved using `module load julia` prior to running julia and thus, tweaking required PATH and LD_LIBRARY_PATH. Alternately, you may downgrade conda installed libunwind only if conda does not throw a warning. `mamba install -c conda-forge libunwind=1.5.0`

*   Once inside julia terminal, notice existing paths from an output of julia command: `DEPOT_PATH`

```jl
3-element Vector{String}:
 "/home/amins/.julia"
 "/projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia/1.6.4/local/share/julia"
 "/projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia/1.6.4/share/julia"
```

*   Quit julia by ++ctrl+d++

We will now update PATH variable and also set a new bash env variable, `JULIA_DEPOT_PATH` in _~/.bashrc_/ Once we finalize **bash startup**, we will move most of custom configurations from _~/.bashrc_ to a dedicated _~/.profile.d/_ directory.

Since we have not installed any julia packages, only packages that are shipped with julia are at _/projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia/1.6.4/share/julia/_, specifically under _base/_ subdirectory. We like to keep this path unaltered and hence, we will keep it at the last in `JULIA_DEPOT_PATH` to assign the lowest priority to install new packages.

*   First, make an empty package directory [similar to R package directory](../SR2_setup/#setup-rprofile-and-renviron) we created earlier.

```sh
mkdir -p /projects/verhaak-lab/amins/hpcenv/opt/julia/pkgs/1.6
```

* Now copy all of _~/.julia/_ contents to this new path. Since we have not installed any new packages, we will be copying only a skeleton of directory and files to a new package path.

```sh
rsync -avhP ~/.julia/ /projects/verhaak-lab/amins/hpcenv/opt/julia/pkgs/1.6/
```

!!! warning "Do not delete _~/.julia/_ directory"
    Do not delete _~/.julia/_ after copying it to a new path. Julia will still use this path to store user-defined configurations, primarily under _~/.julia/config/startup.jl_ file. Please read [Environment Variable](https://docs.julialang.org/en/v1/manual/environment-variables/) in julia documentation if you have not read that yet!

*   Add following line to _~/.bashrc_, preferably above the `# >>> conda initialize >>>` line because we like to take conda setup precedence over rest of configurations during bash startup.

```sh
#### custom configs ####
export PATH="/projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia/1.6.4/bin:${PATH}"

export JULIA_DEPOT_PATH="/projects/verhaak-lab/amins/hpcenv/opt/julia/pkgs/1.6:/projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia/1.6.4/local/share/julia:/projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia/1.6.4/share/julia"

# >>> conda initialize >>>
```

>Notice that we have now purposefully kept _~/.julia/_ path out of default paths to store packages. Of course, julia will still use _~/.julia/_ for storing user configurations among other things but those should not take up much space as installing packages do. If otherwise, we will know later and come up with a better solution!

* Before we start julia again to check new `DEPOT_PATH`, ensure that an updated bash startup has been loaded from _~/.bashrc_ file. Ideally, you should exit from a current session and login again same as we did in the beginning of this page. Alternately, you may run above `export JULIA_...` command in the current terminal to update julia env variable.

??? info "Why not we do `source ~/.bash_profile` or `source ~/.bashrc`?"
    You may do `source ~/.bash_profile` but **do note** that this may have unwanted effects on PATH and LD_LIBRARY_PATH variables depending on how _~/.bashrc_ is loading bash startup env, including from `/etc/bashrc`. In a nutshell, better to run a single command as follows or the best is to log out and login again to have updated bash startup to take an effect.

*   Update current terminal env with an updated depot path variable. Make sure to run subsequent `julia` command in the same terminal (and not in any other terminal sessions in screen you may have already opened) else julia may fall back to old depot path.

```sh
export JULIA_DEPOT_PATH="/projects/verhaak-lab/amins/hpcenv/opt/julia/pkgs/1.6:/projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia/1.6.4/local/share/julia:/projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia/1.6.4/share/julia"
```

*   Start `julia` and type `DEPOT_PATH` inside julia prompt.

```jl
3-element Vector{String}:
 "/projects/verhaak-lab/amins/hpcenv/opt/julia/pkgs/1.6"
 "/projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia/1.6.4/local/share/julia"
 "/projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia/1.6.4/share/julia"
```

>You should now see an updated DEPOT_PATH with our custom path taking the highest priority.

### Install julia kernel

Similar to python and r kernel, we will install julia kernel to interact with julia from JupyterLab console.

!!! warning "Running Jupyter notebook from julia prompt"
    IJulia kernel package in julia also allows you to run jupyter notebook or JupyterLab from julia prompt. It does so by installing a separate conda env inside julia package directory. Since we already have installed conda env outside julia package paths, I prefer **not to install conda env via julia**. So, if you ever come across [Running IJulia guide](https://julialang.github.io/IJulia.jl/dev/manual/running/), please tread carefully installing two different conda env on your system! Unless you know what you are doing, avoid running commands like `notebook()` or `jupyterlab()` inside julia prompt.

!!! tip "Run `julia` command under _yoda_ env"
    Since we have installed julia as a standalone package and path to `julia` is fixed in PATH variable, we can run `julia` independent of which conda env we are in. However, I am using _yoda_ env as my routine env where R and other tools are installed. So, as the best practice, I will **run `julia` after activating _yoda_ env**, including running julia as a kernel.

```sh
mamba activate yoda

# enter julia prompt
julia
```

*   Install IJulia kernel

```jl
using Pkg
Pkg.add("IJulia")
```

>Notice where julia is now installing new packages to!

```
julia> Pkg.add("IJulia")
  Installing known registries into `/projects/verhaak-lab/amins/hpcenv/opt/julia/pkgs/1.6`
  ...Resolving and installing dependency packages...

    Building Conda ─→ `/projects/verhaak-lab/amins/hpcenv/opt/julia/pkgs/1.6/scratchspaces/44cfe95a-1eb2-52ea-b672-e2afdf69b78f/6cdc8832ba11c7695f494c9d9a1c31e90959ce0f/build.log`
    Building IJulia → `/projects/verhaak-lab/amins/hpcenv/opt/julia/pkgs/1.6/scratchspaces/44cfe95a-1eb2-52ea-b672-e2afdf69b78f/d8b9c31196e1dd92181cd0f5760ca2d2ffb4ac0f/build.log`
Precompiling project...
  11 dependencies successfully precompiled in 8 seconds (4 already precompiled)
```

* Exit julia prompt by ++ctrl+d++

For consistency with naming kernels and ensuring that we load a valid _yoda_ env prior to running kernel, let's adjust kernel settings. For rationale, see [kernel loading section in Part 2](../../cpu/sumner_2/#kernel-loading).

*   Create a new kernel wrapper, _/projects/verhaak-lab/amins/hpcenv/opt/kernels/wrap_yoda_jl16_

```sh
mkdir -p /projects/verhaak-lab/amins/hpcenv/opt/kernels
touch /projects/verhaak-lab/amins/hpcenv/opt/kernels/wrap_yoda_jl16

# make file executable
chmod 700 /projects/verhaak-lab/amins/hpcenv/opt/kernels/wrap_yoda_jl16
```

>Add following to _wrap_yoda_jl16_

```
#!/bin/bash

## Load env before loading jupyter kernel @sbamin https://github.com/jupyterhub/jupyterhub/issues/847#issuecomment-260152425

#### Activate CONDA in subshell ####
## Read https://github.com/conda/conda/issues/7980
# I am using conda instead of mamba to activate env
# as somehow I notices warnings/errors sourcing
# mamba.sh in sub-shells.
CONDA_BASE=$(conda info --base) && \
source "${CONDA_BASE}"/etc/profile.d/conda.sh && \
conda activate yoda && \
echo "Env is $(basename ${CONDA_PREFIX})"
#### END CONDA SETUP ####

# this is the critical part, and should be at the end of your script:
exec /projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia/1.6.4/bin/julia -i --color=yes --project=@. /projects/verhaak-lab/amins/hpcenv/opt/julia/pkgs/1.6/packages/IJulia/e8kqU/src/kernel.jl "$@"

## Make sure to update corresponding kernel.json under ~/.local/share/jupyter/kernels/<kernel_name>/kernel.json

#_end_
```

*   Now, adjust kernel settings.

```sh
## go to kernel base dir
cd ~/.local/share/jupyter/kernels/

## rename julia kernel dir to yoda_jl16
mv julia-1.6 yoda_jl16

## edit kernel.json to rename display name to yoda_jl16
cd yoda_jl16
nano kernel.json
```

>Replace contents of _kernel.json_ with following:

```json
{
 "argv": [
  "/projects/verhaak-lab/amins/hpcenv/opt/kernels/wrap_yoda_jl16",
  "{connection_file}"
 ],
 "display_name": "yoda_jl16",
 "language": "julia",
 "env": {},
 "interrupt_mode": "signal"
}
```

>Done! Next time you run jupyter, you should have a new julia kernel in JupyterLab.

## Database

This is an optional setup. If you are using database like postgresql, you may end up needing similar setup to install required postgresql drivers in conda env. Database driver(s) vary based on type of database, e.g., postgresql, mongodb, etc., and supported programming language.

### postgresql driver

*   Create a new env, _luke_ to host database related drivers among other backend tools.

```sh
mamba create -c conda-forge -n luke psqlodbc

# activate _luke_ env
mamba activate luke
```

*   Add database connection entries to _~/.odbc.ini_ and make it `chmod 600 ~/.odbc.ini` as it contains login credentials in plain characters!

>We use postgresql database in our lab and it is hosted internally on a dedicated linux node. I can programmatically (via R, python, jupyterlab kernel) connect to this database by declaring following connection definition in _~/.odbc.ini_ file. Notice path to database driver, _psqlodbcw.so_ that we have just installed, and will be used to connect to a remote database.

```
[db1]
Driver              = /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/luke/lib/psqlodbcw.so
Database            = db1
Servername          = db1.example.com
UserName            = user1
Password            = password1
Port                = <db1 port>
sslmode             = require
[db2]
Driver              = /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/luke/lib/psqlodbcw.so
Database            = db2
Servername          = db2.example.com
UserName            = user2
Password            = password2
Port                = <db1 port>
```

*   If database connection requires SSL (preferable), then you will need to put required SSL configuration files into _~/.postgresql_ or similar database-specific directory.

### ~~jupyterlab-sql (deprecated)~~

I installed jupyterlab-sql in _base_ env thinking it is supported for jupyterlab v3 or higher. However, jupyterlab-sql seems to be outdated and may not function in jupyterlab v3+.

==You can ignore following setup for jupyterlab-sql== (and jump to [postgresql-kernel](#postgresql-kernel)) unless [source wbesite](https://github.com/pbugnion/jupyterlab-sql) confirms that it is supported in an updated jupyrterlab env. Since I already installed jupyterlab-sql, I am going to remove it from _base_ env.

*   Remove deprecated package.

```sh
pip uninstall jupyterlab-sql
```

```
pip uninstall jupyterlab-sql
Found existing installation: jupyterlab-sql 0.3.3
Uninstalling jupyterlab-sql-0.3.3:
  Would remove:
    /projects/verhaak-lab/amins/hpcenv/mambaforge/lib/python3.9/site-packages/jupyterlab_sql-0.3.3.dist-info/*
    /projects/verhaak-lab/amins/hpcenv/mambaforge/lib/python3.9/site-packages/jupyterlab_sql/*
Proceed (Y/n)? Y
```

*   Remove a related extension.

```sh
jupyter server extension disable jupyterlab_sql
jupyter lab extension disable jupyterlab-sql
```

*   Rebuild existing jupyter extensions.

```sh
jupyter lab build

# check enabled extensions
jupyter lab extension list
jupyter server extension list
echo $?
```

??? bug "Error loading server extension"
    If you still notice a following warning (though `echo $?` should be 0 for an error-free configuration of jupyterlab extensions) related to jupyterlab_sql, it should not impact running jupyterlab. This seems like an open issue with jupyterlab extension configuration. https://github.com/jupyter/notebook/issues/2584

    ```
    Error loading server extension jupyterlab_sql
          X is jupyterlab_sql importable?
    ```

***

!!! warning "Before installing third-party packages, check project page for compatibility"
    Turns out that [jupyterlab-sql](https://github.com/pbugnion/jupyterlab-sql) is no longer actively being maintained and may not be compatible with an updated jupyterlab v2+. https://github.com/pbugnion/jupyterlab-sql/issues/147

    Before installing third-party packages, prefer packages that are being actively maintained by looking into [last commit date](https://github.com/pbugnion/jupyterlab-sql/commits/master), [release history, if any](https://github.com/pbugnion/jupyterlab-sql/releases), and [list of open issues](https://github.com/pbugnion/jupyterlab-sql/issues).

jupyterlab-sql is a [GUI](https://en.wikipedia.org/wiki/Graphical_user_interface) extension in the _base_ env because we run jupyter from _base_.

*   From jupyterlab-sql page, [check setup.py](https://github.com/pbugnion/jupyterlab-sql/blob/master/setup.py) requirements.

```sh
## return to base env from _yoda_
mamba deactivate
## confirm that login prompt is showing (base) [userid@sumner]
## else run mamba deactivate or mamba activate base

## check if requirements are already installed or not
mamba list | grep -E "sqlalchemy|jsonschema"

## install required dependencies
mamba install -c conda-forge sqlalchemy jsonschema
```

```sh
pip install jupyterlab-sql
```

```
Successfully built jupyterlab-sql
Installing collected packages: jupyterlab-sql
Successfully installed jupyterlab-sql-0.3.3
```

*   Build required jupyterlab extension for SQL

```sh
jupyter server extension enable jupyterlab_sql --py --sys-prefix

## Rebuild all of jupyterlab extensions
## this may take a while (~5 minutes)
jupyter lab build

# check enabled extensions
jupyter lab extension list
jupyter server extension list
```

*   [Read on how-to use SQL GUI](https://github.com/pbugnion/jupyterlab-sql) 

### postgresql kernel

Similar to other kernels, let's install postgresql kernel, so that jupyter notebooks can interact with postgres database. If using non-postgres system, [follow driver installation based on sqlalchemy-based compatible drivers](https://docs.sqlalchemy.org/en/13/dialects/postgresql.html).

*   Install postgres driver.

>This is not available in conda-forge channel. So, installing using `pip install` after [ensuring that all of dependencies for the drivers](https://pypi.org/project/py-postgresql/) are satisfied in _base_ env and if not, prefer installing dependencies first by `mamba install` and then do `pip install`.

```sh
pip install py-postgresql
```

```
Successfully built py-postgresql
Installing collected packages: py-postgresql
Successfully installed py-postgresql-1.2.2
```

*   Install [ipython-sql](https://github.com/catherinedevlin/ipython-sql) kernel and psycopg2 - a popular postgresql driver for python.

```sh
## install core package, sqlalchemy and related dependencies, if any.
mamba install -c conda-forge sqlalchemy jsonschema
mamba install -c conda-forge ipython-sql psycopg2
```

>Since I will be using _yoda_ env for most times, I have also installed core sql drivers into _yoda_ env without any conflicts with an existing setup.

```sh
mamba activate yoda
mamba install -c conda-forge sqlalchemy ipython-sql psycopg2
mamba deactivate
```

*   If applicable, restart jupyterlab server to enable SQL integration in jupyterlab env. Here is a good [tutorial on using jupyter magic commands with SQL](https://towardsdatascience.com/jupyter-magics-with-sql-921370099589).

## Python 2

Python comes in two major flavors: Python 2 and Python 3. Since January 1, 2020, the official python developer community  have [stopped supporting further development and bug fixes for Python 2](https://www.python.org/doc/sunset-python-2/). So, it's ideal to use Pythonh 3 over Python 2 unless for a few (or more!) softwares in computational biology that depend on Python 2.

Since conda env is bound to Python (and the major version), let's create a separate conda env, _windu_ that will host Python 2.

>Optional: Along with python 2, I will also install a software, [PhyloWGS](https://github.com/morrislab/phylowgs) which requires python 2 as a core dependency.

```sh
## python 2.7 was the last major release.
mamba create -n windu python=2.7 phylowgs
```

*   Let's check briefly if it works ok!

```sh
mamba activate windu
python --version

## if you have also installed phylowgs
# evolve.py --help
```

>Python 2.7.15

*   Deactivate and return to _base_ env.

```sh
mamba deactivate
```

## Ruby

Tools installed under dev or beta env, _anakin_

```sh
mamba create -c conda-forge -n anakin httpie
mamba activate anakin
```

```sh
# install ruby and github cli, https://github.com/cli/cl
mamba install -c conda-forge ruby gh
# additional gist utility, https://github.com/defunkt/gist
gem install gist
```

>Installing gem for the first time will prepend gem bin path, `/projects/verhaak-lab/amins/hpcenv/mambaforge/envs/anakin/share/rubygems/bin` to `$PATH` variable.

!!! warning "Use `mamba deactivate` prior to switching to a new conda env"
    When switching to an another conda env, always prefer using `mamba deactivate` first and then run `mamba activate <other_env>` instead of directly running `mamba activate <other_env>`. By doing deactivation first, conda will reset conda-related paths in `$PATH`, i.e., to remove paths from a deactivated env and fall back to the conda env (or default _base_ env) that was active prior to a deactivated env. However, if you run `mamba activate <other_env>` without prior `mamba deactivate`, some of non-standard paths, i.e., paths other than _.../envs/<env_name>/bin/_, e.g., ruby gem path above, may remain in the `$PATH` and even takes the precedence over paths from a switched (and now active) conda env. Such Such invalid ordering of paths in `$PATH` variable may create issues when you either compile softwares by inadvertently using devtools from a wrong conda env or run softwares with a dynamically linked shared libraries from a wrong conda env.

## Perl

I rarely use perl language except when it is part of a software, e.g., [vcf2maf](https://github.com/mskcc/vcf2maf). If you have configured linux env using setup detailed above, including in previous two parts, you should already have a working perl setup under both, _base_ and _yoda_ env with an identical version (`perl --version` 5.32.1).

### setup PERL5LIB

Optional: Similar to setting up version-specific custom R and julia package path, let's do the same for perl too using a bash env variable, `PERL5LIB`.

!!! warning "Prefer setting up PERL5LIB at the runtime"
    Please know that it is a better to set PERL5LIB at the run time, i.e., using `module load <some program>` (see [Modules](#modules)) of a specific package over hardcoding it in the bash startup (as I am doing below!). Hardcoding PERL5LIB with the same perl packages but built using two different perl versions may fail to run your program. [Read this post at IBM website](https://www.ibm.com/support/pages/perl5lib-or-perllib-can-cause-scripts-fail)

Since we have an identical perl version in _base_ and _yoda_ env, we will only create a common path for both env. If you have a different perl version across conda env, you need to source custom bash startup to update `PERL5LIB` at the time you activate or deactivate conda env. See notes under [Tips on compiling packages](#tips-on-compiling-packages). Also, read more on `PERL5LIB` path at [stackoverflow](https://stackoverflow.com/questions/5167484/setting-perl5lib) and [following guide on setting up custom PERL5LIB path](https://chestofbooks.com/computers/webservers/apache/Stas-Bekman/Practical-mod_perl/3-9-2-2-Using-the-PERL5LIB-environment-variable.html).

!!! warning "Setting up PERL5LIB path"
    HPC job schedulers, like slurm and moab may use their respective perl libraries. Typically, installing a different version of perl in your (user) conda env should not conflict with running slurm or moab commands as the latter is built using system-installed perl (at `/usr/bin/`). If it does, you may need to debug specific errors and resolve issue(s) mostly related to PERL5LIB path.

*   First, check default perl library paths by checking tail portion of `perl -V` output under `@INC:`, e.g., for _yoda_ env, it shows following paths:

```
@INC:
    /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/perl5/site_perl
    /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/perl5/5.32/vendor_perl
    /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/perl5/vendor_perl
    /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/perl5/5.32/core_perl
    /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/perl5/core_perl
```

*   Create an empty path to store user-installed perl packages. We will only need perl standard library path and one for *site_perl*. Paths for vendor and core library are designed for system-only perl packages.

```sh
mkdir -p /projects/verhaak-lab/amins/hpcenv/opt/perl/pkgs/perl5/5.32
mkdir -p /projects/verhaak-lab/amins/hpcenv/opt/perl/pkgs/perl5/site_perl/5.32
```

>:warning: Update PERL5LIB to respective major.minor perl version in case you update perl program.

*   For now, add following to _~/.bashrc_ above `# >>> conda initialize >>>` line. Again, we will move most of custom bash startup settings to a dedicated _~/.profile.d/_ path.

```
export PERL5LIB="/projects/verhaak-lab/amins/hpcenv/opt/perl/pkgs/perl5/5.32:/projects/verhaak-lab/amins/hpcenv/opt/perl/pkgs/perl5/site_perl/5.32:/projects/verhaak-lab/amins/hpcenv/opt/perl/pkgs/perl5/site_perl"
```

>Unlike setting up other library paths, e.g., LD_LIBRARY_PATH, LIBPATH, etc. where we need to append existing system paths (else bash env may fail to find those libraries), in PERL5LIB, we only need to specify user-level library paths and perl will pick up system path based at the run-time.

*   Logout and login again to HPC and activate _yoda_ env.
*   `perl -V` should now show a new `%ENV` variable and perl library paths should now show updated paths with precedence for user-level paths over system paths.

```
%ENV:
    PERL5LIB="/projects/verhaak-lab/amins/hpcenv/opt/perl/pkgs/perl5/5.32:/projects/verhaak-lab/amins/hpcenv/opt/perl/pkgs/perl5/site_perl/5.32:/projects/verhaak-lab/amins/hpcenv/opt/perl/pkgs/perl5/site_perl"
@INC:
    /projects/verhaak-lab/amins/hpcenv/opt/perl/pkgs/perl5/5.32
    /projects/verhaak-lab/amins/hpcenv/opt/perl/pkgs/perl5/site_perl/5.32
    /projects/verhaak-lab/amins/hpcenv/opt/perl/pkgs/perl5/site_perl
    /projects/verhaak-lab/amins/hpcenv/mambaforge/lib/perl5/5.32/site_perl
    /projects/verhaak-lab/amins/hpcenv/mambaforge/lib/perl5/site_perl
    /projects/verhaak-lab/amins/hpcenv/mambaforge/lib/perl5/5.32/vendor_perl
    /projects/verhaak-lab/amins/hpcenv/mambaforge/lib/perl5/vendor_perl
    /projects/verhaak-lab/amins/hpcenv/mambaforge/lib/perl5/5.32/core_perl
    /projects/verhaak-lab/amins/hpcenv/mambaforge/lib/perl5/core_perl
```

## Snakemake

I use [snakemake](https://snakemake.readthedocs.io) for running computational workflows. Snakemake is a well maintained python package with [frequent releases](https://snakemake.readthedocs.io/en/stable/project_info/history.html) for new features and bugfixes. Hence, I prefer to install it in a dedicated conda env, _leia_. This will allow me to update snakemake periodically without worrying about conflicting dependencies for other packages installed in _yoda_ or other envs. Also, I can execute complex workflows using snakemake and can activate other conda envs, like _yoda_ (CPU-otpimized) or _rey_ (GPU-optimized) using one or more of [snakemake-based rules](https://snakemake.readthedocs.io/en/stable/snakefiles/rules.html). To install snakemake, please read [installation guide](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html)

```sh
# for clarity (and sanity): Better to name this env as snakemake unless
# being loyal to Star Wars saga!
mamba create -c conda-forge -c bioconda -n leia snakemake
```

*   To update snakemake to its latest release:

```sh
mamba activate snakemake
mamba update -c conda-forge -c bioconda snakemake
```

## Additional Setup

Following setup is optional.

*   Additional packages in _yoda_ env.

```sh
## in yoda env
# depmap was not available in conda-forge
# biconda version had no conflict with existing setup
mamba install -c bioconda bioconductor-depmap
mamba install -c conda-forge r-odbc r-dbi
mamba install -c conda-forge r-ggthemes r-cowplot r-ggstatsplot r-hrbrthemes
## OpenCL support for CPU
mamba install -c conda-forge pocl
```

### JupyText

Optional: [Jupytext](mamba install -c conda-forge) allows running jupyter notebooks as text or markdown files similar to running scripts for R, Python, and Julia. 

*   Install jupytext in _base_ env if if is not installed before. Note compatibility for related jupyterlab extension at https://github.com/mwouts/jupytext Current version of jupytext (1.13.3) is only compatible with JupyterLab 3+ (I have v3.2.4 and so all good!)

```sh
mamba deactivate
mamba activate base

mamba install -c conda-forge jupytext
```

*  After installing or updating a new jupyterlab extension, good to update and list all extensions.

```sh
## list enabled extension
jupyter lab extension list
jupyter server extension list

## update all extensions
jupyter lab extension update --all
jupyter server extension update --all

jupyter lab extension list
jupyter server extension list
```

I have also installed [jupyter_contrib_nbextensions](https://jupyter-contrib-nbextensions.readthedocs.io/en/latest/index.html) extension earlier in [Part 2](../sumner_2/#start-jupyterlab) which allows additional configuration for jupyter notebook. This is a **beta extension and an optional** setup.

***

## Modules

Similar to managing conda env using `mamba activate` or `mamba deactivate`, we can also load/unload a specific package via `module load` or `module unload` commands. Modules allows us to manage compiled packages or softwares which otherwise are either not available via conda-forge or bioconda channel or installing those with conda is creating dependencies conflict with core conda packages like R and python. Besides overcoming conflicting dependencies, Modules is a better way to organize the same software with multiple versions in case we need to occasionally use an older version for some legacy (and complex) workflow while prefer using an updated version otherwise.

Here, I need to assume you have a working knowledge of using Modules. If not, no worries and here are a few tutorials on using modules in HPC env. Also, talk to your Research IT staff as module configuration may vary across HPC envs.

!!! info "Resources on Modules"
    *   [HPC at NIH](https://hpc.nih.gov/apps/modules.html)
    *   [Sherlock at Stanford](https://www.sherlock.stanford.edu/docs/software/modules/)
    *   [Official documentation](https://modules.readthedocs.io/) also provides an excellent overview of working with Modules. 

*   Your HPC staff may already have installed a few modules. To view those, run `module list`.
*   Besides these default modules, you may also want to load packages that you have compiled by yourself. While buding packages, you may find [tips on compiling packages](#tips-on-compiling-packages) useful.
*   Once packages are built, create an empty directory to package-specific directory and respective *Modulefiles* - one file each for a version, e.g.,

```sh
mkdir -p /projects/verhaak-lab/amins/hpcenv/modules
cd /projects/verhaak-lab/amins/hpcenv/modules

## subdir that will host compiled packages in version specific manner
mkdir apps

## subdir that will host Modulefiles
mkdir def
```

*   Now, if I have compiled multiple versions of a package, e.g., samtools v1.11, v1, 14, etc. or a pre-built packages, e.g., GATK v4.1.9.0 and GATK 4.2, I can do that as follows:

```sh
cd /projects/verhaak-lab/amins/hpcenv/modules

## bash syntax, {1.11,1.14} will create multiple directories
## for each entry separated by comma
mdkir -p apps/samtools/{1.11,1,14}
mkdir -p def/samtools/{1.11,1.14}

```

*   In */def/* directory, you will need to put *Modulefile* as detailed in [official documentation](https://modules.readthedocs.io/). For advanced configuration, [refer to following documentation if your HPC is using Lua module system](https://lmod.readthedocs.io/en/latest/). Following are example Modulefile for samtools v1.14


??? example "Example Modulefile"

    === "Tcl format"

        ```tcl
        #%Module1.0
        ## Example format in Tcl langugae
        ## samtools
        ## Author: Samir Amin

        ## Read about Modulefile manpage
        ## https://modules.readthedocs.io/en/latest/modulefile.html

        ## Substitute version number and app name below
        # for Tcl script use only
        set VERSION 1.11
        set MODULEDIR /projects/verhaak-lab/amins/hpcenv/modules/apps
        set NAME samtools
        ## create a new modulefile for a different version, e.g., 1.14
        set INSTALL_DIR ${MODULEDIR}/${NAME}/${VERSION}

        proc ModulesHelp { } {
                global version
                puts stderr "\nLoads ${NAME}\n"
        }

        module-whatis   "${NAME}"

        ## check available commands in documentation
        append-path PATH ${INSTALL_DIR}/bin

        if { [ module-info mode load ] } {
            puts stderr "\nLoaded ${NAME} ${VERSION} from ${INSTALL_DIR}\n"
        }

        if { [ module-info mode remove ] } {
            puts stderr "\nUnloaded ${NAME} ${VERSION}\n"
        }

        ## END ##
        ```
     
    === "Lua format"

        ```lua
        --[[
        ## Example format in Lua langugae
        ## samtools
        ## Author: Samir Amin

        ## Read about Lmod
        ## https://lmod.readthedocs.io/en/latest/015_writing_modules.html
        ## https://lmod.readthedocs.io/en/latest/050_lua_modulefiles.html
        ## https://lmod.readthedocs.io/en/latest/020_advanced.html
        --]]

        --################################ INTERNAL VARS #################################
        --Module Name and Version are parsed by Lmod from dir/version string in module path
        --Make sure to have exact version numbering when naming respective
        -- app directroy and Modulefile
        local pkgName = myModuleName()
        local version = myModuleVersion()
        local pkgNameVer = myModuleFullName()

        local approot = "/projects/verhaak-lab/amins/hpcenv/modules/apps"
        local appbase = "samtools"
        local pkgdir = pathJoin(approot,appbase,version)
        local pkgbin = pathJoin(pkgdir,"bin")

        --################################# MODULE INFO ##################################
        whatis("Name: ".. pkgName)
        whatis("Version: " .. version)

        --################################## ENV SETUP ###################################
        --## check available commands in documentation
        prepend_path("PATH", pkgbin)
         
        --################################# MODULE LOAD ##################################
        help(
        "Loads " .. pkgNameVer .. '\nCheck env change, if any by\nmodule show ' .. pkgNameVer
        )

        if (mode() == "load") then
          LmodMessage("## INFO ##\nLoading " .. pkgName .. version .. "from " .. pkgdir)
        end

        if (mode() == "unload") then
          LmodMessage("## INFO ##\nUnloading " .. pkgName .. version .. "from " .. pkgdir)
        end

        --## END ##
        ```

## Containers

Containers are a greay way to enclose project-specifig set of packages and workflow(s) to promote portablity and reproducibility of the same workflow across different HPC environments. Here is a brief intro on two of most popular container systems: [Docker](https://www.docker.com/resources/what-container) and [Singularity](https://sylabs.io/guides/latest/user-guide/introduction.html). [HPC at NIH](https://hpc.nih.gov/apps/singularity.html) provides a few examples on building singularity based containers, including packages that require GPU-based configuration, e.g., Keras/Tensorflow and Theano. Your HPC may already have a container system like [Singularity](https://sylabs.io/guides/latest/user-guide/). If so, you can take full advantage of container system.

*   Optional: In my bash startup, I have tweaked singularity [env variables](https://sylabs.io/guides/latest/user-guide/build_env.html) to store cache data on tier 1 space over default *~/.singularity/* path.

```sh
### singularity ###
## add manpath for singularity to an existing manpath
MANPATH="${SUM7ENV}/local/share/man:/cm/local/apps/singularity/current/share/man${MANPATH:+:$MANPATH}"
## set cache dir to non-home path
SINGULARITY_CACHEDIR="/projects/verhaak-lab/amins/containers/cache/singularity"
## path were built SIF images are manually stored
SINGULARITY_SIF="/projects/verhaak-lab/amins/containers/sifbin"
```

??? tip "bash special syntax: `${VAR:+:$VAR}` "
    I have expanded bash env variable like, MANPATH using syntax: `${MANPATH:+:$MANPATH}`. It is a special bash syntax which will expand to existing MANPATH **only if** MANPATH contained any value else output of MANPATH will be an empty string without space or `:`, thereby perseving MANPATH structure.

## Tips on compiling packages

*   Store compiled packages under a base directory like */projects/verhaak-lab/amins/hpcenv/opt/ or */projects/verhaak-lab/amins/hpcenv/opt/apps/*.
*   For each of compiled packages, keep a directory structure that maintains package version, e.g., *.../apps/samtools/v10.2*, *.../apps/samtools/v11.3*, etc.
*   When possible, install or compile packages using a clean terminal session, i.e., ssh to HPC, start screen, and then interactive session to do rest of installation steps.
*   Avoid installing packages via `pip install` as unlike `mamba install or update` command, `pip install` does not strictly check for package dependencies of conda-installed packaegs. So, at least try installing most of package dependencies using `mamba install` first before running `pip install`.
*   Avoid installing packages via Jupyter notebook as unlike terminal session, debugging for a failed installation is difficult with notebook and env session may vary per initialization sequence of jupyter kernel, i.e., whether or not appropriate conda env was loaded prior to starting kernel.
*   While installing packages, prefer using `mamba install/update` first. If this forces you to downgrade core packages like R and python or several core shared libraries, e.g., libz, openssl, etc., you may fall back to compiling via language-specific functions, e.g., `install.packages()` in R, `pip install` for python, etc.
*   While compiling packages, ensure that precedence of paths in PATH, [LD_LIBRARY_PATH, LIBRARY_PATH](https://stackoverflow.com/questions/4250624/ld-library-path-vs-library-path), and related devtools paths are aligned to conda env AND for the respective programming env profile, e.g., if you are compiling a package with intention to use it from _yoda_ env (say a R package), your terminal bash session should have precedence for _/projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/_ path in PATH and if applicable, in LD_LIBRARY_PATH and LIBRARY_PATH too. The identical precedence of paths should also be present in _~/.Renviron_ file.
*   Know that _~/.Renviron_ will be read by any of R session running from _yoda_ or other conda env (say you have R 4.1 in _yoda_ but R 5.1 in _anakin_). Of course, Renviron varies for R 4.1 and R 5.1, and hence, you should have a dedicated [Renviron file](https://stat.ethz.ch/R-manual/R-devel/library/base/html/Startup.html) for each of conda env. You can do that by either [creating a _Renviron.site_](https://support.rstudio.com/hc/en-us/articles/360047157094-Managing-R-with-Rprofile-Renviron-Rprofile-site-Renviron-site-rsession-conf-and-repos-conf) file in the respective env under _/projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/R/etc_ path or loading/unloading a custom Renviron file each time you activate/deactivate conda env using configuration files similar to *~/profile.d/* files (see bash startup below), e.g., `activate.d/load_R4.1env.sh` and `deactivate/unload_R4.1env.sh` under _/projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/etc/conda/_.
*   For julia, [similar startup env files](https://docs.julialang.org/en/v1/manual/environment-variables/) should be *~/.julia/config/startup.jl* and *`$JULIA_BINDIR`/`$SYSCONFDIR`/julia/startup.jl*.

***

## bash startup

As I wrap up setup for our CPU-based Sumner HPC, I will finally configure **bash startup** - a sequence of files containing bash code that should be loaded to setup a consistent bash login environment on HPC login (interactive) and compute nodes (non-interactive). Here the consistent environment equals to order of paths in `PATH` and `LD_LIBRARY_PATH` variables especially when switching conda env and loading of custom configurations for R, Julia, and other packages, etc. that I configured earlier.

First, understand what an interactive and a non-interactive bash session is. For most times, we deal with interactive session when we ssh to HPC. You are in the interactive session if env variable, `PS1` (called [bash custom prompt](https://www.gnu.org/software/bash/manual/html_node/Controlling-the-Prompt.html)) is set and `echo $PS1` is showing some output. For more on bash startup, [please read official documentation](https://www.gnu.org/software/bash/manual/bash.html#Bash-Startup-Files), including [notes on interactive shell](https://www.gnu.org/software/bash/manual/bash.html#Interactive-Shells), especially **behavior of an interactive shell**.

Over years of fiddling with bash startup, my startup setup has become overly complex than needed and may not suit well for your need. At minimum, I prefer to have following in bash startup sequence:

1. Keep minimal configuration (bash code) in the user *~/.bash_profile* and rather keep all of custom configuration commands under *~/.profile.d/* directory.
2. Under user *~/.profile.d/*, organize a few bash script based on order you like your bash startup to setup, e.g., *~/.profile.d/A01.sh* should load commonly used bash env variables related, e.g., `EDITOR` to define default text editor, `TZ` to set default timezone, etc. Then, *~/.profile.d/A02.sh* should have additional configurations for other packages, e.g., R, Julia, etc. which otherwise we populated in *~/.bash_profile* above.
3. Keep minimal configuration in the user *~/.bashrc* file as this may not be loaded with non-interactive, non-login session, e.g., submitting a job to compute nodes without passing bash env of a terminal session or certain commands in R and python using system command to execute bash command(s). Ideally, you like to keep _aesthetic_ configurations in *~/.bashrc* file like setting up terminal fonts and colors, managing bash history, etc. You may also optionally create *~/.bash_aliases* to store bash short codes that you may use while doing command-line interactive work.
4. Contrary to a default setup of conda instructions in *~/.bashrc*, **avoid such major env configuration** in *~/.bashrc* as it may not be loaded in non-interactive sessions, i.e., `mamba activate` or `mamba deactivate` may not work within a running shell script or snakemake workflows before running mamba init code. Conda setup may change in future (an active issue  https://github.com/conda/conda/issues/8072) but until then, I will move conda initialization code from *~/.bashrc* to *~/.bash_profile*, specifically after loading *~/.bashrc* but before loading *~/.profile.d/void* block (see below).
5. bash startup sequence also includes system default configurations, e.g., setting up default modules to run a workload manager like slurm and a singularity container. These instructions are typically located under */etc/profile* file and */etc/profile.d/* directory, both of these will be sourced in the very beginning. These configurations are essential for working on HPC, including submitting jobs to compute nodes. However, sometimes default modules may alter PATH and LD_LIBRARY_PATH variables such that it may conflict with your custom env setup. If so, you can **reconfigure** respective variables using bash command(s) in *~/.profile.d/void/VA01.sh* and similar shell files. These files under *void/* will be loaded after bash has initialized system default configurations, i.e., sourced */etc/profile* file and shell files under */etc/profile.d/* directory, and therefore, any of bash commands within *~/.profile.d/void/VA01.sh* file will override the respective configuration set earlier.
6. I emphasized **reconfigure** and **not resetting** earlier because you should be very careful of resetting PATH and LD_LIBRARY_PATH. You may get locked out of HPC login node and may need a help of sysadmin to let you in again!

>PS: I do reset PATH at the very end of *~/.bash_profile* once bash startup sequence has traversed across all of files detailed above and shown in flow diagram below. By doing so, I can get a consistent bash login environment. However, this is an overkill and you can sure get a stable bash env without such reset.

!!! warning "Order of precedence matters"
    Be aware of how bash startup sequence will load these files. Check a flow diagram under _My bash startup sequence_ below.

    For example, if I set `PATH` variable as `export PATH=/a/b/c:/p/q/r` in *~/.profile.d/A01.sh* and then I add `export PATH=/p/q/r:/a/b/c` in *~/.profile.d/A02.sh*, bash startup sequqence will overwrite previous PATH with an updated PATH from A02.sh file.

??? abstract "My bash startup sequence: flow diagram"
    Following diagram represents sequence of files (containing bash code) that gets sourced each time I login to HPC.

    If plot is not visible below, you can view plot by pasting following code to [mermaid live editor](https://mermaid-js.github.io/mermaid-live-editor/).

    ```mermaid
    graph TB
      A[System <br>/etc/profile] --> B[User<br>.bash_profile]
      B --> C{User .profile.d/ directory};
      C -->|Yes| D[source .profile.d/A01.sh];
      D -.-> E[source .profile.d/A02.sh];
      E -.-> F[source .profile.d/Z99.sh];
      F --> G;
      C --> |No| G{User .bashrc};
      G --> |Interactive shell<br>PS1 var is set| H[source /etc/bashrc]
      H --> I[User .bash_aliases]
      I --> J[bash terminal config, <br> e.g., colors, history, etc.]
      J --> K[Initialize<br>Conda Environment]
      G --> |Non-interactive shell<br>PS1 var is unset| K
      L[User .profile.d/void] --> M[source <br> .profile.d/void/VA01.sh];
      M -.-> N[source <br> .profile.d/void/VZ99.sh];
      K --> L;
      N --> O[Set PATH]
      O --> P[Set PS1]
    ```

    [![](https://mermaid.ink/img/eyJjb2RlIjoiICAgIGdyYXBoIFRCXG4gICAgICBBW1N5c3RlbSA8YnI-L2V0Yy9wcm9maWxlXSAtLT4gQltVc2VyPGJyPi5iYXNoX3Byb2ZpbGVdXG4gICAgICBCIC0tPiBDe1VzZXIgLnByb2ZpbGUuZC8gZGlyZWN0b3J5fTtcbiAgICAgIEMgLS0-fFllc3wgRFtzb3VyY2UgLnByb2ZpbGUuZC9BMDEuc2hdO1xuICAgICAgRCAtLi0-IEVbc291cmNlIC5wcm9maWxlLmQvQTAyLnNoXTtcbiAgICAgIEUgLS4tPiBGW3NvdXJjZSAucHJvZmlsZS5kL1o5OS5zaF07XG4gICAgICBGIC0tPiBHO1xuICAgICAgQyAtLT4gfE5vfCBHe1VzZXIgLmJhc2hyY307XG4gICAgICBHIC0tPiB8SW50ZXJhY3RpdmUgc2hlbGw8YnI-UFMxIHZhciBpcyBzZXR8IEhbc291cmNlIC9ldGMvYmFzaHJjXVxuICAgICAgSCAtLT4gSVtVc2VyIC5iYXNoX2FsaWFzZXNdXG4gICAgICBJIC0tPiBKW2Jhc2ggdGVybWluYWwgY29uZmlnLCA8YnI-IGUuZy4sIGNvbG9ycywgaGlzdG9yeSwgZXRjLl1cbiAgICAgIEogLS0-IEtbSW5pdGlhbGl6ZTxicj5Db25kYSBFbnZpcm9ubWVudF1cbiAgICAgIEcgLS0-IHxOb24taW50ZXJhY3RpdmUgc2hlbGw8YnI-UFMxIHZhciBpcyB1bnNldHwgS1xuICAgICAgTFtVc2VyIC5wcm9maWxlLmQvdm9pZF0gLS0-IE1bc291cmNlIDxicj4gLnByb2ZpbGUuZC92b2lkL1ZBMDEuc2hdO1xuICAgICAgTSAtLi0-IE5bc291cmNlIDxicj4gLnByb2ZpbGUuZC92b2lkL1ZaOTkuc2hdO1xuICAgICAgSyAtLT4gTDtcbiAgICAgIE4gLS0-IE9bU2V0IFBBVEhdXG4gICAgICBPIC0tPiBQW1NldCBQUzFdIiwibWVybWFpZCI6eyJ0aGVtZSI6ImRlZmF1bHQifSwidXBkYXRlRWRpdG9yIjpmYWxzZSwiYXV0b1N5bmMiOnRydWUsInVwZGF0ZURpYWdyYW0iOmZhbHNlfQ)](https://mermaid-js.github.io/mermaid-live-editor/edit#eyJjb2RlIjoiICAgIGdyYXBoIFRCXG4gICAgICBBW1N5c3RlbSA8YnI-L2V0Yy9wcm9maWxlXSAtLT4gQltVc2VyPGJyPi5iYXNoX3Byb2ZpbGVdXG4gICAgICBCIC0tPiBDe1VzZXIgLnByb2ZpbGUuZC8gZGlyZWN0b3J5fTtcbiAgICAgIEMgLS0-fFllc3wgRFtzb3VyY2UgLnByb2ZpbGUuZC9BMDEuc2hdO1xuICAgICAgRCAtLi0-IEVbc291cmNlIC5wcm9maWxlLmQvQTAyLnNoXTtcbiAgICAgIEUgLS4tPiBGW3NvdXJjZSAucHJvZmlsZS5kL1o5OS5zaF07XG4gICAgICBGIC0tPiBHO1xuICAgICAgQyAtLT4gfE5vfCBHe1VzZXIgLmJhc2hyY307XG4gICAgICBHIC0tPiB8SW50ZXJhY3RpdmUgc2hlbGw8YnI-UFMxIHZhciBpcyBzZXR8IEhbc291cmNlIC9ldGMvYmFzaHJjXVxuICAgICAgSCAtLT4gSVtVc2VyIC5iYXNoX2FsaWFzZXNdXG4gICAgICBJIC0tPiBKW2Jhc2ggdGVybWluYWwgY29uZmlnLCA8YnI-IGUuZy4sIGNvbG9ycywgaGlzdG9yeSwgZXRjLl1cbiAgICAgIEogLS0-IEtbSW5pdGlhbGl6ZTxicj5Db25kYSBFbnZpcm9ubWVudF1cbiAgICAgIEcgLS0-IHxOb24taW50ZXJhY3RpdmUgc2hlbGw8YnI-UFMxIHZhciBpcyB1bnNldHwgS1xuICAgICAgTFtVc2VyIC5wcm9maWxlLmQvdm9pZF0gLS0-IE1bc291cmNlIDxicj4gLnByb2ZpbGUuZC92b2lkL1ZBMDEuc2hdO1xuICAgICAgTSAtLi0-IE5bc291cmNlIDxicj4gLnByb2ZpbGUuZC92b2lkL1ZaOTkuc2hdO1xuICAgICAgSyAtLT4gTDtcbiAgICAgIE4gLS0-IE9bU2V0IFBBVEhdXG4gICAgICBPIC0tPiBQW1NldCBQUzFdIiwibWVybWFpZCI6IntcbiAgXCJ0aGVtZVwiOiBcImRlZmF1bHRcIlxufSIsInVwZGF0ZUVkaXRvciI6ZmFsc2UsImF1dG9TeW5jIjp0cnVlLCJ1cGRhdGVEaWFncmFtIjpmYWxzZX0)

!!! info "Example bash startup files"
    Fix link - You can :octicons-file-code-16: [download my bash startup files]({{ repo.url }}{{ repo.tree }}/confs/hpc/user_env/). It will not work by cloning into your linux env. However, each file has inline comments that should help customizing your bash startup.

And that's all! :checkered_flag:

My setup for our CPU-based Sumner HPC or for that matter, a generic linux-based machine is now complete. Since our HPC env at JAX shares the common home directory and base linux image (CentOS 7) between CPU (Sumner) and GPU (Winter) based HPC, the above setup will work off-the-shelf on the Winter HPC too **except** for tasks which require GPU-based computing, e.g., using GPU-based tensorflow and pytorch libraries. For the latter, I will setup a dedicated GPU-based conda env, _rey_ (and _ben_ and _gorgu_!) and tweak bash startup such that I get GPU-based bash env only when I login to Winter and to Sumner HPC.

For GPU-based setup, go to [Part 4](../../gpu/winter_1/).
