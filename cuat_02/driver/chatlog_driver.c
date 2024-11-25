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

MODULE_DESCRIPTION("Driver de Ejemplo para TD3");
MODULE_LICENSE("GPL");
MODULE_ALIAS("platform:Ejemplo-td3");

/*
Definiciones del driver
*/

#define BASE_MINOR 0
#define MINOR_COUNT 1

#define DEVICE_TYPE "chatlog_display"
#define CLASS_TYPE  "interface"
#define DEVICE_NAME "chatlog_display"

/*
Direcciones de registros
*/

#define CTRL_MODULE 0x44E10000     // Control module base address
#define CTRL_MODULE_SIZE 0x2000    // Control module reg bank size
#define CTRL_MODULE_D4_PIN 0x8a4   // Control module pinmux (P8_46, GPIO2_7)
#define CTRL_MODULE_D5_PIN 0x8ac   // Control module pinmux (P8_44, GPIO2_9)
#define CTRL_MODULE_D6_PIN 0x8b4   // Control module pinmux (P8_42, GPIO2_11)
#define CTRL_MODULE_D7_PIN 0x8bc   // Control module pinmux (P8_40, GPIO2_13)
#define CTRL_MODULE_RS_PIN 0x8c4   // Control module pinmux (P8_38, GPIO2_15)
#define CTRL_MODULE_EN_PIN 0x8c8   // Control module pinmux (P8_36, GPIO2_16)
#define CTRL_MODULE_UP_PIN 0x894   // Control module pinmux (P8_8, GPIO2_3)
#define CTRL_MODULE_DOWN_PIN 0x898 // Control module pinmux (P8_10, GPIO2_4)

#define CM_PER 0x44e00000         // Clock module base address
#define CM_PER_SIZE 0x1000        // Clock module reg bank size

#define CM_PER_GPIO2_CLKCTRL 0xb0 // Clock module GPIO2_CLKCTRL offset
#define CM_PER_GPIO2_CLKCTRL_ENABLE 0x2
#define OPTFCLKEN_GPIO_2_GDBCLK_BIT (1 << 18) // Clock module GPIO2_CLKCTRL OPTFCLKEN_GPIO_2_GDBCLK bit

#define CM_PER_L4LS_CLKSTCTRL 0x0 // Clock module CM_PER_L4LS_CLKSTCTRL offset
#define CLKACTIVITY_GPIO_2_GDBCLK_BIT (1 << 20) // Clock module CM_PER_L4LS_CLKSTCTRL CLKACTIVITY_GPIO_2_GDBCLK bit



#define GPIO2 0x481ac000          // GPIO2 module base address
#define GPIO2_SIZE  0x1000        // GPIO2 module reg bank size
#define GPIO_OE 0x134             // GPIO_OE offset
#define GPIO_DATAOUT 0x13c        // GPIO_DATAOUT offset
#define GPIO_CLEARDATAOUT 0x190   // GPIO_CLEARDATAOUT offset
#define GPIO_SETDATAOUT 0x194     // GPIO_SETDATAOUT offset
#define GPIO_DATAIN 0x138         // GPIO_DATAIN offset
#define GPIO_FALLINGDETECT 0x14c  // GPIO_FALLINGDETECT offset
#define GPIO_IRQSTATUS_SET_0 0x34 // GPIO_IRQSTATUS_SET_0 offset
#define GPIO_IRQSTATUS_0 0x2C     // GPIO_IRQSTATUS_0 offset
#define GPIO_DEBOUNCENABLE 0x150  // GPIO_DEBOUNCENABLE offset
#define GPIO_DEBOUNCINGTIME 0x154 // GPIO_DEBOUNCINGTIME offset

#define GPIO_SYSCONFIG 0x10       // GPIO_SYSCONFIG offset
#define GPIO_SOFTRESET 0x2        // GPIO_SYSCONFIG GPIO_SOFTRESET bit
/*
    Definiciones para configuraion de registros
*/

#define CONF_PINMUX_GPIO 0x7
#define CONF_PULL_DISABLE 0x8
#define CONF_PULL_UP 0x10
#define CONF_RECIEVE_ENABLE 0x20

