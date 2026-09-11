# Pulseq compilation for the pge2 GE interpreter

This package compiles Pulseq (`.seq`) files into GE-compatible `.pge` and `.entry` files for use with the pge2 GE interpreter. Compilation can be performed directly in MATLAB during development or on the scanner using the MATLAB Runtime.

---

## Overview

The compiler performs the following Pulseq-to-GE compilation pipeline:

```mermaid
flowchart TD
    A["Pulseq<br/>.seq"] --> B["pulseg.import()"]
    B --> C{"Apply FOV<br/>translation?"}
    C -- Yes --> D["pulseg.translateFOVrf()"]
    C -- No --> E["pge2.import()"]
    D --> E

    E --> F["pge2.check()"]

    F --> G["pge2.serialize()"]
    F --> H["pge2.writeentryfile()"]

    G --> I[".pge"]
    H --> J[".entry"]
```

If an `Rx.txt` file is provided, the prescribed slice offset is applied automatically to the RF excitation before importing the sequence into the GE interpreter. This accounts for all components of the prescribed translation that cannot be achieved by scanner table motion, including through-slice offsets for oblique prescriptions. Otherwise, the original Pulseq sequence is compiled without modification.

The prescribed rotation and the scanner z-axis (S/I) translation are always applied, regardless of whether an `Rx.txt` file is provided.

---

## Direct compilation from MATLAB

For development and testing, a Pulseq sequence can be compiled directly from MATLAB:

```matlab
setup

opts = loadOptionsJSON('compilePGE.json');

% Disable prescription-dependent FOV translation if Rx.txt is unavailable
opts = rmfield(opts, 'translateFOV');

opuser1 = 48;
compilePGE('gre2d.seq', opuser1, 'gre2d.pge', opts);
```

This generates `gre2d.pge` and the corresponding `pge48.entry` file.

Direct MATLAB compilation is convenient when developing or modifying a sequence. It can also be used to generate the `.pge` and `.entry` files before going to the scanner when prescription-dependent RF translation is not required.

If an `Rx.txt` file is available, the `translateFOV` field can instead be retained in `opts` to apply the prescribed translation during compilation.

---

## Scanner-side compilation

The standalone compiler allows the same compilation to be performed directly on the scanner using the MATLAB Runtime.

### Compile a single sequence

To compile a single Pulseq sequence:

```bash
./compilePGE.sh gre2d.seq 48 gre2d.pge compilePGE.json
```

where `48` specifies the Pulseq interpreter slot (`pge48.entry`) used by the pge2 GE interpreter.

To compile without prescription-dependent FOV translation:

```bash
./compilePGE.sh gre2d.seq 48 gre2d.pge compilePGE.json --no-translate-fov
```

This is equivalent to removing the `translateFOV` field from `opts` when calling `compilePGE.m` directly from MATLAB.

### Compile multiple sequences

Create a text file (for example `pulseq_scans.list`) containing the Pulseq sequences to compile:

```text
# opuser1    sequence.seq
48           gre2d.seq
49           b0.seq
50           t1map.seq
```

Then compile all sequences using:

```bash
./compilePGE_batch.sh pulseq_scans.list compilePGE.json
```

This generates one `.pge` file and one `.entry` file for every sequence listed.

---

## Scanner prescription

### 1. Prescribe a reference scan

Prescribe any scan on the GE scanner (either a vendor sequence or a Pulseq sequence). This establishes the desired slice position, orientation, and table location.

### 2. Save the prescription

```bash
printSHM > Rx.txt
```

`printSHM` exports the current scanner prescription, including the slice position, orientation, table position, and field of view.

If `translateFOV.Rxfile` is specified in `compilePGE.json`, this information is automatically applied during compilation. Alternatively, prescription-dependent FOV translation can be disabled using `--no-translate-fov` when compiling a single sequence.

### 3. Install the generated entry files

Create symbolic links (or otherwise install) the generated `.entry` files in the GE Pulseq directory.

### 4. Run the Pulseq scans

Run the compiled Pulseq (`pge2`) sequences as usual.

---

## Directory contents

A scanner compilation directory may contain:

```text
compile/
├── compilePGE.sh
├── compilePGE_cli
├── run_compilePGE_cli.sh
├── compilePGE_batch.sh
├── compilePGE_batch
├── run_compilePGE_batch.sh
├── compilePGE.json
├── pulseq_scans.list
├── Rx.txt                    (optional)
└── *.seq
```

- `compilePGE.sh` — command-line interface for compiling a single sequence
- `compilePGE_cli` and `run_compilePGE_cli.sh` — standalone MATLAB executable and launcher for single-sequence compilation
- `compilePGE_batch.sh` — command-line interface for batch compilation
- `compilePGE_batch` and `run_compilePGE_batch.sh` — standalone MATLAB executable and launcher for batch compilation
- `compilePGE.json` — compilation options
- `pulseq_scans.list` — list of sequences for batch compilation
- `Rx.txt` *(optional)* — scanner prescription exported using `printSHM`
- `*.seq` — Pulseq sequence files

> [!NOTE]
> Each standalone executable and its corresponding `run_*.sh` launcher are generated together and should always be copied as a pair.

---

## Configuration

Compilation is controlled by `compilePGE.json`. The same configuration file is used for direct MATLAB compilation and scanner-side compilation.

### Sections

| Section | Purpose |
|---------|---------|
| `pulseg_import` | Options passed to `pulseg.import()` |
| `translateFOV` | Prescription-based FOV translation |
| `pge_opts` | Scanner hardware model passed to `pge2.opts()` |
| `pge_import` | Options passed to `pge2.import()` |
| `pge_check` | Safety-check configuration |
| `pge_serialize` | Serialization options |
| `pge_writeentryfile` | Output options |

### Important fields

| Field | Description |
|------|-------------|
| `pulseg_import.soft_delay_input_ms` | Value assigned to Pu