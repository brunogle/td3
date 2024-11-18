#include <linux/init.h>
#include <linux/module.h>
#include <linux/kdev_t.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/slab.h>
#include <asm/uaccess.h>
#include <linux/uaccess.h>
#include <asm/io.h>
#include <linux/ioport.h>
#include <linux/delay.h>
#include <linux/interrupt.h>
#include <linux/gpio.h>
#include <linux/wait.h>
#include <linux/sched.h>
#include <linux/semaphore.h>
#include <linux/spinlock.h>
#include <linux/list.h>
#include <linux/device.h>
#include <linux/of.h>
#include <linux/of_irq.h>
#include <linux/of_platform.h>
#include <linux/of_address.h>

#define LCD_ROWS 4
#define LCD_COLUMNS 20
#define LCD_SIZE LCD_ROWS*LCD_COLUMNS

char recv_str[128];

dev_t lcd_device;
static struct cdev * lcd_cdevice;
static struct class * lcd_class;
static struct device * lcd_class_sys;

static struct gpio_desc * en_pin;
static struct gpio_desc * rs_pin;
static struct gpio_desc * d4_pin;
static struct gpio_desc * d5_pin;
static struct gpio_desc * d6_pin;
static struct gpio_desc * d7_pin;


MODULE_LICENSE("Dual BSD/GPL");

void pulseEnable(void) {
    gpiod_set_value(en_pin, false);
    udelay(1);
    gpiod_set_value(en_pin, true);
    udelay(1); // Enable pulse must be >450ns
    gpiod_set_value(en_pin, false);
    udelay(100); // Commands need >37us to settle
}


void write4Bits(uint8_t value) {
    gpiod_set_value(d4_pin, (value >> 0) & 0x01);
    gpiod_set_value(d5_pin, (value >> 1) & 0x01);
    gpiod_set_value(d6_pin, (value >> 2) & 0x01);
    gpiod_set_value(d7_pin, (value >> 3) & 0x01);
    pulseEnable();
}


void sendCommand(uint8_t command) {
    gpiod_set_value(rs_pin, false);
    write4Bits(command >> 4);
    write4Bits(command & 0x0F);
    if (command < 4) udelay(2000); // Clear and home commands need extra time
}

void init_lcd(void) {

    // Initialize LCD in 4-bit mode
    sendCommand(0x33); // Initialize
    sendCommand(0x32); // Set to 4-bit mode
    sendCommand(0x28); // 4-bit mode, 2 lines, 5x7 font
    sendCommand(0x0C); // Display ON, Cursor OFF
    sendCommand(0x06); // Auto-increment cursor
    sendCommand(0x01); // Clear display
    udelay(2000);
}

void sendChar(char character) {
    gpiod_set_value(rs_pin, true);
    write4Bits(character >> 4);
    write4Bits(character & 0x0F);
}

void display(const char text[80]) {
    const uint8_t rowAddresses[4] = {0x00, 0x40, 0x14, 0x54};
    uint8_t row, col;
    for (row = 0; row < 4; row++) {
        sendCommand(0x80 | rowAddresses[row]); // Set cursor to start of the row
        for (col = 0; col < 20; col++) {
            sendChar(text[col + row*20]);
        }
    }
}


int lcd_open(struct inode * inode, struct file * file){
  printk(KERN_ALERT "lcd_open called\n");
  return 0;
}

ssize_t lcd_write(struct file * file, const char __user * userbuff, size_t size, loff_t * offset) {
    int row = 0;
    int col = 0;
    int i = 0;
    const uint8_t  rowAddresses[4] = {0x00, 0x40, 0x14, 0x54};

    printk(KERN_ALERT "lcd_write called");

    if(size > 128){
        size = 128;
    }

    memset(recv_str, 0, 128);

    if (copy_from_user(recv_str, userbuff, size)) {
        printk(KERN_ALERT "lcd_driver: Failed to copy data from user space\n");
        return -EFAULT;
    }

    sendCommand(0x01); // Clear display


    while(row < LCD_ROWS){
        sendCommand(0x80 | rowAddresses[row]);
        col = 0;
        while(col < LCD_COLUMNS){
            if(recv_str[i] == '\n'){
                col = LCD_COLUMNS;
                i++;
                break;
            }

            sendChar(recv_str[i]);
            col++;
            i++;
            if(i >= size){
                row = LCD_ROWS;
                col = LCD_COLUMNS;
            }
        }
        row += 1;
    }
 
    printk("lcd_driver: Updated LCD to: %s\n", recv_str);


    return size;
}

ssize_t lcd_read (struct file * file, char __user * userbuff, size_t size, loff_t * offset) {
    printk(KERN_ALERT "lcd_read called");


    return 0; // Return the number of bytes read
}

