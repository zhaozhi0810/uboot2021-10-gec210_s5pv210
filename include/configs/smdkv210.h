/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * Copyright (C) 2009 Samsung Electronics
 * Minkyu Kang <mk7.kang@samsung.com>
 * Kyungmin Park <kyungmin.park@samsung.com>
 *
 * Configuation settings for the SAMSUNG Universal (s5pc100) board.
 */

#ifndef __CONFIG_H
#define __CONFIG_H

/* High Level Configuration Options */
#define CONFIG_SAMSUNG		1	/* in a SAMSUNG core */
#define CONFIG_S5P		1	/* which is in a S5P Family */
#define CONFIG_S5PC110		1	/* which is in a S5PC110 */

#include <linux/sizes.h>
#include <asm/arch/cpu.h>		/* get chip and board defs */





/* input clock of PLL: has 24MHz input clock at S5PC110 */
#define CONFIG_SYS_CLK_FREQ_C110	24000000

/* DRAM Base */
#define CONFIG_SYS_SDRAM_BASE		0x30000000

/* Text Base */

#define CONFIG_SETUP_MEMORY_TAGS
#define CONFIG_CMDLINE_TAG
#define CONFIG_REVISION_TAG
#define CONFIG_INITRD_TAG

/* Size of malloc() pool before and after relocation */
#define CONFIG_SYS_MALLOC_LEN		(CONFIG_ENV_SIZE + (80 << 20))

/* MMC */
#define SDHCI_MAX_HOSTS		4

/* PWM */
#define CONFIG_PWM			1

/* USB Composite download gadget - g_dnl */
#define DFU_DEFAULT_POLL_TIMEOUT 300

/* USB Samsung's IDs */

#define CONFIG_G_DNL_THOR_VENDOR_NUM 0x04E8
#define CONFIG_G_DNL_THOR_PRODUCT_NUM 0x685D
#define CONFIG_G_DNL_UMS_VENDOR_NUM 0x0525
#define CONFIG_G_DNL_UMS_PRODUCT_NUM 0xA4A5

#define CONFIG_USB_GADGET_VENDOR_NUM 0x18d1
#define CONFIG_USB_GADGET_PRODUCT_NUM 0x4e30


#define CONFIG_USB_OHCI_NEW		1
#define CONFIG_SYS_USB_OHCI_MAX_ROOT_PORTS	2  //2022-0102



/*#define BOOT_ONENAND		0x1*/
#define BOOT_NAND		0x2
#define BOOT_MMCSD		0x3
#define BOOT_NOR		0x4
#define BOOT_SEC_DEV	0x5
#define OMR_OFFSET		0x04
#define INF_REG3_OFFSET		0x0c
#define PRO_ID_BASE			0xE0000000
#define INF_REG_BASE		0xE010F000



#define CFG_PHY_UBOOT_BASE	0x34800000
/* nand copy size from nand to DRAM.*/
#define	COPY_BL2_SIZE		0xc0000   //768k




//#define CONFIG_CMD_NET

#ifdef CONFIG_CMD_NET
//#define CONFIG_DRIVER_DM9000                  /* 使用dm9000驱动 */
#define DM9000_ENV_SROM_BANK 1        /* 使用srom的bank1 */
 
#define DM9000_BASE  0x88000000        
#define DM9000_IO           DM9000_BASE
#define DM9000_DATA         (DM9000_BASE + 4)
#define CONFIG_DM9000_USE_16BIT  1
#define MYCONFIG_ETHDADDR     01:24:45:20:21:12


#define CONFIG_NET_RANDOM_ETHADDR
#define CONFIG_NETMASK  255.255.255.0
#define CONFIG_SERVERIP 192.168.1.10
#define CONFIG_GATEWAYIP    192.168.1.1
#define CONFIG_IPADDR   192.168.1.102



#endif




