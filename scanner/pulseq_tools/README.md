# Interactive FOV translation for Pulseq/PulSeg sequences on GE scanners

This directory provides a scanner-side workflow for automatically translating 
PulSeq FOV offsets based on the GE prescription UI, using the MATLAB Runtime.

## Overview

**Goal:** Set FOV translation automatically on the scanner based on the usual UI prescription

We'll do this by running `pge2.translateFOVrf()` on scanner automatically.
This will make use of the Matlab runtime which is already installed on the scanner.
Specially, we will create a function `translateFOVrf.m` that:
1. loads a PulSeg object from a `.mat` file, 
2. applies the FOV offset, and
3. writes the resulting sequence to a `.pge` file for execution.

We will obtain the FOV offset from the output of `printSHM` 
on the scanner (a built-in command).

Here the sequence name is chosen to be `gre2d` to make the description concrete.

This requires **Matlab R2022a** currently.


## Compile translateFOVrf.m and test it

1. **Compile:**
    On local computer with R2022a installed:
    ```matlab
    >> mcc -m translateFOVrf.m
    ```

2. **Create `gre2d.mat`:**
   Create a `psq` object in the usual way (e.g., the 2D GRE official demo sequence). 
   Save it along with a couple of other parameters:
   ```matlab
   >> save gre2d psq params pislquant
   ```

3. **Create `Rx.txt`:**
   On scanner, type `printSHM > Rx.txt`

3. **Test on local computer:**
   To run on local computer command line (Linux), for testing:
    ```bash
    $ ./run_translateFOVrf.sh /usr/local/MATLAB/R2022a gre2d  # Runs using Matlab instead of the runtime
    ```

4. **Test on the scanner:**
    ```bash
    $ ./run_translateFOVrf.sh /opt/mathworks_matlab_runtime_r2022a/root/v912 gre2d 
    ```

## Scanner workflow

Our eventual goal is to have `run_translateFOVrf.sh` run automatically in the background,
so that the user experience is the same as for product sequences.
For now, some steps are manual (on the command line).

1. **Prescribe FOV:**
   1. For any pge2 sequence, prescribe the desired FOV offset and rotation.

2. **Create the file `pulseq_scans.txt`:** 
   This file contains a list of the PulSeg scan files (`.mat`) to which the FOV shift will be applied.
   Example:
   ```text
   # Comment/empty lines are ok
   gre2d.mat

   # The .mat extension is optional
   b0
   ```

3. **Create FOV-shifted `.pge` files:**
   1. Copy all `.mat` files listed in `pulseq_scans.txt` to the current folder.
   2. Aply the shift:
   ```bash
   $ ./shift_fov_pulseq pulseq_scans.txt
   ```
   This will call `printSHM > Rx.txt`, then create a `.pge` file for each scan in `pulseq_scans.txt`.

4. **Prescribe and run each scan:**
   1. As usual, create a `pge<n>.entry` file for each of the `.pge` files you just created.
   2. For each scan, start a new Series and 
      copy the prescription from the pge2 sequence in step 1 
      (this will apply the desired rotation).
      This can be done automatically by linking the Series.
      Then run the scan as usual.


## Matlab runtime info

### Scanner

On our GE UHP 3T, Matlab runtime is `/opt/mathworks_matlab_runtime_r2022a/root/v912/`

> [!IMPORTANT] Therefore, the `.m` file must be compiled with Matlab R2022a.

### Local installation (not needed but info is here if useful)

```matlab
>> mcrinstaller
MATLAB Runtime installer cannot be found. Download it using the command: compiler.runtime.download
>> compiler.runtime.download
Downloading MATLAB Runtime installer. It may take several minutes...
>> mcrinstaller
    '/home/jon/.MathWorks/MatlabRuntimeCache/MCRInstaller24.2/MATLAB_Runtime_R2024b_Update_4_glnxa64.zip'
```

## Matlab R2022a and Ubuntu 22.04 LTS installation

### Ubuntu 22.04 LTS

Ubuntu 22.04 LTS seems to be the version most compatible with R2022a.

Settings:
* GNOME Boxes VM
* 8 GB RAM
* 60 GB storage
* Selected "Express installation"

Software setup:
* git
    ```bash
    $ git config --global user.email "jfnielsen@gmail.com"
    $ git config --global user.name "Jon-Fredrik Nielsen"
    $ git config --global core.editor "vim"   
    ```
    In .bashrc:
    ```bash
    EDITOR=vim
    ```
* vim


### Matlab R2022a

#### Files needed

* R2022a\_Linux.iso, downloaded from U-Mich BME IT Dropbox

That's it -- no need to download license files since this is handled over the network during installation.

#### Install
1. Mount R2022a\_Linux.iso (this file can reside on a USB stick)
2. Allow root to access display
    ```bash
    $ xhost +local:root
    ```
3. Start installer
    ```bash
    $ sudo ./install
    ```
4. Follow instructions to log in, accept license terms, etc.
5. **Toolboxes**:   I'm not sure which toolboxes are required, 
   but I ended up selecting the following which was sufficient:

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
### FOV prescription example/test data

`data.txt` contains output of `printSHM` for various prescriptions.