/*
    Posicion de bits de las señales en GPIO2
*/
#define D4_PIN (1 << 7)
#define D5_PIN (1 << 9)
#define D6_PIN (1 << 11)
#define D7_PIN (1 << 13)
#define RS_PIN (1 << 15)
#define EN_PIN (1 << 16)
#define UP_PIN (1 << 3)
#define DOWN_PIN (1 << 4)

/*
Parametros del display y tamaños de buffer
(NO SE PUEDEN MODIFICAR PARA USAR UN DISPLAY DIFERENTE)
*/
#define LCD_ROWS 4
#define LCD_COLUMNS 20
#define LCD_SIZE LCD_ROWS*LCD_COLUMNS
#define RECV_BUFFER_SIZE LCD_SIZE + LCD_COLUMNS

/*
Commandos del HD44780
*/

#define LCD_INIT 0x33   // Inicializa el display

#define LCD_FUNCTION 0x20   // Configuracion del display
#define LCD_FUNCTION_8_BIT 0x10
#define LCD_FUNCTION_2_LINE 0x08
#define LCD_FUNCTION_5X10_DOTS 0x04

#define LCD_STATE 0x08  // Estado del display
#define LCD_STATE_ON 0x04
#define LCD_STATE_CURSOR 0x02
#define LCD_STATE_CURSOR_BLINK 0x01

#define LCD_ENTRY 0x04  // Forma de entrada del display
#define LCD_ENTRY_INCREMENT_CURSOR 0x02
#define LCD_ENTRY_DISPLAY_SHIFT 0x01

#define LCD_CLEAR 0x01  // Borra el display

#define LCD_HOME 0x02   // Comienza a escribir del principio

#define LCD_WRITE_DATA 0x80 // Para escribir datos

const uint8_t row_addresses[4] = {0x00, 0x40, 0x14, 0x54}; // Direcciones de cada filas

#define LCD_WELCOME_MESSAGE "Hello world!        This LCD is being   controlled by a     Linux driver        "

/*
Commandos del HD44780
*/

enum{
    NONE_PRESSED,
    UP_PRESSED,
    DOWN_PRESSED
} button_pressed; // Variable que se usa para comunicar el evento entre la interrupcion y la lecutra del driver

DECLARE_WAIT_QUEUE_HEAD(button_press_queue);

const char * up_pressed_str = "up\n";       // String escrito para eventos de boton UP
const char * down_pressed_str = "down\n";   // String escrito para eventos de boton DOWN

/*
Direcciones de bacos de registros mapeados por ioremap()
*/
static void *cm_per_map;
static void *ctrl_module_map;
static void *gpio2_map;


/*
Estados globales
*/
static bool lcd_initialized = false; // Si el LCD ya fue inicializado
int irq; // Linea de interrupcion para los botones

/*
Declaraciones del char device
*/
static int open(struct inode *, struct file *);
static ssize_t write(struct file *, const char __user *,size_t, loff_t*);
static ssize_t read(struct file *, char __user *, size_t, loff_t *);
static int close(struct inode *, struct file *);
static struct cdev * char_device;

/*
Declaraciones del device driver
*/
static int probe(struct platform_device *);
static int remove(struct platform_device *);

/*
Declaraciones del driver
*/
static int init_driver(void);
static void exit_driver(void);
static dev_t dev_number;
static struct class * device_class;
static struct device * device_sys;

/*
Declaraciones de funciones para el control del LCD
*/
void set_pin(uint32_t, uint8_t);
void pulse_en(void);
void write_nibble(uint8_t);
void send_command(uint8_t);
void init_lcd(void);
void send_char(char);
void fill_display(const char[LCD_SIZE]);
void show_init_message(void);


/*
Definiciones de funciones para el control del LCD
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

void fill_display(const char text[LCD_SIZE]) {
    uint8_t row, col;
    for (row = 0; row < LCD_ROWS; row++) {
        send_command(LCD_WRITE_DATA | row_addresses[row]);
        for (col = 0; col < LCD_COLUMNS; col++) {
            send_char(text[col + row*LCD_COLUMNS]);
        }
    }
}

void show_init_message(void){
    printk(KERN_INFO "chatlog_display: Displaying init message\n");
    fill_display(LCD_WELCOME_MESSAGE);
}

/*
Definiciones para el control de los botones
*/


