OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

MEMORY
{
    /* 
    Direccion del comienzo de la ROM.
    Primero se tiene que encontrar el bootloader, seguido del codigo del kernel
    */
    rom(rwx) : org = 0x70010000, len = 0x10000

    /* Direccion del stack  */
    stack(rw) : org = 0x70020000, len = 0x10000

    /* Direccion de RAM. El bootloader va a copiar el kernel aca */
    ram(rwx) : org = 0x70030000, len = 0x10000
}


SECTIONS
{
    
    /*
    Cargo primero el bootloader a ROM
    Para esta seccion, se ejecuta donde se carga (VMA=LMA)
    */
    .bootloader :
    {
        *(.bootloader*);
    } >rom


    /* 
    Despues del bootloader, cargo el kernel a ROM (con AT>ROM)
    Pero este codigo se va a estar ejecutando en RAM (>ram)
    */
    .kernel : 
    {
        *(.kernel*);
    } >ram AT>rom
    /* Defino simbolos con valores numericos importantes para realizar la copia del kernel */
    KERNEL_INIT = ADDR(.kernel); /* VMA del kernel */
    KERNEL_LOAD = LOADADDR(.kernel); /* LMA del kernel */
    KERNEL_SIZE = SIZEOF(.kernel); /* size del kernel */


    /* 
    Defino una seccion vacia para utilizar como stack
    */
    .stack :
    {
        *(.stack*);
    } >stack
    STACK_SIZE = SIZEOF(.stack);
    STACK_END = .;


}