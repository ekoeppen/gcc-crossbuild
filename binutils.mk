binutils_url :=    https://ftpmirror.gnu.org/gnu/binutils/binutils-${BINUTILS}.tar.gz
binutils_file :=   ${download_dir}/binutils-${BINUTILS}.tar.gz
binutils_src :=    ${source_dir}/binutils-${BINUTILS}
binutils_build :=  ${build_dir}/binutils-${BINUTILS}

.PHONY: compile_binutils config_binutils install_binutils \
    clean_binutils clean_binutils_src

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

clean_binutils:
	rm -rf ${binutils_build}

clean_binutils_src:
	rm -rf ${binutils_file} ${binutils_src}
