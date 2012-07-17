objs := head.o init.o main.o interrupt.o

KernelSched.bin: $(objs)
	arm-none-linux-gnueabi-ld -Ttext 0x00000000 -o KernelSched_elf $^
	arm-none-linux-gnueabi-objcopy -O binary -S KernelSched_elf $@
	arm-none-linux-gnueabi-objdump -D -m arm KernelSched_elf > KernelSched.dis
	
%.o:%.c
	arm-none-linux-gnueabi-gcc -Wall -c -o $@ $<

%.o:%.S
	arm-none-linux-gnueabi-gcc -Wall -c -o $@ $<

clean:
	rm -f KernelSched.bin KernelSched_elf KernelSched.dis *.o	
