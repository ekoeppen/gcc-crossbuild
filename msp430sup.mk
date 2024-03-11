msp430sup_url :=   https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-LlCjWuAbzH/9.3.1.2/msp430-gcc-support-files-1.212.zip
msp430sup_file :=  ${download_dir}/msp430-gcc-support-files-1.212.zip
msp430sup_src :=   ${source_dir}/msp430-gcc-support-files
msp430sup_build := ${build_dir}/msp430-gcc-support-files

.PHONY: copy_msp430sup clean_msp430sup_src

${msp430sup_build}:
	mkdir -p $@

${msp430sup_file}: ${download_dir}
	curl -q -o $@ -L ${msp430sup_url}

${msp430sup_src}: ${source_dir} ${msp430sup_file}
	unzip -o ${msp430sup_file} -d ${source_dir}

copy_msp430sup: ${msp430sup_src}
	mkdir -p ${PREFIX}/${TARGET}/include/msp430/
	cp -R ${msp430sup_src}/include/* ${PREFIX}/${TARGET}/include/msp430/

clean_msp430sup_src:
	rm -rf ${msp430sup_file} ${msp430sup_src}
