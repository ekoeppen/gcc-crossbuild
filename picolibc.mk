picolibc_url :=    https://github.com/picolibc/picolibc/releases/download/${PICOLIBC}/picolibc-${PICOLIBC}.tar.xz
picolibc_file :=   ${download_dir}/picolibc-${PICOLIBC}.tar.xz
picolibc_src :=    ${source_dir}/picolibc-${PICOLIBC}
picolibc_build :=  ${build_dir}/picolibc-${PICOLIBC}

.PHONY: config_picolibc compile_picolibc install_picolibc picolibc clean_picolibc clean_picolibc_src

${picolibc_build}:
	mkdir -p $@

${picolibc_file}: ${download_dir}
	curl -q -o $@ -L ${picolibc_url}

${picolibc_src}: ${source_dir} ${picolibc_file}
	tar -C ${source_dir} -xf ${picolibc_file}

ifeq (${TARGET},avr)
picolibc_extra: copy_avrio
else ifeq (${TARGET},msp430-elf)
picolibc_extra: copy_msp430sup
else
picolibc_extra: ;
endif

config_picolibc: ${picolibc_src} ${picolibc_build} picolibc_extra
	cd ${picolibc_build} && \
		PATH=${PREFIX}/bin:"${PATH}" && \
		meson setup ${picolibc_src} \
			-Dincludedir=${TARGET}/include \
			-Dlibdir=${TARGET}/lib \
			-Dprefix=${PREFIX} \
			-Dsysroot-install=true \
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

picolibc: config_picolibc compile_picolibc install_picolibc

clean_picolibc:
	rm -rf ${picolibc_build}

clean_binutils_src:
	rm -rf ${picolibc_file} ${picolibc_src}
