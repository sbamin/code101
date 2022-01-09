---
title: "Setting up GPU env - Part 1"
description: "Winter HPC Setup 2021: Part 1"
keywords: "winter,hpc,gpu,tensorflow,keras,pytorch,machine_learning,conda,jupyter"
wip: true
---

Winter HPC at JAX is a GPU-based computing cluster and it is powered by [NVIDIA(r) V100 series](https://www.nvidia.com/en-us/data-center/v100/) GPU cards. If you are working on GPU-based HPC or linux env, following page should guide you on setting up commonly used GPU libraries, e.g., [Tensorflow 2](https://www.tensorflow.org/), [Keras](https://keras.io/about/), and [PyTorch](https://pytorch.org/). GPU setup involves several technical jargon related to hardware compliant libraries, e.g., CUDA toolkit if using NVIDIA marketed GPU cards. I will not go into details of each step here and instead link to installation guide for further details. Knowing such details should be useful while working with deep learning tools and debugging runtime errors.

Before starting GPU setup, I expect that you have finished CPU setup, up until [Part 3](../../cpu/sumner_3/), mainly installing [_yoda_ env](../../cpu/sumner_2/#create-a-new-env) and [bash startup sequence](../../cpu/sumner_3/#bash-startup).

## Login to GPU HPC

First, let's move away from CPU HPC, aka Sumer HPC at JAX, and instead login to GPU HPC, i.e., Winter HPC at JAX. We have a common linux base operating system (OS), i.e., Cent OS 7 and a user home directory for both HPCs, hence I will have an identical bash env - via [bash startup sequence](../../cpu/sumner_3/#bash-startup) - in Winter as of Sumner.

??? info "home directory and operating system"
    If you have a separate OS and a home directory for CPU and GPU HPCs, you need to start from a scratch in setting up GPU HPC, i.e., initial setup is identical to [CPU setup](../../cpu/sumner_1/), preferably all three parts or at least installing _yoda_ env and bash startup sequence.

    If you have an identical home directory but different OS, e.g., Cent OS 6 on CPU HPC and Cent OS 7 on GPU HPC, that's a bad system design in my view as it will be challenging - at least to me - to separate software compilation libraries by modifying PATH, LD_LIBRARY_PATH, etc. and configuration locations, e.g., ~/.local and ~/.config under the shared bash env.

*   Login to Winter HPC

```sh
ssh winter
```

>If you have set [bash startup sequence](../../cpu/sumner_3/#bash-startup) earlier, you should expect ~identical[^diff_bash_env] bash env, including ordering of paths (output of `echo $PATH`) between CPU and GPU HPCs.

[^diff_bash_env]: There could be a difference though if both HPCs do not share common OS or they are using different system defaults, e.g., loading different bash env from `/etc/profile` which is managed by HPC staff.

*   Start an interactive job, so that we can use compute and not login node for setup/ This is to avoid our setup being potentially killed on the login node due to compute and/or memory intensive commands we will run during setup.

```sh
## interactive job command may vary across HPCs
## requesting partition: gpu with one gpu core
srun --job-name=gpusetup --qos=dev --time=08:00:00 --mem=8G --nodes=1 --ntasks=2 --mail-type=FAIL --export=all --gres gpu:1 --pty bash --login
```

>Notice that I now use `bash --login` over `bash` to force interactive login. Details under [bash startup sequence](../../cpu/sumner_3/#bash-startup).

Once you are in the interactive session, bash prompt will change to *user@winter200* or some other number than the original login node. We are going to create a new and dedicated conda env for GPU HPC, named _rey_. That said, we can use previously setup conda env for CPU HPC here too!

*   For example, to start R session on GPU HPC:

```sh
mamba activate yoda
R
```

You should be able to interact with R same as you do on CPU HPC, as long as both HPCs have shared storage paths and an identical OS.

!!! warning "Avoid managing conda env across HPCs"
    While it should not matter if you are managing conda env on CPU or GPU HPC, e.g., installing or upgrading conda packages, I prefer to manage all of [CPU optimized conda envs](../../cpu/sumner_2/#create-a-new-env), i.e., _base_, _yoda_, _leia_, etc. from Sumner (CPU) HPC. Accordingly, I will use Winter GPU HPC to manage GPU-optimized conda env, i.e., _rey_ and _ben_. This is particularly important for managing GPU env as CUDA and other GPU-specific libraries are not available on CPU HPC and so, installing or upgrading GPU packages may fail if you use CPU HPC to manage GPU env.

Let's deactivate _yoda_ and return to _base_ env in the Winter HPC.

```sh
mamba deactivate
```

## Create a GPU env _rey_

Now, we are going to install *sizable* (3 GB or more) worth of packages into a new conda env, _rey_. These packages form core of deep learning or specifically provide set of algorithms to employ artificial neural network based machine learning.

```sh
mamba create -c conda-forge -c pytorch -n rey python=3.9 tensorflow-gpu keras pytorch torchvision torchaudio cudatoolkit=11.1.1 cudatoolkit-dev=11.1.1 scikit-learn xgboost r-base=4.1.1 r-tensorflow r-keras r-tfdatasets tensorflow-hub cupy dask dask-ml pyopencl pocl 

## lazy way to check if above command had any errors.
## should return 0, meaning successful execution of
## the most recent previous command.
echo $?
```

==Before running above command, please know what we are installing here:==

*   Create a new conda env, _rey_ for GPU-based HPC.
*   Install all packages with the highest preference from _conda-forge_ channel followed by _pytorch_. [PyTorch](https://pytorch.org) is a a commonly used deep learning library and PyTorch team distributes some of dependencies with their own conda channel.
*   For all practical purposes, we will try to keep _rey_ env similar to _yoda_ env while adding GPU support in _rey_. Accordingly, we need to ensure that we are using similar `major.minor` version for Python and R - two major programming languages that I use on daily basis.
    *   I am using python 3.10 in _yoda_. However, python 3.10 support is [not yet available](https://github.com/pytorch/pytorch/issues/66424 for PyTorch), a commonly used deep learning library. Hence, I am specifying `python=3.9` to ensure that `mamba create` will do the best to keep that version. You may try using the same python version as you have in _yoda_ env, and check if `mamba create ...` command above throws an error regarding conflicting versions. If it does, update `=3.XX` to a one lower minor version until mamba allows you to create a new env, _rey_.
    *   Same logic for R by using `r-base=4.1.1` to match R version in _yoda_ env. Please read **important notes below** on using R packages across two or more conda envs.
*   Install popular ML frameworks with GPU support: [Tensorflow 2](https://www.tensorflow.org/install/gpu), [Keras](https://keras.io/getting_started), and [PyTorch](https://pytorch.org/get-started/locally). Keras now ships with Tensorflow 2 and so specifying keras in command above is optional.
    -   Notice that unlike restricting version for Python and R (to match with that in _yoda_ env), we are not specifying versions for any of ML libraries. Doing so has one drawback that in rare cases, conda may end up installing an older but compatible version (with our Python and R) of one or more ML libraries. If this happens and you are in need of the latest ML library, you have an option to create yet another conda env to install the most recent ML library at the cost of possibly installing a different version of Python and R than one in _yoda_ env.
*   CUDA toolkit is the heart of leveraging GPU support on Winter HPC. Using conda, we are installing CUDA toolkit and related development kit to install NVIDIA(r) [cuDNN library](https://developer.nvidia.com/cudnn). However, we will **ensure - by appending, `=11.1.1` to a package - that CUDA toolkit version must match that of system installed CUDA drivers by HPC staff**. If there is a mismatch, GPU hardware (NVIDIA V100 card) may fail to recognize our instructions (commands) to perform machine learning analysis.
    *   For Winter HPC at JAX, I am using ==CUDA 11.1.1== based on available drivers in Winter HPC. These drivers are typically configured using HPC modules and you can list those using `module available` and then list details for a specific drivers, e.g, `module show cuda11.1/toolkit/11.1.1`. Besides toolkit, HPC staff also provides following other core drivers which may be required for installing or running a specific GPU-compiled package. For now, I am not loading any of these default modules and instead relying on conda-managed (and minimal) packages.

    ```
    cuda11.1/blas/11.1.1
    cuda11.1/fft/11.1.1
    cuda11.1/nsight/11.1.1
    cuda11.1/profiler/11.1.1
    cuda11.1/toolkit/11.1.1 
    ```

*   We will also install [scikit-learn](https://scikit-learn.org) and [XGBoost](https://xgboost.readthedocs.io/en/stable/), two popular libraries for machine learning at-large. 
*   Then, I will install GPU support for R language and a few packages for using [Tensorflow for R](https://tensorflow.rstudio.com/tutorials/).
    *   We have earlier [installed R](../../cpu/sumner_2/#installing-r) in _yoda_ but we cannot use it in _rey_ env. To leverage R for machine (and deep) learning, I will install the identical R version, i.e. 4.1.1 in conda env, _rey_. That way, I can use most of R packages from _yoda_ (CPU-based) env for use in _rey_ (GPU-based) env.

!!! warning "Careful sharing R packages across two or more conda envs"
    Do note that some R packages requires additional packages (libraries) to be installed in the respective conda env, e.g., rJava requires `java` from _yoda_ env and may not work with _rey_ env. In such cases, use `mamba install` to install such packages in _rey_ while on GPU env but *avoid* running `install.packages` command from a R session running in _rey_ env. Why?

    I have briefly touched on this issue in [Part 3: Tips on compiling packages](../../cpu/sumner_3/#tips-on-compiling-packages). If we use `install.packages` from _rey_ env, it will end up installing the same package, e.g., `rJava` and perhaps, all of its dependencies into the same library path as of _yoda_ env, i.e., as defined by first entry of `.libPaths()`. That is a recipe for warnings and errors because doing so will inevitably mix up library dependencies between two different conda envs, each optimized for CPU and GPU.

    There is a solution though! We can update `.libPaths()` for _rey_ on-the-fly when we activate or deactivate _rey_ env ([explained later](#renviron-setup)) and that way, we can ensure that `install.packages` _should_ install packages in _rey_ specific R package path. I say "should" as R may end up updating packages in any of user-writable paths, even if the path is set as a second or lower preference.

    In nutshell, to avoid breaking R in multiple conda env, use `mamba install` or `mamba update` over R `install.packages()` when possible.

*   I will also install a few additional packages for image classification and related machine learning purpose. These are: [cupy](https://cupy.dev), [dask](https://docs.dask.org), [dask-ml](https://ml.dask.org), [pyopencl, and pocl](https://documen.tician.de/pyopencl). A notable exception is that I am not installing [Theano](https://github.com/Theano/Theano) which is not under active development but now forked as [Aesara](https://github.com/aesara-devs/aesara).
*   I am installing all major packages at once to ensure package dependencies are not in conflict and we have a stable GPU env.
*   While some of packages, e.g., r-tensorflow may work on CPU-based HPC too, I would recommend to use this conda env only on the GPU-based HPC as most of packages require GPU support.

## Test GPU functionality

Once we have _rey_ env ready, we can test GPU functionality of installed packages. This is not a required step but I like to make sure that I am using GPU and not CPU for computation, e.g., tensorflow and r-keras package may fall back to CPU if it finds missing or badly configured support for GPU.

*   Let's activate _rey_ and power up GPU!

```sh
mamba activate rey
```

*   Check NVIDIA driver version

```sh
nvcc --version
```

```
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2020 NVIDIA Corporation
Built on Mon_Oct_12_20:09:46_PDT_2020
Cuda compilation tools, release 11.1, V11.1.105
Build cuda_11.1.TC455_06.29190527_0
```

*   Check GPU usage activity on the compute node using `nvidia-smi`. This command is from a system-installed cuda libraries, typically under `/usr/bin` or `/usr/local/bin`. On Winter HPC at JAX, it is only available on compute nodes and not on a login node.

## Jupyter kernels

Let's install Python and R jupyter kernels for _rey_ with [configuration](../../cpu/sumner_2/#python-kernel) similar to that for _yoda_ env.

*   First, we will install required packages. Here, I am not interested in installing bash_kernel as I did with _yoda_ as I rarely use bash kernel and rather prefer terminal. If installing reticulate and rpy2 packages throw warnings about potential upgrade or downgrade of existing packages in _rey_ env, please **do not ignore warnings** and instead [follow steps under installing respective packages in _yoda_ env](../../cpu/sumner_2/#reticulate-r-package).

```
mamba install -c conda-forge ipykernel r-irkernel r-reticulate rpy2
```

*   Setup Python jupyter kernel for _rey_

```sh
python -m ipykernel install --user --name rey_py39 --display-name "rey_py39"

## confirm that installation exited without any error
## this should return 0 for successful installation
echo $?
```

*   Setup R jupyter kernel for _rey_

```r
library(IRkernel)
installspec(name = "rey_r41", displayname = "rey_r41", user = TRUE)

## quit R session
q(save = "no")
```


!!! warning "Configure Python and R kernel loading for _rey_"
    Don't forget to [tweak kernel loading](../../cpu/sumner_2/#kernel-loading) as we did for _yoda_ env else you may encounter issues running GPU-based packages in JupyterLab env.

    Pro Tip: You can use conditional expression in kernel wrapper, so kernel can only load on GPU-enabled HPC.

    ```sh
    if [[ "$(hostname)" != *"winter"* ]]; then
        echo -e "ERROR: Invalid hostname\nThis kernel works only on winter HPC\n" >&2
        exit 1
    else
        #### Activate CONDA in subshell ####
        ## Read https://github.com/conda/conda/issues/7980
        CONDA_BASE=$(conda info --base) && \
        source "${CONDA_BASE}"/etc/profile.d/conda.sh && \
        conda activate rey
        #### END CONDA SETUP ####

        ## Load additional CUDA drivers, toolkit, etc.
        ## if applicable prior to initializing kernel
        # module load cuda11.1/toolkit/11.1.1

        ##... rest of kernel setup as explained earlier.
    ```

### Renviron setup

As explained above in the warning box, be careful installing packages using R from more than one conda envs and instead prefer using `mamba install` or `mamba update` to manage R packages. 

When we start R, it reads _~/.Renviron_ file or takes precedence based on order as detailed on [CRAN - startup](https://cran.r-project.org/web/packages/startup/vignettes/startup-intro.html) webpage. Accordingly, we will create a _rey_ env-specific R Renviron file such that loading R in _rey_ env will use rey specific library path to install new packages[^warnrpkg], and will not install those under a default library path for _yoda_ that we specified [earlier in the setup](../../cpu/sumner_2/#setup-rprofile-and-renviron).

[^warnrpkg]: See [warning box above](#create-a-gpu-env-rey) on why our setup can still update R packages managed by _yoda_ env despite using custom Renviron file.

*   Let's create an empty directory to store _rey_ env specific user R packages.

```sh
mkdir -p /projects/verhaak-lab/amins/hpcenv/opt/R/pkgs/rey4.1
```

*   Create an env specific config directory at the place you like and create a Renviron file inside it.

```sh
mkdir -p /projects/verhaak-lab/amins/hpcenv/opt/R/confs/rey
cd /projects/verhaak-lab/amins/hpcenv/opt/R/confs/rey

## create a Renviron file
nano Renviron
```

*   Add following to Renviron file, i.e., we take the `R_LIBS` path from _~/.Renviron_ file we [created earlier](../../cpu/sumner_2/#setup-rprofile-and-renviron), and then **prefix** _rey_ env specific paths to it. Here, _rey_ env path consist of two parts:
    *   First, _/projects/verhaak-lab/amins/hpcenv/opt/R/pkgs/rey4.1_ is a newly created custom path where `install.packages` command can install new packages while working in _rey_ but not _yoda_ env.
    *   Second, _rey_ env default R library path that we got from `.libPaths()` output: _/projects/verhaak-lab/amins/hpcenv/mambaforge/envs/rey/lib/R/library_. This path is used by `mamba install` or `mamba update` for managing R packages.

```r
R_LIBS="/projects/verhaak-lab/amins/hpcenv/opt/R/pkgs/rey4.1:/projects/verhaak-lab/amins/hpcenv/mambaforge/envs/rey/lib/R/library:/projects/verhaak-lab/amins/hpcenv/opt/R/pkgs/4.1:/projects/verhaak-lab/amins/hpcenv/mambaforge/envs/yoda/lib/R/library
```

*   Now setup a custom loading of Renviron for _rey_ env. This will make sure that R environ will switch/revert every time conda env, _rey_ is loaded/unloaded via `mamba activate/deactivate` command.

```sh
cd /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/rey/etc/conda

## create a new file
nano activate.d/activate-r-env.sh
```

*   Add following to *activate.d/activate-r-env.sh*

```sh
#!/usr/bin/env sh

## Define R_HOME from rey env
R_HOME="$CONDA_PREFIX/lib/R"
## override ~/.Renviron which otherwise point to R from yoda env
R_ENVIRON_USER="/projects/verhaak-lab/amins/hpcenv/opt/R/confs/rey/Renviron"

export R_HOME R_ENVIRON_USER
```

!!! tip "load custom user setup after default setup"
    [bash startup](../../cpu/sumner_3/#bash-startup) reads file in alphanumeric order. There could be other R setup files, e.g., *activate.d/activate-r-base.sh*. So, make sure to name custom file(s), e.g., _activate-r-env.sh_ file such that it loads after R specific default files. 

*   Similarly create a *deactivate.d/deactivate-r-env.sh* to unload custom changes when we do `mamba deactivate` to turn off _rey_ env.

```sh
nano deactivate.d/deactivate-r-env.sh
```

*   and add following:

```sh
#!/usr/bin/env sh

## fall back to pre-existing R env
unset R_HOME R_ENVIRON_USER
```

!!! info "Prefer `mamba deactivate` followed by `mamba activate <env name>`"
    `unset` command will erase and not restore the matching custom env variables, if any. So, ideally you should do `mamba deactivate` to turn off _rey_ and then do `mamba activate yoda` to properly activate _yoda_ env to restore custom set env variables and all of env specific bash startup under respective *activate.d/* directory. 

*   Now logout and login to winter HPC again. Do `mamba activate rey` and start R, and type `.libPaths()`. Now, exit R and type do `mamba deactivate` followed by `mamba activate yoda`. Start R and type `.libPaths()`. Notice difference in R library paths under two R sessions!

## Optional Setup

Following packages are optional for setup.

### Tensorboard

[Tensorboard](https://www.tensorflow.org/tensorboard) graphical user interface (GUI) ships with Tensorflow 2 and so does not require additional configuration.

*   Check version for tensorflow and tensorboard

```sh
## in rey env
python -c 'import tensorflow as tf; print(tf.__version__)' #2.6.2 or higher
python -c 'import tensorboard as tb; print(tb.__version__)' #2.6.0 or higher
```

*   Checkout [getting started guide](https://www.tensorflow.org/tensorboard/get_started) for more on how to use GUI app. If tensorboard python notebook extension, `%load_ext tensorboard` fails to initialize tensorboard within notebook, you can manually initialize tensorboard using a terminal command as follows: 

```sh
tensorboard serve --logdir logs --host <IP address to bind to>
```

>where IP address can be a localhost or `hostname -I` as long as it is on the secure network. Tensorboard should be accessible at an unsecure http address shown in the output of above command.

*   To quit tensorboard web server on the terminal, press ++ctrl+c++.

### TensorRT

[NVIDIA(r) TensorRT(tm)](https://developer.nvidia.com/tensorrt) a software development kit (SDK) for NVIDIA compliant GPU cards. Conda does not provide TensorRT package, so we need to install it using [getting started guide](https://developer.nvidia.com/tensorrt-getting-started) and [installation using tarball](https://docs.nvidia.com/deeplearning/tensorrt/install-guide/index.html#installing-tar) instructions. This requires membership into NVIDIA developer program.

*   Download tarball specific to CUDA and cuDNN version as determined by following commands. Accordingly, I have downloaded 

TensorRT-8.2.2.1.Linux.x86_64-gnu.cuda-11.4.cudnn8.2.tar.gz
TensorRT-6.0.1.5.CentOS-7.6.x86_64-gnu.cuda-10.1.cudnn7.6.tar.gz.

```sh
## CUDA version, 11.1
nvcc --version
## cuDNN version 8.2
cat ${CONDA_PREFIX}/include/cudnn_version.h | grep CUDNN_MAJOR -A 2
```

*  




### Image Classification

Libraries specific to cell segmentation

#### Cellprofiler

#### Cellpose

#### Stardist

## Update bash startup

Finally, I am tweaking [bash startup sequence](../../cpu/sumner_3/#bash-startup) that we setup earlier, such that it can allow loading GPU-specific bash env only when we login to Winter GPU HPC and not on Sumner CPU HPC. I have made following changes to bash startup. You can :octicons-file-code-16: [download my bash startup files here]({{ repo.url }}{{ repo.tree }}/confs/hpc/user_env/).

*   Update `SET PATH` block of *~/.bash_profile* to reset PATH for Winter GPU. See my notes under `elif [[ "$(hostname)" == *"winter"* ]]; then` section in :octicons-file-code-16: an example [.bash_profile]({{ repo.url }}{{ repo.blob }}/confs/hpc/user_env/.bash_profile) file.
*   Update *~/.profile.d/void/VW01_set_winter_gpu.sh* to load Winter specific settings. See more into an example [VW01_set_winter_gpu.sh]({{ repo.url }}{{ repo.blob }}/confs/hpc/user_env/.profile.d/void/VW01_set_winter_gpu.sh) file.

Logout and login again to Winter HPC. You will see a near identical bash prompt like Sumner HPC, e.g., `user@winter-log1`. However, when you check `echo $PATH` output and `echo $CONDA_DEFAULT_ENV`, you will notice that a default conda env in Winter HPC is now _rey_ while in Sumner HPC, it is _base_ (sometimes called _root_). Of course, you can revert to base or any other conda env in Winter HPC by doing `mamba deactivate` (because we changed from base to rey during bash startup) and then `mamba activate base` (or yoda, or any other env).

## Done!

Hope you have found this documentation helpful to get you started with HPC setup. I will post a few external resources on getting started guide to learn programming in Python, R, and more. Best wishes!
