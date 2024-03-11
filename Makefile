TARGET ?=          avr
PREFIX ?=          /var/tmp/${TARGET}
NPROC  ?=          1

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

base_dir :=        /var/tmp/gcc-crossbuild
download_dir :=    ${base_dir}/download
source_dir :=      ${base_dir}/source
build_dir :=       ${base_dir}/build/${TARGET}

.PHONY: clean clean_download clean_source clean_build \
	compile_binutils config_binutils install_binutils \
	compile_picolibc config_picolibc install_picolibc \
	compile_gcc config_gcc install_gcc

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

clean: clean_download clean_source clean_build

build_all: binutils gcc_stage1 picolibc gcc_stage2
