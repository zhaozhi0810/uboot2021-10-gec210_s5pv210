typedef int _bool;
 
typedef _bool (*copy_sd_to_mem)(unsigned int,unsigned int, unsigned short, unsigned int*,_bool);
//typedef int (*copy_nand_to_mem)(unsigned int,unsigned int, unsigned char*);
  
 
void mmc_relocate(void)
{
    copy_sd_to_mem uboot_copy = (copy_sd_to_mem)(*(unsigned int*)(0xd0037f98));
 
    unsigned int ch = *(volatile unsigned int*)(0xd0037488);
 
    if(ch == 0xeb200000)
    {   
        /* ��1��������ʼ������������uboot�ķ�ʽ�й�,�Ұ�����500k */
        uboot_copy(2, 1, 1000,(unsigned int*) 0x34800000, 0); 
    }  
#if 0     
    else if(ch == 0xeb000000)
    {   
        /* ֻҪ����33�������Ͷ�����,�Ұ�����500k */
    //    uboot_copy(2, 49, 1000,(unsigned int*) 0x34800000, 0); 
    }
#endif       
}


#if 0
void nand_relocate(void)
{
    copy_nand_to_mem uboot_copy = (copy_nand_to_mem)(*(unsigned int*)(0xD0037F90));    //�Դ��Ŀ���������Ҫ����eccУ�� 
    int i;
    /* ֻҪ����33�������Ͷ�����,�Ұ�����400k */

    /*
        1���ж���ҳ
        1ҳ�ж����ֽ�
     */

    for(i=0;i<256;i++)  //����512k��ÿһҳ��2k�Ļ�������256ҳ
    {
        uboot_copy(0,i,(unsigned char*) (0x34800000 + 2048*i )); 
    }
    
}
#endif
