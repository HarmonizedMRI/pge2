#!/usr/bin/env bash

set -euo pipefail

# Compile a single Pulseq sequence into GE .pge and .entry files.
#
# Usage:
#
#   ./compilePGE.sh <sequence.seq> <opuser1> <output.pge> <config.json>
#
# Disable prescription-dependent FOV translation:
#
#   ./compilePGE.sh <sequence.seq> <opuser1> <output.pge> <config.json> \
#       --no-translate-fov

MATLAB_RUNTIME_DIR=/opt/mathworks_matlab_runtime_r2022a/root/v912

# Example MATLAB installation for local testing:
# MATLAB_RUNTIME_DIR=/usr/local/MATLAB/R2024b

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUN_SCRIPT="${SCRIPT_DIR}/run_compilePGE_cli.sh"

if [[ $# -lt 4 || $# -gt 5 ]]; then
    echo "Usage: $0 <sequence.seq> <opuser1> <output.pge> <config.json> [--no-translate-fov]" >&2
    exit 1
fi

SEQ_FILE="$1"
OPUSER1="$2"
OUTPUT_FILE="$3"
CONFIG_JSON="$4"

NO_TRANSLATE_FOV=false

if [[ $# -eq 5 ]]; then
    if [[ "$5" == "--no-translate-fov" ]]; then
        NO_TRANSLATE_FOV=true
    else
        echo "Error: unknown option: $5" >&2
        exit 1
    fi
fi

if [[ ! -f "$SEQ_FILE" ]]; then
    echo "Error: Pulseq sequence not found: $SEQ_FILE" >&2
    exit 1
fi

if [[ ! "$OPUSER1" =~ ^[0-9]+$ ]]; then
    echo "Error: opuser1 must be an integer: $OPUSER1" >&2
    exit 1
fi

if [[ ! -f "$CONFIG_JSON" ]]; then
    echo "Error: JSON configuration file not found: $CONFIG_JSON" >&2
    exit 1
fi

if [[ ! -x "$RUN_SCRIPT" ]]; then
    echo "Error: MATLAB Runtime launcher not found or not executable:" >&2
    echo "  $RUN_SCRIPT" >&2
    exit 1
fi

if [[ ! -d "$MATLAB_RUNTIME_DIR" ]]; then
    echo "Error: MATLAB Runtime directory not found:" >&2
    echo "  $MATLAB_RUNTIME_DIR" >&2
    exit 1
fi

echo "Compiling Pulseq sequence"
echo "  Sequence:       $SEQ_FILE"
echo "  opuser1:        $OPUSER1"
echo "  Output:         $OUTPUT_FILE"
echo "  Configuration:  $CONFIG_JSON"
echo "  MATLAB Runtime: $MATLAB_RUNTIME_DIR"

if [[ "$NO_TRANSLATE_FOV" == true ]]; then
    echo "  FOV translation: disabled"
fi

"$RUN_SCRIPT" \
    "$MATLAB_RUNTIME_DIR" \
    "$SEQ_FILE" \
    "$OPUSER1" \
    "$OUTPUT_FILE" \
    "$CONFIG_JSON" \
    "$NO_TRANSLATE_FOV"

echo "Compilation complete."
