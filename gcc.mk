gcc_url :=         https://ftpmirror.gnu.org/gnu/gcc/gcc-${GCC}/gcc-${GCC}.tar.gz
gcc_file :=        ${download_dir}/gcc-${GCC}.tar.gz
gcc_src :=         ${source_dir}/gcc-${GCC}
gcc_build :=       ${build_dir}/gcc-${GCC}

.PHONY: config_gcc \
    compile_gcc_stage1 compile_gcc_stage2 \
    install_gcc_stage1 install_gcc_stage2 \
    gcc_stage1 gcc_stage2 \
    clean_gcc clean_gcc_src

ifeq (${TARGET},avr)
avr_opts := --with-double=64 --with-long-double=double
else
avr_opts :=
endif

${gcc_build}:
	mkdir -p $@

${gcc_file}: ${download_dir}
	curl -q -o $@ -L ${gcc_url}

${gcc_src}: ${source_dir} ${gcc_file}
	tar -C ${source_dir} -xf ${gcc_file}
	sed -ibak 's/__AVR__/__AVR_LIBC__/g' ${gcc_src}/libstdc++-v3/src/filesystem/ops-common.h
	mv ${gcc_src}/gcc/config/avr/avr-mcus.def ${gcc_src}/gcc/config/avr/avr-mcus.def.orig
	awk '/"avrxmega|"avr2",|"avr5",|"avr25,"/{print $0}' ${gcc_src}/gcc/config/avr/avr-mcus.def.orig > ${gcc_src}/gcc/config/avr/avr-mcus.def
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
		--without-libiconv-prefix \
		${avr_opts}

compile_gcc_stage1:
	cd ${gcc_build} && make -j ${NPROC} all-gcc

install_gcc_stage1:
	cd ${gcc_build} && make install-strip-gcc

compile_gcc_stage2:
	cd ${gcc_build} && make -j ${NPROC}

install_gcc_stage2:
	cd ${gcc_build} && make install-strip

gcc_stage1: config_gcc compile_gcc_stage1 install_gcc_stage1

gcc_stage2: compile_gcc_stage2 install_gcc_stage2

clean_gcc:
	rm -rf ${gcc_build}

clean_gcc_src:
	rm -rf ${gcc_file} ${gcc_src}
