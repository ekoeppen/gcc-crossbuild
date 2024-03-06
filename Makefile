TARGET ?=          avr
PREFIX ?=          /opt
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

base_dir :=        ${HOME}/Documents/Dev/gcc-crossbuild
download_dir :=    ${base_dir}/download
source_dir :=      ${base_dir}/source
build_dir :=       ${base_dir}/build/${TARGET}

binutils_url :=    https://ftpmirror.gnu.org/pub/gnu/ftp.gnu.org/pub/gnu/binutils/binutils-${BINUTILS}.tar.gz
binutils_file :=   ${download_dir}/binutils-${BINUTILS}.tar.gz
binutils_src :=    ${source_dir}/binutils-${BINUTILS}
binutils_build :=  ${build_dir}/binutils-${BINUTILS}

gcc_url :=         https://ftpmirror.gnu.org/pub/gnu/ftp.gnu.org/pub/gnu//gcc/gcc-${GCC}/gcc-${GCC}.tar.gz
gcc_file :=        ${download_dir}/gcc-${GCC}.tar.gz
gcc_src :=         ${source_dir}/gcc-${GCC}
gcc_build :=       ${build_dir}/gcc-${GCC}

picolibc_url :=    https://github.com/picolibc/picolibc/releases/download/${PICOLIBC}/picolibc-${PICOLIBC}.tar.xz
picolibc_file :=   ${download_dir}/picolibc-${PICOLIBC}.tar.xz
picolibc_src :=    ${source_dir}/picolibc-${PICOLIBC}
picolibc_build :=  ${build_dir}/picolibc-${PICOLIBC}

.PHONY: clean clean_download clean_source clean_build \
	compile_binutils config_binutils install_binutils \
	compile_picolibc config_picolibc install_picolibc \
	compile_gcc config_gcc install_gcc

${download_dir}:
	mkdir -p ${download_dir}

${source_dir}:
	mkdir -p ${source_dir}

sources: ${binutils_src} ${picolibc_src} ${gcc_src}

# ---- binutils ---------------------------------------------------------------

${binutils_build}:
	mkdir -p $@

${binutils_file}: ${download_dir}
	curl -q -o $@ -L ${binutils_url}

${binutils_src}: ${source_dir} ${binutils_file}
	tar -C ${source_dir} -xf ${binutils_file}

config_binutils: ${binutils_src} ${binutils_build}
	cd ${binutils_build} && \
		${binutils_src}/configure \
		--target=${TARGET} \
		--prefix=${PREFIX} \
		--disable-nls \
		--disable-shared \
		--disable-host-shared \
		--disable-werror \
		--enable-interwork

compile_binutils:
	cd ${binutils_build} && make -j ${NPROC}

install_binutils:
	cd ${binutils_build} && make install-strip

binutils: config_binutils compile_binutils install_binutils

# ---- gcc --------------------------------------------------------------------

${gcc_build}:
	mkdir -p $@

${gcc_file}: ${download_dir}
	curl -q -o $@ -L ${gcc_url}

${gcc_src}: ${source_dir} ${gcc_file}
	tar -C ${source_dir} -xf ${gcc_file}
	cd ${gcc_src} && ./contrib/download_prerequisites

config_gcc: ${gcc_src} ${gcc_build}
	cd ${gcc_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		${gcc_src}/configure \
		--target=${TARGET} \
		--prefix=${PREFIX} \
		--enable-languages="c,c++" \
		--enable-cstdio=stdio_pure \
		--enable-libstdcxx \
		--disable-libada \
		--disable-libcc1 \
		--disable-libcilkrts \
		--disable-libffi \
		--disable-libgomp \
		--disable-libmudflap \
		--disable-libquadmath \
		--disable-libsanitizer \
		--disable-libssp \
		--disable-libstdcxx-pch \
		--disable-lto \
		--disable-nls \
		--disable-shared \
		--disable-threads \
		--disable-tls \
		--disable-bootstrap \
		--with-gnu-as \
		--with-gnu-ld \
		--with-libgloss \
		--with-system-zlib \
		--with-newlib \
		--without-libiconv-prefix

compile_gcc_stage1:
	cd ${gcc_build} && make -j ${NPROC} all-gcc

install_gcc_stage1:
	cd ${gcc_build} && make install-strip-gcc

compile_gcc_stage2:
	cd ${gcc_build} && make -j ${NPROC}

install_gcc_stage2:
	cd ${gcc_build} && make install-strip

# ---- picolibc ---------------------------------------------------------------

${picolibc_build}:
	mkdir -p $@

${picolibc_file}: ${download_dir}
	curl -q -o $@ -L ${picolibc_url}

${picolibc_src}: ${source_dir} ${picolibc_file}
	tar -C ${source_dir} -xf ${picolibc_file}

config_picolibc: ${picolibc_src} ${picolibc_build}
	cd ${picolibc_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		meson setup ${picolibc_src} \
			-Dincludedir=${TARGET}/include \
			-Dlibdir=${TARGET}/lib \
			-Dprefix=${PREFIX} \
			-Dnewlib-iconv-encodings-exclude=big5 \
			--cross-file ${picolibc_src}/scripts/cross-${PICOLIBC_TARGET}.txt \
			${picolib_src}

compile_picolibc:
	cd ${picolibc_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
	ninja

install_picolibc:
	cd ${picolibc_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
	ninja install

# ---- clean ------------------------------------------------------------------

clean_download:
	rm -rf ${download_dir}

clean_source:
	rm -rf ${source_dir}

clean_build:
	rm -rf ${picolibc_build}
	rm -rf ${binutils_build}
	rm -rf ${gcc_build}

clean: clean_download clean_source clean_build

build_all: config_binutils compile_binutils install_binutils \
	config_gcc compile_gcc_stage1 install_gcc_stage1 \
	config_picolibc compile_picolibc install_picolibc \
	compile_gcc_stage2 install_gcc_stage2