//#define CONFIG_BOOTCOMMAND "tftp 0x30008000 uImage ;bootm 0x30008000"
#define CONFIG_BOOTCOMMAND "nand read  0x30008000 180000 500000 ;nand read  0x31008000 100000 80000 ; bootz 30008000 - 31008000"
//#define CONFIG_BOOTCOMMAND "tftp 0x30008000 uImage ;bootm 0x30008000"


//#define CONFIG_BOOTARGS "console=ttySAC0,115200n8 root=/dev/nfs nfsroot=192.168.1.10:/home/hqyj/hq6818/system/rootfs rw ip=192.168.1.50 rw root wait ignore_loglevel earlyprintk"


/*
 * NAND Contoller driver
 */
#ifdef CONFIG_CMD_NAND                  /* add by dazhi 2021-12-26 */
#define CONFIG_SYS_MAX_NAND_DEVICE      1
#define CONFIG_SYS_NAND_BASE            0xB0E00000


 /* modied by Sourcelink */
 #define MTDIDS_DEFAULT          "nand0=s5p-nand"
#define MTDPARTS_DEFAULT        "mtdparts=s5p-nand:768k(bootloader)"\
",256k@0xC0000(params)"\
",512k@0x100000(dtb)"\
",5m@0x180000(kernel)"\
",-(rootfs)"








#endif



#define CONFIG_MISC_COMMON




#if 0
/* Actual modem binary size is 16MiB. Add 2MiB for bad block handling */

/* partitions definitions */
#define PARTS_CSA			"csa-mmc"
#define PARTS_BOOTLOADER	"u-boot"
#define PARTS_BOOT			"boot"
#define PARTS_ROOT			"platform"
#define PARTS_DATA			"data"
#define PARTS_CSC			"csc"
#define PARTS_UMS			"ums"

#define CONFIG_DFU_ALT \
	"u-boot raw 0x80 0x400;" \
	"uImage ext4 0 2;" \
	"exynos3-goni.dtb ext4 0 2;" \
	""PARTS_ROOT" part 0 5\0"

#define PARTS_DEFAULT \
	"uuid_disk=${uuid_gpt_disk};" \
	"name="PARTS_CSA",size=8MiB,uuid=${uuid_gpt_"PARTS_CSA"};" \
	"name="PARTS_BOOTLOADER",size=60MiB," \
	"uuid=${uuid_gpt_"PARTS_BOOTLOADER"};" \
	"name="PARTS_BOOT",size=100MiB,uuid=${uuid_gpt_"PARTS_BOOT"};" \
	"name="PARTS_ROOT",size=1GiB,uuid=${uuid_gpt_"PARTS_ROOT"};" \
	"name="PARTS_DATA",size=3GiB,uuid=${uuid_gpt_"PARTS_DATA"};" \
	"name="PARTS_CSC",size=150MiB,uuid=${uuid_gpt_"PARTS_CSC"};" \
	"name="PARTS_UMS",size=-,uuid=${uuid_gpt_"PARTS_UMS"}\0" \

#define CONFIG_BOOTCOMMAND	"run mmcboot"

#define CONFIG_RAMDISK_BOOT	"root=/dev/ram0 rw rootfstype=ext4" \
		" ${console} ${meminfo}"

#define CONFIG_COMMON_BOOT	"${console} ${meminfo} ${mtdparts}"

#define CONFIG_UPDATEB	"updateb=onenand erase 0x0 0x100000;" \
			" onenand write 0x32008000 0x0 0x100000\0"

#define CONFIG_MISC_COMMON

