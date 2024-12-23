CC := gcc
AR := ar
LD := ld

ARCH    := x86_64
BUILD   := build
DEPS    := deps
SRC     := src
INCLUDE := include

IMAGE_NAME := $(BUILD)/kernel
BIN_OUTPUT := $(IMAGE_NAME).bin
ISO_OUTPUT := $(IMAGE_NAME).iso
HDD_OUTPUT := $(IMAGE_NAME).hdd

# Flags for C compiler, assembler, linker & C preprocessor
CFLAGS := \
	-g -O2 -pipe \
	-Wall \
	-Wextra \
	-std=gnu11 \
	-nostdinc \
	-ffreestanding \
	-fno-stack-protector \
	-fno-stack-check \
	-fno-lto \
	-fno-PIC \
	-ffunction-sections \
	-fdata-sections \
	-m64 \
	-march=x86-64 \
	-mno-80387 \
	-mno-mmx \
	-mno-sse \
	-mno-sse2 \
	-mno-red-zone \
	-mcmodel=kernel
NASMFLAGS := -F dwarf -g -Wall -f elf64
LDFLAGS   := -nostdlib -static -z max-page-size=0x1000 -gc-sections -T linker.ld -m elf_x86_64
CPPFLAGS  := -I $(SRC) -I $(INCLUDE) \
    -isystem $(DEPS)/freestnd-c-hdrs-0bsd \
    -MMD \
    -MP

# Collect all files and connect them to the corresponding object
CFILES    := $(shell cd $(SRC) && find -L * -type f -name '*.c' | LC_ALL=C sort)
NASMFILES := $(shell cd $(SRC) && find -L * -type f -name '*.asm' | LC_ALL=C sort)
OBJ       := $(addprefix $(BUILD)/,$(CFILES:.c=.c.o) $(NASMFILES:.asm=.asm.o))

# Collect all C files and map them to their corresponding header dependency file
HEADER_DEPS := $(addprefix $(BUILD)/,$(CFILES:.c=.c.d))

.PHONY: all all-hdd run run-debug run-hdd clean

all: $(ISO_OUTPUT)
all-hdd: $(HDD_OUTPUT)
run: run-$(ARCH)
run-hdd: run-hdd-$(ARCH)

#========================================================================================================== Run Jobs

run-$(ARCH): $(DEPS)/ovmf/ovmf-code-$(ARCH).fd $(ISO_OUTPUT)
	qemu-system-$(ARCH) \
		-drive if=pflash,unit=0,format=raw,file=$(DEPS)/ovmf/ovmf-code-$(ARCH).fd,readonly=on \
		-cdrom $(ISO_OUTPUT) \
		-m 2G

run-hdd-$(ARCH): $(DEPS)/ovmf/ovmf-code-$(ARCH).fd $(HDD_OUTPUT)
	qemu-system-$(ARCH) \
		-M q35 \
		-drive if=pflash,unit=0,format=raw,file=$(DEPS)/ovmf/ovmf-code-$(ARCH).fd,readonly=on \
		-hda $(HDD_OUTPUT) \
		-m 2G

run-debug: $(DEPS)/ovmf/ovmf-code-$(ARCH).fd $(ISO_OUTPUT)
	@mkdir -p logs/
	qemu-system-$(ARCH) \
		-s \
		-S \
		-d int \
		-D logs/out.log \
		-serial file:logs/serial.txt \
		-drive if=pflash,unit=0,format=raw,file=$(DEPS)/ovmf/ovmf-code-$(ARCH).fd,readonly=on \
		-cdrom $(ISO_OUTPUT) \
		-m 2G

#========================================================================================================== The ISO & Hard Drives

