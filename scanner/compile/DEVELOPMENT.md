# Developer Information

This document contains notes for developers who need to rebuild the standalone Pulseq compiler.

## MATLAB Runtime

### Scanner

The target GE scanner uses the MATLAB Runtime located at:

```text
/opt/mathworks_matlab_runtime_r2022a/root/v912/
```

> [!IMPORTANT]
> The standalone executable **must** be compiled using **MATLAB R2022a**. Executables compiled with newer MATLAB releases are not compatible with the scanner runtime.

### Local Runtime Installation (Optional)

For local testing, the MATLAB Runtime can be downloaded directly from MATLAB:

```matlab
>> compiler.runtime.download
Downloading MATLAB Runtime installer. It may take several minutes...

>> mcrinstaller
    '/home/jon/.MathWorks/MatlabRuntimeCache/MCRInstaller24.2/MATLAB_Runtime_R2024b_Update_4_glnxa64.zip'
```

## Ubuntu 22.04 LTS

Ubuntu 22.04 LTS has been found to work well with MATLAB R2022a.

### Virtual machine configuration

* GNOME Boxes
* 8 GB RAM
* 60 GB storage
* Express installation

### Recommended software

Install:

* `git`
* `vim`

Configure Git:

```bash
git config --global user.email "yourname@example.com"
git config --global user.name "Your Name"
git config --global core.editor "vim"
```

In `~/.bashrc`:

```bash
export EDITOR=vim
```

## Installing MATLAB R2022a

### Installation media

Obtain the `R2022a_Linux.iso` installation image.

A separate license file is not required if your institution provides network licensing.

### Installation

1. Mount `R2022a_Linux.iso`.

2. Allow the installer to access the display:

   ```bash
   xhost +local:root
   ```

3. Launch the installer:

   ```bash
   sudo ./install
   ```

4. Log in, accept the license agreement, and complete the installation.

### Required toolboxes

The following toolbox configuration has been verified to build the standalone compiler successfully. This list may not be minimal.

```matlab
>> ver
-----------------------------------------------------------------------------------------------------------------
MATLAB Version: 9.12.0.1884302 (R2022a)
Operating System: Linux 6.8.0-101-generic #101~22.04.1-Ubuntu SMP PREEMPT_DYNAMIC Wed Feb 11 13:19:54 UTC  x86_64
Java Version: Java 1.8.0_202-b08 with Oracle Corporation Java HotSpot(TM) 64-Bit Server VM mixed mode
-----------------------------------------------------------------------------------------------------------------
MATLAB                                                Version 9.12        (R2022a)
Curve Fitting Toolbox                                 Version 3.7         (R2022a)
Image Processing Toolbox                              Version 11.5        (R2022a)
MATLAB Compiler                                       Version 8.4         (R2022a)
Optimization Toolbox                                  Version 9.3         (R2022a)
Signal Processing Toolbox                             Version 9.0         (R2022a)
Wavelet Toolbox                                       Version 6.1         (R2022a)
```

