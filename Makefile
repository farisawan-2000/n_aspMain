default: all

DUMMY != mkdir -p build

NON_MATCHING := 0

DEFINES := 
ifeq ($(NON_MATCHING), 1)
	DEFINES += -DNON_MATCHING
endif

all: build/n_aspMain.text.bin
	@sha1sum -c n_aspMain.text.sha1
	@sha1sum -c n_aspMain.data.sha1

tools/armips: tools/armips.cpp
	$(CXX) $(CXXFLAGS) -fno-exceptions -fno-rtti -pipe $^ -o $@ -lpthread $(ARMIPS_FLAGS)
	chmod +x $@

build/n_aspMain.text.bin: n_aspMain.text.s tools/armips
	cpp -P $< -o build/$< -I/usr/include/n64 $(DEFINES)
	tools/armips -strequ CODE_FILE $@ -strequ DATA_FILE build/n_aspMain.data.bin -temp scratch_space/.t3d  build/$<
	mips-linux-gnu-ld -r -b binary build/n_aspMain.text.bin -o build/naudio_text.o
	mips-linux-gnu-ld -r -b binary build/n_aspMain.data.bin -o build/naudio_data.o


dump_binary:
	mkdir -p dump
	cpp -P ucode.ld -o build/ucode.cp.ld -DTEXT
	mips-linux-gnu-ld -o dump/text.elf -Tbuild/ucode.cp.ld /usr/lib/n64/PR/gspTurbo3D.fifo.o
	mips-linux-gnu-objcopy dump/text.elf dump/text.bin -O binary
	cpp -P ucode.ld -o build/ucode.cp.ld -DDATA
	mips-linux-gnu-ld -o dump/data.elf -Tbuild/ucode.cp.ld /usr/lib/n64/PR/gspTurbo3D.fifo.o
	mips-linux-gnu-objcopy dump/data.elf dump/data.bin -O binary


clean: build/n_aspMain.text.bin
	rm build/ -r
