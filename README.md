# gcc-crossbuild

Makefile to create GCC cross-compilers

## MSP430 specific

- GCC is only compiled for avrxmega2/3/4, avr2, avr25 and avr5
- Specs are only generated for architectures, not devices
- long and long double are set to 64 bits each

## Picolibc related changes

- Dedicated MSP430 linker scripts for avr2/25/5, avrxmega2/4 (read only data in flash mapped to data) and avrxmega3 (read only data in flash)
- Include paths injected via spec files are added at the end of the search order
- GCC_EXEC_PREFIX needs to be set
