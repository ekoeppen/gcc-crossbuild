/*
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Copyright © 2019 Keith Packard
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials provided
 *    with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <string.h>
#include <picotls.h>
#include <stdint.h>
#include <stdlib.h>

typedef uint32_t uint_farptr_t;

#include <avr/io.h>
#include <avr/pgmspace.h>

#ifdef _VECTOR_SIZE
#if _VECTOR_SIZE == 2
#define VJMP "rjmp"
#elif _VECTOR_SIZE == 4
#define VJMP "jmp"
#else
#error _VECTOR_SIZE must be 2 or 4 bytes
#endif
#else
#if defined(__AVR_MEGA__) && __AVR_MEGA__
#define VJMP "jmp"
#else
#define VJMP "rjmp"
#endif
#endif /* _VECTOR_SIZE */

extern const char __data_source[] PROGMEM;
extern char __data_start[];
extern char __data_end[];
extern char __data_size[];
extern char __bss_start[];
extern char __bss_end[];
extern char __bss_size[];
extern char __tls_base[];
extern char __tdata_end[];
extern char __tls_end[];

#ifdef __PICOLIBC_CRT_RUNTIME_SIZE
#define __data_size (__data_end - __data_start)
#define __bss_size (__bss_end - __bss_start)
#endif

/* This is the application entry point */
int
main(int, char **);

#ifdef _HAVE_INITFINI_ARRAY
extern void __libc_init_array(void);
#endif

/* After the architecture-specific chip initialization is done, this
 * function initializes the data and bss segments. Note that a static
 * block of TLS data is carefully interleaved with the regular data
 * and bss segments in picolibc.ld so that this one operation
 * initializes both. Then it runs the application code, starting with
 * any initialization functions, followed by the main application
 * entry point and finally any cleanup functions
 */

#include <picotls.h>
#include <stdio.h>
#ifdef CRT0_SEMIHOST
#include <semihost.h>
#endif

#ifndef CONSTRUCTORS
#define CONSTRUCTORS 1
#endif

void
_start(void)
{
	for (uintptr_t i = 0; i < (uintptr_t) __data_size; i++) {
		__data_start[i] = pgm_read_byte(__data_source + i);
	}
	for (uintptr_t i = 0; i < (uintptr_t) __bss_size; i++) {
		__bss_start[i] = 0;
	}
#ifdef PICOLIBC_TLS
	_set_tls(__tls_base);
#endif
#if defined(_HAVE_INITFINI_ARRAY) && CONSTRUCTORS
	__libc_init_array();
#endif

#ifdef CRT0_SEMIHOST
#define CMDLINE_LEN     1024
#define ARGV_LEN        64
        static char cmdline[CMDLINE_LEN];
        static char *argv[ARGV_LEN];
        int argc = 0;

        if (sys_semihost_get_cmdline(cmdline, sizeof(cmdline)) == 0 &&
            cmdline[0])
        {
            char *c = cmdline;

            while (*c && argc < ARGV_LEN - 1) {
                argv[argc++] = c;
                while (*c && *c != ' ')
                    c++;
                if (!*c)
                    break;
                *c = '\0';
                while (*++c == ' ')
                    ;
            }
        } else
            argv[argc++] = "program-name";
        argv[argc] = NULL;
#else
#define argv NULL
#define argc 0
#endif

	int ret = main(argc, argv);
#ifdef CRT0_EXIT
	exit(ret);
#else
	(void) ret;
	for(;;);
#endif
}

