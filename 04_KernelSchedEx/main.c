//==========================================
// Filename:
//		main.c
//
// Description:
//		创建Task2,及实现Task1/Task2.
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
// INTERNAL FUNCTIONS
//-----------------------------------------------------------------
void Task1();
void Task2();
void TaskCreate(void(*Task)(void), unsigned long *p_Stack, unsigned long *Task_STK_PTR);

//-----------------------------------------------------------------
// EXTERNAL FUNCTIONS
//-----------------------------------------------------------------
extern void EnterCriticalSection();
extern void ExitCriticalSection();

//----------------------------------------------------------------------------
// Function:
//      void Task1()
//
// Description:
//		先闪烁4个LED灯一次，并建立Task2的运行上下文环境(context)。
//		之后进入死循环，LED1一直闪烁。
//
// Parameters:
//      n/a
//
// Return Value:
//      n/a
//
void Task1()
{ 
	int i = 0;
	
	GPBDAT &= ~(0xf<<5);			// 点亮LED1-4		
	for(i=0; i<150000; i++); 		// 延时循环
	
	GPBDAT |= (0xf<<5);				// 关闭LED1-4
	for(i=0; i<150000; i++); 		// 延时循环	
	
	TaskCreate(Task2, TASK2_SP, TASK2_STK_PTR);
	
	while(1)
	{	
		EnterCriticalSection();		// 进入临界区
		
		GPBDAT |= (0xf<<5);			// 关闭LED1-4		
		GPBDAT &= ~(1<<5);			// 点亮LED1		
		for(i=0; i<150000; i++); 	// 延时循环
		
		GPBDAT |= (1<<5);			// 关闭LED1
		for(i=0; i<150000; i++); 	// 延时循环
		
		ExitCriticalSection();		// 退出临界区
	}
}


//----------------------------------------------------------------------------
// Function:
//      void TaskCreate(void(*Task)(void), unsigned long *p_Stack, unsigned long *Task_STK_PTR)
//
// Description:
//		建立Task的运行上下文环境(context)
//
// Parameters:
//      void(*Task)(void):			Task地址
//		unsigned long *p_Stack:		Task堆栈指针
//		unsigned long *Task_STK_PTR:保存Task栈顶的地址 
//
// Return Value:
//      n/a
//
void TaskCreate(void(*Task)(void), unsigned long *p_Stack, unsigned long *Task_STK_PTR)
{	
	*(p_Stack)   = (unsigned long)Task;			/* 将任务的地址压入堆栈 */	
	*(--p_Stack) = (unsigned long)13;			/* lr  */
	*(--p_Stack) = (unsigned long)12;			/* r12 */
	*(--p_Stack) = (unsigned long)11;			/* r11 */
	*(--p_Stack) = (unsigned long)10;			/* r10 */
	*(--p_Stack) = (unsigned long)9;			/* r9  */
   	*(--p_Stack) = (unsigned long)8;			/* r8  */
   	*(--p_Stack) = (unsigned long)7;			/* r7  */
   	*(--p_Stack) = (unsigned long)6;			/* r6  */
   	*(--p_Stack) = (unsigned long)5;			/* r5  */
   	*(--p_Stack) = (unsigned long)4; 			/* r4  */
   	*(--p_Stack) = (unsigned long)3;			/* r3  */
   	*(--p_Stack) = (unsigned long)2;			/* r2  */
   	*(--p_Stack) = (unsigned long)1;			/* r1  */
	*(--p_Stack) = (unsigned long)0;			/* r0  */
    *(--p_Stack) = (unsigned long)(SYSMODE);	/* CPSR */
	*Task_STK_PTR = (unsigned long)p_Stack;  	/* 保存Task栈顶地址*/
}


//----------------------------------------------------------------------------
// Function:
//      void Task2()
//
// Description:
//		先闪烁4个LED灯一次。
//		之后进入死循环，LED2一直闪烁。
//
// Parameters:
//      n/a
//
// Return Value:
//      n/a
//
void Task2()
{ 
	int i = 0;
	
	GPBDAT &= ~(0xf<<5);			// 点亮LED1-4		
	for(i=0; i<150000; i++); 		// 延时循环
	
	GPBDAT |= (0xf<<5);				// 关闭LED1-4
	for(i=0; i<150000; i++); 		// 延时循环
	
	while(1)
	{	
		EnterCriticalSection();		// 进入临界区
			
		GPBDAT |= (0xf<<5);			// 关闭LED1-4	
		GPBDAT &= ~(1<<6);			// 点亮LED2		
		for(i=0; i<150000; i++); 	// 延时循环
		
		GPBDAT |= (1<<6);			// 关闭LED2
		for(i=0; i<150000; i++); 	// 延时循环
		
		ExitCriticalSection();		// 退出临界区
	}
}
