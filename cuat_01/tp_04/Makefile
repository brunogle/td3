################################################## PROGRAMAS ##################################################


AS = arm-none-eabi-as
LD = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
QEMU = qemu-system-arm
DEBUGGER = ddd


################################################## FLAGS ##################################################
ASFLAGS = -g
LDFLAGS = -T $(LINKER_SCRIPT)
OBJCOPYFLAGS = -O binary
QEMUFLAGS = -M realview-pb-a8 -m 32M -no-reboot -nographic -monitor telnet:127.0.0.1:1234,server,nowait -S -gdb tcp::2159
DEBUGGERFLAGS = --debugger "gdb-multiarch -x gdb_init_ddd.txt"

################################################## DIRECTORIOS ##################################################


SRC_DIR = src
BIN_DIR = bin

$(shell mkdir -p $(BIN_DIR))


################################################## ARCHIVOS ESPECIALES ##################################################

LINKER_SCRIPT =  memmap.ld

SRC_EXCEPTIONS = src/exceptions.s # Este archivo no es compilado por la misma tarea que compila las otras fuentes

TARGET_ELF = $(BIN_DIR)/output.elf
TARGET_BIN = $(BIN_DIR)/output.bin



################################################## DETECCION AUTOMATICA DE ARCHIVOS ##################################################

### Fuentes

SRC_FILES_INC_EXCEPTIONS = $(wildcard $(SRC_DIR)/*.s)
SRC_FILES =  $(filter-out $(SRC_EXCEPTIONS),$(SRC_FILES_INC_EXCEPTIONS)) # Archivos fuentes excepto por SRC_EXCPETIONS

### Objetos

OBJ_FILES = $(patsubst $(SRC_DIR)/%.s,$(BIN_DIR)/%.o,$(SRC_FILES))
OBJ_EXCEPTIONS = $(patsubst $(SRC_DIR)/%.s,$(BIN_DIR)/%.o,$(SRC_EXCEPTIONS))


################################################## VARIABLES DEFAULT ##################################################

EXCEPTIONS = 1
IRQ = 1
FIQ = 1

################################################## TAREA MAKE ALL ##################################################

all: $(TARGET_BIN)


################################################## TAREAS DE ASSEMBLER ##################################################


## Tarea para todos los objetos menos OBJ_EXCEPTIONS
$(BIN_DIR)/%.o: $(SRC_DIR)/%.s
	$(AS) $(ASFLAGS) -o $@ $<


## Tarea especial para OBJ_EXCEPTIONS
## Se fuerza en assembly de las expeciones para asegurar que se cumple la condicion de EXCEPTIONS=0 si se pasa

$(OBJ_EXCEPTIONS): $(SRC_EXCEPTIONS) .FORCE

ifeq ($(EXCEPTIONS), 0)
	@echo -e "\033[0;31mExceptions disabled\033[0m"
endif
	$(AS) $(ASFLAGS) --defsym _EXCEPTIONS_ENABLED=$(EXCEPTIONS) --defsym _IRQ_ENABLED=$(IRQ) --defsym _FIQ_ENABLED=$(FIQ) -o $(OBJ_EXCEPTIONS) $(SRC_EXCEPTIONS)

################################################## TAREAS DE LINKEO ##################################################


## Para generar el ELF a partir de los objetos
$(TARGET_ELF): $(OBJ_FILES) $(OBJ_EXCEPTIONS) $(LINKER_SCRIPT)
	$(LD) $(LDFLAGS) -o $@ $(filter-out $(LINKER_SCRIPT), $^)

# Para generar el BIN a partir del ELF
$(TARGET_BIN): $(TARGET_ELF)
	$(OBJCOPY) $(OBJCOPYFLAGS) $< $@


################################################## TAREAS EXTRA ##################################################


# Clean target
clean:
	rm -rf $(BIN_DIR)

# Necesario para forzar el assembly de exepciones
.PHONY: .FORCE
.FORCE:

# Help
help:
	@echo "Este makefile posee las siguientes tareas:"
	@echo "    make all   : Ensambla el binario"
	@echo "    make qemu  : Ensambla el binario y lo corre en qemu"
	@echo "    make debug : Ensambla el binario, lo corre en qemu y abre el ddd y ejecuta los comandos en gdb_init_ddd.txt"
	@echo "    make seer  : Ensambla el binario, lo corre en qemu y abre el seergdb y ejecuta los comandos en gdb_init_seer.txt"
	@echo ""
	@echo "Argumentos opcionales:"
	@echo "    EXCEPTIONS=0 en cualquier tarea, no se ejecutara el handler de ninguna exepcion"
	@echo "    IRQ=0 en cualquier tarea, no se ejecutara el handler de IRQ"
	@echo "    FIQ=0 en cualquier tarea, no se ejecutara el handler de FIQ"

################################################## TAREAS DE EJECUCION ##################################################


## Ejecuta el programa en qemu
qemu: $(TARGET_BIN)
	$(QEMU) $(QEMUFLAGS) -kernel $(TARGET_BIN)


## Ejecuta el programa en qemu y abre ddd
debug: $(TARGET_BIN) $(TARGET_ELF)
	$(QEMU) $(QEMUFLAGS) -kernel $(TARGET_BIN) &
	$(DEBUGGER) $(DEBUGGERFLAGS) $(TARGET_ELF)
	killall $(QEMU)


## Ejecuta el programa en qemu y abre seergdb
debug_seer: $(TARGET_BIN) $(TARGET_ELF)
	$(QEMU) $(QEMUFLAGS) -kernel $(TARGET_BIN) &
	seergdb --project project.seer --gdb-program gdb-multiarch
	killall $(QEMU)


