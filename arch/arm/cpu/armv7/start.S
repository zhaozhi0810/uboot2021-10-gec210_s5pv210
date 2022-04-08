/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * armboot - Startup Code for OMAP3530/ARM Cortex CPU-core
 *
 * Copyright (c) 2004	Texas Instruments <r-woodruff2@ti.com>
 *
 * Copyright (c) 2001	Marius Gröger <mag@sysgo.de>
 * Copyright (c) 2002	Alex Züpke <azu@sysgo.de>
 * Copyright (c) 2002	Gary Jennejohn <garyj@denx.de>
 * Copyright (c) 2003	Richard Woodruff <r-woodruff2@ti.com>
 * Copyright (c) 2003	Kshitij <kshitij@ti.com>
 * Copyright (c) 2006-2008 Syed Mohammed Khasim <x0khasim@ti.com>
 */

#include <asm-offsets.h>
#include <config.h>
#include <asm/system.h>
#include <linux/linkage.h>
#include <asm/armv7.h>

/*************************************************************************
 *
 * Startup Code (reset vector)
 *
 * Do important init only if we don't start from memory!
 * Setup memory and board specific bits prior to relocation.
 * Relocate armboot to ram. Setup stack.
 *
 *************************************************************************/

	.globl	reset
	.globl	save_boot_params_ret
	.type   save_boot_params_ret,%function
#ifdef CONFIG_ARMV7_LPAE
	.global	switch_to_hypervisor_ret
#endif

reset:
	/* Allow the board to save important registers */
	b	save_boot_params
save_boot_params_ret:
#ifdef CONFIG_ARMV7_LPAE
/*
 * check for Hypervisor support
 */
	mrc	p15, 0, r0, c0, c1, 1		@ read ID_PFR1
	and	r0, r0, #CPUID_ARM_VIRT_MASK	@ mask virtualization bits
	cmp	r0, #(1 << CPUID_ARM_VIRT_SHIFT)
	beq	switch_to_hypervisor
switch_to_hypervisor_ret:
#endif
	/*
	 * disable interrupts (FIQ and IRQ), also set the cpu to SVC32 mode,
	 * except if in HYP mode already
	 */
	mrs	r0, cpsr
	and	r1, r0, #0x1f		@ mask mode bits
	teq	r1, #0x1a		@ test for HYP mode
	bicne	r0, r0, #0x1f		@ clear all mode bits
	orrne	r0, r0, #0x13		@ set SVC mode
	orr	r0, r0, #0xc0		@ disable FIQ and IRQ
	msr	cpsr,r0

/*
 * Setup vector:
 * (OMAP4 spl TEXT_BASE is not 32 byte aligned.
 * Continue to use ROM code vector only in OMAP4 spl)
 */
#if !(defined(CONFIG_OMAP44XX) && defined(CONFIG_SPL_BUILD))
	/* Set V=0 in CP15 SCTLR register - for VBAR to point to vector */
	mrc	p15, 0, r0, c1, c0, 0	@ Read CP15 SCTLR Register
	bic	r0, #CR_V		@ V = 0
	mcr	p15, 0, r0, c1, c0, 0	@ Write CP15 SCTLR Register

#ifdef CONFIG_HAS_VBAR
	/* Set vector address in CP15 VBAR register */
	ldr	r0, =_start
	mcr	p15, 0, r0, c12, c0, 0	@Set VBAR
#endif
#endif
    



	/* the mask ROM code should have PLL and others stable */
#ifndef CONFIG_SKIP_LOWLEVEL_INIT
#ifdef CONFIG_CPU_V7A
	bl	cpu_init_cp15
#endif

	ldr sp,=0xd0036000
	bl gpio_out

    

#ifndef CONFIG_SKIP_LOWLEVEL_INIT_ONLY
	bl	cpu_init_crit
