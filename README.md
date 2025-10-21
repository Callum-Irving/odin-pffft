# PFFFT Bindings for Odin

PFFFT is "a pretty fast FFT". See https://bitbucket.org/jpommier/pffft/ for the
original C library.

Right now the bindings are only tested for Linux.

## Using these bindings

Before you can use the bindings, you must compile the PFFFT C library. With GCC
on Linux, you can compile the static library with:

```sh
gcc -msse -mfpmath=sse -O3 -Wall -W -c pffft.c -lm -o pffft.o
ar rcs libpffft.a pffft.o
```
