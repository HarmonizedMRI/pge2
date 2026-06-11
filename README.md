<p align="left">
  <img src="assets/logo.svg" alt="pulseg logo" width="320"/>
</p>


**Serialization & utility toolkit for exporting [PulSeg](https://github.com/HarmonizedMRI/pulseg) intermediate representations to GE MRI platforms**

---

## Overview

This package implements the `+pge2` MATLAB namespace for exporting PulSeg
sequence representations to a binary file that can be consumed by the `pge2` GE
interpreter.

The current `pge2` tools operate on a legacy internal struct called `pge_ir`. New PulSeg
development is moving toward the PulSeg 2.0-alpha intermediate representation
(`pulseg_ir`). During this transition, `pge2` supports PulSeg 2.0-alpha through a
compatibility adapter:

```matlab
pulseg_ir = pulseg.import('path/to/sequence.seq');
pge_ir    = pge2.import(pulseg_ir);
```

where:

- `pulseg_ir` is the PulSeg 2.0-alpha intermediate representation.
- `pge_ir` is the legacy pge2-compatible struct used by existing export/check/plot tools.

Key Features:
- `pge2.import(pulseg_ir)`: Convert PulSeg 2.0-alpha IR to legacy `pge_ir` struct
- `pge2.serialize(pge_ir, 'output.pge')`: Export `pge_ir` sequence object to GE binary format
- `pge2.check(pge_ir, sysGE, ...)`: Check compatibility of `pge_ir` sequence object with GE scanner specifications
- `pge2.plot(pge_ir, sysGE, ...)`: Visualize segment/block layout and detailed timing
- `pge2.validate(pge_ir, seq, ...)`: Validate `pge_ir` structure and GE simulator (WTools) output against original Pulseq sequence object (`seq`)

> **Note:**
> This package does not execute sequences directly on GE hardware, but prepares files and utilities for the downstream GE backend interpreter.

> **Alpha status:**
> PulSeg 2.0 support in `pge2` is currently an alpha-stage compatibility path intended
> for collaborator feedback and testing. The PulSeg 2.0-alpha representation and the
> `pge_ir` adapter may change before a stable PulSeg 2.0 release.

---

## Installation

Clone the repository:

```bash
git clone https://github.com/HarmonizedMRI/pge2.git
```

Set up your MATLAB path:

```matlab
addpath('/path/to/pge2/matlab')   % +pge2 namespace
addpath('/path/to/pulseg/matlab') % +pulseg namespace
```

You will also need the MATLAB Pulseq toolbox on your path.

---

## Usage

For the most up-to-date workflow, see `main.m` in:

https://github.com/HarmonizedMRI/SequenceExamples-GE/tree/main/pge2/2DGRE

Overview:

1. Create the Pulseq (`.seq`) file. Assign a `TRID` label to the first block in each segment instance.

2. Convert the Pulseq file to the PulSeg 2.0-alpha intermediate representation:

    ```matlab
    pulseg_ir = pulseg.import('path/to/sequence.seq');
    ```

3. Convert the PulSeg 2.0-alpha IR to the legacy pge2-compatible `pge_ir` struct:

    ```matlab
    pge_ir = pge2.import(pulseg_ir);
    ```

    Equivalently, the explicit adapter can be called directly:

    ```matlab
    pge_ir = pge2.pulseg2pge(pulseg_ir);
    ```

4. Export to binary file for execution on GE scanners using the pge2 interpreter:

    ```matlab
    pge2.serialize(pge_ir, 'output.pge');
    ```

5. Optional: compare output of the WTools simulator with the original Pulseq file:

    ```matlab
    seq = mr.Sequence();
    seq.read('path/to/sequence.seq');

    xmlPath = '~/transfer/xml/';   % directory for Pulse View .xml files

    pge2.validate(pge_ir, sysGE, seq, xmlPath, 'row', [], 'plot', true);
    ```

---

## PulSeg 2.0-alpha compatibility

PulSeg 2.0-alpha represents sequences using:

- `base_blocks`
- `virtual_segments`
- `execution_stream`

Existing `pge2` tools expect the older `pge_ir` representation, including fields such as:

- `pge_ir.loop`
- `pge_ir.segments`
- `pge_ir.parentBlocks`
- `pge_ir.nMax`
- `pge_ir.nSegments`
- `pge_ir.nParentBlocks`

The adapter:

```matlab
pge_ir = pge2.pulseg2pge(pulseg_ir);
```

maps PulSeg 2.0-alpha objects into this legacy-compatible structure.

### ID mapping

PulSeg 2.0-alpha uses reserved base block IDs:

| PulSeg base block ID | Meaning |
|---:|---|
| `0` | implicit constant delay |
| `1` | implicit variable delay |
| `>= 2` | explicit normalized base block |

Legacy `pge_ir` uses:

| Legacy block ID | Meaning |
|---:|---|
| `0` | constant delay |
| `-1` | variable delay |
| `>= 1` | explicit parent block index |

The adapter maps between these conventions automatically.

### ADC frequency offsets

PulSeg 2.0-alpha stores RF and ADC frequency offsets separately:

- `rf_frequency_offset`
- `adc_frequency_offset`

The legacy `pge_ir.loop` table does not contain a dedicated ADC frequency offset column.
To preserve this information, the adapter stores ADC frequency offsets in a row-aligned
sidecar field:

```matlab
pge_ir.loop_adc_frequency_offset
```

Existing legacy pge2 tools may ignore this field if ADC frequency offsets are not needed.

---

## Development notes

The current development strategy is intentionally conservative:

1. Use PulSeg 2.0-alpha as the source representation.
2. Convert to legacy `pge_ir` for existing `pge2` tools.
3. Gradually migrate `pge2` internals to operate directly on `pulseg_ir` where useful.

This avoids a large rewrite while PulSeg 2.0 is still evolving.

Long-term, direct `pulseg_ir` support is preferred over depending on `pge_ir.loop`.

---

## Documentation

Full API documentation coming soon.

---

## Contributing

Feedback and pull requests are welcome—please see [issues](https://github.com/HarmonizedMRI/pge2/issues).

---

## License

MIT License

---

## Contact

For questions or support, open an [issue](https://github.com/HarmonizedMRI/pge2/issues).

---