#endif
#endif

    mov r0,#0
    bl led_on

	

    /*
            因为要调用c语言，最好还是设置好堆栈
            堆栈设置在uboot代码段的起始位置，因为堆栈向下增长，所以不会影响uboot代码段
         */
    ldr sp, =CONFIG_SYS_TEXT_BASE   /* setup temp stack pointer */
    sub sp, sp, #0x2000
    mov fp, #0          /* no previous frame, so fp=0 */

	/*******************2020**************************************/
	/* Read booting information  获得启动信息，看是如何启动的 */
	ldr	r0, =PRO_ID_BASE
	ldr	r1, [r0,#OMR_OFFSET]
	bic	r2, r1, #0xffffffc1

	/* NAND BOOT */
	cmp	r2, #0x0		@ 512B 4-cycle
	moveq	r3, #BOOT_NAND

	cmp	r2, #0x2		@ 2KB 5-cycle
	moveq	r3, #BOOT_NAND

	cmp	r2, #0x4		@ 4KB 5-cycle	8-bit ECC
	moveq	r3, #BOOT_NAND

	cmp	r2, #0x6		@ 4KB 5-cycle	16-bit ECC
	moveq	r3, #BOOT_NAND

	/* SD/MMC BOOT */
	cmp     r2, #0xc
	moveq   r3, #BOOT_MMCSD	

	/* Uart BOOTONG failed */
	cmp     r2, #(0x1<<4)
	moveq   r3, #BOOT_SEC_DEV
	
	ldr	r0, =INF_REG_BASE
	str	r3, [r0, #INF_REG3_OFFSET]    /*把启动信息保存起来*/ 


	/* when we already run in ram, we don't need to relocate U-Boot.
	 * and actually, memory controller must be configured before U-Boot
	 * is running in ram.
	 */
	ldr	r0, =0xff000fff
	bic	r1, pc, r0		/* r0 <- current base addr of code */
	ldr	r2, =CONFIG_SYS_TEXT_BASE		/* r1 <- original base addr in ram */
	bic	r2, r2, r0		/* r0 <- current base addr of code */
	cmp     r1, r2                  /* compare r0, r1                  */
	beq     after_copy		/* r0 == r1 then skip flash copy   */



	/* @ldr	r0, =INF_REG_BASE
	 @ldr	r1, [r0, #INF_REG3_OFFSET]
	*/
	mov  r1,r3   @r3中保存着启动信息，直接判断吧
	cmp	r1, #BOOT_NAND		/* 0x0 => boot device is nand */
	beq	nand_boot

	cmp     r1, #BOOT_MMCSD
	beq     mmcsd_boot

	cmp     r1, #BOOT_SEC_DEV
	beq     mmcsd_boot

nand_boot:
	
	mov	r0, #0x1000
	bl	copy_from_nand
	
    ldr	pc, _start_armboot
    
mmcsd_boot:
	bl      mmc_relocate
    /* Print 'h' */
	ldr	r0, =0xe2900020
	ldr	r1, =0x4a                       //h
	strb r1, [r0]
	ldr	pc, _start_armboot

_start_armboot:
	.word after_copy




after_copy:     @//设置标志

/*******************2020**************************************/
#if 0
	/* ABB disable */
	ldr	r0, =0xE010C300
	orr	r1, r1, #(0x1<<23)
	str	r1, [r0]
#endif
	/* Print 'K' */
	ldr	r0, =0xe2900020
	ldr	r1, =0x4b
	strb r1, [r0]

	mov r0,#3
	bl led_on
	

	bl	_main

/*------------------------------------------------------------------------------*/

ENTRY(c_runtime_cpu_setup)
/*
 * If I-cache is enabled invalidate it
 */
#if !CONFIG_IS_ENABLED(SYS_ICACHE_OFF)
	mcr	p15, 0, r0, c7, c5, 0	@ invalidate icache
	mcr     p15, 0, r0, c7, c10, 4	@ DSB
	mcr     p15, 0, r0, c7, c5, 4	@ ISB
#endif

	bx	lr

ENDPROC(c_runtime_cpu_setup)

/*************************************************************************
 *
 * void save_boot_params(u32 r0, u32 r1, u32 r2, u32 r3)
 *	__attribute__((weak));
 *
 * Stack pointer is not yet initialized at this moment
 * Don't save anything to stack even if compiled with -O0
 *
 *************************************************************************/
ENTRY(save_boot_params)
	b	save_boot_params_ret		@ back to my caller
ENDPROC(save_boot_params)
	.weak	save_boot_params

#ifdef CONFIG_ARMV7_LPAE
ENTRY(switch_to_hypervisor)
	b	switch_to_hypervisor_ret
ENDPROC(switch_to_hypervisor)
	.weak	switch_to_hypervisor
#endif

/*************************************************************************
 *
 * cpu_init_cp15
 *
 * Setup CP15 registers (cache, MMU, TLBs). The I-cache is turned on unless
 * CONFIG_SYS_ICACHE_OFF is defined.
 *
 *************************************************************************/
ENTRY(cpu_init_cp15)
	/*
	 * Invalidate L1 I/D
	 */
	mov	r0, #0			@ set up for MCR
	mcr	p15, 0, r0, c8, c7, 0	@ invalidate TLBs
	mcr	p15, 0, r0, c7, c5, 0	@ invalidate icache
	mcr	p15, 0, r0, c7, c5, 6	@ invalidate BP array
	mcr     p15, 0, r0, c7, c10, 4	@ DSB
	mcr     p15, 0, r0, c7, c5, 4	@ ISB

	/*
	 * disable MMU stuff and caches
	 */
	mrc	p15, 0, r0, c1, c0, 0
	bic	r0, r0, #0x00002000	@ clear bits 13 (--V-)
	bic	r0, r0, #0x00000007	@ clear bits 2:0 (-CAM)
	orr	r0, r0, #0x00000002	@ set bit 1 (--A-) Align
	orr	r0, r0, #0x00000800	@ set bit 11 (Z---) BTB
#if CONFIG_IS_ENABLED(SYS_ICACHE_OFF)
	bic	r0, r0, #0x00001000	@ clear bit 12 (I) I-cache
#else
	orr	r0, r0, #0x00001000	@ set bit 12 (I) I-cache
#endif
	mcr	p15, 0, r0, c1, c0, 0

#ifdef CONFIG_ARM_ERRATA_716044
	mrc	p15, 0, r0, c1, c0, 0	@ read system control register
	orr	r0, r0, #1 << 11	@ set bit #11
	mcr	p15, 0, r0, c1, c0, 0	@ write system control register
#endif

#if (defined(CONFIG_ARM_ERRATA_742230) || defined(CONFIG_ARM_ERRATA_794072))
	mrc	p15, 0, r0, c15, c0, 1	@ read diagnostic register
	orr	r0, r0, #1 << 4		@ set bit #4
	mcr	p15, 0, r0, c15, c0, 1	@ write diagnostic register
#endif

#ifdef CONFIG_ARM_ERRATA_743622
	mrc	p15, 0, r0, c15, c0, 1	@ read diagnostic register
	orr	r0, r0, #1 << 6		@ set bit #6
	mcr	p15, 0, r0, c15, c0, 1	@ write diagnostic register
#endif

#ifdef CONFIG_ARM_ERRATA_751472
	mrc	p15, 0, r0, c15, c0, 1	@ read diagnostic register
	orr	r0, r0, #1 << 11	@ set bit #11
	mcr	p15, 0, r0, c15, c0, 1	@ write diagnostic register
#endif
#ifdef CONFIG_ARM_ERRATA_761320
	mrc	p15, 0, r0, c15, c0, 1	@ read diagnostic register
	orr	r0, r0, #1 << 21	@ set bit #21
	mcr	p15, 0, r0, c15, c0, 1	@ write diagnostic register
#endif

#ifdef CONFIG_ARM_ERRATA_845369
	mrc     p15, 0, r0, c15, c0, 1	@ read diagnostic register
	orr     r0, r0, #1 << 22	@ set bit #22
	mcr     p15, 0, r0, c15, c0, 1	@ write diagnostic register
#endif

	mov	r5, lr			@ Store my Caller
	mrc	p15, 0, r1, c0, c0, 0	@ r1 has Read Main ID Register (MIDR)
	mov	r3, r1, lsr #20		@ get variant field
	and	r3, r3, #0xf		@ r3 has CPU variant
	and	r4, r1, #0xf		@ r4 has CPU revision
	mov	r2, r3, lsl #4		@ shift variant field for combined value
	orr	r2, r4, r2		@ r2 has combined CPU variant + revision

/* Early stack for ERRATA that needs into call C code */
#if defined(CONFIG_SPL_BUILD) && defined(CONFIG_SPL_STACK)
	ldr	r0, =(CONFIG_SPL_STACK)
#else
	ldr	r0, =(CONFIG_SYS_INIT_SP_ADDR)
#endif
	bic	r0, r0, #7	/* 8-byte alignment for ABI compliance */
	mov	sp, r0

#ifdef CONFIG_ARM_ERRATA_798870
	cmp	r2, #0x30		@ Applies to lower than R3p0
	bge	skip_errata_798870      @ skip if not affected rev
	cmp	r2, #0x20		@ Applies to including and above R2p0
	blt	skip_errata_798870      @ skip if not affected rev

	mrc	p15, 1, r0, c15, c0, 0  @ read l2 aux ctrl reg
	orr	r0, r0, #1 << 7         @ Enable hazard-detect timeout
	push	{r1-r5}			@ Save the cpu info registers
	bl	v7_arch_cp15_set_l2aux_ctrl
	isb				@ Recommended ISB after l2actlr update
	pop	{r1-r5}			@ Restore the cpu info - fall through
skip_errata_798870:
#endif

#ifdef CONFIG_ARM_ERRATA_801819
	cmp	r2, #0x24		@ Applies to lt including R2p4
	bgt	skip_errata_801819      @ skip if not affected rev
	cmp	r2, #0x20		@ Applies to including and above R2p0
	blt	skip_errata_801819      @ skip if not affected rev
	mrc	p15, 0, r0, c0, c0, 6	@ pick up REVIDR reg
	and	r0, r0, #1 << 3		@ check REVIDR[3]
	cmp	r0, #1 << 3
	beq	skip_errata_801819	@ skip erratum if REVIDR[3] is set

	mrc	p15, 0, r0, c1, c0, 1	@ read auxilary control register
	orr	r0, r0, #3 << 27	@ Disables streaming. All write-allocate
					@ lines allocate in the L1 or L2 cache.
	orr	r0, r0, #3 << 25	@ Disables streaming. All write-allocate
					@ lines allocate in the L1 cache.
	push	{r1-r5}			@ Save the cpu info registers
	bl	v7_arch_cp15_set_acr
	pop	{r1-r5}			@ Restore the cpu info - fall through
skip_errata_801819:
#endif

#ifdef CONFIG_ARM_CORTEX_A15_CVE_2017_5715
	mrc	p15, 0, r0, c1, c0, 1	@ read auxilary control register
	orr	r0, r0, #1 << 0		@ Enable invalidates of BTB
	push	{r1-r5}			@ Save the cpu info registers
	bl	v7_arch_cp15_set_acr
	pop	{r1-r5}			@ Restore the cpu info - fall through
#endif

#ifdef CONFIG_ARM_ERRATA_454179
	mrc	p15, 0, r0, c1, c0, 1	@ Read ACR

	cmp	r2, #0x21		@ Only on < r2p1
	orrlt	r0, r0, #(0x3 << 6)	@ Set DBSM(BIT7) and IBE(BIT6) bits

	push	{r1-r5}			@ Save the cpu info registers
	bl	v7_arch_cp15_set_acr
	pop	{r1-r5}			@ Restore the cpu info - fall through
#endif

#if defined(CONFIG_ARM_ERRATA_430973) || defined (CONFIG_ARM_CORTEX_A8_CVE_2017_5715)
	mrc	p15, 0, r0, c1, c0, 1	@ Read ACR

#ifdef CONFIG_ARM_CORTEX_A8_CVE_2017_5715
	orr	r0, r0, #(0x1 << 6)	@ Set IBE bit always to enable OS WA
#else
	cmp	r2, #0x21		@ Only on < r2p1
	orrlt	r0, r0, #(0x1 << 6)	@ Set IBE bit
#endif
	push	{r1-r5}			@ Save the cpu info registers
	bl	v7_arch_cp15_set_acr
	pop	{r1-r5}			@ Restore the cpu info - fall through
#endif

#ifdef CONFIG_ARM_ERRATA_621766
	mrc	p15, 0, r0, c1, c0, 1	@ Read ACR

	cmp	r2, #0x21		@ Only on < r2p1
	orrlt	r0, r0, #(0x1 << 5)	@ Set L1NEON bit

	push	{r1-r5}			@ Save the cpu info registers
	bl	v7_arch_cp15_set_acr
	pop	{r1-r5}			@ Restore the cpu info - fall through
#endif

#ifdef CONFIG_ARM_ERRATA_725233
	mrc	p15, 1, r0, c9, c0, 2	@ Read L2ACR

	cmp	r2, #0x21		@ Only on < r2p1 (Cortex A8)
	orrlt	r0, r0, #(0x1 << 27)	@ L2 PLD data forwarding disable

	push	{r1-r5}			@ Save the cpu info registers
	bl	v7_arch_cp15_set_l2aux_ctrl
	pop	{r1-r5}			@ Restore the cpu info - fall through
#endif

#ifdef CONFIG_ARM_ERRATA_852421
	mrc	p15, 0, r0, c15, c0, 1	@ read diagnostic register
	orr	r0, r0, #1 << 24	@ set bit #24
	mcr	p15, 0, r0, c15, c0, 1	@ write diagnostic register
#endif

#ifdef CONFIG_ARM_ERRATA_852423
	mrc	p15, 0, r0, c15, c0, 1	@ read diagnostic register
	orr	r0, r0, #1 << 12	@ set bit #12
	mcr	p15, 0, r0, c15, c0, 1	@ write diagnostic register
#endif

	mov	pc, r5			@ back to my caller
ENDPROC(cpu_init_cp15)

#if !defined(CONFIG_SKIP_LOWLEVEL_INIT) && \
	!defined(CONFIG_SKIP_LOWLEVEL_INIT_ONLY)
/*************************************************************************
 *
 * CPU_init_critical registers
 *
 * setup important registers
 * setup memory timing
 *
 *************************************************************************/
ENTRY(cpu_init_crit)
	/*
	 * Jump to board specific initialization...
	 * The Mask ROM will have already initialized
	 * basic memory. Go here to bump up clock rate and handle
	 * wake up conditions.
	 */
	b	lowlevel_init		@ go setup pll,mux,memory
ENDPROC(cpu_init_crit)
#endif



/*
 * copy U-Boot to SDRAM and jump to ram (from NAND or OneNAND)
 * r0: size to be compared
 * Load 1'st 2blocks to RAM because U-boot's size is larger than 1block(128k) size
 */
	.globl copy_from_nand
copy_from_nand:
	push	{lr}		/* save return address */

	mov	r9, r0
    
	mov	r9, #0x100		/* Compare about 8KB */
    bl	copy_uboot_to_ram   
	tst 	r0, #0x0
	bne	copy_failed

	ldr	r0, =0xd0020010     //2021-12-19
	ldr	r1, =CONFIG_SYS_TEXT_BASE	/* 0x34800000 */

#if !defined(CONFIG_SECURE_BOOT)
1:	ldr	r3, [r0], #4
	ldr	r4, [r1], #4
	teq	r3, r4
	bne	compare_failed	/* not matched */
	subs	r9, r9, #4
	bne	1b
#endif	
	pop	{pc}		/* all is OK */

copy_failed:
	bl uart_print_hex
	mov r0,#0x55
	bl uart_print_hex
	nop			/* copy from nand failed */    
	b	copy_failed

compare_failed:  
	mov r0,#0x77
	bl uart_print_hex
	mov r0,r9
	bl uart_print_hex 
	nop			/* compare failed */
	b	compare_failed







gpio_out:
        ldr r1, =0xe0200280
        ldr r2, =0x00001111
        str r2, [r1]
 
        ldr r1, =0xe0200284
        ldr r2, =0xf
        str r2, [r1]
        mov pc, lr
 
.globl led_on
led_on:
		push {r2,r11,r12}
        ldr r11, =0xe0200284
        ldr r12, [r11]
        mov r2,#1
        lsl r2,r2,r0
        bic r12, r12,r2
        str r12, [r11]
        pop {r2,r11,r12}
        mov pc, lr
 
.globl led_off
led_off:
		push {r2,r11,r12}
        ldr r11, =0xe0200284
        ldr r12, [r11]
        mov r2,#1
        lsl r2,r2,r0
        orr r12, r12,r2
        str r12, [r11]
        pop {r2,r11,r12}
        mov pc, lr



