#!/usr/bin/env bash

set -euo pipefail

# Compile a single Pulseq sequence into GE .pge and .entry files.
#
# Usage:
#   ./compilePGE.sh <sequence.seq> <opuser1> <pislquant> <output.pge> <config.json> \
#       [--soft-delay-input-ms <ms>] [--no-translate-fov]

MATLAB_RUNTIME_DIR=/opt/mathworks_matlab_runtime_r2022a/root/v912

# Example MATLAB installation for local testing:
MATLAB_RUNTIME_DIR=/usr/local/MATLAB/R2024b

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUN_SCRIPT="${SCRIPT_DIR}/run_compilePGE_cli.sh"

if [[ $# -lt 5 ]]; then
    echo "Usage: $0 <sequence.seq> <opuser1> <pislquant> <output.pge> <config.json> [--soft-delay-input-ms <ms>] [--no-translate-fov]" >&2
    exit 1
fi

SEQ_FILE="$1"
OPUSER1="$2"
PISLQUANT="$3"
OUTPUT_FILE="$4"
CONFIG_JSON="$5"
shift 5

if [[ ! -f "$SEQ_FILE" ]]; then
    echo "Error: Pulseq sequence not found: $SEQ_FILE" >&2
    exit 1
fi

if [[ ! "$OPUSER1" =~ ^[0-9]+$ ]]; then
    echo "Error: opuser1 must be an integer: $OPUSER1" >&2
    exit 1
fi

if [[ ! "$PISLQUANT" =~ ^[0-9]+$ ]]; then
    echo "Error: pislquant must be an integer: $PISLQUANT" >&2
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

ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --soft-delay-input-ms)
            if [[ $# -lt 2 ]]; then
                echo "Error: --soft-delay-input-ms requires a value." >&2
                exit 1
            fi
            ARGS+=("$1" "$2")
            shift 2
            ;;
        --no-translate-fov)
            ARGS+=("$1")
            shift
            ;;
        *)
            echo "Error: unknown option: $1" >&2
            exit 1
            ;;
    esac
done

echo "Compiling Pulseq sequence"
echo "  Sequence:       $SEQ_FILE"
echo "  opuser1:        $OPUSER1"
echo "  pislquant:      $PISLQUANT"
echo "  Output:         $OUTPUT_FILE"
echo "  Configuration:  $CONFIG_JSON"
echo "  MATLAB Runtime: $MATLAB_RUNTIME_DIR"

"$RUN_SCRIPT" \
    "$MATLAB_RUNTIME_DIR" \
    "$SEQ_FILE" \
    "$OPUSER1" \
    "$PISLQUANT" \
    "$OUTPUT_FILE" \
    "$CONFIG_JSON" \
    "${ARGS[@]}"

echo "Compilation complete."
