@**************************************************************
@ File: 	head.S
@ Function: 主要初始化Timer0，并在Time0发生中断后自动进行程序调度。
@ Author: 	Guangwei_Jiang
@ Date:		Dec27'10 
@**************************************************************

.text
.extern Task1
.global _start
.global EnterCriticalSection
.global ExitCriticalSection

@******************************************************************************
@ 定义存放Task1/Task2堆栈指针的地址。
@******************************************************************************
.equ	TaskCur_STK_PTR,	0x00000FFC		@ 4096-4
.equ	TaskNext_STK_PTR,	0x00000FF8		@ 4096-8
.equ	Task01_STK_PTR,		0x00000FF4		@ 4096-12
.equ	TaskMin_STK_PTR,	0x00000FF4		@ 4096-12
.equ	Task02_STK_PTR,		0x00000FF0		@ 4096-16
.equ	TaskMax_STK_PTR,	0x00000FF0		@ 4096-16

.equ	CPSR_TEMP_PTR,		0x00000FA8		@ 4008, CPSR暂存地址
.equ	PC_TEMP_PTR,		0x00000FA4		@ 4004, PC指针暂存地址

.equ	INTOFFSET,			0x4A000014		@ Interrupt offset register
.equ	INT_TIMER0_OFFSET,	10				@ Timer0中断偏移量

.equ	NOINT,				0x00000080		@ 关闭IRQ

	
_start:

@******************************************************************************       
@ 中断向量，本程序中，除Reset和HandleIRQ外，其它异常都没有使用
@******************************************************************************       
    b   Reset

@ 0x04: 未定义指令中止模式的向量地址
HandleUndef:
    b   HandleUndef 
 
@ 0x08: 管理模式的向量地址，通过SWI指令进入此模式
HandleSWI:
    b   HandleSWI

@ 0x0c: 指令预取终止导致的异常的向量地址
HandlePrefetchAbort:
    b   HandlePrefetchAbort

@ 0x10: 数据访问终止导致的异常的向量地址
HandleDataAbort:
    b   HandleDataAbort

@ 0x14: 保留
HandleNotUsed:
    b   HandleNotUsed

@ 0x18: 中断模式的向量地址
    b   HandleIRQ

@ 0x1c: 快中断模式的向量地址
HandleFIQ:
    b   HandleFIQ

Reset:  
	ldr	sp, =4000			@ 设置SVC模式下的堆栈
	bl 	disable_watch_dog	@ 关闭WatchDog

	msr cpsr_c, #0xd2		@ 进入中断模式
	ldr sp, =2560			@ 设置中断模式栈指针
	
	msr cpsr_c, #0xdf		@ 进入系统模式
	ldr sp, =4000			@ 设置系统模式栈指针
	
	bl  clock_init          @ 设置MPLL，改变FCLK、HCLK、PCLK
	bl	init_led			@ 初始化LED灯
    bl  timer0_init         @ 初始化定时器0   
    bl  init_irq            @ 调用中断初始化函数，在init.c中
    msr cpsr_c, #0x5f       @ 设置I-bit=0，开IRQ中断
    
    @ "下一个任务"的堆栈指针指向任务1
    ldr	r0, =Task01_STK_PTR
    ldr r1, =TaskNext_STK_PTR
    str	r0, [r1]			@ mem[r1] =r0

	ldr	lr, =halt_loop		@ 设置lr
	ldr pc, =Task1			@ 启动第一个任务Task1
halt_loop:
	b	halt_loop
	

HandleIRQ:
    sub lr, lr, #4                  @ 计算返回地址
    stmdb   sp!,    { r0-r12,lr }   @ 保存使用到的寄存器
                                    @ 注意，此时的sp是中断模式的sp                                     
	@ 检查是否Timer0中断，若是，则跳转到Timer0_Int
	ldr r0, =INTOFFSET
	ldr r0, [r0]
	ldr r1, =INT_TIMER0_OFFSET
	cmp r0, r1
	beq Timer0_Int
	
	@ 处理其他类型中断
	                        
int_return:
    ldmia   sp!,    { r0-r12, pc }^  @ 中断返回, ^表示将spsr的值复制到cpsr
    