static irqreturn_t interrupt_handler(int irq){
    int irq_status;

    irq_status = ioread32(gpio2_map + GPIO_IRQSTATUS_0);

    if(irq_status & UP_PIN){
        iowrite32(UP_PIN, gpio2_map + GPIO_IRQSTATUS_0);
        button_pressed = UP_PRESSED;
        wake_up_interruptible(&button_press_queue);
        printk(KERN_INFO "chatlog_display: UP pressed\n");
        

    }
    else if(irq_status & DOWN_PIN){
        iowrite32(DOWN_PIN, gpio2_map + GPIO_IRQSTATUS_0);
        button_pressed = DOWN_PRESSED;
        wake_up_interruptible(&button_press_queue);
        printk(KERN_INFO "chatlog_display: DOWN pressed\n");

    }
    else{
        printk(KERN_ERR "chatlog_display: Unkown interrupt\n");
    }

    return IRQ_HANDLED;
}


/*
Definiciones para el platform driver
*/

static const struct of_device_id compatible_devices [] = {
    { .compatible = "td3_glecer"},
    {},
};

MODULE_DEVICE_TABLE(of,compatible_devices);

static struct platform_driver chatlog_display_driver = {
    .probe = probe,
    .remove = remove,
    .driver = {
        .name = "Chatlog_Display_Driver",
        .of_match_table = of_match_ptr(compatible_devices),
    },    
    
};

static int probe(struct platform_device * pdev){
        
    static int irq_request_result;
	
    int reg; // Variable para guardar temporalemnte registros
    
    printk(KERN_INFO "chatlog_display: probe called\n");

    /*
    Mapeo de bacos de registros CM_PER, GPIO2 y CONTROL_MODULE
    */
    
    cm_per_map = ioremap(CM_PER, CM_PER_SIZE);
    if(cm_per_map == NULL){
        printk(KERN_ERR "chatlog_display: CM_PER remap error\n");
        return -1;
    }
    printk(KERN_INFO "chatlog_display: CM_PER remap OK\n");

    gpio2_map = ioremap (GPIO2, GPIO2_SIZE);
    if(gpio2_map == NULL){
        iounmap(cm_per_map);
        printk(KERN_ERR "chatlog_display: GPIO2 remap error\n");
        return -1;
    }
    printk(KERN_INFO "chatlog_display: GPIO2 remap OK\n");

    ctrl_module_map = ioremap (CTRL_MODULE, CTRL_MODULE_SIZE);
    if(ctrl_module_map == NULL){
        iounmap(cm_per_map);
        iounmap(gpio2_map);
        printk(KERN_ERR "chatlog_display: CONTROL_MODULE remmap error\n");
        return -1;
    }
    printk(KERN_INFO "chatlog_display: CONTROL_MODULE remap OK\n");


    /*
    Configuracion de pin-muxing
    */
    iowrite32(CONF_PINMUX_GPIO, ctrl_module_map + CTRL_MODULE_RS_PIN);
    iowrite32(CONF_PINMUX_GPIO, ctrl_module_map + CTRL_MODULE_EN_PIN);
    iowrite32(CONF_PINMUX_GPIO, ctrl_module_map + CTRL_MODULE_D4_PIN);
    iowrite32(CONF_PINMUX_GPIO, ctrl_module_map + CTRL_MODULE_D6_PIN);
    iowrite32(CONF_PINMUX_GPIO, ctrl_module_map + CTRL_MODULE_D5_PIN);
    iowrite32(CONF_PINMUX_GPIO, ctrl_module_map + CTRL_MODULE_D7_PIN);
    iowrite32(CONF_PINMUX_GPIO | CONF_PULL_UP | CONF_RECIEVE_ENABLE, ctrl_module_map + CTRL_MODULE_UP_PIN);
    iowrite32(CONF_PINMUX_GPIO | CONF_PULL_UP | CONF_RECIEVE_ENABLE, ctrl_module_map + CTRL_MODULE_DOWN_PIN);
    printk(KERN_INFO "chatlog_display: Pin-mux set OK\n");
	
    
    // Enable del clock de debounce GPIO2_GDBCLK
    reg = ioread32(cm_per_map + CM_PER_L4LS_CLKSTCTRL);
    reg |= CLKACTIVITY_GPIO_2_GDBCLK_BIT;
    iowrite32(reg, cm_per_map + CM_PER_L4LS_CLKSTCTRL);

    // Enable del clock del modulo GPIO2 y del Optional functional clock (para debounce).
    iowrite32(CM_PER_GPIO2_CLKCTRL_ENABLE | OPTFCLKEN_GPIO_2_GDBCLK_BIT , cm_per_map + CM_PER_GPIO2_CLKCTRL);

    // Reset del modulo de GPIO
    iowrite32(GPIO_SOFTRESET, gpio2_map + GPIO_SYSCONFIG);

    //udelay(100);

    // Todo input excepto pines del display
    iowrite32(~(uint32_t)(EN_PIN|RS_PIN|D4_PIN|D5_PIN|D6_PIN|D7_PIN), gpio2_map + GPIO_OE);
    
    // Configuracion debounce
    iowrite32(0xFF, gpio2_map + GPIO_DEBOUNCINGTIME);
    iowrite32(UP_PIN|DOWN_PIN, gpio2_map + GPIO_DEBOUNCENABLE);


    printk(KERN_INFO "chatlog_display: GPIO Configuration OK\n");

    
    // Request de linea de interrupcion
    irq = platform_get_irq(pdev,0);

    irq_request_result = request_irq ( irq,(irq_handler_t)interrupt_handler, IRQF_TRIGGER_RISING, pdev->name, NULL);
    if(irq_request_result < 0){
        printk(KERN_ERR "chatlog_display: request_irq error\n");
        iounmap(cm_per_map);
        iounmap(gpio2_map);
        iounmap(ctrl_module_map);
        return -1;
    }
    printk(KERN_INFO "chatlog_display: IRQ line assigned: %d", irq);

    // Configuracion de interrupt para botones UP y DOWN.
    iowrite32(UP_PIN|DOWN_PIN, gpio2_map + GPIO_IRQSTATUS_SET_0);
    iowrite32(UP_PIN|DOWN_PIN, gpio2_map + GPIO_FALLINGDETECT);

    lcd_initialized = true;
    button_pressed = NONE_PRESSED;

    return 0;
}


