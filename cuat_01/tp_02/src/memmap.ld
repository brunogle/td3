/* 
    Definiciones necesarias: formato de salida, arquitectura y punto de entrada
*/
OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)


BOOTLOADER_INIT = 0x70010000;
STACK_INIT = 0x70020000;
KERNEL_INIT = 0x70030000;



/* 
    Definición de las secciones
*/
SECTIONS
{
    . = BOOTLOADER_INIT;
    .bootloader :
    { *(.bootloader*); }

    . = STACK_INIT;
    .stack :
    { *(.stack*); }
    STACK_END = .;


    . = KERNEL_INIT;
    .kernel : 
    AT (ADDR(.bootloader) + SIZEOF(.bootloader))
    { *(.kernel*); }
    KERNEL_LOAD = ADDR(.bootloader) + SIZEOF(.bootloader);
    KERNEL_SIZE = SIZEOF(.kernel);

}