<p align="left">
  <img src="assets/logo.svg" alt="pulseg logo" width="320"/>
</p>


🛠️ Under Development

**Serialization & utility toolkit for exporting [PulSeg](https://github.com/HarmonizedMRI/pulseg) intermediate representations to GE MRI platforms**

---

## Overview

This package implements the `+pge2` MATLAB namespace for exporting a `PulSeg` intermediate sequence representation to a binary file that can be consumed by the `pge2` GE interpreter.

Key Features:
- `pge2.serialize(psq, filename)`: Export PulSeg sequence object (`psq1) to GE binary format
- `pge2.check(psq, sysGE, ...)`: Check compatibility of psq with GE scanner specifications
- `pge2.plot(psq, sysGE, ...)`: Visualize segment/block layout and detailed timing
- `pge2.validate(psq, seq, ...)`: Validate psq structure and GE simulator (WTools) output against original Pulseq sequence object (`seq`)

> **Note:**
> This package does not execute sequences directly on GE hardware, but prepares files and utilities for the downstream GE backend interpreter.

---

## Installation

Clone the repository:
```bash
git clone https://github.com/HarmonizedMRI/pge2.git
```

Setup up your MATLAB path:
```
>> addpath pge2/matlab   % +pge2 namespace
```

---

## Usage

For the most up to date workflow, see `main.m` in https://github.com/HarmonizedMRI/SequenceExamples-GE/tree/main/pge2/2DGRE

Overview:
1. Create the Pulseq (`.seq`) file. Assign `TRID` label to the first block in each segment instance.

2. Convert to PulSeg intermediate representation
    ```matlab
    psq = pulseg.fromSeq('path/to/sequence.seq'); 
    ```

3.  Export to binary file for execution on GE scanners using the pge2 interpreter
    ```matlab
    pge2.serialize(psq, 'output.bin');            % Export for GE backend
    ```

4. (optional) Compare output of WTools simulator (MR30.2) with the original Pulseq file:
    ```   
    seq = mr.Sequence();
    seq.read('path/to/sequence.seq');
    xmlPath = '~/transfer/xml/';   % directory for Pulse View .xml files
    pge2.validate(psq, sysGE, seq, xmlPath, 'row', [], 'plot', true);
    ```

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

For questions or support, open an [issue](https://github.com/HarmonizedMRI/pge2/issues) or email your-contact@your-domain.edu

---

