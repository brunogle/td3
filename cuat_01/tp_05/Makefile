################################################## PROGRAMAS ##################################################

TOOLCHAIN = arm-none-eabi
QEMU = qemu-system-arm	
DEBUGGER = ddd

AS = $(TOOLCHAIN)-as
LD = $(TOOLCHAIN)-ld
OBJCOPY = $(TOOLCHAIN)-objcopy


################################################## FLAGS ##################################################

ASFLAGS = -g
LDFLAGS = -T $(LINKER_SCRIPT)
OBJCOPYFLAGS = -O binary

QEMUFLAGS = -M realview-pb-a8 -m 32M -no-reboot -nographic -monitor telnet:127.0.0.1:1234,server,nowait -S -gdb tcp::2159 -device loader,addr=0x70010000,cpu-num=0
DEBUGGERFLAGS = --debugger "gdb-multiarch -x gdb_init_ddd.txt"

################################################## DIRECTORIOS ##################################################

SRC_DIR = src
BIN_DIR = bin
OBJ_DIR = obj
LST_DIR = lst



################################################## ARCHIVOS ESPECIALES ##################################################

LINKER_SCRIPT =  src/memmap.ld

SRC_ISR = src/kernel/interrupt/isr_table.s # Este archivo no es compilado por la misma tarea que compila las otras fuentes

TARGET_ELF = $(BIN_DIR)/output.elf
TARGET_BIN = $(BIN_DIR)/output.bin



################################################## DETECCION AUTOMATICA DE ARCHIVOS ##################################################

### Fuentes

SRC_FILES_INC_ISR := $(shell find $(SRC_DIR) -type f -name '*.s')
SRC_FILES :=  $(filter-out $(SRC_ISR),$(SRC_FILES_INC_ISR)) # Archivos fuentes excepto por SRC_ISR

### Objetos

OBJ_FILES := $(patsubst $(SRC_DIR)/%.s,$(OBJ_DIR)/%.o,$(SRC_FILES))
OBJ_ISR := $(patsubst $(SRC_DIR)/%.s,$(OBJ_DIR)/%.o,$(SRC_ISR))

### Listas
LST_FILES := $(patsubst $(SRC_DIR)/%.s,$(LST_DIR)/%.o,$(SRC_FILES))

################################################## VARIABLES DEFAULT ##################################################

EXCEPTIONS = 1
IRQ = 1
FIQ = 1
SWI = 1

################################################## TAREA MAKE ALL ##################################################

.PHONY: all
all: $(TARGET_BIN)


################################################## TAREAS DE ASSEMBLER ##################################################

## Tarea para todos los objetos menos OBJ_ISR
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(dir $@)
	@mkdir -p $(dir $(LST_DIR)/$*.lst)
	$(AS) $(ASFLAGS) -al=$(LST_DIR)/$*.lst -o $@ $<


## Tarea especial para OBJ_ISR
## Se fuerza el assembly del ISR para asegurar que se cumple las condiciones de EXCEPTIONS=0, etc. si se pasa

$(OBJ_ISR): $(SRC_ISR) .FORCE
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) --defsym _EXCEPTIONS_ENABLED=$(EXCEPTIONS) --defsym _IRQ_ENABLED=$(IRQ) --defsym _FIQ_ENABLED=$(FIQ) -o $(OBJ_ISR) $(SRC_ISR)

################################################## TAREAS DE LINKEO ##################################################


## Para generar el ELF a partir de los objetos
$(TARGET_ELF): $(OBJ_FILES) $(OBJ_ISR) $(LINKER_SCRIPT)
	@mkdir -p $(dir $@)
	$(LD) $(LDFLAGS) -o $@ $(filter-out $(LINKER_SCRIPT), $^)

# Para generar el BIN a partir del ELF
$(TARGET_BIN): $(TARGET_ELF)
	@mkdir -p $(dir $@)
	$(OBJCOPY) $(OBJCOPYFLAGS) $< $@


################################################## TAREAS EXTRA ##################################################

# Clean target
.PHONY: clean
clean:
	rm -rf $(BIN_DIR) $(OBJ_DIR) $(LST_DIR)

# Necesario para forzar el assembly de exepciones
.PHONY: .FORCE

# Help
.PHONY: help
help:
	@echo $(OBJ_FILES)
	@echo "Este makefile posee las siguientes tareas:"
	@echo "    make all   : Ensambla el binario"
	@echo "    make qemu  : Ensambla el binario y lo corre en qemu"
	@echo "    make debug : Ensambla el binario, lo corre en qemu y abre el ddd y ejecuta los comandos en gdb_init_ddd.txt"
	@echo ""
	@echo "Argumentos opcionales:"
	@echo "    EXCEPTIONS=0 en cualquier tarea, no se ejecutara el handler de ninguna exepcion"
	@echo "    IRQ=0 en cualquier tarea, no se ejecutara el handler de IRQ"
	@echo "    FIQ=0 en cualquier tarea, no se ejecutara el handler de FIQ"

################################################## TAREAS DE EJECUCION ##################################################


## Ejecuta el programa en qemu
.PHONY: qemu
qemu: $(TARGET_BIN)

	$(QEMU) $(QEMUFLAGS) -kernel $(TARGET_BIN)


## Ejecuta el programa en qemu y abre ddd
.PHONY: debug
debug: $(TARGET_BIN) $(TARGET_ELF)
	$(QEMU) $(QEMUFLAGS) -kernel $(TARGET_BIN) &
	$(DEBUGGER) $(DEBUGGERFLAGS) $(TARGET_ELF)
	killall $(QEMU)