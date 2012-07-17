@**************************************************************
@ File: 	head.S
@ Function: 初始化，包括设置SVC模式下的堆栈，关闭WatchDog,初始化LED灯，启动第一个任务Task1。
@			还包括Task1/Task2之间相互切换的功能。
@ Author: 	Guangwei_Jiang
@ Date:		Dec09'10 
@**************************************************************

.extern Task1
.global _start
.global Task_Sw_1To2
.global Task_Sw_2To1

@******************************************************************************
@ 定义存放Task1/Task2堆顶指针的地址。
@******************************************************************************
.equ	Task1_STK_PTR,		0x00000FFC		@ 4096-4
.equ	Task2_STK_PTR,		0x00000FF8		@ 4096-8

	
@******************************************************************************
@ CPU reset后运行的第一段代码。
@ 初始化，包括设置SVC模式下的堆栈，关闭WatchDog,初始化LED灯，启动第一个任务Task1。
@******************************************************************************
_start:
	ldr	sp, =4000			@ 设置SVC模式下的堆栈
	bl 	disable_watch_dog	@ 关闭WatchDog
	bl	init_led			@ 初始化LED灯

	ldr	lr, =halt_loop		@ 设置lr
	ldr pc, =Task1			@ 启动第一个任务Task1
halt_loop:
	b	halt_loop

@******************************************************************************
@ 从Task1切换到Task2
@******************************************************************************
Task_Sw_1To2:
	stmfd sp!,{lr}              @ PC 入栈
	stmfd sp!,{r0-r12,lr}		@ r0-r12，lr入栈
			
	mrs r4,cpsr
	stmfd sp!,{r4}				@ cpsr入栈

	ldr r5,=Task1_STK_PTR		@ 取出存放Task1的Stack Pointer的地址
	str sp,[r5]                 @ 保存Task1的Stack Pointer

	ldr r6, =Task2_STK_PTR		@ 取出存放Task2的Stack Pointer的地址
	ldr sp, [r6]				@ 取出Task2的堆顶指针到SP         		
	b   POP_ALL					@ 根据设定的栈结构顺序出栈


@******************************************************************************
@ 从Task2切换到Task1
@******************************************************************************
Task_Sw_2To1:
	stmfd sp!,{lr}              @ PC 入栈
	stmfd sp!,{r0-r12,lr}		@ r0-r12，lr入栈
			
	mrs r4,cpsr
	stmfd sp!,{r4}				@ cpsr入栈

	ldr r5,=Task2_STK_PTR		@ 取出存放Task2的Stack Pointer的地址
	str sp,[r5]                 @ 保存Task2的Stack Pointer
	
	ldr r6,=Task1_STK_PTR		@ 取出存放Task1的Stack Pointer的地址
	ldr sp,[r6]                 @ 取出Task2的堆顶指针到SP   		
	b   POP_ALL					@ 根据设定的栈结构顺序出栈
				
@******************************************************************************			
@ 根据设定的栈结构顺序出栈
@******************************************************************************
POP_ALL:			
	ldmfd sp!,{r4}              @ psr出栈
	msr CPSR_cxsf,r4	
	ldmfd sp!,{r0-r12,lr,pc}    @ r0-r12,lr,pc出栈
