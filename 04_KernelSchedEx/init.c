//==========================================
// Filename:
//     init.c
//
// Description:
//      关闭WatchDog,初始化LED灯.
//
// Author/Created Date:
//      Guangwei Jiang, Dec27'10
//
// Modification History:
// 
//
//
// Note:
//    
//==========================================
//
// 
//


//--------------------------------------------------------------------------------------
// Include Files
//--------------------------------------------------------------------------------------
#include "s3c24xx.h"


//-----------------------------------------------------------------
// 关闭WatchDog
//-----------------------------------------------------------------
void disable_watch_dog(void)
{
	WTCON = 0;					// 写0关闭WatchDog
}

//-----------------------------------------------------------------
// 初始化LED灯
//-----------------------------------------------------------------
void init_led(void)
{
    GPBCON = GPB5_out | GPB6_out | GPB7_out | GPB8_out ;
    GPBDAT |= (0x0f<<5);		// 关闭所有的LED灯
}

#define S3C2410_MPLL_200MHZ     ((0x5c<<12)|(0x04<<4)|(0x00))
#define S3C2440_MPLL_200MHZ     ((0x5c<<12)|(0x01<<4)|(0x02))
/*
 * 对于MPLLCON寄存器，[19:12]为MDIV，[9:4]为PDIV，[1:0]为SDIV
 * 有如下计算公式：
 *  S3C2410: MPLL(FCLK) = (m * Fin)/(p * 2^s)
 *  S3C2410: MPLL(FCLK) = (2 * m * Fin)/(p * 2^s)
 *  其中: m = MDIV + 8, p = PDIV + 2, s = SDIV
 * 对于本开发板，Fin = 12MHz
 * 设置CLKDIVN，令分频比为：FCLK:HCLK:PCLK=1:2:4，
 * FCLK=200MHz,HCLK=100MHz,PCLK=50MHz
 */
void clock_init(void)
{
    // LOCKTIME = 0x00ffffff;   // 使用默认值即可
    CLKDIVN  = 0x03;            // FCLK:HCLK:PCLK=1:2:4, HDIVN=1,PDIVN=1

    /* 如果HDIVN非0，CPU的总线模式应该从“fast bus mode”变为“asynchronous bus mode” */
__asm__(
    "mrc    p15, 0, r1, c1, c0, 0\n"        /* 读出控制寄存器 */ 
    "orr    r1, r1, #0xc0000000\n"          /* 设置为“asynchronous bus mode” */
    "mcr    p15, 0, r1, c1, c0, 0\n"        /* 写入控制寄存器 */
    );

    /* 判断是S3C2410还是S3C2440 */
    if ((GSTATUS1 == 0x32410000) || (GSTATUS1 == 0x32410002))
    {
        MPLLCON = S3C2410_MPLL_200MHZ;  /* 现在，FCLK=200MHz,HCLK=100MHz,PCLK=50MHz */
    }
    else
    {
        MPLLCON = S3C2440_MPLL_200MHZ;  /* 现在，FCLK=200MHz,HCLK=100MHz,PCLK=50MHz */
    }       
}

/*
 * Timer input clock Frequency = PCLK / {prescaler value+1} / {divider value}
 * {prescaler value} = 0~255
 * {divider value} = 2, 4, 8, 16
 * 本实验的Timer0的时钟频率=100MHz/(99+1)/(16)=62500Hz
 * 设置Timer0 0.5秒钟触发一次中断：
 */
void timer0_init(void)
{
    TCFG0  = 99;        // 预分频器0 = 99        
    TCFG1  = 0x03;      // 选择16分频
    TCNTB0 = 31250;     // 0.5秒钟触发一次中断
    TCON   |= (1<<1);   // 手动更新
    TCON   = 0x09;      // 自动加载，清“手动更新”位，启动定时器0
}

/*
 * 定时器0中断使能
 */ 
void init_irq(void)
{        
    // 定时器0中断使能
    INTMSK   &= (~(1<<10));
}
