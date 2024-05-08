AS = arm-none-eabi-as
LD = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
QEMU = qemu-system-arm
DEBUGGER = ddd
#DEBUGGER = seergdb

ASFLAGS = -g
LDFLAGS = -T $(LINKER_SCRIPT)
OBJCOPYFLAGS = -O binary
QEMUFLAGS = -M realview-pb-a8 -m 32M -no-reboot -nographic -monitor telnet:127.0.0.1:1234,server,nowait -S -gdb tcp::2159
DEBUGGERFLAGS = --debugger "gdb-multiarch -x gdb_init_ddd.txt"


LINKER_SCRIPT = $(SRC_DIR)/memmap.ld

SRC_DIR = src
BIN_DIR = bin

SRC_FILES = $(wildcard $(SRC_DIR)/*.s)

OBJ_FILES = $(patsubst $(SRC_DIR)/%.s,$(BIN_DIR)/%.o,$(SRC_FILES)) #Object files places are placed in bin dir

TARGET_ELF = $(BIN_DIR)/output.elf
TARGET_BIN = $(BIN_DIR)/output.bin

all: $(TARGET_BIN)

# Rule to compile assembly files
$(BIN_DIR)/%.o: $(SRC_DIR)/%.s
	$(AS) $(ASFLAGS) -o $@ $<

# Rule to link object files
$(TARGET_ELF): $(OBJ_FILES) $(LINKER_SCRIPT)
	$(LD) $(LDFLAGS) -o $@ $(filter-out $(LINKER_SCRIPT), $^)

# Rule to generate .bin file
$(TARGET_BIN): $(TARGET_ELF)
	$(OBJCOPY) $(OBJCOPYFLAGS) $< $@

# Clean target
clean:
	rm -rf $(BIN_DIR)

# Create bin directory if it doesn't exist
$(shell mkdir -p $(BIN_DIR))

qemu: $(TARGET_BIN) # Run bin file in qemu
	$(QEMU) $(QEMUFLAGS) -kernel $(TARGET_BIN)

debug: $(TARGET_BIN) $(TARGET_ELF) # Debug
	$(QEMU) $(QEMUFLAGS) -kernel $(TARGET_BIN) &
	$(DEBUGGER) $(DEBUGGERFLAGS) $(TARGET_ELF)
	killall $(QEMU)

debug_seer: $(TARGET_BIN) $(TARGET_ELF) # Debug
	$(QEMU) $(QEMUFLAGS) -kernel $(TARGET_BIN) &
	seergdb --project project.seer --gdb-program gdb-multiarch
	killall $(QEMU)


