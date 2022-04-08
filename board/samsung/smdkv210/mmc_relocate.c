typedef int _bool;
 
typedef _bool (*copy_sd_to_mem)(unsigned int,unsigned int, unsigned short, unsigned int*,_bool);
//typedef int (*copy_nand_to_mem)(unsigned int,unsigned int, unsigned char*);
  
 
void mmc_relocate(void)
{
    copy_sd_to_mem uboot_copy = (copy_sd_to_mem)(*(unsigned int*)(0xd0037f98));
 
    unsigned int ch = *(volatile unsigned int*)(0xd0037488);
 
    if(ch == 0xeb200000)
    {   
        /* 从1号扇区开始拷贝，跟制作uboot的方式有关,我搬移了500k */
        uboot_copy(2, 1, 1000,(unsigned int*) 0x34800000, 0); 
    }  
#if 0     
    else if(ch == 0xeb000000)
    {   
        /* 只要大于33号扇区就都可以,我搬移了500k */
    //    uboot_copy(2, 49, 1000,(unsigned int*) 0x34800000, 0); 
    }
#endif       
}


#if 0
void nand_relocate(void)
{
    copy_nand_to_mem uboot_copy = (copy_nand_to_mem)(*(unsigned int*)(0xD0037F90));    //自带的拷贝函数，要进行ecc校验 
    int i;
    /* 只要大于33号扇区就都可以,我搬移了400k */

    /*
        1块有多少页
        1页有多少字节
     */

    for(i=0;i<256;i++)  //拷贝512k，每一页是2k的话，拷贝256页
    {
        uboot_copy(0,i,(unsigned char*) (0x34800000 + 2048*i )); 
    }
    
}
#endif
