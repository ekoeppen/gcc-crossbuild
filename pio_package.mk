ifeq (${TARGET},arm-none-eabi)
PACKAGE_TARGET := arm
else ifeq (${TARGET},msp430-elf)
PACKAGE_TARGET := msp430
else
PACKAGE_TARGET := ${TARGET}
endif

ifeq (${TARGET},arm-none-eabi)
PACKAGE_TARGET := arm
else ifeq (${TARGET},msp430-elf)
PACKAGE_TARGET := msp430
else
PACKAGE_TARGET := ${TARGET}
endif

pio_package: ${PREFIX}/package.json
	echo {\"name\":\"toolchain-gcc${PACKAGE_TARGET}\",\
        \"version\":\"${GCC}\",\
        \"description\":\"GNU GCC for ${PACKAGE_TARGET}\",\
        \"homepage\":\"https://gcc.gnu.org\",\
        \"license\":\"GPL-2.0-or-later\",\
        \"repository\":{\
        \"type\":\"git\",\
        \"url\":\"https://gcc.gnu.org/git/gcc.git\"\
        }} > ${PREFIX}/package.json
