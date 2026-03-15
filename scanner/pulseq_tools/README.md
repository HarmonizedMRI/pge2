# Prescribe FOV offset interactively on the scanner

## Overview

This workflow allows Pulseq-based sequences to use the
standard GE scanner prescription interface for **FOV translation and rotation**.

The workflow automatically reads the prescribed FOV offset from the scanner
(using `printSHM`) and applies it to the PulSeg sequence by calling
`pge2.translateFOVrf()` via the MATLAB Runtime installed on the scanner.

The result is a `.pge` sequence that reflects the prescribed FOV translation.

Workflow summary:
1. Prescribe a reference scan on the GE scanner.
2. Run `printSHM > Rx.txt` to record the current prescription.
3. Run `pulseq_shift_fov.sh` to apply the prescribed FOV translation to multiple Pulseq sequences.
4. Run the generated `pge<n>.entry` and corresponding `.pge` sequences as usual.

```mermaid
flowchart LR
A[Prescribe scan on GE UI]
B[printSHM -> Rx.txt]
C[pulseq_shift_fov.sh]
D[translateFOVrf_batch executable]
E[.pge + .entry files]

A --> B
B --> C
C --> D
D --> E
```


## Scanner workflow

1. Create the file `pulseq_scans.list`, in a local directory of your choice on the scanner. 
   This file contains a list of the PulSeg scan files (`.mat`) to which the FOV shift will be applied.
   Example:
   ```text
   # Example pulseq_scans.list file
   # opuser1     scan            description
   48            gre2d.mat       2D GRE demo
   49            b0.mat          field map
   50            t1map.mat       T1 mapping
   ```
   The `opuser1` column specifies the Pulseq sequence slot used by the GE Pulseq
   interpreter sequence (`pge<opuser1>.entry`).
   GE protocols store this integer value, allowing Pulseq protocols to be
   installed permanently without interfering with other Pulseq scans.  
   The directory should now contain the following:
   ```
   ## Example protocol directory structure
   example_protocol/
   ├── pulseq_scans.list
   ├── gre2d.mat
   ├── b0.mat
   ├── t1map.mat
   ├── pulseq_shift_fov.sh
   ├── run_translateFOVrf_batch.sh
   ├── translateFOVrf_batch
   ├── translateFOVrf
   ```
2. Prescribe any sequence, e.g., built-in 2D SPGR oblique.
3. Apply the prescribed FOV translation to all scans in the `.list` file:
   ```bash
   $ printSHM > Rx.txt
   $ ./pulseq_shift_fov.sh pulseq_scans.list Rx.txt
   ```
   This will create new `.entry` and `_fov.pge` files.
4. Copy the `.entry` files to `/srv/nfs/psd/usr/psd/pulseq/v7/sequences/` on the scanner host computer.
   You do not need to move the `_fov.pge` files -- the `.entry` file points to the current working directory.
5. Prescribe your Pulseq (`pge2`) scans, and for each scan, copy the prescription from Step 1
   (this will copy the prescribed rotation and scanner table location).
   This can be done automatically by linking multiple Series together.
   Run the `pge2` scans as usual.

### What goes on under the hood
For each scan, the function `translateFOVrf.m` is executed.
This does several things:
1. loads the PulSeg object from a `.mat` file, 
2. applies the FOV offset using `pge2.translateFOVrf()`, 
3. writes the resulting sequence to a `_fov.pge` file, and
4  creates the corresponding `.entry` file using `pge2.writeentryfile`.

 
## Preparing the `.mat` files

Each `.mat` file must contain a `psq` object, 
a `params` struct and `pislquant`.
Example:
```matlab
>> psq = pulseg.fromSeq('gre2d.seq');
>> params = pge2.check(psq, sys_ge, ...);
>> pislquant = 10;   % number of ADC events for receive gain calibration in Auto Prescan
>> save gre2d.mat psq params pislquant
```

For more details on working with these functions, see the 'official' PulSeg/pge2 demo sequence at
https://github.com/HarmonizedMRI/SequenceExamples-GE/tree/main/pge2/2DGRE.


## GE prescription data (`printSHM`)

The scanner command-line utility `printSHM` reads the prescribed slice position, orientation, and FOV
directly from the GE shared memory:
```bash
printSHM > Rx.txt
```
The `translateFOVrf` function uses these values to compute the
corresponding FOV translation for the PulSeg sequence via
```matlab
pge2.translateFOVrf()
```
This allows Pulseq sequences to follow the standard GE prescription
workflow, including:

* slice offsets
* oblique rotations
* table position


## Building the MATLAB executable

1. **Compile:**
   On local computer with R2022a installed:
   ```matlab
   >> mcc -m translateFOVrf_batch.m
   ```

2. **Test on local computer:**
   To run on local computer command line (Linux), for testing:
   1. Set `MATLAB_RUNTIME_DIR` in `pulseq_shift_fov.sh`
   2. Obtain an example output of `printSHM > Rx.txt` on the scanner.
   3. Run the script:
      ```bash
      $ ./pulseq_shift_fov.sh pulseq_scans.list Rx.txt
      ```
   This should produce a set of `.pge` and `.entry` files.

3. **Test on the scanner:**
   Same as testing locally, except set the value of `MATLAB_RUNTIME_DIR` to point to
   the runtime installation on the scanner, e.g., `/opt/mathworks_matlab_runtime_r2022a/root/v912`


## Developer setup

### Matlab runtime info

#### Scanner

On our GE UHP 3T, Matlab runtime is `/opt/mathworks_matlab_runtime_r2022a/root/v912/`

> [!IMPORTANT] Therefore, the `.m` file must be compiled with Matlab R2022a.

#### Local installation (not needed but info is here if useful)

```matlab
>> mcrinstaller
MATLAB Runtime installer cannot be found. Download it using the command: compiler.runtime.download
>> compiler.runtime.download
Downloading MATLAB Runtime installer. It may take several minutes...
>> mcrinstaller
    '/home/jon/.MathWorks/MatlabRuntimeCache/MCRInstaller24.2/MATLAB_Runtime_R2024b_Update_4_glnxa64.zip'
```

### Ubuntu 22.04 LTS installation

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


### Matlab R2022a installation

#### Files needed

* R2022a\_Linux.iso, downloaded from U-Mich BME IT Dropbox

That's it -- no need to download license files since this is handled over the network during installation.

#### Installation

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
