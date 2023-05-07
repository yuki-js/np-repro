# NumPy Kernel Panic Reproduction

This repository contains a minimal example to reproduce a kernel panic in NumPy.

## Requirements

Intel Core i9-13900K CPU, Ubuntu Server 22.04, Linux 5.15.0-71-generic

OR

The same environment described in this issue https://github.com/microsoft/WSL/issues/10053

## Reproduction

```sh
git clone https://github.com/yuki-js/np-repro.git
cd np-repro
./bar.sh
# on shell in docker
./tst.py
```

## Result

Either of the following results will be occurred.

- Kernel panic
- Segmentation fault
- ImportError
- SystemError
- Stuck (no response)
  - When stuck, press C-P C-Q to detach from the container, then `./bar.sh`
