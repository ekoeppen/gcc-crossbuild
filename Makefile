TARGET ?=          avr
PREFIX ?=          /var/tmp/${TARGET}
NPROC  ?=          1
BASE_DIR ?=        /var/tmp/gcc-crossbuild

BINUTILS ?=        2.42
GCC ?=             13.2.0
PICOLIBC ?=        1.8.6
AVR_LIBC ?=        22d588c80066102993263018d5324d1424c13f0d
NEWLIB ?=          4.4.0

ifeq (${TARGET},msp430-elf)
PICOLIBC_TARGET = msp430
else
PICOLIBC_TARGET = ${TARGET}
endif

download_dir :=    ${BASE_DIR}/download
source_dir :=      ${BASE_DIR}/source
build_dir :=       ${BASE_DIR}/build/${target}

.PHONY: clean clean_download clean_source clean_build sources build_all

${download_dir}:
	mkdir -p ${download_dir}

${source_dir}:
	mkdir -p ${source_dir}

clean_download:
	rm -rf ${download_dir}

clean_source:
	rm -rf ${source_dir}

clean_build:
	rm -rf ${build_dir}

sources: ${binutils_src} ${picolibc_src} ${gcc_src}

include binutils.mk
include gcc.mk
include avrlibc.mk
include msp430sup.mk
include newlib.mk
include picolibc.mk
include pio_package.mk

clean: clean_download clean_source clean_build

build_all: binutils gcc_stage1 picolibc gcc_stage2 pio_package
