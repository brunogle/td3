#define BASE_MINOR 0
#define MINOR_COUNT 1

#include <linux/init.h>
#include <linux/module.h>
#include <linux/device.h>
#include <linux/types.h>
#include <linux/jiffies.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/interrupt.h>
#include <linux/pm_runtime.h>
#include <linux/delay.h>
#include <linux/slab.h>
#include <linux/of_platform.h>
#include <linux/of_irq.h>
#include <linux/of_address.h>
#include <linux/uaccess.h>
#include <linux/pinctrl/consumer.h>
#include <linux/timer.h>


#define DEVICE_TYPE "chatlog_display"
#define CLASS_TYPE  "interface"
#define DEVICE_NAME "chatlog_display"

#define CTRL_MODULE 0x44E10000
#define CTRL_MODULE_SIZE 0x2000
#define CTRL_MODULE_D4_PIN 0x8a4 // Control module pinmux (P8_46, GPIO2_7)
#define CTRL_MODULE_D5_PIN 0x8ac // Control module pinmux (P8_44, GPIO2_9)
#define CTRL_MODULE_D6_PIN 0x8b4 // Control module pinmux (P8_42, GPIO2_11)
#define CTRL_MODULE_D7_PIN 0x8bc // Control module pinmux (P8_40, GPIO2_13)
#define CTRL_MODULE_EN_PIN 0x8c4 // Control module pinmux (P8_38, GPIO2_15)
#define CTRL_MODULE_RS_PIN 0x8c8 // Control module pinmux (P8_36, GPIO2_16)
#define CTRL_MODULE_DOWN_PIN 0x894 // Control module pinmux (P8_8, GPIO2_3)
#define CTRL_MODULE_UP_PIN 0x898 // Control module pinmux (P8_10, GPIO2_4)

#define CM_PER 0x44e00000   // Control module base address
#define CM_PER_SIZE 0x1000  // Control module reg bank size
#define CM_PER_GPIO2_CLKCTRL 0xb0 // Control module GPIO2_CLKCTRL offset


#define GPIO2 0x481ac000   // GPIO2 module base address
#define GPIO2_SIZE  0x1000 // GPIO2 module reg bank size
#define GPIO_OE 0x134    // GPIO_OE offset
#define GPIO_DATAOUT 0x13c      // GPIO_DATAOUT offset
#define GPIO_CLEARDATAOUT 0x190 // GPIO_CLEARDATAOUT offset
#define GPIO_SETDATAOUT 0x194   // GPIO_SETDATAOUT offset
#define GPIO_DATAIN 0x138
#define GPIO_FALLINGDETECT 0x14c
#define GPIO_IRQSTATUS_SET_0 0x34
#define GPIO_IRQSTATUS_SET_1 0x38

#define D4_PIN (1 << 7)
#define D5_PIN (1 << 9)
#define D6_PIN (1 << 11)
#define D7_PIN (1 << 13)
#define EN_PIN (1 << 15)
#define RS_PIN (1 << 16)
#define DOWN_PIN (1 << 3)
#define UP_PIN (1 << 4)

#define LCD_ROWS 4
#define LCD_COLUMNS 20

#define LCD_SIZE LCD_ROWS*LCD_COLUMNS
#define RECV_BUFFER_SIZE LCD_SIZE + LCD_COLUMNS

#define LCD_INIT 0x33

#define LCD_FUNCTION 0x20
#define LCD_FUNCTION_8_BIT 0x10
#define LCD_FUNCTION_2_LINE 0x08
#define LCD_FUNCTION_5X10_DOTS 0x04

#define LCD_STATE 0x08
#define LCD_STATE_ON 0x04
#define LCD_STATE_CURSOR 0x02
#define LCD_STATE_CURSOR_BLINK 0x01

#define LCD_ENTRY 0x04
#define LCD_ENTRY_INCREMENT_CURSOR 0x02
#define LCD_ENTRY_DISPLAY_SHIFT 0x01

#define LCD_CLEAR 0x01

#define LCD_HOME 0x02

#define LCD_WRITE_DATA 0x80

const uint8_t row_addresses[4] = {0x00, 0x40, 0x14, 0x54};



int Host_open (struct inode * inode, struct file * file);
ssize_t Host_write (struct file * file, const char __user * userbuff,size_t tamano, loff_t* offset);
ssize_t Host_read (struct file * file, char __user * userbuff, size_t tamano, loff_t * offset);
int Host_close (struct inode * inode, struct file * file);
long int Host_ioctl (struct file *file, unsigned int cmd, unsigned long arg);

