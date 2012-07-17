objs := head.o init.o main.o

TaskSwitchEx.bin: $(objs)
	arm-none-linux-gnueabi-ld -Ttext 0x00000000 -o TaskSwitchEx_elf $^
	arm-none-linux-gnueabi-objcopy -O binary -S TaskSwitchEx_elf $@
	arm-none-linux-gnueabi-objdump -D -m arm TaskSwitchEx_elf > TaskSwitchEx.dis
	
%.o:%.c
	arm-none-linux-gnueabi-gcc -Wall -c -o $@ $<

%.o:%.S
	arm-none-linux-gnueabi-gcc -Wall -c -o $@ $<

clean:
	rm -f TaskSwitchEx.bin TaskSwitchEx_elf TaskSwitchEx.dis *.o	