void __attribute__((naked, section(".text.startup")))
__reset_handler(void)
{
	__asm__("clr __zero_reg__");
	__asm__("out %0, __zero_reg__" : : "i" AVR_STATUS_ADDR);
	__asm__("ldi r28, lo8(__stack)");
	__asm__("out %0, r28" : : "i" AVR_STACK_POINTER_LO_ADDR);
#ifdef _HAVE_AVR_STACK_POINTER_HI
	__asm__("ldi r29, hi8(__stack)");
	__asm__("out %0, r29" : : "i" AVR_STACK_POINTER_HI_ADDR);
#endif

#ifdef RAMPD
	__asm__("out %0, __zero_reg__" : : "i" (AVR_RAMPD_ADDR));
#endif
#ifdef RAMPX
	__asm__("out %0, __zero_reg__" : : "i" (AVR_RAMPX_ADDR));
#endif
#ifdef RAMPY
	__asm__("out %0, __zero_reg__" : : "i" (AVR_RAMPY_ADDR));
#endif
#ifdef RAMPZ
	__asm__("out %0, __zero_reg__" : : "i" (AVR_RAMPZ_ADDR));
#endif

#ifdef __AVR_HAVE_JMP_CALL__
	__asm__("jmp _start");
#else
	__asm__("rjmp _start");
#endif
}

static void
__default_handler(void)
{
	while (1)
		;
}

void __attribute__((naked, section(".text.init.enter")))
__vector_table(void)
{
	__asm__(VJMP " __reset_handler");
	__asm__(VJMP " __vector_1");
	__asm__(VJMP " __vector_2");
	__asm__(VJMP " __vector_3");
	__asm__(VJMP " __vector_4");
	__asm__(VJMP " __vector_5");
	__asm__(VJMP " __vector_6");
	__asm__(VJMP " __vector_7");
	__asm__(VJMP " __vector_8");
	__asm__(VJMP " __vector_9");
	__asm__(VJMP " __vector_10");
	__asm__(VJMP " __vector_11");
	__asm__(VJMP " __vector_12");
	__asm__(VJMP " __vector_13");
	__asm__(VJMP " __vector_14");
	__asm__(VJMP " __vector_15");
	__asm__(VJMP " __vector_16");
	__asm__(VJMP " __vector_17");
	__asm__(VJMP " __vector_18");
	__asm__(VJMP " __vector_19");
	__asm__(VJMP " __vector_20");
	__asm__(VJMP " __vector_21");
	__asm__(VJMP " __vector_22");
	__asm__(VJMP " __vector_23");
	__asm__(VJMP " __vector_24");
	__asm__(VJMP " __vector_25");
	__asm__(VJMP " __vector_26");
	__asm__(VJMP " __vector_27");
	__asm__(VJMP " __vector_28");
	__asm__(VJMP " __vector_29");
	__asm__(VJMP " __vector_30");
	__asm__(VJMP " __vector_31");
	__asm__(VJMP " __vector_32");
	__asm__(VJMP " __vector_33");
	__asm__(VJMP " __vector_34");
	__asm__(VJMP " __vector_35");
	__asm__(VJMP " __vector_36");
	__asm__(VJMP " __vector_37");
	__asm__(VJMP " __vector_38");
	__asm__(VJMP " __vector_39");
	__asm__(VJMP " __vector_40");
	__asm__(VJMP " __vector_41");
	__asm__(VJMP " __vector_42");
	__asm__(VJMP " __vector_43");
	__asm__(VJMP " __vector_44");
	__asm__(VJMP " __vector_45");
	__asm__(VJMP " __vector_46");
	__asm__(VJMP " __vector_47");
	__asm__(VJMP " __vector_48");
	__asm__(VJMP " __vector_49");
	__asm__(VJMP " __vector_50");
	__asm__(VJMP " __vector_51");
	__asm__(VJMP " __vector_52");
	__asm__(VJMP " __vector_53");
	__asm__(VJMP " __vector_54");
	__asm__(VJMP " __vector_55");
	__asm__(VJMP " __vector_56");
	__asm__(VJMP " __vector_57");
	__asm__(VJMP " __vector_58");
	__asm__(VJMP " __vector_59");
	__asm__(VJMP " __vector_60");
	__asm__(VJMP " __vector_61");
	__asm__(VJMP " __vector_62");
	__asm__(VJMP " __vector_63");
	__asm__(VJMP " __vector_64");
	__asm__(VJMP " __vector_65");
	__asm__(VJMP " __vector_66");
	__asm__(VJMP " __vector_67");
	__asm__(VJMP " __vector_68");
	__asm__(VJMP " __vector_69");
	__asm__(VJMP " __vector_70");
	__asm__(VJMP " __vector_71");
	__asm__(VJMP " __vector_72");
	__asm__(VJMP " __vector_73");
	__asm__(VJMP " __vector_74");
	__asm__(VJMP " __vector_75");
	__asm__(VJMP " __vector_76");
	__asm__(VJMP " __vector_77");
	__asm__(VJMP " __vector_78");
	__asm__(VJMP " __vector_79");
	__asm__(VJMP " __vector_80");
	__asm__(VJMP " __vector_81");
	__asm__(VJMP " __vector_82");
	__asm__(VJMP " __vector_83");
	__asm__(VJMP " __vector_84");
	__asm__(VJMP " __vector_85");
	__asm__(VJMP " __vector_86");
	__asm__(VJMP " __vector_87");
	__asm__(VJMP " __vector_88");
	__asm__(VJMP " __vector_89");
	__asm__(VJMP " __vector_90");
	__asm__(VJMP " __vector_91");
	__asm__(VJMP " __vector_92");
	__asm__(VJMP " __vector_93");
	__asm__(VJMP " __vector_94");
	__asm__(VJMP " __vector_95");
	__asm__(VJMP " __vector_96");
	__asm__(VJMP " __vector_97");
	__asm__(VJMP " __vector_98");
	__asm__(VJMP " __vector_99");
	__asm__(VJMP " __vector_100");
	__asm__(VJMP " __vector_101");
	__asm__(VJMP " __vector_102");
	__asm__(VJMP " __vector_103");
	__asm__(VJMP " __vector_104");
	__asm__(VJMP " __vector_105");
	__asm__(VJMP " __vector_106");
	__asm__(VJMP " __vector_107");
	__asm__(VJMP " __vector_108");
	__asm__(VJMP " __vector_109");
	__asm__(VJMP " __vector_110");
	__asm__(VJMP " __vector_111");
	__asm__(VJMP " __vector_112");
	__asm__(VJMP " __vector_113");
	__asm__(VJMP " __vector_114");
	__asm__(VJMP " __vector_115");
	__asm__(VJMP " __vector_116");
	__asm__(VJMP " __vector_117");
	__asm__(VJMP " __vector_118");
	__asm__(VJMP " __vector_119");
	__asm__(VJMP " __vector_120");
	__asm__(VJMP " __vector_121");
	__asm__(VJMP " __vector_122");
	__asm__(VJMP " __vector_123");
	__asm__(VJMP " __vector_124");
	__asm__(VJMP " __vector_125");
	__asm__(VJMP " __vector_126");
	__asm__(VJMP " __vector_127");
}

