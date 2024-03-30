avrlibc_url :=     https://github.com/avrdudes/avr-libc/archive/${AVR_LIBC}.tar.gz
avrlibc_file :=    ${download_dir}/avr-libc-${AVR_LIBC}.tar.gz
avrlibc_src :=     ${source_dir}/avr-libc-${AVR_LIBC}
avrlibc_build :=   ${build_dir}/avr-libc-${AVR_LIBC}

.PHONY: copy_avrio clean_avrlibc clean_avrlibc_src

${avrlibc_build}:
	mkdir -p $@

${avrlibc_file}: ${download_dir}
	curl -q -o $@ -L ${avrlibc_url}

${avrlibc_src}: ${source_dir} ${avrlibc_file}
	tar -C ${source_dir} -xf ${avrlibc_file}

copy_avrio: ${avrlibc_src}
	mkdir -p ${PREFIX}/${TARGET}/include/avr/
	cp -R ${avrlibc_src}/include/avr/*.h ${PREFIX}/${TARGET}/include/avr/
	cp -R ${avrlibc_src}/common/*.h ${PREFIX}/${TARGET}/include/avr/
	cp -R ${avrlibc_src}/common/*.inc ${PREFIX}/${TARGET}/include/avr/
	touch ${PREFIX}/${TARGET}/include/avr/version.h

config_avrlibc: ${avrlibc_src} ${avrlibc_build}
	cd ${avrlibc_src} && \
		PATH=${PREFIX}/bin:"${PATH}" && ./bootstrap
	cd ${avrlibc_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		${avrlibc_src}/configure \
			--prefix=${PREFIX} \
			--host=${TARGET}

compile_avrlibc:
	cd ${avrlibc_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		make -j ${NPROC}

install_avrlibc:
	cd ${avrlibc_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		make install

avrlibc: config_avrlibc compile_avrlibc install_avrlibc

clean_avrlibc:
	rm -rf ${avrlibc_build}

clean_avrlibc_src:
	rm -rf ${avrlibc_file} ${avrlibc_src}