static int funcion_probe(struct platform_device * pdev);
static int funcion_remove(struct platform_device * pdev);

MODULE_DESCRIPTION("Driver de Ejemplo para TD3");
MODULE_LICENSE("GPL");
MODULE_ALIAS("platform:Ejemplo-td3");
//MODULE_LICENSE("Dual BSD/GPL");

static dev_t mi_dispo;
static struct cdev * p_cdev;
static struct class * pclase;
static struct device * pdevice_sys;

static void *cm_per_map;
static void *ctrl_module_map;
static void *gpio2_map;

static bool lcd_initialized = false;

int irq;

/*
=================================================
        Funciones Control LCD HD44780 
=================================================
*/

void set_pin(uint32_t pins, uint8_t state){
    if(state){
        iowrite32 (pins, gpio2_map + GPIO_SETDATAOUT);  
    }
    else{
        iowrite32 (pins, gpio2_map + GPIO_CLEARDATAOUT);  
    }
}

void pulse_en(void) {
    set_pin(EN_PIN, false);
    udelay(1);
    set_pin(EN_PIN, true);
    udelay(1);
    set_pin(EN_PIN, false);
    udelay(100);
}

void write_nibble(uint8_t value) {
    set_pin(D4_PIN, (value >> 0) & 0x01);
    set_pin(D5_PIN, (value >> 1) & 0x01);
    set_pin(D6_PIN, (value >> 2) & 0x01);
    set_pin(D7_PIN, (value >> 3) & 0x01);
    pulse_en();
}

void send_command(uint8_t command) {
    set_pin(RS_PIN, false);
    write_nibble(command >> 4);
    write_nibble(command & 0x0F);
    if (command < 4) // Si el comando es HOME o INIT, necesita mas tiempo
        udelay(2000);
}

void init_lcd(void) {
    send_command(LCD_INIT);
    send_command(0x32); //???
    send_command(LCD_FUNCTION | LCD_FUNCTION_2_LINE); 
    send_command(LCD_STATE | LCD_STATE_ON);
    send_command(LCD_ENTRY | LCD_ENTRY_INCREMENT_CURSOR);
    send_command(LCD_CLEAR);
}

void send_char(char character) {
    set_pin(RS_PIN, true);
    write_nibble(character >> 4);
    write_nibble(character & 0x0F);
}

void fill_display(const char text[80]) {
    uint8_t row, col;
    for (row = 0; row < LCD_ROWS; row++) {
        send_command(LCD_WRITE_DATA | row_addresses[row]); // Set cursor to start of the row
        for (col = 0; col < LCD_COLUMNS; col++) {
            send_char(text[col + row*LCD_COLUMNS]);
        }
    }
}

void show_init_message(void){
    printk(KERN_INFO "chatlog_display: Displaying init message\n");
    fill_display("Hello world!        This LCD is being   controlled by a     Linux driver        ");
}

/*
=================================================
          Definiciones Platform Driver 
=================================================
*/

static const struct of_device_id compatible_devices [] = {
    { .compatible = "td3_glecer"},
    {},
};

MODULE_DEVICE_TABLE(of,compatible_devices);

static struct platform_driver chatlog_display_driver = {
    .probe = funcion_probe,
    .remove = funcion_remove,
    .driver = {
        .name = "Chatlog_Display_Driver",
        .of_match_table = of_match_ptr(compatible_devices),
    },    
    
};

static irqreturn_t interrupt_handler(int irq){
    printk(KERN_INFO "chatlog_display: Interrupt triggered\n");
    return IRQ_HANDLED;
}

static struct timer_list debug_timer;
static unsigned int debug_interval = 50;


static void debug_routine(struct timer_list *t) {
    // Esta funcion se llama cada 100ms para probar el GPIO_DATAIN
    static char led_on = false;

    led_on = !led_on;

    printk(KERN_INFO "GPIO_DATAIN: %08X\n", ioread32(gpio2_map + GPIO_DATAIN));

    mod_timer(&debug_timer, jiffies + msecs_to_jiffies(debug_interval));
}