Timer0_Int:	                
	@ 我们要求Time0中断发生后，要执行KernelSched，而不是返回中断发生前的函数，为此要做：
	@ a. 把中断发生前的PC指针保存起来，以备之后使用；
	@ b. 在堆栈中，用KernelSched替换中断发生前的PC指针，使中断后能直接跳到KernelSched!
    mov r4, sp						@ r4 = 堆栈指针
    add r5, r4, #52					@ +52, 找到PC(进入intrrupt之前模式的)存储的位置
    ldr r6, [r5]					@ 将PC(进入intrrupt之前模式的)指针值载入到r6
    ldr r7, =PC_TEMP_PTR			@ r7 = PC指针暂时存放地址
    str r6, [r7]					@ 将PC(进入intrrupt之前模式的)暂存
    ldr r8, =KernelSched			@ r8 = KernelSched
    str r8, [r5]					@ 将PC指针置换成KernelSched
    
    ldr lr, =int_return             @ 设置调用ISR即EINT_Handle函数后的返回地址 
    ldr pc, =Timer0_Handle			@ 调用中断服务函数，在interrupt.c中  
    
@******************************************************************************			
@ 任务切换。这里使用最简单的"轮转法调度"！
@******************************************************************************
KernelSched:
	@ 将“当前任务”寄存器值压栈。
	stmfd sp!,{lr}              @ PC 入栈
	stmfd sp!,{r0-r12,lr}		@ r0-r12，lr入栈	
	
	@ 取出中断发生前的PC值，并将它压入栈中
	mov r4, sp					@ r4 = 堆栈指针
    add r5, r4, #56				@ +56, 找到PC(进入intrrupt之前模式的)存储的位置
    ldr r6, =PC_TEMP_PTR		@ r6 = PC指针暂时存放地址
    ldr r7, [r6]				@ r7 = 进入intrrupt之前模式的PC值
    str r7, [r5]				@ 将PC指针置换成进入intrrupt之前模式的PC值
			
	mrs r4,cpsr
	stmfd sp!,{r4}				@ cpsr入栈

	@ 计算存放“当前任务”堆栈指针的地址。
	@ 因为采用最简单的“轮转法调度”，所以，“当前任务”是上一次调度之前的“下一个任务”！
	ldr r0, =TaskCur_STK_PTR	
	ldr r1, =TaskNext_STK_PTR
	ldr r1, [r1]				 
	str	r1, [r0]	
		
	@ 保存“当前任务”的栈顶指针。
	ldr r5,=TaskCur_STK_PTR		@ 取出存放“当前任务”的堆栈指针的地址
	ldr r5, [r5]
	str sp,[r5]                 @ 保存“当前任务”的堆栈指针			
	
	@ 计算“下一个任务”堆栈指针。
	@ “下一个任务”的堆栈指针, 保存在“当前任务”堆栈指针的地址的后面(-4)；
	@ 如果“下一个任务”超出了界限，则指向第一个任务。
	ldr r0, =TaskNext_STK_PTR
	ldr r1, =TaskCur_STK_PTR
	ldr r1, [r1]
	sub r1, r1, #4				@"下一个任务"保存地址 = “当前任务”保存地址 - 4			
	str r1, [r0]	
	ldr r2, =TaskMin_STK_PTR
	ldr r3, =TaskMax_STK_PTR
	cmp r1, r3
	strmi r2, [r0]				@ 如果TaskNext_STK_PTR越界，
								@ 则将TaskMin_STK_PTR的值赋给TaskNext_STK_PTR.			

	@ 取出“下一个任务”的栈顶指针，并将寄存器依次出栈。
	ldr r6, =TaskNext_STK_PTR	@ 取出存放"下一个任务"的Stack Pointer的地址
	ldr r6, [r6]
	ldr sp, [r6]				@ 取出"下一个任务"的堆顶指针,赋给SP         		
	b   POP_ALL					@ 根据设定的栈结构顺序出栈
						
@ 根据设定的栈结构顺序出栈
POP_ALL:			
	ldmfd sp!,{r4}              @ psr出栈
	msr CPSR_cxsf,r4	
	ldmfd sp!,{r0-r12,lr,pc}    @ r0-r12,lr,pc出栈   
	
@ 进入临界区
EnterCriticalSection:
	stmfd sp!, {r0-r4, lr}		@ 保存寄存器	
	mrs r0, CPSR				@ 将CPSR的值保存到r0
	ldr r3, =CPSR_TEMP_PTR
	str	r0, [r3]				@ 保存CPSR的值
	ldr r1, =NOINT
	orr r2, r0, r1				@ 将CPSR的“I”位置1
	msr CPSR_c, r2				@ 设置CPSR的控制位	
	ldmfd sp!, {r0-r4, pc}		@ 寄存器恢复

@ 退出临界区
ExitCriticalSection:
	stmfd sp!, {r0-r4, lr}		@ 保存寄存器
	ldr r0, =CPSR_TEMP_PTR
	ldr r0, [r0]				@ 获取保存的CPSR的值
	msr CPSR_c, r0				@ 恢复CPSR的值
	ldmfd sp!, {r0-r4, pc}		@ 寄存器恢复