#define CONFIG_EXTRA_ENV_SETTINGS					\
	CONFIG_UPDATEB \
	"updatek=" \
		"onenand erase 0xc00000 0x600000;" \
		"onenand write 0x31008000 0xc00000 0x600000\0" \
	"updateu=" \
		"onenand erase 0x01560000 0x1eaa0000;" \
		"onenand write 0x32000000 0x1260000 0x8C0000\0" \
	"bootk=" \
		"run loaduimage;" \
		"bootm 0x30007FC0\0" \
	"flashboot=" \
		"set bootargs root=/dev/mtdblock${bootblock} " \
		"rootfstype=${rootfstype} ${opts} " \
		"${lcdinfo} " CONFIG_COMMON_BOOT "; run bootk\0" \
	"ubifsboot=" \
		"set bootargs root=ubi0!rootfs rootfstype=ubifs " \
		"${opts} ${lcdinfo} " \
		CONFIG_COMMON_BOOT "; run bootk\0" \
	"tftpboot=" \
		"set bootargs root=ubi0!rootfs rootfstype=ubifs " \
		"${opts} ${lcdinfo} " CONFIG_COMMON_BOOT \
		"; tftp 0x30007FC0 uImage; bootm 0x30007FC0\0" \
	"ramboot=" \
		"set bootargs " CONFIG_RAMDISK_BOOT \
		"initrd=0x33000000,8M ramdisk=8192\0" \
	"mmcboot=" \
		"set bootargs root=/dev/mmcblk${mmcdev}p${mmcrootpart} " \
		"rootfstype=${rootfstype} ${opts} ${lcdinfo} " \
		CONFIG_COMMON_BOOT "; run bootk\0" \
	"boottrace=setenv opts initcall_debug; run bootcmd\0" \
	"bootchart=set opts init=/sbin/bootchartd; run bootcmd\0" \
	"verify=n\0" \
	"rootfstype=ext4\0" \
	"console=console=ttySAC2,115200n8\0" \
	"meminfo=mem=80M mem=256M@0x40000000 mem=128M@0x50000000\0" \
	"loaduimage=ext4load mmc ${mmcdev}:${mmcbootpart} 0x30007FC0 uImage\0" \
	"mmcdev=0\0" \
	"mmcbootpart=2\0" \
	"mmcrootpart=5\0" \
	"partitions=" PARTS_DEFAULT \
	"bootblock=9\0" \
	"ubiblock=8\0" \
	"ubi=enabled\0" \
	"opts=always_resume=1\0" \
	"dfu_alt_info=" CONFIG_DFU_ALT "\0"

#endif



#define CONFIG_SYS_PBSIZE	384	/* Print Buffer Size */
/* memtest works on */
#define CONFIG_SYS_LOAD_ADDR		(CONFIG_SYS_SDRAM_BASE + 0x4000000)    //0x3400 0000

/* Goni has 3 banks of DRAM, but swap the bank */
#define PHYS_SDRAM_1		CONFIG_SYS_SDRAM_BASE	/* OneDRAM Bank #0 */
#define PHYS_SDRAM_1_SIZE	(256 << 20)		/* 80 MB in Bank #0 */
#define PHYS_SDRAM_2		0x40000000		/* mDDR DMC1 Bank #1 */
#define PHYS_SDRAM_2_SIZE	(256 << 20)		/* 256 MB in Bank #1 */
/*#define PHYS_SDRAM_3		0x50000000	*/	/* mDDR DMC2 Bank #2 */
/*#define PHYS_SDRAM_3_SIZE	(128 << 20)	*/	/* 128 MB in Bank #2 */

#define CONFIG_SYS_MONITOR_BASE		0x00000000
#define CONFIG_SYS_MONITOR_LEN		(256 << 10)	/* 256 KiB */

/* FLASH and environment organization */
#define CONFIG_MMC_DEFAULT_DEV	0

//#define CONFIG_USE_ONENAND_BOARD_INIT
//#define CONFIG_SAMSUNG_ONENAND		1
//#define CONFIG_SYS_ONENAND_BASE		0xB0000000

#define CONFIG_SYS_INIT_SP_ADDR	(CONFIG_SYS_LOAD_ADDR - 0x1000000)     //0x3300 0000

#define CONFIG_USB_GADGET_DWC2_OTG_PHY

#endif	/* __CONFIG_H */
