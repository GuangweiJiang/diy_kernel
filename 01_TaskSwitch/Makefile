objs := head.o init.o main.o

TaskSwitch.bin: $(objs)
	arm-linux-ld -Ttext 0x00000000 -o TaskSwitch_elf $^
	arm-linux-objcopy -O binary -S TaskSwitch_elf $@
	arm-linux-objdump -D -m arm TaskSwitch_elf > TaskSwitch.dis
	
%.o:%.c
	arm-linux-gcc -Wall -c -o $@ $<

%.o:%.S
	arm-linux-gcc -Wall -c -o $@ $<

clean:
	rm -f TaskSwitch.bin TaskSwitch_elf TaskSwitch.dis *.o	
