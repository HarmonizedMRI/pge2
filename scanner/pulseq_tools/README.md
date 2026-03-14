# Interactive FOV translation for Pulseq/PulSeg sequences on GE scanners

This directory provides a scanner-side workflow for automatically translating 
FOV slice offsets based on the GE prescription UI, using the MATLAB Runtime.

## Overview

Scanner workflow:
1. Create the file `pulseq_scans.list`. 
   This file contains a list of the PulSeg scan files (`.mat`) to which the FOV shift will be applied.
   Example:
   ```text
    # Example pulse_scans.list file
    # opuser1  scan     description
    48         gre2d    2D GRE demo
    49         b0       field map
    50         t1map    T1 mapping
   ```
   For each scan, a `.mat` file must exist that contains the `psq` object, 
   a`params` struct and `pislquant`.
2. Prescribe any sequence, e.g., built-in 2D SPGR
3. Apply prescribed slice offset to all scans in the `.list` file:
    ```bash
    $ printSHM > Rx.txt
    $ ./pulseq_shift_fov.sh pulseq_scans.list Rx.txt
    ```
   This will create new `.entry` and `.pge` files.
5. Copy the `.entry` files to `/srv/nfs/psd/usr/psd/pulseq/v7/sequences/` on the scanner host computer,
   and copy the `.pge` files to the corresponding locations on the scanner host computer.
6. Prescribe your Pulseq (`pge2`) scans, and for each scan, copy the prescription from Step 1
   (this will copy the prescribed rotation and scanner table location).
   This can be done automatically by linking multiple Series together.
   Run the `pge2` scans as usual.

**What goes on under the hood:**  
For each scan, the function `translateFOVrf.m` is executed.
This does several things:
```
1. loads the PulSeg object from a `.mat` file, 
2. applies the FOV offset using `pge2.translateFOVrf()`, 
3. writes the resulting sequence to a `_fov.pge` file, and
4  creates the corresponding `.entry` file using `pge2.writeentryfile`.
```


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

## Matlab runtime info

This requires **Matlab R2022a** currently.

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
