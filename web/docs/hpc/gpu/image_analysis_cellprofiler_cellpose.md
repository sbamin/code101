---
title: "Image analysis on GPU-based HPC"
description: "Setup CellProfiler, CellPose, StarDist on HPC Winter - GPU HPC at JAX"
keywords: "hpc,linux,configuration,winter,gpu,cuda,imaging,cellprofiler,workflow,pipeline,cellpose,stardist"
author: Samir B. Amin
twitter: sbamin
tags:
    - gpu
    - hpc
    - imaging
    - segmentation
    - cellprofiler
    - cellpose
    - stardist
comments: true
---

# Image analysis on GPU-based HPC

>Setup CellProfiler, CellPose, StarDist on GPU-based HPC.

CPU version of CellProfiler (CP) is [installed under env _grogu_]({{ config.site_url }}/hpc/gpu/winter_1/#cellprofiler). However, we like to run CP based workflow in a headless HPC environment such that it can leverage [CP plugins](https://github.com/CellProfiler/CellProfiler-plugins), including use of GPU-enabled CellPose and StartDist plugins. This requires manually configuring several dependencies for CP vs. those for CellPose and StarDist, such that all three programs can live in harmony within a single conda env.

## Initial Setup

Create a new conda env, _cellprofiler_ because we will be using `pip install` several times and this may require changing package versions which otherwise existing and stable conda-managed env - with other packages and their dependencies - may not allow us to edit/update.

Following setup is based on GPU-enabled HPC at [The Jackson Laboratory for Genomic Medicine](https://www.jax.org/about-us/our-campuses-and-communities/connecticut) but it should be applicable for most other NVIDIA-based GPUs running Cent OS 7.

### CellProfiler

*   Login to Winter HPC which is our GPU based HPC.

```sh
ssh winter
mamba activate base
```

??? tip "Do `echo $?` after each major installation step"
    For error-free setup, check exit code for a successfully run command (should be 0) after each of major installation commands below. This can be done either using `echo $?` **immediately after** the major command or suffixing ` && echo "Success"` to a major command text string.

*   Create a new env and install CP from the official source. Know that purpose of installing CP via conda is to install CP dependencies and not CP itself. For CP, we will later use `pip install` to install it from the source and so override conda managed CP.

```sh
mamba create -c conda-forge -c bioconda -n cellprofiler cellprofiler
```

### CellPose

*   Install CellPose dependencies, including CUDA drivers for GPU functionality.

```sh
mamba activate cellprofiler
mamba install -c conda-forge -c pytorch pytorch cudatoolkit=11.3
```

*   Install or upgrade cellpose along with all of its dependencies.

??? warning "`pip install` of dependencies is generally not a best practice"
    When working in a conda env, it is not a good idea to install packages using `pip install`, especially dependencies. You may rather install all of dependencies for a package using `mamba install` command to avoid version conflict with conda managed packages. You can usually find required dependencies of a package, say CellPose in _setup.py_ and/or `requirements.txt` file under [CellPose source code](https://github.com/MouseLand/cellpose).

    Here, I already know that CP and CellPose have conflicting dependencies and I am attempting to fix those manually using `pip install` with trade off of potentially breaking conda managed package dependencies. Let's see what happens at the end of this setup!

```sh
pip install cellpose[all] --upgrade |& tee -a ~/logs/cellpose2_envcp_install.log
```

>Expected end of the installation log:

```
...
Installing collected packages: slicerator, PyQt5-Qt5, pyasn1, tqdm, rsa, pyqtgraph, pyqt5.sip, pyasn1-modules, protobuf, opencv-python-headless, natsort, llvmlite, google-crc32c, fastremap, cachetools, pyqt5, pims, numba, googleapis-common-protos, google-resumable-media, google-auth, google-api-core, cellpose, google-cloud-core, dask-image, google-cloud-storage
Successfully installed PyQt5-Qt5-5.15.2 cachetools-5.2.0 cellpose-2.1.0 dask-image-2021.12.0 fastremap-1.13.2 google-api-core-2.8.2 google-auth-2.9.1 google-cloud-core-2.3.2 google-cloud-storage-2.4.0 google-crc32c-1.3.0 google-resumable-media-2.3.3 googleapis-common-protos-1.56.4 llvmlite-0.39.0 natsort-8.1.0 numba-0.56.0 opencv-python-headless-4.6.0.66 pims-0.6.1 protobuf-4.21.4 pyasn1-0.4.8 pyasn1-modules-0.2.8 pyqt5-5.15.7 pyqt5.sip-12.11.0 pyqtgraph-0.12.4 rsa-4.9 slicerator-1.1.0 tqdm-4.64.0
```


### StarDist

*   Similarly install [StarDist](https://github.com/stardist/stardist) tensorflow 2 version. For this, we need to first install TensorFlow 2 GPU package, CUDA drivers, and related packages using `mamba install`.

!!! warning "Downgrading major version for CUDA toolkit and cudnn"
    Note that following command may downgrade above installed (during CellPose dependencies install) cudatoolkit from 11 to 10 and cudnn from 8 to 7. While this is not a best practice, we need to ensure that dependencies for all three - CellProfiler, CellPose, and StarDist - live in harmony under the same conda env, _cellprofiler_!

```sh
mamba activate cellprofiler
mamba install -c conda-forge -c pytorch tensorflow-gpu keras pytorch torchvision cudatoolkit scikit-learn numpy scipy natsort tifffile tqdm numba torch-optimizer
```

*   Verify if tensorflow is using GPU. Note that tensorflow may require a valid path to CUDA toolkit in LD_LIBRARY_PATH. Since conda env does not put its lib path in LD_LIBRARY_PATH, we may need to set that explicitly as follows (and later as modulefile - See towards the end)

```sh
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${CONDA_PREFIX}/lib/"
# Verify install:
python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
```

*   Test pytorch cuda support: **This is critical for running Cellpose in GPU mode.**

```py
import torch
## RELU only has one CUDA device: 0
device = torch.device('cuda:0')
torch.zeros([1, 2, 3]).to(device)
```

>This may fail and cellpose may fallback to CPU. If so, reinstall pytorch from cuda-specific conda repository.

*  Cellpose may not use GPU unless pytorch package is compiled using compatible cuda toolkit. See [details here](https://github.com/MouseLand/cellpose/issues/203). To fix, reinstall pytorch ensuring it comes from a channel starting with respective cuda major version, e.g., `cuda102...` in this case.

>For Winter HPC: GPU suport worked with previous steps, and so, I did not reinstall pytorch as pytorch was already built using `cuda102...` toolkit. See pytorch line in *Check versions* step below.

```sh
mamba update -c conda-forge -c pytorch pytorch
```

*   Check versions for GPU related libraries.

```sh
(cellprofiler) foo@winter204:/fastscratch/foo$ mamba list | grep -E "tensor|cuda|torch"
cudatoolkit               10.2.89             h713d32c_10    conda-forge
pytorch                   1.12.0          cuda102py38hfdb21e3_202    conda-forge
pytorch-ranger            0.1.1              pyhd8ed1ab_0    conda-forge
tensorboard               2.8.0              pyhd8ed1ab_1    conda-forge
tensorboard-data-server   0.6.0            py38h2b5fc30_2    conda-forge
tensorboard-plugin-wit    1.8.1              pyhd8ed1ab_0    conda-forge
tensorflow                2.8.1           cuda102py38h32e99bf_0    conda-forge
tensorflow-base           2.8.1           cuda102py38ha005362_0    conda-forge
tensorflow-estimator      2.8.1           cuda102py38h4357c17_0    conda-forge
tensorflow-gpu            2.8.1           cuda102py38hf05f184_0    conda-forge
torch-optimizer           0.3.0              pyhd8ed1ab_0    conda-forge
torchvision               0.13.0          cuda102py38h041733a_0    conda-forge
```

*   Now install or upgrade StarDist.
 
```sh
pip install stardist --upgrade |& tee -a ~/logs/stardist_envcp_install.log
```

??? warning "StarDist: Version conflict with `pip install`"
    Notice errors below while installing stardist using `pip install`. While exit code (`echo $?`) returned zero or success status, CellProfiler command may fail given some of dependencies are mismatched between StarDist and CellProfiler. We need to resolve this later in the setup process.

    >Expected end of the installation log:

    ```
    ...
    Installing collected packages: numpy, h5py, csbdeep, stardist
      Attempting uninstall: numpy
        Found existing installation: numpy 1.23.1
        Uninstalling numpy-1.23.1:
          Successfully uninstalled numpy-1.23.1
      Attempting uninstall: h5py
        Found existing installation: h5py 3.7.0
        Uninstalling h5py-3.7.0:
          Successfully uninstalled h5py-3.7.0

    ERROR: pip's dependency resolver does not currently take into account all the packages that are installed. This behavior is the source of the following dependency conflicts.
    python-bioformats 4.0.5 requires python-javabridge==4.0.3, but you have python-javabridge 4.0.0 which is incompatible.
    centrosome 1.2.0 requires matplotlib==3.1.3, but you have matplotlib 3.5.2 which is incompatible.
    cellprofiler 4.2.1 requires docutils==0.15.2, but you have docutils 0.19 which is incompatible.
    cellprofiler 4.2.1 requires h5py==3.2.1, but you have h5py 2.10.0 which is incompatible.
    cellprofiler 4.2.1 requires matplotlib==3.1.3, but you have matplotlib 3.5.2 which is incompatible.
    cellprofiler 4.2.1 requires mysqlclient==1.4.6, but you have mysqlclient 2.0.3 which is incompatible.
    cellprofiler 4.2.1 requires python-javabridge==4.0.3, but you have python-javabridge 4.0.0 which is incompatible.
    cellprofiler 4.2.1 requires pyzmq==18.0.1, but you have pyzmq 18.1.1 which is incompatible.
    cellprofiler 4.2.1 requires sentry-sdk==0.18.0, but you have sentry-sdk 1.9.0 which is incompatible.
    cellprofiler 4.2.1 requires wxPython==4.1.0, but you have wxpython 4.1.1 which is incompatible.
    cellprofiler-core 4.2.1 requires docutils==0.15.2, but you have docutils 0.19 which is incompatible.
    cellprofiler-core 4.2.1 requires h5py==3.2.1, but you have h5py 2.10.0 which is incompatible.
    cellprofiler-core 4.2.1 requires python-javabridge==4.0.3, but you have python-javabridge 4.0.0 which is incompatible.
    cellprofiler-core 4.2.1 requires pyzmq==18.0.1, but you have pyzmq 18.1.1 which is incompatible.
    Successfully installed csbdeep-0.7.2 h5py-2.10.0 numpy-1.22.4 stardist-0.8.3
    ```

*   Also install including OmniPose which I missed installing earlier with CellPose.

```sh
pip install omnipose --upgrade |& tee -a ~/logs/omnipose_envcp_install.log
```

??? warning "Omnipose: Version conflict with `pip install`"
    Similar to StarDist setup, we need to resolve these conflict issues later.

    >Expected end of the installation log:

    ```
    Successfully built ncolor
    Installing collected packages: mahotas, edt, ncolor, omnipose
      Attempting uninstall: mahotas
        Found existing installation: mahotas 1.4.13
        Uninstalling mahotas-1.4.13:
          Successfully uninstalled mahotas-1.4.13
    ERROR: pip's dependency resolver does not currently take into account all the packages that are installed. This behaviour is the source of the following dependency conflicts.
    cellprofiler 4.2.1 requires docutils==0.15.2, but you have docutils 0.19 which is incompatible.
    cellprofiler 4.2.1 requires h5py==3.2.1, but you have h5py 2.10.0 which is incompatible.
    cellprofiler 4.2.1 requires matplotlib==3.1.3, but you have matplotlib 3.5.2 which is incompatible.
    cellprofiler 4.2.1 requires mysqlclient==1.4.6, but you have mysqlclient 2.0.3 which is incompatible.
    cellprofiler 4.2.1 requires python-javabridge==4.0.3, but you have python-javabridge 4.0.0 which is incompatible.
    cellprofiler 4.2.1 requires pyzmq==18.0.1, but you have pyzmq 18.1.1 which is incompatible.
    cellprofiler 4.2.1 requires sentry-sdk==0.18.0, but you have sentry-sdk 1.9.0 which is incompatible.
    cellprofiler 4.2.1 requires wxPython==4.1.0, but you have wxpython 4.1.1 which is incompatible.
    Successfully installed edt-2.3.0 mahotas-1.4.12 ncolor-1.1.5 omnipose-0.2.1
    ```

## Resolve version conflicts

Before fixing version conflicts that we observed above, see if example headless pipeline of CellProfiler can run on HPC under _cellprofiler_ conda env. If so, there may not be any need of resolving conflicts. I usually check CellProfiler dependencies in its source code (at setup.py and requirements.txt if any) and at their [conda installation](https://github.com/CellProfiler/CellProfiler/wiki/Conda-Installation) and [Linux setup](https://github.com/CellProfiler/CellProfiler/wiki/Ubuntu-20.04) pages.

I usually avoid package downgrade unless I encounter a relevant error. I also avoid upgrading packages unless there is a change in major or minor version from say `h5py` 2.10.0 to 3.2.1 as in above case or 2.10.0 to 5.4.1 to 5.5.0. First, I try using `mamba update` if it can update packages while respecting other packages dependencies that are managed via conda (but may not do so for packages installed via `pip`).

```sh
mamba update -c conda-forge -c bioconda -c pytorch python-javabridge matplotlib docutils h5py mysqlclient pyzmq sentry-sdk wxPython
```

>Resulted into no version changes and so I skipped updating `h5py` at least for now.

!!! wip "ToDo: Check with CellProfiler Team on upgrading `h5py` package"
    Check with CP team on need for upgrading h5py - whether critical or ok to keep v 2.10.0 over 3.2.1?

Another option is to source install CellProfiler from the [CP source code](https://github.com/CellProfiler/CellProfiler) and using `pip3 install .`. Read [installing CP on Ubuntu 20.04](https://github.com/CellProfiler/CellProfiler/wiki/Ubuntu-20.04). However, I have avoided this so far to manage much of my conda CP env using conda and `pip install` commands. So far, I have not seen errors that break CP workflow with or without use of GPU-based CellPose and StarDist plugins. If I do notice errors that can only be fixed by installing CP from its source, I will update this page accordingly.

*   At the end of this setup, you should have all three tools installed in cellprofiler conda env.

```sh
mamba list | grep -E "cellpose|stardist|cellprofiler"
```

```
cellpose                  2.1.0                    pypi_0    pypi
cellprofiler              4.2.1            py38h779adbc_0    bioconda
cellprofiler-core         4.2.1              pyhdfd78af_0    bioconda
stardist                  0.8.3                    pypi_0    pypi
```

## Jupyter Support

To use cellprofiler conda env in jupyter kernel, e.g., in VScode or elsewhere, install `ipykernel` (and related jupyter dependencies)

```sh
mamba activate cellprofiler
mamba install -c conda-forge ipykernel
## install env specific kernel at ~/.local/share/jupyter/kernels
python -m ipykernel install --user --name cellprofiler_py --display-name "cellprofiler_py"
```

### Kernel setup

This setup - using a wrapper script - will first activate CP conda env and then launch python kernel for jupyter connection. That way, I can be certain that all of _cellprofiler_ conda env configurations, including GPU configs, are loaded before launching jupyter session.

To do so, first create a wrapper script like following and save it somewhere on your filesystem, e.g., */projects/foo/hpcenv/opt/kernels/wrap_cellprofiler_py38*. 

```sh
#!/bin/bash

## Load env before loading jupyter kernel

## https://github.com/jupyterhub/jupyterhub/issues/847#issuecomment-260152425

## restrict loading kernel only to GPU (and not CPU) based HPC
if [[ "$(hostname)" != *"winter"* ]]; then
    echo -e "ERROR: Invalid hostname\nThis kernel works only on winter HPC\n" >&2
    exit 1
else
    #### Activate CONDA in subshell ####
    ## Read https://github.com/conda/conda/issues/7980
    # I am using conda instead of mamba to activate env
    # as somehow I notices warnings/errors sourcing
    # mamba.sh in sub-shells.
    CONDA_BASE=$(conda info --base) && \
    source "${CONDA_BASE}"/etc/profile.d/conda.sh && \
    conda activate cellprofiler
    #### END CONDA SETUP ####

    ## Load additional CUDA drivers, toolkit, etc.
    ## if applicable prior to initializing kernel

    # this is the critical part, and should be at the end of your script:
    # replace with path to python under cellprofiler conda env
    exec /projects/foo/hpcenv/mambaforge/envs/cellprofiler/bin/python -m ipykernel_launcher "$@"

    ## Make sure to update corresponding kernel.json under ~/.local/share/jupyter/kernels/<kernel_name>/kernel.json
fi
#_end_
```

*   Now go to `~/.local/share/jupyter/kernels` and locate at `kernel.json` file under **cellprofiler_py** (or whichever name you used when configuring ipykernel above). Open 

```json
{
 "argv": [
  "/projects/foo/hpcenv/opt/kernels/wrap_cellprofiler_py38",
  "-f",
  "{connection_file}"
 ],
 "display_name": "cellprofiler_py",
 "language": "python",
 "metadata": {
  "debugger": true
 }
}
```

??? tip "Change icons to show CellProfiler icon in Jupyter"
    You can also replace icon images under `~/.local/share/jupyter/kernels/cellprofiler_py` to show cellprofile env specific icon in Jupyter Launcher session.

<figure markdown>
  ![Jupyter Launcher after kernel setup]({{ config.site_url }}/assets/images/pages/jupyter_env.png){ width="98%" }
  <figcaption>Example Jupyter Launcher after kernel setup</figcaption>
</figure>

## Backup Conda Env

At this stage, you should backup configurations for cellprofiler conda env, similar to [one detailed here]({{ config.site_url }}/hpc/cpu/sumner_2/#backup-conda-env).

At the end of this setup, including commands that I ran below for GPU and CP plugins setup, my conda _cellprofiler_ env was identical to an _env export file_: :octicons-file-code-16: [cellprofiler_gpu_env_export_pkgs.yml]({{ repo.url }}{{ repo.blob }}/confs/hpc/mambaforge/envs/cellprofiler/bkup/cellprofiler_gpu_env_export_pkgs.yml). Some of package versions may differ for you though and that should be ok. Anaconda provides [an option to recreate an env similar to an exported env file](https://conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#create-env-from-file) which I have not tested personally.

## GPU configuration

Following setup as above, GPU env should be configured and managed via conda. You may however see bash variable `CUDA_HOME` as undefined. This variable may be required by some tools and should point to path where cellprofiler conda env is installed, e.g., `/projects/foo/mambaforge/envs/cellprofiler`.


??? info "Optional: load required CUDA drivers as a modulefile"
    Here an example module file I have in my env. This is optional (and **not loaded** in my HPC env) and only needed for some cases where one or more tools fail to recognize GPU drivers. Talk to your HPC team to configure a valid CUDA driver setup that matches GPU hardware on the HPC.

    ```
    (cellprofiler) foo@winter204:/fastscratch/foo/tmp$ module show gpu/10.2_cellprofiler
    -----------------------------------------------------------------------------------------------------------------------------------------
       /projects/foo/hpcenv/opt/modules/def/gpu/10.2_cellprofiler:
    -----------------------------------------------------------------------------------------------------------------------------------------
    whatis("adds user-defined NVIDIA CUDA 11.1 Toolkit to your environment variables ")
    conflict("gpu/11.1.1")
    conflict("gpu/11.1.1_ben")
    conflict("gpu/10.2_ben")
    setenv("CUDA_INSTALL_PATH","/projects/foo/hpcenv/mambaforge/envs/cellprofiler")
    setenv("CUDA_PATH","/projects/foo/hpcenv/mambaforge/envs/cellprofiler")
    setenv("CUDA_ROOT","/projects/foo/hpcenv/mambaforge/envs/cellprofiler")
    setenv("CUDA_HOME","/projects/foo/hpcenv/mambaforge/envs/cellprofiler")
    prepend_path("PATH","/projects/foo/hpcenv/opt/modules/apps/gpu/10.2/local/bin")
    prepend_path("LIBRARY_PATH","/projects/foo/hpcenv/opt/modules/apps/gpu/10.2/local/lib")
    prepend_path("LD_LIBRARY_PATH","/projects/foo/hpcenv/opt/modules/apps/gpu/10.2/local/lib")
    prepend_path("INCLUDEPATH","/projects/foo/hpcenv/opt/modules/apps/gpu/10.2/local/include")
    prepend_path("MANPATH","/projects/foo/hpcenv/opt/modules/apps/gpu/10.2/local/share/man")
    prepend_path("LIBRARY_PATH","/projects/foo/hpcenv/mambaforge/envs/cellprofiler/lib")
    prepend_path("LD_LIBRARY_PATH","/projects/foo/hpcenv/mambaforge/envs/cellprofiler/lib")
    prepend_path("INCLUDEPATH","/projects/foo/hpcenv/mambaforge/envs/cellprofiler/include")
    prepend_path("CUDA_INC_PATH","/projects/foo/hpcenv/mambaforge/envs/cellprofiler")
    setenv("CUDA_INSTALL_DIR","/projects/foo/hpcenv/mambaforge/envs/cellprofiler")
    help([[ Adds user-defined NVIDIA CUDA 11.1 Toolkit to your environment variables,
    ]])
    ```

### Test GPU

Following commands in bash and python should test GPU functionality. Ideally, you should run all three - CellProfiler, CellPose, and StarDist - to ensure that GPU is in-use during runtime.

```sh
echo $CUDA_HOME # (1)
nvcc --version # (2)
nvidia-smi # (3)
```

1. CUDA_HOME should point to conda env home path, e.g., */foo/mambaforge/envs/cellprofiler*. If not, you may get an error for certain tools.
2. `nvcc` is located at `*/foo/mambaforge/envs/cellprofiler/bin/nvcc`
3. `nvidia-smi` is a system-managed binary at `/usr/bin/nvidia-smi`

```sh
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${CONDA_PREFIX}/lib/"
# Verify install:
python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
```

```sh
python -c "import tensorflow as tf;print(tf.reduce_sum(tf.random.normal([1000, 1000])))"
```

```
2022-07-29 14:08:14.276017: I tensorflow/core/platform/cpu_feature_guard.cc:151] This TensorFlow binary is optimized with oneAPI Deep Neural Network Library (oneDNN) to use the following CPU instructions in performance-critical operations:  SSE4.1 SSE4.2 AVX AVX2 AVX512F FMA
To enable them in other operations, rebuild TensorFlow with the appropriate compiler flags.
2022-07-29 14:08:15.656565: I tensorflow/core/common_runtime/gpu/gpu_device.cc:1525] Created device /job:localhost/replica:0/task:0/device:GPU:0 with 30976 MB memory:  -> device: 0, name: Tesla V100-SXM2-32GB, pci bus id: 0000:89:00.0, compute capability: 7.0
```

>As long as it says using `device:GPU:0`, TensorFlow 2 is setup to use GPU.

```py
import torch
## RELU only has one CUDA device: 0
device = torch.device('cuda:0')
torch.zeros([1, 2, 3]).to(device)

x = torch.rand(5, 3)
print(x)
```

>Should show a tensor with random numbers.

```
tensor([[[0., 0., 0.],
         [0., 0., 0.]]], device='cuda:0')
```

```
tensor([[0.8770, 0.5362, 0.5748],
        [0.4587, 0.8161, 0.3703],
        [0.0056, 0.8461, 0.0816],
        [0.6864, 0.8047, 0.5323],
        [0.2400, 0.3549, 0.7756]])
```

## CellProfiler Plugins

Following guide is based on documentation from [CellProfiler Plugin](https://github.com/CellProfiler/CellProfiler-plugins) page.

```sh
mkdir -p "${HPCAPPS}"/cellprofiler
cd "${HPCAPPS}"/cellprofiler
git clone https://github.com/CellProfiler/CellProfiler-plugins.git
```
>I have used CP plugin version with commits upto: https://github.com/CellProfiler/CellProfiler-plugins/commit/714d4e738921f79cb3c148efe9c02b1720e916d0 dated 2022-08-18.

*   Open CellProfiler in GUI mode. `Preferences > CellProfiler plugins directory`, update path to cellprofiler plugins dir. Restart CP from commandline in GUI mode as `cellprofiler`. If running CP on HPC, this may not be feasible. If so, run CP in headless mode with `--plugins-directory` flag pointing to plugin path we installed above.

>Observe errors on command line and install missing packages as long as 1) updates do not break existing setup of cellprofiler env, and 2) we can run CellPose and StarDist as plugins. We may not need to install dependencies for other plugins, if any. Check plugin-specific dependencies at [CellProfiler-plugins](https://github.com/CellProfiler/CellProfiler-plugins) website.

```sh
mamba activate cellprofiler
mamba install -c conda-forge pandas jpype1 pyimagej
```

*   Restart CP and check for errors on terminal if any.

```sh
cd /fastscratch/foo/cellprofiler/toyset
cellprofiler -c -r -p pipeline/hcs_toyrun.cppipe -o output -i input -L 20  --plugins-directory "${HPCAPPS}"/cellprofiler/CellProfiler-plugins
```

Hurray! CP works in headless mode with GPU-based CellPose as a plugin.

??? ":material-bug: Error in sys.excepthook"
    I was able to run CP with GPU-enabled CellPose workflow in headless mode and was able to get expected output of the workflow. However, CP ended with *Error in sys.excepthook* message but with a bash exit code (`$?`) 0. This is likely a harmless error and a possible bug in the upstream code. See related [Image.sc forum post](https://forum.image.sc/t/error-in-sys-excepthook-while-running-cellprofiler-in-headless-mode-with-cellpose-as-a-plugin/70866)

## Questions

For questions specific to above setup, please use GitHub based comments system below. For questions related to cellprofiler and related plugins, please use an excellent community forum at [Images.sc](https://forum.image.sc), including [cellprofiler based questions](https://forum.image.sc/tag/cellprofiler).
