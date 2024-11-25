rmmod chatlog_driver.ko
insmod ./chatlog_driver.ko
sudo cp ./chatlog_driver.ko /lib/modules/$(uname -r)/
sudo depmod -a