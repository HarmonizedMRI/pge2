#!/usr/bin/env bash

# Apply FOV shift to a list of Pulseq scans.
#
# Usage:
#   1. Create a file 'pulseq_scans.list' containing the list of PulSeg scans
#      For each scan, a .mat file must be present that contains the variables:
#         psq         PulSeg struct, see pulseg.fromSeq()
#         params      See pge2.check()
#         pislquant   See pge2.write()
#   2. Apply FOV shift and install the corresponding `.pge` files:
#      `$ ./set_fov_pulseq.sh pulseq_scans.list`

# Matlab runtime path for scanner. Edit as needed
MATLAB_RUNTIME_DIR=/opt/mathworks_matlab_runtime_r2022a/root/v912 

# Matlab path for testing on your personal computer
#MATLAB_RUNTIME_DIR=/usr/local/MATLAB/R2024b
MATLAB_RUNTIME_DIR=/usr/local/MATLAB/R2022a

SCAN_LIST="$1"

if [ ! -f "$SCAN_LIST" ]; then
    echo "Scan list file not found: $SCAN_LIST"
    exit 1
fi

# Apply FOV shift and write .pge and .entry files
./run_translateFOVrf_batch.sh "$MATLAB_RUNTIME_DIR" "$SCAN_LIST" "$2"

echo "Done."