static int remove(struct platform_device * pdev){    
	printk(KERN_INFO "chatlog_display: remove called");

	iounmap(cm_per_map);
	iounmap(gpio2_map);
    iounmap(ctrl_module_map);
	free_irq(irq,NULL);
 
	return 0;
}

/*
Definiciones Char Driver
*/

static struct file_operations my_device_ops = 
{
    .owner = THIS_MODULE,
    .open = open,
    .read = read,
    .release = close,
    .write = write,
  
};

static int open (struct inode * inode, struct file * file)
{
  
    printk(KERN_INFO "chatlog_display: char device opened. Initializing display...\n");
    
    init_lcd();
    show_init_message();

    return 0;
}

static ssize_t write (struct file * file, const char __user * userbuff, size_t size, loff_t* offset)
{
    /*
    La escritura del archivo escribe los datos en el dispay, remplazando completamente lo que estaba
    escrito anteriormente.
    */

    int row  = 0 , col = 0, i = 0; // Iteradores
    static char recv_str[RECV_BUFFER_SIZE];


    if(!lcd_initialized){
        printk(KERN_ALERT "chatlog_display: LCD not initialized\n");
        return size;
    }


    if(size > RECV_BUFFER_SIZE)
        size = RECV_BUFFER_SIZE;

    memset(recv_str, 0, RECV_BUFFER_SIZE);


    // Copia los datos de user space
    if (copy_from_user(recv_str, userbuff, size)) {
        printk(KERN_ALERT "chatlog_display: Failed to copy data from user space\n");
        return -EFAULT;
    }

    send_command(LCD_CLEAR);


    while(row < LCD_ROWS){
        send_command(LCD_WRITE_DATA | row_addresses[row]);

        // Para cada fila, escribo caracteres
        col = 0;
        while(col < LCD_COLUMNS){
            // Hasta que hay un newline, entonces paso a la siguiente fila
            if(recv_str[i] == '\n'){
                col = LCD_COLUMNS;
                i++;
                break;
            }

            send_char(recv_str[i]);
            col++;
            i++;

            // O hasta que se termine el buffer, entocnes ya termino de escribir
            if(i >= size){
                row = LCD_ROWS;
                col = LCD_COLUMNS;
            }
        }
        row += 1;
    }
    
    printk("chatlog_display: Updated LCD\n");

    return size;
}



