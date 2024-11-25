obj-m += chatlog_driver.o  # Add your driver .c file

KDIR := /lib/modules/$(shell uname -r)/build  # Kernel build directory
PWD := $(shell pwd)  # Current directory

all:
	make -C $(KDIR) M=$(PWD) modules

clean:
	make -C $(KDIR) M=$(PWD) clean  