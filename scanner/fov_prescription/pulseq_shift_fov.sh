#!/usr/bin/env bash
set -euo pipefail

# Apply FOV shifts to a list of PulSeg scans.
#
# Usage:
#   ./pulseq_shift_fov.sh <scan_list> <Rxfile>
#
# Scan list format:
#   One scan per line:
#
#       <opuser1> <sequence.mat>
#
#   Blank lines and lines beginning with '#' are ignored.
#
# Requirements:
#   Each .mat file must contain:
#       - pge or psq    PulSeg sequence structure (adapted for GE)
#       - params        See pge2.check()
#       - pislquant     See pge2.serialize()
#
# The script loads the .mat files, applies the requested FOV shift, 
# and generates the corresponding .pge files.

# MATLAB Runtime installation on scanner
MATLAB_RUNTIME_DIR="/opt/mathworks_matlab_runtime_r2022a/root/v912"

# MATLAB installation for local testing
# MATLAB_RUNTIME_DIR="/usr/local/MATLAB/R2024b"

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <scan_list> <Rxfile>" >&2
    exit 1
fi

SCAN_LIST="$1"
RXFILE="$2"

if [[ ! -f "$SCAN_LIST" ]]; then
    echo "Error: scan list file not found: $SCAN_LIST" >&2
    exit 1
fi

if [[ ! -f "$RXFILE" ]]; then
    echo "Error: Rxfile not found: $RXFILE" >&2
    exit 1
fi

echo "Applying FOV shifts using scan list: $SCAN_LIST"
echo "Rxfile: $RXFILE"

./run_translateFOVrf_batch.sh \
    "$MATLAB_RUNTIME_DIR" \
    "$SCAN_LIST" \
    "$RXFILE"

echo "Done."

