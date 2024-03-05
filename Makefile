PREFIX ?=          /opt
TARGET ?=          avr
NPROC  ?=          1

BINUTILS ?=        2.42
GCC ?=             13.2.0
PICOLIBC ?=        1.8.6
AVR_LIBC ?=        22d588c80066102993263018d5324d1424c13f0d
NEWLIB ?=          4.4.0

PICOLIBC_arm-none-eabi = arm-none-eabi
PICOLIBC_avr =           avr
PICOLIBC_avr-elf =       avr
PICOLIBC_msp430-elf=     msp430

base_dir :=        ${HOME}/Documents/Dev/gcc-crossbuild
download_dir :=    ${base_dir}/download
source_dir :=      ${base_dir}/source
build_dir :=       ${base_dir}/build/${TARGET}

binutils_url :=    https://www.nic.funet.fi/pub/gnu/ftp.gnu.org/pub/gnu/binutils/binutils-${BINUTILS}.tar.gz
binutils_file :=   ${download_dir}/binutils-${BINUTILS}.tar.gz
binutils_src :=    ${source_dir}/binutils-${BINUTILS}
binutils_build :=  ${build_dir}/binutils-${BINUTILS}

gcc_url :=         https://www.nic.funet.fi/pub/gnu/ftp.gnu.org/pub/gnu//gcc/gcc-${GCC}/gcc-${GCC}.tar.gz
gcc_file :=        ${download_dir}/gcc-${GCC}.tar.gz
gcc_src :=         ${source_dir}/gcc-${GCC}
gcc_build :=       ${build_dir}/gcc-${GCC}

picolibc_url :=    https://github.com/picolibc/picolibc/releases/download/${PICOLIBC}/picolibc-${PICOLIBC}.tar.xz
picolibc_file :=   ${download_dir}/picolibc-${PICOLIBC}.tar.xz
picolibc_src :=    ${source_dir}/picolibc-${PICOLIBC}
picolibc_build :=  ${build_dir}/picolibc-${PICOLIBC}

avrlibc_url :=     https://github.com/avrdudes/avr-libc/archive/${AVR_LIBC}.tar.gz
avrlibc_file :=    ${download_dir}/avr-libc-${AVR_LIBC}.tar.gz
avrlibc_src :=     ${source_dir}/avr-libc-${AVR_LIBC}
avrlibc_build :=   ${build_dir}/avr-libc-${AVR_LIBC}

newlib_url :=      https://github.com/bminor/newlib/archive/refs/tags/newlib-${NEWLIB}.tar.gz
newlib_file :=     ${download_dir}/newlib-${NEWLIB}.tar.gz
newlib_src :=      ${source_dir}/newlib-newlib-${NEWLIB}
newlib_build :=    ${build_dir}/newlib-newlib-${NEWLIB}

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

# ---- avr-libc ---------------------------------------------------------------

${avrlibc_build}:
	mkdir -p $@

${avrlibc_file}: ${download_dir}
	curl -q -o $@ -L ${avrlibc_url}

${avrlibc_src}: ${source_dir} ${avrlibc_file}
	tar -C ${source_dir} -xf ${avrlibc_file}
	cd ${avrlibc_src} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		./bootstrap

config_avrlibc: ${avrlibc_src} ${avrlibc_build}
	cd ${avrlibc_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		${avrlibc_src}/configure --prefix=${PREFIX} --host=${TARGET}

compile_avrlibc:
	cd ${avrlibc_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		make -j ${NPROC}

install_avrlibc:
	cd ${avrlibc_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		make install

# ---- newlib -----------------------------------------------------------------

${newlib_build}:
	mkdir -p $@

${newlib_file}: ${download_dir}
	curl -q -o $@ -L ${newlib_url}

${newlib_src}: ${source_dir} ${newlib_file}
	tar -C ${source_dir} -xf ${newlib_file}

config_newlib: ${newlib_src} ${newlib_build}
	cd ${newlib_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		${newlib_src}/configure \
			--prefix=${PREFIX} \
			--host=${TARGET} \
			--disable-nls

compile_newlib:
	cd ${newlib_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		make -j ${NPROC}

install_newlib:
	cd ${newlib_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		make install

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
			--cross-file ${picolibc_src}/scripts/cross-${PICOLIBC_${TARGET}}.txt \
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
