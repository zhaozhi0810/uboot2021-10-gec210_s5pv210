/*
 * Memory Setup stuff - taken from blob memsetup.S
 *
 * Copyright (C) 2009 Samsung Electronics
 * Kyungmin Park <kyungmin.park@samsung.com>
 *
 * SPDX-License-Identifier:	GPL-2.0+
 */

#include <config.h>
#include <asm/arch/cpu.h>
#include <asm/arch/clock.h>
#include <asm/arch/power.h>

/*
 * Register usages:
 *
 * r5 has zero always
 * r7 has S5PC100 GPIO base, 0xE0300000
 * r8 has real GPIO base, 0xE0300000, 0xE0200000 at S5PC100, S5PC110 repectively
 * r9 has Mobile DDR size, 1 means 1GiB, 2 means 2GiB and so on
 */

	.globl lowlevel_init
lowlevel_init:
	mov	r11, lr

	/* r5 has always zero */
	mov	r5, #0

	ldr	r8, =S5PC110_GPIO_BASE      @0xE0200000
100:


	ldr	r0, =S5PC110_RST_STAT
	ldr	r1, [r0]
	and	r1, r1, #0x000D0000
	cmp	r1, #(0x1 << 19)			@ DEEPIDLE_WAKEUP
	beq	didle_wakeup
	

