OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

__DESTINO_KERNEL = 0x70030000

SECTIONS
{
    .bootloader :
    { *(.bootloader); }

    . = 0x70020000;

    .pila :
    AT (LOADADDR(.bootloader) + SIZEOF(.bootloader))
    { *(.pila*); }

    .kernel_origen :
    AT (LOADADDR(.pila) + SIZEOF(.pila))
    { *(.kernel*); }

}