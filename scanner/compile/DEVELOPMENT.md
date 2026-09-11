# Developer Information

This document describes how to rebuild the standalone Pulseq compiler.

## Compiler structure

`compilePGE.m` is the core single-sequence compiler and can be called directly from MATLAB during development.

Two standalone command-line interfaces are provided for scanner-side use:

- `compilePGE_cli.m` — wrapper for compiling a single sequence
- `compilePGE_batch.m` — wrapper for compiling multiple sequences from a scan list

Both ultimately call `compilePGE.m` and use the same JSON configuration loaded by `loadOptionsJSON.m`.

## Building the executables

The standalone executables must be built using **MATLAB R2022a**.

Start MATLAB and initialize the pge2 environment:

```matlab
setup
```

### Single-sequence compiler

Compile the command-line wrapper:

```matlab
mcc -m compilePGE_cli.m
```

This generates:

```text
compilePGE_cli
run_compilePGE_cli.sh
```

These files are used by `compilePGE.sh`.

### Batch compiler

Compile the batch wrapper:

```matlab
mcc -m compilePGE_batch.m
```

This generates:

```text
compilePGE_batch
run_compilePGE_batch.sh
```

These files are used by `compilePGE_batch.sh`.

Copy each executable and its corresponding launcher script to the scanner compilation directory. The executable and launcher are generated as a pair and should always be distributed together.

---

## Testing in MATLAB

The core compiler can be called directly from MATLAB without building a standalone executable:

```matlab
setup

opts = loadOptionsJSON('compilePGE.json');

% Disable prescription-dependent FOV translation if Rx.txt is unavailable
opts = rmfield(opts, 'translateFOV');

opuser1 = 48;
compilePGE('gre2d.seq', opuser1, 'gre2d.pge', opts);
```

This is useful for development and testing and uses the same `compilePGE.json` configuration as the standalone compiler.

---

## MATLAB Runtime

### Scanner

The target GE scanner uses the MATLAB Runtime located at:

```text
/opt/mathworks_matlab_runtime_r2022a/root/v912/
```

> [!IMPORTANT]
> The standalone executables **must** be compiled using **MATLAB R2022a**. Executables compiled with newer MATLAB releases are not compatible with the scanner runtime.

### Local MATLAB Runtime (optional)

The MATLAB Runtime can also be installed locally for testing the standalone executables.

```matlab
>> compiler.runtime.download
Downloading MATLAB Runtime installer. It may take several minutes...

>> mcrinstaller
    '/home/jon/.MathWorks/MatlabRuntimeCache/MCRInstaller24.2/MATLAB_Runtime_R2024b_Update_4_glnxa64.zip'
```

In this case, set `MATLAB_RUNTIME_DIR` in `compilePGE.sh` and `compilePGE_batch.sh` accordingly.

---

## Ubuntu 22.04 LTS

Ubuntu 22.04 LTS is recommended for building the standalone compiler because it has been found to work reliably with MATLAB R2022a.

### Virtual machine configuration

- GNOME Boxes
- 8 GB RAM
- 60 GB storage
- Express installation

### Recommended software

Install:

- `git`
- `vim`

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

The following toolbox configuration has been verified to build the standalone compiler successfully. The minimum required toolbox set has not been determined.

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