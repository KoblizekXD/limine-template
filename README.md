# x86-64 Limine Kernel Template
This is my version of the Limine-based kernel. It's basically
just a stripped down version of the [Limine C Template](https://github.com/limine-bootloader/limine-c-template/),
keeping only the x86-64 architecture support & restructuring the code(no more `kernel/` directory).

## Getting Started

Given this is only a template you can start with, the [OSDev Wiki](https://wiki.osdev.org/Expanded_Main_Page) and
the [Limine Boot Protocol](https://github.com/limine-bootloader/limine/blob/v8.x/PROTOCOL.md) should give you a good headstart to your project.

### Changing the project name

You can change the name of the kernel in the boot menu inside of the `limine.conf` file.

### Structuring
- `include/` - Contains external header files which do not generally belong to the source code(e.g. auto-generated `limine.h`)
- `build/` - Contains built kernel files & intermediary object files
- `deps/` - Contains cloned dependencies required to run the project
- `res/` - Contains resources which should be converted into object files using the `objdump` command(see [Makefile](./Makefile) full command)
- `src/` - Contains kernel's main source code, this is where you will spend most of your time

### Toolchain

I'd say the [Makefile](./Makefile) is pretty well organized, so just a bit of knowledge of make should give
you enough information about the project build and how you can customize it. But generally it follows these steps:

1) Clone & build the dependencies(using the `get-deps.sh` script)
2) Compile & link the object files
3) Create the ISO/HDD
4) (Optional) Run inside QEMU

The Makefile also provides following targets:
- `all` - Builds the ISO
- `all-hdd` - Builds the HDD
- `run` - Runs the ISO inside QEMU
- `run-hdd` - Runs the HDD inside QEMU
- `run-debug` - Runs the ISO inside QEMU and waits for the debugger to attach, also provides useful information
inside of the `logs/` directory
- `clean` - Cleans the contents of the `build/` directory
- `freshen` - Removes all the downloaded dependencies and cleans the contents of the `build/` directory

### Licensing

This project template is licensed under the [MIT License](./LICENSE)