static struct file_operations lcd_ops =
{
  .owner = THIS_MODULE,
  .open = lcd_open,
  .read = lcd_read,
  .write = lcd_write
};




static int lcd_probe(struct platform_device *pdev) {
    int i;
    char lcd_text[80];

    printk("lcd_probe called");

    /* Get the GPIO from the device tree */
    d4_pin = devm_gpiod_get(&pdev->dev, "lcd-d4", GPIOD_OUT_LOW);
    if (IS_ERR(d4_pin)) {
        printk("lcd_driver: Failed to get GPIO for D4\n");
        return PTR_ERR(d4_pin);
    }
    d5_pin = devm_gpiod_get(&pdev->dev, "lcd-d5", GPIOD_OUT_LOW);
    if (IS_ERR(d5_pin)) {
        printk("lcd_driver: Failed to get GPIO for D5\n");
        return PTR_ERR(d5_pin);
    }
    d6_pin = devm_gpiod_get(&pdev->dev, "lcd-d6", GPIOD_OUT_LOW);
    if (IS_ERR(d6_pin)) {
        printk("lcd_driver: Failed to get GPIO for D6\n");
        return PTR_ERR(d6_pin);
    }
    d7_pin = devm_gpiod_get(&pdev->dev, "lcd-d7", GPIOD_OUT_LOW);
    if (IS_ERR(d7_pin)) {
        printk("lcd_driver: Failed to get GPIO for D7\n");
        return PTR_ERR(d7_pin);
    }
    en_pin = devm_gpiod_get(&pdev->dev, "lcd-en", GPIOD_OUT_LOW);
    if (IS_ERR(en_pin)) {
        printk("lcd_driver: Failed to get GPIO for EN\n");
        return PTR_ERR(en_pin);
    }
    rs_pin = devm_gpiod_get(&pdev->dev, "lcd-rs", GPIOD_OUT_LOW);
    if (IS_ERR(rs_pin)) {
        printk("lcd_driver: Failed to get GPIO for RS\n");
        return PTR_ERR(rs_pin);
    }

    printk("lcd_driver: GPIO successfully configured\n");


    init_lcd();


    strncpy(&lcd_text[0], "Hello wo\nrld", 20);  // Copy line1 to the first 20 characters
    strncpy(&lcd_text[20], "This is an LCD", 20); // Copy line2 to the second 20 characters
    strncpy(&lcd_text[40], "Being controlled by", 20); // Copy line3 to the third 20 characters
    strncpy(&lcd_text[60], "a linux driver", 20);
    
    for(i = 0; i < 80; i++)
        if(lcd_text[i] == 0)
            lcd_text[i] = ' ';


    display(lcd_text);


    return 0;
}

/* Remove function - called when the driver is unloaded */
static int lcd_remove(struct platform_device *pdev) {
    pr_info("lcd_remove called\n");

    /* Cleanup: Stop the timer and free GPIO resources */
    gpiod_put(d4_pin);
    gpiod_put(d5_pin);
    gpiod_put(d6_pin);
    gpiod_put(d7_pin);
    gpiod_put(en_pin);
    gpiod_put(rs_pin);

    return 0;
}

static const struct of_device_id lcd_of_match[] = {
    { .compatible = "lcd", },
    { /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, lcd_of_match);

static struct platform_driver lcd_driver = {
        .probe = lcd_probe,
        .remove = lcd_remove,
        .driver = {
            .name = "lcd_driver",
            .of_match_table = of_match_ptr(lcd_of_match),
        },    
};

static char * lcd_devnode(struct device * dev, umode_t * mode){
    if (mode == NULL){
        return NULL;
    }

    *mode = 0666;

    return NULL;
}

static int lcd_init(void){
    alloc_chrdev_region(&lcd_device, 0, 1, "lcd");
    printk(KERN_ALERT "Major number assigned: %d\n", MAJOR(lcd_device));

    lcd_cdevice = cdev_alloc();

    lcd_cdevice->ops = &lcd_ops;
    lcd_cdevice->owner = THIS_MODULE;
    lcd_cdevice->dev = lcd_device;

    printk(KERN_ALERT "struct cdev allocated\n");

    cdev_add(lcd_cdevice, lcd_device, 1);

    lcd_class = class_create(THIS_MODULE, "display");
    lcd_class -> devnode = lcd_devnode; 
    lcd_class_sys = device_create (lcd_class, NULL, lcd_device, NULL, "lcd");

    platform_driver_register(&lcd_driver);

    return 0;
}

static void lcd_exit(void){
    device_destroy(lcd_class, lcd_device);
    class_destroy(lcd_class);
    cdev_del(lcd_cdevice);
    unregister_chrdev_region(lcd_device, 1);

    platform_driver_unregister(&lcd_driver);

}

module_init(lcd_init);
module_exit(lcd_exit);