int data_size = 10;

static ssize_t read (struct file * file, char __user * userbuff, size_t count, loff_t * offset)
{   
    /*
    La lecutra del archivo es bloqueante hasta que sea realiza una interrupcion
    */

    ssize_t bytes_to_read = 0;
    static char * str_to_send;
    static int message_size;

    // Espera a que se aprete un boton y se acrive la interrupcion, modificando button_pressed
    wait_event_interruptible(button_press_queue, button_pressed != NONE_PRESSED);

    if(button_pressed == UP_PRESSED){
        str_to_send = (char *)up_pressed_str;
        message_size = strlen(str_to_send);

    }
    else if(button_pressed == DOWN_PRESSED){
        str_to_send = (char *)down_pressed_str;
        message_size = strlen(str_to_send);
    }
    else{
        printk(KERN_ERR "chatlog_display: Unkown message to send\n");
        return -1;
    }
    

    // Si el usuario pide leer mas que lo que queda del mensaje, lo acota
    bytes_to_read = min(count, (size_t)(message_size - *offset));

    // Escribe los datos a user space
    if (copy_to_user(userbuff, str_to_send + *offset, bytes_to_read)) {
        printk(KERN_ERR "chatlog_display: Failed to send data to user space\n");
        return -EFAULT;
    }

    *offset += bytes_to_read; // Avanzo el offset

    printk(KERN_INFO "chatlog_display: Sent %zd bytes to user space\n", bytes_to_read);

    // Si ya se termino de leer el mensaje, retorna el offset a 0 para el siguiente mensaje, y resetea el estado del boton
    if (*offset >= message_size){
        button_pressed = NONE_PRESSED;
        *offset = 0;

    }
    return bytes_to_read;
}


static int close (struct inode * inode, struct file * file)
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

static int init_driver(void)
{
    int status = 0;

    status = alloc_chrdev_region(&dev_number, BASE_MINOR, MINOR_COUNT, DEVICE_TYPE);

    if(status !=0){
        printk(KERN_ERR "chatlog_display: alloc_chrdev failed\n");
        return status;  
    }
    
    printk(KERN_INFO "chatlog_display: Major number assigned: %d\n", MAJOR(dev_number)); 
    
    char_device = cdev_alloc();
    if(char_device == NULL){
        printk(KERN_ERR "chatlog_display: cdev_alloc failed\n");
        unregister_chrdev_region(dev_number, MINOR_COUNT);
        return -1;  
    }

    char_device->ops = &my_device_ops;
    char_device->owner = THIS_MODULE; 
    char_device->dev = dev_number;      

    status = cdev_add(char_device, dev_number, MINOR_COUNT);

    if (status < 0){
        printk(KERN_ERR "chatlog_display: cdev_add failed \n");
        cdev_del(char_device);    
        unregister_chrdev_region(dev_number, MINOR_COUNT);
        return status;  
    }

    device_class = class_create(THIS_MODULE, CLASS_TYPE);
    
    device_class -> devnode = lcd_devnode;

    if(device_class == NULL){
        printk(KERN_ERR "chatlog_display: class_create failed\n");
        cdev_del(char_device);    
        unregister_chrdev_region(dev_number, MINOR_COUNT);
        return status;  
    }
    
    
    device_sys = device_create(device_class, NULL,dev_number , NULL, "chatlog_lcd");

    platform_driver_register(&chatlog_display_driver);
    
    return 0;
}

static void exit_driver(void){

  printk(KERN_INFO "chatlog_display: exit called\n");

  platform_driver_unregister(&chatlog_display_driver);

  device_destroy(device_class, dev_number);
  class_destroy(device_class);
  cdev_del(char_device);    
  
  unregister_chrdev_region(dev_number, MINOR_COUNT);
}


module_init(init_driver);
module_exit(exit_driver);
