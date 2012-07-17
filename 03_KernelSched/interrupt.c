//==========================================
// Filename:
//     interrupt.c
//
// Description:
//      处理中断发生后的事情.
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

#include "s3c24xx.h"

void Timer0_Handle(void)
{    
    //清中断
    SRCPND = 1 << INTOFFSET;
    INTPND = INTPND;     
}