void __attribute__((weak, alias("__default_handler"))) __vector_1(void);
void __attribute__((weak, alias("__default_handler"))) __vector_2(void);
void __attribute__((weak, alias("__default_handler"))) __vector_3(void);
void __attribute__((weak, alias("__default_handler"))) __vector_4(void);
void __attribute__((weak, alias("__default_handler"))) __vector_5(void);
void __attribute__((weak, alias("__default_handler"))) __vector_6(void);
void __attribute__((weak, alias("__default_handler"))) __vector_7(void);
void __attribute__((weak, alias("__default_handler"))) __vector_8(void);
void __attribute__((weak, alias("__default_handler"))) __vector_9(void);
void __attribute__((weak, alias("__default_handler"))) __vector_10(void);
void __attribute__((weak, alias("__default_handler"))) __vector_11(void);
void __attribute__((weak, alias("__default_handler"))) __vector_12(void);
void __attribute__((weak, alias("__default_handler"))) __vector_13(void);
void __attribute__((weak, alias("__default_handler"))) __vector_14(void);
void __attribute__((weak, alias("__default_handler"))) __vector_15(void);
void __attribute__((weak, alias("__default_handler"))) __vector_16(void);
void __attribute__((weak, alias("__default_handler"))) __vector_17(void);
void __attribute__((weak, alias("__default_handler"))) __vector_18(void);
void __attribute__((weak, alias("__default_handler"))) __vector_19(void);
void __attribute__((weak, alias("__default_handler"))) __vector_20(void);
void __attribute__((weak, alias("__default_handler"))) __vector_21(void);
void __attribute__((weak, alias("__default_handler"))) __vector_22(void);
void __attribute__((weak, alias("__default_handler"))) __vector_23(void);
void __attribute__((weak, alias("__default_handler"))) __vector_24(void);
void __attribute__((weak, alias("__default_handler"))) __vector_25(void);
void __attribute__((weak, alias("__default_handler"))) __vector_26(void);
void __attribute__((weak, alias("__default_handler"))) __vector_27(void);
void __attribute__((weak, alias("__default_handler"))) __vector_28(void);
void __attribute__((weak, alias("__default_handler"))) __vector_29(void);
void __attribute__((weak, alias("__default_handler"))) __vector_30(void);
void __attribute__((weak, alias("__default_handler"))) __vector_31(void);
void __attribute__((weak, alias("__default_handler"))) __vector_32(void);
void __attribute__((weak, alias("__default_handler"))) __vector_33(void);
void __attribute__((weak, alias("__default_handler"))) __vector_34(void);
void __attribute__((weak, alias("__default_handler"))) __vector_35(void);
void __attribute__((weak, alias("__default_handler"))) __vector_36(void);
void __attribute__((weak, alias("__default_handler"))) __vector_37(void);
void __attribute__((weak, alias("__default_handler"))) __vector_38(void);
void __attribute__((weak, alias("__default_handler"))) __vector_39(void);
void __attribute__((weak, alias("__default_handler"))) __vector_40(void);
void __attribute__((weak, alias("__default_handler"))) __vector_41(void);
void __attribute__((weak, alias("__default_handler"))) __vector_42(void);
void __attribute__((weak, alias("__default_handler"))) __vector_43(void);
void __attribute__((weak, alias("__default_handler"))) __vector_44(void);
void __attribute__((weak, alias("__default_handler"))) __vector_45(void);
void __attribute__((weak, alias("__default_handler"))) __vector_46(void);
void __attribute__((weak, alias("__default_handler"))) __vector_47(void);
void __attribute__((weak, alias("__default_handler"))) __vector_48(void);
void __attribute__((weak, alias("__default_handler"))) __vector_49(void);
void __attribute__((weak, alias("__default_handler"))) __vector_50(void);
void __attribute__((weak, alias("__default_handler"))) __vector_51(void);
void __attribute__((weak, alias("__default_handler"))) __vector_52(void);
void __attribute__((weak, alias("__default_handler"))) __vector_53(void);
void __attribute__((weak, alias("__default_handler"))) __vector_54(void);
void __attribute__((weak, alias("__default_handler"))) __vector_55(void);
void __attribute__((weak, alias("__default_handler"))) __vector_56(void);
void __attribute__((weak, alias("__default_handler"))) __vector_57(void);
void __attribute__((weak, alias("__default_handler"))) __vector_58(void);
void __attribute__((weak, alias("__default_handler"))) __vector_59(void);
void __attribute__((weak, alias("__default_handler"))) __vector_60(void);
void __attribute__((weak, alias("__default_handler"))) __vector_61(void);
void __attribute__((weak, alias("__default_handler"))) __vector_62(void);
void __attribute__((weak, alias("__default_handler"))) __vector_63(void);
void __attribute__((weak, alias("__default_handler"))) __vector_64(void);
void __attribute__((weak, alias("__default_handler"))) __vector_65(void);
void __attribute__((weak, alias("__default_handler"))) __vector_66(void);
void __attribute__((weak, alias("__default_handler"))) __vector_67(void);
void __attribute__((weak, alias("__default_handler"))) __vector_68(void);
void __attribute__((weak, alias("__default_handler"))) __vector_69(void);
void __attribute__((weak, alias("__default_handler"))) __vector_70(void);
void __attribute__((weak, alias("__default_handler"))) __vector_71(void);
void __attribute__((weak, alias("__default_handler"))) __vector_72(void);
void __attribute__((weak, alias("__default_handler"))) __vector_73(void);
void __attribute__((weak, alias("__default_handler"))) __vector_74(void);
void __attribute__((weak, alias("__default_handler"))) __vector_75(void);
void __attribute__((weak, alias("__default_handler"))) __vector_76(void);
void __attribute__((weak, alias("__default_handler"))) __vector_77(void);
void __attribute__((weak, alias("__default_handler"))) __vector_78(void);
void __attribute__((weak, alias("__default_handler"))) __vector_79(void);
void __attribute__((weak, alias("__default_handler"))) __vector_80(void);
void __attribute__((weak, alias("__default_handler"))) __vector_81(void);
void __attribute__((weak, alias("__default_handler"))) __vector_82(void);
void __attribute__((weak, alias("__default_handler"))) __vector_83(void);
void __attribute__((weak, alias("__default_handler"))) __vector_84(void);
void __attribute__((weak, alias("__default_handler"))) __vector_85(void);
void __attribute__((weak, alias("__default_handler"))) __vector_86(void);
void __attribute__((weak, alias("__default_handler"))) __vector_87(void);
void __attribute__((weak, alias("__default_handler"))) __vector_88(void);
void __attribute__((weak, alias("__default_handler"))) __vector_89(void);
void __attribute__((weak, alias("__default_handler"))) __vector_90(void);
void __attribute__((weak, alias("__default_handler"))) __vector_91(void);
void __attribute__((weak, alias("__default_handler"))) __vector_92(void);
void __attribute__((weak, alias("__default_handler"))) __vector_93(void);
void __attribute__((weak, alias("__default_handler"))) __vector_94(void);
void __attribute__((weak, alias("__default_handler"))) __vector_95(void);
void __attribute__((weak, alias("__default_handler"))) __vector_96(void);
void __attribute__((weak, alias("__default_handler"))) __vector_97(void);
void __attribute__((weak, alias("__default_handler"))) __vector_98(void);
void __attribute__((weak, alias("__default_handler"))) __vector_99(void);
void __attribute__((weak, alias("__default_handler"))) __vector_100(void);
void __attribute__((weak, alias("__default_handler"))) __vector_101(void);
void __attribute__((weak, alias("__default_handler"))) __vector_102(void);
void __attribute__((weak, alias("__default_handler"))) __vector_103(void);
void __attribute__((weak, alias("__default_handler"))) __vector_104(void);
void __attribute__((weak, alias("__default_handler"))) __vector_105(void);
void __attribute__((weak, alias("__default_handler"))) __vector_106(void);
void __attribute__((weak, alias("__default_handler"))) __vector_107(void);
void __attribute__((weak, alias("__default_handler"))) __vector_108(void);
void __attribute__((weak, alias("__default_handler"))) __vector_109(void);
void __attribute__((weak, alias("__default_handler"))) __vector_110(void);
void __attribute__((weak, alias("__default_handler"))) __vector_111(void);
void __attribute__((weak, alias("__default_handler"))) __vector_112(void);
void __attribute__((weak, alias("__default_handler"))) __vector_113(void);
void __attribute__((weak, alias("__default_handler"))) __vector_114(void);
void __attribute__((weak, alias("__default_handler"))) __vector_115(void);
void __attribute__((weak, alias("__default_handler"))) __vector_116(void);
void __attribute__((weak, alias("__default_handler"))) __vector_117(void);
void __attribute__((weak, alias("__default_handler"))) __vector_118(void);
void __attribute__((weak, alias("__default_handler"))) __vector_119(void);
void __attribute__((weak, alias("__default_handler"))) __vector_120(void);
void __attribute__((weak, alias("__default_handler"))) __vector_121(void);
void __attribute__((weak, alias("__default_handler"))) __vector_122(void);
void __attribute__((weak, alias("__default_handler"))) __vector_123(void);
void __attribute__((weak, alias("__default_handler"))) __vector_124(void);
void __attribute__((weak, alias("__default_handler"))) __vector_125(void);
void __attribute__((weak, alias("__default_handler"))) __vector_126(void);
void __attribute__((weak, alias("__default_handler"))) __vector_127(void);