static int funcion_probe(struct platform_device * pdev){
        
    static int Request_result;

    
    printk(KERN_INFO "chatlog_display: probe called\n");

    cm_per_map = ioremap(CM_PER, CM_PER_SIZE);
    if(cm_per_map == NULL){
        printk(KERN_ERR "chatlog_display: CM_PER remap error\n");
        return -1;
    }
    printk(KERN_ERR "chatlog_display: CM_PER remap OK\n");

    gpio2_map = ioremap (GPIO2, GPIO2_SIZE);
    if(gpio2_map == NULL){
        printk(KERN_ERR "chatlog_display: GPIO2 remap error\n");
        return -1;
    }
    printk(KERN_ERR "chatlog_display: GPIO2 remap OK\n");

    ctrl_module_map = ioremap (CTRL_MODULE, CTRL_MODULE_SIZE);
    if(ctrl_module_map == NULL){
        printk(KERN_ERR "chatlog_display: CONTROL_MODULE remmap error\n");
        return -1;
    }
    printk(KERN_ERR "chatlog_display: CONTROL_MODULE remap OK\n");

/*
    irq = platform_get_irq(pdev,0);

    printk(KERN_INFO "chatlog_display: IRQ line assigned: %d", irq);

    Request_result = request_irq ( irq,(irq_handler_t)interrupt_handler, IRQF_TRIGGER_RISING, pdev->name, NULL);
    if(Request_result < 0){
        printk(KERN_ERR "chatlog_display: request_irq error\n");
        return -1;
    }
*/

    iowrite32(0x07, ctrl_module_map + CTRL_MODULE_RS_PIN);
    iowrite32(0x07, ctrl_module_map + CTRL_MODULE_EN_PIN);
    iowrite32(0x07, ctrl_module_map + CTRL_MODULE_D4_PIN);
    iowrite32(0x07, ctrl_module_map + CTRL_MODULE_D6_PIN);
    iowrite32(0x07, ctrl_module_map + CTRL_MODULE_D5_PIN);
    iowrite32(0x07, ctrl_module_map + CTRL_MODULE_D7_PIN);
    iowrite32(0x07, ctrl_module_map + CTRL_MODULE_UP_PIN);
    iowrite32(0x07, ctrl_module_map + CTRL_MODULE_DOWN_PIN);
    printk(KERN_ERR "chatlog_display: Pin-mux set OK\n");


    iowrite32(0x02, cm_per_map + CM_PER_GPIO2_CLKCTRL);

    iowrite32((0xFFFFFFFF&(~(EN_PIN|RS_PIN|D4_PIN|D5_PIN|D6_PIN|D7_PIN))), gpio2_map + GPIO_OE);
    
    //iowrite32(UP_PIN|DOWN_PIN, gpio2_map + GPIO_FALLINGDETECT);
    
    printk(KERN_INFO "GPIO_SYSSTATUS: %08X\n", ioread32(gpio2_map + 0x114));


    printk(KERN_ERR "chatlog_display: GPIO Configuration OK\n");


    //iowrite32(UP_PIN|DOWN_PIN, gpio2_map + GPIO_IRQSTATUS_SET_0);
    //iowrite32(UP_PIN|DOWN_PIN, gpio2_map + GPIO_IRQSTATUS_SET_1);

    init_lcd();
    printk(KERN_ERR "chatlog_display: LCD Init OK\n");



    lcd_initialized = true;

    show_init_message();
    printk(KERN_ERR "chatlog_display: LCD Message shown OK\n");



    timer_setup(&debug_timer, debug_routine, 0);
    mod_timer(&debug_timer, jiffies + msecs_to_jiffies(debug_interval));

    return 0;
}


static int funcion_remove(struct platform_device * pdev){    
	printk(KERN_INFO "chatlog_display: remove called");

    del_timer_sync(&debug_timer);
	iounmap(cm_per_map);
	iounmap(gpio2_map);
    iounmap(ctrl_module_map);
	//free_irq(irq,NULL);
 
	return 0;
}

/*
=================================================
          Definiciones Char Driver
=================================================
*/

static struct file_operations my_device_ops = //Estructura que tiene funciones de archivo 
{
  .owner = THIS_MODULE,
  .open = Host_open,             //cuando la app quiera abrir el archivo
  .read = Host_read,             //cuando la app quiera leer el archivo
  .release = Host_close,         //cuando la app cierra el archivo
  .write = Host_write,           //cuando la app quiera escribir el archivo
  .unlocked_ioctl = Host_ioctl          // 
  
};