$(HDD_OUTPUT): $(DEPS)/limine/limine kernel $(BIN_OUTPUT)
	rm -f $(HDD_OUTPUT)
	dd if=/dev/zero bs=1M count=0 seek=64 of=$(HDD_OUTPUT)
	sgdisk $(HDD_OUTPUT) -n 1:2048 -t 1:ef00
	./$(DEPS)/limine/limine bios-install $(HDD_OUTPUT)
	mformat -i $(HDD_OUTPUT)@@1M
	mmd -i $(HDD_OUTPUT)@@1M ::/EFI ::/EFI/BOOT ::/boot ::/boot/limine
	mcopy -i $(HDD_OUTPUT)@@1M $(BIN_OUTPUT) ::/boot
	mcopy -i $(HDD_OUTPUT)@@1M limine.conf ::/boot/limine
	mcopy -i $(HDD_OUTPUT)@@1M $(DEPS)/limine/limine-bios.sys ::/boot/limine
	mcopy -i $(HDD_OUTPUT)@@1M $(DEPS)/limine/BOOTX64.EFI ::/EFI/BOOT
	mcopy -i $(HDD_OUTPUT)@@1M $(DEPS)/limine/BOOTIA32.EFI ::/EFI/BOOT

$(ISO_OUTPUT): $(DEPS)/limine/limine kernel-deps $(BIN_OUTPUT)
	rm -rf $(BUILD)/iso_root
	mkdir -p $(BUILD)/iso_root/boot
	cp -v $(BIN_OUTPUT) $(BUILD)/iso_root/boot/
	mkdir -p $(BUILD)/iso_root/boot/limine
	cp -v limine.conf $(BUILD)/iso_root/boot/limine/
	mkdir -p $(BUILD)/iso_root/EFI/BOOT
	cp -v $(DEPS)/limine/limine-bios.sys $(DEPS)/limine/limine-bios-cd.bin $(DEPS)/limine/limine-uefi-cd.bin $(BUILD)/iso_root/boot/limine/
	cp -v $(DEPS)/limine/BOOTX64.EFI $(BUILD)/iso_root/EFI/BOOT/
	cp -v $(DEPS)/limine/BOOTIA32.EFI $(BUILD)/iso_root/EFI/BOOT/
	xorriso -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus \
		-apm-block-size 2048 --efi-boot boot/limine/limine-uefi-cd.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		$(BUILD)/iso_root -o $(ISO_OUTPUT)
	./$(DEPS)/limine/limine bios-install $(ISO_OUTPUT)

#========================================================================================================== Additional Dependencies

# Pulls down the kernel dependencies
kernel-deps:
	./get-deps.sh
	touch kernel-deps

# Clones the limine bootloader and builds the executable
$(DEPS)/limine/limine:
	rm -rf $(DEPS)/limine
	git clone https://github.com/limine-bootloader/limine.git --branch=v8.x-binary --depth=1 $(DEPS)/limine
	$(MAKE) -C $(DEPS)/limine

# OVMF enables support for UEFI in VMs
$(DEPS)/ovmf/ovmf-code-$(ARCH).fd:
	mkdir -p $(DEPS)/ovmf
	curl -Lo $@ https://github.com/osdev0/edk2-ovmf-nightly/releases/latest/download/ovmf-code-$(ARCH).fd

#========================================================================================================== Compilation & Linking

# Link everything together
$(BIN_OUTPUT): linker.ld $(OBJ) $(DEPS)/cc-runtime/cc-runtime.a
	mkdir -p "$$(dirname $@)"
	$(LD) $(OBJ) $(DEPS)/cc-runtime/cc-runtime.a $(LDFLAGS) -o $@

$(DEPS)/cc-runtime/cc-runtime.a:
	$(MAKE) -C $(DEPS)/cc-runtime -f cc-runtime.mk \
		CC="$(CC)" \
		AR="$(AR)" \
		CFLAGS="$(CFLAGS)" \
		CPPFLAGS='-isystem ../../$(DEPS)/freestnd-c-hdrs-0bsd -DCC_RUNTIME_NO_FLOAT'

# Compile all C and ASM files
$(BUILD)/%.c.o: $(SRC)/%.c
	mkdir -p "$$(dirname $@)"
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

$(BUILD)/%.asm.o: $(SRC)/%.asm
	mkdir -p "$$(dirname $@)"
	nasm $(NASMFLAGS) $< -o $@
