newlib_url :=      https://github.com/bminor/newlib/archive/refs/tags/newlib-${NEWLIB}.tar.gz
newlib_file :=     ${download_dir}/newlib-${NEWLIB}.tar.gz
newlib_src :=      ${source_dir}/newlib-newlib-${NEWLIB}
newlib_build :=    ${build_dir}/newlib-newlib-${NEWLIB}

.PHONY: config_newlib compile_newlib install_newlib newlib clean_newlib clean_newlib_src

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
			--target=${TARGET} \
			--disable-nls

compile_newlib:
	cd ${newlib_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		make -j ${NPROC}

install_newlib:
	cd ${newlib_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		make install

newlib: config_newlib compile_newlib install_newlib

clean_newlib:
	rm -rf ${newlib_build}

clean_binutils_src:
	rm -rf ${newlib_file} ${newlib_src}
