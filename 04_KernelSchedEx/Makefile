objs := head.o init.o main.o interrupt.o

KernelSchedEx.bin: $(objs)
	arm-none-linux-gnueabi-ld -Ttext 0x00000000 -o KernelSchedEx_elf $^
	arm-none-linux-gnueabi-objcopy -O binary -S KernelSchedEx_elf $@
	arm-none-linux-gnueabi-objdump -D -m arm KernelSchedEx_elf > KernelSchedEx.dis
	
%.o:%.c
	arm-none-linux-gnueabi-gcc -Wall -c -o $@ $<

%.o:%.S
	arm-none-linux-gnueabi-gcc -Wall -c -o $@ $<

clean:
	rm -f KernelSchedEx.bin KernelSchedEx_elf KernelSchedEx.dis *.o	
