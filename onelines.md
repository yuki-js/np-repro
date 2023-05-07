# One lines

### Disable ASLR

```sh
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
```

### Docker build

```sh
docker build -t <image_name> .
```

### stress test

```sh
while true; do python3d test.py; done
```

### key module

```python
from numpy.core._multiarray_umath import _get_implementing_args
```
