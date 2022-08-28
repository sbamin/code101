---
title: "Setting up CPU env - Part 1"
description: "Getting started with HPC Setup. Part 1: Setup conda from scratch or replace an older environment."
keywords: "hpc,setup,conda,bash,programming,jax,sumner"
comments: true
tags:
    - hpc
    - setup
    - conda
    - bash
    - programming
---

## Set up for HPC Sumner

There are at least two scenarios with an existing HPC env:

1. We start setting up HPC env from scratch, i.e., right after login to HPC login node for the first time or
2. We already have an existing custom setup, e.g., using linuxbrew or even conda, and we like to start from fresh setup. This is true (as in my case) when you may have setup conda env in your home directory and conda env grew in size over time that you are now approaching disk quota of 50 GB for home directory. So, now we like to move it to tier 1 space (`/projects/`) which has disk quota in TBs in not GBs.

Following will guide setting up HPC env for both scenarios.

!!! tip "Change user paths per your username and HPC paths"
    Most of setup below have commands and locations (paths) tied to my username, `amins` and our HPC cluster at [The Jackson Laboratory (JAX)](https://www.jax.org), namely Sumner and Winter HPC, one each of CPU and GPU-based computing. Please ensure that you edit paths such that it reflects your username and paths that are available for HPC at your institute.

### Option 1: Start from scratch

```sh
ssh userid@login.sumner.jax.org

## Know OS and kernel version
cat /etc/redhat-release
uname -a
```

>Running CentOS Linux release 7.7.1908 (Core)  
>Linux sumner-log1 3.10.0-1062.1.2.el7.x86_64 #1 SMP Mon Sep 30 14:19:46 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux 

*   First, login to sumner with a clean env, i.e., as it ships with default profile from HPC team, and nothing added in following files. Default bash configuration for sumner looks similar to following files. See example files in the source at :octicons-file-code-16: [confs/hpc/initials/]({{ repo.url }}{{ repo.tree }}/confs/hpc/initials/).

```
~/.bashrc
~/.bash_profile
~/.bash_aliases # if it exists
~/.profile # if it exists
```

>If you had custom bash configs (linuxbrew, previous conda, etc.), disable those by commenting out from above files. If you'd linuxbrew installed, make sure to disable it unless you are confident that conda and brew can work in harmony!
>Same goes for `~/.local/` directory which should not exist at the fresh startup. If it does, you may have installed some tools using python, perl, or other non-root based setup scripts. For clean setup, ~/.local directory needs to be removed from user environment, i.e., either rename it to say, ~/.local_deprecated or archive it somewhere! If you have made significant changes to HPC env, it is better to follow Option 2.

### Option 2: Override existing setup

Here, we essentially revert from our existing custom setup to fresh HPC env that we had on the day one of login to HPC, and then we start setting up a fresh HPC env that includes conda env and other space-occupying (julia, custon apps, etc.) softwares to resolve disk quota issue.

In order to reset to the fresh HPC env that we had on day one of login, we need to reset the entire bash login env to that of day one. Most of custom HPC env is managed by series of dot files (.bashrc, .Renviron, .Rprofile, etc.) and directories (.local, .config, etc.) in your home directory. So, in order to reset to day one env, I will archive these dot files and directories away from home directory (say *~/legacy_setup/*), and replace with dot files from HPC default env that we had on the day one of login[^dotdir]. **Please note** that if you are using non-bash shell, e.g., `zsh` or other, you do need to make sure to reset login env to the HPC default bash env.

[^dotdir]: There were no default dot directories on the day one.

!!! danger "☠️ Be careful moving dotfiles ☠️"
    Moving some of dotfiles is tricky as some of those files are needed for login to sumner, e.g., files within ~/.ssh/ directory,   If you are doing this, **make sure NOT to logout** of sumner and at the end of executing this code block on sumner, make sure that you can login from another :octicons-terminal-16: terminal to sumner.

*   Following script should be run manually unless you know for sure that it will exit without any error and will move all except essential dotfiles and dot directories to an archived directory. Also, make sure to check exit code by running `echo $?` immediately after running critical commands to make sure you had no error running those commands.

```sh
ssh userid@login.sumner.jax.org
cd "${HOME}" && \
echo "You are in home directory at $(pwd)"

## make an empty archived directory
mkdir -p "${HOME}"/legacy_env

## list files and directories that we will archive
ls -alh "${HOME}"/.[^.]* | tee -a "${HOME}"/legacy_env/list_dotfiles_dirs_"$(date +%d%b%y_%H%M%S_%Z)".txt
echo $?


## list HPC env that we will archive
env | tee -a "${HOME}"/legacy_env/hpc_sumner_env_"$(date +%d%b%y_%H%M%S_%Z)".log
echo $?

## Moving all dot files and dot directories
## Make sure to check exit code
mv "${HOME}"/.[^.]* legacy_env/
echo $?
```

!!! danger "Copy essential files and directories back to home directory"
    Do not forget to copy back following files to "${HOME}" else you may get locked out of sumner. You may not have all of following files/directories but at least run each command once to ensure that essential files/directories, e.g., ~/.ssh/ are in the home directory. Ideally, **confirm with your HPC staff** on which files and directories are essential as HPC env may vary across institutes.

```sh
cd "${HOME}" && \
echo "You are in home directory at $(pwd)"

## sumner ssh dir
rsync -avhP legacy_env/.ssh ./

## sumner login tokens, if any
cp legacy_env/.vas_* ./
cp legacy_env/.ksh* ./
cp legacy_env/.k5login ./
rsync -avhP legacy_env/.pki ./

## optional files, if any
## singularity may take a larger space 
rsync -avhP legacy_env/.singularity ./
rsync -avhP legacy_env/.terminfo ./
rsync -avhP legacy_env/.subversion ./
cp legacy_env/.emacs ./
cp legacy_env/.viminfo ./
cp legacy_env/.screenrc ./
```

*   Make following empty dirs. These are unix specific configuration directories where some of softwares we install at later will keep their respective configurations. Note that we already backed up previous configurations in these directories under *~/legacy_env*

```sh
cd "${HOME}" && \
echo "You are in home directory at $(pwd)"

mkdir -p "${HOME}"/.cache
mkdir -p "${HOME}"/.config
mkdir -p "${HOME}"/.local

## list dotfiles and dot dirs after reset
ls -alh "${HOME}"/.[^.]*
```

Notice that we now have a fewer (and essential) dot files and dot directories right under home directory.

Also, notice that we are missing essential dotfiles for loading bash login env, e.g., ~/.bashrc and ~/.bash_profile. These two files should originally be present when we logged to HPC on day one. Let's copy those original files back to home directory. I am using following default bash dotfiles but it may vary across different HPC env. **Contact your HPC staff for more.**

*   You can copy following dotfile and use text editor like `nano` or `vi` to paste contents to respective dotfiles.

=== "~/.bash_profile"

    ```sh
    # .bash_profile

    # Get the aliases and functions
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi

    # User specific environment and startup programs

    PATH=$PATH:$HOME/.local/bin:$HOME/bin

    export PATH
    ```

=== "~/.bashrc"

    ```sh
    # .bashrc

    # Source global definitions
    if [ -f /etc/bashrc ]; then
        . /etc/bashrc
    fi

    # Uncomment the following line if you don't like systemctl's auto-paging feature:
    # export SYSTEMD_PAGER=

    # User specific aliases and functions
    # This may vary across different HPC
    module load gcc
    ```

*   Now, you should ensure that you can login to HPC from a separate :octicons-terminal-16: terminal. **Do not logout** from an existing terminal yet!

```sh
ssh userid@login.sumner.jax.org
env
```

*   If above command succeeds and `env` looks similar (PATH in particular) to outputs of default env variables (set by HPC staff) below, you're good! You can then exit old sumner session and install anaconda3 from a new (with a fresh or reset env) terminal session.

=== "bash commands"

    ```sh
    ## paths where all executables can be found
    echo $PATH
    ```

    ```sh
    ## paths where shared libraries are available to run programs
    echo $LD_LIBRARY_PATH
    ```

    ```sh
    ## Used by gcc before compiling program
    ## Read https://stackoverflow.com/a/4250666/1243763 
    echo $LIBRARY_PATH
    ```

    ```sh
    ## default loaded modules
    module list
    ```

=== "expected output"

    ```
    /cm/local/apps/gcc/8.2.0/bin:/cm/shared/apps/slurm/18.08.8/sbin:/cm/shared/apps/slurm/18.08.8/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:.:/home/amins/.local/bin:/home/amins/bin
    ```

    ```
    /cm/local/apps/gcc/8.2.0/lib:/cm/local/apps/gcc/8.2.0/lib64:/cm/shared/apps/slurm/18.08.8/lib64/slurm:/cm/shared/apps/slurm/18.08.8/lib64
    ```

    ```
    /cm/shared/apps/slurm/18.08.8/lib64/slurm:/cm/shared/apps/slurm/18.08.8/lib64
    ```

    ```
    Currently Loaded Modules:
      1) shared           3) dot                   5) slurm/18.08.8
      2) DefaultModules   4) default-environment   6) gcc/8.2.0
    ```

??? info "Know what changes `module load` command can do"
    When you load a module, it configures one or more of PATH, LD_LIBRARY_PATH, and other env variables. Command: `module show <module name>` can show you list of changes that a module makes during loading, e.g.,

    ```sh
    module show gcc/8.2.0
    ```

    In this case, loading gcc module will change PATH and LD_LIBRARY_PATH variables by perpending following respective paths. `module unload gcc` should remove these paths.

    ```
    --------------------------------------------------------------------------------------------
       /cm/local/modulefiles/gcc/8.2.0:
    --------------------------------------------------------------------------------------------
    whatis("adds GNU Cross Compilers to your environment variables ")
    prepend_path("PATH","/cm/local/apps/gcc/8.2.0/bin")
    prepend_path("LD_LIBRARY_PATH","/cm/local/apps/gcc/8.2.0/lib:/cm/local/apps/gcc/8.2.0/lib64")
    help([[ Adds GNU Cross Compilers to your environment variables,
    ]])
    ```

*   Make sure to logout and login to sumner again for a clean env to take an effect. Once you login, your `env` should look something similar to above. Note that PATH and LD_LIBRARY_PATH variables should default to Cent OS 7 standard paths with **no user-defined paths** except `/home/amins/.local/bin:/home/amins/bin` if those directories are present.

!!! warning "Careful with user-defined paths"
    For error-free setup, these - `/home/amins/.local/bin:/home/amins/bin` - user-defined directories should be empty to begin with and must not take precedence over system-default paths in PATH and LD_LIBRARY_PATH. Once we install anaconda3 and other tools, we will modify ~/.bash_profile and loading of bash login env such that user-defined paths override system-default paths.

```sh
exit #from sumner

## login again
ssh login.sumner.jax.org
```

*   Store default hpc configuration

>Useful to fall back to HPC defaults if something goes awry!

```sh
mkdir -p ~/bkup/confs/hpc_default_env/

cp .bashrc bkup/confs/hpc_default_env/
cp .bash_profile bkup/confs/hpc_default_env/

## export global env
env | tee -a "${HOME}"/bkup/confs/hpc_default_env/hpc_sumner_env_"$(date +%d%b%y_%H%M%S_%Z)".log
```

## Configure defaults

Following configuration can vary across HPC env. Specifically, I prefer to keep minimal modules (tools that HPC staff installs as default) that are critical for login to HPC and compiling certain packages, e.g., CUDA libraries for Winter GPU-based HPC (detailed later in the setup).

*   `dot` module only appends `.` to PATH variable (see `module show dot`), so that you do not need to prefix `./` to run an executable file under present/current working directory. Since I do not need `dot` module, I will override default module loading by doing `module unload dot` in my bash configuration (later). 

*   For now, I do not need system gcc and will rely on conda-installed gcc and other devtools `x86_64-conda_cos6-linux-gnu-*`. More on that later but let's unload dot and gcc first.

```sh
module unload dot
module unload gcc
module list
```

```
Currently Loaded Modules:
  1) shared   2) DefaultModules   3) default-environment   4) slurm/18.08.8
```

*   For now, you may add following cmd to your ~/.bash_profile to unload dot and gcc at each login to HPC. Eventually it will go to ~/.profile.d/ setup detailed below.

```sh
module unload dot
module unload gcc
```

!!! warning "Make sure that gcc is unloaded"
    While settings in _~/.bash_profile_ should be respected during login to HPC, sometimes starting a pseudo-terminal, e.g., `screen` or `tmux` session may not source _~/.bash_profile_ due to directives related to [interactive versus non-interactive session](https://askubuntu.com/questions/879364/differentiate-interactive-login-and-non-interactive-non-login-shell). Then, you may notice that `gcc` module is not unloaded and still present under `module list` output. If so, manually unload `gcc` by `module unload gcc` after each time you enter into `screen` or `tmux` session or interactive HPC session (detailed below).

*   If you do not add unload command to ~/.bash_profile and rather rely on manually running unload command prior to anaconda installation, you do need ensure that these modules are unloaded in your current terminal, especially when starting a pseudo-terminal like screen, tmux, or slurm interactive job. In summary, **make sure to do** `module unload gcc` before running setup further.

```sh
exit #from sumner

## login again
ssh login.sumner.jax.org
```

## Install conda

*   Download and install anaconda3. I am using a variant of anaconda3 called, [Mambaforge](https://github.com/conda-forge/miniforge#mambaforge). It is based on Miniforge, a minimal conda installer (similar to minioconda) with an added support for conda-forge as a default channel and use of [Mamba](https://github.com/mamba-org/mamba) instead of default conda command to manage packages.

```sh
cd "$HOME" && \
mkdir -p Downloads/conda && \
cd Downloads/conda && \
wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh && \
md5sum Mambaforge-Linux-x86_64.sh > Mambaforge-Linux-x86_64.sh.md5
```

>md5: ab95d7b4fb52c299e92b04d7dc89fa95  Mambaforge-Linux-x86_64.sh

*   Prefer running setup on a dedicated interactive node instead of login node. Some of compute/memory-intensive conda install/update steps may get killed on a login node.

```sh
## start screen session prior to running interactive session
## doing so will keep remote interactive session alive if your connection 
## from local computer to HPC is lost.
screen

## run interactive job
## options may vary across HPC
srun -p compute -q batch -N 1 -n 3 --mem 10G -t 08:00:00 --pty bash

## unload gcc if loaded
module unload gcc
```

>You may not notice a change in login env except that your login prompt may change from a login node: `user@sumner-log1` to one of compute nodes: `user@sumner50`.

*   By default, conda will setup ~/anaconda3 (or ~/mambaforge if using mambaforge) under home directory. Since conda env can grow over time and home directories are typically capped at 50 GB or so (at least with our HPC env), we will setup conda env on tier 1 space at _/projects/verhaak-lab/amins/hpcenv/mambaforge_

```sh
cd "$HOME" && \
bash "${HOME}"/Downloads/conda/Mambaforge-Linux-x86_64.sh
```

*   Accept to license agreement and then set installation path to tier 1 space, e.g., _/projects/verhaak-lab/amins/hpcenv/mambaforge_ in my case.
    * Note that this will vary based on your username and available location on your HPC where you can store large amount of data. Conda env and related setup can grow over time and may exceed typical 50 GB quota for a user home directory. So, prefer installing conda and related env at location where you can store more data. For JAX, it's called tier 1 space under `/projects/<lab_name>/<user_name>/` path.
    *   Installer will start installing conda env and towards the end, it will prompt you for initializing conda env. Say yes! If you say no, you can follow instructions that installer outputs to ensure that you have a working conda env each time you login to HPC. To do so, conda needs to write a few lines of code to _~/.bashrc_ file, so that HPC login env will always start with a valid (by modifying PATH and a several other `env` variables) conda env.

```
Do you wish the installer to initialize Mambaforge
by running conda init? [yes|no]
[no] >>> no

You have chosen to not have conda modify your shell scripts at all.
To activate conda's base environment in your current shell session:

eval "$(/projects/verhaak-lab/amins/hpcenv/mambaforge/bin/conda shell.YOUR_SHELL_NAME hook)" 
## where YOUR_SHELL_NAME is bash or zsh or other shells.

To install conda's shell functions for easier access, first activate, then:

conda init

If you'd prefer that conda's base environment not be activated on startup, 
   set the auto_activate_base parameter to false: 

conda config --set auto_activate_base false

Thank you for installing Mambaforge!
```

*   Since I typed `no` above, I need to manually activate conda by following steps.

```sh
cd "${HOME}"

## replace shell.bash with shell.zsh or other shells you may be using by now.
## know which shell you are using in HPC
echo "$(basename ${SHELL})"

## activate conda base env in the current terminal
eval "$(/projects/verhaak-lab/amins/hpcenv/mambaforge/bin/conda shell.bash hook)"
```

>Once conda _base_ env has been activated, you will notice your login prompt changing from `user@sumner50` to `(base) [userid@sumner50]`. You can also check which conda env you are in by running `echo $CONDA_DEFAULT_ENV`. Since we have not installed additional conda env yet, we only have _base_ env to begin with. You can also run `echo $CONDA_PREFIX` to confirm that conda has been installed on non-default, tier 1 path and not under _~/mambaforge_.

*   Now, let conda edit _~/.bashrc_ file so conda can load _base_ env each time we login to HPC.

```sh
conda init

## if using mamba, also run mamba init
## to enable mamba activate/deactivate env
mamba init

## Check what code has been added to ~/.bashrc
cat ~/.bashrc
```

>You will notice that conda has now added initialization code to _~/.bashrc_

*   Our minimal conda installation is now complete. Logout from interactive session, and then logout from HPC. 

```sh
# exit from interactive session
exit

## exit from HPC
exit
```

[In Part 2](../sumner_2/), we will login and start an interactive session again to customize conda and HPC env.