int Host_open (struct inode * inode, struct file * file)
{
  
  printk(KERN_ALERT "Host opened!\n");
  
  
  return 0;
}

ssize_t Host_write (struct file * file, const char __user * userbuff, size_t size, loff_t* offset)//este pasa de minuscula a mayuscula 
{
    /*
    El string escrito en el archivo remplaza completamente los contendios del display
    */
    int row = 0;
    int col = 0;
    int i = 0;
    static char recv_str[RECV_BUFFER_SIZE];

    if(!lcd_initialized){
        printk(KERN_ALERT "chatlog_display: LCD not initialized\n");
        return size;
    }

    // Recibo los datos
    if(size > RECV_BUFFER_SIZE)
        size = RECV_BUFFER_SIZE;

    memset(recv_str, 0, RECV_BUFFER_SIZE);

    if (copy_from_user(recv_str, userbuff, size)) {
        printk(KERN_ALERT "chatlog_display: Failed to copy data from user space\n");
        return -EFAULT;
    }

    send_command(LCD_CLEAR); 


    while(row < LCD_ROWS){
        send_command(LCD_WRITE_DATA | row_addresses[row]);
        col = 0;
        while(col < LCD_COLUMNS){
            if(recv_str[i] == '\n'){
                col = LCD_COLUMNS;
                i++;
                break;
            }

            send_char(recv_str[i]);
            col++;
            i++;
            if(i >= size){
                row = LCD_ROWS;
                col = LCD_COLUMNS;
            }
        }
        row += 1;
    }
 
    printk("chatlog_display: Updated LCD\n");

    return size;
  return 0;
}

ssize_t Host_read (struct file * file, char __user * userbuff, size_t tamano, loff_t * offset)
{

  return 0;
}


int Host_close (struct inode * inode, struct file * file)
{  

  return 0;

}

long int Host_ioctl (struct file *file, unsigned int cmd, unsigned long arg)
{  

  return 0;
}


static char * lcd_devnode(struct device * dev, umode_t * mode){
    if (mode == NULL){
        return NULL;
    }

    *mode = 0666;

    return NULL;
}

static int chatlog_display_init(void) //INSTALACION 
{
    int status = 0;

    status = alloc_chrdev_region(&mi_dispo, BASE_MINOR, MINOR_COUNT, DEVICE_TYPE);

    if(status !=0){
        printk(KERN_ERR "chatlog_display: alloc_chrdev failed\n");
        return status;  
    }
    
    printk(KERN_INFO "chatlog_display: Major number assigned: %d\n", MAJOR(mi_dispo)); 
    
    p_cdev = cdev_alloc();
    if(p_cdev == NULL){
        printk(KERN_ERR "chatlog_display: cdev_alloc failed\n");
        unregister_chrdev_region(mi_dispo, MINOR_COUNT);
        return -1;  
    }

    p_cdev->ops = &my_device_ops;
    p_cdev->owner = THIS_MODULE; 
    p_cdev->dev = mi_dispo;      

    status = cdev_add(p_cdev, mi_dispo, MINOR_COUNT);

    if (status < 0){
        printk(KERN_ERR "chatlog_display: cdev_add failed \n");
        cdev_del(p_cdev);    
        unregister_chrdev_region(mi_dispo, MINOR_COUNT);
        return status;  
    }

    pclase = class_create(THIS_MODULE, CLASS_TYPE);
    
    pclase -> devnode = lcd_devnode;

    if(pclase == NULL){
        printk(KERN_ERR "chatlog_display: class_create failed\n");
        cdev_del(p_cdev);    
        unregister_chrdev_region(mi_dispo, MINOR_COUNT);
        return status;  
    }
    
    
    pdevice_sys = device_create(pclase, NULL,mi_dispo , NULL, "chatlog_lcd");

    platform_driver_register(&chatlog_display_driver);
    
    return 0;
}

static void chatlog_display_exit(void){

  printk(KERN_INFO "chatlog_display: exit called\n");

  platform_driver_unregister(&chatlog_display_driver);    //llama a funcion remove 

  device_destroy(pclase, mi_dispo);                       //desociacion  del dispositivo
  class_destroy(pclase);
  cdev_del(p_cdev);    
  
  unregister_chrdev_region(mi_dispo, MINOR_COUNT);      //libero el numero mayor y menor del dispositivo
}


//Macros de instalacion y desinstalacion
module_init(chatlog_display_init);
module_exit(chatlog_display_exit);
