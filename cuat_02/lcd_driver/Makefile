obj-m += lcd.o  # Add your driver .c file

KDIR := /lib/modules/$(shell uname -r)/build  # Kernel build directory
PWD := $(shell pwd)  # Current directory

all:
	make -C $(KDIR) M=$(PWD) modules  # Ensure this line starts with a tab

clean:
	make -C $(KDIR) M=$(PWD) clean  # Ensure this line starts with a tab 