skip_check_didle:
#if 0
    addeq	r0, r8, #0x280				@ S5PC100_GPIO_J4
	addne	r0, r8, #0x2C0				@ S5PC110_GPIO_J4
	ldr	r1, [r0, #0x0]				@ GPIO_CON_OFFSET
	bic	r1, r1, #(0xf << 4)			@ 1 * 4-bit
	orr	r1, r1, #(0x1 << 4)
	str	r1, [r0, #0x0]				@ GPIO_CON_OFFSET

	ldr	r1, [r0, #0x4]				@ GPIO_DAT_OFFSET
	bic	r1, r1, #(1 << 1)
	str	r1, [r0, #0x4]				@ GPIO_DAT_OFFSET
#endif

#if 1
	/*
	 * Initialize Async Register Setting for EVT1
	 * Because we are setting EVT1 as the default value of EVT0,
	 * setting EVT0 as well does not make things worse.
	 * Thus, for the simplicity, we set for EVT0, too
	 *
	 * The "Async Registers" are:
	 *	0xE0F0_0000
	 *	0xE1F0_0000
	 *	0xF180_0000
	 *	0xF190_0000
	 *	0xF1A0_0000
	 *	0xF1B0_0000
	 *	0xF1C0_0000
	 *	0xF1D0_0000
	 *	0xF1E0_0000
	 *	0xF1F0_0000
	 *	0xFAF0_0000
	 */
	ldr     r0, =0xe0f00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xe1f00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1800000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1900000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1a00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1b00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1c00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1d00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1e00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1f00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xfaf00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]
#endif
	/*
	 * Diable ABB block to reduce sleep current at low temperature
	 * Note that it's hidden register setup don't modify it
	 */
	ldr	r0, =0xE010C300
	ldr	r1, =0x00800000
	str	r1, [r0]

100:
	/* IO retension release */
	ldr	r0, =S5PC110_OTHERS			@ 0xE010E000
	ldr	r1, [r0]
	ldr	r2, =((1 << 31) |(1 << 30) | (1 << 29) | (1 << 28))  
	orr	r1, r1, r2
	/* Do not release retention here for S5PC110 */
	str	r1, [r0]

	/* Disable Watchdog */
	ldr	r0, =S5PC110_WATCHDOG_BASE		@ 0xE2700000
	str	r5, [r0]
#if 1
	/* setting SRAM */
	ldr	r0, =S5PC110_SROMC_BASE
	ldr	r1, =0x9
	str	r1, [r0]
#endif
	/* S5PC100 has 3 groups of interrupt sources */
	ldr	r0, =S5PC110_VIC0_BASE			@ 0xF2000000
	add	r1, r0, #0x00100000
	add	r2, r0, #0x00200000
	add	r4, r0, #0x00300000			@2020-12-16

	/* Disable all interrupts (VIC0, VIC1 and VIC2) */
	mvn	r3, #0x0
	str	r3, [r0, #0x14]				@ INTENCLEAR
	str	r3, [r1, #0x14]				@ INTENCLEAR
	str	r3, [r2, #0x14]				@ INTENCLEAR
	str	r3, [r4, #0x14]				@ INTENCLEAR    @2020-12-16

	/* Set all interrupts as IRQ */
	str	r5, [r0, #0xc]				@ INTSELECT
	str	r5, [r1, #0xc]				@ INTSELECT
	str	r5, [r2, #0xc]				@ INTSELECT
	str	r5, [r4, #0xc]				@ INTSELECT      @2020-12-16

	/* Pending Interrupt Clear */
	str	r5, [r0, #0xf00]			@ INTADDRESS
	str	r5, [r1, #0xf00]			@ INTADDRESS
	str	r5, [r2, #0xf00]			@ INTADDRESS
	str	r5, [r4, #0xf00]			@ INTADDRESS    @2020-12-16

	bl 	system_clock_init     @2020-12-14

	/* for UART */
	bl	uart_asm_init

	bl	internal_ram_init

	bl 	mem_ctrl_asm_init     @2020-12-16

    bl  nand_asm_init     @2020-12-16



	/* Clear wakeup status register */
	ldr	r0, =S5PC110_WAKEUP_STAT
	ldr	r1, [r0]
	str	r1, [r0]

	/* IO retension release */
	ldr	r0, =S5PC110_OTHERS			@ 0xE010E000
	ldr	r1, [r0]
	ldr	r2, =((1 << 31) | (1 << 30) | (1 << 29) | (1 << 28))
	orr	r1, r1, r2
	str	r1, [r0]

	b	1f

didle_wakeup:
	/* Wait when APLL is locked */
	ldr	r0, =0xE0100100			@ S5PC110_APLL_CON
lockloop:
	ldr	r1, [r0]
	and	r1, r1, #(1 << 29)
	cmp	r1, #(1 << 29)
	bne	lockloop

	ldr	r0, =S5PC110_INFORM0
	ldr	r1, [r0]
	mov	pc, r1
	nop
	nop
	nop
	nop
	nop

1:
    

	mov	lr, r11
	mov	pc, lr

/*
 * system_clock_init: Initialize core clock and bus clock.
 * void system_clock_init(void)
 */


#define ELFIN_CLOCK_POWER_BASE		0xE0100000
    
    /* Clock & Power Controller for s5pc110*/
#define APLL_LOCK_OFFSET		0x00
#define MPLL_LOCK_OFFSET		0x08
#define EPLL_LOCK_OFFSET		0x10
#define VPLL_LOCK_OFFSET		0x20
#define APLL_CON0_OFFSET		0x100
#define APLL_CON1_OFFSET		0x104
#define MPLL_CON_OFFSET			0x108
#define EPLL_CON_OFFSET			0x110
#define VPLL_CON_OFFSET			0x120
    
#define CLK_SRC0_OFFSET			0x200
#define CLK_SRC1_OFFSET			0x204
#define CLK_SRC2_OFFSET			0x208
#define CLK_SRC3_OFFSET			0x20c
#define CLK_SRC4_OFFSET			0x210
#define CLK_SRC5_OFFSET			0x214
#define CLK_SRC6_OFFSET			0x218
#define CLK_SRC_MASK0_OFFSET		0x280
#define CLK_SRC_MASK1_OFFSET		0x284
    
#define CLK_DIV0_OFFSET			0x300
#define CLK_DIV1_OFFSET			0x304
#define CLK_DIV2_OFFSET			0x308
#define CLK_DIV3_OFFSET			0x30c
#define CLK_DIV4_OFFSET			0x310
#define CLK_DIV5_OFFSET			0x314
#define CLK_DIV6_OFFSET			0x318
#define CLK_DIV7_OFFSET			0x31c
    
#define CLK_GATE_IP0_OFFSET		0x460
#define CLK_GATE_IP1_OFFSET		0x464
#define CLK_GATE_IP2_OFFSET		0x468
#define CLK_GATE_IP3_OFFSET		0x46c
#define CLK_GATE_IP4_OFFSET		0x470
#define CLK_GATE_BLOCK_OFFSET		0x480
    
#define CLK_OUT_OFFSET			0x500
#define CLK_DIV_STAT0_OFFSET		0x1000
#define CLK_DIV_STAT1_OFFSET		0x1004
#define CLK_MUX_STAT0_OFFSET		0x1100
#define CLK_MUX_STAT1_OFFSET		0x1104
#define SW_RST_OFFSET			0x2000
    
    
    
    
#define CLK_DIV0_MASK	0x7fffffff
#define CLK_DIV1_MASK	0xffffffff
#define CLK_DIV2_MASK	0x0fff
#define CLK_DIV3_MASK	0x7fffffff
#define CLK_DIV4_MASK	0xffffffff
#define CLK_DIV6_MASK	0xffffffff
    
    
    
#define APLL_MDIV       0x7d
#define APLL_PDIV       0x3
#define APLL_SDIV       0x1
    
#define MPLL_MDIV	0x29b
#define MPLL_PDIV	0xc
#define MPLL_SDIV	0x1
    
    
#define EPLL_MDIV	0x60
#define EPLL_PDIV	0x6
#define EPLL_SDIV	0x2
    
#define VPLL_MDIV	0x6c
#define VPLL_PDIV	0x6
#define VPLL_SDIV	0x3
    
    
#define set_pll(mdiv, pdiv, sdiv)	(1<<31 | mdiv<<16 | pdiv<<8 | sdiv)
    
#define APLL_VAL	set_pll(APLL_MDIV,APLL_PDIV,APLL_SDIV)
#define MPLL_VAL	set_pll(MPLL_MDIV,MPLL_PDIV,MPLL_SDIV)
#define EPLL_VAL	set_pll(EPLL_MDIV,EPLL_PDIV,EPLL_SDIV)
#define VPLL_VAL	set_pll(VPLL_MDIV,VPLL_PDIV,VPLL_SDIV)
    
#define AFC_ON		0x00000000
#define AFC_OFF		0x10000010
    
    
    /* CLK_DIV0 */
#define APLL_RATIO	0
#define A2M_RATIO	4
#define HCLK_MSYS_RATIO	8
#define PCLK_MSYS_RATIO	12
#define HCLK_DSYS_RATIO	16
#define PCLK_DSYS_RATIO 20
#define HCLK_PSYS_RATIO	24
#define PCLK_PSYS_RATIO 28
    
    
#define CLK_DIV0_VAL    ((0<<APLL_RATIO)|(4<<A2M_RATIO)|(4<<HCLK_MSYS_RATIO)|(1<<PCLK_MSYS_RATIO)\
                |(3<<HCLK_DSYS_RATIO)|(1<<PCLK_DSYS_RATIO)|(4<<HCLK_PSYS_RATIO)|(1<<PCLK_PSYS_RATIO))
    
#define CLK_DIV1_VAL	((1<<16)|(1<<12)|(1<<8)|(1<<4))
#define CLK_DIV2_VAL	(1<<0)
#define CLK_DIV4_VAL	0x99990000
#define CLK_DIV6_VAL	0x71000
    
#define APLL_LOCKTIME_VAL	0xe10 
#define MPLL_LOCKTIME_VAL	0xe10 




    
system_clock_init:
	ldr	r0, =ELFIN_CLOCK_POWER_BASE	@0xe0100000

	/* Set Mux to FIN */
	ldr	r1, =0x0
	str	r1, [r0, #CLK_SRC0_OFFSET]

	ldr	r1,	=APLL_LOCKTIME_VAL
	str	r1,	[r0, #APLL_LOCK_OFFSET]

	ldr	r0, =ELFIN_CLOCK_POWER_BASE	@0xe0100000

	ldr	r1,	=MPLL_LOCKTIME_VAL
	str	r1,	[r0, #MPLL_LOCK_OFFSET]
	/********end*********************/

	/* Disable PLL */

retryloop:

	ldr	r1, =0x0
	str	r1, [r0, #APLL_CON0_OFFSET]
	ldr	r1, =0x0
	str	r1, [r0, #MPLL_CON_OFFSET]

	ldr	r1, =0x0
	str	r1, [r0, #MPLL_CON_OFFSET]

	ldr   	r1, [r0, #CLK_DIV0_OFFSET]
	ldr	r2, =CLK_DIV0_MASK
	bic	r1, r1, r2

	ldr	r2, =CLK_DIV0_VAL
	orr	r1, r1, r2
	str	r1, [r0, #CLK_DIV0_OFFSET]

	ldr	r1, =APLL_VAL
	str	r1, [r0, #APLL_CON0_OFFSET]

	ldr	r1, =MPLL_VAL
	str	r1, [r0, #MPLL_CON_OFFSET]

	ldr	r1, =VPLL_VAL
	str	r1, [r0, #VPLL_CON_OFFSET]

	ldr	r1, =EPLL_VAL
	str	r1, [r0, #EPLL_CON_OFFSET]

	ldr   	r1, [r0, #CLK_DIV1_OFFSET]
	ldr	r2, =CLK_DIV1_MASK
	bic	r1, r1, r2

	ldr	r2, =CLK_DIV1_VAL
	orr	r1, r1, r2
	str	r1, [r0, #CLK_DIV1_OFFSET]

	ldr   	r1, [r0, #CLK_DIV2_OFFSET]
	ldr	r2, =CLK_DIV2_MASK
	bic	r1, r1, r2

	ldr	r2, =CLK_DIV2_VAL
	orr	r1, r1, r2
	str	r1, [r0, #CLK_DIV2_OFFSET]

	ldr   	r1, [r0, #CLK_DIV4_OFFSET]
	ldr	r2, =CLK_DIV4_MASK
	bic	r1, r1, r2

	ldr	r2, =CLK_DIV4_VAL
	orr	r1, r1, r2
	str	r1, [r0, #CLK_DIV4_OFFSET]

	ldr   	r1, [r0, #CLK_DIV6_OFFSET]
	ldr	r2, =CLK_DIV6_MASK
	bic	r1, r1, r2

	ldr	r2, =CLK_DIV6_VAL
	orr	r1, r1, r2
	str	r1, [r0, #CLK_DIV6_OFFSET]
	/*******end*****************/
	/*******end*****************/

	ldr	r1, =AFC_ON
	str	r1, [r0, #APLL_CON1_OFFSET]

	mov	r1, #0x10000
1:	subs	r1, r1, #1
	bne	1b


	/* MPLL software workaround */
	ldr	r1, [r0, #MPLL_CON_OFFSET]
	orr     r1, r1, #(1<<28)
	str	r1, [r0, #MPLL_CON_OFFSET]

	mov	r1, #0x100
1:	subs	r1, r1, #1
	bne	1b

	ldr	r1, [r0, #MPLL_CON_OFFSET]
	and	r1, r1, #(1<<29)
	cmp	r1, #(1<<29)
	bne 	retryloop

	/* H/W lock detect disable */
	ldr	r1, [r0, #MPLL_CON_OFFSET]
	bic     r1, r1, #(1<<28)
	str	r1, [r0, #MPLL_CON_OFFSET]


	ldr	r1, [r0, #CLK_SRC0_OFFSET]
    ldr	r2, =0x00000111
	orr	r1, r1, r2
	str	r1, [r0, #CLK_SRC0_OFFSET]

	// added by terry 2012.12.4 for camera 
	ldr r1, [r0, #CLK_SRC1_OFFSET]
	bic r1, r1, #(0xf<<12)
	orr r1, r1, #(0x1<<12) //0001 XusbXTI
	str r1, [r0, #CLK_SRC1_OFFSET]


    /* CLK_DIV6 */
	/*ldr	r1, [r0, #CLK_DIV6_OFFSET]
	bic	r1, r1, #(0x7<<12)	@; ONENAND_RATIO: 0
	str	r1, [r0, #CLK_DIV6_OFFSET]*/ 

    mov pc,lr








    

internal_ram_init:
/*
 * Setting TZPC[TrustZone Protection Controller]
 */

#define ELFIN_TZPC0_BASE		0xF1500000
#define ELFIN_TZPC1_BASE		0xFAD00000
#define ELFIN_TZPC2_BASE		0xE0600000
#define ELFIN_TZPC3_BASE		0xE1C00000

/* Access Controller (TZPC) */
#define TZPC_DECPROT0SET_OFFSET		0x804
#define TZPC_DECPROT1SET_OFFSET		0x810
#define TZPC_DECPROT2SET_OFFSET		0x81C
#define TZPC_DECPROT3SET_OFFSET		0x828



tzpc_init:

	ldr	r0, =ELFIN_TZPC0_BASE
 	mov	r1, #0x0
 	str	r1, [r0]
 	mov	r1, #0xff
 	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
 	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET] 	

 	ldr 	r0, =ELFIN_TZPC1_BASE
 	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
 	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET] 	

 	ldr	r0, =ELFIN_TZPC2_BASE
 	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
 	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET] 

 	ldr	r0, =ELFIN_TZPC3_BASE
 	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
 	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET] 	

 	mov	pc, lr





/*
 * uart_asm_init: Initialize UART's pins
 */
uart_asm_init:
	/* set GPIO to enable UART0-UART4 */
	mov	r0, r8
	ldr	r1, =0x22222222
	str	r1, [r0, #0x0]			@ S5PC100_GPIO_A0_OFFSET
	ldr	r1, =0x00002222
	str	r1, [r0, #0x20]			@ S5PC100_GPIO_A1_OFFSET


200:
	/* set uart0 controler  2020-12-16  */
	ldr	r0, =0xE2900000		@0xE2900000  ELFIN_UART_CONSOLE_BASE
	mov	r1, #0x0
	str	r1, [r0, #8]   @UFCON_OFFSET
	str	r1, [r0, #0xc]  @UMCON_OFFSET

	mov	r1, #0x3
	str	r1, [r0, #0]  @ULCON_OFFSET

	ldr	r1, =0x3c5
	str	r1, [r0, #4]  @UCON_OFFSET

	ldr	r1, =0x75
	str	r1, [r0, #8]  @UFON_OFFSET   开启FIFO

	ldr	r1, =34         @  1000MHz
	str	r1, [r0, #0x28]   @UBRDIV_OFFSET

	ldr	r1, =0xdddd      
	str	r1, [r0, #0x2c]  @UDIVSLOT_OFFSET

	ldr	r1, =0x4f
	strb	r1, [r0, #0x20]		@'O'   UTXH_OFFSET

	mov	pc, lr


.globl uart_print_hex
uart_print_hex:
        stmfd sp!,{r0,r1,r2,r3,lr}
@        ldr     r0, [r0]      @r0 指向的内容，打印为16进制的值
        ldr     r1, =0xe2900020    @uart0
        ldr     r2, = 0x30
        str     r2, [r1]                @UTH0='0' 
        ldr     r2, = 0x78
        str     r2, [r1]                @UTH0='x' 
        ldr     r3, = 28
print_hex_loop:
        lsr     r2, r0, r3       @左移 r3指定移动的位数
        and     r2, r2, #0xf 
        cmp     r2, #10 
        addmi   r2, r2, #0x30            @ 0~10
        addpl   r2, r2, #0x37            @ A~F
 
        str     r2, [r1] 
        sub     r3, r3, #4 
        cmp     r3, #0
        bpl     print_hex_loop 
        ldr     r2, =0xa                @回车+换行
        str     r2, [r1] 
        ldr     r2, =0xd
        str     r2, [r1]
 
        @mov     pc, lr
        ldmfd sp!,{r0,r1,r2,r3,pc}

.globl uart_print_hexp
uart_print_hexp:
        stmfd sp!,{r0,r1,r2,r3,lr}
        ldr     r0, [r0]      @r0 指向的内容，打印为16进制的值
        ldr     r1, =0xe2900020    @uart0
        ldr     r2, = 0x30
        str     r2, [r1]                @UTH0='0' 
        ldr     r2, = 0x78
        str     r2, [r1]                @UTH0='x' 
        ldr     r3, = 28
print_hex_loop1:
        lsr     r2, r0, r3       @左移 r3指定移动的位数
        and     r2, r2, #0xf 
        cmp     r2, #10 
        addmi   r2, r2, #0x30            @ 0~10
        addpl   r2, r2, #0x37            @ A~F
 
        str     r2, [r1] 
        sub     r3, r3, #4 
        cmp     r3, #0
        bpl     print_hex_loop1 
        ldr     r2, =0xa                @回车+换行
        str     r2, [r1] 
        ldr     r2, =0xd
        str     r2, [r1]
 
        @mov     pc, lr
        ldmfd sp!,{r0,r1,r2,r3,pc}

/********************************************************************************/
/*
	nand initialze
	2020-12-16
 */
#if 1

#define MP01CON_OFFSET 			0x2E0 
#define MP01DAT_OFFSET 			0x2E4 
#define MP01PUD_OFFSET 			0x2E8 



#define MP03CON_OFFSET                  0x320 
#define MP03DAT_OFFSET                  0x324
#define MP03PUD_OFFSET                  0x328 

#define MP06CON_OFFSET                  0x380 
#define MP06DAT_OFFSET                  0x384
#define MP06PUD_OFFSET                  0x388 


/*
 * Nand flash controller
 */
#define ELFIN_NAND_BASE			0xB0E00000
#define ELFIN_NAND_ECC_BASE		0xB0E20000

#define NFCONF_OFFSET           	0x00
#define NFCONT_OFFSET           	0x04




#define NFCONF_VAL	(7<<12)|(7<<8)|(7<<4)|(0<<3)|(1<<2)|(1<<1)|(0<<0)       
#define NFCONT_VAL	(0<<18)|(0<<17)|(0<<16)|(0<<10)|(0<<9)|(0<<8)|(0<<7)|(0<<6)|(0x3<<1)|(1<<0)
#define MP03CON_VAL	(1<<29)|(1<<25)|(1<<21)|(1<<17)|(1<<13)|(1<<9)|(1<<5)|(1<<1)
#endif

/*
 * Nand Interface Init for SMDKC110
 */
nand_asm_init:

	/* Setting GPIO for NAND */
	/* This setting is NAND initialze code at booting time in iROM. */

	ldr	r0, =0xE0200000
	
	ldr	r1, [r0, #MP01CON_OFFSET]
	bic	r1, r1, #(0xf<<8)
	orr	r1, r1, #(0x3<<8)
	str	r1, [r0, #MP01CON_OFFSET]

	ldr	r1, [r0, #MP01PUD_OFFSET]
	bic	r1, r1, #(0x3<<4)
	str	r1, [r0, #MP01PUD_OFFSET]

	ldr	r1, [r0, #MP03CON_OFFSET]
	bic	r1, r1, #0xFFFFFF
	ldr	r2, =0x22222222
	orr	r1, r1, r2
	str	r1, [r0, #MP03CON_OFFSET]

	ldr	r1, [r0, #MP03PUD_OFFSET]
	ldr	r2, =0x3fff
	bic	r1, r1, r2
	str	r1, [r0, #MP03PUD_OFFSET]



/********************************************************/  
    ldr r2, =0x22222222
    str r2, [r0, #MP06CON_OFFSET]


    str r2, [r0, #MP06PUD_OFFSET]

/********************************************************/


	ldr	r0, =ELFIN_NAND_BASE

	ldr	r1, [r0, #NFCONF_OFFSET]
	ldr	r2, =0x777F
	bic	r1, r1, r2
	ldr	r2, =NFCONF_VAL
	orr	r1, r1, r2
	str	r1, [r0, #NFCONF_OFFSET]

	ldr	r1, [r0, #NFCONT_OFFSET]
	ldr	r2, =0x707C7
	bic	r1, r1, r2
	ldr	r2, =NFCONT_VAL
	orr	r1, r1, r2
	str	r1, [r0, #NFCONT_OFFSET]

	ldr	r1, [r0, #NFCONF_OFFSET]
	orr	r1, r1, #0x70
	orr	r1, r1, #0x7700
	str  r1, [r0, #NFCONF_OFFSET]

	ldr	r1, [r0, #NFCONT_OFFSET]
	orr	r1, r1, #0x03
	str  r1, [r0, #NFCONT_OFFSET]

	mov	pc, lr
