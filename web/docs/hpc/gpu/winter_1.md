---
title: "Setting up GPU env"
description: "Winter HPC Setup 2021"
keywords: "winter,hpc,gpu,tensorflow,keras,pytorch,machine_learning,conda,jupyter,segmentation"
comments: true
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

### Install essentials

I use following tools in routine and have installed these tools into _yoda_ env - a default for CPU-based HPC[^rlibs]. Similarly, I am installing in these tools here in _rey_ env too for GPU-based HPC.

[^rlibs]: [Installing common packages in yoda env](../../cpu/sumner_2/#install-r-libraries) and [installing essentials](../../cpu/sumner_2/#install-essentials).

```sh
mamba install -c conda-forge wget curl rsync libiconv parallel ipyparallel git rsync vim globus-cli tmux screen openjdk=11.0 r-rjava matplotlib r-reticulate rpy2
```

>For java (openjdk), prefer using the same version as in _yoda_, e.g., restrict java major.minor version to be 11.0 but allow a different patch (11.0.1 or 11.0.2,...).

## Loading GPU env

Once we have _rey_ env ready, we can check type of GPU, CUDA drivers, etc. We should also ensure that we configure CUDA drivers and related env variables correctly, so future installations of GPU tools, like TensorRT recognize CUDA related variables and work correctly.

### Check CUDA drivers

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

### Setup GPU env as Modulefile

Unfortunately, conda installed CUDA toolkit is not a full CUDA installation and it does not set any of CUDA related bash env variables, especially `CUDA_PATH`, `CUDA_HOME`, `CUDNN_PATH` variables. https://github.com/conda/conda/issues/7757 Since I have installed the identical cuda toolkit (v11.1.1) in _rey_ conda env to the one managed by out HPC admins, i.e., `module show cuda11.1/toolkit/11.1.1`, I will [create a module file](../../cpu/sumner_3/#modules) that includes combination of env variables from both of these toolkits. That way, I can load this module during [bash startup](#update-bash-startup) such that the module will configure GPU env only on the Winter (GPU) HPC and not on the Sumner (CPU) HPC.


*   Create an empty local directory structure to store user-installed GPU libraries, e.g., configs related to CUPTI, etc.

```sh
cd "${HPCAPPS}" && \
mkdir -p gpu/11.1.1/local
```

*   Following command will create directory scaffold similar to /usr/local env

```sh
cd "${HPCAPPS}"/gpu/11.1.1/local && \
mkdir -p {bin,etc,include,lib,lib64,libexec,share/{doc,info,locale,man/{man1,man3}}}
```

*   Create a module file at "${HPCMODULES}"

```sh
mkdir -p "${HPCMODULES}"/gpu
cd "${HPCMODULES}"/gpu

## create a module file that matches CUDA version.
touch 11.1.1
```

*   I have placed GPU configurations from both, admin installed CUDA drivers and GPU packages that I just have installed above. You may need to consult your HPC team to get an idea on configurations that you may able override with conda installed cuda toolkit.

!!! tip "Example modulefiles for GPU HPC"
    My gpu modulefile are at :octicons-file-code-16: [/confs/hpc/modules/def]({{ repo.url }}{{ repo.tree }}/confs/hpc/modules/def)

*   Once we have a modulefile ready, we can load custom gpu env using `module load gpu/11.1.1`.
*   Notice change in PATH, LD_LIBRARY_PATH, and related env variables. For now, you will notice that `"${CONDA_PREFIX}"/bin` is pushed behind other cuda related paths we have configured using modulefile. Since I prefer to have `"${CONDA_PREFIX}"/bin` take precedence over rest of `$PATH` contents, I will reset PATH such that `"${CONDA_PREFIX}"/bin`, i.e., `../envs/rey/bin` in Winter HPC, will take precedence over other paths that we are loading via above modulefile. See [bash startup](#update-bash-startup) section for details.

### Jupyter kernels

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

!!! tip "Example activate.d or deactivate.d scripts to manage conda envs"
    You can view example scripts per respective conda env at :octicons-file-code-16: [/confs/hpc/mambaforge/envs]({{ repo.url }}{{ repo.tree }}/confs/hpc/mambaforge/envs).

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

[NVIDIA(r) TensorRT(tm)](https://developer.nvidia.com/tensorrt) a software development kit (SDK) for NVIDIA compliant GPU cards. Conda does not provide TensorRT package, so we need to install it **using [getting started guide](https://developer.nvidia.com/tensorrt-getting-started) and [installation using tarball](https://docs.nvidia.com/deeplearning/tensorrt/install-guide/index.html#installing-tar) instructions**. This requires membership into NVIDIA developer program.

#### Installation steps

*   Download tarball specific to CUDA and cuDNN version as determined by following commands. 

```sh
## CUDA version, 11.1
nvcc --version
## cuDNN version 8.2
cat ${CONDA_PREFIX}/include/cudnn_version.h | grep CUDNN_MAJOR -A 2
```

*  Accordingly, I have downloaded following tarball: 
    *  TensorRT-8.2.2.1.Linux.x86_64-gnu.cuda-11.4.cudnn8.2.tar.gz

*   Extract tarball to apps folder and rename path to extracted contents, so that we can load TensorRT as a [module](../../cpu/sumner_3/#modules).

```sh
cd "${HPCAPPS}"

mkdir -p tensorrt
cd tensorrt

## place tarball in tensorrt directory and then extract it.
tar xvzf TensorRT-8.2.2.1.Linux.x86_64-gnu.cuda-11.4.cudnn8.2.tar.gz

## rename extracted directory for consistency on naming modules.
mv TensorRT-8.2.2.1 8.2.2.1
```

*   To install TensorRT, we need to temporarily export TensorRT library path to LD_LIBRARY_PATH. For future logins to GPU HPC, we can then load this path as and when needed using modulefile or permanently insert this into LD_LIBRARY_PATH for GPU HPC using GPU-specific [bash startup](#update-bash-startup).

```sh
export LD_LIBRARY_PATH="${HPCAPPS}/tensorrt/8.2.2.1/lib:${LD_LIBRARY_PATH}"
```

*   Install Python TensorRT wheel file. There are more than one file with different `cp3x`. I could not figure out what it means and so ended up installing the most recent one, i.e., `cp39`.

```sh
cd "${HPCAPPS}"/tensorrt/8.2.2.1/python && \
pip install tensorrt-8.2.2.1-cp39-none-linux_x86_64.whl |& tee -a tensorrt_8.2.2.1_install.log
```

??? info "Expected output:"

    ```
    Processing ./tensorrt-8.2.2.1-cp39-none-linux_x86_64.whl
    Installing collected packages: tensorrt
    Successfully installed tensorrt-8.2.2.1
    ```

*   Install Python UFF wheel file which is required for working with TensorFlow.

```sh
cd "${HPCAPPS}"/tensorrt/8.2.2.1/uff && \
pip install uff-0.6.9-py2.py3-none-any.whl |& tee -a tensorrt_8.2.2.1_install.log
```

??? info "Expected output:"

    ```
    Processing ./uff-0.6.9-py2.py3-none-any.whl
    Requirement already satisfied: numpy>=1.11.0 in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/rey/lib/python3.9/site-packages (from uff==0.6.9) (1.19.5)
    Requirement already satisfied: protobuf>=3.3.0 in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/rey/lib/python3.9/site-packages (from uff==0.6.9) (3.18.1)
    Installing collected packages: uff
    Successfully installed uff-0.6.9
    ```


!!! tip "When to use bash startup versus module file"
    Above installation step should include `convert-to-uff` in PATH which you can check within output of `which convert-to-uff`. Since installation has already inserted binaries, e.g., `convert-to-uff` into bash PATH variable, I will now prefer to setup TensorRT related PATH and LD_LIBRARY_PATH using [bash startup](#update-bash-startup) instead of loading TensorRT using module file. Module file works better if installation setup does not alter core bash startup variables like PATH and LD_LIBRARY_PATH.

*   Install the Python graphsurgeon wheel file.

```sh
cd "${HPCAPPS}"/tensorrt/8.2.2.1/graphsurgeon && \
pip install graphsurgeon-0.4.5-py2.py3-none-any.whl |& tee -a tensorrt_8.2.2.1_install.log
```

??? info "Expected output:"

    ```
    Processing ./graphsurgeon-0.4.5-py2.py3-none-any.whl
    Installing collected packages: graphsurgeon
    Successfully installed graphsurgeon-0.4.5
    ```

*   Install the Python onnx-graphsurgeon wheel file.

```sh
cd "${HPCAPPS}"/tensorrt/8.2.2.1/onnx_graphsurgeon && \
pip install onnx_graphsurgeon-0.3.12-py2.py3-none-any.whl |& tee -a tensorrt_8.2.2.1_install.log
```

??? info "Expected output:"

    ```
    Processing ./onnx_graphsurgeon-0.3.12-py2.py3-none-any.whl
    Requirement already satisfied: numpy in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/rey/lib/python3.9/site-packages (from onnx-graphsurgeon==0.3.12) (1.19.5)
    Collecting onnx
      Downloading onnx-1.10.2-cp39-cp39-manylinux_2_12_x86_64.manylinux2010_x86_64.whl (12.7 MB)
    Requirement already satisfied: protobuf in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/rey/lib/python3.9/site-packages (from onnx->onnx-graphsurgeon==0.3.12) (3.18.1)
    Requirement already satisfied: six in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/rey/lib/python3.9/site-packages (from onnx->onnx-graphsurgeon==0.3.12) (1.15.0)
    Requirement already satisfied: typing-extensions>=3.6.2.1 in /projects/verhaak-lab/amins/hpcenv/mambaforge/envs/rey/lib/python3.9/site-packages (from onnx->onnx-graphsurgeon==0.3.12) (3.7.4.3)
    Installing collected packages: onnx, onnx-graphsurgeon
    Successfully installed onnx-1.10.2 onnx-graphsurgeon-0.3.12
    ```

## Test GPU functionality

Once we have _rey_ env ready, we can test GPU functionality of installed packages. This is not a required step but I like to make sure that I am using GPU and not CPU for computation, e.g., tensorflow and r-keras package may fall back to CPU if it finds missing or badly configured support for GPU.

### Test Tensorflow and Keras

I have followed beginner scripts from [tensorflow tutorials](https://www.tensorflow.org/tutorials) to test GPU functionality. Similarly, RStudio section on [Tensorflow for R](https://tensorflow.rstudio.com/tutorials/) provides beginners tutorials for testing machine learning using GPU.

### Test PyTorch

See details on [PyTorch](https://pytorch.org/get-started/locally/#mac-verification) website.

```py
import torch
x = torch.rand(5, 3)
print(x)
```

### Test TensorRT

```sh
cd "${HPCAPPS}"/tensorrt/8.2.2.1

## ensure that gpu module is loaded
module load gpu/11.1.1

cd samples/sampleMNIST && \
make && \
echo "make OK"

cd ../../data/mnist && \
## Download MNIST dataset
wget http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz && \
wget http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz && \
wget http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz && \
wget http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz

ls *ubyte.gz | parallel -j2 gunzip {}

cd ../.. && \
./bin/sample_mnist -h && \
./bin/sample_mnist --datadir=data/mnist
```

>If all goes well, you will see tests passed ok and a predicted digit in [ASCII art](https://en.wikipedia.org/wiki/ASCII_art).

### Dask

Read docs at http://distributed.dask.org/en/stable/client.html

## Image Classification

Optional: Libraries specific to cell segmentation.

*   I am **creating a new conda env, _ben_** for installing tools related to cell segmentation analysis. These tools require additional set of packages (including installing using `pip`) and are updated often which together can make _rey_ env unstable over long run. Most of packages are based on package requirements for CellPose tool: [setup.py](https://github.com/MouseLand/cellpose/blob/master/setup.py) and [requirements.txt](https://github.com/MouseLand/cellpose/blob/master/requirements.txt) file.

```sh
mamba create -c conda-forge -c pytorch -n ben python=3.9 tensorflow-gpu keras pytorch torchvision cudatoolkit=11.1.1 cudatoolkit-dev=11.1.1 scikit-learn numpy scipy natsort tifffile tqdm numba torch-optimizer
```

*   Before activating _ben_ env, duplicate modulefile, `gpu/11.1.1` that [we created earlier](#setup-gpu-env-as-modulefile) to `gpu/11.1.1_ben`. Replace conda env name from rey to ben in `gpu/11.1.1_ben`. This will allow to load a valid GPU env and avoid potential danger of putting _rey_ paths in PATH and LD_LIBRARY_PATH while we work in _ben_ env.

*   Activate _ben_ env

```sh
mamba activate ben
```

!!! warning "Check for a valid bash env"
    If you notice any of _rey_ env related paths, especially taking precedence over _ben_ env paths, something is wrong and you should check modulefiles above to load conda env specific valid env. Installing cellpose and related package dependencies with **invalid bash env will invariably break the core, _rey_ env**.

    ```sh
    module load gpu/11.1.1_ben

    ## These should point to paths related to ben and not rey env.
    echo $PATH
    echo $LD_LIBRARY_PATH
    ```

#### Cellpose

A generalized algorithm for cellular segmentation. https://github.com/MouseLand/cellpose

*   Not recommended but given many dependencies for cellpose are not available or of conflicting nature using `mamba install`, I am falling back to `pip install`.

```sh
pip install cellpose[all] |& tee -a ~/logs/cellpose_install.log
```

>In case of errors or unstable env, I can always purge _ben_ env without any impact on _rey_ conda env.

??? info "Installation log and warnings, if any"

    ```
    Installing collected packages: googleapis-common-protos, pyparsing, numpy, google-crc32c, google-api-core, PyWavelets, pyqt5.sip, PyQt5-Qt5, packaging, opencv-python-headless, networkx, imageio, google-resumable-media, google-cloud-core, fastremap, edt, scikit-image, pyqtgraph, pyqt5, google-cloud-storage, cellpose
      Attempting uninstall: numpy
        Found existing installation: numpy 1.19.5
        Uninstalling numpy-1.19.5:
          Successfully uninstalled numpy-1.19.5

    ERROR: pip's dependency resolver does not currently take into account all the packages that are installed. This behaviour is the source of the following dependency conflicts.

    tensorflow 2.6.2 requires numpy~=1.19.2, but you have numpy 1.21.5 which is incompatible.

    Successfully installed PyQt5-Qt5-5.15.2 PyWavelets-1.2.0 cellpose-0.7.2 edt-2.1.1 fastremap-1.12.2 google-api-core-2.4.0 google-cloud-core-2.2.1 google-cloud-storage-2.0.0 google-crc32c-1.3.0 google-resumable-media-2.1.0 googleapis-common-protos-1.54.0 imageio-2.13.5 networkx-2.6.3 numpy-1.21.5 opencv-python-headless-4.5.5.62 packaging-21.3 pyparsing-3.0.6 pyqt5-5.15.6 pyqt5.sip-12.9.0 pyqtgraph-0.11.0rc0 scikit-image-0.19.1
    ```

*   Turns out tensorflow 2 (GPU) works with updated numpy and should not be throw an error.

```sh
python -c "import tensorflow as tf;print(tf.reduce_sum(tf.random.normal([1000, 1000])))"

```

*   CellPose should now be all set for running in _ben_ env.

```sh
cellpose --help
```

#### Stardist

StarDist - Object Detection with Star-convex Shapes. https://github.com/stardist/stardist

```sh
## in ben env
pip install stardist |& tee -a stardist_install.log
```

??? info "Installation log and warnings, if any"

    ```
    Installing collected packages: python-dateutil, kiwisolver, fonttools, cycler, matplotlib, csbdeep, stardist
    Successfully installed csbdeep-0.6.3 cycler-0.11.0 fonttools-4.28.5 kiwisolver-1.3.2 matplotlib-3.5.1 python-dateutil-2.8.2 stardist-0.7.3
    ```

*   To test run, [follow example from stardist repo](https://github.com/stardist/stardist).

#### Cellprofiler

Tool for image analysis, [cellprofiler.org](https://cellprofiler.org)

Related bioformats2raw and raw2ometiff were downloaded as standalone binary packages and installed as modules.

PS: Cellprofiler has a limited GPU support for now but it may change in the future. [Follow Cellprofiler forum](https://forum.image.sc/tag/cellprofiler) for updates. For now, I am installing it in _grogu_ env which is a toy env!

```sh
## login to CPU HPC
ssh sumner 
```

*   Create _grogu_ conda env

```sh
mamba create -c conda-forge -c bioconda -n grogu cellprofiler
```

*   Run cellprofiler

```sh
mamba activate grogu

cellprofiler --help
```

## Update bash startup

Finally, I am tweaking [bash startup sequence](../../cpu/sumner_3/#bash-startup) that we had setup earlier, such that it can allow loading GPU-specific bash env only when we login to Winter GPU HPC and not on Sumner CPU HPC. I have made following changes to bash startup. You can :octicons-file-code-16: [download my bash startup files here]({{ repo.url }}{{ repo.tree }}/confs/hpc/user_env/).

*   Update `SET PATH` block of *~/.bash_profile* to reset PATH for Winter GPU. See my notes under `elif [[ "$(hostname)" == *"winter"* ]]; then` section in :octicons-file-code-16: an example [.bash_profile]({{ repo.url }}{{ repo.blob }}/confs/hpc/user_env/.bash_profile) file.
*   Update *~/.profile.d/void/VW01_set_winter_gpu.sh* to load Winter specific settings. See more into an example [VW01_set_winter_gpu.sh]({{ repo.url }}{{ repo.blob }}/confs/hpc/user_env/.profile.d/void/VW01_set_winter_gpu.sh) file.

Logout and login again to Winter HPC. You will see a near identical bash prompt like Sumner HPC, e.g., `user@winter-log1`. However, when you check `echo $PATH` output and `echo $CONDA_DEFAULT_ENV`, you will notice that a default conda env in Winter HPC is now _rey_ while in Sumner HPC, it is _base_ (sometimes called _root_).

Of course, you can revert to base or any other conda env in Winter HPC by doing `mamba deactivate` (because we changed from base to rey during bash startup) and then `mamba activate base` (or yoda, or any other env).

If you have also setup activate.d/deactivate.d scripts as [detailed earlier](#renviron-setup), you will be able to fine tune loading and unloading of conda env specific to HPC type (CPU or GPU) as well as type of R and GPU-specific configs. See :octicons-file-code-16: [/confs/hpc/mambaforge/envs]({{ repo.url }}{{ repo.tree }}/confs/hpc/mambaforge/envs) for example scripts.

## Done!

Hope you have found this documentation helpful. I think this is more technical that I originally expected and you may have to look into stackoverflow or elsewhere to understand jargons I used across pages. Hopefully, I can go through some of sections again and put emphasis on rationale behind setting up my linux environment.

That said, I hope this documentation, at least the CPU part, should get you started with HPC setup. For learning specific programming language and data analysis, I will post a few external resources on getting started guide to learn programming in Python, R, and more.

Best wishes! :material-thumb-up: :material-rocket-launch-outline:
