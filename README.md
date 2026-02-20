<p align="left">
  <img src="assets/logo.svg" alt="PulSeg logo" width="240">
</p>

# pge2

**Serialization & utility toolkit for exporting [PulSeg](https://github.com/HarmonizedMRI/pulseg) intermediate representations to GE MRI platforms**

---

## Overview

This package implements the `+pge2` MATLAB namespace for harmonized MRI research workflows targeting GE hardware. It allows researchers to:

- Serialize PulSeg IR sequences into GE-compatible binary files for use with the GE `pge2` interpreter.
- Validate PulSeg IR objects for GE compatibility.
- Plot and inspect GE-ready sequence structures.
- Run advanced checks with built-in methods like `pge2.check()` and `validate()`.

> **Note:**
> This package does not execute sequences directly on GE hardware, but prepares files and utilities for the downstream GE backend interpreter.

---

## Key Features

- `pge2.serialize(IR, filename)`: Export PulSeg IR to GE binary format
- `pge2.check(IR)`: Consistency checks for GE compatibility
- `pge2.validate(IR)`: Validation of IR structure for GE
- `pge2.plot(IR)`: Visualization of segment/block layout

---

## Installation

Clone the repository and add to your MATLAB path:

```bash
git clone https://github.com/HarmonizedMRI/pge2.git
```

---

## Getting Started

```matlab
IR = pulseg.fromSeq('path/to/sequence.seq');   % Generate IR in PulSeg
pge2.check(IR);                               % Basic compatibility check
pge2.serialize(IR, 'output.gebin');            % Export for GE backend
```

---

## Documentation

See [PulSeg IR specification](https://github.com/HarmonizedMRI/pulseg/blob/dev/docs/spec.md)
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

