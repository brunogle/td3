# Descripción del proyecto

Este es un ejemplo de como se puede copiar código dentro de la memoria y muestra que rol cumple el linker en este proceso.

La sección `.bootloader`, que se va a encontrar ubicada al principio de la ROM (0x70010000) tiene el trabajo de copiar la sección `.kernel` que originalmente se encuentra inmediatamente después de `.bootloader` en ROM a una nueva dirección en RAM (0x70030000)
Luego de copiar esta sección, hace un branch a la subrutina `kernel_start`, parte de la seccion `kernel` que se encuentra en el lugar nuevo de memoria.
La sección kernel se encuentra en modo Thumb. Como ejemplo, lo único que hace el "kernel" es cambiar un valor de memoria y quedarse en un loop infinito.

# Ejecución

Ejecutando el comando `make debug` genera el binario, lo comienza a ejecutar en `qemu` y abre `ddd` para debuggear.
La conexión de `gdb` y la configuración del registro `pc` se realiza automáticamente. Los comandos de `gdb` que se ejecutan para realizar esto se encuentran en `gdb_init.txt`.
Al completarse el comando (cuando `ddd` se cierra), el makefile automáticamente **mata todos los procesos de `qemu`**.

 
