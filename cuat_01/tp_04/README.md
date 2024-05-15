# Descripción del proyecto


En este proyecto, se configura el GIC y se habilita el Timer 0 para incrementar R10 cada 10ms. Se amplia el uso de las exepciones, haciendo que guarden en R10 un string de 3 caracteres con el tipo de exepcion que se produjo. Se implemento un argumento opcional en el makefile (EXCPETIONS=0) que deshabilita la ejecucion de codigo en las exepciones.

## Archivos:
- `src/bootloader.s`: Aca se encuentra el codigo de bootloader, las secciones definidas en este archivo se ejecutan sobre ROM. Es el punto de entrada del programa
- `src/kernel.s`: Aca (supuestamente) se encuentra el kernel, con el codigo de ejemplo para verificar el funcionamiento de las interrupciones.
- `src/exceptions.s`: Aca se encuentra el codigo necesario para el uso de las interrucpciones y exepciones (Handlers y tabla ISR)
- `src/gic.s`: Aca se encuentra el codigo para configurar el GIC
- `src/timer.s`: Aca se encuentra el codigo para configurar el Timer 0
- `src/addr.s`: Aca se encuentran todos los .equ que especifican direcciones de registros para poder configurar perifericos

# Ejecución

El make ahora incluye `make help` que explica las opciones de ejecutar el codigo:

**make all**   : Ensambla el binario

**make qemu**  : Ensambla el binario y lo corre en qemu

**make debug** : Ensambla el binario, lo corre en qemu y abre el ddd y ejecuta los comandos en gdb_init_ddd.txt

**make seer**  : Ensambla el binario, lo corre en qemu y abre el seergdb y ejecuta los comandos en gdb_init_seer.txt

Opcionalmente, si se pasa EXCEPTIONS=0 en cualquier tarea, no se ejecutara codigo en ninguna exepcion


 
